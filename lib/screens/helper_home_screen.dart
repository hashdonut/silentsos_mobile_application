import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:silentsos_mobile_application/screens/helper_settings_screen.dart';
import 'package:silentsos_mobile_application/screens/helper_profile_screen.dart';
import 'package:silentsos_mobile_application/screens/helper_map_screen.dart';

class HelperHomeScreen extends StatefulWidget {
  const HelperHomeScreen({super.key});

  @override
  State<HelperHomeScreen> createState() => _HelperHomeScreenState();
}

class _HelperHomeScreenState extends State<HelperHomeScreen> {
  int _currentIndex = 0;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  void _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = position;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      _buildHomeBody(),
      HelperMapScreen(),
      HelperProfileScreen(),
      HelperSettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text(
          'SilentSOS+ Helper',
          style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple.shade400,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Helper Guide',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Helper Guide'),
                  content: const Text('Here you can assist users during emergencies. More features coming soon.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildHomeBody() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      return const Center(child: Text('User not logged in.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          color: Colors.deepPurple,
          child: const Text(
            "Assigned SOS Alerts",
            style: TextStyle(
              fontSize: 22,
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('sos_alerts')
                .where('assignedHelper', isEqualTo: currentUserId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Center(child: Text('Error loading SOS alerts.'));
              }

              final alerts = snapshot.data?.docs ?? [];

              if (alerts.isEmpty) {
                return const Center(child: Text('No assigned SOS alerts.'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: alerts.length,
                itemBuilder: (context, index) {
                  final alert = alerts[index].data() as Map<String, dynamic>;
                  final alertId = alerts[index].id;
                  final status = alert['status'] ?? 'Unknown';
                  final location = alert['location'];
                  final timestamp = (alert['timestamp'] as Timestamp?)?.toDate();
                  final formattedTime = timestamp != null
                      ? '${timestamp.toLocal()}'
                      : 'Unknown Time';
                  double? lat;
                  double? lng;

                  if (location is GeoPoint) {
                    lat = location.latitude;
                    lng = location.longitude;
                  } else if (location is Map<String, dynamic> &&
                      (location['_latitude'] != null && location['_longitude'] != null)) {
                    lat = location['_latitude'] * 1.0;
                    lng = location['_longitude'] * 1.0;
                  }

                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🚨 SOS Alert: $alertId',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),

                          const SizedBox(height: 8),

                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 18, color: Colors.deepPurple),
                              const SizedBox(width: 6),
                              Text(
                                timestamp != null
                                    ? '${DateFormat.yMd().format(timestamp)}, ${DateFormat.jm().format(timestamp)}'
                                    : 'Unknown Time',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          if (lat != null && lng != null)
                            Row(
                              children: [
                                const Icon(Icons.map, size: 18, color: Colors.deepPurple),
                                const SizedBox(width: 6),
                                Text(
                                  'Lat: ${lat.toStringAsFixed(5)}, Lng: ${lng.toStringAsFixed(5)}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            )
                          else
                            const Text(
                              'Lat/Lng: Unknown',
                              style: TextStyle(fontSize: 16),
                            ),

                          const SizedBox(height: 8),

                          if (lat != null && lng != null && _currentPosition != null)
                            Text(
                              '~${(Geolocator.distanceBetween(
                                _currentPosition!.latitude,
                                _currentPosition!.longitude,
                                lat,
                                lng,
                              ) / 1000).toStringAsFixed(2)} km away',
                              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                            )
                          else
                            Text(
                              'Distance unavailable',
                              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                            ),

                          const SizedBox(height: 8),

                          Row(
                            children: [
                              const Text(
                                'Status:',
                                style: TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: status == 'resolved' ? Colors.green.shade100 : Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Text(
                                  status.toString().toLowerCase(),
                                  style: TextStyle(
                                    color: status == 'resolved' ? Colors.green.shade800 : Colors.red.shade800,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          if (lat != null && lng != null)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(top: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(50),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 6,
                                      offset: const Offset(2, 2),
                                    ),
                                  ],
                                ),
                                child: TextButton.icon(
                                  icon: const Icon(Icons.navigation, color: Colors.deepPurple, size: 18),
                                  label: const Text(
                                    'Track Route',
                                    style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _currentIndex = 1; // Switch to Map tab
                                    });
                                    Future.delayed(const Duration(milliseconds: 300), () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => HelperMapScreen(
                                            targetLat: lat!,
                                            targetLng: lng!,
                                          ),
                                        ),
                                      );
                                    });
                                  },
                                ),
                              ),
                            )
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}