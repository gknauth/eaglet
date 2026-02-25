class Student {
  final int? id;
  final String name;
  final String? certLevel;
  final String? notes;
  final String createdAt;

  Student({
    this.id,
    required this.name,
    this.certLevel,
    this.notes,
    required this.createdAt,
  });

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id:        map['id'] as int?,
      name:      map['name'] as String,
      certLevel: map['cert_level'] as String?,
      notes:     map['notes'] as String?,
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name':       name,
      'cert_level': certLevel,
      'notes':      notes,
      'created_at': createdAt,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id':         id,
      'name':       name,
      'cert_level': certLevel,
      'notes':      notes,
      'created_at': createdAt,
    };
  }

  Student copyWith({
    int? id,
    String? name,
    String? certLevel,
    String? notes,
    String? createdAt,
  }) {
    return Student(
      id:        id        ?? this.id,
      name:      name      ?? this.name,
      certLevel: certLevel ?? this.certLevel,
      notes:     notes     ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Student(id: $id, name: $name, certLevel: $certLevel)';
  }
}