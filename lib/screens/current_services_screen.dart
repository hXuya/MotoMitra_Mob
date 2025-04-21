import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:moto_mitra/services/auth_service.dart';
import 'recommended_item_screen.dart';

class CurrentServicesScreen extends StatefulWidget {
  const CurrentServicesScreen({super.key});

  @override
  State<CurrentServicesScreen> createState() => _CurrentServicesScreenState();
}

class _CurrentServicesScreenState extends State<CurrentServicesScreen> {
  bool _isLoading = true;
  List<dynamic> _services = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCurrentServices();
  }

  Future<void> _fetchCurrentServices() async {
    setState(() => _isLoading = true);
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Authentication error. Please login again.';
        });
        return;
      }

      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/api/reservation/accepted-user'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && mounted) {
        setState(() {
          _services = data['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = data['msg'] ?? 'Failed to load services';
        });
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error: ${e.toString()}';
        });
    }
  }

  String _formatDate(String dateString) {
    return DateFormat('MMM dd, yyyy - hh:mm a')
        .format(DateTime.parse(dateString));
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'started':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'started':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      default:
        return 'Scheduled';
    }
  }

  void _navigateToRecommendedItems(String reservationId, String serviceName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecommendedItemsScreen(
          reservationId: reservationId,
          serviceName: serviceName,
        ),
      ),
    ).then((_) => _fetchCurrentServices());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF5F2),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF9900)))
          : RefreshIndicator(
              color: const Color(0xFFFF9900),
              onRefresh: _fetchCurrentServices,
              child: _errorMessage != null
                  ? _buildErrorState()
                  : _services.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _services.length,
                          itemBuilder: (context, index) =>
                              _buildServiceCard(_services[index]),
                        ),
            ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchCurrentServices,
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFA800)),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.engineering, size: 64, color: Color(0xFFE58A00)),
          SizedBox(height: 16),
          Text('No active services found',
              style: TextStyle(fontSize: 18, color: Color(0xFF666666))),
          SizedBox(height: 8),
          Text('Book a service to get started',
              style: TextStyle(fontSize: 14, color: Color(0xFF999999))),
        ],
      ),
    );
  }

  Widget _buildServiceCard(dynamic service) {
    final reservationId = service['_id'];
    final serviceName = service['title'] ?? 'Untitled Service';
    final garageName = service['garage']?['name'] ?? 'Unknown Garage';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFCEFE8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8C5AE)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFFFE8D6),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Text(
              garageName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE58A00),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        serviceName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF9900),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(service['workstatus']),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusText(service['workstatus']),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.directions_car_outlined,
                    service['vehicle']?['name'] ?? 'Unknown Vehicle'),
                _buildInfoRow(Icons.location_on_outlined,
                    service['garage']?['location'] ?? 'Unknown Location'),
                _buildInfoRow(Icons.access_time, _formatDate(service['date'])),
                if (service['description'] != null &&
                    service['description'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      service['description'],
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF333333)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _navigateToRecommendedItems(reservationId, serviceName),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE58A00),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      foregroundColor: Colors.white,
                    ),
                    icon:
                        const Icon(Icons.build, size: 18, color: Colors.white),
                    label: const Text(
                      'View Recommended Parts',
                      style: TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFFE58A00)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
