// Enum para las monedas disponibles
enum Currency {
  clp('CLP', 'Peso Chileno', '\$', 0),
  usd('USD', 'Dólar Americano', '\$', 2),
  eur('EUR', 'Euro', '€', 2),
  gbp('GBP', 'Libra Esterlina', '£', 2),
  jpy('JPY', 'Yen Japonés', '¥', 0),
  ars('ARS', 'Peso Argentino', '\$', 2),
  brl('BRL', 'Real Brasileño', 'R\$', 2);

  const Currency(this.code, this.name, this.symbol, this.decimals);
  
  final String code;
  final String name;
  final String symbol;
  final int decimals;
}
