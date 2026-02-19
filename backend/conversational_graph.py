"""
LangGraph-based conversational pipeline for healthcare triage.

The LLM drives conversation flow and follow-up questions,
while ML models remain authoritative for intent, extraction, and triage.
"""

from __future__ import annotations

import json
import os
import re
from typing import Dict, List, Optional, TypedDict

from dotenv import load_dotenv
from langgraph.graph import StateGraph, END

from language_detector import LanguageDetector
from translation import TranslationService
from extraction_layer import MedicalSymptomExtractor
from intent_classifier import IntentClassifier
from triage_engine import TriageEngine
from explanation_layer import ExplanationLayer
from utils.validators import SafetyValidator

try:
    from langchain_openai import ChatOpenAI
    from langchain_core.messages import SystemMessage, HumanMessage
    LANGCHAIN_OPENROUTER_AVAILABLE = True
except ImportError:
    LANGCHAIN_OPENROUTER_AVAILABLE = False


class ConversationState(TypedDict, total=False):
    session_id: str
    user_input: str
    language: str
    lang_confidence: float
    english_text: str
    conversation_intent: str
    conversation_action: str
    response_type: str
    response_text: str
    mode: str  # "chat" or "final_triage"
    extracted_symptoms: List[str]
    severity: str
    duration: str
    body_parts: List[str]
    needs_followup: bool
    missing_fields: List[str]
    emergency_override: bool  # Force immediate triage for red flags
    sufficient_information: bool  # DST decision
    triage_level: str
    confidence: float
    actions: List[str]
    error: str


