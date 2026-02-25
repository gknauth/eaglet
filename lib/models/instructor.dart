class Instructor {
  final int? id;
  final String name;
  final String? certificate;
  final String? notes;
  final String createdAt;

  Instructor({
    this.id,
    required this.name,
    this.certificate,
    this.notes,
    required this.createdAt,
  });

  // Convert a map (from SQLite) to an Instructor object
  factory Instructor.fromMap(Map<String, dynamic> map) {
    return Instructor(
      id:          map['id'] as int?,
      name:        map['name'] as String,
      certificate: map['certificate'] as String?,
      notes:       map['notes'] as String?,
      createdAt:   map['created_at'] as String,
    );
  }

  // Convert an Instructor object to a map (for SQLite)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name':        name,
      'certificate': certificate,
      'notes':       notes,
      'created_at':  createdAt,
    };
  }

  // Convert to JSON for API sync
  Map<String, dynamic> toJson() {
    return {
      'id':          id,
      'name':        name,
      'certificate': certificate,
      'notes':       notes,
      'created_at':  createdAt,
    };
  }

  // Convenience method for creating a copy with modified fields
  Instructor copyWith({
    int? id,
    String? name,
    String? certificate,
    String? notes,
    String? createdAt,
  }) {
    return Instructor(
      id:          id          ?? this.id,
      name:        name        ?? this.name,
      certificate: certificate ?? this.certificate,
      notes:       notes       ?? this.notes,
      createdAt:   createdAt   ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Instructor(id: $id, name: $name, certificate: $certificate)';
  }
}