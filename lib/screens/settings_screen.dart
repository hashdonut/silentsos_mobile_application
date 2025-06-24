import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'dart:io' show Platform;
import '../routes/route_names.dart';


class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushNamedAndRemoveUntil(RouteNames.login, (route) => false);
  }

  Future<void> _openAppSettings(BuildContext context) async {
    if (Platform.isAndroid) {
      final intent = AndroidIntent(
        action: 'android.settings.APP_NOTIFICATION_SETTINGS',
        arguments: <String, dynamic>{
          'android.provider.extra.APP_PACKAGE': 'com.example.silentsos', // Replace with your actual package
        },
      );
      try {
        await intent.launch();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Could not open settings: $e")),
        );
      }
    } else if (Platform.isIOS) {
      final uri = Uri.parse('app-settings:');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠️ Opening settings isn't supported on iOS.")),
        );
      }
    }
  }

  void _launchPrivacyPolicy(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (_, controller) => Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: ListView(
              controller: controller,
              children: const [
                Text(
                  "Privacy Policy",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6A5ACD),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  '''
SilentSOS+ respects your privacy. We do not collect any unnecessary personal information. Any data we gather is used solely for emergency alerts and app functionality.

1. **Data Collection**: Your name, contact number, email, and location may be used for alerting nearby volunteers or responders during emergencies.

2. **Data Sharing**: We *never* sell or share your data with third parties for marketing. Only authorized medical personnel or trusted NGOs may view alerts during active emergencies.

3. **Security**: All data is secured using Firebase Authentication and Firestore rules.

4. **User Control**: You can delete your account and associated data anytime from the settings.

By using this app, you consent to this privacy policy. For more, contact: support@silentsos.com
                ''',
                  style: TextStyle(fontSize: 16, height: 1.5),
                ),
                SizedBox(height: 12),
                Text(
                  "Last updated: June 2025",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _launchEmail() async {
    final Uri emailUri = Uri.parse(
        'mailto:support@silentsos.com?subject=SilentSOS%20App%20Support&body=Hi%20Support%20Team,');

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("❌ Could not launch email app.");
    }
  }

  void _deleteAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You're not logged in.")),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text("Are you sure you want to delete your account permanently? This cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final uid = user.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      await user.delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account deleted successfully.")),
      );

      Navigator.of(context).pushNamedAndRemoveUntil(RouteNames.login, (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting account: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FF),
      appBar: AppBar(
        title: const Text("Settings"),
        centerTitle: true,
        backgroundColor: const Color(0xFF6A5ACD),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          const Text("App Preferences", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          // ListTile(
          //   leading: const Icon(Icons.notifications_active, color: Colors.deepPurple),
          //   title: const Text("Notification Settings"),
          //   onTap: () => _openAppSettings(context),
          // ),

          ListTile(
            leading: const Icon(Icons.lock, color: Colors.deepPurple),
            title: const Text("Change PIN"),
            onTap: () => Navigator.of(context).pushNamed(RouteNames.changePin),
          ),

          const Divider(height: 40),

          const Text("Support", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          ListTile(
            leading: const Icon(Icons.help_outline, color: Colors.teal),
            title: const Text("FAQ"),
            onTap: () => Navigator.of(context).pushNamed(RouteNames.faq),
          ),

          ListTile(
            leading: const Icon(Icons.privacy_tip, color: Colors.teal),
            title: const Text("Privacy Policy"),
            onTap: () => _launchPrivacyPolicy(context),
          ),

          // ListTile(
          //   leading: const Icon(Icons.email, color: Colors.teal),
          //   title: const Text("Contact Support"),
          //   onTap: () => _launchEmail(),
          // ),
          // ListTile(
          //   leading: const Icon(Icons.email, color: Colors.teal),
          //   title: const Text("Contact Support"),
          //   onTap: () {
          //     // Using the default HTML anchor mailto trick
          //     final Uri emailUri = Uri(
          //       scheme: 'mailto',
          //       path: 'support@silentsos.com',
          //       queryParameters: {
          //         'subject': 'SilentSOS App Support',
          //         'body': 'Hi Support Team,'
          //       },
          //     );
          //     // Trigger launch via HTML element
          //     launchMailtoLink(emailUri.toString());
          //   },
          // ),

          const Divider(height: 40),

          const Text("Account", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text("Logout"),
            onTap: () => _logout(context),
          ),

          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text("Delete Account"),
            onTap: () => _deleteAccount(context),
          ),
        ],
      ),
    );
  }
}
