import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hawkins_frequency/energy_manager.dart';
import 'package:hawkins_frequency/dimension_switch_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnergyManager.init();
  runApp(const HawkinsFrequencyApp());
}

class HawkinsFrequencyApp extends StatelessWidget {
  const HawkinsFrequencyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'The Hawkins Frequency',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF050505),
        primaryColor: const Color(0xFFE71D36), 
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE71D36),
          secondary: Color(0xFF00FFC5), 
          surface: Color(0xFF121212),
        ),
        textTheme: TextTheme(
          displayLarge: GoogleFonts.rubikGlitch(fontSize: 48, color: const Color(0xFFE71D36)), 
          bodyLarge: GoogleFonts.shareTechMono(fontSize: 18, color: Colors.white70), 
          bodyMedium: GoogleFonts.shareTechMono(fontSize: 16, color: Colors.white60),
        ),
      ),
      home: const DimensionSwitchScreen(),
    );
  }
}