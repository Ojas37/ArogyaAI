"""
Fix feature_columns.pkl compatibility issue
This script extracts column names from the old pickle and saves in compatible format
"""

import pickle
import sys

def fix_feature_columns():
    """Extract and re-save feature columns in compatible format"""
    
    print("🔧 Fixing feature_columns.pkl...")
    
    # Try multiple approaches to extract the column names
    columns = None
    
    # Approach 1: Try with latin1 encoding and extract raw data
    try:
        print("   Attempting method 1: Raw pickle with latin1...")
        with open('feature_columns.pkl', 'rb') as f:
            data = pickle.load(f, encoding='latin1')
            
            # Try different ways to extract list data
            if hasattr(data, 'tolist'):
                columns = data.tolist()
                print(f"   ✓ Extracted {len(columns)} columns using tolist()")
            elif hasattr(data, 'values'):
                columns = list(data.values)
                print(f"   ✓ Extracted {len(columns)} columns using values")
            elif hasattr(data, '_data'):
                columns = list(data._data)
                print(f"   ✓ Extracted {len(columns)} columns using _data")
            elif isinstance(data, (list, tuple)):
                columns = list(data)
                print(f"   ✓ Extracted {len(columns)} columns as list")
            else:
                print(f"   ⚠️  Unknown data type: {type(data)}")
                print(f"   Available attributes: {dir(data)}")
    except Exception as e:
        print(f"   ✗ Method 1 failed: {e}")
    
    # Approach 2: Try to read with numpy
    if columns is None:
        try:
            print("   Attempting method 2: Numpy load...")
            import numpy as np
            data = np.load('feature_columns.pkl', allow_pickle=True, encoding='latin1')
            columns = list(data)
            print(f"   ✓ Extracted {len(columns)} columns using numpy")
        except Exception as e:
            print(f"   ✗ Method 2 failed: {e}")
    
    if columns is None:
        print("\n❌ Could not extract columns automatically.")
        print("\n📝 Manual solution:")
        print("   1. Open your training notebook")
        print("   2. Get the feature column names from X_train.columns or similar")
        print("   3. Save them using:")
        print("      import joblib")
        print("      joblib.dump(list(column_names), 'feature_columns.pkl')")
        return False
    
    # Save in multiple formats for safety
    print(f"\n💾 Saving {len(columns)} feature columns...")
    
    # Save with joblib (most compatible)
    try:
        import joblib
        joblib.dump(columns, 'feature_columns_fixed.pkl')
        print("   ✓ Saved: feature_columns_fixed.pkl (joblib)")
    except ImportError:
        print("   ⚠️  joblib not available, skipping joblib format")
    
    # Save with pickle (current Python version)
    with open('feature_columns_fixed.pkl', 'wb') as f:
        pickle.dump(columns, f, protocol=4)
    print("   ✓ Saved: feature_columns_fixed.pkl (pickle)")
    
    # Save as JSON for inspection
    import json
    with open('feature_columns.json', 'w') as f:
        json.dump(columns, f, indent=2)
    print("   ✓ Saved: feature_columns.json (human-readable)")
    
    # Print preview
    print(f"\n📋 Feature columns preview (first 10):")
    for i, col in enumerate(columns[:10], 1):
        print(f"   {i}. {col}")
    if len(columns) > 10:
        print(f"   ... and {len(columns) - 10} more")
    
    print(f"\n✅ Success! Now rename the file:")
    print(f"   Move-Item feature_columns.pkl feature_columns_old.pkl")
    print(f"   Move-Item feature_columns_fixed.pkl feature_columns.pkl")
    
    return True

if __name__ == '__main__':
    success = fix_feature_columns()
    sys.exit(0 if success else 1)
