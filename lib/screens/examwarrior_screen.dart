import 'package:flutter/material.dart';

class ExamWarriorScreen extends StatelessWidget {
  const ExamWarriorScreen({super.key});

  void showFeature(BuildContext context, String title) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$title selected')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ExamWarrior',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 27,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    Icons.menu_book,
                    size: 30,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ExamWarrior 📚',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text('Prepare smarter and score better.'),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Progress card
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    SizedBox(
                      width: 75,
                      height: 75,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: 0.68,
                            strokeWidth: 8,
                            backgroundColor: Colors.grey.shade200,
                          ),
                          const Text(
                            '68%',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Preparation Progress',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text('Keep practicing to improve your preparation.'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 26),

            const Text(
              'Study Tools',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            _ExamCard(
              icon: Icons.history_edu,
              title: 'Previous Year Papers',
              subtitle: 'Access previous year question papers',
              onTap: () => showFeature(context, 'Previous Year Papers'),
            ),

            _ExamCard(
              icon: Icons.auto_awesome,
              title: 'Topic Predictor',
              subtitle: 'Find topics that are likely to be important',
              onTap: () => showFeature(context, 'Topic Predictor'),
            ),

            _ExamCard(
              icon: Icons.quiz_outlined,
              title: 'AI Question Generator',
              subtitle: 'Generate practice questions from topics',
              onTap: () => showFeature(context, 'AI Question Generator'),
            ),

            _ExamCard(
              icon: Icons.timer_outlined,
              title: 'Practice Quiz',
              subtitle: 'Test your preparation with timed quizzes',
              onTap: () => showFeature(context, 'Practice Quiz'),
            ),

            _ExamCard(
              icon: Icons.analytics_outlined,
              title: 'Preparation Progress',
              subtitle: 'Track your preparation and performance',
              onTap: () => showFeature(context, 'Preparation Progress'),
            ),

            const SizedBox(height: 10),

            // Start button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => showFeature(context, 'Start Preparation'),
                icon: const Icon(Icons.play_arrow),
                label: const Text(
                  'Start Preparation',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Tip card
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Study Tip',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Practice PYQs regularly and focus on frequently repeated topics.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ExamCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(subtitle),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        ),
      ),
    );
  }
}
