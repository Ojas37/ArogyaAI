from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional, Dict
from datetime import datetime
import uvicorn
from language_detector import LanguageDetector
from intent_classifier import IntentClassifier

# Import the integrated pipeline
try:
    from pipeline_orchestrator import HealthcareTriagePipeline
    pipeline = HealthcareTriagePipeline()
    print("✅ Complete pipeline initialized successfully")
except Exception as e:
    print(f"⚠️  Pipeline initialization failed: {e}")
    pipeline = None

app = FastAPI(
    title="ArogyaAI Healthcare API",
    description="AI-powered symptom checker and triage system",
    version="1.0.0"
)

# Initialize Language Detector
try:
    language_detector = LanguageDetector()
    print("✅ Language detector initialized successfully")
except Exception as e:
    print(f"⚠️  Language detector initialization failed: {e}")
    language_detector = None

# Initialize Intent Classifier
try:
    intent_classifier = IntentClassifier()
    print("✅ Intent classifier initialized successfully")
except Exception as e:
    print(f"⚠️  Intent classifier initialization failed: {e}")
    intent_classifier = None


# CORS middleware - allow mobile app to call API
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify exact origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ==================== Models ====================

class SymptomReport(BaseModel):
    userId: str
    language: str
    textInput: str
    symptoms: Optional[List[str]] = []
    vitals: Optional[Dict[str, float]] = None
    timestamp: datetime

class TriageResult(BaseModel):
    urgencyLevel: str  # "self-care", "doctor", "emergency"
    recommendation: str
    explanation: str
    confidence: float
    redFlags: List[str]
    nextSteps: List[str]

class LanguageDetectionRequest(BaseModel):
    text: str

class LanguageDetectionResponse(BaseModel):
    language: str
    confidence: float
    detected_language_name: Optional[str] = None

class IntentClassificationRequest(BaseModel):
    text: str
    top_k: Optional[int] = 1

class IntentPrediction(BaseModel):
    intent: str
    confidence: float

class IntentClassificationResponse(BaseModel):
    intent: str
    confidence: float
    all_predictions: List[IntentPrediction]

# ==================== Root Endpoint ====================

@app.get("/")
async def root():
    return {
        "message": "ArogyaAI Healthcare API",
        "version": "1.0.0",
        "status": "running",
        "endpoints": [
            "/api/v1/symptom/analyze",
            "/api/v1/language/detect",
            "/api/v1/intent/classify",
            "/api/v1/guidance/generate",
            "/api/v1/guidance/emergency-contacts",
            "/api/v1/session/clear",
            "/api/v1/session/clear-all",
            "/api/v1/health",
            "/docs"
        ]
    }

@app.get("/api/v1/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "timestamp": datetime.now().isoformat()
    }

# ==================== Main Triage Endpoint ====================

@app.post("/api/v1/symptom/analyze", response_model=TriageResult)
async def analyze_symptoms(report: SymptomReport):
    """
    Analyze symptoms and return triage recommendation using COMPLETE INTEGRATED PIPELINE
    
    This endpoint:
    1. Detects language
    2. Translates to English (if needed)
    3. Classifies intent
    4. Extracts symptoms using Medical NER
    5. Runs triage classification (XGBoost + emergency overrides)
    6. Generates multilingual guidance
    7. Translates response back
    8. Returns actionable recommendations with safety constraints
    """
    
    print(f"\n{'='*80}")
    print(f"📨 NEW REQUEST - User: {report.userId}, Input: '{report.textInput}'")
    print(f"{'='*80}")
    
    try:
        if pipeline is None:
            # Fallback to simple rule-based if pipeline not loaded
            return _fallback_triage(report.textInput)
        
        # Process through complete pipeline
        result = pipeline.process_message(
            user_input=report.textInput,
            session_id=report.userId,
            force_language=report.language if report.language else None
        )
        
        # Handle errors
        if result.get('error'):
            raise HTTPException(status_code=500, detail=result.get('message', 'Processing error'))
        
        # ✅ NEW: Check mode field to determine response type
        mode = result.get('mode', 'chat')
        print(f"🔍 MAIN.PY: mode={mode}, response_type={result.get('response_type')}, response_text={result.get('response_text', '')[:50]}...")
        
        # Chat mode: follow-up questions or informational
        if mode == 'chat':
            if result.get('response_type') == 'followup':
                print(f"✅ RETURNING FOLLOWUP QUESTION")
                return TriageResult(
                    urgencyLevel="clarification",
                    recommendation=result.get('response_text', ''),
                    explanation="I need more information to provide accurate guidance.",
                    confidence=0.5,
                    redFlags=[],
                    nextSteps=["Please provide more details about your symptoms"]
                )
            
            # Informational responses (greetings, etc.)
            if result.get('response_type') == 'informational':
                return TriageResult(
                    urgencyLevel="info",
                    recommendation=result.get('response_text', ''),
                    explanation=result.get('response_text', ''),
                    confidence=1.0,
                    redFlags=[],
                    nextSteps=[]
                )
        
        # ✅ FINAL TRIAGE mode: Show classification result
        if mode == 'final_triage' or result.get('response_type') == 'final':
            # Map triage levels
            urgency_map = {
                'EMERGENCY': 'emergency',
                'URGENT': 'doctor',
                'SELF_CARE': 'self-care'
            }
            urgency = urgency_map.get(result.get('triage_level'), 'self-care')
        
        # Extract red flags (emergency symptoms)
        red_flags = []
        if result.get('triage_level') == 'EMERGENCY':
            red_flags = [f"Critical: {symptom}" for symptom in result.get('extracted_symptoms', [])]
        
        # Return complete response
        return TriageResult(
            urgencyLevel=urgency,
            recommendation=result.get('response_text', ''),
            explanation=result.get('response_text', ''),
            confidence=result.get('confidence', 0.0),
            redFlags=red_flags,
            nextSteps=result.get('actions', [])[:5]  # Top 5 actions
        )
        
    except Exception as e:
        print(f"❌ Error in symptom analysis: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Error analyzing symptoms: {str(e)}")


