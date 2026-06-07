import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final roles = ['عميل', 'مورد / مقاول', 'مهندس حر'];

    return Scaffold(
      appBar: AppBar(title: const Text('اختر الدور')),
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: roles.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            leading: const Icon(Icons.badge_outlined),
            title: Text(roles[index]),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoutes.home),
          );
        },
      ),
    );
  }
}
