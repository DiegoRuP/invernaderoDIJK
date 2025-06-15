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
└── web-dashboard/             # Dashboard web en Angular
```

## 🔧 Componentes del Sistema

### 🔌 ESP32 (`/esp32-code`)
- **Función**: Recopilación de datos de sensores y control de actuadores
- **Sensores**: Temperatura, humedad, luminosidad, pH del suelo
- **Actuadores**: Sistema de riego, ventilación, iluminación LED
- **Conectividad**: WiFi para comunicación con Firebase

### 📱 Aplicación Móvil (`/invernadero_app`)
- **Plataforma**: [Flutter/React Native]
- **Funciones**: 
  - Monitoreo en tiempo real
  - Control remoto de dispositivos
  - Notificaciones push
  - Historial de datos
  - Configuración de alertas

### 🌐 Dashboard Web (`/web-dashboard`)
- **Framework**: Angular
- **Funciones**:
  - Panel de control administrativo
  - Visualización de datos históricos
  - Configuración avanzada del sistema
  - Reportes y analytics
  - Gestión de usuarios

### 🔥 Base de Datos (`/firebase-database-config`)
- **Servicio**: Firebase Realtime Database
- **Función**: Almacenamiento y sincronización de datos en tiempo real
- **Estructura**: Configuraciones, datos de sensores, logs del sistema

## 🚀 Instalación y Configuración

### Prerrequisitos
- Node.js (v14 o superior)
- Angular CLI
- Arduino IDE o PlatformIO
- Cuenta de Firebase
- [Flutter SDK / React Native CLI] (para app móvil)

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
cd web-dashboard
npm install
ng serve
```

### 4. Aplicación Móvil
```bash
cd invernadero_app
# [Instrucciones específicas según la plataforma elegida]
```

## 📊 Funcionalidades

### Monitoreo
- ✅ Temperatura ambiente
- ✅ Humedad relativa
- ✅ Humedad del suelo
- ✅ Intensidad lumínica
- ✅ pH del suelo
- ✅ Estado de actuadores

### Control Automático
- 🔄 Sistema de riego automático
- 🔄 Control de ventilación
- 🔄 Regulación de iluminación LED
- 🔄 Alertas por condiciones críticas

### Interfaz de Usuario
- 📱 App móvil intuitiva
- 💻 Dashboard web responsive
- 📈 Gráficos en tiempo real
- 🔔 Notificaciones push
- 📋 Historial y reportes

## 🔒 Seguridad

- Autenticación mediante Firebase Auth
- Comunicación encriptada HTTPS/TLS
- Variables de entorno para datos sensibles
- Validación de permisos por usuario

## 🐛 Reporte de Bugs

Si encuentras algún bug, por favor abre un issue incluyendo:
- Descripción del problema
- Pasos para reproducirlo
- Comportamiento esperado vs actual
- Screenshots (si aplica)