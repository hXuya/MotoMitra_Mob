import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:moto_mitra/services/auth_service.dart';

class CustomVehicleIcons {
  static const _kFontFam = 'MyFlutterApp';
  static const IconData motorcycleSilhouette =
      IconData(0xe800, fontFamily: _kFontFam);
  static const IconData scooterIcon = IconData(0xe801, fontFamily: _kFontFam);
}

class MyVehicleScreen extends StatefulWidget {
  const MyVehicleScreen({super.key});
  @override
  State<MyVehicleScreen> createState() => _MyVehicleScreenState();
}

class _MyVehicleScreenState extends State<MyVehicleScreen> {
  bool _isLoading = true;
  List _vehicles = [];
  final _c = const Color(0xFFFF9900); // base color
  final _bg = const Color(0xFFFDF5F2); // background

  @override
  void initState() {
    super.initState();
    _fetchVehicles();
  }

  void _msg(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _fetchVehicles() async {
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
        setState(() {
          _vehicles = jsonDecode(res.body)['data'];
          _isLoading = false;
        });
      } else if (mounted) {
        if (context.mounted) {
          _msg("Failed to load vehicles");
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        if (context.mounted) {
          _msg("Error: $e");
        }
      }
    }
  }

  Future<void> _deleteVehicle(String id, String name) async {
    if (await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: _bg,
            title: Text('Delete Vehicle', style: TextStyle(color: _c)),
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
        ) !=
        true) {
      return;
    }

    try {
      final res = await http.delete(
        Uri.parse('${AuthService.baseUrl}/api/vehicle/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await AuthService.getToken()}'
        },
      );
      if (res.statusCode == 200 && mounted) {
        if (context.mounted) {
          _msg("Vehicle deleted successfully");
          _fetchVehicles();
        }
      } else {
        if (context.mounted) {
          _msg(jsonDecode(res.body)['message'] ?? "Failed to delete vehicle");
        }
      }
    } catch (e) {
      if (context.mounted) {
        _msg("Error: $e");
      }
    }
  }

  Widget _icon(String t) {
    const c = Color(0xFFFF9900);
    const s1 = 28.0;
    const s2 = s1 * 1.8;
    return Icon(
        t.toLowerCase() == 'car'
            ? Icons.directions_car
            : t.toLowerCase() == 'bike'
                ? CustomVehicleIcons.motorcycleSilhouette
                : t.toLowerCase() == 'scooter'
                    ? CustomVehicleIcons.scooterIcon
                    : Icons.directions_car,
        size: t.toLowerCase() == 'car' ? s1 : s2,
        color: c);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text('My Vehicles',
            style: TextStyle(color: _c, fontWeight: FontWeight.bold)),
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _c),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        backgroundColor: _c,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _c))
          : _vehicles.isEmpty
              ? _emptyState()
              : _vehicleList(),
    );
  }

  void _showForm([dynamic v]) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => VehicleForm(
            vehicle: v,
            onSave: () {
              Navigator.pop(context);
              _fetchVehicles();
            }),
      );

  Widget _emptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.directions_car_outlined,
                size: 80, color: Color(0xFFE58A00)),
            const SizedBox(height: 16),
            const Text('No vehicles found',
                style: TextStyle(fontSize: 18, color: Color(0xFF333333))),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _showForm(),
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

  Widget _vehicleList() => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _vehicles.length,
        itemBuilder: (_, i) {
          final v = _vehicles[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: const Color(0xFFFCEFE8),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 55,
                        height: 55,
                        decoration: const BoxDecoration(
                            color: Color(0xFFFFEEDD), shape: BoxShape.circle),
                        child: Center(child: _icon(v['type'])),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(v['name'],
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: _c)),
                            const SizedBox(height: 4),
                            Text('Model: ${v['model']}'),
                            Text('Number: ${v['number']}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: IconButton(
                    icon: Icon(Icons.edit, color: _c),
                    onPressed: () => _showForm(v),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: IconButton(
                    icon: Icon(Icons.delete, color: _c),
                    onPressed: () => _deleteVehicle(v['_id'], v['name']),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
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
  final _name = TextEditingController();
  final _model = TextEditingController();
  final _number = TextEditingController();
  String _type = 'Car';
  final _types = ['Car', 'Bike', 'Scooter', 'Other'];
  final _c = const Color(0xFFFF9900);

  @override
  void initState() {
    super.initState();
    if (widget.vehicle != null) {
      _name.text = widget.vehicle['name'] ?? '';
      _model.text = widget.vehicle['model'] ?? '';
      _number.text = widget.vehicle['number'] ?? '';
      _type = widget.vehicle['type'] ?? 'Car';
    }
  }

  Widget _icon(String t) {
    const c = Color(0xFFFF9900);
    const s1 = 20.0;
    const s2 = s1 * 1.8;
    return Icon(
        t.toLowerCase() == 'car'
            ? Icons.directions_car
            : t.toLowerCase() == 'bike'
                ? CustomVehicleIcons.motorcycleSilhouette
                : t.toLowerCase() == 'scooter'
                    ? CustomVehicleIcons.scooterIcon
                    : Icons.directions_car,
        size: t.toLowerCase() == 'car' ? s1 : s2,
        color: c);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      final edit = widget.vehicle != null;
      final uri = Uri.parse(
          '${AuthService.baseUrl}/api/vehicle${edit ? "/${widget.vehicle['_id']}" : ""}');
      final data = {
        'name': _name.text,
        'model': _model.text,
        'number': _number.text,
        'type': _type
      };
      final token = await AuthService.getToken();
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      };

      final res = edit
          ? await http.put(uri, headers: headers, body: jsonEncode(data))
          : await http.post(uri, headers: headers, body: jsonEncode(data));

      if (res.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(edit ? "Vehicle updated" : "Vehicle added")));
        widget.onSave();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(jsonDecode(res.body)['message'] ?? "Failed")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  InputDecoration _decor(String label) => InputDecoration(
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
    final edit = widget.vehicle != null;
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
              Text(edit ? 'Edit Vehicle' : 'Add Vehicle',
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold, color: _c)),
              const SizedBox(height: 20),
              TextFormField(
                controller: _name,
                validator: (v) => v!.isEmpty ? 'Required' : null,
                decoration: _decor('Name'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _model,
                validator: (v) => v!.isEmpty ? 'Required' : null,
                decoration: _decor('Model'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _number,
                validator: (v) => v!.isEmpty ? 'Required' : null,
                decoration: _decor('Number'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _type,
                decoration: _decor('Type'),
                dropdownColor: const Color(0xFFFCEFE8),
                items: _types
                    .map((t) => DropdownMenuItem<String>(
                          value: t,
                          child: Row(children: [
                            _icon(t),
                            const SizedBox(width: 10),
                            Text(t)
                          ]),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _type = v);
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitting ? null : _save,
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
                    : Text(edit ? 'Update' : 'Add',
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
    _name.dispose();
    _model.dispose();
    _number.dispose();
    super.dispose();
  }
}
