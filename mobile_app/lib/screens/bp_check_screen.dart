import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../services/bp_classifier.dart';
import '../services/location_service.dart';
import '../services/geocoding_service.dart';
import '../services/overpass_service.dart';
import 'bp_results_screen.dart';

class BPCheckScreen extends StatefulWidget {
  const BPCheckScreen({super.key});

  @override
  State<BPCheckScreen> createState() => _BPCheckScreenState();
}

class _BPCheckScreenState extends State<BPCheckScreen> {
  final _formKey = GlobalKey<FormState>();
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _placeController = TextEditingController();
  bool _isLoading = false;
  bool _isSearchingPlace = false;
  bool _useManualLocation = false;
  double? _selectedLatitude;
  double? _selectedLongitude;
  String? _selectedPlaceName;
  String _locationType = 'City';
  bool _locationAcquired = false;
  BPResult? _bpResult;

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    _placeController.dispose();
    super.dispose();
  }

  Future<void> _searchLocation() async {
    setState(() {
      _isSearchingPlace = true;
    });
    final place = await GeocodingService.searchPlace(_placeController.text);
    if (place != null) {
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
        timeout: const Duration(seconds: 10));
    if (pos != null) {
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
    // Show facilities or message
    if (facilities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No facilities found nearby.')),
      );
    } else {
      // TODO: Show facility list UI
    }
  }

  void _classifyBP() {
    if (!_formKey.currentState!.validate()) return;
    final systolic = double.tryParse(_systolicController.text);
    final diastolic = double.tryParse(_diastolicController.text);
    if (systolic == null || diastolic == null) return;
    final result = BPClassifier.evaluate(systolic, diastolic);
    setState(() {
      _bpResult = result;
    });
    if (result.level == BPLevel.red) {
      // Emergency: ask for location and show hospital list
      _showEmergencyDialog(result);
    }
  }

  void _showEmergencyDialog(BPResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: result.color),
            const SizedBox(width: 8),
            Text(result.status, style: TextStyle(color: result.color)),
          ],
        ),
        content: Text(result.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToResults();
            },
            style: ElevatedButton.styleFrom(backgroundColor: result.color),
            child: const Text('Find Nearby Hospitals'),
          ),
        ],
      ),
    );
  }

  void _navigateToResults() {
    if (_selectedLatitude != null &&
        _selectedLongitude != null &&
        _bpResult != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BPResultsScreen(
            result: _bpResult!,
            latitude: _selectedLatitude!,
            longitude: _selectedLongitude!,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide your location first.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text(languageProvider.t('vitals.bloodPressure'))),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              TextFormField(
                controller: _systolicController,
                decoration: InputDecoration(
                  labelText: languageProvider.t('vitalsForm.systolicLabel'),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty
                    ? languageProvider.t('errors.invalidInput')
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _diastolicController,
                decoration: InputDecoration(
                  labelText: languageProvider.t('vitalsForm.diastolicLabel'),
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
                onPressed: _classifyBP,
                child: Text(languageProvider.t('vitalsForm.checkNow')),
              ),
              if (_bpResult != null) ...[
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _bpResult!.color.withOpacity(0.15),
                    border: Border.all(color: _bpResult!.color, width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        _bpResult!.level == BPLevel.green
                            ? languageProvider.t('vitalsForm.statusNormal')
                            : _bpResult!.level == BPLevel.yellow
                                ? languageProvider.t('vitalsForm.statusWarning')
                                : languageProvider
                                    .t('vitalsForm.statusEmergency'),
                        style: TextStyle(
                          color: _bpResult!.color,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _bpResult!.level == BPLevel.green
                            ? languageProvider.t('vitalsForm.adviceNormal')
                            : _bpResult!.level == BPLevel.yellow
                                ? languageProvider.t('vitalsForm.adviceMonitor')
                                : languageProvider
                                    .t('vitalsForm.adviceSeekCare'),
                        style: TextStyle(
                          color: _bpResult!.color,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
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
