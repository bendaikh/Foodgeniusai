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

async function claimPendingRecipe(userId) {
  const pendingRef = getFirestore().collection('pending_recipes').doc(userId);
  const pendingDoc = await pendingRef.get();
  if (!pendingDoc.exists) return null;

  const data = pendingDoc.data() || {};
  const clientId = data.clientId || data.id || null;

  if (clientId) {
    const existingRef = getFirestore().collection('recipes').doc(clientId);
    const existingDoc = await existingRef.get();
    if (existingDoc.exists) {
      await pendingRef.delete();
      return clientId;
    }
  }

  const { savedAt, clientId: _clientId, ...recipeFields } = data;
  if (!recipeFields.title) {
    await pendingRef.delete();
    return null;
  }

  const recipeDoc = {
    ...recipeFields,
    userId,
    createdAt: recipeFields.createdAt || new Date(),
  };

  if (clientId) {
    await getFirestore().collection('recipes').doc(clientId).set(recipeDoc);
    await pendingRef.delete();
    return clientId;
  }

  const docRef = await getFirestore().collection('recipes').add(recipeDoc);
  await pendingRef.delete();
  return docRef.id;
}

async function activateUserSubscription(uid, tier, extraFields = {}) {
  const userRef = getFirestore().collection('users').doc(uid);
  const userDoc = await userRef.get();
  const existingData = userDoc.exists ? userDoc.data() || {} : {};
  const existingUsed = existingData.monthlyGenerationsUsed || 0;

  const updates = {
    subscriptionTier: tier,
    subscriptionStatus: 'active',
    subscriptionUpdatedAt: new Date(),
    monthlyGenerationsUsed: existingUsed,
    generationPeriodStart: new Date(),
    ...extraFields,
  };

  // When RevenueCat reports a new billing-period start (renewal), reset the
  // Fridge Scan counter so quota refreshes with the subscription cycle.
  const incomingBilling = extraFields.subscriptionBillingPeriodStart;
  if (incomingBilling) {
    const newBillingStart =
      incomingBilling instanceof Date
        ? incomingBilling
        : new Date(incomingBilling);
    const previousBilling =
      existingData.subscriptionBillingPeriodStart?.toDate?.() || null;
    updates.subscriptionBillingPeriodStart = newBillingStart;

    if (
      previousBilling &&
      newBillingStart.getTime() > previousBilling.getTime()
    ) {
      updates.monthlyFridgeScansUsed = 0;
      updates.fridgeScanPeriodStart = newBillingStart;
      console.log('[FridgeScanQuota] billing period rolled — reset scans', {
        uid,
        tier,
        previousBilling: previousBilling.toISOString(),
        newBillingStart: newBillingStart.toISOString(),
      });
    } else if (!existingData.fridgeScanPeriodStart) {
      updates.fridgeScanPeriodStart = newBillingStart;
    }
  }

  await userRef.set(updates, { merge: true });

  try {
    await claimPendingRecipe(uid);
  } catch (error) {
    console.error('Failed to claim pending recipe for user', uid, error);
  }
}

function startOfCurrentMonth(date = new Date()) {
  return new Date(date.getFullYear(), date.getMonth(), 1);
}

function isSameMonth(a, b) {
  return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth();
}

/** Canonical RevenueCat tiers — server source of truth for paid quotas. */
const REVENUECAT_TIER_LIMITS = {
  basic: { recipes: 20, fridgeScans: 5 },
  pro: { recipes: null, fridgeScans: 20 }, // null = unlimited
  premium: { recipes: null, fridgeScans: null },
};

/** Highest → lowest. Used for restore / multi-product selection. */
const REVENUECAT_TIERS_BY_PRIORITY = ['premium', 'pro', 'basic'];

function isValidRevenueCatTier(tier) {
  return REVENUECAT_TIERS_BY_PRIORITY.includes(tier);
}

/**
 * Infer a tier from a store / package product identifier.
 * Checked in priority order so "premium" wins over a naive "pro" substring.
 */
function tierFromProductIdentifier(productId) {
  if (!productId || typeof productId !== 'string') return null;
  const id = productId.toLowerCase();
  if (id.includes('premium')) return 'premium';
  if (id.includes('pro')) return 'pro';
  if (id.includes('basic')) return 'basic';
  return null;
}

