#define ENABLE_USER_AUTH
#define ENABLE_DATABASE
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <FirebaseClient.h>
#include <DHT.h>
#include "time.h"

// Definición de pines
#define DHT_PIN 4
#define DHT_TYPE DHT11
#define LDR_PIN 34        // Pin analógico para LDR
#define SOIL_PIN 35       // Pin analógico para sensor de humedad del suelo
#define RELAY_PIN 2       // Pin digital para el relé de la bomba

// Inicialización del sensor DHT
DHT dht(DHT_PIN, DHT_TYPE);

// User functions
void asyncCB(AsyncResult &aResult);
void processData(AsyncResult &aResult);

// WiFi credentials

// Authentication
UserAuth user_auth("AIzaSyAeX00Myg65WK8uQpNneEDwfd32udYVv8Y", "diegoruan109@gmail.com", "prueba123");

// Firebase components
FirebaseApp app;
WiFiClientSecure ssl_client;
using AsyncClient = AsyncClientClass;
AsyncClient aClient(ssl_client);
RealtimeDatabase Database;

// Variable to save USER UID
String uid;

// Database paths
String databasePath;
String tempPath = "/temperature";
String humPath = "/humidity";
String lightPath = "/lightLevel";
String soilPath = "/soilMoisture";
String pumpPath = "/pumpStatus";
String timePath = "/timestamp";

// Parent Node (to be updated in every loop)
String parentPath;

// Variables para los sensores
float temperature = 0;
float humidity = 0;
int lightLevel = 0;
int soilMoisture = 0;
bool pumpStatus = false;

// Timing variables
unsigned long lastSensorRead = 0;
unsigned long lastDataSend = 0;
unsigned long lastManualCheck = 0;
const unsigned long SENSOR_INTERVAL = 2000;  // Leer sensores cada 2 segundos
const unsigned long SEND_INTERVAL = 10000;   // Enviar datos cada 10 segundos
const unsigned long MANUAL_CHECK_INTERVAL = 3000; // Revisar estado manual cada 3 segundos

bool firebaseReady = false;

// NTP Server
const char* ntpServer = "pool.ntp.org";
int timestamp;

// Create JSON objects for storing data
object_t jsonData, obj1, obj2, obj3, obj4, obj5, obj6;
JsonWriter writer;

String pumpMode = "auto"; // Estados: "auto", "on", "off"

// Initialize WiFi
void initWiFi() {
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to WiFi ..");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print('.');
    delay(1000);
  }
  Serial.println();
  Serial.print("Connected with IP: ");
  Serial.println(WiFi.localIP());
}

// Function that gets current epoch time
unsigned long getTime() {
  time_t now;
  struct tm timeinfo;
  if (!getLocalTime(&timeinfo)) {
    return(0);
  }
  time(&now);
  return now;
}

// Función para leer sensores
void readSensors() {
  // Leer DHT11
  temperature = dht.readTemperature();
  humidity = dht.readHumidity();
  
  // Verificar si las lecturas son válidas
  if (isnan(temperature) || isnan(humidity)) {
    Serial.println("Error reading DHT sensor!");
    temperature = 0;
    humidity = 0;
  }
  
  // Leer LDR (convertir a porcentaje, 0-100%)
  int ldrRaw = analogRead(LDR_PIN);
  lightLevel = map(ldrRaw, 0, 4095, 0, 100);
  
  // Leer sensor de humedad del suelo (convertir a porcentaje, 0-100%)
  int soilRaw = analogRead(SOIL_PIN);
  soilMoisture = map(soilRaw, 0, 4095, 100, 0); // Más humedad = mayor valor
  
  // Mostrar valores en Serial
  Serial.println("=== LECTURA DE SENSORES ===");
  Serial.printf("Temperatura: %.1f°C\n", temperature);
  Serial.printf("Humedad: %.1f%%\n", humidity);
  Serial.printf("Luz: %d%%\n", lightLevel);
  Serial.printf("Humedad suelo: %d%%\n", soilMoisture);
  Serial.printf("Bomba: %s\n", pumpStatus ? "ON" : "OFF");
  Serial.println("==========================");
}

