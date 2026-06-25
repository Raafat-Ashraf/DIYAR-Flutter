import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_client.dart';
import '../../../account/domain/entities/account_profile.dart';
import 'edit_cities_page.dart';
import 'edit_specializations_page.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../cubit/account_cubit.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/profile_widgets.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final accountState = context.watch<AccountCubit>().state;
    final profile = accountState.profile;
    final authUser = context.select((AuthBloc bloc) => bloc.state.user);
    final name = profile?.displayName.isNotEmpty == true
        ? profile!.displayName
        : authUser?.displayName.isNotEmpty == true
        ? authUser!.displayName
        : 'حسابي';
    final email = authUser?.email.trim();
    final bio = profile?.bio?.trim();
    final companyName = profile?.companyName?.trim();
    final yearsOfExperience = profile?.yearsOfExperience;
    final hasBio = bio != null && bio.isNotEmpty;
    final hasProfessionalInfo =
        (companyName != null && companyName.isNotEmpty) ||
        yearsOfExperience != null;
    final isProvider = profile?.providerType == ProviderType.supplier ||
        profile?.providerType == ProviderType.freelancer;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        body: accountState.isLoading && profile == null
            ? const ProfileSkeleton()
            : RefreshIndicator(
                onRefresh: () => context.read<AccountCubit>().loadProfile(),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverAppBar(
                      pinned: true,
                      elevation: 0,
                      surfaceTintColor: Colors.transparent,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerLowest,
                      title: const Text('الملف الشخصي'),
                      actions: [
                        IconButton(
                          tooltip: 'تحديث البيانات',
                          onPressed: () =>
                              context.read<AccountCubit>().loadProfile(),
                          icon: const Icon(Icons.refresh_rounded),
                        ),
                      ],
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 560),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (accountState.errorMessage != null) ...[
                                  _ProfileNotice(
                                    message: accountState.errorMessage!,
                                  ),
                                  const SizedBox(height: 14),
                                ],
                                ProfileHeader(
                                  profile: profile,
                                  displayName: name,
                                ),
                                if (hasBio) ...[
                                  const SizedBox(height: 14),
                                  ProfileInfoCard(
                                    title: 'نبذة مختصرة',
                                    icon: Icons.notes_rounded,
                                    children: [
                                      Text(
                                        bio,
                                        textAlign: TextAlign.start,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              height: 1.65,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (hasProfessionalInfo) ...[
                                  const SizedBox(height: 14),
                                  ProfileInfoCard(
                                    title: 'البيانات المهنية',
                                    icon: Icons.business_center_rounded,
                                    children: [
                                      if (companyName != null &&
                                          companyName.isNotEmpty) ...[
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
                                          value: _experienceText(
                                            yearsOfExperience,
                                          ),
                                          color: const Color(0xFF0E9F6E),
                                        ),
                                    ],
                                  ),
                                ],
                                // Work Cities — always show for provider
                                if (isProvider && profile != null) ...[
                                  const SizedBox(height: 14),
                                  _WorkCitiesCard(
                                    profile: profile,
                                    onEdit: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const EditCitiesPage(),
                                      ),
                                    ),
                                  ),
                                ],
                                // Specializations — always show for provider
                                if (isProvider && profile != null) ...[
                                  const SizedBox(height: 14),
                                  _SpecializationsCard(
                                    profile: profile,
                                    onEdit: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const EditSpecializationsPage(),
                                      ),
                                    ),
                                  ),
                                ],
                                // Ratings — for providers
                                if (isProvider && profile != null) ...[
                                  const SizedBox(height: 14),
                                  _RatingsCard(userId: profile.id),
                                ],
                                if (email != null && email.isNotEmpty) ...[
                                  const SizedBox(height: 14),
                                  ProfileInfoCard(
                                    title: 'التواصل',
                                    icon: Icons.alternate_email_rounded,
                                    children: [
                                      ProfileStatTile(
                                        icon: Icons.email_rounded,
                                        label: 'البريد الإلكتروني',
                                        value: email,
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 14),
                                ProfileInfoCard(
                                  title: 'إجراءات الحساب',
                                  icon: Icons.tune_rounded,
                                  children: [
                                    ProfileActionButton(
                                      icon: Icons.edit_rounded,
                                      label: 'تعديل الملف الشخصي',
                                      onPressed: () =>
                                          context.push(AppRoutes.editProfile),
                                    ),
                                    const SizedBox(height: 10),
                                    ProfileActionButton(
                                      icon: Icons.lock_reset_rounded,
                                      label: 'تغيير كلمة المرور',
                                      onPressed: () =>
                                          context.push(AppRoutes.changePassword),
                                    ),
                                    const SizedBox(height: 10),
                                    ProfileActionButton(
                                      icon: Icons.logout_rounded,
                                      label: 'تسجيل الخروج',
                                      isDestructive: true,
                                      onPressed: () => context
                                          .read<AuthBloc>()
                                          .add(const AuthLogoutRequested()),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        bottomNavigationBar: CustomBottomNavBar(
          selected: BottomNavDestination.profile,
          profileImageUrl: profile?.imageUrl,
        ),
      ),
    );
  }

  static String _experienceText(int years) {
    if (years <= 0) return 'خبرة حديثة';
    if (years == 1) return 'سنة خبرة';
    if (years == 2) return 'سنتان خبرة';
    if (years <= 10) return '$years سنوات خبرة';
    return '$years سنة خبرة';
  }

  static void _showComingSoon(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ProfileNotice extends StatelessWidget {
  const _ProfileNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: .75),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.error.withValues(alpha: .16)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_rounded, color: scheme.onErrorContainer, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: scheme.onErrorContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Work Cities Card ──────────────────────────────────────────────────────────

class _WorkCitiesCard extends StatelessWidget {
  const _WorkCitiesCard({required this.profile, this.onEdit});
  final AccountProfile profile;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: .04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(Icons.location_city_rounded,
                    size: 20, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('مدن العمل',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w900)),
                ),
                if (onEdit != null)
                  IconButton(
                    onPressed: onEdit,
                    icon: Icon(Icons.edit_rounded,
                        size: 18, color: scheme.primary),
                    tooltip: 'تعديل مدن العمل',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
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
                  leading:
                      Icon(Icons.location_on_rounded, color: scheme.primary),
                  title: Text(g.governorateName,
                      style:
                          const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${g.cities.length} مدينة',
                      style: TextStyle(
                          fontSize: 12, color: scheme.onSurfaceVariant)),
                  children: g.cities
                      .map((c) => ListTile(
                            leading: const Icon(Icons.circle, size: 8),
                            title: Text(c,
                                style: const TextStyle(fontSize: 14)),
                            dense: true,
                            contentPadding: const EdgeInsets.only(
                                right: 32, left: 16),
                          ))
                      .toList(),
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

// ── Specializations Card ──────────────────────────────────────────────────────

class _SpecializationsCard extends StatelessWidget {
  const _SpecializationsCard({required this.profile, this.onEdit});
  final AccountProfile profile;
  final VoidCallback? onEdit;

  // Recursive tile builder: if name is itself a parent → expandable, else flat
  Widget _buildTile(String name, Map<String, List<String>> map, ColorScheme scheme) {
    final children = map[name] ?? [];
    if (children.isEmpty) {
      return ListTile(
        leading: Icon(Icons.check_circle_outline_rounded,
            color: scheme.primary, size: 20),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
        dense: true,
      );
    }
    return ExpansionTile(
      leading: Icon(Icons.workspace_premium_rounded,
          color: scheme.primary, size: 20),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
      childrenPadding: const EdgeInsetsDirectional.only(start: 16),
      children: children
          .map((child) => _buildTile(child, map, scheme))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    final hasGroupedSpecs = profile.profileSpecializations.isNotEmpty;
    final hasSpecIds = profile.specializationIds.isNotEmpty;

    // Build map: parentName → children list (for recursive tree)
    final childrenMap = <String, List<String>>{
      for (final g in profile.profileSpecializations) g.parentName: g.children,
    };
    // Names that appear as a child inside another group — not top-level
    final nestedNames = profile.profileSpecializations
        .expand((g) => g.children)
        .toSet();
    // Top-level: parentName is not a child of any other group
    final topLevel = profile.profileSpecializations
        .where((g) => !nestedNames.contains(g.parentName))
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: .04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(Icons.workspace_premium_rounded,
                    size: 20, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('التخصصات',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w900)),
                ),
                if (onEdit != null)
                  IconButton(
                    onPressed: onEdit,
                    icon: Icon(Icons.edit_rounded,
                        size: 18, color: scheme.primary),
                    tooltip: 'تعديل التخصصات',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (hasGroupedSpecs)
            ...topLevel
                .map((g) => _buildTile(g.parentName, childrenMap, scheme))
                .toList()
          else if (hasSpecIds)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'لديك ${profile.specializationIds.length} تخصص — اضغط زر التعديل لعرضها',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('لم يتم تحديد التخصصات بعد',
                  style: TextStyle(color: scheme.onSurfaceVariant)),
            ),
        ],
      ),
    );
  }
}

// ── Ratings Card ──────────────────────────────────────────────────────────────

class _RatingsCard extends StatefulWidget {
  const _RatingsCard({required this.userId});
  final String userId;

  @override
  State<_RatingsCard> createState() => _RatingsCardState();
}

class _RatingsCardState extends State<_RatingsCard> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await getIt<ApiClient>().get<Map<String, dynamic>>(
        ApiConstants.getUserRatings,
        queryParameters: {'userId': widget.userId},
      );
      if (mounted) setState(() { _data = r; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showRateDialog(BuildContext context) async {
    int selected = (_data?['myRating'] as int?) ?? 0;
    final commentCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('تقييمك'),
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
      _load();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ، حاول مرة أخرى')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final avg = (_data?['averageRating'] as num?)?.toDouble() ?? 0.0;
    final total = (_data?['totalRatings'] as int?) ?? 0;
    final ratings = (_data?['ratings'] as List?) ?? [];
    final myId = getIt<AccountCubit>().state.profile?.id;
    final isMyProfile = myId == widget.userId;
    final myRating = _data?['myRating'] as int?;

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
            child: Row(
              children: [
                const Icon(Icons.star_rounded, size: 20, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('التقييمات',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                ),
                if (!isMyProfile)
                  TextButton.icon(
                    onPressed: () => _showRateDialog(context),
                    icon: Icon(myRating != null ? Icons.edit_rounded : Icons.star_outline_rounded, size: 16),
                    label: Text(myRating != null ? 'تعديل تقييمك' : 'قيّم'),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (_loading)
            const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()))
          else if (total == 0)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('لا توجد تقييمات بعد', style: TextStyle(color: scheme.onSurfaceVariant)),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Text(avg.toStringAsFixed(1), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: List.generate(5, (i) => Icon(
                        i < avg.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: Colors.amber, size: 18,
                      ))),
                      Text('$total تقييم', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ...ratings.take(3).map((r) {
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
