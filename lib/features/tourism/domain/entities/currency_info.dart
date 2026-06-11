class CurrencyInfo implements Comparable<CurrencyInfo> {
  const CurrencyInfo({
    required this.code,
    required this.name,
    this.symbol,
  });

  final String code;
  final String name;
  final String? symbol;

  @override
  int compareTo(CurrencyInfo other) => code.compareTo(other.code);
}
