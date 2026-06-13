const { onRequest } = require('firebase-functions/v2/https');
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

// Helper to set CORS headers
const setCorsHeaders = (res) => {
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.set('Access-Control-Max-Age', '3600');
};

exports.dodoPaymentsProxy = onRequest({ cors: true }, async (req, res) => {
  // Handle preflight OPTIONS request
  if (req.method === 'OPTIONS') {
    setCorsHeaders(res);
    res.status(204).send('');
    return;
  }

  setCorsHeaders(res);

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
