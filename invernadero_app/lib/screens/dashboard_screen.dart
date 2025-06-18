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
    void _listenToPumpMode() {
      _firebaseService.getPumpModeStream().listen((mode) {
        if (mounted) {
          setState(() {
            _pumpMode = mode;
          });
        }
      });
    }
    _getUid();
  }
  void _getUid() {
    setState(() {
      _currentUserUid = "YM7mg66eafgxz7i4vBJID8xy3Sq2"; 
    });
  }

  // Variable para controlar el estado del botón de riego
  String _pumpMode = "auto";

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
          _pumpMode = data.pumpStatus.toString();


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
                  physics: const NeverScrollableScrollPhysics(), 
                  crossAxisCount: 2, 
                  childAspectRatio: 1, 
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
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const Text(
                          'Control Manual:',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),

                        // NUEVOS BOTONES: Auto, ON, OFF
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Botón Automático
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    setState(() {
                                      _pumpMode = "auto";
                                    });
                                    await _firebaseService.setPumpMode(_currentUserUid!, "auto");
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Modo automático activado')),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.auto_mode, size: 20),
                                  label: const Text('Auto'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _pumpMode == "auto" ? Colors.blue[600] : Colors.grey[400],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Botón Encender (ON)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    setState(() {
                                      _pumpMode = "on";
                                    });
                                    await _firebaseService.setPumpMode(_currentUserUid!, "on");
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Bomba encendida manualmente')),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.water_drop, size: 20),
                                  label: const Text('ON'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _pumpMode == "on" ? Colors.green[600] : Colors.grey[400],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Botón Apagar (OFF)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    setState(() {
                                      _pumpMode = "off";
                                    });
                                    await _firebaseService.setPumpMode(_currentUserUid!, "off");
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Bomba apagada manualmente')),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.water_drop_outlined, size: 20),
                                  label: const Text('OFF'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _pumpMode == "off" ? Colors.red[600] : Colors.grey[400],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
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