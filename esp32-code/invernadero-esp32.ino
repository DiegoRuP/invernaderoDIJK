// SISTEMA DE RIEGO HÍBRIDO - ESP32 FIRMWARE v5.1
// Implementación corregida según especificación técnica

#define ENABLE_USER_AUTH
#define ENABLE_DATABASE
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <FirebaseClient.h>
#include <DHT.h>
#include <time.h>

// Definición de pines
#define DHT_PIN 4
#define DHT_TYPE DHT11
#define LDR_PIN 34
#define SOIL_PIN 35
#define RELAY_PIN 2

// Inicialización del sensor DHT
DHT dht(DHT_PIN, DHT_TYPE);

// User functions
void asyncCB(AsyncResult &aResult);
void processData(AsyncResult &aResult);
void processCommand(AsyncResult &aResult);

// --- Credenciales ---
#define WIFI_SSID "Red-Ruan"
#define WIFI_PASSWORD "Pulgoso510"
#define Web_API_KEY "AIzaSyAeX00Myg65WK8uQpNneEDwfd32udYVv8Y"
#define DATABASE_URL "https://invernadero-multi-default-rtdb.firebaseio.com/"
#define USER_EMAIL "diegoruan109@gmail.com"
#define USER_PASS "prueba123"

// NTP Server para timestamp real
const char* ntpServer = "pool.ntp.org";
const long gmtOffset_sec = -21600; // GMT-6 para México
const int daylightOffset_sec = 0;

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

// ENDPOINTS según especificación
String commandEndpoint = "/invernadero/control";        // SOLO LECTURA para ESP32
String statusEndpoint;                                  // SOLO ESCRITURA para ESP32 (/UsersData/{uid}/current)

// Variables del sistema (estado interno del ESP32)
float temperature = 0;
float humidity = 0;
int lightLevel = 0;
int soilMoisture = 0;
bool pumpStatus = false;        // Estado FÍSICO actual del relé
String pumpMode = "auto";       // Modo de operación ("manual" o "auto")

// Control de riego por duración
bool isWatering = false;                    // Indica si está regando actualmente
unsigned long wateringStartTime = 0;       // Tiempo de inicio del riego
const unsigned long WATERING_DURATION = 3000; // 3 segundos de riego
unsigned long lastAutoWatering = 0;        // Timestamp del último riego automático
const unsigned long AUTO_WATERING_COOLDOWN = 60000; // 1 minuto entre riegos automáticos

// Control de timestamps para evitar comandos repetidos
unsigned long lastProcessedTimestamp = 0;

// Timing variables
unsigned long lastSensorRead = 0;
unsigned long lastStatusSend = 0;
unsigned long lastCommandCheck = 0;
const unsigned long SENSOR_INTERVAL = 2000;     // Leer sensores cada 2s
const unsigned long STATUS_INTERVAL = 5000;     // Enviar estado cada 5s
const unsigned long COMMAND_INTERVAL = 3000;    // Revisar comandos cada 3s

bool firebaseReady = false;
bool firebaseIsBusy = false;
bool ntpSynced = false;

// Create JSON objects
object_t jsonData, obj1, obj2, obj3, obj4, obj5, obj6, obj7;
JsonWriter writer;

// Función para obtener timestamp Unix real
unsigned long getUnixTimestamp() {
  if (!ntpSynced) {
    return millis() / 1000; // Fallback con tiempo relativo
  }
  time_t now;
  time(&now);
  return now;
}

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
  
  // Configurar NTP para timestamp real
  Serial.println("⏰ Sincronizando tiempo con NTP...");
  configTime(gmtOffset_sec, daylightOffset_sec, ntpServer);
  
  // Esperar a que se sincronice el tiempo
  struct tm timeinfo;
  int attempts = 0;
  while (!getLocalTime(&timeinfo) && attempts < 10) {
    delay(1000);
    attempts++;
    Serial.print(".");
  }
  
  if (attempts < 10) {
    ntpSynced = true;
    Serial.println();
    Serial.println("✅ Tiempo sincronizado con NTP");
    Serial.println(&timeinfo, "Fecha y hora actual: %A, %B %d %Y %H:%M:%S");
  } else {
    Serial.println();
    Serial.println("⚠️ Usando tiempo relativo (NTP no disponible)");
  }
}

