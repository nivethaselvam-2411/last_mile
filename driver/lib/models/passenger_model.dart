// lib/models/passenger_model.dart

class PassengerModel {
  final String id;
  final String name;
  final double fareShare;

  const PassengerModel({
    required this.id,
    required this.name,
    required this.fareShare,
  });

  /// Deserialise from a Firestore passengers sub-document map.
  /// CRITICAL: fareShare is stored as a Firestore Number which can be int or
  /// double. Always cast via `(value as num).toDouble()` to avoid type errors.
  factory PassengerModel.fromMap(Map<String, dynamic> map) {
    return PassengerModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Unknown',
      fareShare: (map['fareShare'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'fareShare': fareShare,
      };

  @override
  String toString() => 'PassengerModel(id: $id, name: $name, fare: ₹$fareShare)';
}
