import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../dto/bigk/bigk_funding.dart';
import '../../services/bigk/bigk_payment_service.dart';
import '../../services/http_service.dart';
import '../../util/message_util.dart';

class BigKTopUpPage extends StatefulWidget {
  const BigKTopUpPage({super.key});

  @override
  State<BigKTopUpPage> createState() => _BigKTopUpPageState();
}

class _BigKTopUpPageState extends State<BigKTopUpPage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _sessionIdController = TextEditingController();

  List<BigKCurrency> _currencies = const <BigKCurrency>[];
  List<BigKExchangeRate> _rates = const <BigKExchangeRate>[];
  BigKConversionQuote? _quote;
  BigKConversionQuote? _fundingRate;
  bool _isLoading = true;
  bool _isCreatingSession = false;
  bool _isVerifyingSession = false;
  String? _loadError;
  String _selectedCurrency = 'USD';

  @override
  void initState() {
    super.initState();
    _amountController.text = '10';
    _loadData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _sessionIdController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      BigKConversionQuote? fundingRate;
      try {
        fundingRate = await BigKPaymentService.getFundingExchangeRate();
      } catch (_) {
        fundingRate = null;
      }

      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        BigKPaymentService.getCurrencies(),
        BigKPaymentService.getExchangeRates(),
      ]);

      if (!mounted) {
        return;
      }

      final currencies = (results[0] as List<dynamic>).cast<BigKCurrency>();
      setState(() {
        _currencies = currencies.where((currency) => currency.enabled).toList();
        _rates = (results[1] as List<dynamic>).cast<BigKExchangeRate>();
        _fundingRate = fundingRate;
        if (_currencies.isNotEmpty &&
            !_currencies.any((item) => item.code == _selectedCurrency)) {
          _selectedCurrency = _currencies.first.code;
        }
        _isLoading = false;
      });

      await _refreshQuote(showError: false);
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _loadError = e.toString();
      });
    }
  }

  Future<void> _refreshQuote({bool showError = true}) async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0 || _selectedCurrency.isEmpty) {
      setState(() => _quote = null);
      return;
    }

    try {
      final quote = await BigKPaymentService.convert(
        amount: amount,
        fromCurrency: _selectedCurrency,
        toCurrency: 'KCC',
      );
      if (!mounted) {
        return;
      }
      setState(() => _quote = quote);
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _quote = null);
      if (showError) {
        MessageUtil.info(context, 'Quote unavailable: $e');
      }
    }
  }

  Future<void> _createCheckoutSession() async {
    if (_isCreatingSession) {
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      MessageUtil.info(context, 'Enter a valid amount.');
      return;
    }

    setState(() => _isCreatingSession = true);
    try {
      final session = await BigKPaymentService.createTopUpSession(
        amount: amount,
        currency: _selectedCurrency,
        successUrl: '${HttpService.domain}/?bigk_topup=success',
        cancelUrl: '${HttpService.domain}/?bigk_topup=cancel',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isCreatingSession = false;
        _sessionIdController.text = session.sessionId;
      });

      if (session.checkoutUrl.isNotEmpty) {
        final uri = Uri.tryParse(session.checkoutUrl);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (!mounted) {
            return;
          }
          MessageUtil.success(context, 'Checkout session created.');
          return;
        }
      }

      if (!mounted) {
        return;
      }
      MessageUtil.success(
        context,
        session.message.isNotEmpty
            ? session.message
            : 'Checkout session created.',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _isCreatingSession = false);
      MessageUtil.error(context, 'Checkout failed: $e');
    }
  }

  Future<void> _verifySession() async {
    if (_isVerifyingSession) {
      return;
    }

    final sessionId = _sessionIdController.text.trim();
    if (sessionId.isEmpty) {
      MessageUtil.info(context, 'Enter a session ID first.');
      return;
    }

    setState(() => _isVerifyingSession = true);
    try {
      final result = await BigKPaymentService.verifyPayment(sessionId);
      if (!mounted) {
        return;
      }

      setState(() => _isVerifyingSession = false);
      final message = result.message?.isNotEmpty == true
          ? result.message!
          : 'Status: ${result.status}';
      if (result.success || result.isComplete) {
        MessageUtil.success(context, message);
      } else {
        MessageUtil.info(context, message);
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _isVerifyingSession = false);
      MessageUtil.error(context, 'Verify failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Top up wallet'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  if (_loadError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _loadError!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  _buildFundingCard(theme),
                  const SizedBox(height: 16),
                  _buildRateCard(theme),
                ],
              ),
            ),
    );
  }

  Widget _buildFundingCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Hosted Stripe checkout',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Amount',
              hintText: '10.00',
            ),
            onChanged: (_) => _refreshQuote(showError: false),
          ),
          const SizedBox(height: 12),
          if (_currencies.isNotEmpty)
            DropdownButtonFormField<String>(
              initialValue: _selectedCurrency,
              decoration: const InputDecoration(labelText: 'Currency'),
              items: _currencies
                  .map(
                    (currency) => DropdownMenuItem<String>(
                      value: currency.code,
                      child: Text(currency.displayLabel),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() => _selectedCurrency = value);
                _refreshQuote(showError: false);
              },
            ),
          const SizedBox(height: 12),
          if (_quote != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _quote!.formatted.isNotEmpty
                    ? _quote!.formatted
                    : '${_quote!.fromAmount.toStringAsFixed(2)} ${_quote!.fromCurrency} ≈ '
                        '${_quote!.toAmount.toStringAsFixed(2)} ${_quote!.toCurrency}',
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isCreatingSession ? null : _createCheckoutSession,
              child: _isCreatingSession
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create checkout session'),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _sessionIdController,
            decoration: const InputDecoration(
              labelText: 'Session ID',
              hintText: 'Stripe checkout session ID',
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _isVerifyingSession ? null : _verifySession,
              child: _isVerifyingSession
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Verify session'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRateCard(ThemeData theme) {
    final displayRates = _rates.take(8).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Exchange rates',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (_fundingRate != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _fundingRate!.formatted.isNotEmpty
                    ? _fundingRate!.formatted
                    : 'Funding rate: ${_fundingRate!.rate.toStringAsFixed(4)}',
              ),
            ),
          if (displayRates.isEmpty)
            Text(
              'No exchange rate rows were returned.',
              style: theme.textTheme.bodySmall,
            )
          else
            ...displayRates.map(
              (rate) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        rate.pairLabel.isEmpty
                            ? 'Unknown pair'
                            : rate.pairLabel,
                      ),
                    ),
                    Text(rate.rate.toStringAsFixed(4)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
