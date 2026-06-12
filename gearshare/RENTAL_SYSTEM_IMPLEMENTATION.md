# GearShare Booking System Implementation Guide

## Overview
This document provides a complete guide to the new rental/booking system implemented in the GearShare app. The system allows users to browse equipment and book items for rent with a complete workflow from request to completion.

---

## 📁 Files Created/Modified

### 1. **rent.sql** (NEW)
Location: `gearshare/rent.sql`

Contains the complete database schema for the rental system with the following tables:

#### Tables Created:
- **rentals**: Main table storing rental bookings
- **rental_activity_logs**: Tracks status changes and history
- **rental_payments**: Payment records for each rental

#### Key Features:
- ✅ Rental status tracking (requested, approved, pending, accepted, rejected, canceled_by_requester, running, completed, disputed)
- ✅ Payment status tracking (pending, processing, completed, processing_for_refund, refunded, canceled)
- ✅ Automatic equipment availability updates
- ✅ Row Level Security (RLS) policies for data protection
- ✅ Triggers for timestamp updates and equipment status changes

### 2. **rental.dart** (NEW)
Location: `gearshare/lib/models/rental.dart`

Dart model class for rental data:
- Handles JSON serialization/deserialization
- Provides status and payment status enums
- Includes helper methods for UI display (color, text display)
- Fully typed and null-safe

### 3. **rent_page.dart** (NEW)
Location: `gearshare/lib/pages/rent_page.dart`

The main booking interface with:
- **Date Selection**: Calendar picker for start and end dates
- **Price Calculation**: Automatic calculation with discount support
- **Booking Request**: Creates rental request in database
- **Price Summary**: Shows subtotal, discounts, and total amount
- **Responsive UI**: Mobile-optimized with dark theme

### 4. **my_requests_page.dart** (NEW)
Location: `gearshare/lib/pages/my_requests_page.dart`

Complete rental request management with 3 tabs:

**Tab 1: My Requests** (As Requester)
- View all rental requests you've made
- Cancel pending requests
- Complete payments for approved bookings
- Confirm equipment reception
- Complete rentals after dates pass

**Tab 2: Booking Requests** (As Owner)
- View rental requests for your equipment
- Approve or reject requests
- Confirm equipment given to requester
- Mark rentals as complete

**Tab 3: Active Rentals**
- View currently running rentals
- Track confirmation status
- Monitor rental progress

### 5. **equipment_details_page.dart** (MODIFIED)
Location: `gearshare/lib/pages/equipment_details_page.dart`

Changes:
- ✅ Added import for `rent_page.dart`
- ✅ Updated "Rent Now" button to "Book Now"
- ✅ Button now navigates to RentPage with equipment data
- ✅ Fully functional booking workflow

### 6. **dashboard_page.dart** (MODIFIED)
Location: `gearshare/lib/pages/dashboard_page.dart`

Changes:
- ✅ Added import for `my_requests_page.dart`
- ✅ Updated "Requests" tab (Tab 3) to show MyRequestsPage
- ✅ Integrated rental management into main dashboard

---

## 🔄 Complete Booking Workflow

### For Requesters (Users Booking Equipment):

```
1. Browse Equipment (Feed Page)
   ↓
2. Click Equipment → View Details
   ↓
3. Click "Book Now" → Opens RentPage
   ↓
4. Select Dates (Start & End)
   ↓
5. System Calculates Amount (with discounts)
   ↓
6. Click "Request Booking" → Creates request
   ↓
7. Check "My Requests" tab in Dashboard
   ↓
8. Wait for owner approval
   ↓
9. Upon approval → Click "Complete Payment"
   ↓
10. Payment Status → Completed
   ↓
11. Click "Confirm Received" (after owner confirms "given")
   ↓
12. Rental Status → Running
   ↓
13. After rental end date → Click "Complete Rental"
   ↓
14. Rental Status → Completed ✅
```

### For Owners (Equipment Owners):

```
1. Equipment Added to System
   ↓
2. Check "Booking Requests" tab in Dashboard
   ↓
3. Review new requests
   ↓
4. Approve or Reject request
   ↓
5. Upon payment completion (requester pays)
   ↓
6. Click "Confirm Given" (after giving equipment)
   ↓
7. Monitor rental status
   ↓
8. After rental period ends → Click "Complete Rental"
   ↓
9. Equipment automatically marked as "available" ✅
```

