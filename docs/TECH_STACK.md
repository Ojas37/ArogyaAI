# 🛠️ ArogyaAI Technology Stack

## Overview

This document details every technology, library, and tool used in ArogyaAI with justifications for hackathon judges.

---

## 🎨 Frontend (Mobile App)

### **Flutter 3.x**
**Why?**
- ✅ Single codebase for Android + iOS (2x faster development)
- ✅ Native performance (compiled to ARM/x64)
- ✅ Rich widget library (Material + Cupertino)
- ✅ Strong community support

**Installation**:
```bash
# Windows
# Download from https://docs.flutter.dev/get-started/install/windows
flutter doctor
```

**Version**: 3.19+ (Stable channel)

---

### **Key Flutter Packages**

#### 1. **hive** (Local Database)
```yaml
# pubspec.yaml
dependencies:
  hive: ^2.2.3
  hive_flutter: ^1.1.0
```

**Purpose**: Offline-first data storage  
**Why not SQLite?** Hive is 10x faster for key-value data  
**Use Case**: Store symptom reports, sync queue, user preferences

**Example**:
```dart
// lib/services/storage_service.dart
import 'package:hive_flutter/hive_flutter.dart';

class StorageService {
  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox('reports');
  }
  
  Future<void> saveReport(SymptomReport report) async {
    final box = Hive.box('reports');
    await box.put(report.id, report.toJson());
  }
}
```

---

#### 2. **speech_to_text** (Voice Input)
```yaml
dependencies:
  speech_to_text: ^6.6.0
```

**Purpose**: Convert voice to text in regional languages  
**Supports**: Hindi, Telugu, Tamil, Bengali (Google Speech API)  
**Offline?** Limited (only English), use Whisper API for full offline

**Example**:
```dart
// lib/services/speech_service.dart
import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  final SpeechToText _speech = SpeechToText();
  
  Future<String> listen(String languageCode) async {
    await _speech.initialize(
      onStatus: (status) => print('Status: $status'),
    );
    
    String result = '';
    _speech.listen(
      onResult: (val) => result = val.recognizedWords,
      localeId: languageCode, // 'hi-IN', 'te-IN', 'ta-IN', 'bn-IN'
    );
    
    return result;
  }
}
```

---

#### 3. **flutter_tts** (Text-to-Speech)
```yaml
dependencies:
  flutter_tts: ^4.0.0
```

**Purpose**: Voice output for low-literacy users  
**Supports**: 50+ languages including Indic  
**Quality**: Good for Hindi, acceptable for Telugu/Tamil

**Example**:
```dart
// lib/services/tts_service.dart
import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  final FlutterTts _tts = FlutterTts();
  
  Future<void> speak(String text, String language) async {
    await _tts.setLanguage(language); // 'hi-IN', 'te-IN'
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.5); // Slower for clarity
    await _tts.speak(text);
  }
}
```

---

#### 4. **flutter_blue_plus** (IoT Integration)
```yaml
dependencies:
  flutter_blue_plus: ^1.31.0
```

**Purpose**: Connect to Bluetooth Low Energy (BLE) health devices  
**Supports**: SpO₂ sensors, thermometers, heart rate monitors  
**Why not bluetooth_plus?** flutter_blue_plus has better null safety

**Example**:
```dart
// lib/services/iot_service.dart
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class IoTService {
  Future<void> scanDevices() async {
    FlutterBluePlus.startScan(timeout: Duration(seconds: 4));
    
    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        if (r.device.name.contains('OxyPulse')) {
          connectToDevice(r.device);
        }
      }
    });
  }
  
  Future<Map<String, double>> readVitals(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();
    // Parse SpO2, heart rate from BLE characteristics
    return {'spo2': 98.0, 'heartRate': 72.0};
  }
}
```

---

#### 5. **http** (API Communication)
```yaml
dependencies:
  http: ^1.2.0
```

**Purpose**: REST API calls to backend  
**Why not dio?** Simpler for basic requests, less overhead

**Example**:
```dart
// lib/services/api_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  final String baseUrl = 'http://localhost:8000/api/v1';
  
  Future<TriageResult> analyzeSymptoms(SymptomReport report) async {
    final response = await http.post(
      Uri.parse('$baseUrl/symptom/analyze'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(report.toJson()),
    );
    
    if (response.statusCode == 200) {
      return TriageResult.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('API Error');
    }
  }
}
```

---

#### 6. **provider** (State Management)
```yaml
dependencies:
  provider: ^6.1.0
```

**Purpose**: Manage app state (loading, results, user settings)  
**Why not BLoC/Riverpod?** Provider is simpler for MVP, easier learning curve

