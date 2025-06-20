# 🌱 Sistema de Monitoreo de Invernadero

Sistema integral de monitoreo y control para invernaderos que incluye un dispositivo ESP32, aplicación móvil y dashboard web, todo conectado a través de Firebase.

## 📋 Descripción del Proyecto

Este sistema permite monitorear y controlar las condiciones ambientales de un invernadero en tiempo real, incluyendo temperatura, humedad, iluminación y otros parámetros importantes para el crecimiento óptimo de las plantas.

## 🏗️ Arquitectura del Sistema

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Dispositivo   │────│    Firebase     │────│  App Móvil &    │
│     ESP32       │    │    Database     │    │  Web Dashboard  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 📁 Estructura del Proyecto

```
├── esp32-code/                 # Código para el microcontrolador ESP32
├── firebase-database-config/   # Configuración de Firebase Database
├── invernadero_app/           # Aplicación móvil
```

## 🔧 Componentes del Sistema

### 🔌 ESP32 (`/esp32-code`)
- **Función**: Recopilación de datos de sensores y control de actuadores
- **Sensores**: Temperatura, humedad, luminosidad, pH del suelo
- **Actuadores**: Sistema de riego, ventilación, iluminación LED
- **Conectividad**: WiFi para comunicación con Firebase

### 📱 Aplicación Móvil (`/invernadero_app`)
- **Plataforma**: [Flutter]
- **Funciones**: 
  - Monitoreo en tiempo real
  - Control remoto de dispositivos

### 🌐 Dashboard Web (`/web-dashboard`)
- **Framework**: Angular
- **Funciones**:
  - Panel de control administrativo
  - Visualización de datos 

### 🔥 Base de Datos (`/firebase-database-config`)
- **Servicio**: Firebase Realtime Database
- **Función**: Almacenamiento y sincronización de datos en tiempo real
- **Estructura**: Configuraciones, datos de sensores, logs del sistema

## 🚀 Instalación y Configuración

### Prerrequisitos
- Arduino IDE o PlatformIO
- Cuenta de Firebase
- [Flutter SDK] (para app móvil y web)

### 1. Configuración de Firebase
```bash
cd firebase-database-config
# Agregar tu archivo de configuración de Firebase
# Seguir las instrucciones en el README específico de esta carpeta
```

### 2. Configuración ESP32
```bash
cd esp32-code
# Configurar credenciales WiFi y Firebase en config.h
# Compilar y subir el código al ESP32
```

### 3. Dashboard Web
```bash
cd invernadero_app
flutter build web
python3 
```

### 4. Aplicación Móvil
```bash
cd invernadero_app
flutter run
```

## 📊 Funcionalidades

### Monitoreo
- ✅ Temperatura ambiente
- ✅ Humedad relativa
- ✅ Humedad del suelo
- ✅ Intensidad lumínica
- ✅ Estado de actuadores

### Control Automático
- 🔄 Sistema de riego automático
- 🔄 Alertas por condiciones críticas

### Interfaz de Usuario
- 📱 App móvil intuitiva
- 💻 Dashboard web responsive
- 📈 Gráficos en tiempo real

## 🔒 Seguridad

- Autenticación mediante Firebase Auth
- Comunicación encriptada HTTPS/TLS
- Variables de entorno para datos sensibles
- Validación de permisos por usuario
