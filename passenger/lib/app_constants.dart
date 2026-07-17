// ─────────────────────────────────────────────────────────────────────────────
// app_constants.dart
// All hard-coded values and magic strings for the Passenger MVP.
// ─────────────────────────────────────────────────────────────────────────────

/// Hardcoded passenger identity (no Auth in MVP).
const String kPassengerId = 'pass_001';
const String kPassengerName = 'Student 1';

/// Firestore collection names.
const String kCollectionRideRequests = 'rideRequests';
const String kCollectionSharedRides = 'sharedRides';

/// Hub identifiers — must match exactly what the driver app uses.
const List<String> kHubs = [
  'HUB_ASHOK_PILLAR',
  'HUB_MIOT',
  'HUB_DLF',
  'HUB_SRM',
];

/// Human-readable display labels for each hub constant.
const Map<String, String> kHubDisplayNames = {
  'HUB_ASHOK_PILLAR': 'Ashok Pillar',
  'HUB_MIOT': 'MIOT Hospital',
  'HUB_DLF': 'DLF IT Park',
  'HUB_SRM': 'SRM College',
};

/// Vehicle type constants.
const String kVehicleAuto = 'auto';
const String kVehicleCab = 'cab';
const int kMaxAutoCapacity = 3;
const int kMaxCabCapacity = 4;

/// rideRequests status values.
const String kStatusSearching = 'searching';
const String kStatusCancelled = 'cancelled';

/// sharedRides status values.
const String kStatusPending = 'pending';
const String kStatusAccepted = 'accepted';
const String kStatusCompleted = 'completed';
