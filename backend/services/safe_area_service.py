import os
import pickle
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

def create_supply():
    try:
        data = request.get_json()
        required_values = ['food', 'water', 'medicine', 'blankets', 'shelter_materials']
        if not all(key in data for key in required_values):
            return jsonify({'error': 'Missing required fields'}), 400

        food = data['food']
        water = data['water']
        medicine = data['medicine']
        blankets = data['blankets']
        shelter_materials = data['shelter_materials']


    except Exception as e:
        print(e)
        return jsonify({'error': 'Server error', 'details': str(e)}), 500


def get_default_supply():
    """Get default available supply for resources - ADJUSTED to be more realistic"""
    return {
        'food': 5000,  # Reduced from 10000
        'water': 8000,  # Reduced from 50000
        'medicine': 6000,  # Reduced from 2000
        'blankets': 8000,  # Reduced from 5000
        'shelter_materials': 5500  # Reduced from 3000
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

        # Set up supply (using more realistic values)
        optimizer.supply = get_default_supply()

        # Set up priority weights - NORMALIZED to 1-3 scale
        priority_weights = {}
        for sh in sh_data:
            priority = float(sh['priority'])
            # Normalize priority to 1-3 scale based on input range
            if priority <= 1:
                weight = 1.0
            elif priority <= 2:
                weight = 2.0
            else:
                weight = 3.0
            priority_weights[sh['safe_area']] = weight
        optimizer.priority_weights = priority_weights

        # Debug: Print setup info
        print("=== OPTIMIZATION SETUP ===")
        print(f"Safe houses: {len(safe_house_names)}")
        print("Total demands per resource:")
        total_demands = {}
        for resource in optimizer.resources:
            total_demands[resource] = sum(demands[sh][resource] for sh in safe_house_names)
            print(f"  {resource}: {total_demands[resource]} (supply: {optimizer.supply[resource]})")

        print("Priority weights:", priority_weights)

        # Solve optimization
        prob, x, satisfaction, overall_satisfaction = optimizer.solve_optimizer()

        # Check if solution is optimal
        if prob.status != pulp.LpStatusOptimal:
            return jsonify({
                'error': 'Optimization failed',
                'status': pulp.LpStatus[prob.status],
                'message': 'Try adjusting supply levels or reducing demands'
            }), 400

        # Get results
        results = optimizer.get_results_dict(prob, x, satisfaction, overall_satisfaction)

        # Add summary statistics
        results['summary'] = {
            'total_safe_houses': len(safe_house_names),
            'average_satisfaction': round(sum([results['satisfaction_rates'][sh]['satisfaction_percentage']
                                               for sh in safe_house_names]) / len(safe_house_names), 1),
            'resource_shortage': {}
        }

        # Identify resource shortages
        for resource in optimizer.resources:
            if total_demands[resource] > optimizer.supply[resource]:
                shortage_pct = round((1 - optimizer.supply[resource] / total_demands[resource]) * 100, 1)
                results['summary']['resource_shortage'][resource] = f"{shortage_pct}% shortage"

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


# Global variables for model and scaler
model = None
scaler = None

# def load_model_and_scaler():
#     global model, scaler
#
#     import os
#     print(os.path.exists('./models/supply_predictionmodel.pkl'))
#     print(os.path.exists('./models/supplyscaler.pkl'))
#
#     try:
#         model = joblib.load('./models/supply_predictionmodel.pkl')
#         scaler = joblib.load('./models/supplyscaler.pkl')
#         return True
#     except Exception as e:
#         print(f"Error loading model: {e}")


def predict_resources(severity, people_count):
    """
    Predict resource requirements based on severity and people count

    Parameters:
    -----------
    severity : int
        Severity level (1=Low, 2=Moderate, 3=High)
    people_count : int
        Number of affected people

    Returns:
    --------
    list : Predicted resource quantities
           [bandages, ors_kits, water_liters, mosquito_nets, antibiotics, first_aids, saline]
    """
    model = joblib.load('./models/supply_predictionmodel.pkl')
    scaler = joblib.load('./models/supplyscaler.pkl')

    if model is None or scaler is None:
        raise Exception("Model not loaded")

    # Create input array
    sample_input = np.array([[severity, people_count]])

    # Scale the input
    sample_input_scaled = scaler.transform(sample_input)

    # Predict
    prediction = model.predict(sample_input_scaled)

    # Round to integers and return as list
    return prediction.tolist()


def getSHResourcesPrediction():
    try:
        # Get query parameters
        severity = request.args.get('severity', type=int)
        people_count = request.args.get('people_count', type=int)

        # Validate inputs
        if severity is None:
            return jsonify({
                'error': 'Missing required parameter: severity',
                'message': 'Please provide severity level (1, 2, or 3)'
            }), 400

        if people_count is None:
            return jsonify({
                'error': 'Missing required parameter: people_count',
                'message': 'Please provide number of affected people'
            }), 400

        # Validate severity range
        if severity not in [1, 2, 3]:
            return jsonify({
                'error': 'Invalid severity level',
                'message': 'Severity must be 1 (Low), 2 (Moderate), or 3 (High)'
            }), 400

        # Validate people_count
        if people_count <= 0:
            return jsonify({
                'error': 'Invalid people count',
                'message': 'People count must be greater than 0'
            }), 400

        # Make prediction
        prediction = predict_resources(severity, people_count)

        # Return response
        return jsonify({
            'prediction': prediction,
            'input': {
                'severity': severity,
                'people_count': people_count
            },
            'resources': {
                'bandages': int(prediction[0][0]),
                'ors_kits': int(prediction[0][1]),
                'water_liters': int(prediction[0][2]),
                'mosquito_nets': int(prediction[0][3]),
                'antibiotics': int(prediction[0][4]),
                'first_aids': int(prediction[0][5]),
                'saline': int(prediction[0][6])
            }
        }), 200

    except Exception as e:
        return jsonify({
            'error': 'Prediction failed',
            'message': str(e)
        }), 500
