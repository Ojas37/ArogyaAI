import 'package:flutter/services.dart';
import 'dart:convert';

class TranslationService {
  Map<String, dynamic> _translations = {};
  String _currentLanguage = 'en';

  Future<void> load(String languageCode) async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/translations/$languageCode.json',
      );
      _translations = json.decode(jsonString);
      _currentLanguage = languageCode;
    } catch (e) {
      // Fallback to English if translation file not found
      if (languageCode != 'en') {
        await load('en');
      } else {
        _translations = {};
      }
    }
  }

  String translate(String key, {Map<String, String>? params}) {
    final keys = key.split('.');
    dynamic value = _translations;

    for (final k in keys) {
      if (value is Map && value.containsKey(k)) {
        value = value[k];
      } else {
        return key; // Return key if translation not found
      }
    }

    String result = value.toString();

    // Replace parameters if provided
    if (params != null) {
      params.forEach((key, value) {
        result = result.replaceAll('{$key}', value);
      });
    }

    return result;
  }

  String get currentLanguage => _currentLanguage;
}
