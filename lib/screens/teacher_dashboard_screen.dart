import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DateTime _selectedDate = DateTime.now();
  String _selectedSection = 'CSE 1st Year';

  final Map<String, String> _attendance = {};

  bool _loadingStudents = true;
  bool _saving = false;

  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  String get _selectedDateString {
    final year = _selectedDate.year.toString().padLeft(4, '0');
    final month = _selectedDate.month.toString().padLeft(2, '0');
    final day = _selectedDate.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  Future<void> _loadStudents() async {
    if (!mounted) return;

    setState(() {
      _loadingStudents = true;
    });

    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();

      final students = snapshot.docs.map((doc) {
        final data = doc.data();

        return {
          'id': doc.id,
          'collegeId': data['collegeId']?.toString() ?? 'N/A',
          'email': data['email']?.toString() ?? 'No email',
          'name':
              data['name']?.toString() ??
              data['collegeId']?.toString() ??
              'Student',
        };
      }).toList();

      students.sort(
        (a, b) =>
            a['collegeId'].toString().compareTo(b['collegeId'].toString()),
      );

      if (!mounted) return;

      setState(() {
        _students = students;
        _loadingStudents = false;
      });

      await _loadExistingAttendance();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingStudents = false;
      });

      _showMessage('Students load nahi ho pa rahe: $e', isError: true);
    }
  }

  Future<void> _loadExistingAttendance() async {
    if (_students.isEmpty) return;

    try {
      final snapshot = await _firestore
          .collection('attendance')
          .where('date', isEqualTo: _selectedDateString)
          .get();

      final existing = <String, String>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final userId = data['userId']?.toString();
        final status = data['status']?.toString();

        if (userId != null && status != null) {
          existing[userId] = status;
        }
      }

      if (!mounted) return;

      setState(() {
        _attendance
          ..clear()
          ..addAll(existing);
      });
    } catch (_) {
      if (!mounted) return;

      _showMessage('Existing attendance load nahi ho payi.', isError: true);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (!mounted || picked == null) return;

    setState(() {
      _selectedDate = picked;
      _attendance.clear();
    });

    await _loadExistingAttendance();
  }

  void _setAttendance(String studentId, String status) {
    setState(() {
      _attendance[studentId] = status;
    });
  }

  Future<void> _saveAttendance() async {
    if (_students.isEmpty) {
      _showMessage('Save karne ke liye students nahi hain.', isError: true);
      return;
    }

    if (_attendance.length != _students.length) {
      _showMessage(
        'Please har student ki Present ya Absent attendance select karo.',
        isError: true,
      );
      return;
    }

    final teacher = FirebaseAuth.instance.currentUser;

    if (teacher == null) {
      _showMessage('Teacher login nahi hai.', isError: true);
      return;
    }

    if (!mounted) return;

    setState(() {
      _saving = true;
    });

    try {
      final batch = _firestore.batch();

      for (final student in _students) {
        final studentId = student['id'].toString();
        final status = _attendance[studentId];

        if (status == null) {
          continue;
        }

        final query = await _firestore
            .collection('attendance')
            .where('userId', isEqualTo: studentId)
            .where('date', isEqualTo: _selectedDateString)
            .limit(1)
            .get();

        final data = {
          'userId': studentId,
          'collegeId': student['collegeId'],
          'date': _selectedDateString,
          'status': status,
          'markedBy': teacher.uid,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (query.docs.isEmpty) {
          final newDoc = _firestore.collection('attendance').doc();

          batch.set(newDoc, {
            ...data,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } else {
          batch.update(query.docs.first.reference, data);
        }
      }

      await batch.commit();

      if (!mounted) return;

      _showMessage('Attendance successfully saved for $_selectedDateString.');
    } catch (e) {
      if (!mounted) return;

      _showMessage('Attendance save nahi hui: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    final presentCount = _attendance.values
        .where((status) => status == 'present')
        .length;

    final absentCount = _attendance.values
        .where((status) => status == 'absent')
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadingStudents ? null : _loadStudents,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _loadingStudents
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStudents,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 16),
                  _buildControls(context),
                  const SizedBox(height: 16),
                  _buildSummary(context, presentCount, absentCount),
                  const SizedBox(height: 20),
                  Text(
                    'Student Attendance',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (_students.isEmpty)
                    _buildEmptyStudents(context)
                  else
                    ..._students.map(
                      (student) => _buildStudentCard(context, student),
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _saving ? null : _saveAttendance,
                    icon: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(
                      _saving ? 'Saving Attendance...' : 'Save Attendance',
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.person_rounded,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Teacher Attendance Panel',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mark and manage student attendance.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Attendance Settings',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(14),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Attendance Date',
                  prefixIcon: Icon(Icons.calendar_month),
                ),
                child: Text(_formatDate(_selectedDate)),
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _selectedSection,
              decoration: const InputDecoration(
                labelText: 'Class / Section',
                prefixIcon: Icon(Icons.school_outlined),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'CSE 1st Year',
                  child: Text('CSE 1st Year'),
                ),
                DropdownMenuItem(
                  value: 'CSE 2nd Year',
                  child: Text('CSE 2nd Year'),
                ),
                DropdownMenuItem(
                  value: 'CSE 3rd Year',
                  child: Text('CSE 3rd Year'),
                ),
                DropdownMenuItem(
                  value: 'CSE 4th Year',
                  child: Text('CSE 4th Year'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _selectedSection = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(BuildContext context, int present, int absent) {
    return Row(
      children: [
        Expanded(
          child: _summaryCard(context, 'Present', present, Icons.check_circle),
        ),
        const SizedBox(width: 12),
        Expanded(child: _summaryCard(context, 'Absent', absent, Icons.cancel)),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryCard(context, 'Total', _students.length, Icons.people),
        ),
      ],
    );
  }

  Widget _summaryCard(
    BuildContext context,
    String title,
    int count,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, size: 25),
            const SizedBox(height: 6),
            Text(
              count.toString(),
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(title, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCard(BuildContext context, Map<String, dynamic> student) {
    final studentId = student['id'].toString();
    final currentStatus = _attendance[studentId];

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Text(
                    student['collegeId'].toString().isNotEmpty
                        ? student['collegeId'].toString()[0].toUpperCase()
                        : 'S',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student['name'].toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'College ID: ${student['collegeId']}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _attendanceButton(
                    context,
                    studentId,
                    'Present',
                    'present',
                    Icons.check_circle,
                    currentStatus == 'present',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _attendanceButton(
                    context,
                    studentId,
                    'Absent',
                    'absent',
                    Icons.cancel,
                    currentStatus == 'absent',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _attendanceButton(
    BuildContext context,
    String studentId,
    String label,
    String status,
    IconData icon,
    bool selected,
  ) {
    return OutlinedButton.icon(
      onPressed: () {
        _setAttendance(studentId, status);
      },
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 46),
        side: BorderSide(width: selected ? 2 : 1),
      ),
    );
  }

  Widget _buildEmptyStudents(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            Icon(
              Icons.people_outline,
              size: 60,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 14),
            const Text(
              'No students found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Student accounts created in CampusX '
              'will appear here.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