// Función para leer sensores
void readSensors() {
  // Leer DHT
  float temp = dht.readTemperature();
  float hum = dht.readHumidity();
  
  if (!isnan(temp) && !isnan(hum) && temp > 0 && hum > 0) {
    temperature = temp;
    humidity = hum;
  }
  
  // Leer sensores analógicos
  int ldrRaw = analogRead(LDR_PIN);
  lightLevel = map(ldrRaw, 0, 4095, 0, 100);
  int soilRaw = analogRead(SOIL_PIN);
  soilMoisture = map(soilRaw, 0, 4095, 100, 0);
}

// Función para iniciar riego por duración
void startWatering(String reason) {
  if (isWatering) {
    Serial.println("⚠️ Ya se está regando, ignorando comando");
    return;
  }
  
  isWatering = true;
  pumpStatus = true;
  wateringStartTime = millis();
  digitalWrite(RELAY_PIN, LOW); // Activar bomba (relé activo bajo)
  
  Serial.printf("💧 INICIANDO RIEGO por %s - Duración: %lu ms\n", reason.c_str(), WATERING_DURATION);
  
  // ENVÍO INMEDIATO de estado cuando INICIA el riego
  sendStatusToFirebase();
}

// Función para detener riego
void stopWatering() {
  if (!isWatering) return;
  
  isWatering = false;
  pumpStatus = false;
  digitalWrite(RELAY_PIN, HIGH); // Desactivar bomba
  
  // Volver al modo automático después de cualquier ciclo
  pumpMode = "auto";
  
  Serial.println("🛑 RIEGO TERMINADO - Volviendo a modo automático");
  
  // ENVÍO INMEDIATO de estado cuando TERMINA el riego
  sendStatusToFirebase();
}

// Función para enviar ESTADO a Firebase (/UsersData/{uid}/current)
void sendStatusToFirebase() {
  if (!firebaseReady || firebaseIsBusy) return;
  
  firebaseIsBusy = true;
  Serial.println("📤 Enviando estado a Firebase...");
  
  // Obtener timestamp Unix real
  unsigned long timestamp = getUnixTimestamp();
  
  // Construir JSON según especificación exacta
  writer.create(obj1, "temperature", temperature);
  writer.create(obj2, "humidity", humidity);
  writer.create(obj3, "lightLevel", lightLevel);
  writer.create(obj4, "soilMoisture", soilMoisture);
  writer.create(obj5, "pumpStatus", pumpStatus);        // Estado FÍSICO actual del relé
  writer.create(obj6, "pumpMode", pumpMode);            // Modo de operación actual
  writer.create(obj7, "timestamp", timestamp);          // Timestamp Unix real
  
  // Unir todos los objetos
  writer.join(jsonData, 7, obj1, obj2, obj3, obj4, obj5, obj6, obj7);
  
  Database.set<object_t>(aClient, statusEndpoint, jsonData, processData, "SEND_STATUS");
}

// Función para leer COMANDOS desde Firebase (/invernadero/control)
void readCommandsFromFirebase() {
  if (!firebaseReady || firebaseIsBusy) return;
  
  firebaseIsBusy = true;
  Serial.println("📥 Revisando comandos...");
  
  Database.get(aClient, commandEndpoint, processCommand, "READ_COMMAND");
}

