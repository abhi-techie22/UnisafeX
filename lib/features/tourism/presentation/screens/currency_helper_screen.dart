import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:unisafex/core/theme/app_theme.dart';
import 'package:unisafex/features/tourism/data/services/currency_service.dart';
import 'package:unisafex/features/tourism/domain/entities/currency_info.dart';

class CurrencyHelperScreen extends StatefulWidget {
  const CurrencyHelperScreen({super.key});

  @override
  State<CurrencyHelperScreen> createState() => _CurrencyHelperScreenState();
}

class _CurrencyHelperScreenState extends State<CurrencyHelperScreen> {
  final _controller = TextEditingController(text: '100');
  final _service = CurrencyService();

  List<CurrencyInfo> _currencies = const [];
  CurrencyRates? _rates;
  String _from = 'USD';
  String _to = 'INR';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final currencies = await _service.getCurrencies();
    final rates = await _service.getRates(_from);
    if (!mounted) return;
    setState(() {
      _currencies = currencies;
      _rates = rates;
      if (!_currencies.any((currency) => currency.code == _from)) {
        _from = _currencies.first.code;
      }
      if (!_currencies.any((currency) => currency.code == _to)) {
        _to = _currencies.first.code;
      }
      _loading = false;
    });
  }

  Future<void> _changeBase(String value) async {
    if (value == _from) return;
    setState(() {
      _from = value;
      _loading = true;
    });
    final rates = await _service.getRates(value);
    if (mounted) {
      setState(() {
        _rates = rates;
        _loading = false;
      });
    }
  }

  Future<void> _swap() async {
    final previousFrom = _from;
    setState(() {
      _from = _to;
      _to = previousFrom;
      _loading = true;
    });
    final rates = await _service.getRates(_from);
    if (mounted) {
      setState(() {
        _rates = rates;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(_controller.text.replaceAll(',', '')) ?? 0;
    final rate = _rates?.rates[_to];
    final converted = rate == null ? null : amount * rate;
    final formatter = NumberFormat('#,##0.00');

    return Scaffold(
      appBar: AppBar(
        title: Text('currency_helper'.tr()),
        actions: [
          IconButton(
            tooltip: 'refresh_rates'.tr(),
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.currency_exchange_rounded,
                    color: Colors.white, size: 34),
                SizedBox(height: 20),
                Text(
                  'Convert travel money',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'Convert between available world currencies with cached '
                  'rates for offline reference.',
                  style: TextStyle(color: Colors.white70, height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Amount',
              prefixIcon: Icon(Icons.payments_outlined),
            ),
          ),
          const SizedBox(height: 14),
          _CurrencyField(
            label: 'from'.tr(),
            currency: _currency(_from),
            onTap: _currencies.isEmpty
                ? null
                : () async {
                    final value = await _pickCurrency(_from);
                    if (value != null) await _changeBase(value.code);
                  },
          ),
          Center(
            child: IconButton.filledTonal(
              tooltip: 'swap_currencies'.tr(),
              onPressed: _loading ? null : _swap,
              icon: const Icon(Icons.swap_vert_rounded),
            ),
          ),
          _CurrencyField(
            label: 'to'.tr(),
            currency: _currency(_to),
            onTap: _currencies.isEmpty
                ? null
                : () async {
                    final value = await _pickCurrency(_to);
                    if (value != null) setState(() => _to = value.code);
                  },
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.18),
              ),
            ),
            child: Column(
              children: [
                Text(
                  '${formatter.format(amount)} $_from',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(),
                  )
                else
                  Text(
                    converted == null
                        ? 'Rate unavailable'
                        : '${formatter.format(converted)} $_to',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: AppColors.primary,
                          fontSize: 34,
                        ),
                  ),
                const SizedBox(height: 8),
                if (rate != null)
                  Text(
                    '1 $_from = ${rate.toStringAsFixed(4)} $_to',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _RateStatus(rates: _rates),
          const SizedBox(height: 12),
          Text(
            'Reference rates may differ from card networks, banks and cash '
            'exchange counters. Always review the final charged amount.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  CurrencyInfo _currency(String code) => _currencies.firstWhere(
        (currency) => currency.code == code,
        orElse: () => CurrencyInfo(code: code, name: code),
      );

  Future<CurrencyInfo?> _pickCurrency(String selected) {
    return showModalBottomSheet<CurrencyInfo>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _CurrencyPicker(
        currencies: _currencies,
        selected: selected,
      ),
    );
  }
}

class _CurrencyField extends StatelessWidget {
  const _CurrencyField({
    required this.label,
    required this.currency,
    required this.onTap,
  });

  final String label;
  final CurrencyInfo currency;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.public_rounded),
          suffixIcon: const Icon(Icons.expand_more_rounded),
        ),
        child: Text(
          '${currency.code} · ${currency.name}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _RateStatus extends StatelessWidget {
  const _RateStatus({required this.rates});

  final CurrencyRates? rates;

  @override
  Widget build(BuildContext context) {
    if (rates == null) return const SizedBox.shrink();
    final date = DateFormat('d MMM yyyy').format(rates!.updatedAt);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          rates!.isLive
              ? Icons.cloud_done_outlined
              : Icons.offline_bolt_outlined,
          color: rates!.isLive ? AppColors.success : AppColors.warning,
          size: 18,
        ),
        const SizedBox(width: 7),
        Text(
          rates!.isLive
              ? 'Reference rates updated $date'
              : 'Offline reference rates · last available $date',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _CurrencyPicker extends StatefulWidget {
  const _CurrencyPicker({
    required this.currencies,
    required this.selected,
  });

  final List<CurrencyInfo> currencies;
  final String selected;

  @override
  State<_CurrencyPicker> createState() => _CurrencyPickerState();
}

class _CurrencyPickerState extends State<_CurrencyPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final query = _query.toLowerCase();
    final filtered = widget.currencies
        .where(
          (currency) =>
              currency.code.toLowerCase().contains(query) ||
              currency.name.toLowerCase().contains(query),
        )
        .toList();

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.78,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: TextField(
              autofocus: true,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'search_currency'.tr(),
                prefixIcon: const Icon(Icons.search_rounded),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final currency = filtered[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      currency.symbol?.trim().isNotEmpty == true
                          ? currency.symbol!
                          : currency.code.substring(0, 1),
                      style: const TextStyle(color: AppColors.primary),
                    ),
                  ),
                  title: Text(currency.code),
                  subtitle: Text(currency.name),
                  trailing: widget.selected == currency.code
                      ? const Icon(Icons.check_circle, color: AppColors.primary)
                      : null,
                  onTap: () => Navigator.pop(context, currency),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
