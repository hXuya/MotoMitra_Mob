import 'package:flutter/material.dart';
import 'package:moto_mitra/services/auth_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class NearbyGaragesScreen extends StatefulWidget {
  const NearbyGaragesScreen({Key? key}) : super(key: key);

  @override
  State<NearbyGaragesScreen> createState() => _NearbyGaragesScreenState();
}

class _NearbyGaragesScreenState extends State<NearbyGaragesScreen> {
  bool _isLoading = true;
  List<dynamic> _nearbyGarages = [];
  double _searchRadius = 5.0;
  double _latitude = 0.0;
  double _longitude = 0.0;
  String _locationName = 'Current Location';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  // Comprehensive position and permission handling
  Future<void> _determinePosition() async {
    setState(() => _isLoading = true);

    try {
      // Test if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage =
              'Location services are disabled. Please enable location services.';
          _isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = 'Location permission denied';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage =
              'Location permissions permanently denied. Please enable in settings.';
          _isLoading = false;
        });
        return;
      }

      // Get the current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      // Get location name from coordinates
      await _getAddressFromLatLng(position.latitude, position.longitude);

      // Fetch nearby garages
      _fetchNearbyGarages();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error getting location: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _latitude = lat;
          _longitude = lng;

          // Building a more precise location name
          List<String> locationParts = [];

          if (place.locality != null && place.locality!.isNotEmpty) {
            locationParts.add(place.locality!);
          } else if (place.subLocality != null &&
              place.subLocality!.isNotEmpty) {
            locationParts.add(place.subLocality!);
          }

          if (place.administrativeArea != null &&
              place.administrativeArea!.isNotEmpty) {
            locationParts.add(place.administrativeArea!);
          }

          _locationName = locationParts.isNotEmpty
              ? locationParts.join(', ')
              : 'Current Location';
        });
      }
    } catch (e) {
      // If geocoding fails, at least set the coordinates
      setState(() {
        _latitude = lat;
        _longitude = lng;
      });
    }
  }

  Future<void> _fetchNearbyGarages() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        setState(() {
          _errorMessage = 'Authentication required';
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse(
            '${AuthService.baseUrl}/api/get-nearby-garages?latitude=$_latitude&longitude=$_longitude&radius=$_searchRadius'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _nearbyGarages = data['data'] ?? [];
          _isLoading = false;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch nearby garages';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF5F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF5F2),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFFCEFE8),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.location_on,
                color: Color(0xFFE58A00),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _locationName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF9900)),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 60,
                color: Color(0xFFE58A00),
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF666666),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _determinePosition,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9900),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        _nearbyGarages.isEmpty ? _buildEmptyState() : _buildGarageList(),
        _buildRadiusSlider(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.build_circle_outlined,
            size: 80,
            color: Color(0xFFE58A00),
          ),
          SizedBox(height: 16),
          Text(
            'No garages found nearby',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF666666),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try increasing the search radius',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF888888),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGarageList() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80, left: 16, right: 16, top: 16),
      itemCount: _nearbyGarages.length,
      itemBuilder: (context, index) {
        final garage = _nearbyGarages[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(14)),
                  color: const Color(0xFFFCEFE8),
                  image: garage['image'] != null
                      ? DecorationImage(
                          image: NetworkImage(
                            AuthService.formatProfileImageUrl(
                                    garage['image']) ??
                                '',
                          ),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: garage['image'] == null
                    ? const Center(
                        child: Icon(
                          Icons.garage,
                          size: 50,
                          color: Color(0xFFE58A00),
                        ),
                      )
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      garage['name'] ?? 'Unnamed Garage',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: Color(0xFF999999),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            garage['address'] ?? 'No address provided',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.phone_outlined,
                          color: Color(0xFF999999),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          garage['phoneNumber'] ?? 'No phone number',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Booking garage: ${garage['name'] ?? garage['_id']}'),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF9900),
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Book Garage',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRadiusSlider() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        color: const Color(0xFFFCEFE8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Search Radius',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                ),
                Text(
                  '${_searchRadius.toStringAsFixed(1)} km',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFE58A00),
                  ),
                ),
              ],
            ),
            Slider(
              value: _searchRadius,
              min: 1.0,
              max: 20.0,
              divisions: 19,
              activeColor: const Color(0xFFFF9900),
              inactiveColor: const Color(0xFFE8C5AE),
              onChanged: (value) {
                setState(() {
                  _searchRadius = value;
                });
              },
              onChangeEnd: (value) {
                _fetchNearbyGarages();
              },
            ),
          ],
        ),
      ),
    );
  }
}
