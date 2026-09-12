import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../widgets/ai_voice_assistant.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  static const LatLng campusCenter = LatLng(26.7439, 83.2212);

  Future<void> updateReportStatus(
    BuildContext context,
    String reportId,
    String status,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('safety_reports')
          .doc(reportId)
          .update({
            'status': status,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Report status updated')));
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Update failed: $e')));
    }
  }

  Color statusColor(String status, BuildContext context) {
    if (status == 'resolved') {
      return Colors.green;
    }

    if (status == 'reviewing') {
      return Colors.orange;
    }

    return Theme.of(context).colorScheme.primary;
  }

  Color riskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'critical':
        return Colors.red.shade900;
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void showReportDetails(BuildContext context, Map<String, dynamic> data) {
    final type = (data['reportType'] ?? 'Unknown').toString();
    final description = (data['description'] ?? 'No description').toString();
    final status = (data['status'] ?? 'new').toString();
    final collegeId = (data['collegeId'] ?? 'Unknown').toString();

    final latitude = data['latitude'];
    final longitude = data['longitude'];

    final riskScore = data['aiRiskScore'];
    final riskLevel = (data['aiRiskLevel'] ?? 'Not analyzed').toString();
    final category = (data['aiCategory'] ?? 'Unknown').toString();
    final severity = (data['aiSeverity'] ?? 'Unknown').toString();
    final reason = (data['aiReason'] ?? 'No AI analysis available.').toString();

    final recommendedAction =
        (data['aiRecommendedAction'] ?? 'No recommendation available.')
            .toString();

    final timeRisk = (data['aiTimeRisk'] ?? 'Unknown').toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(description),
                const SizedBox(height: 16),
                _InfoRow(label: 'Status', value: status.toUpperCase()),
                _InfoRow(label: 'College ID', value: collegeId),
                if (latitude != null && longitude != null)
                  _InfoRow(label: 'Location', value: '$latitude, $longitude'),
                const SizedBox(height: 18),
                Text(
                  'AI Risk Analysis',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Card(
                  color: riskColor(riskLevel).withValues(alpha: 0.08),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.psychology_outlined,
                              color: riskColor(riskLevel),
                              size: 30,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                riskLevel.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: riskColor(riskLevel),
                                ),
                              ),
                            ),
                            if (riskScore != null)
                              Text(
                                '${riskScore.toString()}/100',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: riskColor(riskLevel),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _InfoRow(label: 'Category', value: category),
                        _InfoRow(label: 'Severity', value: severity),
                        _InfoRow(label: 'Time Risk', value: timeRisk),
                        const Divider(height: 24),
                        const Text(
                          'AI Reason',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(reason),
                        const SizedBox(height: 14),
                        const Text(
                          'Recommended Action',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(recommendedAction),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildSafetyMap(
    BuildContext context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> reports,
  ) {
    final markers = <Marker>[];

    for (final report in reports) {
      final data = report.data();

      final latitude = data['latitude'];
      final longitude = data['longitude'];

      if (latitude == null || longitude == null) {
        continue;
      }

      final riskLevel = (data['aiRiskLevel'] ?? 'unknown').toString();

      markers.add(
        Marker(
          point: LatLng(
            (latitude as num).toDouble(),
            (longitude as num).toDouble(),
          ),
          width: 50,
          height: 50,
          child: GestureDetector(
            onTap: () {
              showReportDetails(context, data);
            },
            child: Icon(
              Icons.location_on,
              color: riskColor(riskLevel),
              size: 46,
            ),
          ),
        ),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 360,
        child: FlutterMap(
          options: const MapOptions(
            initialCenter: campusCenter,
            initialZoom: 16,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.campusx.app',
            ),
            MarkerLayer(markers: markers),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications coming soon')),
              );
            },
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('safety_reports')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Reports load nahi ho rahi.\n\n'
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final reports = snapshot.data?.docs ?? [];

              int newReports = 0;
              int reviewingReports = 0;
              int resolvedReports = 0;

              int darkAreas = 0;
              int brokenLights = 0;

              int highRiskReports = 0;
              int mediumRiskReports = 0;
              int lowRiskReports = 0;
              int criticalRiskReports = 0;

              for (final report in reports) {
                final data = report.data();

                final status = (data['status'] ?? 'new').toString();

                final type = (data['reportType'] ?? '').toString();

                final risk = (data['aiRiskLevel'] ?? '')
                    .toString()
                    .toLowerCase();

                if (status == 'new') {
                  newReports++;
                } else if (status == 'reviewing') {
                  reviewingReports++;
                } else if (status == 'resolved') {
                  resolvedReports++;
                }

                if (type == 'Dark Area') {
                  darkAreas++;
                }

                if (type == 'Broken Light') {
                  brokenLights++;
                }

                if (risk == 'critical') {
                  criticalRiskReports++;
                } else if (risk == 'high') {
                  highRiskReports++;
                } else if (risk == 'medium') {
                  mediumRiskReports++;
                } else if (risk == 'low') {
                  lowRiskReports++;
                }
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Campus Safety Overview',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'Monitor and manage campus safety reports.',
                      style: theme.textTheme.bodyMedium,
                    ),

                    const SizedBox(height: 20),

                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        _StatCard(
                          title: 'Total Reports',
                          value: '${reports.length}',
                          icon: Icons.report_outlined,
                        ),
                        _StatCard(
                          title: 'New Reports',
                          value: '$newReports',
                          icon: Icons.fiber_new_outlined,
                        ),
                        _StatCard(
                          title: 'Dark Areas',
                          value: '$darkAreas',
                          icon: Icons.nightlight_outlined,
                        ),
                        _StatCard(
                          title: 'Broken Lights',
                          value: '$brokenLights',
                          icon: Icons.lightbulb_outline,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Text(
                      'AI Safety Intelligence',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _RiskSummary(
                              title: 'Critical Risk',
                              value: '$criticalRiskReports',
                              color: Colors.red.shade900,
                            ),
                            const SizedBox(height: 12),
                            _RiskSummary(
                              title: 'High Risk',
                              value: '$highRiskReports',
                              color: Colors.red,
                            ),
                            const SizedBox(height: 12),
                            _RiskSummary(
                              title: 'Medium Risk',
                              value: '$mediumRiskReports',
                              color: Colors.orange,
                            ),
                            const SizedBox(height: 12),
                            _RiskSummary(
                              title: 'Low Risk',
                              value: '$lowRiskReports',
                              color: Colors.green,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      'Safety Map',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    buildSafetyMap(context, reports),

                    const SizedBox(height: 12),

                    const Text(
                      'Map markers are colored using AI risk level.',
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 20),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            _StatusInfo(
                              title: 'New',
                              value: '$newReports',
                              color: theme.colorScheme.primary,
                            ),
                            _StatusInfo(
                              title: 'Reviewing',
                              value: '$reviewingReports',
                              color: Colors.orange,
                            ),
                            _StatusInfo(
                              title: 'Resolved',
                              value: '$resolvedReports',
                              color: Colors.green,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      'Recent Reports',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    if (reports.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(30),
                          child: Center(child: Text('No safety reports yet.')),
                        ),
                      )
                    else
                      ...reports.map((report) {
                        final data = report.data();

                        final type = (data['reportType'] ?? 'Unknown')
                            .toString();

                        final description =
                            (data['description'] ?? 'No description')
                                .toString();

                        final status = (data['status'] ?? 'new').toString();

                        final collegeId = (data['collegeId'] ?? 'Unknown')
                            .toString();

                        final riskLevel =
                            (data['aiRiskLevel'] ?? 'Not analyzed').toString();

                        final riskScore = data['aiRiskScore'];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        type,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                    Text(
                                      status.toUpperCase(),
                                      style: TextStyle(
                                        color: statusColor(status, context),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),

                                Text(description),

                                const SizedBox(height: 8),

                                Text('College ID: $collegeId'),

                                const SizedBox(height: 12),

                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: riskColor(riskLevel)
                                        .withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.psychology_outlined,
                                        color: riskColor(riskLevel),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'AI Risk',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              riskLevel.toUpperCase(),
                                              style: TextStyle(
                                                color: riskColor(riskLevel),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (riskScore != null)
                                        Text(
                                          '${riskScore.toString()}/100',
                                          style: TextStyle(
                                            color: riskColor(riskLevel),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 10),

                                OutlinedButton.icon(
                                  onPressed: () {
                                    showReportDetails(context, data);
                                  },
                                  icon: const Icon(Icons.psychology_outlined),
                                  label: const Text('View AI Analysis'),
                                ),

                                const SizedBox(height: 10),

                                DropdownButtonFormField<String>(
                                  initialValue: status,
                                  decoration: const InputDecoration(
                                    labelText: 'Update Status',
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'new',
                                      child: Text('New'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'reviewing',
                                      child: Text('Reviewing'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'resolved',
                                      child: Text('Resolved'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value == null) {
                                      return;
                                    }

                                    updateReportStatus(
                                      context,
                                      report.id,
                                      value,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              );
            },
          ),

          const Positioned(right: 12, bottom: 12, child: AIVoiceAssistant()),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(title),
          ],
        ),
      ),
    );
  }
}

class _RiskSummary extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _RiskSummary({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(radius: 6, backgroundColor: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _StatusInfo extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatusInfo({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(title),
        ],
      ),
    );
  }
}
