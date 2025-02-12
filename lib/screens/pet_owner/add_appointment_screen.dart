import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'billing_screen.dart';

class AddAppointmentScreen extends StatefulWidget {
  @override
  _AddAppointmentScreenState createState() => _AddAppointmentScreenState();
}

class _AddAppointmentScreenState extends State<AddAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _typeController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedVetId = 'no_vet'; // Default to OPD Doctor
  String? _selectedPetId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _scheduleAppointment() async {
    if (_formKey.currentState!.validate() &&
        _selectedDate != null &&
        _selectedVetId != null &&
        _selectedPetId != null) {
      try {
        await _firestore.collection('appointments').add({
          'type': _typeController.text.trim(),
          'date': Timestamp.fromDate(_selectedDate!),
          'vetId': _selectedVetId,
          'ownerId': _auth.currentUser!.uid,
          'petId': _selectedPetId,
          'status': 'scheduled',
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Appointment Scheduled Successfully')),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BillingScreen()),
        );
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scheduling appointment: $error')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please complete all fields')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('New Appointment')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _typeController,
                decoration: InputDecoration(labelText: 'Appointment Type'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              ListTile(
                title: Text(_selectedDate == null
                    ? 'Select Date'
                    : 'Date: ${_selectedDate!.toLocal().toString().split(' ')[0]}'),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() => _selectedDate = date);
                  }
                },
              ),
              StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('users')
                    .where('role', isEqualTo: 'Veterinarian')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return CircularProgressIndicator();

                  var vetDocs = snapshot.data!.docs;

                  List<DropdownMenuItem<String>> vetItems = [
                    DropdownMenuItem(
                      value: 'no_vet',
                      child: Text('OPD Doctor'),
                    ),
                  ];

                  vetItems.addAll(vetDocs.map((vet) {
                    return DropdownMenuItem<String>(
                      value: vet.id,
                      child: Text(vet['name']),
                    );
                  }).toList());

                  return DropdownButton<String>(
                    hint: Text('Select Veterinarian'),
                    value: _selectedVetId,
                    items: vetItems,
                    onChanged: (value) => setState(() => _selectedVetId = value),
                  );
                },
              ),
              SizedBox(height: 16),
              StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('pets')
                    .where('ownerId', isEqualTo: _auth.currentUser!.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return CircularProgressIndicator();

                  var petDocs = snapshot.data!.docs;

                  List<DropdownMenuItem<String>> petItems = petDocs.map((pet) {
                    return DropdownMenuItem<String>(
                      value: pet.id,
                      child: Text(pet['name']),
                    );
                  }).toList();

                  return DropdownButton<String>(
                    hint: Text('Select Pet'),
                    value: _selectedPetId,
                    items: petItems,
                    onChanged: (value) => setState(() => _selectedPetId = value),
                  );
                },
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _scheduleAppointment,
                child: Text('Schedule Appointment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
