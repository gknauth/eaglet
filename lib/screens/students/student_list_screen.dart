import 'package:flutter/material.dart';
import '../../database/repositories/student_repository.dart';
import '../../models/student.dart';
import 'add_student_screen.dart';
import 'student_detail_screen.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final _repository = StudentRepository();
  List<Student> _students = [];
  List<Student> _filtered = [];
  final _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    final students = await _repository.getAll();
    setState(() {
      _students = students;
      _filtered = students;
      _isLoading = false;
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filtered = query.isEmpty
          ? _students
          : _students
          .where((s) => s.name.toLowerCase().contains(query))
          .toList();
    });
  }

  Future<void> _navigateToAddStudent() async {
    final added = await Navigator.of(context).push<Student>(
      MaterialPageRoute(builder: (_) => const AddStudentScreen()),
    );
    if (added != null) _loadStudents();
  }

  Future<void> _navigateToStudentDetail(Student student) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudentDetailScreen(student: student),
      ),
    );
    _loadStudents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search students...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
                    : null,
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filtered.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              _students.isEmpty
                  ? 'No students yet.\nTap + to add your first student.'
                  : 'No students match your search.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadStudents,
        child: ListView.separated(
          itemCount: _filtered.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final student = _filtered[index];
            return ListTile(
              leading: CircleAvatar(
                child: Text(
                  student.name[0].toUpperCase(),
                ),
              ),
              title: Text(student.name),
              subtitle: student.certLevel != null
                  ? Text(student.certLevel!)
                  : null,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _navigateToStudentDetail(student),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddStudent,
        tooltip: 'Add Student',
        child: const Icon(Icons.add),
      ),
    );
  }
}