import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MedicalRecordScreen extends StatefulWidget {
  final String petId;

  MedicalRecordScreen({required this.petId});

  @override
  _MedicalRecordScreenState createState() => _MedicalRecordScreenState();
}

class _MedicalRecordScreenState extends State<MedicalRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _diagnosisController = TextEditingController();
  final _treatmentController = TextEditingController();
  final _prescriptionController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Medical Records'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('medicalRecords')
                  .where('petId', isEqualTo: widget.petId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                var records = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    var record = records[index];
                    return ListTile(
                      title: Text('Diagnosis: ${record['diagnosis']}'),
                      subtitle: Text('Treatment: ${record['treatment']}'),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _diagnosisController,
                    decoration: InputDecoration(labelText: 'Diagnosis'),
                    validator: (value) =>
                    value!.isEmpty ? 'Please enter a diagnosis' : null,
                  ),
                  TextFormField(
                    controller: _treatmentController,
                    decoration: InputDecoration(labelText: 'Treatment'),
                    validator: (value) =>
                    value!.isEmpty ? 'Please enter a treatment' : null,
                  ),
                  TextFormField(
                    controller: _prescriptionController,
                    decoration: InputDecoration(labelText: 'Prescription'),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _addMedicalRecord,
                    child: Text('Add Record'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addMedicalRecord() async {
    if (_formKey.currentState!.validate()) {
      await _firestore.collection('medicalRecords').add({
        'petId': widget.petId,
        'diagnosis': _diagnosisController.text.trim(),
        'treatment': _treatmentController.text.trim(),
        'prescription': _prescriptionController.text.trim(),
        'date': DateTime.now(),
      });

      // Clear the form
      _diagnosisController.clear();
      _treatmentController.clear();
      _prescriptionController.clear();
    }
  }
}