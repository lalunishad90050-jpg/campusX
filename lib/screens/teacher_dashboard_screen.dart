import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  final db = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;

  DateTime selectedDate = DateTime.now();
  String selectedSection = 'CSE 1st Year';

  bool loading = true;
  bool saving = false;

  List<Map<String, dynamic>> students = [];
  final Map<String, String> attendance = {};

  final sections = [
    'CSE 1st Year',
    'CSE 2nd Year',
    'CSE 3rd Year',
    'CSE 4th Year',
  ];

  String get dateString {
    final d = selectedDate.day.toString().padLeft(2, '0');
    final m = selectedDate.month.toString().padLeft(2, '0');
    return '$d/$m/${selectedDate.year}';
  }

  @override
  void initState() {
    super.initState();
    loadStudents();
  }

  Future<void> loadStudents() async {
    if (!mounted) return;

    setState(() => loading = true);

    try {
      final snap = await db
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();

      final list = snap.docs.map((doc) {
        final data = doc.data();

        return {
          'id': doc.id,
          'name': (data['name'] ?? 'Student').toString(),
          'rollNumber': (data['rollNumber'] ?? 'N/A').toString(),
          'collegeId': (data['collegeId'] ?? 'N/A').toString(),
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        students = list;
        loading = false;
      });

      await loadExistingAttendance();
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);
      message('Students load nahi hue: $e', true);
    }
  }

  Future<void> loadExistingAttendance() async {
    try {
      final snap = await db
          .collection('attendance')
          .where('date', isEqualTo: dateString)
          .get();

      final Map<String, String> old = {};

      for (final doc in snap.docs) {
        final data = doc.data();
        final id = data['userId']?.toString();
        final status = data['status']?.toString();

        if (id != null && (status == 'present' || status == 'absent')) {
          old[id] = status!;
        }
      }

      if (!mounted) return;

      setState(() {
        attendance
          ..clear()
          ..addAll(old);
      });
    } catch (e) {
      if (!mounted) return;
      message('Attendance load nahi hui: $e', true);
    }
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null || !mounted) return;

    setState(() {
      selectedDate = picked;
      attendance.clear();
    });

    await loadExistingAttendance();
  }

  void setStatus(String id, String status) {
    setState(() {
      attendance[id] = status;
    });
  }

  int get presentCount => attendance.values.where((x) => x == 'present').length;

  int get absentCount => attendance.values.where((x) => x == 'absent').length;

  Future<void> saveAttendance() async {
    if (students.isEmpty) {
      message('Koi student nahi mila.', true);
      return;
    }

    final unmarked = students.where((student) {
      return !attendance.containsKey(student['id'].toString());
    }).toList();

    if (unmarked.isNotEmpty) {
      message('Har student ko Present ya Absent mark karo.', true);
      return;
    }

    final teacher = auth.currentUser;

    if (teacher == null) {
      message('Teacher login session nahi mila.', true);
      return;
    }

    if (!mounted) return;

    setState(() => saving = true);

    try {
      final batch = db.batch();

      for (final student in students) {
        final id = student['id'].toString();
        final status = attendance[id]!;

        final old = await db
            .collection('attendance')
            .where('userId', isEqualTo: id)
            .where('date', isEqualTo: dateString)
            .limit(1)
            .get();

        final data = {
          'userId': id,
          'collegeId': student['collegeId'].toString(),
          'date': dateString,
          'status': status,
          'markedBy': teacher.uid,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (old.docs.isNotEmpty) {
          batch.update(old.docs.first.reference, data);
        } else {
          final ref = db.collection('attendance').doc();

          batch.set(ref, {...data, 'createdAt': FieldValue.serverTimestamp()});
        }
      }

      await batch.commit();

      if (!mounted) return;
      message('Attendance saved successfully! ✅', false);
    } catch (e) {
      if (!mounted) return;
      message('Attendance save nahi hui: $e', true);
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  void message(String text, bool error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  Future<void> logout() async {
    await auth.signOut();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Teacher Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: loading ? null : loadStudents,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(onPressed: logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadStudents,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            child: const Icon(Icons.person, size: 34),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Teacher Attendance Panel',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text('Manage student attendance'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: pickDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Attendance Date',
                                prefixIcon: Icon(Icons.calendar_month),
                              ),
                              child: Text(dateString),
                            ),
                          ),
                          const SizedBox(height: 14),
                          DropdownButtonFormField<String>(
                            initialValue: selectedSection,
                            decoration: const InputDecoration(
                              labelText: 'Class / Section',
                              prefixIcon: Icon(Icons.school),
                            ),
                            items: sections.map((section) {
                              return DropdownMenuItem(
                                value: section,
                                child: Text(section),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value == null) return;

                              setState(() {
                                selectedSection = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: summaryCard(
                          'Present',
                          presentCount,
                          Icons.check_circle,
                          theme,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: summaryCard(
                          'Absent',
                          absentCount,
                          Icons.cancel,
                          theme,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: summaryCard(
                          'Total',
                          students.length,
                          Icons.groups,
                          theme,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Student Attendance',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (students.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(25),
                        child: Column(
                          children: [
                            const Icon(Icons.people_outline, size: 55),
                            const SizedBox(height: 10),
                            const Text(
                              'No Students Found',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Students will appear automatically after registration.',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...students.map((student) => studentCard(student, theme)),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: saving ? null : saveAttendance,
                      icon: saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(saving ? 'Saving...' : 'Save Attendance'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget summaryCard(String title, int count, IconData icon, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 6),
            Text(
              '$count',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(title),
          ],
        ),
      ),
    );
  }

  Widget studentCard(Map<String, dynamic> student, ThemeData theme) {
    final id = student['id'].toString();
    final name = student['name'].toString();
    final roll = student['rollNumber'].toString();
    final collegeId = student['collegeId'].toString();
    final status = attendance[id];

    final initial = name.trim().isEmpty ? 'S' : name.trim()[0].toUpperCase();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Roll No: $roll',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'College ID: $collegeId',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setStatus(id, 'present');
                    },
                    icon: Icon(
                      Icons.check_circle,
                      color: status == 'present'
                          ? theme.colorScheme.primary
                          : null,
                    ),
                    label: const Text('Present'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      side: BorderSide(
                        width: status == 'present' ? 2 : 1,
                        color: status == 'present'
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setStatus(id, 'absent');
                    },
                    icon: Icon(
                      Icons.cancel,
                      color: status == 'absent'
                          ? theme.colorScheme.error
                          : null,
                    ),
                    label: const Text('Absent'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      side: BorderSide(
                        width: status == 'absent' ? 2 : 1,
                        color: status == 'absent'
                            ? theme.colorScheme.error
                            : theme.colorScheme.outline,
                      ),
                    ),
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
