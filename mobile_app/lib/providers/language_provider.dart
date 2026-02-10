import 'package:flutter/material.dart';

class LanguageProvider with ChangeNotifier {
  String _currentLanguage = 'en';

  String get currentLanguage => _currentLanguage;

  void setLanguage(String languageCode) {
    _currentLanguage = languageCode;
    notifyListeners();
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
