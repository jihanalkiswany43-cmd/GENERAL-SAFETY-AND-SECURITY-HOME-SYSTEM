#include <WiFi.h>
#include <PubSubClient.h>
#include <ESP32Servo.h>

// -------- WIFI SETTING AND MQTT --------
const char* ssid = "WIFI NAME";
const char* password = "YOUR WIFI PASSWORD ";
const char* mqtt_server = "YOUR_MQTT_SERVER_IP";
const int mqtt_port = 1884;

WiFiClient espClient;
PubSubClient client(espClient);
Servo doorServo;

// -------- Pins --------
int oxygenPin = 34;       // MQ-2 Analog
int pirPin = 13;           // PIR sensor
int relayPin = 26;         // Relay Active LOW (بدل الليد الأصفر)
int ledBlue = 17;
int ledRed  = 18;
int buzzerPin = 22;        // Buzzer للأوكسجين
int doorPin = 23;          // Servo pin

// -------- Threshold --------
int oxygenThreshold = 130;
bool pirStateLast = LOW;

// -------- Motion Control --------
bool pirEnabled = true; // Motion sensor default: enabled

void setup_wifi() {
  Serial.begin(115200);
  delay(10);
  Serial.println();
  Serial.print("Connecting to ");
  Serial.println(ssid);
  
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  
  Serial.println("");
  Serial.println("WiFi connected");
  Serial.println(WiFi.localIP());
}

void reconnect() {
  while (!client.connected()) {
    Serial.print("Attempting MQTT connection...");
    if (client.connect("ESP32Client")) {
      Serial.println("connected");
      client.subscribe("home/door");
      client.subscribe("home/light");
      client.subscribe("home/alarm");
      client.subscribe("home/motion_control");
    } else {
      Serial.print("failed, rc=");
      Serial.print(client.state());
      Serial.println(" try again in 5 seconds");
      delay(5000);
    }
  }
}

void callback(char* topic, byte* payload, unsigned int length) {
  String msg = "";
  for (unsigned int i = 0; i < length; i++) {
    msg += (char)payload[i];
  }

  if (String(topic) == "home/door") {
    if (msg == "open") doorServo.write(0);
    else if (msg == "close") doorServo.write(90);
  }
  else if (String(topic) == "home/light") {
    if (msg == "toggle") digitalWrite(ledBlue, !digitalRead(ledBlue));
  }
  else if (String(topic) == "home/alarm") {
    if (msg == "toggle") digitalWrite(buzzerPin, !digitalRead(buzzerPin));
  }
  else if (String(topic) == "home/motion_control") {
    if (msg == "on") pirEnabled = true;
    else if (msg == "off") pirEnabled = false;
  }
}

void setup() {
  Serial.begin(115200);
  setup_wifi();
  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(callback);

     // LED الداخلي
  pinMode(relayPin, OUTPUT); // Relay
  pinMode(ledBlue, OUTPUT);
  pinMode(ledRed, OUTPUT);
  pinMode(buzzerPin, OUTPUT);
  pinMode(pirPin, INPUT);

  digitalWrite(relayPin, HIGH); // Relay OFF (Active LOW)

  doorServo.attach(doorPin);
}

void loop() {
  if (!client.connected()) reconnect();
  client.loop();

  // -------- قراءة الاوكسجين --------
  int oxygenValue = analogRead(oxygenPin);
  Serial.print("Oxygen level: ");
  Serial.println(oxygenValue);

  if (oxygenValue >= oxygenThreshold) {
    client.publish("home/oxygen_alert", "Take safety precautions immediately!");
    digitalWrite(buzzerPin, HIGH);
  } else {
    digitalWrite(buzzerPin, LOW);
  }
    delay(500); 
  // -------- قراءة PIR --------
  bool pirState = digitalRead(pirPin);

  if (pirEnabled) {
    if (pirState == HIGH && pirStateLast == LOW) {
      Serial.println("Motion detected!");
      digitalWrite(2, HIGH);        // LED الداخلي
      digitalWrite(relayPin, LOW);  // Relay ON
      digitalWrite(ledBlue, HIGH);
      digitalWrite(ledRed, HIGH);

      client.publish("home/motion_alert", "Please check immediately!");
    } 
    else if (pirState == LOW && pirStateLast == HIGH) {
      digitalWrite(2, LOW);
      digitalWrite(relayPin, HIGH); // Relay OFF
      digitalWrite(ledBlue, LOW);
      digitalWrite(ledRed, LOW);
    }
  } else {
    digitalWrite(2, LOW);
    digitalWrite(relayPin, HIGH); // Relay OFF
    digitalWrite(ledBlue, LOW);
    digitalWrite(ledRed, LOW);
  }

  pirStateLast = pirState;
}
