import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  static const String apiUrl =
      'https://campusx-backend-43jp.onrender.com/attendance/student-insight';

  bool isLoadingAI = false;

  Map<String, dynamic>? aiInsight;

  Stream<QuerySnapshot<Map<String, dynamic>>> _attendanceStream() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('attendance')
        .where('userId', isEqualTo: user.uid)
        .orderBy('date', descending: true)
        .snapshots();
  }

  Future<void> getAIInsight({
    required int presentCount,
    required int absentCount,
    required int totalClasses,
    required List<Map<String, dynamic>> recentRecords,
  }) async {
    if (totalClasses == 0) {
      return;
    }

    setState(() {
      isLoadingAI = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      final studentName = user?.displayName ?? 'Student';

      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'student_name': studentName,
              'present_count': presentCount,
              'absent_count': absentCount,
              'total_classes': totalClasses,
              'recent_records': recentRecords,
            }),
          )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (!mounted) return;

        setState(() {
          aiInsight = Map<String, dynamic>.from(data);
        });
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI analysis failed: ${response.statusCode}')),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI analysis unavailable. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoadingAI = false;
        });
      }
    }
  }

  Color aiRiskColor(String risk) {
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
        return Theme.of(context).colorScheme.primary;
    }
  }

  Widget buildAIInsightCard() {
    if (isLoadingAI) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(),
              ),
              SizedBox(width: 14),
              Expanded(child: Text('AI attendance analysis is running...')),
            ],
          ),
        ),
      );
    }

    if (aiInsight == null) {
      return const SizedBox.shrink();
    }

    final riskLevel = (aiInsight!['risk_level'] ?? 'unknown').toString();

    final status = (aiInsight!['status'] ?? 'Unknown').toString();

    final insight = (aiInsight!['insight'] ?? 'No insight available.')
        .toString();

    final recommendation =
        (aiInsight!['recommendation'] ?? 'No recommendation available.')
            .toString();

    final trend = (aiInsight!['trend'] ?? 'Unknown').toString();

    final percentage = aiInsight!['attendance_percentage'];

    final color = aiRiskColor(riskLevel);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology_outlined, color: color, size: 30),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'AI Attendance Insight',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Risk Level',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          riskLevel.toUpperCase(),
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (percentage != null)
                    Text(
                      '${percentage.toString()}%',
                      style: TextStyle(
                        color: color,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            _AIInfoRow(label: 'Status', value: status),

            _AIInfoRow(label: 'Trend', value: trend),

            const Divider(height: 24),

            const Text(
              'AI Insight',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 6),

            Text(insight),

            const SizedBox(height: 14),

            const Text(
              'Recommendation',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 6),

            Text(recommendation),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Attendance',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _attendanceStream(),

        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Unable to load attendance',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('${snapshot.error}', textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final records = snapshot.data?.docs ?? [];

          int presentCount = 0;
          int absentCount = 0;

          for (final doc in records) {
            final status = (doc.data()['status'] ?? '')
                .toString()
                .toLowerCase();

            if (status == 'present') {
              presentCount++;
            } else if (status == 'absent') {
              absentCount++;
            }
          }

          final total = presentCount + absentCount;

          final percentage = total == 0
              ? 0
              : (presentCount / total * 100).round();

          final recentRecords = records
              .take(10)
              .map(
                (doc) => {
                  'date': doc.data()['date'],
                  'status': doc.data()['status'],
                },
              )
              .toList();

          return RefreshIndicator(
            onRefresh: () async {
              await getAIInsight(
                presentCount: presentCount,
                absentCount: absentCount,
                totalClasses: total,
                recentRecords: recentRecords,
              );
            },

            child: ListView(
              padding: const EdgeInsets.all(20),

              children: [
                _AttendanceSummary(
                  percentage: percentage,
                  presentCount: presentCount,
                  absentCount: absentCount,
                  total: total,
                ),

                const SizedBox(height: 16),

                if (total > 0)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isLoadingAI
                          ? null
                          : () {
                              getAIInsight(
                                presentCount: presentCount,
                                absentCount: absentCount,
                                totalClasses: total,
                                recentRecords: recentRecords,
                              );
                            },
                      icon: const Icon(Icons.psychology_outlined),
                      label: Text(
                        isLoadingAI
                            ? 'Analyzing...'
                            : 'Get AI Attendance Insight',
                      ),
                    ),
                  ),

                const SizedBox(height: 14),

                buildAIInsightCard(),

                const SizedBox(height: 24),

                const Text(
                  'Attendance History',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                if (records.isEmpty)
                  const _EmptyAttendance()
                else
                  ...records.map(
                    (doc) => _AttendanceHistoryCard(data: doc.data()),
                  ),

                const SizedBox(height: 24),

                const _AttendanceInfoCard(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AIInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _AIInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
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

class _AttendanceSummary extends StatelessWidget {
  final int percentage;
  final int presentCount;
  final int absentCount;
  final int total;

  const _AttendanceSummary({
    required this.percentage,
    required this.presentCount,
    required this.absentCount,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            SizedBox(
              width: 190,
              height: 190,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 170,
                    height: 170,
                    child: CircularProgressIndicator(
                      value: total == 0 ? 0 : percentage / 100,
                      strokeWidth: 16,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),

                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$percentage%',
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text('Attendance', style: TextStyle(fontSize: 17)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: _CountCard(
                    icon: Icons.check_circle_outline,
                    count: presentCount,
                    label: 'Present',
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: _CountCard(
                    icon: Icons.cancel_outlined,
                    count: absentCount,
                    label: 'Absent',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CountCard extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;

  const _CountCard({
    required this.icon,
    required this.count,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, size: 34, color: theme.colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          Text(label, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}

class _AttendanceHistoryCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _AttendanceHistoryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final status = (data['status'] ?? 'unknown').toString().toLowerCase();

    final date = (data['date'] ?? 'Date not available').toString();

    final isPresent = status == 'present';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),

        leading: CircleAvatar(
          backgroundColor: isPresent
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.errorContainer,
          child: Icon(
            isPresent ? Icons.check : Icons.close,
            color: isPresent
                ? theme.colorScheme.primary
                : theme.colorScheme.error,
          ),
        ),

        title: Text(
          isPresent ? 'Present' : 'Absent',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),

        subtitle: Text(date),

        trailing: Icon(
          Icons.chevron_right,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _EmptyAttendance extends StatelessWidget {
  const _EmptyAttendance();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(
              Icons.event_available_outlined,
              size: 60,
              color: theme.colorScheme.primary,
            ),

            const SizedBox(height: 14),

            const Text(
              'No Attendance Records',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            const Text(
              'Your teacher or authorized admin will add your attendance records here.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceInfoCard extends StatelessWidget {
  const _AttendanceInfoCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline,
              color: theme.colorScheme.primary,
              size: 28,
            ),

            const SizedBox(width: 14),

            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Attendance is managed by teachers',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),

                  SizedBox(height: 6),

                  Text(
                    'Only authorized teachers or admins can mark and update attendance.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
