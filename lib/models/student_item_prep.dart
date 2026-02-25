class StudentItemPrep {
  final String  id;
  final int     studentId;
  final int     itemId;
  final bool    readDone;
  final bool    questions;
  final bool    instruction;
  final bool    demo;
  final bool    synced;

  StudentItemPrep({
    required this.id,
    required this.studentId,
    required this.itemId,
    this.readDone   = false,
    this.questions  = false,
    this.instruction = false,
    this.demo       = false,
    this.synced     = false,
  });

  factory StudentItemPrep.fromMap(Map<String, dynamic> map) {
    return StudentItemPrep(
      id:          map['id']          as String,
      studentId:   map['student_id']  as int,
      itemId:      map['item_id']     as int,
      readDone:    (map['read_done']  as int) == 1,
      questions:   (map['questions']  as int) == 1,
      instruction: (map['instruction'] as int) == 1,
      demo:        (map['demo']       as int) == 1,
      synced:      (map['synced']     as int) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id':          id,
      'student_id':  studentId,
      'item_id':     itemId,
      'read_done':   readDone   ? 1 : 0,
      'questions':   questions  ? 1 : 0,
      'instruction': instruction ? 1 : 0,
      'demo':        demo       ? 1 : 0,
      'synced':      synced     ? 1 : 0,
    };
  }

  StudentItemPrep copyWith({
    String? id,
    int?    studentId,
    int?    itemId,
    bool?   readDone,
    bool?   questions,
    bool?   instruction,
    bool?   demo,
    bool?   synced,
  }) {
    return StudentItemPrep(
      id:          id          ?? this.id,
      studentId:   studentId   ?? this.studentId,
      itemId:      itemId      ?? this.itemId,
      readDone:    readDone    ?? this.readDone,
      questions:   questions   ?? this.questions,
      instruction: instruction ?? this.instruction,
      demo:        demo        ?? this.demo,
      synced:      synced      ?? this.synced,
    );
  }

  @override
  String toString() =>
      'StudentItemPrep(studentId: $studentId, itemId: $itemId, '
          'R:$readDone Q:$questions I:$instruction D:$demo)';
}