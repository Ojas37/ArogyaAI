import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../services/temperature_classifier.dart';
import '../services/location_service.dart';
import '../services/geocoding_service.dart';
import '../services/overpass_service.dart';

class TemperatureCheckScreen extends StatefulWidget {
  const TemperatureCheckScreen({super.key});

  @override
  State<TemperatureCheckScreen> createState() => _TemperatureCheckScreenState();
}

class _TemperatureCheckScreenState extends State<TemperatureCheckScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tempController = TextEditingController();
  final _placeController = TextEditingController();
  bool _isLoading = false;
  bool _isSearchingPlace = false;
  bool _useManualLocation = false;
  double? _selectedLatitude;
  double? _selectedLongitude;
  String? _selectedPlaceName;
  String _locationType = 'City';
  bool _locationAcquired = false;
  TemperatureLevel? _level;

  @override
  void dispose() {
    _tempController.dispose();
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
        _locationAcquired = true;
      });
    }
    setState(() {
      _isSearchingPlace = false;
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });
    final pos = await LocationService.getCurrentLocationWithTimeout(
      timeout: const Duration(seconds: 10),
    );
    if (pos != null && mounted) {
      setState(() {
        _selectedLatitude = pos.latitude;
        _selectedLongitude = pos.longitude;
        _selectedPlaceName = 'Current Location';
        _locationAcquired = true;
      });
    }
    setState(() {
      _isLoading = false;
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

  void _classifyTemperature() {
    if (!_formKey.currentState!.validate()) return;
    final temp = double.tryParse(_tempController.text);
    if (temp == null) return;
    final level = TemperatureClassifier.classify(temp);
    setState(() {
      _level = level;
    });
  }

  Color _levelColor(TemperatureLevel level) {
    switch (level) {
      case TemperatureLevel.green:
        return Colors.green;
      case TemperatureLevel.yellow:
        return Colors.orange;
      case TemperatureLevel.red:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text(languageProvider.t('vitals.temperature'))),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              TextFormField(
                controller: _tempController,
                decoration: InputDecoration(
                  labelText: languageProvider.t('vitalsForm.temperatureLabel'),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty
                    ? languageProvider.t('errors.invalidInput')
                    : null,
              ),
              const SizedBox(height: 20),
              Text(
                languageProvider.t('location.yourLocation'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _useManualLocation = !_useManualLocation;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(
                                _useManualLocation
                                    ? Icons.edit_location_alt
                                    : Icons.my_location,
                                color: Colors.teal),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _useManualLocation
                                    ? languageProvider.t('location.enterManual')
                                    : languageProvider.t('location.usingGps'),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            Switch(
                              value: _useManualLocation,
                              onChanged: (val) {
                                setState(() {
                                  _useManualLocation = val;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_useManualLocation) ...[
                DropdownButton<String>(
                  value: _locationType,
                  items: [
                    DropdownMenuItem(
                      value: 'City',
                      child: Text(languageProvider.t('location.city')),
                    ),
                    DropdownMenuItem(
                      value: 'Village',
                      child: Text(languageProvider.t('location.village')),
                    ),
                    DropdownMenuItem(
                      value: 'Pin Code',
                      child: Text(languageProvider.t('location.pinCode')),
                    ),
                    DropdownMenuItem(
                      value: 'Taluka',
                      child: Text(languageProvider.t('location.taluka')),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _locationType = val;
                      });
                    }
                  },
                ),
                TextFormField(
                  controller: _placeController,
                  decoration: InputDecoration(
                    labelText: languageProvider.t('location.enterLocation'),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _isSearchingPlace ? null : _searchLocation,
                  child: _isSearchingPlace
                      ? const CircularProgressIndicator()
                      : Text(languageProvider.t('location.searchLocation')),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_off, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _locationAcquired
                              ? languageProvider.t('location.locationAcquired')
                              : languageProvider
                                  .t('location.locationNotAcquired'),
                          style: const TextStyle(color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _getCurrentLocation,
                  icon: const Icon(Icons.my_location),
                  label: _isLoading
                      ? const CircularProgressIndicator()
                      : Text(languageProvider.t('location.getCurrentLocation')),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _findFacilities,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(languageProvider.t('location.findNearbyFacilities')),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _classifyTemperature,
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
                        _level == TemperatureLevel.green
                            ? languageProvider.t('vitalsForm.statusNormal')
                            : _level == TemperatureLevel.yellow
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
                        _level == TemperatureLevel.green
                            ? languageProvider.t('vitalsForm.adviceNormal')
                            : _level == TemperatureLevel.yellow
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
