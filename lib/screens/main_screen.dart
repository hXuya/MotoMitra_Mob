import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moto_mitra/screens/accounts_setting_screen.dart';

class HomeScreen extends StatelessWidget {
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
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Color(0xFFE15E3B)),
                SizedBox(width: 4),
                Text(
                  'Loktantrik Chowk, Tarkeshwor',
                  style:
                      GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
            SizedBox(height: 16),
            ServiceCard(
              image: 'assets/images/service1.png',
              title: 'Vehicle Servicing Appointment',
              description:
                  'Book your vehicle service easily for maintenance and repairs.',
            ),
            SizedBox(height: 16),
            ServiceCard(
              image: 'assets/images/service2.png',
              title: 'Vehicle Towing Service',
              description:
                  'Request a tow for your vehicle in case of emergency and get it safely transported for repairs.',
            ),
          ],
        ),
      ),
    );
  }
}

class ServiceCard extends StatelessWidget {
  final String image;
  final String title;
  final String description;

  ServiceCard(
      {required this.image, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(image, height: 120),
          SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 4),
          Text(
            description,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
