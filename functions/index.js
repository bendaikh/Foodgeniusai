const crypto = require('crypto');
const { onRequest, onCall, HttpsError } = require('firebase-functions/v2/https');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');

initializeApp();

const ALLOWED_PREFIXES = [
  '/products',
  '/checkouts',
  '/subscriptions',
  '/payments/',
];

const setCorsHeaders = (req, res) => {
  const origin = req.headers.origin;
  if (origin) {
    res.set('Access-Control-Allow-Origin', origin);
    res.set('Vary', 'Origin');
  } else {
    res.set('Access-Control-Allow-Origin', '*');
  }
  res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.set('Access-Control-Max-Age', '3600');
};

async function verifyAuthToken(req) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return { error: 'Missing or invalid Authorization header', status: 401 };
  }

  try {
    const idToken = authHeader.split('Bearer ')[1];
    const decodedToken = await getAuth().verifyIdToken(idToken);
    return { decodedToken };
  } catch (authError) {
    console.error('Auth verification failed:', authError);
    return { error: 'Invalid authentication token', status: 401 };
  }
}

async function loadDodoSettings() {
  const settingsDoc = await getFirestore()
    .collection('admin_settings')
    .doc('payment_settings')
    .get();

  if (!settingsDoc.exists) {
    return { error: 'DodoPayment settings not configured yet', status: 400 };
  }

  const settings = settingsDoc.data();
  const apiKey = settings.dodo_api_key;
  const testMode = settings.dodo_test_mode !== false;

  if (!apiKey) {
    return { error: 'DodoPayment API key is missing', status: 400 };
  }

  const baseUrl = testMode
    ? 'https://test.dodopayments.com'
    : 'https://live.dodopayments.com';

  const headers = {
    Authorization: `Bearer ${apiKey}`,
    'Content-Type': 'application/json',
  };

  if (settings.dodo_business_id) {
    headers['business-id'] = settings.dodo_business_id;
  }

  return { settings, apiKey, baseUrl, headers, testMode };
}

async function resolvePlanFromFirestore(planId) {
  const planDoc = await getFirestore()
    .collection('subscription_plans')
    .doc(planId)
    .get();

  if (!planDoc.exists) {
    return { error: `Subscription plan "${planId}" was not found.` };
  }

  const plan = planDoc.data();
  if (!plan.isActive) {
    return { error: 'This subscription plan is no longer available.' };
  }

  const productId = plan.dodoProductId;
  if (!productId) {
    return { error: 'This plan is missing a DodoPayments product ID.' };
  }

  return { plan, productId, planId };
}

async function resolveProductId(tier, settings, baseUrl, headers) {
  const configuredId =
    tier === 'pro' ? settings.pro_product_id : settings.elite_product_id;
  if (configuredId) return configuredId;

  const response = await fetch(`${baseUrl}/products`, { headers });
  if (!response.ok) {
    throw new Error(`Failed to fetch Dodo products (${response.status})`);
  }

  const data = JSON.parse(await response.text());
  const products = data.items || [];
  const keywords =
    tier === 'pro'
      ? ['pro', 'gourmet']
      : ['elite', 'michelin'];

  const match = products.find((product) => {
    const name = (product.name || '').toLowerCase();
    return keywords.some((keyword) => name.includes(keyword));
  });

  return match?.product_id || match?.id || null;
}

function buildCheckoutUrl(session, testMode) {
  if (session.checkout_url) return session.checkout_url;

  const sessionId = session.session_id || session.id;
  const baseCheckoutUrl = testMode
    ? 'https://test.checkout.dodopayments.com'
    : 'https://checkout.dodopayments.com';
  return `${baseCheckoutUrl}/session/${sessionId}`;
}

function isCheckoutPaid(checkout) {
  const status = (checkout.status || checkout.payment_status || '').toLowerCase();
  return ['completed', 'paid', 'succeeded', 'success', 'active'].includes(status);
}

async function fetchCheckoutById(baseUrl, headers, checkoutId) {
  const checkoutResponse = await fetch(`${baseUrl}/checkouts/${checkoutId}`, {
    headers,
  });
  const checkoutText = await checkoutResponse.text();
  if (!checkoutResponse.ok) return null;
  return JSON.parse(checkoutText);
}

async function fetchPaymentById(baseUrl, headers, paymentId) {
  const response = await fetch(`${baseUrl}/payments/${paymentId}`, { headers });
  const text = await response.text();
  if (!response.ok) return null;
  return JSON.parse(text);
}

