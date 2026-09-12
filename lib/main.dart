import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

import 'screens/ai_welcome_screen.dart';
import 'screens/attendance_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/campus_map_screen.dart';
import 'screens/copycatcher_screen.dart';
import 'screens/examwarrior_screen.dart';
import 'screens/home_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/safety_screen.dart';
import 'screens/skillbridge_screen.dart';
import 'screens/teacher_dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const CampusXApp());
}

class CampusXApp extends StatelessWidget {
  const CampusXApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6366F1);
    const backgroundColor = Color(0xFF070B1A);

    return MaterialApp(
      title: 'CampusX',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,

        scaffoldBackgroundColor: backgroundColor,

        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.dark,
          surface: backgroundColor,
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: backgroundColor,
          elevation: 0,
          centerTitle: false,
        ),

        cardTheme: CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: Color(0xFF11172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF11172A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide(color: primaryColor, width: 1.5),
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),

      initialRoute: '/welcome',

      routes: {
        '/welcome': (context) => const AIWelcomeScreen(),

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
