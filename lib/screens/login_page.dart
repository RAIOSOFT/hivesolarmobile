import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'admin_dash.dart';
import 'user_dash.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  bool showPassword = false;

  Future<void> login() async {
    try {
      setState(() {
        loading = true;
      });

      // 🔹 1. Login user
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final uid = credential.user!.uid;

      // 🔹 2. Fetch user document
      final doc = await FirebaseFirestore.instance
          .collection('users-list')
          .doc(uid)
          .get();

      if (!doc.exists) {
        await FirebaseAuth.instance.signOut();
        throw Exception("User record not found in database");
      }

      final data = doc.data() as Map<String, dynamic>;
      final role = data['role'];

      if (!mounted) return;

      // 🔹 3. Navigate based on role
      if (role == "Admin") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDash()),
        );
      } else if (role == "User") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const UserDash()),
        );
      } else {
        await FirebaseAuth.instance.signOut();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Access denied. Unknown role."),
            backgroundColor: Color(0xFF1E3060),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message ?? "Login failed",
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF1E3060),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF1E3060),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B3E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 28),

              // Logo
              Image.asset('assets/images/logo1.png', height: 70),

              const SizedBox(height: 36),

              const Text(
                "Welcome back,",
                style: TextStyle(
                  color: Color(0xFF8FA3CC),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 4),

              const Text(
                "Sign in to continue",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 32),

              // Email Label
              const Text(
                "Email Address",
                style: TextStyle(
                  color: Color(0xFFE8C42A),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 8),

              // Email Field
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                cursorColor: const Color(0xFFE8C42A),
                decoration: InputDecoration(
                  hintText: "you@hivesolar.com",
                  hintStyle: const TextStyle(color: Color(0xFF4A6090)),
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: Color(0xFFE8C42A),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF162447),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Password Label
              const Text(
                "Password",
                style: TextStyle(
                  color: Color(0xFFE8C42A),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 8),

              // Password Field
              TextField(
                controller: passwordController,
                obscureText: !showPassword,
                style: const TextStyle(color: Colors.white),
                cursorColor: const Color(0xFFE8C42A),
                decoration: InputDecoration(
                  hintText: "Enter your password",
                  hintStyle: const TextStyle(color: Color(0xFF4A6090)),
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: Color(0xFFE8C42A),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      showPassword ? Icons.visibility_off : Icons.visibility,
                      color: const Color(0xFF4A6090),
                    ),
                    onPressed: () {
                      setState(() {
                        showPassword = !showPassword;
                      });
                    },
                  ),
                  filled: true,
                  fillColor: const Color(0xFF162447),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Sign In Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: loading ? null : login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8C42A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: loading
                      ? const CircularProgressIndicator(
                          color: Color(0xFF0D1B3E),
                        )
                      : const Text(
                          "Sign In",
                          style: TextStyle(
                            color: Color(0xFF0D1B3E),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const Spacer(),

              const Center(
                child: Text(
                  "ISO 9001 · 3000+ Customers",
                  style: TextStyle(color: Color(0xFF4A6090), fontSize: 11),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
