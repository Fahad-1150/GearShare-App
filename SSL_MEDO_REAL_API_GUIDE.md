# SSL Medo Real API Implementation Guide

## Quick Start

### 1. Get SSL Credentials

First, you need an SSL Medo (sslcommerz) account:

```
Website: https://www.sslcommerz.com/
1. Sign up for merchant account
2. Complete KYC verification
3. Receive: Store ID & Store Password
```

**Test Credentials Format:**
```
Store ID: testbox
Store Password: testpass
API: https://sandbox.sslcommerz.com/gwprocess/v4/api.php
```

### 2. Configure Your App

Edit `lib/services/ssl_payment_service.dart`:

```dart
// Replace these with your actual credentials
static const String storeId = 'YOUR_STORE_ID_HERE';
static const String storePassword = 'YOUR_STORE_PASSWORD_HERE';

// For testing use: true
// For production use: false
static const bool isTestMode = true;
```

### 3. Test Payment Flow

The payment flow works as follows:

```
1. User clicks "Complete Payment"
   ↓
2. App fetches user details from Supabase
   ↓
3. Payment request sent to SSL API with:
   - Store ID & Password
   - Amount
   - Customer info
   - Transaction ID
   - Callback URLs
   ↓
4. SSL returns payment gateway URL
   ↓
5. User's browser opens SSL payment gateway
   ↓
6. User enters card details
   ↓
7. SSL processes payment
   ↓
8. User redirected to success/fail URL
   ↓
9. Database updated with payment status
```

## Test Cards for Sandbox

Use these test card details in sandbox mode:

### Visa Card
```
Card Number:     4111111111111111
Expiry:          Any future date (MM/YY)
CVV:             Any 3 digits
Card Holder:     Test User
```

### Mastercard
```
Card Number:     5555555555554444
Expiry:          Any future date (MM/YY)
CVV:             Any 3 digits
Card Holder:     Test User
```

## API Request Details

### Initiate Payment Request

**Endpoint:** 
```
https://sandbox.sslcommerz.com/gwprocess/v4/api.php (Test)
https://securepay.sslcommerz.com/gwprocess/v4/api.php (Production)
```

**Method:** POST

**Required Parameters:**
```
store_id              - Your Store ID
store_passwd          - Your Store Password  
total_amount          - Payment amount (BDT)
currency              - BDT (fixed)
tran_id               - Unique transaction ID (UUID/Timestamp)
cus_name              - Customer name
cus_email             - Customer email
cus_phone             - Customer phone
cus_addr1             - Address
cus_city              - City
cus_state             - State/Division
cus_postcode          - Postal code
cus_country           - Country
product_name          - Product/Equipment name
product_category      - Category
product_profile       - 'general' or specific profile
success_url           - URL after successful payment
fail_url              - URL after failed payment
cancel_url            - URL if user cancels
```

**Example Request:**
```
POST /gwprocess/v4/api.php HTTP/1.1
Host: sandbox.sslcommerz.com
Content-Type: application/x-www-form-urlencoded

store_id=testbox&store_passwd=testpass&total_amount=1000&currency=BDT&
tran_id=TXN_12345_1234567890&cus_name=John+Doe&cus_email=john@example.com&
cus_phone=01700000000&product_name=Camera+Rental&product_category=Electronics&
success_url=https://gearshare.app/success&fail_url=https://gearshare.app/fail&
cancel_url=https://gearshare.app/cancel
```

## Response Types

### Success Response
```
Status: REDIRECT_TO_AUTH
sessionkey=ABC123DEF456...
```

Redirect user to:
```
https://sandbox.sslcommerz.com/gwprocess/v4/api.php?sessionkey=ABC123DEF456
```

### Error Response
```
Status: FAILED
Reason: Invalid Store ID
```

## Production Checklist

### Before Going Live:

1. **Credentials**
   ```dart
   static const String storeId = 'YOUR_PRODUCTION_STORE_ID';
   static const String storePassword = 'YOUR_PRODUCTION_STORE_PASSWORD';
   static const bool isTestMode = false;
   ```

2. **API Endpoint**
   ```dart
   static const String productionApiUrl = 
     'https://securepay.sslcommerz.com/gwprocess/v4/api.php';
   ```

3. **Callback URLs**
   - Update to production domain
   - Ensure HTTPS
   - Make endpoints accessible

4. **Verification System**
   - Implement backend IPN handler
   - Verify transactions before activating rentals
   - Log all payment events

5. **Testing**
   - Do test transaction with production credentials
   - Verify payment appears in SSL dashboard
   - Check callback URLs work

## Common Issues & Solutions

### Issue: Payment Gateway Won't Open
**Solution:**
- Check internet connection
- Verify store ID is correct
- Ensure callback URLs are valid URLs
- Check if URL launcher is configured

### Issue: "Invalid Store ID" Error
**Solution:**
- Copy store ID exactly from SSL dashboard
- No extra spaces or characters
- Verify you're using correct credentials

### Issue: Transaction Not Appearing in Dashboard
**Solution:**
- Check test vs production mode
- Verify store ID/password in request
- Check if transaction was actually processed
- Review SSL dashboard transaction history

### Issue: Payment Verification Always Fails
**Solution:**
- Implement backend verification
- Check response from SSL verification API
- Verify transaction ID format matches
- Review SSL documentation for status codes

## Advanced: Custom Payment Handler

To implement custom payment handling:

```dart
// In your backend/API
Future<PaymentResponse> handlePaymentCallback(
  String transactionId, 
  String status
) async {
  // Verify payment with SSL
  final verification = await SSLPaymentService.verifyPayment(
    transactionId: transactionId,
    amount: rentalAmount,
  );
  
  if (verification['success']) {
    // Update rental status
    await updateRentalPaymentStatus(rentalId, 'completed');
    return PaymentResponse.success();
  } else {
    return PaymentResponse.failed();
  }
}
```

## Integration with Supabase

The payment flow integrates with Supabase:

```dart
// After successful payment
await _supabase
    .from('rentals')
    .update({
      'payment_status': 'completed',
      'rental_status': 'accepted',
      'payment_time': DateTime.now().toIso8601String(),
      'transaction_id': transactionId,
    })
    .eq('id', rentalId);
```

## Logging & Debugging

The service logs payment events:

```
🔐 Initiating SSL Payment...
Rental ID: abc123def456
Amount: BDT 5000.00
Customer: John Doe (john@example.com)

✅ Payment Gateway URL: https://sandbox.sslcommerz.com/gwprocess/v4/api.php?sessionkey=ABC123...

🔍 Verifying Payment - Transaction ID: TXN_abc123_1234567890
✅ Verification Response: {status: VALID, ...}
```

## Useful Links

- **SSL Medo Official:** https://www.sslcommerz.com/
- **Developer Docs:** https://www.sslcommerz.com/developer/
- **Merchant Dashboard:** https://dashboard.sslcommerz.com/
- **Payment Status Codes:** See SSL documentation
- **Test Store Info:** Contact SSL support

## Support Contacts

**SSL Medo Support:**
- Email: support@sslcommerz.com
- Phone: +880-2-48314443
- Website: https://www.sslcommerz.com/

## Summary

✅ **What This Implementation Provides:**
- Real SSL Medo API integration
- Test mode for development
- Production mode for live payments
- Proper error handling
- Payment verification
- Supabase integration
- Complete logging

🚀 **Next Steps:**
1. Get SSL Medo credentials
2. Update store ID and password
3. Test with sandbox credentials
4. Deploy to production when ready
5. Monitor payments in SSL dashboard
