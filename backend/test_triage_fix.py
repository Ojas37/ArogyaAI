"""
Test the CRITICAL TRIAGE FIXES
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

print("\n" + "="*80)
print("🚨 TEST 1: EMERGENCY SYMPTOMS (Red Flag Override)")
print("="*80)
print("Expected: Immediate EMERGENCY triage, no follow-up questions\n")

user_id = "emergency_test"
msg = "I have severe chest pain and can't breathe"
print(f"👤 USER: {msg}")
result = chat(user_id, msg)
print(f"🤖 BOT: {result.get('recommendation')}")
print(f"   Level: {result.get('urgencyLevel')}")
print(f"   Mode: {result.get('mode', 'N/A')}")

if result.get('urgencyLevel') == 'emergency':
    print("   ✅ PASS: Emergency detected!")
else:
    print(f"   ❌ FAIL: Expected 'emergency', got '{result.get('urgencyLevel')}'")

print("\n" + "="*80)
print("✅ TEST 2: COMPLETE SYMPTOM INFO (Should Trigger Triage)")
print("="*80)
print("Expected: Triage result shown, not stuck in conversation loop\n")

user_id = "complete_test"
msg = "I have fever and headache for 3 days. Severity is 7 out of 10."
print(f"👤 USER: {msg}")
result = chat(user_id, msg)
print(f"🤖 BOT: {result.get('recommendation')}")
print(f"   Level: {result.get('urgencyLevel')}")
print(f"   Mode: {result.get('mode', 'N/A')}")

if result.get('urgencyLevel') in ['emergency', 'doctor', 'self-care']:
    print("   ✅ PASS: Triage result returned!")
elif result.get('urgencyLevel') == 'clarification':
    print("   ⚠️  Still asking questions (may need one more)")
else:
    print(f"   ❌ FAIL: Expected triage, got '{result.get('urgencyLevel')}'")

print("\n" + "="*80)
print("💬 TEST 3: INCOMPLETE INFO (Session Memory Test)")
print("="*80)
print("Expected: Ask follow-up, then show triage after user answers\n")

user_id = "session_test"
messages = [
    "I have a fever",
    "For 3 days",
    "8 out of 10"
]

for i, msg in enumerate(messages, 1):
    print(f"\n[Turn {i}]")
    print(f"👤 USER: {msg}")
    result = chat(user_id, msg)
    print(f"🤖 BOT: {result.get('recommendation')[:100]}...")
    print(f"   Level: {result.get('urgencyLevel')}")
    time.sleep(1)

if result.get('urgencyLevel') in ['emergency', 'doctor', 'self-care']:
    print("\n   ✅ PASS: Final triage shown after gathering info!")
else:
    print(f"\n   ❌ FAIL: Still in loop, level = '{result.get('urgencyLevel')}'")

print("\n" + "="*80)
print("📊 TEST SUMMARY")
print("="*80)
print("The fixes should ensure:")
print("1. ✅ Red-flag symptoms trigger immediate EMERGENCY triage")
print("2. ✅ Complete info triggers triage (not endless conversation)")
print("3. ✅ Session memory preserves context across turns")
print("4. ✅ 'mode' field signals frontend: 'chat' or 'final_triage'")
print("="*80 + "\n")
