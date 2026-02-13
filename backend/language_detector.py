"""
MODEL 1: Language Detection Model (LIGHTWEIGHT)

Purpose: Detect which language the user is speaking/typing
Uses: langdetect library (accurate and easy to install)
No training needed - uses pretrained model

Usage:
    from language_detector import LanguageDetector
    
    detector = LanguageDetector()
    result = detector.detect("मुझे सिरदर्द है")
    print(result)  # {"language": "hi", "confidence": 0.99}
"""

from langdetect import detect, detect_langs, LangDetectException
from typing import Dict


class LanguageDetector:
    """
    Language detection model supporting 55+ languages.
    
    Supports all required Indian languages:
    - Hindi (hi), English (en), Marathi (mr), Gujarati (gu)
    - Punjabi (pa), Telugu (te), Tamil (ta), Bengali (bn)
    - Kannada (kn), Malayalam (ml), Urdu (ur)
    """
    
    def __init__(self):
        """Initialize the language detector."""
        print("✅ Language detection model ready!")
    
    def detect(self, text: str) -> Dict[str, any]:
        """
        Detect the language of the input text.
        
        Args:
            text: Input text to analyze
            
        Returns:
            dict: Dictionary containing language code and confidence score
            Example: {"language": "hi", "confidence": 0.97}
        """
        if not text or not text.strip():
            return {
                "language": "unknown",
                "confidence": 0.0
            }
        
        try:
            # Clean text - replace newlines with spaces
            text = text.replace('\n', ' ').strip()
            
            # Get predictions with probabilities
            langs = detect_langs(text)
            
            if langs:
                # Get the most probable language
                top_lang = langs[0]
                return {
                    "language": top_lang.lang,
                    "confidence": round(top_lang.prob, 2)
                }
            else:
                return {
                    "language": "unknown",
                    "confidence": 0.0
                }
                
        except LangDetectException:
            # If detection fails, return unknown
            return {
                "language": "unknown",
                "confidence": 0.0
            }
    
    def detect_batch(self, texts: list) -> list:
        """
        Detect languages for multiple texts.
        
        Args:
            texts: List of text strings
            
        Returns:
            list: List of detection results
        """
        return [self.detect(text) for text in texts]


# Example usage
if __name__ == "__main__":
    # Initialize detector
    detector = LanguageDetector()
    
    # Test with sample texts
    test_cases = [
        "Hello, how are you?",           # English
        "नमस्ते, आप कैसे हैं?",         # Hindi
        "तुमचं नाव काय आहे?",            # Marathi
        "તમે કેમ છો?",                   # Gujarati
        "ਤੁਸੀਂ ਕਿਵੇਂ ਹੋ?",              # Punjabi
        "నమస్కారం",                     # Telugu
        "வணக்கம்",                      # Tamil
        "আপনি কেমন আছেন?",              # Bengali
        "ನಮಸ್ಕಾರ",                      # Kannada
        "का हाल बा?",                    # Bhojpuri
    ]
    
    print("\n" + "="*60)
    print("Language Detection Examples")
    print("="*60)
    
    for text in test_cases:
        result = detector.detect(text)
        print(f"\nText: {text}")
        print(f"Language: {result['language']} (confidence: {result['confidence']})")