async function fetchSubscriptionById(baseUrl, headers, subscriptionId) {
  const response = await fetch(`${baseUrl}/subscriptions/${subscriptionId}`, {
    headers,
  });
  const text = await response.text();
  if (!response.ok) return null;
  return JSON.parse(text);
}

function isRedirectStatusPaid(status) {
  const normalized = (status || '').toLowerCase();
  return ['succeeded', 'success', 'completed', 'paid', 'active'].includes(normalized);
}

function isPaymentRecordPaid(payment) {
  const status = (payment.status || payment.payment_status || '').toLowerCase();
  return ['succeeded', 'success', 'completed', 'paid'].includes(status);
}

function isSubscriptionRecordActive(subscription) {
  const status = (subscription.status || '').toLowerCase();
  return ['active', 'trialing', 'succeeded', 'success'].includes(status);
}

function extractTierFromMetadata(metadata) {
  if (!metadata || typeof metadata !== 'object') return null;
  return metadata.planId || metadata.tier || metadata.subscriptionTier || null;
}

async function activateUserSubscription(uid, tier, extraFields = {}) {
  await getFirestore()
    .collection('users')
    .doc(uid)
    .set(
      {
        subscriptionTier: tier,
        subscriptionStatus: 'active',
        subscriptionUpdatedAt: new Date(),
        monthlyGenerationsUsed: 0,
        generationPeriodStart: new Date(),
        ...extraFields,
      },
      { merge: true },
    );
}

function startOfCurrentMonth(date = new Date()) {
  return new Date(date.getFullYear(), date.getMonth(), 1);
}

function isSameMonth(a, b) {
  return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth();
}

async function getPlanMonthlyGenerationLimit(planId) {
  if (!planId || planId === 'free') return 0;

  const planDoc = await getFirestore()
    .collection('subscription_plans')
    .doc(planId)
    .get();

  if (planDoc.exists) {
    const limit = planDoc.data().monthlyGenerationLimit;
    if (typeof limit === 'number') return limit;
  }

  if (planId === 'pro') return 25;
  if (planId === 'elite') return 50;
  return 0;
}

async function getRecipeGenerationStatus(uid) {
  const userDoc = await getFirestore().collection('users').doc(uid).get();
  const userData = userDoc.data() || {};
  const tier = userData.subscriptionTier || 'free';
  const status = userData.subscriptionStatus || 'active';

  if (status !== 'active') {
    return { limit: 0, used: 0, remaining: 0, tier, planId: tier };
  }

  const limit = await getPlanMonthlyGenerationLimit(tier);
  const now = new Date();
  let used = userData.monthlyGenerationsUsed || 0;
  const periodStart = userData.generationPeriodStart?.toDate?.() || null;

  if (periodStart && !isSameMonth(periodStart, now)) {
    used = 0;
  }

  return {
    limit,
    used,
    remaining: Math.max(0, limit - used),
    tier,
    planId: tier,
  };
}

async function consumeRecipeGeneration(uid) {
  const db = getFirestore();
  const userRef = db.collection('users').doc(uid);

  return db.runTransaction(async (tx) => {
    const userDoc = await tx.get(userRef);
    if (!userDoc.exists) {
      throw new HttpsError('not-found', 'User profile not found.');
    }

    const userData = userDoc.data();
    const tier = userData.subscriptionTier || 'free';
    const status = userData.subscriptionStatus || 'active';

    if (status !== 'active') {
      throw new HttpsError('permission-denied', 'Your subscription is not active.');
    }

    const planLimit = await getPlanMonthlyGenerationLimit(tier);
    if (planLimit <= 0) {
      throw new HttpsError(
        'permission-denied',
        'Subscribe to a plan to generate AI recipes.',
      );
    }

    const now = new Date();
    let used = userData.monthlyGenerationsUsed || 0;
    let periodStart = userData.generationPeriodStart?.toDate?.() || null;

    if (!periodStart || !isSameMonth(periodStart, now)) {
      used = 0;
      periodStart = startOfCurrentMonth(now);
    }

    if (used >= planLimit) {
      throw new HttpsError(
        'resource-exhausted',
        `You've used all ${planLimit} AI recipe generations for this month. Your limit resets at the start of next month.`,
      );
    }

    const newUsed = used + 1;
    tx.update(userRef, {
      monthlyGenerationsUsed: newUsed,
      generationPeriodStart: periodStart,
      totalRecipesGenerated: FieldValue.increment(1),
      apiUsageCount: FieldValue.increment(1),
    });

    return {
      limit: planLimit,
      used: newUsed,
      remaining: planLimit - newUsed,
      tier,
      planId: tier,
    };
  });
}

