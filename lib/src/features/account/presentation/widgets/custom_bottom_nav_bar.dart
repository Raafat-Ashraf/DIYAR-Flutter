import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/account_profile.dart';
import '../cubit/account_cubit.dart';
import 'profile_avatar.dart';

enum BottomNavDestination { home, notifications, add, trending, profile }

class CustomBottomNavBar extends StatelessWidget {
  const CustomBottomNavBar({
    super.key,
    required this.selected,
    required this.profileImageUrl,
    this.onShowcaseCreated,
    this.onRequestCreated,
  });

  final BottomNavDestination selected;
  final String? profileImageUrl;
  final VoidCallback? onShowcaseCreated;
  final VoidCallback? onRequestCreated;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final barHeight = 58.0 + bottomInset;

    return SizedBox(
      height: barHeight,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              height: barHeight,
              width: double.infinity,
              padding: EdgeInsets.only(bottom: bottomInset),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .96),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(22),
                ),
                border: Border.all(color: Colors.black.withValues(alpha: .06)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .14),
                    blurRadius: 16,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _iconSlot(
                    context,
                    destination: BottomNavDestination.home,
                    icon: Icons.home_filled,
                    onTap: () => _go(context, AppRoutes.home),
                  ),
                  _iconSlot(
                    context,
                    destination: BottomNavDestination.notifications,
                    icon: Icons.notifications_rounded,
                    onTap: () => _comingSoon(context),
                  ),
                  _addSlot(context),
                  _trendingSlot(context),
                  // Hamburger menu (replaces profile avatar)
                  Expanded(
                    child: Center(
                      child: _AnimatedNavButton(
                        isActive: false,
                        onTap: () => _openMenu(context),
                        child: Icon(
                          Icons.menu_rounded,
                          size: 26,
                          color: Colors.black.withValues(alpha: .64),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconSlot(
    BuildContext context, {
    required BottomNavDestination destination,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isActive = selected == destination;
    return Expanded(
      child: Center(
        child: _AnimatedNavButton(
          isActive: isActive,
          onTap: onTap,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Icon(
              icon,
              key: ValueKey(isActive),
              size: isActive ? 27 : 25,
              color: isActive
                  ? Colors.black
                  : Colors.black.withValues(alpha: .48),
            ),
          ),
        ),
      ),
    );
  }

  Widget _trendingSlot(BuildContext context) {
    final isActive = selected == BottomNavDestination.trending;
    return Expanded(
      child: Center(
        child: _AnimatedNavButton(
          isActive: isActive,
          onTap: () => context.push(AppRoutes.trending),
          child: _FireIcon(isActive: isActive),
        ),
      ),
    );
  }

  Widget _addSlot(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Center(
        child: _AnimatedNavButton(
          isActive: selected == BottomNavDestination.add,
          onTap: () => _onAddTap(context),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }

  void _go(BuildContext context, String route) {
    if (GoRouterState.of(context).uri.path == route) return;
    context.go(route);
  }

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('قريبًا')));
  }

  Future<void> _onAddTap(BuildContext context) async {
    final providerType =
        context.read<AccountCubit>().state.profile?.providerType;
    if (providerType == ProviderType.client) {
      final created = await context.push<bool>(AppRoutes.createRequest);
      if (created == true) onRequestCreated?.call();
      return;
    }
    if (providerType == ProviderType.freelancer ||
        providerType == ProviderType.supplier) {
      final created = await context.push<bool>(AppRoutes.createShowcase);
      if (created == true) onShowcaseCreated?.call();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('هذا الحساب غير مؤهل لإضافة محتوى.')),
    );
  }

  void _openMenu(BuildContext context) {
    final profile = context.read<AccountCubit>().state.profile;

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.paddingOf(ctx).bottom + 8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // ── Profile tile ──────────────────────────────
                ListTile(
                  leading: ProfileAvatar(
                    imageUrl: profile?.imageUrl,
                    size: 44,
                  ),
                  title: Text(
                    profile?.displayName ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  subtitle: Text(
                    profile?.providerType?.arabicName ?? '',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  trailing: const Icon(Icons.chevron_left_rounded),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push(AppRoutes.profile);
                  },
                ),

                Divider(height: 1, color: scheme.outlineVariant),

                // ── Browse showcases ──────────────────────────
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: scheme.primary.withValues(alpha: .12),
                    child: Icon(Icons.storefront_outlined,
                        color: scheme.primary),
                  ),
                  title: const Text('تصفح المشاريع الهندسية',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  trailing: const Icon(Icons.chevron_left_rounded),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push(AppRoutes.showcasesList);
                  },
                ),

                Divider(height: 1, color: scheme.outlineVariant),

                // ── Logout ────────────────────────────────────
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: scheme.error.withValues(alpha: .1),
                    child: Icon(Icons.logout_rounded, color: scheme.error),
                  ),
                  title: Text('تسجيل الخروج',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, color: scheme.error)),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.read<AuthBloc>().add(const AuthLogoutRequested());
                  },
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Animated nav button ───────────────────────────────────────────────────────

class _AnimatedNavButton extends StatefulWidget {
  const _AnimatedNavButton({
    required this.isActive,
    required this.onTap,
    required this.child,
  });

  final bool isActive;
  final VoidCallback onTap;
  final Widget child;

  @override
  State<_AnimatedNavButton> createState() => _AnimatedNavButtonState();
}

class _AnimatedNavButtonState extends State<_AnimatedNavButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        scale: _pressed
            ? .9
            : widget.isActive
            ? 1.06
            : 1,
        child: SizedBox.square(
          dimension: 44,
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}

// ── Fire icon ─────────────────────────────────────────────────────────────────

class _FireIcon extends StatefulWidget {
  const _FireIcon({required this.isActive});
  final bool isActive;

  @override
  State<_FireIcon> createState() => _FireIconState();
}

class _FireIconState extends State<_FireIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseSize = widget.isActive ? 28.0 : 25.0;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final flicker = Curves.easeInOut.transform(_controller.value);
        final scale = 1 + flicker * .12;
        final tilt = (flicker - .5) * .12;
        final glowAlpha =
            (widget.isActive ? .35 : .18) + flicker * .25;

        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6A00).withValues(alpha: glowAlpha),
                blurRadius: 10 + flicker * 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Transform.rotate(
            angle: tilt,
            child: Transform.scale(
              scale: scale,
              child: ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    Color.lerp(
                        const Color(0xFFFFE08A),
                        const Color(0xFFFFC371),
                        flicker)!,
                    Color.lerp(
                        const Color(0xFFFF512F),
                        const Color(0xFFFF2D00),
                        flicker)!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: Icon(
                  Icons.whatshot_rounded,
                  size: baseSize,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
