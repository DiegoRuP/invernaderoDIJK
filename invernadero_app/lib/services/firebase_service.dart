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
  Future<void> setPumpStatus(String uid, bool status) async {
    await _database.child('invernadero/actuadores/riego_manual').set(status);
    print('Bomba de agua: ${status ? 'ON' : 'OFF'} enviado a Firebase');
  }

  // Puedes añadir más funciones para otros actuadores o para enviar comandos
}