import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moto_mitra/screens/accounts_setting_screen.dart';
import 'package:moto_mitra/screens/nearby_garages_screen.dart';
import 'package:moto_mitra/screens/history_screen.dart';
import 'package:moto_mitra/screens/current_services_screen.dart';

class MainScreen extends StatefulWidget {
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 1; // Default to Nearby Garages

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFEF7F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Image.asset('assets/icons/icon.png', height: 30),
            SizedBox(width: 8),
            Text(
              'MotoMitra',
              style: GoogleFonts.poppins(
                color: Color(0xFFE15E3B),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: Color(0xFFE15E3B)),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.person_outline, color: Color(0xFFE15E3B)),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const AccountSettingsScreen(userName: ''),
                ),
              );
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
              spreadRadius: 2,
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFFE15E3B),
          unselectedItemColor: Colors.grey,
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.build_outlined),
              label: 'Current Services',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.location_on_outlined),
              label: 'Nearby Garages',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'Activity',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return const CurrentServicesScreen();
      case 1:
        return NearbyGaragesScreen();
      case 2:
        return HistoryScreen();
      default:
        return NearbyGaragesScreen();
    }
  }
}
