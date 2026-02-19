"""
RAG (Retrieval-Augmented Generation) Layer for Medical Knowledge Enhancement

This module provides medical knowledge retrieval to enhance:
1. Follow-up question generation (contextual and relevant)
2. Triage validation (evidence-based)
3. Explanations (with medical citations)

Architecture:
- Vector Database: ChromaDB (persistent, local)
- Embeddings: Sentence Transformers (all-MiniLM-L6-v2 - free, fast)
- Retrieval: LangChain integration with Groq LLM
"""

import os
from typing import List, Dict, Optional
from langchain_community.vectorstores import Chroma
from langchain_community.embeddings import HuggingFaceEmbeddings
from langchain_openai import ChatOpenAI
from langchain.chains import RetrievalQA
from langchain.prompts import PromptTemplate
from langchain.schema import Document


class MedicalRAG:
    """Medical Knowledge Retrieval-Augmented Generation System"""
    
    def __init__(self, persist_directory: str = "./medical_knowledge_db"):
        """
        Initialize RAG system with vector store and LLM
        
        Args:
            persist_directory: Path to persist ChromaDB data
        """
        self.persist_directory = persist_directory
        self.embeddings = None
        self.vectorstore = None
        self.llm = None
        
        # Initialize components
        self._initialize_embeddings()
        self._initialize_vectorstore()
        self._initialize_llm()
        
        print("✅ Medical RAG system initialized")
    
    def _initialize_embeddings(self):
        """Initialize HuggingFace embeddings (free, works offline)"""
        try:
            self.embeddings = HuggingFaceEmbeddings(
                model_name="sentence-transformers/all-MiniLM-L6-v2",
                model_kwargs={'device': 'cpu'},
                encode_kwargs={'normalize_embeddings': True}
            )
            print("✅ Loaded embedding model: all-MiniLM-L6-v2")
        except Exception as e:
            print(f"⚠️  Embedding model loading failed: {e}")
            self.embeddings = None
    
    def _initialize_vectorstore(self):
        """Initialize ChromaDB vector store (creates if doesn't exist)"""
        if not self.embeddings:
            print("⚠️  Skipping vector store - embeddings not available")
            return
        
        # Create or load vector store
        print(f"🔍 Checking vector store at: {self.persist_directory}")
        
        try:
            self.vectorstore = Chroma(
                persist_directory=self.persist_directory,
                embedding_function=self.embeddings,
                collection_name="medical_knowledge"
            )
            print(f"✅ Chroma vectorstore created: {type(self.vectorstore)}")
        except Exception as e:
            print(f"❌ Failed to create Chroma vectorstore: {e}")
            import traceback
            traceback.print_exc()
            self.vectorstore = None
            return
        
        # Check if we have documents
        try:
            doc_count = self.vectorstore._collection.count()
            print(f"📊 Current vector store has {doc_count} documents")
        except Exception as e:
            print(f"❌ Failed to count documents: {e}")
            import traceback
            traceback.print_exc()
            return
        
        # Populate if empty
        if doc_count == 0:
            print("⚠️ Vector store is empty, populating with medical knowledge...")
            try:
                self._populate_initial_knowledge()
            except Exception as e:
                print(f"❌ Failed to populate knowledge: {e}")
                import traceback
                traceback.print_exc()
        else:
            print(f"✅ Loaded existing vector store: {doc_count} documents")
    
    def _initialize_llm(self):
        """Initialize Groq LLM for RAG-enhanced responses"""
        try:
            groq_api_key = os.getenv("GROQ_API_KEY")
            if not groq_api_key:
                print("⚠️  GROQ_API_KEY not found - RAG will use templates only")
                return
            
            self.llm = ChatOpenAI(
                model="llama-3.1-8b-instant",
                openai_api_key=groq_api_key,
                openai_api_base="https://api.groq.com/openai/v1",
                temperature=0.3,  # Lower temperature for factual medical info
                max_tokens=150,  # Reduced for faster responses
                timeout=10  # Timeout after 10 seconds
            )
            print("✅ Groq LLM initialized for RAG")
        except Exception as e:
            print(f"⚠️  LLM initialization failed: {e}")
            self.llm = None
    
    def _populate_initial_knowledge(self):
        """Populate vector store with essential medical triage knowledge"""
        print(f"🔄 _populate_initial_knowledge() called")
        print(f"   - self.vectorstore = {self.vectorstore}")
        print(f"   - type = {type(self.vectorstore)}")
        print(f"   - is None? {self.vectorstore is None}")
        print(f"   - bool check: {bool(self.vectorstore) if self.vectorstore is not None else 'N/A'}")
        
        if self.vectorstore is None:
            print("❌ ERROR: vectorstore is None, cannot populate!")
            return
        
        print(f"✅ Vectorstore exists: {type(self.vectorstore)}")
        
        # Essential medical knowledge for triage
        medical_documents = [
            # Emergency red flags
            Document(
                page_content="Chest pain with shortness of breath, sweating, or radiating pain to arm/jaw indicates potential heart attack. This is a medical emergency requiring immediate attention (call emergency services). Duration: Any duration is concerning.",
                metadata={"category": "emergency", "symptom": "chest_pain", "urgency": "EMERGENCY"}
            ),
            Document(
                page_content="Severe difficulty breathing, gasping for air, blue lips/face, or inability to speak full sentences indicates respiratory emergency. Seek immediate emergency care. Common causes: anaphylaxis, asthma attack, pneumonia, pulmonary embolism.",
                metadata={"category": "emergency", "symptom": "breathing_difficulty", "urgency": "EMERGENCY"}
            ),
            Document(
                page_content="Sudden severe headache (thunderclap headache), worst headache of life, especially with confusion, vision changes, or loss of consciousness may indicate stroke or brain hemorrhage. Call emergency services immediately.",
                metadata={"category": "emergency", "symptom": "severe_headache", "urgency": "EMERGENCY"}
            ),
            Document(
                page_content="Uncontrolled bleeding, spurting blood, or bleeding that doesn't stop after 10 minutes of pressure is a medical emergency. Apply direct pressure and seek immediate help.",
                metadata={"category": "emergency", "symptom": "severe_bleeding", "urgency": "EMERGENCY"}
            ),
            
            # Fever duration guidelines
            Document(
                page_content="Fever lasting more than 3-4 weeks (chronic fever) requires urgent medical evaluation. Possible causes include tuberculosis, lymphoma, autoimmune diseases, or hidden infections. This is NOT normal and requires diagnostic workup including blood tests, imaging.",
                metadata={"category": "duration_rules", "symptom": "fever", "duration": "chronic", "urgency": "EMERGENCY"}
            ),
            Document(
                page_content="Fever over 103°F (39.4°C) in adults or any fever in infants under 3 months requires same-day medical attention. High fever with severe headache, stiff neck, rash, or confusion suggests serious infection (meningitis).",
                metadata={"category": "urgent", "symptom": "high_fever", "urgency": "URGENT"}
            ),
            Document(
                page_content="Low-grade fever (100-102°F) for 3-7 days with improving symptoms is often viral and can be managed with rest, fluids, and fever reducers. Seek care if fever persists beyond 7 days or worsens.",
                metadata={"category": "self_care", "symptom": "fever", "duration": "short", "urgency": "SELF_CARE"}
            ),
            
            # Chronic symptom duration rules
            Document(
                page_content="Any persistent symptom lasting 4-6 weeks or longer (chronic) requires medical evaluation even if mild. Chronic symptoms can indicate serious underlying conditions that need diagnosis: cancer, autoimmune disease, chronic infection, organ dysfunction.",
                metadata={"category": "duration_rules", "symptom": "chronic_symptoms", "urgency": "EMERGENCY"}
            ),
            Document(
                page_content="Persistent cough for more than 3 weeks, especially with blood, weight loss, or night sweats, requires chest X-ray and medical evaluation. Possible causes: tuberculosis, lung cancer, chronic bronchitis, pertussis.",
                metadata={"category": "urgent", "symptom": "chronic_cough", "urgency": "URGENT"}
            ),
            
            # Common symptom triage
            Document(
                page_content="Abdominal pain: Sudden severe pain (especially right lower abdomen) with fever, vomiting may be appendicitis - EMERGENCY. Persistent pain >24 hours or worsening pain - see doctor within 24 hours. Mild cramping that resolves - monitor at home.",
                metadata={"category": "symptom_guide", "symptom": "abdominal_pain", "urgency": "VARIES"}
            ),
            Document(
                page_content="Headache: Sudden worst headache ever, headache with fever+stiff neck, or headache after head injury - EMERGENCY. Severe migraine not responding to usual treatment - urgent care. Mild tension headache - self-care with rest and pain relievers.",
                metadata={"category": "symptom_guide", "symptom": "headache", "urgency": "VARIES"}
            ),
            Document(
                page_content="Dizziness/vertigo: With chest pain, difficulty speaking, or one-sided weakness - EMERGENCY (stroke). Severe room-spinning vertigo with vomiting - urgent care same day. Mild lightheadedness when standing - increase fluids, rest.",
                metadata={"category": "symptom_guide", "symptom": "dizziness", "urgency": "VARIES"}
            ),
            
            # Follow-up question guidelines
            Document(
                page_content="Essential triage questions: (1) Duration: When did symptoms start? (2) Severity: Rate pain/discomfort 1-10. (3) Associated symptoms: Other symptoms occurring together? (4) Red flags: Difficulty breathing, chest pain, severe bleeding, altered consciousness? (5) Medical history: Chronic conditions, allergies, current medications?",
                metadata={"category": "triage_protocol", "type": "follow_up_questions"}
            ),
            Document(
                page_content="Pain assessment scale: 1-3 (mild - daily activities not affected), 4-6 (moderate - some limitation), 7-9 (severe - major limitation), 10 (worst imaginable - cannot function). Severity helps determine urgency and appropriate care level.",
                metadata={"category": "triage_protocol", "type": "severity_assessment"}
            ),
            
            # Self-care guidance
            Document(
                page_content="Common cold symptoms (runny nose, sore throat, mild cough, low fever <101°F): Self-care with rest, fluids (8+ glasses water/day), humidity, over-the-counter cold medicine. See doctor if symptoms worsen after 3 days or persist beyond 10 days.",
                metadata={"category": "self_care", "condition": "common_cold", "urgency": "SELF_CARE"}
            ),
            Document(
                page_content="Minor cuts/scrapes: Clean with soap and water, apply antibiotic ointment, bandage. Monitor for infection signs (increased redness, warmth, pus, red streaks). Seek medical care if signs of infection appear or wound doesn't heal in 7-10 days.",
                metadata={"category": "self_care", "condition": "minor_wound", "urgency": "SELF_CARE"}
            ),
        ]
        
        print(f"📋 Created {len(medical_documents)} document objects")
        
        try:
            # Add documents to vector store
            print(f"📝 Adding {len(medical_documents)} medical documents to vector store...")
            self.vectorstore.add_documents(medical_documents)
            
            # Verify documents were added
            doc_count = self.vectorstore._collection.count()
            print(f"✅ Successfully added {doc_count} medical knowledge documents to vector store")
            
            if doc_count == 0:
                print("❌ ERROR: Documents were not persisted to vector store!")
                print("   This may be a ChromaDB issue. Try deleting the medical_knowledge_db folder and restarting.")
                
        except Exception as e:
            print(f"❌ Failed to populate knowledge base: {e}")
            import traceback
            traceback.print_exc()
    
    def retrieve_relevant_knowledge(self, query: str, k: int = 3) -> List[Dict]:
        """
        Retrieve relevant medical knowledge for a query
        
        Args:
            query: User's symptoms or medical question
            k: Number of documents to retrieve
            
        Returns:
            List of relevant medical knowledge with metadata
        """
        if not self.vectorstore:
            return []
        
        try:
            # Retrieve similar documents
            results = self.vectorstore.similarity_search_with_score(query, k=k)
            
            knowledge = []
            for doc, score in results:
                knowledge.append({
                    "content": doc.page_content,
                    "metadata": doc.metadata,
                    "relevance_score": float(score)
                })
            
            return knowledge
        except Exception as e:
            print(f"⚠️  Retrieval failed: {e}")
            return []
    
    def enhance_followup_question(self, 
                                   symptoms: str, 
                                   conversation_history: List[Dict],
                                   extracted_data: Dict) -> str:
        """
        Use RAG to generate smarter, contextually relevant follow-up questions
        
        Args:
            symptoms: Current extracted symptoms
            conversation_history: Past conversation
            extracted_data: Already collected data (severity, duration)
            
        Returns:
            Enhanced follow-up question
        """
        # Retrieve relevant medical knowledge
        knowledge = self.retrieve_relevant_knowledge(symptoms, k=2)
        
        if not knowledge or not self.llm:
            # Fallback to basic follow-up
            return self._basic_followup(extracted_data)
        
        # Build context from retrieved knowledge
        context = "\n\n".join([k["content"] for k in knowledge])
        
        # Create prompt for intelligent follow-up
        prompt = f"""You are a medical triage assistant. Ask ONE simple, direct question to gather essential information.

PATIENT SYMPTOMS: {symptoms}

ALREADY COLLECTED:
- Severity: {extracted_data.get('severity', 'Not asked')}
- Duration: {extracted_data.get('duration', 'Not asked')}

RULES - USE EXACT TEMPLATES:
- If severity is missing, ask EXACTLY: "On a scale of 1-10, where 1 is mild and 10 is severe, how bad is your discomfort?"
- If duration is missing, ask EXACTLY: "How long have you been experiencing these symptoms?"
- DO NOT modify these templates
- DO NOT ask about specific symptoms or temperature
- DO NOT ask yes/no questions

Follow-up question (use exact template):"""
        
        try:
            response = self.llm.invoke(prompt)
            return response.content.strip()
        except Exception as e:
            print(f"⚠️  LLM follow-up generation failed: {e}")
            return self._basic_followup(extracted_data)
    
    def _basic_followup(self, extracted_data: Dict) -> str:
        """Fallback follow-up question logic"""
        if not extracted_data.get('severity'):
            return "On a scale of 1-10, where 1 is mild and 10 is severe, how bad is your discomfort?"
        elif not extracted_data.get('duration'):
            return "How long have you been experiencing these symptoms?"
        else:
            return "Do you have any other symptoms?"
    
    def validate_triage_with_evidence(self, 
                                      symptoms: str,
                                      severity: str,
                                      duration: str,
                                      ml_prediction: str) -> Dict:
        """
        Validate ML model triage prediction against medical evidence
        
        Args:
            symptoms: Patient symptoms
            severity: Severity level
            duration: Duration of symptoms
            ml_prediction: XGBoost model prediction
            
        Returns:
            {
                "validated_urgency": str,
                "evidence": str,
                "override": bool,
                "reason": str
            }
        """
        # Retrieve evidence
        query = f"{symptoms} severity {severity} duration {duration}"
        knowledge = self.retrieve_relevant_knowledge(query, k=3)
        
        if not knowledge:
            return {
                "validated_urgency": ml_prediction,
                "evidence": "No medical evidence retrieved",
                "override": False,
                "reason": "Using ML model prediction"
            }
        
        # Extract urgency from retrieved evidence
        evidence_urgencies = [k["metadata"].get("urgency") for k in knowledge if "urgency" in k["metadata"]]
        
        # Check for EMERGENCY evidence
        if "EMERGENCY" in evidence_urgencies:
            emergency_evidence = [k for k in knowledge if k["metadata"].get("urgency") == "EMERGENCY"]
            return {
                "validated_urgency": "EMERGENCY",
                "evidence": emergency_evidence[0]["content"],
                "override": ml_prediction != "EMERGENCY",
                "reason": "Medical guidelines indicate emergency situation"
            }
        
        # Return ML prediction with supporting evidence
        return {
            "validated_urgency": ml_prediction,
            "evidence": knowledge[0]["content"] if knowledge else "",
            "override": False,
            "reason": "ML prediction aligns with medical guidelines"
        }
    
    def enhance_explanation(self, 
                           urgency_level: str,
                           symptoms: str,
                           base_explanation: str) -> Dict:
        """
        Enhance triage explanation with medical evidence and citations
        
        Args:
            urgency_level: EMERGENCY/URGENT/SELF_CARE
            symptoms: Patient symptoms
            base_explanation: Base explanation from explanation layer
            
        Returns:
            {
                "enhanced_explanation": str,
                "medical_evidence": List[str],
                "recommendations": str
            }
        """
        # Retrieve supporting medical evidence
        knowledge = self.retrieve_relevant_knowledge(f"{urgency_level} {symptoms}", k=2)
        
        if not knowledge:
            return {
                "enhanced_explanation": base_explanation,
                "medical_evidence": [],
                "recommendations": ""
            }
        
        # Extract evidence
        evidence_list = [k["content"] for k in knowledge]
        
        # Build enhanced explanation
        enhanced = f"{base_explanation}\n\nMEDICAL CONTEXT:\n"
        for i, evidence in enumerate(evidence_list, 1):
            enhanced += f"\n{i}. {evidence[:200]}..."  # Truncate for brevity
        
        return {
            "enhanced_explanation": enhanced,
            "medical_evidence": evidence_list,
            "recommendations": self._get_recommendations(urgency_level)
        }
    
    def _get_recommendations(self, urgency_level: str) -> str:
        """Get action recommendations based on urgency"""
        recommendations = {
            "EMERGENCY": "🚨 SEEK IMMEDIATE EMERGENCY CARE: Call emergency services (911) or go to nearest emergency room immediately.",
            "URGENT": "⚠️  SEE A DOCTOR WITHIN 24 HOURS: Contact your doctor or visit urgent care clinic today.",
            "SELF_CARE": "✅ MONITOR AT HOME: Rest, stay hydrated, and use over-the-counter treatments as needed. See a doctor if symptoms worsen or persist beyond 7-10 days."
        }
        return recommendations.get(urgency_level, "Consult a healthcare professional for guidance.")


