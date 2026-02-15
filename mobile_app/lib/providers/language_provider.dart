import 'package:flutter/material.dart';
import '../services/translation_service.dart';

class LanguageProvider with ChangeNotifier {
  String _currentLanguage = 'en';
  final TranslationService _translationService = TranslationService();
  bool _isLoading = false;

  String get currentLanguage => _currentLanguage;
  bool get isLoading => _isLoading;

  Future<void> setLanguage(String languageCode) async {
    if (_currentLanguage == languageCode) return;

    _isLoading = true;
    notifyListeners();

    await _translationService.load(languageCode);
    _currentLanguage = languageCode;

    _isLoading = false;
    notifyListeners();
  }

  String translate(String key, {Map<String, String>? params}) {
    return _translationService.translate(key, params: params);
  }

  // Short alias for translate
  String t(String key, {Map<String, String>? params}) {
    return translate(key, params: params);
  }

  String getLanguageName() {
    switch (_currentLanguage) {
      case 'hi':
        return 'Hindi';
      case 'te':
        return 'Telugu';
      case 'ta':
        return 'Tamil';
      case 'bn':
        return 'Bengali';
      case 'mr':
        return 'Marathi';
      case 'kn':
        return 'Kannada';
      case 'gu':
        return 'Gujarati';
      case 'bh':
        return 'Bhojpuri';
      case 'pa':
        return 'Punjabi';
      default:
        return 'English';
    }
  }

  String getLanguageCode() {
    switch (_currentLanguage) {
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
        return 'bh-IN';
      case 'pa':
        return 'pa-IN';
      default:
        return 'en-US';
    }
  }
}