// Procesar comandos recibidos desde Firebase
void processCommand(AsyncResult &aResult) {
  firebaseIsBusy = false;
  
  if (aResult.isError()) {
    Serial.printf("❌ Error leyendo comandos: %s\n", aResult.error().message().c_str());
    return;
  }
  
  if (aResult.available()) {
    String payload = aResult.payload();
    Serial.printf("📋 Payload RAW recibido: %s\n", payload.c_str());
    
    // El payload puede venir como "null" si no hay datos
    if (payload == "null" || payload.length() < 10) {
      Serial.println("ℹ️ No hay comandos disponibles (payload vacío)");
      return;
    }
    
    // Parsear el JSON para extraer command y timestamp
    String command = "";
    unsigned long timestamp = 0;
    
    // Extraer comando - buscar "water-now" directamente
    if (payload.indexOf("water-now") != -1) {
      command = "water-now";
      Serial.println("🔍 Comando 'water-now' detectado en payload");
    }
    
    // Extraer timestamp con parsing más robusto
    int tsIndex = payload.indexOf("timestamp");
    if (tsIndex != -1) {
      // Buscar el valor después de "timestamp":
      int colonIndex = payload.indexOf(":", tsIndex);
      if (colonIndex != -1) {
        // Encontrar el final del número (hasta coma, corchete o fin)
        int start = colonIndex + 1;
        int end = payload.length();
        
        // Buscar delimitadores
        int commaPos = payload.indexOf(",", start);
        int bracePos = payload.indexOf("}", start);
        
        if (commaPos != -1 && commaPos < end) end = commaPos;
        if (bracePos != -1 && bracePos < end) end = bracePos;
        
        String tsStr = payload.substring(start, end);
        tsStr.trim();
        tsStr.replace(" ", ""); // Eliminar espacios
        
        // Convertir a número
        timestamp = tsStr.toInt();
        if (timestamp == 0) {
          // Intentar conversión con long long por si es muy grande
          timestamp = (unsigned long)tsStr.toDouble();
        }
      }
    }
    
    Serial.printf("🔍 PARSEADO - Comando: '%s', Timestamp: %lu (Último procesado: %lu)\n", 
                  command.c_str(), timestamp, lastProcessedTimestamp);
    
    // Verificar si es un comando válido y nuevo
    if (command.length() > 0 && command == "water-now") {
      if (timestamp > lastProcessedTimestamp) {
        lastProcessedTimestamp = timestamp;
        Serial.printf("✅ ¡EJECUTANDO COMANDO MANUAL! Timestamp: %lu\n", timestamp);
        
        // Ejecutar riego manual
        pumpMode = "manual";
        startWatering("MANUAL desde APP");
        
      } else {
        Serial.printf("⚠️ Comando ya procesado - Timestamp: %lu <= %lu\n", timestamp, lastProcessedTimestamp);
      }
    } else if (command.length() == 0) {
      Serial.println("❌ No se encontró comando válido en el payload");
    } else {
      Serial.printf("⚠️ Comando desconocido: '%s'\n", command.c_str());
    }
    
  } else {
    Serial.println("ℹ️ No hay datos disponibles en la respuesta");
  }
}

// Función para controlar la bomba (lógica híbrida)
void controlPump() {
  unsigned long currentTime = millis();
  
  // 1. Verificar si el riego actual debe terminar (PRIORIDAD MÁXIMA)
  if (isWatering && (currentTime - wateringStartTime >= WATERING_DURATION)) {
    stopWatering();
    return; // Salir para procesar el cambio de estado
  }
  
  // 2. Riego automático solo si:
  //    - NO está regando actualmente
  //    - Está en modo automático
  //    - La humedad del suelo es menor a 30%
  //    - Ha pasado el tiempo de cooldown
  if (!isWatering && pumpMode == "auto" && soilMoisture < 30) {
    if (currentTime - lastAutoWatering >= AUTO_WATERING_COOLDOWN) {
      lastAutoWatering = currentTime;
      startWatering("AUTOMÁTICO");
      Serial.printf("🤖 Riego automático activado (humedad: %d%% < 30%%)\n", soilMoisture);
    } else {
      // Debug del cooldown cada 10 segundos
      static unsigned long lastCooldownMsg = 0;
      if (currentTime - lastCooldownMsg >= 10000) {
        lastCooldownMsg = currentTime;
        unsigned long remaining = AUTO_WATERING_COOLDOWN - (currentTime - lastAutoWatering);
        Serial.printf("⏳ Riego automático en cooldown (faltan %lu segundos)\n", remaining / 1000);
      }
    }
  }
}

void setup() {
  Serial.begin(115200);
  Serial.println("\n========================================");
  Serial.println("=== ESP32 IRRIGATION SYSTEM v5.1 ===");
  Serial.println("=== SISTEMA DE RIEGO HÍBRIDO      ===");
  Serial.println("========================================");
  
  // Configurar pin del relé
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, HIGH); // Bomba OFF inicialmente (relé activo bajo)
  pumpStatus = false;
  
  // Inicializar sensor DHT
  dht.begin();
  
  // Conectar WiFi y sincronizar tiempo
  initWiFi();
  
  // Configurar cliente SSL
  ssl_client.setInsecure();
  ssl_client.setConnectionTimeout(1000);
  ssl_client.setHandshakeTimeout(5);
  
  // Inicializar Firebase
  Serial.println("🔥 Inicializando Firebase...");
  initializeApp(aClient, app, getAuth(user_auth), processData, "AUTH_TASK");
  app.getApp<RealtimeDatabase>(Database);
  Database.url(DATABASE_URL);
  
  Serial.println("⏳ Esperando autenticación de Firebase...");
}

