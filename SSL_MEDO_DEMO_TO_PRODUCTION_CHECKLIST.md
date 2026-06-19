# SSL Medo Payment - Demo to Production Checklist

## Phase 1: Development & Testing (CURRENT)

- [x] SSL payment service created
- [x] Real API integration implemented
- [x] Test mode configured
- [x] Payment UI updated
- [x] Supabase integration added
- [x] Error handling implemented
- [x] Documentation created

**Current Status:** ✅ Ready for demo/testing

---

## Phase 2: Sandbox Testing

### Setup
- [ ] Visit https://www.sslcommerz.com/
- [ ] Sign up for merchant account
- [ ] Complete initial verification
- [ ] Receive test Store ID and Password
- [ ] Note the credentials

### Configuration
- [ ] Update `ssl_payment_service.dart`:
  ```dart
  static const String storeId = 'YOUR_TEST_STORE_ID';
  static const String storePassword = 'YOUR_TEST_PASSWORD';
  static const bool isTestMode = true;
  ```
- [ ] Or use test credentials: `testbox` / `testpass`

### Testing
- [ ] Run Flutter app: `flutter run`
- [ ] Create rental request
- [ ] Click "Complete Payment"
- [ ] Verify payment dialog appears
- [ ] Verify SSL gateway opens in browser
- [ ] Enter test card: `4111111111111111`
- [ ] Enter any future expiry date
- [ ] Enter any 3-digit CVV
- [ ] Complete payment in SSL gateway
- [ ] Verify redirect back to app
- [ ] Check Supabase - payment_status should be 'completed'
- [ ] Check rental_status should be 'accepted'
- [ ] View payment in SSL dashboard

### Verification
- [ ] Payment appears in SSL dashboard
- [ ] Transaction ID is correct
- [ ] Amount is correct
- [ ] Customer info is correct
- [ ] Log messages show successful flow

---

## Phase 3: Production Preparation

### Get Production Credentials
- [ ] Contact SSL Medo: support@sslcommerz.com
- [ ] Complete full KYC verification
- [ ] Provide:
  - Business documents
  - Director/Owner details
  - Bank account info
  - Website details
- [ ] Receive production Store ID
- [ ] Receive production Store Password
- [ ] Receive merchant dashboard access

### Update Code
- [ ] Update `ssl_payment_service.dart`:
  ```dart
  static const String storeId = 'YOUR_PRODUCTION_STORE_ID';
  static const String storePassword = 'YOUR_PRODUCTION_PASSWORD';
  static const bool isTestMode = false;
  ```

### Update URLs
- [ ] Update app domain (in `_initiateSSLPayment`):
  ```dart
  final successUrl = 'https://yourdomain.com/payment/success';
  final failUrl = 'https://yourdomain.com/payment/fail';
  final cancelUrl = 'https://yourdomain.com/payment/cancel';
  ```

### Backend Setup (Recommended)
- [ ] Create backend endpoint for IPN handling
- [ ] Implement payment verification
- [ ] Store transaction logs
- [ ] Set up error alerts
- [ ] Configure SSL dashboard IPN URL

### Security Review
- [ ] Move credentials to environment variables
- [ ] Implement backend payment verification
- [ ] Enable HTTPS on all URLs
- [ ] Add request signing if available
- [ ] Implement rate limiting
- [ ] Add transaction validation

### Testing in Production Mode
- [ ] Do NOT process real payments yet
- [ ] Test with production Store ID
- [ ] Verify responses match
- [ ] Test error scenarios
- [ ] Check logging

---

## Phase 4: Production Deployment

### Before Going Live
- [ ] Update Flutter app with production config
- [ ] Update callback URLs in code
- [ ] Deploy updated app to App Store/Play Store
- [ ] Test payment flow in production environment
- [ ] Configure SSL dashboard settings
- [ ] Set up payment notifications

### Go Live Checklist
- [ ] Production credentials configured
- [ ] Production API endpoint active
- [ ] Callback URLs are production domain
- [ ] SSL certificate is valid
- [ ] Backend IPN handler is ready
- [ ] Payment verification is working
- [ ] Error handling is in place
- [ ] Monitoring is configured
- [ ] Support contact info is available

