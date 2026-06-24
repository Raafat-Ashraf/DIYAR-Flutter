import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/di/service_locator.dart';
import '../../domain/entities/quotation.dart';
import '../../domain/entities/quotation_stats.dart';
import '../cubit/quotation_stats_cubit.dart';
import '../cubit/quotations_cubit.dart';
import '../cubit/quotations_state.dart';
import 'quotation_card.dart';

class MyQuotationsHomeSection extends StatelessWidget {
  const MyQuotationsHomeSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlocProvider(
          create: (_) => QuotationStatsCubit(getIt())..load(),
          child: const _QuotationStatsSection(),
        ),
        const SizedBox(height: 8),
        BlocProvider(
          create: (_) => QuotationsCubit(
            getQuotations: getIt(),
            cancelQuotation: getIt(),
            acceptQuotation: getIt(),
            rejectQuotation: getIt(),
            pageSize: 3,
          )..load(),
          child: const _MyQuotationsPreview(),
        ),
      ],
    );
  }
}

// ── Stats ─────────────────────────────────────────────────────────────────────

class _QuotationStatsSection extends StatelessWidget {
  const _QuotationStatsSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QuotationStatsCubit, QuotationStatsState>(
      builder: (context, state) {
        return _SectionCard(
          title: 'إحصائياتي',
          child: state.isLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              : _QuotationStatsChart(stats: state.stats ?? QuotationStats.empty),
        );
      },
    );
  }
}

class _QuotationStatsChart extends StatelessWidget {
  const _QuotationStatsChart({required this.stats});
  final QuotationStats stats;

  @override
  Widget build(BuildContext context) {
    final segments = [
      (const Color(0xFFF59E0B), stats.pendingQuotations, 'قيد الانتظار'),
      (const Color(0xFF16A34A), stats.acceptedQuotations, 'مقبول'),
      (const Color(0xFFDC2626), stats.rejectedQuotations, 'مرفوض'),
      (const Color(0xFF6B7280), stats.cancelledQuotations, 'ملغى'),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: CustomPaint(
            painter: _DonutPainter(
              segments: segments.map((s) => (s.$1, s.$2)).toList(),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${stats.totalQuotations}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                  const Text('الكل', style: TextStyle(fontSize: 9)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: segments.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _LegendRow(color: s.$1, label: s.$3, value: s.$2),
              ),
            ).toList(),
          ),
        ),
      ],
    );
  }
}

// ── Recent quotations ─────────────────────────────────────────────────────────

class _MyQuotationsPreview extends StatelessWidget {
  const _MyQuotationsPreview();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocBuilder<QuotationsCubit, QuotationsState>(
      builder: (context, state) {
        return _SectionCard(
          title: 'العروض المقدمة',
          onSeeAll: state.items.isEmpty
              ? null
              : () => context.push(AppRoutes.quotations),
          child: state.isLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              : state.items.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          'لم تقدم أي عروض بعد',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      ),
                    )
                  : Column(
                      children: state.items
                          .map((q) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _QuotationHomeCard(quotation: q),
                              ))
                          .toList(),
                    ),
        );
      },
    );
  }
}

class _QuotationHomeCard extends StatelessWidget {
  const _QuotationHomeCard({required this.quotation});
  final Quotation quotation;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = quotation.status;
    final statusColor = _statusColor(status);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'طلب #${quotation.requestId}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status?.arabicLabel ?? '-',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${quotation.price.toStringAsFixed(0)} ج.م'
                  '${quotation.executionDurationDays != null ? ' • ${quotation.executionDurationDays} يوم' : ''}',
                  style: TextStyle(
                      fontSize: 13, color: scheme.onSurfaceVariant),
                ),
                if (quotation.description != null &&
                    quotation.description!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    quotation.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12, color: scheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => context.push(
              '${AppRoutes.requestById}?id=${quotation.requestId}',
            ),
            style: OutlinedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(fontSize: 12),
            ),
            icon: const Icon(Icons.open_in_new_rounded, size: 14),
            label: const Text('الطلب'),
          ),
        ],
      ),
    );
  }

  Color _statusColor(QuotationStatus? status) {
    return switch (status) {
      QuotationStatus.pending => const Color(0xFFF59E0B),
      QuotationStatus.accepted => const Color(0xFF16A34A),
      QuotationStatus.rejected => const Color(0xFFDC2626),
      QuotationStatus.cancelled => const Color(0xFF6B7280),
      null => const Color(0xFF6B7280),
    };
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.onSeeAll,
  });

  final String title;
  final Widget child;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: .05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
              if (onSeeAll != null)
                TextButton(onPressed: onSeeAll, child: const Text('عرض الكل')),
            ],
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow(
      {required this.color, required this.label, required this.value});

  final Color color;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(label,
              style:
                  const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis),
        ),
        Text('$value',
            style:
                const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.segments});
  final List<(Color, int)> segments;

  static const _strokeWidth = 10.0;
  static const _gap = 0.04;

  @override
  void paint(Canvas canvas, Size size) {
    final total = segments.fold(0, (s, e) => s + e.$2);
    final rect =
        Rect.fromLTWH(0, 0, size.width, size.height).deflate(_strokeWidth / 2 + 2);

    if (total == 0) {
      canvas.drawArc(
        rect, 0, 2 * pi, false,
        Paint()
          ..color = Colors.grey.withValues(alpha: .2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = _strokeWidth,
      );
      return;
    }

    double startAngle = -pi / 2;
    for (final (color, value) in segments) {
      if (value == 0) continue;
      final sweep = (2 * pi * (value / total)) - _gap;
      canvas.drawArc(
        rect, startAngle, sweep, false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = _strokeWidth
          ..strokeCap = StrokeCap.round,
      );
      startAngle += sweep + _gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => old.segments != segments;
}
