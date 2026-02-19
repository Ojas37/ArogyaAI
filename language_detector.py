"""
MODEL 1: Language Detection Model (VERY SMALL)

Purpose: Detect which language the user is speaking/typing
Model: fastText lid.176.bin (126MB, 176 languages)
No training needed - uses pretrained model

Usage:
    from language_detector import LanguageDetector
    
    detector = LanguageDetector()
    result = detector.detect("मुझे सिरदर्द है")
    print(result)  # {"language": "hi", "confidence": 0.97}
"""

import fasttext
import urllib.request
import os
from typing import Dict


class LanguageDetector:
    """
    Language detection model supporting 176 languages.
    
    Supports all required Indian languages:
    - Hindi (hi), English (en), Marathi (mr), Gujarati (gu)
    - Punjabi (pa), Telugu (te), Tamil (ta), Bengali (bn)
    - Kannada (kn), Bhojpuri (bho)
    """
    
    def __init__(self, model_path: str = "lid.176.bin"):
        """
        Initialize the language detector.
        
        Args:
            model_path: Path to the fastText model file
        """
        self.model_path = model_path
        self.model = None
        self._load_model()
    
    def _load_model(self):
        """Download and load the fastText language detection model."""
        # Download model if not exists
        if not os.path.exists(self.model_path):
            print(f"Downloading fastText model to {self.model_path}...")
            url = "https://dl.fbaipublicfiles.com/fasttext/supervised-models/lid.176.bin"
            urllib.request.urlretrieve(url, self.model_path)
            print("✅ Download complete!")
        
        # Load model
        self.model = fasttext.load_model(self.model_path)
        print(f"✅ Language detection model loaded successfully!")
    
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
        
        # Clean text - replace newlines with spaces
        text = text.replace('\n', ' ').strip()
        
        # Get prediction from fastText
        predictions = self.model.predict(text, k=1)
        
        # Extract language code (remove __label__ prefix)
        language_code = predictions[0][0].replace('__label__', '')
        confidence_score = float(predictions[1][0])
        
        # Format output
        return {
            "language": language_code,
            "confidence": round(confidence_score, 2)
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
