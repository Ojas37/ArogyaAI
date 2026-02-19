import 'package:arogyaai_app/models/spo2_reading.dart';
import 'package:arogyaai_app/screens/spo2_result_screen.dart';
import 'package:arogyaai_app/services/spo2_classifier.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../services/location_service.dart';
import '../services/geocoding_service.dart';

class SpO2CheckScreen extends StatefulWidget {
  const SpO2CheckScreen({super.key});

  @override
  State<SpO2CheckScreen> createState() => _SpO2CheckScreenState();
}

class _SpO2CheckScreenState extends State<SpO2CheckScreen> {
  final _formKey = GlobalKey<FormState>();
  final _spo2Controller = TextEditingController();
  final _placeController = TextEditingController();
  final Set<Spo2Symptom> _selectedSymptoms = {};
  Position? _currentPosition;
  bool _isLoading = false;
  bool _isSearchingPlace = false;
  bool _useManualLocation = false;
  double? _selectedLatitude;
  double? _selectedLongitude;
  String? _selectedPlaceName;
  String _locationType = 'City';
  bool _locationAcquired = false;

  @override
  void dispose() {
    _spo2Controller.dispose();
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
    try {
      final pos = await LocationService.getCurrentLocation();
      if (pos != null && mounted) {
        setState(() {
          _selectedLatitude = pos.latitude;
          _selectedLongitude = pos.longitude;
          _selectedPlaceName = 'Current Location';
          _locationAcquired = true;
          _currentPosition = pos;
        });
      }
    } catch (e) {
      // handle error
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _classifyAndNavigate() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_currentPosition == null && !_useManualLocation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please get your location first.')),
      );
      return;
    }

    if (_useManualLocation && !_locationAcquired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please search and select a location.')),
      );
      return;
    }

    final spo2 = int.parse(_spo2Controller.text);
    final result = Spo2Classifier.classifySpo2(spo2, _selectedSymptoms);

    Position position;
    if (_useManualLocation) {
      position = Position(
        latitude: _selectedLatitude!,
        longitude: _selectedLongitude!,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    } else {
      position = _currentPosition!;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Spo2ResultScreen(
          result: result,
          position: position,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Oxygen Level (SpO₂)'),
        backgroundColor: Colors.cyan,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.cyan.shade50,
              Colors.white,
            ],
          ),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.cyan,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Icon(
                        Icons.air,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(width: 20),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Check Your SpO₂ Level',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Enter your oxygen saturation reading and any symptoms',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _spo2Controller,
                  decoration: InputDecoration(
                    labelText: 'SpO₂ (%)',
                    prefixIcon: const Icon(Icons.air, color: Colors.cyan),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Colors.cyan, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.isEmpty
                      ? languageProvider.t('errors.invalidInput')
                      : null,
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle,
                          size: 14, color: Colors.green.shade700),
                      const SizedBox(width: 6),
                      Text(
                        'Normal: 95-100%',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Your Location:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
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
                                      ? 'Enter location manually'
                                      : 'Using GPS location',
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
                      color: _locationAcquired
                          ? Colors.green.shade50
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: _locationAcquired
                              ? Colors.green.shade200
                              : Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _locationAcquired
                              ? Icons.location_on
                              : Icons.location_off,
                          color:
                              _locationAcquired ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _locationAcquired
                                ? 'Location acquired'
                                : 'Location not acquired',
                            style: TextStyle(
                              color: _locationAcquired
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.cyan.shade400, Colors.cyan.shade600],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyan.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _getCurrentLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.my_location, color: Colors.white),
                      label: Text(
                        _isLoading
                            ? 'Getting Location...'
                            : 'Get Current Location',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // Symptoms section
                const Text(
                  'Symptoms (select all that apply):',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                _buildSymptomChips(),
                const SizedBox(height: 32),
                // Submit button
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.cyan.shade400, Colors.cyan.shade600],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyan.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _classifyAndNavigate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
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
                            'Check SpO₂ Now',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

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
                          'This tool provides general health information and should not replace professional medical advice.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSymptomChips() {
    final symptoms = {
      'Shortness of Breath': Spo2Symptom.shortnessOfBreath,
      'Fast Heartbeat': Spo2Symptom.fastHeartbeat,
      'Coughing': Spo2Symptom.coughing,
      'Wheezing': Spo2Symptom.wheezing,
      'Chest Pain': Spo2Symptom.chestPain,
      'Confusion': Spo2Symptom.confusion,
      'Blue Lips/Face': Spo2Symptom.blueLips,
      'None': Spo2Symptom.none,
    };

    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: symptoms.entries.map((entry) {
        final isSelected = _selectedSymptoms.contains(entry.value);
        return FilterChip(
          label: Text(entry.key),
          selected: isSelected,
          onSelected: (bool selected) {
            setState(() {
              if (selected) {
                if (entry.value == Spo2Symptom.none) {
                  _selectedSymptoms.clear();
                  _selectedSymptoms.add(Spo2Symptom.none);
                } else {
                  _selectedSymptoms.remove(Spo2Symptom.none);
                  _selectedSymptoms.add(entry.value);
                }
              } else {
                _selectedSymptoms.remove(entry.value);
              }
            });
          },
          selectedColor: Colors.teal.withOpacity(0.3),
        );
      }).toList(),
    );
  }
}
