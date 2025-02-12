import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BillingScreen extends StatefulWidget {
  final String appointmentId;
  final String vetId;

  BillingScreen({required this.appointmentId, required this.vetId});

  @override
  _BillingScreenState createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  String? _billStatus;
  double? _amount;
  double? _price;

  @override
  void initState() {
    super.initState();
    _fetchBillingDetails();
  }

  Future<void> _fetchBillingDetails() async {
    try {
      QuerySnapshot query = await _firestore
          .collection('billings')
          .where('appointmentId', isEqualTo: widget.appointmentId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        var doc = query.docs.first;
        setState(() {
          _billStatus = doc['billStatus'];
          _amount = doc['amount'];
          _price = doc['price'];
        });
      } else {
        setState(() {
          _billStatus = "unpaid";
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error fetching billing details: $e'),
      ));
    }
  }

  Future<void> _saveBillingDetails() async {
    try {
      double amount = double.parse(_amountController.text);
      double price = double.parse(_priceController.text);

      // Save billing details to Firestore
      DocumentReference docRef = _firestore.collection('billings').doc();
      await docRef.set({
        'billingId': docRef.id,
        'appointmentId': widget.appointmentId,
        'vetId': widget.vetId,
        'amount': amount,
        'price': price,
        'billStatus': "unpaid",  // Initially, the bill status is unpaid
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Billing details saved successfully'),
      ));

      // Create notification for the pet owner
      await _sendNotificationToPetOwner(price);

      // If the billing details were updated, fetch them again
      _fetchBillingDetails();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error saving billing details: $e'),
      ));
    }
  }

  Future<void> _sendNotificationToPetOwner(double price) async {
    try {
      // Assume that you have the pet owner's userId available
      // Replace with the correct method to fetch the pet owner's userId
      String petOwnerUserId = 'petOwnerUserId';  // Replace with actual userId

      // Create a notification document in Firestore
      DocumentReference notificationRef = _firestore.collection('notifications').doc();
      await notificationRef.set({
        'userId': petOwnerUserId,
        'title': 'Price Set for Appointment',
        'body': 'The price for your appointment has been set to \$${price.toStringAsFixed(2)}.',
        'type': 'price_set',
        'status': 'unread',  // Mark as unread initially
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Optionally, notify the veterinarian and/or admin if needed
      await _sendNotificationToVet(price);
    } catch (e) {
      print('Error sending notification to pet owner: $e');
    }
  }

  Future<void> _sendNotificationToVet(double price) async {
    try {
      // Assume that you have the vet's userId available
      // Replace with the correct method to fetch the vet's userId
      String vetUserId = widget.vetId;  // Assuming vetId is passed to the screen

      // Create a notification document in Firestore
      DocumentReference notificationRef = _firestore.collection('notifications').doc();
      await notificationRef.set({
        'userId': vetUserId,
        'title': 'New Appointment Price Set',
        'body': 'A new price of \$${price.toStringAsFixed(2)} has been set for an appointment.',
        'type': 'price_set',
        'status': 'unread',  // Mark as unread initially
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error sending notification to vet: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Billing Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _billStatus == null
            ? Center(child: CircularProgressIndicator())
            : _billStatus == "paid"
            ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Bill Status: $_billStatus",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text("Amount Paid: $_amount",
                style: TextStyle(fontSize: 16)),
            Text("Price: $_price",
                style: TextStyle(fontSize: 16)),
          ],
        )
            : Column(
          children: [
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: InputDecoration(
                labelText: 'Price',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveBillingDetails,
              child: Text('Save Billing Details'),
            ),
          ],
        ),
      ),
    );
  }
}
