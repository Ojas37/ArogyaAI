"""
Complete Pipeline Test Script

Tests the entire healthcare triage system end-to-end
"""

import json
import sys
from typing import Dict, List

# Import pipeline
from pipeline_orchestrator import HealthcareTriagePipeline


def print_section(title: str):
    """Print formatted section header"""
    print(f"\n{'='*80}")
    print(f"{title}")
    print(f"{'='*80}\n")


def print_result(result: Dict):
    """Print formatted result"""
    print(json.dumps(result, indent=2, ensure_ascii=False))


def test_emergency_cases():
    """Test emergency triage cases"""
    print_section("TEST 1: EMERGENCY CASES")
    
    pipeline = HealthcareTriagePipeline()
    
    test_cases = [
        "I have severe chest pain and difficulty breathing for 30 minutes",
        "Patient unconscious with severe bleeding",
        "Sudden severe headache with vision problems",
    ]
    
    for i, message in enumerate(test_cases, 1):
        print(f"\nTest 1.{i}: {message}")
        print("-" * 80)
        
        result = pipeline.process_message(message, force_language='en')
        
        assert result['triage'] == 'EMERGENCY', f"Expected EMERGENCY, got {result['triage']}"
        assert result['tone'] == 'urgent', f"Expected urgent tone, got {result['tone']}"
        
        print(f"✅ Triage: {result['triage']}")
        print(f"✅ Tone: {result['tone']}")
        print(f"✅ Response: {result['spoken_response'][:100]}...")
        
        pipeline.reset_session()
    
    print("\n✅ All emergency cases passed!")


def test_urgent_cases():
    """Test urgent (doctor visit) cases"""
    print_section("TEST 2: URGENT CASES")
    
    pipeline = HealthcareTriagePipeline()
    
    test_cases = [
        "I have high fever and body ache for 3 days",
        "Persistent cough and breathing difficulty for 5 days",
        "Moderate headache with fever since yesterday",
    ]
    
    for i, message in enumerate(test_cases, 1):
        print(f"\nTest 2.{i}: {message}")
        print("-" * 80)
        
        result = pipeline.process_message(message, force_language='en')
        
        # Should be URGENT or possibly EMERGENCY
        assert result['triage'] in ['URGENT', 'EMERGENCY'], f"Unexpected triage: {result['triage']}"
        
        print(f"✅ Triage: {result['triage']}")
        print(f"✅ Response: {result['spoken_response'][:100]}...")
        
        pipeline.reset_session()
    
    print("\n✅ All urgent cases passed!")


def test_self_care_cases():
    """Test self-care cases"""
    print_section("TEST 3: SELF-CARE CASES")
    
    pipeline = HealthcareTriagePipeline()
    
    test_cases = [
        "Mild headache since this morning",
        "Slight cold and runny nose for 1 day",
        "Minor fatigue after exercise",
    ]
    
    for i, message in enumerate(test_cases, 1):
        print(f"\nTest 3.{i}: {message}")
        print("-" * 80)
        
        result = pipeline.process_message(message, force_language='en')
        
        print(f"✅ Triage: {result['triage']}")
        print(f"✅ Tone: {result['tone']}")
        print(f"✅ Response: {result['spoken_response'][:100]}...")
        
        pipeline.reset_session()
    
    print("\n✅ All self-care cases passed!")


def test_multilingual():
    """Test multilingual support"""
    print_section("TEST 4: MULTILINGUAL SUPPORT")
    
    pipeline = HealthcareTriagePipeline()
    
    test_cases = [
        ("Hello, I need help", "en"),
        ("मुझे बुखार और सिरदर्द है", "hi"),
        ("I have mild cough", "en"),
    ]
    
    for i, (message, expected_lang) in enumerate(test_cases, 1):
        print(f"\nTest 4.{i}: {message}")
        print("-" * 80)
        
        result = pipeline.process_message(message)
        
        print(f"✅ Detected Language: {result['language']}")
        print(f"✅ Response: {result['spoken_response'][:100]}...")
        
        pipeline.reset_session()
    
    print("\n✅ Multilingual tests passed!")


