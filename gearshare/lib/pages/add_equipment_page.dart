import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:latlong2/latlong.dart'; // Import LatLng
import '../services/equipment_service.dart';
import 'location_picker_map.dart';

class AddEquipmentPage extends StatefulWidget {
  const AddEquipmentPage({super.key});

  @override
  State<AddEquipmentPage> createState() => _AddEquipmentPageState();
}

class _AddEquipmentPageState extends State<AddEquipmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _equipmentService = EquipmentService();

  // Form field controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  final _discountDaysController = TextEditingController(text: '7');
  final _locationNameController = TextEditingController();
  final _pickupAddressController = TextEditingController();

  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  // State variables
  String _selectedStatus = 'available';
  DateTime? _availableFromDate;
  List<PlatformFile> _selectedImages = [];
  List<File> _imageFiles = [];
  bool _isPublic = true;
  bool _isLoading = false;
  double? _locationLatitude;
  double? _locationLongitude;
  String? _pickedAddress;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    _discountDaysController.dispose();
    _locationNameController.dispose();
    _pickupAddressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(result.files);
          // Convert PlatformFile to File for cross-platform compatibility
          for (var file in result.files) {
            if (file.bytes != null) {
              // For web: create a file-like object from bytes
              _imageFiles.add(File(file.name));
            } else if (file.path != null) {
              // For native platforms: use the file path
              _imageFiles.add(File(file.path!));
            }
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking images: $e')));
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      _imageFiles.removeAt(index);
    });
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked != null && picked != _availableFromDate) {
      setState(() {
        _availableFromDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter equipment name')),
      );
      return;
    }

    if (double.tryParse(_priceController.text) == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter valid price')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
      List<String> base64Images = [];

      // Convert selected images to base64
      for (var i = 0; i < _selectedImages.length; i++) {
        final platformFile = _selectedImages[i];
        String base64String;

        // For web: use bytes from PlatformFile
        if (platformFile.bytes != null) {
          base64String = base64Encode(platformFile.bytes!);
        } else {
          // For native platforms: read from file path
          base64String = await _equipmentService.fileToBase64(
            platformFile.path ?? _imageFiles[i].path,
          );
        }

        base64Images.add(base64String);
      }

      // Create equipment with base64 images
      await _equipmentService.addEquipment(
        ownerId: userId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _categoryController.text.trim(),
        perDayPrice: double.parse(_priceController.text.trim()),
        discountPercentage: int.tryParse(_discountController.text.trim()) ?? 0,
        discountMinDays: int.tryParse(_discountDaysController.text.trim()) ?? 7,
        status: _selectedStatus,
        availableFrom: _availableFromDate,
        imageBase64List: base64Images,
        locationName: _locationNameController.text.trim(),
        pickupAddress: _pickupAddressController.text.trim(),
        locationLatitude: _locationLatitude,
        locationLongitude: _locationLongitude,
        isPublic: _isPublic,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Equipment added successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Reset form
      _resetForm();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding equipment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openMapPicker() async {
    final Map<String, dynamic>? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerMap(
          initialLocation: _locationLatitude != null && _locationLongitude != null
              ? LatLng(_locationLatitude!, _locationLongitude!)
              : null,
        ),
      ),
    );

    if (result != null) {
      final LatLng location = result['location'];
      setState(() {
        _locationLatitude = location.latitude;
        _locationLongitude = location.longitude;
        _pickedAddress = result['address'];
        _latitudeController.text = location.latitude.toStringAsFixed(6);
        _longitudeController.text = location.longitude.toStringAsFixed(6);
        _pickupAddressController.text = result['address'] ?? '';
      });
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _descriptionController.clear();
    _categoryController.clear();
    _priceController.clear();
    _discountController.text = '0';
    _discountDaysController.text = '7';
    _locationNameController.clear();
    _pickupAddressController.clear();
    _latitudeController.clear();
    _longitudeController.clear();

    setState(() {
      _selectedStatus = 'available';
      _availableFromDate = null;
      _selectedImages.clear();
      _imageFiles.clear();
      _isPublic = true;
      _pickedAddress = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            _buildSectionHeader(
              'Equipment Photos',
              'Add high-quality images of your gear',
              Icons.image_search_outlined,
            ),
            const SizedBox(height: 16),

            // Add Images Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Add Images from Gallery'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Display selected images
            if (_imageFiles.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white.withOpacity(0.02),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.image_not_supported_outlined,
                      size: 48,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No images selected',
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  SizedBox(
                    height: 110,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _imageFiles.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(
                                      0xFFBB86FC,
                                    ).withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: _selectedImages[index].bytes != null
                                      ? Image.memory(
                                          _selectedImages[index].bytes!,
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.file(
                                          _imageFiles[index],
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                              ),
                              Positioned(
                                top: 6,
                                right: 6,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${_imageFiles.length} image${_imageFiles.length > 1 ? 's' : ''} selected',
                    style: TextStyle(
                      fontSize: 13,
                      color: const Color(0xFFBB86FC),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 32),

            // Basic Info Section
            _buildSectionHeader(
              'Equipment Details',
              'Give your gear a distinctive identity',
              Icons.info_outline,
            ),
            const SizedBox(height: 16),

            // Equipment Name
            _buildTextField(
              controller: _nameController,
              label: 'Equipment Name',
              hint: 'Mountain Bike, Tent, Professional Camera',
              icon: Icons.label_outline,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Equipment name is required';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Category
            _buildTextField(
              controller: _categoryController,
              label: 'Category',
              hint: 'Sports, Electronics, Tools, etc.',
              icon: Icons.category_outlined,
            ),

            const SizedBox(height: 16),

            // Description
            _buildTextField(
              controller: _descriptionController,
              label: 'Description',
              hint: 'Describe condition, features, and any special details...',
              icon: Icons.description_outlined,
              maxLines: 4,
            ),

            const SizedBox(height: 32),

            // Pricing Section
            _buildSectionHeader(
              'Pricing & Discounts',
              'Set competitive rental rates',
              Icons.local_offer_outlined,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _priceController,
                    label: 'Price Per Day (TK)',
                    hint: '500',
                    icon: Icons.attach_money,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Required';
                      }
                      if (double.tryParse(value!) == null) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _discountController,
                    label: 'Discount %',
                    hint: '10',
                    icon: Icons.percent,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _buildTextField(
              controller: _discountDaysController,
              label: 'Min. Days for Discount',
              hint: '7',
              icon: Icons.calendar_today_outlined,
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 32),

            // Availability Section
            _buildSectionHeader(
              'Availability',
              'Let renters know when your gear is available',
              Icons.schedule_outlined,
            ),
            const SizedBox(height: 16),

            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  dropdownColor: const Color(0xFF2A2A2A),
                  decoration: InputDecoration(
                    labelText: 'Status',
                    border: InputBorder.none,
                    prefixIcon: const Icon(Icons.info_outline),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'available',
                      child: Text('Available Now'),
                    ),
                    DropdownMenuItem(
                      value: 'unavailable',
                      child: Text('Unavailable'),
                    ),
                    DropdownMenuItem(
                      value: 'available_from',
                      child: Text('Available From Date'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedStatus = value ?? 'available');
                  },
                ),
              ),
            ),

            if (_selectedStatus == 'available_from') ...[
              const SizedBox(height: 16),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _selectDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          color: const Color(0xFFBB86FC),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Available From',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _availableFromDate?.toString().split(' ')[0] ??
                                  'Select a date',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward_ios_outlined,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Location Section
            _buildSectionHeader(
              'Pickup Location',
              'Help renters find your gear',
              Icons.location_on_outlined,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _locationNameController,
              label: 'Location Name',
              hint: 'Downtown Park, Home, Storage Unit',
              icon: Icons.location_city_outlined,
            ),

            const SizedBox(height: 16),

            _buildTextField(
              controller: _pickupAddressController,
              label: 'Full Address',
              hint: 'Street address for pickup',
              icon: Icons.location_on_outlined,
              maxLines: 2,
            ),

            const SizedBox(height: 16),

            // Latitude and Longitude fields
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _latitudeController,
                    label: 'Latitude',
                    hint: 'e.g., 40.7128',
                    icon: Icons.location_on_outlined,
                    keyboardType: TextInputType.number,
                    readOnly: true, // Make it read-only
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _longitudeController,
                    label: 'Longitude',
                    hint: 'e.g., -74.0060',
                    icon: Icons.location_on_outlined,
                    keyboardType: TextInputType.number,
                    readOnly: true, // Make it read-only
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Pick Location from Map Button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _openMapPicker,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFBB86FC).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.map_outlined,
                        color: const Color(0xFFBB86FC),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pick Location from Map',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _pickedAddress != null
                                  ? _pickedAddress!
                                  : 'Tap to select location on map',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_outlined,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Public Visibility
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFBB86FC).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.public_outlined,
                      color: Color(0xFFBB86FC),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Make Public',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Show this in the public marketplace',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isPublic,
                    activeColor: const Color(0xFFBB86FC),
                    onChanged: (value) {
                      setState(() => _isPublic = value);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.add),
                label: Text(
                  _isLoading ? 'Adding Equipment...' : 'List My Equipment',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Reset Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isLoading ? null : _resetForm,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Clear Form',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFBB86FC).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFFBB86FC).withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Icon(icon, color: const Color(0xFFBB86FC), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    FormFieldValidator<String>? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        readOnly: readOnly,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          prefixIcon: icon != null ? Icon(icon) : null,
          labelStyle: TextStyle(color: Colors.grey[400]),
          hintStyle: TextStyle(color: Colors.grey[700]),
        ),
      ),
    );
  }
}
