const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

// 1. Initialize firebase-admin
// Assuming the service account key is saved locally as 'serviceAccountKey.json'
const serviceAccount = require('./serviceAccountKey.json');

initializeApp({
  credential: cert(serviceAccount)
});

const db = getFirestore();

console.log("🚕 Matching engine started. Listening for ride requests...");

// 2. Listen to 'rideRequests' where status == 'searching' using a realtime snapshot listener
db.collection('rideRequests')
  .where('status', '==', 'searching')
  .onSnapshot(async (snapshot) => {
    if (snapshot.empty) {
      return;
    }

    console.log(`\n[${new Date().toISOString()}] Snapshot updated: ${snapshot.docs.length} searching requests.`);

    // 3. Group requests by an exact match of (pickupHub + dropoffHub + vehiclePreference)
    const groups = {};

    snapshot.docs.forEach(doc => {
      const data = doc.data();
      // Create a unique key for grouping
      const key = `${data.pickupHub}|${data.dropoffHub}|${data.vehiclePreference}`;

      if (!groups[key]) {
        groups[key] = [];
      }
      groups[key].push({ docId: doc.id, ...data });
    });

    // 4. Process groups to find matches
    for (const [key, reqs] of Object.entries(groups)) {
      // Sort by timestamp if available to match earlier requests first
      reqs.sort((a, b) => {
        const tA = a.timestamp && typeof a.timestamp.toMillis === 'function' ? a.timestamp.toMillis() : 0;
        const tB = b.timestamp && typeof b.timestamp.toMillis === 'function' ? b.timestamp.toMillis() : 0;
        return tA - tB;
      });

      const sample = reqs[0];
      const vehiclePref = sample.vehiclePreference;

      // Determine required group size based on preference
      const maxSeats = vehiclePref === 'auto' ? 3 : (vehiclePref === 'cab' ? 4 : null);

      if (!maxSeats) continue; // Skip if invalid vehicle preference

      // Check if a group has reached the required capacity
      while (reqs.length >= maxSeats) {
        const matchedRequests = reqs.splice(0, maxSeats);
        const groupSize = matchedRequests.length;

        console.log(`✅ Match formed! [${vehiclePref.toUpperCase()}] ${sample.pickupHub} -> ${sample.dropoffHub}`);
        console.log(`Passengers: ${matchedRequests.map(r => r.passengerId).join(', ')}`);

        try {
          // Perform a Firestore Batch write
          const batch = db.batch();

          // Create the new sharedRide document reference
          const sharedRideRef = db.collection('sharedRides').doc();

          // Prepare passenger data
          const passengers = matchedRequests.map(r => ({
            id: r.passengerId,
            name: r.name || 'Unknown', // Fallback in case name isn't stored in rideRequests
            fareShare: 40
          }));

          const passengerIds = matchedRequests.map(r => r.passengerId);

          const sharedRideData = {
            status: 'pending',
            pickupHub: sample.pickupHub,
            dropoffHub: sample.dropoffHub,
            vehicleType: vehiclePref,
            maxSeats: maxSeats,
            totalFare: groupSize * 40,
            passengers: passengers,
            passengerIds: passengerIds,
            createdAt: FieldValue.serverTimestamp()
          };

          // Add the sharedRide creation to the batch
          batch.set(sharedRideRef, sharedRideData);

          // Update the status of each matched rideRequest to 'matched'
          matchedRequests.forEach(r => {
            const reqRef = db.collection('rideRequests').doc(r.docId);
            batch.update(reqRef, { status: 'matched' });
          });

          // Commit the batch write
          await batch.commit();
          console.log(`🎉 Successfully created sharedRide ID: ${sharedRideRef.id} and updated request statuses.`);
        } catch (error) {
          console.error("❌ Error committing match batch:", error);
        }
      }
    }
  }, err => {
    console.error("❌ Error listening to rideRequests:", err);
  });