/**
 * Pick the highest tier among a list of product identifiers.
 * @returns {'basic'|'pro'|'premium'|null}
 */
function highestTierFromProductIds(productIds) {
  const ids = Array.isArray(productIds)
    ? productIds.filter((id) => typeof id === 'string' && id.length > 0)
    : [];
  const matched = new Set();
  for (const productId of ids) {
    const tier = tierFromProductIdentifier(productId);
    if (tier) matched.add(tier);
  }
  for (const tier of REVENUECAT_TIERS_BY_PRIORITY) {
    if (matched.has(tier)) return tier;
  }
  return null;
}

/**
 * Optional RevenueCat REST verification when a secret key is configured in
 * admin_settings/payment_settings.revenuecat_secret_api_key.
 *
 * @returns {Promise<'basic'|'pro'|'premium'|null|'unavailable'>}
 *   tier string when verified, null when subscriber has no recognized paid
 *   product, 'unavailable' when the API key is missing or the call failed.
 */
async function resolveTierFromRevenueCatApi(appUserId) {
  if (!appUserId) return 'unavailable';

  try {
    const settingsDoc = await getFirestore()
      .collection('admin_settings')
      .doc('payment_settings')
      .get();
    const secret =
      settingsDoc.exists
        ? settingsDoc.data().revenuecat_secret_api_key
        : null;
    if (!secret || typeof secret !== 'string') {
      return 'unavailable';
    }

    const response = await fetch(
      `https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(appUserId)}`,
      {
        headers: {
          Authorization: `Bearer ${secret}`,
          'Content-Type': 'application/json',
        },
      },
    );

    if (!response.ok) {
      console.error(
        'RevenueCat subscriber lookup failed',
        response.status,
        await response.text(),
      );
      return 'unavailable';
    }

    const body = await response.json();
    const subscriber = body.subscriber || {};
    const productIds = new Set();

    const entitlements = subscriber.entitlements || {};
    for (const [key, entitlement] of Object.entries(entitlements)) {
      if (!entitlement) continue;
      const expires = entitlement.expires_date
        ? new Date(entitlement.expires_date)
        : null;
      const active = !expires || expires.getTime() > Date.now();
      if (!active) continue;
      if (entitlement.product_identifier) {
        productIds.add(entitlement.product_identifier);
      }
      // Prefer the paid entitlement named `premium` when present.
      if (key === 'premium' && entitlement.product_identifier) {
        productIds.add(entitlement.product_identifier);
      }
    }

    const subscriptions = subscriber.subscriptions || {};
    for (const [productId, sub] of Object.entries(subscriptions)) {
      if (!sub) continue;
      const expires = sub.expires_date ? new Date(sub.expires_date) : null;
      const active = !expires || expires.getTime() > Date.now();
      if (active) productIds.add(productId);
    }

    return highestTierFromProductIds([...productIds]);
  } catch (error) {
    console.error('RevenueCat API tier resolve failed', error);
    return 'unavailable';
  }
}

/**
 * @returns {{ unlimited: boolean, limit: number|null }}
 * limit is null when unlimited; otherwise a non-negative monthly cap.
 */
function recipeLimitForTier(tier) {
  if (!tier || tier === 'free') {
    return { unlimited: false, limit: 0 };
  }

  if (Object.prototype.hasOwnProperty.call(REVENUECAT_TIER_LIMITS, tier)) {
    const recipes = REVENUECAT_TIER_LIMITS[tier].recipes;
    if (recipes === null) return { unlimited: true, limit: null };
    return { unlimited: false, limit: recipes };
  }

  // Legacy / Web Dodo plans: look up Firestore subscription_plans/{id}.
  return { unlimited: false, limit: null, needsFirestoreLookup: true };
}

/**
 * @returns {{ unlimited: boolean, limit: number|null }}
 *
 * RevenueCat tiers use REVENUECAT_TIER_LIMITS only. Unrecognized RevenueCat
 * profiles fail closed (limit 0) — never unlimited. Legacy non-RC paid tiers
 * (web/Dodo) keep unlimited fridge scans.
 */
