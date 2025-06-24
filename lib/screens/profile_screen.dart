import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'edit_profile_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
        // log
        print(data);
        final name = data['name']?.toString().trim() ?? 'N/A';
        final email = data['email']?.toString().trim() ?? 'N/A';
        final contact = data['contact']?.toString().trim() ?? 'N/A';
        final role = data['role']?.toString().trim() ?? 'N/A';
        final createdAt = (data['createdAt'] is Timestamp)
            ? DateFormat('yMMMd').format((data['createdAt'] as Timestamp).toDate())
            : 'N/A';

        return Scaffold(
          backgroundColor: const Color(0xFFFFF0F5),
          appBar: AppBar(
            title: const Text("Your Profile"),
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
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("📊 SOS Stats", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        FutureBuilder<QuerySnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('sos_alerts')
                              .where('userId', isEqualTo: uid)
                              .get(),
                          builder: (context, alertSnapshot) {
                            if (alertSnapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            final alerts = alertSnapshot.data?.docs ?? [];
                            final resolved = alerts.where((doc) => doc['status'] == 'resolved').length;
                            final lastAlert = alerts.isNotEmpty
                                ? alerts
                                .map((doc) => doc['timestamp'] as Timestamp)
                                .reduce((a, b) => a.toDate().isAfter(b.toDate()) ? a : b)
                                : null;

                            return Column(
                              children: [
                                _buildRow("🚨 Total SOS Alerts", alerts.length.toString()),
                                const SizedBox(height: 8),
                                _buildRow("✅ Resolved Alerts", resolved.toString()),
                                const SizedBox(height: 8),
                                _buildRow("🕓 Last Alert", lastAlert != null ? timeago.format(lastAlert.toDate()) : "N/A"),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ).animate().scale(duration: 400.ms),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
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

  Widget _buildRow(String label, String value) {
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
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
