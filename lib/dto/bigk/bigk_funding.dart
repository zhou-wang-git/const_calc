import 'bigk_json.dart';

class BigKCurrency {
  final String code;
  final String name;
  final String symbol;
  final int decimals;
  final bool enabled;

  const BigKCurrency({
    this.code = '',
    this.name = '',
    this.symbol = '',
    this.decimals = 2,
    this.enabled = true,
  });

  factory BigKCurrency.fromJson(dynamic json) {
    final data = bigkAsMap(json);
    return BigKCurrency(
      code: bigkString(
        data,
        const ['code', 'currency', 'iso_code'],
      ).toUpperCase(),
      name: bigkString(data, const ['name', 'label']),
      symbol: bigkString(data, const ['symbol', 'sign']),
      decimals: bigkInt(data, const ['decimals', 'precision'], fallback: 2),
      enabled: bigkBool(
        data,
        const ['enabled', 'active', 'is_active'],
        fallback: true,
      ),
    );
  }

  String get displayLabel =>
      code.isEmpty ? name : '$code${name.isEmpty ? '' : ' - $name'}';
}

class BigKExchangeRate {
  final String fromCurrency;
  final String toCurrency;
  final double rate;

  const BigKExchangeRate({
    this.fromCurrency = '',
    this.toCurrency = '',
    this.rate = 0,
  });

  factory BigKExchangeRate.fromJson(dynamic json) {
    final data = bigkAsMap(json);
    return BigKExchangeRate(
      fromCurrency: bigkString(
        data,
        const ['from_currency', 'base_currency', 'base'],
      ).toUpperCase(),
      toCurrency: bigkString(
        data,
        const ['to_currency', 'quote_currency', 'quote'],
      ).toUpperCase(),
      rate: bigkDouble(data, const ['rate', 'value', 'exchange_rate']),
    );
  }

  String get pairLabel {
    if (fromCurrency.isEmpty || toCurrency.isEmpty) {
      return '';
    }
    return '$fromCurrency/$toCurrency';
  }
}

class BigKConversionQuote {
  final String fromCurrency;
  final String toCurrency;
  final double fromAmount;
  final double toAmount;
  final double rate;
  final String formatted;

  const BigKConversionQuote({
    this.fromCurrency = '',
    this.toCurrency = '',
    this.fromAmount = 0,
    this.toAmount = 0,
    this.rate = 0,
    this.formatted = '',
  });

  factory BigKConversionQuote.fromJson(dynamic json) {
    final data = bigkUnwrapMap(json);
    return BigKConversionQuote(
      fromCurrency: bigkString(
        data,
        const ['from_currency', 'base_currency', 'base'],
      ).toUpperCase(),
      toCurrency: bigkString(
        data,
        const ['to_currency', 'quote_currency', 'quote'],
      ).toUpperCase(),
      fromAmount: bigkDouble(
        data,
        const ['from_amount', 'amount', 'source_amount'],
      ),
      toAmount: bigkDouble(
        data,
        const ['to_amount', 'converted_amount', 'target_amount'],
      ),
      rate: bigkDouble(data, const ['rate', 'exchange_rate']),
      formatted: bigkString(
        data,
        const ['formatted', 'display_price', 'price'],
      ),
    );
  }
}

class BigKPriceQuote {
  final String formatted;
  final double amount;
  final String currency;

  const BigKPriceQuote({
    this.formatted = '',
    this.amount = 0,
    this.currency = '',
  });

  factory BigKPriceQuote.fromJson(dynamic json) {
    final data = bigkUnwrapMap(json);
    return BigKPriceQuote(
      formatted: bigkString(
        data,
        const ['formatted_price', 'formatted', 'display_price', 'price'],
      ),
      amount: bigkDouble(data, const ['amount', 'price', 'value']),
      currency: bigkString(
        data,
        const ['currency', 'display_currency'],
      ).toUpperCase(),
    );
  }
}
