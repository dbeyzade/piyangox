class Person {
  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final String? ticketNumber;
  final double debt; // Borçlu
  final double credit; // Alacaklı
  final bool isPaid; // Ödedi
  final DateTime createdAt;
  final DateTime? updatedAt;

  Person({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.ticketNumber,
    this.debt = 0.0,
    this.credit = 0.0,
    this.isPaid = false,
    required this.createdAt,
    this.updatedAt,
  });

  String get fullName => '$firstName $lastName';
  
  bool get isInDebt => debt > 0;
  bool get hasCredit => credit > 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'ticketNumber': ticketNumber,
      'debt': debt,
      'credit': credit,
      'isPaid': isPaid,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  factory Person.fromMap(Map<String, dynamic> map) {
    return Person(
      id: map['id'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      phone: map['phone'],
      ticketNumber: map['ticketNumber'],
      debt: map['debt']?.toDouble() ?? 0.0,
      credit: map['credit']?.toDouble() ?? 0.0,
      isPaid: map['isPaid'] ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
          : null,
    );
  }

  // JSON serialization için
  Map<String, dynamic> toJson() => toMap();
  factory Person.fromJson(Map<String, dynamic> json) => Person.fromMap(json);

  Person copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? phone,
    String? ticketNumber,
    double? debt,
    double? credit,
    bool? isPaid,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Person(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      debt: debt ?? this.debt,
      credit: credit ?? this.credit,
      isPaid: isPaid ?? this.isPaid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
