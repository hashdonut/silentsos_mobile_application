import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'helper_edit_profile_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HelperProfileScreen extends StatefulWidget {
  const HelperProfileScreen({super.key});

  @override
  State<HelperProfileScreen> createState() => _HelperProfileScreenState();
}

class _HelperProfileScreenState extends State<HelperProfileScreen> {
  late Future<DocumentSnapshot<Map<String, dynamic>>> _userFuture;
  String? uid;

  @override
  void initState() {
    super.initState();
    uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _userFuture = FirebaseFirestore.instance.collection('users').doc(uid!).get();
    } else {
      _userFuture = Future.error('User not logged in');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(body: Center(child: Text("No user data found.")));
        }

        final data = snapshot.data!.data() ?? {};
        final name = data['name']?.toString().trim() ?? 'N/A';
        final email = data['email']?.toString().trim() ?? 'N/A';
        final contact = data['contact']?.toString().trim() ?? 'N/A';
        final role = data['role']?.toString().trim() ?? 'N/A';
        final createdAt = (data['createdAt'] is Timestamp)
            ? DateFormat('yMMMd').format((data['createdAt'] as Timestamp).toDate())
            : 'N/A';
        final ngoId = data['ngo']?.toString().trim();

        print('DEBUG >> Full user data: $data');
        print('DEBUG >> Extracted NGO ID: $ngoId');

        return Scaffold(
          backgroundColor: const Color(0xFFFFF0F5),
          appBar: AppBar(
            title: const Text("Your Helper Profile"),
            centerTitle: true,
            backgroundColor: const Color(0xFF6A5ACD),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF957DAD), Color(0xFFD291BC)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 42,
                        backgroundColor: Colors.white,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 36, color: Color(0xFF6A5ACD)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 600.ms),
                const SizedBox(height: 20),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("📋 Account Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        _buildRow("📧 Email", email),
                        const SizedBox(height: 12),
                        _buildRow("📱 Contact", contact),
                        const SizedBox(height: 12),
                        _buildRow("🛡️ Role", role),
                        const SizedBox(height: 12),
                        _buildRow("📅 Joined On", createdAt),
                      ],
                    ),
                  ),
                ).animate().slideY(begin: 0.3, duration: 500.ms),
                const SizedBox(height: 20),

                if (ngoId != null && ngoId.isNotEmpty)
                  FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    future: FirebaseFirestore.instance.collection('ngos').doc(ngoId).get(),
                    builder: (context, ngoSnapshot) {
                      if (ngoSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (ngoSnapshot.hasError) {
                        print('DEBUG >> NGO Snapshot Error: ${ngoSnapshot.error}');
                        return const Text("Unable to load NGO information (Error)");
                      }

                      if (!ngoSnapshot.hasData || !ngoSnapshot.data!.exists) {
                        print('DEBUG >> NGO document does not exist for ID: $ngoId');
                        return const Text("Unable to load NGO information (Not Found)");
                      }

                      final ngoData = ngoSnapshot.data!.data() ?? {};
                      final ngoName = ngoData['name']?.toString() ?? 'N/A';
                      final ngoAddress = ngoData['address']?.toString() ?? 'N/A';

                      print('DEBUG >> Fetched NGO data: $ngoData');

                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("🏢 Serving Under", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 16),
                              _buildRow("📌 NGO Name", ngoName, allowEllipsis: false),
                              const SizedBox(height: 12),
                              _buildRow("📍 Address", ngoAddress, allowEllipsis: false),
                            ],
                          ),
                        ),
                      ).animate().scale(duration: 400.ms);
                    },
                  )
                else
                  const Text("No NGO assigned to this user."),

                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HelperEditProfileScreen()),
                    );
                  },
                  icon: const Icon(Icons.edit, size: 20),
                  label: const Text('Edit Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purpleAccent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRow(String label, String value, {bool allowEllipsis = true}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$label: ",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
            overflow: allowEllipsis ? TextOverflow.ellipsis : TextOverflow.visible,
            softWrap: true,
          ),
        ),
      ],
    );
  }
}