import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PetProfileScreen extends StatefulWidget {
  final String? petId;

  PetProfileScreen({this.petId});

  @override
  _PetProfileScreenState createState() => _PetProfileScreenState();
}

class _PetProfileScreenState extends State<PetProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _ageController = TextEditingController();
  final _medicalHistoryController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    if (widget.petId != null) {
      _loadPetData();
    }
  }

  Future<void> _loadPetData() async {
    var petDoc = await _firestore.collection('pets').doc(widget.petId).get();
    if (petDoc.exists) {
      setState(() {
        _nameController.text = petDoc['name'];
        _breedController.text = petDoc['breed'];
        _ageController.text = petDoc['age'].toString();
        _medicalHistoryController.text = petDoc['medicalHistory'];
      });
    }
  }

  Future<void> _savePet() async {
    if (_formKey.currentState!.validate()) {
      var petData = {
        'name': _nameController.text.trim(),
        'breed': _breedController.text.trim(),
        'age': int.parse(_ageController.text.trim()),
        'medicalHistory': _medicalHistoryController.text.trim(),
        'ownerId': _auth.currentUser!.uid,
      };

      if (widget.petId == null) {
        await _firestore.collection('pets').add(petData);
      } else {
        await _firestore.collection('pets').doc(widget.petId).update(petData);
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.petId == null ? 'Add Pet' : 'Edit Pet'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
                validator: (value) =>
                value!.isEmpty ? 'Please enter the pet\'s name' : null,
              ),
              TextFormField(
                controller: _breedController,
                decoration: InputDecoration(labelText: 'Breed'),
                validator: (value) =>
                value!.isEmpty ? 'Please enter the pet\'s breed' : null,
              ),
              TextFormField(
                controller: _ageController,
                decoration: InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                value!.isEmpty ? 'Please enter the pet\'s age' : null,
              ),
              TextFormField(
                controller: _medicalHistoryController,
                decoration: InputDecoration(labelText: 'Medical History'),
                maxLines: 3,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _savePet,
                child: Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}