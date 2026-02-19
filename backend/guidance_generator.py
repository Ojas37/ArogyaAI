"""
Model 6: Guidance Generator (Template-Based)
Purpose: Show advice in simple language based on triage level
NOT an ML model - uses predefined templates
"""

from typing import Dict, List, Optional


class GuidanceGenerator:
    """
    Template-based guidance generator for healthcare triage
    Provides language-specific advice based on urgency level
    """
    
    def __init__(self):
        """Initialize guidance templates for different languages and urgency levels"""
        
        # English templates
        self.templates_en = {
            "emergency": {
                "message": "⚠️ EMERGENCY: Seek immediate medical attention!",
                "description": "Your symptoms indicate a serious condition that requires urgent care.",
                "actions": [
                    "Call emergency services (108) immediately",
                    "Do not drive yourself - call an ambulance",
                    "If unconscious, place in recovery position",
                    "Keep calm and stay with the patient",
                    "Note the time symptoms started"
                ],
                "do_not": [
                    "Do not delay calling for help",
                    "Do not give food or water if unconscious",
                    "Do not leave the patient alone"
                ],
                "symptoms_requiring_emergency": [
                    "Severe chest pain or pressure",
                    "Difficulty breathing or shortness of breath",
                    "Sudden severe headache",
                    "Loss of consciousness",
                    "Severe bleeding",
                    "Signs of stroke (face drooping, arm weakness, speech difficulty)"
                ]
            },
            
            "doctor": {
                "message": "🏥 Please consult a doctor within 24-48 hours.",
                "description": "Your symptoms suggest you should see a healthcare professional soon.",
                "actions": [
                    "Schedule an appointment with your doctor",
                    "Visit a nearby clinic or hospital",
                    "Note down all your symptoms and their duration",
                    "Keep a record of your temperature if you have fever",
                    "Monitor if symptoms worsen"
                ],
                "do_not": [
                    "Do not ignore persistent symptoms",
                    "Do not self-medicate with antibiotics",
                    "Do not wait if symptoms get worse"
                ],
                "when_to_seek_emergency": [
                    "If fever exceeds 103°F (39.4°C)",
                    "If breathing becomes difficult",
                    "If you cannot keep fluids down",
                    "If symptoms suddenly worsen",
                    "If you develop chest pain"
                ]
            },
            
            "self-care": {
                "message": "🏡 You can manage this at home with self-care.",
                "description": "Your symptoms appear mild and can likely be managed with rest and home remedies.",
                "actions": [
                    "Get plenty of rest",
                    "Stay well hydrated - drink 8-10 glasses of water daily",
                    "Eat a balanced, nutritious diet",
                    "Monitor your symptoms for 24-48 hours",
                    "Use over-the-counter remedies if needed"
                ],
                "do_not": [
                    "Do not overexert yourself",
                    "Do not ignore worsening symptoms",
                    "Do not skip meals or fluids"
                ],
                "when_to_seek_doctor": [
                    "If symptoms persist beyond 3 days",
                    "If symptoms worsen instead of improving",
                    "If new symptoms develop",
                    "If you develop high fever",
                    "If you're concerned about your condition"
                ]
            }
        }
        
        # Hindi templates
        self.templates_hi = {
            "emergency": {
                "message": "⚠️ आपातकाल: तुरंत चिकित्सा सहायता लें!",
                "description": "आपके लक्षण एक गंभीर स्थिति का संकेत देते हैं जिसके लिए तत्काल देखभाल की आवश्यकता है।",
                "actions": [
                    "तुरंत आपातकालीन सेवाओं (108) को कॉल करें",
                    "खुद गाड़ी न चलाएं - एम्बुलेंस बुलाएं",
                    "यदि बेहोश हो तो रिकवरी पोजीशन में रखें",
                    "शांत रहें और रोगी के साथ रहें",
                    "लक्षण शुरू होने का समय नोट करें"
                ],
                "do_not": [
                    "मदद बुलाने में देरी न करें",
                    "बेहोश व्यक्ति को खाना या पानी न दें",
                    "रोगी को अकेला न छोड़ें"
                ],
                "symptoms_requiring_emergency": [
                    "गंभीर सीने में दर्द या दबाव",
                    "सांस लेने में कठिनाई या सांस की कमी",
                    "अचानक गंभीर सिरदर्द",
                    "बेहोशी",
                    "गंभीर रक्तस्राव",
                    "स्ट्रोक के लक्षण (चेहरे का लटकना, हाथ की कमजोरी, बोलने में कठिनाई)"
                ]
            },
            
            "doctor": {
                "message": "🏥 कृपया 24-48 घंटों के भीतर डॉक्टर से परामर्श लें।",
                "description": "आपके लक्षण बताते हैं कि आपको जल्द ही एक स्वास्थ्य पेशेवर से मिलना चाहिए।",
                "actions": [
                    "अपने डॉक्टर के साथ अपॉइंटमेंट शेड्यूल करें",
                    "नजदीकी क्लिनिक या अस्पताल जाएं",
                    "अपने सभी लक्षणों और उनकी अवधि को नोट करें",
                    "यदि बुखार है तो अपने तापमान का रिकॉर्ड रखें",
                    "निगरानी करें कि लक्षण बदतर तो नहीं हो रहे"
                ],
                "do_not": [
                    "लगातार लक्षणों को नजरअंदाज न करें",
                    "एंटीबायोटिक्स के साथ स्व-दवा न करें",
                    "अगर लक्षण बदतर हो जाएं तो इंतजार न करें"
                ],
                "when_to_seek_emergency": [
                    "यदि बुखार 103°F (39.4°C) से अधिक हो",
                    "यदि सांस लेना मुश्किल हो जाए",
                    "यदि आप तरल पदार्थ नहीं रख सकते",
                    "यदि लक्षण अचानक बदतर हो जाएं",
                    "यदि आपको सीने में दर्द हो"
                ]
            },
            
            "self-care": {
                "message": "🏡 आप स्व-देखभाल के साथ घर पर इसका प्रबंधन कर सकते हैं।",
                "description": "आपके लक्षण हल्के लगते हैं और संभवतः आराम और घरेलू उपचार से प्रबंधित किए जा सकते हैं।",
                "actions": [
                    "भरपूर आराम करें",
                    "अच्छी तरह से हाइड्रेटेड रहें - प्रतिदिन 8-10 गिलास पानी पिएं",
                    "संतुलित, पौष्टिक आहार लें",
                    "24-48 घंटों के लिए अपने लक्षणों की निगरानी करें",
                    "आवश्यकता होने पर ओवर-द-काउंटर उपचार का उपयोग करें"
                ],
                "do_not": [
                    "खुद को ज्यादा थकाएं नहीं",
                    "बिगड़ते लक्षणों को नजरअंदाज न करें",
                    "भोजन या तरल पदार्थ न छोड़ें"
                ],
                "when_to_seek_doctor": [
                    "यदि लक्षण 3 दिनों से अधिक बने रहें",
                    "यदि सुधार के बजाय लक्षण बिगड़ जाएं",
                    "यदि नए लक्षण विकसित हों",
                    "यदि तेज बुखार हो",
                    "यदि आप अपनी स्थिति के बारे में चिंतित हैं"
                ]
            }
        }
        
        # Marathi templates (optional - can add more languages)
        self.templates_mr = {
            "emergency": {
                "message": "⚠️ आणीबाणी: ताबडतोब वैद्यकीय मदत घ्या!",
                "description": "तुमची लक्षणे गंभीर स्थितीचे संकेत देतात ज्यासाठी तातडीची काळजी आवश्यक आहे।",
                "actions": [
                    "ताबडतोब आणीबाणी सेवांना (108) कॉल करा",
                    "स्वतः गाडी चालवू नका - रुग्णवाहिका बोलवा",
                    "जर बेशुद्ध असेल तर रिकव्हरी पोझिशनमध्ये ठेवा",
                    "शांत रहा आणि रुग्णासोबत रहा",
                    "लक्षणे सुरू झाल्याची वेळ नोंदवा"
                ],
                "do_not": [
                    "मदत मागण्यास उशीर करू नका",
                    "बेशुद्ध व्यक्तीला अन्न किंवा पाणी देऊ नका",
                    "रुग्णाला एकटे सोडू नका"
                ]
            },
            "doctor": {
                "message": "🏥 कृपया 24-48 तासांत डॉक्टरांचा सल्ला घ्या.",
                "description": "तुमची लक्षणे सूचित करतात की तुम्ही लवकरच आरोग्य व्यावसायिकांना भेटावे.",
                "actions": [
                    "तुमच्या डॉक्टरांसोबत भेटीचा वेळ ठरवा",
                    "जवळच्या दवाखान्यात किंवा रुग्णालयात जा",
                    "तुमची सर्व लक्षणे आणि त्यांचा कालावधी नोंदवा",
                    "जर ताप असेल तर तुमच्या तापमानाची नोंद ठेवा",
                    "लक्षणे बिघडत नाहीत याचे निरीक्षण करा"
                ],
                "do_not": [
                    "सतत लक्षणांकडे दुर्लक्ष करू नका",
                    "प्रतिजैविकांसह स्व-औषध करू नका"
                ]
            },
            "self-care": {
                "message": "🏡 तुम्ही स्व-काळजीसह घरी याचे व्यवस्थापन करू शकता.",
                "description": "तुमची लक्षणे सौम्य दिसतात आणि विश्रांती आणि घरगुती उपायांनी व्यवस्थापित केली जाऊ शकतात.",
                "actions": [
                    "भरपूर विश्रांती घ्या",
                    "चांगले हायड्रेटेड रहा - दररोज 8-10 ग्लास पाणी प्या",
                    "संतुलित, पौष्टिक आहार घ्या",
                    "24-48 तासांसाठी तुमच्या लक्षणांचे निरीक्षण करा"
                ],
                "do_not": [
                    "स्वतःला जास्त थकवू नका",
                    "बिघडणाऱ्या लक्षणांकडे दुर्लक्ष करू नका"
                ]
            }
        }
        
    def generate_guidance(
        self, 
        urgency_level: str, 
        language: str = "en",
        symptoms: Optional[List[str]] = None,
        severity: Optional[str] = None
    ) -> Dict:
        """
        Generate guidance message and actions based on urgency level and language
        
        Args:
            urgency_level: One of "emergency", "doctor", "self-care"
            language: Language code - "en", "hi", "mr" (default: "en")
            symptoms: Optional list of detected symptoms
            severity: Optional severity level
            
        Returns:
            Dictionary with message, description, actions, warnings, and metadata
        """
        
        # Normalize urgency level
        urgency_level = urgency_level.lower()
        if urgency_level not in ["emergency", "doctor", "self-care"]:
            urgency_level = "self-care"  # Default to safest option
        
        # Select template based on language
        templates = self._get_templates(language)
        template = templates.get(urgency_level, templates["self-care"])
        
        # Build response
        response = {
            "urgency_level": urgency_level,
            "language": language,
            "message": template["message"],
            "description": template["description"],
            "actions": template["actions"],
            "do_not": template.get("do_not", []),
            "warnings": self._get_warnings(urgency_level, template),
            "metadata": {
                "symptoms_count": len(symptoms) if symptoms else 0,
                "severity": severity if severity else "unknown",
                "template_version": "1.0"
            }
        }
        
        # Add symptoms if provided
        if symptoms:
            response["detected_symptoms"] = symptoms
        
        return response
    
    def _get_templates(self, language: str) -> Dict:
        """Get templates for specified language, fallback to English"""
        language_map = {
            "en": self.templates_en,
            "english": self.templates_en,
            "hi": self.templates_hi,
            "hindi": self.templates_hi,
            "mr": self.templates_mr,
            "marathi": self.templates_mr
        }
        
        return language_map.get(language.lower(), self.templates_en)
    
    def _get_warnings(self, urgency_level: str, template: Dict) -> List[str]:
        """Get relevant warnings based on urgency level"""
        if urgency_level == "emergency":
            return template.get("symptoms_requiring_emergency", [])
        elif urgency_level == "doctor":
            return template.get("when_to_seek_emergency", [])
        else:  # self-care
            return template.get("when_to_seek_doctor", [])
    
    def get_emergency_contacts(self, language: str = "en") -> Dict:
        """Get emergency contact information"""
        contacts = {
            "en": {
                "ambulance": "108",
                "police": "100",
                "fire": "101",
                "women_helpline": "1091",
                "child_helpline": "1098",
                "disaster_management": "108"
            },
            "hi": {
                "एम्बुलेंस": "108",
                "पुलिस": "100",
                "फायर": "101",
                "महिला हेल्पलाइन": "1091",
                "बाल हेल्पलाइन": "1098",
                "आपदा प्रबंधन": "108"
            },
            "mr": {
                "रुग्णवाहिका": "108",
                "पोलीस": "100",
                "अग्निशमन": "101",
                "महिला हेल्पलाइन": "1091",
                "बाल हेल्पलाइन": "1098"
            }
        }
        
        return contacts.get(language, contacts["en"])


