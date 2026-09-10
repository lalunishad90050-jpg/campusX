import 'package:flutter/material.dart';

class SkillBridgeScreen extends StatefulWidget {
  const SkillBridgeScreen({super.key});

  @override
  State<SkillBridgeScreen> createState() => _SkillBridgeScreenState();
}

class _SkillBridgeScreenState extends State<SkillBridgeScreen> {
  final TextEditingController jobController = TextEditingController();

  bool resumeUploaded = false;
  bool isAnalyzing = false;

  @override
  void dispose() {
    jobController.dispose();
    super.dispose();
  }

  void uploadResume() {
    setState(() {
      resumeUploaded = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Resume selected successfully ✓')),
    );
  }

  void analyzeSkills() {
    if (!resumeUploaded || jobController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload a resume and add a job description.'),
        ),
      );
      return;
    }

    setState(() {
      isAnalyzing = true;
    });

    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;

      setState(() {
        isAnalyzing = false;
      });

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text(
              'Skill Analysis 📊',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Resume vs Job Match',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  '78%',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const Text('Match Score', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 20),
                const Text(
                  'Suggested skills to learn:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _skillChip('Python'),
                    _skillChip('SQL'),
                    _skillChip('Data Analysis'),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ],
          );
        },
      );
    });
  }

  Widget _skillChip(String text) {
    return Chip(
      label: Text(text),
      avatar: const Icon(Icons.check_circle_outline, size: 18),
    );
  }

  void showRoadmap() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Learning roadmap feature selected.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SkillBridge',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primaryContainer,
                    theme.colorScheme.surface,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.work_outline,
                    size: 38,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'SkillBridge 💼',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Match your skills with your dream job.',
                    style: TextStyle(
                      fontSize: 15,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Step 1 — Resume',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(14),
                leading: CircleAvatar(
                  radius: 25,
                  child: Icon(resumeUploaded ? Icons.check : Icons.upload_file),
                ),
                title: Text(
                  resumeUploaded ? 'Resume Uploaded ✓' : 'Upload Resume',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  resumeUploaded
                      ? 'Resume is ready for analysis'
                      : 'Select your resume file',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                onTap: uploadResume,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Step 2 — Job Description',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: jobController,
              maxLines: 7,
              decoration: InputDecoration(
                hintText: 'Paste the job description here...',
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 12, right: 8, top: 12),
                  child: Icon(Icons.description_outlined),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 45,
                  minHeight: 45,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Step 3 — Analyze',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(14),
                leading: const CircleAvatar(
                  radius: 25,
                  child: Icon(Icons.analytics_outlined),
                ),
                title: const Text(
                  'Skill Match',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Compare your resume with job requirements',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                onTap: analyzeSkills,
              ),
            ),

            const SizedBox(height: 12),

            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(14),
                leading: const CircleAvatar(
                  radius: 25,
                  child: Icon(Icons.school_outlined),
                ),
                title: const Text(
                  'Learning Roadmap',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Get a plan for improving missing skills'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                onTap: showRoadmap,
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: isAnalyzing ? null : analyzeSkills,
                icon: isAnalyzing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(
                  isAnalyzing ? 'Analyzing...' : 'Analyze My Skills',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tip: Add a complete job description for a better skill match.',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
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