function fridgeScanLimitForTier(tier, subscriptionSource) {
  if (!tier || tier === 'free') {
    return { unlimited: false, limit: 0 };
  }

  if (Object.prototype.hasOwnProperty.call(REVENUECAT_TIER_LIMITS, tier)) {
    const scans = REVENUECAT_TIER_LIMITS[tier].fridgeScans;
    if (scans === null) return { unlimited: true, limit: null };
    if (typeof scans === 'number' && scans >= 0) {
      return { unlimited: false, limit: scans };
    }
  }

  // Mis-synced / unknown RevenueCat plan must never unlock unlimited scans.
  if (subscriptionSource === 'revenue_cat' || isValidRevenueCatTier(tier)) {
    console.warn(
      'fridgeScanLimitForTier: unrecognized RevenueCat tier — denying scans',
      tier,
    );
    return { unlimited: false, limit: 0 };
  }

  // Legacy web / Dodo paid tiers without an explicit fridge product.
  return { unlimited: true, limit: null };
}

/**
 * Resolve Fridge Scan usage for the active billing period.
 *
 * Prefer RevenueCat `subscriptionBillingPeriodStart` (renewal / purchase
 * boundary). Fall back to calendar-month windows when billing data is absent
 * (legacy / web profiles).
 *
 * @returns {{ used: number, periodStart: Date }}
 */
function resolveFridgeScanPeriod(userData, now = new Date()) {
  let used = userData.monthlyFridgeScansUsed || 0;
  let periodStart = userData.fridgeScanPeriodStart?.toDate?.() || null;
  const billingStart =
    userData.subscriptionBillingPeriodStart?.toDate?.() || null;

  if (billingStart) {
    if (!periodStart || periodStart.getTime() < billingStart.getTime()) {
      used = 0;
      periodStart = billingStart;
    }
    return { used, periodStart };
  }

  if (!periodStart || !isSameMonth(periodStart, now)) {
    used = 0;
    periodStart = startOfCurrentMonth(now);
  }
  return { used, periodStart };
}

async function getPlanMonthlyGenerationLimit(planId) {
  const resolved = recipeLimitForTier(planId);
  if (!resolved.needsFirestoreLookup) {
    return resolved;
  }

  if (!planId || planId === 'free') {
    return { unlimited: false, limit: 0 };
  }

  const planDoc = await getFirestore()
    .collection('subscription_plans')
    .doc(planId)
    .get();

  if (planDoc.exists) {
    const limit = planDoc.data().monthlyGenerationLimit;
    if (typeof limit === 'number') {
      // Negative values mean unlimited for legacy admin plans.
      if (limit < 0) return { unlimited: true, limit: null };
      return { unlimited: false, limit };
    }
  }

  return { unlimited: false, limit: 0 };
}

function buildQuotaStatusPayload({
  unlimited,
  limit,
  used,
  tier,
  planId,
}) {
  if (unlimited) {
    return {
      unlimited: true,
      limit: null,
      used: String(used),
      remaining: null,
      tier,
      planId,
    };
  }

  const safeLimit = typeof limit === 'number' ? limit : 0;
  return {
    unlimited: false,
    limit: String(safeLimit),
    used: String(used),
    remaining: String(Math.max(0, safeLimit - used)),
    tier,
    planId,
  };
}

function periodUsed(userData, usedField, periodField, now) {
  let used = userData[usedField] || 0;
  const periodStart = userData[periodField]?.toDate?.() || null;
  if (periodStart && !isSameMonth(periodStart, now)) {
    used = 0;
  }
  return used;
}

async function getRecipeGenerationStatus(uid) {
  const userDoc = await getFirestore().collection('users').doc(uid).get();
  const userData = userDoc.data() || {};
  const tier = userData.subscriptionTier || 'free';
  const status = userData.subscriptionStatus || 'active';

  if (status !== 'active') {
    return buildQuotaStatusPayload({
      unlimited: false,
      limit: 0,
      used: 0,
      tier,
      planId: tier,
    });
  }

  const plan = await getPlanMonthlyGenerationLimit(tier);
  const now = new Date();
  const used = periodUsed(
    userData,
    'monthlyGenerationsUsed',
    'generationPeriodStart',
    now,
  );

  return buildQuotaStatusPayload({
    unlimited: plan.unlimited,
    limit: plan.limit,
    used,
    tier,
    planId: tier,
  });
}