def _fallback_triage(text: str) -> TriageResult:
    """Fallback rule-based triage if pipeline fails"""
    emergency_keywords = ['chest pain', 'difficulty breathing', 'unconscious', 'severe bleeding']
    is_emergency = any(keyword in text.lower() for keyword in emergency_keywords)
    
    if is_emergency:
        return TriageResult(
            urgencyLevel="emergency",
            recommendation="⚠️ EMERGENCY: Seek immediate medical attention! Call emergency services (108).",
            explanation="Your symptoms indicate a potentially serious condition requiring urgent care.",
            confidence=0.95,
            redFlags=["Emergency symptoms detected"],
            nextSteps=[
                "Call emergency services (108) immediately",
                "Do not drive yourself",
                "Stay calm"
            ]
        )
    
    doctor_keywords = ['fever', 'persistent', 'severe', 'pain']
    needs_doctor = any(keyword in text.lower() for keyword in doctor_keywords)
    
    if needs_doctor:
        return TriageResult(
            urgencyLevel="doctor",
            recommendation="🏥 Please consult a doctor within 24-48 hours.",
            explanation="Your symptoms suggest you should see a healthcare professional soon.",
            confidence=0.75,
            redFlags=[],
            nextSteps=[
                "Schedule a doctor appointment",
                "Monitor symptoms",
                "Rest and stay hydrated"
            ]
        )
    
    return TriageResult(
        urgencyLevel="self-care",
        recommendation="🏡 You can manage this at home with self-care.",
        explanation="Your symptoms appear mild. Monitor and seek care if they worsen.",
        confidence=0.70,
        redFlags=[],
        nextSteps=[
            "Get adequate rest",
            "Stay hydrated",
            "Monitor symptoms for 24-48 hours"
        ]
    )

# ==================== Session Management ====================

@app.post("/api/v1/session/clear")
async def clear_session(session_id: str):
    """
    Clear backend session history for a specific session ID
    Use this when starting a new conversation or clearing history
    """
    try:
        if pipeline and hasattr(pipeline, 'conversational_graph'):
            graph = pipeline.conversational_graph
            
            # Clear session state and conversation history
            if session_id in graph.sessions:
                del graph.sessions[session_id]
            if session_id in graph.conversation_history:
                del graph.conversation_history[session_id]
            
            print(f"✅ Cleared backend session: {session_id}")
            return {"status": "success", "message": f"Session {session_id} cleared"}
        
        return {"status": "success", "message": "No active sessions to clear"}
        
    except Exception as e:
        print(f"⚠️ Error clearing session: {e}")
        return {"status": "error", "message": str(e)}

@app.post("/api/v1/session/clear-all")
async def clear_all_sessions():
    """
    Clear all backend session history
    Use this for cleanup or testing
    """
    try:
        if pipeline and hasattr(pipeline, 'conversational_graph'):
            graph = pipeline.conversational_graph
            graph.sessions.clear()
            graph.conversation_history.clear()
            print("✅ Cleared all backend sessions")
            return {"status": "success", "message": "All sessions cleared"}
        
        return {"status": "success", "message": "No active sessions to clear"}
        
    except Exception as e:
        print(f"⚠️ Error clearing sessions: {e}")
        return {"status": "error", "message": str(e)}

# ==================== Additional Endpoints ====================