async function markPendingCheckoutCompleted(uid, checkoutId) {
  if (!checkoutId) return;
  await getFirestore()
    .collection('pending_checkouts')
    .doc(`${uid}_${checkoutId}`)
    .set(
      {
        status: 'completed',
        completedAt: new Date(),
      },
      { merge: true },
    );
}

async function findRecentPendingCheckout(uid) {
  const pendingSnap = await getFirestore()
    .collection('pending_checkouts')
    .where('userId', '==', uid)
    .limit(10)
    .get();

  if (pendingSnap.empty) return null;

  const sorted = pendingSnap.docs.sort((a, b) => {
    const aTime = a.data().createdAt?.toMillis?.() ?? 0;
    const bTime = b.data().createdAt?.toMillis?.() ?? 0;
    return bTime - aTime;
  });

  return sorted[0];
}

function verifyDodoWebhookSignature(rawBody, headers, secret) {
  if (!secret) return true;

  const webhookId = headers['webhook-id'];
  const webhookTimestamp = headers['webhook-timestamp'];
  const webhookSignature = headers['webhook-signature'];

  if (!webhookId || !webhookTimestamp || !webhookSignature) {
    return false;
  }

  const keyMaterial = secret.startsWith('whsec_') ? secret.slice(6) : secret;
  let key;
  try {
    key = Buffer.from(keyMaterial, 'base64');
  } catch (_) {
    key = Buffer.from(keyMaterial, 'utf8');
  }

  const payload =
    typeof rawBody === 'string' ? rawBody : rawBody.toString('utf8');
  const signedContent = `${webhookId}.${webhookTimestamp}.${payload}`;
  const expectedSignature = crypto
    .createHmac('sha256', key)
    .update(signedContent)
    .digest('base64');

  return webhookSignature.split(' ').some((entry) => {
    const parts = entry.split(',');
    return parts.length > 1 && parts.slice(1).join(',') === expectedSignature;
  });
}

async function activateSubscriptionFromWebhookPayload(payload) {
  const metadata =
    payload.metadata ||
    payload.checkout?.metadata ||
    payload.checkout_metadata ||
    {};
  const userId = metadata.userId;
  const tier = extractTierFromMetadata(metadata);

  if (!userId) {
    console.warn('Webhook payload missing metadata.userId');
    return;
  }

  if (!tier || tier === 'free') {
    console.warn('Webhook payload missing subscription tier metadata');
    return;
  }

  await activateUserSubscription(userId, tier, {
    dodoPaymentId: payload.payment_id || null,
    dodoSubscriptionId: payload.subscription_id || null,
    dodoCheckoutId: payload.checkout_id || metadata.checkoutId || null,
  });

  const checkoutId =
    payload.checkout_id ||
    metadata.checkoutId ||
    payload.checkout?.checkout_id ||
    null;
  await markPendingCheckoutCompleted(userId, checkoutId);
}

