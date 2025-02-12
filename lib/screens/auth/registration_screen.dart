import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../app_config.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _specialtyController = TextEditingController();
  String _role = 'Pet Owner';

  File? _profileImage;
  File? _petImage;

  Future<void> _pickImage(bool isPetImage) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        if (isPetImage) {
          _petImage = File(pickedFile.path);
        } else {
          _profileImage = File(pickedFile.path);
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No image selected')),
      );
    }
  }



  Future<String> _uploadImage(File imageFile, String fileName) async {
    try {
      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child(fileName);
      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception("Image upload failed: $e");
    }
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate() && _profileImage != null) {
      try {
        UserCredential userCredential =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Upload profile picture
        String profileImageUrl =
        await _uploadImage(_profileImage!, "${userCredential.user!.uid}.jpg");

        // Prepare user data
        Map<String, dynamic> userData = {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'role': _role,
          'profileImageUrl': profileImageUrl, // Store profile picture URL
        };

        // If Veterinarian, add specialty
        if (_role == 'Veterinarian') {
          userData['specialty'] = _specialtyController.text.trim();
        }

        // If Pet Owner, upload pet image
        if (_role == 'Pet Owner' && _petImage != null) {
          String petImageUrl =
          await _uploadImage(_petImage!, "${userCredential.user!.uid}_pet.jpg");
          userData['petImageUrl'] = petImageUrl; // Store pet picture URL
        }

        // Save to Firestore
        await FirebaseFirestore.instance
            .collection(AppConfig.usersCollection)
            .doc(userCredential.user!.uid)
            .set(userData);

        Navigator.pushReplacementNamed(context, '/dashboard');
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Registration failed')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select a profile picture")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                  validator: (value) =>
                  value!.isEmpty ? 'Please enter your name' : null,
                ),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                  validator: (value) =>
                  value!.isEmpty ? 'Please enter your email' : null,
                ),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (value) =>
                  value!.isEmpty ? 'Please enter your password' : null,
                ),
                DropdownButtonFormField(
                  value: _role,
                  items: ['Pet Owner', 'Veterinarian', 'Admin']
                      .map((role) => DropdownMenuItem(
                    value: role,
                    child: Text(role),
                  ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _role = value.toString();
                    });
                  },
                ),
                if (_role == 'Veterinarian') ...[
                  TextFormField(
                    controller: _specialtyController,
                    decoration: InputDecoration(labelText: 'Specialty'),
                    validator: (value) =>
                    value!.isEmpty ? 'Please enter your specialty' : null,
                  ),
                ],
                SizedBox(height: 10),
                Text("Select Profile Picture"),
                GestureDetector(
                  onTap: () => _pickImage(false),
                  child: _profileImage != null
                      ? CircleAvatar(
                    radius: 50,
                    backgroundImage: FileImage(_profileImage!),
                  )
                      : CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[300],
                    child: Icon(Icons.camera_alt, size: 40),
                  ),
                ),
                if (_role == 'Pet Owner') ...[
                  SizedBox(height: 10),
                  Text("Select Pet Image"),
                  GestureDetector(
                    onTap: () => _pickImage(true),
                    child: _petImage != null
                        ? CircleAvatar(
                      radius: 50,
                      backgroundImage: FileImage(_petImage!),
                    )
                        : CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[300],
                      child: Icon(Icons.camera_alt, size: 40),
                    ),
                  ),
                ],
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _register,
                  child: Text('Register'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
