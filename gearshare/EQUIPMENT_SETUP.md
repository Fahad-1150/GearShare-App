# GearShare Equipment Management Setup

## 📋 Overview

This document provides setup instructions for the Equipment Management feature in GearShare. The system allows users to:
- Add equipment for rent with detailed information
- Set pricing and discount tiers
- Manage equipment images
- Set equipment availability status
- Make equipment public or private
- Track ownership and rental status

## 🗄️ Database Setup

### Step 1: Run the SQL Script

Execute the `equipment.sql` file in your Supabase SQL Editor:

1. Go to [Supabase Dashboard](https://supabase.com)
2. Select your GearShare project
3. Navigate to **SQL Editor**
4. Click **New Query**
5. Copy the contents of `equipment.sql`
6. Click **Run**

This will create the following tables:
- `equipment` - Main equipment table
- `public_equipment` - Index for public equipment visibility
- `equipment_images` - Additional images per equipment (optional future use)

### Step 2: Enable Storage for Images

1. In Supabase Dashboard, go to **Storage**
2. Create a new bucket named `equipment-images`
3. Set the bucket to **Public**
4. Set up the following RLS policy:

```sql
CREATE POLICY "Public Access" ON storage.objects
  FOR SELECT USING (bucket_id = 'equipment-images');

CREATE POLICY "Users can upload equipment images" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'equipment-images');
```

---

## 🛠️ Dependencies

The feature uses the following Flutter packages:

```yaml
dependencies:
  supabase_flutter: ^2.10.0  # Database & Auth
  http: ^1.1.0               # HTTP client
  image_picker: ^1.0.0       # Image selection
```

Install dependencies:
```bash
flutter pub get
```

---

## 📁 Project Structure

```
lib/
├── models/
│   └── equipment.dart          # Equipment data model
├── services/
│   ├── supabase_service.dart   # Existing auth service
│   └── equipment_service.dart  # Equipment CRUD operations
└── pages/
    ├── dashboard_page.dart     # Main dashboard with tabs
    └── add_equipment_page.dart # Equipment addition form
```

---

## 🎯 Features Implemented

### 1. **Equipment Model** (`lib/models/equipment.dart`)
- Complete equipment data structure
- JSON serialization/deserialization
- Discount calculation logic

### 2. **Equipment Service** (`lib/services/equipment_service.dart`)
Provides methods for:
- `getUserEquipment()` - Get all equipment owned by user
- `getPublicEquipment()` - Get equipment for public feed
- `addEquipment()` - Create new equipment
- `updateEquipment()` - Modify existing equipment
- `deleteEquipment()` - Remove equipment
- `uploadEquipmentImage()` - Upload image to storage
- `makeEquipmentPublic()` - Add to public feed
- `removeFromPublic()` - Remove from public feed

### 3. **Dashboard Page** (`lib/pages/dashboard_page.dart`)
Tabbed interface with:
- **Equipment Tab** - View all user's equipment
- **Add Equipment Tab** - Form to add new equipment
- **Analytics Tab** - Placeholder for charts (coming soon)
- **Requests Tab** - Placeholder for rental requests (coming soon)
- **History Tab** - Placeholder for rental history (coming soon)

### 4. **Add Equipment Form** (`lib/pages/add_equipment_page.dart`)
Comprehensive form with:
- Equipment image picker
- Name, category, and description
- Pricing and discount configuration
- Availability status management
- Location selection with coordinates
- Public/Private visibility toggle

---

## 📝 Database Schema

### Equipment Table

| Column | Type | Description |
|--------|------|------------|
| `id` | UUID | Primary key (auto-generated) |
| `owner_id` | UUID | Foreign key to auth.users |
| `name` | VARCHAR | Equipment name |
| `description` | TEXT | Detailed description |
| `category` | VARCHAR | Equipment category |
| `per_day_price` | DECIMAL | Daily rental price |
| `discount_percentage` | INTEGER | Discount % for longer rentals |
| `discount_min_days` | INTEGER | Minimum days to qualify for discount |
| `status` | ENUM | 'available', 'unavailable', 'available_from' |
| `available_from` | DATE | Date when equipment becomes available |
| `image_url` | TEXT | Primary image URL |
| `location_name` | VARCHAR | Pickup location name |
| `location_latitude` | DECIMAL | Latitude coordinate |
| `location_longitude` | DECIMAL | Longitude coordinate |
| `pickup_address` | TEXT | Full pickup address |
| `is_public` | BOOLEAN | Visible in public feed |
| `created_at` | TIMESTAMP | Creation timestamp |
| `updated_at` | TIMESTAMP | Last update timestamp |

### Public Equipment Table

| Column | Type | Description |
|--------|------|------------|
| `id` | UUID | Primary key |
| `equipment_id` | UUID | Foreign key to equipment |
| `owner_id` | UUID | Foreign key to auth.users |
| `display_order` | INTEGER | Display order in feed |
| `featured` | BOOLEAN | Featured item flag |
| `created_at` | TIMESTAMP | Creation timestamp |

---

## 🔒 Row Level Security (RLS)

The database implements the following RLS policies:

### Equipment Table
- ✅ Users can view their own equipment
- ✅ Users can insert their own equipment
- ✅ Users can update their own equipment
- ✅ Users can delete their own equipment
- ✅ Anyone can view public equipment

### Public Equipment Table
- ✅ Anyone can view public equipment
- ✅ Users can manage their own public equipment

---

## 🚀 Usage Guide

### For Users

1. **Login** to the GearShare app
2. **Navigate to Dashboard** (automatic after login)
3. **Go to "Add Equipment" tab**
4. **Fill in the form:**
   - Select equipment image
   - Enter name and category
   - Add description
   - Set per-day price
   - Configure discount (optional)
   - Select status
   - Add location details
5. **Toggle public visibility**
6. **Click "Add Equipment"**

### For Developers

#### Adding New Equipment:
```dart
final service = EquipmentService();
final equipment = await service.addEquipment(
  ownerId: userId,
  name: 'Mountain Bike',
  perDayPrice: 25.0,
  discountPercentage: 10,
  discountMinDays: 7,
  isPublic: true,
);
```

#### Fetching Equipment:
```dart
// Get user's equipment
final userEquipment = await service.getUserEquipment(userId);

// Get public equipment
final publicEquipment = await service.getPublicEquipment();
```

#### Uploading Images:
```dart
final imageUrl = await service.uploadEquipmentImage(
  equipmentId: equipment.id,
  imagePath: pickedFile.path,
);
```

---

## 🗺️ Location Integration

Equipment includes location features:

### Manual Coordinates Entry
- Latitude and Longitude fields for precise location
- Optional coordinates (location name is sufficient)

### OpenStreetMap Integration (Recommended)
To add interactive map selection:

1. Add packages to `pubspec.yaml`:
```yaml
dependencies:
  flutter_map: ^6.0.0
  latlong2: ^0.9.0
```

2. Create a location picker widget (future enhancement)

### Sample Coordinates
- Center of a city: 40.7128, -74.0060 (New York)
- User can find coordinates at: [openstreetmap.org](https://openstreetmap.org)

---

## ⚙️ Configuration

### Image Storage Settings

**Maximum Image Size:** 1024x1024 pixels (automatically compressed)

**Storage Path:** `equipment/{equipment_id}/{timestamp}.jpg`

**Public URL Format:**
```
https://[your-project].supabase.co/storage/v1/object/public/equipment-images/equipment/{id}/{timestamp}.jpg
```

### Discount Calculation Example

```
Equipment: Mountain Bike
Price/Day: $25
Discount: 10% after 7 days

Rental Duration Calculation:
- 5 days: $25 × 5 = $125.00
- 7 days: $25 × 7 = $175.00 (discount applies)
  - Discount: $175.00 × 10% = $17.50
  - Total: $175.00 - $17.50 = $157.50
- 10 days: $25 × 10 = $250.00 - $25.00 = $225.00
```

---

## 🧪 Testing

### Test Credentials
```
Email: test@gearshare.com
Password: TestPassword123!
```

### Test Equipment Data
```
Name: Mountain Bike
Category: Sports Equipment
Description: High-quality bike for mountain trails
Price: $25.00/day
Discount: 10% after 7 days
Location: Downtown Park ($40.7128, -74.0060)
```

---

## 📚 API Reference

### EquipmentService Methods

#### Get User Equipment
```dart
Future<List<Equipment>> getUserEquipment(String userId)
```

#### Get Public Equipment
```dart
Future<List<Equipment>> getPublicEquipment({
  int limit = 20,
  int offset = 0,
})
```

#### Get Single Equipment
```dart
Future<Equipment?> getEquipmentById(String equipmentId)
```

#### Add Equipment
```dart
Future<Equipment> addEquipment({
  required String ownerId,
  required String name,
  String? description,
  String? category,
  required double perDayPrice,
  int discountPercentage = 0,
  int discountMinDays = 7,
  String status = 'available',
  DateTime? availableFrom,
  String? imageUrl,
  String? locationName,
  double? locationLatitude,
  double? locationLongitude,
  String? pickupAddress,
  bool isPublic = true,
})
```

#### Update Equipment
```dart
Future<Equipment> updateEquipment({
  required String equipmentId,
  String? name,
  String? description,
  // ... other optional fields
})
```

#### Delete Equipment
```dart
Future<void> deleteEquipment(String equipmentId)
```

#### Upload Image
```dart
Future<String> uploadEquipmentImage({
  required String equipmentId,
  required String imagePath,
})
```

---

## 🐛 Troubleshooting

### Image Upload Fails
**Solution:** Ensure storage bucket `equipment-images` exists and RLS policies are set

### Equipment Not Visible
**Solution:** Check if `is_public = true` and `status = 'available'`

### Price Not Saving
**Solution:** Ensure price is a valid decimal number (e.g., 25.00, not 25)

### Location Coordinates Invalid
**Solution:** Coordinates are optional. If provided, use format: Latitude: -90 to 90, Longitude: -180 to 180

---

## 🔄 Future Enhancements

- [ ] Interactive map for location selection (flutter_map)
- [ ] Multiple images per equipment
- [ ] Equipment availability calendar
- [ ] Rental request notifications
- [ ] Booking/reservation system
- [ ] Equipment ratings and reviews
- [ ] Insurance options
- [ ] Payment processing integration
- [ ] Damage deposit tracking

---

## 📞 Support

For issues or questions:
1. Check troubleshooting section above
2. Review Supabase documentation
3. Check Flutter package documentation
4. Test with sample data provided

---

**Last Updated:** April 15, 2026  
**Version:** 1.0.0
