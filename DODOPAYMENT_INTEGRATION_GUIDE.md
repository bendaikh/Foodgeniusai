# DodoPayment Integration Guide

This guide explains how to use the DodoPayment integration in your GourmetAI admin panel.

## Overview

The DodoPayment integration allows you to:
- Accept payments and manage subscriptions
- Create and manage products
- Generate checkout sessions
- Use inline checkout for seamless payment experiences

## Setup Instructions

### 1. Get Your DodoPayment Credentials

1. Visit [DodoPayments Dashboard](https://dashboard.dodopayments.com)
2. Sign up or log in to your account
3. Navigate to **API Keys** section
4. Copy your:
   - API Key (starts with `dodo_sk_`)
   - Business ID (starts with `bus_`)

### 2. Configure DodoPayment in Admin Panel

1. Go to your admin panel
2. Navigate to **Settings** tab
3. Scroll to the **DodoPayment Configuration** section
4. Enter your credentials:
   - **API Key**: Your DodoPayment API key
   - **Business ID**: Your business identifier
   - **Test Mode**: Toggle ON for testing (uses sandbox), OFF for production
5. Click **Save DodoPay Config**
6. Click **Test Connection** to verify your credentials

## Features

### 1. Product Management

Create products that customers can purchase:

1. Go to **Payments** tab
2. Click **Create Product**
3. Fill in the details:
   - **Product Name**: e.g., "Pro Plan"
   - **Description**: Describe what the product offers
   - **Price**: Enter in cents (1200 = $12.00)
   - **Currency**: USD, EUR, etc.
4. Click **Create**

Your products will appear as cards with checkout buttons.

### 2. Creating Checkout Sessions

#### Option A: From Product Card
1. Click the **Checkout** button on any product card
2. Choose between:
   - **Inline Checkout**: Embedded checkout experience
   - **New Window**: Opens checkout in a new tab

#### Option B: Manual Creation
1. Click **Create Checkout** button
2. Follow the instructions to select a product

### 3. Inline Checkout Integration

The inline checkout embeds the payment form directly in your page.

#### How It Works:
1. When you click "Inline Checkout", you'll see:
   - **Left side**: Embedded checkout form from DodoPayments
   - **Right side**: Order summary with secure payment badge
   
2. The checkout form handles:
   - Customer information collection
   - Payment method selection (cards, PayPal, Apple Pay, Google Pay)
   - Tax calculation
   - PCI-compliant payment processing

#### Events Tracked:
- `checkout.opened`: Checkout loaded
- `checkout.form_ready`: Form ready for input
- `checkout.breakdown`: Price/tax updates
- `checkout.pay_button_clicked`: Payment initiated

### 4. Payment Methods Supported

DodoPayments automatically provides:
- **Credit/Debit Cards**: Visa, Mastercard, Amex
- **Digital Wallets**: Apple Pay, Google Pay
- **PayPal**
- **Local Payment Methods**: Based on customer location

## Testing

### Test Mode
When Test Mode is enabled:
- Uses `https://test.dodopayments.com` for checkouts
- No real charges are made
- Use test card numbers from DodoPayments docs

### Test Card Numbers
- **Success**: 4242 4242 4242 4242
- **Decline**: 4000 0000 0000 0002
- Use any future expiry date and any 3-digit CVV

## Integration Code Examples

### Creating a Checkout Session (Dart/Flutter)

```dart
final session = await DodoPaymentService().createCheckoutSession(
  items: [
    {
      'product_id': 'prod_123',
      'quantity': 1,
    }
  ],
  successUrl: 'https://yourapp.com/payment-success',
  cancelUrl: 'https://yourapp.com/payment-cancel',
  customerEmail: 'customer@example.com',
);

final checkoutUrl = DodoPaymentService().getCheckoutUrl(session['id']);
```

### Inline Checkout HTML Implementation

```html
<!DOCTYPE html>
<html>
<head>
    <script src="https://cdn.jsdelivr.net/npm/dodopayments-checkout@latest/dist/index.js"></script>
</head>
<body>
    <div id="dodo-inline-checkout"></div>
    
    <script>
        DodoPaymentsCheckout.DodoPayments.Initialize({
            mode: "test",
            displayType: "inline",
            onEvent: (event) => {
                if (event.event_type === "checkout.breakdown") {
                    console.log('Price breakdown:', event.data?.message);
                }
            }
        });
        
        DodoPaymentsCheckout.DodoPayments.Checkout.open({
            checkoutUrl: "https://test.dodopayments.com/session/cks_123",
            elementId: "dodo-inline-checkout"
        });
    </script>
</body>
</html>
```

## Webhook Setup

To receive payment notifications:

1. In your DodoPayments Dashboard, go to **Webhooks**
2. Add your endpoint URL: `https://yourapp.com/webhooks/dodopayment`
3. Subscribe to events:
   - `payment.succeeded`
   - `payment.failed`
   - `subscription.created`
   - `subscription.updated`
   - `subscription.cancelled`

### Webhook Handler Example

```dart
// In your backend (Firebase Cloud Functions recommended)
Future<void> handleDodoPaymentWebhook(Map<String, dynamic> webhook) async {
  final eventType = webhook['event_type'];
  final data = webhook['data'];
  
  switch (eventType) {
    case 'payment.succeeded':
      // Update user subscription status
      await updateUserSubscription(data['customer_id'], 'active');
      break;
      
    case 'subscription.cancelled':
      // Handle cancellation
      await updateUserSubscription(data['customer_id'], 'cancelled');
      break;
  }
}
```

## Security Best Practices

1. **Never expose API keys**: Store them in Firestore with proper security rules
2. **Use HTTPS**: Always use secure connections
3. **Verify webhooks**: Validate webhook signatures
4. **Test thoroughly**: Use test mode before going live

## Troubleshooting

### "DodoPayment Not Configured" Warning
- **Solution**: Go to Settings and configure your API credentials

### "Connection Test Failed"
- Check your API key is correct
- Ensure you're using the right mode (test/live)
- Verify your network connection
- Check DodoPayments status page

### "Failed to Create Product"
- Verify your API key has product creation permissions
- Check price is in cents (integer)
- Ensure currency code is valid (e.g., USD, EUR)

### Inline Checkout Not Loading
- Check browser console for errors
- Verify checkout URL is valid
- Ensure DodoPayments SDK loaded correctly
- Check network requests in browser dev tools

## Going Live

When you're ready for production:

1. Get your **live** API credentials from DodoPayments
2. Update admin settings with live credentials
3. Toggle **Test Mode** to OFF
4. Test with a real card (small amount)
5. Set up webhooks for production
6. Monitor transactions in DodoPayments Dashboard

## Support

- **DodoPayments Docs**: https://docs.dodopayments.com
- **Dashboard**: https://dashboard.dodopayments.com
- **Discord Community**: https://discord.gg/bYqAp4ayYh
- **Support Email**: support@dodopayments.com

## Additional Features

### Subscription Management
- View all subscriptions in Payments tab
- Monitor monthly recurring revenue (MRR)
- Track churn rate
- Manage customer subscriptions

### Analytics
- Revenue tracking
- Active subscriber count
- Average revenue per user (ARPU)
- Transaction history

### Payment Methods
DodoPayments intelligently routes payments to the best processor for optimal success rates.

## Files Structure

```
lib/
├── services/
│   └── dodopayment_service.dart       # Main DodoPayment service
├── admin/
│   └── screens/
│       ├── admin_settings_page.dart   # Configuration UI
│       ├── admin_payments_page.dart   # Payment management
│       └── inline_checkout_demo_page.dart  # Inline checkout demo
```

## Next Steps

1. **Configure your credentials** in Settings
2. **Create test products** to familiarize yourself
3. **Try the inline checkout** to see how it works
4. **Set up webhooks** for production readiness
5. **Go live** when ready!

---

**Need Help?** Check the DodoPayments documentation or reach out to their support team.
