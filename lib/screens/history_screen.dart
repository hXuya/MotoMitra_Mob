import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:moto_mitra/services/auth_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isLoading = true;
  List<dynamic> _reservations = [];

  @override
  void initState() {
    super.initState();
    _fetchArchivedReservations();
  }

  Future<void> _fetchArchivedReservations() async {
    setState(() => _isLoading = true);
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        _showSnackBar('No token found');
        setState(() => _isLoading = false);
        return;
      }

      final baseUrl = AuthService.baseUrl;
      // Fixed the API endpoint URL to match the backend route
      final response = await http.get(
        Uri.parse('$baseUrl/api/reservation/archive-user'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        setState(() {
          _reservations = data['data'];
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Failed to load history');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar("Error: ${e.toString()}");
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'cancelled':
        return const Color(0xFFE15E3B);
      case 'completed':
        return const Color(0xFF4CAF50);
      case 'pending':
        return const Color(0xFFFFB74D);
      default:
        return const Color(0xFF666666);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(
            child: CircularProgressIndicator(color: Color(0xFFE15E3B)),
          )
        : _reservations.isEmpty
            ? _buildEmptyState()
            : RefreshIndicator(
                onRefresh: _fetchArchivedReservations,
                color: const Color(0xFFE15E3B),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _reservations.length,
                  itemBuilder: (context, index) =>
                      _buildReservationCard(_reservations[index]),
                ),
              );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history, size: 80, color: Color(0xFFE8C5AE)),
          const SizedBox(height: 16),
          Text(
            'No reservation history found',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Color(0xFF666666),
            ),
          ),
          // Refresh button removed as requested
        ],
      ),
    );
  }

  Widget _buildReservationCard(dynamic reservation) {
    final vehicleName = reservation['vehicle']?['name'] ?? 'Unknown Vehicle';
    final garageName = reservation['garage']?['name'] ?? 'Unknown Garage';
    final location = reservation['garage']?['location'] ?? 'Unknown Location';
    final status = reservation['status'] ?? 'Unknown';
    final date = reservation['date'] != null
        ? DateTime.parse(reservation['date']).toString().split(' ')[0]
        : 'No date';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  vehicleName,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE15E3B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(status),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.garage, garageName),
          _buildInfoRow(Icons.location_on, location),
          _buildInfoRow(Icons.calendar_today, date),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Color(0xFFE15E3B)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Color(0xFF666666),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
