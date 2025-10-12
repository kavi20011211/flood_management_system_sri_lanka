import json
from flask import request, jsonify

from app.extensions import mysql


def get_all_flood_prone_areas():
    try:
        severity = request.args.get('severity')
        query = '''
            SELECT id, severity, area, latitude, longitude, polygon_coordinates
            FROM flood_risk_solution.flood_prone_areas
            WHERE (%s = 'high' AND severity IN('high','moderate','low'))
            OR (%s = 'moderate' AND severity IN ('moderate','low'))
            OR (%s = 'low' AND severity = 'low')
            '''
        cursor = mysql.connection.cursor()
        cursor.execute(query, (severity, severity, severity))
        results = cursor.fetchall()
        cursor.close()

        # Build GeoJSON FeatureCollection
        features = []
        for dat in results:
            # Parse the stored JSON coordinates
            coordinates = json.loads(dat[5]) if dat[5] else None

            if coordinates:
                features.append({
                    "type": "Feature",
                    "geometry": {
                        "type": "Polygon",
                        "coordinates": coordinates
                    },
                    "properties": {
                        "id": dat[0],
                        "severity": dat[1],
                        "area": dat[2],
                        "center_lat": float(dat[3]) if dat[3] else None,
                        "center_lng": float(dat[4]) if dat[4] else None
                    }
                })

        if not features:
            return jsonify({'error': "No data found for the given severity"}), 404

        # Return GeoJSON FeatureCollection
        geojson = {
            "type": "FeatureCollection",
            "features": features
        }

        return jsonify(geojson), 200

    except Exception as e:
        return jsonify({'error': 'Server error', 'details': str(e)}), 500
