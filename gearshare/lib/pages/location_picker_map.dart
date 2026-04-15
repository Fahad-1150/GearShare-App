import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationPickerMap extends StatefulWidget {
  final LatLng? initialLocation;

  const LocationPickerMap({super.key, this.initialLocation});

  @override
  State<LocationPickerMap> createState() => _LocationPickerMapState();
}

class _LocationPickerMapState extends State<LocationPickerMap> {
  LatLng? _pickedLocation;
  late MapController _mapController;
  String _address = "Searching address...";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _pickedLocation = widget.initialLocation;
    _mapController = MapController();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    if (_pickedLocation != null) {
      await _fetchAddress(_pickedLocation!.latitude, _pickedLocation!.longitude);
      setState(() => _isLoading = false);
      return;
    }

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition();
        final currentLatLng = LatLng(position.latitude, position.longitude);
        setState(() {
          _pickedLocation = currentLatLng;
        });
        _mapController.move(currentLatLng, 15.0);
        await _fetchAddress(position.latitude, position.longitude);
      }
    } catch (e) {
      debugPrint("Error getting location: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAddress(double lat, double lng) async {
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1');
      final response = await http.get(url, headers: {'User-Agent': 'GearShare-App'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() => _address = data['display_name'] ?? "Unknown Location");
      }
    } catch (e) {
      setState(() => _address = "Address unavailable");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Location on Map'),
        backgroundColor: const Color(0xFF1E1E1E),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _pickedLocation ?? const LatLng(0, 0),
              initialZoom: _pickedLocation != null ? 15.0 : 2.0,
              onTap: (tapPosition, latlng) {
                setState(() {
                  _pickedLocation = latlng;
                  _address = "Fetching address...";
                });
                _fetchAddress(latlng.latitude, latlng.longitude);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.gearshare',
              ),
              if (_pickedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 80.0,
                      height: 80.0,
                      point: _pickedLocation!,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 40.0,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Color(0xFFBB86FC))),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFFBB86FC), size: 20),
                      const SizedBox(height: 8),
                      Text(
                        _address,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _pickedLocation == null
                        ? null
                        : () {
                            Navigator.pop(context, {
                              'location': _pickedLocation,
                              'address': _address,
                            });
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: const Color(0xFFBB86FC),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      'Confirm Location',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context); // Pop without returning a value
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}