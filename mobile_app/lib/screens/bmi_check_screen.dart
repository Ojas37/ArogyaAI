import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../services/bmi_classifier.dart';
import '../services/geocoding_service.dart';
import '../services/overpass_service.dart';

class BMICheckScreen extends StatefulWidget {
  const BMICheckScreen({super.key});

  @override
  State<BMICheckScreen> createState() => _BMICheckScreenState();
}

class _BMICheckScreenState extends State<BMICheckScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _placeController = TextEditingController();
  bool _isLoading = false;
  bool _isSearchingPlace = false;
  double? _selectedLatitude;
  double? _selectedLongitude;
  String? _selectedPlaceName;
  final String _locationType = 'City';
  BMILevel? _level;

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _placeController.dispose();
    super.dispose();
  }

  Future<void> _searchLocation() async {
    setState(() {
      _isSearchingPlace = true;
    });
    final query = _placeController.text.trim();
    final place = await GeocodingService.searchPlace(query);
    if (place != null && mounted) {
      setState(() {
        _selectedLatitude = place['latitude'];
        _selectedLongitude = place['longitude'];
        _selectedPlaceName = place['displayName'];
      });
    }
    setState(() {
      _isSearchingPlace = false;
    });
  }

  Future<void> _findFacilities() async {
    if (_selectedLatitude == null || _selectedLongitude == null) return;
    setState(() {
      _isLoading = true;
    });
    final facilities = await OverpassService.searchNearbyFacilities(
      latitude: _selectedLatitude!,
      longitude: _selectedLongitude!,
      facilityType: 'hospital,clinic',
      limit: 50,
      radiusMeters: 20000,
    );
    setState(() {
      _isLoading = false;
    });
    if (facilities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No facilities found nearby.')),
      );
    } else {
      // TODO: Show facility list UI
    }
  }

  void _classifyBMI() {
    if (!_formKey.currentState!.validate()) return;
    final weight = double.tryParse(_weightController.text);
    final height = double.tryParse(_heightController.text);
    if (weight == null || height == null || height == 0) return;
    final bmi = weight / ((height / 100) * (height / 100));
    final level = BMIClassifier.classify(bmi);
    setState(() {
      _level = level;
    });
  }

  Color _levelColor(BMILevel level) {
    switch (level) {
      case BMILevel.green:
        return Colors.green;
      case BMILevel.yellow:
        return Colors.orange;
      case BMILevel.red:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text(languageProvider.t('vitals.bmi'))),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextFormField(
                controller: _weightController,
                decoration: InputDecoration(
                  labelText: languageProvider.t('vitalsForm.weightLabel'),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty
                    ? languageProvider.t('errors.invalidInput')
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _heightController,
                decoration: InputDecoration(
                  labelText: languageProvider.t('vitalsForm.heightLabel'),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty
                    ? languageProvider.t('errors.invalidInput')
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _placeController,
                decoration: InputDecoration(
                  labelText: languageProvider.t('location.enterLocation'),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _searchLocation,
                child: _isSearchingPlace
                    ? const CircularProgressIndicator()
                    : Text(languageProvider.t('location.searchLocation')),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _findFacilities,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(languageProvider.t('location.findNearbyFacilities')),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _classifyBMI,
                child: Text(languageProvider.t('vitalsForm.checkNow')),
              ),
              if (_level != null) ...[
                const SizedBox(height: 16),
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
                        _level == BMILevel.green
                            ? languageProvider.t('vitalsForm.statusNormal')
                            : _level == BMILevel.yellow
                                ? languageProvider
                                    .t('vitalsForm.statusBorderline')
                                : languageProvider
                                    .t('vitalsForm.statusCritical'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _levelColor(_level!),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _level == BMILevel.green
                            ? languageProvider.t('vitalsForm.adviceNormal')
                            : _level == BMILevel.yellow
                                ? languageProvider.t('vitalsForm.adviceMonitor')
                                : languageProvider
                                    .t('vitalsForm.adviceSeekCare'),
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
