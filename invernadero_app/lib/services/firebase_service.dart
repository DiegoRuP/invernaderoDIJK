import 'package:firebase_database/firebase_database.dart';
import 'package:invernadero_app/models/sensor_data.dart';

class FirebaseService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  Stream<SensorData?> getLatestSensorData(String uid) {
    return _database.child('UsersData/$uid/readings').orderByKey().limitToLast(1).onValue.map((event) {
      if (event.snapshot.value != null) {
        final Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
        // Iterar sobre el mapa (que contendrá un solo timestamp como clave)
        if (data.isNotEmpty) {
          final Map<dynamic, dynamic> latestEntry = data.values.first;
          return SensorData.fromMap(latestEntry);
        }
      }
      return null;
    });
  }
  // Función para enviar el estado de la bomba de agua
  Future<void> setPumpMode(String uid, String mode) async {
    await _database.child('invernadero/actuadores/riego_manual').set(mode);
    print('Modo bomba: $mode enviado a Firebase');
  }

  Stream<String> getPumpModeStream() {
    return _database
        .child('invernadero/actuadores/riego_manual')
        .onValue
        .map((event) {
          if (event.snapshot.value != null) {
            return event.snapshot.value.toString();
          }
          return "auto"; // Valor por defecto
        });
  }

  Future<String> getCurrentPumpMode() async {
    final snapshot = await _database.child('invernadero/actuadores/riego_manual').get();
    if (snapshot.exists) {
      return snapshot.value.toString();
    }
    return "auto"; // Valor por defecto
  }

}