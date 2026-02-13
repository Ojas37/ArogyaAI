"""
Test script for language detection API
"""

import requests
import json

# Base URL
BASE_URL = "http://localhost:8000/api/v1"

def test_health():
    """Test health endpoint"""
    print("\n" + "="*60)
    print("1. Testing Health Endpoint")
    print("="*60)
    
    try:
        response = requests.get(f"{BASE_URL}/health")
        print(f"Status Code: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}")
    except Exception as e:
        print(f"❌ Error: {e}")

def test_language_detection():
    """Test language detection endpoint"""
    print("\n" + "="*60)
    print("2. Testing Language Detection Endpoint")
    print("="*60)
    
    test_cases = [
        ("Hello, how are you?", "English"),
        ("मुझे सिरदर्द है", "Hindi"),
        ("నాకు తలనొప్పి ఉంది", "Telugu"),
        ("எனக்கு தலைவலி உள்ளது", "Tamil"),
        ("আমার মাথাব্যথা আছে", "Bengali"),
    ]
    
    for text, expected_lang in test_cases:
        try:
            response = requests.post(
                f"{BASE_URL}/language/detect",
                json={"text": text}
            )
            
            if response.status_code == 200:
                result = response.json()
                print(f"\n✅ Text: {text[:30]:30}")
                print(f"   Detected: {result['language']} ({result.get('detected_language_name', 'N/A')})")
                print(f"   Confidence: {result['confidence']}")
            else:
                print(f"\n❌ Error: Status {response.status_code}")
                print(f"   Response: {response.text}")
                
        except Exception as e:
            print(f"\n❌ Error: {e}")

    print("\n" + "="*60)

def test_intent_classification():
    """Test intent classification endpoint"""
    print("\n" + "="*60)
    print("3. Testing Intent Classification Endpoint")
    print("="*60)
    
    test_cases = [
        ("I have severe chest pain and difficulty breathing", "emergency"),
        ("What causes headaches?", "question"),
        ("I want to schedule an appointment", "appointment"),
        ("My fever has been going on for 3 days", "symptom_reporting"),
        ("What is the dosage for paracetamol?", "medication"),
        ("I'm feeling better after taking the medicine", "follow_up"),
    ]
    
    for text, expected_intent in test_cases:
        try:
            response = requests.post(
                f"{BASE_URL}/intent/classify",
                json={"text": text, "top_k": 3}
            )
            
            if response.status_code == 200:
                result = response.json()
                print(f"\n✅ Text: {text[:50]}")
                print(f"   Intent: {result['intent']} (confidence: {result['confidence']:.2%})")
                print(f"   Top predictions:")
                for pred in result.get('all_predictions', [])[:3]:
                    print(f"      - {pred['intent']}: {pred['confidence']:.2%}")
            else:
                print(f"\n❌ Error: Status {response.status_code}")
                print(f"   Response: {response.text}")
                
        except Exception as e:
            print(f"\n❌ Error: {e}")

    print("\n" + "="*60)

if __name__ == "__main__":
    print("\nTesting ArogyaAI Backend API")
    print("="*60)
    
    test_health()
    test_language_detection()
    test_intent_classification()
    
    print("\n✅ Testing Complete!")
    print("="*60 + "\n")
