/// Vehicle model (from /api/profile/vehicle endpoints).
class Vehicle {
  final String id;
  final String ownerId;
  final String make;
  final String model;
  final String color;
  final String registrationNo;
  final int seatCapacity;
  final DateTime? createdAt;

  const Vehicle({
    required this.id,
    required this.ownerId,
    required this.make,
    required this.model,
    required this.color,
    required this.registrationNo,
    required this.seatCapacity,
    this.createdAt,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] ?? '',
      ownerId: json['owner_id'] ?? '',
      make: json['make'] ?? '',
      model: json['model'] ?? '',
      color: json['color'] ?? '',
      registrationNo: json['registration_no'] ?? '',
      seatCapacity: json['seat_capacity'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'make': make,
      'model': model,
      'color': color,
      'registration_no': registrationNo,
      'seat_capacity': seatCapacity,
    };
  }

  /// Display name like "Toyota Innova"
  String get displayName => '$make $model';

  Vehicle copyWith({
    String? id,
    String? ownerId,
    String? make,
    String? model,
    String? color,
    String? registrationNo,
    int? seatCapacity,
    DateTime? createdAt,
  }) {
    return Vehicle(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      make: make ?? this.make,
      model: model ?? this.model,
      color: color ?? this.color,
      registrationNo: registrationNo ?? this.registrationNo,
      seatCapacity: seatCapacity ?? this.seatCapacity,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
