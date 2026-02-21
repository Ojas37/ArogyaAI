import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/blood_sugar_reading.dart';
import '../models/medical_facility.dart';
import '../services/blood_sugar_classifier.dart';
import '../services/overpass_service.dart';

class BloodSugarResultScreen extends StatefulWidget {
  final double sugarValue;
  final List<BloodSugarSymptom>? symptoms;

  const BloodSugarResultScreen({
    super.key,
    required this.sugarValue,
    this.symptoms,
  });

  @override
  State<BloodSugarResultScreen> createState() => _BloodSugarResultScreenState();
}

class _BloodSugarResultScreenState extends State<BloodSugarResultScreen> {
  late BloodSugarReading result;
  List<MedicalFacility> hospitals = [];
  bool isLoadingHospitals = false;
  String? errorMessage;
  bool hospitalsFetched = false;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    
    // Classify the blood sugar reading
    result = BloodSugarClassifier.getSugarCategory(
      sugarValue: widget.sugarValue,
      symptoms: widget.symptoms,
    );

    // Auto-fetch hospitals for emergency cases
    if (BloodSugarClassifier.shouldAutoFetchHospitals(result.level)) {
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
      // Get current location first
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission permanently denied.');
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Fetch hospitals using OverpassService
      final facilities = await OverpassService.searchNearbyFacilities(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        facilityType: 'hospital,clinic',
        limit: 10,
        radiusMeters: 10000,
      );

      if (mounted) {
        setState(() {
          hospitals = facilities;
          isLoadingHospitals = false;
          hospitalsFetched = true;
        });
      }

      if (hospitals.isEmpty) {
        setState(() {
          errorMessage = 'No hospitals found within 10 km radius.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingHospitals = false;
          errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _callAmbulance() async {
    final emergencyNumber = BloodSugarClassifier.getEmergencyNumber();
    final uri = Uri.parse('tel:$emergencyNumber');
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cannot make call. Please dial $emergencyNumber manually.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openDirections(MedicalFacility facility) async {
    final uri = Uri.parse(facility.googleMapsUrl);
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening maps: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = BloodSugarClassifier.getLevelColor(result.level);
    final icon = BloodSugarClassifier.getIcon(result.level);
    final label = BloodSugarClassifier.getLevelLabel(result.level);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blood Sugar Result'),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Result Card
              _buildResultCard(color, icon, label),
              
              const SizedBox(height: 24),

              // Emergency button (only for emergency cases)
              if (BloodSugarClassifier.shouldShowAmbulanceButton(result.level))
                _buildAmbulanceButton(),

              // Find Hospitals button (show for all levels if not already fetched)
              if (!hospitalsFetched && !isLoadingHospitals)
                _buildFindHospitalsButton(),

              // Loading indicator
              if (isLoadingHospitals)
                _buildLoadingIndicator(),

              // Error message
              if (errorMessage != null && !isLoadingHospitals)
                _buildErrorMessage(),

              // Hospital list
              if (hospitals.isNotEmpty)
                _buildHospitalList(),

              const SizedBox(height: 24),

              // Health tips
              _buildHealthTips(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(Color color, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 64,
              color: color,
            ),
          ),
          const SizedBox(height: 16),

          // Status label
          Text(
            label,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 12),

          // Blood sugar value
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${widget.sugarValue.toStringAsFixed(0)} mg/dL',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Message
          Text(
            result.message,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAmbulanceButton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ElevatedButton.icon(
        onPressed: _callAmbulance,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        icon: const Icon(Icons.local_hospital, size: 28),
        label: const Text(
          'Call Ambulance (102)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildFindHospitalsButton() {
    // Use appropriate color based on sugar level
    Color buttonColor;
    if (result.level == BloodSugarLevel.red) {
      buttonColor = Colors.red.shade600;
    } else if (result.level == BloodSugarLevel.orange) {
      buttonColor = Colors.orange.shade600;
    } else {
      buttonColor = Colors.blue.shade600; // Normal/info color
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ElevatedButton.icon(
        onPressed: _fetchHospitals,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.local_hospital, size: 24),
        label: const Text(
          'Find Nearby Hospitals',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          CircularProgressIndicator(
            color: BloodSugarClassifier.getLevelColor(result.level),
          ),
          const SizedBox(height: 16),
          const Text(
            'Finding nearby hospitals...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              errorMessage!,
              style: TextStyle(
                color: Colors.red.shade900,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHospitalList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.local_hospital,
              color: BloodSugarClassifier.getLevelColor(result.level),
            ),
            const SizedBox(width: 8),
            const Text(
              'Nearby Hospitals (within 10 km)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: hospitals.length,
          itemBuilder: (context, index) {
            return _buildHospitalCard(hospitals[index], index + 1);
          },
        ),
      ],
    );
  }

  Widget _buildHospitalCard(MedicalFacility facility, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Number badge
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: BloodSugarClassifier.getLevelColor(result.level),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$index',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Hospital info
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
                      if (facility.address != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          facility.address!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      
                      // Distance
                      if (facility.distanceInKm != null)
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${facility.distanceInKm!.toStringAsFixed(1)} km',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Get Directions button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openDirections(facility),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BloodSugarClassifier.getLevelColor(result.level),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.directions, size: 18),
                label: const Text('Get Directions'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthTips() {
    List<String> tips;
    IconData tipIcon;
    Color tipColor;

    switch (result.level) {
      case BloodSugarLevel.red:
        tipIcon = Icons.warning;
        tipColor = Colors.red.shade600;
        tips = [
          'Seek immediate medical attention',
          'Do not attempt to drive yourself',
          'Inform family members about your condition',
          'Keep your medical records ready',
        ];
        break;
      case BloodSugarLevel.orange:
        tipIcon = Icons.info;
        tipColor = Colors.orange.shade600;
        tips = [
          'Consult a doctor within 24 hours',
          'Monitor your blood sugar regularly',
          'Avoid sugary foods and drinks',
          'Stay hydrated with water',
          'Review your medication with your doctor',
        ];
        break;
      case BloodSugarLevel.green:
        tipIcon = Icons.check_circle;
        tipColor = Colors.green.shade600;
        tips = [
          'Maintain a balanced diet',
          'Exercise regularly (30 mins/day)',
          'Monitor blood sugar periodically',
          'Stay hydrated',
          'Get adequate sleep (7-8 hours)',
        ];
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(tipIcon, color: tipColor),
              const SizedBox(width: 8),
              const Text(
                'Health Tips',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...tips.map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: tipColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tip,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
