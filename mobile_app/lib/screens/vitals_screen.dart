import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import 'blood_sugar_check_screen.dart';
import 'bp_check_screen.dart';
import 'cholesterol_check_screen.dart';
import 'heart_rate_check_screen.dart';
import 'spo2_check_screen.dart';
import 'temperature_check_screen.dart';

class VitalsScreen extends StatefulWidget {
  const VitalsScreen({super.key});

  @override
  State<VitalsScreen> createState() => _VitalsScreenState();
}

class _VitalsScreenState extends State<VitalsScreen> {
  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.t('vitals.title')),
        backgroundColor: Colors.blue,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.monitor_heart,
                        color: Colors.blue.shade700,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            languageProvider.t('vitals.title'),
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            languageProvider.t('vitals.trackMetrics'),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Health Check Options Header
                Row(
                  children: [
                    Container(
                      height: 2,
                      width: 40,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      languageProvider.t('vitals.healthCheckOptions'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Blood Sugar Check
                _buildHealthCheckButton(
                  languageProvider: languageProvider,
                  title: languageProvider.t('vitals.bloodSugar'),
                  subtitle: languageProvider.t('vitals.bloodSugarSubtitle'),
                  icon: Icons.bloodtype,
                  gradientColors: [Colors.red.shade400, Colors.red.shade600],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BloodSugarCheckScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Blood Pressure Check
                _buildHealthCheckButton(
                  languageProvider: languageProvider,
                  title: languageProvider.t('vitals.bloodPressure'),
                  subtitle: languageProvider.t('vitals.bloodPressureSubtitle'),
                  icon: Icons.favorite_border,
                  gradientColors: [Colors.pink.shade400, Colors.pink.shade600],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BPCheckScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Oxygen Level Check
                _buildHealthCheckButton(
                  languageProvider: languageProvider,
                  title: languageProvider.t('vitals.oxygenLevel'),
                  subtitle: languageProvider.t('vitals.oxygenLevelSubtitle'),
                  icon: Icons.air,
                  gradientColors: [Colors.cyan.shade400, Colors.cyan.shade600],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SpO2CheckScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Body Temperature Check
                _buildHealthCheckButton(
                  languageProvider: languageProvider,
                  title: languageProvider.t('vitals.temperature'),
                  subtitle: languageProvider.t('vitals.temperatureSubtitle'),
                  icon: Icons.thermostat,
                  gradientColors: [
                    Colors.orange.shade400,
                    Colors.orange.shade600
                  ],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TemperatureCheckScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Heart Rate Check
                _buildHealthCheckButton(
                  languageProvider: languageProvider,
                  title: languageProvider.t('vitals.heartRate'),
                  subtitle: languageProvider.t('vitals.heartRateSubtitle'),
                  icon: Icons.monitor_heart,
                  gradientColors: [
                    Colors.purple.shade400,
                    Colors.purple.shade600
                  ],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HeartRateCheckScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Cholesterol Check
                _buildHealthCheckButton(
                  languageProvider: languageProvider,
                  title: languageProvider.t('vitals.cholesterol'),
                  subtitle: languageProvider.t('vitals.cholesterolSubtitle'),
                  icon: Icons.science,
                  gradientColors: [Colors.teal.shade400, Colors.teal.shade600],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CholesterolCheckScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHealthCheckButton({
    required LanguageProvider languageProvider,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
