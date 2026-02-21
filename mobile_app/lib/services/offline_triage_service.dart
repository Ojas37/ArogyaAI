import '../models/symptom_report.dart';
import '../models/triage_result.dart';

class OfflineTriageService {
  /// Simple offline triage using rule-based logic
  /// This runs entirely on the device without internet
  /// Supports English and Hindi (transliterated) keywords
  TriageResult analyzeOffline(SymptomReport report) {
    final text = report.textInput.toLowerCase();
    
    // Emergency red flags (English + Hindi transliterated)
    final emergencyKeywords = [
      // English
      'chest pain', 'heart attack', 'difficulty breathing', 'can\'t breathe',
      'unconscious', 'severe bleeding', 'stroke', 'seizure', 'suicide',
      'collapsed', 'fainted', 'not responding', 'choking', 'snake bite',
      'poisoning', 'accident', 'head injury', 'electric shock',
      // Hindi (transliterated)
      'seene mein dard', 'dil ka dard', 'saans nahi aa rahi', 'behosh',
      'bahut khoon', 'lakwa', 'mirgi', 'gir gaya', 'saanp katna',
      'zeher', 'hadsa', 'sir mein chot', 'bijli ka jhatkaa',
      'dil ka daura', 'heart attack', 'bahut tez dard',
    ];
    
    for (final keyword in emergencyKeywords) {
      if (text.contains(keyword)) {
        return TriageResult(
          urgencyLevel: 'emergency',
          recommendation: '⚠️ तुरंत चिकित्सा सहायता लें!\nआपातकालीन सेवाएं कॉल करें (108/102)\n\n⚠️ SEEK IMMEDIATE MEDICAL ATTENTION!\nCall emergency services (108/102)',
          explanation: 'आपके लक्षण गंभीर स्थिति का संकेत देते हैं।\nYour symptoms indicate a potentially life-threatening condition.',
          confidence: 1.0,
          redFlags: [keyword],
          nextSteps: [
            'तुरंत एम्बुलेंस बुलाएं (108) / Call ambulance immediately (108)',
            'खुद गाड़ी न चलाएं / Do not drive yourself',
            'शांत रहें और बैठ जाएं / Stay calm and sit down',
            'किसी को अपने साथ रखें / Have someone stay with you'
          ],
          isOfflineResult: true,
        );
      }
    }
    
    // Doctor visit needed (English + Hindi)
    final doctorKeywords = [
      // English
      'fever', 'high fever', 'persistent', 'severe pain', 'vomiting',
      'diarrhea', 'blood in', 'swelling', 'rash', 'infection',
      'wound', 'injury', 'burn', 'pregnancy', 'pregnant',
      'child sick', 'baby sick', 'stomach pain', 'abdominal pain',
      // Hindi (transliterated)
      'bukhar', 'tez bukhar', 'dard', 'tez dard', 'ulti', 'dast',
      'khoon', 'sujan', 'daane', 'ghav', 'chot', 'jalna',
      'garbhvati', 'pet mein dard', 'pet dard', 'sir dard', 'sar dard',
      'kamzori', 'chakkar', 'khansi', 'sardI', 'zukam',
      'baccha bimar', 'din se', 'hafte se',
    ];
    
    int doctorMatches = 0;
    for (final keyword in doctorKeywords) {
      if (text.contains(keyword)) doctorMatches++;
    }
    
    if (doctorMatches >= 1) {
      return TriageResult(
        urgencyLevel: 'doctor',
        recommendation: '🏥 24-48 घंटों के भीतर डॉक्टर से मिलें\n\n🏥 Consult a doctor within 24-48 hours',
        explanation: 'आपके लक्षण बताते हैं कि आपको डॉक्टर से जांच करानी चाहिए।\nYour symptoms suggest you should see a healthcare professional.',
        confidence: 0.7,
        redFlags: [],
        nextSteps: [
          'डॉक्टर से मिलने का समय लें / Schedule a doctor appointment',
          'लक्षणों पर नजर रखें / Monitor your symptoms',
          'आराम करें और पानी पीते रहें / Rest and stay hydrated',
          'लक्षण बिगड़ें तो तुरंत जाएं / Seek immediate care if symptoms worsen',
          'नजदीकी PHC या अस्पताल जाएं / Visit nearest PHC or hospital'
        ],
        isOfflineResult: true,
      );
    }
    
    // Self-care (default)
    return TriageResult(
      urgencyLevel: 'self-care',
      recommendation: '🏡 घर पर देखभाल करें और आराम करें\n\n🏡 Monitor symptoms and practice self-care at home',
      explanation: 'आपके लक्षण हल्के लग रहे हैं। घर पर आराम और देखभाल से ठीक हो सकते हैं।\nYour symptoms may be manageable at home with rest and care.',
      confidence: 0.6,
      redFlags: [],
      nextSteps: [
        'पर्याप्त आराम करें / Get adequate rest',
        'खूब पानी पीएं / Drink plenty of fluids',
        'तापमान जांचते रहें / Monitor your temperature',
        '3 दिन से ज्यादा हो तो डॉक्टर से मिलें / See doctor if symptoms persist beyond 3 days',
        'लक्षण बिगड़ें तो तुरंत जाएं / Seek care if symptoms worsen'
      ],
      isOfflineResult: true,
    );
  }
}
