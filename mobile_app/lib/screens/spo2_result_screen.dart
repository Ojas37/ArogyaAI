import 'package:arogyaai_app/models/hospital.dart';
import 'package:arogyaai_app/services/hospital_finder_service.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/spo2_reading.dart';

class Spo2ResultScreen extends StatefulWidget {
  final Spo2Reading result;
  final Position position;

  const Spo2ResultScreen(
      {super.key, required this.result, required this.position});

  @override
  State<Spo2ResultScreen> createState() => _Spo2ResultScreenState();
}

class _Spo2ResultScreenState extends State<Spo2ResultScreen> {
  List<Hospital> _hospitals = [];
  bool _isLoading = false;
  String? _error;
  bool _hospitalsFetched = false;

  @override
  void initState() {
    super.initState();
    if (widget.result.category == 'Emergency') {
      _fetchHospitals();
    }
  }

  Future<void> _fetchHospitals() async {
    if (_hospitalsFetched) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final hospitals = await HospitalFinderService.findNearbyHospitals(
        latitude: widget.position.latitude,
        longitude: widget.position.longitude,
      );
      if (mounted) {
        setState(() {
          _hospitals = hospitals;
          _hospitalsFetched = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to find hospitals: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _callAmbulance() async {
    final uri = Uri.parse('tel:102');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not call 102. Please dial manually.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SpO₂ Result'),
        backgroundColor: widget.result.color,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 24),
            if (widget.result.category == 'Emergency') _buildEmergencyUI(),
            if (widget.result.category == 'Medium') _buildMediumUI(),
            if (_isLoading)
              const Center(child: CircularProgressIndicator()),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            if (_hospitals.isNotEmpty) _buildHospitalList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: widget.result.color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.result.color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(widget.result.icon,
                  size: 48, color: widget.result.color),
            ),
            const SizedBox(height: 16),
            Text(
              widget.result.title,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: widget.result.color),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.result.spo2}%',
              style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: widget.result.color),
            ),
            const SizedBox(height: 12),
            Text(
              widget.result.message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyUI() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _callAmbulance,
          icon: const Icon(Icons.phone),
          label: const Text('Call Ambulance (102)'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMediumUI() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _fetchHospitals,
          icon: const Icon(Icons.local_hospital),
          label: const Text('Find Nearby Hospitals'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildHospitalList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nearby Medical Facilities',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _hospitals.length,
          itemBuilder: (context, index) {
            final hospital = _hospitals[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const Icon(Icons.local_hospital, color: Colors.teal),
                title: Text(hospital.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hospital.distance != null)
                      Text('${hospital.distance!.toStringAsFixed(1)} km away'),
                    if (hospital.rating != null)
                      Text('Rating: ${hospital.rating}'),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.directions),
                  onPressed: () async {
                    final url =
                        'https://www.google.com/maps/dir/?api=1&destination=${hospital.latitude},${hospital.longitude}';
                    if (await canLaunch(url)) {
                      await launch(url);
                    }
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
