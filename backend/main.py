from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional, Dict
from datetime import datetime
import uvicorn
from language_detector import LanguageDetector
from intent_classifier import IntentClassifier

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
    Analyze symptoms and return triage recommendation
    
    This is the main endpoint that:
    1. Translates input to English (if needed)
    2. Extracts symptoms using NLP
    3. Runs rule-based red-flag detection
    4. Runs ML-based urgency classification
    5. Combines results (hybrid approach)
    6. Returns actionable recommendations
    """
    
    try:
        # TODO: Implement actual logic (Week 2-3)
        # For now, return mock response
        
        # Mock red-flag detection
        emergency_keywords = ['chest pain', 'difficulty breathing', 'unconscious']
        is_emergency = any(keyword in report.textInput.lower() for keyword in emergency_keywords)
        
        if is_emergency:
            return TriageResult(
                urgencyLevel="emergency",
                recommendation="Seek immediate medical attention. Call emergency services.",
                explanation="Your symptoms indicate a potentially serious condition requiring urgent care.",
                confidence=0.95,
                redFlags=["chest pain detected", "breathing difficulty"],
                nextSteps=[
                    "Call emergency services (108)",
                    "Do not drive yourself",
                    "Stay calm and sit down"
                ]
            )
        
        # Check for doctor visit
        doctor_keywords = ['fever', 'persistent', 'severe']
        needs_doctor = any(keyword in report.textInput.lower() for keyword in doctor_keywords)
        
        if needs_doctor:
            return TriageResult(
                urgencyLevel="doctor",
                recommendation="Visit a doctor within 24-48 hours.",
                explanation="Your symptoms suggest you should consult a healthcare professional.",
                confidence=0.80,
                redFlags=[],
                nextSteps=[
                    "Schedule a doctor appointment",
                    "Monitor symptoms",
                    "Rest and stay hydrated"
                ]
            )
        
        # Default: self-care
        return TriageResult(
            urgencyLevel="self-care",
            recommendation="Monitor symptoms and practice self-care.",
            explanation="Your symptoms can likely be managed at home with rest and care.",
            confidence=0.75,
            redFlags=[],
            nextSteps=[
                "Get adequate rest",
                "Stay hydrated",
                "Monitor for worsening symptoms",
                "Seek care if symptoms persist beyond 3 days"
            ]
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error analyzing symptoms: {str(e)}")

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

# ==================== Run Server ====================

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True  # Auto-reload on code changes (development only)
    )
