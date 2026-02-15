import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../services/cholesterol_classifier.dart';

class CholesterolCheckScreen extends StatefulWidget {
  const CholesterolCheckScreen({super.key});

  @override
  State<CholesterolCheckScreen> createState() => _CholesterolCheckScreenState();
}

class _CholesterolCheckScreenState extends State<CholesterolCheckScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cholesterolController = TextEditingController();
  CholesterolLevel? _level;

  @override
  void dispose() {
    _cholesterolController.dispose();
    super.dispose();
  }

  void _classifyCholesterol() {
    if (!_formKey.currentState!.validate()) return;
    final value = double.tryParse(_cholesterolController.text.trim());
    if (value == null) return;
    setState(() {
      _level = CholesterolClassifier.classify(value);
    });
  }

  Color _levelColor(CholesterolLevel level) {
    switch (level) {
      case CholesterolLevel.green:
        return Colors.green;
      case CholesterolLevel.yellow:
        return Colors.orange;
      case CholesterolLevel.red:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.t('vitals.cholesterol')),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                languageProvider.t('vitalsForm.cholesterolIntro'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cholesterolController,
                decoration: InputDecoration(
                  labelText: languageProvider.t('vitalsForm.cholesterolLabel'),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return languageProvider.t('errors.invalidInput');
                  }
                  final number = double.tryParse(value);
                  if (number == null || number <= 0) {
                    return languageProvider.t('errors.invalidInput');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _classifyCholesterol,
                  child: Text(languageProvider.t('vitalsForm.checkNow')),
                ),
              ),
              if (_level != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _levelColor(_level!).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _levelColor(_level!)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _level == CholesterolLevel.green
                            ? languageProvider.t('vitalsForm.statusNormal')
                            : _level == CholesterolLevel.yellow
                                ? languageProvider
                                    .t('vitalsForm.statusBorderline')
                                : languageProvider.t('vitalsForm.statusHigh'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _levelColor(_level!),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _level == CholesterolLevel.green
                            ? languageProvider.t('vitalsForm.adviceNormal')
                            : _level == CholesterolLevel.yellow
                                ? languageProvider.t('vitalsForm.adviceMonitor')
                                : languageProvider
                                    .t('vitalsForm.adviceConsultDoctor'),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
