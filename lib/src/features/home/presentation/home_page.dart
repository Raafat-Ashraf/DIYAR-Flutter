import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../account/domain/entities/account_profile.dart';
import '../../account/presentation/cubit/account_cubit.dart';
import '../../account/presentation/widgets/custom_bottom_nav_bar.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authUser = context.select((AuthBloc bloc) => bloc.state.user);
    final profile = context.select((AccountCubit cubit) => cubit.state.profile);
    final providerType = profile?.providerType;
    final title = _titleFor(providerType);
    final description = _descriptionFor(providerType);
    final name = profile?.displayName.isNotEmpty == true
        ? profile!.displayName
        : authUser?.displayName.isNotEmpty == true
        ? authUser!.displayName
        : authUser?.email ?? '';

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
            Text(
              'أهلًا $name',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(description, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 24),
            if (profile != null)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatusChip(label: providerType?.arabicName ?? 'بدون دور'),
                  _StatusChip(label: profile.verificationStatus.arabicName),
                  if (profile.governorate != null)
                    _StatusChip(label: profile.governorate!.name),
                ],
              ),
            if (providerType == ProviderType.admin) ...[
              const SizedBox(height: 24),
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
                      Icons.fact_check_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: const Text(
                    'طلبات التحقق',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: const Text('مراجعة حسابات الموردين والمهندسين'),
                  trailing: const Icon(Icons.chevron_left_rounded),
                  onTap: () =>
                      context.push(AppRoutes.adminPendingVerification),
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selected: BottomNavDestination.home,
        profileImageUrl: profile?.imageUrl,
      ),
    );
  }

  static String _titleFor(ProviderType? providerType) {
    return switch (providerType) {
      ProviderType.client => 'الرئيسية الخاصة بالعميل',
      ProviderType.supplier => 'الرئيسية الخاصة بالمورد',
      ProviderType.freelancer => 'الرئيسية الخاصة بالمستقل',
      ProviderType.admin => 'لوحة تحكم المسؤول',
      null => 'الرئيسية',
    };
  }

  static String _descriptionFor(ProviderType? providerType) {
    return switch (providerType) {
      ProviderType.client => 'يمكنك هنا متابعة طلباتك وخدماتك القادمة.',
      ProviderType.supplier => 'يمكنك هنا إدارة عروضك وطلبات التوريد.',
      ProviderType.freelancer =>
        'يمكنك هنا متابعة فرص العمل والخدمات المناسبة لك.',
      ProviderType.admin => 'يمكنك هنا متابعة مؤشرات المنصة وإدارة العمليات.',
      null => 'اكتملت بيانات الحساب ويمكن إضافة وحدات السوق هنا.',
    };
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label),
    );
  }
}
