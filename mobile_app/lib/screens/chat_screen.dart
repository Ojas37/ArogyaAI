import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/triage_provider.dart';
import '../providers/language_provider.dart';
import '../services/speech_service.dart';
import '../services/api_service.dart';
import '../models/symptom_report.dart';
import '../models/chat_message.dart';
import 'result_screen.dart';
import 'vitals_screen.dart';

class ChatScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;
  
  const ChatScreen({super.key, this.onNavigateToTab});

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
  
  // Generate unique session ID on each app reload for fresh conversations
  late final String _sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    print('🆕 New chat session started: $_sessionId');
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
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Location Required'),
          content: const Text(
            'Location access is required to find nearby doctors and provide personalized healthcare services. Please enable location permission in your device settings.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
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
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final welcomeText = _getWelcomeText(languageProvider.currentLanguage);
    
    setState(() {
      _messages.add(ChatMessage(
        text: welcomeText,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }

  String _getWelcomeText(String language) {
    switch (language) {
      case 'hi':
        return 'नमस्ते! मैं आपका स्वास्थ्य सहायक हूं। कृपया अपने लक्षण बताएं।';
      case 'te':
        return 'నమస్కారం! నేను మీ ఆరోగ్య సహాయకుడిని. దయచేసి మీ లక్షణాలను చెప్పండి.';
      case 'ta':
        return 'வணக்கம்! நான் உங்கள் சுகாதார உதவியாளர். உங்கள் அறிகுறிகளைச் சொல்லுங்கள்.';
      case 'bn':
        return 'নমস্কার! আমি আপনার স্বাস্থ্য সহায়ক। অনুগ্রহ করে আপনার লক্ষণগুলি বলুন।';
      case 'mr':
        return 'नमस्कार! मी तुमचा आरोग्य सहाय्यक आहे. कृपया तुमची लक्षणे सांगा.';
      case 'kn':
        return 'ನಮಸ್ಕಾರ! ನಾನು ನಿಮ್ಮ ಆರೋಗ್ಯ ಸಹಾಯಕ. ದಯವಿಟ್ಟು ನಿಮ್ಮ ಲಕ್ಷಣಗಳನ್ನು ತಿಳಿಸಿ.';
      case 'gu':
        return 'નમસ્તે! હું તમારો આરોગ્ય સહાયક છું. કૃપા કરીને તમારા લક્ષણો જણાવો.';
      case 'bh':
        return 'नमस्कार! हम राउर स्वास्थ्य सहायक हईं। कृपया आपन लक्षण बताईं।';
      case 'pa':
        return 'ਸਤ ਸ੍ਰੀ ਅਕਾਲ! ਮੈਂ ਤੁਹਾਡਾ ਸਿਹਤ ਸਹਾਇਕ ਹਾਂ। ਕਿਰਪਾ ਕਰਕੇ ਆਪਣੇ ਲੱਛਣ ਦੱਸੋ।';
      default:
        return 'Hello! I\'m your health assistant. Please tell me your symptoms.';
    }
  }

  String _getHintText(String language) {
    switch (language) {
      case 'hi':
        return 'अपने लक्षण लिखें...';
      case 'te':
        return 'మీ లక్షణాలను టైప్ చేయండి...';
      case 'ta':
        return 'உங்கள் அறிகுறிகளை தட்டச்சு செய்யுங்கள்...';
      case 'bn':
        return 'আপনার লক্ষণগুলি টাইপ করুন...';
      case 'mr':
        return 'तुमची लक्षणे टाइप करा...';
      case 'kn':
        return 'ನಿಮ್ಮ ಲಕ್ಷಣಗಳನ್ನು ಟೈಪ್ ಮಾಡಿ...';
      case 'gu':
        return 'તમારા લક્ષણો ટાઇપ કરો...';
      case 'bh':
        return 'आपन लक्षण टाइप करीं...';
      case 'pa':
        return 'ਆਪਣੇ ਲੱਛਣ ਟਾਈਪ ਕਰੋ...';
      default:
        return 'Type your symptoms...';
    }
  }

  String _getTitle(String language) {
    switch (language) {
      case 'hi':
        return 'स्वास्थ्य सहायक';
      case 'te':
        return 'ఆరోగ్య సహాయకుడు';
      case 'ta':
        return 'சுகாதார உதவியாளர்';
      case 'bn':
        return 'স্বাস্থ্য সহায়ক';
      case 'mr':
        return 'आरोग्य सहाय्यक';
      case 'kn':
        return 'ಆರೋಗ್ಯ ಸಹಾಯಕ';
      case 'gu':
        return 'આરોગ્ય સહાયક';
      default:
        return 'Health Assistant';
    }
  }

  Future<void> _handleVoiceInput() async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    
    setState(() {
      _isListening = true;
    });

    try {
      final text = await _speechService.listen(languageProvider.currentLanguage);
      if (text.isNotEmpty) {
        _textController.text = text;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isListening = false;
   

  Future<void> _handleAutoDetect() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter some text first')),
      );
      return;
    }

    setState(() {
      _isDetectingLanguage = true;
    });

    try {
      final result = await _apiService.detectLanguage(text);
      final detectedLang = result['language'] as String;
      final detectedName = result['detected_language_name'] as String? ?? detectedLang;
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
                  final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
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
          SnackBar(content: Text('Error detecting language: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDetectingLanguage = false;
        });
      }
    }
  }   });
    }
  }

  Future<void> _handleSubmit() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
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

    // Create symptom report with unique session ID
    final report = SymptomReport(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: _sessionId, // Unique session ID per app reload
      language: languageProvider.currentLanguage,
      textInput: text,
      timestamp: DateTime.now(),
    );

    // Show loading
    setState(() {
      _messages.add(ChatMessage(
        text: 'Analyzing...',
        isUser: false,
        timestamp: DateTime.now(),
        isLoading: true,
      ));
    });

    // Remove loading message
    setState(() {
      _messages.removeLast();
    });

    try {
      // Call API and get conversational response
      await triageProvider.analyzeSymptoms(report);

      // Get the conversational response from the API
      final result = triageProvider.currentResult;
      final responseText = result?.recommendation ?? 
        'I\'ve recorded your symptoms. You can continue chatting or check the results using the Symptom Check button below.';

      // Add AI response
      setState(() {
        _messages.add(ChatMessage(
          text: responseText,
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    } catch (e) {
      // Show error in chat
      setState(() {
        _messages.add(ChatMessage(
          text: 'Sorry, I encountered an error: ${e.toString()}. Please try again.',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    }
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
                  'ArogyaAI Health',
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
            title: const Text('Chatbot'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              // Already on chat screen
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_balance, color: Colors.green),
            title: const Text('Government Schemes'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to Schemes tab (index 3)
              widget.onNavigateToTab?.call(3);
            },
          ),
          ListTile(
            leading: const Icon(Icons.phone, color: Colors.green),
            title: const Text('Call Nearest Doctor'),
            onTap: () async {
              Navigator.pop(context);
              final status = await Permission.location.status;
              if (status.isGranted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Finding nearest doctors...'),
                    duration: Duration(seconds: 2),
                  ),
                );
              } else {
                _requestLocationPermission();
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.favorite, color: Colors.green),
            title: const Text('Vitals'),
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
            title: const Text('About'),
            onTap: () {
              Navigator.pop(context);
              showAboutDialog(
                context: context,
                applicationName: 'ArogyaAI Health',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(Icons.health_and_safety, size: 48, color: Colors.green),
                children: [
                  const Text('AI-powered rural healthcare assistant with multilingual symptom checker.'),
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
        title: Text(_getTitle(languageProvider.currentLanguage)),
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
                      hintText: _getHintText(languageProvider.currentLanguage),
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

