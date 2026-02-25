import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../database/repositories/instructor_repository.dart';
import '../../database/repositories/session_repository.dart';
import '../../database/repositories/syllabus_repository.dart';
import '../../database/repositories/aircraft_repository.dart';
import '../../models/student.dart';
import '../../models/training_session.dart';
import '../../models/session_item.dart';
import '../../models/syllabus_group.dart';
import '../../models/syllabus_item.dart';
import '../../models/aircraft.dart';

class NewSessionScreen extends StatefulWidget {
  final Student student;

  const NewSessionScreen({super.key, required this.student});

  @override
  State<NewSessionScreen> createState() => _NewSessionScreenState();
}

class _NewSessionScreenState extends State<NewSessionScreen> {
  final _uuid = const Uuid();
  final _sessionRepository = SessionRepository();
  final _syllabusRepository = SyllabusRepository();
  final _instructorRepository = InstructorRepository();
  final _durationController = TextEditingController();
  final _sessionNotesController = TextEditingController();
  final _aircraftRepository = AircraftRepository();
  List<Aircraft> _aircraft = [];
  Aircraft? _selectedAircraft;

  static const List<String> _levels = ['L1', 'L2', 'L3', 'RES', 'PRO'];

  List<SyllabusGroup> _groups = [];
  List<SyllabusItem> _items = [];
  Map<int, bool> _expanded = {}; // group_id -> expanded
  Map<int, String> _loggedLevels = {}; // item_id  -> level
  Map<int, String> _loggedIds = {}; // item_id  -> session_item id
  Map<int, bool> _itemExpanded = {}; // item_id  -> inline expanded
  Map<int, TextEditingController> _itemNoteControllers = {};

