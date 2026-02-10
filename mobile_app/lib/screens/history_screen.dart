import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _reports = [];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  void _loadReports() {
    setState(() {
      _reports = StorageService.getAllReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Consultation History',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              if (_reports.isNotEmpty)
                TextButton.icon(
                  onPressed: () async {
                    await StorageService.clearAll();
                    _loadReports();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('History cleared')),
                    );
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Clear All'),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Report list
          Expanded(
            child: _reports.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No consultation history yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Your saved consultations will appear here',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _reports.length,
                    itemBuilder: (context, index) {
                      final report = _reports[_reports.length - 1 - index];
                      return _buildReportCard(report);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final urgency = report['urgencyLevel'] ?? 'unknown';
    
    Color urgencyColor;
    switch (urgency) {
      case 'emergency':
        urgencyColor = Colors.red;
        break;
      case 'doctor':
        urgencyColor = Colors.orange;
        break;
      default:
        urgencyColor = Colors.green;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: urgencyColor.withOpacity(0.2),
          child: Icon(
            urgency == 'emergency'
                ? Icons.warning
                : urgency == 'doctor'
                    ? Icons.local_hospital
                    : Icons.check_circle,
            color: urgencyColor,
          ),
        ),
        title: Text(
          urgency.toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: urgencyColor,
          ),
        ),
        subtitle: Text(
          report['recommendation'] ?? 'No recommendation',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          _showReportDetails(report);
        },
      ),
    );
  }

  void _showReportDetails(Map<String, dynamic> report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    report['urgencyLevel']?.toUpperCase() ?? 'REPORT',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow('Recommendation', report['recommendation']),
                  _buildDetailRow('Explanation', report['explanation']),
                  if (report['nextSteps'] != null) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Next Steps:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...(report['nextSteps'] as List).map((step) => 
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('• $step'),
                      )
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    if (value == null) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
