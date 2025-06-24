import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';

Future<String?> getDeviceFCMToken() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  return await messaging.getToken();
}

Future<Position> getCurrentLocation() async {
  LocationPermission permission = await Geolocator.requestPermission();
  return await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );
}