exports.dodoPaymentsProxy = onRequest({ cors: true }, async (req, res) => {
  // Handle preflight OPTIONS request
  if (req.method === 'OPTIONS') {
    setCorsHeaders(req, res);
    res.status(204).send('');
    return;
  }

  setCorsHeaders(req, res);

  try {
    // Verify Firebase Auth token from Authorization header
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      res.status(401).json({ error: 'Missing or invalid Authorization header' });
      return;
    }

    const idToken = authHeader.split('Bearer ')[1];
    let decodedToken;
    try {
      decodedToken = await getAuth().verifyIdToken(idToken);
    } catch (authError) {
      console.error('Auth verification failed:', authError);
      res.status(401).json({ error: 'Invalid authentication token' });
      return;
    }

    // Check if user is admin
    const userDoc = await getFirestore().collection('users').doc(decodedToken.uid).get();
    const role = userDoc.exists ? userDoc.data().role : null;
    if (role !== 'admin') {
      res.status(403).json({ error: 'Admin access required' });
      return;
    }

    // Get Dodo settings from Firestore
    const settingsDoc = await getFirestore()
      .collection('admin_settings')
      .doc('payment_settings')
      .get();

    if (!settingsDoc.exists) {
      res.status(400).json({ error: 'DodoPayment settings not configured yet' });
      return;
    }

    const settings = settingsDoc.data();
    const apiKey = settings.dodo_api_key;
    const testMode = settings.dodo_test_mode !== false;

    if (!apiKey) {
      res.status(400).json({ error: 'DodoPayment API key is missing' });
      return;
    }

    // Parse request body
    const { method = 'GET', path, body } = req.body;

    if (!path || typeof path !== 'string') {
      res.status(400).json({ error: 'A valid API path is required' });
      return;
    }

    if (!ALLOWED_PREFIXES.some((prefix) => path.startsWith(prefix))) {
      res.status(400).json({ error: 'That Dodo API path is not allowed' });
      return;
    }

    const baseUrl = testMode
      ? 'https://test.dodopayments.com'
      : 'https://live.dodopayments.com';

    const headers = {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    };

    if (settings.dodo_business_id) {
      headers['business-id'] = settings.dodo_business_id;
    }

    console.log(`DodoProxy: ${method} ${baseUrl}${path}`);

    const fetchOptions = {
      method: method.toUpperCase(),
      headers,
    };

    if (body && ['POST', 'PUT', 'PATCH'].includes(method.toUpperCase())) {
      fetchOptions.body = JSON.stringify(body);
    }

    const response = await fetch(`${baseUrl}${path}`, fetchOptions);
    const responseText = await response.text();

    console.log(`DodoProxy: Received ${response.status} (${responseText.length} bytes)`);

    // Return as JSON string to avoid Int64 issues on Flutter Web
    res.status(200).json({
      statusCode: String(response.status),
      body: responseText,
      url: `${baseUrl}${path}`,
    });

  } catch (error) {
    console.error('DodoProxy Error:', error);
    res.status(500).json({ error: error.message || 'Unknown server error' });
  }
});

async function performCreateUserCheckout({
  uid,
  tier,
  planId,
  successUrl,
  cancelUrl,
}) {
  const dodo = await loadDodoSettings();
  if (dodo.error) {
    throw new HttpsError('failed-precondition', dodo.error);
  }

  let resolvedPlanId = planId || null;
  let resolvedTier = tier || null;
  let productId = null;

  if (resolvedPlanId) {
    const planResult = await resolvePlanFromFirestore(resolvedPlanId);
    if (planResult.error) {
      throw new HttpsError('failed-precondition', planResult.error);
    }
    productId = planResult.productId;
    resolvedTier = resolvedPlanId;
  } else if (resolvedTier && ['pro', 'elite'].includes(resolvedTier)) {
    productId = await resolveProductId(
      resolvedTier,
      dodo.settings,
      dodo.baseUrl,
      dodo.headers,
    );
  } else {
    throw new HttpsError(
      'invalid-argument',
      'A valid planId or tier (pro/elite) is required.',
    );
  }

  if (!productId) {
    throw new HttpsError(
      'failed-precondition',
      'No Dodo product found for this plan. Create and activate the plan in the admin Payments section.',
    );
  }

  const origin = successUrl ? new URL(successUrl).origin : '';
  const baseSuccessUrl = successUrl || `${origin}/payment-success`;
  const separator = baseSuccessUrl.includes('?') ? '&' : '?';
  const returnUrl = `${baseSuccessUrl}${separator}planId=${encodeURIComponent(resolvedTier)}`;

  const checkoutResponse = await fetch(`${dodo.baseUrl}/checkouts`, {
    method: 'POST',
    headers: dodo.headers,
    body: JSON.stringify({
      product_cart: [{ product_id: productId, quantity: 1 }],
      return_url: returnUrl,
      metadata: {
        userId: uid,
        tier: resolvedTier,
        planId: resolvedPlanId || resolvedTier,
        cancelUrl: cancelUrl || `${origin}/payment-cancel`,
      },
    }),
  });

  const checkoutText = await checkoutResponse.text();
  if (!checkoutResponse.ok) {
    throw new HttpsError(
      'internal',
      checkoutText || 'Failed to create checkout session',
    );
  }

  const session = JSON.parse(checkoutText);
  const checkoutUrl = buildCheckoutUrl(session, dodo.testMode);
  const checkoutId = session.checkout_id || session.id || session.session_id;

  await getFirestore()
    .collection('pending_checkouts')
    .doc(`${uid}_${checkoutId}`)
    .set({
      userId: uid,
      tier: resolvedTier,
      planId: resolvedPlanId || resolvedTier,
      checkoutId,
      productId,
      status: 'pending',
      createdAt: new Date(),
    });

  return { checkoutUrl, checkoutId, tier: resolvedTier, planId: resolvedPlanId || resolvedTier };
}

