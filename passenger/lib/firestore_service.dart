// ─────────────────────────────────────────────────────────────────────────────
// firestore_service.dart
// Single-responsibility service for all Firestore reads and writes.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_constants.dart';
import 'models.dart';

class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── rideRequests ────────────────────────────────────────────────────────

  /// Creates a new ride request document and returns its auto-generated ID.
  /// Status is set to [kStatusSearching] on creation.
  Future<String> createRideRequest({
    required String pickupHub,
    required String dropoffHub,
    required String vehiclePreference,
  }) async {
    final docRef = _db.collection(kCollectionSharedRides).doc();
    await docRef.set({
      'rideId': docRef.id,
      'status': 'pending', // Driver expects 'pending'
      'vehicleType': vehiclePreference,
      'pickupHub': pickupHub,
      'dropoffHub': dropoffHub,
      'maxSeats': vehiclePreference == 'auto' ? 3 : 4,
      'totalFare': 150.0,
      'driverId': null,
      'passengerIds': [kPassengerId], // For passenger app to query
      'passengers': [
        {
          'id': kPassengerId, // For driver app
          'passengerId': kPassengerId, // For passenger app
          'name': kPassengerName, // For driver app
          'passengerName': kPassengerName, // For passenger app
          'fareShare': 150.0,
        }
      ],
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  /// Updates the status of a ride request to [kStatusCancelled].
  Future<void> cancelRideRequest(String requestId) async {
    await _db
        .collection(kCollectionSharedRides)
        .doc(requestId)
        .update({'status': kStatusCancelled});
  }

  // ─── sharedRides ─────────────────────────────────────────────────────────

  /// Returns a real-time stream of [SharedRide] documents that contain this
  /// passenger, filtered to only active statuses (pending | accepted).
  ///
  /// Uses `arrayContains` on the flat [passengerIds] field — Firestore does
  /// not support `arrayContains` on nested object fields.
  Stream<List<SharedRide>> listenToSharedRides(String passengerId) {
    return _db
        .collection(kCollectionSharedRides)
        .where('passengerIds', arrayContains: passengerId)
        .where('status', whereIn: [kStatusPending, kStatusAccepted])
        .snapshots()
        .map((snapshot) {
          final rides = snapshot.docs
              .map((doc) => SharedRide.fromDoc(doc))
              .toList();

          // Sort descending by createdAt so rides.first is the most recent.
          rides.sort((a, b) {
            final aTime = a.createdAt?.millisecondsSinceEpoch ?? 0;
            final bTime = b.createdAt?.millisecondsSinceEpoch ?? 0;
            return bTime.compareTo(aTime);
          });

          return rides;
        });
  }
}