  late String _sessionId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _sessionId = _uuid.v4();
    _initSession();
  }

  @override
  void dispose() {
    _durationController.dispose();
    _sessionNotesController.dispose();
    for (final c in _itemNoteControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _initSession() async {
    // Get current instructor
    final instructor = await _instructorRepository.getCurrentInstructor();
    if (instructor == null) return;

    // Create session record immediately
    final session = TrainingSession(
      id: _sessionId,
      studentId: widget.student.id!,
      instructorId: instructor.id!,
      sessionDate: DateTime.now().toIso8601String(),
    );
    await _sessionRepository.insert(session);

    // Load syllabus
    final groups = await _syllabusRepository.getGroups();
    final items = await _syllabusRepository.getItems();

    // Default all groups expanded
    final expanded = <int, bool>{};
    for (final g in groups) {
      expanded[g.id] = true;
    }

    // Create note controllers for all items
    final noteControllers = <int, TextEditingController>{};
    for (final item in items) {
      noteControllers[item.id] = TextEditingController();
    }

    final aircraft = await _aircraftRepository.getAll();

    setState(() {
      _groups = groups;
      _items = items;
      _expanded = expanded;
      _itemNoteControllers = noteControllers;
      _aircraft = aircraft;
      _isLoading = false;
    });

    _durationController.addListener(_updateSessionDetails);
    _sessionNotesController.addListener(_updateSessionDetails);
  }

  Future<void> _updateSessionDetails() async {
    final db = await _sessionRepository.getById(_sessionId);
    if (db == null) return;
    final updated = db.copyWith(
      aircraftId: _selectedAircraft?.id,
      durationMinutes: int.tryParse(_durationController.text.trim()),
      notes: _sessionNotesController.text.trim().isEmpty
          ? null
          : _sessionNotesController.text.trim(),
    );
    await _sessionRepository.update(updated);
  }

  Future<void> _logItem(SyllabusItem item, String level) async {
    final now = DateTime.now().toIso8601String();
    final notes = _itemNoteControllers[item.id]?.text.trim();
    final existing = _loggedIds[item.id];

    if (existing != null) {
      // Update existing session item
      final sessionItem = SessionItem(
        id: existing,
        sessionId: _sessionId,
        itemId: item.id,
        level: level,
        notes: notes?.isEmpty ?? true ? null : notes,
        timestamp: now,
      );
      await _sessionRepository.updateItem(sessionItem);
    } else {
      // Insert new session item
      final sessionItem = SessionItem(
        id: _uuid.v4(),
        sessionId: _sessionId,
        itemId: item.id,
        level: level,
        notes: notes?.isEmpty ?? true ? null : notes,
        timestamp: now,
      );
      final saved = await _sessionRepository.insertItem(sessionItem);
      _loggedIds[item.id] = saved.id;
    }

    setState(() {
      _loggedLevels[item.id] = level;
      _itemExpanded[item.id] = false;
    });
  }

  Future<void> _addAircraft() async {
    final tailController = TextEditingController();
    final makeModelController = TextEditingController();

    final result = await showDialog<Aircraft>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Aircraft'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tailController,
              decoration: const InputDecoration(
                labelText: 'Tail Number *',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: makeModelController,
              decoration: const InputDecoration(
                labelText: 'Make & Model',
                hintText: 'e.g. Grob G103',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (tailController.text.trim().isEmpty) return;
              final aircraft = await _aircraftRepository.insert(
                Aircraft(
                  tailNumber: tailController.text.trim().toUpperCase(),
                  makeModel: makeModelController.text.trim().isEmpty
                      ? null
                      : makeModelController.text.trim(),
                  createdAt: DateTime.now().toIso8601String(),
                ),
              );
              if (context.mounted) Navigator.of(context).pop(aircraft);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      final aircraft = await _aircraftRepository.getAll();
      setState(() {
        _aircraft = aircraft;
        // Find the matching aircraft in the freshly loaded list by ID
        // rather than using the dialog's returned object directly
        _selectedAircraft = aircraft.firstWhere((a) => a.id == result.id);
      });
      _updateSessionDetails();
    }

    tailController.dispose();
    makeModelController.dispose();
  }

  Future<void> _finishSession() async {
    if (_loggedLevels.isEmpty) {
      // No items logged — delete the empty session
      await _sessionRepository.delete(_sessionId);
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _toggleItem(int itemId) {
    setState(() {
      _itemExpanded[itemId] = !(_itemExpanded[itemId] ?? false);
    });
  }

  Widget _buildLevelButton(SyllabusItem item, String level) {
    final isSelected = _loggedLevels[item.id] == level;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: ElevatedButton(
        onPressed: () => _logItem(item, level),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceVariant,
          foregroundColor: isSelected
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.onSurfaceVariant,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          minimumSize: const Size(0, 36),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          level,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildItemRow(SyllabusItem item) {
    final isExpanded = _itemExpanded[item.id] ?? false;
    final loggedLevel = _loggedLevels[item.id];
    final isLogged = loggedLevel != null;

    return Container(
      decoration: BoxDecoration(
        color: isLogged
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
            : null,
        border: const Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Column(
        children: [
          // Item header row
          InkWell(
            onTap: () => _toggleItem(item.id),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.code,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        Text(item.title, style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                  if (isLogged)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        loggedLevel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),

          // Inline level selector
          if (isExpanded)
            Container(
              color: Theme.of(context).colorScheme.surface,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Level buttons
                  Row(
                    children: _levels
                        .map((l) => _buildLevelButton(item, l))
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  // Notes field
                  TextField(
                    controller: _itemNoteControllers[item.id],
                    decoration: const InputDecoration(
                      hintText: 'Notes (optional)',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 13),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(SyllabusGroup group) {
    final groupItems = _items.where((i) => i.groupId == group.id).toList();
    final isExpanded = _expanded[group.id] ?? true;
    final loggedCount = groupItems
        .where((i) => _loggedLevels.containsKey(i.id))
        .length;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        children: [
          // Group header
          InkWell(
            onTap: () {
              setState(() {
                _expanded[group.id] = !isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Text(
                    group.code,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      group.title,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  if (loggedCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$loggedCount',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                  Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
          ),

          // Items
          if (isExpanded) ...[
            const Divider(height: 1),
            ...groupItems.map((item) => _buildItemRow(item)),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await _finishSession();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('New Session — ${widget.student.name}'),
          actions: [
            TextButton(onPressed: _finishSession, child: const Text('Done')),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                children: [
                  // Session details card
                  Card(
                    margin: const EdgeInsets.all(8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Session Details',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<Aircraft>(
                                  value: _selectedAircraft,
                                  decoration: const InputDecoration(
                                    labelText: 'Aircraft',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  hint: const Text('Select aircraft'),
                                  items: _aircraft.map((a) {
                                    return DropdownMenuItem<Aircraft>(
                                      value: a,
                                      child: Text(a.displayName),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() => _selectedAircraft = value);
                                    _updateSessionDetails();
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                tooltip: 'Add aircraft',
                                onPressed: _addAircraft,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _durationController,
                            decoration: const InputDecoration(
                              labelText: 'Duration (minutes)',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _sessionNotesController,
                            decoration: const InputDecoration(
                              labelText: 'Session Notes',
                              hintText: 'Optional',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Syllabus groups
                  ..._groups.map((g) => _buildGroupCard(g)),
                  const SizedBox(height: 80),
                ],
              ),
      ),
    );
  }
}
