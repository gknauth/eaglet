class Aircraft {
  final int?   id;
  final String tailNumber;
  final String? makeModel;
  final String? notes;
  final String  createdAt;

  Aircraft({
    this.id,
    required this.tailNumber,
    this.makeModel,
    this.notes,
    required this.createdAt,
  });

  factory Aircraft.fromMap(Map<String, dynamic> map) {
    return Aircraft(
      id:         map['id']          as int?,
      tailNumber: map['tail_number'] as String,
      makeModel:  map['make_model']  as String?,
      notes:      map['notes']       as String?,
      createdAt:  map['created_at']  as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'tail_number': tailNumber,
      'make_model':  makeModel,
      'notes':       notes,
      'created_at':  createdAt,
    };
  }

  Aircraft copyWith({
    int?    id,
    String? tailNumber,
    String? makeModel,
    String? notes,
    String? createdAt,
  }) {
    return Aircraft(
      id:         id         ?? this.id,
      tailNumber: tailNumber ?? this.tailNumber,
      makeModel:  makeModel  ?? this.makeModel,
      notes:      notes      ?? this.notes,
      createdAt:  createdAt  ?? this.createdAt,
    );
  }

  // Display string for picker
  String get displayName => makeModel != null
      ? '$tailNumber — $makeModel'
      : tailNumber;

  @override
  String toString() => 'Aircraft(id: $id, tailNumber: $tailNumber)';
}