class ConversationalTriageGraph:
    """LangGraph-based conversational flow for the triage system."""

    def __init__(self, models_dir: str = "."):
        # Load environment variables from .env file
        load_dotenv()
        
        self.models_dir = models_dir
        self.validator = SafetyValidator()

        self.language_detector = None
        self.translator = None
        self.symptom_extractor = None
        self.intent_classifier = None
        self.triage_engine = None
        self.explanation_layer = None

        self.llm = self._init_openrouter_llm()
        self.graph = self._build_graph()

        # Session memory
        self.sessions: Dict[str, ConversationState] = {}
        self.conversation_history: Dict[str, List[Dict[str, str]]] = {}
        
        # Pre-load ALL heavy models to avoid first-request delays
        print("🔄 Pre-loading all models for instant response...")
        self._lazy_load_symptom_extractor()  # NER model (~3-5 seconds)
        self._lazy_load_intent_classifier()   # Intent classifier (~2-3 seconds)
        self._lazy_load_triage_engine()       # Triage XGBoost model (~1 second)
        print("✅ All models pre-loaded - ready for instant responses!")

    def _init_openrouter_llm(self):
        if not LANGCHAIN_OPENROUTER_AVAILABLE:
            raise RuntimeError("langchain-openai is not installed. Please install it to use Groq.")

        api_key = os.getenv("GROQ_API_KEY")
        if not api_key:
            raise RuntimeError("GROQ_API_KEY is not set. Please set it to use the conversational LLM.")

        model_name = os.getenv("GROQ_MODEL", "llama-3.1-8b-instant")
        return ChatOpenAI(
            model=model_name,
            api_key=api_key,
            base_url="https://api.groq.com/openai/v1",
            temperature=0.2,
            max_tokens=150,  # Reduced for faster responses
            timeout=10  # Timeout individual LLM calls
        )

    def _lazy_load_language_detector(self):
        if self.language_detector is None:
            self.language_detector = LanguageDetector()

    def _lazy_load_translator(self):
        if self.translator is None:
            self.translator = TranslationService(backend="auto")

    def _lazy_load_symptom_extractor(self):
        if self.symptom_extractor is None:
            self.symptom_extractor = MedicalSymptomExtractor()

    def _lazy_load_intent_classifier(self):
        if self.intent_classifier is None:
            self.intent_classifier = IntentClassifier()

    def _lazy_load_triage_engine(self):
        if self.triage_engine is None:
            self.triage_engine = TriageEngine(models_dir=self.models_dir)

    def _lazy_load_explanation_layer(self):
        if self.explanation_layer is None:
            self.explanation_layer = ExplanationLayer()

    def _detect_red_flags(self, symptoms: List[str], text: str) -> bool:
        """
        Detect emergency red-flag symptoms that require immediate triage.
        Returns True if ANY emergency symptom is detected.
        """
        RED_FLAGS = [
            # Cardiovascular emergencies
            "chest pain", "chest pressure", "chest tightness", "heart attack",
            # Respiratory emergencies
            "difficulty breathing", "can't breathe", "shortness of breath", "breathlessness",
            "not able to breathe", "unable to breathe", "gasping", "choking",
            # Neurological emergencies
            "stroke", "seizure", "convulsion", "unconscious", "unresponsive",
            "severe headache", "sudden weakness", "facial drooping", "slurred speech",
            # Bleeding/Trauma
            "severe bleeding", "heavy bleeding", "blood loss", "hemorrhage",
            "major injury", "severe trauma",
            # Other critical
            "severe pain", "unbearable pain", "excruciating pain",
            "going to die", "dying", "can't move",
            "poisoning", "overdose", "allergic reaction", "anaphylaxis"
        ]
        
        # Check in raw text (case-insensitive)
        text_lower = text.lower()
        for flag in RED_FLAGS:
            if flag in text_lower:
                print(f"🚨 RED FLAG DETECTED: '{flag}' in user input")
                return True
        
        # Check in extracted symptoms (must be exact phrase match)
        for symptom in symptoms:
            symptom_lower = symptom.lower()
            for flag in RED_FLAGS:
                # Only check if red flag is IN the symptom, not vice versa
                # This prevents "pain" from matching "chest pain"
                if flag in symptom_lower:
                    print(f"🚨 RED FLAG DETECTED: '{flag}' in extracted symptom '{symptom}'")
                    return True
        
        return False

    def _assess_emergency_by_context(self, symptoms: List[str], severity: str, duration: str) -> dict:
        """
        Use LLM reasoning to determine if symptoms + duration + severity warrant emergency.
        This catches cases like 'fever for 3 months' that simple keyword detection misses.
        
        Returns: {"is_emergency": bool, "reason": str}
        """
        if not symptoms or (not severity and not duration):
            return {"is_emergency": False, "reason": ""}
        
        # Convert severity number to text if needed
        severity_text = severity
        if severity and severity.isdigit():
            sev_num = int(severity)
            if sev_num <= 3:
                severity_text = f"mild ({severity}/10)"
            elif sev_num <= 7:
                severity_text = f"moderate ({severity}/10)"
            else:
                severity_text = f"severe ({severity}/10)"
        
        print(f"🔍 EMERGENCY ASSESSMENT: symptoms={symptoms}, severity={severity_text}, duration={duration}")
        
        system_prompt = (
            "You are an AI medical triage assistant with expertise in emergency medicine. "
            "Analyze if symptoms require IMMEDIATE emergency medical care (call emergency services).\n\n"
            "CRITICAL DECISION RULES FOR EMERGENCY:\n"
            "1. ANY symptom lasting >4-6 weeks (chronic) = EMERGENCY (requires diagnostic workup)\n"
            "2. Fever >3-4 weeks = EMERGENCY (TB, cancer, autoimmune disease)\n"
            "3. High severity (9-10/10) with ANY concerning symptom = EMERGENCY\n"
            "4. Severe symptoms (8/10) lasting >1 week = URGENT, possibly EMERGENCY\n\n"
            "NON-EMERGENCY CASES:\n"
            "- Fever with severity 6-7/10 for <7 days = NOT EMERGENCY (URGENT or SELF_CARE)\n"
            "- Common cold/flu symptoms <7 days = NOT EMERGENCY\n"
            "- Mild to moderate pain (1-7/10) for <2 weeks = NOT EMERGENCY\n"
            "- Moderate fever (severity 5-7/10) for 1-3 days = NOT EMERGENCY\n\n"
            "BE ACCURATE: Most common illnesses are NOT emergencies. Only classify as EMERGENCY if:\n"
            "- Life-threatening symptoms (chest pain, breathing difficulty, severe bleeding)\n"
            "- Very high severity (9-10/10)\n"
            "- Chronic duration (>4 weeks)\n\n"
            "Respond ONLY with valid JSON: {\"is_emergency\": true/false, \"reason\": \"brief medical explanation\"}"
        )
        
        user_prompt = {
            "symptoms": symptoms,
            "duration": duration if duration else "not specified",
            "severity": severity if severity else "not specified",
            "question": "Does this require EMERGENCY medical attention (immediate hospital evaluation)?"
        }
        
        try:
            response = self.llm.invoke([
                SystemMessage(content=system_prompt),
                HumanMessage(content=json.dumps(user_prompt))
            ])
            
            parsed = self._parse_json_response(response.content)
            is_emergency = parsed.get("is_emergency", False)
            reason = parsed.get("reason", "")
            
            print(f"🧠 LLM EMERGENCY ASSESSMENT: is_emergency={is_emergency}, reason='{reason}'")
            return {"is_emergency": is_emergency, "reason": reason}
            
        except Exception as e:
            print(f"⚠️ LLM emergency assessment failed: {e}")
            return {"is_emergency": False, "reason": ""}

    def _build_graph(self):
        graph = StateGraph(ConversationState)

        graph.add_node("detect_language", self._detect_language_node)
        graph.add_node("translate_to_english", self._translate_to_english_node)
        graph.add_node("conversational_llm", self._conversational_llm_node)
        graph.add_node("symptom_extraction", self._symptom_extraction_node)
        graph.add_node("dst_decision", self._dst_decision_node)
        graph.add_node("followup_question", self._followup_question_node)
        graph.add_node("triage", self._triage_node)
        graph.add_node("explanation", self._explanation_node)
        graph.add_node("translate_back", self._translate_back_node)

        graph.set_entry_point("detect_language")
        graph.add_edge("detect_language", "translate_to_english")
        graph.add_edge("translate_to_english", "conversational_llm")

        graph.add_conditional_edges(
            "conversational_llm",
            self._route_after_conversational_llm,
            {
                "respond": "translate_back",
                "medical": "symptom_extraction",
            },
        )

        graph.add_edge("symptom_extraction", "dst_decision")

        graph.add_conditional_edges(
            "dst_decision",
            self._route_after_dst,
            {
                "followup": "followup_question",
                "triage": "triage",
            },
        )

        graph.add_edge("followup_question", "translate_back")
        graph.add_edge("triage", "explanation")
        graph.add_edge("explanation", "translate_back")
        graph.add_edge("translate_back", END)

        return graph.compile()

    def _detect_language_node(self, state: ConversationState) -> ConversationState:
        user_input = state.get("user_input", "")
        force_language = state.get("language")
        if force_language:
            state["language"] = force_language
            state["lang_confidence"] = 1.0
            return state

        self._lazy_load_language_detector()
        result = self.language_detector.detect(user_input)
        state["language"] = result.get("language", "en")
        state["lang_confidence"] = result.get("confidence", 0.0)

        is_valid, error = self.validator.validate_language_confidence(
            state["language"], state["lang_confidence"]
        )
        if not is_valid:
            state["error"] = error
        return state

    def _translate_to_english_node(self, state: ConversationState) -> ConversationState:
        if state.get("error"):
            return state

        self._lazy_load_translator()
        language = state.get("language", "en")
        user_input = state.get("user_input", "")
        state["english_text"] = self.translator.translate_to_english(user_input, language)
        return state

    def _conversational_llm_node(self, state: ConversationState) -> ConversationState:
        if state.get("error"):
            return state

        history = self.conversation_history.get(state.get("session_id", ""), [])
        known_symptoms = state.get("extracted_symptoms", [])
        known_severity = state.get("severity", "")
        known_duration = state.get("duration", "")

        system_prompt = (
            "You are a medical conversational assistant. You can greet, ask clarifying questions, "
            "and guide the user, but you must NEVER diagnose, prescribe medicine, or override triage. "
            "Return JSON only, no markdown."
        )

        user_prompt = {
            "user_input": state.get("english_text", ""),
            "conversation_history": history[-6:],
            "known_symptoms": known_symptoms,
            "known_severity": known_severity,
            "known_duration": known_duration,
            "allowed_intents": ["greeting", "symptom", "followup", "unrelated"],
            "actions": ["respond", "continue_medical"],
            "output_schema": {
                "intent": "greeting | symptom | followup | unrelated",
                "action": "respond | continue_medical",
                "assistant_message": "string"
            },
            "rules": [
                "If greeting: respond warmly and ask for symptoms.",
                "If unrelated: respond briefly and redirect to symptoms.",
                "If symptom or followup: set action to continue_medical."
            ]
        }

        response = self.llm.invoke(
            [
                SystemMessage(content=system_prompt),
                HumanMessage(content=json.dumps(user_prompt))
            ]
        )

        parsed = self._parse_json_response(response.content)
        intent = parsed.get("intent", "symptom")
        action = parsed.get("action", "continue_medical")
        assistant_message = parsed.get("assistant_message", "")

        print(f"🤖 CONVERSATIONAL LLM: intent={intent}, action={action}")
        print(f"   Message: '{assistant_message[:100] if assistant_message else 'None'}...'")

        state["conversation_intent"] = intent
        state["conversation_action"] = action

        if action == "respond":
            state["response_type"] = "informational"
            state["response_text"] = assistant_message
            state["mode"] = "chat"
            print(f"✅ RESPONDING TO USER (greeting/unrelated) - will not proceed to medical extraction")

        return state

    def _symptom_extraction_node(self, state: ConversationState) -> ConversationState:
        if state.get("error"):
            return state

        self._lazy_load_symptom_extractor()
        self._lazy_load_intent_classifier()

        english_text = state.get("english_text", "")
        history = self.conversation_history.get(state.get("session_id", ""), [])
        
        # 🔧 FIX: Only check intent for non-conversational inputs
        # If we have conversation history, skip intent check to allow extraction of follow-up answers
        if len(history) == 0 or len(english_text.split()) > 5:
            # Only classify intent for initial messages or long messages
            intent_result = self.intent_classifier.classify(english_text)
            if intent_result.get("intent") in ["greeting", "thank_you", "general_query"]:
                state["response_type"] = "informational"
                state["response_text"] = self._redirect_to_symptoms(state)
                state["mode"] = "chat"
                return state

        # Use LLM to extract info from context if user gives short answers
        print(f"🔍 DEBUG: Input='{english_text}', WordCount={len(english_text.split())}, HistoryLen={len(history)}")
        
        # Variable to track if we extracted anything from context
        context_extraction_successful = False
        
        if len(english_text.split()) <= 5 and len(history) > 0:
            # Short answer - use LLM to interpret in context
            print(f"🤖 DEBUG: Using context-aware extraction...")
            extracted_context = self._extract_with_context(english_text, history, state)
            print(f"📊 DEBUG: Extracted context: {extracted_context}")
            if extracted_context:
                # Update state with LLM-extracted info
                if extracted_context.get("severity") and extracted_context["severity"].strip():
                    state["severity"] = extracted_context["severity"]
                    context_extraction_successful = True
                    print(f"✅ DEBUG: Set severity to '{state['severity']}'")
                if extracted_context.get("duration") and extracted_context["duration"].strip():
                    state["duration"] = extracted_context["duration"]
                    context_extraction_successful = True
                    print(f"✅ DEBUG: Set duration to '{state['duration']}'")
                if extracted_context.get("symptoms") and len(extracted_context["symptoms"]) > 0:
                    symptoms = state.get("extracted_symptoms", [])
                    for symptom in extracted_context["symptoms"]:
                        if symptom not in symptoms:
                            symptoms.append(symptom)
                    state["extracted_symptoms"] = symptoms
                    context_extraction_successful = True
                    print(f"✅ DEBUG: Updated symptoms to {symptoms}")
        
        # If context extraction didn't find anything useful, run NER model
        if not context_extraction_successful:
            print(f"🔬 DEBUG: Running NER model extraction...")
            extracted = self.symptom_extractor.extract(english_text)

            # Merge with existing session data
            symptoms = state.get("extracted_symptoms", [])
            for symptom in extracted.get("symptoms", []):
                if symptom not in symptoms:
                    symptoms.append(symptom)

            state["extracted_symptoms"] = symptoms
            if extracted.get("severity") and not state.get("severity"):
                state["severity"] = extracted.get("severity")
            if extracted.get("duration") and not state.get("duration"):
                state["duration"] = extracted.get("duration")

            state["body_parts"] = list(set(state.get("body_parts", []) + extracted.get("body_parts", [])))
        
        # ✅ CRITICAL: Detect red-flag emergency symptoms
        has_red_flags = self._detect_red_flags(
            state.get("extracted_symptoms", []),
            english_text
        )
        
        if has_red_flags:
            state["emergency_override"] = True
            print("🚨 EMERGENCY OVERRIDE ACTIVATED - Will skip follow-up questions")
        
        return state

    def _extract_with_context(self, user_input: str, history: List[Dict], state: ConversationState) -> Optional[Dict]:
        """Use LLM to extract info from short answers using conversation context."""
        try:
            last_assistant_msg = ""
            for msg in reversed(history):
                if msg.get("role") == "assistant":
                    last_assistant_msg = msg.get("content", "")
                    break

            print(f"🔎 DEBUG: Last bot question was: '{last_assistant_msg}'")

            system_prompt = (
                "You are a medical data extractor. Extract information from the user's short response based on what the assistant just asked. "
                "Return ONLY valid JSON with these fields: {\"severity\": \"mild/moderate/severe\", \"duration\": \"X days/weeks/months\", \"symptoms\": []}. "
                "Rules: "
                "- If bot asked about DURATION and user gave time period: extract duration exactly (e.g., '1 day', '3 days', '2 weeks', 3 months') "
                "- If bot asked about SEVERITY and user gave a number 1-10: 1-3=mild, 4-7=moderate, 8-10=severe "
                "- If user said 'normal' or 'okay' or 'fine': interpret as {\"severity\": \"mild\"} "
                "- If user said 'extreme' or 'unbearable' or 'worst': interpret as {\"severity\": \"severe\"} "
                "- If user said 'bad' or 'painful' or 'uncomfortable': interpret as {\"severity\": \"moderate\"} "
                "- If the answer doesn't provide new medical info, return empty fields. "
                "- Never add symptoms unless explicitly mentioned. "
                "Examples: "
                "Bot: 'How long have you been experiencing these symptoms?' User: '1 day' → {\"severity\": \"\", \"duration\": \"1 day\", \"symptoms\": []} "
                "Bot: 'How long have you been experiencing these symptoms?' User: '3 days' → {\"severity\": \"\", \"duration\": \"3 days\", \"symptoms\": []} "
                "Bot: 'How long have you been experiencing these symptoms?' User: '2 weeks' → {\"severity\": \"\", \"duration\": \"2 weeks\", \"symptoms\": []} "
                "Bot: 'On a scale of 1-10, how severe?' User: '8' → {\"severity\": \"severe\", \"duration\": \"\", \"symptoms\": []} "
                "Bot: 'On a scale of 1-10, how severe?' User: 'normal' → {\"severity\": \"mild\", \"duration\": \"\", \"symptoms\": []} "
                "Bot: 'On a scale of 1-10, how severe?' User: 'very painful' → {\"severity\": \"severe\", \"duration\": \"\", \"symptoms\": []} "
            )

            user_prompt = {
                "conversation_context": f"Bot asked: {last_assistant_msg}",
                "user_response": user_input,
                "current_symptoms": state.get("extracted_symptoms", []),
                "current_severity": state.get("severity", "unknown"),
                "current_duration": state.get("duration", "unknown"),
                "instruction": "What medical info can you extract from this response in this context?"
            }

            response = self.llm.invoke([
                SystemMessage(content=system_prompt),
                HumanMessage(content=json.dumps(user_prompt))
            ])

            parsed = self._parse_json_response(response.content)
            print(f"🧠 DEBUG: LLM raw response: {response.content}")
            print(f"📋 DEBUG: Parsed JSON: {parsed}")
            
            # 🔧 ENHANCED DURATION EXTRACTION: Check user input with multiple patterns
            print(f"🔍 DEBUG: Checking for duration in user_input: '{user_input}'")
            
            # Pattern 1: Full duration like "1 day", "3 weeks", etc.
            duration_match = re.search(r'(\d+)\s*(day|days|week|weeks|month|months|year|years|din|hafte|mahine)', user_input.lower())
            if duration_match:
                number = duration_match.group(1)
                unit = duration_match.group(2)
                # Normalize unit to English
                unit_map = {'din': 'days', 'hafte': 'weeks', 'mahine': 'months'}
                unit = unit_map.get(unit, unit)
                if not unit.endswith('s') and int(number) > 1:
                    unit = unit + 's'  # pluralize
                parsed["duration"] = f"{number} {unit}"
                print(f"✅ DEBUG: Extracted duration from input (pattern 1): '{parsed['duration']}'")
            
            # Pattern 2: Just a number when bot asked "how long"
            elif 'how long' in last_assistant_msg.lower() and user_input.strip().isdigit():
                days = int(user_input.strip())
                if 1 <= days <= 365:
                    parsed["duration"] = f"{days} day" if days == 1 else f"{days} days"
                    print(f"✅ DEBUG: Extracted duration from number (pattern 2): '{parsed['duration']}'")
            
            # Pattern 3: LLM returned duration in parsed response
            elif parsed.get("duration") and parsed["duration"].strip():
                print(f"✅ DEBUG: LLM extracted duration: '{parsed['duration']}'")
            
            #Map numeric severity to text  
            if parsed.get("severity") and parsed["severity"].strip():
                sev = parsed["severity"].strip()
                print(f"🎯 DEBUG: Processing severity: '{sev}'")
                if sev.isdigit():
                    sev_num = int(sev)
                    # If bot asked "how long" and user gave number, treat as duration not severity
                    if 'how long' in last_assistant_msg.lower() and 1 <= sev_num <= 365:
                        print(f"⚠️ DEBUG: Bot asked 'how long', user gave number {sev_num} - treating as days, not severity!")
                        parsed["duration"] = f"{sev_num} day" if sev_num == 1 else f"{sev_num} days"
                        parsed["severity"] = ""  # Clear severity
                    else:
                        # Normal severity mapping
                        if sev_num <= 3:
                            parsed["severity"] = "mild"
                        elif sev_num <= 7:
                            parsed["severity"] = "moderate"
                        else:
                            parsed["severity"] = "severe"
                        print(f"📈 DEBUG: Mapped {sev_num} -> {parsed['severity']}")
            
            return parsed if parsed else None
        except Exception as e:
            print(f"❌ DEBUG: Context extraction failed: {e}")
            return None

    def _dst_decision_node(self, state: ConversationState) -> ConversationState:
        if state.get("error"):
            return state

        self._lazy_load_triage_engine()

        # Check if emergency override is active
        emergency_override = state.get("emergency_override", False)
        
        missing = []
        if not state.get("extracted_symptoms"):
            missing.append("symptoms")
        if not state.get("duration"):
            missing.append("duration")
        if not state.get("severity"):
            missing.append("severity")

        # ✅ DECISION LOGIC: When to trigger triage?
        # 1. Emergency override (red flags) -> ALWAYS trigger triage
        # 2. Have symptoms + (severity OR duration) -> SUFFICIENT for triage
        # 3. DST model says sufficient -> trigger triage
        
        has_symptoms = bool(state.get("extracted_symptoms"))
        has_severity = bool(state.get("severity"))
        has_duration = bool(state.get("duration"))
        
        # ✅ SIMPLIFIED: Require symptoms, severity, AND duration
        # No complex DST logic - just simple checks
        sufficient_for_triage = has_symptoms and has_severity and has_duration
        
        print(f"🔍 DST CHECK: symptoms={has_symptoms}, severity={has_severity}, duration={has_duration}")
        print(f"   → sufficient_for_triage={sufficient_for_triage}")
        
        # ✅ FINAL DECISION (SIMPLE LOGIC)
        if emergency_override:
            # Emergency: trigger triage immediately
            state["sufficient_information"] = True
            state["needs_followup"] = False
            print("🚨 EMERGENCY: Triggering immediate triage")
        elif sufficient_for_triage:
            # Have all required info: trigger triage
            state["sufficient_information"] = True
            state["needs_followup"] = False
            print("✅ SUFFICIENT INFO: Triggering triage")
        else:
            # Need more info
            state["sufficient_information"] = False
            state["needs_followup"] = True
            print(f"⏳ NEED MORE INFO: Missing {missing}")
        
        state["missing_fields"] = missing
        return state

    def _followup_question_node(self, state: ConversationState) -> ConversationState:
        if state.get("error"):
            return state

        # Standard LLM-based follow-up
        system_prompt = (
            "You are a healthcare assistant. Ask ONE simple, direct follow-up question. "
            "YOU MUST USE THESE EXACT TEMPLATES - DO NOT MODIFY THEM: "
            "- For severity: 'On a scale of 1-10, where 1 is mild and 10 is severe, how bad is your discomfort?' "
            "- For duration: 'How long have you been experiencing these symptoms?' "
            "DO NOT ask about temperature readings. DO NOT ask yes/no questions. "
            "ALWAYS use the 1-10 scale format for severity. NEVER deviate from these templates."
        )

        # Check what just got updated
        history = self.conversation_history.get(state.get("session_id", ""), [])
        just_updated = []
        if state.get("severity") and len(history) >= 2:
            # Check if severity was just added
            just_updated.append(f"severity ({state.get('severity')})")
        
        user_prompt = {
            "known_symptoms": state.get("extracted_symptoms", []),
            "known_severity": state.get("severity", ""),
            "known_duration": state.get("duration", ""),
            "missing_fields": state.get("missing_fields", []),
            "just_provided": just_updated,
            "instruction": (
                "Ask ONE question about the first missing field. "
                "Use EXACT template: "
                "If asking for severity: 'On a scale of 1-10, where 1 is mild and 10 is severe, how bad is your discomfort?' "
                "If asking for duration: 'How long have you been experiencing these symptoms?' "
                "COPY THE TEMPLATE EXACTLY. Do NOT modify it. Do NOT ask about specific symptoms."
            ),
            "output": "Return ONLY the question text (exact template), no JSON, no explanation."
        }

        response = self.llm.invoke(
            [
                SystemMessage(content=system_prompt),
                HumanMessage(content=json.dumps(user_prompt))
            ]
        )

        question = response.content.strip().strip('"')
        print(f"❓ FOLLOWUP QUESTION GENERATED: '{question}'")
        state["response_type"] = "followup"
        state["response_text"] = question
        state["mode"] = "chat"  # Still in conversation mode
        print(f"🔄 FOLLOWUP NODE COMPLETE - mode={state['mode']}, response_type={state['response_type']}")
        return state

    def _triage_node(self, state: ConversationState) -> ConversationState:
        if state.get("error"):
            return state

        self._lazy_load_triage_engine()
        extracted = {
            "symptoms": state.get("extracted_symptoms", []),
            "severity": state.get("severity", ""),
            "duration": state.get("duration", ""),
            "body_parts": state.get("body_parts", [])
        }

        # Check if red flag detection already set emergency override
        if state.get("emergency_override"):
            print("🚨 TRIAGE NODE: Emergency override active - forcing EMERGENCY classification")
            state["triage_level"] = "EMERGENCY"
            state["confidence"] = 1.0
        else:
            # ✅ RULE-BASED: Check for obviously chronic durations (>1 month)
            duration_str = state.get("duration", "").lower()
            chronic_detected = False
            chronic_reason = ""
            
            if duration_str:
                # Parse duration to detect chronic cases
                if any(x in duration_str for x in ["month", "months", "year", "years"]):
                    # Extract number
                    numbers = re.findall(r'\d+', duration_str)
                    if numbers:
                        num = int(numbers[0])
                        if "month" in duration_str and num >= 1:
                            chronic_detected = True
                            chronic_reason = f"Persistent symptoms for {num} month(s) require immediate medical investigation to rule out serious underlying conditions."
                        elif "year" in duration_str:
                            chronic_detected = True
                            chronic_reason = f"Chronic symptoms lasting {num} year(s) require urgent medical evaluation."
                elif any(x in duration_str for x in ["week", "weeks"]):
                    numbers = re.findall(r'\d+', duration_str)
                    if numbers and int(numbers[0]) >= 4:
                        chronic_detected = True
                        chronic_reason = f"Symptoms persisting for {numbers[0]} weeks warrant immediate medical consultation."
            
            if chronic_detected:
                print(f"🚨 CHRONIC DURATION DETECTED: {chronic_reason}")
                state["triage_level"] = "EMERGENCY"
                state["confidence"] = 0.95
                state["emergency_reason"] = chronic_reason
            else:
                # ✅ SKIP LLM for clearly non-emergency cases (common symptoms + short duration)
                common_symptoms = ["fever", "cough", "headache", "cold", "flu", "sore throat", "runny nose"]
                has_common_symptom = any(sym.lower() in common_symptoms for sym in state.get("extracted_symptoms", []))
                
                # Parse duration to check if it's short
                duration_str = state.get("duration", "").lower()
                is_short_duration = False
                if duration_str:
                    # Check for days/hours
                    if any(x in duration_str for x in ["day", "days", "hour", "hours"]):
                        # Extract number
                        numbers = re.findall(r'\d+', duration_str)
                        if numbers:
                            num = int(numbers[0])
                            if ("day" in duration_str and num <= 7) or "hour" in duration_str:
                                is_short_duration = True
                
                # Parse severity to check if it's moderate or mild
                severity_str = state.get("severity", "").lower()
                is_moderate_or_mild = False
                if severity_str:
                    if severity_str in ["mild", "moderate"]:
                        is_moderate_or_mild = True
                    elif severity_str.isdigit():
                        sev_num = int(severity_str)
                        if sev_num <= 7:
                            is_moderate_or_mild = True
                
                # Skip LLM assessment for common symptoms + short duration + moderate/mild severity
                skip_llm = has_common_symptom and is_short_duration and is_moderate_or_mild
                
                if skip_llm:
                    print(f"✅ SKIPPING LLM: Common symptom ({state.get('extracted_symptoms')}) + short duration ({duration_str}) + moderate severity ({severity_str}) = NOT EMERGENCY")
                    # Let ML model handle it
                    llm_assessment = {"is_emergency": False, "reason": ""}
                else:
                    # ✅ LLM ASSESSMENT: Use LLM to assess if duration/severity/symptoms combination is emergency
                    llm_assessment = self._assess_emergency_by_context(
                        symptoms=state.get("extracted_symptoms", []),
                        severity=state.get("severity", ""),
                        duration=state.get("duration", "")
                    )
                
                if llm_assessment.get("is_emergency"):
                    print(f"🚨 LLM OVERRIDE: Emergency detected - {llm_assessment.get('reason')}")
                    state["triage_level"] = "EMERGENCY"
                    state["confidence"] = 0.95
                    state["emergency_reason"] = llm_assessment.get("reason", "")
                else:
                    # Check for emergency override first
                    emergency_override = self.triage_engine.override_emergency_symptoms(extracted)
                    if emergency_override:
                        print(f"🚨 TRIAGE ENGINE: Emergency override - {emergency_override}")
                        state["triage_level"] = emergency_override
                        state["confidence"] = 1.0
                    else:
                        # Check for self-care conditions (NEW)
                        is_self_care = self.triage_engine.check_self_care_symptoms(extracted)
                        if is_self_care:
                            print(f"✅ SELF-CARE: Mild common symptoms suitable for home care")
                            state["triage_level"] = "SELF_CARE"
                            state["confidence"] = 0.95
                        else:
                            # Get ML model prediction
                            triage_level, confidence = self.triage_engine.classify_triage(extracted)
                            print(f"🤖 ML MODEL: {triage_level} (confidence: {confidence:.2f})")
                            state["triage_level"] = triage_level
                            state["confidence"] = confidence
        return state

    def _explanation_node(self, state: ConversationState) -> ConversationState:
        if state.get("error"):
            return state
        
        # Check if we have a custom emergency reason from LLM assessment
        emergency_reason = state.get("emergency_reason", "")
        triage_level = state.get("triage_level", "")
        symptoms_str = ", ".join(state.get("extracted_symptoms", []))
        severity = state.get("severity", "")
        duration = state.get("duration", "")
        confidence = state.get("confidence", 0.0)
        
        # Format confidence as percentage
        confidence_pct = int(confidence * 100)
        
        # Generate concise, template-based explanations
        if emergency_reason or triage_level == "EMERGENCY":
            # Emergency case
            if emergency_reason:
                message = f"🚨 EMERGENCY: {emergency_reason}\n\n⚠️ Call emergency services (108) immediately.\n\nConfidence: {confidence_pct}%"
            else:
                message = f"🚨 EMERGENCY: Your symptoms ({symptoms_str}) require immediate medical attention.\n\n⚠️ Call emergency services (108) immediately.\n\nConfidence: {confidence_pct}%"
            
            actions = [
                "Call emergency services (108) immediately",
                "Go to nearest hospital",
                "Do not wait for symptoms to worsen"
            ]
            
        elif triage_level == "URGENT":
            # Urgent - see doctor within 24-48 hours
            if duration:
                message = f"⚠️ URGENT: {symptoms_str.capitalize()} (severity: {severity}, duration: {duration}) requires medical attention.\n\nPlease see a doctor within 24-48 hours.\n\nConfidence: {confidence_pct}%"
            else:
                message = f"⚠️ URGENT: {symptoms_str.capitalize()} requires medical attention.\n\nPlease see a doctor within 24-48 hours.\n\nConfidence: {confidence_pct}%"
            
            actions = [
                "Schedule doctor appointment within 24-48 hours",
                "Monitor symptoms closely",
                "Seek immediate care if symptoms worsen"
            ]
            
        else:  # SELF_CARE
            # Self-care - manageable at home
            message = f"✅ SELF-CARE: {symptoms_str.capitalize()} can be managed at home with rest and self-care.\n\nMonitor symptoms and seek care if they worsen or persist beyond 3 days.\n\nConfidence: {confidence_pct}%"
            
            actions = [
                "Get adequate rest",
                "Stay hydrated",
                "Monitor symptoms for 24-48 hours",
                "See doctor if symptoms worsen or persist >3 days"
            ]
        
        print(f"📝 Concise explanation: {message[:80]}...")
        state["response_type"] = "final"
        state["response_text"] = message
        state["actions"] = actions
        state["mode"] = "final_triage"
        
        return state
        return state

    def _translate_back_node(self, state: ConversationState) -> ConversationState:
        if state.get("error"):
            return state

        self._lazy_load_translator()
        language = state.get("language", "en")
        response_text = state.get("response_text", "")

        print(f"🔄 TRANSLATE_BACK: response_type={state.get('response_type')}, mode={state.get('mode')}")
        print(f"   Response text: '{response_text[:100] if response_text else 'EMPTY'}...'")

        if language != "en":
            response_text = self.translator.translate_from_english(response_text, language)

        state["response_text"] = response_text
        return state

    def _route_after_conversational_llm(self, state: ConversationState) -> str:
        action = state.get("conversation_action", "continue_medical")
        intent = state.get("conversation_intent", "symptom")
        print(f"🔀 ROUTING AFTER LLM: intent={intent}, action={action}")
        
        if action == "respond":
            print(f"   → Going to 'translate_back' (greeting/unrelated response)")
            return "respond"
        print(f"   → Going to 'symptom_extraction' (medical processing)")
        return "medical"

    def _route_after_dst(self, state: ConversationState) -> str:
        """
        Critical routing decision: Should we ask follow-up questions or run triage?
        
        Triggers TRIAGE when:
        - sufficient_information = True (from DST decision)
        - OR emergency_override = True (red flags detected)
        
        Triggers FOLLOWUP when:
        - needs_followup = True (missing critical info)
        """
        sufficient = state.get("sufficient_information", False)
        emergency = state.get("emergency_override", False)
        needs_followup = state.get("needs_followup", True)
        
        if emergency or sufficient or not needs_followup:
            print("🎯 ROUTING TO: triage (final classification)")
            return "triage"
        else:
            print("🎯 ROUTING TO: followup (need more info)")
            return "followup"

    def _parse_json_response(self, text: str) -> Dict:
        try:
            return json.loads(text)
        except json.JSONDecodeError:
            # Try to extract JSON substring
            start = text.find("{")
            end = text.rfind("}")
            if start != -1 and end != -1 and end > start:
                try:
                    return json.loads(text[start:end + 1])
                except json.JSONDecodeError:
                    pass
        return {}

    def _redirect_to_symptoms(self, state: ConversationState) -> str:
        system_prompt = (
            "You are a medical conversational assistant. Be polite, concise, and ask the user to share symptoms. "
            "Never diagnose or prescribe."
        )

        user_prompt = {
            "user_input": state.get("english_text", ""),
            "instruction": "Respond and ask the user to describe their symptoms."
        }

        response = self.llm.invoke(
            [
                SystemMessage(content=system_prompt),
                HumanMessage(content=json.dumps(user_prompt))
            ]
        )
        return response.content.strip()

    def run(self, user_input: str, session_id: str, force_language: Optional[str] = None) -> Dict:
        base_state = self.sessions.get(session_id, {})
        print(f"\n🔍 SESSION STATE BEFORE: session_id={session_id}")
        print(f"   - Previous symptoms: {base_state.get('extracted_symptoms', [])}")
        print(f"   - Previous severity: {base_state.get('severity', '')}")
        print(f"   - Previous duration: {base_state.get('duration', '')}")
        
        base_state.update({
            "session_id": session_id,
            "user_input": user_input
        })

        if force_language:
            base_state["language"] = force_language

        result = self.graph.invoke(base_state)

        # Update session state
        self.sessions[session_id] = {
            "session_id": session_id,
            "language": result.get("language", "en"),
            "extracted_symptoms": result.get("extracted_symptoms", []),
            "severity": result.get("severity", ""),
            "duration": result.get("duration", ""),
            "body_parts": result.get("body_parts", [])
        }
        
        print(f"💾 SESSION STATE AFTER: session_id={session_id}")
        print(f"   - Symptoms: {result.get('extracted_symptoms', [])}")
        print(f"   - Severity: {result.get('severity', '')}")
        print(f"   - Duration: {result.get('duration', '')}")

        # Update conversation history
        history = self.conversation_history.get(session_id, [])
        history.append({"role": "user", "content": user_input})
        if result.get("response_text"):
            history.append({"role": "assistant", "content": result.get("response_text")})
        self.conversation_history[session_id] = history[-12:]

        return result