async function performCompleteUserCheckout({
  uid,
  checkoutId,
  sessionId,
  paymentId,
  subscriptionId,
  status,
  tier,
  planId,
}) {
  const resolvedCheckoutId = checkoutId || sessionId;

  const dodo = await loadDodoSettings();
  if (dodo.error) {
    throw new HttpsError('failed-precondition', dodo.error);
  }

  let resolvedTier = tier || planId || null;
  let paid = false;
  let checkoutData = null;
  let pendingDoc = null;
  let pendingRef = null;

  if (resolvedCheckoutId) {
    pendingRef = getFirestore()
      .collection('pending_checkouts')
      .doc(`${uid}_${resolvedCheckoutId}`);
    pendingDoc = await pendingRef.get();

    checkoutData = await fetchCheckoutById(
      dodo.baseUrl,
      dodo.headers,
      resolvedCheckoutId,
    );

    if (checkoutData && !isCheckoutPaid(checkoutData)) {
      await new Promise((resolve) => setTimeout(resolve, 2000));
      checkoutData = await fetchCheckoutById(
        dodo.baseUrl,
        dodo.headers,
        resolvedCheckoutId,
      );
    }

    if (checkoutData && isCheckoutPaid(checkoutData)) {
      paid = true;
      resolvedTier =
        resolvedTier || extractTierFromMetadata(checkoutData.metadata);
    }
  }

  if (!paid && paymentId) {
    const paymentData = await fetchPaymentById(
      dodo.baseUrl,
      dodo.headers,
      paymentId,
    );

    if (paymentData && isPaymentRecordPaid(paymentData)) {
      paid = true;
      resolvedTier = resolvedTier || extractTierFromMetadata(paymentData.metadata);
    } else if (isRedirectStatusPaid(status)) {
      paid = true;
    }
  }

  if (!paid && subscriptionId) {
    const subscriptionData = await fetchSubscriptionById(
      dodo.baseUrl,
      dodo.headers,
      subscriptionId,
    );

    if (subscriptionData && isSubscriptionRecordActive(subscriptionData)) {
      paid = true;
      resolvedTier =
        resolvedTier || extractTierFromMetadata(subscriptionData.metadata);
    } else if (isRedirectStatusPaid(status)) {
      paid = true;
    }
  }

  if (!pendingDoc && !resolvedCheckoutId) {
    const recentPending = await findRecentPendingCheckout(uid);
    if (recentPending) {
      pendingDoc = recentPending;
      pendingRef = recentPending.ref;
      resolvedTier =
        resolvedTier || pendingDoc.data().planId || pendingDoc.data().tier;

      if (pendingDoc.data().status === 'completed') {
        paid = true;
      } else if (!paid && pendingDoc.data().checkoutId) {
        checkoutData = await fetchCheckoutById(
          dodo.baseUrl,
          dodo.headers,
          pendingDoc.data().checkoutId,
        );
        if (checkoutData && isCheckoutPaid(checkoutData)) {
          paid = true;
        }
      }
    }
  } else if (pendingDoc?.exists) {
    resolvedTier =
      resolvedTier || pendingDoc.data().planId || pendingDoc.data().tier;
    if (pendingDoc.data().status === 'completed') {
      paid = true;
    }
  }

  if (!paid) {
    const userDoc = await getFirestore().collection('users').doc(uid).get();
    const userData = userDoc.data() || {};
    if (
      userData.subscriptionStatus === 'active' &&
      userData.subscriptionTier &&
      userData.subscriptionTier !== 'free'
    ) {
      return {
        success: true,
        subscriptionTier: userData.subscriptionTier,
        subscriptionStatus: 'active',
        alreadyActive: true,
      };
    }
  }

  if (!resolvedTier || resolvedTier === 'free') {
    throw new HttpsError('invalid-argument', 'Unable to determine subscription plan.');
  }

  if (!paid) {
    throw new HttpsError(
      'failed-precondition',
      'Payment has not been completed yet. Please finish checkout first.',
    );
  }

  await activateUserSubscription(uid, resolvedTier, {
    ...(paymentId ? { dodoPaymentId: paymentId } : {}),
    ...(subscriptionId ? { dodoSubscriptionId: subscriptionId } : {}),
    ...(resolvedCheckoutId ? { dodoCheckoutId: resolvedCheckoutId } : {}),
  });

  const checkoutIdToComplete =
    resolvedCheckoutId || pendingDoc?.data()?.checkoutId || null;
  await markPendingCheckoutCompleted(uid, checkoutIdToComplete);

  return {
    success: true,
    subscriptionTier: resolvedTier,
    subscriptionStatus: 'active',
  };
}

