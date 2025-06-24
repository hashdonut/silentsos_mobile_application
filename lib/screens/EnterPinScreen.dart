import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'forgot_pin_screen.dart';

class EnterPinScreen extends StatefulWidget {
  const EnterPinScreen({super.key});

  @override
  State<EnterPinScreen> createState() => _EnterPinScreenState();
}

class _EnterPinScreenState extends State<EnterPinScreen> {
  final _pinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmNewPinController = TextEditingController();

  bool _isChecking = false;
  bool _isFirstTime = false;
  bool _loading = true;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _checkUserAndPinStatus();
  }

  Future<void> _checkUserAndPinStatus() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final storedPin = doc.data()?['pin'];

      setState(() {
        _isFirstTime = storedPin == null || storedPin.toString().isEmpty;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorText = "Error fetching PIN: $e";
        _loading = false;
      });
    }
  }

  Future<void> _setNewPin() async {
    final newPin = _newPinController.text.trim();
    final confirmPin = _confirmNewPinController.text.trim();

    if (newPin.length != 4 || confirmPin.length != 4 || newPin != confirmPin) {
      setState(() => _errorText = "PINs must match and be 4 digits");
      return;
    }

    setState(() {
      _isChecking = true;
      _errorText = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'pin': newPin});

      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } catch (e) {
      setState(() => _errorText = "Error setting PIN: $e");
    } finally {
      setState(() => _isChecking = false);
    }
  }

  Future<void> _verifyPin() async {
    final enteredPin = _pinController.text.trim();

    if (enteredPin.length != 4) {
      setState(() => _errorText = "Enter a valid 4-digit PIN");
      return;
    }

    setState(() {
      _isChecking = true;
      _errorText = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final storedPin = doc.data()?['pin'];

      if (enteredPin == storedPin) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      } else {
        setState(() => _errorText = "Incorrect PIN. Try again.");
      }
    } catch (e) {
      setState(() => _errorText = "Error: $e");
    } finally {
      setState(() => _isChecking = false);
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    _newPinController.dispose();
    _confirmNewPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      appBar: AppBar(
        title: Text(_isFirstTime ? "Set PIN" : "Enter PIN"),
        backgroundColor: const Color(0xFF6A5ACD),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(
              _isFirstTime ? Icons.lock_open : Icons.lock_outline,
              size: 64,
              color: Colors.deepPurple.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              _isFirstTime
                  ? "Set your 4-digit PIN to protect your app access."
                  : "Enter your 4-digit PIN to access the app.",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF4A148C)),
            ),
            const SizedBox(height: 32),
            if (_isFirstTime) ...[
              _pinField(controller: _newPinController, label: "New PIN"),
              const SizedBox(height: 16),
              _pinField(controller: _confirmNewPinController, label: "Confirm PIN"),
              const SizedBox(height: 24),
              _actionButton(label: "Save PIN", onPressed: _isChecking ? null : _setNewPin),
            ] else ...[
              _pinField(controller: _pinController, label: "Enter PIN"),
              const SizedBox(height: 24),
              _actionButton(label: "Unlock", onPressed: _isChecking ? null : _verifyPin),
              TextButton(
                onPressed: _isChecking
                    ? null
                    : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPinScreen())),
                child: const Text(
                  "Forgot PIN?",
                  style: TextStyle(color: Color(0xFF4A148C), fontWeight: FontWeight.w500),
                ),
              ),
            ],
            if (_errorText != null) ...[
              const SizedBox(height: 20),
              Text(_errorText!, style: const TextStyle(color: Colors.red)),
            ]
          ],
        ),
      ),
    );
  }

  Widget _pinField({required TextEditingController controller, required String label}) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      obscureText: true,
      maxLength: 4,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF4A148C)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: const Icon(Icons.lock, color: Colors.deepPurple),
        filled: true,
        fillColor: Colors.white,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
        ),
      ),
    );
  }

  Widget _actionButton({required String label, required VoidCallback? onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple.shade400,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 5,
        ),
        child: _isChecking
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        )
            : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
