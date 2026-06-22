import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/di/service_locator.dart';
import '../../../account/domain/entities/account_profile.dart';
import '../../domain/usecases/get_showcases_use_case.dart';
import '../cubit/showcases_cubit.dart';
import '../pages/my_showcases_page.dart';
import 'showcase_card.dart';

class MyShowcasesHomeSection extends StatelessWidget {
  const MyShowcasesHomeSection({super.key, required this.profile});

  final AccountProfile profile;

  @override
  Widget build(BuildContext context) {
    final providerType = profile.providerType;

    if (providerType == ProviderType.client) return const SizedBox.shrink();

    // Supplier: stats UI ready, other sections coming soon
    if (providerType == ProviderType.supplier) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionCard(
            title: 'إحصائياتي',
            child: const _SupplierStatsChart(),
          ),
          const SizedBox(height: 8),
          _SectionCard(
            title: 'العروض المقدمة',
            child: const _ComingSoonContent(),
          ),
          const SizedBox(height: 8),
          _SectionCard(
            title: 'سجل التعليقات',
            child: const _ComingSoonContent(),
          ),
        ],
      );
    }

    if (providerType != ProviderType.freelancer) {
      return const SizedBox.shrink();
    }

    // Freelancer sections
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats — zeros until API is ready (same as supplier)
        _SectionCard(
          title: 'إحصائياتي',
          child: const _SupplierStatsChart(),
        ),
        const SizedBox(height: 8),
        // مشاريعي — existing implementation
        BlocProvider(
          create: (_) => ShowcasesCubit(
            getShowcases: getIt<GetShowcasesUseCase>(),
            userId: profile.id,
            pageSize: 2,
          )..load(),
          child: _MyShowcasesPreview(title: 'مشاريعي', userId: profile.id),
        ),
        const SizedBox(height: 8),
        // Coming soon sections
        _SectionCard(
          title: 'العروض المقدمة',
          child: const _ComingSoonContent(),
        ),
        const SizedBox(height: 8),
        _SectionCard(
          title: 'السجل',
          child: const _ComingSoonContent(),
        ),
      ],
    );
  }
}

class _ShowcaseStatsChart extends StatefulWidget {
  const _ShowcaseStatsChart({required this.userId});

  final String userId;

  @override
  State<_ShowcaseStatsChart> createState() => _ShowcaseStatsChartState();
}

class _ShowcaseStatsChartState extends State<_ShowcaseStatsChart> {
  late final Future<List<int>> _future;