async function consumeRecipeGeneration(uid) {
  const db = getFirestore();
  const userRef = db.collection('users').doc(uid);

  // Resolve plan outside the transaction (may read subscription_plans).
  const userSnap = await userRef.get();
  if (!userSnap.exists) {
    throw new HttpsError('not-found', 'User profile not found.');
  }
  const preview = userSnap.data();
  const previewTier = preview.subscriptionTier || 'free';
  const previewStatus = preview.subscriptionStatus || 'active';
  if (previewStatus !== 'active') {
    throw new HttpsError('permission-denied', 'Your subscription is not active.');
  }
  const plan = await getPlanMonthlyGenerationLimit(previewTier);

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

    if (!plan.unlimited && (plan.limit == null || plan.limit <= 0)) {
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

    if (!plan.unlimited && used >= plan.limit) {
      throw new HttpsError(
        'resource-exhausted',
        `You've used all ${plan.limit} AI recipe generations for this month. Your limit resets at the start of next month.`,
      );
    }

    const newUsed = used + 1;
    tx.update(userRef, {
      monthlyGenerationsUsed: newUsed,
      generationPeriodStart: periodStart,
      totalRecipesGenerated: FieldValue.increment(1),
      apiUsageCount: FieldValue.increment(1),
    });

    return buildQuotaStatusPayload({
      unlimited: plan.unlimited,
      limit: plan.limit,
      used: newUsed,
      tier,
      planId: tier,
    });
  });
}

async function getFridgeScanStatus(uid) {
  const userDoc = await getFirestore().collection('users').doc(uid).get();
  const userData = userDoc.data() || {};
  const tier = userData.subscriptionTier || 'free';
  const status = userData.subscriptionStatus || 'active';

  if (status !== 'active' || tier === 'free') {
    console.log('[FridgeScanQuota] status blocked', { uid, tier, status });
    return buildQuotaStatusPayload({
      unlimited: false,
      limit: 0,
      used: 0,
      tier,
      planId: tier,
    });
  }

  const plan = fridgeScanLimitForTier(tier, userData.subscriptionSource);
  const { used } = resolveFridgeScanPeriod(userData);
  const payload = buildQuotaStatusPayload({
    unlimited: plan.unlimited,
    limit: plan.limit,
    used,
    tier,
    planId: tier,
  });
  console.log('[FridgeScanQuota] status', {
    uid,
    activePlan: tier,
    scanLimit: plan.unlimited ? 'unlimited' : plan.limit,
    scansUsed: used,
    scansRemaining: payload.remaining,
    allowed: plan.unlimited || Number(payload.remaining) > 0,
  });
  return payload;
}

async function consumeFridgeScan(uid) {
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

    if (status !== 'active' || tier === 'free') {
      throw new HttpsError(
        'permission-denied',
        'Subscribe to a plan to use Fridge Scan.',
      );
    }

    const plan = fridgeScanLimitForTier(tier, userData.subscriptionSource);
    const { used, periodStart } = resolveFridgeScanPeriod(userData);

    if (!plan.unlimited) {
      if (plan.limit == null || plan.limit <= 0) {
        console.log('[FridgeScanQuota] consume blocked — no scan entitlement', {
          uid,
          activePlan: tier,
          scanLimit: plan.limit,
          scansUsed: used,
        });
        throw new HttpsError(
          'permission-denied',
          'Fridge Scan is not available on your plan.',
        );
      }
      if (used >= plan.limit) {
        console.log('[FridgeScanQuota] consume blocked — limit reached', {
          uid,
          activePlan: tier,
          scanLimit: plan.limit,
          scansUsed: used,
          scansRemaining: 0,
          allowed: false,
        });
        throw new HttpsError(
          'resource-exhausted',
          `You've used all ${plan.limit} Fridge Scans for this billing period. Upgrade your plan for more scans.`,
        );
      }
    }

    const newUsed = used + 1;
    tx.update(userRef, {
      monthlyFridgeScansUsed: newUsed,
      fridgeScanPeriodStart: periodStart,
    });

    const payload = buildQuotaStatusPayload({
      unlimited: plan.unlimited,
      limit: plan.limit,
      used: newUsed,
      tier,
      planId: tier,
    });
    console.log('[FridgeScanQuota] consume success', {
      uid,
      activePlan: tier,
      scanLimit: plan.unlimited ? 'unlimited' : plan.limit,
      scansUsed: newUsed,
      scansRemaining: payload.remaining,
      allowed: true,
    });
    return payload;
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

exports.getFridgeScanStatus = onCall({ region: 'us-central1' }, async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'You must be signed in.');
  }

  if (request.auth.token.firebase?.sign_in_provider === 'anonymous') {
    throw new HttpsError('permission-denied', 'Create an account to track Fridge Scans.');
  }

  return getFridgeScanStatus(request.auth.uid);
});

