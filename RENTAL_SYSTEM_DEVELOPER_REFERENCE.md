# GearShare Rental System - Developer Reference

## 🔗 File Structure

```
gearshare/
├── rent.sql                                    # Database schema
├── lib/
│   ├── models/
│   │   ├── equipment.dart                      # (existing)
│   │   ├── chat.dart                           # (existing)
│   │   └── rental.dart                         # ✅ NEW - Rental data model
│   ├── pages/
│   │   ├── equipment_details_page.dart         # ✅ UPDATED - Added "Book Now"
│   │   ├── dashboard_page.dart                 # ✅ UPDATED - Added My Requests tab
│   │   ├── rent_page.dart                      # ✅ NEW - Booking interface
│   │   ├── my_requests_page.dart               # ✅ NEW - Request management
│   │   ├── add_equipment_page.dart             # (existing)
│   │   ├── chat_page.dart                      # (existing)
│   │   └── chat_detail_page.dart               # (existing)
│   └── services/
│       ├── supabase_service.dart               # (existing)
│       ├── equipment_service.dart              # (existing)
│       └── chat_service.dart                   # (existing)
├── RENTAL_SYSTEM_IMPLEMENTATION.md             # ✅ NEW - Full documentation
└── RENTAL_SYSTEM_QUICK_START.md                # ✅ NEW - Quick guide
```

---

## 🗄️ Database Relationships

```
                         ┌─────────────────────┐
                         │    equipment        │
                         │  (existing table)   │
                         │   id (FK)           │
                         │   owner_id (FK)    │
                         │   per_day_price     │
                         └──────────┬──────────┘
                                    │
                          ┌─────────▼──────────┐
                          │    rentals        │
                          │  ✅ NEW TABLE     │
                          │   equipment_id ─┘
                          │   owner_id ────┐
                          │   requester_id ┤
                          │   (status)     │
                          │   (payment)    │
                          └─────────┬──────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    │               │               │
        ┌───────────▼────────┐  ┌───▼────────────┐
        │ rental_activity_   │  │ rental_        │
        │    logs            │  │  payments      │
        │  ✅ NEW TABLE      │  │  ✅ NEW TABLE  │
        │  (audit trail)     │  │  (payment tx)  │
        └────────────────────┘  └────────────────┘
```

---

## 📦 Enums & Types

### RentalStatus (Dart)
```dart
enum RentalStatus {
  requested,
  approved,
  pending,
  accepted,
  rejected,
  canceledByRequester,
  running,
  completed,
  disputed
}
```

### PaymentStatusEnum (Dart)
```dart
enum PaymentStatusEnum {
  pending,
  processing,
  completed,
  processingForRefund,
  refunded,
  canceled
}
```

### SQL Enums
```sql
CREATE TYPE rental_status AS ENUM (
  'requested', 'approved', 'pending', 'accepted',
  'rejected', 'canceled_by_requester', 'running',
  'completed', 'disputed'
);

CREATE TYPE payment_status_enum AS ENUM (
  'pending', 'processing', 'completed',
  'processing_for_refund', 'refunded', 'canceled'
);
```

---

## 🔑 Key Functions & Methods

### rental.dart Methods

```dart
// Conversion methods
Rental.fromJson(Map<String, dynamic> json)
  → Creates Rental from JSON (from database)

rental.toJson()
  → Converts Rental to JSON (for database)

rental.getStatusDisplay()
  → Returns human-readable status string

rental.getStatusColor()
  → Returns Color for status badge UI

rental.getPaymentStatusDisplay()
  → Returns human-readable payment status

rental.getPaymentStatusColor()
  → Returns Color for payment badge UI
```

### rent_page.dart Methods

```dart
_calculateAmount()
  → Calculates total with discounts
  → Called when dates change

_selectStartDate(context)
  → Opens date picker for start date
  → Updates end date validation

_selectEndDate(context)
  → Opens date picker for end date
  → Ensures it's after start date

_requestBooking()
  → Creates rental record in Supabase
  → Shows confirmation dialog

_showBookingConfirmationDialog()
  → Displays booking summary
  → Allows user to proceed or cancel
```

### my_requests_page.dart Methods

```dart
_loadRentalRequests()
  → Fetches rentals where user is requester or owner
  → Updates UI with loaded data

_approveRequest(Rental)
  → Owner approves a request
  → Changes status to 'approved'

_rejectRequest(Rental)
  → Owner rejects a request
  → Changes status to 'rejected'

_cancelRequest(Rental)
  → Requester cancels request
  → Changes status to 'canceled_by_requester'

_processPayment(Rental)
  → Shows payment dialog
  → Updates payment_status to 'completed'

_confirmGiven(Rental)
  → Owner confirms they gave equipment
  → Changes status to 'running'

_confirmReceived(Rental)
  → Requester confirms receipt
  → Sets confirmation timestamp

_completeRental(Rental)
  → Marks rental as complete
  → Auto-updates equipment to available

_buildRentalCard(Rental, bool isOwner)
  → Renders rental UI card
  → Shows status and payment info
  → Displays action buttons

_buildActionButtons(Rental, bool isOwner)
  → Dynamically generates available buttons
  → Different buttons for owner vs requester
  → Buttons appear based on status
```

---

## 🎯 Key Business Logic

### Discount Calculation
```dart
if (totalDays >= equipment.discountMinDays) {
  discountAmount = subtotal * (discountPercentage / 100);
  totalAmount = subtotal - discountAmount;
} else {
  discountAmount = 0;
  totalAmount = subtotal;
}
```

### Status Transitions

