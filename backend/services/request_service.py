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


def getAllRequest():
    try:
        query = "SELECT * FROM flood_risk_solution.user_requests"

        cursor = mysql.connection.cursor()
        cursor.execute(query)
        results = cursor.fetchall()

        if results is None:
            return jsonify({'requests': [], 'total': 0}), 200

        # Get column names
        columns = [desc[0] for desc in cursor.description]
        cursor.close()

        # Convert results to list of dictionaries
        requests = []
        for row in results:
            request_dict = dict(zip(columns, row))
            requests.append(request_dict)

        return jsonify({'requests': requests, 'total': len(requests)}), 200

    except Exception as e:
        return jsonify({'error': 'Server error', 'details': str(e)}), 500


def updateStatus():
    try:
        data = request.get_json()

        print(data)

        if data is None:
            return jsonify({'error': 'Invalid or missing JSON body'}), 400

        # Check for required fields
        if 'id' not in data or 'status' not in data:
            return jsonify({'error': 'Missing required fields: id and status'}), 400

        request_id = int(data['id'])
        new_status = data['status']

        # Validate status values
        valid_statuses = ['pending', 'approved', 'rejected']
        if new_status not in valid_statuses:
            return jsonify({'error': f'Invalid status. Must be one of: {valid_statuses}'}), 400

        # Check if request exists
        check_query = "SELECT request_id FROM flood_risk_solution.user_requests WHERE request_id = %s"
        cursor = mysql.connection.cursor()
        cursor.execute(check_query, (request_id,))
        result = cursor.fetchone()

        if not result:
            cursor.close()
            return jsonify({'error': 'Request not found'}), 404

        # Update the status
        update_query = "UPDATE flood_risk_solution.user_requests SET status = %s WHERE request_id = %s"
        cursor.execute(update_query, (new_status, request_id))
        mysql.connection.commit()
        cursor.close()

        return jsonify({'message': 'Status updated successfully'}), 200

    except ValueError:
        return jsonify({'error': 'Invalid data type for id'}), 400
    except Exception as e:
        return jsonify({'error': 'Server error', 'details': str(e)}), 500