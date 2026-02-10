import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    final languages = [
      {'code': 'en', 'name': 'English', 'nativeName': 'English', 'flag': '🇬🇧'},
      {'code': 'hi', 'name': 'Hindi', 'nativeName': 'हिंदी', 'flag': '🇮🇳'},
      {'code': 'te', 'name': 'Telugu', 'nativeName': 'తెలుగు', 'flag': '🇮🇳'},
      {'code': 'ta', 'name': 'Tamil', 'nativeName': 'தமிழ்', 'flag': '🇮🇳'},
      {'code': 'bn', 'name': 'Bengali', 'nativeName': 'বাংলা', 'flag': '🇮🇳'},
      {'code': 'mr', 'name': 'Marathi', 'nativeName': 'मराठी', 'flag': '🇮🇳'},
      {'code': 'kn', 'name': 'Kannada', 'nativeName': 'ಕನ್ನಡ', 'flag': '🇮🇳'},
      {'code': 'gu', 'name': 'Gujarati', 'nativeName': 'ગુજરાતી', 'flag': '🇮🇳'},
      {'code': 'bh', 'name': 'Bhojpuri', 'nativeName': 'भोजपुरी', 'flag': '🇮🇳'},
      {'code': 'pa', 'name': 'Punjabi', 'nativeName': 'ਪੰਜਾਬੀ', 'flag': '🇮🇳'},
    ];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade400, Colors.blue.shade700],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 60),
              // Logo
              const Icon(
                Icons.favorite,
                size: 80,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              const Text(
                'ArogyaAI Health',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Healthcare for Everyone',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 60),
              // Language selection
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      const Text(
                        'Select Your Language',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'अपनी भाषा चुनें | మీ భాషను ఎంచుకోండి',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: languages.length,
                          itemBuilder: (context, index) {
                            final lang = languages[index];
                            final isSelected = languageProvider.currentLanguage == lang['code'];
                            
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: InkWell(
                                onTap: () {
                                  languageProvider.setLanguage(lang['code']!);
                                  Navigator.pushReplacementNamed(context, '/home');
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.blue.shade50 : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected ? Colors.blue : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        lang['flag']!,
                                        style: const TextStyle(fontSize: 32),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              lang['nativeName']!,
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              lang['name']!,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(
                                          Icons.check_circle,
                                          color: Colors.blue,
                                          size: 28,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
