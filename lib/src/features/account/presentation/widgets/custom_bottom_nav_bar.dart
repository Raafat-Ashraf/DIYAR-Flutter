import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import 'profile_avatar.dart';

enum BottomNavDestination { home, notifications, add, trending, profile }

class CustomBottomNavBar extends StatelessWidget {
  const CustomBottomNavBar({
    super.key,
    required this.selected,
    required this.profileImageUrl,
  });

  final BottomNavDestination selected;
  final String? profileImageUrl;

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
                  _iconSlot(
                    context,
                    destination: BottomNavDestination.trending,
                    icon: Icons.whatshot_rounded,
                    onTap: () => _comingSoon(context),
                  ),
                  Expanded(
                    child: Center(
                      child: _AnimatedNavButton(
                        isActive: selected == BottomNavDestination.profile,
                        onTap: () => _go(context, AppRoutes.profile),
                        child: ProfileAvatar(
                          imageUrl: profileImageUrl,
                          size: 30,
                          isActive: selected == BottomNavDestination.profile,
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

  Widget _addSlot(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Center(
        child: _AnimatedNavButton(
          isActive: selected == BottomNavDestination.add,
          onTap: () => _comingSoon(context),
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('قريبًا')));
  }
}

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
