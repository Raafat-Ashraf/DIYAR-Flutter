import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/di/service_locator.dart';
import '../../account/domain/entities/account_profile.dart';
import '../../account/presentation/cubit/account_cubit.dart';
import '../../account/presentation/widgets/custom_bottom_nav_bar.dart';
import '../../account/presentation/widgets/profile_avatar.dart';
import '../../admin/presentation/cubit/pending_verification_cubit.dart';
import '../../requests/presentation/widgets/my_requests_home_section.dart';
import '../../showcases/domain/usecases/get_showcases_use_case.dart';
import '../../showcases/presentation/cubit/showcases_cubit.dart';
import '../../showcases/presentation/widgets/my_showcases_home_section.dart';
import '../../showcases/presentation/widgets/showcase_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _showcasesRefreshToken = 0;

  void _refreshShowcases() {
    setState(() => _showcasesRefreshToken++);
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.select((AccountCubit cubit) => cubit.state.profile);
    final providerType = profile?.providerType;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'Dyiar-Logo.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            const Text('DIYAR'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'تحديث البيانات',
            onPressed: () => context.read<AccountCubit>().loadProfile(),
            icon: const Icon(Icons.refresh),
          ),
          // Profile icon in AppBar
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: GestureDetector(
              onTap: () => context.push(AppRoutes.profile),
              child: ProfileAvatar(
                imageUrl: profile?.imageUrl,
                size: 30,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Admin section ──────────────────────────────────
            if (providerType == ProviderType.admin)
              BlocProvider(
                create: (_) =>
                    getIt<PendingVerificationCubit>()..loadPendingUsersCount(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BlocBuilder<PendingVerificationCubit, PendingVerificationState>(
                      builder: (context, state) {
                        final count = state.pendingUsersCount ?? 0;
                        return Card(
                          margin: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: scheme.outlineVariant),
                          ),
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            leading: CircleAvatar(
                              backgroundColor:
                                  scheme.primary.withValues(alpha: .12),
                              child: Icon(Icons.fact_check_rounded,
                                  color: scheme.primary),
                            ),
                            title: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('طلبات التحقق',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w800)),
                                const SizedBox(width: 8),
                                _PendingCountBadge(count: count),
                              ],
                            ),
                            subtitle: const Text(
                                'مراجعة حسابات الموردين والمهندسين'),
                            trailing: const Icon(Icons.chevron_left_rounded),
                            onTap: () => context
                                .push(AppRoutes.adminPendingVerification),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Card(
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: scheme.outlineVariant),
                      ),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        leading: CircleAvatar(
                          backgroundColor:
                              scheme.primary.withValues(alpha: .12),
                          child: Icon(Icons.category_rounded,
                              color: scheme.primary),
                        ),
                        title: const Text('إدارة التخصصات',
                            style:
                                TextStyle(fontWeight: FontWeight.w800)),
                        subtitle: const Text('إضافة وتعديل وحذف التخصصات'),
                        trailing: const Icon(Icons.chevron_left_rounded),
                        onTap: () =>
                            context.push(AppRoutes.adminSpecializations),
                      ),
                    ),
                  ],
                ),
              ),
            if (providerType == ProviderType.admin) const SizedBox(height: 20),

            // ── Role-specific section ──────────────────────────
            if (providerType == ProviderType.client && profile != null)
              MyRequestsHomeSection(
                key: ValueKey(_showcasesRefreshToken),
                clientId: profile.id,
              ),
            if (providerType != ProviderType.client && profile != null)
              MyShowcasesHomeSection(
                key: ValueKey(_showcasesRefreshToken),
                profile: profile,
              ),

            // ── Showcases browse section (for all) ────────────
            if (providerType != ProviderType.admin) ...[
              const SizedBox(height: 20),
              BlocProvider(
                create: (_) => ShowcasesCubit(
                  getShowcases: getIt<GetShowcasesUseCase>(),
                  pageSize: 2,
                )..load(),
                child: _ShowcasesHomeSection(
                  onRefresh: _refreshShowcases,
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selected: BottomNavDestination.home,
        profileImageUrl: profile?.imageUrl,
        onShowcaseCreated: _refreshShowcases,
      ),
    );
  }
}

// ── Showcases browse section ──────────────────────────────────────────────────

class _ShowcasesHomeSection extends StatelessWidget {
  const _ShowcasesHomeSection({required this.onRefresh});
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocBuilder<ShowcasesCubit, ShowcasesState>(
      builder: (context, state) {
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
                  const Expanded(
                    child: Text(
                      'عروض المهندسين والموردين',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.showcasesList),
                    child: const Text('عرض الكل'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (state.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'لا توجد عروض حالياً',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ),
                )
              else
                Column(
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
            ],
          ),
        );
      },
    );
  }
}

class _PendingCountBadge extends StatelessWidget {
  const _PendingCountBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}
