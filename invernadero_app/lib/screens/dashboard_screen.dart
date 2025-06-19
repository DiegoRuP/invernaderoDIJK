// EN: lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:invernadero_app/models/sensor_data.dart';
import 'package:invernadero_app/services/firebase_service.dart';
import 'package:invernadero_app/widgets/sensor_card.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  String? _currentUserUid;

  @override
  void initState() {
    super.initState();
    _getUid();
  }

  void _getUid() {
    // En una app real, aquí obtendrías el UID del usuario autenticado.
    // Usamos uno fijo para la prueba.
    setState(() {
      _currentUserUid = "YM7mg66eafgxz7i4vBJID8xy3Sq2";
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
            stream: _firebaseService.getCurrentDataStream(_currentUserUid!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data == null) {
                return const Center(child: Text('Esperando datos del invernadero...'));
              }

              final SensorData data = snapshot.data!;
              
              final bool isWatering = data.pumpStatus;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Datos Actuales:', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    
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
                                      fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 10),
                    
                    // --- DISEÑO RESPONSIVO PARA LAS TARJETAS DE SENSORES ---
                    LayoutBuilder(
                      builder: (context, constraints) {
                        // Punto de quiebre: si la pantalla es más ancha que 600px, usamos el diseño horizontal.
                        const double desktopBreakpoint = 600;

                        if (constraints.maxWidth < desktopBreakpoint) {
                          // VISTA PARA MÓVILES (Grid 2x2)
                          return GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: .95,
                            children: [
                              SensorCard(title: 'Temperatura', value: '${data.temperature.toStringAsFixed(1)} °C', icon: Icons.thermostat_outlined, color: Colors.redAccent),
                              SensorCard(title: 'Humedad Ambiental', value: '${data.humidity.toStringAsFixed(1)} %', icon: Icons.water_drop_outlined, color: Colors.blueAccent),
                              SensorCard(title: 'Nivel de Luz', value: '${data.lightLevel} %', icon: Icons.light_mode_outlined, color: Colors.orangeAccent),
                              SensorCard(title: 'Humedad del Suelo', value: '${data.soilMoisture} %', icon: Icons.grass_outlined, color: Colors.brown),
                            ],
                          );
                        } else {
                          // VISTA PARA WEB/ESCRITORIO (Fila Horizontal 1x4)
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
                    
                    // Panel de control (sin cambios)
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Control de Riego', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 15),
                            ElevatedButton.icon(
                              onPressed: isWatering ? null : () {
                                _firebaseService.triggerWatering();
                              },
                              icon: isWatering
                                  ? const SizedBox(
                                      width: 24,
                                      height: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                                    )
                                  : const Icon(Icons.water_drop, size: 20),
                              label: Text(isWatering ? "REGANDO..." : "REGAR AHORA (3 seg)"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isWatering ? Colors.grey.shade600 : Colors.blue.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Última actualización: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.fromMillisecondsSinceEpoch(data.timestamp * 1000))}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
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