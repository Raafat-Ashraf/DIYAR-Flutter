import 'package:flutter/material.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/account_profile.dart';
import '../cubit/account_cubit.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/profile_widgets.dart';

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
  AccountProfile? _profile;
  bool _loading = true;
  Map<String, dynamic>? _ratings;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final json = await getIt<ApiClient>()
          .get<Map<String, dynamic>>('${ApiConstants.getUserProfile}/${widget.userId}');
      final profile = AccountProfile.fromJson(json);
      if (mounted) setState(() { _profile = profile; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
    _loadRatings();
  }

  Future<void> _loadRatings() async {
    try {
      final r = await getIt<ApiClient>().get<Map<String, dynamic>>(
        ApiConstants.getUserRatings,
        queryParameters: {'userId': widget.userId},
      );
      if (mounted) setState(() => _ratings = r);
    } catch (_) {}
  }

  bool get _isMe => getIt<AccountCubit>().state.profile?.id == widget.userId;

  bool get _isProvider {
    final p = _profile?.providerType;
    return p == ProviderType.supplier || p == ProviderType.freelancer;
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
                decoration: const InputDecoration(
                    labelText: 'تعليق (اختياري)', border: OutlineInputBorder()),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إرسال التقييم ✓'), backgroundColor: Color(0xFF16A34A)));
        _loadRatings();
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('حدث خطأ، حاول مرة أخرى')));
    }
  }

  static String _experienceText(int years) {
    if (years <= 0) return 'خبرة حديثة';
    if (years == 1) return 'سنة خبرة';
    if (years == 2) return 'سنتان خبرة';
    if (years <= 10) return '$years سنوات خبرة';
    return '$years سنة خبرة';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final profile = _profile;
    final bio = profile?.bio?.trim();
    final companyName = profile?.companyName?.trim();
    final yearsOfExperience = profile?.yearsOfExperience;
    final hasBio = bio != null && bio.isNotEmpty;
    final hasProfessionalInfo =
        (companyName != null && companyName.isNotEmpty) || yearsOfExperience != null;
    final avg = (_ratings?['averageRating'] as num?)?.toDouble() ?? 0.0;
    final total = (_ratings?['totalRatings'] as int?) ?? 0;
    final myRating = _ratings?['myRating'] as int?;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: scheme.surfaceContainerLowest,
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    elevation: 0,
                    surfaceTintColor: Colors.transparent,
                    backgroundColor: scheme.surfaceContainerLowest,
                    title: Text(widget.displayName),
                    actions: [
                      if (!_isMe) ...[
                        // Rating button
                        IconButton(
                          tooltip: myRating != null ? 'تعديل تقييمك' : 'قيّم',
                          icon: Icon(myRating != null
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                              color: Colors.amber),
                          onPressed: _showRateDialog,
                        ),
                      ],
                    ],
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Rating summary under header (if any)
                              if (total > 0) ...[
                                Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ...List.generate(5, (i) => Icon(
                                        i < avg.round()
                                            ? Icons.star_rounded
                                            : Icons.star_outline_rounded,
                                        color: Colors.amber, size: 16,
                                      )),
                                      const SizedBox(width: 6),
                                      Text('${avg.toStringAsFixed(1)} ($total)',
                                          style: const TextStyle(fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                              ProfileHeader(
                                profile: profile,
                                displayName: widget.displayName,
                              ),
                              if (hasBio) ...[
                                const SizedBox(height: 14),
                                ProfileInfoCard(
                                  title: 'نبذة مختصرة',
                                  icon: Icons.notes_rounded,
                                  children: [
                                    Text(bio,
                                        textAlign: TextAlign.start,
                                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                            height: 1.65, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ],
                              if (hasProfessionalInfo) ...[
                                const SizedBox(height: 14),
                                ProfileInfoCard(
                                  title: 'البيانات المهنية',
                                  icon: Icons.business_center_rounded,
                                  children: [
                                    if (companyName != null && companyName.isNotEmpty) ...[
                                      ProfileStatTile(
                                        icon: Icons.apartment_rounded,
                                        label: 'الشركة',
                                        value: companyName,
                                      ),
                                    ],
                                    if (companyName != null &&
                                        companyName.isNotEmpty &&
                                        yearsOfExperience != null)
                                      const SizedBox(height: 10),
                                    if (yearsOfExperience != null)
                                      ProfileStatTile(
                                        icon: Icons.timeline_rounded,
                                        label: 'سنوات الخبرة',
                                        value: _experienceText(yearsOfExperience),
                                        color: const Color(0xFF0E9F6E),
                                      ),
                                  ],
                                ),
                              ],
                              // Work Cities
                              if (_isProvider && profile != null) ...[
                                const SizedBox(height: 14),
                                _ViewWorkCitiesCard(profile: profile),
                              ],
                              // Specializations
                              if (_isProvider && profile != null) ...[
                                const SizedBox(height: 14),
                                _ViewSpecializationsCard(profile: profile),
                              ],
                              // Ratings
                              if (_isProvider) ...[
                                const SizedBox(height: 14),
                                _ViewRatingsCard(
                                  ratings: _ratings,
                                  displayName: widget.displayName,
                                  onRate: _isMe ? null : _showRateDialog,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── View-only Work Cities ─────────────────────────────────────────────────────

class _ViewWorkCitiesCard extends StatelessWidget {
  const _ViewWorkCitiesCard({required this.profile});
  final AccountProfile profile;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [BoxShadow(color: scheme.shadow.withValues(alpha: .04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(children: [
              Icon(Icons.location_city_rounded, size: 20, color: scheme.primary),
              const SizedBox(width: 8),
              Text('مدن العمل',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            ]),
          ),
          const Divider(height: 1),
          if (profile.worksInAllEgypt)
            ListTile(
              leading: Icon(Icons.public_rounded, color: scheme.primary),
              title: const Text('يعمل في جميع محافظات مصر',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            )
          else if (profile.workCities.isNotEmpty)
            ...profile.workCities.map((g) => ExpansionTile(
                  leading: Icon(Icons.location_on_rounded, color: scheme.primary),
                  title: Text(g.governorateName, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${g.cities.length} مدينة',
                      style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                  children: g.cities.map((c) => ListTile(
                        leading: const Icon(Icons.circle, size: 8),
                        title: Text(c, style: const TextStyle(fontSize: 14)),
                        dense: true,
                        contentPadding: const EdgeInsets.only(right: 32, left: 16),
                      )).toList(),
                ))
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('لم يتم تحديد مدن العمل بعد',
                  style: TextStyle(color: scheme.onSurfaceVariant)),
            ),
        ],
      ),
    );
  }
}

// ── View-only Specializations ─────────────────────────────────────────────────

class _ViewSpecializationsCard extends StatelessWidget {
  const _ViewSpecializationsCard({required this.profile});
  final AccountProfile profile;

  Widget _buildTile(String name, Map<String, List<String>> map, ColorScheme scheme) {
    final children = map[name] ?? [];
    if (children.isEmpty) {
      return ListTile(
        leading: Icon(Icons.check_circle_outline_rounded, color: scheme.primary, size: 20),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
        dense: true,
      );
    }
    return ExpansionTile(
      leading: Icon(Icons.workspace_premium_rounded, color: scheme.primary, size: 20),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
      childrenPadding: const EdgeInsetsDirectional.only(start: 16),
      children: children.map((c) => _buildTile(c, map, scheme)).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final childrenMap = <String, List<String>>{
      for (final g in profile.profileSpecializations) g.parentName: g.children,
    };
    final nestedNames = profile.profileSpecializations.expand((g) => g.children).toSet();
    final topLevel = profile.profileSpecializations
        .where((g) => !nestedNames.contains(g.parentName))
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [BoxShadow(color: scheme.shadow.withValues(alpha: .04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(children: [
              Icon(Icons.workspace_premium_rounded, size: 20, color: scheme.primary),
              const SizedBox(width: 8),
              Text('التخصصات',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            ]),
          ),
          const Divider(height: 1),
          if (topLevel.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('لم يتم تحديد التخصصات بعد',
                  style: TextStyle(color: scheme.onSurfaceVariant)),
            )
          else
            ...topLevel.map((g) => _buildTile(g.parentName, childrenMap, scheme)).toList(),
        ],
      ),
    );
  }
}

// ── View-only Ratings ─────────────────────────────────────────────────────────

class _ViewRatingsCard extends StatelessWidget {
  const _ViewRatingsCard({
    required this.ratings,
    required this.displayName,
    this.onRate,
  });
  final Map<String, dynamic>? ratings;
  final String displayName;
  final VoidCallback? onRate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final avg = (ratings?['averageRating'] as num?)?.toDouble() ?? 0.0;
    final total = (ratings?['totalRatings'] as int?) ?? 0;
    final myRating = ratings?['myRating'] as int?;
    final list = (ratings?['ratings'] as List?) ?? [];

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [BoxShadow(color: scheme.shadow.withValues(alpha: .04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(children: [
              const Icon(Icons.star_rounded, size: 20, color: Colors.amber),
              const SizedBox(width: 8),
              Expanded(child: Text('التقييمات',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900))),
              if (onRate != null)
                TextButton.icon(
                  onPressed: onRate,
                  icon: Icon(myRating != null ? Icons.edit_rounded : Icons.star_outline_rounded, size: 16),
                  label: Text(myRating != null ? 'تعديل تقييمك' : 'قيّم'),
                ),
            ]),
          ),
          const Divider(height: 1),
          if (total == 0)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('لا توجد تقييمات بعد', style: TextStyle(color: scheme.onSurfaceVariant)),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(children: [
                Text(avg.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: List.generate(5, (i) => Icon(
                      i < avg.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: Colors.amber, size: 18,
                    ))),
                    Text('$total تقييم',
                        style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                  ],
                ),
              ]),
            ),
            const Divider(height: 1),
            ...list.take(5).map((r) {
              final name = (r['reviewerName'] ?? '') as String;
              final value = (r['ratingValue'] as int?) ?? 0;
              final comment = r['comment'] as String?;
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      const Spacer(),
                      Row(children: List.generate(5, (i) => Icon(
                        i < value ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: Colors.amber, size: 14,
                      ))),
                    ]),
                    if (comment != null && comment.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(comment, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                    ],
                    const Divider(height: 16),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
