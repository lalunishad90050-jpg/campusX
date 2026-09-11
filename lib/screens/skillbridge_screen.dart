import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SkillBridgeScreen extends StatefulWidget {
  const SkillBridgeScreen({super.key});

  @override
  State<SkillBridgeScreen> createState() => _SkillBridgeScreenState();
}

class _SkillBridgeScreenState extends State<SkillBridgeScreen> {
  final TextEditingController jobController = TextEditingController();

  bool resumeUploaded = false;
  bool isAnalyzing = false;

  int matchPercentage = 0;
  List<String> matchedSkills = [];
  List<String> missingSkills = [];
  List<Map<String, dynamic>> roadmap = [];

  // CampusX online AI backend
  static const String apiUrl =
      'https://campusx-backend-43jp.onrender.com/skillbridge/analyze';

  @override
  void dispose() {
    jobController.dispose();
    super.dispose();
  }

  void uploadResume() {
    setState(() {
      resumeUploaded = true;
    });

    showMessage('Resume uploaded successfully ✅');
  }

  Future<void> analyzeResume() async {
    if (!resumeUploaded) {
      showMessage('Please upload your resume first.');
      return;
    }

    if (jobController.text.trim().isEmpty) {
      showMessage('Please enter the job description.');
      return;
    }

    setState(() {
      isAnalyzing = true;
    });

    try {
      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'resume_text': 'Python SQL Git Flutter Firebase Data Analysis Machine Learning Dart',
              'job_description': jobController.text.trim(),
            }),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode != 200) {
        String message = 'Server error: ${response.statusCode}';

        try {
          final errorData = jsonDecode(response.body);
          message = errorData['detail']?.toString() ?? message;
        } catch (_) {}

        showMessage(message);
        return;
      }

      final data = jsonDecode(response.body);

      final newMatchPercentage =
          (data['match_percentage'] as num?)?.toInt() ?? 0;

      final newMatchedSkills =
          (data['matched_skills'] as List?)
              ?.map((item) => item.toString())
              .toList() ??
          [];

      final newMissingSkills =
          (data['missing_skills'] as List?)
              ?.map((item) => item.toString())
              .toList() ??
          [];

      final newRoadmap =
          (data['roadmap'] as List?)
              ?.whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList() ??
          [];

      if (!mounted) return;

      setState(() {
        matchPercentage = newMatchPercentage;
        matchedSkills = newMatchedSkills;
        missingSkills = newMissingSkills;
        roadmap = newRoadmap;
      });

      showMessage('AI analysis completed successfully 🤖');
    } catch (e) {
      if (!mounted) return;

      showMessage('Backend se connection nahi ho pa raha. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          isAnalyzing = false;
        });
      }
    }
  }

  void showRoadmap() {
    if (roadmap.isEmpty) {
      showMessage('Analyze your resume first.');
      return;
    }

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
                    '4-Week Learning Roadmap',
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      itemCount: roadmap.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = roadmap[index];

                        final week = item['week'] ?? index + 1;
                        final title = item['title'] ?? 'Learning Plan';

                        final skills =
                            (item['skills'] as List?)
                                ?.map((skill) => skill.toString())
                                .toList() ??
                            [];

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Week $week',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  title.toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (skills.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: skills
                                        .map(
                                          (skill) => Chip(label: Text(skill)),
                                        )
                                        .toList(),
                                  ),
                                ],
                              ],
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
      appBar: AppBar(
        title: const Text(
          'SkillBridge',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            child: Icon(
                              Icons.auto_awesome,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AI Career Match',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Compare your skills with a job description.',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton.icon(
                        onPressed: isAnalyzing ? null : uploadResume,
                        icon: Icon(
                          resumeUploaded
                              ? Icons.check_circle
                              : Icons.upload_file,
                        ),
                        label: Text(
                          resumeUploaded ? 'Resume Uploaded' : 'Upload Resume',
                        ),
                      ),
                      if (resumeUploaded) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Demo resume loaded. PDF/DOCX file picker can be connected later.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Job Description',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: jobController,
                maxLines: 7,
                decoration: const InputDecoration(
                  hintText: 'Paste the job description here...\n\nExample: Python, SQL, Machine Learning, AWS, Git',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: isAnalyzing ? null : analyzeResume,
                icon: isAnalyzing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(isAnalyzing ? 'Analyzing...' : 'Analyze with AI'),
              ),
              if (matchPercentage > 0 || matchedSkills.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'AI Analysis Result',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 140,
                          width: 140,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                height: 140,
                                width: 140,
                                child: CircularProgressIndicator(
                                  value: matchPercentage / 100,
                                  strokeWidth: 13,
                                  backgroundColor:
                                      theme.colorScheme.surfaceContainerHighest,
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$matchPercentage%',
                                    style: theme.textTheme.headlineMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const Text('Match'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _SkillSection(
                          title: 'Matched Skills',
                          skills: matchedSkills,
                          icon: Icons.check_circle_outline,
                        ),
                        const SizedBox(height: 18),
                        _SkillSection(
                          title: 'Missing Skills',
                          skills: missingSkills,
                          icon: Icons.warning_amber_rounded,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: showRoadmap,
                  icon: const Icon(Icons.route_rounded),
                  label: const Text('View Learning Roadmap'),
                ),
              ],
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.security_rounded,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your OpenAI API key stays on the backend. '
                          'The Flutter app only communicates with the CampusX API.',
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
    );
  }
}

class _SkillSection extends StatelessWidget {
  final String title;
  final List<String> skills;
  final IconData icon;

  const _SkillSection({
    required this.title,
    required this.skills,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (skills.isEmpty)
          const Text('None')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: skills.map((skill) => Chip(label: Text(skill))).toList(),
          ),
      ],
    );
  }
}
