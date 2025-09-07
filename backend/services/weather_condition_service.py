import json

import requests
from flask import request, jsonify
from app.extensions import mysql
import joblib
import numpy as np


def sendWeatherData():
    try:
        data = request.get_json()

        # Validate input keys
        required_keys = ['date', 'area', 'rainfall', 'river_level', 'soil_moisture', 'elevation']
        if not all(key in data for key in required_keys):
            return jsonify({'error': 'Missing required fields'}), 400

        date = data['date']  # Should be in 'YYYY-MM-DD' format
        area = data['area']
        rainfall = float(data['rainfall'])
        river_level = float(data['river_level'])
        soil_moisture = float(data['soil_moisture'])
        elevation = float(data['elevation'])

        query = '''
            INSERT INTO flood_risk_solution.weather_conditions 
            (date, area, rainfall, river_level, soil_moisture, elevation)
            VALUES (%s, %s, %s, %s, %s, %s)
        '''

        cursor = mysql.connection.cursor()
        cursor.execute(query, (date, area, rainfall, river_level, soil_moisture, elevation))
        mysql.connection.commit()
        cursor.close()

        return jsonify({'message': 'Data inserted successfully'}), 200

    except ValueError:
        return jsonify({'error': 'Invalid data type'}), 400
    except Exception as e:
        return jsonify({'error': 'Server error', 'details': str(e)}), 500


def getWeatherData():
    try:
        area = request.args.get('area')
        cursor = mysql.connection.cursor()
        query = '''
            SELECT date, area, rainfall, river_level, soil_moisture, elevation 
            FROM flood_risk_solution.weather_conditions 
            WHERE date = CURDATE() AND area = %s
        '''
        cursor.execute(query, (area,))
        results = cursor.fetchall()
        cursor.close()

        data = [{
            'date': dat[0],
            'area': dat[1],
            'rainfall': dat[2],
            'river_level': dat[3],
            'soil_moisture': dat[4],
            'elevation': dat[5]
        } for dat in results]

        if not data:
            return jsonify({'error': 'No data available'}), 404

        model = joblib.load('./models/flood_prediction_model.pkl')
        scaler = joblib.load('./models/scaler.pkl')
        label_encoder = joblib.load('./models/label_encoder.pkl')

        row = data[0]
        features = np.array([[row['rainfall'], row['river_level'], row['soil_moisture'], row['elevation']]])
        scaled_features = scaler.transform(features)
        prediction = model.predict(scaled_features)
        predicted_category = label_encoder.inverse_transform(prediction)[0]

        return jsonify({
            'date': row['date'],
            'area': row['area'],
            'risk_prediction': predicted_category,
            'features_used': {
                'rainfall': row['rainfall'],
                'river_level': row['river_level'],
                'soil_moisture': row['soil_moisture'],
                'elevation': row['elevation']
            }
        }), 200

    except Exception as e:
        return jsonify({'error': 'Server error', 'details': str(e)}), 500


