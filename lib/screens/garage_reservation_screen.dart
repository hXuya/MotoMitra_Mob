import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:moto_mitra/services/auth_service.dart';

class GarageReservationScreen extends StatefulWidget {
  final dynamic garage;
  const GarageReservationScreen({super.key, required this.garage});

  @override
  State<GarageReservationScreen> createState() =>
      _GarageReservationScreenState();
}

class _GarageReservationScreenState extends State<GarageReservationScreen> {
  bool _isLoading = true;
  bool _submitting = false;
  List<dynamic> _vehicles = [];
  dynamic _selectedVehicle;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _towingRequested = false;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController(text: "Current Location");

  final Color _primaryColor = const Color(0xFFFF9900);
  final Color _backgroundColor = const Color(0xFFFDF5F2);
  final Color _cardColor = const Color(0xFFFCEFE8);
  final Color _borderColor = const Color(0xFFE8C5AE);

  @override
  void initState() {
    super.initState();
    _fetchUserVehicles();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _fetchUserVehicles() async {
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
        final data = jsonDecode(response.body);
        setState(() {
          _vehicles = data['data'];
          if (_vehicles.isNotEmpty) _selectedVehicle = _vehicles[0];
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

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: _primaryColor),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
      _selectTime();
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: _primaryColor),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) setState(() => _selectedTime = picked);
  }

  Future<void> _submitReservation() async {
    if (!_formKey.currentState!.validate() || _selectedVehicle == null) {
      if (_selectedVehicle == null) _showMessage("Please select a vehicle");
      return;
    }

    setState(() => _submitting = true);
    try {
      final dateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/api/reservation'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await AuthService.getToken()}'
        },
        body: jsonEncode({
          'vehicle': _selectedVehicle['_id'],
          'garage': widget.garage['_id'],
          'date': dateTime.toIso8601String(),
          'title': _titleController.text,
          'description': _descriptionController.text,
          'towingRequest': _towingRequested,
          'location': _locationController.text,
        }),
      );

      if (response.statusCode == 200 && mounted) {
        _showMessage("Reservation created successfully");
        Navigator.pop(context, true);
      } else if (mounted) {
        final error = jsonDecode(response.body);
        _showMessage(error['msg'] ?? "Failed to create reservation");
      }
    } catch (e) {
      if (mounted) _showMessage("Error: $e");
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _getVehicleImagePath(String type) {
    switch (type.toLowerCase()) {
      case 'bike':
        return 'assets/images/bike.png';
      case 'scooter':
        return 'assets/images/scooter.png';
      default:
        return 'assets/images/car.png';
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator ?? (value) => value!.isEmpty ? 'Required' : null,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: _primaryColor),
        filled: true,
        fillColor: _cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _primaryColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        title: Text('Book Service',
            style:
                TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _borderColor),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _borderColor),
                            ),
                            child: widget.garage['image'] != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      AuthService.formatProfileImageUrl(
                                              widget.garage['image']) ??
                                          '',
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Center(
                                    child: Image.asset(
                                        'assets/images/garage.png',
                                        width: 40,
                                        height: 40)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.garage['name'] ?? 'Garage',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: _primaryColor),
                                ),
                                if (widget.garage['location'] != null)
                                  Text(
                                    widget.garage['location'],
                                    style: const TextStyle(
                                        fontSize: 14, color: Colors.black54),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('Select Vehicle',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    _vehicles.isEmpty
                        ? Container(
                            height: 100,
                            decoration: BoxDecoration(
                              color: _cardColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: _borderColor),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('No vehicles found',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  TextButton(
                                    onPressed: () => Navigator.pushNamed(
                                            context, '/my-vehicles')
                                        .then((_) => _fetchUserVehicles()),
                                    child: Text('Add Vehicle',
                                        style: TextStyle(color: _primaryColor)),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Container(
                            height: 120,
                            decoration: BoxDecoration(
                              color: _cardColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: _borderColor),
                            ),
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _vehicles.length,
                              padding: const EdgeInsets.all(8),
                              itemBuilder: (context, index) {
                                final vehicle = _vehicles[index];
                                final isSelected = _selectedVehicle != null &&
                                    _selectedVehicle['_id'] == vehicle['_id'];
                                return GestureDetector(
                                  onTap: () => setState(
                                      () => _selectedVehicle = vehicle),
                                  child: Container(
                                    width: 100,
                                    margin: const EdgeInsets.only(right: 10),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Color.fromRGBO(255, 153, 0, 0.15)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSelected
                                            ? _primaryColor
                                            : Colors.grey.withAlpha(77),
                                        width: 2,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                            _getVehicleImagePath(
                                                vehicle['type'] ?? 'car'),
                                            width: 40,
                                            height: 40),
                                        const SizedBox(height: 5),
                                        Text(
                                          vehicle['name'] ?? 'Vehicle',
                                          style: TextStyle(
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: isSelected
                                                ? _primaryColor
                                                : Colors.black87,
                                          ),
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          vehicle['number'] ?? '',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isSelected
                                                ? _primaryColor
                                                : Colors.black54,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                    const SizedBox(height: 24),
                    InkWell(
                      onTap: _selectDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: _cardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _borderColor),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: _primaryColor),
                            const SizedBox(width: 10),
                            Text(
                              '${DateFormat('MMM dd, yyyy').format(_selectedDate)} at ${_selectedTime.format(context)}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const Spacer(),
                            Icon(Icons.arrow_drop_down, color: _primaryColor),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(
                      controller: _titleController,
                      labelText: 'Service Title',
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _descriptionController,
                      labelText: 'Description of issue',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _locationController,
                      labelText: 'Your Location',
                    ),
                    const SizedBox(height: 24),
                    if (widget.garage['towing'] == true)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _cardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _borderColor),
                        ),
                        child: Row(
                          children: [
                            Image.asset('assets/icons/towing.png',
                                width: 24, height: 24, color: _primaryColor),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Request Towing Service',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500)),
                                  Text('If your vehicle is immobilized',
                                      style: TextStyle(
                                          fontSize: 14, color: Colors.black54)),
                                ],
                              ),
                            ),
                            Switch(
                              value: _towingRequested,
                              onChanged: (value) =>
                                  setState(() => _towingRequested = value),
                              activeColor: _primaryColor,
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: // Replace the existing button code (around line 374) with this:
                          ElevatedButton(
                        onPressed: _submitting ? null : _submitReservation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFA800),
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          disabledBackgroundColor: const Color(0xFFFFCC80),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Confirm Booking',
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
            ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}
