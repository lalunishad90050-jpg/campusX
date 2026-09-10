import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

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

          return RefreshIndicator(
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 500));
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
                _AttendanceInfoCard(),
              ],
            ),
          );
        },
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
