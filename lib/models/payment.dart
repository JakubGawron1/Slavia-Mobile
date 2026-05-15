class PaymentStatusResponse {
  final String month;
  final String dueDate;
  final bool isPaid;
  final bool isOverdue;
  final bool hasStandingOrder;

  PaymentStatusResponse({
    required this.month,
    required this.dueDate,
    required this.isPaid,
    required this.isOverdue,
    required this.hasStandingOrder,
  });

  factory PaymentStatusResponse.fromJson(Map<String, dynamic> json) {
    return PaymentStatusResponse(
      month: json['month'],
      dueDate: json['due_date'],
      isPaid: json['is_paid'] ?? false,
      isOverdue: json['is_overdue'] ?? false,
      hasStandingOrder: json['has_standing_order'] ?? false,
    );
  }
}

class PaymentMonthStatusRow {
  final String month;
  final String dueDate;
  final bool isPaid;
  final bool hasPending;
  final bool isOverdue;

  PaymentMonthStatusRow({
    required this.month,
    required this.dueDate,
    required this.isPaid,
    required this.hasPending,
    required this.isOverdue,
  });

  factory PaymentMonthStatusRow.fromJson(Map<String, dynamic> json) {
    return PaymentMonthStatusRow(
      month: json['month'],
      dueDate: json['due_date'],
      isPaid: json['is_paid'] ?? false,
      hasPending: json['has_pending'] ?? false,
      isOverdue: json['is_overdue'] ?? false,
    );
  }
}
