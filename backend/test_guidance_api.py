"""
Test Guidance Generator API endpoints
"""
import requests
import json
from datetime import datetime

BASE_URL = "http://localhost:8000"

print("="*80)
print("TESTING GUIDANCE GENERATOR API")
print("="*80)
print("\nMake sure the backend server is running:")
print("  cd C:\\Deepblue\\backend")
print("  .\\venv\\Scripts\\python.exe -m uvicorn main:app --reload")
print("\nPress Enter to continue...")
input()

# Test 1: Emergency guidance in English
print("\n" + "="*80)
print("TEST 1: Emergency Guidance (English)")
print("="*80)

test_data = {
    "urgencyLevel": "emergency",
    "language": "en",
    "symptoms": ["chest pain", "difficulty breathing", "severe headache"],
    "severity": "severe"
}

try:
    response = requests.post(f"{BASE_URL}/api/v1/guidance/generate", json=test_data)
    if response.status_code == 200:
        result = response.json()
        print(f"\n✅ Status: {response.status_code}")
        print(f"📋 Message: {result['message']}")
        print(f"📝 Description: {result['description']}")
        print(f"\n✅ Actions ({len(result['actions'])} total):")
        for action in result['actions'][:3]:
            print(f"   • {action}")
        print(f"\n❌ Do NOT ({len(result['do_not'])} total):")
        for dont in result['do_not'][:2]:
            print(f"   • {dont}")
        print(f"\n⚠️  Warnings: {len(result['warnings'])} items")
        print(f"\n📞 Emergency Contacts:")
        for service, number in list(result['emergency_contacts'].items())[:3]:
            print(f"   {service}: {number}")
    else:
        print(f"❌ Error: {response.status_code}")
        print(response.text)
except Exception as e:
    print(f"❌ Connection error: {e}")
    print("Make sure the server is running!")

# Test 2: Doctor visit guidance in Hindi
print("\n" + "="*80)
print("TEST 2: Doctor Visit Guidance (Hindi)")
print("="*80)

test_data = {
    "urgencyLevel": "doctor",
    "language": "hi",
    "symptoms": ["बुखार", "सिर दर्द", "उल्टी"],
    "severity": "high"
}

try:
    response = requests.post(f"{BASE_URL}/api/v1/guidance/generate", json=test_data)
    if response.status_code == 200:
        result = response.json()
        print(f"\n✅ Status: {response.status_code}")
        print(f"📋 Message: {result['message']}")
        print(f"📝 Description: {result['description']}")
        print(f"\n✅ Actions: {len(result['actions'])} total")
        for action in result['actions'][:2]:
            print(f"   • {action}")
        print(f"\n📊 Metadata: {json.dumps(result['metadata'], ensure_ascii=False)}")
    else:
        print(f"❌ Error: {response.status_code}")
except Exception as e:
    print(f"❌ Error: {e}")

# Test 3: Self-care guidance
print("\n" + "="*80)
print("TEST 3: Self-care Guidance (English)")
print("="*80)

test_data = {
    "urgencyLevel": "self-care",
    "language": "en",
    "symptoms": ["mild headache", "tiredness"],
    "severity": "mild"
}

try:
    response = requests.post(f"{BASE_URL}/api/v1/guidance/generate", json=test_data)
    if response.status_code == 200:
        result = response.json()
        print(f"\n✅ Status: {response.status_code}")
        print(f"📋 Message: {result['message']}")
        print(f"\n✅ Actions: {len(result['actions'])} items")
        print(f"❌ Do NOT: {len(result['do_not'])} items")
        print(f"⚠️  When to seek doctor: {len(result['warnings'])} items")
    else:
        print(f"❌ Error: {response.status_code}")
except Exception as e:
    print(f"❌ Error: {e}")

# Test 4: Get emergency contacts
print("\n" + "="*80)
print("TEST 4: Emergency Contacts (Hindi)")
print("="*80)

try:
    response = requests.get(f"{BASE_URL}/api/v1/guidance/emergency-contacts?language=hi")
    if response.status_code == 200:
        result = response.json()
        print(f"\n✅ Status: {response.status_code}")
        print(f"📞 Emergency Contacts:")
        for service, number in result['contacts'].items():
            print(f"   {service}: {number}")
    else:
        print(f"❌ Error: {response.status_code}")
except Exception as e:
    print(f"❌ Error: {e}")

# Test 5: Multiple languages
print("\n" + "="*80)
print("TEST 5: Self-care in Marathi")
print("="*80)

test_data = {
    "urgencyLevel": "self-care",
    "language": "mr",
    "symptoms": ["हलका ताप"],
    "severity": "mild"
}

try:
    response = requests.post(f"{BASE_URL}/api/v1/guidance/generate", json=test_data)
    if response.status_code == 200:
        result = response.json()
        print(f"\n✅ Status: {response.status_code}")
        print(f"📋 Message: {result['message']}")
        print(f"📊 Language: {result['language']}")
        print(f"⚠️  Urgency: {result['urgency_level']}")
    else:
        print(f"❌ Error: {response.status_code}")
except Exception as e:
    print(f"❌ Error: {e}")

print("\n" + "="*80)
print("TESTING COMPLETE")
print("="*80)
print("\nAll 6 Models Created:")
print("  ✅ Model 1: Language Detection")
print("  ✅ Model 2: Symptom Extraction (NER)")
print("  ✅ Model 3: Intent Classification")
print("  ✅ Model 4: Triage/Urgency Classification")
print("  ✅ Model 5: Disease Knowledge Base")
print("  ✅ Model 6: Guidance Generator (NEW!)")
print("="*80)
