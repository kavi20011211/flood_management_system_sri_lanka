from flask import request, jsonify

from app.extensions import mysql


def get_all_flood_prone_areas():
    try:
        severity = request.args.get('severity')
        query = '''
            SELECT * FROM flood_risk_solution.flood_prone_areas WHERE (%s = 'high' AND severity IN('high','moderate','low'))
            OR (%s = 'moderate' AND severity IN ('moderate','low'))
            OR (%s = 'low' AND severity = 'low')
            '''
        cursor = mysql.connection.cursor()
        cursor.execute(query, (severity, severity, severity))
        results = cursor.fetchall()
        cursor.close()

        data = [
            {
                "id": dat[0],
                "severity": dat[1],
                "area": dat[2],
                "latitude": dat[3],
                "longitude": dat[4],
            } for dat in results
        ]

        if not data:
            return jsonify({'error': "No data found for the given severity"}), 404

        return jsonify(data), 200
    except Exception as e:
        return jsonify({'error': 'Server error', 'details': str(e)}), 500