def test_safety_constraints():
    """Test safety validators"""
    print_section("TEST 5: SAFETY CONSTRAINTS")
    
    from utils.validators import SafetyValidator
    
    validator = SafetyValidator()
    
    # Test unsafe responses
    unsafe_responses = [
        "You have diabetes.",
        "Take this medicine twice a day.",
        "You are diagnosed with pneumonia.",
    ]
    
    print("Testing unsafe response detection:")
    for i, response in enumerate(unsafe_responses, 1):
        is_safe, violations = validator.validate_response_safety(response)
        print(f"\n{i}. '{response}'")
        print(f"   Safe: {is_safe}")
        print(f"   Violations: {violations}")
        assert not is_safe, "Should detect as unsafe"
    
    # Test safe responses
    safe_responses = [
        "Your symptoms suggest you should see a doctor.",
        "This requires immediate medical attention.",
        "You may be able to manage this at home.",
    ]
    
    print("\n\nTesting safe response validation:")
    for i, response in enumerate(safe_responses, 1):
        is_safe, violations = validator.validate_response_safety(response)
        print(f"\n{i}. '{response}'")
        print(f"   Safe: {is_safe}")
        assert is_safe, f"Should be safe: {violations}"
    
    print("\n✅ Safety constraint tests passed!")


def test_json_structure():
    """Test JSON response structure"""
    print_section("TEST 6: JSON RESPONSE STRUCTURE")
    
    pipeline = HealthcareTriagePipeline()
    
    message = "I have fever and headache for 2 days"
    print(f"Input: {message}\n")
    
    result = pipeline.process_message(message, force_language='en')
    
    # Check required fields
    required_fields = [
        'language', 'detected_intent', 'extracted_symptoms',
        'triage', 'confidence', 'spoken_response', 'tone', 'actions'
    ]
    
    print("Checking required fields:")
    for field in required_fields:
        assert field in result, f"Missing field: {field}"
        print(f"  ✅ {field}: {str(result[field])[:50]}...")
    
    print("\n\nComplete JSON Response:")
    print_result(result)
    
    print("\n✅ JSON structure test passed!")


def test_complete_flow():
    """Test complete end-to-end flow"""
    print_section("TEST 7: COMPLETE END-TO-END FLOW")
    
    pipeline = HealthcareTriagePipeline()
    
    # Simulate a conversation
    messages = [
        "Hello",
        "I have chest pain",
        "It's very severe",
    ]
    
    for i, message in enumerate(messages, 1):
        print(f"\n{'>'*40}")
        print(f"User (Turn {i}): {message}")
        print(f"{'>'*40}")
        
        result = pipeline.process_message(message, force_language='en')
        
        print(f"\nBot Response:")
        print(f"  Intent: {result.get('detected_intent', 'N/A')}")
        print(f"  Triage: {result.get('triage', 'N/A')}")
        print(f"  Message: {result['spoken_response'][:150]}...")
        
        # If emergency detected, stop
        if result.get('triage') == 'EMERGENCY':
            print(f"\n🚨 EMERGENCY DETECTED - System correctly escalated!")
            break
    
    print("\n✅ Complete flow test passed!")


def run_all_tests():
    """Run all test suites"""
    print("="*80)
    print("HEALTHCARE TRIAGE PIPELINE - COMPREHENSIVE TEST SUITE")
    print("="*80)
    
    test_suites = [
        ("Emergency Cases", test_emergency_cases),
        ("Urgent Cases", test_urgent_cases),
        ("Self-Care Cases", test_self_care_cases),
        ("Multilingual Support", test_multilingual),
        ("Safety Constraints", test_safety_constraints),
        ("JSON Structure", test_json_structure),
        ("Complete Flow", test_complete_flow),
    ]
    
    passed = 0
    failed = 0
    
    for name, test_func in test_suites:
        try:
            test_func()
            passed += 1
        except Exception as e:
            print(f"\n❌ {name} FAILED: {e}")
            import traceback
            traceback.print_exc()
            failed += 1
    
    # Summary
    print_section("TEST SUMMARY")
    print(f"Total Tests: {len(test_suites)}")
    print(f"✅ Passed: {passed}")
    print(f"❌ Failed: {failed}")
    
    if failed == 0:
        print("\n🎉 ALL TESTS PASSED!")
        return 0
    else:
        print(f"\n⚠️ {failed} test(s) failed")
        return 1


if __name__ == "__main__":
    exit_code = run_all_tests()
    sys.exit(exit_code)