def generateRiskSummary():
    try:
        data = request.get_json()
        required_fields = ['longitude', 'latitude', 'area', 'river_level', 'severity', 'elevation']
        if not all(key in data for key in required_fields):
            return jsonify({'error': 'Fields are required'}), 400

        longitude = data['longitude']
        latitude = data['latitude']
        area = data['area']
        river_level = data['river_level']
        severity = data['severity']
        elevation = data['elevation']

        # Add your OpenRouter API key here
        OPENROUTER_API_KEY = "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"

        if not OPENROUTER_API_KEY or OPENROUTER_API_KEY == "your_api_key_here":
            return jsonify({'error': 'OpenRouter API key not configured'}), 500

        prompt = f"""You are a disaster response AI specialized in flood risk assessment.

Given the following data:
- Location: {area}
- Latitude: {latitude}
- Longitude: {longitude}
- Elevation: {elevation} meters
- River Level: {river_level} meters
- Severity Index: {severity} (Low, Moderate, High)

1. Provide a brief summary of the flood risk situation.
2. Predict how long the flood conditions may persist based on this data.
3. Include a recommendation for local authorities.

Respond in 3–4 concise sentences."""

        headers = {
            "Authorization": f"Bearer {OPENROUTER_API_KEY}",
            "Content-Type": "application/json",
            "HTTP-Referer": "http://localhost:5000",
            "X-Title": "Flood Risk Assessment"
        }

        payload = {
            "model": "openai/gpt-3.5-turbo",
            "messages": [
                {
                    "role": "system",
                    "content": "You are a disaster response AI specialized in flood risk assessment. Provide concise, "
                               "actionable flood risk summaries. "
                },
                {
                    "role": "user",
                    "content": prompt
                }
            ],
            "max_tokens": 200,
            "temperature": 0.7,
            "top_p": 0.9
        }

        # Use requests (synchronous) instead of aiohttp
        response = requests.post(
            "https://openrouter.ai/api/v1/chat/completions",
            headers=headers,
            json=payload,
            timeout=30  # 30 second timeout
        )

        if response.status_code != 200:
            print(f"OpenRouter API error: {response.status_code} - {response.text}")
            return jsonify({'error': 'Failed to generate summary', 'details': response.text}), 500

        result = response.json()

        if 'choices' not in result or len(result['choices']) == 0:
            return jsonify({'error': 'No response generated'}), 500

        result_text = result['choices'][0]['message']['content'].strip()

        print(f"Generated summary: {result_text}")

        return jsonify({'summary': result_text})

    except requests.exceptions.RequestException as e:
        print(f"Network error: {str(e)}")
        return jsonify({'error': 'Network error', 'details': str(e)}), 500
    except json.JSONDecodeError as e:
        print(f"JSON decode error: {str(e)}")
        return jsonify({'error': 'Invalid response format', 'details': str(e)}), 500
    except Exception as e:
        print(f"Unexpected error: {str(e)}")
        return jsonify({'error': 'Server error', 'details': str(e)}), 500


# Alternative: Mock version for testing without API key
# def generateRiskSummaryMock():
#     """Mock version for testing without API calls"""
#     try:
#         data = request.get_json()
#         required_fields = ['longitude', 'latitude', 'area', 'river_level', 'severity', 'elevation']
#         if not all(key in data for key in required_fields):
#             return jsonify({'error': 'Fields are required'}), 400
#
#         area = data['area']
#         river_level = data['river_level']
#         severity = data['severity']
#         elevation = data['elevation']
#
#         # Generate mock response based on severity
#         if severity.lower() == 'high':
#             summary = f"HIGH FLOOD RISK in {area}: River level at {river_level}m poses immediate danger. Conditions may persist for 24-48 hours due to elevated water levels. Local authorities should implement evacuation procedures for low-lying areas immediately. Emergency shelters should be activated."
#         elif severity.lower() == 'moderate':
#             summary = f"MODERATE FLOOD RISK in {area}: River level at {river_level}m requires monitoring. Conditions expected to improve within 12-24 hours. Local authorities should issue advisories and prepare emergency response teams. Residents should avoid flood-prone areas."
#         else:
#             summary = f"LOW FLOOD RISK in {area}: Current river level at {river_level}m is manageable. Conditions should remain stable over the next 24 hours. Local authorities should maintain routine monitoring. No immediate action required for residents."
#
#         return jsonify({
#             "summary": summary,
#             "usage": {"total_tokens": 150, "prompt_tokens": 100, "completion_tokens": 50},
#             "model": "mock-gpt-3.5-turbo"
#         })
#
#     except Exception as e:
#         return jsonify({'error': 'Server error', 'details': str(e)}), 500


def sendSafestAreas():
    try:
        area = request.args.get('area')

        query = '''
        SELECT * FROM flood_risk_solution.safe_areas WHERE area =%s
        '''

        cursor = mysql.connection.cursor()
        cursor.execute(query, (area,))
        results = cursor.fetchall()
        cursor.close()

        data = [
            {
                "safe_area_id": dat[0],
                "area": dat[1],
                "safe_area": dat[2],
                "longitude": dat[3],
                "latitude": dat[4],
                "capacity": dat[5]
            } for dat in results
        ]

        if not data:
            return jsonify({'error': "No data found for the given area"}), 404

        return jsonify(data), 200

    except Exception as e:
        return jsonify({'error': 'Server error', 'details': str(e)}), 500
