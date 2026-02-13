import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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

  String _getHintText() {
    switch (_locationType) {
      case 'City':
        return 'e.g., Satara, Mumbai, Pune';
      case 'Village':
        return 'e.g., Karad, Wai, Panchgani';
      case 'Pin Code':
        return 'e.g., 415002, 411001';
      case 'Taluka':
        return 'e.g., Satara, Karad, Phaltan';
      default:
        return 'Enter location';
    }
  }

  String _getLocationTip() {
    switch (_locationType) {
      case 'City':
        return 'Tip: Enter your city name like "Satara", "Mumbai", etc.';
      case 'Village':
        return 'Tip: Enter your village name, you can also add taluka for better results';
      case 'Pin Code':
        return 'Tip: Enter 6-digit postal pin code of your area';
      case 'Taluka':
        return 'Tip: Enter taluka/tehsil name like "Satara", "Karad", etc.';
      default:
        return '';
    }
  }

  Future<void> _searchPlace() async {
    if (_placeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a $_locationType'),
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
            content: Text('Found: ${result['displayName']}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location not found. Try a different name.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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
          const SnackBar(
            content: Text('Location acquired successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Could not get location: $e';

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
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.location_off, color: Colors.orange),
                SizedBox(width: 8),
                Text('Location Services Disabled'),
              ],
            ),
            content: const Text(
              'Location services are turned off. Please enable them to find nearby medical facilities.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _showPermissionDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Permission Required'),
          ],
        ),
        content: const Text(
          'Location permission is required to find nearby medical facilities. Please grant permission in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              LocationService.openAppSettings();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            child: const Text('Open Settings'),
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
            const SnackBar(
              content: Text('Please get your location first'),
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
          SnackBar(content: Text('Error: $e')),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blood Sugar Check'),
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
              const Text(
                'Check Your Blood Sugar',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your current blood sugar reading and any symptoms you\'re experiencing',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Sugar value input
              TextFormField(
                controller: _sugarController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Blood Sugar (mg/dL)',
                  hintText: 'Enter value, e.g., 120',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.medical_information),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your blood sugar reading';
                  }
                  final num? sugar = double.tryParse(value);
                  if (sugar == null || sugar <= 0 || sugar > 1000) {
                    return 'Please enter a valid value (1-1000 mg/dL)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Location section
              const Text(
                'Your Location:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                      title: const Text('Enter location manually'),
                      subtitle: Text(
                        _useManualLocation
                            ? 'Manual entry mode'
                            : 'Using GPS location',
                        style: const TextStyle(fontSize: 12),
                      ),
                      value: _useManualLocation,
                      activeThumbColor: Colors.teal,
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
                                    ? 'Location: ${_selectedLatitude!.toStringAsFixed(4)}, ${_selectedLongitude!.toStringAsFixed(4)}'
                                    : 'Location not acquired',
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
                          label: Text(_isLoading
                              ? 'Getting location...'
                              : 'Get Current Location'),
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
                      initialValue: _locationType,
                      decoration: const InputDecoration(
                        labelText: 'Search By',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.map),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'City', child: Text('City')),
                        DropdownMenuItem(
                            value: 'Village', child: Text('Village')),
                        DropdownMenuItem(
                            value: 'Pin Code', child: Text('Pin Code')),
                        DropdownMenuItem(
                            value: 'Taluka', child: Text('Taluka')),
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
                        labelText: 'Enter $_locationType',
                        hintText: _getHintText(),
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
                      label: const Text('Search Location'),
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
                      _getLocationTip(),
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              const SizedBox(height: 24),

              // Symptoms section
              const Text(
                'Symptoms (select all that apply):',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildSymptomChips(),
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
                    : const Text(
                        'Check Now',
                        style: TextStyle(fontSize: 18),
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
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This tool provides guidance only and does not replace professional medical care.',
                        style: TextStyle(fontSize: 12),
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

  Widget _buildSymptomChips() {
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
        final label = _getSymptomLabel(symptom);

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

  String _getSymptomLabel(BloodSugarSymptom symptom) {
    switch (symptom) {
      case BloodSugarSymptom.confusion:
        return 'Confusion';
      case BloodSugarSymptom.fainting:
        return 'Fainting';
      case BloodSugarSymptom.vomiting:
        return 'Vomiting';
      case BloodSugarSymptom.breathingTrouble:
        return 'Breathing Trouble';
      case BloodSugarSymptom.unconscious:
        return 'Unconscious';
      case BloodSugarSymptom.excessiveThirst:
        return 'Excessive Thirst';
      case BloodSugarSymptom.frequentUrination:
        return 'Frequent Urination';
      case BloodSugarSymptom.fatigue:
        return 'Fatigue';
      case BloodSugarSymptom.blurredVision:
        return 'Blurred Vision';
      case BloodSugarSymptom.none:
        return 'No Symptoms';
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
