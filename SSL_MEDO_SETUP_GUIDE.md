# SSL Medo Payment Integration Guide

## Overview
This guide explains how to integrate SSL Medo (sslcommerz) payment gateway with the GearShare Flutter app.

## What is SSL Medo?
SSL Medo (sslcommerz) is a popular payment gateway in Bangladesh that processes credit cards, debit cards, mobile banking, and other digital payment methods.

## Setup Instructions

### 1. Get SSL Medo Account
- Visit: https://www.sslcommerz.com/
- Sign up for a merchant account
- Complete KYC verification
- Receive your Store ID and Store Password

### 2. Configuration

#### Option A: Environment Variables (Recommended)
Create a `.env` file in your Flutter project root:
```
SSL_STORE_ID=your_store_id_here
SSL_STORE_PASSWORD=your_store_password_here
SSL_TEST_MODE=true
```

Install the `flutter_dotenv` package:
```bash
flutter pub add flutter_dotenv
```

#### Option B: Direct Configuration (Quick Testing)
Edit `lib/services/ssl_payment_service.dart`:
```dart
static const String storeId = 'YOUR_ACTUAL_STORE_ID';
static const String storePassword = 'YOUR_ACTUAL_STORE_PASSWORD';
static const bool isTestMode = true; // Set to false for production
```

### 3. API Endpoints

**Test Environment:**
```
https://sandbox.sslcommerz.com/gwprocess/v4/api.php
```

**Production Environment:**
```
https://securepay.sslcommerz.com/gwprocess/v4/api.php
```

### 4. Required Payment Parameters

The service sends the following to SSL Medo:
- `store_id`: Your merchant ID
- `store_passwd`: Your merchant password
- `total_amount`: Transaction amount in BDT
- `currency`: BDT (Bangladeshi Taka)
- `tran_id`: Unique transaction ID
- `cus_name`: Customer name
- `cus_email`: Customer email
- `cus_phone`: Customer phone
- `product_name`: Equipment name
- `product_category`: Equipment category
- `success_url`: URL after successful payment
- `fail_url`: URL after failed payment
- `cancel_url`: URL after cancelled payment

### 5. Testing

#### Demo/Sandbox Testing
Use test credit card details:
- Card Number: `4111111111111111`
- Expiry: Any future date (MM/YY)
- CVV: Any 3 digits
- Card Holder: Any name

#### Test Store IDs (if provided by SSL)
SSL Medo provides test store IDs for sandbox testing without real payments.

### 6. Payment Flow

1. User clicks "Complete Payment" button
2. User details are fetched from Supabase
3. Payment request is sent to SSL Medo
4. User is redirected to SSL payment gateway
5. User enters payment details and completes payment
6. SSL redirects to success/fail URL
7. Payment status is updated in database
8. User is shown confirmation message

### 7. IPN (Instant Payment Notification)

For production, set up IPN callbacks in your backend:
- SSL Medo sends payment confirmation to your server
- Your server updates the rental payment status
- Implement endpoint: `https://yourbackend.com/payment/ipn`

### 8. Security Considerations

✅ **What's Secure:**
- HTTPS for all API calls
- Store credentials never exposed to client
- Payment gateway handles sensitive card data
- Transaction IDs are unique per payment

⚠️ **To Add in Production:**
- Move store credentials to backend API
- Implement payment verification on backend
- Add IPN (Instant Payment Notification) callback
- Use HTTPS for all callback URLs
- Validate transaction amounts on backend
- Implement order validation before accepting payment

### 9. Troubleshooting

#### Payment Gateway Won't Open
- Check internet connection
- Verify store ID and password
- Ensure callback URLs are valid

#### Transaction Declined
- Verify card details are correct
- Check account has sufficient balance
- Ensure card is not blocked for international transactions

#### Payment Verification Fails
- Implement backend verification
- Check transaction logs in SSL dashboard
- Verify callback URLs are accessible

### 10. SSL Medo Dashboard

Access your merchant dashboard at:
```
https://dashboard.sslcommerz.com/
```

Monitor:
- Transaction history
- Settlement status
- Refunds
- Report generation

### 11. Production Checklist

- [ ] Replace store ID and password with production credentials
- [ ] Set `isTestMode = false` in ssl_payment_service.dart
- [ ] Update callback URLs to production domain
- [ ] Implement backend IPN handler
- [ ] Test complete payment flow
- [ ] Set up monitoring and alerts
- [ ] Configure refund policies
- [ ] Enable SSL certificate verification

### 12. Support

**SSL Medo Support:**
- Email: support@sslcommerz.com
- Phone: +880-2-48314443
- Website: https://www.sslcommerz.com/

**Integration Documentation:**
- https://www.sslcommerz.com/developer/

## Code Example

### Basic Payment Initiation
```dart
final paymentUrl = await SSLPaymentService.initiatePayment(
  rental: rental,
  customerName: 'John Doe',
  customerEmail: 'john@example.com',
  customerPhone: '01700000000',
  successUrl: 'https://gearshare.app/payment/success',
  failUrl: 'https://gearshare.app/payment/fail',
  cancelUrl: 'https://gearshare.app/payment/cancel',
);

if (paymentUrl != null) {
  await launchUrl(Uri.parse(paymentUrl));
}
```

### Payment Verification (Backend)
```dart
final result = await SSLPaymentService.verifyPayment(
  transactionId: 'TXN_12345_67890',
  amount: 5000.00,
);

if (result['success']) {
  // Update database - payment confirmed
  // Mark rental as accepted
}
```

## Notes

- All amounts are in BDT (Bangladeshi Taka)
- Transaction IDs must be unique across all transactions
- Test mode uses sandbox.sslcommerz.com
- Production uses securepay.sslcommerz.com
- Callback URLs must be accessible from the internet
- SSL certificates are verified (HTTPS required)
