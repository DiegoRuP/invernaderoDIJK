class SensorData {
  final double humidity;
  final int lightLevel;
  final bool pumpStatus;
  final int soilMoisture;
  final double temperature;

  SensorData({
    required this.humidity,
    required this.lightLevel,
    required this.pumpStatus,
    required this.soilMoisture,
    required this.temperature,
  });

  // Constructor de fábrica para crear una instancia desde un mapa (Firebase)
  factory SensorData.fromMap(Map<dynamic, dynamic> map) {
    return SensorData(
      humidity: (map['humidity'] as num).toDouble(),
      lightLevel: (map['lightLevel'] as num).toInt(),
      pumpStatus: map['pumpStatus'] as bool,
      soilMoisture: (map['soilMoisture'] as num).toInt(),
      temperature: (map['temperature'] as num).toDouble(),
    );
  }
}