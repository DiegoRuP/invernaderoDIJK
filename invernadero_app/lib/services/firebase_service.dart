import 'package:firebase_database/firebase_database.dart';
import 'package:invernadero_app/models/sensor_data.dart';

class FirebaseService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Escucha los cambios en los datos del último registro
  // Asumimos que quieres la última entrada dentro de /UsersData/{uid}/readings/
  // Para obtener el "último" necesitamos escuchar el nodo padre y ordenar/limitar.
  // Esto puede ser complejo si la estructura es solo timestamp como clave.
  // Si tu ESP32 sube datos a una ruta fija como /invernadero/latest_data, sería más fácil.

  // Dado que usas un timestamp como clave, necesitaremos escuchar todo el nodo 'readings'
  // y luego obtener la entrada más reciente.
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

  // Si decides tener un nodo 'current' o 'latest' en Firebase, sería más eficiente:
  // _database.child('UsersData/$uid/current_data').onValue.map(...)

  // Función para activar/desactivar la bomba manualmente
  Future<void> setPumpStatus(String uid, bool status) async {
    // Asumiendo que tienes un nodo 'control' para actuadores o similar
    // Si tu ESP32 espera un 'riego_manual' en una ruta específica
    // Database.setBool("invernadero/actuadores/riego_manual", true);
    // Necesitas replicar esa ruta aquí.
    // Por ejemplo, si tu ESP32 escucha en /invernadero/actuadores/riego_manual
    await _database.child('invernadero/actuadores/riego_manual').set(status);
    print('Bomba de agua: ${status ? 'ON' : 'OFF'} enviado a Firebase');
  }

  // Puedes añadir más funciones para otros actuadores o para enviar comandos
}