"""
Medical Symptom Extractor using Pre-trained Biomedical NER
Extracted from Model 2: Symptom Extraction NER

Purpose: Extract symptoms, severity, duration, and body parts from medical text
Model: d4data/biomedical-ner-all (Pre-trained Medical NER)
"""

import re
import warnings
from typing import Dict, List
from transformers import AutoTokenizer, AutoModelForTokenClassification, pipeline

# Suppress warnings
warnings.filterwarnings('ignore')


class MedicalSymptomExtractor:
    """Extract symptoms, severity, duration, and body parts from medical text"""
    
    def __init__(self, model_path="d4data/biomedical-ner-all"):
        """
        Initialize the symptom extractor
        
        Args:
            model_path: Path to the model (default: HuggingFace model)
        """
        print(f"Loading medical NER model from: {model_path}")
        self.tokenizer = AutoTokenizer.from_pretrained(model_path)
        self.model = AutoModelForTokenClassification.from_pretrained(model_path)
        self.ner_pipeline = pipeline(
            "ner",
            model=self.model,
            tokenizer=self.tokenizer,
            aggregation_strategy="simple"
        )
        print("✅ Medical NER model loaded successfully")
        
        # Define keywords and patterns
        self.severity_keywords = {
            'severe', 'extreme', 'intense', 'acute', 'chronic', 'critical',
            'mild', 'moderate', 'slight', 'low', 'high', 'persistent',
            'sharp', 'throbbing', 'continuous', 'constant', 'intermittent',
            'bahut tez', 'halka', 'bahut', 'tez'
        }
        
        self.duration_patterns = [
            r'for\s+(?:the\s+)?(?:past\s+|last\s+)?\d+\s+(?:day|days|week|weeks|month|months|hour|hours|year|years)',
            r'since\s+(?:the\s+)?(?:past\s+|last\s+)?\d+\s+(?:day|days|week|weeks|month|months|hour|hours|year|years)',
            r'\d+\s+(?:day|days|week|weeks|month|months|hour|hours|year|years)',
            r'since\s+(?:the\s+)?(?:this\s+)?(?:morning|yesterday|last\s+\w+|today)',
            r'for\s+\d+\s+(?:day|days|week|weeks|month|months|hour|hours|year|years)',
            r'started\s+\d+\s+(?:minute|minutes|hour|hours|day|days)\s+ago',
            r'\d+\s+(?:minute|minutes|hour|hours)\s+ago',
            r'for\s+years',
            r'since\s+\w+\s+(?:morning|afternoon|evening|night)',
            r'\d+\s*din\s*se',
            r'\d+\s*hafte\s*se',
            r'\d+\s*mahine\s*se',
            r'subah se',
            r'kal se',
            # Additional patterns for short inputs
            r'^\d+$',  # Just a number (will be interpreted as days in context)
        ]
        
        # Duration unit mapping
        self.duration_unit_map = {
            'din': 'day',
            'hafte': 'week', 
            'mahine': 'month',
            'saal': 'year'
        }
        
        self.body_parts = {
            'head', 'chest', 'stomach', 'back', 'leg', 'arm', 'knee', 'hand',
            'foot', 'eye', 'ear', 'throat', 'neck', 'shoulder', 'abdomen',
            'ankle', 'finger', 'toe', 'heart', 'lung', 'liver', 'kidney',
            'brain', 'skin', 'bone', 'muscle', 'joint',
            'sir', 'pet', 'pairo', 'gale', 'haath'
        }
        
        self.exclude_words = {
            'patient', 'has', 'have', 'experiencing', 'with', 'and', 'or',
            'the', 'a', 'an', 'in', 'on', 'at', 'for', 'since', 'from',
            'severe', 'mild', 'moderate', 'acute', 'chronic', 'high', 'low',
            'this', 'that', 'these', 'those', 'morning', 'evening', 'night',
            'day', 'days', 'week', 'weeks', 'month', 'months', 'hour', 'hours',
            'year', 'years', 'yesterday', 'today', 'tomorrow', 'left', 'right',
            'when', 'after', 'before', 'appeared', 'requiring', 'grade', 'side'
        }
    
    def extract(self, text: str) -> Dict:
        """
        Extract medical symptoms and related information from text
        
        Args:
            text: Medical text describing symptoms
            
        Returns:
            Dictionary with symptoms, severity, duration, and body_parts
        """
        # Get NER predictions from ML model
        entities = self.ner_pipeline(text)
        
        # Initialize result
        result = {
            "symptoms": [],
            "severity": "",
            "duration": "",
            "body_parts": []
        }
        
        # Process entities - filter out non-symptoms
        number_pattern = r'^\d+$'
        time_phrase_pattern = r'^\d+\s*(?:day|days|week|weeks|month|months|hour|hours|year|years|din|hafte)$'
        
        for entity in entities:
            entity_text = entity['word'].strip().lower()
            
            # Skip excluded words, numbers, severity keywords, body parts, time phrases
            if (entity_text in self.exclude_words or 
                re.match(number_pattern, entity_text) or 
                re.match(time_phrase_pattern, entity_text) or
                len(entity_text) <= 2 or
                entity_text in self.severity_keywords or
                entity_text in self.body_parts):
                continue
            
            # Add to symptoms
            original_text = entity['word'].strip()
            if original_text not in result['symptoms']:
                result['symptoms'].append(original_text)
        
        # Extract severity (exact word matching)
        words = text.lower().split()
        for word in words:
            word_clean = word.strip(',.!?;:')
            if word_clean in self.severity_keywords:
                if not result['severity']:
                    result['severity'] = word_clean.title()
                    break
        
        # Extract body parts
        for word in words:
            word_clean = word.strip(',.!?;:')
            for body_part in self.body_parts:
                if body_part == word_clean or word_clean.startswith(body_part):
                    if body_part.title() not in result['body_parts']:
                        result['body_parts'].append(body_part.title())
        
        # Extract duration (capture full phrases)
        duration_matches = []
        for pattern in self.duration_patterns:
            matches = re.findall(pattern, text.lower())
            if matches:
                duration_matches.extend(matches)
        
        if duration_matches and not result['duration']:
            longest_match = max(duration_matches, key=len).strip()
            
            # If it's just a number, assume it's days
            if longest_match.isdigit():
                num = int(longest_match)
                longest_match = f"{num} day" if num == 1 else f"{num} days"
            
            # Translate Hindi/regional units to English
            for hindi, english in self.duration_unit_map.items():
                if hindi in longest_match:
                    longest_match = longest_match.replace(hindi, english)
            
            # Normalize singular/plural forms for English units
            # Extract number and unit
            match = re.search(r'(\d+)\s+(day|week|month|year)', longest_match)
            if match:
                num = int(match.group(1))
                unit = match.group(2)
                # Pluralize if number > 1 and unit is singular
                if num > 1 and not unit.endswith('s'):
                    longest_match = re.sub(r'(\d+)\s+(day|week|month|year)', rf'\1 {unit}s', longest_match)
                # Singularize if number = 1 and unit is plural
                elif num == 1 and unit.endswith('s'):
                    longest_match = re.sub(r'(\d+)\s+(days|weeks|months|years)', rf'\1 {unit[:-1]}', longest_match)
            
            result['duration'] = longest_match
        
        return result


# Singleton instance for reuse
_extractor = None

def get_extractor():
    """Get or create singleton extractor instance"""
    global _extractor
    if _extractor is None:
        _extractor = MedicalSymptomExtractor()
    return _extractor


def extract_symptoms(text: str) -> Dict:
    """
    Convenience function to extract symptoms from text
    
    Args:
        text: Medical text
        
    Returns:
        Extraction result dictionary
    """
    extractor = get_extractor()
    return extractor.extract(text)


# Usage example
if __name__ == "__main__":
    import json
    
    # Test the extractor
    test_texts = [
        "I have severe fever and headache for 3 days",
        "Chronic diabetes with chest pain",
        "Mild cough since this morning",
    ]
    
    print("\n" + "="*70)
    print("Medical Symptom Extraction Examples")
    print("="*70)
    
    for text in test_texts:
        print(f"\nInput: {text}")
        result = extract_symptoms(text)
        print(f"Output: {json.dumps(result, indent=2)}")
        print("-"*70)
