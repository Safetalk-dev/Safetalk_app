const admin = require('firebase-admin');

// 1. Emulator configurations
process.env.FIRESTORE_EMULATOR_HOST = process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080';
process.env.FIREBASE_AUTH_EMULATOR_HOST = process.env.FIREBASE_AUTH_EMULATOR_HOST || '127.0.0.1:9099';

const projectId = process.env.GCLOUD_PROJECT || 'safetalk-5fa4c';
if (admin.apps.length === 0) {
  admin.initializeApp({ projectId });
}

const db = admin.firestore();

async function runEndToEndSessionLifecycle() {
  console.log('=== SafeTalk End-to-End Session Verification Loop (A0.2) ===');
  
  const seekerId = `seeker_e2e_${Date.now()}`;
  const listenerId = `listener_e2e_${Date.now()}`;

  try {
    // 1. Seed Listener with ISO language standard ('en')
    console.log('[1/6] Seeding available online listener with ISO language code...');
    await db.collection('users').doc(listenerId).set({
      uid: listenerId,
      role: 'listener',
      displayName: 'E2E Test Listener',
      listenerData: {
        isOnline: true,
        status: 'available',
        languagesSpoken: ['en'],
        stats: {
          rating: 5.0,
          minutesListened: 120,
        }
      },
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // 2. Seed Seeker with ISO preferred languages
    console.log('[2/6] Seeding seeker profile...');
    await db.collection('users').doc(seekerId).set({
      uid: seekerId,
      role: 'user',
      displayName: 'E2E Test Seeker',
      seekerData: {
        preferredLanguages: ['en'],
        safeCircle: []
      },
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // 3. Seeker creates Session Request
    console.log('[3/6] Seeker creates session request...');
    const sessionRef = await db.collection('sessions').add({
      seekerId,
      seekerMoniker: 'Serene Stream',
      seekerMoodTag: 'Anxious',
      seekerConcern: 'Stress and overwhelm',
      status: 'pending',
      sessionType: 'messages',
      requestedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    console.log(`Session created with ID: ${sessionRef.id}`);

    // 4. Await Matcher Assignment
    console.log('[4/6] Awaiting auto-match assignment...');
    await new Promise((resolve, reject) => {
      const timeout = setTimeout(() => {
        unsubscribe();
        reject(new Error('Timeout waiting for auto-match Cloud Function trigger'));
      }, 12000);

      const unsubscribe = sessionRef.onSnapshot((snapshot) => {
        const data = snapshot.data();
        if (data && data.listenerId) {
          console.log(`Auto-match assigned listener: ${data.listenerId}`);
          clearTimeout(timeout);
          unsubscribe();
          resolve(data);
        }
      }, (err) => {
        clearTimeout(timeout);
        reject(err);
      });
    });

    // 5. Listener Accepts Session
    console.log('[5/6] Listener accepts session -> payment_pending...');
    await sessionRef.update({
      status: 'payment_pending',
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // 6. Simulate Payment Success -> Active -> Complete
    console.log('[6/6] Advancing session through active and completed phases...');
    await sessionRef.update({
      status: 'active',
      startedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    const activeDoc = await sessionRef.get();
    if (activeDoc.data().status !== 'active') {
      throw new Error(`Expected active status, got ${activeDoc.data().status}`);
    }

    // Complete session
    await sessionRef.update({
      status: 'completed',
      completedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    const completedDoc = await sessionRef.get();
    if (completedDoc.data().status !== 'completed') {
      throw new Error(`Expected completed status, got ${completedDoc.data().status}`);
    }

    console.log('=== All Session Lifecycle Assertions Passed Successfully ===');

    // Clean up
    await sessionRef.delete();
    await db.collection('users').doc(listenerId).delete();
    await db.collection('users').doc(seekerId).delete();

    process.exit(0);
  } catch (error) {
    console.error('E2E Loop Verification failed:', error);
    process.exit(1);
  }
}

runEndToEndSessionLifecycle();
