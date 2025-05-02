import os
import pyodbc

def get_unprocessed_files(files, conn_str):
    # Step 1: Extract just the filenames from full paths
    filenames = [os.path.basename(f) for f in files]

    # Step 2: Connect to SQL Server
    conn = pyodbc.connect(conn_str)
    cursor = conn.cursor()

    # Step 3: Create a parameterized query
    placeholders = ','.join('?' for _ in filenames)
    query = f"""
        SELECT filename
        FROM resource
        WHERE filename IN ({placeholders})
          AND processed = 1
    """

    # Step 4: Execute query and get processed filenames
    cursor.execute(query, filenames)
    processed_files = {row.filename for row in cursor.fetchall()}

    # Step 5: Filter out processed files from the original list
    unprocessed_files = [f for f in files if os.path.basename(f) not in processed_files]

    # Step 6: Cleanup
    cursor.close()
    conn.close()

    return unprocessed_files


files = [
    "C:/data/input/file1.csv",
    "C:/data/input/file2.csv",
    "C:/data/input/file3.csv"
]

conn_str = "DRIVER={ODBC Driver 17 for SQL Server};SERVER=your_server;DATABASE=your_db;UID=your_user;PWD=your_password"

cleaned_files = get_unprocessed_files(files, conn_str)
print(cleaned_files)
