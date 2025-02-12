import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'medical_record_screen.dart';

class AppointmentDetailsScreen extends StatelessWidget {
  final String appointmentId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AppointmentDetailsScreen({required this.appointmentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Appointment Details'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _firestore.collection('appointments').doc(appointmentId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading appointment details.'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('No appointment details found.'));
          }

          var appointmentData = snapshot.data!.data() as Map<String, dynamic>;

          // Handle missing fields gracefully
          String type = appointmentData['type'] ?? 'No Type';
          String petId = appointmentData['petId'] ?? 'No Pet ID';
          String date = appointmentData['date'] != null
              ? (appointmentData['date'] as Timestamp).toDate().toString()
              : 'No Date';

          // Fetch pet and owner details based on petId
          return FutureBuilder<DocumentSnapshot>(
            future: _firestore.collection('pets').doc(petId).get(),
            builder: (context, petSnapshot) {
              if (petSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (petSnapshot.hasError) {
                return Center(child: Text('Error loading pet details.'));
              }

              if (!petSnapshot.hasData || !petSnapshot.data!.exists) {
                return Center(child: Text('No pet details found.'));
              }

              var petData = petSnapshot.data!.data() as Map<String, dynamic>;

              // Handle missing pet and owner fields gracefully
              String petName = petData['name'] ?? 'No Pet Name';
              String ownerName = petData['ownerName'] ?? 'No Owner Name';

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Type: $type'),
                    Text('Date: $date'),
                    Text('Pet ID: $petId'),
                    Text('Pet Name: $petName'),
                    Text('Owner Name: $ownerName'),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        if (petId != 'No Pet ID') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MedicalRecordScreen(
                                petId: petId,
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('No Pet ID available')),
                          );
                        }
                      },
                      child: Text('View Medical Records'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
