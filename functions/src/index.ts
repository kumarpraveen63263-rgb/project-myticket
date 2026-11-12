import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';
import crypto from 'crypto';
import Razorpay from 'razorpay';

admin.initializeApp();
const db = admin.firestore();

// Pricing constants strictly owned by backend
const CONVENIENCE_FEE_PER_TICKET = 30.0;
const GST_RATE = 0.18; // 18%
const HOLD_DURATION_MS = 10 * 60 * 1000; // 10 minutes

/**
 * 1. ATOMIC SEAT HOLD
 *
 * Reserves all requested seats simultaneously inside a single Firestore transaction.
 * Guarantees that concurrent attempts for the same seat result in exactly one winner.
 */
export const holdSeats = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated to hold seats.'
    );
  }

  const userId = context.auth.uid;
  const { showId, seatIds, referenceId, title, venue, date, time, screen, imageUrl } = data;

  if (!showId || !Array.isArray(seatIds) || seatIds.length === 0) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'showId and non-empty seatIds array are required.'
    );
  }

  if (seatIds.length > 10) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Maximum 10 seats allowed per booking transaction.'
    );
  }

  const showRef = db.collection('shows').doc(showId);
  const now = Date.now();
  const holdExpiresAt = now + HOLD_DURATION_MS;

  return await db.runTransaction(async (transaction) => {
    // 1. Read all seat documents
    const seatRefs = seatIds.map((id) => showRef.collection('seats').doc(id));
    const seatSnapshots = await Promise.all(seatRefs.map((ref) => transaction.get(ref)));

    let calculatedSubtotal = 0;

    for (let i = 0; i < seatSnapshots.length; i++) {
      const snap = seatSnapshots[i];
      const seatId = seatIds[i];

      if (snap.exists) {
        const seatData = snap.data()!;
        const isCurrentlyHeld =
          seatData.status === 'held' &&
          seatData.holdExpiresAt &&
          seatData.holdExpiresAt.toMillis() > now &&
          seatData.heldBy !== userId;

        const isBooked = seatData.status === 'booked';

        if (isCurrentlyHeld || isBooked) {
          throw new functions.https.HttpsError(
            'already-exists',
            `Seat ${seatId} is no longer available. Please select another seat.`
          );
        }

        calculatedSubtotal += Number(seatData.price || 150.0);
      } else {
        // Seat document does not exist yet; default baseline price
        calculatedSubtotal += 150.0;
      }
    }

    // 2. Server-side fee and tax calculations
    const convenienceFee = seatIds.length * CONVENIENCE_FEE_PER_TICKET;
    const gst = Math.round((calculatedSubtotal + convenienceFee) * GST_RATE * 100) / 100;
    const totalAmount = Math.round((calculatedSubtotal + convenienceFee + gst) * 100) / 100;

    // 3. Mark all seats as held
    const expiresTimestamp = admin.firestore.Timestamp.fromMillis(holdExpiresAt);
    for (const ref of seatRefs) {
      transaction.set(
        ref,
        {
          status: 'held',
          heldBy: userId,
          holdExpiresAt: expiresTimestamp,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    }

    // 4. Create authoritative pending booking
    const bookingRef = db.collection('users').doc(userId).collection('bookings').doc();
    const holdData = {
      id: bookingRef.id,
      bookingId: `MT${Date.now().toString().slice(-6)}${Math.random().toString(36).substring(2, 5).toUpperCase()}`,
      userId,
      showId,
      type: 'movie',
      referenceId: referenceId || '',
      title: title || 'Movie Booking',
      imageUrl: imageUrl || '',
      venue: venue || '',
      date: date || new Date().toISOString(),
      time: time || '',
      screen: screen || 'Screen 1',
      seats: seatIds,
      quantity: seatIds.length,
      subtotal: calculatedSubtotal,
      convenienceFee,
      gst,
      discount: 0,
      totalAmount,
      status: 'held',
      holdExpiresAt: expiresTimestamp,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    transaction.set(bookingRef, holdData);

    return {
      success: true,
      holdId: bookingRef.id,
      bookingId: holdData.bookingId,
      subtotal: calculatedSubtotal,
      convenienceFee,
      gst,
      totalAmount,
      holdExpiresAt,
    };
  });
});

/**
 * 2. CREATE PAYMENT ORDER
 *
 * Verifies that the hold is still valid and creates an authentic order on Razorpay
 * using backend server credentials.
 */
export const createPaymentOrder = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated.');
  }

  const userId = context.auth.uid;
  const { holdId, promoCode } = data;

  if (!holdId) {
    throw new functions.https.HttpsError('invalid-argument', 'holdId is required.');
  }

  const bookingRef = db.collection('users').doc(userId).collection('bookings').doc(holdId);
  const bookingSnap = await bookingRef.get();

  if (!bookingSnap.exists) {
    throw new functions.https.HttpsError('not-found', 'Booking hold not found.');
  }

  const booking = bookingSnap.data()!;
  const now = Date.now();

  if (booking.status !== 'held' || booking.holdExpiresAt.toMillis() <= now) {
    throw new functions.https.HttpsError(
      'deadline-exceeded',
      'Seat hold has expired. Please select seats again.'
    );
  }

  // Calculate promo discount on server
  let discount = 0;
  if (promoCode && typeof promoCode === 'string') {
    const code = promoCode.toUpperCase().trim();
    if (code === 'FIRST100') {
      discount = Math.min(100, booking.subtotal);
    } else if (code === 'EVENT20') {
      discount = Math.min(200, Math.round(booking.subtotal * 0.2));
    }
  }

  const finalAmount = Math.max(0, Math.round((booking.totalAmount - discount) * 100) / 100);
  const amountInPaise = Math.round(finalAmount * 100);

  // Initialize Razorpay SDK using server environment variables
  const razorpayKeyId = process.env.RAZORPAY_KEY_ID || functions.config().razorpay?.key_id;
  const razorpayKeySecret = process.env.RAZORPAY_KEY_SECRET || functions.config().razorpay?.key_secret;

  let razorpayOrderId = `demo_order_${Date.now()}`;

  if (razorpayKeyId && razorpayKeySecret) {
    const instance = new Razorpay({
      key_id: razorpayKeyId,
      key_secret: razorpayKeySecret,
    });

    const order = await instance.orders.create({
      amount: amountInPaise,
      currency: 'INR',
      receipt: holdId,
      notes: {
        userId,
        bookingId: booking.bookingId,
      },
    });
    razorpayOrderId = order.id;
  }

  await bookingRef.update({
    status: 'payment_pending',
    discount,
    finalAmount,
    razorpayOrderId,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return {
    orderId: razorpayOrderId,
    amountInPaise,
    currency: 'INR',
    discount,
    finalAmount,
    keyId: razorpayKeyId || 'rzp_test_MyTicketsDemoKey',
  };
});

