from decimal import Decimal

from flask import request, jsonify
from app.extensions import mysql
from classses.safe_house_optimizer import SafeHouseOptimizer
import pulp
import joblib
import numpy as np


def createSafeAreas():
    try:
        data = request.get_json()
        required_values = ['area', 'longitude', 'latitude', 'capacity', 'priority']
        if not all(key in data for key in required_values):
            return jsonify({'error': 'Missing required fields'}), 400

        area = data['area']
        longitude = data['longitude']
        latitude = data['latitude']
        safe_area = data['safe_area']
        capacity = int(data['capacity'])
        priority = float(data['priority'])

        query = '''
        INSERT INTO flood_risk_solution.safe_areas (area, safe_area, longitude, latitude, capacity, priority)
        VALUES (%s, %s, %s, %s, %s, %s)
        '''

        cursor = mysql.connection.cursor()
        cursor.execute(query, (area, safe_area, longitude, latitude, capacity, priority))
        mysql.connection.commit()
        cursor.close()

        return jsonify({'message': 'Data inserted successfully'}), 200

    except ValueError:
        return jsonify({'error': 'Invalid data type'}), 400
    except Exception as e:
        return jsonify({'error': 'Server error', 'details': str(e)}), 500


def getAllSHData():
    try:
        query = '''
                SELECT * FROM flood_risk_solution.safe_areas
                '''

        cursor = mysql.connection.cursor()
        cursor.execute(query)
        results = cursor.fetchall()
        cursor.close()

        data = [
            {
                "safe_area_id": dat[0],
                "area": dat[1],
                "safe_area": dat[2],
                "longitude": float(dat[3]) if dat[3] is not None else 0.0,
                "latitude": float(dat[4]) if dat[4] is not None else 0.0,
                "capacity": float(dat[5]) if dat[5] is not None else 0.0,
                "priority": float(dat[6]) if dat[6] is not None else 1.0
            } for dat in results
        ]

        return data
    except Exception as e:
        print(e)
        return jsonify({'error': 'Server error', 'details': str(e)}), 500


def calculate_resource_demands(capacity):
    """Calculate resource demands based on safe house capacity"""
    # Basic resource requirements per person
    capacity = float(capacity)
    per_person_requirements = {
        'food': 3,  # meals per day
        'water': 5,  # liters per day
        'medicine': 0.5,  # units per day
        'blankets': 0.3,  # blankets per person
        'shelter_materials': 0.2  # units per person
    }

    demands = {}
    for resource, per_person in per_person_requirements.items():
        demands[resource] = float(capacity * per_person)

    return demands


def get_default_supply():
    """Get default available supply for resources"""
    return {
        'food': 10000,
        'water': 50000,
        'medicine': 2000,
        'blankets': 5000,
        'shelter_materials': 3000
    }


def convert_decimal_to_float(obj):
    """Recursively convert Decimal objects to float in nested structures"""
    if isinstance(obj, Decimal):
        return float(obj)
    elif isinstance(obj, dict):
        return {k: convert_decimal_to_float(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [convert_decimal_to_float(item) for item in obj]
    else:
        return obj


def requestResourcesAllocation():
    try:
        # Get safe house data
        sh_data = getAllSHData()
        if not sh_data:
            return jsonify({'error': 'Failed to retrieve safe house data'}), 500

        # Convert any Decimal objects to float
        sh_data = convert_decimal_to_float(sh_data)

        # Initialize optimizer
        optimizer = SafeHouseOptimizer()

        # Set up safe houses
        safe_house_names = [sh['safe_area'] for sh in sh_data]
        optimizer.safe_houses = safe_house_names

        # Set up resources
        optimizer.resources = ['food', 'water', 'medicine', 'blankets', 'shelter_materials']

        # Set up demands based on capacity
        demands = {}
        for sh in sh_data:
            demands[sh['safe_area']] = calculate_resource_demands(sh['capacity'])
        optimizer.demands = demands

        # Set up supply
        optimizer.supply = get_default_supply()

        # Set up priority weights (higher priority = higher weight)
        priority_weights = {}
        for sh in sh_data:
            # Convert priority to weight (assuming priority is 1-5, convert to weight 1-3)
            # Ensure all operations use float
            priority = float(sh['priority'])
            weight = min(priority / 2.0, 3.0)
            priority_weights[sh['safe_area']] = weight
        optimizer.priority_weights = priority_weights

        # Debug: Print data types to verify
        print("Sample capacity type:", type(sh_data[0]['capacity']) if sh_data else "No data")
        print("Sample priority type:", type(sh_data[0]['priority']) if sh_data else "No data")
        print("Sample demand value type:", type(list(demands.values())[0]['food']) if demands else "No demands")

        # Solve optimization
        prob, x, unmet = optimizer.solve_optimizer()

        # Check if solution is optimal
        if prob.status != pulp.LpStatusOptimal:
            return jsonify({
                'error': 'Optimization failed',
                'status': pulp.LpStatus[prob.status]
            }), 400

        # Get results
        results = optimizer.get_results_dict(prob, x, unmet)

        return jsonify({
            'success': True,
            'message': 'Resource allocation optimized successfully',
            'data': results
        }), 200

    except Exception as e:
        print(f"Error in requestResourcesAllocation: {str(e)}")
        print(f"Error type: {type(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': 'Server error', 'details': str(e)}), 500


def getSHResourcesPrediction():
    try:
        people_count = float(request.args.get('people_count'))
        severity = float(request.args.get('severity'))

        model = joblib.load('./models/linear_regression_model.pkl')
        features = np.array([[people_count, severity]])

        prediction = model.predict(features)

        return jsonify({'prediction': prediction.tolist()})

    except Exception as e:
        print(f"Error in requestResourcesAllocation: {str(e)}")
        print(f"Error type: {type(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': 'Server error', 'details': str(e)}), 500
