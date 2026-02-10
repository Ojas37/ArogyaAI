# 📅 ArogyaAI Implementation Timeline (Jan 5 - Feb 21, 2026)

## Overview: 6.5 Weeks = 47 Days

**Hackathon Deadline**: February 21, 2026  
**Available Time**: ~300 productive hours (team of 4)

---

## 🎯 Weekly Milestones

### **Week 1 (Jan 5-11): Foundation & Setup**
**Goal**: Working project skeleton with basic chat UI

#### Days 1-2 (Jan 5-6): Environment Setup
- [ ] Install Flutter SDK (3.x), Android Studio
- [ ] Install Python 3.11, pip, virtualenv
- [ ] Setup GitHub repository with CI/CD
- [ ] Initialize Flutter project structure
- [ ] Setup FastAPI backend skeleton
- [ ] Configure Docker (optional)

**Deliverable**: `flutter run` and `uvicorn main:app` both work

---

#### Days 3-4 (Jan 7-8): Basic Mobile UI
- [ ] Create home screen with language selector
- [ ] Build chat interface (text input only)
- [ ] Add simple navigation
- [ ] Setup Hive database for local storage
- [ ] Implement basic theme (low-literacy friendly)

**Code Focus**:
```dart
// lib/screens/chat_screen.dart
class ChatScreen extends StatefulWidget {
  final String selectedLanguage;
  // Message list, input field, send button
}
```

**Deliverable**: User can type symptoms and see them in chat

---

#### Days 5-6 (Jan 9-10): Backend API Skeleton
- [ ] Create FastAPI project structure
- [ ] Setup SQLite database + models
- [ ] Create `/api/v1/symptom/analyze` endpoint (dummy response)
- [ ] Add CORS middleware
- [ ] Test with Postman/Thunder Client

**Code Focus**:
```python
# backend/api/routes.py
@app.post("/api/v1/symptom/analyze")
async def analyze_symptoms(report: SymptomReport):
    return {"urgency": "doctor", "recommendation": "dummy"}
```

**Deliverable**: Mobile app can call API successfully

---

#### Day 7 (Jan 11): Integration Test
- [ ] Connect Flutter app to backend API
- [ ] Display API response in app
- [ ] Add loading states and error handling
- [ ] Test end-to-end flow

**Weekend Checkpoint**: 
✅ User types "fever" → API returns "see doctor" → App shows result

---

### **Week 2 (Jan 12-18): Core Intelligence**
**Goal**: Working triage engine with rule-based logic

#### Days 8-9 (Jan 12-13): Rule Engine
- [ ] Create rule definitions file (JSON)
- [ ] Implement red-flag detection logic
- [ ] Add urgency classification (3 levels)
- [ ] Write unit tests for rules

**Code Focus**:
```python
# backend/triage/rule_engine.py
def check_red_flags(symptoms: List[str], vitals: dict):
    # Implement emergency detection
    pass
```

**Deliverable**: API correctly flags "chest pain" as emergency

---

#### Days 10-11 (Jan 14-15): Basic NLP
- [ ] Install spaCy, download model
- [ ] Create symptom extraction function
- [ ] Build symptom normalization mapper
- [ ] Test with English inputs

**Code Focus**:
```python
# backend/nlp/symptom_extractor.py
def extract_symptoms(text: str):
    # "I have fever and headache" → ["fever", "headache"]
    pass
```

**Deliverable**: Text input → Extracted symptom list

---

#### Days 12-13 (Jan 16-17): Result Screen + Explainability
- [ ] Design result screen UI in Flutter
- [ ] Show urgency level with color coding
- [ ] Display recommendation text
- [ ] Add "Why this result?" explanation section
- [ ] Implement share/save functionality

**Deliverable**: Complete user flow from input to result

---

#### Day 14 (Jan 18): Testing & Bug Fixes
- [ ] End-to-end testing
- [ ] Fix critical bugs
- [ ] Performance optimization

**Weekend Checkpoint**:
✅ User inputs "severe chest pain" → App shows "🚨 EMERGENCY" → Explanation shown

---

### **Week 3 (Jan 19-25): Multilingual + Voice**
**Goal**: 4-language support + voice input

#### Days 15-16 (Jan 19-20): Translation Layer
- [ ] Integrate IndicNLP or Google Translate API
- [ ] Create translation service
- [ ] Add language switcher in UI
- [ ] Test Hindi, Telugu, Tamil, Bengali

