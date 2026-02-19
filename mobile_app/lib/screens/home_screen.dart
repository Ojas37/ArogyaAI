import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../providers/connectivity_provider.dart';
import 'chat_screen.dart';
import 'vitals_screen.dart';
import 'history_screen.dart';
import 'schemes_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _changeTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  List<Widget> get _screens => [
    ChatScreen(onNavigateToTab: _changeTab),
    const VitalsScreen(),
    const HistoryScreen(),
    const SchemesScreen(),
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
        title: Text(languageProvider.t('app.name')),
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
                    connectivityProvider.isOnline
                        ? languageProvider.t('common.online')
                        : languageProvider.t('common.offline'),
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
              PopupMenuItem(
                  value: 'en',
                  child: Text(languageProvider.t('language.english'))),
              PopupMenuItem(
                  value: 'hi',
                  child: Text(languageProvider.t('language.hindi'))),
              PopupMenuItem(
                  value: 'te',
                  child: Text(languageProvider.t('language.telugu'))),
              PopupMenuItem(
                  value: 'ta',
                  child: Text(languageProvider.t('language.tamil'))),
              PopupMenuItem(
                  value: 'bn',
                  child: Text(languageProvider.t('language.bengali'))),
              PopupMenuItem(
                  value: 'mr',
                  child: Text(languageProvider.t('language.marathi'))),
              PopupMenuItem(
                  value: 'kn',
                  child: Text(languageProvider.t('language.kannada'))),
              PopupMenuItem(
                  value: 'gu',
                  child: Text(languageProvider.t('language.gujarati'))),
              PopupMenuItem(
                  value: 'bh',
                  child: Text(languageProvider.t('language.bhojpuri'))),
              PopupMenuItem(
                  value: 'pa',
                  child: Text(languageProvider.t('language.punjabi'))),
            ],
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.chat_bubble_outline),
            label: languageProvider.t('navigation.symptomCheck'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.favorite_border),
            label: languageProvider.t('navigation.vitals'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.history),
            label: languageProvider.t('navigation.history'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.policy_outlined),
            label: languageProvider.t('navigation.schemes'),
          ),
        ],
      ),
    );
  }
}
