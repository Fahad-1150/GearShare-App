import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/equipment.dart';
import '../services/equipment_service.dart';
import 'equipment_details_page.dart';
import '../models/equipment_card.dart';
import '../services/supabase_service.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final EquipmentService _equipmentService = EquipmentService();
  final TextEditingController _searchController = TextEditingController();
  List<Equipment> _allEquipment = [];
  List<Equipment> _filteredEquipment = [];
  String? _selectedCategory;
  double? _selectedDistance; // Distance filter in km
  Position? _userPosition;
  bool _isLoading = true;
  String? _error;

  // Distance options in km
  static const List<double> distanceOptions = [5, 10, 20, 50, 100];

  final List<String> _categories = [
    'All',
    'Photography',
    'Tools',
    'Sports',
    'Camping',
    'Music',
    'Electronics',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadEquipment();
    _initializeUserLocation();
    _searchController.addListener(_filterEquipment);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Initialize user location
  Future<void> _initializeUserLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition();
        setState(() {
          _userPosition = position;
        });
        _filterEquipment(); // Refilter when location is obtained
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  // Calculate distance between two coordinates in kilometers
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const distance = Distance();
    final distanceInMeters = distance(LatLng(lat1, lon1), LatLng(lat2, lon2));
    return distanceInMeters / 1000; // Convert to kilometers
  }

  // Get distance for equipment or null if user location not available
  double? _getEquipmentDistance(Equipment equipment) {
    if (_userPosition == null ||
        equipment.locationLatitude == null ||
        equipment.locationLongitude == null) {
      return null;
    }

    return _calculateDistance(
      _userPosition!.latitude,
      _userPosition!.longitude,
      equipment.locationLatitude!,
      equipment.locationLongitude!,
    );
  }

  Future<void> _loadEquipment() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final equipment = await _equipmentService.getPublicEquipment(limit: 100);
      print('Loaded ${equipment.length} equipment items');
      setState(() {
        _allEquipment = equipment;
        _isLoading = false;
      });
      _filterEquipment();
    } catch (e) {
      setState(() {
        _error = 'Failed to load equipment: $e';
        _isLoading = false;
      });
    }
  }

  void _filterEquipment() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredEquipment = _allEquipment.where((item) {
        final matchesSearch =
            item.name.toLowerCase().contains(query) ||
            (item.description?.toLowerCase().contains(query) ?? false);

        final matchesCategory =
            _selectedCategory == null ||
            _selectedCategory == 'All' ||
            item.category == _selectedCategory;

        // Apply distance filter
        bool matchesDistance = true;
        if (_selectedDistance != null && _userPosition != null) {
          final distance = _getEquipmentDistance(item);
          if (distance == null) {
            matchesDistance = false; // Exclude items without location
          } else {
            matchesDistance = distance <= _selectedDistance!;
          }
        }

        return matchesSearch && matchesCategory && matchesDistance;
      }).toList();

      // Sort by distance if user location is available and distance filter not set to "All"
      if (_userPosition != null && _selectedDistance != null) {
        _filteredEquipment.sort((a, b) {
          final distanceA = _getEquipmentDistance(a) ?? double.infinity;
          final distanceB = _getEquipmentDistance(b) ?? double.infinity;
          return distanceA.compareTo(distanceB);
        });
      }
    });
  }

  void _onCategoryChanged(String? value) {
    setState(() {
      _selectedCategory = value;
    });
    _filterEquipment();
  }

  void _onDistanceChanged(double? value) {
    setState(() {
      _selectedDistance = value;
    });
    _filterEquipment();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GearShare',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFE87C31),
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Find equipment near you',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                  if (SupabaseService().getCurrentUser() == null)
                    TextButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/signin'),
                      icon: const Icon(Icons.login, color: Color(0xFFE87C31)),
                      label: const Text(
                        'Login',
                        style: TextStyle(
                          color: Color(0xFFE87C31),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Search and Filter Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Search Bar
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search equipment...',
                        hintStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.grey,
                        ),
                        filled: true,
                        fillColor: const Color(0xFF1E1E1E),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF333333),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF333333),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE87C31),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Category Filter Dropdown
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF333333)),
                    ),
                    child: PopupMenuButton<String>(
                      onSelected: _onCategoryChanged,
                      itemBuilder: (BuildContext context) {
                        return _categories.map((String choice) {
                          return PopupMenuItem<String>(
                            value: choice,
                            child: Row(
                              children: [
                                if (_selectedCategory == choice)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 8),
                                    child: Icon(
                                      Icons.check,
                                      color: Color(0xFFE87C31),
                                      size: 20,
                                    ),
                                  ),
                                Text(choice),
                              ],
                            ),
                          );
                        }).toList();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(
                          Icons.filter_list,
                          color:
                              _selectedCategory != null &&
                                  _selectedCategory != 'All'
                              ? const Color(0xFFE87C31)
                              : Colors.grey,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Distance Filter Dropdown
                  if (_userPosition != null)
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF333333)),
                      ),
                      child: PopupMenuButton<double?>(
                        onSelected: _onDistanceChanged,
                        itemBuilder: (BuildContext context) {
                          final items = <PopupMenuEntry<double?>>[
                            const PopupMenuItem<double?>(
                              value: null,
                              child: Row(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(right: 8),
                                    child: Icon(
                                      Icons.check,
                                      color: Color(0xFFE87C31),
                                      size: 20,
                                    ),
                                  ),
                                  Text('All Distances'),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                          ];

                          for (double distance in distanceOptions) {
                            items.add(
                              PopupMenuItem<double?>(
                                value: distance,
                                child: Row(
                                  children: [
                                    if (_selectedDistance == distance)
                                      const Padding(
                                        padding: EdgeInsets.only(right: 8),
                                        child: Icon(
                                          Icons.check,
                                          color: Color(0xFFE87C31),
                                          size: 20,
                                        ),
                                      ),
                                    Text('${distance.toInt()} km'),
                                  ],
                                ),
                              ),
                            );
                          }

                          return items;
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(
                            Icons.location_on,
                            color: _selectedDistance != null
                                ? const Color(0xFFE87C31)
                                : Colors.grey,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFE87C31),
                      ),
                    )
                  : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadEquipment,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE87C31),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadEquipment,
                      color: const Color(0xFFE87C31),
                      child: ListView(
                        children: [
                          // "Here" Featured Section
                          if (_allEquipment.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '📍 Here',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            setState(() {
                                              _selectedCategory = null;
                                            });
                                            _filterEquipment();
                                          },
                                          child: const Text('View All'),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    height: 260,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: _allEquipment.take(5).length,
                                      itemBuilder: (context, index) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            right: 12,
                                          ),
                                          child: _buildFeaturedCard(
                                            context,
                                            _allEquipment[index],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          // All Equipment Section
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                              bottom: 16,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'All Equipment',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                ),
                                const SizedBox(height: 12),
                                _filteredEquipment.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.shopping_bag_outlined,
                                              color: Colors.grey[600],
                                              size: 48,
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'No equipment found',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge
                                                  ?.copyWith(
                                                    color: Colors.grey,
                                                  ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Try adjusting your search or filters',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: Colors.grey,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : GridView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        gridDelegate:
                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 2,
                                              childAspectRatio: 0.75,
                                              crossAxisSpacing: 12,
                                              mainAxisSpacing: 16,
                                            ),
                                        itemCount: _filteredEquipment.length,
                                        itemBuilder: (context, index) {
                                          return _buildEquipmentCard(
                                            context,
                                            _filteredEquipment[index],
                                          );
                                        },
                                      ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedCard(BuildContext context, Equipment equipment) {
    final distance = _getEquipmentDistance(equipment);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EquipmentDetailsPage(equipment: equipment),
          ),
        );
      },
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE87C31), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE87C31).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  color: const Color(0xFF0F0F0F),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      
                    ),
                    // Distance badge
                    if (distance != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Color(0xFFE87C31),
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${distance.toStringAsFixed(1)} km',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Content
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Featured Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE87C31),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Featured',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Name
                    Text(
                      equipment.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    // Price
                    Text(
                      'TK ${equipment.perDayPrice.toStringAsFixed(2)}/day',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFE87C31),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEquipmentCard(BuildContext context, Equipment equipment) {
    final distance = _getEquipmentDistance(equipment);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EquipmentDetailsPage(equipment: equipment),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF333333)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  color: const Color(0xFF0F0F0F),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    
                    ),
                    // Distance badge
                    if (distance != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Color(0xFFE87C31),
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${distance.toStringAsFixed(1)} km',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Content
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      equipment.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Category
                    if (equipment.category != null)
                      Text(
                        equipment.category!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    const Spacer(),
                    // Price and Location
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TK ${equipment.perDayPrice.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFE87C31),
                                  ),
                            ),
                            Text(
                              '/day',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                        if (equipment.locationName != null)
                          Expanded(
                            child: Text(
                              equipment.locationName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
