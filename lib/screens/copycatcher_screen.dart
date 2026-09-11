import 'package:flutter/material.dart';

class CopyCatcherScreen extends StatefulWidget {
  const CopyCatcherScreen({super.key});

  @override
  State<CopyCatcherScreen> createState() => _CopyCatcherScreenState();
}

class _CopyCatcherScreenState extends State<CopyCatcherScreen> {
  bool assignmentUploaded = false;
  bool isChecking = false;
  bool reportReady = false;

  int similarityPercentage = 0;
  int originalityPercentage = 0;
  int aiPercentage = 0;

  void uploadAssignment() {
    setState(() {
      assignmentUploaded = true;
      reportReady = false;
    });

    showMessage('Assignment uploaded successfully ✅');
  }

  Future<void> checkAssignment() async {
    if (!assignmentUploaded) {
      showMessage('Pehle assignment upload karo.');
      return;
    }

    setState(() {
      isChecking = true;
      reportReady = false;
    });

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() {
      isChecking = false;
      reportReady = true;

      similarityPercentage = 18;
      originalityPercentage = 82;
      aiPercentage = 12;
    });

    showMessage('Assignment analysis complete 🎯');
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void showDetailedReport() {
    if (!reportReady) {
      showMessage('Pehle assignment check karo.');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.72,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Originality Report',
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _ReportItem(
                    icon: Icons.copy_outlined,
                    title: 'Internet Similarity',
                    value: '$similarityPercentage%',
                  ),
                  _ReportItem(
                    icon: Icons.auto_awesome_outlined,
                    title: 'AI-like Text Indicator',
                    value: '$aiPercentage%',
                  ),
                  _ReportItem(
                    icon: Icons.verified_outlined,
                    title: 'Original Content',
                    value: '$originalityPercentage%',
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Note: Ye current frontend demo result hai. '
                        'Real plagiarism aur AI-content analysis secure '
                        'backend/API integration ke baad perform hoga.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
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
      appBar: AppBar(title: const Text('CopyCatcher')),
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
                          Icons.content_copy_rounded,
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
                              'Assignment Analyzer',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Check similarity, originality and AI-like content.',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 22),

              Text(
                '1. Upload Assignment',
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
                      Icon(
                        assignmentUploaded
                            ? Icons.description_rounded
                            : Icons.upload_file_rounded,
                        size: 52,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        assignmentUploaded
                            ? 'Assignment uploaded'
                            : 'Upload your assignment',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        assignmentUploaded
                            ? 'Your file is ready for checking.'
                            : 'PDF/DOCX upload support will be connected here.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: uploadAssignment,
                        icon: const Icon(Icons.upload_rounded),
                        label: Text(
                          assignmentUploaded
                              ? 'Replace Assignment'
                              : 'Upload Assignment',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                '2. Run Analysis',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              ElevatedButton.icon(
                onPressed: isChecking ? null : checkAssignment,
                icon: isChecking
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search_rounded),
                label: Text(
                  isChecking ? 'Checking Assignment...' : 'Check Assignment',
                ),
              ),

              const SizedBox(height: 24),

              if (reportReady) ...[
                Text(
                  '3. Analysis Result',
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
                          height: 150,
                          width: 150,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                height: 150,
                                width: 150,
                                child: CircularProgressIndicator(
                                  value: originalityPercentage / 100,
                                  strokeWidth: 14,
                                  backgroundColor:
                                      theme.colorScheme.surfaceContainerHighest,
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$originalityPercentage%',
                                    style: theme.textTheme.headlineMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const Text('Original'),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        Row(
                          children: [
                            Expanded(
                              child: _ResultCard(
                                title: 'Similarity',
                                value: '$similarityPercentage%',
                                icon: Icons.copy_outlined,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _ResultCard(
                                title: 'AI Indicator',
                                value: '$aiPercentage%',
                                icon: Icons.auto_awesome_outlined,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Icon(Icons.assessment_outlined),
                    ),
                    title: const Text(
                      'View Detailed Report',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'See similarity and originality details',
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                    ),
                    onTap: showDetailedReport,
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
                        Icons.info_outline_rounded,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Real plagiarism detection ke liye internet '
                          'similarity, classmate comparison aur AI-text '
                          'analysis backend/API se connect kiya jayega.',
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
                  showMessage(
                    'CopyCatcher AI backend next phase me connect hoga 🚀',
                  );
                },
                icon: const Icon(Icons.cloud_outlined),
                label: const Text('AI Backend Status'),
              ),

              const SizedBox(height: 10),

              Text(
                'CopyCatcher frontend demo ready',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _ResultCard({
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
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(title, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ReportItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _ReportItem({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text(
          value,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
