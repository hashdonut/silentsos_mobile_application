import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Screens
import 'home_screen.dart';
import 'login_screen.dart';
import 'verify_email_screen.dart';
import 'enterpinscreen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _loading = true;
  Widget? _targetScreen;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        _targetScreen = const LoginScreen();
        _loading = false;
      });
      return;
    }

    // if (!user.emailVerified) {
    //   setState(() {
    //     _targetScreen = const VerifyEmailScreen();
    //     _loading = false;
    //   });
    //   return;
    // }

    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final doc = await docRef.get();

    // Create user record if missing
    if (!doc.exists) {
      await docRef.set({
        'email': user.email,
        'name': 'User',
        'contact': 'Not Provided',
        'role': 'user',
        'createdAt': Timestamp.now(),
        'pin': '', // Initially empty
      });
    }

    // Fetch updated data
    final userData = (await docRef.get()).data();
    final pin = userData?['pin'] ?? '';

    if (pin == null || pin.toString().isEmpty) {
      setState(() {
        _targetScreen = const EnterPinScreen();
        _loading = false;
      });
    } else {
      setState(() {
        _targetScreen = const HomeScreen();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Scaffold(body: Center(child: CircularProgressIndicator()))
        : _targetScreen!;
  }
}
