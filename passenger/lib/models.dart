// ─────────────────────────────────────────────────────────────────────────────
// models.dart
// Data models for rideRequests and sharedRides documents.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';

// ─── PassengerEntry ──────────────────────────────────────────────────────────

class PassengerEntry {
  final String passengerId;
  final String passengerName;

  const PassengerEntry({
    required this.passengerId,
    required this.passengerName,
  });

  factory PassengerEntry.fromMap(Map<String, dynamic> map) {
    return PassengerEntry(
      passengerId: map['passengerId'] as String? ?? '',
      passengerName: map['passengerName'] as String? ?? '',
    );
  }
}

// ─── SharedRide ──────────────────────────────────────────────────────────────

class SharedRide {
  final String rideId;
  final List<String> passengerIds;
  final List<PassengerEntry> passengers;
  final String status;

  /// CRITICAL: parsed via (num).toDouble() to prevent Firestore type crashes
  /// when the driver app stores the value as int vs double.
  final double totalFare;

  final String driverId;
  final String vehicleType;
  final String pickupHub;
  final String dropoffHub;
  final Timestamp? createdAt;

  const SharedRide({
    required this.rideId,
    required this.passengerIds,
    required this.passengers,
    required this.status,
    required this.totalFare,
    required this.driverId,
    required this.vehicleType,
    required this.pickupHub,
    required this.dropoffHub,
    this.createdAt,
  });

  /// Fare split equally among all passengers in this ride.
  double get fareShare =>
      passengers.isEmpty ? totalFare : totalFare / passengers.length;

  factory SharedRide.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;

    // Safe flat array parse
    final List<String> passengerIds = (map['passengerIds'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [];

    // Safe object array parse
    final List<PassengerEntry> passengers =
        (map['passengers'] as List<dynamic>?)
                ?.whereType<Map<String, dynamic>>()
                .map(PassengerEntry.fromMap)
                .toList() ??
            [];

    return SharedRide(
      rideId: doc.id,
      passengerIds: passengerIds,
      passengers: passengers,
      status: map['status'] as String? ?? '',
      // CRITICAL: use (as num).toDouble() to handle int or double from Firestore
      totalFare: (map['totalFare'] as num? ?? 0).toDouble(),
      driverId: map['driverId'] as String? ?? '',
      vehicleType: map['vehicleType'] as String? ?? '',
      pickupHub: map['pickupHub'] as String? ?? '',
      dropoffHub: map['dropoffHub'] as String? ?? '',
      createdAt: map['createdAt'] as Timestamp?,
    );
  }
}
