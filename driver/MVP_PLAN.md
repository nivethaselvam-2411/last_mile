# Shared Auto/Cab Driver App — Flutter MVP Technical Specification

**Author:** Staff Software Engineer
**Deadline:** 4:00 PM (Today)
**Scope:** Single-screen Flutter MVP · Shared Rides · Firebase Firestore · No Auth (hardcoded IDs)

---

## 1. Firestore Schema

### Collection: `sharedRides`

Each document represents ONE shared ride request that may contain multiple passengers.
The backend is responsible for grouping passengers; the driver app only consumes this document.

```
sharedRides/
  {rideId}/
    vehicleType:   String          # "auto" | "cab"
    status:        String          # "pending" | "accepted" | "in_progress" | "completed" | "cancelled"
    pickupHub:     String          # One of the 4 hub constants (see Hubs section)
    dropoffHub:    String          # One of the 4 hub constants (see Hubs section)
    maxSeats:      Number          # 3 for auto, 4 for cab — enforced by backend on grouping
    totalFare:     Number          # Sum of all passenger fareShares (INR)
    driverId:      String | null   # null when pending; set on accept
    acceptedAt:    Timestamp | null
    completedAt:   Timestamp | null
    createdAt:     Timestamp       # Server timestamp

    passengers:    Array<PassengerObject>
      [
        {
          id:        String        # Dummy passenger ID e.g. "passenger_001"
          name:      String        # Display name e.g. "Ravi Kumar"
          fareShare: Number        # This passenger's share of the fare (INR)
        },
        ...                        # Up to maxSeats entries
      ]
```

### Hub Constants

These are the ONLY valid values for `pickupHub` and `dropoffHub`:

| Constant | Human Label |
|---|---|
| HUB_ASHOK_PILLAR | Ashok Pillar |
| HUB_MIOT | MIOT Hospital |
| HUB_DLF | DLF IT Park |
| HUB_SRM | SRM College |

### Seat Capacity Rules (enforced by backend, displayed by driver app)

| vehicleType | maxSeats |
|---|---|
| auto | 3 |
| cab | 4 |

The driver UI displays: `passengers.length / maxSeats seats filled`

### Status Flow

```
  pending
     |
     +--acceptRide()--> accepted --startRide()--> in_progress --completeRide()--> completed
     |
     +--cancel()------> cancelled
```

### Firestore Query Used by Driver

```
db.collection("sharedRides")
  .where("status", isEqualTo: "pending")
  .where("vehicleType", isEqualTo: "auto")   // from AppConstants.vehicleType
  .orderBy("createdAt", descending: false)
  .snapshots()                                // real-time listener
```

> COMPOSITE INDEX REQUIRED — create before writing code:
> Collection: sharedRides | Fields: status ASC, vehicleType ASC, createdAt ASC
> Firebase Console -> Firestore Database -> Indexes -> Create Composite Index

---

## 2. Folder & File Structure

```
driver/
+-- pubspec.yaml
+-- MVP_PLAN.md
|
+-- lib/
|   +-- main.dart                         # Firebase init, MaterialApp, global theme
|   |
|   +-- constants/
|   |   +-- app_constants.dart            # Driver ID, vehicleType, hub map, seat limits
|   |
|   +-- models/
|   |   +-- passenger_model.dart          # PassengerModel (id, name, fareShare)
|   |   +-- ride_model.dart               # RideModel with passengers: List<PassengerModel>
|   |
|   +-- services/
|   |   +-- firestore_service.dart        # getPendingRidesStream, acceptRide, completeRide
|   |
|   +-- screens/
|       +-- driver_home_screen.dart       # Single StatefulWidget screen — all UI & state
|
+-- android/
|   +-- app/src/main/AndroidManifest.xml  # url_launcher <queries> block goes here
+-- ios/
+-- ...
```

### File Responsibilities

| File | Single Responsibility |
|---|---|
| main.dart | Firebase.initializeApp(), run MaterialApp with theme |
| app_constants.dart | All hardcoded values — driver ID, vehicle type, hub labels, seat caps |
| passenger_model.dart | Typed model for a single passenger entry in the array |
| ride_model.dart | Typed model for a sharedRides document; deserialises passengers sub-array |
| firestore_service.dart | Pure data layer — zero UI concerns |
| driver_home_screen.dart | All display logic, state management, user interactions |

---

## 3. State Variables

All state lives in `_DriverHomeScreenState`. No external state manager for MVP.

### 3.1 Driver Identity (never changes at runtime)

