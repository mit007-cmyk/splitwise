import '../../domain/entities/currency.dart';

/// Static catalog of commonly used currencies for the currency picker.
/// Not an exhaustive ISO-4217 list, but covers the currencies a Splitwise
/// clone's users are realistically going to search for.
class CurrencyCatalog {
  CurrencyCatalog._();

  static const Currency defaultCurrency = Currency(
    code: 'INR',
    symbol: '₹',
    name: 'Indian Rupee',
  );

  static const List<Currency> all = [
    Currency(code: 'INR', symbol: '₹', name: 'Indian Rupee'),
    Currency(code: 'USD', symbol: '\$', name: 'US Dollar'),
    Currency(code: 'EUR', symbol: '€', name: 'Euro'),
    Currency(code: 'GBP', symbol: '£', name: 'British Pound'),
    Currency(code: 'AED', symbol: 'د.إ', name: 'United Arab Emirates Dirham'),
    Currency(code: 'AFN', symbol: '؋', name: 'Afghan Afghani'),
    Currency(code: 'ALL', symbol: 'L', name: 'Albanian Lek'),
    Currency(code: 'AMD', symbol: '֏', name: 'Armenian Dram'),
    Currency(code: 'ANG', symbol: 'ƒ', name: 'Netherlands Antillean Guilder'),
    Currency(code: 'AOA', symbol: 'Kz', name: 'Angolan Kwanza'),
    Currency(code: 'ARS', symbol: '\$', name: 'Argentine Peso'),
    Currency(code: 'AUD', symbol: 'A\$', name: 'Australian Dollar'),
    Currency(code: 'AWG', symbol: 'ƒ', name: 'Aruban Florin'),
    Currency(code: 'AZN', symbol: '₼', name: 'Azerbaijani Manat'),
    Currency(code: 'BDT', symbol: '৳', name: 'Bangladeshi Taka'),
    Currency(code: 'BGN', symbol: 'лв', name: 'Bulgarian Lev'),
    Currency(code: 'BHD', symbol: '.د.ب', name: 'Bahraini Dinar'),
    Currency(code: 'BND', symbol: '\$', name: 'Brunei Dollar'),
    Currency(code: 'BOB', symbol: 'Bs.', name: 'Bolivian Boliviano'),
    Currency(code: 'BRL', symbol: 'R\$', name: 'Brazilian Real'),
    Currency(code: 'BWP', symbol: 'P', name: 'Botswanan Pula'),
    Currency(code: 'CAD', symbol: 'C\$', name: 'Canadian Dollar'),
    Currency(code: 'CHF', symbol: 'CHF', name: 'Swiss Franc'),
    Currency(code: 'CLP', symbol: '\$', name: 'Chilean Peso'),
    Currency(code: 'CNY', symbol: '¥', name: 'Chinese Yuan'),
    Currency(code: 'COP', symbol: '\$', name: 'Colombian Peso'),
    Currency(code: 'CRC', symbol: '₡', name: 'Costa Rican Colón'),
    Currency(code: 'CZK', symbol: 'Kč', name: 'Czech Koruna'),
    Currency(code: 'DKK', symbol: 'kr', name: 'Danish Krone'),
    Currency(code: 'DOP', symbol: 'RD\$', name: 'Dominican Peso'),
    Currency(code: 'DZD', symbol: 'دج', name: 'Algerian Dinar'),
    Currency(code: 'EGP', symbol: 'E£', name: 'Egyptian Pound'),
    Currency(code: 'ETB', symbol: 'Br', name: 'Ethiopian Birr'),
    Currency(code: 'FJD', symbol: '\$', name: 'Fijian Dollar'),
    Currency(code: 'HKD', symbol: 'HK\$', name: 'Hong Kong Dollar'),
    Currency(code: 'HUF', symbol: 'Ft', name: 'Hungarian Forint'),
    Currency(code: 'IDR', symbol: 'Rp', name: 'Indonesian Rupiah'),
    Currency(code: 'ILS', symbol: '₪', name: 'Israeli New Shekel'),
    Currency(code: 'JOD', symbol: 'د.ا', name: 'Jordanian Dinar'),
    Currency(code: 'JPY', symbol: '¥', name: 'Japanese Yen'),
    Currency(code: 'KES', symbol: 'KSh', name: 'Kenyan Shilling'),
    Currency(code: 'KRW', symbol: '₩', name: 'South Korean Won'),
    Currency(code: 'KWD', symbol: 'د.ك', name: 'Kuwaiti Dinar'),
    Currency(code: 'LKR', symbol: 'Rs', name: 'Sri Lankan Rupee'),
    Currency(code: 'MAD', symbol: 'د.م.', name: 'Moroccan Dirham'),
    Currency(code: 'MXN', symbol: '\$', name: 'Mexican Peso'),
    Currency(code: 'MYR', symbol: 'RM', name: 'Malaysian Ringgit'),
    Currency(code: 'NGN', symbol: '₦', name: 'Nigerian Naira'),
    Currency(code: 'NOK', symbol: 'kr', name: 'Norwegian Krone'),
    Currency(code: 'NPR', symbol: 'रू', name: 'Nepalese Rupee'),
    Currency(code: 'NZD', symbol: 'NZ\$', name: 'New Zealand Dollar'),
    Currency(code: 'OMR', symbol: 'ر.ع.', name: 'Omani Rial'),
    Currency(code: 'PHP', symbol: '₱', name: 'Philippine Peso'),
    Currency(code: 'PKR', symbol: 'Rs', name: 'Pakistani Rupee'),
    Currency(code: 'PLN', symbol: 'zł', name: 'Polish Złoty'),
    Currency(code: 'QAR', symbol: 'ر.ق', name: 'Qatari Riyal'),
    Currency(code: 'RON', symbol: 'lei', name: 'Romanian Leu'),
    Currency(code: 'RUB', symbol: '₽', name: 'Russian Ruble'),
    Currency(code: 'SAR', symbol: 'ر.س', name: 'Saudi Riyal'),
    Currency(code: 'SEK', symbol: 'kr', name: 'Swedish Krona'),
    Currency(code: 'SGD', symbol: 'S\$', name: 'Singapore Dollar'),
    Currency(code: 'THB', symbol: '฿', name: 'Thai Baht'),
    Currency(code: 'TRY', symbol: '₺', name: 'Turkish Lira'),
    Currency(code: 'TWD', symbol: 'NT\$', name: 'New Taiwan Dollar'),
    Currency(code: 'TZS', symbol: 'TSh', name: 'Tanzanian Shilling'),
    Currency(code: 'UAH', symbol: '₴', name: 'Ukrainian Hryvnia'),
    Currency(code: 'UGX', symbol: 'USh', name: 'Ugandan Shilling'),
    Currency(code: 'VND', symbol: '₫', name: 'Vietnamese Dong'),
    Currency(code: 'XAF', symbol: 'FCFA', name: 'Central African CFA Franc'),
    Currency(code: 'XOF', symbol: 'CFA', name: 'West African CFA Franc'),
    Currency(code: 'ZAR', symbol: 'R', name: 'South African Rand'),
  ];

  static List<Currency> search(String query) {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return all;
    return all
        .where(
          (currency) =>
              currency.code.toLowerCase().contains(trimmed) ||
              currency.name.toLowerCase().contains(trimmed),
        )
        .toList();
  }

  static Currency byCode(String code) {
    return all.firstWhere(
      (currency) => currency.code == code,
      orElse: () => defaultCurrency,
    );
  }

  static String normalizeCode(String? code) {
    final trimmed = (code ?? '').trim().toUpperCase();
    return trimmed.isEmpty ? defaultCurrency.code : trimmed;
  }

  static String symbolFor(String? code, [String? fallbackSymbol]) {
    final symbol = (fallbackSymbol ?? '').trim();
    if (symbol.isNotEmpty) return symbol;
    return byCode(normalizeCode(code)).symbol;
  }
}