exports.consumeFridgeScan = onCall({ region: 'us-central1' }, async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'You must be signed in.');
  }

  if (request.auth.token.firebase?.sign_in_provider === 'anonymous') {
    throw new HttpsError('permission-denied', 'Create an account to use Fridge Scan.');
  }

  return consumeFridgeScan(request.auth.uid);
});

/**
 * Trusted write path for iOS RevenueCat purchase / restore.
 *
 * Clients may no longer write subscriptionTier/status (or related quota
 * fields) directly — Firestore rules block those keys. This callable is the
 * only normal-user path that activates a RevenueCat tier.
 *
 * Resolution order:
 * 1. If a RevenueCat secret key is configured, derive the tier from the
 *    subscriber's active products via the RevenueCat REST API.
 * 2. Otherwise derive from the client-supplied productIds (same mapping:
 *    premium > pro > basic).
 * 3. Fall back to the client-supplied tier only when it is a valid
 *    basic/pro/premium value AND at least one productId was provided that
 *    maps to that same tier (or productIds were empty but the tier is valid
 *    — still refuse unknown tiers).
 *
 * Never defaults a restore to premium.
 */
exports.syncRevenueCatSubscription = onCall(
  { region: 'us-central1' },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'You must be signed in.');
    }

    if (request.auth.token.firebase?.sign_in_provider === 'anonymous') {
      throw new HttpsError(
        'permission-denied',
        'Create an account to sync a subscription.',
      );
    }

    const uid = request.auth.uid;
    const requestedTier = request.data?.tier;
    const productIds = Array.isArray(request.data?.productIds)
      ? request.data.productIds
      : [];
    const appUserId =
      (typeof request.data?.appUserId === 'string' &&
        request.data.appUserId.trim()) ||
      uid;
    const billingPeriodStartMs = Number(request.data?.billingPeriodStartMs);
    const hasBillingPeriodStart =
      Number.isFinite(billingPeriodStartMs) && billingPeriodStartMs > 0;

    let resolvedTier = null;

    const apiTier = await resolveTierFromRevenueCatApi(appUserId);
    if (apiTier !== 'unavailable') {
      // API responded — trust it exclusively (null means no active paid plan).
      resolvedTier = apiTier;
    } else {
      // No secret / API unavailable: derive ONLY from verified product IDs.
      // Never accept a bare client-requested tier (prevents self-upgrade).
      // Same mapping as the app: premium > pro > basic.
      const fromProducts = highestTierFromProductIds(productIds);
      if (fromProducts) {
        resolvedTier = fromProducts;
        if (
          isValidRevenueCatTier(requestedTier) &&
          requestedTier !== fromProducts
        ) {
          console.log(
            'syncRevenueCatSubscription: client tier',
            requestedTier,
            'overridden by product-derived',
            fromProducts,
            'for',
            uid,
          );
        }
      }
    }

    if (!resolvedTier || !isValidRevenueCatTier(resolvedTier)) {
      throw new HttpsError(
        'failed-precondition',
        'No active recognized subscription product was found.',
      );
    }

    const activateExtras = {
      subscriptionSource: 'revenue_cat',
    };
    if (hasBillingPeriodStart) {
      activateExtras.subscriptionBillingPeriodStart = new Date(
        billingPeriodStartMs,
      );
    }

    await activateUserSubscription(uid, resolvedTier, activateExtras);

    return { success: true, tier: resolvedTier };
  },
);

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