exports.createUserCheckout = onCall({ region: 'us-central1' }, async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'You must be signed in to subscribe.');
  }

  if (request.auth.token.firebase?.sign_in_provider === 'anonymous') {
    throw new HttpsError(
      'permission-denied',
      'Please create an account before subscribing.',
    );
  }

  const { tier, planId, successUrl, cancelUrl } = request.data || {};
  return performCreateUserCheckout({
    uid: request.auth.uid,
    tier,
    planId,
    successUrl,
    cancelUrl,
  });
});

exports.completeUserCheckout = onCall({ region: 'us-central1' }, async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'You must be signed in to complete checkout.');
  }

  const {
    checkoutId,
    sessionId,
    paymentId,
    subscriptionId,
    status,
    tier,
    planId,
  } = request.data || {};
  return performCompleteUserCheckout({
    uid: request.auth.uid,
    checkoutId,
    sessionId,
    paymentId,
    subscriptionId,
    status,
    tier,
    planId,
  });
});

exports.getRecipeGenerationStatus = onCall({ region: 'us-central1' }, async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'You must be signed in.');
  }

  if (request.auth.token.firebase?.sign_in_provider === 'anonymous') {
    throw new HttpsError('permission-denied', 'Create an account to track recipe generations.');
  }

  return getRecipeGenerationStatus(request.auth.uid);
});

exports.consumeRecipeGeneration = onCall({ region: 'us-central1' }, async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'You must be signed in.');
  }

  if (request.auth.token.firebase?.sign_in_provider === 'anonymous') {
    throw new HttpsError('permission-denied', 'Create an account to generate recipes.');
  }

  return consumeRecipeGeneration(request.auth.uid);
});

exports.dodoPaymentsWebhook = onRequest({ cors: false }, async (req, res) => {
  if (req.method !== 'POST') {
    res.status(405).send('Method not allowed');
    return;
  }

  try {
    const dodo = await loadDodoSettings();
    if (dodo.error) {
      res.status(dodo.status || 500).send(dodo.error);
      return;
    }

    const rawBody = req.rawBody
      ? req.rawBody.toString('utf8')
      : JSON.stringify(req.body || {});
    const webhookSecret = dodo.settings.dodo_webhook_secret;

    if (
      webhookSecret &&
      !verifyDodoWebhookSignature(rawBody, req.headers, webhookSecret)
    ) {
      console.error('Invalid DodoPayments webhook signature');
      res.status(401).send('Invalid signature');
      return;
    }

    res.status(200).send('OK');

    const event = JSON.parse(rawBody);
    const eventType = event.type;
    const payload = event.data || {};

    switch (eventType) {
      case 'payment.succeeded':
      case 'subscription.active':
      case 'subscription.updated':
      case 'subscription.renewed':
        await activateSubscriptionFromWebhookPayload(payload);
        break;
      case 'subscription.cancelled':
      case 'subscription.canceled':
        await handleSubscriptionCancelled(payload);
        break;
      default:
        console.log(`Unhandled DodoPayments webhook event: ${eventType}`);
    }
  } catch (error) {
    console.error('DodoPayments webhook error:', error);
    if (!res.headersSent) {
      res.status(500).send('Webhook processing failed');
    }
  }
});

async function handleSubscriptionCancelled(payload) {
  const metadata =
    payload.metadata ||
    payload.checkout?.metadata ||
    payload.checkout_metadata ||
    {};
  const userId = metadata.userId;
  if (!userId) return;

  await getFirestore()
    .collection('users')
    .doc(userId)
    .set(
      {
        subscriptionStatus: 'cancelled',
        subscriptionUpdatedAt: new Date(),
      },
      { merge: true },
    );
}
