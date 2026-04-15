# GearShare Equipment Management - Quick Reference Guide

## 🚀 Quick Start

### 1. Database Setup (5 minutes)
```bash
# 1. Open Supabase Dashboard
# 2. Go to SQL Editor
# 3. Create new query
# 4. Copy-paste equipment.sql content
# 5. Click Run
```

### 2. Install Dependencies (3 minutes)
```bash
flutter pub get
```

### 3. Run the App
```bash
flutter run
```

### 4. Test the Feature
```
1. Sign up or Sign in
2. Redirected to Dashboard
3. Click "Add Equipment" tab
4. Fill in sample data:
   - Select image
   - Name: "Mountain Bike"
   - Category: "Sports"
   - Price: "25.00"
   - Discount: "10" (after 7 days)
   - Status: "Available Now"
   - Location: "Downtown Park"
5. Click "Add Equipment"
6. View in Equipment tab
```

---

## 📊 Database Design Diagram

```
┌─────────────────────────────────┐
│         auth.users              │
│  (Supabase built-in)            │
│  - id (UUID)                    │
│  - email                        │
└────────────────┬────────────────┘
                 │ (one-to-many)
                 │
                 ▼
┌──────────────────────────────────┐
│       equipment (main)           │
│  - id (PK, UUID)                 │
│  - owner_id (FK → users)         │
│  - name                          │
│  - description                   │
│  - per_day_price                 │
│  - discount_percentage           │
│  - status (enum)                 │
│  - image_url                     │
│  - location_name                 │
│  - location_latitude             │
│  - location_longitude            │
│  - is_public (boolean)           │
│  - created_at                    │
│  - updated_at                    │
└────────────┬──────────────────────┘
             │ (one-to-one)
             │
             ▼
  ┌──────────────────────────────┐
  │   public_equipment (index)   │
  │  - id (PK, UUID)             │
  │  - equipment_id (FK, UNIQUE) │
  │  - owner_id (FK)             │
  │  - featured                  │
  │  - created_at                │
  └──────────────────────────────┘

┌──────────────────────────────────┐
│  equipment_images (future)       │
│  - id (PK, UUID)                 │
│  - equipment_id (FK)             │
│  - image_url                     │
│  - display_order                 │
│  - created_at                    │
└──────────────────────────────────┘

┌──────────────────────────────────┐
│ storage.equipment-images (bucket)│
│  JSON path structure:            │
│  equipment/{id}/{timestamp}.jpg  │
└──────────────────────────────────┘
```

---

## 🏗️ Code Architecture

```
lib/
│
├── main.dart ........................ App setup, routes
│   ├── Routes: /, /signin, /signup, /home, /dashboard
│   └── Navigation to DashboardPage after login
│
├── models/
│   └── equipment.dart .............. Data structure
│       ├── 18 properties
│       ├── fromJson()
│       ├── toJson()
│       └── calculateRentalPrice()
│
├── services/
│   ├── supabase_service.dart ....... Existing auth service
│   └── equipment_service.dart ...... Equipment CRUD
│       ├── getUserEquipment()
│       ├── getPublicEquipment()
│       ├── addEquipment()
│       ├── updateEquipment()
│       ├── deleteEquipment()
│       ├── uploadEquipmentImage()
│       ├── makeEquipmentPublic()
│       └── removeFromPublic()
│
└── pages/
    ├── sign_in_page.dart ........... Updated to /dashboard
    ├── sign_up_page.dart
    ├── dashboard_page.dart ......... Main 5-tab interface
    │   ├── Equipment Tab
    │   ├── Add Equipment Tab
    │   ├── Analytics Tab
    │   ├── Requests Tab
    │   └── History Tab
    └── add_equipment_page.dart ..... Equipment form
        ├── Image picker
        ├── Form fields (15+)
        ├── Validation
        ├── API calls
        └── Success feedback
```

---

## 🔵 Component Interactions

```
User Login
    │
    ▼
sign_in_page.dart
    │ (calls SupabaseService.signIn())
    ▼
Navigate to /dashboard
    │
    ▼
dashboard_page.dart (5 tabs)
    │
    └─► Equipment Tab
    │    │ (calls EquipmentService.getUserEquipment())
    │    └─► SupabaseService → Database
    │         └─► Equipment cards
    │
    └─► Add Equipment Tab
         │ (shows add_equipment_page.dart)
         │
         ▼
    add_equipment_page.dart
         │
         ├─► Image Picker
         │    └─► ImagePicker._pickImage()
         │
         ├─► Form Fields (name, price, etc.)
         │    └─► TextFormField widgets
         │
         └─► Submit
              │
              ├─► Image Upload
              │    └─► EquipmentService.uploadEquipmentImage()
              │         └─► Supabase Storage
              │
              ├─► Equipment Save
              │    └─► EquipmentService.addEquipment()
              │         └─► Supabase Database
              │
              └─► Public Equipment (if is_public)
                   └─► EquipmentService.makeEquipmentPublic()
                        └─► Supabase Database
```

---

## 🧪 Class Reference

### Equipment Model
```dart
Equipment {
  String id
  String ownerId
  String name
  String? description
  String? category
  double perDayPrice
  int discountPercentage
  int discountMinDays
  String status
  DateTime? availableFrom
  String? imageUrl
  String? locationName
  double? locationLatitude
  double? locationLongitude
  String? pickupAddress
  bool isPublic
  DateTime createdAt
  DateTime updatedAt
  
  Methods:
  - fromJson(Map)
  - toJson() → Map
  - calculateRentalPrice(int days) → double
}
```

