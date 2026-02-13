"""
Test script for Intent Classification Model
"""

from intent_classifier import IntentClassifier

def test_intent_classifier():
    """Test the intent classifier with various healthcare queries"""
    print("\n" + "="*70)
    print("Testing Intent Classification Model")
    print("="*70)
    
    # Initialize classifier
    try:
        classifier = IntentClassifier()
        print("\n✅ Intent classifier initialized successfully!\n")
    except Exception as e:
        print(f"\n❌ Failed to initialize: {e}")
        print("\nNote: This requires a large model download (~14.5 GB)")
        print("Make sure you have:")
        print("  1. Installed transformers: pip install transformers torch")
        print("  2. Stable internet connection")
        print("  3. Sufficient disk space\n")
        return
    
    # Test cases covering different intents
    test_cases = [
        # Emergency cases
        ("I have severe chest pain and can't breathe", "emergency"),
        ("My baby is unconscious and not responding", "emergency"),
        ("Sudden severe headache with vision loss", "emergency"),
        
        # Symptom reporting
        ("I've had a fever for 3 days with cough", "symptom_reporting"),
        ("My stomach hurts after eating", "symptom_reporting"),
        ("I have a persistent headache", "symptom_reporting"),
        
        # Questions
        ("What causes diabetes?", "question"),
        ("How can I prevent flu?", "question"),
        ("Is this symptom normal during pregnancy?", "question"),
        
        # Appointment related
        ("I want to book an appointment with a doctor", "appointment"),
        ("Can I schedule a checkup for next week?", "appointment"),
        ("I need to see a specialist", "appointment"),
        
        # Medication queries
        ("What is the dosage for paracetamol?", "medication"),
        ("Can I take this medicine with food?", "medication"),
        ("What are the side effects of aspirin?", "medication"),
        
        # Follow-up
        ("I'm feeling better after the treatment", "follow_up"),
        ("The pain is still there after taking medicine", "follow_up"),
        
        # General chat
        ("Hello, how are you?", "general_chat"),
        ("Thank you for your help", "general_chat"),
    ]
    
    print("="*70)
    print("Test Results")
    print("="*70)
    
    correct = 0
    total = len(test_cases)
    
    for text, expected_intent in test_cases:
        result = classifier.classify(text, top_k=3)
        
        predicted_intent = result['intent']
        confidence = result['confidence']
        is_correct = "✅" if predicted_intent == expected_intent else "❌"
        
        print(f"\n{is_correct} Text: {text}")
        print(f"   Expected: {expected_intent}")
        print(f"   Predicted: {predicted_intent} ({confidence:.2%})")
        print(f"   Top 3 predictions:")
        for pred in result['all_predictions'][:3]:
            print(f"      - {pred['intent']}: {pred['confidence']:.2%}")
        
        if predicted_intent == expected_intent:
            correct += 1
    
    print("\n" + "="*70)
    print(f"Accuracy: {correct}/{total} = {(correct/total)*100:.1f}%")
    print("="*70 + "\n")
    
    # Test batch classification
    print("\nTesting batch classification...")
    batch_texts = [
        "I have chest pain",
        "Can I book an appointment?",
        "What medicine should I take?"
    ]
    
    batch_results = classifier.classify_batch(batch_texts)
    print("\nBatch Results:")
    for text, result in zip(batch_texts, batch_results):
        print(f"  - '{text}' → {result['intent']} ({result['confidence']:.2%})")
    
    print("\n✅ Testing complete!\n")

if __name__ == "__main__":
    test_intent_classifier()
