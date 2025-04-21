import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:moto_mitra/services/auth_service.dart';

class RecommendedItemsScreen extends StatefulWidget {
  final String reservationId;
  final String serviceName;

  const RecommendedItemsScreen({
    super.key,
    required this.reservationId,
    required this.serviceName,
  });

  @override
  State<RecommendedItemsScreen> createState() => _RecommendedItemsScreenState();
}

class _RecommendedItemsScreenState extends State<RecommendedItemsScreen> {
  bool _isLoading = true;
  List<dynamic> _items = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchRecommendedItems();
  }

  Future<void> _fetchRecommendedItems() async {
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

      final baseUrl = AuthService.baseUrl;
      final response = await http.get(
        Uri.parse('$baseUrl/api/item/${widget.reservationId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && mounted) {
        setState(() {
          _items = data['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = data['msg'] ?? 'Failed to load items';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _handleItemAction(String itemId, String action) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return;

      final baseUrl = AuthService.baseUrl;
      final response = await http.put(
        Uri.parse('$baseUrl/api/item/$action/$itemId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Item ${action}ed successfully')),
        );
        _fetchRecommendedItems();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['msg'] ?? 'Failed to $action item')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF5F2),
      appBar: AppBar(
        title: const Text(
          'Recommended Updates',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        backgroundColor: const Color(0xFFFDF5F2),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFE58A00)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF9900)),
            )
          : RefreshIndicator(
              color: const Color(0xFFFF9900),
              onRefresh: _fetchRecommendedItems,
              child: _errorMessage != null
                  ? _buildErrorView()
                  : _items.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          itemBuilder: (context, index) {
                            return _buildItemCard(_items[index]);
                          },
                        ),
            ),
    );
  }

  Widget _buildErrorView() {
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
            onPressed: _fetchRecommendedItems,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFA800),
            ),
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
          Icon(
            Icons.build_circle_outlined,
            size: 64,
            color: Color(0xFFE58A00),
          ),
          SizedBox(height: 16),
          Text(
            'No recommended parts or items yet',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF666666),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'The garage will recommend parts as needed',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(dynamic item) {
    final bool isPending = item['status'] == 'pending';
    final bool isAccepted = item['status'] == 'accept';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isAccepted
            ? const Color(0xFFEAF7ED)
            : isPending
                ? const Color(0xFFFCEFE8)
                : const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAccepted
              ? const Color(0xFFBEDDC7)
              : isPending
                  ? const Color(0xFFE8C5AE)
                  : const Color(0xFFE0E0E0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                        item['name'] ?? 'Unnamed Item',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isAccepted
                              ? const Color(0xFF4CAF50)
                              : isPending
                                  ? const Color(0xFFFF9900)
                                  : const Color(0xFF999999),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isAccepted
                            ? const Color(0xFF4CAF50)
                            : isPending
                                ? const Color(0xFFFF9900)
                                : const Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isAccepted
                            ? 'Accepted'
                            : isPending
                                ? 'Pending'
                                : 'Rejected',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'NRS ${item['price'].toString()}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                if (item['description'] != null &&
                    item['description'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      item['description'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (isPending)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFFFE8D6),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handleItemAction(item['_id'], 'reject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFE58A00),
                        side: const BorderSide(color: Color(0xFFE58A00)),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handleItemAction(item['_id'], 'accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE58A00),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Accept'),
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
