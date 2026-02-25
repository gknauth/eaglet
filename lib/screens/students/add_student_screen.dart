import 'package:flutter/material.dart';
import '../../database/repositories/student_repository.dart';
import '../../models/student.dart';

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({super.key});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  final _repository = StudentRepository();
  String? _selectedCertLevel;
  bool _isSaving = false;

  static const List<Map<String, String>> _certLevels = [
    {'value': 'student',        'label': 'Student Pilot'},
    {'value': 'private_add',    'label': 'Adding Glider to Private'},
    {'value': 'commercial_add', 'label': 'Adding Glider to Commercial'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final student = Student(
        name:      _nameController.text.trim(),
        certLevel: _selectedCertLevel,
        notes:     _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: DateTime.now().toIso8601String(),
      );

      final saved = await _repository.insert(student);

      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } catch (e) {
      setState(() => _isSaving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving student: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Student'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // Name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Student Name *',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the student\'s name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Certificate level dropdown
              DropdownButtonFormField<String>(
                value: _selectedCertLevel,
                decoration: const InputDecoration(
                  labelText: 'Training Goal',
                  border: OutlineInputBorder(),
                ),
                hint: const Text('Select training goal'),
                items: _certLevels.map((level) {
                  return DropdownMenuItem<String>(
                    value: level['value'],
                    child: Text(level['label']!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCertLevel = value);
                },
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
                  'Save Student',
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