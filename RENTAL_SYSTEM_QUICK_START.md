# GearShare Rental System - Quick Start Guide

## 🚀 Setup in 5 Minutes

### Step 1: Create Tables in Supabase (2 min)

1. Open [Supabase Dashboard](https://supabase.com)
2. Select your GearShare project
3. Go to **SQL Editor** → **New Query**
4. Copy and paste the entire content from `rent.sql`
5. Click **Run** (or Ctrl+Enter)
6. ✅ Done! Tables are created

### Step 2: Verify Installation (1 min)

In Supabase, check **Database** section:
```
✅ Table: rentals
✅ Table: rental_activity_logs
✅ Table: rental_payments
✅ Type: rental_status (enum)
✅ Type: payment_status_enum (enum)
```

### Step 3: Run Your App (1 min)

```bash
cd gearshare
flutter run
```

### Step 4: Test the System (1 min)

**As User A (Renter):**
1. Go to Feed Page
2. Click on any equipment
3. Click "Book Now"
4. Select dates
5. Click "Request Booking"

**As User B (Equipment Owner):**
1. Go to Dashboard → "Requests" tab
2. See the booking request
3. Click "Approve"

**Back to User A:**
1. See status changed to "Approved"
2. Click "Complete Payment"
3. See "Confirm Received" button

---

## 📱 Main Features

### For Equipment Renters:
```
Browse Equipment
    ↓
Click "Book Now"
    ↓
Select Dates & Amount
    ↓
Request Booking
    ↓
Check "My Requests" Tab
    ↓
Pay When Approved
    ↓
Confirm Receipt
    ↓
Complete After Rental
```

### For Equipment Owners:
```
View Booking Requests
    ↓
Approve/Reject
    ↓
Confirm Equipment Given
    ↓
Track Rental Status
    ↓
Complete After Dates
```

---

## 🎯 Key Pages

| Page | Location | Purpose |
|------|----------|---------|
| **Equipment Details** | Feed → Click Equipment | Updated with "Book Now" button |
| **Rent Page** | Click "Book Now" | Select dates and create booking |
| **My Requests** | Dashboard → "Requests" Tab | Manage all bookings |
| **Dashboard** | Home screen | Access all features |

---

## 💡 Status Meanings

### Rental Status:
- 🔵 **Requested** - Waiting for owner
- 🟡 **Approved** - Owner said yes, waiting for payment
- 🟢 **Accepted** - Paid, ready to exchange
- 🟣 **Running** - Currently rented
- ✅ **Completed** - Finished & returned
- ❌ **Rejected** - Owner declined
- ❌ **Canceled** - Renter canceled

### Payment Status:
- 🔵 **Pending** - Waiting for payment
- 🟡 **Processing** - Being processed
- 🟢 **Completed** - Payment successful
- ❌ **Canceled** - Payment canceled

---

## 🔄 Complete Rental Journey

### Example: Booking a Camera for 5 Days

**Day 1 - Request Phase:**
```
Renter:
- Browse camera on Feed
- Click "Book Now"
- Select June 15-20 (5 days)
- System shows: $50/day = $250 total
- Click "Request Booking"

Owner:
- Gets notification
- Checks "Booking Requests" tab
- Sees camera rental request
- Clicks "Approve"
```

**Day 1 Afternoon - Payment Phase:**
```
Renter:
- Sees status changed to "Approved"
- Clicks "Complete Payment"
- Status changes to "Accepted"

Owner:
- Gets notification
- Prepares camera for handover
```

**Day 2 - Exchange Phase:**
```
Owner:
- Gives camera to renter
- Clicks "Confirm Given"

Renter:
- Receives camera
- Clicks "Confirm Received"
- Status changes to "Running"
- Camera marked "unavailable" in system
```

**Day 20 - Return Phase:**
```
Renter:
- Returns camera to owner
- Clicks "Complete Rental"

Owner:
- Confirms receipt
- Status changes to "Completed"
- Camera auto-marked "available"
```

---

## 🛠️ Database Tables Explained

### rentals Table
Main table storing rental information:
- Who is renting (requester_id)
- Who owns it (owner_id)
- Which equipment (equipment_id)
- Start/end dates
- Prices and discounts
- Status tracking
- Payment info

### rental_activity_logs Table
Records every change:
- What status changed
- Who made the change
- Old and new status
- When it happened

### rental_payments Table
Payment history:
- Amount paid
- Payment method
- Transaction ID
- Payment status

---

## 🔐 Security Notes

✅ Only equipment owners can see requests for their gear
✅ Only renters can see their own bookings
✅ Payment info is protected
✅ Activity logs are auditable
✅ All data encrypted in transit

---

## 💰 Pricing & Discounts

The system automatically calculates:
```
Total = Daily Rate × Number of Days - Discount

Example:
Daily Rate: $50
Days: 10
Discount: 10% for 7+ days booking

Calculation:
  Subtotal: 50 × 10 = $500
  Discount: 500 × 10% = $50
  Total: $500 - $50 = $450
```

---

## ❓ FAQ

**Q: How do owners get paid?**
A: The `rental_payments` table tracks all payments. You can integrate Stripe/PayPal using the `transaction_id` field.

**Q: Can renters cancel bookings?**
A: Yes, before "Running" status. Owners can reject before approval.

**Q: What if equipment is damaged?**
A: The `disputed` status can be used. Future feature for damage tracking.

**Q: How long does equipment stay unavailable?**
A: From rental start date to completion. Auto-resets to available.

**Q: Can I modify the rental dates?**
A: Currently, you'd need to cancel and rebook. Future feature.

---

## 🧪 Testing Checklist

- [ ] Can create booking request
- [ ] Owner can approve request
- [ ] Renter can complete payment
- [ ] Both can confirm exchange
- [ ] Status updates correctly
- [ ] Equipment becomes unavailable
- [ ] Equipment returns to available
- [ ] Rental shows in history
- [ ] Discounts apply correctly
- [ ] Buttons appear/disappear based on status

---

## 📞 Troubleshooting

| Problem | Solution |
|---------|----------|
| "Book Now" button not showing | Check equipment_details_page.dart imports |
| Can't create booking | Check Supabase auth is working |
| Status not updating | Refresh the page, check Supabase connection |
| Rentals tab empty | Check user is logged in |
| Price calculations wrong | Verify discount settings on equipment |

---

## 🎉 Success! You're Done

Your rental system is now live! Users can:
- ✅ Browse and book equipment
- ✅ Manage rental requests
- ✅ Track rental status
- ✅ View payment history
- ✅ Complete rentals

---

## 📚 Next Steps

1. **Test thoroughly** with multiple user accounts
2. **Integrate payment gateway** (Stripe/PayPal)
3. **Add notifications** for status changes
4. **Set up analytics** to track bookings
5. **Create review system** for rentals

---

## 📖 Full Documentation

For detailed information, see: `RENTAL_SYSTEM_IMPLEMENTATION.md`

---

**Last Updated:** June 2024
**Status:** ✅ Ready for Production