**For Requester:**
```
requested ──(owner approval)──> approved
             ╱
        (owner rejection)
           ╲
            rejected
            
approved ──(payment)──> accepted

accepted ──(confirm given)──> running
          ─────────────────┘

running ──(after end_date)──> completed
```

**For Owner:**
```
awaiting approval ──(approve)──> pending approval
                  ──(reject)──> rejected
                  
pending payment ──(payment made)──> ready to give

exchange ──(confirm given)──> running

running ──(after end_date)──> completed
```

### RLS Security Rules

```sql
-- Renters see their requests
SELECT: requester_id = current_user_id

-- Owners see their equipment requests  
SELECT: owner_id = current_user_id

-- Only requesters can create
INSERT: requester_id = current_user_id

-- Limited updates based on status
UPDATE: NOT IN (running, completed, rejected)
```

---

## 🔌 API Integration Points

### Supabase Calls

```dart
// Create rental
_supabase.from('rentals').insert(rentalData)

// Load rentals
_supabase.from('rentals')
  .select()
  .eq('requester_id', userId)
  .order('created_at', ascending: false)

// Update rental
_supabase.from('rentals')
  .update({'rental_status': 'approved'})
  .eq('id', rentalId)

// Auto-updates equipment
// Trigger: update_equipment_after_rental()
```

### Future Payment Integration

```dart
// When implementing Stripe/PayPal:
String transactionId = 'txn_' + generateId();
await _supabase.from('rentals').update({
  'payment_status': 'completed',
  'transaction_id': transactionId,
  'payment_method': 'stripe', // or 'paypal'
  'payment_time': DateTime.now(),
}).eq('id', rentalId);
```

---

## 🧪 Testing Scenarios

### Scenario 1: Complete Successful Rental
```
1. User A books User B's camera
2. User B approves
3. User A pays
4. User A confirms received
5. User B confirms given
6. After dates pass → Both complete
7. Camera returns to available
```

### Scenario 2: Request Rejection
```
1. User A books equipment
2. User B rejects
3. Status → rejected
4. No payment needed
5. Can submit new request
```

### Scenario 3: Cancellation by Requester
```
1. User A books equipment
2. Still in "requested" state
3. User A clicks Cancel
4. Status → canceled_by_requester
5. No payment charged
```

### Scenario 4: Discount Applied
```
1. Equipment: $50/day, 10% off for 7+ days
2. Book 10 days
3. Subtotal: $500
4. Discount: $50
5. Total: $450
```

---

## 🐛 Common Bugs & Solutions

| Bug | Cause | Solution |
|-----|-------|----------|
| "Book Now" not showing | Import missing | Add `import 'rent_page.dart'` to equipment_details_page.dart |
| Rentals tab empty | Not logged in | Ensure user is authenticated |
| Status not updating | UI not refreshing | Call `_loadRentalRequests()` after update |
| Wrong calculations | Discount logic | Check `_calculateAmount()` formula |
| Buttons not showing | Status checking | Verify status enum values match database |
| Can't approve request | Not owner | Check `owner_id = current_user_id` in RLS |

---

## 📊 SQL Useful Queries

```sql
-- Get all rentals for a user
SELECT * FROM rentals
WHERE requester_id = 'user-id' OR owner_id = 'user-id';

-- Get pending approvals
SELECT * FROM rentals
WHERE rental_status = 'requested'
AND owner_id = 'user-id';

-- Get active rentals
SELECT * FROM rentals
WHERE rental_status = 'running'
AND DATE(end_date) >= TODAY();

-- Get revenue
SELECT SUM(total_amount)
FROM rentals
WHERE owner_id = 'user-id'
AND rental_status = 'completed';

-- Get activity log
SELECT * FROM rental_activity_logs
WHERE rental_id = 'rental-id'
ORDER BY created_at DESC;
```

---

## 🚀 Performance Tips

1. **Pagination**: Add `.range()` for large lists
2. **Caching**: Store equipment details locally
3. **Indexes**: Already created on frequently queried fields
4. **Real-time**: Use `.stream()` instead of `.select()` for live updates
5. **Filters**: Apply filters at database level, not in Dart

---

## 📝 Code Examples

### Creating a Rental
```dart
final rental = Rental(
  id: 'rental-123',
  equipmentId: 'eq-456',
  ownerId: 'owner-789',
  requesterId: 'renter-101',
  startDate: DateTime(2024, 6, 20),
  endDate: DateTime(2024, 6, 24),
  totalDays: 4,
  perDayPrice: 50.0,
  subtotal: 200.0,
  totalAmount: 200.0,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);
```

### Updating Rental Status
```dart
await _supabase
  .from('rentals')
  .update({'rental_status': 'approved'})
  .eq('id', rental.id);
```

### Loading Rentals
```dart
final data = await _supabase
  .from('rentals')
  .select()
  .eq('requester_id', currentUser.id)
  .order('created_at', ascending: false);

final rentals = (data as List)
  .map((r) => Rental.fromJson(r))
  .toList();
```

---

## 🔍 Debugging Tips

1. **Print statements**: Use `print()` to debug values
2. **Breakpoints**: Set breakpoints in VS Code
3. **Logs**: Check Supabase logs for SQL errors
4. **RLS**: Disable temporarily to test permissions
5. **Network**: Check Dart DevTools for network calls

---

## 📞 Support Resources

- Supabase Docs: https://supabase.com/docs
- Flutter Docs: https://flutter.dev/docs
- Dart Docs: https://dart.dev/guides

---

**Version:** 1.0
**Last Updated:** June 2024
**Status:** Production Ready ✅
