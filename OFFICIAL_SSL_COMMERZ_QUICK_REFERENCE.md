# Official SSL Commerz - Quick Reference

## Installation Status

✅ **Already Installed:**
- `flutter_sslcommerz: ^3.0.2`
- `fluttertoast: ^8.2.2`

No additional installation needed!

## Configuration (30 seconds)

Edit: `lib/services/ssl_payment_service.dart`

```dart
// Line 18-19: Update credentials
static const String storeId = 'testbox';      // Your Store ID
static const String storePassword = 'qwerty'; // Your Password

// Line 22: Set mode
static SdkType sdkType = SdkType.testbox; // testbox or live

// Line 25: Set language (optional)
static String paymentLanguage = 'en'; // 'en' or 'bn'
```

## Test Now

```bash
flutter pub get
flutter run
```

## Test Card

```
Number:  4111111111111111
Expiry:  Any future date (MM/YY)
CVV:     Any 3 digits
```

## Integration Code

### In my_requests_page.dart

```dart
// Import the service
import '../services/ssl_payment_service.dart';

// Initiate payment
final result = await SSLPaymentService.initiatePayment(
  rental: rental,
  customerName: customerName,
  customerEmail: customerEmail,
  customerPhone: customerPhone,
);

// Handle result
if (result != null) {
  SSLPaymentService.handlePaymentResult(result);
  
  if (result.status?.toLowerCase() == 'success') {
    // Update database
    await _updatePaymentStatus(rental, result.tranID ?? 'UNKNOWN');
  }
}
```

## Payment Result

```dart
result.status         // 'success', 'failed', or 'closed'
result.tranID         // Transaction ID
result.amount         // Amount paid
result.currency       // BDT
result.cardType       // Card type used
result.cardNumber     // Last 4 digits
```

## Change Configuration at Runtime

```dart
// Switch to production
SSLPaymentService.setSdkType(SdkType.live);

// Switch language
SSLPaymentService.setPaymentLanguage('bn');
```

## Database Update After Payment

```dart
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

## Production Credentials

Get from: https://www.sslcommerz.com/

```dart
static const String storeId = 'production_store_id';
static const String storePassword = 'production_password';
static SdkType sdkType = SdkType.live;
```

## Supported Payment Methods

- Credit Cards (Visa, Mastercard, AmEx)
- Debit Cards
- Mobile Banking (bKash, Nagad, Rocket)
- Bank Transfer
- EMI/Installments

## Error Messages (Toast)

```
✅ Green:  "Payment Successful!"
❌ Red:    "Payment Error: [details]"
⚠️ Orange: "Payment Cancelled"
ℹ️ Blue:   "Payment Status: [status]"
```

## Debugging

Check console for logs:

```
🔐 Initiating SSL Commerz Payment...
✅ Payment Result: Status=success
💾 Updating payment status in database...
✅ Database updated successfully
```

## Common Issues

| Issue | Fix |
|-------|-----|
| Won't open | Check Store ID/Password |
| "Invalid Store ID" | Verify credentials exact |
| Payment "failed" | Try test card 4111111111111111 |
| Not in database | Check Supabase connection |

## Files Changed

- `pubspec.yaml` - Added flutter_sslcommerz, fluttertoast
- `lib/services/ssl_payment_service.dart` - Complete rewrite
- `lib/pages/my_requests_page.dart` - Updated payment flow

## Full Documentation

See: `SSL_COMMERZ_OFFICIAL_PACKAGE_GUIDE.md`

## Support

- SSL: support@sslcommerz.com
- Phone: +880-2-48314443
- Docs: https://www.sslcommerz.com/developer/

---

**You're ready to accept payments! 🎉**