# Standalone function for quick usage
def get_guidance(urgency_level: str, language: str = "en", **kwargs) -> Dict:
    """
    Quick function to get guidance without instantiating class
    
    Args:
        urgency_level: "emergency", "doctor", or "self-care"
        language: "en", "hi", or "mr"
        **kwargs: Additional parameters (symptoms, severity)
        
    Returns:
        Guidance dictionary
    """
    generator = GuidanceGenerator()
    return generator.generate_guidance(urgency_level, language, **kwargs)


if __name__ == "__main__":
    # Test the guidance generator
    print("="*80)
    print("TESTING GUIDANCE GENERATOR")
    print("="*80)
    
    generator = GuidanceGenerator()
    
    # Test cases
    test_cases = [
        {
            "urgency": "emergency",
            "language": "en",
            "symptoms": ["chest pain", "difficulty breathing"],
            "severity": "severe"
        },
        {
            "urgency": "doctor",
            "language": "hi",
            "symptoms": ["fever", "headache"],
            "severity": "high"
        },
        {
            "urgency": "self-care",
            "language": "en",
            "symptoms": ["mild headache"],
            "severity": "mild"
        }
    ]
    
    for i, test in enumerate(test_cases, 1):
        print(f"\n{'='*80}")
        print(f"TEST {i}: {test['urgency'].upper()} - {test['language'].upper()}")
        print('='*80)
        
        result = generator.generate_guidance(
            urgency_level=test['urgency'],
            language=test['language'],
            symptoms=test.get('symptoms'),
            severity=test.get('severity')
        )
        
        print(f"\n📋 Message: {result['message']}")
        print(f"\n📝 Description: {result['description']}")
        print(f"\n✅ Actions to take:")
        for action in result['actions'][:3]:
            print(f"   • {action}")
        
        if result['do_not']:
            print(f"\n❌ Do NOT:")
            for dont in result['do_not'][:2]:
                print(f"   • {dont}")
        
        print(f"\n⚠️  Important warnings: {len(result['warnings'])} items")
        print(f"\n📊 Metadata: {result['metadata']}")
    
    # Test emergency contacts
    print(f"\n{'='*80}")
    print("EMERGENCY CONTACTS (Hindi)")
    print('='*80)
    contacts = generator.get_emergency_contacts("hi")
    for service, number in contacts.items():
        print(f"   {service}: {number}")
    
    print(f"\n{'='*80}")
    print("TESTING COMPLETE")
    print('='*80)