**Example**:
```dart
// lib/providers/triage_provider.dart
import 'package:flutter/material.dart';

class TriageProvider with ChangeNotifier {
  TriageResult? _result;
  bool _isLoading = false;
  
  TriageResult? get result => _result;
  bool get isLoading => _isLoading;
  
  Future<void> analyzeSymptoms(SymptomReport report) async {
    _isLoading = true;
    notifyListeners();
    
    _result = await apiService.analyzeSymptoms(report);
    
    _isLoading = false;
    notifyListeners();
  }
}
```

---

#### 7. **connectivity_plus** (Network Detection)
```yaml
dependencies:
  connectivity_plus: ^5.0.0
```

**Purpose**: Detect online/offline status for sync  
**Use Case**: Switch between online API and offline triage

---

#### 8. **permission_handler** (Permissions)
```yaml
dependencies:
  permission_handler: ^11.0.0
```

**Purpose**: Request microphone, Bluetooth, storage permissions  
**Critical for**: Voice input, IoT devices, local storage

---

### **Complete pubspec.yaml**
```yaml
name: arogyaai_app
description: AI-powered rural healthcare assistant
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  provider: ^6.1.0
  
  # Local Storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  
  # Speech
  speech_to_text: ^6.6.0
  flutter_tts: ^4.0.0
  
  # IoT
  flutter_blue_plus: ^1.31.0
  
  # Networking
  http: ^1.2.0
  connectivity_plus: ^5.0.0
  
  # Utilities
  permission_handler: ^11.0.0
  intl: ^0.19.0  # Internationalization
  share_plus: ^7.0.0  # Share reports
  path_provider: ^2.1.0  # File paths
  
  # UI
  cupertino_icons: ^1.0.6
  google_fonts: ^6.1.0
  flutter_svg: ^2.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  hive_generator: ^2.0.0
  build_runner: ^2.4.0

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/audio/
    - assets/rules/
  fonts:
    - family: NotoSans
      fonts:
        - asset: assets/fonts/NotoSans-Regular.ttf
        - asset: assets/fonts/NotoSans-Bold.ttf
          weight: 700
```

---

## 🖥️ Backend (API Server)

### **FastAPI** (Python Web Framework)
**Why?**
- ✅ Async I/O (handles 1000s of concurrent requests)
- ✅ Auto-generated OpenAPI docs (Swagger UI)
- ✅ Pydantic validation (type-safe)
- ✅ Fast development (Pythonic)

**Installation**:
```bash
pip install fastapi[all] uvicorn[standard]
```

**Version**: 0.110+

**Example**:
```python
# backend/main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="ArogyaAI API", version="1.0.0")

# Allow mobile app to call API
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    return {"message": "ArogyaAI API is running"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
```

---

### **Key Python Libraries**

#### 1. **spaCy** (NLP Engine)
```bash
pip install spacy
python -m spacy download en_core_web_sm
```

**Purpose**: Extract symptoms, body parts, duration from text  
**Why?** Best accuracy for medical entity recognition  
**Model Size**: 12MB (en_core_web_sm)

**Example**:
```python
# backend/nlp/symptom_extractor.py
import spacy

nlp = spacy.load("en_core_web_sm")

def extract_symptoms(text: str):
    doc = nlp(text)
    symptoms = []
    
    for ent in doc.ents:
        if ent.label_ in ["SYMPTOM", "DISEASE"]:
            symptoms.append(ent.text.lower())
    
    # Fallback: keyword matching
    if not symptoms:
        keywords = ["fever", "headache", "cough", "pain"]
        symptoms = [kw for kw in keywords if kw in text.lower()]
    
    return symptoms
```

---

#### 2. **XGBoost** (ML Classifier)
```bash
pip install xgboost
```

**Purpose**: Urgency classification (self-care, doctor, emergency)  
**Why?** Best for tabular data, fast inference, explainable  
**Alternatives**: Random Forest (less accurate), Neural Nets (overkill)

**Example**:
```python
# ml_models/training/train_triage_model.py
import xgboost as xgb
import pandas as pd
from sklearn.model_selection import train_test_split

def train_model(dataset_path: str):
    # Load synthetic data
    df = pd.read_csv(dataset_path)
    X = df.drop('urgency', axis=1)
    y = df['urgency']  # 0=self-care, 1=doctor, 2=emergency
    
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2)
    
    model = xgb.XGBClassifier(
        objective='multi:softmax',
        num_class=3,
        max_depth=5,
        learning_rate=0.1,
        n_estimators=100
    )
    
    model.fit(X_train, y_train)
    
    accuracy = model.score(X_test, y_test)
    print(f"Accuracy: {accuracy:.2f}")
    
    # Save model
    model.save_model('models/xgboost_triage.json')
    
    return model
```

---

#### 3. **SHAP** (Explainability)
```bash
pip install shap
```

**Purpose**: Explain why model made a decision  
**Critical for**: Trust, transparency, hackathon judges

