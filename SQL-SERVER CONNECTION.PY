import pyodbc

server = r'ANKIT'          # from your SSMS window
database = 'LibraryDB'     # your database name
driver = '{ODBC Driver 17 for SQL Server}'  # or Driver 18 if installed

conn_str = (
    f"DRIVER={driver};"
    f"SERVER={server};"
    f"DATABASE={database};"
    "Trusted_Connection=yes;"
    "Encrypt=no;"     # important for Windows Authentication
)

try:
    conn = pyodbc.connect(conn_str)
    cursor = conn.cursor()
    print("🔥 Connected successfully!")

    cursor.execute("SELECT TOP 5 * FROM Books;")
    rows = cursor.fetchall()
    for row in rows:
        print(row)

except Exception as e:
    print("❌ Error:", e)
