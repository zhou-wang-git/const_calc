import 'package:flutter/foundation.dart';

import '../../dto/bigk/bigk_funding.dart';
import '../../dto/bigk/bigk_json.dart';
import 'bigk_http_service.dart';

class BigKTopUpSession {
  final String sessionId;
  final String checkoutUrl;
  final String clientSecret;
  final String paymentIntentId;
  final String message;

  BigKTopUpSession({
    required this.sessionId,
    required this.checkoutUrl,
    this.clientSecret = '',
    this.paymentIntentId = '',
    this.message = '',
  });

  factory BigKTopUpSession.fromJson(dynamic json) {
    final payload = bigkUnwrapMap(json);
    return BigKTopUpSession(
      sessionId: bigkString(
        payload,
        const ['session_id', 'id', 'checkout_session_id'],
      ),
      checkoutUrl: bigkString(
        payload,
        const ['checkout_url', 'url'],
      ),
      clientSecret: bigkString(
        payload,
        const ['client_secret'],
      ),
      paymentIntentId: bigkString(
        payload,
        const ['payment_intent_id', 'payment_intent'],
      ),
      message: bigkString(payload, const ['message']),
    );
  }
}

class BigKPaymentVerification {
  final bool success;
  final String status;
  final double? amount;
  final String? currency;
  final String? message;

  BigKPaymentVerification({
    required this.success,
    required this.status,
    this.amount,
    this.currency,
    this.message,
  });

  bool get isComplete => status == 'complete' || status == 'paid';
  bool get isPending => status == 'pending';
  bool get isFailed => status == 'failed' || status == 'expired';

  factory BigKPaymentVerification.fromJson(dynamic json) {
    final payload = bigkUnwrapMap(json);
    final status = bigkString(
      payload,
      const ['status', 'payment_status'],
    );
    final explicitSuccess = bigkBool(
      payload,
      const ['success', 'paid', 'verified'],
      fallback: status == 'complete' || status == 'paid',
    );
    return BigKPaymentVerification(
      success: explicitSuccess,
      status: status,
      amount: bigkDouble(payload, const ['amount', 'paid_amount']),
      currency: bigkString(
        payload,
        const ['currency', 'display_currency'],
      ),
      message: bigkString(payload, const ['message']),
    );
  }
}

class BigKPaymentService {
  static Future<List<BigKCurrency>> getCurrencies() async {
    debugPrint('BigKPaymentService: Fetching currencies...');

    return BigKHttpService.getWallet<List<BigKCurrency>>(
      '/currencies',
      (data) => bigkUnwrapList(data, preferredKey: 'currencies')
          .map(BigKCurrency.fromJson)
          .toList(),
    );
  }

  static Future<List<BigKExchangeRate>> getExchangeRates() async {
    debugPrint('BigKPaymentService: Fetching exchange rates...');

    return BigKHttpService.getWallet<List<BigKExchangeRate>>(
      '/exchange-rates',
      (data) => bigkUnwrapList(data, preferredKey: 'rates')
          .map(BigKExchangeRate.fromJson)
          .toList(),
    );
  }

  static Future<BigKConversionQuote> convert({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) async {
    debugPrint('BigKPaymentService: Converting amount...');

    return BigKHttpService.getWallet<BigKConversionQuote>(
      '/exchange-rates/convert',
      BigKConversionQuote.fromJson,
      queryParams: <String, String>{
        'amount': amount.toString(),
        'from': fromCurrency.trim().toUpperCase(),
        'to': toCurrency.trim().toUpperCase(),
      },
    );
  }

  static Future<BigKPriceQuote> getDisplayPrice({
    required double amount,
    required String currency,
  }) async {
    debugPrint('BigKPaymentService: Fetching localized price...');

    return BigKHttpService.getWallet<BigKPriceQuote>(
      '/currencies/price',
      BigKPriceQuote.fromJson,
      queryParams: <String, String>{
        'amount': amount.toString(),
        'currency': currency.trim().toUpperCase(),
      },
    );
  }

  static Future<BigKTopUpSession> createTopUpSession({
    required double amount,
    String currency = 'usd',
    required String successUrl,
    required String cancelUrl,
  }) async {
    debugPrint('BigKPaymentService: Creating Stripe checkout session...');

    return BigKHttpService.postWallet<BigKTopUpSession>(
      '/payments/stripe/checkout',
      <String, dynamic>{
        'amount': amount,
        'currency': currency.trim().toLowerCase(),
        'success_url': successUrl,
        'cancel_url': cancelUrl,
      },
      BigKTopUpSession.fromJson,
    );
  }

  static Future<BigKPaymentVerification> verifyPayment(String sessionId) async {
    debugPrint('BigKPaymentService: Verifying payment session $sessionId...');

    return BigKHttpService.getWallet<BigKPaymentVerification>(
      '/payments/stripe/verify/$sessionId',
      BigKPaymentVerification.fromJson,
    );
  }

  static Future<BigKConversionQuote> getFundingExchangeRate() async {
    debugPrint('BigKPaymentService: Fetching funding exchange rate...');

    return BigKHttpService.getWallet<BigKConversionQuote>(
      '/payments/exchange-rate',
      BigKConversionQuote.fromJson,
    );
  }

  static Future<BigKTopUpSession> createPaymentIntent({
    required double amount,
    String currency = 'usd',
  }) async {
    debugPrint('BigKPaymentService: Creating Stripe payment intent...');

    return BigKHttpService.postWallet<BigKTopUpSession>(
      '/payments/intents',
      <String, dynamic>{
        'amount': amount,
        'currency': currency.trim().toLowerCase(),
      },
      BigKTopUpSession.fromJson,
    );
  }
}
