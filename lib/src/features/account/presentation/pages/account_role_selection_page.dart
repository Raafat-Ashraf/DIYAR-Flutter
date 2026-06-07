import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../domain/entities/account_profile.dart';

class AccountRoleSelectionPage extends StatelessWidget {
  const AccountRoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final roles = [
      _RoleItem(
        type: ProviderType.client,
        icon: Icons.person_outline,
        subtitle: 'اطلب الخدمات وتابع طلباتك بسهولة.',
      ),
      _RoleItem(
        type: ProviderType.supplier,
        icon: Icons.storefront_outlined,
        subtitle: 'أرسل بيانات شركتك ومستندات الاعتماد.',
      ),
      _RoleItem(
        type: ProviderType.freelancer,
        icon: Icons.engineering_outlined,
        subtitle: 'وثق خبرتك ومستنداتك المهنية.',
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('اختر نوع الحساب')),
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: roles.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final role = roles[index];
          return InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => context.go(
              '${AppRoutes.verifyAccount}?type=${role.type.apiValue}',
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Row(
                children: [
                  Icon(role.icon, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          role.type.arabicName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(role.subtitle),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RoleItem {
  const _RoleItem({
    required this.type,
    required this.icon,
    required this.subtitle,
  });

  final ProviderType type;
  final IconData icon;
  final String subtitle;
}
