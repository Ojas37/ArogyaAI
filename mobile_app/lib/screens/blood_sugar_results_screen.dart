import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/blood_sugar_reading.dart';
import '../models/medical_facility.dart';
import '../services/blood_sugar_classifier.dart';
import '../services/overpass_service.dart';

class BloodSugarResultsScreen extends StatefulWidget {
  final BloodSugarReading reading;
  final double latitude;
  final double longitude;

  const BloodSugarResultsScreen({
    super.key,
    required this.reading,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<BloodSugarResultsScreen> createState() =>
      _BloodSugarResultsScreenState();
}

class _BloodSugarResultsScreenState extends State<BloodSugarResultsScreen> {
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
        facilityType: widget.reading.facilityType,
        limit: 5,
      );

      if (mounted) {
        setState(() {
          _facilities = facilities;
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

  Future<void> _callEmergency() async {
    final number = BloodSugarClassifier.getEmergencyNumber(country: 'IN');
    final uri = Uri.parse('tel:$number');
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot call $number')),
        );
      }
    }
  }

  Future<void> _openInMaps(MedicalFacility facility, {bool startNavigation = false}) async {
    String url;
    
    if (startNavigation) {
      // Open with directions from current location
      url = facility.getDirectionsUrl(
        originLat: widget.latitude,
        originLng: widget.longitude,
      );
    } else {
      // Just show the location
      url = facility.googleMapsUrl;
    }
    
    final uri = Uri.parse(url);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot open Google Maps')),
        );
      }
    }
  }

  Color _getLevelColor() {
    switch (widget.reading.level) {
      case BloodSugarLevel.red:
        return Colors.red;
      case BloodSugarLevel.orange:
        return Colors.orange;
      case BloodSugarLevel.green:
        return Colors.green;
    }
  }

  IconData _getLevelIcon() {
    switch (widget.reading.level) {
      case BloodSugarLevel.red:
        return Icons.emergency;
      case BloodSugarLevel.orange:
        return Icons.warning;
      case BloodSugarLevel.green:
        return Icons.check_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blood Sugar Results'),
        backgroundColor: _getLevelColor(),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status header
            _buildStatusHeader(),

            // Emergency warning (RED only)
            if (widget.reading.isEmergency) _buildEmergencyWarning(),

            // Message
            _buildMessage(),

            // Facilities list
            _buildFacilitiesList(),

            // Disclaimer
            _buildDisclaimer(),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: _getLevelColor().withOpacity(0.1),
      child: Column(
        children: [
          Icon(
            _getLevelIcon(),
            size: 64,
            color: _getLevelColor(),
          ),
          const SizedBox(height: 16),
          Text(
            BloodSugarClassifier.getLevelLabel(widget.reading.level),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: _getLevelColor(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.reading.sugarValue.toStringAsFixed(0)} mg/dL',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (widget.reading.symptoms.isNotEmpty &&
              widget.reading.symptoms.first != BloodSugarSymptom.none) ...[
            const SizedBox(height: 8),
            Text(
              'With ${widget.reading.symptoms.length} symptom(s)',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmergencyWarning() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red, width: 2),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.error, color: Colors.red, size: 32),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'MEDICAL EMERGENCY',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Your reading is very high and may be life-threatening. Please seek emergency care NOW.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _callEmergency,
            icon: const Icon(Icons.phone),
            label: const Text('Call Ambulance (102)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        widget.reading.message,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildFacilitiesList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nearby Medical Facilities',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
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
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadFacilities,
                  ),
                ],
              ),
            )
          else if (_facilities == null || _facilities!.isEmpty)
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
                      'No facilities found nearby. Try searching manually in Google Maps.',
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _facilities!.length,
              itemBuilder: (context, index) {
                return _buildFacilityCard(_facilities![index]);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFacilityCard(MedicalFacility facility) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getFacilityIcon(facility.type),
                  color: Colors.teal,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        facility.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (facility.distanceInKm != null)
                        Text(
                          '${facility.distanceInKm!.toStringAsFixed(1)} km away',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
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
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      facility.address!,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ],
            if (facility.phone != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.phone, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    facility.phone!,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openInMaps(facility, startNavigation: false),
                    icon: const Icon(Icons.location_on, size: 18),
                    label: const Text('View'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => _openInMaps(facility, startNavigation: true),
                    icon: const Icon(Icons.directions, size: 18),
                    label: const Text('Start Navigation'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFacilityIcon(String type) {
    switch (type.toLowerCase()) {
      case 'hospital':
        return Icons.local_hospital;
      case 'clinic':
        return Icons.medical_services;
      case 'pharmacy':
        return Icons.medication;
      default:
        return Icons.business;
    }
  }

  Widget _buildDisclaimer() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
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
    );
  }
}
