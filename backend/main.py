from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional, Dict
from datetime import datetime
import uvicorn

app = FastAPI(
    title="ArogyaAI Healthcare API",
    description="AI-powered symptom checker and triage system",
    version="1.0.0"
)

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

# ==================== Root Endpoint ====================

@app.get("/")
async def root():
    return {
        "message": "ArogyaAI Healthcare API",
        "version": "1.0.0",
        "status": "running",
        "endpoints": [
            "/api/v1/symptom/analyze",
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
