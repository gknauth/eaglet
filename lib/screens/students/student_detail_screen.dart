import 'package:flutter/material.dart';
import '../../database/repositories/student_repository.dart';
import '../../models/student.dart';
import '../../models/syllabus_group.dart';
import '../../models/syllabus_item.dart';
import '../../models/student_item_prep.dart';
import '../../models/training_session.dart';
import '../../database/repositories/syllabus_repository.dart';
import '../../database/repositories/session_repository.dart';
import '../../database/repositories/prep_repository.dart';
import '../sessions/new_session_screen.dart';
import '../sessions/session_detail_screen.dart';
import '../../database/repositories/aircraft_repository.dart';
import '../../models/aircraft.dart';

class StudentDetailScreen extends StatefulWidget {
  final Student student;
  const StudentDetailScreen({super.key, required this.student});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showPracticedOnly = false;

  final _syllabusRepository = SyllabusRepository();
  final _sessionRepository  = SessionRepository();
  final _prepRepository     = PrepRepository();
  final _aircraftRepository = AircraftRepository();
  Map<int, Aircraft> _aircraftMap = {};

  List<SyllabusGroup> _groups = [];
  List<SyllabusItem>  _items  = [];

  // group_id -> is expanded
  Map<int, bool> _expanded = {};

  // item_id -> most recent level
  Map<int, String> _currentLevel = {};

  // item_id -> days since last practiced (null = never)
  Map<int, int?> _daysSince = {};

  // item_id -> prep record
  Map<int, StudentItemPrep> _prepMap = {};

  List<TrainingSession> _sessions = [];

  // session_id -> item count
  Map<String, int> _sessionItemCounts = {};

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final groups   = await _syllabusRepository.getGroups();
    final items    = await _syllabusRepository.getItems();
    final preps    = await _prepRepository.getForStudent(widget.student.id!);
    final sessions = await _sessionRepository.getForStudent(widget.student.id!);
    final aircraftList = await _aircraftRepository.getAll();
    final aircraftMap  = <int, Aircraft>{};
    for (final a in aircraftList) {
      aircraftMap[a.id!] = a;
    }

    // Build prep map
    final prepMap = <int, StudentItemPrep>{};
    for (final p in preps) {
      prepMap[p.itemId] = p;
    }

    // Build current level and days since maps
    final currentLevel = <int, String>{};
    final daysSince    = <int, int?>{};
    final sessionItemCounts = <String, int>{};

    for (final session in sessions) {
      final count = await _sessionRepository.getItemCount(session.id);
      sessionItemCounts[session.id] = count;
    }

    final history = await _sessionRepository.getItemHistoryForStudent(
      widget.student.id!,
    );

    final now = DateTime.now();
    for (final row in history) {
      final itemId    = row['item_id'] as int;
      final level     = row['level'] as String;
      final timestamp = DateTime.parse(row['timestamp'] as String);
      final days      = now.difference(timestamp).inDays;

      // History is ordered newest first so first hit = most recent
      if (!currentLevel.containsKey(itemId)) {
        currentLevel[itemId] = level;
        daysSince[itemId]    = days;
      }
    }

    // Default all groups to expanded
    final expanded = <int, bool>{};
    for (final g in groups) {
      expanded[g.id] = true;
    }

    setState(() {
      _groups             = groups;
      _items              = items;
      _prepMap            = prepMap;
      _currentLevel       = currentLevel;
      _daysSince          = daysSince;
      _expanded           = expanded;
      _sessions           = sessions;
      _sessionItemCounts  = sessionItemCounts;
      _aircraftMap        = aircraftMap;
      _isLoading          = false;
    });
  }

  Future<void> _startNewSession() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NewSessionScreen(student: widget.student),
      ),
    );
    _loadData();
  }

  String _levelDisplay(int itemId) {
    return _currentLevel[itemId] ?? 'NEVER';
  }

  String _daysDisplay(int itemId) {
    final days = _daysSince[itemId];
    if (days == null) return '';
    if (days == 0) return 'today';
    if (days == 1) return '1 day ago';
    return '$days days ago';
  }

  Widget _buildPrepIndicator(int itemId) {
    final prep = _prepMap[itemId];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _prepIcon('R', prep?.readDone ?? false),
        _prepIcon('Q', prep?.questions ?? false),
        _prepIcon('I', prep?.instruction ?? false),
        _prepIcon('D', prep?.demo ?? false),
      ],
    );
  }

  Widget _prepIcon(String label, bool done) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: done ? Colors.green : Colors.grey,
          decoration: done ? TextDecoration.none : TextDecoration.lineThrough,
        ),
      ),
    );
  }

  Widget _buildProgressTab() {
    if (_groups.isEmpty) {
      return const Center(child: Text('No syllabus data found.'));
    }

    return Column(
      children: [
        // Toggle bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              const Text(
                'Show:',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('All Items'),
                selected: !_showPracticedOnly,
                onSelected: (_) => setState(() => _showPracticedOnly = false),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Practiced Only'),
                selected: _showPracticedOnly,
                onSelected: (_) => setState(() => _showPracticedOnly = true),
              ),
            ],
          ),
        ),

        // Syllabus list
        Expanded(
          child: ListView.builder(
            itemCount: _groups.length,
            itemBuilder: (context, index) {
              final group = _groups[index];
              final groupItems = _items
                  .where((i) => i.groupId == group.id)
                  .where((i) => _showPracticedOnly
                  ? _currentLevel.containsKey(i.id)
                  : true)
                  .toList();

              if (_showPracticedOnly && groupItems.isEmpty) {
                return const SizedBox.shrink();
              }

              final isExpanded = _expanded[group.id] ?? true;
              final loggedCount = groupItems
                  .where((i) => _currentLevel.containsKey(i.id))
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12,
                        ),
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
                            Icon(
                              isExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                            ),
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
            },
          ),
        ),
      ],
    );
  }

  Widget _buildItemRow(SyllabusItem item) {
    final level    = _levelDisplay(item.id);
    final daysText = _daysDisplay(item.id);

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item code and title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.code,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  item.title,
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 4),
                _buildPrepIndicator(item.id),
              ],
            ),
          ),

          // Level and days
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: level == 'NEVER'
                      ? Colors.grey.shade200
                      : Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  level,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: level == 'NEVER'
                        ? Colors.grey.shade600
                        : Colors.blue.shade800,
                  ),
                ),
              ),
              if (daysText.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  daysText,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsTab() {
    if (_sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flight_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No sessions yet.\nTap + to log the first flight.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _sessions.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final session = _sessions[index];
        final count   = _sessionItemCounts[session.id] ?? 0;
        final date    = DateTime.parse(session.sessionDate);
        final dateStr = '${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}';

        return ListTile(
          leading: const Icon(Icons.flight),
          title: Text(dateStr),
          subtitle: Text(
            [
              if (session.aircraftId != null)
              _aircraftMap[session.aircraftId]?.displayName ?? 'Unknown aircraft',
              '$count item${count == 1 ? '' : 's'} covered',
              if (session.durationMinutes != null)
                '${session.durationMinutes} min',
            ].join(' · '),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SessionDetailScreen(session: session),
              ),
            );
            _loadData();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.student.name),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Progress'),
            Tab(text: 'Sessions'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          _buildProgressTab(),
          _buildSessionsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startNewSession,
        icon: const Icon(Icons.add),
        label: const Text('New Session'),
      ),
    );
  }
}