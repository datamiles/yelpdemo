import pandas as pd
import datetime

# Define expected columns and which ones require type validation
expected_columns = ['id', 'name', 'age', 'salary', 'created_at']

# Type constraints: column -> expected type
# Allowed types: 'int', 'float', 'datetime'
type_constraints = {
    'id': 'int',
    'salary': 'float',
    'created_at': 'datetime'
}

# Set to True to enforce exact column order
enforce_order = False

def is_valid_datetime(value, fmt="%Y-%m-%d %H:%M:%S"):
    try:
        datetime.datetime.strptime(value, fmt)
        return True
    except Exception:
        return False

def validate_schema(file_path):
    try:
        df = pd.read_csv(file_path, delimiter='|', dtype=str)
    except Exception as e:
        print(f"❌ Failed to read file: {e}")
        return False

    actual_columns = df.columns.tolist()

    # 1. Check column names
    if enforce_order:
        if actual_columns != expected_columns:
            print(f"❌ Column order mismatch.\nExpected: {expected_columns}\nFound: {actual_columns}")
            return False
    else:
        if not set(expected_columns).issubset(set(actual_columns)):
            missing = set(expected_columns) - set(actual_columns)
            print(f"❌ Missing expected columns: {missing}")
            return False

    # 2. Validate data types for selected columns
    errors = []
    for col, expected_type in type_constraints.items():
        if col not in df.columns:
            errors.append(f"Missing column for type validation: '{col}'")
            continue
        for i, val in enumerate(df[col]):
            if pd.isna(val) or val.strip() == '':
                continue  # Allow blank values
            try:
                if expected_type == 'int':
                    int(val)
                elif expected_type == 'float':
                    float(val)
                elif expected_type == 'datetime':
                    if not is_valid_datetime(val):
                        raise ValueError()
                else:
                    errors.append(f"Unsupported type '{expected_type}' for column '{col}'")
            except Exception:
                errors.append(f"Invalid {expected_type} in column '{col}' at row {i+2}: '{val}'")

    if errors:
        print("❌ Schema validation failed with following issues:")
        for err in errors:
            print(" -", err)
        return False

    print("✅ CSV schema and data types are valid.")
    return True

# === Example Usage ===
file_path = 'your_file.csv'
validate_schema(file_path)
