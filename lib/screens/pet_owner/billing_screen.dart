import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BillingScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Function to simulate payment
  Future<void> _handlePayment(String billId, BuildContext context) async {
    // Show the payment dialog to enter card details
    showDialog(
      context: context,
      builder: (context) {
        return PaymentDialog(billId: billId);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Billing'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('billings')
            .where('vetId', isEqualTo: 'zLBelOXt5CMLGW49ujileETMw0K2')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          var bills = snapshot.data!.docs;
          return ListView.builder(
            itemCount: bills.length,
            itemBuilder: (context, index) {
              var bill = bills[index];
              return ListTile(
                title: Text('Amount: \$${bill['amount']}'),
                subtitle: Text('Status: ${bill['billStatus']}'),
                trailing: bill['billStatus'] == 'paid'
                    ? Icon(Icons.check_circle, color: Colors.green)
                    : IconButton(
                  icon: Icon(Icons.payment),
                  onPressed: () => _handlePayment(bill.id, context),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class PaymentDialog extends StatefulWidget {
  final String billId;

  PaymentDialog({required this.billId});

  @override
  _PaymentDialogState createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final _cardNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();

  // Function to handle payment processing
  Future<void> _processPayment(BuildContext context) async {
    try {
      // Simulate payment processing (replace with actual payment gateway integration)
      await Future.delayed(Duration(seconds: 2));

      // Update Firestore to mark the bill as 'paid'
      await FirebaseFirestore.instance.collection('billings').doc(widget.billId).update({
        'billStatus': 'paid',
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment successful!')));

      // Send notifications
      await _sendNotificationToPetOwner();
      await _sendNotificationToVet();
      await _sendNotificationToAdmin();

      // Close the dialog
      Navigator.of(context).pop();
    } catch (e) {
      // Show error message if payment fails
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment failed. Please try again.')));
    }
  }

// Send notification to the pet owner
  Future<void> _sendNotificationToPetOwner() async {
    try {
      // Ensure the user is authenticated and get the pet owner's user ID
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String petOwnerUserId = user.uid;

        DocumentReference notificationRef = FirebaseFirestore.instance.collection('notifications').doc();
        await notificationRef.set({
          'userId': petOwnerUserId,
          'title': 'Payment Successful',
          'body': 'Your payment for the appointment has been successfully processed.',
          'type': 'payment_success',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error sending notification to pet owner: $e');
    }
  }

// Send notification to the vet (dynamically fetch vet's userId)
  Future<void> _sendNotificationToVet() async {
    try {
      // Query Firestore to fetch the vet's user ID based on the billId (or relevant information)
      DocumentSnapshot appointmentDoc = await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.billId) // Ensure this document ID corresponds to the billId or another identifier
          .get();

      if (appointmentDoc.exists) {
        // Assuming the vetUserId is stored in the 'vetUserId' field
        String vetUserId = appointmentDoc['vetId'];

        DocumentReference notificationRef = FirebaseFirestore.instance.collection('notifications').doc();
        await notificationRef.set({
          'userId': vetUserId,
          'title': 'Payment Received',
          'body': 'The pet owner has successfully paid for the appointment.',
          'type': 'payment_received',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error sending notification to vet: $e');
    }
  }

// Send notification to the admin (dynamically fetch admin's userId)
  Future<void> _sendNotificationToAdmin() async {
    try {
      // Query Firestore to fetch the admin's user ID based on the billId (or relevant information)
      DocumentSnapshot appointmentDoc = await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.billId) // Ensure this document ID corresponds to the billId or another identifier
          .get();

      if (appointmentDoc.exists) {
        // Assuming the adminUserId is stored in the 'adminUserId' field
        String adminUserId = appointmentDoc['adminUserId'];

        DocumentReference notificationRef = FirebaseFirestore.instance.collection('notifications').doc();
        await notificationRef.set({
          'userId': adminUserId,
          'title': 'Payment Received for Appointment',
          'body': 'A pet owner has successfully paid for an appointment.',
          'type': 'payment_received',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error sending notification to admin: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Enter Card Details'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _cardNumberController,
            decoration: InputDecoration(labelText: 'Card Number'),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: _expiryDateController,
            decoration: InputDecoration(labelText: 'Expiry Date (MM/YY)'),
            keyboardType: TextInputType.datetime,
          ),
          TextField(
            controller: _cvvController,
            decoration: InputDecoration(labelText: 'CVV'),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            // Close the dialog without processing payment
            Navigator.of(context).pop();
          },
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => _processPayment(context),
          child: Text('Pay Now'),
        ),
      ],
    );
  }
}
