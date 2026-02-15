import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../services/heart_rate_classifier.dart';
import '../services/geocoding_service.dart';
import '../services/overpass_service.dart';

class HeartRateCheckScreen extends StatefulWidget {
  const HeartRateCheckScreen({super.key});

  @override
  State<HeartRateCheckScreen> createState() => _HeartRateCheckScreenState();
}

class _HeartRateCheckScreenState extends State<HeartRateCheckScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bpmController = TextEditingController();
  final _placeController = TextEditingController();
  bool _isLoading = false;
  bool _isSearchingPlace = false;
  double? _selectedLatitude;
  double? _selectedLongitude;
  String? _selectedPlaceName;
  final String _locationType = 'City';
  HeartRateLevel? _level;

  @override
  void dispose() {
    _bpmController.dispose();
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

  void _classifyHeartRate() {
    if (!_formKey.currentState!.validate()) return;
    final bpm = int.tryParse(_bpmController.text);
    if (bpm == null) return;
    final level = HeartRateClassifier.classify(bpm);
    setState(() {
      _level = level;
    });
  }

  Color _levelColor(HeartRateLevel level) {
    switch (level) {
      case HeartRateLevel.green:
        return Colors.green;
      case HeartRateLevel.yellow:
        return Colors.orange;
      case HeartRateLevel.red:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text(languageProvider.t('vitals.heartRate'))),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextFormField(
                controller: _bpmController,
                decoration: InputDecoration(
                  labelText: languageProvider.t('vitalsForm.heartRateLabel'),
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
                onPressed: _classifyHeartRate,
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
                        _level == HeartRateLevel.green
                            ? languageProvider.t('vitalsForm.statusNormal')
                            : _level == HeartRateLevel.yellow
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
                        _level == HeartRateLevel.green
                            ? languageProvider.t('vitalsForm.adviceNormal')
                            : _level == HeartRateLevel.yellow
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
