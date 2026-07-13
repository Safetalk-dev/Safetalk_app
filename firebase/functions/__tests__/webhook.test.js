process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";
process.env.RAZORPAY_KEY_SECRET = "local_mock_razorpay_key_secret";
const admin = require("firebase-admin");
const crypto = require("crypto");
const projectId = process.env.GCLOUD_PROJECT || "demo-safetalk";
const test = require("firebase-functions-test")({
  projectId: projectId,
});

describe("Razorpay Webhook Trigger", () => {
  let myFunctions;
  const webhookSecret = "local_mock_razorpay_key_secret";

  beforeAll(() => {
    jest.setTimeout(30000);
    if (admin.apps.length === 0) {
      admin.initializeApp({ projectId: projectId });
    }
    myFunctions = require("../index.js");
  });

  afterAll(() => {
    test.cleanup();
  });

  it("should fail signature verification if x-razorpay-signature header is missing", async () => {
    const req = {
      headers: {},
      body: {},
      rawBody: Buffer.from(JSON.stringify({})),
    };
    
    let statusCode = 0;
    let responseBody = "";
    const res = {
      status: (code) => {
        statusCode = code;
        return res;
      },
      send: (body) => {
        responseBody = body;
        return res;
      },
    };

    await myFunctions.razorpayWebhook(req, res);

    expect(statusCode).toBe(400);
    expect(responseBody).toContain("Signature missing");
  });

  it("should fail signature verification if signature is invalid", async () => {
    const req = {
      headers: {
        "x-razorpay-signature": "invalid_sig",
      },
      body: {},
      rawBody: Buffer.from(JSON.stringify({})),
    };
    
    let statusCode = 0;
    let responseBody = "";
    const res = {
      status: (code) => {
        statusCode = code;
        return res;
      },
      send: (body) => {
        responseBody = body;
        return res;
      },
    };

    await myFunctions.razorpayWebhook(req, res);

    expect(statusCode).toBe(400);
    expect(responseBody).toContain("Signature verification failed");
  });

  it("should succeed and update session status to active for a valid signature and payload", async () => {
    const db = admin.firestore();
    const sessionId = "testSession456";
    await db.collection("sessions").doc(sessionId).set({
      seekerId: "seeker123",
      status: "payment_pending",
    });

    const payload = {
      event: "payment.authorized",
      payload: {
        payment: {
          entity: {
            id: "pay_testPayment123",
            amount: 15000,
            notes: {
              sessionId: sessionId,
            },
          },
        },
      },
    };

    const rawBodyString = JSON.stringify(payload);
    const signature = crypto
      .createHmac("sha256", webhookSecret)
      .update(rawBodyString)
      .digest("hex");

    const req = {
      headers: {
        "x-razorpay-signature": signature,
      },
      body: payload,
      rawBody: Buffer.from(rawBodyString),
    };

    let statusCode = 0;
    let responseBody = "";
    const res = {
      status: (code) => {
        statusCode = code;
        return res;
      },
      send: (body) => {
        responseBody = body;
        return res;
      },
    };

    await myFunctions.razorpayWebhook(req, res);

    expect(statusCode).toBe(200);
    expect(responseBody).toBe("OK");

    const doc = await db.collection("sessions").doc(sessionId).get();
    expect(doc.exists).toBe(true);
    expect(doc.data().status).toBe("active");
    expect(doc.data().paymentId).toBe("pay_testPayment123");
  });
});
