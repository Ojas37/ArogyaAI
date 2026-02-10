# 🚀 ArogyaAI Quick Start Guide

## Prerequisites

Before starting, ensure you have:
- **Flutter SDK 3.x** installed
- **Python 3.11+** installed
- **Android Studio** (for Android development)
- **VS Code** (recommended) with Flutter and Python extensions

---

## 🔧 Backend Setup (5 minutes)

### 1. Navigate to backend folder
```powershell
cd backend
```

### 2. Create virtual environment
```powershell
python -m venv venv
```

### 3. Activate virtual environment
```powershell
.\venv\Scripts\activate
```

### 4. Install dependencies
```powershell
pip install -r requirements.txt
```

### 5. Download spaCy model
```powershell
python -m spacy download en_core_web_sm
```

### 6. Run the server
```powershell
python main.py
```

✅ **Backend should now be running at http://localhost:8000**

Visit http://localhost:8000/docs to see the API documentation (Swagger UI)

---

## 📱 Mobile App Setup (5 minutes)

### 1. Open new terminal and navigate to mobile app
```powershell
cd mobile_app
```

### 2. Get Flutter dependencies
```powershell
flutter pub get
```

### 3. Check Flutter setup
```powershell
flutter doctor
```

Fix any issues shown (Android SDK, licenses, etc.)

### 4. Connect device or start emulator
```powershell
# List connected devices
flutter devices

# Or start an emulator from Android Studio
```

### 5. Run the app
```powershell
flutter run
```

✅ **App should launch on your device/emulator**

---

## 🧪 Test the Integration

1. **Select a language** (Hindi, Telugu, Tamil, Bengali, or English)
2. **Type a symptom** like "I have fever and headache"
3. **Or use voice input** by clicking the microphone icon
4. **Click send** and see the triage result

---

## 📂 Project Structure

```
ArogyaAI/
├── mobile_app/          # Flutter mobile application
│   ├── lib/
│   │   ├── main.dart
│   │   ├── screens/     # UI screens
│   │   ├── providers/   # State management
│   │   ├── services/    # API, speech, storage
│   │   └── models/      # Data models
│   └── pubspec.yaml
│
├── backend/             # FastAPI backend
│   ├── main.py          # Main API file
│   ├── requirements.txt
│   ├── triage/          # Triage engine (Week 2)
│   ├── nlp/             # NLP processing (Week 3)
│   └── ml_models/       # ML models (Week 4)
│
├── docs/                # Documentation
│   ├── ARCHITECTURE.md
│   ├── TECH_STACK.md
│   └── TIMELINE.md
│
└── README.md
```

---

## 🎯 Current Implementation Status

### ✅ Completed (Week 1 - MVP)
- [x] Project structure
- [x] Flutter app with navigation
- [x] Language selection screen (5 languages)
- [x] Chat interface (text input)
- [x] Backend API with FastAPI
- [x] Basic triage logic (rule-based)
- [x] API-app integration

### 🚧 In Progress (To be implemented)
- [ ] Voice input (STT)
- [ ] Text-to-speech (TTS)
- [ ] Multilingual translation
- [ ] ML model training
- [ ] IoT vitals integration
- [ ] Offline mode
- [ ] Complete UI polish

---

## 🔄 Development Workflow

### Making Changes

**Backend:**
1. Edit files in `backend/`
2. Server auto-reloads (if using `--reload` flag)
3. Test at http://localhost:8000/docs

**Mobile:**
1. Edit files in `mobile_app/lib/`
2. Save file (app hot-reloads automatically)
3. Or press `r` in terminal for hot reload
4. Or press `R` for full restart

---

## 🐛 Troubleshooting

### Backend Issues

**Error: "No module named 'fastapi'"**
```powershell
# Make sure virtual environment is activated
.\venv\Scripts\activate
pip install -r requirements.txt
```

**Port 8000 already in use**
```powershell
# Kill process on port 8000
Get-Process -Id (Get-NetTCPConnection -LocalPort 8000).OwningProcess | Stop-Process

# Or change port in main.py:
uvicorn.run("main:app", port=8001)
```

### Mobile App Issues

**Error: "Waiting for another flutter command"**
```powershell
# Delete flutter lock file
rm $env:LOCALAPPDATA\Temp\flutter_tools_lock
```

**Gradle build failed**
```powershell
cd mobile_app/android
.\gradlew clean
cd ../..
flutter pub get
flutter run
```

**Dependencies not found**
```powershell
flutter pub get
flutter pub upgrade
```

---

## 📝 Next Steps (Week 2+)

Follow the [TIMELINE.md](TIMELINE.md) for detailed weekly tasks.

**Week 2 Focus:**
1. Implement NLP symptom extraction
2. Build rule-based red-flag engine
3. Create result screen with explanations

**Week 3 Focus:**
1. Add translation service
2. Implement voice input (STT)
3. Add text-to-speech responses

See [TECH_STACK.md](TECH_STACK.md) for detailed implementation guides.

---

## 🆘 Getting Help

- Check [ARCHITECTURE.md](ARCHITECTURE.md) for system design
- Review API docs at http://localhost:8000/docs
- Flutter docs: https://docs.flutter.dev
- FastAPI docs: https://fastapi.tiangolo.com

---

## 🎉 Success Indicators

You're ready to proceed if:
- ✅ Backend API returns responses
- ✅ Mobile app connects to backend
- ✅ You can type symptoms and get triage results
- ✅ Language selection works
- ✅ App runs without crashes

---

**Ready to build something amazing! 🚀**

Start with Week 2 tasks in [TIMELINE.md](TIMELINE.md)
