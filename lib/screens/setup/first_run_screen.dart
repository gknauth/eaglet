import 'package:flutter/material.dart';
import '../../database/repositories/instructor_repository.dart';
import '../../models/instructor.dart';
import '../students/student_list_screen.dart';

class FirstRunScreen extends StatefulWidget {
  const FirstRunScreen({super.key});

  @override
  State<FirstRunScreen> createState() => _FirstRunScreenState();
}

class _FirstRunScreenState extends State<FirstRunScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _certificateController = TextEditingController();
  final _notesController = TextEditingController();
  final _repository = InstructorRepository();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _certificateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final instructor = Instructor(
        name:        _nameController.text.trim(),
        certificate: _certificateController.text.trim().isEmpty
            ? null
            : _certificateController.text.trim(),
        notes:       _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt:   DateTime.now().toIso8601String(),
      );

      final saved = await _repository.insert(instructor);
      await _repository.setCurrentInstructor(saved.id!);

      if (!mounted) return;

      // Replace the first-run screen with the student list
      // so the user can't navigate back to setup
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const StudentListScreen()),
      );
    } catch (e) {
      setState(() => _isSaving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to Eaglet'),
        automaticallyImplyLeading: false, // no back button
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Let\'s set up your instructor profile.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),

              // Name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Your Name *',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Certificate number field
              TextFormField(
                controller: _certificateController,
                decoration: const InputDecoration(
                  labelText: 'CFI Certificate Number',
                  hintText: 'Optional',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 16),

              // Notes field
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Optional',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // Save button
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSaving
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text(
                  'Save and Continue',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}