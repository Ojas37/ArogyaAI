import 'package:flutter/material.dart';
import '../services/bmi_classifier.dart';
import '../services/location_service.dart';
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
  String _locationType = 'City';

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
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

  void _classifyBMI() {
    if (!_formKey.currentState!.validate()) return;
    final weight = double.tryParse(_weightController.text);
    final height = double.tryParse(_heightController.text);
    if (weight == null || height == null || height == 0) return;
    final bmi = weight / ((height / 100) * (height / 100));
    final level = BMIClassifier.classify(bmi);
    final status = BMIClassifier.statusLabel(level);
    final advice = BMIClassifier.advice(level);
    // TODO: Show result UI with color/status/advice
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BMI Check')),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _weightController,
              decoration: const InputDecoration(labelText: 'Weight (kg)'),
              keyboardType: TextInputType.number,
              validator: (v) => v == null || v.isEmpty ? 'Enter weight' : null,
            ),
            TextFormField(
              controller: _heightController,
              decoration: const InputDecoration(labelText: 'Height (cm)'),
              keyboardType: TextInputType.number,
              validator: (v) => v == null || v.isEmpty ? 'Enter height' : null,
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
              onPressed: _classifyBMI,
              child: const Text('Check BMI Status'),
            ),
            // TODO: Show result/status/advice UI
          ],
        ),
      ),
    );
  }
}
