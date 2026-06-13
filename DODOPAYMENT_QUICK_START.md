# DodoPayment Quick Start Guide

## 🚀 Get Started in 5 Minutes

### Step 1: Get Your Credentials
1. Visit https://dashboard.dodopayments.com
2. Sign up for a free account
3. Go to **API Keys** section
4. Copy your **API Key** and **Business ID**

### Step 2: Configure in Admin Panel
1. Open your admin panel
2. Click on **Settings** tab
3. Scroll to **DodoPayment Configuration**
4. Paste your credentials:
   - API Key: `dodo_sk_...`
   - Business ID: `bus_...`
   - Keep **Test Mode** ON for testing
5. Click **Save DodoPay Config**
6. Click **Test Connection** to verify

### Step 3: Create Your First Product
1. Go to **Payments** tab
2. Click **Create Product**
3. Fill in:
   - Name: "Pro Subscription"
   - Description: "Access to premium features"
   - Price: 2900 (=$29.00)
   - Currency: USD
4. Click **Create**

### Step 4: Try the Checkout
1. Click **Checkout** on your product card
2. Select **Inline Checkout** to see the embedded experience
3. Use test card: `4242 4242 4242 4242`
4. Any future expiry date, any CVV

## ✨ What You Get

### In Admin Settings
- ✅ DodoPayment configuration panel
- ✅ Test connection button
- ✅ Test/Live mode toggle
- ✅ Secure credential storage

### In Payments Tab
- ✅ Product management (create, view)
- ✅ Checkout session creation
- ✅ Inline checkout demo
- ✅ Revenue analytics
- ✅ Subscription tracking

## 🎨 Inline Checkout Features

The inline checkout provides:
- **Embedded payment form** - No redirects
- **Auto tax calculation** - Based on customer location
- **Multiple payment methods** - Cards, PayPal, Apple Pay, Google Pay
- **Real-time updates** - Price breakdowns update live
- **Mobile responsive** - Works on all devices
- **PCI compliant** - DodoPayments handles security

## 📋 Test Cards

| Card Number | Scenario |
|-------------|----------|
| 4242 4242 4242 4242 | Success |
| 4000 0000 0000 0002 | Decline |
| 4000 0000 0000 9995 | Insufficient funds |

Use any:
- Future expiry date (e.g., 12/25)
- Any 3-digit CVV (e.g., 123)
- Any name

## 🔧 Key Files Created

1. **DodoPayment Service** (`lib/services/dodopayment_service.dart`)
   - API integration
   - Product management
   - Checkout creation

2. **Settings UI** (`lib/admin/screens/admin_settings_page.dart`)
   - Configuration interface
   - Credential management
   - Connection testing

3. **Payments Page** (`lib/admin/screens/admin_payments_page.dart`)
   - Product display
   - Checkout creation
   - Revenue tracking

4. **Inline Checkout Demo** (`lib/admin/screens/inline_checkout_demo_page.dart`)
   - Full checkout experience
   - Order summary
   - Real-time integration

## 🎯 Common Use Cases

### Use Case 1: Subscription Plans
```dart
// Create subscription product
await DodoPaymentService().createProduct(
  name: 'Monthly Pro Plan',
  description: 'Unlimited recipes, premium features',
  price: 2900, // $29.00
  currency: 'USD',
);
```

### Use Case 2: One-Time Purchase
```dart
// Create one-time product
await DodoPaymentService().createProduct(
  name: 'Recipe Pack',
  description: '100 exclusive recipes',
  price: 1499, // $14.99
  currency: 'USD',
);
```

### Use Case 3: Custom Checkout
```dart
// Create checkout with custom settings
final session = await DodoPaymentService().createCheckoutSession(
  items: [{'product_id': productId, 'quantity': 1}],
  successUrl: 'https://yourapp.com/success',
  cancelUrl: 'https://yourapp.com/cancel',
  customerEmail: 'user@example.com',
  metadata: {'user_id': '12345'},
);
```

## 🎓 Next Steps

1. **Create test products** to get familiar
2. **Try different payment methods** in test mode
3. **Set up webhooks** (see full guide)
4. **Switch to live mode** when ready
5. **Monitor revenue** in the Payments dashboard

## 🆘 Need Help?

- 📚 Full Guide: See `DODOPAYMENT_INTEGRATION_GUIDE.md`
- 🌐 Docs: https://docs.dodopayments.com
- 💬 Discord: https://discord.gg/bYqAp4ayYh
- 📧 Support: support@dodopayments.com

## 🎉 You're Ready!

Your admin panel now has full payment processing capabilities with DodoPayment. Start creating products and accepting payments!

---

**Pro Tip**: Keep Test Mode ON until you've thoroughly tested your checkout flow.
