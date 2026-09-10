import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/attendance_screen.dart';
import 'screens/auth_screen.dart';
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CampusX',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          titleTextStyle: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
        ),
        cardTheme: CardThemeData(
          elevation: 3,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),

      initialRoute: '/auth',

      routes: {
        // Authentication
        '/auth': (context) => const AuthScreen(),

        // Student
        '/': (context) => const HomeScreen(),
        '/safety': (context) => const SafetyScreen(),
        '/attendance': (context) => const AttendanceScreen(),
        '/examwarrior': (context) => const ExamWarriorScreen(),
        '/skillbridge': (context) => const SkillBridgeScreen(),
        '/copycatcher': (context) => const CopyCatcherScreen(),

        // Admin
        '/admin': (context) => const AdminDashboardScreen(),

        // Teacher
        '/teacher': (context) => const TeacherDashboardScreen(),
      },
    );
  }
}
