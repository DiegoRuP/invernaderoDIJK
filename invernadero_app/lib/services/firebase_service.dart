// EN: lib/services/firebase_service.dart

import 'package:firebase_database/firebase_database.dart';
import 'package:invernadero_app/models/sensor_data.dart';

class FirebaseService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Función para leer los datos del sensor de la ruta simple (CORREGIDA)
  Stream<SensorData?> getLatestSensorData(String uid) {
    return _database.child('UsersData/$uid/readings').onValue.map((event) {
      if (event.snapshot.value != null) {
        final Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
        return SensorData.fromMap(data);
      }
      return null;
    });
  }
  
  // Función para enviar el comando de la bomba
  Future<void> setPumpMode(String uid, String mode) async {
    await _database.child('invernadero/actuadores/riego_manual').set(mode);
    print('Comando enviado a Firebase: $mode');
  }

  // Función para escuchar el modo actual de la bomba y actualizar los colores
  Stream<String> getPumpModeStream() {
    return _database
        .child('invernadero/actuadores/riego_manual')
        .onValue
        .map((event) {
          final value = event.snapshot.value;
          if (value is String) {
            return value.trim(); // Limpia espacios en blanco
          }
          return "auto"; // Valor por defecto
        });
  }
}