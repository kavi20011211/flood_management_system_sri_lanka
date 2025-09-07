import json

import requests
from flask import request, jsonify
from app.extensions import mysql


def addAnewFeedBack():
    try:
        data = request.get_json()

        # Validate input keys
        required_keys = ['feedback']
        if not all(key in data for key in required_keys):
            return jsonify({'error': 'Missing required fields'}), 400

        feedback = data['feedback']

        query = '''
                    INSERT INTO flood_risk_solution.feedbacks 
                    (feedback)
                    VALUES (%s)
                '''

        cursor = mysql.connection.cursor()
        cursor.execute(query, (feedback,))
        mysql.connection.commit()
        cursor.close()

        return jsonify({'message': 'Data inserted successfully'}), 200
    except Exception as e:
        return jsonify({'error': 'Server error', 'details': str(e)}), 500


def getAllFeedbacks():
    try:
        query = '''SELECT * FROM flood_risk_solution.feedbacks '''
        cursor = mysql.connection.cursor()
        cursor.execute(query, )
        results = cursor.fetchall()
        cursor.close()

        data = [{
            'id': dat[0],
            'feedback': dat[1],
            'reply': dat[2],
        } for dat in results]

        if not data:
            return jsonify({'error': 'No data available'}), 404

        return jsonify(data), 200
    except Exception as e:
        return jsonify({'error': 'Server error', 'details': str(e)}), 500


def addAReply():
    try:
        id = request.args.get('id')
        data = request.get_json()

        required_keys = ['reply']
        if not all(key in data for key in required_keys):
            return jsonify({'error': 'Missing required fields'}), 400

        reply = data['reply']

        query = '''
                            UPDATE flood_risk_solution.feedbacks SET reply = %s
                            WHERE id = %s
                        '''

        cursor = mysql.connection.cursor()
        cursor.execute(query, (reply, id))
        mysql.connection.commit()
        cursor.close()

        return jsonify({'message': 'Data updated successfully'}), 200

    except Exception as e:
        return jsonify({'error': 'Server error', 'details': str(e)}), 500
