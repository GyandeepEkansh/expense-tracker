class Expense {
  final String id;
  final double amount;
  final String categoryId;
  final DateTime date;
  final String? note;
  final DateTime createdAt;

  const Expense({
    required this.id,
    required this.amount,
    required this.categoryId,
    required this.date,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'categoryId': categoryId,
        'date': date.toIso8601String(),
        'note': note,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      categoryId: json['categoryId'] as String,
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Expense copyWith({
    double? amount,
    String? categoryId,
    DateTime? date,
    String? note,
  }) {
    return Expense(
      id: id,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      note: note ?? this.note,
      createdAt: createdAt,
    );
  }
}
