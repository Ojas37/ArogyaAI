import requests
from datetime import datetime

print("\n=== TESTING CONVERSATIONAL AI ===\n")

# Test 1: Initial symptom
response = requests.post(
    'http://127.0.0.1:8000/api/v1/symptom/analyze',
    json={
        'userId': 'quick_test',
        'language': 'en',
        'textInput': 'I have a fever',
        'symptoms': [],
        'timestamp': datetime.now().isoformat()
    },
    timeout=30
)

result = response.json()
print("👤 User: I have a fever")
print(f"🤖 AI: {result['recommendation']}")
print(f"   Type: {result['urgencyLevel']}")
print(f"   Confidence: {result['confidence']:.1%}\n")

print("✅ Conversational AI is working!")
print("🌐 Open Chrome and test the app at: ArogyaAI Health tab\n")
