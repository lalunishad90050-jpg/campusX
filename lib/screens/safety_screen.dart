import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class SafetyScreen extends StatefulWidget {
  const SafetyScreen({super.key});

  @override
  State<SafetyScreen> createState() => _SafetyScreenState();
}

class _SafetyScreenState extends State<SafetyScreen> {
  static const String apiUrl =
      'https://campusx-backend-43jp.onrender.com/safety/analyze';

  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String selectedType = 'Dark Area';

  LatLng? selectedLocation;

  bool isSubmitting = false;

  final List<String> reportTypes = [
    'Dark Area',
    'Broken Light',
    'Suspicious Activity',
    'Unsafe Area',
    'Other',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> selectLocation() async {
    final result = await Navigator.pushNamed(context, '/campus-map');

    if (!mounted) return;

    if (result is LatLng) {
      setState(() {
        selectedLocation = result;
      });
    }
  }

  Future<Map<String, dynamic>> analyzeSafetyWithAI() async {
    final response = await http
        .post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'report_type': selectedType,
            'description': _descriptionController.text.trim(),
            'latitude': selectedLocation!.latitude,
            'longitude': selectedLocation!.longitude,
            'recent_reports': [],
          }),
        )
        .timeout(const Duration(seconds: 45));

    if (response.statusCode != 200) {
      throw Exception('Safety AI server error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);

    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid Safety AI response.');
    }

    return data;
  }

  Future<void> submitReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedLocation == null) {
      showMessage('Please map par safety location select karo.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      showMessage('Please login first.');
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        showMessage('User profile nahi mila.');
        return;
      }

      final userData = userDoc.data();
      final collegeId = userData?['collegeId'] ?? 'Unknown';

      // --------------------------------------------------
      // AI SAFETY ANALYSIS
      // --------------------------------------------------

      final aiResult = await analyzeSafetyWithAI();

      final riskScore = (aiResult['risk_score'] ?? 0) as num;

      final riskLevel = (aiResult['risk_level'] ?? 'Low').toString();

      final category = (aiResult['category'] ?? selectedType).toString();

      final severity = (aiResult['severity'] ?? 'Low').toString();

      final reason = (aiResult['reason'] ?? '').toString();

      final recommendedAction = (aiResult['recommended_action'] ?? '')
          .toString();

      final timeRisk = (aiResult['time_risk'] ?? '').toString();

      // --------------------------------------------------
      // SAVE REPORT + AI ANALYSIS TO FIRESTORE
      // --------------------------------------------------

      await _firestore.collection('safety_reports').add({
        'collegeId': collegeId,
        'userId': user.uid,
        'reportType': selectedType,
        'description': _descriptionController.text.trim(),
        'status': 'new',

        // Location
        'latitude': selectedLocation!.latitude,
        'longitude': selectedLocation!.longitude,

        // AI analysis
        'aiRiskScore': riskScore.toDouble(),
        'aiRiskLevel': riskLevel,
        'aiCategory': category,
        'aiSeverity': severity,
        'aiReason': reason,
        'aiRecommendedAction': recommendedAction,
        'aiTimeRisk': timeRisk,

        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      _descriptionController.clear();

      setState(() {
        selectedType = 'Dark Area';
        selectedLocation = null;
      });

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Report Submitted ✅'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your campus safety report has been submitted successfully.',
                  ),
                  const SizedBox(height: 18),

                  Text(
                    'AI Risk Score: '
                    '${riskScore.toStringAsFixed(0)}/100',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Risk Level: $riskLevel',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 6),

                  Text('Severity: $severity'),

                  if (category.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('Category: $category'),
                  ],

                  if (recommendedAction.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Text(
                      'Recommended Action',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(recommendedAction),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      showMessage(
        'Report save nahi hui: '
        '${e.message ?? 'Unknown error'}',
      );
    } on http.ClientException {
      if (!mounted) return;

      showMessage('Safety AI se connection nahi ho paaya.');
    } on FormatException {
      if (!mounted) return;

      showMessage('Safety AI ne invalid response diya.');
    } catch (e) {
      if (!mounted) return;

      showMessage('Safety AI analysis failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Campus Safety')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.shield_rounded,
                          size: 42,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Report an Unsafe Area',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Help make your campus safer by reporting unsafe locations.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  'Report Type',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.report_problem_outlined),
                    labelText: 'Select issue',
                  ),
                  items: reportTypes.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: isSubmitting
                      ? null
                      : (value) {
                          if (value == null) return;

                          setState(() {
                            selectedType = value;
                          });
                        },
                ),

                const SizedBox(height: 20),

                Text(
                  'Safety Location',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(
                          selectedLocation == null
                              ? Icons.location_on_outlined
                              : Icons.location_on,
                          size: 42,
                          color: selectedLocation == null
                              ? theme.colorScheme.primary
                              : Colors.green,
                        ),

                        const SizedBox(height: 10),

                        Text(
                          selectedLocation == null
                              ? 'No location selected'
                              : 'Location selected ✅',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        if (selectedLocation != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Lat: ${selectedLocation!.latitude.toStringAsFixed(6)}\n'
                            'Lng: ${selectedLocation!.longitude.toStringAsFixed(6)}',
                            textAlign: TextAlign.center,
                          ),
                        ],

                        const SizedBox(height: 14),

                        OutlinedButton.icon(
                          onPressed: isSubmitting ? null : selectLocation,
                          icon: const Icon(Icons.map_outlined),
                          label: Text(
                            selectedLocation == null
                                ? 'Select on Campus Map'
                                : 'Change Location',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  'Description',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                TextFormField(
                  controller: _descriptionController,
                  maxLines: 5,
                  enabled: !isSubmitting,
                  decoration: const InputDecoration(
                    hintText: 'Describe the safety issue...',
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 80),
                      child: Icon(Icons.description_outlined),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Description is required';
                    }

                    if (value.trim().length < 5) {
                      return 'Please provide a little more detail';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 24),

                ElevatedButton.icon(
                  onPressed: isSubmitting ? null : submitReport,
                  icon: isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(
                    isSubmitting
                        ? 'AI Analyzing...'
                        : 'Submit with AI Analysis',
                  ),
                ),

                const SizedBox(height: 16),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'CampusShield AI estimates the risk '
                            'level of your report and provides '
                            'a recommendation for authorized staff. '
                            'AI results are estimates, not guarantees.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Please report genuine campus safety concerns. '
                            'Your report will be reviewed by authorized staff.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
