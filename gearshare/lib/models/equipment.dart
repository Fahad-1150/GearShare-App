class Equipment {
  final String id;
  final String ownerId;
  final String name;
  final String? description;
  final String? category;
  final double perDayPrice;
  final int discountPercentage;
  final int discountMinDays;
  final String status; // 'available', 'unavailable', 'available_from'
  final DateTime? availableFrom;
  final List<String> images; // Base64 encoded images
  final String? locationName;
  final double? locationLatitude;
  final double? locationLongitude;
  final String? pickupAddress;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;

  Equipment({
    required this.id,
    required this.ownerId,
    required this.name,
    this.description,
    this.category,
    required this.perDayPrice,
    this.discountPercentage = 0,
    this.discountMinDays = 7,
    this.status = 'available',
    this.availableFrom,
    this.images = const [],
    this.locationName,
    this.locationLatitude,
    this.locationLongitude,
    this.pickupAddress,
    this.isPublic = true,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create equipment from JSON (Supabase response)
  factory Equipment.fromJson(Map<String, dynamic> json) {
    List<String> imagesList = [];

    // Handle equipment_images relation if included
    if (json['equipment_images'] != null && json['equipment_images'] is List) {
      imagesList = (json['equipment_images'] as List)
          .map((img) => img['image_url'] as String)
          .toList();
    }

    return Equipment(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      category: json['category'] as String?,
      perDayPrice: (json['per_day_price'] as num).toDouble(),
      discountPercentage: json['discount_percentage'] as int? ?? 0,
      discountMinDays: json['discount_min_days'] as int? ?? 7,
      status: json['status'] as String? ?? 'available',
      availableFrom: json['available_from'] != null
          ? DateTime.parse(json['available_from'] as String)
          : null,
      images: imagesList,
      locationName: json['location_name'] as String?,
      locationLatitude: (json['location_latitude'] as num?)?.toDouble(),
      locationLongitude: (json['location_longitude'] as num?)?.toDouble(),
      pickupAddress: json['pickup_address'] as String?,
      isPublic: json['is_public'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // Convert equipment to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'description': description,
      'category': category,
      'per_day_price': perDayPrice,
      'discount_percentage': discountPercentage,
      'discount_min_days': discountMinDays,
      'status': status,
      'available_from': availableFrom?.toIso8601String(),
      'location_name': locationName,
      'location_latitude': locationLatitude,
      'location_longitude': locationLongitude,
      'pickup_address': pickupAddress,
      'is_public': isPublic,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Get first image for display
  String? get firstImage => images.isNotEmpty ? images.first : null;

  // Get all images
  List<String> get allImages => List.unmodifiable(images);

  // Calculate rental price with discount
  double calculateRentalPrice(int days) {
    double basePrice = perDayPrice * days;
    if (days >= discountMinDays && discountPercentage > 0) {
      double discount = basePrice * (discountPercentage / 100);
      return basePrice - discount;
    }
    return basePrice;
  }

  @override
  String toString() => 'Equipment(id: $id, name: $name, price: TK $perDayPrice)';
}
