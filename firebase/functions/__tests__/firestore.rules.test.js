const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const fs = require('fs');

let testEnv;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: "demo-safetalk",
    firestore: {
      rules: fs.readFileSync("../../firestore.rules", "utf8"),
      host: "127.0.0.1",
      port: 8080,
    },
  });
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

afterAll(async () => {
  await testEnv.cleanup();
});

describe("SafeTalk Firestore Security Rules", () => {

  describe("Users Collection", () => {
    it("allows a user to read their own profile", async () => {
      const alice = testEnv.authenticatedContext("alice");
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection("users").doc("alice").set({ role: "user" });
      });

      const db = alice.firestore();
      await assertSucceeds(db.collection("users").doc("alice").get());
    });

    it("denies a user from reading another user's profile if they are not a listener", async () => {
      const alice = testEnv.authenticatedContext("alice");
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection("users").doc("bob").set({ role: "user" });
      });

      const db = alice.firestore();
      await assertFails(db.collection("users").doc("bob").get());
    });

    it("allows any authenticated user to read a listener's profile", async () => {
      const alice = testEnv.authenticatedContext("alice");
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection("users").doc("charlie").set({ role: "listener" });
      });

      const db = alice.firestore();
      await assertSucceeds(db.collection("users").doc("charlie").get());
    });
  });

  describe("Sessions Collection", () => {
    it("allows participants to read a session", async () => {
      const alice = testEnv.authenticatedContext("alice");
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection("sessions").doc("session1").set({
          seekerId: "alice",
          listenerId: "bob",
        });
      });

      const db = alice.firestore();
      await assertSucceeds(db.collection("sessions").doc("session1").get());
    });

    it("denies non-participants from reading a session", async () => {
      const charlie = testEnv.authenticatedContext("charlie");
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection("sessions").doc("session1").set({
          seekerId: "alice",
          listenerId: "bob",
        });
      });

      const db = charlie.firestore();
      await assertFails(db.collection("sessions").doc("session1").get());
    });

    it("allows seeker to create session with status pending", async () => {
      const alice = testEnv.authenticatedContext("alice");
      const db = alice.firestore();
      await assertSucceeds(db.collection("sessions").doc("session1").set({
        seekerId: "alice",
        status: "pending",
        sessionType: "messages"
      }));
    });

    it("denies seeker from creating session with status active", async () => {
      const alice = testEnv.authenticatedContext("alice");
      const db = alice.firestore();
      await assertFails(db.collection("sessions").doc("session1").set({
        seekerId: "alice",
        status: "active",
        sessionType: "messages"
      }));
    });

    it("denies user from creating session for another seeker", async () => {
      const eve = testEnv.authenticatedContext("eve");
      const db = eve.firestore();
      await assertFails(db.collection("sessions").doc("session1").set({
        seekerId: "alice",
        status: "pending",
        sessionType: "messages"
      }));
    });

    it("denies client write to status active during update (A2.3)", async () => {
      const alice = testEnv.authenticatedContext("alice");
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection("sessions").doc("session1").set({
          seekerId: "alice",
          listenerId: "bob",
          status: "payment_pending"
        });
      });

      const db = alice.firestore();
      await assertFails(db.collection("sessions").doc("session1").update({
        status: "active"
      }));
    });

    it("denies client revival of completed session back to active (A2.2)", async () => {
      const alice = testEnv.authenticatedContext("alice");
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection("sessions").doc("session1").set({
          seekerId: "alice",
          listenerId: "bob",
          status: "completed"
        });
      });

      const db = alice.firestore();
      await assertFails(db.collection("sessions").doc("session1").update({
        status: "active"
      }));
    });

    it("allows assigned listener to transition pending to payment_pending", async () => {
      const bob = testEnv.authenticatedContext("bob");
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection("sessions").doc("session1").set({
          seekerId: "alice",
          listenerId: "bob",
          status: "pending"
        });
      });

      const db = bob.firestore();
      await assertSucceeds(db.collection("sessions").doc("session1").update({
        status: "payment_pending"
      }));
    });

    it("denies client session deletion", async () => {
      const alice = testEnv.authenticatedContext("alice");
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection("sessions").doc("session1").set({
          seekerId: "alice",
          listenerId: "bob",
          status: "pending"
        });
      });

      const db = alice.firestore();
      await assertFails(db.collection("sessions").doc("session1").delete());
    });
  });

  describe("Notifications & Mood Subcollections (A4.1, A4.5)", () => {
    it("allows a user to read and write their own notifications", async () => {
      const alice = testEnv.authenticatedContext("alice");
      const db = alice.firestore();
      const notifRef = db.collection("users").doc("alice").collection("notifications").doc("notif1");

      await assertSucceeds(notifRef.set({ title: "Alert", body: "Hello", read: false }));
      await assertSucceeds(notifRef.get());
      await assertSucceeds(notifRef.update({ read: true }));
      await assertSucceeds(notifRef.delete());
    });

    it("denies another user from reading or writing a user's notifications", async () => {
      const bob = testEnv.authenticatedContext("bob");
      const db = bob.firestore();
      const notifRef = db.collection("users").doc("alice").collection("notifications").doc("notif1");

      await assertFails(notifRef.get());
      await assertFails(notifRef.set({ title: "Sneaky" }));
    });

    it("allows a user to read and write their own mood check-ins", async () => {
      const alice = testEnv.authenticatedContext("alice");
      const db = alice.firestore();
      const moodRef = db.collection("users").doc("alice").collection("mood_checkins").doc("mood1");

      await assertSucceeds(moodRef.set({ score: 7.0, graphScore: 0.7 }));
      await assertSucceeds(moodRef.get());
    });

    it("denies another user from reading a user's mood check-ins", async () => {
      const bob = testEnv.authenticatedContext("bob");
      const db = bob.firestore();
      const moodRef = db.collection("users").doc("alice").collection("mood_checkins").doc("mood1");

      await assertFails(moodRef.get());
    });
  });
});
