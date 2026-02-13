import 'package:flutter/material.dart';
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

  @override
  void dispose() {
    _tempController.dispose();
    _placeController.dispose();
    super.dispose();
  }

  Future<void> _searchLocation() async {
    setState(() { _isSearchingPlace = true; });
    final place = await GeocodingService.searchPlace(_placeController.text, _locationType);
    if (place != null) {
      setState(() {
        _selectedLatitude = place.latitude;
        _selectedLongitude = place.longitude;
        _selectedPlaceName = place.displayName;
        _locationAcquired = true;
      });
    }
    setState(() { _isSearchingPlace = false; });
  }

  Future<void> _getCurrentLocation() async {
    setState(() { _isLoading = true; });
    final pos = await LocationService.getCurrentPosition();
    if (pos != null) {
      setState(() {
        _selectedLatitude = pos.latitude;
        _selectedLongitude = pos.longitude;
        _selectedPlaceName = 'Current Location';
        _locationAcquired = true;
      });
    }
    setState(() { _isLoading = false; });
  }

  Future<void> _findFacilities() async {
    if (_selectedLatitude == null || _selectedLongitude == null) return;
    setState(() { _isLoading = true; });
    final facilities = await OverpassService.searchNearbyFacilities(
      latitude: _selectedLatitude!,
      longitude: _selectedLongitude!,
      facilityType: 'hospital,clinic',
      limit: 50,
      radiusMeters: 20000,
    );
    setState(() { _isLoading = false; });
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
    final status = TemperatureClassifier.statusLabel(level);
    final advice = TemperatureClassifier.advice(level);
    // TODO: Show result UI with color/status/advice
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Temperature Check')),
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
                decoration: const InputDecoration(labelText: 'Temperature (°C)'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Enter temperature' : null,
              ),
              const SizedBox(height: 20),
              Text('Your Location:', style: Theme.of(context).textTheme.subtitle1),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() { _useManualLocation = !_useManualLocation; });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(_useManualLocation ? Icons.edit_location_alt : Icons.my_location, color: Colors.teal),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(_useManualLocation ? 'Enter location manually' : 'Using GPS location',
                                style: const TextStyle(fontSize: 16)),
                            ),
                            Switch(
                              value: _useManualLocation,
                              onChanged: (val) {
                                setState(() { _useManualLocation = val; });
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
                  items: const [
                    DropdownMenuItem(value: 'City', child: Text('City')),
                    DropdownMenuItem(value: 'Village', child: Text('Village')),
                    DropdownMenuItem(value: 'Pin Code', child: Text('Pin Code')),
                    DropdownMenuItem(value: 'Taluka', child: Text('Taluka')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() { _locationType = val; });
                  },
                ),
                TextFormField(
                  controller: _placeController,
                  decoration: InputDecoration(labelText: 'Enter $_locationType'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _isSearchingPlace ? null : _searchLocation,
                  child: _isSearchingPlace ? const CircularProgressIndicator() : const Text('Search Location'),
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
                      Expanded(child: Text(_locationAcquired ? 'Location acquired' : 'Location not acquired', style: const TextStyle(color: Colors.orange))),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _getCurrentLocation,
                  icon: const Icon(Icons.my_location),
                  label: _isLoading ? const CircularProgressIndicator() : const Text('Get Current Location'),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _findFacilities,
                child: _isLoading ? const CircularProgressIndicator() : const Text('Find Nearby Medical Facilities'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _classifyTemperature,
                child: const Text('Check Temperature Status'),
              ),
              // TODO: Show result/status/advice UI
            ],
          ),
        ),
      ),
    );
  }
}
