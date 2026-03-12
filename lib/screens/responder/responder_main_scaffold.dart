import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'responder_home_screen.dart';
import 'emergency_requests_screen.dart';
import 'my_accepted_requests_screen.dart';
import 'responder_profile_screen.dart';

class ResponderMainScaffold extends StatefulWidget {
  const ResponderMainScaffold({super.key});

  @override
  State<ResponderMainScaffold> createState() => _ResponderMainScaffoldState();
}

class _ResponderMainScaffoldState extends State<ResponderMainScaffold> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const ResponderHomeScreen(),
    const EmergencyRequestsScreen(),
    const MyAcceptedRequestsScreen(),
    const ResponderProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFDC2626),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.listTodo),
            label: 'Requests Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.activity),
            label: 'My Responses',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.user),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