void loop() {
  app.loop();
  
  // Configurar endpoints cuando Firebase esté listo
  if (app.ready() && !firebaseReady) {
    uid = app.getUid().c_str();
    firebaseReady = true;
    
    // Configurar endpoint de estado según especificación
    statusEndpoint = "/UsersData/" + uid + "/current";
    
    Serial.println("========================================");
    Serial.println("🔥 FIREBASE CONECTADO EXITOSAMENTE!");
    Serial.printf("📍 Command Endpoint (READ):  %s\n", commandEndpoint.c_str());
    Serial.printf("📍 Status Endpoint (WRITE):  %s\n", statusEndpoint.c_str());
    Serial.printf("👤 User UID: %s\n", uid.c_str());
    Serial.println("🚀 Sistema listo para operar");
    Serial.println("========================================");
  }
  
  if (firebaseReady) {
    unsigned long currentTime = millis();
    
    // 1. Leer sensores (operación local - siempre)
    if (currentTime - lastSensorRead >= SENSOR_INTERVAL) {
      readSensors();
      lastSensorRead = currentTime;
    }
    
    // 2. Controlar bomba físicamente (operación local - siempre)
    controlPump();
    
    // 3. Comunicación con Firebase (solo si no está ocupado)
    if (!firebaseIsBusy) {
      // Prioridad 1: Leer comandos del endpoint de control
      if (currentTime - lastCommandCheck >= COMMAND_INTERVAL) {
        lastCommandCheck = currentTime;
        readCommandsFromFirebase();
      }
      // Prioridad 2: Enviar estado al endpoint de estado
      else if (currentTime - lastStatusSend >= STATUS_INTERVAL) {
        lastStatusSend = currentTime;
        sendStatusToFirebase();
      }
    }
    
    // Debug del estado cada 10 segundos
    static unsigned long lastDebug = 0;
    if (currentTime - lastDebug >= 10000) {
      lastDebug = currentTime;
      Serial.println("==========================================");
      Serial.printf("📊 ESTADO DEL SISTEMA:\n");
      Serial.printf("   🌡️  Temperatura: %.1f°C\n", temperature);
      Serial.printf("   💧 Humedad Aire: %.1f%%\n", humidity);
      Serial.printf("   ☀️  Nivel Luz: %d%%\n", lightLevel);
      Serial.printf("   🌱 Humedad Suelo: %d%%\n", soilMoisture);
      Serial.printf("   ⚡ Estado Bomba: %s (%s)\n", pumpStatus ? "ACTIVA" : "INACTIVA", pumpMode.c_str());
      Serial.printf("   🔄 Estado Riego: %s\n", isWatering ? "REGANDO" : "ESPERANDO");
      Serial.println("==========================================");
    }
  }
}

// Callback para procesar respuestas de Firebase
void processData(AsyncResult &aResult) {
  if (aResult.uid() == "SEND_STATUS") {
    firebaseIsBusy = false;
  }
  
  if (aResult.isError()) {
    Serial.printf("❌ Error en tarea '%s': %s\n", aResult.uid().c_str(), aResult.error().message().c_str());
    firebaseIsBusy = false; // Liberar el flag en caso de error
    return;
  }
  
  if (aResult.available() && aResult.uid() == "SEND_STATUS") {
    Serial.println("✅ Estado enviado a Firebase exitosamente");
  }
  
  if (aResult.uid() == "AUTH_TASK") {
    if (aResult.available()) {
      Serial.println("🔐 Autenticación completada");
    }
  }
}

void asyncCB(AsyncResult &aResult) {
  if (aResult.isEvent()) {
    Serial.printf("📅 Event: %s\n", aResult.uid().c_str());
  }
  if (aResult.isError()) {
    Serial.printf("❌ Async Error: %s, msg: %s\n", aResult.uid().c_str(), aResult.error().message().c_str());
  }
}