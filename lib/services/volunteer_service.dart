import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> saveVolunteerData({
  required String uid,
  required String fcmToken,
  required double lat,
  required double lng,
  required bool isAvailable,
}) async {
  await FirebaseFirestore.instance.collection('volunteers').doc(uid).set({
    'uid': uid,
    'fcmToken': fcmToken,
    'isAvailable': isAvailable,
    'location': GeoPoint(lat, lng),
    'lastUpdated': Timestamp.now(),
  });
}
