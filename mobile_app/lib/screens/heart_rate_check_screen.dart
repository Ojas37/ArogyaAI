import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../services/heart_rate_classifier.dart';
import '../services/location_service.dart';
import '../services/geocoding_service.dart';

class HeartRateCheckScreen extends StatefulWidget {
  const HeartRateCheckScreen({super.key});

  @override
  State<HeartRateCheckScreen> createState() => _HeartRateCheckScreenState();
}

class _HeartRateCheckScreenState extends State<HeartRateCheckScreen> {
  final _formKey = GlobalKey<FormState>();
  final _heartRateController = TextEditingController();
  final _placeController = TextEditingController();
  final Set<HeartRateSymptom> _selectedSymptoms = {};
  bool _isLoading = false;
  bool _isSearchingPlace = false;
  bool _useManualLocation = false;
  Position? _currentPosition;
  double? _selectedLatitude;
  double? _selectedLongitude;
  String? _selectedPlaceName;
  String _locationType = 'City'; // City, Village, Pin Code, Taluka

  @override
  void dispose() {
    _heartRateController.dispose();
    _placeController.dispose();
    super.dispose();
  }

  String _locationTypeLabel(LanguageProvider languageProvider) {
    switch (_locationType) {
      case 'City':
        return languageProvider.t('location.city');
      case 'Village':
        return languageProvider.t('location.village');
      case 'Pin Code':
        return languageProvider.t('location.pinCode');
      case 'Taluka':
        return languageProvider.t('location.taluka');
      default:
        return languageProvider.t('location.enterLocation');
    }
  }

  String _getHintText(LanguageProvider languageProvider) {
    switch (_locationType) {
      case 'City':
        return languageProvider.t('heartRate.hintCity');
      case 'Village':
        return languageProvider.t('heartRate.hintVillage');
      case 'Pin Code':
        return languageProvider.t('heartRate.hintPinCode');
      case 'Taluka':
        return languageProvider.t('heartRate.hintTaluka');
      default:
        return languageProvider.t('location.enterLocation');
    }
  }

  String _getLocationTip(LanguageProvider languageProvider) {
    switch (_locationType) {
      case 'City':
        return languageProvider.t('heartRate.tipCity');
      case 'Village':
        return languageProvider.t('heartRate.tipVillage');
      case 'Pin Code':
        return languageProvider.t('heartRate.tipPinCode');
      case 'Taluka':
        return languageProvider.t('heartRate.tipTaluka');
      default:
        return '';
    }
  }

  Future<void> _getCurrentLocation() async {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);

