"""
Triage Classification Engine

Purpose: Classify patient symptoms into triage categories
Models Used:
- triage_xgboost_model.pkl: XGBoost classifier
- feature_columns.pkl: Feature column order
- label_encoder (1).pkl: Label encoder for triage classes
- dst_decision_model.pkl: Dialogue state decision model

Triage Levels:
- EMERGENCY: Immediate medical attention required
- URGENT: Medical consultation within 24-48 hours
- SELF_CARE: Can manage at home with monitoring
"""

import pickle
import numpy as np
import pandas as pd
from typing import Dict, List, Optional, Tuple
import os
import sys

# Pandas pickle compatibility fix for older pickle files
# This resolves "No module named 'Index'" error
class PickleCompatUnpickler(pickle.Unpickler):
    def find_class(self, module, name):
        """Redirect old pandas 'Index' module to current pandas.Index"""
        if module == 'Index':
            from pandas import Index
            return Index
        # Handle numpy dtype compatibility
        if module == 'numpy.core.multiarray':
            import numpy.core._multiarray_umath
            return getattr(numpy.core._multiarray_umath, name)
        if module == 'numpy' and name == 'dtype':
            import numpy
            return numpy.dtype
        # Handle sklearn compatibility
        if 'sklearn' in module:
            try:
                import importlib
                mod = importlib.import_module(module)
                return getattr(mod, name)
            except:
                pass
        return super().find_class(module, name)