# Global RAG instance (lazy initialization)
_medical_rag_instance = None


def get_medical_rag() -> Optional[MedicalRAG]:
    """Get global RAG instance (singleton pattern)"""
    global _medical_rag_instance
    
    if _medical_rag_instance is None:
        try:
            _medical_rag_instance = MedicalRAG()
        except Exception as e:
            print(f"⚠️  Failed to initialize Medical RAG: {e}")
            print("   System will continue without RAG enhancement")
            return None
    
    return _medical_rag_instance


if __name__ == "__main__":
    # Test RAG system
    print("Testing Medical RAG System...\n")
    
    rag = get_medical_rag()
    if rag:
        # Test retrieval
        print("\n1. Testing knowledge retrieval:")
        results = rag.retrieve_relevant_knowledge("fever for 2 months", k=3)
        for i, result in enumerate(results, 1):
            print(f"\n   Result {i}:")
            print(f"   Content: {result['content'][:100]}...")
            print(f"   Urgency: {result['metadata'].get('urgency', 'N/A')}")
        
        # Test follow-up enhancement
        print("\n2. Testing follow-up question enhancement:")
        question = rag.enhance_followup_question(
            symptoms="fever, headache",
            conversation_history=[],
            extracted_data={}
        )
        print(f"   Generated: {question}")
        
        # Test triage validation
        print("\n3. Testing triage validation:")
        validation = rag.validate_triage_with_evidence(
            symptoms="fever",
            severity="moderate",
            duration="3 months",
            ml_prediction="URGENT"
        )
        print(f"   Validated Urgency: {validation['validated_urgency']}")
        print(f"   Override: {validation['override']}")
        print(f"   Reason: {validation['reason']}")
