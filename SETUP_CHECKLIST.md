# 🎯 DodoPayment Setup Checklist

Use this checklist to set up your payment integration step-by-step.

## 📋 Pre-Setup

- [ ] Read `PAYMENT_INTEGRATION_SUMMARY.md` (overview of what was added)
- [ ] Read `DODOPAYMENT_QUICK_START.md` (5-minute guide)
- [ ] Have access to your admin panel

## 🔧 Initial Configuration

### Get DodoPayment Credentials
- [ ] Go to https://dashboard.dodopayments.com
- [ ] Sign up for a free account
- [ ] Navigate to **Developers** → **API Keys**
- [ ] Copy your **API Key** (starts with `dodo_sk_test_` for test mode)
- [ ] Copy your **Business ID** (starts with `bus_`)
- [ ] Note: Keep test credentials for now

### Configure in Admin Panel
- [ ] Open your admin panel (`/admin`)
- [ ] Click on **Settings** tab in the sidebar
- [ ] Scroll down to **DodoPayment Configuration** section
- [ ] Paste your **API Key** in the first field
- [ ] Paste your **Business ID** in the second field
- [ ] Ensure **Test Mode** toggle is ON (green)
- [ ] Click **Test Connection** button
- [ ] Verify you see "✅ Connected successfully" message
- [ ] Click **Save DodoPay Config** button

## 🛍️ Create Test Products

### Product 1: Pro Plan
- [ ] Go to **Payments** tab
- [ ] Click **Create Product** button
- [ ] Fill in:
  - Name: `Pro Plan`
  - Description: `Monthly subscription with premium features`
  - Price: `2900` (= $29.00)
  - Currency: `USD`
- [ ] Click **Create**
- [ ] Verify product card appears in the list

### Product 2: Elite Plan (Optional)
- [ ] Click **Create Product** again
- [ ] Fill in:
  - Name: `Elite Plan`
  - Description: `Ultimate subscription with all features`
  - Price: `4900` (= $49.00)
  - Currency: `USD`
- [ ] Click **Create**
- [ ] Verify product card appears in the list

## 💳 Test Checkout Flow

### Test Inline Checkout
- [ ] Click **Checkout** button on any product card
- [ ] Select **Inline Checkout** option
- [ ] Verify checkout page loads with:
  - Left side: Embedded payment form
  - Right side: Order summary
- [ ] Fill in the checkout form:
  - Email: `test@example.com`
  - Country: `United States`
  - ZIP: `10001`
  - Card: `4242 4242 4242 4242`
  - Expiry: `12/28`
  - CVV: `123`
  - Name: `Test User`
- [ ] Click **Complete Purchase** or **Pay Now**
- [ ] Verify payment processes successfully

### Test New Window Checkout
- [ ] Go back to **Payments** tab
- [ ] Click **Checkout** on a product again
- [ ] Select **New Window** option
- [ ] Verify checkout opens in a new tab
- [ ] Complete the same test payment flow
- [ ] Verify payment processes successfully

## 📊 Verify Dashboard

### Check DodoPayments Dashboard
- [ ] Go to https://dashboard.dodopayments.com
- [ ] Click on **Payments** in the sidebar
- [ ] Verify you see your test payments
- [ ] Check payment status is "Succeeded"
- [ ] Review payment details

### Check Your Admin Panel
- [ ] Go back to your **Payments** tab
- [ ] Click **Refresh** button
- [ ] Verify revenue cards update (if implemented)
- [ ] Check for any transactions in the table

## 🎨 Explore Features

### View Inline Checkout Demo
- [ ] Click **View Inline Demo** button
- [ ] Explore the inline checkout interface
- [ ] Notice real-time updates as you fill the form
- [ ] Check the security badges and order summary

### Test Product Management
- [ ] Create another test product with different price
- [ ] Try creating products in different currencies (EUR, GBP)
- [ ] Verify all products appear correctly

## 📱 Test Mobile Experience

### Mobile Checkout
- [ ] Open your admin panel on a mobile device (or use browser dev tools)
- [ ] Go to **Payments** tab
- [ ] Click **Checkout** on a product
- [ ] Verify inline checkout is responsive
- [ ] Complete a test payment on mobile
- [ ] Verify it works smoothly

## 🔐 Security Check

