import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pet_profile_screen.dart';
import 'appointment_screen.dart';
import 'billing_screen.dart';  // Import the BillingScreen

class DashboardScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(' Pet Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PetProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('pets')
                  .where('ownerId', isEqualTo: _auth.currentUser!.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                var pets = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: pets.length,
                  itemBuilder: (context, index) {
                    var pet = pets[index];
                    return ListTile(
                      title: Text(pet['name']),
                      subtitle: Text(pet['breed']),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PetProfileScreen(petId: pet.id),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AppointmentScreen()),
              );
            },
            child: Text('View Appointments'),
          ),
          // Button to go to Billing Screen
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BillingScreen()),
              );
            },
            child: Text('Go to Billing'),
          ),
        ],
      ),
    );
  }
}
