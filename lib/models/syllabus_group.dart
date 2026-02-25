class SyllabusGroup {
  final int    id;
  final String code;
  final String title;

  SyllabusGroup({
    required this.id,
    required this.code,
    required this.title,
  });

  factory SyllabusGroup.fromMap(Map<String, dynamic> map) {
    return SyllabusGroup(
      id:    map['id']    as int,
      code:  map['code']  as String,
      title: map['title'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id':    id,
      'code':  code,
      'title': title,
    };
  }

  @override
  String toString() => 'SyllabusGroup(id: $id, code: $code, title: $title)';
}