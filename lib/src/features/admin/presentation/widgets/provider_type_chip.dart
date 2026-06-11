import 'package:flutter/material.dart';

import '../../../account/domain/entities/account_profile.dart';

class ProviderTypeChip extends StatelessWidget {
  const ProviderTypeChip({super.key, required this.type});

  final ProviderType? type;

  @override
  Widget build(BuildContext context) {
    final meta = _meta(type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: meta.color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: meta.color.withValues(alpha: .18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(meta.icon, size: 14, color: meta.color),
          const SizedBox(width: 6),
          Text(
            meta.label,
            style: TextStyle(
              color: meta.color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  static _ChipMeta _meta(ProviderType? type) {
    return switch (type) {
      ProviderType.client => const _ChipMeta(
        label: 'عميل',
        icon: Icons.person_rounded,
        color: Color(0xFF2563EB),
      ),
      ProviderType.supplier => const _ChipMeta(
        label: 'مورد',
        icon: Icons.inventory_2_rounded,
        color: Color(0xFF0E9F6E),
      ),
      ProviderType.freelancer => const _ChipMeta(
        label: 'مهندس',
        icon: Icons.engineering_rounded,
        color: Color(0xFF7C3AED),
      ),
      ProviderType.admin => const _ChipMeta(
        label: 'أدمن',
        icon: Icons.admin_panel_settings_rounded,
        color: Color(0xFF0F172A),
      ),
      null => const _ChipMeta(
        label: 'غير محدد',
        icon: Icons.help_outline_rounded,
        color: Color(0xFF64748B),
      ),
    };
  }
}

class _ChipMeta {
  const _ChipMeta({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}
