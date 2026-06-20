import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/di/service_locator.dart';
import '../cubit/request_stats_cubit.dart';
import '../cubit/requests_cubit.dart';
import '../pages/my_requests_page.dart';
import 'request_card.dart';

class MyRequestsHomeSection extends StatelessWidget {
  const MyRequestsHomeSection({super.key, required this.clientId});

  final String clientId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Stats ──────────────────────────────────────────────
        BlocProvider(
          create: (_) => getIt<RequestStatsCubit>()..load(),
          child: const _RequestStatsSection(),
        ),
        const SizedBox(height: 14),
        // ── Last 2 requests ────────────────────────────────────
        BlocProvider(
          create: (_) => RequestsCubit(
            getRequests: getIt(),
            clientId: clientId,
            pageSize: 2,
          )..load(),
          child: _MyRequestsPreview(clientId: clientId),
        ),
      ],
    );
  }
}

// ── Stats section ────────────────────────────────────────────────────────────

class _RequestStatsSection extends StatelessWidget {
  const _RequestStatsSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RequestStatsCubit, RequestStatsState>(
      builder: (context, state) {
        return _SectionCard(
          title: 'إحصائياتي',
          child: state.isLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              : state.stats == null
              ? const SizedBox.shrink()
              : _StatsCharts(stats: state.stats!),
        );
      },
    );
  }
}

class _StatsCharts extends StatelessWidget {
  const _StatsCharts({required this.stats});

  final dynamic stats; // RequestStats

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final statusSegments = [
      (_StatusColor.open, stats.openRequests as int, 'مفتوح'),
      (_StatusColor.inProgress, stats.inProgressRequests as int, 'جارٍ'),
      (_StatusColor.completed, stats.completedRequests as int, 'مكتمل'),
      (_StatusColor.cancelled, stats.cancelledRequests as int, 'ملغى'),
    ];

    final typeSegments = [
      (const Color(0xFF0EA5E9), stats.materialRequests as int, 'مادة'),
      (scheme.primary, stats.serviceRequests as int, 'خدمة'),
    ];

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status donut
            Expanded(
              child: _ChartBlock(
                title: 'الحالة',
                total: stats.totalRequests as int,
                totalLabel: 'الكل',
                segments: statusSegments,
              ),
            ),
            Container(
              width: 1,
              height: 140,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            // Type donut
            Expanded(
              child: _ChartBlock(
                title: 'النوع',
                total: stats.totalRequests as int,
                totalLabel: 'الكل',
                segments: typeSegments,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusColor {
  static const open = Color(0xFF16A34A);
  static const inProgress = Color(0xFFD97706);
  static const completed = Color(0xFF2563EB);
  static const cancelled = Color(0xFFDC2626);
}

class _ChartBlock extends StatelessWidget {
  const _ChartBlock({
    required this.title,
    required this.total,
    required this.totalLabel,
    required this.segments,
  });

  final String title;
  final int total;
  final String totalLabel;
  final List<(Color, int, String)> segments;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: CustomPaint(
                painter: _MultiDonutPainter(
                  segments: segments.map((s) => (s.$1, s.$2)).toList(),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$total',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        totalLabel,
                        style: const TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: segments.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: _LegendRow(color: s.$1, label: s.$3, value: s.$2),
                  ),
                ).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MultiDonutPainter extends CustomPainter {
  _MultiDonutPainter({required this.segments});

  final List<(Color, int)> segments;

  static const _strokeWidth = 10.0;
  static const _gap = 0.04; // radians gap between segments

  @override
  void paint(Canvas canvas, Size size) {
    final total = segments.fold(0, (sum, s) => sum + s.$2);
    final rect = Rect.fromLTWH(0, 0, size.width, size.height)
        .deflate(_strokeWidth / 2 + 2);

    if (total == 0) {
      canvas.drawArc(
        rect,
        0,
        2 * pi,
        false,
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
        rect,
        startAngle,
        sweep,
        false,
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
  bool shouldRepaint(covariant _MultiDonutPainter old) =>
      old.segments != segments;
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.color, required this.label, required this.value});

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
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '$value',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

// ── My requests preview ───────────────────────────────────────────────────────

class _MyRequestsPreview extends StatelessWidget {
  const _MyRequestsPreview({required this.clientId});

  final String clientId;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocBuilder<RequestsCubit, RequestsState>(
      builder: (context, state) {
        return _SectionCard(
          title: 'طلباتي',
          onSeeAll: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => MyRequestsPage(clientId: clientId),
            ),
          ),
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
                      'لا توجد طلبات بعد',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ),
                )
              : Column(
                  children: state.items
                      .map(
                        (req) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: RequestCard(
                            request: req,
                            onTap: () => context.push(
                              AppRoutes.requestDetails,
                              extra: req,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
        );
      },
    );
  }
}

// ── Section card ──────────────────────────────────────────────────────────────

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
      padding: const EdgeInsets.all(14),
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
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              if (onSeeAll != null)
                TextButton(onPressed: onSeeAll, child: const Text('عرض الكل')),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
