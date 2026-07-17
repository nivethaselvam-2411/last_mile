// lib/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ride_model.dart';

class FirestoreService {
  FirestoreService._(); // prevent instantiation

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'sharedRides';

  // ── Stream ─────────────────────────────────────────────────────────────────

  /// Real-time stream of pending rides filtered by [vehicleType].
  ///
  /// Requires a composite index on Firestore:
  ///   Collection: sharedRides
  ///   Fields: status ASC, vehicleType ASC, createdAt ASC
  static Stream<List<RideModel>> getPendingRidesStream(String vehicleType) {
    return _db
        .collection(_collection)
        .where('status', isEqualTo: 'pending')
        .where('vehicleType', isEqualTo: vehicleType)
        .snapshots()
        .map((snapshot) {
          final rides = snapshot.docs
              .map((doc) => RideModel.fromFirestore(doc))
              .toList();
          rides.sort((a, b) {
            final aTime = a.createdAt?.millisecondsSinceEpoch ?? 0;
            final bTime = b.createdAt?.millisecondsSinceEpoch ?? 0;
            return aTime.compareTo(bTime);
          });
          return rides;
        });
  }

  // ── Write: Accept ──────────────────────────────────────────────────────────

  /// Accepts a ride using a Firestore Transaction to handle the race condition
  /// where two drivers attempt to accept the same ride simultaneously.
  ///
  /// Throws an [Exception] if the ride is no longer in 'pending' status by the
  /// time the transaction commits (i.e., another driver got there first).
  static Future<void> acceptRide(String rideId, String driverId) async {
    final docRef = _db.collection(_collection).doc(rideId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists) {
        throw Exception('Ride does not exist.');
      }

      final currentStatus = snapshot.data()?['status'] as String?;

      if (currentStatus != 'pending') {
        throw Exception('Ride no longer available.');
      }

      // Atomic write — only one driver will succeed
      transaction.update(docRef, {
        'status': 'accepted',
        'driverId': driverId,
        'acceptedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // ── Write: Complete ────────────────────────────────────────────────────────

  /// Marks a ride as completed and records the server-side timestamp.
  static Future<void> completeRide(String rideId) async {
    await _db.collection(_collection).doc(rideId).update({
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
    });
  }
}