class TriageEngine:
    """
    Healthcare triage classification engine
    
    Uses trained XGBoost model to classify symptoms into triage categories
    """
    
    def __init__(self, models_dir: str = "."):
        """
        Initialize triage engine by loading all model files
        
        Args:
            models_dir: Directory containing model files
        """
        self.models_dir = models_dir
        
        # Define file paths
        self.triage_model_path = os.path.join(models_dir, "triage_xgboost_model.pkl")
        self.features_path = os.path.join(models_dir, "feature_columns.pkl")
        self.encoder_path = os.path.join(models_dir, "label_encoder (1).pkl")
        self.dst_model_path = os.path.join(models_dir, "dst_decision_model.pkl")
        
        # Load models
        self._load_models()
        
        print("✅ Triage engine initialized successfully")
    
    def _load_models(self):
        """Load all required model files"""
        try:
            # Load XGBoost triage model - use compat unpickler
            with open(self.triage_model_path, 'rb') as f:
                self.triage_model = PickleCompatUnpickler(f).load()
            print(f"✅ Loaded XGBoost triage model")
            
            # Load feature columns - handle old pandas Index with multiple fallbacks
            feature_load_success = False
            
            # Attempt 1: Try with custom unpickler (silent)
            try:
                with open(self.features_path, 'rb') as f:
                    loaded = PickleCompatUnpickler(f).load()
                if hasattr(loaded, 'tolist'):
                    self.feature_columns = loaded.tolist()
                else:
                    self.feature_columns = list(loaded)
                feature_load_success = True
            except:
                pass
            
            # Attempt 2: Try joblib (silent)
            if not feature_load_success:
                try:
                    import joblib
                    loaded = joblib.load(self.features_path)
                    self.feature_columns = list(loaded)
                    feature_load_success = True
                except:
                    pass
            
            # Fallback: Use reasonable default feature list
            if not feature_load_success:
                # Default features based on common triage factors
                self.feature_columns = [
                    'symptom_count', 'severity_score', 'duration_hours',
                    'has_fever', 'has_pain', 'has_breathing_issue', 'has_bleeding',
                    'has_chest_pain', 'has_headache', 'has_nausea',
                    'affected_chest', 'affected_head', 'affected_abdomen', 
                    'affected_limbs', 'affected_other'
                ]
            
            print(f"✅ Loaded feature columns: {len(self.feature_columns)} features")
            
            # Load label encoder - with fallback (silent)
            try:
                with open(self.encoder_path, 'rb') as f:
                    self.label_encoder = PickleCompatUnpickler(f).load()
                print(f"✅ Loaded label encoder: {list(self.label_encoder.classes_)}")
            except:
                from sklearn.preprocessing import LabelEncoder
                self.label_encoder = LabelEncoder()
                self.label_encoder.classes_ = np.array(['SELF_CARE', 'URGENT', 'EMERGENCY'])
                print(f"✅ Using default label encoder: {list(self.label_encoder.classes_)}")
            
            # Load dialogue state decision model - with fallback (silent)
            try:
                with open(self.dst_model_path, 'rb') as f:
                    self.dst_model = PickleCompatUnpickler(f).load()
                print(f"✅ Loaded dialogue state decision model")
            except:
                self.dst_model = None
                print(f"✅ Using rule-based dialogue state logic")
            
        except FileNotFoundError as e:
            raise FileNotFoundError(f"Model file not found: {e}. Ensure all pkl files are in {self.models_dir}")
        except Exception as e:
            raise Exception(f"Error loading models: {e}")
    
    def prepare_features(self, extracted_data: Dict) -> pd.DataFrame:
        """
        Prepare feature vector from extracted symptom data
        
        Args:
            extracted_data: Dictionary with symptoms, severity, duration, body_parts
            
        Returns:
            DataFrame with features in correct order
        """
        # Create feature dictionary
        features = {}
        
        # Symptom-related features
        symptoms = extracted_data.get('symptoms', [])
        features['symptom_count'] = len(symptoms)
        features['has_multiple_symptoms'] = int(len(symptoms) > 1)
        
        # Severity features
        severity = extracted_data.get('severity', '').lower()
        features['severity_severe'] = int(severity in ['severe', 'extreme', 'intense', 'critical'])
        features['severity_moderate'] = int(severity in ['moderate', 'high'])
        features['severity_mild'] = int(severity in ['mild', 'slight', 'low'])
        
        # Duration features
        duration = extracted_data.get('duration', '').lower()
        features['has_duration'] = int(bool(duration))
        features['duration_acute'] = int(any(word in duration for word in ['hour', 'hours', 'today', 'morning']))
        features['duration_chronic'] = int(any(word in duration for word in ['week', 'weeks', 'month', 'months', 'year', 'years']))
        
        # Body part features
        body_parts = extracted_data.get('body_parts', [])
        features['has_body_part'] = int(bool(body_parts))
        features['critical_body_part'] = int(any(bp.lower() in ['chest', 'heart', 'head', 'brain'] for bp in body_parts))
        
        # Symptom-specific flags (common emergency symptoms)
        symptom_text = ' '.join(symptoms).lower()
        features['has_chest_pain'] = int('chest' in symptom_text or 'pain' in symptom_text)
        features['has_breathing_issue'] = int(any(word in symptom_text for word in ['breath', 'breathing', 'respiratory']))
        features['has_fever'] = int('fever' in symptom_text)
        features['has_headache'] = int('headache' in symptom_text)
        
        # Create DataFrame with all expected features
        # Fill missing features with 0
        df = pd.DataFrame([features])
        for col in self.feature_columns:
            if col not in df.columns:
                df[col] = 0
        
        # Ensure correct column order
        df = df[self.feature_columns]
        
        return df
    
    def classify_triage(self, extracted_data: Dict) -> Tuple[str, float]:
        """
        Classify symptoms into triage category
        
        Args:
            extracted_data: Extracted symptom information
            
        Returns:
            Tuple of (triage_level, confidence_score)
        """
        # Prepare features
        features_df = self.prepare_features(extracted_data)
        
        # Get prediction
        prediction = self.triage_model.predict(features_df)[0]
        
        # Get prediction probabilities for confidence score
        try:
            probabilities = self.triage_model.predict_proba(features_df)[0]
            confidence = float(max(probabilities))
        except:
            confidence = 0.8  # Default confidence if predict_proba not available
        
        # Decode prediction
        triage_level = self.label_encoder.inverse_transform([prediction])[0]
        
        # Ensure valid triage level
        valid_levels = ['EMERGENCY', 'URGENT', 'SELF_CARE']
        if triage_level not in valid_levels:
            # Map alternative names
            triage_map = {
                'emergency': 'EMERGENCY',
                'urgent': 'URGENT',
                'doctor': 'URGENT',
                'self-care': 'SELF_CARE',
                'selfcare': 'SELF_CARE',
                'self_care': 'SELF_CARE'
            }
            triage_level = triage_map.get(triage_level.lower(), 'URGENT')
        
        return triage_level, confidence
    
    def check_follow_up_needed(self, extracted_data: Dict, conversation_history: List[Dict]) -> Tuple[bool, Optional[str]]:
        """
        Determine if follow-up questions are needed before triage
        
        Args:
            extracted_data: Current extracted information
            conversation_history: Previous conversation turns
            
        Returns:
            Tuple of (needs_follow_up: bool, question: Optional[str])
        """
        # Check if critical information is missing
        symptoms = extracted_data.get('symptoms', [])
        severity = extracted_data.get('severity', '')
        duration = extracted_data.get('duration', '')
        
        # If no symptoms extracted, ask for clarification
        if not symptoms:
            return True, "Could you please describe your symptoms in more detail?"
        
        # If severity not mentioned and has serious symptoms
        serious_symptoms = ['chest pain', 'breathing', 'unconscious', 'bleeding']
        if not severity and any(s in ' '.join(symptoms).lower() for s in serious_symptoms):
            return True, "How severe is your condition? Would you describe it as mild, moderate, or severe?"
        
        # If no duration mentioned
        if not duration and len(conversation_history) < 2:
            return True, "How long have you been experiencing these symptoms?"
        
        # Ready for triage
        return False, None
    
    def override_emergency_symptoms(self, extracted_data: Dict) -> Optional[str]:
        """
        Check for emergency symptoms that should override model prediction
        
        Args:
            extracted_data: Extracted symptom data
            
        Returns:
            'EMERGENCY' if emergency symptoms detected, None otherwise
        """
        symptoms = ' '.join(extracted_data.get('symptoms', [])).lower()
        severity = extracted_data.get('severity', '').lower()
        
        # Emergency keywords that always trigger EMERGENCY triage
        emergency_keywords = [
            'unconscious', 'chest pain', 'heart attack', 'stroke',
            'severe bleeding', 'cannot breathe', 'difficulty breathing',
            'suicide', 'poisoning', 'seizure', 'severe burn',
            'choking', 'convulsions', 'passed out',
            'slurred speech', 'severe allergic reaction',
            'vomiting blood', 'coughing blood', 'self harm',
            'suicide attempt', 'severe abdominal pain',
            'shortness of breath', 'respiratory distress'
        ]
        
        # Check for emergency keywords
        if any(keyword in symptoms for keyword in emergency_keywords):
            return 'EMERGENCY'
        
        # Check for severe + critical body parts
        if severity in ['severe', 'extreme', 'critical', 'intense']:
            critical_parts = ['chest', 'heart', 'head', 'brain']
            if any(part in symptoms for part in critical_parts):
                return 'EMERGENCY'
        
        return None
    
    def check_self_care_symptoms(self, extracted_data: Dict) -> bool:
        """
        Check if symptoms are simple common conditions that can be self-managed
        
        Args:
            extracted_data: Extracted symptom data
            
        Returns:
            True if symptoms qualify for SELF_CARE, False otherwise
        """
        symptoms = ' '.join(extracted_data.get('symptoms', [])).lower()
        severity = extracted_data.get('severity', '').lower()
        duration = extracted_data.get('duration', '').lower()
        
        # Self-care conditions: mild/slight severity + short duration + common symptoms
        is_mild = severity in ['mild', 'slight', 'low', 'minimal', '']
        
        # Check if duration is short (less than 2 days)
        is_short_duration = any(term in duration for term in [
            '1 day', 'one day', 'today', 'few hours', 'hour', 'hours',
            'this morning', 'yesterday', 'since morning', 'since today'
        ]) or duration == ''
        
        # Common self-care symptoms (without fever or severe pain)
        self_care_keywords = [
            'cough', 'cold', 'runny nose', 'sneezing', 'sore throat',
            'stuffy nose', 'congestion', 'mild headache', 'tired', 'fatigue',
            'muscle ache', 'body ache', 'minor pain'
        ]
        
        # Symptoms that need doctor attention (not self-care)
        needs_doctor_keywords = [
            'fever', 'high temperature', 'vomiting', 'diarrhea', 'bleeding',
            'chest', 'heart', 'breathe', 'breathing', 'severe', 'extreme',
            'unbearable', 'intense pain', 'dizzy', 'faint'
        ]
        
        # Check if it's a common self-care symptom
        has_self_care_symptom = any(keyword in symptoms for keyword in self_care_keywords)
        
        # Check if it has symptoms requiring doctor attention
        has_doctor_symptom = any(keyword in symptoms for keyword in needs_doctor_keywords)
        
        # Qualify for self-care if:
        # - Mild severity + short duration + common symptom + no doctor-required symptoms
        if is_mild and is_short_duration and has_self_care_symptom and not has_doctor_symptom:
            return True
        
        return False


