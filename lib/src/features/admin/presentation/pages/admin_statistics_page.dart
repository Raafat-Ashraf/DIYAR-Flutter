import 'package:flutter/material.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_client.dart';

class AdminStatisticsPage extends StatefulWidget {
  const AdminStatisticsPage({super.key});

  @override
  State<AdminStatisticsPage> createState() => _AdminStatisticsPageState();
}

class _AdminStatisticsPageState extends State<AdminStatisticsPage> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await getIt<ApiClient>()
          .get<Map<String, dynamic>>(ApiConstants.adminStatistics);
      if (mounted) setState(() { _data = result; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = 'تعذر تحميل الإحصائيات'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الإحصائيات والتقارير'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _load,
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _Section(
                          title: 'المستخدمون',
                          icon: Icons.people_rounded,
                          color: const Color(0xFF2563EB),
                          items: [
                            _StatItem('إجمالي العملاء', _val('totalClients'), Icons.person_rounded, const Color(0xFF2563EB)),
                            _StatItem('الموردون', _val('totalSuppliers'), Icons.inventory_2_rounded, const Color(0xFF0E9F6E)),
                            _StatItem('المهندسون', _val('totalEngineers'), Icons.engineering_rounded, const Color(0xFF7C3AED)),
                            _StatItem('في انتظار التحقق', _val('pendingVerification'), Icons.hourglass_top_rounded, const Color(0xFFF59E0B)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _Section(
                          title: 'الطلبيات',
                          icon: Icons.assignment_rounded,
                          color: const Color(0xFF0EA5E9),
                          items: [
                            _StatItem('إجمالي الطلبات', _val('totalRequests'), Icons.list_alt_rounded, const Color(0xFF0EA5E9)),
                            _StatItem('مفتوحة', _val('openRequests'), Icons.radio_button_unchecked_rounded, const Color(0xFF16A34A)),
                            _StatItem('مكتملة', _val('completedRequests'), Icons.check_circle_rounded, const Color(0xFF7C3AED)),
                            _StatItem('ملغاة', _val('cancelledRequests'), Icons.cancel_rounded, Colors.red),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _Section(
                          title: 'عروض الأسعار',
                          icon: Icons.local_offer_rounded,
                          color: const Color(0xFF7C3AED),
                          items: [
                            _StatItem('إجمالي العروض', _val('totalQuotations'), Icons.receipt_long_rounded, const Color(0xFF7C3AED)),
                            _StatItem('مقبولة', _val('acceptedQuotations'), Icons.thumb_up_rounded, const Color(0xFF16A34A)),
                            _StatItem('مرفوضة', _val('rejectedQuotations'), Icons.thumb_down_rounded, Colors.red),
                            _StatItem('ملغاة', _val('cancelledQuotations'), Icons.cancel_rounded, Colors.orange),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _Section(
                          title: 'التفاعل',
                          icon: Icons.chat_bubble_rounded,
                          color: const Color(0xFFF59E0B),
                          items: [
                            _StatItem('التعليقات', _val('totalComments'), Icons.comment_rounded, const Color(0xFFF59E0B)),
                            _StatItem('التقييمات', _val('totalRatings'), Icons.star_rounded, Colors.amber),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
      ),
    );
  }

  int _val(String key) => (_data?[key] as num?)?.toInt() ?? 0;
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<_StatItem> items;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900)),
            ]),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.2,
              children: items,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem(this.label, this.value, this.icon, this.color);

  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: .2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