### EquipmentService
```dart
class EquipmentService {
  // Queries
  - Future<List<Equipment>> getUserEquipment(String userId)
  - Future<List<Equipment>> getPublicEquipment({int limit, int offset})
  - Future<Equipment?> getEquipmentById(String equipmentId)
  
  // Mutations
  - Future<Equipment> addEquipment({...})
  - Future<Equipment> updateEquipment({...})
  - Future<void> deleteEquipment(String equipmentId)
  
  // Media
  - Future<String> uploadEquipmentImage({...})
  
  // Public Feed
  - Future<void> makeEquipmentPublic(String id, String ownerId)
  - Future<void> removeFromPublic(String equipmentId)
}
```

---

## 📝 Form Fields Reference

| Field | Type | Required | Validation |
|-------|------|----------|-----------|
| Image | File | No | Image picker |
| Name | String | Yes | Non-empty |
| Category | String | No | Any |
| Description | String | No | Max 500 chars |
| Price | Double | Yes | > 0 |
| Discount % | Int | No | 0-100 |
| Min Days | Int | No | > 0 |
| Status | Enum | Yes | 3 options |
| Available From | Date | Conditional | Future date |
| Location Name | String | No | Any |
| Address | String | No | Any |
| Latitude | Double | No | -90 to 90 |
| Longitude | Double | No | -180 to 180 |
| Public | Boolean | Yes | Default true |

---

## 🔑 Key Code Examples

### Fetching Equipment
```dart
final service = EquipmentService();
final equipment = await service.getUserEquipment(userId);
```

### Adding Equipment
```dart
final equipment = await service.addEquipment(
  ownerId: userId,
  name: 'Mountain Bike',
  perDayPrice: 25.0,
  discountPercentage: 10,
  isPublic: true,
);
```

### Uploading Image
```dart
final imageUrl = await service.uploadEquipmentImage(
  equipmentId: equipment.id,
  imagePath: pickedFile.path,
);
```

### Calculating Price
```dart
final price = equipment.calculateRentalPrice(10); // 10-day rental
// Returns: (basePrice * days) - discount (if applicable)
```

---

## 🚨 Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| Image upload fails | Check storage bucket exists and RLS enabled |
| Equipment not saved | Verify all required fields filled (name, price) |
| Can't see equipment | Check is_public=true and status='available' |
| Coordinates invalid | Ensure lat: -90~90, lng: -180~180 |
| Price shows incorrectly | Ensure double type (25.00 not 25) |
| Form won't submit | Check all validations pass |

---

## 📱 Screen Flow

```
Landing Page
    │
    ├─► Sign In
    │    │
    │    └─► Dashboard
    │         │
    │         ├─► Equipment Tab (view equipment)
    │         │    └─► Edit/Delete
    │         │
    │         ├─► Add Equipment Tab (form)
    │         │    └─► Pick Image → Fill Form → Submit
    │         │
    │         ├─► Analytics Tab (coming soon)
    │         ├─► Requests Tab (coming soon)
    │         └─► History Tab (coming soon)
    │
    └─► Sign Up
         │
         └─► Sign In
              │
              └─► Dashboard
```

---

## 🌐 API Endpoints (Supabase)

```
Database:
- GET  /rest/v1/equipment?owner_id=eq.{userId}
- GET  /rest/v1/equipment?is_public=eq.true
- POST /rest/v1/equipment
- PATCH /rest/v1/equipment?id=eq.{id}
- DELETE /rest/v1/equipment?id=eq.{id}

Storage:
- POST /storage/v1/object/equipment-images/equipment/{id}/{file}
- GET  /storage/v1/object/public/equipment-images/{path}

Auth:
- POST /auth/v1/signup (existing)
- POST /auth/v1/token (existing)
```

---

## 📚 Documentation Files

| File | Purpose |
|------|---------|
| equipment.sql | Database schema |
| EQUIPMENT_SETUP.md | Complete setup guide |
| EQUIPMENT_IMPLEMENTATION.md | Implementation summary |
| QUICK_REFERENCE.md | This file |

---

## ⏱️ Performance Notes

- Pagination support in getPublicEquipment()
- Indexes on frequently queried columns
- Image compression (max 1024x1024)
- Async/await throughout to prevent UI blocking
- FutureBuilder for reactive UI updates

---

## 🔒 Security Checklist

- ✅ RLS enabled on all tables
- ✅ Users can only modify own equipment
- ✅ Public equipment visible to all
- ✅ Image upload restricted by ownership
- ✅ Foreign keys enforced
- ✅ Input validation on forms

---

## 🎯 Testing Checklist

- [ ] Add equipment with all fields
- [ ] Add equipment with minimal fields
- [ ] Upload image and verify
- [ ] Set discount and verify calculation
- [ ] View equipment in list
- [ ] Edit equipment
- [ ] Delete equipment
- [ ] Public equipment visible
- [ ] Private equipment hidden
- [ ] Status changes work
- [ ] Date selection works
- [ ] Form validation works
- [ ] Error messages display
- [ ] Loading states visible

---

**Quick Reference Version:** 1.0  
**Last Updated:** April 15, 2026
