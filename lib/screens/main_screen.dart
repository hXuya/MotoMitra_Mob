import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moto_mitra/screens/accounts_setting_screen.dart';
import 'package:moto_mitra/screens/nearby_garages_screen.dart'; // Make sure the path is correct

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
              label: 'My Services',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.location_on_outlined),
              label: 'Nearby Garages',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'History',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildMyServicesScreen();
      case 1:
        return _buildNearbyGaragesScreen();
      case 2:
        return _buildHistoryScreen();
      default:
        return _buildNearbyGaragesScreen();
    }
  }

  Widget _buildMyServicesScreen() {
    return Center(
      child: Text(
        'My Services',
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFFE15E3B),
        ),
      ),
    );
  }

  Widget _buildNearbyGaragesScreen() {
    return NearbyGaragesScreen(); // Fully integrated screen
  }

  Widget _buildHistoryScreen() {
    return Center(
      child: Text(
        'History',
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFFE15E3B),
        ),
      ),
    );
  }
}
