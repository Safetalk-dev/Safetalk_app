process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";
const admin = require("firebase-admin");
const projectId = process.env.GCLOUD_PROJECT || "demo-safetalk";
const test = require("firebase-functions-test")({
  projectId: projectId,
});

describe("Auth Triggers", () => {
  let myFunctions;

  beforeAll(() => {
    jest.setTimeout(30000);
    // Required to mock admin.initializeApp
    if (admin.apps.length === 0) {
      admin.initializeApp({ projectId: projectId });
    }
    myFunctions = require("../index.js");
  });

  afterAll(() => {
    test.cleanup();
  });

  it("should create a base Firestore document when a new user signs up", async () => {
    const wrapped = test.wrap(myFunctions.onUserAuthCreated);
    
    const userRecord = {
      uid: "testUser123",
      email: "test@example.com",
      displayName: "Test User",
    };

    // Execute the function
    await wrapped(userRecord);

    // Verify the document was created in Firestore
    const doc = await admin.firestore().collection("users").doc("testUser123").get();
    expect(doc.exists).toBe(true);
    expect(doc.data().uid).toBe("testUser123");
    expect(doc.data().role).toBe("user"); // default role
  }, 30000);
});
