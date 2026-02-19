"""
LLM-Based Explanation Layer using LangChain + LangGraph
Integrated from Explaination_layer.py

Purpose: Generate natural, empathetic explanations for triage decisions
Uses: Groq API (llama-3.1) via LangChain
"""

import os
import json
from typing import Dict, List, Optional, TypedDict
import warnings
warnings.filterwarnings('ignore')

try:
    from langchain_openai import ChatOpenAI
    from langchain_core.prompts import ChatPromptTemplate
    from langchain_core.messages import HumanMessage, SystemMessage
    from langgraph.graph import StateGraph as LangStateGraph, END
    StateGraph = LangStateGraph  # Create alias for use below
    LANGCHAIN_AVAILABLE = True
except ImportError:
    LANGCHAIN_AVAILABLE = False
    StateGraph = None  # Set to None when unavailable
    END = None
    warnings.warn("LangChain not available. Explanation layer will use template fallback.")


class TriageState(TypedDict):
    """State for the triage explanation graph"""
    user_input: str
    extracted_symptoms: List[str]
    severity: str
    duration: str
    triage_level: str
    confidence: float
    language: str
    spoken_response: str
    tone: str
    actions: List[str]


class ExplanationLayer:
    """
    LLM-based explanation layer for healthcare triage
    Uses LangChain + LangGraph for generating empathetic responses
    """
    
    def __init__(self, api_key: Optional[str] = None, model_name: str = "llama-3.1-8b-instant"):
        """
        Initialize explanation layer
        
        Args:
            api_key: Groq API key (or set GROQ_API_KEY env var)
            model_name: Groq model to use
        """
        self.use_llm = False
        
        # Get API key from parameter or environment (Groq)
        self.api_key = api_key or os.getenv("GROQ_API_KEY")
        
        if LANGCHAIN_AVAILABLE and self.api_key:
            try:
                print(f"🤖 Initializing LLM explanation layer with Groq {model_name}...")
                
                # Initialize Groq LLM via LangChain OpenAI-compatible interface
                self.llm = ChatOpenAI(
                    model=model_name,
                    openai_api_key=self.api_key,
                    openai_api_base="https://api.groq.com/openai/v1",
                    temperature=0.3,
                    max_tokens=200,
                    timeout=10  # Timeout after 10 seconds
                )
                
                # Build LangGraph workflow
                self.workflow = self._build_workflow()
                
                self.use_llm = True
                print("✅ LLM explanation layer initialized successfully!")
                
            except Exception as e:
                print(f"⚠️ LLM initialization failed: {e}")
                print("✅ Using template-based fallback")
        else:
            # Silently use template-based explanations
            # (LangChain + Groq LLM not configured - using template fallback)
            pass
        
        # Template fallback
        self._load_templates()
    
    def _build_workflow(self) -> StateGraph:
        """Build LangGraph workflow for triage explanation"""
        
        workflow = StateGraph(TriageState)
        
        # Add nodes
        workflow.add_node("analyze_severity", self._analyze_severity_node)
        workflow.add_node("generate_explanation", self._generate_explanation_node)
        workflow.add_node("determine_tone", self._determine_tone_node)
        workflow.add_node("suggest_actions", self._suggest_actions_node)
        
        # Define edges
        workflow.set_entry_point("analyze_severity")
        workflow.add_edge("analyze_severity", "generate_explanation")
        workflow.add_edge("generate_explanation", "determine_tone")
        workflow.add_edge("determine_tone", "suggest_actions")
        workflow.add_edge("suggest_actions", END)
        
        return workflow.compile()
    
    def _analyze_severity_node(self, state: TriageState) -> TriageState:
        """Analyze severity and context"""
        # This node can be extended with additional LLM-based analysis
        return state
    
    def _generate_explanation_node(self, state: TriageState) -> TriageState:
        """Generate natural language explanation using LLM"""
        
        # Create prompt
        prompt = f"""You are a compassionate healthcare assistant. Generate a clear, empathetic response for a patient.

Patient Input: {state['user_input']}
Detected Symptoms: {', '.join(state['extracted_symptoms'])}
Severity: {state['severity']}
Duration: {state['duration']}
Triage Level: {state['triage_level']}
Confidence: {state['confidence']:.0%}

CRITICAL CONSTRAINTS:
- DO NOT diagnose any disease
- DO NOT prescribe any medication
- DO NOT use medical jargon
- Be empathetic and reassuring
- Keep response under 100 words
- Focus on next steps and safety

Generate a spoken response appropriate for {state['triage_level']} triage level:"""

        try:
            # Generate response using LLM
            messages = [
                SystemMessage(content="You are a compassionate healthcare guidance assistant. Never diagnose or prescribe."),
                HumanMessage(content=prompt)
            ]
            
            response = self.llm.invoke(messages)
            state['spoken_response'] = response.content.strip()
            
        except Exception as e:
            print(f"⚠️ LLM generation failed: {e}, using template")
            state['spoken_response'] = self._get_template_response(state)
        
        return state
    
    def _determine_tone_node(self, state: TriageState) -> TriageState:
        """Determine appropriate tone based on triage level"""
        
        tone_map = {
            'EMERGENCY': 'urgent',
            'URGENT': 'firm',
            'SELF_CARE': 'reassuring'
        }
        
        state['tone'] = tone_map.get(state['triage_level'], 'firm')
        return state
    
    def _suggest_actions_node(self, state: TriageState) -> TriageState:
        """Suggest appropriate actions based on triage level"""
        
        action_map = {
            'EMERGENCY': [
                "Call emergency services (108) immediately",
                "Do not drive yourself",
                "Stay calm and wait for help",
                "Note the time symptoms started"
            ],
            'URGENT': [
                "Schedule doctor appointment within 24-48 hours",
                "Monitor symptoms closely",
                "Keep record of symptoms",
                "Seek immediate care if symptoms worsen"
            ],
            'SELF_CARE': [
                "Rest and stay hydrated",
                "Monitor symptoms for 24-48 hours",
                "Use over-the-counter remedies if needed",
                "Consult doctor if symptoms persist"
            ]
        }
        
        state['actions'] = action_map.get(state['triage_level'], action_map['SELF_CARE'])
        return state
    
    def _load_templates(self):
        """Load template fallbacks"""
        self.templates = {
            'EMERGENCY': {
                'message': "⚠️ Your symptoms require immediate medical attention. Please call emergency services (108) or go to the nearest hospital right away.",
                'tone': 'urgent'
            },
            'URGENT': {
                'message': "🏥 Based on your symptoms, you should consult a healthcare professional within 24-48 hours. Please schedule an appointment with your doctor.",
                'tone': 'firm'
            },
            'SELF_CARE': {
                'message': "🏡 Your symptoms appear manageable at home. Get plenty of rest, stay hydrated, and monitor your condition. Seek medical help if symptoms worsen.",
                'tone': 'reassuring'
            }
        }
    
    def _get_template_response(self, state: TriageState) -> str:
        """Get template-based response as fallback"""
        template = self.templates.get(state['triage_level'], self.templates['SELF_CARE'])
        return template['message']
    
    def generate_explanation(
        self,
        user_input: str,
        extracted_symptoms: List[str],
        severity: str,
        duration: str,
        triage_level: str,
        confidence: float,
        language: str = "en"
    ) -> Dict:
        """
        Generate explanation for triage decision
        
        Args:
            user_input: Original user input
            extracted_symptoms: List of extracted symptoms
            severity: Severity level
            duration: Duration of symptoms
            triage_level: Triage classification (EMERGENCY/URGENT/SELF_CARE)
            confidence: Confidence score
            language: Language code
            
        Returns:
            Dictionary with spoken_response, tone, and actions
        """
        
        # Initialize state
        state: TriageState = {
            'user_input': user_input,
            'extracted_symptoms': extracted_symptoms or [],
            'severity': severity or 'unknown',
            'duration': duration or 'unknown',
            'triage_level': triage_level,
            'confidence': confidence,
            'language': language,
            'spoken_response': '',
            'tone': 'firm',
            'actions': []
        }
        
        # Use LLM workflow if available
        if self.use_llm:
            try:
                result = self.workflow.invoke(state)
                return {
                    'spoken_response': result['spoken_response'],
                    'tone': result['tone'],
                    'actions': result['actions']
                }
            except Exception as e:
                print(f"⚠️ LLM workflow error: {e}, using template")
        
        # Template fallback
        template = self.templates.get(triage_level, self.templates['SELF_CARE'])
        actions = self._suggest_actions_node(state)['actions']
        
        return {
            'spoken_response': template['message'],
            'tone': template['tone'],
            'actions': actions
        }