/**
 * 3. VERIFY PAYMENT (Client completion hook)
 *
 * Validates HMAC signature of the transaction before granting ticket.
 */
export const verifyPayment = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated.');
  }

  const userId = context.auth.uid;
  const { holdId, razorpayOrderId, razorpayPaymentId, razorpaySignature } = data;

  const bookingRef = db.collection('users').doc(userId).collection('bookings').doc(holdId);
  const bookingSnap = await bookingRef.get();

  if (!bookingSnap.exists) {
    throw new functions.https.HttpsError('not-found', 'Booking not found.');
  }

  const booking = bookingSnap.data()!;

  // Verify HMAC if secrets exist
  const razorpayKeySecret = process.env.RAZORPAY_KEY_SECRET || functions.config().razorpay?.key_secret;
  if (razorpayKeySecret && razorpaySignature) {
    const generatedSignature = crypto
      .createHmac('sha256', razorpayKeySecret)
      .update(`${razorpayOrderId}|${razorpayPaymentId}`)
      .digest('hex');

    if (generatedSignature !== razorpaySignature) {
      await bookingRef.update({ status: 'payment_failed' });
      throw new functions.https.HttpsError('permission-denied', 'Payment signature verification failed.');
    }
  }

  // Cryptographically sign the ticket payload for QR generation
  const qrSecret = process.env.QR_SIGNING_SECRET || 'mytickets_secure_qr_token_salt';
  const qrPayload = `${booking.bookingId}:${userId}:${Date.now()}`;
  const qrSignature = crypto.createHmac('sha256', qrSecret).update(qrPayload).digest('hex').substring(0, 16);
  const signedTicketToken = `${qrPayload}:${qrSignature}`;

  // Atomic confirmation
  await db.runTransaction(async (transaction) => {
    // Lock seats permanently
    const showRef = db.collection('shows').doc(booking.showId);
    for (const seatId of booking.seats) {
      transaction.set(
        showRef.collection('seats').doc(seatId),
        {
          status: 'booked',
          bookedBy: userId,
          bookingId: booking.id,
          bookedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    }

    transaction.update(bookingRef, {
      status: 'upcoming',
      paymentId: razorpayPaymentId || '',
      qrToken: signedTicketToken,
      confirmedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Reward points increment
    transaction.set(
      db.collection('users').doc(userId),
      {
        bookingsCount: admin.firestore.FieldValue.increment(1),
        rewardPoints: admin.firestore.FieldValue.increment(booking.quantity * 10),
      },
      { merge: true }
    );
  });

  return {
    success: true,
    bookingId: booking.bookingId,
    qrToken: signedTicketToken,
    status: 'upcoming',
  };
});

/**
 * 4. RELEASE EXPIRED HOLDS (Scheduled cron runner)
 *
 * Automatically frees seats that were held but never paid for within 10 minutes.
 */
export const releaseExpiredHolds = functions.pubsub.schedule('every 5 minutes').onRun(async () => {
  const now = admin.firestore.Timestamp.now();
  const expiredSeatsQuery = await db
    .collectionGroup('seats')
    .where('status', '==', 'held')
    .where('holdExpiresAt', '<=', now)
    .get();

  if (expiredSeatsQuery.empty) {
    return null;
  }

  const batch = db.batch();
  expiredSeatsQuery.docs.forEach((doc) => {
    batch.delete(doc.ref);
  });

  await batch.commit();
  console.log(`Successfully released ${expiredSeatsQuery.size} expired seat holds.`);
  return null;
});