---

## 📊 Database Schema Summary

### Rentals Table
```
id (UUID)                          - Unique identifier
equipment_id (FK)                  - Link to equipment
owner_id (FK)                      - Equipment owner
requester_id (FK)                  - User requesting rental

start_date (DATE)                  - Rental start date
end_date (DATE)                    - Rental end date
total_days (INTEGER)               - Number of days

per_day_price (DECIMAL)            - Price per day
discount_percentage (INTEGER)      - Applied discount %
subtotal (DECIMAL)                 - Before discount
discount_amount (DECIMAL)          - Discount value
total_amount (DECIMAL)             - Final amount to pay

rental_status (ENUM)               - Status of rental
payment_status (ENUM)              - Payment status

payment_time (TIMESTAMP)           - When payment was made
payment_method (VARCHAR)           - Payment method used
transaction_id (VARCHAR)           - Payment transaction ID

owner_gave_confirmation_at         - When owner gave equipment
requester_received_confirmation_at - When requester received

notes (TEXT)                       - Additional notes
cancellation_reason (TEXT)         - Why it was canceled
refund_amount (DECIMAL)            - Refund amount
refund_processed_at (TIMESTAMP)    - When refund was processed

created_at, updated_at, completed_at - Timestamps
```

---

## 🔐 Security Features

### Row Level Security (RLS) Policies:

**Rentals Table:**
- ✅ Renters can only view their own requests
- ✅ Owners can only view requests for their equipment
- ✅ Only requesters can create bookings
- ✅ Limited update permissions based on status

**Activity Logs:**
- ✅ Users can only view logs for their rentals
- ✅ System auto-inserts activity records

**Payments:**
- ✅ Users can only view their payment records
- ✅ Requesters create payment records
- ✅ Both parties can update payment info

---

## 💰 Discount System

The system supports automatic discounts:

```dart
if (totalDays >= discountMinDays) {
    discountAmount = subtotal * (discountPercentage / 100);
    totalAmount = subtotal - discountAmount;
}
```

Example:
- Equipment: $50/day
- Discount: 10% for 7+ days
- Booking: 10 days = $500
- Discount: 10% = $50
- **Total: $450**

---

## 🚀 Setup Instructions

### 1. Database Setup

Run the SQL script in Supabase:

```bash
1. Go to Supabase Dashboard
2. Click "SQL Editor"
3. Create new query
4. Copy content from rent.sql
5. Click "Run" or "Ctrl+Enter"
```

### 2. Verify Installation

Check that these tables exist in Supabase:
- ✅ `rentals`
- ✅ `rental_activity_logs`
- ✅ `rental_payments`

Check that these types exist:
- ✅ `rental_status` (enum)
- ✅ `payment_status_enum` (enum)

### 3. Test the System

1. **Create Test Equipment**
   - Use "Add Equipment" in Dashboard
   - Set price and discount

2. **Create Test Rental**
   - Browse equipment in Feed
   - Click "Book Now"
   - Select dates
   - Submit request

3. **Check Status**
   - Go to Dashboard → "Requests" tab
   - View your rental requests
   - Test approval/rejection workflow

---

## 🎯 Key Features

### Automatic Features:
- ✅ Equipment status auto-updates when rental starts/ends
- ✅ Timestamps automatically updated on changes
- ✅ Activity logs auto-created for all changes
- ✅ Discount calculations automatic

### Manual Features:
- ✅ Owners approve/reject requests
- ✅ Requesters confirm receipt
- ✅ Owners confirm equipment given
- ✅ Both parties complete rentals

### Payment Integration Ready:
- ✅ Payment status tracking
- ✅ Transaction ID storage
- ✅ Payment method tracking
- ✅ Refund processing support
- *(Ready for Stripe/PayPal integration)*

---

## 📱 UI Components

### rent_page.dart Components:
- Equipment summary card
- Date range pickers
- Price breakdown display
- Request booking button
- Workflow guide

### my_requests_page.dart Components:
- 3-tab interface
- Rental status badges
- Payment status indicators
- Action buttons (context-aware)
- Empty states
- Pull-to-refresh

