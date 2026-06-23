import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../domain/entities/notification_item.dart';
import '../cubit/notifications_cubit.dart';

class NotificationDetailPage extends StatefulWidget {
  const NotificationDetailPage({super.key, required this.notification});

  final NotificationItem notification;

  @override
  State<NotificationDetailPage> createState() => _NotificationDetailPageState();
}

class _NotificationDetailPageState extends State<NotificationDetailPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..forward();

    _fadeIn = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(begin: const Offset(0, .12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));

    if (!widget.notification.isRead) {
      context.read<NotificationsCubit>().markAsRead(widget.notification.id);
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final config = _NotificationConfig.from(widget.notification);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: scheme.surfaceContainerLowest,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(config.categoryLabel,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
        body: FadeTransition(
          opacity: _fadeIn,
          child: SlideTransition(
            position: _slideUp,
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                    child: Column(
                      children: [
                        // ── Hero icon ──────────────────────────────────────
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: config.gradientColors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: config.gradientColors.first
                                    .withValues(alpha: .35),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(config.icon,
                              size: 48, color: Colors.white),
                        ),

                        const SizedBox(height: 28),

                        // ── Title ──────────────────────────────────────────
                        Text(
                          widget.notification.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            height: 1.35,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── Content card ───────────────────────────────────
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            widget.notification.content,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.6,
                              color: scheme.onSurface
                                  .withValues(alpha: .85),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // ── Time ───────────────────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.access_time_rounded,
                                size: 14,
                                color: scheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(
                              _formatTime(widget.notification.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),

                        const Spacer(),

                        // ── Navigate button ────────────────────────────────
                        if (config.destination != null) ...[
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: config.gradientColors.last,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: Icon(config.destinationIcon,
                                  size: 20),
                              label: Text(
                                config.destinationLabel!,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              onPressed: () =>
                                  context.push(config.destination!),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 1) return 'منذ ${diff.inDays} يوم';
    if (diff.inHours >= 1) return 'منذ ${diff.inHours} ساعة';
    if (diff.inMinutes >= 1) return 'منذ ${diff.inMinutes} دقيقة';
    return 'الآن';
  }
}

// ── Notification config (type → icon, colors, destination) ───────────────────

class _NotificationConfig {
  const _NotificationConfig({
    required this.icon,
    required this.gradientColors,
    required this.categoryLabel,
    this.destination,
    this.destinationLabel,
    this.destinationIcon = Icons.arrow_forward_rounded,
  });

  final IconData icon;
  final List<Color> gradientColors;
  final String categoryLabel;
  final String? destination;
  final String? destinationLabel;
  final IconData destinationIcon;

  factory _NotificationConfig.from(NotificationItem n) {
    switch (n.type) {
      case 'QuotationAccepted':
        return _NotificationConfig(
          icon: Icons.check_circle_rounded,
          gradientColors: const [Color(0xFF22C55E), Color(0xFF16A34A)],
          categoryLabel: 'عرض سعر',
          destination: n.referenceId != null
              ? '${AppRoutes.requestById}?id=${n.referenceId}'
              : null,
          destinationLabel: 'عرض الطلب',
          destinationIcon: Icons.assignment_rounded,
        );
      case 'QuotationRejected':
        return _NotificationConfig(
          icon: Icons.cancel_rounded,
          gradientColors: const [Color(0xFFEF4444), Color(0xFFDC2626)],
          categoryLabel: 'عرض سعر',
          destination: n.referenceId != null
              ? '${AppRoutes.requestById}?id=${n.referenceId}'
              : null,
          destinationLabel: 'عرض الطلب',
          destinationIcon: Icons.assignment_rounded,
        );
      case 'NewQuotation':
        // Client receives this — referenceId = requestId
        return _NotificationConfig(
          icon: Icons.local_offer_rounded,
          gradientColors: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
          categoryLabel: 'عرض سعر جديد',
          destination: n.referenceId != null
              ? '${AppRoutes.quotations}?requestId=${n.referenceId}'
              : null,
          destinationLabel: 'عرض العروض',
          destinationIcon: Icons.local_offer_outlined,
        );
      case 'QuotationSubmitted':
        // Provider receives confirmation — referenceId = requestId
        return _NotificationConfig(
          icon: Icons.send_rounded,
          gradientColors: const [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
          categoryLabel: 'تأكيد الإرسال',
          destination: n.referenceId != null
              ? '${AppRoutes.requestById}?id=${n.referenceId}'
              : null,
          destinationLabel: 'عرض الطلب',
          destinationIcon: Icons.assignment_rounded,
        );
      case 'NewRequest':
        return _NotificationConfig(
          icon: Icons.assignment_rounded,
          gradientColors: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
          categoryLabel: 'طلب جديد',
          destination: AppRoutes.requests,
          destinationLabel: 'تصفح الطلبات',
          destinationIcon: Icons.list_alt_rounded,
        );
      default:
        return const _NotificationConfig(
          icon: Icons.notifications_rounded,
          gradientColors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
          categoryLabel: 'إشعار',
        );
    }
  }
}
