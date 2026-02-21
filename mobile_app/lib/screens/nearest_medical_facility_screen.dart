import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/location_service.dart';
import '../services/overpass_service.dart';
import '../models/medical_facility.dart';
import '../services/geocoding_service.dart';

class NearestMedicalFacilityScreen extends StatefulWidget {
  const NearestMedicalFacilityScreen({super.key});

  @override
  State<NearestMedicalFacilityScreen> createState() =>
      _NearestMedicalFacilityScreenState();
}

class _NearestMedicalFacilityScreenState
    extends State<NearestMedicalFacilityScreen> {
  bool _isLoading = false;
  bool _isSearchingPlace = false;
  bool _useManualLocation = false;
  double? _selectedLatitude;
  double? _selectedLongitude;
  String? _selectedPlaceName;
  String _locationType = 'City';
  final _placeController = TextEditingController();
  List<MedicalFacility> _facilities = [];
  String? _error;

  @override
  void dispose() {
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
      String searchQuery = _placeController.text;
      if (_locationType == 'Pin Code') {
        searchQuery += ', India';
      } else if (_locationType == 'Taluka') {
        searchQuery += ', Maharashtra, India';
      }
      final result = await GeocodingService.searchPlace(searchQuery);
      // Only accept results in India
      if (result != null &&
          mounted &&
          (result['displayName']?.toLowerCase().contains('india') ?? false)) {
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
            content: Text(
                'Location not found or not in India. Try a different name.'),
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
      bool serviceEnabled = await LocationService.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location services are disabled.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      final position = await LocationService.getCurrentLocationWithTimeout(
          timeout: const Duration(seconds: 10));
      if (position != null && mounted) {
        setState(() {
          _selectedLatitude = position.latitude;
          _selectedLongitude = position.longitude;
          _selectedPlaceName = 'Current Location';
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not get location: $e'),
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

  Future<void> _fetchFacilities() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _facilities = [];
    });
    try {
      double? latitude = _selectedLatitude;
      double? longitude = _selectedLongitude;
      if (latitude == null || longitude == null) {
        setState(() {
          _error = 'Please get your location first.';
          _isLoading = false;
        });
        return;
      }
      // Only search for pharmacies (medical stores)
      // Increase radius for rural areas (20km)
      final facilities = await OverpassService.searchNearbyFacilities(
        latitude: latitude,
        longitude: longitude,
        facilityType: 'pharmacy',
        limit: 100,
        radiusMeters: 20000,
      );
      // No filtering - OSM entries may not have full address
      setState(() {
        _facilities = facilities;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Pharmacies'),
        backgroundColor: Colors.green[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                    activeColor: Colors.teal,
                    onChanged: (value) {
                      setState(() => _useManualLocation = value);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (!_useManualLocation)
              Container(
                decoration: BoxDecoration(
                  color: _selectedLatitude != null
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedLatitude != null
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
                                    strokeWidth: 2, color: Colors.white),
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
                  DropdownButtonFormField<String>(
                    value: _locationType,
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
                      DropdownMenuItem(value: 'Taluka', child: Text('Taluka')),
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
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2)),
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
                ],
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _fetchFacilities,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text('Find Nearby Pharmacies'),
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Could not load facilities: $_error',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              )
            else if (_facilities.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                          'No pharmacies found nearby. Try searching manually in Google Maps.'),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _facilities.length,
                itemBuilder: (context, index) {
                  final facility = _facilities[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.local_hospital,
                                  color: Colors.teal, size: 32),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      facility.name,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    if (facility.distanceInKm != null)
                                      Text(
                                        '${facility.distanceInKm!.toStringAsFixed(1)} km away',
                                        style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 14),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (facility.address != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.location_on,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    facility.address!,
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _openInMaps(facility,
                                      startNavigation: false),
                                  icon: const Icon(Icons.location_on, size: 18),
                                  label: const Text('View'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey.shade700,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton.icon(
                                  onPressed: () => _openInMaps(facility,
                                      startNavigation: true),
                                  icon: const Icon(Icons.directions, size: 18),
                                  label: const Text('Start Navigation'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openInMaps(MedicalFacility facility,
      {bool startNavigation = false}) async {
    String url;
    if (startNavigation) {
      url = facility.getDirectionsUrl(
        originLat: _selectedLatitude ?? 0,
        originLng: _selectedLongitude ?? 0,
      );
    } else {
      url = facility.googleMapsUrl;
    }
    final uri = Uri.parse(url);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps')),
        );
      }
    }
  }
}
