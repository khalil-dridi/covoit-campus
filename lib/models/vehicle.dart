class Vehicle {
  final int? id;
  final int userId;
  final String brand;
  final String model;
  final String? color;
  final String licensePlate;
  final int seats;
  final String? createdAt;

  const Vehicle({
    this.id,
    required this.userId,
    required this.brand,
    required this.model,
    this.color,
    required this.licensePlate,
    required this.seats,
    this.createdAt,
  });

  factory Vehicle.fromMap(Map<String, Object?> map) {
    return Vehicle(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      brand: map['brand'] as String,
      model: map['model'] as String,
      color: map['color'] as String?,
      licensePlate: map['license_plate'] as String,
      seats: map['seats'] as int,
      createdAt: map['created_at'] as String?,
    );
  }

  Map<String, Object?> toMap() => {
        'user_id': userId,
        'brand': brand,
        'model': model,
        'color': color,
        'license_plate': licensePlate,
        'seats': seats,
        'created_at': createdAt?.trim().isNotEmpty == true
            ? createdAt!.trim()
            : DateTime.now().toIso8601String(),
      };
}