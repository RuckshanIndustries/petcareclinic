import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _specialtyController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _role = "Pet Owner"; // Default role
  String? _profileImageUrl;
  String? _petImageUrl;
  File? _profileImage;
  File? _petImage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    var userQuery = await _firestore
        .collection('users')
        .where('email', isEqualTo: _auth.currentUser!.email)
        .limit(1)
        .get();

    if (userQuery.docs.isNotEmpty) {
      var userDoc = userQuery.docs.first;
      setState(() {
        _nameController.text = userDoc['name'];
        _emailController.text = userDoc['email'];
        _role = userDoc['role'] ?? 'Pet Owner'; // Default to 'Pet Owner' if role is not set

        // Log the role for debugging
        print('Fetched Role: $_role'); // Add this for debugging

        // Ensure _role is a valid value
        if (!['Pet Owner', 'Veterinarian', 'Admin'].contains(_role)) {
          _role = 'Null'; // Default value if an invalid role is found
        }

        _profileImageUrl = userDoc['profileImage'] ?? "";
        _petImageUrl = userDoc['petImage'] ?? "";
        if (_role == "Veterinarian") {
          _specialtyController.text = userDoc['specialty'] ?? "";
        }
      });
    }
  }

  Future<String> _uploadImage(File image, String path) async {
    Reference storageRef = FirebaseStorage.instance.ref().child(path);
    UploadTask uploadTask = storageRef.putFile(image);
    TaskSnapshot taskSnapshot = await uploadTask;
    return await taskSnapshot.ref.getDownloadURL();
  }

  Future<void> _pickImage(bool isProfileImage) async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (isProfileImage) {
          _profileImage = File(pickedFile.path);
        } else {
          _petImage = File(pickedFile.path);
        }
      });
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      String? profileImageUrl = _profileImage != null
          ? await _uploadImage(_profileImage!, 'profile_images/${_auth.currentUser!.uid}.jpg')
          : _profileImageUrl;

      String? petImageUrl = (_role == "Pet Owner" && _petImage != null)
          ? await _uploadImage(_petImage!, 'pet_images/${_auth.currentUser!.uid}.jpg')
          : _petImageUrl;

      Map<String, dynamic> updatedData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'profileImage': profileImageUrl,
      };

      if (_role == "Veterinarian") {
        updatedData['specialty'] = _specialtyController.text.trim();
      } else if (_role == "Pet Owner") {
        updatedData['petImage'] = petImageUrl;
      }

      await _firestore.collection('users').doc(_auth.currentUser!.uid).update(updatedData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully')),
      );
      _loadUserData(); // Refresh UI
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Profile Picture
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : (_profileImageUrl != null && _profileImageUrl!.isNotEmpty
                          ? NetworkImage(_profileImageUrl!) as ImageProvider
                          : AssetImage('assets/default_profile.png')),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: IconButton(
                        icon: Icon(Icons.camera_alt, color: Colors.blue),
                        onPressed: () => _pickImage(true),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
                validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
              ),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) => value!.isEmpty ? 'Please enter your email' : null,
              ),
              SizedBox(height: 20),
              // Role
              TextFormField(
                controller: TextEditingController(text: _role), // current logged-in role
                readOnly: true,  // makes it non-editable
                decoration: InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
              ),

              // Veterinarian Specialty Field
              if (_role == 'Veterinarian')
                TextFormField(
                  controller: _specialtyController,
                  decoration: InputDecoration(labelText: 'Specialty'),
                  validator: (value) => value!.isEmpty ? 'Please enter your specialty' : null,
                ),

              // Pet Image for Pet Owner
              if (_role == 'Pet Owner')
                Column(
                  children: [
                    SizedBox(height: 20),
                    Text('Pet Image'),
                    SizedBox(height: 10),
                    _petImage != null || (_petImageUrl != null && _petImageUrl!.isNotEmpty)
                        ? Image(
                      width: 100,
                      height: 100,
                      image: _petImage != null
                          ? FileImage(_petImage!)
                          : NetworkImage(_petImageUrl!) as ImageProvider,
                    )
                        : Icon(Icons.pets, size: 50, color: Colors.grey),
                    IconButton(
                      icon: Icon(Icons.camera_alt, color: Colors.blue),
                      onPressed: () => _pickImage(false),
                    ),
                  ],
                ),

              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateProfile,
                child: Text('Update Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
