import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'enterpinscreen.dart';

class ForgotPinScreen extends StatefulWidget {
  const ForgotPinScreen({super.key});

  @override
  State<ForgotPinScreen> createState() => _ForgotPinScreenState();
}

class _ForgotPinScreenState extends State<ForgotPinScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _newPinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();

  bool _isLoading = false;
  String? _errorText;
  String? _successText;

  Future<void> _resetPin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
      _successText = null;
    });

    try {
      final newPin = _newPinController.text.trim();
      final confirmPin = _confirmPinController.text.trim();

      if (newPin != confirmPin) {
        throw Exception("PINs do not match.");
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("You must be logged in.");

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'pin': newPin,
      });

      if (!mounted) return;

      setState(() {
        _successText = "✅ Your PIN has been reset!";
      });

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const EnterPinScreen()),
        );
      }
    } catch (e) {
      setState(() => _errorText = e.toString().replaceFirst("Exception: ", ""));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FF),
      appBar: AppBar(
        title: const Text("Reset PIN"),
        backgroundColor: const Color(0xFF6A5ACD),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text(
                "Set a new 4-digit PIN to protect your app.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              _textField(
                controller: _newPinController,
                label: "New PIN",
                icon: Icons.lock_outline,
                obscureText: true,
                maxLength: 4,
                keyboardType: TextInputType.number,
                validator: (val) =>
                val == null || val.length != 4 ? 'Enter a 4-digit PIN' : null,
              ),
              const SizedBox(height: 20),
              _textField(
                controller: _confirmPinController,
                label: "Confirm PIN",
                icon: Icons.lock,
                obscureText: true,
                maxLength: 4,
                keyboardType: TextInputType.number,
                validator: (val) => val != _newPinController.text ? 'PINs do not match' : null,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _resetPin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                      : const Text("Reset PIN", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 16),
                Text(_errorText!, style: const TextStyle(color: Colors.red)),
              ],
              if (_successText != null) ...[
                const SizedBox(height: 16),
                Text(_successText!, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    int? maxLength,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      maxLength: maxLength,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
