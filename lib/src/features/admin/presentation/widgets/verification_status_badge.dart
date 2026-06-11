import 'package:flutter/material.dart';

import '../../../account/domain/entities/account_profile.dart';

class VerificationStatusBadge extends StatelessWidget {
  const VerificationStatusBadge({super.key, required this.status});

  final VerificationStatus status;

  @override
  Widget build(BuildContext context) {
    final meta = _meta(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: meta.color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: meta.color.withValues(alpha: .25)),
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

  static _StatusMeta _meta(VerificationStatus status) {
    return switch (status) {
      VerificationStatus.approved => const _StatusMeta(
        label: 'مقبول',
        icon: Icons.check_circle_rounded,
        color: Color(0xFF16A34A),
      ),
      VerificationStatus.pending => const _StatusMeta(
        label: 'قيد المراجعة',
        icon: Icons.hourglass_top_rounded,
        color: Color(0xFFF59E0B),
      ),
      VerificationStatus.rejected => const _StatusMeta(
        label: 'مرفوض',
        icon: Icons.cancel_rounded,
        color: Color(0xFFDC2626),
      ),
      VerificationStatus.notSubmitted => const _StatusMeta(
        label: 'لم يتم الإرسال',
        icon: Icons.assignment_late_rounded,
        color: Color(0xFF94A3B8),
      ),
    };
  }
}

class _StatusMeta {
  const _StatusMeta({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}