**Code Focus**:
```dart
// lib/services/translation_service.dart
Future<String> translate(String text, String from, String to);
```

**Deliverable**: User can switch to Hindi and type symptoms

---

#### Days 17-18 (Jan 21-22): Speech-to-Text
- [ ] Add `speech_to_text` Flutter package
- [ ] Implement voice input button
- [ ] Handle microphone permissions
- [ ] Add loading animation during transcription
- [ ] Support multiple languages

**Code Focus**:
```dart
// lib/services/speech_service.dart
Future<String> listenToSpeech(String language);
```

**Deliverable**: User speaks "bukhar hai" → App transcribes → Translates

---

#### Days 19-20 (Jan 23-24): Text-to-Speech
- [ ] Add `flutter_tts` package
- [ ] Implement voice response playback
- [ ] Add language-specific voices
- [ ] Create toggle button (voice on/off)

**Deliverable**: App reads result aloud in user's language

---

#### Day 21 (Jan 25): Multilingual Testing
- [ ] Test all 4 languages thoroughly
- [ ] Fix translation issues
- [ ] Optimize voice quality

**Weekend Checkpoint**:
✅ User speaks in Telugu → App responds in Telugu (text + voice)

---

### **Week 4 (Jan 26-Feb 1): ML Model + IoT**
**Goal**: ML-based triage + vitals integration

#### Days 22-24 (Jan 26-28): ML Model Training
- [ ] Create synthetic symptom dataset (1000+ samples)
- [ ] Feature engineering (symptom vectors + demographics)
- [ ] Train XGBoost classifier
- [ ] Evaluate performance (accuracy, precision, recall)
- [ ] Export model (pickle/ONNX)

**Code Focus**:
```python
# ml_models/training/train_triage_model.py
def train_model(dataset):
    # Train XGBoost with 3-class output
    pass
```

**Deliverable**: Model with >85% accuracy on test set

---

#### Days 25-26 (Jan 29-30): ML Integration
- [ ] Add model inference to backend
- [ ] Implement SHAP explainability
- [ ] Merge rule + ML outputs
- [ ] Test hybrid triage logic

**Code Focus**:
```python
# backend/triage/ml_classifier.py
def predict(symptoms, vitals):
    # Return urgency + SHAP values
    pass
```

**Deliverable**: API uses ML for triage decisions

---

#### Days 27-28 (Jan 31-Feb 1): IoT Vitals Integration
- [ ] Add `flutter_blue_plus` package
- [ ] Implement Bluetooth device scanning
- [ ] Read SpO₂, temperature, heart rate
- [ ] Add manual entry fallback
- [ ] Create vitals dashboard screen

**Code Focus**:
```dart
// lib/services/iot_service.dart
Future<VitalsData> readFromDevice(String deviceId);
```

**Weekend Checkpoint**:
✅ ML model upgrades triage + IoT device connects + reads SpO₂

---

### **Week 5 (Feb 2-8): Offline Mode + Polish**
**Goal**: Offline-first functionality + UI refinement

#### Days 29-30 (Feb 2-3): Offline Triage
- [ ] Implement local rule engine in Flutter
- [ ] Add offline indicator in UI
- [ ] Create sync queue system
- [ ] Test offline → online transition

**Code Focus**:
```dart
// lib/services/offline_triage.dart
TriageResult analyzeOffline(SymptomReport report);
```

**Deliverable**: App works without internet

---

#### Days 31-32 (Feb 4-5): UI/UX Refinement
- [ ] Add icons and illustrations
- [ ] Improve color contrast (accessibility)
- [ ] Simplify navigation for low-literacy users
- [ ] Add onboarding tutorial
- [ ] Localize all UI strings

**Deliverable**: Polished, user-friendly interface

---

#### Days 33-34 (Feb 6-7): History & Reports
- [ ] Create consultation history screen
- [ ] Add report export (PDF/image)
- [ ] Implement search/filter
- [ ] Show trends (frequency of symptoms)

**Deliverable**: User can view past consultations

---

#### Day 35 (Feb 8): Integration Testing
- [ ] Full regression testing
- [ ] Performance profiling
- [ ] Battery optimization
- [ ] Fix critical issues

**Weekend Checkpoint**:
✅ Fully functional app with offline support

---

