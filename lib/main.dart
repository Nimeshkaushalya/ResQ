import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:resq_flutter/screens/home_screen.dart';
import 'package:resq_flutter/screens/report_screen.dart';
import 'package:resq_flutter/screens/first_aid_screen.dart';
import 'package:resq_flutter/screens/nearby_map_screen.dart';
import 'package:resq_flutter/screens/profile_screen.dart';
import 'package:resq_flutter/services/gemini_service.dart';
import 'package:lucide_icons/lucide_icons.dart';

void main() {
  runApp(const ResQApp());
}

class ResQApp extends StatelessWidget {
  const ResQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<GeminiService>(create: (_) => GeminiService()),
      ],
      child: MaterialApp(
        title: 'ResQ',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFDC2626), // Tailwind red-600
            primary: const Color(0xFFDC2626),
            background: const Color(0xFFF8FAFC), // Slate-50
            surface: Colors.white,
          ),
          scaffoldBackgroundColor: const Color(0xFFF8FAFC),
          textTheme: GoogleFonts.interTextTheme(
            Theme.of(context).textTheme,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Color(0xFF0F172A), // Slate-900
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
        home: const MainScaffold(),
      ),
    );
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    NearbyMapScreen(),
    ReportScreen(initialType: 'General'), // Placeholder, actual logic might differ
    FirstAidScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
            // Special handling for Report if it's meant to be a separate flow, 
            // but for tab nav we stick to index switching.
            setState(() => _currentIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFFDC2626),
        unselectedItemColor: Colors.grey[500],
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.map), // MapPin
            label: 'Nearby',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.alertCircle),
            label: 'Report',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.heartPulse), // closest to HeartPulse
            label: 'First Aid',
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
