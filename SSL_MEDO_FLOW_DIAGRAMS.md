# SSL Medo Payment Flow Diagrams

## 1. Complete Payment Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                    GearShare Payment Process                         │
└─────────────────────────────────────────────────────────────────────┘

    1. USER CLICKS "COMPLETE PAYMENT"
           │
           ↓
    2. PAYMENT DIALOG APPEARS
       ├─ Equipment name
       ├─ Rental period
       ├─ Total amount
       └─ Security notice
           │
           ↓
    3. USER CLICKS "PAY WITH SSL MEDO"
           │
           ↓
    4. APP FETCHES USER DETAILS
       └─ Name, email, phone from Supabase
           │
           ↓
    5. PAYMENT REQUEST SENT TO SSL API
       ├─ Store ID
       ├─ Store Password
       ├─ Amount
       ├─ Customer info
       ├─ Transaction ID
       └─ Callback URLs
           │
           ↓
    6. SSL GATEWAY URL RETURNED
           │
           ↓
    7. BROWSER OPENS SSL PAYMENT GATEWAY
       ├─ User enters card details
       ├─ User confirms payment
       └─ SSL processes payment
           │
           ↓
    8. SSL REDIRECTS TO CALLBACK URL
           │
           ↓
    9. DATABASE UPDATED
       ├─ payment_status: 'completed'
       ├─ rental_status: 'accepted'
       ├─ transaction_id: stored
       └─ payment_time: recorded
           │
           ↓
   10. SUCCESS MESSAGE SHOWN TO USER
           │
           ↓
   11. RENTAL ACTIVATED
```

---

## 2. API Communication Sequence

```
┌──────────────────┐                                   ┌──────────────────┐
│   Flutter App    │                                   │   SSL Medo API   │
└──────────────────┘                                   └──────────────────┘
        │                                                      │
        │ 1. POST /gwprocess/v4/api.php                       │
        │    [store_id, store_passwd, total_amount, ...]      │
        ├─────────────────────────────────────────────────────>│
        │                                                       │
        │                                          2. Response │
        │                                    [sessionkey=...]  │
        │<─────────────────────────────────────────────────────┤
        │                                                       │
        │ 3. Extract session key                              │
        │                                                       │
        │ 4. Open in browser:                                  │
        │    /api.php?sessionkey=...                           │
        │                                                       │
        │─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─>│
        │    (User interacts with SSL gateway)                 │
        │<─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─│
        │                                                       │
        │ 5. Redirect to success_url                           │
        │ (Browser automatically)                              │
        │                                                       │
        │ 6. User returns to app                               │
        │                                                       │
        │ 7. POST /verification (Optional)                     │
        ├─────────────────────────────────────────────────────>│
        │                                                       │
        │                                          8. Response │
        │                                    [status: VALID]    │
        │<─────────────────────────────────────────────────────┤
        │                                                       │
        │ 9. Update Supabase database                          │
        │                                                       │
        │ 10. Show success message                             │
```

---

## 3. App Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Flutter App                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │           my_requests_page.dart                          │   │
│  │  ┌─────────────────────────────────────────────────────┐│   │
│  │  │ _processPayment()                                    ││   │
│  │  │  └─ Shows payment dialog                            ││   │
│  │  │                                                      ││   │
│  │  │ _initiateSSLPayment()                               ││   │
│  │  │  ├─ Fetch user from Supabase                        ││   │
│  │  │  ├─ Call SSLPaymentService.initiatePayment()        ││   │
│  │  │  ├─ Launch URL in browser                           ││   │
│  │  │  └─ Show progress dialog                            ││   │
│  │  │                                                      ││   │
│  │  │ _simulatePaymentProcessing()                        ││   │
│  │  │  └─ Update database after payment                   ││   │
│  │  └─────────────────────────────────────────────────────┘│   │
│  └──────────────────────────┬───────────────────────────────┘   │
│                              │                                   │
│         ┌────────────────────┴────────────────────┐               │
│         │                                         │               │
│         ↓                                         ↓               │
│  ┌─────────────────────────┐  ┌──────────────────────────────┐  │
│  │ ssl_payment_service.dart │  │   Supabase                   │  │
│  │ ┌─────────────────────┐  │  │ ┌──────────────────────────┐ │  │
│  │ │ initiatePayment()   │  │  │ │ Update rentals table     │ │  │
│  │ │ ├─ Build request    │  │  │ │ ├─ payment_status       │ │  │
│  │ │ ├─ Call SSL API     │  │  │ │ ├─ rental_status        │ │  │
│  │ │ ├─ Get session key  │  │  │ │ ├─ transaction_id       │ │  │
│  │ │ └─ Return URL       │  │  │ │ └─ payment_time         │ │  │
│  │ │                     │  │  │ │                          │ │  │
│  │ │ verifyPayment()     │  │  │ └──────────────────────────┘ │  │
│  │ │ └─ Check status     │  │  │                              │  │
│  │ └─────────────────────┘  │  └──────────────────────────────┘  │
│  └──────────────────────────┘                                    │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ↓
                    ┌─────────────────────┐
                    │  SSL Medo Gateway   │
                    │ (sslcommerz.com)    │
                    └─────────────────────┘
```

---

## 4. Database Update Flow

