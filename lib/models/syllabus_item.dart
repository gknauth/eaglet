class SyllabusItem {
  final int    id;
  final int    groupId;
  final int    stage;
  final String code;
  final String title;

  SyllabusItem({
    required this.id,
    required this.groupId,
    required this.stage,
    required this.code,
    required this.title,
  });

  factory SyllabusItem.fromMap(Map<String, dynamic> map) {
    return SyllabusItem(
      id:      map['id']       as int,
      groupId: map['group_id'] as int,
      stage:   map['stage']    as int,
      code:    map['code']     as String,
      title:   map['title']    as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id':       id,
      'group_id': groupId,
      'stage':    stage,
      'code':     code,
      'title':    title,
    };
  }

  @override
  String toString() => 'SyllabusItem(id: $id, code: $code, title: $title)';
}