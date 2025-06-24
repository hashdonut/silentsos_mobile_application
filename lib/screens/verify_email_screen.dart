import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isSending = false;
  bool _isChecking = false;
  String? _message;

  Future<void> _resendEmailVerification() async {
    setState(() {
      _isSending = true;
      _message = null;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        setState(() {
          _message = "Verification email sent again!";
        });
      }
    } catch (e) {
      setState(() {
        _message = "Failed to resend verification email. ${e.toString()}";
      });
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _checkVerificationStatus() async {
    setState(() {
      _isChecking = true;
      _message = null;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      await user?.reload();
      user = FirebaseAuth.instance.currentUser;

      if (user != null && user.emailVerified) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() {
          _message = "Email is not verified yet. Try again.";
        });
      }
    } catch (e) {
      setState(() {
        _message = "Error checking verification status.";
      });
    } finally {
      setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Verify Your Email"),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.email_outlined, size: 90, color: Colors.teal),
            const SizedBox(height: 30),
            const Text(
              "Almost there!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              "We sent a verification email to:\n${user?.email}",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            if (_message != null)
              Text(
                _message!,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isSending ? null : _resendEmailVerification,
              icon: const Icon(Icons.refresh),
              label: _isSending
                  ? const Text("Sending...")
                  : const Text("Resend Email"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isChecking ? null : _checkVerificationStatus,
              icon: const Icon(Icons.verified_user),
              label: _isChecking
                  ? const Text("Checking...")
                  : const Text("I've Verified My Email"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

