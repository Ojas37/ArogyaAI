"""
Safety Validators for Healthcare Triage System

HARD CONSTRAINTS (NON-NEGOTIABLE):
1. DO NOT diagnose diseases
2. DO NOT prescribe medicines
3. DO NOT modify triage decision after classification
4. Translation is ONLY for language conversion, not meaning change
5. Emergency triage ALWAYS overrides everything
6. Must always return valid JSON response
"""

from typing import Dict, List, Optional, Tuple
import re


class SafetyValidator:
    """
    Validates and enforces safety constraints for healthcare chatbot
    """
    
    # Prohibited terms that should never appear in responses
    PROHIBITED_DIAGNOSIS_TERMS = [
        'you have', 'diagnosed with', 'you are suffering from',
        'medical diagnosis', 'confirmed diagnosis', 'you\'re diagnosed',
        'this is', 'you definitely have', 'you certainly have'
    ]
    
    PROHIBITED_PRESCRIPTION_TERMS = [
        'take this medicine', 'prescribed', 'dosage', 'medication',
        'drug', 'tablet', 'capsule', 'injection', 'antibiotic',
        'prescription', 'mg', 'ml', 'dose'
    ]
    
    # Required disclaimer phrases
    REQUIRED_DISCLAIMERS = [
        'This is not a medical diagnosis',
        'not a substitute for professional medical advice',
        'consult a healthcare professional'
    ]
    
    # Valid triage levels
    VALID_TRIAGE_LEVELS = {'EMERGENCY', 'URGENT', 'SELF_CARE'}
    
    # Valid tone values
    VALID_TONES = {'reassuring', 'firm', 'urgent'}
    
    @staticmethod
    def validate_language_confidence(language: str, confidence: float) -> Tuple[bool, Optional[str]]:
        """
        Validate language detection confidence
        
        Args:
            language: Detected language code
            confidence: Confidence score (0-1)
            
        Returns:
            Tuple of (is_valid, error_message)
        """
        if confidence < 0.7:
            return False, f"Language detection confidence too low ({confidence:.2f}). Please confirm your language."
        
        return True, None
    
    @staticmethod
    def validate_triage_level(triage: str) -> Tuple[bool, str]:
        """
        Validate and normalize triage level
        
        Args:
            triage: Triage level string
            
        Returns:
            Tuple of (is_valid, normalized_triage)
        """
        triage_upper = triage.upper()
        
        if triage_upper in SafetyValidator.VALID_TRIAGE_LEVELS:
            return True, triage_upper
        
        # Attempt to map common variations
        triage_map = {
            'DOCTOR': 'URGENT',
            'EMERGENCY_CARE': 'EMERGENCY',
            'HOME_CARE': 'SELF_CARE',
            'SELF-CARE': 'SELF_CARE',
            'SELFCARE': 'SELF_CARE'
        }
        
        normalized = triage_map.get(triage_upper)
        if normalized:
            return True, normalized
        
        # Default to URGENT for safety
        return False, 'URGENT'
    
    @staticmethod
    def validate_response_safety(response: str) -> Tuple[bool, List[str]]:
        """
        Check if response violates safety constraints
        
        Args:
            response: Generated response text
            
        Returns:
            Tuple of (is_safe, list_of_violations)
        """
        violations = []
        response_lower = response.lower()
        
        # Check for prohibited diagnosis terms
        for term in SafetyValidator.PROHIBITED_DIAGNOSIS_TERMS:
            if term in response_lower:
                violations.append(f"Contains diagnosis term: '{term}'")
        
        # Check for prohibited prescription terms
        for term in SafetyValidator.PROHIBITED_PRESCRIPTION_TERMS:
            if term in response_lower:
                violations.append(f"Contains prescription term: '{term}'")
        
        # Check for medical terminology that implies diagnosis
        medical_disease_pattern = r'\b(cancer|diabetes|hypertension|tuberculosis|pneumonia|covid)\b'
        if re.search(medical_disease_pattern, response_lower):
            violations.append("Contains specific disease names")
        
        is_safe = len(violations) == 0
        return is_safe, violations
    
    @staticmethod
    def add_safety_disclaimer(response: str, triage: str) -> str:
        """
        Add appropriate safety disclaimer to response
        
        Args:
            response: Original response
            triage: Triage level
            
        Returns:
            Response with disclaimer
        """
        # Check if disclaimer already exists
        if any(disclaimer.lower() in response.lower() for disclaimer in SafetyValidator.REQUIRED_DISCLAIMERS):
            return response
        
        # Add triage-specific disclaimer
        if triage == 'EMERGENCY':
            disclaimer = " Remember: This is not a diagnosis. Call emergency services immediately."
        elif triage == 'URGENT':
            disclaimer = " This is not a medical diagnosis. Please consult a healthcare professional."
        else:
            disclaimer = " This is guidance only, not a medical diagnosis. Consult a doctor if symptoms worsen."
        
        return response + disclaimer
    
    @staticmethod
    def sanitize_symptoms(symptoms: List[str]) -> List[str]:
        """
        Remove potentially unsafe or non-symptom terms
        
        Args:
            symptoms: Raw symptom list
            
        Returns:
            Sanitized symptom list
        """
        sanitized = []
        
        # Remove very short or very long terms
        for symptom in symptoms:
            if 2 < len(symptom) < 50:
                # Remove numbers and special characters
                cleaned = re.sub(r'[^a-zA-Z\s]', '', symptom).strip()
                if cleaned:
                    sanitized.append(cleaned)
        
        return sanitized
    
    @staticmethod
    def validate_json_response(response: Dict) -> Tuple[bool, Optional[str]]:
        """
        Validate final JSON response structure
        
        Args:
            response: Response dictionary
            
        Returns:
            Tuple of (is_valid, error_message)
        """
        required_fields = [
            'language', 'triage', 'confidence', 'spoken_response', 'tone'
        ]
        
        missing_fields = [field for field in required_fields if field not in response]
        
        if missing_fields:
            return False, f"Missing required fields: {', '.join(missing_fields)}"
        
        # Validate triage value
        is_valid_triage, _ = SafetyValidator.validate_triage_level(response['triage'])
        if not is_valid_triage:
            return False, f"Invalid triage level: {response['triage']}"
        
        # Validate tone
        if response['tone'] not in SafetyValidator.VALID_TONES:
            return False, f"Invalid tone: {response['tone']}"
        
        # Validate confidence
        if not (0 <= response['confidence'] <= 1):
            return False, f"Invalid confidence: {response['confidence']}"
        
        return True, None
    
    @staticmethod
    def enforce_emergency_override(triage: str, symptoms: List[str]) -> str:
        """
        Enforce emergency triage for critical symptoms
        
        Args:
            triage: Predicted triage level
            symptoms: List of symptoms
            
        Returns:
            Final triage level (may be overridden to EMERGENCY)
        """
        symptoms_text = ' '.join(symptoms).lower()
        
        # Critical keywords that MUST trigger emergency
        critical_keywords = [
            'unconscious', 'not breathing', 'chest pain', 'heart attack',
            'stroke', 'severe bleeding', 'cannot breathe', 'seizure',
            'suicide', 'overdose', 'severe burn', 'head injury'
        ]
        
        if any(keyword in symptoms_text for keyword in critical_keywords):
            return 'EMERGENCY'
        
        return triage


