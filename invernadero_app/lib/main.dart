import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  // Necesario para inicializar Firebase
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase
  await Firebase.initializeApp();
  
  runApp(InvernaderoApp());
}

class InvernaderoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Invernadero Inteligente',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: PantallaPrincipal(),
    );
  }
}

class PantallaPrincipal extends StatefulWidget {
  @override
  _PantallaPrincipalState createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  // Referencias a las colecciones en Firestore
  final CollectionReference _sensores = FirebaseFirestore.instance.collection('sensores');
  final CollectionReference _actuadores = FirebaseFirestore.instance.collection('actuadores');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🌱 Invernadero Smart'),
        backgroundColor: Colors.green,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título de sensores
              Text(
                '📊 Estado de Sensores',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              
              // Tarjetas de sensores
              _construirTarjetaSensor('Temperatura', '🌡️', Colors.orange),
              SizedBox(height: 12),
              _construirTarjetaSensor('Humedad Ambiente', '💧', Colors.blue),
              SizedBox(height: 12),
              _construirTarjetaSensor('Humedad Suelo', '🌱', Colors.brown),
              SizedBox(height: 12),
              _construirTarjetaSensor('Luz', '☀️', Colors.yellow),
              
              SizedBox(height: 32),
              
              // Título de controles
              Text(
                '🎛️ Controles',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              
              // Botones de control
              _construirBotonControl('Riego Manual', '💦', Colors.blue, 'riego'),
              SizedBox(height: 12),
              _construirBotonControl('Ventilador', '🌀', Colors.cyan, 'ventilador'),
              SizedBox(height: 12),
              _construirBotonControl('Lámpara', '💡', Colors.amber, 'lampara'),
            ],
          ),
        ),
      ),
    );
  }

  // Widget para crear tarjetas de sensores
  Widget _construirTarjetaSensor(String nombre, String emoji, Color color) {
    return StreamBuilder<QuerySnapshot>(
      stream: _sensores.where('tipo', isEqualTo: nombre.toLowerCase()).snapshots(),
      builder: (context, snapshot) {
        String valor = 'Cargando...';
        
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          var doc = snapshot.data!.docs.first;
          valor = '${doc['valor']} ${doc['unidad'] ?? ''}';
        }

        return Card(
          elevation: 4,
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              ),
            ),
            child: Row(
              children: [
                Text(emoji, style: TextStyle(fontSize: 32)),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        valor,
                        style: TextStyle(fontSize: 24, color: color, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Widget para crear botones de control
  Widget _construirBotonControl(String nombre, String emoji, Color color, String tipo) {
    return StreamBuilder<QuerySnapshot>(
      stream: _actuadores.where('tipo', isEqualTo: tipo).snapshots(),
      builder: (context, snapshot) {
        bool activo = false;
        String docId = '';
        
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          var doc = snapshot.data!.docs.first;
          activo = doc['activo'] ?? false;
          docId = doc.id;
        }

        return Card(
          elevation: 4,
          child: Container(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _controlarActuador(tipo, !activo, docId),
              style: ElevatedButton.styleFrom(
                backgroundColor: activo ? color : Colors.grey[300],
                foregroundColor: activo ? Colors.white : Colors.black,
                padding: EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(emoji, style: TextStyle(fontSize: 24)),
                  SizedBox(width: 12),
                  Text(
                    '$nombre: ${activo ? "ENCENDIDO" : "APAGADO"}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Función para controlar actuadores
  void _controlarActuador(String tipo, bool nuevoEstado, String docId) {
    if (docId.isEmpty) {
      // Crear documento si no existe
      _actuadores.add({
        'tipo': tipo,
        'activo': nuevoEstado,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } else {
      // Actualizar documento existente
      _actuadores.doc(docId).update({
        'activo': nuevoEstado,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    // Mostrar mensaje
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$tipo ${nuevoEstado ? "activado" : "desactivado"}'),
        backgroundColor: nuevoEstado ? Colors.green : Colors.orange,
      ),
    );
  }
}