### **Week 6 (Feb 9-15): Demo Prep + Documentation**
**Goal**: Hackathon-ready presentation

#### Days 36-37 (Feb 9-10): Demo Video
- [ ] Write video script (2-3 minutes)
- [ ] Record app walkthrough
- [ ] Show real user scenarios
- [ ] Add voiceover and subtitles
- [ ] Edit and finalize

**Deliverable**: Professional demo video

---

#### Days 38-39 (Feb 11-12): Impact Metrics Dashboard
- [ ] Create admin panel (optional)
- [ ] Show usage statistics
- [ ] Calculate social impact metrics
- [ ] Generate charts/graphs

**Deliverable**: Data-driven impact story

---

#### Days 40-41 (Feb 13-14): Documentation
- [ ] Finalize README.md
- [ ] API documentation (Swagger)
- [ ] Deployment guide
- [ ] User manual (multilingual)
- [ ] Code comments cleanup

**Deliverable**: Complete documentation package

---

#### Day 42 (Feb 15): Pitch Deck
- [ ] Create presentation (10-15 slides)
- [ ] Problem statement + solution
- [ ] Architecture diagram
- [ ] Demo screenshots
- [ ] Impact metrics
- [ ] Future roadmap

**Weekend Checkpoint**:
✅ Ready for submission

---

### **Week 6.5 (Feb 16-21): Buffer & Submission**

#### Days 43-45 (Feb 16-18): Bug Fixes & Optimization
- [ ] Address remaining issues
- [ ] Performance tuning
- [ ] Security review
- [ ] Accessibility testing

---

#### Days 46-47 (Feb 19-21): Final Submission
- [ ] Submit project to hackathon portal
- [ ] Upload demo video
- [ ] Share GitHub repository
- [ ] Prepare for presentation/judging
- [ ] Practice pitch (5-7 minutes)

**Final Checkpoint**:
✅ PROJECT SUBMITTED!

---

## 📊 Team Responsibilities (4 Members)

### **Member 1: Mobile Lead**
- Flutter UI development
- Voice/speech integration
- IoT/Bluetooth implementation
- Offline functionality

**Weekly Hours**: 40-50

---

### **Member 2: Backend Lead**
- FastAPI development
- Database design
- API endpoints
- Deployment & DevOps

**Weekly Hours**: 40-50

---

### **Member 3: ML/AI Lead**
- NLP pipeline
- Translation services
- ML model training
- Triage engine logic

**Weekly Hours**: 40-50

---

### **Member 4: Product + Testing**
- Project management
- Testing & QA
- Documentation
- Demo preparation
- Presentation design

**Weekly Hours**: 30-40

---

## 🚨 Risk Mitigation

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| ML model accuracy <80% | Medium | High | Use rule-based fallback |
| Voice recognition poor for Indic languages | High | Medium | Prioritize text input |
| IoT device compatibility issues | Medium | Low | Manual entry as backup |
| Team member unavailable | Low | High | Cross-training, documentation |
| API rate limits (free tier) | Medium | Medium | Implement caching |

---

## ✅ Definition of Done (Each Week)

- [ ] Code committed to GitHub
- [ ] Tests passing (>80% coverage for backend)
- [ ] Demo-able feature
- [ ] Documentation updated
- [ ] No critical bugs

---

## 🎯 Success Metrics

### **Technical**
- App loads in <3 seconds
- API response time <500ms
- Offline mode functional
- 4 languages supported
- ML accuracy >85%
- Zero crashes in testing

### **Hackathon**
- Demo video <3 minutes, high quality
- Pitch deck compelling, data-driven
- Code well-documented
- Deployable prototype
- Clear social impact story

---

## 📞 Weekly Sync Schedule

- **Monday 9 AM**: Sprint planning
- **Wednesday 6 PM**: Mid-week check-in
- **Friday 8 PM**: Demo + retrospective
- **Daily**: 15-min standup (async on Slack)

---

## 🔗 Key Resources

- [Flutter Docs](https://docs.flutter.dev)
- [FastAPI Tutorial](https://fastapi.tiangolo.com)
- [XGBoost Guide](https://xgboost.readthedocs.io)
- [IndicNLP Library](https://github.com/anoopkunchukuttan/indic_nlp_library)
- [Medical Symptom Dataset](https://www.kaggle.com/datasets/symptom-checker)

---

**Let's build something that saves lives! 🚀**