### Launch Day
- [ ] Monitor transactions closely
- [ ] Check SSL dashboard every hour
- [ ] Monitor app logs for errors
- [ ] Have support team on standby
- [ ] Track first 10-20 transactions

---

## Phase 5: Production Monitoring

### Daily Checks
- [ ] Review transaction logs
- [ ] Check payment success rate
- [ ] Monitor failed payments
- [ ] Review error logs
- [ ] Check customer complaints

### Weekly Reviews
- [ ] Analyze payment patterns
- [ ] Review settlement status
- [ ] Check refund requests
- [ ] Monitor system performance
- [ ] Review SSL dashboard reports

### Monthly Maintenance
- [ ] Reconcile transactions
- [ ] Review settlement statements
- [ ] Update documentation
- [ ] Plan system improvements
- [ ] Contact SSL for support

---

## Rollback Plan

If issues occur in production:

1. **Immediate Actions**
   - [ ] Stop promoting payments
   - [ ] Notify users of temporary issue
   - [ ] Check SSL dashboard for errors
   - [ ] Review app logs

2. **Diagnosis**
   - [ ] Check network connectivity
   - [ ] Verify credentials are correct
   - [ ] Check callback URL status
   - [ ] Review SSL API status

3. **Recovery**
   - [ ] If code issue: rollback to previous version
   - [ ] If API issue: contact SSL support
   - [ ] If network issue: wait and retry
   - [ ] Communicate status to users

4. **Prevention**
   - [ ] Add monitoring alerts
   - [ ] Implement automatic retries
   - [ ] Improve error messages
   - [ ] Add health check endpoint

---

## Demo Credentials (For Testing)

```
Store ID: testbox
Store Password: testpass
API: https://sandbox.sslcommerz.com/gwprocess/v4/api.php

Test Card:
Number: 4111111111111111
Expiry: Any future (MM/YY)
CVV: Any 3 digits
```

---

## Useful Commands

### View Logs
```bash
# Flutter console logs
flutter run

# Supabase logs
# Check in Supabase dashboard
```

### Test Payment
```bash
# Manual test via curl
curl -X POST https://sandbox.sslcommerz.com/gwprocess/v4/api.php \
  -d "store_id=testbox&store_passwd=testpass&total_amount=100&currency=BDT&..."
```

### View SSL Dashboard
```
https://dashboard.sslcommerz.com/
- Login with your credentials
- View transactions
- Check settlement status
- Download reports
```

---

## Important Contacts

**SSL Medo Support**
- Email: support@sslcommerz.com
- Phone: +880-2-48314443
- Website: https://www.sslcommerz.com/

**Your SSL Account Manager**
- Will be provided during KYC verification
- Direct contact for production issues

**GearShare Support**
- Internal team to monitor payments
- Handle customer payment disputes

---

## Quick Reference

### Configuration Locations
- Production config: `lib/services/ssl_payment_service.dart`
- Environment vars: `.env` file
- Payment UI: `lib/pages/my_requests_page.dart`

### Test vs Production

| Aspect | Test | Production |
|--------|------|-----------|
| API URL | sandbox.sslcommerz.com | securepay.sslcommerz.com |
| Credentials | testbox/testpass | Your merchant credentials |
| Real Charges | No | Yes |
| Card Numbers | Test cards | Real cards |
| Data | Sandbox database | Production database |

### Status Codes
- REDIRECT_TO_AUTH - Payment initiated successfully
- FAILED - Payment failed
- EXPIRED_SESSION - Session timed out
- INVALID_AMOUNT - Amount validation failed

---

## Notes

- ✅ Demo mode is ready to use immediately
- ⏱️ Sandbox testing takes 30 minutes
- 📅 Production approval takes 3-7 days
- 💰 No setup fees for SSL Medo
- 🔐 All payments are secure and encrypted

**Status: Ready for Testing Phase** ✅
