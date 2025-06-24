import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  LatLng? _currentLatLng;
  final Set<Marker> _markers = {};
  StreamSubscription<Position>? _positionStream;
  String? userId;
  String? activeSosId;

  double? etaMinutes;
  double? progressPercent;
  LatLng? _assignedNGOLocation;

  static const double averageSpeedKmh = 40.0;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _initialize() async {
    await _getUserId();
    await _determineCurrentPosition();
    await _createInitialSOSAlert();
    _startLiveLocationTracking();
    _listenToSOSAlerts();
    _loadNGOMarkers();
  }

  Future<void> _getUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    userId = user?.uid;
  }

  Future<void> _determineCurrentPosition() async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      debugPrint("❌ Location permissions denied.");
      return;
    }

    final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
    final latLng = LatLng(pos.latitude, pos.longitude);

    if (_isDisposed || !mounted) return;
    setState(() {
      _currentLatLng = latLng;
      _addOrUpdateUserMarker(latLng);
    });

    final controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16));
  }

  Future<void> _createInitialSOSAlert() async {
    if (_currentLatLng == null || userId == null) return;

    final docRef = await FirebaseFirestore.instance.collection('sos_alerts').add({
      'userId': userId,
      'timestamp': Timestamp.now(),
      'location': {
        '_latitude': _currentLatLng!.latitude,
        '_longitude': _currentLatLng!.longitude,
      },
      'emergency': 'Live Tracking',
      'status': 'active',
    });

    activeSosId = docRef.id;
  }

  void _startLiveLocationTracking() {
    const settings = LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5);

    _positionStream = Geolocator.getPositionStream(locationSettings: settings).listen((pos) {
      final latLng = LatLng(pos.latitude, pos.longitude);
      _currentLatLng = latLng;
      _addOrUpdateUserMarker(latLng);

      if (activeSosId != null) {
        FirebaseFirestore.instance.collection('sos_alerts').doc(activeSosId).update({
          'timestamp': Timestamp.now(),
          'location': {
            '_latitude': pos.latitude,
            '_longitude': pos.longitude,
          },
        });
      }

      _updateETAandProgress();
      if (_isDisposed || !mounted) return;
      setState(() {});
    });
  }

  void _addOrUpdateUserMarker(LatLng pos) {
    _markers.removeWhere((m) => m.markerId.value == 'user');
    _markers.add(
      Marker(
        markerId: const MarkerId('user'),
        position: pos,
        infoWindow: const InfoWindow(title: 'You (Live Location)'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    );
    if (_isDisposed || !mounted) return;
    setState(() {});
  }

  void _listenToSOSAlerts() {
    FirebaseFirestore.instance
        .collection('sos_alerts')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .listen((snapshot) {
      final newMarkers = <Marker>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final loc = data['location'];
        if (loc == null) continue;

        final lat = loc['_latitude'];
        final lng = loc['_longitude'];
        if (lat == null || lng == null) continue;

        final emergency = data['emergency'] ?? 'Emergency';
        final id = data['userId'];

        if (id == userId) continue;

        newMarkers.add(
          Marker(
            markerId: MarkerId('sos_${doc.id}'),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(title: emergency),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );
      }

      if (_isDisposed || !mounted) return;
      setState(() {
        _markers.removeWhere((m) => m.markerId.value.startsWith('sos_'));
        _markers.addAll(newMarkers);
      });
    });
  }

  void _loadNGOMarkers() async {
    final ngoSnapshot = await FirebaseFirestore.instance.collection('ngos').get();
    double? shortestDistance;

    for (final doc in ngoSnapshot.docs) {
      final data = doc.data();
      final GeoPoint? loc = data['location'];
      if (loc == null) continue;

      final lat = loc.latitude;
      final lng = loc.longitude;
      final name = data['name'] ?? 'NGO Center';
      final ngoLatLng = LatLng(lat, lng);

      _markers.add(
        Marker(
          markerId: MarkerId('ngo_${doc.id}'),
          position: ngoLatLng,
          infoWindow: InfoWindow(title: 'NGO: $name'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );

      if (_currentLatLng != null) {
        final dist = _calculateDistance(_currentLatLng!, ngoLatLng);
        if (shortestDistance == null || dist < shortestDistance) {
          shortestDistance = dist;
          _assignedNGOLocation = ngoLatLng;
        }
      }
    }

    _updateETAandProgress();
  }

  void _updateETAandProgress() {
    if (_currentLatLng == null || _assignedNGOLocation == null) return;
    final shortest = _calculateDistance(_currentLatLng!, _assignedNGOLocation!);
    etaMinutes = (shortest / averageSpeedKmh) * 60;
    progressPercent = (1.0 - (shortest / 10.0)).clamp(0.0, 1.0);
  }

  double _calculateDistance(LatLng a, LatLng b) {
    const R = 6371;
    final dLat = _deg2rad(b.latitude - a.latitude);
    final dLon = _deg2rad(b.longitude - a.longitude);
    final lat1 = _deg2rad(a.latitude);
    final lat2 = _deg2rad(b.latitude);

    final aVal = sin(dLat / 2) * sin(dLat / 2) +
        sin(dLon / 2) * sin(dLon / 2) * cos(lat1) * cos(lat2);
    final c = 2 * atan2(sqrt(aVal), sqrt(1 - aVal));
    return R * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Map & SOS"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          Expanded(
            child: _currentLatLng == null
                ? const Center(child: CircularProgressIndicator())
                : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentLatLng!,
                zoom: 16,
              ),
              markers: _markers,
              onMapCreated: (controller) => _controller.complete(controller),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
          ),
          _buildRescueProgressTracker(),
        ],
      ),
    );
  }

  Widget _buildRescueProgressTracker() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStepIcon(Icons.campaign, "Alert Sent", true),
              _buildLine(),
              _buildStepIcon(Icons.group, "Responders\nAssigned", _assignedNGOLocation != null),
              _buildLine(),
              _buildStepIcon(Icons.directions_car, "Help En Route", etaMinutes != null),
              _buildLine(),
              _buildStepIcon(Icons.check_circle, "Safe", false),
            ],
          ),
          const SizedBox(height: 12),
          if (etaMinutes != null && progressPercent != null)
            Column(
              children: [
                LinearProgressIndicator(
                  value: progressPercent!.clamp(0.0, 1.0),
                  backgroundColor: Colors.grey.shade300,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                  minHeight: 8,
                ),
                const SizedBox(height: 8),
                Text(
                  "🚑 Estimated arrival in ${etaMinutes!.toStringAsFixed(1)} minutes",
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStepIcon(IconData icon, String label, bool completed) {
    return Column(
      children: [
        Icon(icon, size: 30, color: completed ? Colors.deepPurple : Colors.grey),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: completed ? Colors.black : Colors.grey,
          ),
          textAlign: TextAlign.center,
        )
      ],
    );
  }

  Widget _buildLine() {
    return Expanded(
      child: Container(
        height: 2,
        color: Colors.grey.shade400,
      ),
    );
  }
}
