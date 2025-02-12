import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageVetsScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Veterinarians'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('users')
            .where('role', isEqualTo: 'Veterinarian') // Filtering users by role = 'vet'
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var vets = snapshot.data!.docs;
          return ListView.builder(
            itemCount: vets.length,
            itemBuilder: (context, index) {
              var vet = vets[index];
              return ListTile(
                title: Text(vet['name']),
                subtitle: Text(vet['specialty'] ?? 'No Specialty'), // Assuming 'specialty' field is present
                onTap: () {
                  _showUpdateVetDialog(context, vet);
                },
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () async {
                    await _firestore
                        .collection('users')
                        .doc(vet.id)
                        .delete();
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddVetDialog(context);
        },
        child: Icon(Icons.add),
      ),
    );
  }

  void _showAddVetDialog(BuildContext context) {
    final _nameController = TextEditingController();
    final _specialtyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Veterinarian'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
              ),
              TextFormField(
                controller: _specialtyController,
                decoration: InputDecoration(labelText: 'Specialty'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await _firestore.collection('users').add({
                  'name': _nameController.text.trim(),
                  'specialty': _specialtyController.text.trim(),
                  'role': 'Veterinarian', // Set the role as 'vet'
                });
                Navigator.pop(context);
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showUpdateVetDialog(BuildContext context, DocumentSnapshot vet) {
    final _nameController = TextEditingController(text: vet['name']);
    final _specialtyController = TextEditingController(text: vet['specialty'] ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Update Veterinarian'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
              ),
              TextFormField(
                controller: _specialtyController,
                decoration: InputDecoration(labelText: 'Specialty'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await _firestore.collection('users').doc(vet.id).update({
                  'name': _nameController.text.trim(),
                  'specialty': _specialtyController.text.trim(),
                });
                Navigator.pop(context);
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }
}
