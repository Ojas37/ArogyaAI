"""
Healthcare Triage Pipeline Orchestrator

COMPLETE END-TO-END FLOW:
User Input → Language Detection → Translation → Medical NLP → 
Dialogue State → Triage → Guidance → Translation → JSON Response

SAFETY CONSTRAINTS (ENFORCED):
1. NO disease diagnosis
2. NO medicine prescription
3. NO triage modification after classification
4. Translation = language conversion only
5. Emergency ALWAYS overrides
6. Always valid JSON response
"""

import json
from typing import Dict, Optional, List
import warnings
warnings.filterwarnings('ignore')

from conversational_graph import ConversationalTriageGraph


class HealthcareTriagePipeline:
    """Conversational healthcare triage orchestrator using LangGraph."""
    
    def __init__(self, models_dir: str = "."):
        """
        Initialize all pipeline components
        
        Args:
            models_dir: Directory containing model files
        """
        print("🏥 Initializing Conversational Triage Pipeline...")
        print("=" * 70)
        self.models_dir = models_dir
        self.graph = ConversationalTriageGraph(models_dir=models_dir)
        print("✅ Conversational pipeline initialized")
        print("=" * 70)
    
    def process_message(
        self,
        user_input: str,
        session_id: str,
        force_language: Optional[str] = None
    ) -> Dict:
        """Process a user message through the conversational LangGraph pipeline."""
        try:
            return self.graph.run(
                user_input=user_input,
                session_id=session_id,
                force_language=force_language
            )
        except Exception as e:
            print(f"\n❌ Pipeline error: {e}")
            return {
                "error": True,
                "message": str(e)
            }
    
    def _create_safe_fallback(self, triage_level: str) -> str:
        """Create a safe fallback response"""
        fallback_map = {
            'EMERGENCY': "Your symptoms require immediate medical attention. Please call emergency services or go to the nearest hospital.",
            'URGENT': "Based on your symptoms, you should consult a healthcare professional within 24-48 hours.",
            'SELF_CARE': "You may be able to manage these symptoms at home. Monitor your condition and seek medical help if symptoms worsen."
        }
        return fallback_map.get(triage_level, "Please consult a healthcare professional for proper evaluation.")
    
    def _create_error_response(self, error_message: str, language: str) -> Dict:
        """Create error response"""
        return {
            "language": language,
            "error": True,
            "message": error_message,
            "spoken_response": "I apologize, but I encountered an issue processing your request. Please try again or consult a healthcare professional.",
            "tone": "firm"
        }
    
    def reset_session(self):
        """Reset session state"""
        self.session_language = None
        self.conversation_history = []
        print("✅ Session reset")


# Singleton instance
_pipeline = None

def get_pipeline(models_dir: str = ".") -> HealthcareTriagePipeline:
    """Get or create singleton pipeline instance"""
    global _pipeline
    if _pipeline is None:
        _pipeline = HealthcareTriagePipeline(models_dir=models_dir)
    return _pipeline


# Convenience function for quick processing
def process_user_message(message: str, language: Optional[str] = None) -> Dict:
    """
    Process user message through complete pipeline
    
    Args:
        message: User's message
        language: Optional language code (will auto-detect if not provided)
        
    Returns:
        Complete JSON response
    """
    pipeline = get_pipeline()
    return pipeline.process_message(message, force_language=language)


# Usage example
if __name__ == "__main__":
    print("="*70)
    print("HEALTHCARE TRIAGE PIPELINE - COMPLETE SYSTEM TEST")
    print("="*70)
    
    # Initialize pipeline
    pipeline = HealthcareTriagePipeline()
    
    # Test cases
    test_messages = [
        "I have severe chest pain and difficulty breathing for 30 minutes",
        "मुझे 2 दिन से बुखार और सिरदर्द है",
        "Mild cough since this morning",
    ]
    
    for i, message in enumerate(test_messages, 1):
        print(f"\n{'#'*70}")
        print(f"TEST CASE {i}")
        print(f"{'#'*70}")
        
        result = pipeline.process_message(message)
        
        print(f"\nFINAL RESPONSE:")
        print(json.dumps(result, indent=2, ensure_ascii=False))
        
        pipeline.reset_session()
