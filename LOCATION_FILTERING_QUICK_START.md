# Location-Based Filtering - Quick Start Guide

## What's New

Your GearShare app now has **location-based filtering** that lets users find equipment near them!

## Features Added

✅ **Automatic Location Detection**
- App requests location permission on startup
- Gets user's current GPS coordinates

✅ **Distance Filter**
- Filter button with location icon in the search bar
- Choose from: 5km, 10km, 20km, 50km, or 100km
- Only shows when location is available

✅ **Distance Display**
- Each equipment card shows distance in top-right corner
- Format: "X.X km" (e.g., "2.5 km")
- Helps users quickly see how far equipment is

✅ **Smart Sorting**
- Equipment automatically sorted by proximity
- Closest items appear first when distance filter is active

## How Users Use It

### Step 1: Grant Location Permission
```
User opens app → Grants location permission → Location automatically detected
```

### Step 2: Use Distance Filter
```
1. Tap the location icon 📍 in the search bar
2. Select distance range (5km, 10km, etc.)
3. Equipment list updates instantly
```

### Step 3: See Distances
```
Each card shows distance badge:
📍 2.5 km
```

### Step 4: Combine Filters
```
Can use distance filter + text search + category filter together:
- Search for "camera" 
- Filter by "Photography" category
- Show only within 10km
```

## Files Modified

### `lib/pages/feed_page.dart` - MAIN CHANGES
- Added location tracking
- Added distance calculations
- Added distance filter UI
- Updated equipment cards to show distance
- Auto-sorting by proximity

### `lib/services/location_service.dart` - NEW FILE
- Singleton service for all location operations
- Reusable across the app
- Methods:
  - `getCurrentPosition()` - Get user location
  - `calculateDistance()` - Calculate distance between coordinates
  - `getDistanceFromPosition()` - Get distance from user to target
  - `formatDistance()` - Format distance for display

## Technical Details

### Dependencies Used
- `geolocator` - Already installed, gets device location
- `latlong2` - Already installed, calculates distances using Haversine formula

### Distance Calculation
Uses Haversine formula for accurate distance:
- Accounts for Earth's curvature
- Accurate within ~0.5% for typical distances

### State Variables
```dart
Position? _userPosition;           // User's GPS coordinates
double? _selectedDistance;         // Selected filter (km)
bool _isLoadingLocation = true;    // Location loading state
```

### New Methods

**Initialize Location**
```dart
Future<void> _initializeUserLocation()
```

**Calculate Distance**
```dart
double _calculateDistance(double lat1, double lon1, double lat2, double lon2)
```

**Get Equipment Distance**
```dart
double? _getEquipmentDistance(Equipment equipment)
```

**Handle Distance Filter Change**
```dart
void _onDistanceChanged(double? value)
```

## UI Changes

### Search Bar
```
[Search Box] [Category ▼] [Distance 📍]
                           ↑ NEW
```

### Equipment Cards
```
┌─────────────────────┐
│                     │ 📍 2.5 km ← NEW
│    Equipment Image  │
│                     │
├─────────────────────┤
│ Camera             │
│ Photography        │
│ $50.00/day  📍     │
└─────────────────────┘
```

## Error Handling

### User Denies Location Permission
- Distance filter button is hidden
- App continues to work normally
- All equipment shown without distance filtering

### Equipment Without Location Data
- Excluded from distance-filtered results
- Still shown when "All Distances" selected

## Configuration

### Change Distance Options
Edit in `feed_page.dart`:
```dart
static const List<double> distanceOptions = [5, 10, 20, 50, 100];
```

Change to:
```dart
static const List<double> distanceOptions = [2, 5, 15, 30]; // Custom options
```

## Testing

Try these scenarios:

1. **Basic Filtering**
   - Open app
   - Tap distance filter
   - Select "10 km"
   - Verify equipment list updates

2. **Sorting**
   - Select distance filter
   - Check equipment is sorted by distance
   - Closest should be first

3. **Distance Display**
   - Open app
   - Check distance appears on cards
   - Verify format is "X.X km"

4. **Combined Filtering**
   - Select category "Photography"
   - Select distance "20 km"
   - Search "camera"
   - All three filters should work together

5. **Permissions**
   - Deny location permission
   - Verify app still works
   - Distance filter button should be hidden

## Future Enhancements

Consider adding:
- 🗺️ Map view of nearby equipment
- 🔄 Real-time location updates
- 📍 Save favorite locations
- 🔔 Notifications for new nearby equipment
- 📊 Distance slider for custom ranges

## Troubleshooting

### Distance Filter Button Not Showing
- Check if user granted location permission
- Verify location service is enabled on device
- Check if `_userPosition` is not null

### Distance Showing as null
- Equipment missing location coordinates
- Check database has latitude/longitude values
- Ensure equipment was added with location

### Wrong Distance Calculation
- Verify GPS coordinates are accurate
- Check equipment location data in Supabase
- Use a distance calculator to verify: https://www.distance-calculator.com/

## Code Examples

### Use LocationService in Other Pages
```dart
import 'package:gearshare/services/location_service.dart';

final locationService = LocationService();

// Get user location
final position = await locationService.getCurrentPosition();

// Calculate distance
final distance = locationService.calculateDistance(
  position!.latitude,
  position!.longitude,
  equipmentLatitude,
  equipmentLongitude,
);

// Display
final formatted = locationService.formatDistance(distance);
print('Equipment is $formatted away');
```

### Check if Equipment Has Location
```dart
final distance = _getEquipmentDistance(equipment);
if (distance != null) {
  print('Distance: ${distance.toStringAsFixed(1)} km');
} else {
  print('Equipment location unknown');
}
```

## Performance Tips

1. **User Location** - Cached after first request
2. **Distance Calculations** - Only for visible items
3. **Sorting** - Efficient single-pass algorithm
4. **Battery** - Location fetched once, not continuously

## Support

For issues or questions about location-based filtering:
1. Check the complete documentation in `LOCATION_FILTERING.md`
2. Review error messages in console
3. Verify Supabase equipment has location data

---

**Status**: ✅ Implemented and tested
**Version**: 1.0
**Last Updated**: 2026-04-24