  @override
  void initState() {
    super.initState();
    final useCase = getIt<GetShowcasesUseCase>();
    _future = Future.wait([
      useCase(pageNumber: 1, pageSize: 1, userId: widget.userId, isOpen: true),
      useCase(
        pageNumber: 1,
        pageSize: 1,
        userId: widget.userId,
        isOpen: false,
      ),
    ]).then((results) => results.map((r) => r.totalCount).toList());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<int>>(
      future: _future,
      builder: (context, snapshot) {
        final loading = !snapshot.hasData;
        final first = snapshot.data?[0] ?? 0;
        final second = snapshot.data?[1] ?? 0;
        final total = first + second;
        const label1 = 'مفتوح';
        const label2 = 'مغلق';
        const color1 = Colors.green;
        const color2 = Colors.red;
        const totalLabel = 'إجمالي';

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 96,
                height: 96,
                child: loading
                    ? const Center(
                        child: CircularProgressIndicator(strokeWidth: 3),
                      )
                    : CustomPaint(
                        painter: _DonutChartPainter(open: first, closed: second),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$total',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                ),
                              ),
                              Text(
                                totalLabel,
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LegendRow(color: color1, label: label1, value: first),
                    const SizedBox(height: 8),
                    _LegendRow(color: color2, label: label2, value: second),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  _DonutChartPainter({required this.open, required this.closed});

  final int open;
  final int closed;

  static const _strokeWidth = 12.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height).deflate(
      _strokeWidth / 2,
    );
    final total = open + closed;

    if (total == 0) {
      final emptyPaint = Paint()
        ..color = Colors.grey.withValues(alpha: .2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth;
      canvas.drawArc(rect, 0, 2 * pi, false, emptyPaint);
      return;
    }

    const startAngle = -pi / 2;
    final openSweep = 2 * pi * (open / total);
    final closedSweep = 2 * pi * (closed / total);

    if (open > 0) {
      canvas.drawArc(
        rect,
        startAngle,
        openSweep,
        false,
        Paint()
          ..color = Colors.green
          ..style = PaintingStyle.stroke
          ..strokeWidth = _strokeWidth,
      );
    }
    if (closed > 0) {
      canvas.drawArc(
        rect,
        startAngle + openSweep,
        closedSweep,
        false,
        Paint()
          ..color = Colors.red
          ..style = PaintingStyle.stroke
          ..strokeWidth = _strokeWidth,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) =>
      oldDelegate.open != open || oldDelegate.closed != closed;
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        const Spacer(),
        Text(
          '$value',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
      ],
    );
  }
}

class _MyShowcasesPreview extends StatelessWidget {
  const _MyShowcasesPreview({required this.title, required this.userId});

  final String title;
  final String userId;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocBuilder<ShowcasesCubit, ShowcasesState>(
      builder: (context, state) {
        return _SectionCard(
          title: title,
          onSeeAll: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => MyShowcasesPage(title: title, userId: userId),
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
                      'لا توجد عروض حالياً',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ),
                )
              : Column(
                  children: state.items
                      .map(
                        (showcase) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: ShowcaseCard(
                            showcase: showcase,
                            onTap: () => context.push(
                              AppRoutes.showcaseDetails,
                              extra: showcase,
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.onSeeAll});

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
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}

// ── Supplier stats chart (UI only, all zeros until API ready) ─────────────────

class _SupplierStatsChart extends StatelessWidget {
  const _SupplierStatsChart();

  @override
  Widget build(BuildContext context) {
    const accepted = 0;
    const inProgress = 0;
    const rejected = 0;
    const total = accepted + inProgress + rejected;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: CustomPaint(
              painter: _SupplierDonutPainter(
                accepted: accepted,
                inProgress: inProgress,
                rejected: rejected,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$total',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                    const Text('عروض', style: TextStyle(fontSize: 11)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LegendRow(
                  color: const Color(0xFF16A34A),
                  label: 'مقبول',
                  value: accepted,
                ),
                const SizedBox(height: 8),
                _LegendRow(
                  color: const Color(0xFFD97706),
                  label: 'جارٍ',
                  value: inProgress,
                ),
                const SizedBox(height: 8),
                _LegendRow(
                  color: const Color(0xFFDC2626),
                  label: 'مرفوض',
                  value: rejected,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SupplierDonutPainter extends CustomPainter {
  const _SupplierDonutPainter({
    required this.accepted,
    required this.inProgress,
    required this.rejected,
  });

  final int accepted;
  final int inProgress;
  final int rejected;

  static const _strokeWidth = 12.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height)
        .deflate(_strokeWidth / 2);
    final total = accepted + inProgress + rejected;

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

    const gap = 0.05;
    double start = -pi / 2;

    void drawArc(int value, Color color) {
      if (value == 0) return;
      final sweep = (2 * pi * (value / total)) - gap;
      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = _strokeWidth
          ..strokeCap = StrokeCap.round,
      );
      start += sweep + gap;
    }

    drawArc(accepted, const Color(0xFF16A34A));
    drawArc(inProgress, const Color(0xFFD97706));
    drawArc(rejected, const Color(0xFFDC2626));
  }

  @override
  bool shouldRepaint(covariant _SupplierDonutPainter old) =>
      old.accepted != accepted ||
      old.inProgress != inProgress ||
      old.rejected != rejected;
}

class _ComingSoonContent extends StatelessWidget {
  const _ComingSoonContent();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.schedule_rounded,
              size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            'قريباً',
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
