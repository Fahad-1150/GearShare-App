import 'dart:convert';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/equipment.dart';

class EquipmentService {
  static final EquipmentService _instance = EquipmentService._internal();

  factory EquipmentService() {
    return _instance;
  }

  EquipmentService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  // Convert file to base64 string
  Future<String> fileToBase64(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      print('Error converting file to base64: $e');
      rethrow;
    }
  }

  // Get all equipment for current user with images
  Future<List<Equipment>> getUserEquipment(String userId) async {
    try {
      final response = await _client
          .from('equipment')
          .select('*, equipment_images(id, image_url, display_order)')
          .eq('owner_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => Equipment.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching user equipment: $e');
      rethrow;
    }
  }

  // Get all public equipment for feed with images
  Future<List<Equipment>> getPublicEquipment({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _client
          .from('equipment')
          .select('*, equipment_images(id, image_url, display_order)')
          .eq('is_public', true)
          .eq('status', 'available')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((item) => Equipment.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching public equipment: $e');
      rethrow;
    }
  }

  // Get single equipment by ID with images
  Future<Equipment?> getEquipmentById(String equipmentId) async {
    try {
      final response = await _client
          .from('equipment')
          .select('*, equipment_images(id, image_url, display_order)')
          .eq('id', equipmentId)
          .single();

      return Equipment.fromJson(response);
    } catch (e) {
      print('Error fetching equipment: $e');
      return null;
    }
  }

  // Add new equipment with multiple base64 images
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
    List<String> imageBase64List = const [],
    String? locationName,
    double? locationLatitude,
    double? locationLongitude,
    String? pickupAddress,
    bool isPublic = true,
  }) async {
    try {
      final now = DateTime.now();
      final equipmentData = {
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
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      // Insert equipment
      final equipmentResponse = await _client
          .from('equipment')
          .insert(equipmentData)
          .select()
          .single();

      final equipment = Equipment.fromJson(equipmentResponse);

      // Add images if provided
      if (imageBase64List.isNotEmpty) {
        await addEquipmentImages(equipment.id, imageBase64List);
      }

      // Add to public equipment if public
      if (isPublic) {
        await makeEquipmentPublic(equipment.id, ownerId);
      }

      // Fetch equipment with images
      return (await getEquipmentById(equipment.id))!;
    } catch (e) {
      print('Error adding equipment: $e');
      rethrow;
    }
  }

  // Add images to equipment
  Future<void> addEquipmentImages(
    String equipmentId,
    List<String> base64Images,
  ) async {
    try {
      final imageRecords = <Map<String, dynamic>>[];

      for (int i = 0; i < base64Images.length; i++) {
        imageRecords.add({
          'equipment_id': equipmentId,
          'image_url': base64Images[i],
          'display_order': i,
        });
      }

      await _client.from('equipment_images').insert(imageRecords);
    } catch (e) {
      print('Error adding equipment images: $e');
      rethrow;
    }
  }

  // Delete image from equipment
  Future<void> deleteEquipmentImage(String imageId) async {
    try {
      await _client.from('equipment_images').delete().eq('id', imageId);
    } catch (e) {
      print('Error deleting image: $e');
      rethrow;
    }
  }

  // Update equipment
  Future<Equipment> updateEquipment({
    required String equipmentId,
    String? name,
    String? description,
    String? category,
    double? perDayPrice,
    int? discountPercentage,
    int? discountMinDays,
    String? status,
    DateTime? availableFrom,
    String? locationName,
    double? locationLatitude,
    double? locationLongitude,
    String? pickupAddress,
    bool? isPublic,
  }) async {
    try {
      final updateData = <String, dynamic>{
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (category != null) 'category': category,
        if (perDayPrice != null) 'per_day_price': perDayPrice,
        if (discountPercentage != null)
          'discount_percentage': discountPercentage,
        if (discountMinDays != null) 'discount_min_days': discountMinDays,
        if (status != null) 'status': status,
        if (availableFrom != null)
          'available_from': availableFrom.toIso8601String(),
        if (locationName != null) 'location_name': locationName,
        if (locationLatitude != null) 'location_latitude': locationLatitude,
        if (locationLongitude != null) 'location_longitude': locationLongitude,
        if (pickupAddress != null) 'pickup_address': pickupAddress,
        if (isPublic != null) 'is_public': isPublic,
      };

      final response = await _client
          .from('equipment')
          .update(updateData)
          .eq('id', equipmentId)
          .select('*, equipment_images(id, image_url, display_order)')
          .single();

      return Equipment.fromJson(response);
    } catch (e) {
      print('Error updating equipment: $e');
      rethrow;
    }
  }

  // Delete equipment (cascades to images)
  Future<void> deleteEquipment(String equipmentId) async {
    try {
      await _client.from('equipment').delete().eq('id', equipmentId);
    } catch (e) {
      print('Error deleting equipment: $e');
      rethrow;
    }
  }

  // Add equipment to public feed
  Future<void> makeEquipmentPublic(String equipmentId, String ownerId) async {
    try {
      await _client.from('public_equipment').insert({
        'equipment_id': equipmentId,
        'owner_id': ownerId,
        'featured': false,
      });
    } catch (e) {
      print('Error making equipment public: $e');
      // Don't rethrow - equipment is still created even if public feed fails
    }
  }

  // Remove equipment from public feed
  Future<void> removeFromPublic(String equipmentId) async {
    try {
      await _client
          .from('public_equipment')
          .delete()
          .eq('equipment_id', equipmentId);
    } catch (e) {
      print('Error removing from public: $e');
      rethrow;
    }
  }
}
