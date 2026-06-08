import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import 'profile_avatar.dart';

enum BottomNavDestination { home, profile }

class BottomNavItem {
  const BottomNavItem({
    required this.destination,
    required this.route,
    required this.icon,
  });

  final BottomNavDestination destination;
  final String route;
  final IconData icon;
}

class CustomBottomNavBar extends StatelessWidget {
  const CustomBottomNavBar({
    super.key,
    required this.selected,
    required this.profileImageUrl,
  });

  final BottomNavDestination selected;
  final String? profileImageUrl;

  static const _homeItem = BottomNavItem(
    destination: BottomNavDestination.home,
    route: AppRoutes.home,
    icon: Icons.home_filled,
  );

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
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: _AnimatedNavButton(
                      isActive: selected == BottomNavDestination.home,
                      onTap: () => _go(context, _homeItem.route),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        transitionBuilder: (child, animation) =>
                            ScaleTransition(scale: animation, child: child),
                        child: Icon(
                          _homeItem.icon,
                          key: ValueKey(selected == BottomNavDestination.home),
                          size: selected == BottomNavDestination.home ? 27 : 25,
                          color: selected == BottomNavDestination.home
                              ? Colors.black
                              : Colors.black.withValues(alpha: .48),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 16,
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
                ],
              ),
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
