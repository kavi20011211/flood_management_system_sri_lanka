from flask import Flask
from .extensions import mysql
from .routes import api
from flask_cors import CORS


def create_app():
    app = Flask(__name__)

    app.secret_key = ""
    app.config['MYSQL_HOST'] = 'localhost'
    app.config['MYSQL_USER'] = 'root'
    app.config['MYSQL_PASSWORD'] = '@Lk6985iop'
    app.config['MYSQL_DB'] = 'flood_risk_solution'

    # Update CORS
    CORS(app, origins=["http://localhost:5173", "*"])

    mysql.init_app(app)
    app.register_blueprint(api)

    return app
