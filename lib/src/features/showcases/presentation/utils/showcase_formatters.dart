const _arabicMonths = [
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];

String formatShowcaseDate(DateTime? date) {
  if (date == null) return '';
  return '${date.day} ${_arabicMonths[date.month - 1]} ${date.year}';
}

String formatShowcasePrice(double? price) {
  if (price == null) return '';
  final isWhole = price == price.roundToDouble();
  final value = isWhole
      ? price.toStringAsFixed(0)
      : price.toStringAsFixed(2);
  return '$value ج.م';
}
