class QuotationStats {
  const QuotationStats({
    required this.totalQuotations,
    required this.pendingQuotations,
    required this.acceptedQuotations,
    required this.rejectedQuotations,
    required this.cancelledQuotations,
  });

  final int totalQuotations;
  final int pendingQuotations;
  final int acceptedQuotations;
  final int rejectedQuotations;
  final int cancelledQuotations;

  factory QuotationStats.fromJson(Map<String, dynamic> json) => QuotationStats(
        totalQuotations: json['totalQuotations'] as int? ?? 0,
        pendingQuotations: json['pendingQuotations'] as int? ?? 0,
        acceptedQuotations: json['acceptedQuotations'] as int? ?? 0,
        rejectedQuotations: json['rejectedQuotations'] as int? ?? 0,
        cancelledQuotations: json['cancelledQuotations'] as int? ?? 0,
      );

  static const empty = QuotationStats(
    totalQuotations: 0,
    pendingQuotations: 0,
    acceptedQuotations: 0,
    rejectedQuotations: 0,
    cancelledQuotations: 0,
  );
}
