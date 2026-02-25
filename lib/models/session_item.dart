class SessionItem {
  final String  id;
  final String  sessionId;
  final int     itemId;
  final String  level;
  final String? notes;
  final String  timestamp;
  final bool    synced;

  SessionItem({
    required this.id,
    required this.sessionId,
    required this.itemId,
    required this.level,
    this.notes,
    required this.timestamp,
    this.synced = false,
  });

  factory SessionItem.fromMap(Map<String, dynamic> map) {
    return SessionItem(
      id:        map['id']         as String,
      sessionId: map['session_id'] as String,
      itemId:    map['item_id']    as int,
      level:     map['level']      as String,
      notes:     map['notes']      as String?,
      timestamp: map['timestamp']  as String,
      synced:    (map['synced']    as int) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id':         id,
      'session_id': sessionId,
      'item_id':    itemId,
      'level':      level,
      'notes':      notes,
      'timestamp':  timestamp,
      'synced':     synced ? 1 : 0,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id':         id,
      'session_id': sessionId,
      'item_id':    itemId,
      'level':      level,
      'notes':      notes,
      'timestamp':  timestamp,
    };
  }

  SessionItem copyWith({
    String?  id,
    String?  sessionId,
    int?     itemId,
    String?  level,
    String?  notes,
    String?  timestamp,
    bool?    synced,
  }) {
    return SessionItem(
      id:        id        ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      itemId:    itemId    ?? this.itemId,
      level:     level     ?? this.level,
      notes:     notes     ?? this.notes,
      timestamp: timestamp ?? this.timestamp,
      synced:    synced    ?? this.synced,
    );
  }

  @override
  String toString() =>
      'SessionItem(sessionId: $sessionId, itemId: $itemId, level: $level)';
}