"""
Translation Module for Healthcare Triage System

Purpose: Translate user input to English and responses back to user language
Supports: Pluggable translation backends (Google Translate via deep-translator, or Mock)

IMPORTANT: Translation is ONLY for language conversion, NOT for changing medical meaning
"""

from typing import Dict, Optional
import warnings

# Try to import deep_translator
try:
    from deep_translator import GoogleTranslator
    DEEP_TRANSLATOR_AVAILABLE = True
except ImportError:
    DEEP_TRANSLATOR_AVAILABLE = False
    warnings.warn("deep-translator not installed. Using mock translator. Install with: pip install deep-translator")


class TranslationService:
    """
    Pluggable translation service for healthcare chatbot
    
    Supports multiple backends:
    - Google Translate via deep-translator (reliable, free)
    - Mock translator (fallback for development)
    """
    
    # Supported languages with their codes
    SUPPORTED_LANGUAGES = {
        'en': 'english',
        'hi': 'hindi',
        'mr': 'marathi',
        'gu': 'gujarati',
        'pa': 'punjabi',
        'te': 'telugu',
        'ta': 'tamil',
        'bn': 'bengali',
        'kn': 'kannada',
        'bho': 'hindi'  # Bhojpuri maps to Hindi for translation
    }
    
    # Display names for languages
    LANGUAGE_NAMES = {
        'en': 'English',
        'hi': 'Hindi',
        'mr': 'Marathi',
        'gu': 'Gujarati',
        'pa': 'Punjabi',
        'te': 'Telugu',
        'ta': 'Tamil',
        'bn': 'Bengali',
        'kn': 'Kannada',
        'bho': 'Bhojpuri'
    }
    
    def __init__(self, backend: str = "auto"):
        """
        Initialize translation service
        
        Args:
            backend: Translation backend ("google", "mock", or "auto")
        """
        self.backend = backend
        
        if backend == "auto":
            self.backend = "google" if DEEP_TRANSLATOR_AVAILABLE else "mock"
        
        if self.backend == "google":
            if not DEEP_TRANSLATOR_AVAILABLE:
                print("⚠️ deep-translator not available, using mock translator")
                self.backend = "mock"
            else:
                print("✅ Google Translate (via deep-translator) initialized")
        else:
            print("✅ Mock translator initialized (development mode)")
    
    def translate_to_english(self, text: str, source_lang: str) -> str:
        """
        Translate text from source language to English
        
        Args:
            text: Text to translate
            source_lang: Source language code (e.g., 'hi', 'mr')
            
        Returns:
            Translated English text
        """
        # If already English, return as-is
        if source_lang == 'en':
            return text
        
        # Validate language support
        if source_lang not in self.SUPPORTED_LANGUAGES:
            print(f"⚠️ Unsupported language: {source_lang}, returning original text")
            return text
        
        if self.backend == "google":
            try:
                # Get the target language name for deep-translator
                source_name = self.SUPPORTED_LANGUAGES.get(source_lang, 'auto')
                translator = GoogleTranslator(source=source_name, target='english')
                translated = translator.translate(text)
                print(f"📝 Translated ({source_lang} → en): {text[:50]}... → {translated[:50]}...")
                return translated
            except Exception as e:
                print(f"⚠️ Translation error: {e}, returning original text")
                return text
        
        else:  # Mock translator
            # For development: return original text with a marker
            print(f"🔧 Mock translation ({source_lang} → en): {text[:50]}...")
            return f"[MOCK_EN] {text}"
    
    def translate_from_english(self, text: str, target_lang: str) -> str:
        """
        Translate text from English to target language
        
        Args:
            text: English text to translate
            target_lang: Target language code
            
        Returns:
            Translated text in target language
        """
        # If target is English, return as-is
        if target_lang == 'en':
            return text
        
        # Validate language support
        if target_lang not in self.SUPPORTED_LANGUAGES:
            print(f"⚠️ Unsupported language: {target_lang}, returning English text")
            return text
        
        if self.backend == "google":
            try:
                # Get the target language name for deep-translator
                target_name = self.SUPPORTED_LANGUAGES.get(target_lang, target_lang)
                translator = GoogleTranslator(source='english', target=target_name)
                translated = translator.translate(text)
                print(f"📝 Translated (en → {target_lang}): {text[:50]}... → {translated[:50]}...")
                return translated
            except Exception as e:
                print(f"⚠️ Translation error: {e}, returning English text")
                return text
        
        else:  # Mock translator
            # For development: return text with a marker
            print(f"🔧 Mock translation (en → {target_lang}): {text[:50]}...")
            return f"[MOCK_{target_lang.upper()}] {text}"
    
    def get_language_name(self, lang_code: str) -> str:
        """Get language name from code"""
        return self.LANGUAGE_NAMES.get(lang_code, "Unknown")


# Singleton instance
_translation_service = None

def get_translator(backend: str = "auto") -> TranslationService:
    """Get or create singleton translator instance"""
    global _translation_service
    if _translation_service is None:
        _translation_service = TranslationService(backend=backend)
    return _translation_service


def translate_to_english(text: str, source_lang: str) -> str:
    """Convenience function to translate to English"""
    translator = get_translator()
    return translator.translate_to_english(text, source_lang)


def translate_from_english(text: str, target_lang: str) -> str:
    """Convenience function to translate from English"""
    translator = get_translator()
    return translator.translate_from_english(text, target_lang)


# Usage example
if __name__ == "__main__":
    # Test the translator
    translator = get_translator()
    
    print("\n" + "="*70)
    print("Translation Service Test")
    print("="*70)
    
    # Test cases
    test_cases = [
        ("Hello, how are you?", "en", "hi"),
        ("I have fever and headache", "en", "mr"),
        ("मुझे बुखार है", "hi", "en"),
    ]
    
    for text, src, tgt in test_cases:
        print(f"\nOriginal ({src}): {text}")
        if src != "en":
            translated = translator.translate_to_english(text, src)
            print(f"English: {translated}")
        else:
            translated = translator.translate_from_english(text, tgt)
            print(f"Translated ({tgt}): {translated}")
        print("-"*70)
