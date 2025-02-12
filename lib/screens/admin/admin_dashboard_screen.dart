import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pet_care_clinic_new/screens/admin/AppointmentDetailsScreen.dart';
import 'package:pet_care_clinic_new/screens/admin/manage_vets_screen.dart';
import 'package:pet_care_clinic_new/screens/admin/reports_screen.dart';


import '../common/notifications_screen.dart';
import '../common/profile_screen.dart';
import '../common/settings_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.animateToPage(index,
          duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: NeverScrollableScrollPhysics(),
        children: [
          _buildDashboard(),  // Admin Dashboard
          ProfileScreen(),    // Profile Page
          NotificationsScreen(), // Notifications Page
          SettingsScreen(),   // Settings Page
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return Column(
      children: [
        AppBar(
          title: Text('Admin Dashboard'),
        ),
        Card(
          child: ListTile(
            title: Text('Total Revenue'),
            subtitle: FutureBuilder<QuerySnapshot>(
              future: _firestore.collection('billings').get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Text('Loading...');
                }
                double totalRevenue = 0;
                snapshot.data!.docs.forEach((bill) {
                  totalRevenue += bill['amount'];
                });
                return Text('\$${totalRevenue.toStringAsFixed(2)}');
              },
            ),
          ),
        ),
        Card(
          child: ListTile(
            title: Text('Total Appointments'),
            subtitle: FutureBuilder<QuerySnapshot>(
              future: _firestore.collection('appointments').get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Text('Loading...');
                }
                return Text('${snapshot.data!.docs.length}');
              },
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AppointmentDetailsScreen(),
                ),
              );
            },
          ),
        ),
        Card(
          child: ListTile(
            title: Text('Total Users'),
            subtitle: FutureBuilder<QuerySnapshot>(
              future: _firestore.collection('users').get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Text('Loading...');
                }
                return Text('${snapshot.data!.docs.length}');
              },
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ManageVetsScreen()),
            );
          },
          child: Text('Manage Veterinarians'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ReportsScreen()),
            );
          },
          child: Text('Generate Reports'),
        ),
      ],
    );
  }
}