// Función para enviar datos a Firebase
void sendToFirebase() {
  if (!firebaseReady) return;
  
  // Update database path
  databasePath = "/UsersData/" + uid + "/readings";
  
  // Get current timestamp
  timestamp = getTime();
  Serial.print("time: ");
  Serial.println(timestamp);
  
  parentPath = databasePath + "/" + String(timestamp);
  
  // Create JSON objects with sensor data (similar to the example)
  writer.create(obj1, tempPath, temperature);
  writer.create(obj2, humPath, humidity);
  writer.create(obj3, lightPath, lightLevel);
  writer.create(obj4, soilPath, soilMoisture);
  writer.create(obj5, pumpPath, pumpStatus);
  writer.create(obj6, timePath, timestamp);
  
  // Join all objects into one JSON
  writer.join(jsonData, 6, obj1, obj2, obj3, obj4, obj5, obj6);
  
  // Send to Firebase using the parent path
  Database.set<object_t>(aClient, parentPath, jsonData, processData, "RTDB_Send_Data");
  
  Serial.println("Datos enviados a Firebase");
}

// Función para verificar el modo de la bomba desde Firebase
void checkManualPumpStatus() {
  if (!firebaseReady) return;
  
  Database.get(aClient, "/invernadero/actuadores/riego_manual", processManualPump, "Manual_Pump_Check");
}

// Callback para procesar el modo de la bomba
void processManualPump(AsyncResult &aResult) {
  if (aResult.available()) {
    String result = aResult.c_str();
    // Remover comillas si las tiene
    result.replace("\"", "");
    
    Serial.printf("Modo bomba recibido: '%s'\n", result.c_str());
    
    if (result == "auto") {
      pumpMode = "auto";
      Serial.println("MODO AUTOMÁTICO activado desde Firebase");
    } else if (result == "on") {
      pumpMode = "on";
      Serial.println("BOMBA FORZADA ENCENDIDA desde Firebase");
    } else if (result == "off") {
      pumpMode = "off";
      Serial.println("BOMBA FORZADA APAGADA desde Firebase");
    } else {
      Serial.printf("Valor desconocido recibido: '%s'. Manteniendo modo actual: %s\n", result.c_str(), pumpMode.c_str());
    }
  }
  
  if (aResult.isError()) {
    Serial.printf("Error al leer modo bomba: %s\n", aResult.error().message().c_str());
  }
}

void setup(){
  Serial.begin(115200);
  
  Serial.println("=== SISTEMA INVERNADERO ===");
  
  // Inicializar pines
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, HIGH); // Bomba apagada inicialmente (asumiendo relé activo-bajo)
  
  // Inicializar DHT
  dht.begin();
  
  initWiFi();
  
  // Configure time
  configTime(0, 0, ntpServer);
  
  // Configure SSL client
  ssl_client.setInsecure();
  ssl_client.setConnectionTimeout(1000);
  ssl_client.setHandshakeTimeout(5);
  
  Serial.println("Initializing Firebase...");
  
  // Initialize Firebase
  initializeApp(aClient, app, getAuth(user_auth), processData, "🔐 authTask");
  app.getApp<RealtimeDatabase>(Database);
  Database.url(DATABASE_URL);
  
  Serial.println("Setup complete. Waiting for authentication...");
}

