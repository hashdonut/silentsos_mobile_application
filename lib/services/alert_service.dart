import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';

class AlertService {
  // 👇 1️⃣ Register FCM + location
  Future<void> registerDeviceToken({required bool isNGO}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) {
      print("❌ Failed to get FCM token");
      return;
    }

    LocationPermission permission = await Geolocator.requestPermission();
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final docRef = FirebaseFirestore.instance
        .collection(isNGO ? 'ngos' : 'volunteers')
        .doc(user.uid);

    await docRef.set({
      'uid': user.uid,
      'fcmToken': token,
      'isAvailable': true,
      'location': GeoPoint(position.latitude, position.longitude),
      'lastUpdated': Timestamp.now(),
    });

    print("✅ Device token and location registered!");
  }

  // 👇 2️⃣ Show alert snackbars (use anywhere in UI)
  static void showAlert(BuildContext context, String message, {bool isError = false}) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.redAccent : Colors.green,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // 👇 3️⃣ Send an SOS Alert (placeholder logic)
  Future<void> sendSOSAlert({required String crisisType}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final alert = {
      'uid': user.uid,
      'crisisType': crisisType,
      'timestamp': Timestamp.now(),
      // We'll add more (location, etc.) later
    };

    await FirebaseFirestore.instance.collection('alerts').add(alert);
    print('🚨 SOS Alert Sent: $crisisType');
  }
}
