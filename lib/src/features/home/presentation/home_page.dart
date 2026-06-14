import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/di/service_locator.dart';
import '../../account/domain/entities/account_profile.dart';
import '../../account/presentation/cubit/account_cubit.dart';
import '../../account/presentation/widgets/custom_bottom_nav_bar.dart';
import '../../admin/presentation/cubit/pending_verification_cubit.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.select((AccountCubit cubit) => cubit.state.profile);
    final providerType = profile?.providerType;

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
          IconButton(
            tooltip: 'تسجيل الخروج',
            onPressed: () =>
                context.read<AuthBloc>().add(const AuthLogoutRequested()),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.outlineVariant,
                            ),
                          ),
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: .12),
                              child: Icon(
                                Icons.fact_check_rounded,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            title: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'طلبات التحقق',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(width: 8),
                                _PendingCountBadge(count: count),
                              ],
                            ),
                            subtitle: const Text('مراجعة حسابات الموردين والمهندسين'),
                            trailing: const Icon(Icons.chevron_left_rounded),
                            onTap: () =>
                                context.push(AppRoutes.adminPendingVerification),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Card(
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: .12),
                          child: Icon(
                            Icons.category_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        title: const Text(
                          'إدارة التخصصات',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: const Text('إضافة وتعديل وحذف التخصصات'),
                        trailing: const Icon(Icons.chevron_left_rounded),
                        onTap: () =>
                            context.push(AppRoutes.adminSpecializations),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selected: BottomNavDestination.home,
        profileImageUrl: profile?.imageUrl,
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
