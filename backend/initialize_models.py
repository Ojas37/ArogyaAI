"""
Model Initialization Script

Downloads and verifies all required models for the healthcare triage system
Run this ONCE before first use
"""

import os
import sys
import urllib.request
from pathlib import Path


def print_header(text):
    """Print formatted header"""
    print(f"\n{'='*70}")
    print(f"  {text}")
    print(f"{'='*70}\n")


def download_fasttext_model():
    """Download fastText language detection model"""
    print_header("1. FastText Language Detection Model")
    
    model_path = "lid.176.bin"
    
    if os.path.exists(model_path):
        print(f"✅ Model already exists: {model_path}")
        return True
    
    print(f"📥 Downloading fastText model (126MB)...")
    url = "https://dl.fbaipublicfiles.com/fasttext/supervised-models/lid.176.bin"
    
    try:
        urllib.request.urlretrieve(url, model_path)
        print(f"✅ Downloaded: {model_path}")
        return True
    except Exception as e:
        print(f"❌ Download failed: {e}")
        print(f"   Please download manually from: {url}")
        return False


def verify_pkl_models():
    """Verify all required .pkl model files exist"""
    print_header("2. Verifying Triage Model Files")
    
    required_models = [
        "triage_xgboost_model.pkl",
        "feature_columns.pkl",
        "label_encoder (1).pkl",
        "dst_decision_model.pkl"
    ]
    
    all_exist = True
    for model_file in required_models:
        if os.path.exists(model_file):
            print(f"✅ Found: {model_file}")
        else:
            print(f"❌ Missing: {model_file}")
            all_exist = False
    
    if not all_exist:
        print("\n⚠️  Some model files are missing!")
        print("   Please ensure all .pkl files are in the backend directory")
    
    return all_exist


def test_transformers_models():
    """Test that HuggingFace models can be loaded"""
    print_header("3. Testing HuggingFace Models")
    
    try:
        print("📦 Testing Intent Classifier...")
        from intent_classifier import IntentClassifier
        intent_clf = IntentClassifier()
        print("✅ Intent Classifier loaded successfully")
    except Exception as e:
        print(f"❌ Intent Classifier failed: {e}")
        return False
    
    try:
        print("\n📦 Testing Symptom Extractor (Medical NER)...")
        from extraction_layer import MedicalSymptomExtractor
        extractor = MedicalSymptomExtractor()
        print("✅ Symptom Extractor loaded successfully")
    except Exception as e:
        print(f"❌ Symptom Extractor failed: {e}")
        return False
    
    return True


def verify_dependencies():
    """Verify all Python dependencies are installed"""
    print_header("4. Verifying Python Dependencies")
    
    required_packages = [
        ("fastapi", "FastAPI"),
        ("uvicorn", "Uvicorn"),
        ("transformers", "Transformers"),
        ("torch", "PyTorch"),
        ("sklearn", "Scikit-learn"),
        ("xgboost", "XGBoost"),
        ("pandas", "Pandas"),
        ("numpy", "NumPy"),
        ("langdetect", "LangDetect"),
    ]
    
    missing = []
    
    for package, name in required_packages:
        try:
            __import__(package)
            print(f"✅ {name}")
        except ImportError:
            print(f"❌ {name} not installed")
            missing.append(package)
    
    if missing:
        print(f"\n⚠️  Missing packages: {', '.join(missing)}")
        print("   Install with: pip install -r requirements.txt")
        return False
    
    return True


def run_quick_test():
    """Run a quick test of the complete pipeline"""
    print_header("5. Running Quick Pipeline Test")
    
    try:
        from pipeline_orchestrator import HealthcareTriagePipeline
        
        print("🏥 Initializing pipeline...")
        pipeline = HealthcareTriagePipeline()
        
        print("\n🧪 Testing with sample message...")
        test_message = "I have fever and headache"
        
        result = pipeline.process_message(test_message, force_language='en')
        
        print(f"\n✅ Pipeline test successful!")
        print(f"   Input: {test_message}")
        print(f"   Triage: {result['triage']}")
        print(f"   Response: {result['spoken_response'][:80]}...")
        
        return True
    except Exception as e:
        print(f"❌ Pipeline test failed: {e}")
        import traceback
        traceback.print_exc()
        return False


def main():
    """Main initialization function"""
    print("="*70)
    print("  🏥 AROGYAAI HEALTHCARE TRIAGE SYSTEM")
    print("  Model Initialization & Verification")
    print("="*70)
    
    # Change to backend directory if needed
    if os.path.exists("backend") and not os.path.exists("pipeline_orchestrator.py"):
        os.chdir("backend")
        print(f"\n📁 Changed directory to: {os.getcwd()}")
    
    results = []
    
    # Step 1: Download fastText model
    results.append(("FastText Model", download_fasttext_model()))
    
    # Step 2: Verify .pkl models
    results.append(("PKL Models", verify_pkl_models()))
    
    # Step 3: Verify dependencies
    results.append(("Dependencies", verify_dependencies()))
    
    # Step 4: Test HuggingFace models
    results.append(("HuggingFace Models", test_transformers_models()))
    
    # Step 5: Quick pipeline test
    results.append(("Pipeline Test", run_quick_test()))
    
    # Summary
    print_header("INITIALIZATION SUMMARY")
    
    for name, success in results:
        status = "✅ PASS" if success else "❌ FAIL"
        print(f"{status}  {name}")
    
    all_success = all(success for _, success in results)
    
    if all_success:
        print("\n🎉 All checks passed! System is ready to use.")
        print("\n📝 Next steps:")
        print("   1. Run tests: python test_pipeline.py")
        print("   2. Start server: uvicorn main:app --reload")
        print("   3. Read docs: INTEGRATION_COMPLETE.md")
        return 0
    else:
        print("\n⚠️  Some checks failed. Please resolve issues above.")
        return 1


if __name__ == "__main__":
    exit_code = main()
    sys.exit(exit_code)
