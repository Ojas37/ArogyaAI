"""
Test script for language detection integration
Run this to verify the language detector is working properly
"""

from language_detector import LanguageDetector

def test_language_detector():
    print("\n" + "="*60)
    print("Testing Language Detection Model")
    print("="*60)
    
    # Initialize detector
    print("\n1. Initializing detector...")
    detector = LanguageDetector()
    
    # Test cases for Indian languages
    test_cases = [
        ("Hello, how are you?", "en", "English"),
        ("नमस्ते, आप कैसे हैं?", "hi", "Hindi"),
        ("मुझे सिरदर्द है", "hi", "Hindi"),
        ("నాకు తలనొప్పి ఉంది", "te", "Telugu"),
        ("எனக்கு தலைவலி உள்ளது", "ta", "Tamil"),
        ("আমার মাথাব্যথা আছে", "bn", "Bengali"),
        ("મને માથાનો દુખાવો છે", "gu", "Gujarati"),
        ("ನನಗೆ ತಲೆನೋವು ಇದೆ", "kn", "Kannada"),
        ("I have fever and headache", "en", "English"),
    ]
    
    print("\n2. Running test cases...\n")
    
    passed = 0
    failed = 0
    
    for text, expected_lang, lang_name in test_cases:
        result = detector.detect(text)
        detected = result["language"]
        confidence = result["confidence"]
        
        status = "✅ PASS" if detected == expected_lang else "❌ FAIL"
        if detected == expected_lang:
            passed += 1
        else:
            failed += 1
            
        print(f"{status} | Text: {text[:30]:30} | Expected: {expected_lang:3} | Detected: {detected:3} | Confidence: {confidence:.2f}")
    
    print("\n" + "="*60)
    print(f"Results: {passed} passed, {failed} failed out of {len(test_cases)} tests")
    print("="*60 + "\n")
    
    return passed, failed

if __name__ == "__main__":
    test_language_detector()
