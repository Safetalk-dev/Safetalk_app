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
  });
});
