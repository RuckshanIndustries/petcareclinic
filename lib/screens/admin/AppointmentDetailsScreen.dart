import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pet_care_clinic_new/screens/admin/billing_screen_admin.dart';


class AppointmentDetailsScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Function to fetch vet name based on vetId
  Future<String> _getVetName(String vetId) async {
    try {
      DocumentSnapshot vetDoc = await _firestore.collection('users').doc(vetId).get();
      if (vetDoc.exists) {
        return vetDoc['name'] ?? 'Unknown Vet'; // Return the vet's name or 'Unknown Vet' if not found
      } else {
        return 'Vet not found';
      }
    } catch (e) {
      return 'Error fetching vet name';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Appointment Details'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('appointments').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var appointments = snapshot.data!.docs;
          return ListView.builder(
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              var appointment = appointments[index];

              // Convert Firestore Timestamp to DateTime
              Timestamp timestamp = appointment['date'];
              DateTime date = timestamp.toDate();

              // Format the DateTime as a string
              String formattedDate = "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}";

              return FutureBuilder<String>(
                future: _getVetName(appointment['vetId']), // Fetch vet name based on vetId
                builder: (context, vetSnapshot) {
                  if (!vetSnapshot.hasData) {
                    return ListTile(
                      title: Text('Loading vet name...'),
                      subtitle: Text('Date: $formattedDate'),
                      trailing: Text('Status: ${appointment['status']}'),
                    );
                  }

                  String vetName = vetSnapshot.data!;

                  return ListTile(
                    title: Text('Appointment with: $vetName'), // Display vet's name
                    subtitle: Text('Date: $formattedDate'),
                    trailing: Text('Status: ${appointment['status']}'),
                    onTap: () {
                      // Navigate to the BillingScreen and pass appointmentId and vetId
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BillingScreen(
                            appointmentId: appointment.id,
                            vetId: appointment['vetId'],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