---

## 🐛 Status Handling

### Rental Statuses:
```
requested     → Initial state when user books
approved      → Owner accepts the request
pending       → Waiting for something
accepted      → Ready to use
rejected      → Owner declined
canceled_by_requester → Requester cancelled
running       → Currently rented
completed     → Finished & equipment returned
disputed      → Issue with rental
```

### Payment Statuses:
```
pending               → Waiting for payment
processing           → Payment being processed
completed            → Payment successful
processing_for_refund → Refund in process
refunded             → Money returned to user
canceled             → Payment was canceled
```

---

## 📝 Example Rental Flow with Data

```json
// 1. Create Rental Request
{
  "equipment_id": "eq-123",
  "owner_id": "user-owner",
  "requester_id": "user-renter",
  "start_date": "2024-06-20",
  "end_date": "2024-06-24",
  "total_days": 4,
  "per_day_price": 50.00,
  "discount_percentage": 0,
  "subtotal": 200.00,
  "total_amount": 200.00,
  "rental_status": "requested",
  "payment_status": "pending"
}

// 2. Owner Approves
{
  "rental_status": "approved"
}

// 3. Requester Pays
{
  "payment_status": "completed",
  "payment_time": "2024-06-19T10:30:00Z",
  "transaction_id": "TXN_1234567890",
  "rental_status": "accepted"
}

// 4. Owner Confirms Given
{
  "owner_gave_confirmation_at": "2024-06-20T09:00:00Z",
  "rental_status": "running"
}

// 5. Requester Confirms Received
{
  "requester_received_confirmation_at": "2024-06-20T10:00:00Z"
}

// 6. Complete Rental (After end date)
{
  "rental_status": "completed",
  "completed_at": "2024-06-24T18:00:00Z"
}
// Equipment automatically set to "available"
```

---

## ✅ Checklist for Full Implementation

- [x] Database schema created (rent.sql)
- [x] Rental model created (rental.dart)
- [x] Booking UI created (rent_page.dart)
- [x] Request management UI created (my_requests_page.dart)
- [x] Equipment details page updated
- [x] Dashboard integrated
- [x] Automatic equipment status updates
- [x] RLS security policies
- [x] Price calculations with discounts
- [x] Payment tracking
- [x] Confirmation workflows
- [ ] Payment gateway integration (Stripe/PayPal) - Ready for implementation
- [ ] Push notifications for status changes - Ready for implementation
- [ ] Email notifications - Ready for implementation

---

## 🔧 Future Enhancements

1. **Payment Gateway Integration**
   - Integrate Stripe or PayPal
   - Use `transaction_id` field for payment reference

2. **Notifications**
   - Add push notifications on status changes
   - Email notifications for important updates

3. **Reviews & Ratings**
   - Add rating system for rentals
   - Review feedback from both parties

4. **Dispute Resolution**
   - Support ticket system for disputes
   - Refund handling

5. **Analytics**
   - Rental history and statistics
   - Revenue tracking for owners
   - Usage patterns

6. **Insurance**
   - Equipment damage reports
   - Insurance integration

---

## 📞 Support & Troubleshooting

### Common Issues:

**Issue: "Rental status dropdown missing"**
- Solution: Ensure Supabase enums are created correctly

**Issue: "Can't see booking requests"**
- Solution: Check RLS policies are enabled and correct

**Issue: "Payment not updating"**
- Solution: Verify payment_status enum exists in database

**Issue: "Equipment not updating to available"**
- Solution: Check triggers are created and working

---

## 🎉 Success Indicators

When everything is working correctly, you should see:

1. ✅ "Book Now" button appears on equipment details
2. ✅ Can select dates and create booking request
3. ✅ Request appears in Dashboard "Requests" tab
4. ✅ Owners can approve/reject requests
5. ✅ Requesters can pay for approved bookings
6. ✅ Status changes reflect in real-time
7. ✅ Equipment becomes unavailable when renting
8. ✅ Equipment becomes available after completion

---

## 📚 Documentation Files

Related documentation files:
- `rent.sql` - Database schema
- `rental.dart` - Data model
- `rent_page.dart` - Booking interface
- `my_requests_page.dart` - Request management
- This file - Implementation guide

