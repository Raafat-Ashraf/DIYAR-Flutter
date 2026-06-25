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
import '../../showcases/presentation/widgets/my_showcases_home_section.dart';
import '../../quotations/presentation/widgets/my_quotations_home_section.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _refreshToken = 0;

  void _refreshAll() {
    setState(() => _refreshToken++);
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
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<AccountCubit>().loadProfile();
          _refreshAll();
        },
        child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
                    const SizedBox(height: 12),
                    Card(
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: scheme.outlineVariant),
                      ),
                      child: ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        leading: CircleAvatar(
                          backgroundColor: scheme.primary.withValues(alpha: .12),
                          child: Icon(Icons.inbox_rounded, color: scheme.primary),
                        ),
                        title: const Text('إدارة الطلبيات', style: TextStyle(fontWeight: FontWeight.w800)),
                        subtitle: const Text('عرض وإدارة طلبيات العملاء'),
                        trailing: const Icon(Icons.chevron_left_rounded),
                        onTap: () => context.push(AppRoutes.adminRequests),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: scheme.outlineVariant),
                      ),
                      child: ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        leading: CircleAvatar(
                          backgroundColor: scheme.primary.withValues(alpha: .12),
                          child: Icon(Icons.manage_accounts_rounded, color: scheme.primary),
                        ),
                        title: const Text('إدارة المستخدمين', style: TextStyle(fontWeight: FontWeight.w800)),
                        subtitle: const Text('عرض وبحث في حسابات المستخدمين'),
                        trailing: const Icon(Icons.chevron_left_rounded),
                        onTap: () => context.push(AppRoutes.adminUsers),
                      ),
                    ),
                  ],
                ),
              ),
            if (providerType == ProviderType.admin) const SizedBox(height: 20),

            // ── Role-specific section ──────────────────────────
            if (providerType == ProviderType.client && profile != null)
              MyRequestsHomeSection(
                key: ValueKey(_refreshToken),
                clientId: profile.id,
              ),
            if ((providerType == ProviderType.supplier ||
                    providerType == ProviderType.freelancer) &&
                profile != null) ...[
              MyQuotationsHomeSection(key: ValueKey(_refreshToken)),
              const SizedBox(height: 8),
              MyShowcasesHomeSection(
                key: ValueKey('sc-$_refreshToken'),
                profile: profile,
              ),
            ],
            if (providerType != ProviderType.client &&
                providerType != ProviderType.supplier &&
                providerType != ProviderType.freelancer &&
                profile != null)
              MyShowcasesHomeSection(
                key: ValueKey(_refreshToken),
                profile: profile,
              ),

          ],
        ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selected: BottomNavDestination.home,
        profileImageUrl: profile?.imageUrl,
        onShowcaseCreated: _refreshAll,
      ),
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
