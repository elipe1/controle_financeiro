class Earning {
  Earning({
    required this.id,
    required this.value,
    required this.category,
    required this.date,
    this.currency = 'BRL',
  });

  final String id;
  final double value;
  final String category;
  final DateTime date;
  final String currency;
}