| Variable | Type | Value | Description |
|---|---|---|---|
| `_driverId` | `String` | `AppConstants.driverId` | Hardcoded e.g. "driver_auto_001" |
| `_vehicleType` | `String` | `AppConstants.vehicleType` | Hardcoded "auto" or "cab" |
| `_maxSeats` | `int` | `AppConstants.maxSeats` | 3 for auto, 4 for cab |

### 3.2 Online/Offline State

| Variable | Type | Initial | Description |
|---|---|---|---|
| `_isOnline` | `bool` | `false` | Master toggle; controls stream subscription |

### 3.3 Ride Feed State

| Variable | Type | Initial | Description |
|---|---|---|---|
| `_pendingRides` | `List<RideModel>` | `[]` | Live-updating list of available shared rides |
| `_feedSubscription` | `StreamSubscription?` | `null` | Firestore listener handle; cancelled in dispose() |
| `_isLoadingFeed` | `bool` | `false` | True from stream subscribe until first snapshot arrives |

### 3.4 Active Ride State

| Variable | Type | Initial | Description |
|---|---|---|---|
| `_activeRide` | `RideModel?` | `null` | The accepted ride; non-null drives the active ride panel |
| `_isAccepting` | `bool` | `false` | Locks Accept button during Firestore write (prevents double-tap) |
| `_isCompleting` | `bool` | `false` | Locks Complete button during Firestore write |

### 3.5 State Transition Rules

```
_isOnline = false
  -> _feedSubscription cancelled
  -> _pendingRides = []
  -> _activeRide = null
  -> show "You are Offline" full-screen card

_isOnline = true
  -> _feedSubscription active
  -> _pendingRides populates via stream
  -> if _activeRide == null: show rides feed
  -> if _activeRide != null: show active ride panel (hides feed)
```

### 3.6 Derived / Computed Values (not stored in state)

These are calculated inline from existing state — no extra variables needed:

```
seatsDisplay    = "${_activeRide!.passengers.length} / ${_activeRide!.maxSeats} seats"
isFull          = passengers.length >= maxSeats
dropoffHubLabel = AppConstants.hubLabels[ride.dropoffHub]  // e.g. "SRM College"
pickupHubLabel  = AppConstants.hubLabels[ride.pickupHub]
```

---

## 4. Step-by-Step Implementation Plan

---

### Step 1 — Project Setup & Firebase Configuration

**Goal:** Runnable Flutter project with Firebase connected.

**Actions:**
1. Confirm `flutter create driver` or use existing project.
2. Add to `pubspec.yaml`:

```
dependencies:
  firebase_core: ^3.x.x
  cloud_firestore: ^5.x.x
  url_launcher: ^6.x.x
```

3. Run `flutter pub get`.
4. Install FlutterFire CLI and run `flutterfire configure`:
   - `dart pub global activate flutterfire_cli`
   - `flutterfire configure` -> select Firebase project -> auto-generates firebase_options.dart
5. Place `google-services.json` in `android/app/` and `GoogleService-Info.plist` in `ios/Runner/`.
6. In `android/app/src/main/AndroidManifest.xml`, add inside `<manifest>`:

```xml
<queries>
  <intent>
    <action android:name="android.intent.action.VIEW" />
    <data android:scheme="https" />
  </intent>
  <intent>
    <action android:name="android.intent.action.VIEW" />
    <data android:scheme="geo" />
  </intent>
</queries>
```

7. Create the Firestore composite index (see Section 1).

**Exit Criteria:** `flutter run` boots without crash; "Firebase initialized" visible in debug console.

---

### Step 2 — Constants, Models & Service Layer

**Goal:** Complete data layer before touching UI.

**Sub-step 2a — app_constants.dart**
- `driverId = "driver_auto_001"`
- `vehicleType = "auto"`
- `maxSeats = 3` (or 4 for cab)
- `hubLabels = { "HUB_ASHOK_PILLAR": "Ashok Pillar", "HUB_MIOT": "MIOT Hospital", "HUB_DLF": "DLF IT Park", "HUB_SRM": "SRM College" }`

**Sub-step 2b — passenger_model.dart**
- Fields: `id`, `name`, `fareShare`
- Factory: `PassengerModel.fromMap(Map<String, dynamic> map)`

**Sub-step 2c — ride_model.dart**
- Fields: `id`, `vehicleType`, `status`, `pickupHub`, `dropoffHub`, `maxSeats`, `totalFare`, `driverId`, `passengers`, `createdAt`, `acceptedAt`, `completedAt`
- Factory: `RideModel.fromFirestore(DocumentSnapshot doc)`
  - Deserialise `passengers` as `(doc['passengers'] as List).map((p) => PassengerModel.fromMap(p)).toList()`
