import json

import MySQLdb
from flask import request, jsonify
from werkzeug.security import generate_password_hash, check_password_hash
from app.extensions import mysql


def createUser():
    try:
        data = request.get_json()

        # Validate input keys
        required_keys = ['firstname', 'lastname', 'residence', 'postal_code', 'email', 'password', 'confirm_password']
        if not all(key in data for key in required_keys):
            return jsonify({'error': 'Missing required fields'}), 400

        firstName = data['firstname']
        lastName = data['lastname']
        residence = data['residence']
        postalCode = data['postal_code']
        email = data['email']  # fixed typo
        password = data['password']
        confirmPassword = data['confirm_password']

        # Check if passwords match
        if password != confirmPassword:
            return jsonify({'error': 'Passwords do not match'}), 400

        # Hash password securely
        hashedPassword = generate_password_hash(password)

        # Check if user already exists
        cursor = mysql.connection.cursor()
        cursor.execute("SELECT * FROM flood_risk_solution.user_table WHERE email = %s", (email,))
        existing_user = cursor.fetchone()
        if existing_user:
            cursor.close()
            return jsonify({'error': 'User already exists with this email'}), 409

        # Insert new user
        query = '''
            INSERT INTO flood_risk_solution.user_table 
            (firstname, lastname, residence, postal_code, email, password)
            VALUES (%s, %s, %s, %s, %s, %s)
        '''
        cursor.execute(query, (firstName, lastName, residence, postalCode, email, hashedPassword))
        mysql.connection.commit()
        cursor.close()

        return jsonify({'message': 'User created successfully'}), 201

    except Exception as e:
        print(str(e))
        return jsonify({'error': 'Server error', 'details': str(e)}), 500


def loginUser():
    try:
        data = request.get_json()

        # Validate required fields
        required_keys = ['email', 'password']
        if not all(key in data for key in required_keys):
            return jsonify({'error': 'Missing required fields'}), 400

        email = data['email']
        password = data['password']

        cursor = mysql.connection.cursor(MySQLdb.cursors.DictCursor)
        cursor.execute("SELECT * FROM flood_risk_solution.user_table WHERE email = %s", (email,))
        user = cursor.fetchone()
        cursor.close()

        if not user:
            return jsonify({'error': 'Invalid email or password'}), 401

        # Verify password
        if not check_password_hash(user['password'], password):
            return jsonify({'error': 'Invalid email or password'}), 401

        # Optional: return user details (avoid password)
        return jsonify({
            'message': 'Login successful',
            'user': {
                'id': user['id'],
                'firstname': user['firstname'],
                'lastname': user['lastname'],
                'email': user['email']
            }
        }), 200

    except Exception as e:
        print(str(e))
        return jsonify({'error': 'Server error', 'details': str(e)}), 500