@app.post("/api/v1/language/detect", response_model=LanguageDetectionResponse)
async def detect_language(request: LanguageDetectionRequest):
    """
    Detect the language of input text using fastText model
    Supports 176 languages including all Indian languages
    """
    try:
        if language_detector is None:
            raise HTTPException(
                status_code=503, 
                detail="Language detection service is not available"
            )
        
        result = language_detector.detect(request.text)
        
        # Map language codes to full names
        language_names = {
            "hi": "Hindi",
            "en": "English",
            "mr": "Marathi",
            "gu": "Gujarati",
            "pa": "Punjabi",
            "te": "Telugu",
            "ta": "Tamil",
            "bn": "Bengali",
            "kn": "Kannada",
            "bho": "Bhojpuri"
        }
        
        return LanguageDetectionResponse(
            language=result["language"],
            confidence=result["confidence"],
            detected_language_name=language_names.get(result["language"], result["language"])
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=500, 
            detail=f"Error detecting language: {str(e)}"
        )

@app.post("/api/v1/intent/classify", response_model=IntentClassificationResponse)
async def classify_intent(request: IntentClassificationRequest):
    """
    Classify the intent of user's input text.
    
    Supported intents:
    - symptom_reporting: User describing symptoms
    - emergency: Urgent medical situation
    - question: General health question
    - appointment: Appointment related
    - medication: Medication queries
    - follow_up: Follow-up on previous condition
    - general_chat: Casual conversation
    
    Returns intent classification with confidence scores.
    """
    try:
        if intent_classifier is None:
            raise HTTPException(
                status_code=503,
                detail="Intent classification service is not available"
            )
        
        result = intent_classifier.classify(request.text, top_k=request.top_k or 3)
        
        # Convert all_predictions to Pydantic models
        all_preds = [
            IntentPrediction(intent=pred["intent"], confidence=pred["confidence"])
            for pred in result.get("all_predictions", [])
        ]
        
        return IntentClassificationResponse(
            intent=result["intent"],
            confidence=result["confidence"],
            all_predictions=all_preds
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error classifying intent: {str(e)}"
        )

@app.post("/api/v1/symptom/translate")
async def translate_text(text: str, source_lang: str, target_lang: str = "en"):
    """Translate symptom text between languages"""
    # TODO: Implement translation (Week 3)
    return {"translated_text": text, "source": source_lang, "target": target_lang}

@app.get("/api/v1/diseases/search")
async def search_diseases(query: str, language: str = "en"):
    """Search disease knowledge base"""
    # TODO: Implement semantic search (Week 4)
    return {"diseases": [], "query": query}

@app.post("/api/v1/vitals/analyze")
async def analyze_vitals(vitals: Dict[str, float]):
    """
    Analyze vital signs (SpO2, temperature, heart rate)
    Returns interpretation and flags
    """
    # TODO: Implement vitals analysis (Week 4)
    flags = []
    
    if "spo2" in vitals and vitals["spo2"] < 90:
        flags.append("Low oxygen saturation - seek immediate care")
    
    if "temperature" in vitals and vitals["temperature"] > 103:
        flags.append("High fever - consult doctor")
    
    if "heartRate" in vitals and (vitals["heartRate"] < 50 or vitals["heartRate"] > 120):
        flags.append("Abnormal heart rate - medical attention recommended")
    
    return {
        "vitals": vitals,
        "flags": flags,
        "status": "critical" if flags else "normal"
    }

# ==================== Guidance Generator Endpoint ====================

class GuidanceRequest(BaseModel):
    urgencyLevel: str  # "emergency", "doctor", or "self-care"
    language: str = "en"  # "en", "hi", "mr"
    symptoms: Optional[List[str]] = None
    severity: Optional[str] = None

@app.post("/api/v1/guidance/generate")
async def generate_guidance(request: GuidanceRequest):
    """
    Generate guidance and recommendations based on urgency level
    
    This endpoint provides template-based advice in the user's language:
    - Emergency: Immediate actions for critical situations
    - Doctor: When and how to seek medical care
    - Self-care: Home remedies and monitoring advice
    
    Returns structured guidance with actions, warnings, and emergency contacts
    """
    
    if not guidance_generator:
        raise HTTPException(status_code=503, detail="Guidance generator not available")
    
    try:
        guidance = guidance_generator.generate_guidance(
            urgency_level=request.urgencyLevel,
            language=request.language,
            symptoms=request.symptoms,
            severity=request.severity
        )
        
        # Add emergency contacts
        emergency_contacts = guidance_generator.get_emergency_contacts(request.language)
        guidance["emergency_contacts"] = emergency_contacts
        
        return guidance
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error generating guidance: {str(e)}")

@app.get("/api/v1/guidance/emergency-contacts")
async def get_emergency_contacts(language: str = "en"):
    """Get emergency contact numbers for the specified language"""
    
    if not guidance_generator:
        raise HTTPException(status_code=503, detail="Guidance generator not available")
    
    try:
        contacts = guidance_generator.get_emergency_contacts(language)
        return {"language": language, "contacts": contacts}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching contacts: {str(e)}")

# ==================== Run Server ====================

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True  # Auto-reload on code changes (development only)
    )