- Computed getter: `int get filledSeats => passengers.length`
- Computed getter: `bool get isFull => passengers.length >= maxSeats`

**Sub-step 2d — firestore_service.dart**

```
Stream<List<RideModel>> getPendingRidesStream(String vehicleType)
  -> .where("status", isEqualTo: "pending")
  -> .where("vehicleType", isEqualTo: vehicleType)
  -> .orderBy("createdAt", descending: false)
  -> .snapshots() mapped to List<RideModel>

Future<void> acceptRide(String rideId, String driverId)
  -> Firestore Transaction:
     1. Read document
     2. If status != "pending" -> throw Exception("Ride no longer available")
     3. Write: status="accepted", driverId=driverId, acceptedAt=FieldValue.serverTimestamp()

Future<void> completeRide(String rideId)
  -> Update: status="completed", completedAt=FieldValue.serverTimestamp()
```

> CRITICAL: acceptRide uses a Transaction to handle the race condition where two drivers
> tap Accept on the same ride simultaneously. Only one will win. The loser's UI shows a SnackBar.

**Exit Criteria:** All classes compile. Call acceptRide manually in a test and verify Firestore Console shows the updated document.

---

### Step 3 — UI Shell (Static, No Logic)

**Goal:** Build all visual regions with hardcoded/dummy data; zero Firestore wiring yet.

**AppBar:**
- Left: App name "AutoShare Driver"
- Right: `Switch` widget (online/offline toggle) with a colored label

**Offline State (full-screen):**
- Large icon (e.g., Icons.wifi_off)
- Text: "You are Offline"
- Subtext: "Toggle the switch to start receiving rides"

**Online - Feed View (_activeRide == null):**
- Section header: "Available Rides (N)"
- `ListView.builder` of `RideCard` widgets

**RideCard Widget layout:**
```
+------------------------------------------+
| [HUB LABEL] -> [HUB LABEL]    auto       |
| Passengers: Ravi, Priya      2/3 seats   |
| Total Fare: Rs. 170          4.2 km      |
|       [ Accept Ride ]                    |
+------------------------------------------+
```

**Online - Active Ride View (_activeRide != null):**
- Full card showing:
  - Route: pickupHubLabel -> dropoffHubLabel
  - Seats: "2 / 3 seats filled"
  - Passenger names list
  - Total Fare: Rs. X
  - Button: "Navigate to Dropoff" (primary, full-width)
  - Button: "Complete Ride" (success color, full-width)

**Exit Criteria:** Both views render correctly with hardcoded dummy data; no logic connected.

---

### Step 4 — Wire State & Firestore Logic

**Goal:** Connect all UI interactions to FirestoreService and setState.

**4.1 Toggle Online/Offline:**
```
onChanged(bool value):
  if value == true:
    setState(_isOnline = true, _isLoadingFeed = true)
    _feedSubscription = FirestoreService.getPendingRidesStream(vehicleType).listen((rides):
      setState(_pendingRides = rides, _isLoadingFeed = false)
    )
  else:
    _feedSubscription?.cancel()
    setState(_isOnline = false, _pendingRides = [], _activeRide = null)
```

**4.2 Accept Ride:**
```
onAcceptTap(RideModel ride):
  setState(_isAccepting = true)
  try:
    await FirestoreService.acceptRide(ride.id, _driverId)
    setState(_activeRide = ride, _isAccepting = false)
  catch (e):
    setState(_isAccepting = false)
    ScaffoldMessenger.showSnackBar("Ride no longer available")
```

**4.3 Navigate to Dropoff:**
```
onNavigateTap():
  // Navigate to the dropoff hub using its name as a search query
  final query = Uri.encodeComponent(AppConstants.hubLabels[_activeRide!.dropoffHub]!)
  final uri = Uri.parse("https://www.google.com/maps/search/?api=1&query=$query")
  launchUrl(uri, mode: LaunchMode.externalApplication)
```

**4.4 Complete Ride:**
```
onCompleteTap():
  setState(_isCompleting = true)
  try:
    await FirestoreService.completeRide(_activeRide!.id)
    setState(_activeRide = null, _isCompleting = false)
  catch (e):
    setState(_isCompleting = false)
    ScaffoldMessenger.showSnackBar("Error completing ride. Please try again.")
```

**4.5 dispose():**
```
_feedSubscription?.cancel()
super.dispose()
```

**Exit Criteria:** Full end-to-end flow works: toggle on -> ride appears -> accept -> navigate -> complete -> feed returns.

