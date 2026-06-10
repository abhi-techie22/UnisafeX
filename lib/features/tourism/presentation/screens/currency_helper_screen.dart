import 'package:flutter/material.dart';

class CurrencyHelperScreen extends StatefulWidget {
  const CurrencyHelperScreen({super.key});

  @override
  State<CurrencyHelperScreen> createState() => _CurrencyHelperScreenState();
}

class _CurrencyHelperScreenState extends State<CurrencyHelperScreen> {
  final _controller = TextEditingController(text: '100');
  String _currency = 'USD';

  // TODO: Replace static fallback rates with a reliable live-rate API.
  static const _rates = {'USD': 83.5, 'EUR': 90.5, 'GBP': 106.0};

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(_controller.text) ?? 0;
    final converted = amount * _rates[_currency]!;
    return Scaffold(
      appBar: AppBar(title: const Text('Currency Helper')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Estimate your spending',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Quick offline reference rates for travel planning.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 28),
          TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Amount',
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _currency,
                    items: _rates.keys
                        .map((value) =>
                            DropdownMenuItem(value: value, child: Text(value)))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _currency = value ?? _currency),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text('Estimated value',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 10),
                  Text(
                    'INR ${converted.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1 $_currency ≈ INR ${_rates[_currency]!.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Rates are static estimates and may differ from banks, cards, or '
            'currency exchanges.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
