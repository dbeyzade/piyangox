class Ticket {
  final String id;
  final String number;
  final String status;
  final bool published;
  final bool isWinner;
  final DateTime drawDate;

  Ticket({
    required this.id,
    required this.number,
    required this.status,
    required this.published,
    required this.isWinner,
    required this.drawDate,
  });

  factory Ticket.fromMap(Map<String, dynamic> map) {
    return Ticket(
      id: map['id'],
      number: map['number'],
      status: map['status'],
      published: map['published'],
      isWinner: map['is_winner'] ?? false,
      drawDate: map['draw_date'] != null 
          ? DateTime.parse(map['draw_date'])
          : DateTime.now().add(Duration(days: 1)).copyWith(hour: 20, minute: 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'number': number,
      'status': status,
      'published': published,
      'is_winner': isWinner,
      'draw_date': drawDate.toIso8601String(),
    };
  }

  Ticket copyWith({
    String? id,
    String? number,
    String? status,
    bool? published,
    bool? isWinner,
    DateTime? drawDate,
  }) {
    return Ticket(
      id: id ?? this.id,
      number: number ?? this.number,
      status: status ?? this.status,
      published: published ?? this.published,
      isWinner: isWinner ?? this.isWinner,
      drawDate: drawDate ?? this.drawDate,
    );
  }
} 