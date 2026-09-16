import { createHmac, timingSafeEqual } from "node:crypto";

function safeEqualHex(expected: string, received: string) {
  const expectedBuffer = Buffer.from(expected, "utf8");
  const receivedBuffer = Buffer.from(received, "utf8");

  return (
    expectedBuffer.length === receivedBuffer.length &&
    timingSafeEqual(expectedBuffer, receivedBuffer)
  );
}

export function verifyRazorpayWebhookSignature(
  rawBody: string,
  receivedSignature: string,
  secret: string,
) {
  const expected = createHmac("sha256", secret)
    .update(rawBody, "utf8")
    .digest("hex");
  return safeEqualHex(expected, receivedSignature);
}

export function verifyRazorpayPaymentSignature(
  orderId: string,
  paymentId: string,
  receivedSignature: string,
  secret: string,
) {
  const expected = createHmac("sha256", secret)
    .update(`${orderId}|${paymentId}`, "utf8")
    .digest("hex");
  return safeEqualHex(expected, receivedSignature);
}
