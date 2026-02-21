import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../models/blood_sugar_reading.dart';
import '../models/medical_facility.dart';
import '../services/blood_sugar_classifier.dart';
import '../services/overpass_service.dart';
import '../providers/language_provider.dart';

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
  List<MedicalFacility> hospitals = [];
  bool isLoadingHospitals = false;
  String? errorMessage;
  bool hospitalsFetched = false;

  @override
  void initState() {
    super.initState();
    
    // Auto-fetch hospitals for emergency cases
    if (BloodSugarClassifier.shouldAutoFetchHospitals(widget.reading.level)) {
      _fetchHospitals();
    }
  }

  Future<void> _fetchHospitals() async {
    if (hospitalsFetched) return;

    setState(() {
      isLoadingHospitals = true;
      errorMessage = null;
    });

    try {
      final fetchedHospitals = await OverpassService.searchNearbyFacilities(
        latitude: widget.latitude,
        longitude: widget.longitude,
        facilityType: 'hospital,clinic',
        limit: 10,
        radiusMeters: 10000,
      );

      setState(() {
        hospitals = fetchedHospitals;
        isLoadingHospitals = false;
        hospitalsFetched = true;
      });

      if (hospitals.isEmpty) {
        setState(() {
          errorMessage = 'No hospitals found within 10 km radius.';
        });
      }
    } catch (e) {
      setState(() {
        isLoadingHospitals = false;
        errorMessage = e.toString();
      });
    }
  }

  Future<void> _callEmergency() async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final number = BloodSugarClassifier.getEmergencyNumber(country: 'IN');
    final uri = Uri.parse('tel:$number');
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              languageProvider.t('bloodSugarResults.cannotCallEmergency', params: {'number': number}),
            ),
          ),
        );
      }
    }
  }

  Future<void> _openInMaps(MedicalFacility facility, {bool startNavigation = false}) async {
    final String url;

    if (startNavigation) {
      url = facility.getDirectionsUrl(
        originLat: widget.latitude,
        originLng: widget.longitude,
      );
    } else {
      url = facility.googleMapsUrl;
    }

    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(languageProvider.t('bloodSugarResults.cannotOpenMaps'))),
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
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.t('bloodSugarResults.title')),
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
      color: _getLevelColor().withValues(alpha: 0.1),
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
            Builder(
              builder: (context) {
                final languageProvider = Provider.of<LanguageProvider>(context);
                return Text(
                  languageProvider.t(
                    'bloodSugarResults.withSymptoms',
                    params: {'count': widget.reading.symptoms.length.toString()},
                  ),
                  style: const TextStyle(color: Colors.grey),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmergencyWarning() {
    final languageProvider = Provider.of<LanguageProvider>(context);
    
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
          Row(
            children: [
              const Icon(Icons.error, color: Colors.red, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  languageProvider.t('bloodSugarResults.medicalEmergency'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            languageProvider.t('bloodSugarResults.emergencyWarning'),
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _callEmergency,
            icon: const Icon(Icons.phone),
            label: Text(languageProvider.t('bloodSugarResults.callAmbulance')),
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
    final languageProvider = Provider.of<LanguageProvider>(context);
    final shouldShowHospitals =
        BloodSugarClassifier.shouldShowHospitals(widget.reading.level);

    if (!shouldShowHospitals) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            languageProvider.t('bloodSugarResults.nearbyFacilities'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (isLoadingHospitals)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (errorMessage != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          languageProvider.t(
                            'bloodSugarResults.couldNotLoadFacilities',
                            params: {'error': errorMessage!},
                          ),
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _fetchHospitals,
                      icon: const Icon(Icons.refresh),
                      label: Text(languageProvider.t('common.retry')),
                    ),
                  ),
                ],
              ),
            )
          else if (!hospitalsFetched)
            ElevatedButton.icon(
              onPressed: _fetchHospitals,
              style: ElevatedButton.styleFrom(
                backgroundColor: _getLevelColor() == Colors.green 
                    ? Colors.blue.shade600 
                    : _getLevelColor(),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.local_hospital),
              label: Text(languageProvider.t('bloodSugarResults.nearbyFacilities')),
            )
          else if (hospitals.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      languageProvider.t('bloodSugarResults.noFacilitiesFound'),
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: hospitals.length,
              itemBuilder: (context, index) {
                return _buildFacilityCard(hospitals[index]);
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
                const Icon(Icons.local_hospital, color: Colors.teal, size: 32),
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
                        Builder(
                          builder: (context) {
                            final languageProvider =
                                Provider.of<LanguageProvider>(context);
                            return Text(
                              languageProvider.t(
                                'bloodSugarResults.kmAway',
                                params: {'distance': facility.distanceInKm!.toStringAsFixed(1)},
                              ),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (facility.address != null) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
            if (facility.phone != null && facility.phone!.isNotEmpty) ...[
              const SizedBox(height: 6),
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
            Builder(
              builder: (context) {
                final languageProvider = Provider.of<LanguageProvider>(context);
                return Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openInMaps(facility, startNavigation: false),
                        icon: const Icon(Icons.location_on, size: 18),
                        label: Text(languageProvider.t('bloodSugarResults.view')),
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
                        label: Text(languageProvider.t('bloodSugarResults.startNavigation')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisclaimer() {
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              languageProvider.t('bloodSugarResults.disclaimer'),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
