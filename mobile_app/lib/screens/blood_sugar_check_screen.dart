import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../models/blood_sugar_reading.dart';
import '../services/blood_sugar_classifier.dart';
import '../services/location_service.dart';
import '../services/geocoding_service.dart';
import 'blood_sugar_results_screen.dart';

class BloodSugarCheckScreen extends StatefulWidget {
  const BloodSugarCheckScreen({super.key});

  @override
  State<BloodSugarCheckScreen> createState() => _BloodSugarCheckScreenState();
}

class _BloodSugarCheckScreenState extends State<BloodSugarCheckScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sugarController = TextEditingController();
  final _placeController = TextEditingController();
  final Set<BloodSugarSymptom> _selectedSymptoms = {};
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
    _sugarController.dispose();
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
        return languageProvider.t('bloodSugar.hintCity');
      case 'Village':
        return languageProvider.t('bloodSugar.hintVillage');
      case 'Pin Code':
        return languageProvider.t('bloodSugar.hintPinCode');
      case 'Taluka':
        return languageProvider.t('bloodSugar.hintTaluka');
      default:
        return languageProvider.t('location.enterLocation');
    }
  }

  String _getLocationTip(LanguageProvider languageProvider) {
    switch (_locationType) {
      case 'City':
        return languageProvider.t('bloodSugar.tipCity');
      case 'Village':
        return languageProvider.t('bloodSugar.tipVillage');
      case 'Pin Code':
        return languageProvider.t('bloodSugar.tipPinCode');
      case 'Taluka':
        return languageProvider.t('bloodSugar.tipTaluka');
      default:
        return '';
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
              'bloodSugar.enterLocationType',
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
        searchQuery += ', India'; // Add country for better pin code search
      } else if (_locationType == 'Taluka') {
        searchQuery += ', Maharashtra, India'; // Add state context for taluka
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
                'bloodSugar.locationFound',
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
            content: Text(languageProvider.t('bloodSugar.locationNotFound')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              languageProvider.t(
                'bloodSugar.errorMessage',
                params: {'error': e.toString()},
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSearchingPlace = false);
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    setState(() => _isLoading = true);

    try {
      // Check if location services are enabled
      bool serviceEnabled = await LocationService.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          final shouldOpen = await _showLocationServiceDialog();
          if (shouldOpen) {
            await LocationService.openLocationSettings();
          }
          setState(() => _isLoading = false);
          return;
        }
      }

      // Get location
      final position = await LocationService.getCurrentLocationWithTimeout(
        timeout: const Duration(seconds: 10),
      );

      if (position != null && mounted) {
        setState(() {
          _currentPosition = position;
          _selectedLatitude = position.latitude;
          _selectedLongitude = position.longitude;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(languageProvider.t('bloodSugar.locationAcquiredSuccess')),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = languageProvider.t(
          'bloodSugar.locationError',
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
                Text(languageProvider.t('bloodSugar.locationServicesDisabled')),
              ],
            ),
            content: Text(
              languageProvider.t('bloodSugar.locationServicesOff'),
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
      // Parse sugar value
      final sugarValue = double.parse(_sugarController.text);

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
                    .t('bloodSugar.locationFirst'),
              ),
              backgroundColor: Colors.orange,
            ),
          );
          setState(() => _isLoading = false);
        }
        return;
      }

      // Classify reading
      final reading = BloodSugarClassifier.classifyReading(
        sugarValue: sugarValue,
        symptoms: _selectedSymptoms.toList(),
      );

      // Navigate to results
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BloodSugarResultsScreen(
              reading: reading,
              latitude: latitude,
              longitude: longitude,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Provider.of<LanguageProvider>(context, listen: false).t(
                'bloodSugar.errorMessage',
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

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.t('bloodSugar.title')),
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
                languageProvider.t('bloodSugar.header'),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                languageProvider.t('bloodSugar.description'),
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Sugar value input
              TextFormField(
                controller: _sugarController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: languageProvider.t('bloodSugar.label'),
                  hintText: languageProvider.t('bloodSugar.hintValue'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.medical_information),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return languageProvider.t('bloodSugar.required');
                  }
                  final num? sugar = double.tryParse(value);
                  if (sugar == null || sugar <= 0 || sugar > 1000) {
                    return languageProvider.t('bloodSugar.invalid');
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
                            ? languageProvider.t('bloodSugar.manualEntryMode')
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
                        labelText: languageProvider.t('bloodSugar.searchBy'),
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
                languageProvider.t('bloodSugar.symptomsTitle'),
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
                        languageProvider.t('bloodSugar.disclaimer'),
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
      BloodSugarSymptom.confusion,
      BloodSugarSymptom.fainting,
      BloodSugarSymptom.vomiting,
      BloodSugarSymptom.breathingTrouble,
      BloodSugarSymptom.excessiveThirst,
      BloodSugarSymptom.frequentUrination,
      BloodSugarSymptom.fatigue,
      BloodSugarSymptom.blurredVision,
      BloodSugarSymptom.none,
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
              if (symptom == BloodSugarSymptom.none) {
                // If "None" is selected, clear all others
                _selectedSymptoms.clear();
                if (selected) {
                  _selectedSymptoms.add(symptom);
                }
              } else {
                // Remove "None" if selecting other symptoms
                _selectedSymptoms.remove(BloodSugarSymptom.none);
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
    BloodSugarSymptom symptom,
    LanguageProvider languageProvider,
  ) {
    switch (symptom) {
      case BloodSugarSymptom.confusion:
        return languageProvider.t('bloodSugar.symptom.confusion');
      case BloodSugarSymptom.fainting:
        return languageProvider.t('bloodSugar.symptom.fainting');
      case BloodSugarSymptom.vomiting:
        return languageProvider.t('bloodSugar.symptom.vomiting');
      case BloodSugarSymptom.breathingTrouble:
        return languageProvider.t('bloodSugar.symptom.breathingTrouble');
      case BloodSugarSymptom.unconscious:
        return languageProvider.t('bloodSugar.symptom.unconscious');
      case BloodSugarSymptom.excessiveThirst:
        return languageProvider.t('bloodSugar.symptom.excessiveThirst');
      case BloodSugarSymptom.frequentUrination:
        return languageProvider.t('bloodSugar.symptom.frequentUrination');
      case BloodSugarSymptom.fatigue:
        return languageProvider.t('bloodSugar.symptom.fatigue');
      case BloodSugarSymptom.blurredVision:
        return languageProvider.t('bloodSugar.symptom.blurredVision');
      case BloodSugarSymptom.none:
        return languageProvider.t('bloodSugar.symptom.none');
    }
  }

  bool _isSevereSymptom(BloodSugarSymptom symptom) {
    return symptom == BloodSugarSymptom.confusion ||
        symptom == BloodSugarSymptom.fainting ||
        symptom == BloodSugarSymptom.vomiting ||
        symptom == BloodSugarSymptom.breathingTrouble ||
        symptom == BloodSugarSymptom.unconscious;
  }
}
