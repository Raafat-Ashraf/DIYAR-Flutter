import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_client.dart';
import '../../../account/domain/entities/account_profile.dart';
import '../../../showcases/domain/entities/showcase.dart';
import '../../../showcases/presentation/widgets/showcase_card.dart';
import '../cubit/account_cubit.dart';
import '../widgets/profile_avatar.dart';

class ProviderProfilePage extends StatefulWidget {
  const ProviderProfilePage({
    super.key,
    required this.userId,
    required this.displayName,
    this.imageUrl,
    this.providerType,
  });

  final String userId;
  final String displayName;
  final String? imageUrl;
  final ProviderType? providerType;

  @override
  State<ProviderProfilePage> createState() => _ProviderProfilePageState();
}

class _ProviderProfilePageState extends State<ProviderProfilePage> {
  Map<String, dynamic>? _ratings;
  List<Showcase> _showcases = [];
  bool _loadingRatings = true;
  bool _loadingShowcases = true;

  @override
  void initState() {
    super.initState();
    _loadRatings();
    _loadShowcases();
  }

  Future<void> _loadRatings() async {
    try {
      final r = await getIt<ApiClient>().get<Map<String, dynamic>>(
        ApiConstants.getUserRatings,
        queryParameters: {'userId': widget.userId},
      );
      if (mounted) setState(() { _ratings = r; _loadingRatings = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingRatings = false);
    }
  }

  Future<void> _loadShowcases() async {
    try {
      final r = await getIt<ApiClient>().get<Map<String, dynamic>>(
        ApiConstants.getAllShowcases,
        queryParameters: {'UserId': widget.userId, 'PageSize': 6, 'PageNumber': 1},
      );
      final items = (r['items'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(Showcase.fromJson)
          .toList();
      if (mounted) setState(() { _showcases = items; _loadingShowcases = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingShowcases = false);
    }
  }

  Future<void> _showRateDialog() async {
    int selected = (_ratings?['myRating'] as int?) ?? 0;
    final commentCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text('تقييم ${widget.displayName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => IconButton(
                  icon: Icon(i < selected ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: Colors.amber, size: 32),
                  onPressed: () => setS(() => selected = i + 1),
                )),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: commentCtrl,
                decoration: const InputDecoration(labelText: 'تعليق (اختياري)', border: OutlineInputBorder()),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
            FilledButton(
              onPressed: selected == 0 ? null : () => Navigator.pop(ctx, true),
              child: const Text('إرسال'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await getIt<ApiClient>().post<dynamic>(ApiConstants.rateUser, data: {
        'ratedUserId': widget.userId,
        'ratingValue': selected,
        'comment': commentCtrl.text.trim().isEmpty ? null : commentCtrl.text.trim(),
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال التقييم ✓')));
      _loadRatings();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ، حاول مرة أخرى')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final myId = getIt<AccountCubit>().state.profile?.id;
    final isMe = myId == widget.userId;
    final avg = (_ratings?['averageRating'] as num?)?.toDouble() ?? 0.0;
    final total = (_ratings?['totalRatings'] as int?) ?? 0;
    final myRating = _ratings?['myRating'] as int?;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: scheme.surfaceContainerLowest,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              title: Text(widget.displayName),
              actions: [
                if (!isMe)
                  TextButton.icon(
                    onPressed: _showRateDialog,
                    icon: Icon(myRating != null ? Icons.edit_rounded : Icons.star_outline_rounded, size: 18),
                    label: Text(myRating != null ? 'تعديل تقييمك' : 'قيّم'),
                  ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        ProfileAvatar(imageUrl: widget.imageUrl, size: 64),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.displayName,
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                              if (widget.providerType != null) ...[
                                const SizedBox(height: 4),
                                Text(widget.providerType!.arabicName,
                                    style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600)),
                              ],
                              if (total > 0) ...[
                                const SizedBox(height: 6),
                                Row(children: [
                                  const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                  const SizedBox(width: 4),
                                  Text('${avg.toStringAsFixed(1)} ($total تقييم)',
                                      style: const TextStyle(fontWeight: FontWeight.w700)),
                                ]),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Showcases section
                    if (_loadingShowcases)
                      const Center(child: CircularProgressIndicator())
                    else if (_showcases.isNotEmpty) ...[
                      Text('المشاريع',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 10),
                      ..._showcases.map((s) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: ShowcaseCard(
                              showcase: s,
                              onTap: () => context.push(AppRoutes.showcaseDetails, extra: s),
                            ),
                          )),
                      const SizedBox(height: 10),
                    ],

                    // Ratings section
                    if (!_loadingRatings && total > 0) ...[
                      Text('التقييمات',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 10),
                      ...(_ratings?['ratings'] as List? ?? []).take(5).map((r) {
                        final name = (r['reviewerName'] ?? '') as String;
                        final value = (r['ratingValue'] as int?) ?? 0;
                        final comment = r['comment'] as String?;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: scheme.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: scheme.outlineVariant),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                const Spacer(),
                                Row(children: List.generate(5, (i) => Icon(
                                  i < value ? Icons.star_rounded : Icons.star_outline_rounded,
                                  color: Colors.amber, size: 16,
                                ))),
                              ]),
                              if (comment != null && comment.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(comment, style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
                              ],
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
