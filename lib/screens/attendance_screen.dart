import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  bool isMarking = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> get attendanceStream {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('attendance')
        .where('userId', isEqualTo: user.uid)
        .orderBy('date', descending: true)
        .snapshots();
  }

  Future<void> markAttendance(String status) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      showMessage('Please login first.');
      return;
    }

    setState(() => isMarking = true);

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        showMessage('User profile nahi mila.');
        return;
      }

      final userData = userDoc.data();
      final collegeId = userData?['collegeId'] ?? 'Unknown';

      final today = DateTime.now();

      final date =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final existing = await _firestore
          .collection('attendance')
          .where('userId', isEqualTo: user.uid)
          .where('date', isEqualTo: date)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        showMessage('Aaj ki attendance already marked hai.');
        return;
      }

      await _firestore.collection('attendance').add({
        'collegeId': collegeId,
        'userId': user.uid,
        'date': date,
        'status': status,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      showMessage(
        status == 'present'
            ? 'Attendance marked as Present ✅'
            : 'Attendance marked as Absent',
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      showMessage('Attendance save nahi hui: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      if (!mounted) return;

      showMessage('Kuch error aa gaya. Please try again.');
    } finally {
      if (mounted) {
        setState(() => isMarking = false);
      }
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void showAttendanceHistory(
    BuildContext context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> records,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.75,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Attendance History',
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: records.isEmpty
                        ? const Center(
                            child: Text('No attendance records yet.'),
                          )
                        : ListView.separated(
                            itemCount: records.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final data = records[index].data();
                              final status = data['status'] ?? 'unknown';
                              final date = data['date'] ?? '';

                              final isPresent = status == 'present';

                              return Card(
                                child: ListTile(
                                  leading: CircleAvatar(
                                    child: Icon(
                                      isPresent
                                          ? Icons.check_rounded
                                          : Icons.close_rounded,
                                    ),
                                  ),
                                  title: Text(
                                    isPresent ? 'Present' : 'Absent',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(date.toString()),
                                  trailing: Text(
                                    isPresent ? 'P' : 'A',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isPresent
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: attendanceStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Attendance load nahi ho rahi.\n\n${snapshot.error}',
                    textAlign: TextAlign.center,
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

            for (final record in records) {
              final status = record.data()['status'];

              if (status == 'present') {
                presentCount++;
              } else if (status == 'absent') {
                absentCount++;
              }
            }

            final total = presentCount + absentCount;

            final attendancePercentage = total == 0
                ? 0.0
                : (presentCount / total) * 100;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 150,
                            width: 150,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  height: 150,
                                  width: 150,
                                  child: CircularProgressIndicator(
                                    value: attendancePercentage / 100,
                                    strokeWidth: 14,
                                    backgroundColor: theme
                                        .colorScheme
                                        .surfaceContainerHighest,
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${attendancePercentage.toStringAsFixed(0)}%',
                                      style: theme.textTheme.headlineMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const Text('Attendance'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: _AttendanceStat(
                                  title: 'Present',
                                  value: '$presentCount',
                                  icon: Icons.check_circle_outline,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _AttendanceStat(
                                  title: 'Absent',
                                  value: '$absentCount',
                                  icon: Icons.cancel_outlined,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    'Mark Attendance',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  ElevatedButton.icon(
                    onPressed: isMarking
                        ? null
                        : () => markAttendance('present'),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Mark Present'),
                  ),

                  const SizedBox(height: 12),

                  OutlinedButton.icon(
                    onPressed: isMarking
                        ? null
                        : () => markAttendance('absent'),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Mark Absent'),
                  ),

                  const SizedBox(height: 24),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Attendance Tools',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 14),

                          _ToolTile(
                            icon: Icons.history_rounded,
                            title: 'Attendance History',
                            subtitle: 'View your attendance records',
                            onTap: () {
                              showAttendanceHistory(context, records);
                            },
                          ),

                          _ToolTile(
                            icon: Icons.analytics_outlined,
                            title: 'Analytics',
                            subtitle: 'Track your attendance percentage',
                            onTap: () {
                              showMessage(
                                'Current attendance: ${attendancePercentage.toStringAsFixed(1)}%',
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AttendanceStat extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _AttendanceStat({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(title),
        ],
      ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ToolTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(child: Icon(icon)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
      onTap: onTap,
    );
  }
}
