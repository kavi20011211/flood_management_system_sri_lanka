from app import create_app
from app.extensions import mysql

app = create_app()

# Check DB connection
with app.app_context():
    try:
        cursor = mysql.connection.cursor()
        cursor.execute("SELECT 1")
        print("MySQL database connected successfully.")
        cursor.close()
    except Exception as e:
        print("Failed to connect to MySQL database.")
        print(f"Error: {e}")

if __name__ == '__main__':
    app.run(debug=True)