### Verify Secure Storage
- [ ] Go to Firebase Console
- [ ] Navigate to **Firestore Database**
- [ ] Find `admin_settings` collection
- [ ] Check `payment_settings` document
- [ ] Verify your credentials are stored there
- [ ] Check that API key is not visible in browser dev tools

### Test Connection Toggle
- [ ] Go to **Settings** tab
- [ ] Change a character in the API key
- [ ] Click **Test Connection**
- [ ] Verify you get an error message
- [ ] Restore the correct API key
- [ ] Test connection again - should succeed

## 📚 Documentation Review

### Read Integration Guide
- [ ] Open `DODOPAYMENT_INTEGRATION_GUIDE.md`
- [ ] Review the webhook setup section
- [ ] Understand the security best practices
- [ ] Note the troubleshooting tips

### Bookmark Resources
- [ ] Bookmark: https://docs.dodopayments.com
- [ ] Bookmark: https://dashboard.dodopayments.com
- [ ] Save Discord invite: https://discord.gg/bYqAp4ayYh
- [ ] Save support email: support@dodopayments.com

## 🚀 Going Live Preparation (When Ready)

### Before Going Live
- [ ] Test thoroughly with multiple products
- [ ] Test different payment methods
- [ ] Test error scenarios (declined cards)
- [ ] Set up webhooks (see integration guide)
- [ ] Create live products in DodoPayments dashboard

### Get Live Credentials
- [ ] In DodoPayments dashboard, switch to **Live Mode**
- [ ] Generate live API keys
- [ ] Copy live **API Key** and **Business ID**

### Update Admin Configuration
- [ ] Go to your admin **Settings** tab
- [ ] Update API Key with live credentials
- [ ] Update Business ID with live credentials
- [ ] Toggle **Test Mode** to OFF
- [ ] Click **Test Connection** to verify
- [ ] Click **Save DodoPay Config**

### Test Live Mode
- [ ] Create a test product in live mode
- [ ] Make a real payment (small amount)
- [ ] Verify payment appears in dashboard
- [ ] Verify webhooks are working (if set up)

## ✅ Final Verification

### Smoke Test
- [ ] Admin can configure DodoPayment credentials
- [ ] Admin can create products
- [ ] Admin can generate checkout sessions
- [ ] Inline checkout loads and works
- [ ] Payments process successfully
- [ ] Revenue tracking displays correctly
- [ ] No console errors in browser

### User Experience
- [ ] Checkout flow is smooth and intuitive
- [ ] Payment form is mobile-friendly
- [ ] Error messages are clear
- [ ] Success messages appear
- [ ] Navigation works correctly

## 🎓 Optional Advanced Features

### Webhook Implementation
- [ ] Set up webhook endpoint in your backend
- [ ] Register webhook URL in DodoPayments dashboard
- [ ] Subscribe to payment events
- [ ] Test webhook delivery
- [ ] Implement webhook handler logic

### Customer Management
- [ ] Add customer email collection
- [ ] Store payment history per user
- [ ] Create customer portal
- [ ] Implement subscription management

### Analytics Enhancement
- [ ] Add charts for revenue over time
- [ ] Track conversion rates
- [ ] Monitor failed payments
- [ ] Generate financial reports

## 🎉 Congratulations!

If you've completed all the items above, your DodoPayment integration is fully set up and ready to accept payments!

## 🆘 Troubleshooting

### Common Issues

**Issue**: Connection test fails
- [ ] Check API key is correct
- [ ] Verify you're in the right mode (test/live)
- [ ] Check internet connection
- [ ] Look at browser console for errors

**Issue**: Products don't appear
- [ ] Click the Refresh button
- [ ] Check browser console for API errors
- [ ] Verify API key has correct permissions

**Issue**: Inline checkout doesn't load
- [ ] Check browser console for errors
- [ ] Verify checkout URL is valid
- [ ] Clear browser cache
- [ ] Try in incognito mode

**Issue**: Payment fails
- [ ] Verify using correct test card number
- [ ] Check expiry date is in the future
- [ ] Try a different test card
- [ ] Check DodoPayments status page

## 📞 Get Help

If you're stuck:
1. Check the troubleshooting section in `DODOPAYMENT_INTEGRATION_GUIDE.md`
2. Review DodoPayments documentation
3. Ask in DodoPayments Discord community
4. Contact support@dodopayments.com

---

**Next Steps**: Once you've completed this checklist, you're ready to start accepting real payments! 🎊
