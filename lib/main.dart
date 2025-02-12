import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pet_care_clinic_new/screens/admin/admin_dashboard_screen.dart';
import 'screens/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // await FirebaseAppCheck.instance.activate(
  //   androidProvider: AndroidProvider.safetyNet,
  //   appleProvider: AppleProvider.deviceCheck,
  //   webProvider: ReCaptchaV3Provider('your-web-key'),
  // );

  String? debugToken = await FirebaseAppCheck.instance.getToken(true);
  print('Debug token: $debugToken');
  // Get the current user
  User? user = FirebaseAuth.instance.currentUser;

  // If a user is already logged in, sign them out
  if (user != null) {
    await FirebaseAuth.instance.signOut();
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pet Care Clinic',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AdminDashboardScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