# Singleton instance
_explanation_layer = None

def get_explanation_layer(api_key: Optional[str] = None) -> ExplanationLayer:
    """Get or create singleton explanation layer"""
    global _explanation_layer
    if _explanation_layer is None:
        _explanation_layer = ExplanationLayer(api_key=api_key)
    return _explanation_layer


def generate_explanation(
    user_input: str,
    extracted_symptoms: List[str],
    severity: str,
    duration: str,
    triage_level: str,
    confidence: float,
    language: str = "en"
) -> Dict:
    """Convenience function to generate explanation"""
    layer = get_explanation_layer()
    return layer.generate_explanation(
        user_input, extracted_symptoms, severity, duration,
        triage_level, confidence, language
    )


# Test
if __name__ == "__main__":
    print("="*70)
    print("LLM-Based Explanation Layer Test")
    print("="*70)
    
    # Test cases
    test_cases = [
        {
            'user_input': "I have severe chest pain and difficulty breathing",
            'symptoms': ["chest pain", "difficulty breathing"],
            'severity': "severe",
            'duration': "30 minutes",
            'triage': "EMERGENCY",
            'confidence': 0.95
        },
        {
            'user_input': "I have fever and headache for 3 days",
            'symptoms': ["fever", "headache"],
            'severity': "moderate",
            'duration': "3 days",
            'triage': "URGENT",
            'confidence': 0.85
        }
    ]
    
    layer = ExplanationLayer()
    
    for i, test in enumerate(test_cases, 1):
        print(f"\nTest {i}: {test['triage']}")
        print("-"*70)
        
        result = layer.generate_explanation(
            test['user_input'],
            test['symptoms'],
            test['severity'],
            test['duration'],
            test['triage'],
            test['confidence']
        )
        
        print(f"Response: {result['spoken_response']}")
        print(f"Tone: {result['tone']}")
        print(f"Actions: {result['actions'][:2]}")
