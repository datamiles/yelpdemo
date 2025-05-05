# example 1
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

    filenames_upper = [os.path.basename(f).upper() for f in files]
    placeholders = ','.join('?' for _ in filenames_upper)

    query = f"""
        SELECT UPPER(ResourceName) AS ProcessedName
        FROM j.resource
        WHERE UPPER(ResourceName) IN ({placeholders})
          AND ResourceTypeId = 3
          AND ResourceProcessed = 1
    """

    cursor.execute(query, filenames_upper)
    processed_filenames_upper = {row.ProcessedName for row in cursor.fetchall()}

    unprocessed_files = [
        f for f in files if os.path.basename(f).upper() not in processed_filenames_upper
    ]

    conn.close()
    return unprocessed_files


#example 2
import os
import pyodbc

def get_unprocessed_files(files, sql_server_instance):
    if not files:
        print("No files provided.")
        return []

    # Connect to SQL Server
    conn = pyodbc.connect(
        "DRIVER={SQL Server};"
        f"Server={sql_server_instance};"
        "Database=DM;"
        "trusted_connection=Yes;"
        "autocommit=True"
    )
    cursor = conn.cursor()

    # Extract and normalize filenames to uppercase
    filenames_upper = [os.path.basename(f).upper() for f in files]
    placeholders = ','.join('?' for _ in filenames_upper)

    print("Filenames being checked:", filenames_upper)
    print("Placeholders:", placeholders)

    # Query database with upper-cased ResourceName
    query = f"""
        SELECT UPPER(ResourceName)
        FROM j.resource
        WHERE UPPER(ResourceName) IN ({placeholders})
          AND ResourceTypeId = 3
          AND ResourceProcessed = 1
    """
    cursor.execute(query, filenames_upper)

    # Use row[0] because there's no alias for the column
    processed_filenames_upper = {row[0] for row in cursor.fetchall()}
    print("Processed filenames from DB:", processed_filenames_upper)

    # Return full file paths where the base name is NOT in processed set
    unprocessed_files = [
        f for f in files
        if os.path.basename(f).upper() not in processed_filenames_upper
    ]

    conn.close()
    return unprocessed_files
