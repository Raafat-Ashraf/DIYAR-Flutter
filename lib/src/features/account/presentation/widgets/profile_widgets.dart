import 'package:flutter/material.dart';

import '../../domain/entities/account_profile.dart';
import 'profile_avatar.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.profile,
    required this.displayName,
  });

  final AccountProfile? profile;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final governorate = profile?.governorate?.name.trim();

    return FadeInProfileSection(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: .08),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                ProfileAvatar(
                  imageUrl: profile?.imageUrl,
                  size: 112,
                  isActive: true,
                ),
                PositionedDirectional(
                  end: 2,
                  bottom: 2,
                  child: VerificationIconBadge(
                    status: profile?.verificationStatus,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              displayName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                ProviderTypeChip(type: profile?.providerType),
                if (governorate != null && governorate.isNotEmpty)
                  ProfileMiniChip(
                    icon: Icons.location_on_rounded,
                    label: governorate,
                    color: colorScheme.primary,
                  ),
              ],
            ),
            const SizedBox(height: 14),
            VerificationBadge(status: profile?.verificationStatus),
          ],
        ),
      ),
    );
  }
}

class ProviderTypeChip extends StatelessWidget {
  const ProviderTypeChip({super.key, required this.type});

  final ProviderType? type;

  @override
  Widget build(BuildContext context) {
    final meta = _meta(context, type);
    return ProfileMiniChip(
      icon: meta.icon,
      label: meta.label,
      color: meta.color,
    );
  }

  static _ChipMeta _meta(BuildContext context, ProviderType? type) {
    final scheme = Theme.of(context).colorScheme;
    return switch (type) {
      ProviderType.client => _ChipMeta(
        label: 'عميل',
        icon: Icons.person_rounded,
        color: scheme.primary,
      ),
      ProviderType.supplier => _ChipMeta(
        label: 'مورد',
        icon: Icons.inventory_2_rounded,
        color: const Color(0xFF0E9F6E),
      ),
      ProviderType.freelancer => _ChipMeta(
        label: 'مهندس',
        icon: Icons.workspace_premium_rounded,
        color: const Color(0xFF7C3AED),
      ),
      ProviderType.admin => _ChipMeta(
        label: 'مسؤول',
        icon: Icons.admin_panel_settings_rounded,
        color: const Color(0xFF2563EB),
      ),
      null => _ChipMeta(
        label: 'حساب DIYAR',
        icon: Icons.account_circle_rounded,
        color: scheme.secondary,
      ),
    };
  }
}

class VerificationBadge extends StatelessWidget {
  const VerificationBadge({super.key, required this.status});

  final VerificationStatus? status;

  @override
  Widget build(BuildContext context) {
    final meta = _meta(status);
    final scheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: meta.color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: meta.color.withValues(alpha: .22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(meta.icon, size: 18, color: meta.color),
          const SizedBox(width: 7),
          Text(
            meta.label,
            style: TextStyle(
              color: scheme.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  static _StatusMeta _meta(VerificationStatus? status) {
    return switch (status) {
      VerificationStatus.approved => const _StatusMeta(
        label: 'حساب موثق',
        icon: Icons.verified_rounded,
        color: Color(0xFF16A34A),
      ),
      VerificationStatus.pending => const _StatusMeta(
        label: 'قيد المراجعة',
        icon: Icons.hourglass_top_rounded,
        color: Color(0xFFF59E0B),
      ),
      VerificationStatus.rejected => const _StatusMeta(
        label: 'يحتاج تحديث',
        icon: Icons.error_rounded,
        color: Color(0xFFDC2626),
      ),
      VerificationStatus.notSubmitted || null => const _StatusMeta(
        label: 'يحتاج تحقق',
        icon: Icons.assignment_turned_in_rounded,
        color: Color(0xFFF97316),
      ),
    };
  }
}

class VerificationIconBadge extends StatelessWidget {
  const VerificationIconBadge({super.key, required this.status});

  final VerificationStatus? status;

  @override
  Widget build(BuildContext context) {
    final meta = VerificationBadge._meta(status);
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .12),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(child: Icon(meta.icon, size: 22, color: meta.color)),
    );
  }
}

class ProfileMiniChip extends StatelessWidget {
  const ProfileMiniChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: .14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileInfoCard extends StatelessWidget {
  const ProfileInfoCard({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return FadeInProfileSection(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: scheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: .055),
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
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 20, color: scheme.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

class ProfileStatTile extends StatelessWidget {
  const ProfileStatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tone = color ?? scheme.primary;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: .55),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: .7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: .11),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: tone, size: 21),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileActionButton extends StatelessWidget {
  const ProfileActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tone = isDestructive ? scheme.error : scheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          decoration: BoxDecoration(
            color: isDestructive
                ? scheme.error.withValues(alpha: .08)
                : scheme.surfaceContainerHighest.withValues(alpha: .50),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDestructive
                  ? scheme.error.withValues(alpha: .18)
                  : scheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: tone, size: 22),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: tone,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
              Icon(Icons.chevron_left_rounded, color: tone, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class FadeInProfileSection extends StatelessWidget {
  const FadeInProfileSection({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            children: [
              _PulseBox(height: 254, color: scheme.surfaceContainerHighest),
              const SizedBox(height: 14),
              _PulseBox(height: 138, color: scheme.surfaceContainerHighest),
              const SizedBox(height: 14),
              _PulseBox(height: 170, color: scheme.surfaceContainerHighest),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulseBox extends StatelessWidget {
  const _PulseBox({required this.height, required this.color});

  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: .42, end: 1),
      duration: const Duration(milliseconds: 850),
      curve: Curves.easeInOut,
      builder: (context, value, _) => Opacity(
        opacity: value,
        child: Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
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
