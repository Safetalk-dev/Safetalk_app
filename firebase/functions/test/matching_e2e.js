const admin = require('firebase-admin');

// Initialize admin SDK pointing to the emulator
process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080';
process.env.FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9099';
admin.initializeApp({ projectId: 'safetalk-5fa4c' });

const db = admin.firestore();

async function runTest() {
  console.log('Starting E2E Matching Flow Test...');
  const seekerId = 'test_seeker_admin';
  const listenerId = 'test_listener_admin';
  
  // 1. Setup Dummy Listener
  await db.collection('users').doc(listenerId).set({
    uid: listenerId,
    role: 'listener',
    listenerData: {
      isOnline: true,
      languagesSpoken: ['English']
    }
  });
  console.log(`Created listener: ${listenerId}`);

  // 2. Seeker creates session
  const sessionRef = await db.collection('sessions').add({
    seekerId: seekerId,
    seekerMoniker: 'Sad Panda',
    status: 'pending',
    sessionType: 'SessionType.messages',
    requestedAt: admin.firestore.FieldValue.serverTimestamp()
  });
  console.log(`Created session: ${sessionRef.id}`);

  // 3. Wait for Cloud Function to auto-match
  console.log('Waiting for Cloud Function auto-match...');
  let matchedSession = null;
  
  // Create a promise that resolves when the session is updated with listenerId
  await new Promise((resolve, reject) => {
    const unsubscribe = sessionRef.onSnapshot((doc) => {
      const data = doc.data();
      if (data && data.listenerId) {
        matchedSession = data;
        unsubscribe();
        resolve();
      }
    }, reject);
    
    // Timeout after 10 seconds
    setTimeout(() => {
      unsubscribe();
      reject(new Error('Timeout waiting for auto-match'));
    }, 10000);
  });
  
  console.log(`Cloud Function assigned listener: ${matchedSession.listenerId}`);
  if (matchedSession.listenerId !== listenerId) {
    throw new Error('Assigned listener ID does not match expected listener ID!');
  }

  // 4. Listener Accepts
  console.log('Simulating listener acceptance...');
  await sessionRef.update({
    status: 'payment_pending'
  });
  
  // 5. Verification
  const finalDoc = await sessionRef.get();
  if (finalDoc.data().status === 'payment_pending') {
    console.log('SUCCESS: Session advanced to payment_pending!');
  } else {
    throw new Error('Failed to advance to payment_pending');
  }

  // Cleanup
  await sessionRef.delete();
  await db.collection('users').doc(listenerId).delete();
  
  console.log('Test completed successfully.');
  process.exit(0);
}

runTest().catch(err => {
  console.error('Test failed:', err);
  process.exit(1);
});
