from app.extensions import mysql
from flask import current_app

def create_connection():
    with current_app.app_context():
        cursor = mysql.connection.cursor()
        return cursor
