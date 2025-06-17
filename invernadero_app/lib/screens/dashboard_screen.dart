import 'package:flutter/material.dart';
import 'package:invernadero_app/models/sensor_data.dart';
import 'package:invernadero_app/services/firebase_service.dart';
import 'package:invernadero_app/widgets/sensor_card.dart';
import 'package:intl/intl.dart'; // Para formatear el timestamp

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  String? _currentUserUid; // Necesitamos el UID del usuario

  @override
  void initState() {
    super.initState();
    _getUid();
  }

  // Función para obtener el UID. En un futuro, si usas autenticación,
  // el UID vendrá de FirebaseAuth. Por ahora, lo pondremos hardcodeado
  // o lo derivaremos de tu usuario de prueba.
  // Tu ESP32 usa "diegoruan109@gmail.com" y "prueba123".
  // Puedes obtener el UID de tu usuario en la consola de Firebase -> Authentication.
  // Si no quieres hardcodearlo, necesitarías Firebase Auth para el login.
  void _getUid() {
    // Por ahora, como no tienes autenticación en la app, y tu ESP32 usa un UID específico
    // que se genera al autenticarse, necesitarías obtener ese UID.
    // La forma más fácil de comenzar es obtener el UID de tu usuario de prueba
    // desde la consola de Firebase -> Authentication (es una cadena larga).
    // O podrías hacer que el ESP32 suba los datos directamente a una ruta fija
    // sin el UID dinámico, por ejemplo, /invernadero/readings/...
    // Para fines de esta práctica inicial, puedes usar un UID de prueba o una ruta fija.
    // Por ejemplo, si el UID del usuario "diegoruan109@gmail.com" es "tu_uid_largo_aqui", úsalo.
    // Voy a usar un placeholder para el UID que deberías reemplazar.
    setState(() {
      _currentUserUid = "YM7mg66eafgxz7i4vBJID8xy3Sq2"; // Reemplaza esto con tu UID real
      // Si no usas UID, y tu ESP32 sube a una ruta fija como 'invernadero/readings',
      // entonces el stream no necesitaría el uid: _database.child('invernadero/readings')...
      // Pero dado tu código de ESP32, el UID es parte de la ruta.
      // Así que obtén tu UID de la sección de Autenticación de Firebase.
    });
  }

  // Variable para controlar el estado del botón de riego
  bool _isPumpManualActive = false;

  @override
  Widget build(BuildContext context) {
    if (_currentUserUid == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Invernadero Inteligente'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard de Invernadero'),
        centerTitle: true,
      ),
      body: StreamBuilder<SensorData?>(
        stream: _firebaseService.getLatestSensorData(_currentUserUid!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Esperando datos del sensor...'));
          }

          final SensorData data = snapshot.data!;
          // Actualizar el estado del botón de riego basado en el dato de la bomba (si es el mismo flag)
          // Si el ESP32 escribe pumpStatus true/false directamente basado en riego_manual
          // o si tienes un flag separado 'riego_manual_app' en Firebase
          // Por ahora, usaremos el `pumpStatus` que ya tienes.
          _isPumpManualActive = data.pumpStatus;


          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Datos Actuales:',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(), // Deshabilita el scroll del GridView
                  crossAxisCount: 2, // 2 columnas
                  childAspectRatio: 1, // Relación de aspecto para las tarjetas
                  children: [
                    SensorCard(
                      title: 'Temperatura',
                      value: '${data.temperature.toStringAsFixed(1)} °C',
                      icon: Icons.thermostat_outlined,
                      color: Colors.redAccent,
                    ),
                    SensorCard(
                      title: 'Humedad Ambiental',
                      value: '${data.humidity.toStringAsFixed(1)} %',
                      icon: Icons.water_drop_outlined,
                      color: Colors.blueAccent,
                    ),
                    SensorCard(
                      title: 'Nivel de Luz',
                      value: '${data.lightLevel} %',
                      icon: Icons.light_mode_outlined,
                      color: Colors.orangeAccent,
                    ),
                    SensorCard(
                      title: 'Humedad del Suelo',
                      value: '${data.soilMoisture} %',
                      icon: Icons.grass_outlined,
                      color: Colors.brown,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Botón de Riego Manual
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Control Manual:',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () async {
                            // Cambia el estado en Firebase
                            final newStatus = !_isPumpManualActive; // Invertir el estado
                            setState(() {
                              _isPumpManualActive = newStatus; // Actualiza el UI inmediatamente
                            });
                            await _firebaseService.setPumpStatus(_currentUserUid!, newStatus);
                            // Puedes añadir un SnackBar para confirmar el envío
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Riego ${newStatus ? 'activado' : 'desactivado'} manualmente.'),
                                ),
                              );
                            }
                          },
                          icon: Icon(
                            _isPumpManualActive ? Icons.water_drop : Icons.water_drop_outlined,
                            size: 30,
                          ),
                          label: Text(
                            _isPumpManualActive ? 'Desactivar Riego Manual' : 'Activar Riego Manual',
                            style: const TextStyle(fontSize: 18),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isPumpManualActive ? Colors.red[400] : Colors.green[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Última actualización: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.fromMillisecondsSinceEpoch(data.timestamp * 1000))}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}