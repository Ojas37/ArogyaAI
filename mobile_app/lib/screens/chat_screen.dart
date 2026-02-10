import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/triage_provider.dart';
import '../providers/language_provider.dart';
import '../services/speech_service.dart';
import '../models/symptom_report.dart';
import 'result_screen.dart';
import 'vitals_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final SpeechService _speechService = SpeechService();
  final List<ChatMessage> _messages = [];
  bool _isListening = false;
  String _lastLanguage = 'en';

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
      });
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

    // Store report temporarily in provider
    await triageProvider.analyzeSymptoms(report);

    // Ask if user wants to add vitals for better accuracy
    if (mounted) {
      final addVitals = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Add Vitals?'),
          content: const Text(
            'Would you like to add vital signs (SpO2, Temperature, Heart Rate) for a more accurate assessment?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Skip'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Add Vitals'),
            ),
          ],
        ),
      );

      if (addVitals == true) {
        // Navigate to vitals screen with special flag
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const VitalsScreen(fromSymptomCheck: true),
          ),
        );
      } else {
        // Go directly to results (symptoms only)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ResultScreen(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    return Column(
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

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isLoading;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isLoading = false,
  });
}