void loop(){
  // Maintain authentication and async tasks
  app.loop();
  
  // Check if authentication is ready
  if (app.ready() && !firebaseReady){
    uid = app.getUid().c_str();
    firebaseReady = true;
    
    Serial.println("FIREBASE CONNECTION SUCCESSFUL!");
    Serial.println("Authentication: READY");
    Serial.print("User UID: ");
    Serial.println(uid);

    Serial.println("Sistema de sensores iniciado...");
    Serial.println("================================");
  }
  
  // Si Firebase está listo, ejecutar tareas de sensores
  if (firebaseReady) {
    unsigned long currentTime = millis();
    
    // Leer sensores
    if (currentTime - lastSensorRead >= SENSOR_INTERVAL) {
      readSensors();
      lastSensorRead = currentTime;
    }
    
    // Verificar estado manual desde Firebase
    if (currentTime - lastManualCheck >= MANUAL_CHECK_INTERVAL) {
      checkManualPumpStatus();
      lastManualCheck = currentTime;
    }
    
    // Control de la bomba con 3 estados
    if (pumpMode == "on") {
      // Estado 1: Forzar bomba ENCENDIDA
      digitalWrite(RELAY_PIN, LOW); // Activar bomba
      pumpStatus = true;
      Serial.println("BOMBA ACTIVADA - Modo Manual ON");
    } 
    else if (pumpMode == "off") {
      // Estado 2: Forzar bomba APAGADA  
      digitalWrite(RELAY_PIN, HIGH); // Desactivar bomba
      pumpStatus = false;
      Serial.println("BOMBA DESACTIVADA - Modo Manual OFF");
    }
    else if (pumpMode == "auto") {
      // Estado 3: Control AUTOMÁTICO basado en humedad
      if (soilMoisture < 30) {
        digitalWrite(RELAY_PIN, LOW); // Activar bomba
        pumpStatus = true;
        Serial.println("BOMBA ACTIVADA - Modo Automático (suelo seco)");
      } else if (soilMoisture > 70) {
        digitalWrite(RELAY_PIN, HIGH); // Desactivar bomba
        pumpStatus = false;
        Serial.println("BOMBA DESACTIVADA - Modo Automático (suelo húmedo)");
      }
      // Si está entre 30-70%, mantener el estado actual
    }
    
    // Mostrar el estado actual de la bomba
    static bool lastDisplayedPumpStatus = !pumpStatus;
    static String lastDisplayedPumpMode = "";
    if (pumpStatus != lastDisplayedPumpStatus || pumpMode != lastDisplayedPumpMode) {
        Serial.printf("Estado de la Bomba: %s (Modo: %s)\n", 
                     pumpStatus ? "ON" : "OFF", 
                     pumpMode.c_str());
        lastDisplayedPumpStatus = pumpStatus;
        lastDisplayedPumpMode = pumpMode;
    }
    
    // Enviar datos a Firebase
    if (currentTime - lastDataSend >= SEND_INTERVAL) {
      sendToFirebase();
      lastDataSend = currentTime;
    }
  }
  else {
    static unsigned long lastCheck = 0;
    if (millis() - lastCheck > 2000) { // Check every 2 seconds
      lastCheck = millis();
      Serial.println("⏳ Waiting for Firebase authentication...");
    }
  }
}

void asyncCB(AsyncResult &aResult) {
  if (aResult.isEvent()) {
    Firebase.printf("📅 Event: %s\n", aResult.uid().c_str());
  }
  if (aResult.isError()) {
    Firebase.printf("Error: %s, msg: %s, code: %d\n", 
                   aResult.uid().c_str(), 
                   aResult.error().message().c_str(), 
                   aResult.error().code());
  }
  if (aResult.available()) {
    Firebase.printf("Data sent successfully: %s\n", aResult.uid().c_str());
  }
}

void processData(AsyncResult &aResult){
  if (!aResult.isResult())
    return;
  if (aResult.isEvent())
    Firebase.printf("📅 Event: %s, msg: %s, code: %d\n", aResult.uid().c_str(), aResult.eventLog().message().c_str(), aResult.eventLog().code());
  if (aResult.isDebug())
    Firebase.printf("🐛 Debug: %s, msg: %s\n", aResult.uid().c_str(), aResult.debug().c_str());
  if (aResult.isError())
    Firebase.printf("❌ Error: %s, msg: %s, code: %d\n", aResult.uid().c_str(), aResult.error().message().c_str(), aResult.error().code());
  if (aResult.available())
    Firebase.printf("✅ Success: %s, payload: %s\n", aResult.uid().c_str(), aResult.c_str());
}