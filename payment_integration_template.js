// Payment Integration Template for Dubai Market
// Bridge between frontend PaymentManager and Firebase backend

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

// Initialize Firebase
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'glist-6e64f'
});

const db = admin.firestore();

// Dubai-specific payment processors
const paymentProviders = {
  // UAE Local
  benefit: { name: 'Benefit Pay', code: 'benefit', fees: 0.025 }, // 2.5% + AED 1
  mada: { name: 'Mada', code: 'mada', fees: 0.015 }, // 1.5%

  // International
  stripe: { name: 'Stripe', code: 'stripe', fees: 0.029 }, // 2.9% + AED 2
  paypal: { name: 'PayPal', code: 'paypal', fees: 0.039 }, // 3.9% + AED 1
};

// Create payment intent for table booking
async function createBookingPayment(data) {
  const {
    userId,
    venueId,
    tableId,
    amount,
    currency = 'AED',
    paymentMethod = 'apple_pay',
    guestCount,
    deposit = false
  } = data;

  console.log(`💳 Creating booking payment: AED ${amount} for user ${userId}`);

  try {
    // 1. Check venue pricing and availability
    const venueDoc = await db.collection('venues').doc(venueId).get();
    if (!venueDoc.exists) throw new Error('Venue not found');

    const venueData = venueDoc.data();
    const table = venueData.tables.find(t => t.id === tableId);
    if (!table || !table.isAvailable) throw new Error('Table not available');

    // 2. Calculate fees (Glist takes 5%, venue gets rest)
    const glistFee = Math.round(amount * 0.05); // 5% platform fee
    const venueAmount = amount - glistFee;

    // 3. Create Firebase transaction record
    const transactionRef = db.collection('transactions').doc();
    const transaction = {
      id: transactionRef.id,
      userId,
      venueId,
      tableId,
      amount: amount,
      currency,
      glistFee,
      venueAmount,
      paymentMethod,
      guestCount,
      status: 'pending',
      deposit,
      createdAt: admin.firestore.Timestamp.now(),
      dueDate: deposit ? admin.firestore.Timestamp.fromDate(new Date(Date.now() + 24 * 60 * 60 * 1000)) : null, // 24h for deposit
    };

    await transactionRef.set(transaction);

    // 4. Create Stripe payment intent (if using Stripe)
    let paymentIntent = null;
    if (paymentMethod === 'apple_pay' || paymentMethod === 'credit_card') {
      paymentIntent = await stripe.paymentIntents.create({
        amount: Math.round(amount * 100), // Convert to cents
        currency: currency.toLowerCase(),
        metadata: {
          transactionId: transactionRef.id,
          userId,
          venueId,
          tableId,
          deposit: deposit.toString()
        },
        description: `${deposit ? 'Deposit' : 'Payment'} for table at ${venueData.name}`,
        // Apple Pay configuration for UAE
        payment_method_types: paymentMethod === 'apple_pay' ? ['card'] : ['card'],
        setup_future_usage: 'off_session', // For future repeat bookings
      });

      // Update transaction with Stripe data
      await transactionRef.update({
        stripePaymentIntentId: paymentIntent.id,
        clientSecret: paymentIntent.client_secret
      });
    }

    return {
      transactionId: transactionRef.id,
      clientSecret: paymentIntent?.client_secret,
      status: 'pending'
    };

  } catch (error) {
    console.error('❌ Payment creation failed:', error);
    throw error;
  }
}

// Process successful payment
async function confirmPayment(stripePaymentIntentId) {
  try {
    const transactionSnapshot = await db.collection('transactions')
      .where('stripePaymentIntentId', '==', stripePaymentIntentId)
      .limit(1)
      .get();

    if (transactionSnapshot.empty) throw new Error('Transaction not found');

    const transactionDoc = transactionSnapshot.docs[0];
    const transactionData = transactionDoc.data();

    // Update transaction status
    await transactionDoc.ref.update({
      status: 'completed',
      completedAt: admin.firestore.Timestamp.now(),
    });

    // Update table availability
    const venueRef = db.collection('venues').doc(transactionData.venueId);
    await venueRef.update({
      [`tables.${transactionData.tableId}.isAvailable`]: false
    });

    // Create booking record
    const bookingRef = db.collection('bookings').doc();
    await bookingRef.set({
      id: bookingRef.id,
      userId: transactionData.userId,
      venueId: transactionData.venueId,
      tableId: transactionData.tableId,
      tableName: `Table at ${transactionData.venueId}`,
      date: admin.firestore.Timestamp.now(),
      depositAmount: transactionData.amount,
      status: 'confirmed',
      createdAt: admin.firestore.Timestamp.now()
    });

    console.log(`✅ Payment confirmed: ${stripePaymentIntentId}`);
    return { success: true, bookingId: bookingRef.id };

  } catch (error) {
    console.error('❌ Payment confirmation failed:', error);
    throw error;
  }
}

