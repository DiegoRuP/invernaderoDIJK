class SensorData {
  final double humidity;
  final int lightLevel;
  final bool pumpStatus;   // Estado físico del relé (true si está regando)
  final int soilMoisture;
  final double temperature;
  final String pumpMode;   // Modo actual ("auto" o "manual")
  final int timestamp;     // Timestamp Unix real

  const SensorData({
    required this.humidity,
    required this.lightLevel,
    required this.pumpStatus,
    required this.soilMoisture,
    required this.temperature,
    required this.pumpMode,
    required this.timestamp,
  });

  factory SensorData.fromMap(Map<dynamic, dynamic> map) {
    return SensorData(
      humidity: (map['humidity'] as num? ?? 0).toDouble(),
      lightLevel: (map['lightLevel'] as num? ?? 0).toInt(),
      pumpStatus: map['pumpStatus'] as bool? ?? false,
      soilMoisture: (map['soilMoisture'] as num? ?? 0).toInt(),
      temperature: (map['temperature'] as num? ?? 0).toDouble(),
      pumpMode: map['pumpMode'] as String? ?? 'auto',
      timestamp: (map['timestamp'] as num? ?? 0).toInt(),
    );
  }
  
  @override
  List<Object?> get props => [
        humidity,
        lightLevel,
        pumpStatus,
        soilMoisture,
        temperature,
        pumpMode,
        timestamp,
      ];
}