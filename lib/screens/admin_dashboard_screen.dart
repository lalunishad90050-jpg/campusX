import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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

  void showReportDetails(BuildContext context, Map<String, dynamic> data) {
    final type = (data['reportType'] ?? 'Unknown').toString();

    final description = (data['description'] ?? 'No description').toString();

    final status = (data['status'] ?? 'new').toString();

    final collegeId = (data['collegeId'] ?? 'Unknown').toString();

    final latitude = data['latitude'];
    final longitude = data['longitude'];

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(description),
                const SizedBox(height: 12),
                Text('Status: ${status.toUpperCase()}'),
                Text('College ID: $collegeId'),
                if (latitude != null && longitude != null)
                  Text('Location: $latitude, $longitude'),
                const SizedBox(height: 12),
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
            child: const Icon(Icons.location_on, color: Colors.red, size: 46),
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
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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

          for (final report in reports) {
            final data = report.data();

            final status = (data['status'] ?? 'new').toString();

            final type = (data['reportType'] ?? '').toString();

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
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
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
                  'Safety Map',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                buildSafetyMap(context, reports),

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

                    final type = (data['reportType'] ?? 'Unknown').toString();

                    final description =
                        (data['description'] ?? 'No description').toString();

                    final status = (data['status'] ?? 'new').toString();

                    final collegeId = (data['collegeId'] ?? 'Unknown')
                        .toString();

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
                                        ?.copyWith(fontWeight: FontWeight.bold),
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

                                updateReportStatus(context, report.id, value);
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
