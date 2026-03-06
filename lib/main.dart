import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'screens/login_page.dart';
import 'screens/admin_dash.dart';
import 'screens/user_dash.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Firebase hasn't responded yet — show branded splash
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        // Not logged in → go to login
        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginPage();
        }

        // Logged in → check role and route
        return const RoleRouter();
      },
    );
  }
}

class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users-list')
          .doc(uid)
          .get(),
      builder: (context, snapshot) {
        // Still fetching from Firestore
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        // Doc missing or error → sign out cleanly
        if (!snapshot.hasData || !snapshot.data!.exists) {
          FirebaseAuth.instance.signOut();
          return const LoginPage();
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final role = data['role'];

        if (role == 'Admin') {
          return const AdminDash();
        } else if (role == 'User') {
          return const UserDash();
        } else {
          // Unknown role → sign out
          FirebaseAuth.instance.signOut();
          return const LoginPage();
        }
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0D1B3E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image(image: AssetImage('assets/images/logo1.png'), height: 80),
            SizedBox(height: 32),
            CircularProgressIndicator(
              color: Color(0xFFE8C42A),
              strokeWidth: 2.5,
            ),
            SizedBox(height: 16),
            Text(
              'Loading...',
              style: TextStyle(color: Color(0xFF8FA3CC), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
