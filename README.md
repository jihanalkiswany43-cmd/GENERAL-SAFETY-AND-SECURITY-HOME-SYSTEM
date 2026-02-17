# GENERAL-SAFETY-AND-SECURITY-HOME-SYSTEM
The project focuses on developing a smart and integrated home safety solution that goes beyond traditional security systems limited to theft prevention. Instead, it addresses critical environmental and security risks inside homes, such as oxygen level depletion in enclosed spaces and unauthorized access during long periods of absence.

The system integrates air quality monitoring, facial recognition–based access control, and home occupancy simulation, all fully managed through a cross-platform mobile application developed using Flutter.

The system architecture follows a three-tier model, consisting of:
 •A mobile application built with Flutter for real-time monitoring, control, and alert management
 •A backend server developed using Python (Flask) that acts as the Core Logic & API Provider, responsible for system logic and alert handling. The backend performs face detection using OpenCV and facial recognition using a deep learning model based on ResNet. Upon successful recognition, a real-time command is sent from the application to open or close the home door through the system
 •A hardware layer based on ESP32, equipped with environmental sensors, motion sensors, actuators, and alert mechanisms

A two-factor authentication mechanism was implemented by combining biometric facial recognition and password-based authentication, achieving a balance between security and usability.
In addition, Firebase Cloud Messaging (FCM) was integrated to deliver instant push notifications to users in case of any danger, such as low oxygen levels or abnormal motion detection.

To ensure fast and lightweight communication between system components, the MQTT protocol was adopted using the Mosquitto MQTT Broker, enabling low-latency message exchange between the backend server and the ESP32 device, making it well-suited for IoT applications.

The system was tested under real-world conditions and demonstrated reliable performance, scalability, and ease of use.

This project is highly relevant to the field of smart homes, as it demonstrates how Internet of Things (IoT), embedded systems, artificial intelligence, computer vision, mobile application development, and backend systems can be integrated into a practical and unified solution that enhances both safety and security.
