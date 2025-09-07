from flask import request, jsonify
from app.extensions import mysql


def userRequests():
    try:
        data = request.get_json()

        print("RAW request.get_json():", data)
        if data is None:
            return jsonify({'error': 'Invalid or missing JSON body'}), 400

        required_fields = ['safe_area_id', 'user', 'latitude', 'longitude', 'count', 'request']
        missing = [key for key in required_fields if key not in data]
        if missing:
            return jsonify(
                {'error': 'Missing required fields', 'missing': missing, 'received_keys': list(data.keys())}), 400

        safe_area_id = int(data['safe_area_id'])
        user = data['user']
        latitude = float(data['latitude'])
        longitude = float(data['longitude'])
        count = int(data['count'])
        request_type = data['request']

        query = '''
        INSERT INTO flood_risk_solution.user_requests 
        (safe_area_id, user, latitude, longitude, count, request, status)
        VALUES (%s, %s, %s, %s, %s, %s, %s)
        '''

        cursor = mysql.connection.cursor()
        cursor.execute(query, (safe_area_id, user, latitude, longitude, count, request_type, 'pending'))
        mysql.connection.commit()
        cursor.close()

        return jsonify({'message': 'Data inserted successfully'}), 200

    except ValueError:
        return jsonify({'error': 'Data value error'}), 400
    except Exception as e:
        return jsonify({'error': 'Server error', 'details': str(e)}), 500
