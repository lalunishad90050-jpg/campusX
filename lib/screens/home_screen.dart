import 'package:flutter/material.dart';

import '../widgets/ai_voice_assistant.dart';
import '../widgets/animated_3d_background.dart';
import '../widgets/campusx_glass_card.dart';

import 'attendance_screen.dart';
import 'copycatcher_screen.dart';
import 'examwarrior_screen.dart';
import 'safety_screen.dart';
import 'skillbridge_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void openScreen(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.hub_rounded, size: 26, color: Color(0xFF22D3EE)),
            SizedBox(width: 9),
            Text(
              'CampusX',
              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.3),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No new notifications')),
              );
            },
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CampusXAnimatedBackground(
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 82, 18, 150),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CampusXGlassCard(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                height: 52,
                                width: 52,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF6366F1),
                                      Color(0xFF22D3EE),
                                    ],
                                  ),
                                ),
                                child: const Icon(
                                  Icons.auto_awesome_rounded,
                                  color: Colors.white,
                                  size: 27,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 11,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF22D3EE)
                                      .withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: const Color(0xFF22D3EE)
                                        .withValues(alpha: 0.20),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.circle,
                                      size: 7,
                                      color: Color(0xFF22D3EE),
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'SMART CAMPUS',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                        color: Color(0xFF67E8F9),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          Text(
                            'Welcome to CampusX 👋',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),

                          const SizedBox(height: 7),

                          Text(
                            'Your intelligent campus companion',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.white.withValues(alpha: 0.60),
                            ),
                          ),

                          const SizedBox(height: 20),

                          Row(
                            children: const [
                              _MiniStatus(
                                icon: Icons.security_rounded,
                                text: 'Safety',
                              ),
                              SizedBox(width: 8),
                              _MiniStatus(
                                icon: Icons.school_rounded,
                                text: 'Learning',
                              ),
                              SizedBox(width: 8),
                              _MiniStatus(
                                icon: Icons.work_outline_rounded,
                                text: 'Career',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    CampusXGlassCard(
                      padding: EdgeInsets.zero,
                      onTap: () {
                        openScreen(context, const SafetyScreen());
                      },
                      child: Container(
                        padding: const EdgeInsets.all(19),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF6366F1).withValues(alpha: 0.20),
                              const Color(0xFF22D3EE).withValues(alpha: 0.05),
                            ],
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              height: 58,
                              width: 58,
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1)
                                    .withValues(alpha: 0.20),
                                borderRadius: BorderRadius.circular(17),
                              ),
                              child: const Icon(
                                Icons.shield_rounded,
                                color: Color(0xFF818CF8),
                                size: 31,
                              ),
                            ),

                            const SizedBox(width: 15),

                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'CampusShield',
                                    style: TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    'Report unsafe areas and help make campus safer.',
                                    style: TextStyle(
                                      color: Colors.white60,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 8),

                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: Colors.white54,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    const Text(
                      'Campus Tools',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      'Everything you need, connected in one place.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.50),
                      ),
                    ),

                    const SizedBox(height: 15),

                    LayoutBuilder(
                      builder: (context, constraints) {
                        final cardWidth = (constraints.maxWidth - 12) / 2;

                        return GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: cardWidth / 205,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            FeatureCard(
                              icon: Icons.fingerprint_rounded,
                              title: 'Attendance',
                              subtitle: 'Track attendance',
                              iconColor: const Color(0xFF22D3EE),
                              onTap: () {
                                openScreen(context, const AttendanceScreen());
                              },
                            ),

                            FeatureCard(
                              icon: Icons.menu_book_rounded,
                              title: 'ExamWarrior',
                              subtitle: 'PYQs & practice',
                              iconColor: const Color(0xFFA78BFA),
                              onTap: () {
                                openScreen(context, const ExamWarriorScreen());
                              },
                            ),

                            FeatureCard(
                              icon: Icons.work_outline_rounded,
                              title: 'SkillBridge',
                              subtitle: 'Skills & careers',
                              iconColor: const Color(0xFF34D399),
                              onTap: () {
                                openScreen(context, const SkillBridgeScreen());
                              },
                            ),

                            FeatureCard(
                              icon: Icons.content_copy_rounded,
                              title: 'CopyCatcher',
                              subtitle: 'Originality check',
                              iconColor: const Color(0xFFF59E0B),
                              onTap: () {
                                openScreen(context, const CopyCatcherScreen());
                              },
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 28),
                    CampusXGlassCard(
                      child: Row(
                        children: [
                          Container(
                            height: 50,
                            width: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFF22D3EE)
                                  .withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Icon(
                              Icons.psychology_rounded,
                              color: Color(0xFF22D3EE),
                              size: 28,
                            ),
                          ),

                          const SizedBox(width: 14),

                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AI-Powered Campus',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'Smart insights across safety, learning, attendance and careers.',
                                  style: TextStyle(
                                    color: Colors.white60,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    CampusXGlassCard(
                      child: Row(
                        children: [
                          Container(
                            height: 46,
                            width: 46,
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.dashboard_customize_rounded,
                              color: Color(0xFF818CF8),
                            ),
                          ),

                          const SizedBox(width: 13),

                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'One Smart Dashboard',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'All CampusX tools are just one tap away.',
                                  style: TextStyle(color: Colors.white60),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // =========================
              // FLOATING AI ROBOT
              // =========================
              const Positioned(left: 18, top: 15, child: AIVoiceAssistant()),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStatus extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MiniStatus({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.045),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF67E8F9)),
            const SizedBox(height: 4),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
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
  final Color iconColor;
  final VoidCallback onTap;

  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CampusXGlassCard(
      padding: const EdgeInsets.all(15),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 58,
            width: 58,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: iconColor.withValues(alpha: 0.16)),
            ),
            child: Icon(icon, size: 29, color: iconColor),
          ),

          const SizedBox(height: 12),

          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),

          const SizedBox(height: 5),

          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Colors.white54),
          ),

          const SizedBox(height: 9),

          Icon(
            Icons.arrow_forward_rounded,
            size: 17,
            color: iconColor.withValues(alpha: 0.65),
          ),
        ],
      ),
    );
  }
}
