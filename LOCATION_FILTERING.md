# Location-Based Filtering Implementation

## Overview
This document describes the location-based filtering feature implemented in the GearShare app, which allows users to find equipment near them by filtering and sorting based on distance.

## Features

### 1. User Location Tracking
- **Automatic location detection**: The app automatically requests location permissions on startup
- **Permission handling**: Gracefully handles permission denials
- **Real-time updates**: User location is captured when the feed page loads

### 2. Distance Filtering
- **Filter options**: Users can filter equipment by distance:
  - All Distances (no filter)
  - 5 km
  - 10 km
  - 20 km
  - 50 km
  - 100 km

- **Smart UI**: Distance filter button only appears when user location is available
- **Visual indicators**: Selected distance filter is highlighted in orange (theme color)

### 3. Distance Display
- **Equipment cards**: Each equipment item displays distance in the top-right corner
- **Distance format**: Distance is shown as "X.X km" (e.g., "2.5 km")
- **Location icon**: Clear location icon indicates distance information

### 4. Automatic Sorting
- **Proximity sorting**: When a distance filter is applied, equipment is automatically sorted by proximity
- **Closest first**: Equipment closer to the user appears first in the list

## Technical Implementation

### Components Modified

#### 1. **FeedPage** (`lib/pages/feed_page.dart`)
- Added location tracking state variables:
  - `_userPosition`: Stores current user coordinates
  - `_selectedDistance`: Tracks selected distance filter
  - `_isLoadingLocation`: Indicates location loading state

- New methods:
  - `_initializeUserLocation()`: Requests permissions and gets current location
  - `_calculateDistance()`: Calculates distance between two coordinates using Haversine formula
  - `_getEquipmentDistance()`: Gets distance for a specific equipment item
  - `_onDistanceChanged()`: Handles distance filter changes

- Enhanced filtering:
  - Updated `_filterEquipment()` to include distance-based filtering
  - Automatic sorting by proximity when filter is active

- UI enhancements:
  - Added distance filter dropdown in search bar
  - Distance badges on equipment cards (featured and regular)
  - Distance information integrated into card display

#### 2. **LocationService** (`lib/services/location_service.dart`)
New singleton service for location operations:
- `getCurrentPosition()`: Gets user's current location
- `calculateDistance()`: Calculates distance between coordinates
- `getDistanceFromPosition()`: Gets distance from user position to a target
- `formatDistance()`: Formats distance for display

### Dependencies
The implementation uses existing dependencies:
- `geolocator: ^13.0.1` - For location services
- `latlong2: ^0.9.1` - For distance calculations (Haversine formula)

### Distance Calculation
Uses the Haversine formula through the `latlong2` package:
```
distance = atan2(√(a), √(1−a)) * 2 * R
where:
  a = sin²(Δlat/2) + cos(lat1) * cos(lat2) * sin²(Δlon/2)
  R = Earth's radius (≈ 6,371 km)
```

## User Workflow

1. **App Launch**:
   - Feed page loads
   - App requests location permission
   - User location is obtained

2. **Location Filtering**:
   - Distance filter button appears in the search bar (location icon)
   - User taps the distance button
   - Distance options menu appears
   - User selects desired distance range

3. **Equipment Display**:
   - Equipment list filters to show only items within selected distance
   - Items are sorted by proximity (closest first)
   - Distance labels appear on each card

4. **Search & Filter Combinations**:
   - Users can combine location filter with:
     - Text search
     - Category filter
   - All filters work together

## UI Elements

### Distance Filter Button
- **Icon**: Location pin icon
- **Color**: Grey (inactive), Orange (active when distance filter selected)
- **Location**: Right side of search bar, next to category filter
- **Visibility**: Only appears when location permission is granted

### Distance Badge on Cards
- **Location**: Top-right corner of equipment image
- **Background**: Semi-transparent black for visibility
- **Content**: Location icon + distance text (e.g., "2.5 km")
- **Font**: Bold, 10pt, white text

### Distance Filter Menu
- **Options**: 
  - All Distances (default)
  - 5 km
  - 10 km
  - 20 km
  - 50 km
  - 100 km
- **Selection**: Checkmark indicator shows current selection

## Error Handling

### Location Permission Issues
- If user denies location permission:
  - Distance filter button is hidden
  - App continues to function normally
  - All equipment is shown without distance filtering

### Missing Location Data
- Equipment without location coordinates:
  - Excluded from filtered results when distance filter is active
  - Shown when "All Distances" filter is selected

## Data Flow

```
User Permission Request
        ↓
Get Current Position (Latitude, Longitude)
        ↓
Load Equipment from Supabase
        ↓
Apply Filters:
  - Text Search
  - Category Filter
  - Distance Filter (if enabled)
        ↓
Calculate Distance for Each Item
        ↓
Sort by Distance (if distance filter active)
        ↓
Display Equipment Cards with Distance
```

## Performance Considerations

1. **Location Caching**: User position is cached, reducing repeated permission requests
2. **Lazy Calculation**: Distances are calculated only for filtered items
3. **Efficient Sorting**: Uses single-pass sort when distance filter is active
4. **Battery Optimization**: Location is fetched once on initialization

## Future Enhancements

1. **Real-time Location Updates**:
   - Continuous location tracking
   - Periodic updates every 5 minutes

2. **Map View**:
   - Show equipment on map
   - Visual distance indication

3. **Custom Distance Radius**:
   - Allow users to input custom distance
   - Slider for distance selection

4. **Location History**:
   - Save favorite locations
   - Quick filter by saved locations

5. **Nearby Notifications**:
   - Notify user when new equipment appears nearby

6. **Offline Support**:
   - Cache location data
   - Show last known positions when offline

## Testing Checklist

- [ ] Location permission request works
- [ ] Distance filter button appears after permission granted
- [ ] Distance calculations are accurate
- [ ] Filtering works correctly
- [ ] Sorting by distance works
- [ ] Distance badges display correctly on cards
- [ ] Combined filters (search + category + distance) work
- [ ] Equipment without location is handled correctly
- [ ] Permission denial doesn't break the app

## Code Examples

### Using LocationService in Other Pages
```dart
import 'package:gearshare/services/location_service.dart';

final locationService = LocationService();

// Get current position
final position = await locationService.getCurrentPosition();

// Calculate distance
final distance = locationService.calculateDistance(
  position!.latitude,
  position!.longitude,
  equipmentLat,
  equipmentLon,
);

// Format for display
final formattedDistance = locationService.formatDistance(distance);
```

### Accessing Distance in Equipment Details
```dart
final distance = _getEquipmentDistance(equipment);
if (distance != null) {
  print('Equipment is ${distance.toStringAsFixed(1)} km away');
}
```

## Configuration

### Distance Options
To modify available distance options, edit `FeedPage` class:
```dart
static const List<double> distanceOptions = [5, 10, 20, 50, 100];
```

### Theme Colors
- **Active**: `Color(0xFFE87C31)` (Orange)
- **Inactive**: `Colors.grey`
- **Background**: `Color(0xFF1E1E1E)` (Dark)
