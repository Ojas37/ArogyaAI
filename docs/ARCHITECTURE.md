# 🏗️ ArogyaAI System Architecture

## Table of Contents
1. [High-Level Overview](#high-level-overview)
2. [Component Architecture](#component-architecture)
3. [Data Flow](#data-flow)
4. [Offline-First Strategy](#offline-first-strategy)
5. [Security Architecture](#security-architecture)
6. [Scalability Design](#scalability-design)

---

## High-Level Overview

ArogyaAI follows a **3-tier architecture** with offline-first capabilities:

```
┌─────────────────────────────────────────────────────────────────┐
│                      PRESENTATION LAYER                          │
│                     (Flutter Mobile App)                         │
│                                                                  │
│  ┌───────────────┐  ┌──────────────┐  ┌────────────────────┐  │
│  │  Voice Input  │  │  Chat UI     │  │  Vitals Dashboard  │  │
│  │  (STT)        │  │  (Text)      │  │  (IoT/Manual)      │  │
│  └───────┬───────┘  └──────┬───────┘  └─────────┬──────────┘  │
│          │                  │                     │              │
│          └──────────────────┴─────────────────────┘              │
│                             │                                    │
│                    ┌────────▼────────┐                          │
│                    │  Local Storage  │                          │
│                    │  (Hive DB)      │                          │
│                    └────────┬────────┘                          │
└─────────────────────────────┼─────────────────────────────────┘
                              │
                    ┌─────────▼─────────┐
                    │  Sync Manager     │ (When online)
                    │  (Queue + Upload) │
                    └─────────┬─────────┘
                              │
┌─────────────────────────────┼─────────────────────────────────┐
│                             │    APPLICATION LAYER             │
│                    ┌────────▼────────┐                         │
│                    │   FastAPI       │                         │
│                    │   REST API      │                         │
│                    └────────┬────────┘                         │
│                             │                                   │
│        ┌────────────────────┼────────────────────┐            │
│        │                    │                    │            │
│   ┌────▼─────┐      ┌──────▼──────┐      ┌─────▼─────┐     │
│   │   NLP    │      │   Triage    │      │  User     │     │
│   │  Engine  │      │   Engine    │      │  Service  │     │
│   │          │      │             │      │           │     │
│   │ • Extract│      │ • Rules     │      │ • Auth    │     │
│   │ • Translate     │ • ML Model  │      │ • History │     │
│   │ • Normalize     │ • Explain   │      │ • Logs    │     │
│   └──────────┘      └──────┬──────┘      └───────────┘     │
│                             │                                │
└─────────────────────────────┼────────────────────────────────┘
                              │
┌─────────────────────────────┼────────────────────────────────┐
│                      DATA LAYER                               │
│                             │                                 │
│        ┌────────────────────┼────────────────────┐           │
│        │                    │                    │           │
│   ┌────▼─────┐      ┌──────▼──────┐      ┌─────▼─────┐    │
│   │  SQLite  │      │   ML Models │      │ Knowledge │    │
│   │  (Prod)  │      │   (Pickle)  │      │   Base    │    │
│   │          │      │             │      │  (JSON)   │    │
│   │ • Users  │      │ • XGBoost   │      │ • Symptoms│    │
│   │ • Logs   │      │ • Vectorizer│      │ • Diseases│    │
│   │ • Vitals │      │ • SHAP      │      │ • RedFlags│    │
│   └──────────┘      └─────────────┘      └───────────┘    │
└───────────────────────────────────────────────────────────┘
```

---

## Component Architecture

### 1. Mobile App (Flutter)

#### **1.1 UI Layer**
```
lib/screens/
├── home_screen.dart          # Landing page
├── chat_screen.dart          # Main symptom input
├── vitals_screen.dart        # IoT/manual vitals
├── result_screen.dart        # Triage output + explanation
└── history_screen.dart       # Past consultations
```

#### **1.2 Business Logic Layer**
```
lib/services/
├── speech_service.dart       # STT/TTS handling
├── api_service.dart          # Backend communication
├── storage_service.dart      # Hive DB operations
├── iot_service.dart          # BLE device integration
└── sync_service.dart         # Offline queue management
```

#### **1.3 Data Models**
```dart
class SymptomReport {
  String userId;
  String language;
  String textInput;
  List<String> symptoms;
  Map<String, double>? vitals;
  DateTime timestamp;
  bool isSynced;
}

class TriageResult {
  String urgencyLevel;      // "self-care" | "doctor" | "emergency"
  List<String> redFlags;    // Critical symptoms detected
  String recommendation;    // Action steps
  String explanation;       // Why this urgency?
  double confidence;        // ML model confidence
}
```

---

### 2. Backend API (FastAPI)

#### **2.1 API Endpoints**

```python
# backend/api/routes.py

@app.post("/api/v1/symptom/analyze")
async def analyze_symptoms(report: SymptomReport):
    """
    Main triage endpoint
    Input: Symptom text + vitals
    Output: Urgency + recommendations
    """
    pass

@app.post("/api/v1/speech/transcribe")
async def transcribe_audio(audio: UploadFile, language: str):
    """
    Convert voice to text (offline Whisper)
    """
    pass

@app.get("/api/v1/diseases/search")
async def search_diseases(query: str, language: str):
    """
    Semantic search in knowledge base
    """
    pass

@app.post("/api/v1/vitals/analyze")
async def analyze_vitals(vitals: VitalsData):
    """
    Interpret SpO2, temp, heart rate
    """
    pass
```

---

### 3. Triage Engine (Hybrid System)

#### **3.1 Rule-Based Layer (Safety First)**

```python
# backend/triage/rule_engine.py

RED_FLAGS = {
    "emergency": [
        {"symptom": "chest_pain", "duration": "<1hr", "severity": "severe"},
        {"symptom": "difficulty_breathing", "spo2": "<90%"},
        {"symptom": "altered_consciousness", "any": True},
        {"symptom": "severe_bleeding", "any": True},
        {"symptom": "stroke_symptoms", "time_sensitive": True},
    ],
    "doctor_urgent": [
        {"symptom": "high_fever", "duration": ">3days", "temp": ">103F"},
        {"symptom": "persistent_vomiting", "duration": ">24hrs"},
        {"symptom": "severe_dehydration", "signs": ["dry_mouth", "no_urine"]},
    ]
}

def check_red_flags(symptoms: List[str], vitals: dict) -> dict:
    """
    Returns {
        "is_emergency": bool,
        "matched_rules": List[str],
        "override_ml": bool
    }
    """
    for flag in RED_FLAGS["emergency"]:
        if matches_condition(symptoms, vitals, flag):
            return {
                "is_emergency": True,
                "matched_rules": [flag["symptom"]],
                "override_ml": True  # Always escalate
            }
    return {"is_emergency": False, "override_ml": False}
```

#### **3.2 ML-Based Layer (Context-Aware)**

```python
# backend/triage/ml_classifier.py

class TriageClassifier:
    def __init__(self):
        self.model = load_model("models/xgboost_triage.pkl")
        self.vectorizer = load_vectorizer("models/tfidf_vectorizer.pkl")
        self.explainer = shap.TreeExplainer(self.model)
    
    def predict(self, symptoms: List[str], vitals: dict, demographics: dict):
        """
        Features:
        - Symptom embeddings (TF-IDF)
        - Vitals (SpO2, temp, HR)
        - Demographics (age, gender)
        - Duration of symptoms
        
        Returns:
        {
            "urgency": "self-care" | "doctor" | "emergency",
            "confidence": 0.87,
            "shap_values": {...}  # For explainability
        }
        """
        pass
```

#### **3.3 Hybrid Decision Logic**

```python
def final_triage_decision(rule_result, ml_result):
    """
    Decision Matrix:
    
    | Rule Result | ML Result  | Final Decision | Reasoning          |
    |-------------|------------|----------------|--------------------|
    | Emergency   | Any        | EMERGENCY      | Safety override    |
    | Doctor      | Self-care  | DOCTOR         | Conservative       |
    | None        | ML Output  | ML Output      | Trust model        |
    """
    if rule_result["override_ml"]:
        return rule_result
    
    # Conservative bias: upgrade if close call
    if ml_result["confidence"] < 0.7:
        return upgrade_urgency(ml_result)
    
    return ml_result
```

---

### 4. NLP Pipeline (Multilingual)

```python
# backend/nlp/symptom_extractor.py

class MultilingualNLP:
    def __init__(self):
        self.translators = {
            "hi": IndicTranslator("hi"),
            "te": IndicTranslator("te"),
            "ta": IndicTranslator("ta"),
            "bn": IndicTranslator("bn"),
        }
        self.spacy_model = spacy.load("en_core_web_sm")
        self.symptom_ontology = load_json("knowledge/symptoms.json")
    
    def extract_symptoms(self, text: str, language: str):
        """
        Pipeline:
        1. Language detection (if mixed)
        2. Translation to English
        3. Entity extraction (symptoms, body parts, duration)
        4. Normalization (map to standard terms)
        5. Return structured data
        """
        # Step 1: Translate
        if language != "en":
            text_en = self.translators[language].translate(text)
        
        # Step 2: Extract entities
        doc = self.spacy_model(text_en)
        symptoms = []
        for ent in doc.ents:
            if ent.label_ in ["SYMPTOM", "DISEASE"]:
                normalized = self.normalize_symptom(ent.text)
                symptoms.append(normalized)
        
        # Step 3: Extract context
        duration = extract_duration(text)
        severity = extract_severity(text)
        
        return {
            "symptoms": symptoms,
            "duration": duration,
            "severity": severity,
            "original_text": text
        }
```

---

## Data Flow

### **Typical User Journey**

```
[User Opens App]
      ↓
[Selects Language: Hindi]
      ↓
[Speaks: "Mujhe bukhar aur sar dard hai 3 din se"]
      ↓
┌─────────────────────────────────┐
│  OFFLINE PROCESSING (if no net)│
│  1. STT (Whisper local)        │
│  2. Store in Hive DB           │
│  3. Queue for later sync       │
└─────────────────────────────────┘
      ↓ (when online)
[Backend API: /analyze]
      ↓
┌─────────────────────────────────┐
│  NLP PIPELINE                   │
│  1. Translate: "I have fever   │
│     and headache for 3 days"   │
│  2. Extract: ["fever",          │
│     "headache"]                 │
│  3. Duration: 3 days            │
└─────────────────────────────────┘
      ↓
┌─────────────────────────────────┐
│  RULE ENGINE                    │
│  - Check red flags: None        │
│  - Fever >3 days → "Doctor"     │
└─────────────────────────────────┘
      ↓
┌─────────────────────────────────┐
│  ML CLASSIFIER                  │
│  - Features: [fever, headache,  │
│    duration_3days, age_25]      │
│  - Prediction: "Doctor Visit"   │
│  - Confidence: 0.82             │
└─────────────────────────────────┘
      ↓
┌─────────────────────────────────┐
│  HYBRID DECISION                │
│  - Rule: Doctor                 │
│  - ML: Doctor (0.82)            │
│  - Final: DOCTOR VISIT (24hrs)  │
└─────────────────────────────────┘
      ↓
[Generate Explanation]
  "You have persistent fever for 3 days
   with headache. This may indicate
   infection requiring medical evaluation."
      ↓
[Return to App]
      ↓
[Display Result Screen]
  • Urgency: 🟡 Doctor Visit (24 hrs)
  • Symptoms: Fever, Headache
  • Recommendation: Visit nearby clinic
  • Red Flags: None
  • Confidence: 82%
      ↓
[User Clicks "Find Nearby Clinics"]
[User Clicks "Save Report"]
```

---

## Offline-First Strategy

### **Challenge**: Rural areas have intermittent connectivity

### **Solution**: 3-Layer Offline Architecture

#### **Layer 1: Local Processing**
```dart
// mobile_app/lib/services/offline_triage.dart

class OfflineTriage {
  // Embedded rule engine in mobile app
  Future<TriageResult> analyzeOffline(SymptomReport report) async {
    // Load local rules from assets
    final rules = await loadLocalRules();
    
    // Simple keyword matching
    bool hasEmergencySymptom = checkEmergencyKeywords(
      report.symptoms
    );
    
    if (hasEmergencySymptom) {
      return TriageResult(
        urgencyLevel: "emergency",
        recommendation: "Seek immediate medical attention",
        explanation: "Critical symptoms detected",
        confidence: 1.0,
        isOfflineResult: true
      );
    }
    
    // Conservative default
    return TriageResult(
      urgencyLevel: "doctor",
      recommendation: "Consult doctor when possible",
      explanation: "Limited offline analysis",
      confidence: 0.5,
      isOfflineResult: true
    );
  }
}
```

#### **Layer 2: Sync Queue**
```dart
// mobile_app/lib/services/sync_service.dart

class SyncService {
  final Hive box = Hive.box('pending_reports');
  
  Future<void> queueReport(SymptomReport report) async {
    report.isSynced = false;
    await box.add(report.toJson());
  }
  
  Future<void> syncWhenOnline() async {
    if (await isOnline()) {
      final pending = box.values.where((r) => !r.isSynced);
      
      for (var report in pending) {
        try {
          final betterResult = await apiService.analyzeSymptoms(report);
          // Update local result with ML prediction
          await updateLocalResult(report.id, betterResult);
          report.isSynced = true;
        } catch (e) {
          // Keep in queue
        }
      }
    }
  }
}
```

#### **Layer 3: Local ML Model (Future)**
```
Option for advanced offline ML:
- Use TensorFlow Lite for mobile
- Deploy quantized XGBoost model (< 5MB)
- Trade-off: Accuracy vs App size
```

---

## Security Architecture

### **1. Data Privacy**

```python
# backend/security/anonymizer.py

class DataAnonymizer:
    def anonymize_report(self, report: dict):
        """
        Before storing:
        - Hash user ID with salt
        - Remove location metadata
        - Encrypt symptom text
        - Keep only aggregated demographics
        """
        return {
            "user_hash": hashlib.sha256(report["user_id"].encode()).hexdigest(),
            "age_group": self.bucket_age(report["age"]),  # 20-30, 30-40
            "symptoms": encrypt(report["symptoms"]),
            "timestamp": report["timestamp"],
            "result": report["result"]
        }
```

### **2. API Security**

```python
# backend/api/middleware.py

@app.middleware("http")
async def rate_limiter(request: Request, call_next):
    """
    Rate limiting: 100 requests/hour per user
    Prevents abuse, ensures fair usage
    """
    pass

@app.middleware("http")
async def input_sanitizer(request: Request, call_next):
    """
    Sanitize all inputs to prevent:
    - SQL injection
    - XSS attacks
    - Malicious file uploads
    """
    pass
```

### **3. HIPAA-Like Compliance**

- ✅ **Consent**: Explicit user agreement before data collection
- ✅ **Right to Delete**: User can wipe all data
- ✅ **Audit Logs**: Track who accessed what data
- ✅ **Encryption**: At-rest and in-transit (TLS 1.3)

---

## Scalability Design

### **Phase 1: MVP (1000 users)**
- Single server (Heroku/Railway free tier)
- SQLite database
- Synchronous API calls

### **Phase 2: Growth (10K users)**
- Load balancer (Nginx)
- PostgreSQL with read replicas
- Async processing (Celery + Redis)

### **Phase 3: Scale (100K+ users)**
```
            [Load Balancer]
                  │
        ┌─────────┼─────────┐
        │         │         │
   [API-1]   [API-2]   [API-3]
        │         │         │
        └─────────┼─────────┘
                  │
          [Message Queue]
                  │
        ┌─────────┼─────────┐
        │         │         │
   [Worker-1] [Worker-2] [Worker-3]
        │         │         │
        └─────────┼─────────┘
                  │
          [PostgreSQL]
          (Master + 2 Replicas)
```

### **Cost Optimization (No Cloud Credits)**

| Component | Free Option | Cost |
|-----------|-------------|------|
| Backend Hosting | Railway.app | $0 (500 hrs/mo) |
| Database | Supabase Free | $0 (500MB) |
| ML Model Serving | Hugging Face Spaces | $0 |
| Storage | Cloudinary Free | $0 (10GB) |
| Monitoring | Sentry Free | $0 (5K errors/mo) |

**Total: $0/month for MVP**

---

## Technology Justifications

### **Why Flutter?**
- ✅ Single codebase for Android + iOS
- ✅ Fast UI rendering (60fps)
- ✅ Strong offline capabilities (Hive DB)
- ✅ Good Bluetooth support (flutter_blue_plus)

### **Why FastAPI?**
- ✅ Async I/O for high concurrency
- ✅ Auto-generated API docs
- ✅ Pydantic validation (fewer bugs)
- ✅ Fast prototyping

### **Why XGBoost?**
- ✅ Best accuracy for tabular data
- ✅ Small model size (<10MB)
- ✅ Fast inference (<50ms)
- ✅ Native SHAP support (explainability)

### **Why Offline-First?**
- ✅ 65% of rural India has intermittent connectivity
- ✅ Builds user trust (always works)
- ✅ Reduces server costs
- ✅ Faster response times

---

## Next Steps

See [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md) for step-by-step coding instructions.
