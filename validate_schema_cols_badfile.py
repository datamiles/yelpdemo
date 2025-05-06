import pandas as pd
import datetime
import os

# Define your destination schema: column -> (expected_type, nullable)
destination_schema = {
    'id': ('int', False),
    'name': ('varchar', False),
    'age': ('int', True),
    'salary': ('decimal', True),
    'created_at': ('datetime', False),  # format: YYYY-MM-DD HH:MM:SS
    'birth_date': ('date', True)        # format: YYYY-MM-DD
}

datetime_format = "%Y-%m-%d %H:%M:%S"
date_format = "%Y-%m-%d"

# === Type Validators ===
def is_valid_int(val): return val.strip().isdigit()
def is_valid_decimal(val): 
    try: float(val); return True
    except: return False
def is_valid_datetime(val):
    try: datetime.datetime.strptime(val, datetime_format); return True
    except: return False
def is_valid_date(val):
    try: datetime.datetime.strptime(val, date_format); return True
    except: return False
def is_valid_varchar(val): return isinstance(val, str)

# === Row Validator ===
def validate_row(row):
    for col, (expected_type, nullable) in destination_schema.items():
        val = str(row.get(col, "")).strip()

        if val == '':
            if not nullable:
                return False
            continue

        if expected_type == 'int' and not is_valid_int(val):
            return False
        elif expected_type == 'decimal' and not is_valid_decimal(val):
            return False
        elif expected_type == 'datetime' and not is_valid_datetime(val):
            return False
        elif expected_type == 'date' and not is_valid_date(val):
            return False
        elif expected_type == 'varchar' and not is_valid_varchar(val):
            return False
    return True

# === CSV Validation and Row Separation ===
def validate_csv(file_path, delimiter='|'):
    base_name = os.path.basename(file_path)
    good_file = f"good_{base_name}"
    bad_file = f"bad_{base_name}"

    try:
        df = pd.read_csv(file_path, delimiter=delimiter, dtype=str)
    except Exception as e:
        print(f"❌ Error reading file: {e}")
        return False

    # Step 1: Schema check
    expected_columns = list(destination_schema.keys())
    actual_columns = df.columns.tolist()
    if actual_columns != expected_columns:
        print(f"❌ Column mismatch.\nExpected: {expected_columns}\nFound: {actual_columns}")
        return False

    # Step 2: Validate each row
    good_rows = []
    bad_rows = []

    for idx, row in df.iterrows():
        if validate_row(row):
            good_rows.append(row)
        else:
            bad_rows.append(row)

    # Step 3: Write output files
    if good_rows:
        pd.DataFrame(good_rows).to_csv(good_file, index=False, sep=delimiter)
        print(f"✅ Wrote {len(good_rows)} good rows to {good_file}")

    if bad_rows:
        pd.DataFrame(bad_rows).to_csv(bad_file, index=False, sep=delimiter)
        print(f"❌ Wrote {len(bad_rows)} bad rows to {bad_file}")

    return True

# === Example Usage ===
validate_csv("staged_file.csv")





Absolutely! Here's a **step-by-step explanation** of the refined CSV validation script, tailored for your use case of **staging-to-destination table validation in a SQL Server ETL pipeline**:

---

## 🧠 **Goal Recap**

You have:

* A **staging table** where all columns are `VARCHAR`
* A **destination table** where columns have real types: `INT`, `DECIMAL`, `DATETIME`, `DATE`, `VARCHAR`
* You want to:

  1. Ensure incoming CSV files **match the expected layout**
  2. **Validate values** to ensure they're castable to the destination types
  3. Separate **good rows** and **bad rows** into two output files

---

## 📄 Script Breakdown

### ✅ 1. **Define the Expected Schema**

```python
destination_schema = {
    'id': ('int', False),
    'name': ('varchar', False),
    'age': ('int', True),
    'salary': ('decimal', True),
    'created_at': ('datetime', False),
    'birth_date': ('date', True)
}
```

This defines:

* Each column name in the **expected order**
* Its expected **data type** (`int`, `decimal`, `datetime`, etc.)
* Whether the column is **nullable** (`True` or `False`)

This is used later for both:

* Column **layout check**
* **Value type and nullability check**

---

### ✅ 2. **Validation Functions for Each Type**

Functions like:

```python
def is_valid_int(val): ...
def is_valid_decimal(val): ...
def is_valid_datetime(val): ...
def is_valid_date(val): ...
```

Each of these:

* Takes a string value (from the CSV)
* Tries to cast it to the intended SQL Server type
* Returns `True` if valid, `False` if invalid

This mimics what SQL Server would accept or reject during insert/cast.

---

### ✅ 3. **Row-Level Validator**

```python
def validate_row(row): ...
```

This function:

* Iterates through each column in the row
* Checks if the value is:

  * Missing (and allowed to be nullable), OR
  * Correctly castable to the defined type
* Returns `True` if the row is valid, otherwise `False`

This is the core check before inserting into the final table.

---

### ✅ 4. **Main Function: `validate_csv()`**

```python
def validate_csv(file_path, delimiter='|'): ...
```

This is the orchestrator.

#### 🧩 Step-by-step:

##### a. Read the CSV

```python
df = pd.read_csv(file_path, delimiter=delimiter, dtype=str)
```

* Reads the full CSV file as strings
* Keeps all values as text (like your staging table)

##### b. Schema check

```python
if actual_columns != expected_columns:
```

* Ensures the column names **exactly match** the schema
* If columns are missing, extra, or reordered, it fails fast

##### c. Row-wise validation

```python
for idx, row in df.iterrows():
    if validate_row(row): ...
```

* For each row, calls `validate_row()`
* Good rows go to `good_rows`
* Bad rows go to `bad_rows`

##### d. Output to files

```python
pd.DataFrame(good_rows).to_csv(...)
pd.DataFrame(bad_rows).to_csv(...)
```

* Good rows → `good_<original_file>.csv`
* Bad rows → `bad_<original_file>.csv`
* Same `|` delimiter as input
* Lets you control what gets inserted vs. rejected

---

## ✅ Result

| File                   | Description                            |
| ---------------------- | -------------------------------------- |
| `good_staged_file.csv` | ✅ Safe rows to insert into destination |
| `bad_staged_file.csv`  | ❌ Problematic rows for review/fix      |

---

## 📌 Why This Script is Valuable in Your Workflow

* **Protects downstream SQL Server insert logic** from breaking due to type errors
* Gives you **clear separation of good/bad data**
* Helps ensure your staging-to-destination ETL process is **robust, clean, and reliable**

---

Would you like the script to **log specific error reasons per bad row** as a new column (e.g., "Invalid date in `created_at`")?
