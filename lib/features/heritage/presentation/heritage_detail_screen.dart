import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:unisafex/core/theme/app_theme.dart';
import 'package:unisafex/features/heritage/domain/heritage_monument.dart';

class HeritageDetailScreen extends StatelessWidget {
  const HeritageDetailScreen({super.key, required this.monument});
  final HeritageMonument monument;

  @override
  Widget build(BuildContext context) {
    final location = [
      monument.locality,
      monument.district,
      monument.state,
    ].whereType<String>().where((value) => value.isNotEmpty).join(', ');

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 280,
            flexibleSpace: FlexibleSpaceBar(
              background: monument.imageUrl?.isNotEmpty == true
                  ? Image.network(
                      monument.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallback(),
                    )
                  : _fallback(),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList.list(
              children: [
                Text(monument.name,
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        color: AppColors.primary),
                    const SizedBox(width: 6),
                    Expanded(child: Text(location)),
                  ],
                ),
                const SizedBox(height: 22),
                _InfoGrid(monument: monument),
                const SizedBox(height: 22),
                Text('about'.tr(),
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  monument.description?.isNotEmpty == true
                      ? monument.description!
                      : '${monument.name} is a centrally protected Indian '
                          'heritage site maintained in the UniSafeX catalogue. '
                          'Detailed visitor information can be added from the '
                          'Admin Console.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.6,
                      ),
                ),
                const SizedBox(height: 22),
                _DetailRow(label: 'region'.tr(), value: monument.region ?? '-'),
                _DetailRow(
                    label: 'asi_circle'.tr(), value: monument.asiCircle ?? '-'),
                _DetailRow(
                  label: 'protection_status'.tr(),
                  value: monument.protectionStatus ?? '-',
                ),
                _DetailRow(
                  label: 'visitor_information'.tr(),
                  value: monument.visitorCategory ?? 'free_entry'.tr(),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallback() => Image.asset(
        'assets/images/heritage_placeholder.jpg',
        fit: BoxFit.cover,
      );
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.monument});
  final HeritageMonument monument;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: _InfoTile(
              icon: Icons.category_outlined,
              label: 'category'.tr(),
              value: monument.monumentType ?? '-',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _InfoTile(
              icon: Icons.confirmation_number_outlined,
              label: 'entry_fee'.tr(),
              value: monument.entryFeeForeigner == null ||
                      monument.entryFeeForeigner == 0
                  ? 'free_entry'.tr()
                  : '₹${monument.entryFeeForeigner!.toInt()}',
            ),
          ),
        ],
      );
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 3),
            Text(value,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 130,
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            Expanded(child: Text(value)),
          ],
        ),
      );
}
