"""
Test session memory and context-aware extraction
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

print("\n" + "="*70)
print("SESSION MEMORY TEST - Simulating User's Issue")
print("="*70)

user_id = "session_test_user"

# Conversation flow similar to user's issue
messages = [
    "Hi",
    "I am having fever and headache",
    "9"  # This should be understood as severity answer
]

for i, msg in enumerate(messages, 1):
    print(f"\n[Turn {i}]")
    print(f"👤 USER: {msg}")
    
    result = chat(user_id, msg)
    bot_response = result.get('recommendation', 'No response')
    
    print(f"🤖 BOT: {bot_response}")
    print(f"   Level: {result.get('urgencyLevel')}")
    
    time.sleep(1)  # Small delay between messages

print("\n" + "="*70)
print("✅ Test Complete!")
print("="*70)
print("\nExpected behavior:")
print("- Turn 1: Bot should greet")
print("- Turn 2: Bot should ask about severity or duration")
print("- Turn 3: Bot should understand '9' as severity and either:")
print("         a) Ask for duration, or")
print("         b) Provide triage result")
print("="*70 + "\n")
