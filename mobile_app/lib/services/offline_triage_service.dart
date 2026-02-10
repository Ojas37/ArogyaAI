import '../models/symptom_report.dart';
import '../models/triage_result.dart';

class OfflineTriageService {
  /// Simple offline triage using rule-based logic
  /// This runs entirely on the device without internet
  TriageResult analyzeOffline(SymptomReport report) {
    final text = report.textInput.toLowerCase();
    
    // Emergency red flags
    final emergencyKeywords = [
      'chest pain',
      'difficulty breathing',
      'can\'t breathe',
      'unconscious',
      'severe bleeding',
      'stroke',
      'seizure',
      'suicide',
    ];
    
    for (final keyword in emergencyKeywords) {
      if (text.contains(keyword)) {
        return TriageResult(
          urgencyLevel: 'emergency',
          recommendation: '⚠️ SEEK IMMEDIATE MEDICAL ATTENTION\nCall emergency services (108/102)',
          explanation: 'Your symptoms indicate a potentially life-threatening condition.',
          confidence: 1.0,
          redFlags: [keyword],
          nextSteps: [
            'Call emergency services immediately',
            'Do not drive yourself to hospital',
            'Stay calm and sit or lie down',
            'Have someone stay with you'
          ],
          isOfflineResult: true,
        );
      }
    }
    
    // Doctor visit needed
    final doctorKeywords = [
      'fever',
      'persistent',
      'severe pain',
      'vomiting',
      'diarrhea',
      'days',
      'week',
    ];
    
    int doctorMatches = 0;
    for (final keyword in doctorKeywords) {
      if (text.contains(keyword)) doctorMatches++;
    }
    
    if (doctorMatches >= 2) {
      return TriageResult(
        urgencyLevel: 'doctor',
        recommendation: 'Consult a doctor within 24-48 hours',
        explanation: 'Your symptoms suggest you should see a healthcare professional.',
        confidence: 0.7,
        redFlags: [],
        nextSteps: [
          'Schedule a doctor appointment',
          'Monitor your symptoms',
          'Rest and stay hydrated',
          'Seek immediate care if symptoms worsen'
        ],
        isOfflineResult: true,
      );
    }
    
    // Self-care
    return TriageResult(
      urgencyLevel: 'self-care',
      recommendation: 'Monitor symptoms and practice self-care',
      explanation: 'Your symptoms may be manageable at home with rest and care.',
      confidence: 0.6,
      redFlags: [],
      nextSteps: [
        'Get adequate rest',
        'Drink plenty of fluids',
        'Monitor your temperature',
        'Seek medical care if symptoms persist beyond 3 days',
        'Watch for worsening symptoms'
      ],
      isOfflineResult: true,
    );
  }
}
