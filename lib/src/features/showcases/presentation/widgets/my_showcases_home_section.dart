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

    if (providerType == ProviderType.client) {
      return const _SectionCard(
        title: 'طلباتي',
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: Text('قريباً', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ),
      );
    }

    if (providerType != ProviderType.freelancer &&
        providerType != ProviderType.supplier) {
      return const SizedBox.shrink();
    }

    final title = providerType == ProviderType.freelancer ? 'مشاريعي' : 'عروضي';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionCard(
          title: 'إحصائياتي',
          child: _ShowcaseStatsChart(userId: profile.id),
        ),
        const SizedBox(height: 14),
        BlocProvider(
          create: (_) => ShowcasesCubit(
            getShowcases: getIt<GetShowcasesUseCase>(),
            userId: profile.id,
            pageSize: 2,
          )..load(),
          child: _MyShowcasesPreview(title: title, userId: profile.id),
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
        final open = snapshot.data?[0] ?? 0;
        final closed = snapshot.data?[1] ?? 0;
        final total = open + closed;

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
                        painter: _DonutChartPainter(open: open, closed: closed),
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
                              const Text(
                                'إجمالي',
                                style: TextStyle(fontSize: 11),
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
                    _LegendRow(color: Colors.green, label: 'مفتوح', value: open),
                    const SizedBox(height: 12),
                    _LegendRow(color: Colors.red, label: 'مغلق', value: closed),
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
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
