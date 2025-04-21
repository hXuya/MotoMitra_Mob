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
  bool _isLoading = true, _submitting = false, _towingRequested = false;
  List _vehicles = [];
  dynamic _selectedVehicle;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final Color _primaryColor = const Color(0xFFFF9900);
  final Color _bgColor = const Color(0xFFFDF5F2);
  final Color _cardColor = const Color(0xFFFCEFE8);
  final Color _borderColor = const Color(0xFFE8C5AE);

  @override
  void initState() {
    super.initState();
    _fetchUserVehicles();
  }

  void _showMsg(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _fetchUserVehicles() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('${AuthService.baseUrl}/api/vehicle/my-vehicles'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await AuthService.getToken()}'
        },
      );
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        setState(() {
          _vehicles = data['data'];
          if (_vehicles.isNotEmpty) _selectedVehicle = _vehicles[0];
          _isLoading = false;
        });
      } else if (mounted) {
        _showMsg("Failed to load vehicles");
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showMsg("Error: $e");
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
          timePickerTheme: TimePickerThemeData(
            dayPeriodColor: WidgetStateColor.resolveWith((states) =>
                states.contains(MaterialState.selected)
                    ? _primaryColor.withOpacity(0.15)
                    : Colors.transparent),
            dayPeriodTextColor: MaterialStateColor.resolveWith((states) =>
                states.contains(MaterialState.selected)
                    ? _primaryColor
                    : Colors.black87),
          ),
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
          timePickerTheme: TimePickerThemeData(
            dayPeriodColor: WidgetStateColor.resolveWith((states) {
              return states.contains(WidgetState.selected)
                  ? _primaryColor.withAlpha(38) // ≈ 15% opacity
                  : Colors.transparent;
            }),
            dayPeriodTextColor: WidgetStateColor.resolveWith((states) {
              return states.contains(WidgetState.selected)
                  ? _primaryColor
                  : Colors.black87;
            }),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) setState(() => _selectedTime = picked);
  }

  Future<void> _submitReservation() async {
    if (!_formKey.currentState!.validate() || _selectedVehicle == null) {
      if (_selectedVehicle == null) _showMsg("Please select a vehicle");
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
      final res = await http.post(
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
      if (res.statusCode == 200 && mounted) {
        _showMsg("Reservation created successfully");
        Navigator.pop(context, true);
      } else if (mounted) {
        final error = jsonDecode(res.body);
        _showMsg(error['msg'] ?? "Failed to create reservation");
      }
    } catch (e) {
      if (mounted) _showMsg("Error: $e");
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _getVehicleImg(String type) {
    switch (type.toLowerCase()) {
      case 'bike':
        return 'assets/images/bike.png';
      case 'scooter':
        return 'assets/images/scooter.png';
      default:
        return 'assets/images/car.png';
    }
  }

  InputDecoration _inpDeco(String label) => InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: _primaryColor),
        filled: true,
        fillColor: _cardColor,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _borderColor)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _borderColor)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _primaryColor)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.red)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        title: Text('Book Service',
            style:
                TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
        leading: IconButton(
            icon: Icon(Icons.arrow_back, color: _primaryColor),
            onPressed: () => Navigator.pop(context)),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primaryColor))
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 80),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Select Vehicle',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _primaryColor)),
                          _buildVehicleSelector(),
                          const SizedBox(height: 16),
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
                                  Icon(Icons.calendar_today,
                                      color: _primaryColor),
                                  const SizedBox(width: 10),
                                  Text(
                                      '${DateFormat('MMM dd, yyyy').format(_selectedDate)} at ${_selectedTime.format(context)}'),
                                  const Spacer(),
                                  Icon(Icons.arrow_drop_down,
                                      color: _primaryColor),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _titleController,
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                            decoration: _inpDeco('Service Title'),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descriptionController,
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                            maxLines: 3,
                            decoration: _inpDeco('Description of issue'),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _locationController,
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                            decoration: _inpDeco('Your Location'),
                          ),
                          const SizedBox(height: 16),
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
                                      width: 24,
                                      height: 24,
                                      color: _primaryColor),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Request Towing Service',
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                                color: _primaryColor)),
                                        Text('If your vehicle is immobilized',
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.black54)),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: _towingRequested,
                                    onChanged: (v) =>
                                        setState(() => _towingRequested = v),
                                    activeColor: _primaryColor,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    color: _bgColor,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submitReservation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFA800),
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        disabledBackgroundColor: const Color(0xFFFFCC80),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('Confirm Booking',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildVehicleSelector() {
    if (_vehicles.isEmpty) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _borderColor)),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No vehicles found',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/my-vehicles')
                    .then((_) => _fetchUserVehicles()),
                child:
                    Text('Add Vehicle', style: TextStyle(color: _primaryColor)),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 120,
      decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _borderColor)),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _vehicles.length,
        padding: const EdgeInsets.all(8),
        itemBuilder: (ctx, i) {
          final v = _vehicles[i];
          final isSelected =
              _selectedVehicle != null && _selectedVehicle['_id'] == v['_id'];
          return GestureDetector(
            onTap: () => setState(() => _selectedVehicle = v),
            child: Container(
              width: 100,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? Color.fromRGBO(255, 153, 0, 0.15)
                    : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color:
                        isSelected ? _primaryColor : Colors.grey.withAlpha(77),
                    width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(_getVehicleImg(v['type'] ?? 'car'),
                      width: 40, height: 40),
                  const SizedBox(height: 5),
                  Text(
                    v['name'] ?? 'Vehicle',
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? _primaryColor : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    v['number'] ?? '',
                    style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? _primaryColor : Colors.black54),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
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
