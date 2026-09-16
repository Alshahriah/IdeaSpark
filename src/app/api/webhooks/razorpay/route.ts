import { eq } from "drizzle-orm";
import { NextResponse } from "next/server";
import { db } from "@/db";
import { payments } from "@/db/schema";
import { markPaymentPaidByOrderAtomically } from "@/db/transactions";
import { verifyRazorpayWebhookSignature } from "@/lib/razorpay";

export const runtime = "nodejs";

export async function POST(request: Request) {
  const secret = process.env.RAZORPAY_WEBHOOK_SECRET;
  if (!secret) {
    return NextResponse.json(
      { error: "Razorpay webhook secret is not configured" },
      { status: 500 },
    );
  }

  // Razorpay signs the exact raw request body. Do not parse JSON before verifying.
  const rawBody = await request.text();
  const signature = request.headers.get("x-razorpay-signature");

  if (
    !signature ||
    !verifyRazorpayWebhookSignature(rawBody, signature, secret)
  ) {
    return NextResponse.json(
      { error: "Invalid webhook signature" },
      { status: 400 },
    );
  }

  let payload: {
    event?: string;
    payload?: {
      payment?: {
        entity?: {
          id?: string;
          order_id?: string;
          status?: string;
        };
      };
    };
  };

  try {
    payload = JSON.parse(rawBody);
  } catch {
    return NextResponse.json(
      { error: "Invalid JSON payload" },
      { status: 400 },
    );
  }

  const event = payload.event;
  const entity = payload.payload?.payment?.entity;
  const orderId = entity?.order_id;
  const paymentId = entity?.id;

  // We only finalize a payment after Razorpay reports a captured payment.
  if (event === "payment.captured" && orderId && paymentId) {
    const [knownPayment] = await db
      .select({ id: payments.id })
      .from(payments)
      .where(eq(payments.razorpayOrderId, orderId))
      .limit(1);

    // Unknown orders are acknowledged without mutating state.
    if (knownPayment) {
      await markPaymentPaidByOrderAtomically({
        razorpayOrderId: orderId,
        razorpayPaymentId: paymentId,
        razorpaySignature: signature,
      });
    }
  }

  return NextResponse.json({ received: true });
}
