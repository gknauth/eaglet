class TrainingSession {
  final String  id;
  final int     studentId;
  final int     instructorId;
  final String  sessionDate;
  final int?    aircraftId;        // changed from aircraft
  final int?    durationMinutes;
  final String? notes;
  final bool    synced;

  TrainingSession({
    required this.id,
    required this.studentId,
    required this.instructorId,
    required this.sessionDate,
    this.aircraftId,               // changed
    this.durationMinutes,
    this.notes,
    this.synced = false,
  });

  factory TrainingSession.fromMap(Map<String, dynamic> map) {
    return TrainingSession(
      id:              map['id']               as String,
      studentId:       map['student_id']       as int,
      instructorId:    map['instructor_id']    as int,
      sessionDate:     map['session_date']     as String,
      aircraftId:      map['aircraft_id']      as int?,   // changed
      durationMinutes: map['duration_minutes'] as int?,
      notes:           map['notes']            as String?,
      synced:          (map['synced']          as int) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id':               id,
      'student_id':       studentId,
      'instructor_id':    instructorId,
      'session_date':     sessionDate,
      'aircraft_id':      aircraftId,            // changed
      'duration_minutes': durationMinutes,
      'notes':            notes,
      'synced':           synced ? 1 : 0,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id':               id,
      'student_id':       studentId,
      'instructor_id':    instructorId,
      'session_date':     sessionDate,
      'aircraft_id':      aircraftId,            // changed
      'duration_minutes': durationMinutes,
      'notes':            notes,
    };
  }

  TrainingSession copyWith({
    String? id,
    int?    studentId,
    int?    instructorId,
    String? sessionDate,
    int?    aircraftId,                          // changed
    int?    durationMinutes,
    String? notes,
    bool?   synced,
  }) {
    return TrainingSession(
      id:              id              ?? this.id,
      studentId:       studentId       ?? this.studentId,
      instructorId:    instructorId    ?? this.instructorId,
      sessionDate:     sessionDate     ?? this.sessionDate,
      aircraftId:      aircraftId      ?? this.aircraftId,  // changed
      durationMinutes: durationMinutes ?? this.durationMinutes,
      notes:           notes           ?? this.notes,
      synced:          synced          ?? this.synced,
    );
  }

  @override
  String toString() =>
      'TrainingSession(id: $id, studentId: $studentId, date: $sessionDate)';
}