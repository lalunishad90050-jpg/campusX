import 'package:flutter/material.dart';

import 'safety_screen.dart';
import 'attendance_screen.dart';
import 'examwarrior_screen.dart';
import 'skillbridge_screen.dart';
import 'copycatcher_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void openScreen(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CampusX',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No new notifications')),
              );
            },
            icon: const Icon(Icons.notifications_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome section
            Text(
              'Welcome to CampusX 👋',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Your smart campus companion',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 22),

            // Campus Safety
            Card(
              elevation: 4,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  openScreen(context, const SafetyScreen());
                },
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(
                          Icons.security,
                          size: 32,
                          color: theme.colorScheme.primary,
                        ),
                      ),

                      const SizedBox(width: 16),

                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Campus Safety',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Report unsafe areas and help improve campus safety.',
                            ),
                          ],
                        ),
                      ),

                      const Icon(Icons.arrow_forward_ios, size: 17),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 26),

            const Text(
              'Campus Tools',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            // Tools
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.05,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                FeatureCard(
                  icon: Icons.fingerprint,
                  title: 'Attendance',
                  subtitle: 'Track attendance',
                  onTap: () {
                    openScreen(context, const AttendanceScreen());
                  },
                ),

                FeatureCard(
                  icon: Icons.menu_book,
                  title: 'ExamWarrior',
                  subtitle: 'PYQs & practice',
                  onTap: () {
                    openScreen(context, const ExamWarriorScreen());
                  },
                ),

                FeatureCard(
                  icon: Icons.work_outline,
                  title: 'SkillBridge',
                  subtitle: 'Skills & careers',
                  onTap: () {
                    openScreen(context, const SkillBridgeScreen());
                  },
                ),

                FeatureCard(
                  icon: Icons.content_copy,
                  title: 'CopyCatcher',
                  subtitle: 'Originality check',
                  onTap: () {
                    openScreen(context, const CopyCatcherScreen());
                  },
                ),
              ],
            ),

            const SizedBox(height: 26),

            const Text(
              'CampusX Features',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: theme.colorScheme.secondaryContainer,
                      child: Icon(
                        Icons.auto_awesome,
                        color: theme.colorScheme.secondary,
                      ),
                    ),

                    const SizedBox(width: 14),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Smart Campus',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Safety, learning, attendance and career tools in one app.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Quick info
            Card(
              elevation: 2,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    Icons.dashboard_outlined,
                    color: theme.colorScheme.primary,
                  ),
                ),
                title: const Text(
                  'Everything in one place',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Access all CampusX tools directly from your dashboard.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(icon, size: 28, color: theme.colorScheme.primary),
              ),

              const SizedBox(height: 10),

              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