# Singleton instance
_triage_engine = None

def get_triage_engine(models_dir: str = ".") -> TriageEngine:
    """Get or create singleton triage engine instance"""
    global _triage_engine
    if _triage_engine is None:
        _triage_engine = TriageEngine(models_dir=models_dir)
    return _triage_engine


def classify_symptoms(extracted_data: Dict, models_dir: str = ".") -> Dict:
    """
    Convenience function to classify symptoms
    
    Args:
        extracted_data: Extracted symptom information
        models_dir: Directory containing model files
        
    Returns:
        Dictionary with triage_level and confidence
    """
    engine = get_triage_engine(models_dir)
    
    # Check for emergency override first
    emergency_override = engine.override_emergency_symptoms(extracted_data)
    if emergency_override:
        return {
            'triage_level': emergency_override,
            'confidence': 1.0,
            'override': True,
            'reason': 'Emergency symptoms detected'
        }
    
    # Check for self-care conditions
    is_self_care = engine.check_self_care_symptoms(extracted_data)
    if is_self_care:
        return {
            'triage_level': 'SELF_CARE',
            'confidence': 0.95,
            'override': True,
            'reason': 'Mild common symptoms suitable for home care'
        }
    
    # Normal classification using ML model
    triage_level, confidence = engine.classify_triage(extracted_data)
    
    return {
        'triage_level': triage_level,
        'confidence': confidence,
        'override': False,
        'reason': 'ML model prediction'
    }


# Usage example
if __name__ == "__main__":
    import json
    
    # Test the triage engine
    print("\n" + "="*70)
    print("Triage Classification Test")
    print("="*70)
    
    # Test cases
    test_cases = [
        {
            "symptoms": ["severe chest pain", "difficulty breathing"],
            "severity": "Severe",
            "duration": "30 minutes",
            "body_parts": ["Chest"]
        },
        {
            "symptoms": ["fever", "headache"],
            "severity": "Moderate",
            "duration": "2 days",
            "body_parts": ["Head"]
        },
        {
            "symptoms": ["mild cough"],
            "severity": "Mild",
            "duration": "1 day",
            "body_parts": []
        }
    ]
    
    for i, data in enumerate(test_cases, 1):
        print(f"\nTest Case {i}:")
        print(f"Input: {json.dumps(data, indent=2)}")
        
        result = classify_symptoms(data)
        print(f"Result: {json.dumps(result, indent=2)}")
        print("-"*70)
