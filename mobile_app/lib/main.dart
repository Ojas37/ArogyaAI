import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/home_screen.dart';
import 'screens/language_screen.dart';
import 'providers/triage_provider.dart';
import 'providers/language_provider.dart';
import 'providers/connectivity_provider.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for offline storage
  await Hive.initFlutter();
  await StorageService.init();
  
  runApp(const ArogyaAIApp());
}

class ArogyaAIApp extends StatelessWidget {
  const ArogyaAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => TriageProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return MaterialApp(
            title: 'ArogyaAI Health',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.blue,
              scaffoldBackgroundColor: const Color(0xFFF5F7FA),
              textTheme: GoogleFonts.notoSansTextTheme(
                Theme.of(context).textTheme,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            home: const LanguageSelectionScreen(),
            routes: {
              '/home': (context) => const HomeScreen(),
              '/language': (context) => const LanguageSelectionScreen(),
            },
          );
        },
      ),
    );
  }
}