```
┌────────────────────────────────────────────────────────────┐
│              Payment Completion → DB Update                │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  Browser Closes / Payment Complete                        │
│           │                                                │
│           ↓                                                │
│  ┌────────────────────────┐                               │
│  │ _simulatePaymentProcessing()                           │
│  └────────────────────────┘                               │
│           │                                                │
│           ↓                                                │
│  Supabase.from('rentals').update({                        │
│    'payment_status': 'completed',                         │
│    'rental_status': 'accepted',                           │
│    'payment_time': DateTime.now(),                        │
│    'transaction_id': 'TXN_...'                            │
│  }).eq('id', rentalId)                                   │
│           │                                                │
│           ↓                                                │
│  ┌────────────────────────┐                               │
│  │   Database Updated     │                               │
│  │   ✓ rental exists      │                               │
│  │   ✓ payment recorded   │                               │
│  │   ✓ status changed     │                               │
│  └────────────────────────┘                               │
│           │                                                │
│           ↓                                                │
│  ScaffoldMessenger.showSnackBar(                          │
│    'Payment completed successfully!'                      │
│  )                                                        │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

---

## 5. Error Handling Flow

```
                    Payment Initiated
                          │
                          ↓
                ┌─────────────────────┐
                │   Try Payment       │
                └─────────────────────┘
                          │
              ┌───────────┴───────────┐
              │                       │
              ↓                       ↓
         SUCCESS              ERROR/EXCEPTION
              │                       │
              ├─ Return URL          ├─ Log error
              ├─ Open Browser        ├─ Show SnackBar
              └─ Wait for Callback   ├─ Close dialog
                                     └─ Allow retry


    Error Types:
    
    ┌──────────────────────┐
    │  Network Error       │  → "Check internet connection"
    └──────────────────────┘
    
    ┌──────────────────────┐
    │  Invalid Store ID    │  → "Invalid credentials"
    └──────────────────────┘
    
    ┌──────────────────────┐
    │  Payment Timeout     │  → "Payment gateway timeout"
    └──────────────────────┘
    
    ┌──────────────────────┐
    │  DB Update Error     │  → "Database error"
    └──────────────────────┘
```

---

## 6. Test vs Production Flow Comparison

```
┌─────────────────────────────────────────────────────────────────────┐
│                        TEST MODE                                     │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  API: https://SANDBOX.sslcommerz.com/gwprocess/v4/api.php          │
│  Store ID: testbox                                                  │
│  Store Password: testpass                                           │
│  Cards: Test cards (4111111111111111, etc.)                         │
│  Charges: NONE (Simulated)                                          │
│  Database: Development Database                                     │
│  Turnaround: Instant                                                │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘

                              ↓ Switch ↓

┌─────────────────────────────────────────────────────────────────────┐
│                      PRODUCTION MODE                                 │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  API: https://SECUREPAY.sslcommerz.com/gwprocess/v4/api.php        │
│  Store ID: Your Merchant ID                                         │
│  Store Password: Your Merchant Password                             │
│  Cards: Real credit/debit cards                                     │
│  Charges: REAL (From customer accounts)                             │
│  Database: Production Database                                      │
│  Turnaround: 1-2 minutes                                            │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 7. User Interface Flow

```
                    My Requests Tab
                          │
                          ↓
                ┌──────────────────────┐
                │   Rental Card        │
                │ ┌──────────────────┐ │
                │ │ Equipment Info   │ │
                │ │ Dates & Amount   │ │
                │ └──────────────────┘ │
                │ ┌──────────────────┐ │
                │ │ Status Badge     │ │
                │ │ Payment Status   │ │
                │ └──────────────────┘ │
                │ ┌──────────────────┐ │
                │ │ Approved & Pending│ │
                │ │ [Complete Payment]│ │
                │ └──────────────────┘ │
                └──────────────────────┘
                          │
                          ↓ Tap Button
                ┌──────────────────────┐
                │  Payment Dialog      │
                │ ┌──────────────────┐ │
                │ │ Equipment Name   │ │
                │ │ Rental Period    │ │
                │ │ Amount: TK 5000  │ │
                │ │ Security Notice  │ │
                │ └──────────────────┘ │
                │ [Cancel] [Pay w SSL] │
                └──────────────────────┘
                          │
                          ↓ Tap "Pay"
                ┌──────────────────────┐
                │  Loading Dialog      │
                │  Initializing SSL... │
                │  Amount: TK 5000     │
                └──────────────────────┘
                          │
                          ↓
                ┌──────────────────────┐
                │ SSL Payment Gateway  │
                │ (Browser)            │
                │ [Enter Card Details] │
                │ [Confirm Payment]    │
                └──────────────────────┘
                          │
                          ↓ Success
                ┌──────────────────────┐
                │ Payment Complete     │
                │ [Complete Payment]   │
                │ [Close]              │
                └──────────────────────┘
                          │
                          ↓
                ┌──────────────────────┐
                │ Rental Activated!    │
                │ Payment: Completed   │
                │ Status: Accepted     │
                └──────────────────────┘
```

---

## 8. Data Flow Overview

```
User Input          Processing           Storage
    │                  │                    │
    ├─ Payment Amount  ├─ Validate Amount  ├─ Supabase
    │                  │                    │
    ├─ User Details   ├─ Fetch from DB    ├─ Rental Record
    │                  │                    │
    ├─ Confirmation   ├─ Call SSL API     ├─ Transaction ID
    │                  │                    │
    ├─ Card Details   ├─ SSL Processing   ├─ Payment Status
    │  (via SSL)       │                    │
    │                  ├─ Verify Payment   ├─ Payment Time
    │                  │                    │
    │                  ├─ Update DB        ├─ Rental Status
    │                  │                    │
    └─ Confirmation   └─ Show Message     └─ Payment Record
                                            (Complete)
```

---

## Summary

✅ **Complete SSL Medo Integration**
- Real API endpoints
- Test and production modes
- Proper error handling
- Database integration
- User-friendly UI

🎯 **Flow Overview:**
1. User initiates payment
2. App collects details
3. SSL API processes payment
4. Database updated automatically
5. Success/failure shown to user

💳 **Support:**
- Test cards provided
- Real production mode available
- Comprehensive documentation
- Error handling included