# Singleton instance
_validator = None

def get_validator() -> SafetyValidator:
    """Get or create singleton validator instance"""
    global _validator
    if _validator is None:
        _validator = SafetyValidator()
    return _validator


# Convenience functions
def validate_language(language: str, confidence: float) -> Tuple[bool, Optional[str]]:
    """Validate language detection"""
    validator = get_validator()
    return validator.validate_language_confidence(language, confidence)


def validate_triage(triage: str) -> Tuple[bool, str]:
    """Validate triage level"""
    validator = get_validator()
    return validator.validate_triage_level(triage)


def validate_response(response: str) -> Tuple[bool, List[str]]:
    """Validate response safety"""
    validator = get_validator()
    return validator.validate_response_safety(response)


def add_disclaimer(response: str, triage: str) -> str:
    """Add safety disclaimer"""
    validator = get_validator()
    return validator.add_safety_disclaimer(response, triage)


# Usage example
if __name__ == "__main__":
    validator = SafetyValidator()
    
    print("\n" + "="*70)
    print("Safety Validator Test")
    print("="*70)
    
    # Test response validation
    test_responses = [
        "You have diabetes. Take this medicine.",  # UNSAFE
        "Your symptoms suggest you should see a doctor soon.",  # SAFE
        "This is a severe condition requiring immediate care.",  # SAFE
    ]
    
    for response in test_responses:
        is_safe, violations = validator.validate_response_safety(response)
        print(f"\nResponse: {response}")
        print(f"Safe: {is_safe}")
        if violations:
            print(f"Violations: {violations}")
        print("-"*70)
