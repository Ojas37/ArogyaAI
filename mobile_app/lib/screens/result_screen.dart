import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/triage_provider.dart';
import '../services/storage_service.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final triageProvider = Provider.of<TriageProvider>(context);
    final result = triageProvider.currentResult;

    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Result')),
        body: const Center(child: Text('No result available')),
      );
    }

    // Color based on urgency
    Color urgencyColor;
    IconData urgencyIcon;
    
    switch (result.urgencyLevel) {
      case 'emergency':
        urgencyColor = Colors.red;
        urgencyIcon = Icons.warning;
        break;
      case 'doctor':
        urgencyColor = Colors.orange;
        urgencyIcon = Icons.local_hospital;
        break;
      default:
        urgencyColor = Colors.green;
        urgencyIcon = Icons.check_circle;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Triage Result'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              await StorageService.saveReport(result.toJson());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Report saved')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Offline indicator
            if (result.isOfflineResult)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.cloud_off, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Offline Analysis - Connect to internet for more accurate results',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

            // Urgency level
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: urgencyColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: urgencyColor, width: 2),
              ),
              child: Column(
                children: [
                  Icon(urgencyIcon, size: 64, color: urgencyColor),
                  const SizedBox(height: 16),
                  Text(
                    result.urgencyLevel.toUpperCase(),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: urgencyColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Confidence: ${(result.confidence * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Recommendation
            _buildSection(
              'Recommendation',
              result.recommendation,
              Icons.lightbulb_outline,
            ),

            const SizedBox(height: 16),

            // Explanation
            _buildSection(
              'Why this result?',
              result.explanation,
              Icons.info_outline,
            ),

            const SizedBox(height: 16),

            // Red flags
            if (result.redFlags.isNotEmpty) ...[
              _buildSection(
                'Red Flags Detected',
                result.redFlags.join('\n• '),
                Icons.flag,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
            ],

            // Next steps
            _buildSection(
              'Next Steps',
              result.nextSteps.map((step) => '• $step').join('\n'),
              Icons.list,
            ),

            const SizedBox(height: 32),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.home),
                    label: const Text('Back to Home'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, IconData icon, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
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
              Icon(icon, color: color ?? Colors.blue),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
        ],
      ),
    );
  }
}
