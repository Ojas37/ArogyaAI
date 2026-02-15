import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/triage_provider.dart';
import '../providers/language_provider.dart';
import '../services/speech_service.dart';
import '../services/api_service.dart';
import '../models/symptom_report.dart';
import '../models/chat_message.dart';
import 'vitals_screen.dart';
import 'nearest_medical_facility_screen.dart';
import 'nearest_hospital_clinics_screen.dart';
import 'schemes_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final SpeechService _speechService = SpeechService();
  final ApiService _apiService = ApiService();
  final List<ChatMessage> _messages = [];
  bool _isListening = false;
  bool _isDetectingLanguage = false;
  String _lastLanguage = 'en';
  bool _hasRequestedLocation = false;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final languageProvider = Provider.of<LanguageProvider>(context);

    // Check if language has changed
    if (_lastLanguage != languageProvider.currentLanguage) {
      _lastLanguage = languageProvider.currentLanguage;

      // Clear previous messages and add new welcome message in current language
      setState(() {
        _messages.clear();
      });
      _addWelcomeMessage();

      // Request location permission after language is set
      if (!_hasRequestedLocation) {
        _hasRequestedLocation = true;
        Future.delayed(const Duration(milliseconds: 500), () {
          _requestLocationPermission();
        });
      }
    }
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();

    if (!mounted) return;

    if (status.isDenied || status.isPermanentlyDenied) {
      final languageProvider =
          Provider.of<LanguageProvider>(context, listen: false);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(languageProvider.t('permissions.locationTitle')),
          content: Text(languageProvider.t('permissions.locationMessage')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(languageProvider.t('common.ok')),
            ),
            if (status.isPermanentlyDenied)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
          ],
        ),
      );
    }
  }

  void _addWelcomeMessage() {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    final welcomeText = languageProvider.t('chat.welcome');

    setState(() {
      _messages.add(ChatMessage(
        text: welcomeText,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }

  String _getWelcomeText(String language) {
    // Deprecated: Now using translation service
    return 'Hello! I\'m your health assistant. Please tell me your symptoms.';
  }

  String _getHintText(String language) {
    // Deprecated: Now using translation service
    return 'Type your symptoms...';
  }

  String _getTitle(String language) {
    // Deprecated: Now using translation service
    return 'Health Assistant';
  }

  Future<void> _handleVoiceInput() async {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);

    setState(() {
      _isListening = true;
    });

    try {
      final text =
          await _speechService.listen(languageProvider.currentLanguage);
      if (text.isNotEmpty) {
        _textController.text = text;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(languageProvider.t('chat.errorSendingMessage'))),
      );
    } finally {
      setState(() {
        _isListening = false;

        Future<void> handleAutoDetect() async {
          final text = _textController.text.trim();
          if (text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(languageProvider.t('errors.invalidInput'))),
            );
            return;
          }

          setState(() {
            _isDetectingLanguage = true;
          });

          try {
            final result = await _apiService.detectLanguage(text);
            final detectedLang = result['language'] as String;
            final detectedName =
                result['detected_language_name'] as String? ?? detectedLang;
            final confidence = result['confidence'] as double;

            if (mounted) {
              // Show detection result
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Language Detected'),
                  content: Text(
                    'Detected: $detectedName ($detectedLang)\n'
                    'Confidence: ${(confidence * 100).toStringAsFixed(0)}%\n\n'
                    'Would you like to switch to this language?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final languageProvider = Provider.of<LanguageProvider>(
                            context,
                            listen: false);
                        languageProvider.setLanguage(detectedLang);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Switched to $detectedName')),
                        );
                      },
                      child: const Text('Switch'),
                    ),
                  ],
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Error detecting language: ${e.toString()}')),
              );
            }
          } finally {
            if (mounted) {
              setState(() {
                _isDetectingLanguage = false;
              });
            }
          }
        }
      });
    }
  }

  Future<void> _handleSubmit() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    final triageProvider = Provider.of<TriageProvider>(context, listen: false);

    // Add user message
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
    });

    _textController.clear();

    // Create symptom report
    final report = SymptomReport(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: 'user123', // TODO: Implement proper auth
      language: languageProvider.currentLanguage,
      textInput: text,
      timestamp: DateTime.now(),
    );

    // Show loading
    setState(() {
      _messages.add(ChatMessage(
        text: languageProvider.t('chat.processing'),
        isUser: false,
        timestamp: DateTime.now(),
        isLoading: true,
      ));
    });

    // Remove loading message
    setState(() {
      _messages.removeLast();
    });

    // Store report temporarily in provider
    await triageProvider.analyzeSymptoms(report);

    // Add AI response
    setState(() {
      _messages.add(ChatMessage(
        text:
            'I\'ve recorded your symptoms. You can continue chatting or check the results using the Symptom Check button below.',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }

  Widget _buildDrawer(LanguageProvider languageProvider) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.green[700],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(
                  Icons.health_and_safety,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  languageProvider.t('app.name'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.chat, color: Colors.green),
            title: Text(languageProvider.t('drawer.chatbot')),
            onTap: () {
              Navigator.pop(context); // Close drawer
              // Already on chat screen
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_balance, color: Colors.green),
            title: Text(languageProvider.t('drawer.governmentSchemes')),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SchemesScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.local_hospital, color: Colors.green),
            title: Text(languageProvider.t('drawer.nearestMedicalFacility')),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const NearestMedicalFacilityScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.medical_services, color: Colors.green),
            title: Text(languageProvider.t('drawer.nearestHospitalClinics')),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const NearestHospitalClinicsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.favorite, color: Colors.green),
            title: Text(languageProvider.t('navigation.vitals')),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const VitalsScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.grey),
            title: Text(languageProvider.t('drawer.about')),
            onTap: () {
              Navigator.pop(context);
              showAboutDialog(
                context: context,
                applicationName: languageProvider.t('app.name'),
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(Icons.health_and_safety,
                    size: 48, color: Colors.green),
                children: [
                  Text(languageProvider.t('app.tagline')),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.t('chat.title')),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: _buildDrawer(languageProvider),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessage(_messages[index]);
              },
            ),
          ),

          // Input area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Voice input button
                IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening ? Colors.red : Colors.blue,
                  ),
                  onPressed: _handleVoiceInput,
                  iconSize: 32,
                ),
                const SizedBox(width: 8),

                // Text input
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: languageProvider.t('chat.inputPlaceholder'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _handleSubmit(),
                  ),
                ),
                const SizedBox(width: 8),

                // Send button
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _handleSubmit,
                  iconSize: 32,
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: message.isUser ? Colors.blue : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: message.isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? Colors.white : Colors.black87,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
