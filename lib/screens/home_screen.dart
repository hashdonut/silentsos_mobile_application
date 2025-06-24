import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'profile_screen.dart';
import 'settings_screen.dart';
import 'map_screen.dart';
import '../services/alert_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String? selectedEmergency;

  final List<String> emergencyTypes = const [
    'Domestic Abuse',
    'Sexual Harassment',
    'Stalking',
    'Kidnapping',
    'Heart Attack',
    'Fire',
    'Assault',
    'Robbery',
  ];

  final List<Widget> _pages = [
    Placeholder(),
    MapScreen(),
    ProfileScreen(),
    SettingsScreen(),
  ];

  void _sendSOSAlert() async {
    final alertService = AlertService();
    await alertService.sendSOSAlert(crisisType: selectedEmergency ?? 'General Emergency');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🚨 Alert sent${selectedEmergency != null ? ' for "$selectedEmergency"' : ''}'),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('SilentSOS+', style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple.shade400,
      ),
      body: _currentIndex == 0 ? _buildHomeBody() : _pages[_currentIndex],
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
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEDE7F6), Color(0xFFFFF3E0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                '🚨 Choose Your Emergency',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF4A148C)),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 70,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: emergencyTypes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final type = emergencyTypes[index];
                    final isSelected = selectedEmergency == type;
                    return GestureDetector(
                      onTap: () => setState(() => selectedEmergency = type),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isSelected
                                ? [Colors.deepPurpleAccent, Colors.purpleAccent]
                                : [Color(0xFFE1BEE7), Color(0xFFCE93D8)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? Colors.deepPurple : const Color(0xFF6A1B9A),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepPurple.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(3, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            type,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : const Color(0xFF4A148C),
                              fontFamily: 'RobotoMono',
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 50),
              Expanded(
                child: Center(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onLongPress: _sendSOSAlert,
                      customBorder: const CircleBorder(),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Colors.red, Colors.redAccent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent.withOpacity(0.5),
                              blurRadius: 30,
                              spreadRadius: 10,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'SOS',
                            style: TextStyle(
                              fontSize: 46,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'Orbitron',
                              letterSpacing: 3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Long-press the red button to send a silent alert.\nChoosing a crisis type helps responders, but is optional.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.black87),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
