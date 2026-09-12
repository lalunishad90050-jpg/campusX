import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/attendance_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/campus_map_screen.dart';
import 'screens/copycatcher_screen.dart';
import 'screens/examwarrior_screen.dart';
import 'screens/home_screen.dart';
import 'screens/safety_screen.dart';
import 'screens/skillbridge_screen.dart';
import 'screens/teacher_dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const CampusX());
}

class CampusX extends StatelessWidget {
  const CampusX({super.key});

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF070B1A);
    const surface = Color(0xFF10172A);
    const primary = Color(0xFF6366F1);
    const secondary = Color(0xFF22D3EE);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CampusX',

      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,

        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.dark,
          surface: surface,
        ).copyWith(primary: primary, secondary: secondary, surface: surface),

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),

        cardTheme: CardThemeData(
          color: Colors.white.withValues(alpha: 0.055),
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.06),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: secondary, width: 1.5),
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            backgroundColor: primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            foregroundColor: Colors.white,
            side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),

        dividerTheme: DividerThemeData(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),

      initialRoute: '/auth',

      routes: {
        '/auth': (context) => const AuthScreen(),
        '/': (context) => const HomeScreen(),
        '/safety': (context) => const SafetyScreen(),
        '/attendance': (context) => const AttendanceScreen(),
        '/examwarrior': (context) => const ExamWarriorScreen(),
        '/skillbridge': (context) => const SkillBridgeScreen(),
        '/copycatcher': (context) => const CopyCatcherScreen(),
        '/admin': (context) => const AdminDashboardScreen(),
        '/teacher': (context) => const TeacherDashboardScreen(),
        '/campus-map': (context) => const CampusMapScreen(),
      },
    );
  }
}
