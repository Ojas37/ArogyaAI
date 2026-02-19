"""
Test conversational flow with multiple turns
"""
import requests
import json
from datetime import datetime
import time

API_URL = "http://127.0.0.1:8000/api/v1/symptom/analyze"

def chat(user_id, message):
    """Send a message and get response"""
    response = requests.post(
        API_URL,
        json={
            'userId': user_id,
            'language': 'en',
            'textInput': message,
            'symptoms': [],
            'timestamp': datetime.now().isoformat()
        },
        timeout=40
    )
    return response.json()

def print_response(bot_response):
    """Pretty print bot response"""
    print(f"  Level: {bot_response.get('urgencyLevel')}")
    print(f"  Response: {bot_response.get('recommendation')}")
    print(f"  Confidence: {bot_response.get('confidence', 0):.2%}")
    print()

# Test 1: Simple greeting
print("\n" + "="*60)
print("TEST 1: Greeting")
print("="*60)
print("USER: Hello")
response = chat("test1", "Hello")
print_response(response)

# Test 2: Complete symptom description (should get triage)
print("\n" + "="*60)
print("TEST 2: Complete Symptom Description")
print("="*60)
print("USER: I have severe chest pain for 2 hours now. Pain level is 9/10")
response = chat("test2", "I have severe chest pain for 2 hours now. Pain level is 9/10")
print_response(response)

# Test 3: Incomplete symptom (should ask follow-up)
print("\n" + "="*60)
print("TEST 3: Incomplete Symptom")
print("="*60)
print("USER: I have a headache")
response = chat("test3", "I have a headache")
print_response(response)

# Test 4: Multilingual (Hindi)
print("\n" + "="*60)
print("TEST 4: Multilingual Support")
print("="*60)
print("USER: मुझे तेज बुखार है। तीन दिन से। बहुत तेज है")
response = chat("test4", "मुझे तेज बुखार है। तीन दिन से। बहुत तेज है")
print_response(response)

print("\n" + "="*60)
print("✅ All tests complete!")
print("="*60)