**Example**:
```python
# backend/triage/explainer.py
import shap
import xgboost as xgb

model = xgb.Booster()
model.load_model('models/xgboost_triage.json')

explainer = shap.TreeExplainer(model)

def explain_prediction(features):
    shap_values = explainer.shap_values(features)
    
    # Top 3 contributing factors
    top_features = sorted(
        zip(features.columns, shap_values[0]),
        key=lambda x: abs(x[1]),
        reverse=True
    )[:3]
    
    explanation = f"Decision based on: {', '.join([f[0] for f in top_features])}"
    return explanation
```

---

#### 4. **googletrans** (Translation)
```bash
pip install googletrans==4.0.0rc1
```

**Purpose**: Translate Indic languages to English for NLP  
**Why?** Free, supports all target languages  
**Alternative**: Bhashini API (Indian govt, slower)

**Example**:
```python
# backend/nlp/translator.py
from googletrans import Translator

translator = Translator()

def translate_to_english(text: str, source_lang: str):
    """
    source_lang: 'hi', 'te', 'ta', 'bn'
    """
    result = translator.translate(text, src=source_lang, dest='en')
    return result.text
```

---

#### 5. **SQLAlchemy** (Database ORM)
```bash
pip install sqlalchemy
```

**Purpose**: Database abstraction, migrations  
**Use Case**: Store user logs, symptoms, results

**Example**:
```python
# backend/models/database.py
from sqlalchemy import create_engine, Column, Integer, String, JSON
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

Base = declarative_base()

class SymptomLog(Base):
    __tablename__ = "symptom_logs"
    
    id = Column(Integer, primary_key=True)
    user_id = Column(String)
    symptoms = Column(JSON)
    vitals = Column(JSON)
    urgency = Column(String)
    created_at = Column(String)

engine = create_engine('sqlite:///arogyaai.db')
Base.metadata.create_all(engine)
SessionLocal = sessionmaker(bind=engine)
```

---

#### 6. **python-multipart** (File Uploads)
```bash
pip install python-multipart
```

**Purpose**: Handle audio file uploads for STT  
**Use Case**: User sends recorded voice, backend transcribes

---

### **Complete requirements.txt**
```txt
# Web Framework
fastapi==0.110.0
uvicorn[standard]==0.27.0
python-multipart==0.0.9

# NLP & ML
spacy==3.7.0
en-core-web-sm @ https://github.com/explosion/spacy-models/releases/download/en_core_web_sm-3.7.0/en_core_web_sm-3.7.0-py3-none-any.whl
xgboost==2.0.3
shap==0.44.0
scikit-learn==1.4.0

# Translation
googletrans==4.0.0rc1

# Database
sqlalchemy==2.0.25
pydantic==2.6.0

# Speech (Optional offline STT)
openai-whisper==20231117

# Utilities
python-jose[cryptography]==3.3.0  # JWT tokens
passlib[bcrypt]==1.7.4  # Password hashing
python-dotenv==1.0.0  # Environment variables
```

---

## 🤖 ML/AI Tools

### **Dataset Creation**
**Challenge**: No access to real medical data

**Solution**: Synthetic Data Generation

```python
# ml_models/data/generate_synthetic_data.py
import pandas as pd
import numpy as np

def generate_symptom_dataset(n_samples=1000):
    """
    Create synthetic symptom combinations with urgency labels
    """
    symptoms_pool = [
        'fever', 'headache', 'cough', 'chest_pain', 'difficulty_breathing',
        'vomiting', 'diarrhea', 'rash', 'fatigue', 'dizziness'
    ]
    
    data = []
    for _ in range(n_samples):
        # Randomly select 2-4 symptoms
        n_symptoms = np.random.randint(2, 5)
        symptoms = np.random.choice(symptoms_pool, n_symptoms, replace=False)
        
        # Assign urgency based on rules
        if 'chest_pain' in symptoms or 'difficulty_breathing' in symptoms:
            urgency = 2  # Emergency
        elif 'fever' in symptoms and len(symptoms) > 2:
            urgency = 1  # Doctor
        else:
            urgency = 0  # Self-care
        
        # Create feature vector
        feature_dict = {symptom: 1 if symptom in symptoms else 0 
                       for symptom in symptoms_pool}
        feature_dict['urgency'] = urgency
        feature_dict['age'] = np.random.randint(5, 80)
        feature_dict['duration_hours'] = np.random.randint(1, 168)
        
        data.append(feature_dict)
    
    df = pd.DataFrame(data)
    df.to_csv('symptom_dataset.csv', index=False)
    return df
```

