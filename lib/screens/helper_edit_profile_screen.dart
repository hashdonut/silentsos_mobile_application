import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HelperEditProfileScreen extends StatefulWidget {
  const HelperEditProfileScreen({super.key});

  @override
  State<HelperEditProfileScreen> createState() => _HelperEditProfileScreenState();
}

class _HelperEditProfileScreenState extends State<HelperEditProfileScreen> {
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? '';
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();
      if (data != null) {
        _nameController.text = data['name'] ?? '';
        _contactController.text = data['contact'] ?? '';
      }
    }
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    final name = _nameController.text.trim();
    final contact = _contactController.text.trim();
    final newEmail = _emailController.text.trim();
    final newPassword = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty || contact.isEmpty || newEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Name, contact, and email are required')),
      );
      return;
    }

    if (newPassword.isNotEmpty && newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Passwords do not match')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 🔄 Update email if changed
      if (user != null && newEmail != user.email) {
        await user.updateEmail(newEmail);
        await user.sendEmailVerification();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('📩 Email updated! Verification sent.')),
        );
      }

      // 🔄 Update password if entered
      if (newPassword.isNotEmpty) {
        await user?.updatePassword(newPassword);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🔐 Password updated!')),
        );
      }

      // 🔄 Update Firestore name & contact
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'name': name,
          'contact': contact,
          'email': newEmail,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Profile updated successfully')),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String message = e.message ?? 'Authentication error';
      if (e.code == 'requires-recent-login') {
        message = '⚠️ Please log in again to update email or password.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: const Color(0xFF6A5ACD),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contactController,
              decoration: const InputDecoration(labelText: 'Contact Number'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email Address'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'New Password (leave blank if unchanged)'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(labelText: 'Confirm New Password'),
              obscureText: true,
            ),
            const SizedBox(height: 30),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