---

### Step 5 — Seed Test Data & Validation

**Goal:** Confirm real-time stream, seat display, and full flow with live Firestore documents.

Add the sample documents from Section 5 below in Firebase Console.

**Validation Checklist:**
- [ ] Toggle online -> both sample rides appear immediately
- [ ] RideCard shows "2 / 3 seats" for the auto ride
- [ ] Accept ride #1 -> active panel appears with passenger names and total fare
- [ ] Tap Navigate -> Google Maps opens to SRM College
- [ ] Tap Complete -> active panel disappears, feed returns
- [ ] Accept ride #1 from a second device simultaneously -> one gets SnackBar "no longer available"

---

### Step 6 — Polish & Error Handling

**Goal:** Demo-ready, no white screens, no unhandled exceptions.

1. Loading state: show `CircularProgressIndicator` while `_isLoadingFeed == true`
2. Empty state: "No rides available right now" widget when `_pendingRides.isEmpty`
3. Disable Accept button (`onPressed: null`) when `_isAccepting == true`
4. Disable Complete button (`onPressed: null`) when `_isCompleting == true`
5. Wrap all async calls in try/catch with SnackBar feedback
6. Test url_launcher on a real Android device (emulator may not have Maps)

**Exit Criteria:** No crashes during a full walkthrough demo with any edge case input.

---

## 5. Sample Firestore Test Documents

### Document 1 — 2 Passengers, Auto, Ashok Pillar -> SRM

```json
{
  "vehicleType": "auto",
  "status": "pending",
  "pickupHub": "HUB_ASHOK_PILLAR",
  "dropoffHub": "HUB_SRM",
  "maxSeats": 3,
  "totalFare": 170.0,
  "driverId": null,
  "acceptedAt": null,
  "completedAt": null,
  "createdAt": "<FieldValue.serverTimestamp()>",
  "passengers": [
    {
      "id": "passenger_001",
      "name": "Ravi Kumar",
      "fareShare": 85.0
    },
    {
      "id": "passenger_002",
      "name": "Priya Nair",
      "fareShare": 85.0
    }
  ]
}
```

> Note: maxSeats=3, passengers.length=2 -> driver UI shows "2 / 3 seats filled"
> totalFare = 85 + 85 = 170 (consistent)

### Document 2 — 3 Passengers (Full Auto), MIOT -> DLF

```json
{
  "vehicleType": "auto",
  "status": "pending",
  "pickupHub": "HUB_MIOT",
  "dropoffHub": "HUB_DLF",
  "maxSeats": 3,
  "totalFare": 210.0,
  "driverId": null,
  "acceptedAt": null,
  "completedAt": null,
  "createdAt": "<FieldValue.serverTimestamp()>",
  "passengers": [
    {
      "id": "passenger_003",
      "name": "Arjun Menon",
      "fareShare": 70.0
    },
    {
      "id": "passenger_004",
      "name": "Sneha Rao",
      "fareShare": 70.0
    },
    {
      "id": "passenger_005",
      "name": "Karthik S",
      "fareShare": 70.0
    }
  ]
}
```

> Note: passengers.length=3 == maxSeats=3 -> isFull=true; UI can show a "FULL" badge

---

## 6. Risk Register & Mitigations

| Risk | Likelihood | Mitigation |
|---|---|---|
| Composite index missing | High | Create index in Step 1 before any code; takes ~60 seconds |
| Two drivers accept same ride | High | Firestore Transaction in acceptRide() — read-verify-write atomically |
| url_launcher crash on Android | Medium | Add <queries> block to AndroidManifest.xml |
| google-services.json misconfigured | Medium | Use flutterfire configure CLI — never copy-paste |
| passengers array not deserialising | Medium | Cast explicitly: (doc["passengers"] as List<dynamic>) |
| Hot reload loses stream subscription | Low | Full restart; dispose() always cancels subscription |

---

## 7. Definition of Done (MVP)

- [ ] Driver toggles online/offline
- [ ] Pending shared rides appear in real time, filtered by vehicleType
- [ ] Each RideCard shows seat fill count (e.g. 2/3) and passenger names
- [ ] Accept ride uses a Firestore Transaction (race condition safe)
- [ ] "Navigate to Dropoff" opens Google Maps to the dropoff hub by name
- [ ] "Complete Ride" marks the ride complete and returns to feed
- [ ] Empty state shown when no rides are available
- [ ] Loading state shown while stream initialises
- [ ] All errors caught and shown as SnackBars (no white screens)
- [ ] Tested end-to-end on a physical or emulated device
