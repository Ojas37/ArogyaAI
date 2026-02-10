class TriageResult {
  final String urgencyLevel; // "self-care", "doctor", "emergency"
  final String recommendation;
  final String explanation;
  final double confidence;
  final List<String> redFlags;
  final List<String> nextSteps;
  final bool isOfflineResult;

  TriageResult({
    required this.urgencyLevel,
    required this.recommendation,
    required this.explanation,
    required this.confidence,
    required this.redFlags,
    required this.nextSteps,
    this.isOfflineResult = false,
  });

  factory TriageResult.fromJson(Map<String, dynamic> json) {
    return TriageResult(
      urgencyLevel: json['urgencyLevel'],
      recommendation: json['recommendation'],
      explanation: json['explanation'],
      confidence: json['confidence'].toDouble(),
      redFlags: List<String>.from(json['redFlags'] ?? []),
      nextSteps: List<String>.from(json['nextSteps'] ?? []),
      isOfflineResult: json['isOfflineResult'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'urgencyLevel': urgencyLevel,
      'recommendation': recommendation,
      'explanation': explanation,
      'confidence': confidence,
      'redFlags': redFlags,
      'nextSteps': nextSteps,
      'isOfflineResult': isOfflineResult,
    };
  }
}
