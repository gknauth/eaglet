import 'package:flutter/material.dart';
import 'database/repositories/instructor_repository.dart';
import 'screens/setup/first_run_screen.dart';
import 'screens/students/student_list_screen.dart';

void main() async {
  // Required when calling native code (like sqflite) before runApp
  WidgetsFlutterBinding.ensureInitialized();

  final repository = InstructorRepository();
  final isSetupComplete = await repository.isSetupComplete();

  runApp(EagletApp(isSetupComplete: isSetupComplete));
}

class EagletApp extends StatelessWidget {
  final bool isSetupComplete;

  const EagletApp({super.key, required this.isSetupComplete});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eaglet',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: isSetupComplete
          ? const StudentListScreen()
          : const FirstRunScreen(),
    );
  }
}