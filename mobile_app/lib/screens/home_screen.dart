import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../providers/connectivity_provider.dart';
import 'chat_screen.dart';
import 'vitals_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const ChatScreen(),
    const VitalsScreen(),
    const HistoryScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Start connectivity monitoring
    Provider.of<ConnectivityProvider>(context, listen: false).startMonitoring();
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final connectivityProvider = Provider.of<ConnectivityProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ArogyaAI Health'),
        actions: [
          // Connectivity indicator
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: connectivityProvider.isOnline 
                    ? Colors.green.shade100 
                    : Colors.orange.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    connectivityProvider.isOnline 
                        ? Icons.cloud_done 
                        : Icons.cloud_off,
                    size: 16,
                    color: connectivityProvider.isOnline 
                        ? Colors.green 
                        : Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    connectivityProvider.isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: connectivityProvider.isOnline 
                          ? Colors.green.shade800 
                          : Colors.orange.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Language selector
          PopupMenuButton<String>(
            icon: const Icon(Icons.language),
            onSelected: (langCode) {
              languageProvider.setLanguage(langCode);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'en', child: Text('English')),
              const PopupMenuItem(value: 'hi', child: Text('हिंदी (Hindi)')),
              const PopupMenuItem(value: 'te', child: Text('తెలుగు (Telugu)')),
              const PopupMenuItem(value: 'ta', child: Text('தமிழ் (Tamil)')),
              const PopupMenuItem(value: 'bn', child: Text('বাংলা (Bengali)')),
              const PopupMenuItem(value: 'mr', child: Text('मराठी (Marathi)')),
              const PopupMenuItem(value: 'kn', child: Text('ಕನ್ನಡ (Kannada)')),
              const PopupMenuItem(value: 'gu', child: Text('ગુજરાતી (Gujarati)')),
              const PopupMenuItem(value: 'bh', child: Text('भोजपुरी (Bhojpuri)')),
              const PopupMenuItem(value: 'pa', child: Text('ਪੰਜਾਬੀ (Punjabi)')),
            ],
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Symptom Check',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: 'Vitals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }
}
