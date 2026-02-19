from triage_engine import classify_symptoms
import json

print("\n" + "="*70)
print("🏥 TRIAGE MODEL TEST")
print("="*70)

test_cases = [
    # ======= SELF_CARE Cases (Common mild conditions) =======
    {
        "name": "Normal Cough (1 day, mild) - SHOULD BE SELF_CARE",
        "data": {
            "symptoms": ["cough"],
            "severity": "mild",
            "duration": "1 day",
            "body_parts": []
        },
        "expected": "SELF_CARE"
    },
    {
        "name": "Normal Cold (1 day, mild) - SHOULD BE SELF_CARE",
        "data": {
            "symptoms": ["cold", "runny nose"],
            "severity": "mild",
            "duration": "1 day",
            "body_parts": []
        },
        "expected": "SELF_CARE"
    },
    {
        "name": "Mild Sore Throat (few hours) - SHOULD BE SELF_CARE",
        "data": {
            "symptoms": ["sore throat"],
            "severity": "mild",
            "duration": "few hours",
            "body_parts": []
        },
        "expected": "SELF_CARE"
    },
    {
        "name": "Sneezing (1 day) - SHOULD BE SELF_CARE",
        "data": {
            "symptoms": ["sneezing"],
            "severity": "mild",
            "duration": "1 day",
            "body_parts": []
        },
        "expected": "SELF_CARE"
    },
    {
        "name": "Stuffy Nose (today) - SHOULD BE SELF_CARE",
        "data": {
            "symptoms": ["stuffy nose", "congestion"],
            "severity": "mild",
            "duration": "today",
            "body_parts": []
        },
        "expected": "SELF_CARE"
    },
    {
        "name": "Mild Fatigue (1 day) - SHOULD BE SELF_CARE",
        "data": {
            "symptoms": ["tired", "fatigue"],
            "severity": "slight",
            "duration": "1 day",
            "body_parts": []
        },
        "expected": "SELF_CARE"
    },
    {
        "name": "Minor Muscle Ache (few hours) - SHOULD BE SELF_CARE",
        "data": {
            "symptoms": ["muscle ache"],
            "severity": "mild",
            "duration": "few hours",
            "body_parts": []
        },
        "expected": "SELF_CARE"
    },
    
    # ======= URGENT Cases (Need doctor within 24-48h) =======
    {
        "name": "Mild Fever (1 day) - URGENT",
        "data": {
            "symptoms": ["fever"],
            "severity": "mild",
            "duration": "1 day",
            "body_parts": []
        },
        "expected": "URGENT"
    },
    {
        "name": "Persistent Cough (5 days) - URGENT",
        "data": {
            "symptoms": ["cough"],
            "severity": "moderate",
            "duration": "5 days",
            "body_parts": []
        },
        "expected": "URGENT"
    },
    {
        "name": "Moderate Headache (3 days) - URGENT",
        "data": {
            "symptoms": ["headache"],
            "severity": "moderate",
            "duration": "3 days",
            "body_parts": ["Head"]
        },
        "expected": "URGENT"
    },
    {
        "name": "Stomach Pain (2 days) - URGENT",
        "data": {
            "symptoms": ["stomach pain", "abdominal pain"],
            "severity": "moderate",
            "duration": "2 days",
            "body_parts": ["Abdomen"]
        },
        "expected": "URGENT"
    },
    {
        "name": "High Fever (1 day) - URGENT",
        "data": {
            "symptoms": ["high fever", "temperature"],
            "severity": "moderate",
            "duration": "1 day",
            "body_parts": []
        },
        "expected": "URGENT"
    },
    {
        "name": "Diarrhea (1 day) - URGENT",
        "data": {
            "symptoms": ["diarrhea"],
            "severity": "moderate",
            "duration": "1 day",
            "body_parts": []
        },
        "expected": "URGENT"
    },
    {
        "name": "Nausea and Vomiting (few hours) - URGENT",
        "data": {
            "symptoms": ["nausea", "vomiting"],
            "severity": "moderate",
            "duration": "few hours",
            "body_parts": []
        },
        "expected": "URGENT"
    },
    
    # ======= EMERGENCY Cases (Immediate attention) =======
    {
        "name": "Severe Chest Pain - EMERGENCY",
        "data": {
            "symptoms": ["severe chest pain"],
            "severity": "severe",
            "duration": "30 minutes",
            "body_parts": ["Chest"]
        },
        "expected": "EMERGENCY"
    },
    {
        "name": "Difficulty Breathing - EMERGENCY",
        "data": {
            "symptoms": ["difficulty breathing", "cannot breathe"],
            "severity": "severe",
            "duration": "now",
            "body_parts": []
        },
        "expected": "EMERGENCY"
    },
    {
        "name": "Severe Bleeding - EMERGENCY",
        "data": {
            "symptoms": ["severe bleeding", "blood loss"],
            "severity": "severe",
            "duration": "now",
            "body_parts": []
        },
        "expected": "EMERGENCY"
    },
    {
        "name": "Unconscious - EMERGENCY",
        "data": {
            "symptoms": ["unconscious", "passed out"],
            "severity": "severe",
            "duration": "now",
            "body_parts": []
        },
        "expected": "EMERGENCY"
    },
    {
        "name": "Severe Head Injury - EMERGENCY",
        "data": {
            "symptoms": ["head injury", "severe pain"],
            "severity": "severe",
            "duration": "30 minutes",
            "body_parts": ["Head"]
        },
        "expected": "EMERGENCY"
    },
    {
        "name": "Heart Attack Symptoms - EMERGENCY",
        "data": {
            "symptoms": ["heart attack", "chest pain", "shortness of breath"],
            "severity": "severe",
            "duration": "20 minutes",
            "body_parts": ["Chest"]
        },
        "expected": "EMERGENCY"
    },
    {
        "name": "Stroke Symptoms - EMERGENCY",
        "data": {
            "symptoms": ["stroke", "slurred speech", "weakness"],
            "severity": "severe",
            "duration": "10 minutes",
            "body_parts": ["Head"]
        },
        "expected": "EMERGENCY"
    },
    {
        "name": "Seizure - EMERGENCY",
        "data": {
            "symptoms": ["seizure", "convulsions"],
            "severity": "severe",
            "duration": "5 minutes",
            "body_parts": []
        },
        "expected": "EMERGENCY"
    },
    {
        "name": "Severe Burn - EMERGENCY",
        "data": {
            "symptoms": ["severe burn"],
            "severity": "severe",
            "duration": "now",
            "body_parts": []
        },
        "expected": "EMERGENCY"
    },
    {
        "name": "Poisoning - EMERGENCY",
        "data": {
            "symptoms": ["poisoning", "ingested toxic substance"],
            "severity": "severe",
            "duration": "30 minutes",
            "body_parts": []
        },
        "expected": "EMERGENCY"
    },
    {
        "name": "Choking/Cannot Breathe - EMERGENCY",
        "data": {
            "symptoms": ["choking", "cannot breathe"],
            "severity": "severe",
            "duration": "now",
            "body_parts": []
        },
        "expected": "EMERGENCY"
    },
    {
        "name": "Intense Chest Pain + Arm Pain - EMERGENCY",
        "data": {
            "symptoms": ["intense chest pain", "left arm pain"],
            "severity": "extreme",
            "duration": "15 minutes",
            "body_parts": ["Chest", "Arm"]
        },
        "expected": "EMERGENCY"
    },
    {
        "name": "Severe Allergic Reaction - EMERGENCY",
        "data": {
            "symptoms": ["severe allergic reaction", "swelling throat"],
            "severity": "severe",
            "duration": "10 minutes",
            "body_parts": []
        },
        "expected": "EMERGENCY"
    },
    {
        "name": "Suicide Attempt - EMERGENCY",
        "data": {
            "symptoms": ["suicide attempt", "self harm"],
            "severity": "critical",
            "duration": "now",
            "body_parts": []
        },
        "expected": "EMERGENCY"
    },
    {
        "name": "Severe Abdominal Pain + Vomiting Blood - EMERGENCY",
        "data": {
            "symptoms": ["severe abdominal pain", "vomiting blood"],
            "severity": "severe",
            "duration": "1 hour",
            "body_parts": ["Abdomen"]
        },
        "expected": "EMERGENCY"
    },
]