    setState(() => _isLoading = true);

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          bool openSettings = await _showLocationServiceDialog();
          if (openSettings) {
            await Geolocator.openLocationSettings();
          }
        }
        setState(() => _isLoading = false);
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            await _showPermissionDialog();
          }
          setState(() => _isLoading = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          await _showPermissionDialog();
        }
        setState(() => _isLoading = false);
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _selectedLatitude = position.latitude;
          _selectedLongitude = position.longitude;
          _selectedPlaceName = 'Current Location';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(languageProvider.t('heartRate.locationAcquiredSuccess')),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = languageProvider.t(
          'heartRate.locationError',
          params: {'error': e.toString()},
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _searchPlace() async {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);

    if (_placeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            languageProvider.t(
              'heartRate.enterLocationType',
              params: {'type': _locationTypeLabel(languageProvider)},
            ),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSearchingPlace = true);

    try {
      // Format search query based on location type
      String searchQuery = _placeController.text;
      if (_locationType == 'Pin Code') {
        searchQuery += ', India';
      } else if (_locationType == 'Taluka') {
        searchQuery += ', Maharashtra, India';
      }

      final result = await GeocodingService.searchPlace(searchQuery);

      if (result != null && mounted) {
        setState(() {
          _selectedLatitude = result['latitude'];
          _selectedLongitude = result['longitude'];
          _selectedPlaceName = result['displayName'];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              languageProvider.t(
                'heartRate.locationFound',
                params: {'name': result['displayName']},
              ),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(languageProvider.t('heartRate.locationNotFound')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = languageProvider.t(
          'heartRate.errorMessage',
          params: {'error': e.toString()},
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSearchingPlace = false);
      }
    }
  }

  Future<bool> _showLocationServiceDialog() async {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.location_off, color: Colors.orange),
                const SizedBox(width: 8),
                Text(languageProvider.t('heartRate.locationServicesDisabled')),
              ],
            ),
            content: Text(
              languageProvider.t('heartRate.locationServicesOff'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(languageProvider.t('common.cancel')),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                child: Text(languageProvider.t('errors.openSettings')),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _showPermissionDialog() async {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            Text(languageProvider.t('errors.locationRequired')),
          ],
        ),
        content: Text(
          languageProvider.t('errors.locationMessage'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(languageProvider.t('common.cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              LocationService.openAppSettings();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            child: Text(languageProvider.t('errors.openSettings')),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Parse heart rate value
      final heartRateValue = int.parse(_heartRateController.text);

      // Get location
      double? latitude = _selectedLatitude;
      double? longitude = _selectedLongitude;

      // Validate location is available
      if (latitude == null || longitude == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                Provider.of<LanguageProvider>(context, listen: false)
                    .t('heartRate.locationFirst'),
              ),
              backgroundColor: Colors.orange,
            ),
          );
          setState(() => _isLoading = false);
        }
        return;
      }

      // Classify reading
      final level = HeartRateClassifier.classify(heartRateValue);

      // Show result dialog
      if (mounted) {
        _showResultDialog(level, heartRateValue);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Provider.of<LanguageProvider>(context, listen: false).t(
                'heartRate.errorMessage',
                params: {'error': e.toString()},
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showResultDialog(HeartRateLevel level, int value) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    
    Color levelColor;
    String statusText;
    String adviceText;
    
    switch (level) {
      case HeartRateLevel.green:
        levelColor = Colors.green;
        statusText = languageProvider.t('vitalsForm.statusNormal');
        adviceText = languageProvider.t('vitalsForm.adviceNormal');
        break;
      case HeartRateLevel.yellow:
        levelColor = Colors.orange;
        statusText = languageProvider.t('vitalsForm.statusWarning');
        adviceText = languageProvider.t('vitalsForm.adviceMonitor');
        break;
      case HeartRateLevel.red:
        levelColor = Colors.red;
        statusText = languageProvider.t('vitalsForm.statusEmergency');
        adviceText = languageProvider.t('vitalsForm.adviceSeekCare');
        break;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.favorite, color: levelColor),
            const SizedBox(width: 8),
            Text(statusText, style: TextStyle(color: levelColor)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${languageProvider.t('heartRate.label')}: $value bpm',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(adviceText),
            if (_selectedSymptoms.isNotEmpty && _selectedSymptoms.first != HeartRateSymptom.none) ...[
              const SizedBox(height: 12),
              Text(
                languageProvider.t('heartRate.withSymptoms', 
                  params: {'count': _selectedSymptoms.length.toString()}),
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(languageProvider.t('common.ok')),
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
        title: Text(languageProvider.t('heartRate.title')),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              const Icon(
                Icons.favorite,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                languageProvider.t('heartRate.header'),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                languageProvider.t('heartRate.description'),
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Heart rate input
              TextFormField(
                controller: _heartRateController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: languageProvider.t('heartRate.label'),
                  hintText: languageProvider.t('heartRate.hintValue'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.favorite),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return languageProvider.t('heartRate.required');
                  }
                  final num? bpm = int.tryParse(value);
                  if (bpm == null || bpm <= 0 || bpm > 300) {
                    return languageProvider.t('heartRate.invalid');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Location section
              Text(
                languageProvider.t('location.yourLocation'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Location method toggle
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(languageProvider.t('location.enterManual')),
                      subtitle: Text(
                        _useManualLocation
                            ? languageProvider.t('heartRate.manualEntryMode')
                            : languageProvider.t('location.usingGps'),
                        style: const TextStyle(fontSize: 12),
                      ),
                      value: _useManualLocation,
                      onChanged: (value) {
                        setState(() => _useManualLocation = value);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // GPS location or manual input
              if (!_useManualLocation)
                Container(
                  decoration: BoxDecoration(
                    color: _currentPosition != null
                        ? Colors.green.shade50
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _currentPosition != null
                          ? Colors.green.shade200
                          : Colors.orange.shade200,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              _selectedLatitude != null
                                  ? Icons.location_on
                                  : Icons.location_off,
                              color: _selectedLatitude != null
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedLatitude != null
                                    ? languageProvider.t(
                                        'location.coordinates',
                                        params: {
                                          'lat': _selectedLatitude!
                                              .toStringAsFixed(4),
                                          'lon': _selectedLongitude!
                                              .toStringAsFixed(4),
                                        },
                                      )
                                    : languageProvider
                                        .t('location.locationNotAcquired'),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _getCurrentLocation,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.my_location),
                          label: Text(
                            _isLoading
                                ? languageProvider.t('location.gettingLocation')
                                : languageProvider.t('location.getCurrentLocation'),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            minimumSize: const Size(double.infinity, 45),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    // Location type dropdown
                    DropdownButtonFormField<String>(
                      value: _locationType,
                      decoration: InputDecoration(
                        labelText: languageProvider.t('heartRate.searchBy'),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.map),
                      ),
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
                      onChanged: (value) {
                        setState(() {
                          _locationType = value!;
                          _placeController.clear();
                          _selectedLatitude = null;
                          _selectedLongitude = null;
                          _selectedPlaceName = null;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    // Place name search field
                    TextFormField(
                      controller: _placeController,
                      keyboardType: _locationType == 'Pin Code'
                          ? TextInputType.number
                          : TextInputType.text,
                      decoration: InputDecoration(
                        labelText: languageProvider.t('location.enterLocation'),
                        hintText: _getHintText(languageProvider),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _isSearchingPlace
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : null,
                      ),
                      onFieldSubmitted: (_) => _searchPlace(),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _isSearchingPlace ? null : _searchPlace,
                      icon: const Icon(Icons.search),
                      label: Text(languageProvider.t('location.searchLocation')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        minimumSize: const Size(double.infinity, 45),
                      ),
                    ),
                    if (_selectedPlaceName != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle,
                                color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedPlaceName!,
                                style: const TextStyle(fontSize: 12),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      _getLocationTip(languageProvider),
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              const SizedBox(height: 24),

              // Symptoms section
              Text(
                languageProvider.t('heartRate.symptomsTitle'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildSymptomChips(languageProvider),
              const SizedBox(height: 32),

              // Submit button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.all(16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        languageProvider.t('vitalsForm.checkNow'),
                        style: const TextStyle(fontSize: 18),
                      ),
              ),
              const SizedBox(height: 16),

              // Disclaimer
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        languageProvider.t('heartRate.disclaimer'),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSymptomChips(LanguageProvider languageProvider) {
    final symptoms = [
      HeartRateSymptom.chestPain,
      HeartRateSymptom.palpitations,
      HeartRateSymptom.shortnesOfBreath,
      HeartRateSymptom.dizziness,
      HeartRateSymptom.fatigue,
      HeartRateSymptom.lightheadedness,
      HeartRateSymptom.fainting,
      HeartRateSymptom.sweating,
      HeartRateSymptom.none,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: symptoms.map((symptom) {
        final isSelected = _selectedSymptoms.contains(symptom);
        final label = _getSymptomLabel(symptom, languageProvider);

        return FilterChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (symptom == HeartRateSymptom.none) {
                // If "None" is selected, clear all others
                _selectedSymptoms.clear();
                if (selected) {
                  _selectedSymptoms.add(symptom);
                }
              } else {
                // Remove "None" if selecting other symptoms
                _selectedSymptoms.remove(HeartRateSymptom.none);
                if (selected) {
                  _selectedSymptoms.add(symptom);
                } else {
                  _selectedSymptoms.remove(symptom);
                }
              }
            });
          },
          backgroundColor: Colors.grey.shade200,
          selectedColor: _isSevereSymptom(symptom)
              ? Colors.red.shade100
              : Colors.teal.shade100,
        );
      }).toList(),
    );
  }

  String _getSymptomLabel(
    HeartRateSymptom symptom,
    LanguageProvider languageProvider,
  ) {
    switch (symptom) {
      case HeartRateSymptom.chestPain:
        return languageProvider.t('heartRate.symptom.chestPain');
      case HeartRateSymptom.palpitations:
        return languageProvider.t('heartRate.symptom.palpitations');
      case HeartRateSymptom.shortnesOfBreath:
        return languageProvider.t('heartRate.symptom.shortnessOfBreath');
      case HeartRateSymptom.dizziness:
        return languageProvider.t('heartRate.symptom.dizziness');
      case HeartRateSymptom.fatigue:
        return languageProvider.t('heartRate.symptom.fatigue');
      case HeartRateSymptom.lightheadedness:
        return languageProvider.t('heartRate.symptom.lightheadedness');
      case HeartRateSymptom.fainting:
        return languageProvider.t('heartRate.symptom.fainting');
      case HeartRateSymptom.sweating:
        return languageProvider.t('heartRate.symptom.sweating');
      case HeartRateSymptom.none:
        return languageProvider.t('heartRate.symptom.none');
    }
  }

  bool _isSevereSymptom(HeartRateSymptom symptom) {
    return symptom == HeartRateSymptom.chestPain ||
        symptom == HeartRateSymptom.fainting ||
        symptom == HeartRateSymptom.shortnesOfBreath;
  }
}