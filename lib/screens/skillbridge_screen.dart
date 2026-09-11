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
  bool analysisDone = false;

  int matchPercentage = 0;

  List<String> matchedSkills = [];
  List<String> missingSkills = [];

  // Linux desktop par FastAPI same Chromebook par chal raha hai.
  static const String apiUrl = 'http://127.0.0.1:8000/skillbridge/analyze';

  final List<Map<String, dynamic>> roadmap = [
    {
      'week': 'Week 1',
      'title': 'Python Fundamentals',
      'topics': ['Variables & Data Types', 'Conditions & Loops', 'Functions'],
    },
    {
      'week': 'Week 2',
      'title': 'SQL Basics',
      'topics': ['SELECT & WHERE', 'JOIN', 'GROUP BY'],
    },
    {
      'week': 'Week 3',
      'title': 'Data Analysis',
      'topics': ['Pandas', 'Data Cleaning', 'Basic Visualization'],
    },
    {
      'week': 'Week 4',
      'title': 'Project & Resume',
      'topics': ['Mini Project', 'GitHub', 'Resume Improvement'],
    },
  ];

  @override
  void dispose() {
    jobController.dispose();
    super.dispose();
  }

  void uploadResume() {
    setState(() {
      resumeUploaded = true;
      analysisDone = false;
      matchPercentage = 0;
      matchedSkills = [];
      missingSkills = [];
    });

    showMessage('Resume uploaded successfully ✅');
  }

  Future<void> analyzeResume() async {
    if (!resumeUploaded) {
      showMessage('Pehle resume upload karo.');
      return;
    }

    if (jobController.text.trim().isEmpty) {
      showMessage('Job description enter karo.');
      return;
    }

    setState(() {
      isAnalyzing = true;
      analysisDone = false;
    });

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'resume_text': 'Python SQL Git Flutter Firebase Data Analysis Machine Learning Dart',
          'job_description': jobController.text.trim(),
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        setState(() {
          matchPercentage = (data['match_percentage'] ?? 0) as int;

          matchedSkills = List<String>.from(data['matched_skills'] ?? []);

          missingSkills = List<String>.from(data['missing_skills'] ?? []);

          analysisDone = true;
        });

        showMessage('Resume analysis complete 🎯');
      } else {
        showMessage('Backend error: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;

      showMessage('Backend se connection nahi ho pa raha.');
    } finally {
      if (mounted) {
        setState(() {
          isAnalyzing = false;
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

  void showRoadmap() {
    if (!analysisDone) {
      showMessage('Pehle resume analysis complete karo.');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.78,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '1-Month Learning Roadmap',
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text('Missing skills improve karne ke liye roadmap.'),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      itemCount: roadmap.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = roadmap[index];

                        return Card(
                          child: ExpansionTile(
                            leading: CircleAvatar(child: Text('${index + 1}')),
                            title: Text(
                              item['title'].toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(item['week'].toString()),
                            children: [
                              for (final topic
                                  in item['topics'] as List<String>)
                                ListTile(
                                  dense: true,
                                  leading: const Icon(
                                    Icons.check_circle_outline,
                                  ),
                                  title: Text(topic),
                                ),
                            ],
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
      appBar: AppBar(title: const Text('SkillBridge')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(
                          Icons.work_outline_rounded,
                          size: 30,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Resume → Job Match',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Resume skills ko job requirements se compare karo.',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                '1. Upload Resume',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Icon(
                        resumeUploaded
                            ? Icons.description_rounded
                            : Icons.upload_file_rounded,
                        size: 48,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        resumeUploaded
                            ? 'Resume uploaded successfully'
                            : 'Upload your resume',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        resumeUploaded
                            ? 'Resume is ready for analysis.'
                            : 'PDF/DOCX upload support will be connected here.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: uploadResume,
                        icon: const Icon(Icons.upload_rounded),
                        label: Text(
                          resumeUploaded ? 'Replace Resume' : 'Upload Resume',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                '2. Job Description',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: jobController,
                maxLines: 7,
                decoration: const InputDecoration(
                  hintText: 'Paste job description here...\n\nExample: Looking for a developer with Python, SQL and Flutter skills.',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 90),
                    child: Icon(Icons.work_history_outlined),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: isAnalyzing ? null : analyzeResume,
                icon: isAnalyzing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.analytics_outlined),
                label: Text(isAnalyzing ? 'Analyzing...' : 'Analyze Resume'),
              ),

              const SizedBox(height: 24),

              if (analysisDone) ...[
                Text(
                  '3. Match Result',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

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

                        const SizedBox(height: 18),

                        Text(
                          matchPercentage >= 70
                              ? 'Good match! 🎯'
                              : 'Skills improve karne ki zarurat hai.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  'Matched Skills',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: matchedSkills.isEmpty
                        ? const ListTile(
                            title: Text('No matching skills found.'),
                          )
                        : Column(
                            children: [
                              for (final skill in matchedSkills)
                                ListTile(
                                  leading: CircleAvatar(
                                    child: const Icon(Icons.check_rounded),
                                  ),
                                  title: Text(
                                    skill,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 20),
                Text(
                  'Missing Skills',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: missingSkills.isEmpty
                        ? const ListTile(
                            leading: Icon(Icons.verified_rounded),
                            title: Text('No major missing skills found 🎉'),
                          )
                        : Column(
                            children: [
                              for (final skill in missingSkills)
                                ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        theme.colorScheme.errorContainer,
                                    child: Icon(
                                      Icons.priority_high_rounded,
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                  title: Text(
                                    skill,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.school_outlined),
                    ),
                    title: const Text(
                      'Create Learning Roadmap',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('4-week plan based on your skills.'),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                    ),
                    onTap: showRoadmap,
                  ),
                ),
              ],

              const SizedBox(height: 24),

              Card(
                color: theme.colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.cloud_done_rounded,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'SkillBridge ab FastAPI backend se connected hai. '
                          'Advanced AI analysis baad me add karenge.',
                          style: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              OutlinedButton.icon(
                onPressed: () {
                  showMessage('SkillBridge backend connected 🚀');
                },
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Backend Connected'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
