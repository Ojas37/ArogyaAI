"""
MODEL 2: Intent Classification Model

Purpose: Classify user's intent from their medical queries
Uses: Hugging Face transformers with zero-shot classification
Supports healthcare-specific intents

Intents:
- symptom_query: User is describing symptoms
- emergency: User has an urgent medical situation
- greeting: General greeting
- thank_you: Thank you message
- general_query: General health question

Usage:
    from intent_classifier import IntentClassifier
    
    classifier = IntentClassifier()
    result = classifier.classify("I have severe chest pain")
    print(result)  # {"intent": "emergency", "confidence": 0.95}
"""

import warnings
warnings.filterwarnings('ignore')

from transformers import pipeline
from typing import Dict, List
import os

class IntentClassifier:
    """
    Intent classification model for healthcare queries.
    Uses zero-shot classification with a pre-trained model.
    """
    
    def __init__(self, model_name: str = "facebook/bart-large-mnli"):
        """
        Initialize the intent classifier.
        
        Args:
            model_name: Hugging Face model identifier
                       Defaults to facebook/bart-large-mnli for zero-shot classification
        """
        
        # Define intent labels
        self.intent_labels = [
            "symptom_query",
            "emergency",
            "greeting", 
            "thank_you",
            "general_query"
        ]
        
        print(f"🔄 Loading intent classification model: {model_name}...")
        
        # Load zero-shot classification model
        self.classifier = pipeline(
            "zero-shot-classification",
            model=model_name
        )
        
        print("✅ Intent classification model ready (ML-based)!")
    
    def classify(self, text: str, top_k: int = 1) -> Dict:
        """
        Classify the intent of the input text using ML model
        
        Args:
            text: Input text to classify
            top_k: Number of top predictions to return
            
        Returns:
            dict: Dictionary containing intent and confidence
        """
        if not text or not text.strip():
            return {
                "intent": "unknown",
                "confidence": 0.0,
                "all_predictions": []
            }
        
        try:
            # Use zero-shot classification
            result = self.classifier(
                text,
                self.intent_labels,
                multi_label=False
            )
            
            all_predictions = []
            for label, score in zip(result['labels'], result['scores']):
                all_predictions.append({
                    "intent": label,
                    "confidence": round(score, 3)
                })
            
            top_predictions = all_predictions[:min(top_k, len(all_predictions))]
            
            return {
                "intent": top_predictions[0]["intent"],
                "confidence": top_predictions[0]["confidence"],
                "all_predictions": top_predictions
            }
        
        except Exception as e:
            print(f"❌ Error in ML classification: {e}")
            raise
    
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
