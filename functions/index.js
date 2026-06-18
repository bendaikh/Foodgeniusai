const { onRequest, onCall, HttpsError } = require('firebase-functions/v2/https');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
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
  tier,
  planId,
}) {
  const resolvedCheckoutId = checkoutId || sessionId;

  const dodo = await loadDodoSettings();
  if (dodo.error) {
    throw new HttpsError('failed-precondition', dodo.error);
  }

  let resolvedTier = tier || planId || null;
  let checkoutData = null;

  if (resolvedCheckoutId) {
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
  }

  const pendingRef = resolvedCheckoutId
    ? getFirestore()
        .collection('pending_checkouts')
        .doc(`${uid}_${resolvedCheckoutId}`)
    : null;

  const pendingDoc = pendingRef ? await pendingRef.get() : null;
  if (!resolvedTier && pendingDoc?.exists) {
    resolvedTier = pendingDoc.data().planId || pendingDoc.data().tier;
  }

  if (checkoutData) {
    resolvedTier =
      resolvedTier ||
      checkoutData.metadata?.planId ||
      checkoutData.metadata?.tier ||
      checkoutData.metadata?.subscriptionTier;
  }

  if (!resolvedTier || resolvedTier === 'free') {
    throw new HttpsError('invalid-argument', 'Unable to determine subscription plan.');
  }

  const paid =
    (checkoutData && isCheckoutPaid(checkoutData)) ||
    (pendingDoc?.exists && pendingDoc.data().status === 'completed');

  if (!paid) {
    throw new HttpsError(
      'failed-precondition',
      'Payment has not been completed yet. Please finish checkout first.',
    );
  }

  await getFirestore()
    .collection('users')
    .doc(uid)
    .set(
      {
        subscriptionTier: resolvedTier,
        subscriptionStatus: 'active',
        subscriptionUpdatedAt: new Date(),
      },
      { merge: true },
    );

  if (pendingRef) {
    await pendingRef.set(
      {
        status: 'completed',
        completedAt: new Date(),
      },
      { merge: true },
    );
  }

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

  const { checkoutId, sessionId, tier, planId } = request.data || {};
  return performCompleteUserCheckout({
    uid: request.auth.uid,
    checkoutId,
    sessionId,
    tier,
    planId,
  });
});
