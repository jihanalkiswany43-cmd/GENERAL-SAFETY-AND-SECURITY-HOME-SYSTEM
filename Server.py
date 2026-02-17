from flask import Flask, request, jsonify
import os
import cv2
import face_recognition
import numpy as np
from werkzeug.utils import secure_filename
import pickle
import hashlib
import paho.mqtt.client as mqtt

# ---------------- Firebase Notification Setup ----------------
# Replace with your Firebase service account JSON file path
FIREBASE_CRED_PATH = "PATH_TO_YOUR_FIREBASE_SERVICE_ACCOUNT.json"

from google.oauth2 import service_account
from google.auth.transport.requests import Request
import json
import requests

cred = service_account.Credentials.from_service_account_file(
    FIREBASE_CRED_PATH,
    scopes=["https://www.googleapis.com/auth/firebase.messaging"]
)

def send_fcm_notification(title, body):
    access_token_info = cred.with_scopes(["https://www.googleapis.com/auth/firebase.messaging"])
    access_token_info.refresh(Request())
    access_token = access_token_info.token

    headers = {
        "Authorization": f"Bearer {access_token}",
        "Content-Type": "application/json; UTF-8",
    }

    message = {
        "message": {
            "topic": "oxygen_alerts",
            "notification": {"title": title, "body": body}
        }
    }

    response = requests.post(
        "https://fcm.googleapis.com/v1/projects/YOUR_FIREBASE_PROJECT_ID/messages:send",
        headers=headers,
        data=json.dumps(message)
    )
    print("Notification sent:", response.status_code, response.text)
    return response

# ---------------- MQTT Setup ----------------
# Replace with your MQTT broker IP or domain
MQTT_BROKER = "YOUR_MQTT_SERVER_IP"
MQTT_PORT = 1884  # Default MQTT port, change if needed
mqtt_client = mqtt.Client("FlaskServer")
mqtt_client.connect(MQTT_BROKER, MQTT_PORT)
mqtt_client.loop_start()

app = Flask(__name__)

# ---------------- Configuration ----------------
DATA_DIR = "dataset"
os.makedirs(DATA_DIR, exist_ok=True)

PASS_FILE = "passwords.pkl"
if not os.path.exists(PASS_FILE):
    with open(PASS_FILE, "wb") as f:
        pickle.dump({}, f)

# ---------------- Helper Functions ----------------
def hash_password(password: str) -> str:
    return hashlib.sha256(password.encode()).hexdigest()

def load_passwords():
    with open(PASS_FILE, "rb") as f:
        return pickle.load(f)

def save_passwords(data):
    with open(PASS_FILE, "wb") as f:
        pickle.dump(data, f)

# Face detection and encoding functions remain unchanged
# ...

# ---------------- ESP controls ----------------
# Replace IPs, topics, and sensitive configs with placeholders as above

# ---------------- Run ----------------
if __name__ == "__main__":
    mqtt_client.loop_start()
    app.run(host="0.0.0.0", port=5000)
