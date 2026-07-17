// lib/models/ride_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'passenger_model.dart';

class RideModel {
  final String id;
  final String vehicleType;
  final String status;
  final String pickupHub;
  final String dropoffHub;
  final int maxSeats;
  final double totalFare;
  final String? driverId;
  final List<PassengerModel> passengers;
  final Timestamp? createdAt;
  final Timestamp? acceptedAt;
  final Timestamp? completedAt;

  const RideModel({
    required this.id,
    required this.vehicleType,
    required this.status,
    required this.pickupHub,
    required this.dropoffHub,
    required this.maxSeats,
    required this.totalFare,
    required this.passengers,
    this.driverId,
    this.createdAt,
    this.acceptedAt,
    this.completedAt,
  });

  // ── Computed Getters ───────────────────────────────────────────────────────

  /// Number of seats currently occupied.
  int get filledSeats => passengers.length;

  /// True when the ride has no more available seats.
  bool get isFull => passengers.length >= maxSeats;

  // ── Deserialisation ────────────────────────────────────────────────────────

  /// Build a [RideModel] from a Firestore [DocumentSnapshot].
  /// CRITICAL: totalFare and fareShare fields may come back as int OR double
  /// from Firestore. Always cast through `num` to avoid runtime type errors.
  factory RideModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Deserialise passengers sub-array
    final rawPassengers = (data['passengers'] as List<dynamic>? ?? []);
    final passengers = rawPassengers
        .map((p) => PassengerModel.fromMap(p as Map<String, dynamic>))
        .toList();

    return RideModel(
      id: doc.id,
      vehicleType: data['vehicleType'] as String? ?? 'auto',
      status: data['status'] as String? ?? 'pending',
      pickupHub: data['pickupHub'] as String? ?? '',
      dropoffHub: data['dropoffHub'] as String? ?? '',
      // maxSeats from Firestore is always an integer Number
      maxSeats: (data['maxSeats'] as num?)?.toInt() ?? 3,
      // totalFare must go through num to survive int/double ambiguity
      totalFare: (data['totalFare'] as num).toDouble(),
      driverId: data['driverId'] as String?,
      passengers: passengers,
      createdAt: data['createdAt'] as Timestamp?,
      acceptedAt: data['acceptedAt'] as Timestamp?,
      completedAt: data['completedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() => {
        'vehicleType': vehicleType,
        'status': status,
        'pickupHub': pickupHub,
        'dropoffHub': dropoffHub,
        'maxSeats': maxSeats,
        'totalFare': totalFare,
        'driverId': driverId,
        'passengers': passengers.map((p) => p.toMap()).toList(),
        'createdAt': createdAt,
        'acceptedAt': acceptedAt,
        'completedAt': completedAt,
      };

  @override
  String toString() =>
      'RideModel(id: $id, route: $pickupHub->$dropoffHub, seats: $filledSeats/$maxSeats, status: $status)';
}
