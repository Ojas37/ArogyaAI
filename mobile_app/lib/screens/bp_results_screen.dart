import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/bp_classifier.dart';
import '../models/medical_facility.dart';
import '../services/overpass_service.dart';

class BPResultsScreen extends StatefulWidget {
  final BPResult result;
  final double latitude;
  final double longitude;
  const BPResultsScreen({super.key, required this.result, required this.latitude, required this.longitude});

  @override
  State<BPResultsScreen> createState() => _BPResultsScreenState();
}

class _BPResultsScreenState extends State<BPResultsScreen> {
  List<MedicalFacility>? _facilities;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFacilities();
  }

  Future<void> _loadFacilities() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final facilities = await OverpassService.searchNearbyFacilities(
        latitude: widget.latitude,
        longitude: widget.longitude,
        facilityType: 'hospital,clinic,pharmacy',
        limit: 100,
        radiusMeters: 10000,
      );
      // Filter to only those within 10km (should already be, but double check)
      final filtered = facilities.where((f) => f.distanceInKm != null && f.distanceInKm! <= 10.0).toList();
      filtered.sort((a, b) => a.distanceInKm!.compareTo(b.distanceInKm!));
      if (mounted) {
        setState(() {
          _facilities = filtered;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _openInMaps(MedicalFacility facility) async {
    final url = facility.googleMapsUrl;
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open maps.')));
    }
  }

  void _startNavigation(MedicalFacility facility) async {
    final url = facility.getDirectionsUrl(
      originLat: widget.latitude,
      originLng: widget.longitude,
    );
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not start navigation.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nearby Medical Facilities')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _facilities == null || _facilities!.isEmpty
                  ? const Center(child: Text('No facilities found nearby.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _facilities!.length,
                      itemBuilder: (context, i) {
                        final f = _facilities![i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(f.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                if (f.distanceInKm != null)
                                  Text('${f.distanceInKm!.toStringAsFixed(1)} km away', style: const TextStyle(color: Colors.grey)),
                                if (f.address != null)
                                  Text(f.address!, style: const TextStyle(color: Colors.black54)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => _openInMaps(f),
                                      icon: const Icon(Icons.location_on),
                                      label: const Text('View'),
                                    ),
                                    const SizedBox(width: 12),
                                    ElevatedButton.icon(
                                      onPressed: () => _startNavigation(f),
                                      icon: const Icon(Icons.navigation),
                                      label: const Text('Start Navigation'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
