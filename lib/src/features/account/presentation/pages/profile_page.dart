import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../cubit/account_cubit.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/profile_widgets.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final accountState = context.watch<AccountCubit>().state;
    final profile = accountState.profile;
    final authUser = context.select((AuthBloc bloc) => bloc.state.user);
    final name = profile?.displayName.isNotEmpty == true
        ? profile!.displayName
        : authUser?.displayName.isNotEmpty == true
        ? authUser!.displayName
        : 'حسابي';
    final email = authUser?.email.trim();
    final bio = profile?.bio?.trim();
    final companyName = profile?.companyName?.trim();
    final yearsOfExperience = profile?.yearsOfExperience;
    final hasBio = bio != null && bio.isNotEmpty;
    final hasProfessionalInfo =
        (companyName != null && companyName.isNotEmpty) ||
        yearsOfExperience != null;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        body: accountState.isLoading && profile == null
            ? const ProfileSkeleton()
            : RefreshIndicator(
                onRefresh: () => context.read<AccountCubit>().loadProfile(),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverAppBar(
                      pinned: true,
                      elevation: 0,
                      surfaceTintColor: Colors.transparent,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerLowest,
                      title: const Text('الملف الشخصي'),
                      actions: [
                        IconButton(
                          tooltip: 'تحديث البيانات',
                          onPressed: () =>
                              context.read<AccountCubit>().loadProfile(),
                          icon: const Icon(Icons.refresh_rounded),
                        ),
                      ],
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 560),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (accountState.errorMessage != null) ...[
                                  _ProfileNotice(
                                    message: accountState.errorMessage!,
                                  ),
                                  const SizedBox(height: 14),
                                ],
                                ProfileHeader(
                                  profile: profile,
                                  displayName: name,
                                ),
                                if (hasBio) ...[
                                  const SizedBox(height: 14),
                                  ProfileInfoCard(
                                    title: 'نبذة مختصرة',
                                    icon: Icons.notes_rounded,
                                    children: [
                                      Text(
                                        bio,
                                        textAlign: TextAlign.start,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              height: 1.65,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (hasProfessionalInfo) ...[
                                  const SizedBox(height: 14),
                                  ProfileInfoCard(
                                    title: 'البيانات المهنية',
                                    icon: Icons.business_center_rounded,
                                    children: [
                                      if (companyName != null &&
                                          companyName.isNotEmpty) ...[
                                        ProfileStatTile(
                                          icon: Icons.apartment_rounded,
                                          label: 'الشركة',
                                          value: companyName,
                                        ),
                                      ],
                                      if (companyName != null &&
                                          companyName.isNotEmpty &&
                                          yearsOfExperience != null)
                                        const SizedBox(height: 10),
                                      if (yearsOfExperience != null)
                                        ProfileStatTile(
                                          icon: Icons.timeline_rounded,
                                          label: 'سنوات الخبرة',
                                          value: _experienceText(
                                            yearsOfExperience,
                                          ),
                                          color: const Color(0xFF0E9F6E),
                                        ),
                                    ],
                                  ),
                                ],
                                if (email != null && email.isNotEmpty) ...[
                                  const SizedBox(height: 14),
                                  ProfileInfoCard(
                                    title: 'التواصل',
                                    icon: Icons.alternate_email_rounded,
                                    children: [
                                      ProfileStatTile(
                                        icon: Icons.email_rounded,
                                        label: 'البريد الإلكتروني',
                                        value: email,
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 14),
                                ProfileInfoCard(
                                  title: 'إجراءات الحساب',
                                  icon: Icons.tune_rounded,
                                  children: [
                                    ProfileActionButton(
                                      icon: Icons.edit_rounded,
                                      label: 'تعديل الملف الشخصي',
                                      onPressed: () => _showComingSoon(
                                        context,
                                        'تعديل الملف الشخصي سيكون متاحًا قريبًا.',
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    ProfileActionButton(
                                      icon: Icons.lock_reset_rounded,
                                      label: 'تغيير كلمة المرور',
                                      onPressed: () => _showComingSoon(
                                        context,
                                        'تغيير كلمة المرور سيكون متاحًا قريبًا.',
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    ProfileActionButton(
                                      icon: Icons.logout_rounded,
                                      label: 'تسجيل الخروج',
                                      isDestructive: true,
                                      onPressed: () => context
                                          .read<AuthBloc>()
                                          .add(const AuthLogoutRequested()),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        bottomNavigationBar: CustomBottomNavBar(
          selected: BottomNavDestination.profile,
          profileImageUrl: profile?.imageUrl,
        ),
      ),
    );
  }

  static String _experienceText(int years) {
    if (years <= 0) return 'خبرة حديثة';
    if (years == 1) return 'سنة خبرة';
    if (years == 2) return 'سنتان خبرة';
    if (years <= 10) return '$years سنوات خبرة';
    return '$years سنة خبرة';
  }

  static void _showComingSoon(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ProfileNotice extends StatelessWidget {
  const _ProfileNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: .75),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.error.withValues(alpha: .16)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_rounded, color: scheme.onErrorContainer, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: scheme.onErrorContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
