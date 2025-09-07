from flask import Blueprint, jsonify, request
from services import weather_condition_service, safe_area_service, request_service, flood_prone_area_service, \
    feedback_service

api = Blueprint('api', __name__)


@api.route('/ping', methods=['GET'])
def ping():
    return jsonify({'message': 'pong'})


@api.route('/data', methods=['POST'])
def post_data():
    data = request.json
    return jsonify({'received': data})


# Weather condition API
@api.route('/weather-condition', methods=['POST'])
def handle_weather_data():
    return weather_condition_service.sendWeatherData()


@api.route('/get-risk-prediction', methods=['GET'])
def handle_risk_prediction():
    return weather_condition_service.getWeatherData()


@api.route('/generate-risk-summary', methods=['POST'])
def handle_risk_summary_generate():
    return weather_condition_service.generateRiskSummary()


@api.route('/get-safe-areas', methods=['GET'])
def handleGetSafeArea():
    return weather_condition_service.sendSafestAreas()


# Safe areas API
@api.route('/safe-area-create', methods=['POST'])
def handleSafeAreaCreate():
    return safe_area_service.createSafeAreas()


# Request API
@api.route('/request-safe-area', methods=['POST'])
def handleRequest():
    return request_service.userRequests()


# Flood prone area API
@api.route('/get-flood-prone-areas', methods=['GET'])
def handleFloodProne():
    return flood_prone_area_service.get_all_flood_prone_areas()


# Resource allocation API
@api.route('/get-resource-allocation', methods=['GET'])
def handleResourceAllocation():
    return safe_area_service.requestResourcesAllocation()


# Predict safe houses resources needs based on people count and severity
@api.route('/get-prediction-resources-needs', methods=['GET'])
def handlePredictionResourcesNeeds():
    return safe_area_service.getSHResourcesPrediction()


# Add a new feedback
@api.route("/add-a-new-feedback", methods=['POST'])
def handleAddANewFeedback():
    return feedback_service.addAnewFeedBack()


@api.route("/get-all-feedbacks", methods=['GET'])
def handleGetAllFeedBacks():
    return feedback_service.getAllFeedbacks()


@api.route("/add-a-reply", methods=['PUT'])
def handleAddAReply():
    return feedback_service.addAReply()
