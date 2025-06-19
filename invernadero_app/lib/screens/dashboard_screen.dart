// EN: lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:invernadero_app/models/sensor_data.dart';
import 'package:invernadero_app/services/firebase_service.dart';
import 'package:invernadero_app/widgets/sensor_card.dart';
// Ya no necesitamos 'intl' para el timestamp
// import 'package:intl/intl.dart'; 

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  String? _currentUserUid;
  String _pumpMode = "auto";

  @override
  void initState() {
    super.initState();
    _getUid();
    _listenToPumpMode();
  }

  void _getUid() {
    setState(() {
      _currentUserUid = "YM7mg66eafgxz7i4vBJID8xy3Sq2"; // UID de prueba
    });
  }

  void _listenToPumpMode() {
    _firebaseService.getPumpModeStream().listen((mode) {
      // --- LÍNEA DE DEPURACIÓN ---
      // Revisa la consola para asegurarte de que el valor llega correctamente
      print(">>> Modo actual desde Firebase: '---$mode---'");
      
      if (mounted) {
        setState(() {
          _pumpMode = mode;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserUid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Invernadero Inteligente')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard de Invernadero'),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: StreamBuilder<SensorData?>(
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
              
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Datos Actuales:', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),

                    // Tu tarjeta de alerta de luz (sin cambios)
                    if (data.lightLevel < 10)
                      Card(
                        color: Colors.amber[100],
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.amber[600]!)),
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.amber, size: 28),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "Se recomienda acercar a una fuente de luz",
                                  style: TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 10),
                    
                    // Tu LayoutBuilder para las tarjetas de sensores (sin cambios)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        const double mobileBreakpoint = 600;
                        if (constraints.maxWidth < mobileBreakpoint) {
                          return GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(), 
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: .92, 
                            children: [
                              SensorCard(title: 'Temperatura', value: '${data.temperature.toStringAsFixed(1)} °C', icon: Icons.thermostat_outlined, color: Colors.redAccent),
                              SensorCard(title: 'Humedad Ambiental', value: '${data.humidity.toStringAsFixed(1)} %', icon: Icons.water_drop_outlined, color: Colors.blueAccent),
                              SensorCard(title: 'Nivel de Luz', value: '${data.lightLevel} %', icon: Icons.light_mode_outlined, color: Colors.orangeAccent),
                              SensorCard(title: 'Humedad del Suelo', value: '${data.soilMoisture} %', icon: Icons.grass_outlined, color: Colors.brown),
                            ],
                          );
                        } else {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: SensorCard(title: 'Temperatura', value: '${data.temperature.toStringAsFixed(1)} °C', icon: Icons.thermostat_outlined, color: Colors.redAccent)),
                              const SizedBox(width: 16),
                              Expanded(child: SensorCard(title: 'Humedad Ambiental', value: '${data.humidity.toStringAsFixed(1)} %', icon: Icons.water_drop_outlined, color: Colors.blueAccent)),
                              const SizedBox(width: 16),
                              Expanded(child: SensorCard(title: 'Nivel de Luz', value: '${data.lightLevel} %', icon: Icons.light_mode_outlined, color: Colors.orangeAccent)),
                              const SizedBox(width: 16),
                              Expanded(child: SensorCard(title: 'Humedad del Suelo', value: '${data.soilMoisture} %', icon: Icons.grass_outlined, color: Colors.brown)),
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    // Tu Card de Control Manual (ahora funcional)
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.symmetric(horizontal: 0), // Ajustado para mejor alineación
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text('Control Manual:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 15),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Botón AUTO
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _firebaseService.setPumpMode(_currentUserUid!, "auto"),
                                    icon: const Icon(Icons.auto_mode, size: 20),
                                    label: const Text('Auto'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _pumpMode == "auto" ? Colors.blue[600] : Colors.grey[400],
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Botón ON
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _firebaseService.setPumpMode(_currentUserUid!, "on"),
                                    icon: const Icon(Icons.water_drop, size: 20),
                                    label: const Text('ON'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _pumpMode == "on" ? Colors.green[600] : Colors.grey[400],
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Botón OFF
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _firebaseService.setPumpMode(_currentUserUid!, "off"),
                                    icon: const Icon(Icons.stop_circle_outlined, size: 20), // Icono cambiado
                                    label: const Text('OFF'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _pumpMode == "off" ? Colors.red[600] : Colors.grey[400],
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Se eliminó el texto de 'Última actualización'
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}