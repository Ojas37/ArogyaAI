"""
MODEL 2: Intent Classification Model

Purpose: Classify user's intent from their medical queries
Uses: Hugging Face transformers with pre-trained models
Supports healthcare-specific intents

Intents:
- symptom_reporting: User is describing symptoms
- emergency: User has an urgent medical situation
- question: General health question
- appointment: Wants to book/check appointment
- medication: Questions about medications
- follow_up: Following up on previous condition

Usage:
    from intent_classifier import IntentClassifier
    
    classifier = IntentClassifier()
    result = classifier.classify("I have severe chest pain")
    print(result)  # {"intent": "emergency", "confidence": 0.95}

Note: This implementation uses facebook/bart-large-mnli for zero-shot classification
      as a reliable alternative. You can switch to rohannp8/intent_model if it
      becomes accessible.
"""

from transformers import pipeline
from typing import Dict, List
import os

class IntentClassifier:
    """
    Intent classification model for healthcare queries.
    Uses zero-shot classification with a pre-trained model.
    """
    
    def __init__(self, model_name: str = None):
        """
        Initialize the intent classifier.
        
        Args:
            model_name: Hugging Face model identifier (optional)
                       Defaults to facebook/bart-large-mnli for zero-shot classification
        """
        
        # Define intent labels
        self.intent_labels = [
            "symptom_reporting",
            "emergency",
            "question", 
            "appointment",
            "medication",
            "follow_up",
            "general_chat"
        ]
        
        # Define more descriptive labels for zero-shot classification
        self.intent_descriptions = {
            "symptom_reporting": "reporting medical symptoms or health issues",
            "emergency": "urgent medical emergency requiring immediate attention",
            "question": "asking a general health or medical question",
            "appointment": "scheduling or booking a doctor appointment",
            "medication": "asking about medicine dosage or medication information",
            "follow_up": "following up on previous medical condition or treatment",
            "general_chat": "casual conversation or greeting"
        }
        
        print(f"🔄 Loading intent classification model...")
        
        try:
            # Use zero-shot classification with a reliable model
            # This works out of the box without custom training
            if model_name == "rohannp8/intent_model":
                # Try the custom model first
                try:
                    from transformers import AutoTokenizer, AutoModelForSequenceClassification
                    import torch
                    
                    print(f"   Attempting to load {model_name}...")
                    self.tokenizer = AutoTokenizer.from_pretrained(model_name, use_fast=False)
                    self.model = AutoModelForSequenceClassification.from_pretrained(model_name)
                    self.model.eval()
                    self.use_zero_shot = False
                    print("✅ Custom model loaded successfully!")
                except Exception as e:
                    print(f"   ⚠️  Could not load custom model: {e}")
                    print(f"   📝 Falling back to zero-shot classification...")
                    self.classifier = pipeline("zero-shot-classification", 
                                             model="facebook/bart-large-mnli")
                    self.use_zero_shot = True
            else:
                # Use zero-shot classification by default
                self.classifier = pipeline("zero-shot-classification",
                                         model="facebook/bart-large-mnli") 
                self.use_zero_shot = True
            
            print("✅ Intent classification model ready!")
            
        except Exception as e:
            print(f"⚠️  Error loading intent model: {e}")
            raise
    
    def classify(self, text: str, top_k: int = 1) -> Dict:
        """
        Classify the intent of the input text.
        
        Args:
            text: Input text to classify
            top_k: Number of top predictions to return
            
        Returns:
            dict: Dictionary containing intent and confidence
            Example: {
                "intent": "emergency",
                "confidence": 0.95,
                "all_predictions": [
                    {"intent": "emergency", "confidence": 0.95},
                    {"intent": "symptom_reporting", "confidence": 0.03}
                ]
            }
        """
        if not text or not text.strip():
            return {
                "intent": "unknown",
                "confidence": 0.0,
                "all_predictions": []
            }
        
        try:
            if self.use_zero_shot:
                # Use zero-shot classification
                result = self.classifier(
                    text,
                    list(self.intent_descriptions.values()),
                    multi_label=False
                )
                
                # Map back to intent names
                all_predictions = []
                for label, score in zip(result['labels'], result['scores']):
                    # Find the intent key that matches this description
                    intent_name = None
                    for key, desc in self.intent_descriptions.items():
                        if desc == label:
                            intent_name = key
                            break
                    
                    all_predictions.append({
                        "intent": intent_name or label,
                        "confidence": round(score, 3)
                    })
                
                # Return top predictions
                top_predictions = all_predictions[:min(top_k, len(all_predictions))]
                
                return {
                    "intent": top_predictions[0]["intent"],
                    "confidence": top_predictions[0]["confidence"],
                    "all_predictions": top_predictions
                }
            else:
                # Use custom model (if rohannp8/intent_model loaded successfully)
                import torch
                
                # Tokenize input
                inputs = self.tokenizer(
                    text,
                    return_tensors="pt",
                    truncation=True,
                    max_length=512,
                    padding=True
                )
                
                # Get predictions
                with torch.no_grad():
                    outputs = self.model(**inputs)
                    logits = outputs.logits
                    probabilities = torch.softmax(logits, dim=-1)[0]
                
                # Get top-k predictions
                top_probs, top_indices = torch.topk(probabilities, min(top_k, len(self.intent_labels)))
                
                all_predictions = []
                for prob, idx in zip(top_probs, top_indices):
                    intent_name = self.intent_labels[idx] if idx < len(self.intent_labels) else f"class_{idx}"
                    all_predictions.append({
                        "intent": intent_name,
                        "confidence": round(prob.item(), 3)
                    })
                
                # Return top prediction and all predictions
                return {
                    "intent": all_predictions[0]["intent"],
                    "confidence": all_predictions[0]["confidence"],
                    "all_predictions": all_predictions
                }
            
        except Exception as e:
            print(f"Error classifying intent: {e}")
            return {
                "intent": "error",
                "confidence": 0.0,
                "all_predictions": [],
                "error": str(e)
            }
    
    def classify_batch(self, texts: List[str]) -> List[Dict]:
        """
        Classify intents for multiple texts.
        
        Args:
            texts: List of text strings
            
        Returns:
            list: List of classification results
        """
        return [self.classify(text) for text in texts]


# Example usage
if __name__ == "__main__":
    # Initialize classifier
    print("\n" + "="*60)
    print("Intent Classification Model Test")
    print("="*60)
    
    try:
        # Use default zero-shot classification
        # To try rohannp8/intent_model, use: IntentClassifier("rohannp8/intent_model")
        classifier = IntentClassifier()
        
        # Test cases
        test_cases = [
            "I have severe chest pain and difficulty breathing",
            "What causes headaches?",
            "I want to schedule an appointment with a doctor",
            "My fever has been going on for 3 days",
            "What is the dosage for paracetamol?",
            "I'm feeling better after taking the medicine",
            "Hello, how are you?"
        ]
        
        print("\n" + "="*60)
        print("Testing Intent Classification")
        print("="*60)
        
        for text in test_cases:
            result = classifier.classify(text, top_k=3)
            print(f"\nText: {text}")
            print(f"Intent: {result['intent']} (confidence: {result['confidence']})")
            print("Top predictions:")
            for pred in result['all_predictions']:
                print(f"  - {pred['intent']}: {pred['confidence']}")
                
    except Exception as e:
        print(f"\n❌ Error: {e}")
        print("\nMake sure you have transformers and torch installed:")
        print("  pip install transformers torch")