passed = 0
failed = 0
test_results = []

for i, test in enumerate(test_cases, 1):
    print(f"\n{i}. {test['name']}")
    print(f"   Input: Symptoms={test['data']['symptoms']}, Severity={test['data']['severity']}, Duration={test['data']['duration']}")
    result = classify_symptoms(test['data'])
    expected = test.get('expected', 'N/A')
    actual = result['triage_level']
    
    # Check if result matches expectation
    is_match = actual == expected
    match_symbol = "✅" if is_match else "❌"
    
    if is_match:
        passed += 1
    else:
        failed += 1
    
    test_results.append({
        'name': test['name'],
        'expected': expected,
        'actual': actual,
        'match': is_match
    })
    
    print(f"   {match_symbol} Result: {actual} (confidence: {result['confidence']:.2f})")
    print(f"   Expected: {expected}")
    print(f"   Reason: {result.get('reason', 'N/A')}")
    
    if result.get('override'):
        print(f"   ⚠️  Rule-based override applied")

print("\n" + "="*70)
print("📊 TEST SUMMARY")
print("="*70)
print(f"Total Tests: {len(test_cases)}")
print(f"✅ Passed: {passed} ({passed/len(test_cases)*100:.1f}%)")
print(f"❌ Failed: {failed} ({failed/len(test_cases)*100:.1f}%)")

if failed > 0:
    print(f"\n❌ Failed Tests:")
    for tr in test_results:
        if not tr['match']:
            print(f"   - {tr['name']}: Expected {tr['expected']}, Got {tr['actual']}")

print("="*70 + "\n")
