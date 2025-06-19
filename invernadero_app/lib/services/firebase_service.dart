// EN: lib/services/firebase_service.dart

import 'package:firebase_database/firebase_database.dart';
import 'package:invernadero_app/models/sensor_data.dart';

class FirebaseService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  
  // FUNCIÓN PARA LEER EL ESTADO ACTUAL
  // Se suscribe a la ruta donde el ESP32 reporta su estado y la convierte
  // en un objeto SensorData para que la app la pueda usar.
  Stream<SensorData?> getCurrentDataStream(String uid) {
    // La ruta ahora es la que definimos en el ESP32 optimizado
    return _database.child('UsersData/$uid/current').onValue.map((event) {
      if (event.snapshot.value != null) {
        final Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
        return SensorData.fromMap(data);
      }
      return null;
    });
  }
  
  // FUNCIÓN PARA EL BOTÓN ÚNICO
  // Envía el comando para iniciar un ciclo de riego manual de 3 segundos.
  // Es la única acción que la app necesita enviar.
  Future<void> triggerWatering() async {
    final controlPath = _database.child('invernadero/control');
    try {
      await controlPath.set({
        // El comando es fijo, ya que el botón solo hace una cosa
        'command': 'water-now', 
        'timestamp': ServerValue.timestamp, 
      });
      print('✅ Comando "Regar Ahora" enviado con éxito.');

    } catch (error) {
      print('❌❌❌ ERROR AL ENVIAR EL COMANDO: $error ❌❌❌');
    }
  }
}