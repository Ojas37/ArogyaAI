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
  bool _isLoading = false;
  String? _error;
  bool _facilitiesLoaded = false;

  bool get _isEmergency => widget.result.level == BPLevel.red;

  @override
  void initState() {
    super.initState();
    // Auto-load for emergency cases only
    if (_isEmergency) {
      _loadFacilities();
    }
  }

  Future<void> _loadFacilities() async {
    if (_facilitiesLoaded) return;
    
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
          _facilitiesLoaded = true;
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

  Future<void> _callEmergencyHelpline() async {
    const number = '102';
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not start a call right now.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blood Pressure Result'),
        backgroundColor: widget.result.color,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildResultHeader(),
            const SizedBox(height: 16),
            _buildMessageCard(),
            const SizedBox(height: 16),
            if (_isEmergency) _buildHelplineButton(),
            if (_isEmergency) const SizedBox(height: 16),
            if (!_facilitiesLoaded && !_isLoading) _buildFindHospitalsButton(),
            if (_isLoading || _facilities != null) _buildFacilitiesSection(),
            const SizedBox(height: 16),
            _buildDisclaimer(),
          ],
        ),
      ),
    );
  }

  Widget _buildResultHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.result.color.withOpacity(0.2),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: widget.result.color.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.result.color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getLevelIcon(),
              size: 36,
              color: widget.result.color,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.result.status,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: widget.result.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'BP classification based on your inputs',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        widget.result.message,
        style: const TextStyle(fontSize: 16, height: 1.4),
      ),
    );
  }

  Widget _buildHelplineButton() {
    return ElevatedButton.icon(
      onPressed: _callEmergencyHelpline,
      style: ElevatedButton.styleFrom(
        backgroundColor: _isEmergency ? Colors.red.shade600 : Colors.orange.shade600,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(_isEmergency ? Icons.emergency : Icons.phone_in_talk),
      label: Text(_isEmergency ? 'Call Ambulance (102)' : 'Call Health Helpline (102)'),
    );
  }

  Widget _buildFindHospitalsButton() {
    // Use appropriate color based on BP level
    Color buttonColor;
    if (widget.result.level == BPLevel.red) {
      buttonColor = Colors.red.shade600;
    } else if (widget.result.level == BPLevel.yellow) {
      buttonColor = Colors.orange.shade600;
    } else {
      buttonColor = Colors.blue.shade600; // Normal/green level
    }

    return ElevatedButton.icon(
      onPressed: _loadFacilities,
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(Icons.local_hospital, size: 24),
      label: const Text(
        'Find Nearby Hospitals',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildFacilitiesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.local_hospital, color: Colors.teal),
              SizedBox(width: 8),
              Text(
                'Nearby Medical Facilities',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_error != null)
            Column(
              children: [
                Text(
                  'Could not load facilities: $_error',
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _loadFacilities,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            )
          else if (_facilities == null || _facilities!.isEmpty)
            const Text('No facilities found within 10 km radius.')
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _facilities!.length,
              itemBuilder: (context, i) {
                return _buildFacilityCard(_facilities![i]);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFacilityCard(MedicalFacility facility) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(facility.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            if (facility.distanceInKm != null)
              Text('${facility.distanceInKm!.toStringAsFixed(1)} km away', style: const TextStyle(color: Colors.grey)),
            if (facility.address != null)
              Text(facility.address!, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openInMaps(facility),
                    icon: const Icon(Icons.location_on),
                    label: const Text('View'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _startNavigation(facility),
                    icon: const Icon(Icons.navigation),
                    label: const Text('Navigate'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.info_outline, color: Colors.orange),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'This assessment is informational only. Please consult a licensed medical professional for diagnosis and treatment.',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getLevelIcon() {
    switch (widget.result.level) {
      case BPLevel.red:
        return Icons.emergency;
      case BPLevel.yellow:
        return Icons.warning_rounded;
      case BPLevel.green:
        return Icons.check_circle;
    }
  }
}
