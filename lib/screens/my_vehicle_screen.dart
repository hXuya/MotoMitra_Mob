import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:moto_mitra/services/auth_service.dart';

class MyVehicleScreen extends StatefulWidget {
  const MyVehicleScreen({super.key});
  @override
  State<MyVehicleScreen> createState() => _MyVehicleScreenState();
}

class _MyVehicleScreenState extends State<MyVehicleScreen> {
  bool _isLoading = true;
  List _vehicles = [];
  final _primaryColor = const Color(0xFFFF9900);
  final _bgColor = const Color(0xFFFDF5F2);

  @override
  void initState() {
    super.initState();
    _fetchVehicles();
  }

  void _showMessage(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  Future<void> _fetchVehicles() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/api/vehicle/my-vehicles'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await AuthService.getToken()}'
        },
      );

      if (response.statusCode == 200 && mounted) {
        setState(() {
          _vehicles = jsonDecode(response.body)['data'];
          _isLoading = false;
        });
      } else if (mounted) {
        _showMessage("Failed to load vehicles");
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showMessage("Error: $e");
      }
    }
  }

  Future<void> _deleteVehicle(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _bgColor,
        title: Text('Delete Vehicle', style: TextStyle(color: _primaryColor)),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF666666))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: Color(0xFFFF5E00))),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await http.delete(
        Uri.parse('${AuthService.baseUrl}/api/vehicle/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await AuthService.getToken()}'
        },
      );

      if (response.statusCode == 200 && mounted) {
        _showMessage("Vehicle deleted successfully");
        _fetchVehicles();
      } else if (mounted) {
        _showMessage(
            jsonDecode(response.body)['message'] ?? "Failed to delete vehicle");
      }
    } catch (e) {
      if (mounted) _showMessage("Error: $e");
    }
  }

  String _getVehicleImagePath(String type) {
    switch (type.toLowerCase()) {
      case 'car':
        return 'assets/images/car.png';
      case 'bike':
        return 'assets/images/bike.png';
      case 'scooter':
        return 'assets/images/scooter.png';
      default:
        return 'assets/images/car.png';
    }
  }

  Widget _vehicleImage(String type, {double size = 40}) {
    return Image.asset(
      _getVehicleImagePath(type),
      width: size,
      height: size,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: Text('My Vehicles',
            style:
                TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
        backgroundColor: _bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showVehicleForm(),
        backgroundColor: _primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primaryColor))
          : _vehicles.isEmpty
              ? _buildEmptyState()
              : _buildVehicleList(),
    );
  }

  void _showVehicleForm([dynamic vehicle]) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => VehicleForm(
            vehicle: vehicle,
            onSave: () {
              Navigator.pop(context);
              _fetchVehicles();
            }),
      );

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEEDD),
                borderRadius: BorderRadius.circular(75),
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/car.png',
                  width: 90,
                  height: 90,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('No vehicles found',
                style: TextStyle(fontSize: 18, color: Color(0xFF333333))),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _showVehicleForm(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFA800),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Add Vehicle',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

  Widget _buildVehicleList() => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _vehicles.length,
        itemBuilder: (_, index) {
          final vehicle = _vehicles[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: const Color(0xFFFCEFE8),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 90,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFEEDD),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                    ),
                    child: Center(
                      child: _vehicleImage(vehicle['type'], size: 60),
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vehicle['name'],
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: _primaryColor),
                              ),
                              const SizedBox(height: 4),
                              Text('Model: ${vehicle['model']}'),
                              Text('Number: ${vehicle['number']}'),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: IconButton(
                            icon: Icon(Icons.edit, color: _primaryColor),
                            onPressed: () => _showVehicleForm(vehicle),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: IconButton(
                            icon: Icon(Icons.delete, color: _primaryColor),
                            onPressed: () =>
                                _deleteVehicle(vehicle['_id'], vehicle['name']),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
}

class VehicleForm extends StatefulWidget {
  final dynamic vehicle;
  final VoidCallback onSave;
  const VehicleForm({super.key, this.vehicle, required this.onSave});
  @override
  State<VehicleForm> createState() => _VehicleFormState();
}

class _VehicleFormState extends State<VehicleForm> {
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;
  final _nameController = TextEditingController();
  final _modelController = TextEditingController();
  final _numberController = TextEditingController();
  String _selectedType = 'Car';
  final _vehicleTypes = ['Car', 'Bike', 'Scooter', 'Other'];
  final _primaryColor = const Color(0xFFFF9900);

  @override
  void initState() {
    super.initState();
    if (widget.vehicle != null) {
      _nameController.text = widget.vehicle['name'] ?? '';
      _modelController.text = widget.vehicle['model'] ?? '';
      _numberController.text = widget.vehicle['number'] ?? '';
      _selectedType = widget.vehicle['type'] ?? 'Car';
    }
  }

  String _getVehicleImagePath(String type) {
    switch (type.toLowerCase()) {
      case 'car':
        return 'assets/images/car.png';
      case 'bike':
        return 'assets/images/bike.png';
      case 'scooter':
        return 'assets/images/scooter.png';
      default:
        return 'assets/images/car.png';
    }
  }

  Widget _vehicleImage(String type) {
    return Image.asset(
      _getVehicleImagePath(type),
      width: 24,
      height: 24,
    );
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      final isEditing = widget.vehicle != null;
      final uri = Uri.parse(
          '${AuthService.baseUrl}/api/vehicle${isEditing ? "/${widget.vehicle['_id']}" : ""}');

      final vehicleData = {
        'name': _nameController.text,
        'model': _modelController.text,
        'number': _numberController.text,
        'type': _selectedType
      };

      final token = await AuthService.getToken();
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      };

      final response = isEditing
          ? await http.put(uri, headers: headers, body: jsonEncode(vehicleData))
          : await http.post(uri,
              headers: headers, body: jsonEncode(vehicleData));

      if (response.statusCode == 200 && mounted) {
        _showMessage(isEditing ? "Vehicle updated" : "Vehicle added");
        widget.onSave();
      } else if (mounted) {
        _showMessage(
            jsonDecode(response.body)['message'] ?? "Operation failed");
      }
    } catch (e) {
      if (mounted) {
        _showMessage("Error: $e");
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showMessage(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  InputDecoration _inputDecoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFFE58A00)),
        filled: true,
        fillColor: const Color(0xFFFCEFE8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE8C5AE)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE8C5AE)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.vehicle != null;

    return Container(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Color(0xFFFDF5F2),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isEditing ? 'Edit Vehicle' : 'Add Vehicle',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor)),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                validator: (value) => value!.isEmpty ? 'Required' : null,
                decoration: _inputDecoration('Name'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _modelController,
                validator: (value) => value!.isEmpty ? 'Required' : null,
                decoration: _inputDecoration('Model'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _numberController,
                validator: (value) => value!.isEmpty ? 'Required' : null,
                decoration: _inputDecoration('Number'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: _inputDecoration('Type'),
                dropdownColor: const Color(0xFFFCEFE8),
                items: _vehicleTypes
                    .map((type) => DropdownMenuItem<String>(
                          value: type,
                          child: Row(
                            children: [
                              _vehicleImage(type),
                              const SizedBox(width: 10),
                              Text(type)
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedType = value);
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitting ? null : _saveVehicle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFA800),
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(isEditing ? 'Update' : 'Add',
                        style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _modelController.dispose();
    _numberController.dispose();
    super.dispose();
  }
}