// Split payment for groups
async function createGroupPayment(data) {
  const {
    creatorId,
    venueId,
    tableId,
    totalAmount,
    participants = [], // [{userId, amount}]
    currency = 'AED'
  } = data;

  console.log(`👥 Creating group payment: AED ${totalAmount} for ${participants.length} people`);

  // Calculate shares
  const groupPaymentRef = db.collection('groupPayments').doc();
  const groupPayment = {
    id: groupPaymentRef.id,
    creatorId,
    venueId,
    tableId,
    totalAmount,
    currency,
    status: 'pending',
    participants,
    createdAt: admin.firestore.Timestamp.now()
  };

  await groupPaymentRef.set(groupPayment);

  // Create individual payment intents for each participant
  const result = await Promise.all(participants.map(async (participant) => {
    const participantPayment = await createBookingPayment({
      userId: participant.userId,
      venueId,
      tableId,
      amount: participant.amount,
      currency,
      guestCount: 1,
      groupPaymentId: groupPaymentRef.id
    });
    return { userId: participant.userId, ...participantPayment };
  }));

  return {
    groupPaymentId: groupPaymentRef.id,
    participantPayments: result
  };
}

// Refund processing
async function processRefund(transactionId, reason = 'cancelled', amount = null) {
  try {
    const transactionDoc = await db.collection('transactions').doc(transactionId).get();
    if (!transactionDoc.exists) throw new Error('Transaction not found');

    const transactionData = transactionDoc.data();

    // Check refund eligibility (within 24h for deposits, 7 days for full payment)
    const now = Date.now();
    const transactionTime = transactionData.createdAt.toMillis();
    const hoursDiff = (now - transactionTime) / (1000 * 60 * 60);

    const refundAmount = amount || transactionData.amount;
    const refundThreshold = transactionData.deposit ? 24 : (24 * 7); // 24h for deposits, 7 days for full payments

    if (hoursDiff > refundThreshold) {
      throw new Error(`Refund not allowed: ${hoursDiff.toFixed(1)}h > ${refundThreshold}h limit`);
    }

    // Process Stripe refund
    let refund = null;
    if (transactionData.stripePaymentIntentId) {
      refund = await stripe.refunds.create({
        payment_intent: transactionData.stripePaymentIntentId,
        amount: Math.round(refundAmount * 100),
        reason: reason,
        metadata: {
          originalTransactionId: transactionId,
          reason
        }
      });

      // Update transaction
      await transactionDoc.ref.update({
        status: 'refunded',
        refundId: refund.id,
        refundAmount,
        refundReason: reason,
        refundedAt: admin.firestore.Timestamp.now()
      });
    }

    console.log(`💸 Refund processed: ${refundAmount} AED for ${reason}`);
    return { success: true, refundId: refund.id, amount: refundAmount };

  } catch (error) {
    console.error('❌ Refund failed:', error);
    throw error;
  }
}

// Dubai-specific payment methods validation
function validateUAE(paymentData) {
  const { amount, currency, paymentMethod } = paymentData;

  // AED only for UAE
  if (currency !== 'AED') {
    throw new Error('Only AED currency supported in UAE');
  }

  // Minimum amounts per provider
  const minAmounts = {
    benefit: 1, // AED 1 minimum
    mada: 5, // AED 5 minimum
    stripe: 10, // AED 10 minimum for international cards
  };

  const minAmount = minAmounts[paymentMethod] || 10;
  if (amount < minAmount) {
    throw new Error(`Minimum payment amount is AED ${minAmount} for ${paymentMethod.toUpperCase()}`);
  }

  return true;
}

module.exports = {
  createBookingPayment,
  createGroupPayment,
  confirmPayment,
  processRefund,
  validateUAE,
  paymentProviders
};
