import os
import pyodbc

def get_unprocessed_files(files, sql_server_instance):
    if not files:
        print("No files provided.")
        return []

    conn = pyodbc.connect(
        "DRIVER={SQL Server};"
        f"Server={sql_server_instance};"
        "Database=DM;"
        "trusted_connection=Yes;"
        "autocommit=True"
    )
    cursor = conn.cursor()

    # Extract just filenames and normalize to uppercase
    filenames_upper = [os.path.basename(f).upper() for f in files]
    print("Filenames to check:", filenames_upper)

    # Build placeholders (?, ?, ?) and parameter list
    placeholders = ','.join('?' for _ in filenames_upper)

    query = f"""
        SELECT UPPER(ResourceName)
        FROM j.resource
        WHERE UPPER(ResourceName) IN ({placeholders})
          AND ResourceTypeId = 3
          AND ResourceProcessed = 1
    """

    cursor.execute(query, filenames_upper)

    # Fetch processed files and convert to a set of uppercase names
    processed_files = {row[0] for row in cursor.fetchall()}
    print("Processed files from DB:", processed_files)

    # Return only unprocessed file paths
    unprocessed_files = [
        f for f in files if os.path.basename(f).upper() not in processed_files
    ]

    conn.close()
    return unprocessed_files
