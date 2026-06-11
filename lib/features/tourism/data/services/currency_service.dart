import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unisafex/features/tourism/domain/entities/currency_info.dart';

class CurrencyRates {
  const CurrencyRates({
    required this.base,
    required this.rates,
    required this.updatedAt,
    required this.isLive,
  });

  final String base;
  final Map<String, double> rates;
  final DateTime updatedAt;
  final bool isLive;
}

class CurrencyService {
  CurrencyService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://api.frankfurter.dev/v2',
                connectTimeout: const Duration(seconds: 8),
                receiveTimeout: const Duration(seconds: 8),
              ),
            );

  final Dio _dio;

  static const _currenciesCacheKey = 'travel_currency_catalog_v2';
  static const _ratesCachePrefix = 'travel_currency_rates_v2_';

  Future<List<CurrencyInfo>> getCurrencies() async {
    try {
      final response = await _dio.get<List<dynamic>>('/currencies');
      final currencies = (response.data ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(_currencyFromJson)
          .where((currency) => currency.code.isNotEmpty)
          .toList()
        ..sort();
      if (currencies.isNotEmpty) {
        final preferences = await SharedPreferences.getInstance();
        await preferences.setString(
          _currenciesCacheKey,
          jsonEncode(
            currencies
                .map(
                  (currency) => {
                    'code': currency.code,
                    'name': currency.name,
                    'symbol': currency.symbol,
                  },
                )
                .toList(),
          ),
        );
        return currencies;
      }
    } catch (_) {
      // Cached and bundled currencies keep the converter usable offline.
    }

    final cached = await _cachedCurrencies();
    return cached.isNotEmpty ? cached : _fallbackCurrencies;
  }

  Future<CurrencyRates> getRates(String base) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/rates',
        queryParameters: {'base': base},
      );
      final rows = response.data ?? const [];
      final rates = <String, double>{base: 1};
      DateTime? rateDate;
      for (final row in rows.whereType<Map<String, dynamic>>()) {
        final quote = row['quote']?.toString();
        final rate = (row['rate'] as num?)?.toDouble();
        if (quote != null && rate != null) rates[quote] = rate;
        rateDate ??= DateTime.tryParse(row['date']?.toString() ?? '');
      }
      if (rates.length > 1) {
        final result = CurrencyRates(
          base: base,
          rates: rates,
          updatedAt: rateDate ?? DateTime.now(),
          isLive: true,
        );
        await _cacheRates(result);
        return result;
      }
    } catch (_) {
      // Fall through to the latest cached or bundled reference rates.
    }

    final cached = await _cachedRates(base);
    return cached ?? _fallbackRates(base);
  }

  CurrencyInfo _currencyFromJson(Map<String, dynamic> json) {
    final code =
        (json['iso_code'] ?? json['code'] ?? json['currency'])?.toString() ??
            '';
    return CurrencyInfo(
      code: code,
      name: json['name']?.toString() ?? code,
      symbol: json['symbol']?.toString(),
    );
  }

  Future<List<CurrencyInfo>> _cachedCurrencies() async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString(_currenciesCacheKey);
    if (value == null) return const [];
    try {
      return (jsonDecode(value) as List)
          .whereType<Map<String, dynamic>>()
          .map(
            (item) => CurrencyInfo(
              code: item['code']?.toString() ?? '',
              name: item['name']?.toString() ?? '',
              symbol: item['symbol']?.toString(),
            ),
          )
          .where((currency) => currency.code.isNotEmpty)
          .toList()
        ..sort();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _cacheRates(CurrencyRates value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      '$_ratesCachePrefix${value.base}',
      jsonEncode({
        'base': value.base,
        'updatedAt': value.updatedAt.toIso8601String(),
        'rates': value.rates,
      }),
    );
  }

  Future<CurrencyRates?> _cachedRates(String base) async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString('$_ratesCachePrefix$base');
    if (value == null) return null;
    try {
      final decoded = jsonDecode(value) as Map<String, dynamic>;
      final rawRates = decoded['rates'] as Map<String, dynamic>;
      return CurrencyRates(
        base: base,
        rates: rawRates.map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        ),
        updatedAt: DateTime.tryParse(decoded['updatedAt']?.toString() ?? '') ??
            DateTime.now(),
        isLive: false,
      );
    } catch (_) {
      return null;
    }
  }

  CurrencyRates _fallbackRates(String base) {
    final baseInUsd = _fallbackUsdRates[base] ?? 1;
    return CurrencyRates(
      base: base,
      rates: _fallbackUsdRates.map(
        (code, usdRate) => MapEntry(code, usdRate / baseInUsd),
      ),
      updatedAt: DateTime(2026, 1, 1),
      isLive: false,
    );
  }

  static const _fallbackUsdRates = <String, double>{
    'USD': 1,
    'INR': 83.5,
    'EUR': 0.92,
    'GBP': 0.79,
    'AUD': 1.52,
    'CAD': 1.37,
    'CHF': 0.90,
    'CNY': 7.24,
    'JPY': 157.0,
    'KRW': 1380.0,
    'SGD': 1.35,
    'HKD': 7.81,
    'NZD': 1.65,
    'AED': 3.6725,
    'SAR': 3.75,
    'QAR': 3.64,
    'THB': 36.7,
    'MYR': 4.72,
    'IDR': 16250.0,
    'VND': 25450.0,
    'PHP': 58.6,
    'NPR': 133.6,
    'LKR': 303.0,
    'BDT': 117.5,
    'PKR': 278.5,
    'ZAR': 18.4,
    'BRL': 5.1,
    'MXN': 18.0,
    'TRY': 32.7,
    'RUB': 89.0,
    'SEK': 10.5,
    'NOK': 10.7,
    'DKK': 6.86,
    'PLN': 4.0,
    'CZK': 22.8,
  };

  static const _fallbackCurrencies = <CurrencyInfo>[
    CurrencyInfo(code: 'AED', name: 'UAE Dirham', symbol: 'د.إ'),
    CurrencyInfo(code: 'AUD', name: 'Australian Dollar', symbol: r'$'),
    CurrencyInfo(code: 'BDT', name: 'Bangladeshi Taka', symbol: '৳'),
    CurrencyInfo(code: 'BRL', name: 'Brazilian Real', symbol: r'R$'),
    CurrencyInfo(code: 'CAD', name: 'Canadian Dollar', symbol: r'$'),
    CurrencyInfo(code: 'CHF', name: 'Swiss Franc', symbol: 'CHF'),
    CurrencyInfo(code: 'CNY', name: 'Chinese Yuan', symbol: '¥'),
    CurrencyInfo(code: 'CZK', name: 'Czech Koruna', symbol: 'Kč'),
    CurrencyInfo(code: 'DKK', name: 'Danish Krone', symbol: 'kr'),
    CurrencyInfo(code: 'EUR', name: 'Euro', symbol: '€'),
    CurrencyInfo(code: 'GBP', name: 'British Pound', symbol: '£'),
    CurrencyInfo(code: 'HKD', name: 'Hong Kong Dollar', symbol: r'$'),
    CurrencyInfo(code: 'IDR', name: 'Indonesian Rupiah', symbol: 'Rp'),
    CurrencyInfo(code: 'INR', name: 'Indian Rupee', symbol: '₹'),
    CurrencyInfo(code: 'JPY', name: 'Japanese Yen', symbol: '¥'),
    CurrencyInfo(code: 'KRW', name: 'South Korean Won', symbol: '₩'),
    CurrencyInfo(code: 'LKR', name: 'Sri Lankan Rupee', symbol: 'Rs'),
    CurrencyInfo(code: 'MXN', name: 'Mexican Peso', symbol: r'$'),
    CurrencyInfo(code: 'MYR', name: 'Malaysian Ringgit', symbol: 'RM'),
    CurrencyInfo(code: 'NOK', name: 'Norwegian Krone', symbol: 'kr'),
    CurrencyInfo(code: 'NPR', name: 'Nepalese Rupee', symbol: 'रू'),
    CurrencyInfo(code: 'NZD', name: 'New Zealand Dollar', symbol: r'$'),
    CurrencyInfo(code: 'PHP', name: 'Philippine Peso', symbol: '₱'),
    CurrencyInfo(code: 'PKR', name: 'Pakistani Rupee', symbol: 'Rs'),
    CurrencyInfo(code: 'PLN', name: 'Polish Zloty', symbol: 'zł'),
    CurrencyInfo(code: 'QAR', name: 'Qatari Riyal', symbol: 'ر.ق'),
    CurrencyInfo(code: 'RUB', name: 'Russian Ruble', symbol: '₽'),
    CurrencyInfo(code: 'SAR', name: 'Saudi Riyal', symbol: 'ر.س'),
    CurrencyInfo(code: 'SEK', name: 'Swedish Krona', symbol: 'kr'),
    CurrencyInfo(code: 'SGD', name: 'Singapore Dollar', symbol: r'$'),
    CurrencyInfo(code: 'THB', name: 'Thai Baht', symbol: '฿'),
    CurrencyInfo(code: 'TRY', name: 'Turkish Lira', symbol: '₺'),
    CurrencyInfo(code: 'USD', name: 'US Dollar', symbol: r'$'),
    CurrencyInfo(code: 'VND', name: 'Vietnamese Dong', symbol: '₫'),
    CurrencyInfo(code: 'ZAR', name: 'South African Rand', symbol: 'R'),
  ];
}