**Public Datasets** (for reference):
- [Kaggle: Disease Symptom Prediction](https://www.kaggle.com/datasets/itachi9604/disease-symptom-description-dataset)
- [UCI: Primary Tumor Dataset](https://archive.ics.uci.edu/dataset/83/primary+tumor)

---

### **Model Evaluation**

```python
# ml_models/evaluation/evaluate_model.py
from sklearn.metrics import classification_report, confusion_matrix
import matplotlib.pyplot as plt
import seaborn as sns

def evaluate_triage_model(model, X_test, y_test):
    y_pred = model.predict(X_test)
    
    # Classification report
    print(classification_report(y_test, y_pred, 
                                target_names=['Self-care', 'Doctor', 'Emergency']))
    
    # Confusion matrix
    cm = confusion_matrix(y_test, y_pred)
    sns.heatmap(cm, annot=True, fmt='d', cmap='Blues')
    plt.xlabel('Predicted')
    plt.ylabel('Actual')
    plt.title('Triage Confusion Matrix')
    plt.savefig('confusion_matrix.png')
    
    # Critical metric: Emergency recall (must be >95%)
    emergency_recall = cm[2, 2] / (cm[2, 0] + cm[2, 1] + cm[2, 2])
    print(f"Emergency Detection Recall: {emergency_recall:.2%}")
    
    return emergency_recall
```

---

## 🚀 Deployment & DevOps

### **Docker** (Containerization)
```dockerfile
# backend/Dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Download spaCy model
RUN python -m spacy download en_core_web_sm

# Copy application
COPY . .

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

```yaml
# docker-compose.yml
version: '3.8'

services:
  backend:
    build: ./backend
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=sqlite:///./arogyaai.db
    volumes:
      - ./backend:/app

  # Optional: PostgreSQL for production
  # db:
  #   image: postgres:15
  #   environment:
  #     POSTGRES_DB: arogyaai
  #     POSTGRES_USER: admin
  #     POSTGRES_PASSWORD: secure_password
```

---

### **Free Hosting Options**

#### **Option 1: Railway.app** (Recommended)
- 500 hours/month free
- Automatic deployments from GitHub
- Built-in database

```bash
# Install Railway CLI
npm install -g @railway/cli

# Deploy
railway login
railway init
railway up
```

#### **Option 2: Render.com**
- Free tier for web services
- Auto-scaling
- Custom domains

#### **Option 3: Heroku** (Limited free tier)
```bash
heroku create arogyaai-api
git push heroku main
```

---

### **CI/CD with GitHub Actions**
```yaml
# .github/workflows/test.yml
name: Test Backend

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      
      - name: Install dependencies
        run: |
          cd backend
          pip install -r requirements.txt
          python -m spacy download en_core_web_sm
      
      - name: Run tests
        run: |
          cd backend
          pytest tests/
      
      - name: Check code quality
        run: |
          pip install flake8
          flake8 backend/ --max-line-length=100
```

---

## 📊 Monitoring & Analytics

### **Sentry** (Error Tracking)
```bash
pip install sentry-sdk
```

```python
# backend/main.py
import sentry_sdk

sentry_sdk.init(
    dsn="https://your-dsn@sentry.io/project-id",
    traces_sample_rate=1.0,
)
```

### **Google Analytics** (Mobile)
```yaml
# pubspec.yaml
dependencies:
  firebase_analytics: ^10.8.0
```

---

## 🔐 Security Tools

### **Rate Limiting**
```bash
pip install slowapi
```

```python
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)

@app.post("/api/v1/symptom/analyze")
@limiter.limit("10/minute")
async def analyze_symptoms(request: Request):
    pass
```

---

## 📝 Testing Tools

### **Backend Tests**
```bash
pip install pytest pytest-asyncio httpx
```

```python
# backend/tests/test_triage.py
import pytest
from triage.rule_engine import check_red_flags

def test_emergency_detection():
    symptoms = ["chest_pain", "difficulty_breathing"]
    vitals = {"spo2": 88}
    
    result = check_red_flags(symptoms, vitals)
    assert result["is_emergency"] == True
```

### **Mobile Tests**
```dart
// mobile_app/test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Chat screen displays input field', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());
    expect(find.byType(TextField), findsOneWidget);
  });
}
```

---

## 🎓 Learning Resources

| Technology | Resource | Time |
|------------|----------|------|
| Flutter | [Flutter Crash Course](https://www.youtube.com/watch?v=VPvVD8t02U8) | 4 hrs |
| FastAPI | [Official Tutorial](https://fastapi.tiangolo.com/tutorial/) | 2 hrs |
| XGBoost | [Complete Guide](https://www.kaggle.com/learn/intermediate-machine-learning) | 3 hrs |
| spaCy | [NLP Course](https://course.spacy.io/) | 4 hrs |

---

## 📦 Final Package Sizes

| Component | Size |
|-----------|------|
| Flutter APK (Release) | ~25 MB |
| Backend Docker Image | ~800 MB |
| ML Models | ~15 MB |
| Total | ~840 MB |

---

**Next**: See [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md) for step-by-step coding!
