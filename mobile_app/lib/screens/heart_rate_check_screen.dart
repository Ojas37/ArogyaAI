import 'package:flutter/material.dart';
import '../services/heart_rate_classifier.dart';
import '../services/location_service.dart';
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
  String _locationType = 'City';

  @override
  void dispose() {
    _bpmController.dispose();
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
      });
    }
    setState(() { _isSearchingPlace = false; });
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

  void _classifyHeartRate() {
    if (!_formKey.currentState!.validate()) return;
    final bpm = int.tryParse(_bpmController.text);
    if (bpm == null) return;
    final level = HeartRateClassifier.classify(bpm);
    final status = HeartRateClassifier.statusLabel(level);
    final advice = HeartRateClassifier.advice(level);
    // TODO: Show result UI with color/status/advice
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Heart Rate Check')),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _bpmController,
              decoration: const InputDecoration(labelText: 'Heart Rate (bpm)'),
              keyboardType: TextInputType.number,
              validator: (v) => v == null || v.isEmpty ? 'Enter heart rate' : null,
            ),
            TextFormField(
              controller: _placeController,
              decoration: const InputDecoration(labelText: 'Enter location'),
            ),
            ElevatedButton(
              onPressed: _searchLocation,
              child: _isSearchingPlace ? const CircularProgressIndicator() : const Text('Search Location'),
            ),
            ElevatedButton(
              onPressed: _findFacilities,
              child: _isLoading ? const CircularProgressIndicator() : const Text('Find Nearby Medical Facilities'),
            ),
            ElevatedButton(
              onPressed: _classifyHeartRate,
              child: const Text('Check Heart Rate Status'),
            ),
            // TODO: Show result/status/advice UI
          ],
        ),
      ),
    );
  }
}
