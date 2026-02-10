import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;

  Future<String> listen(String languageCode) async {
    if (!_isInitialized) {
      _isInitialized = await _speech.initialize(
        onError: (error) => throw Exception(error.errorMsg),
      );
    }

    if (!_isInitialized) {
      throw Exception('Speech recognition not available');
    }

    String result = '';
    
    await _speech.listen(
      onResult: (val) {
        result = val.recognizedWords;
      },
      localeId: _getLocaleId(languageCode),
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
    );

    // Wait for listening to complete
    await Future.delayed(const Duration(seconds: 5));
    await _speech.stop();

    return result;
  }

  String _getLocaleId(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'hi-IN';
      case 'te':
        return 'te-IN';
      case 'ta':
        return 'ta-IN';
      case 'bn':
        return 'bn-IN';
      case 'mr':
        return 'mr-IN';
      case 'kn':
        return 'kn-IN';
      case 'gu':
        return 'gu-IN';
      case 'bh':
        return 'hi-IN'; // Bhojpuri uses Hindi locale
      case 'pa':
        return 'pa-IN';
      default:
        return 'en-US';
    }
  }

  Future<void> stop() async {
    await _speech.stop();
  }

  bool get isListening => _speech.isListening;
}
