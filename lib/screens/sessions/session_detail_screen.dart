import 'package:flutter/material.dart';
import '../../database/repositories/aircraft_repository.dart';
import '../../database/repositories/session_repository.dart';
import '../../database/repositories/syllabus_repository.dart';
import '../../models/aircraft.dart';
import '../../models/session_item.dart';
import '../../models/syllabus_item.dart';
import '../../models/training_session.dart';

class SessionDetailScreen extends StatefulWidget {
  final TrainingSession session;
  const SessionDetailScreen({super.key, required this.session});

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  final _sessionRepository  = SessionRepository();
  final _syllabusRepository = SyllabusRepository();
  final _aircraftRepository = AircraftRepository();

  final _durationController = TextEditingController();
  final _notesController    = TextEditingController();
  late DateTime _sessionDate;

  List<SessionItem>      _items       = [];
  Map<int, SyllabusItem> _syllabusMap = {};
  List<Aircraft>         _aircraftList = [];
  Aircraft?              _selectedAircraft;

  // edit mode state
  bool              _editMode    = false;
  Map<int, bool>    _itemExpanded = {};  // sessionItem index -> expanded

  static const List<String> _levels = ['L1', 'L2', 'L3', 'RES', 'PRO'];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final items         = await _sessionRepository.getItemsForSession(
      widget.session.id,
    );
    final syllabusItems = await _syllabusRepository.getItems();
    final syllabusMap   = <int, SyllabusItem>{};
    for (final s in syllabusItems) {
      syllabusMap[s.id] = s;
    }

    final aircraftList = await _aircraftRepository.getAll();
    Aircraft? selectedAircraft;
    if (widget.session.aircraftId != null) {
      selectedAircraft = aircraftList.firstWhere(
            (a) => a.id == widget.session.aircraftId,
        orElse: () => aircraftList.first,
      );
    }

    _durationController.text =
        widget.session.durationMinutes?.toString() ?? '';
    _notesController.text    = widget.session.notes ?? '';

    _sessionDate = DateTime.parse(widget.session.sessionDate);

    setState(() {
      _items            = items;
      _syllabusMap      = syllabusMap;
      _aircraftList     = aircraftList;
      _selectedAircraft = selectedAircraft;
      _isLoading        = false;
    });
  }

  Future<void> _saveHeader() async {
    final current = await _sessionRepository.getById(widget.session.id);
    if (current == null) return;
    final updated = current.copyWith(
      sessionDate:     _sessionDate.toIso8601String(),
      aircraftId:      _selectedAircraft?.id,
      durationMinutes: int.tryParse(_durationController.text.trim()),
      notes:           _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );
    await _sessionRepository.update(updated);
  }

  Future<void> _updateItemLevel(SessionItem item, String level) async {
    final updated = item.copyWith(
      level:     level,
      timestamp: DateTime.now().toIso8601String(),
    );
    await _sessionRepository.updateItem(updated);
    setState(() {
      final index = _items.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        _items[index]      = updated;
        _itemExpanded[index] = false;
      }
    });
  }

  Future<void> _deleteItem(SessionItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Item'),
        content: Text(
          'Remove ${_syllabusMap[item.itemId]?.title ?? 'this item'} '
              'from the session?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _sessionRepository.deleteItem(item.id);
    setState(() {
      _items.removeWhere((i) => i.id == item.id);
    });
  }

  Future<void> _deleteSession() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Session'),
        content: const Text(
          'Delete this entire session? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete Session'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _sessionRepository.deleteSessionAndItems(widget.session.id);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _toggleEditMode() {
    if (_editMode) {
      // Save on exit from edit mode
      _saveHeader();
    }
    setState(() {
      _editMode     = !_editMode;
      _itemExpanded = {};
    });
  }

  String _formatDateTime(String isoDate) {
    final date = DateTime.parse(isoDate);
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatTime(String isoTimestamp) {
    final dt = DateTime.parse(isoTimestamp);
    final h  = dt.hour.toString().padLeft(2, '0');
    final m  = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _pickDateTime() async {
    // First pick the date
    final date = await showDatePicker(
      context: context,
      initialDate: _sessionDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date == null) return;

    // Then pick the time
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_sessionDate),
    );
    if (time == null) return;

    setState(() {
      _sessionDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Widget _buildHeader() {
    if (!_editMode) {
      // Read-only header
      return Card(
        margin: const EdgeInsets.all(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    _formatDateTime(_sessionDate.toIso8601String()),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (_selectedAircraft != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.flight, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(_selectedAircraft!.displayName),
                  ],
                ),
              ],
              if (widget.session.durationMinutes != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.timer, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text('${widget.session.durationMinutes} minutes'),
                  ],
                ),
              ],
              if (widget.session.notes != null &&
                  widget.session.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 4),
                Text(
                  widget.session.notes!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Editable header
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date/time picker
            InkWell(
              onTap: _pickDateTime,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date & Time',
                  border: OutlineInputBorder(),
                  isDense: true,
                  suffixIcon: Icon(Icons.calendar_today, size: 18),
                ),
                child: Text(
                  _formatDateTime(_sessionDate.toIso8601String()),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Aircraft picker
            DropdownButtonFormField<Aircraft>(
              value: _selectedAircraft,
              decoration: const InputDecoration(
                labelText: 'Aircraft',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              hint: const Text('Select aircraft'),
              items: _aircraftList.map((a) {
                return DropdownMenuItem<Aircraft>(
                  value: a,
                  child: Text(a.displayName),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedAircraft = value);
              },
            ),
            const SizedBox(height: 12),

            // Duration
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

            // Notes
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Session Notes',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelButton(SessionItem item, String level) {
    final isSelected = item.level == level;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: ElevatedButton(
        onPressed: () => _updateItemLevel(item, level),
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
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildItemRow(int index, SessionItem item) {
    final syllabus   = _syllabusMap[item.itemId];
    final isExpanded = _itemExpanded[index] ?? false;

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Column(
        children: [
          // Item header
          InkWell(
            onTap: _editMode
                ? () => setState(() {
              _itemExpanded[index] = !isExpanded;
            })
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          syllabus?.code ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          syllabus?.title ?? 'Unknown item',
                          style: const TextStyle(fontSize: 13),
                        ),
                        if (item.notes != null &&
                            item.notes!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.notes!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Level badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.level,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),

                  // Time or delete button
                  if (_editMode) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.red, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _deleteItem(item),
                    ),
                  ] else ...[
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(item.timestamp),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Inline level selector in edit mode
          if (_editMode && isExpanded)
            Container(
              color: Theme.of(context).colorScheme.surface,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: _levels
                    .map((l) => _buildLevelButton(item, l))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_formatDateTime(_sessionDate.toIso8601String())),
        actions: [
          TextButton(
            onPressed: _toggleEditMode,
            child: Text(_editMode ? 'Done' : 'Edit'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _buildHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Text(
                  '${_items.length} item${_items.length == 1 ? '' : 's'} covered',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) =>
                  _buildItemRow(index, _items[index]),
            ),
          ),

          // Delete session button — only in edit mode
          if (_editMode)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _deleteSession,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Delete Session'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}