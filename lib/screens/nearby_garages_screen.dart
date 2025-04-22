import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:moto_mitra/services/auth_service.dart';
import 'garage_reservation_screen.dart';

class NearbyGaragesScreen extends StatefulWidget {
  const NearbyGaragesScreen({super.key});

  @override
  State<NearbyGaragesScreen> createState() => _NearbyGaragesScreenState();
}

class _NearbyGaragesScreenState extends State<NearbyGaragesScreen> {
  bool _isLoading = true;
  List _nearbyGarages = [];
  double _latitude = 0.0, _longitude = 0.0;
  String _locationName = 'Current Location';
  String? _errorMessage;
  double _searchRadius = 5.0;

  final Color _primaryColor = const Color(0xFFFF9900);
  final Color _backgroundColor = const Color(0xFFFDF5F2);
  final Color _cardColor = const Color(0xFFFCEFE8);
  final Color _borderColor = const Color(0xFFE8C5AE);
  final Color _iconColor = const Color(0xFFE58A00);

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    setState(() => _isLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'Location services disabled';
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
          _errorMessage = 'Location permissions permanently denied';
          _isLoading = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      await _getLocationName();
      await _fetchNearbyGarages();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _getLocationName() async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(_latitude, _longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _locationName = place.locality != null && place.locality!.isNotEmpty
              ? '${place.locality}, ${place.administrativeArea ?? ''}'
              : 'Current Location';
        });
      }
    } catch (_) {}
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
            '${AuthService.baseUrl}/api/garage/get-nearby-garages?latitude=$_latitude&longitude=$_longitude&radius=$_searchRadius'),
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

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: AppBar(
          backgroundColor: _backgroundColor,
          elevation: 0,
          automaticallyImplyLeading: false,
          flexibleSpace: SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: _cardColor,
                border:
                    Border(bottom: BorderSide(color: _borderColor, width: 1)),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: _iconColor, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _locationName,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: _primaryColor))
                : _errorMessage != null
                    ? _buildErrorState()
                    : _nearbyGarages.isEmpty
                        ? _buildEmptyState()
                        : _buildGarageList(),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              border: Border(bottom: BorderSide(color: _borderColor, width: 1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  offset: const Offset(0, -2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Search radius:',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    Text('${_searchRadius.round()} km',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: _primaryColor)),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: _primaryColor,
                    inactiveTrackColor: _borderColor,
                    thumbColor: _primaryColor,
                  ),
                  child: Slider(
                    value: _searchRadius,
                    min: 1,
                    max: 20,
                    divisions: 19,
                    onChanged: (value) => setState(() => _searchRadius = value),
                    onChangeEnd: (_) => _fetchNearbyGarages(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: _primaryColor),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(_errorMessage!, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _determinePosition,
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _fetchNearbyGarages,
      color: _primaryColor,
      child: ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/garage.png',
                      width: 280, height: 280),
                  const SizedBox(height: 16),
                  Text('No garages found nearby',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor)),
                  Text('Try increasing the search radius'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGarageList() {
    return RefreshIndicator(
      onRefresh: _fetchNearbyGarages,
      color: _primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _nearbyGarages.length,
        itemBuilder: (context, index) {
          final garage = _nearbyGarages[index];
          final distance = _calculateDistance(
            _latitude,
            _longitude,
            garage['latitude'] ?? 0.0,
            garage['longitude'] ?? 0.0,
          );
          final rating =
              garage['rating'] != null ? (garage['rating'] as num).toInt() : 0;

          return InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => GarageReservationScreen(garage: garage)),
            ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: _borderColor.withAlpha(204), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                        height: 160,
                        decoration: BoxDecoration(
                          color: _cardColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
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
                            ? Center(
                                child: Image.asset('assets/images/garage.png',
                                    width: 220))
                            : null,
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Row(
                          children: [
                            Icon(Icons.star, color: _primaryColor, size: 18),
                            const SizedBox(width: 2),
                            Text(
                              rating.toString(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _primaryColor,
                                shadows: [
                                  Shadow(
                                    color: Colors.white.withAlpha(178),
                                    blurRadius: 2,
                                    offset: const Offset(0, 0),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Row(
                          children: [
                            Icon(
                              Icons.directions,
                              color: _primaryColor,
                              size: 16,
                              shadows: [
                                Shadow(
                                    color: Colors.white.withAlpha(178),
                                    blurRadius: 2)
                              ],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${distance.toStringAsFixed(1)} km',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _primaryColor,
                                fontSize: 13,
                                shadows: [
                                  Shadow(
                                    color: Colors.white.withAlpha(178),
                                    blurRadius: 2,
                                    offset: const Offset(0, 0),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                garage['name'] ?? 'Unnamed Garage',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: _primaryColor,
                                ),
                              ),
                            ),
                            if (garage['openHours'] != null) ...[
                              Icon(Icons.access_time_outlined,
                                  color: _iconColor, size: 16),
                              const SizedBox(width: 4),
                              Text(garage['openHours'],
                                  style: const TextStyle(fontSize: 13)),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                color: _iconColor, size: 16),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                garage['location'] ?? 'No address',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Image.asset('assets/icons/towing.png',
                                width: 16, height: 16, color: _iconColor),
                            const SizedBox(width: 4),
                            Text(
                              garage['towing'] == true
                                  ? 'Available'
                                  : 'Unavailable',
                              style: TextStyle(
                                color: garage['towing'] == true
                                    ? _primaryColor
                                    : Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
