import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/di/service_locator.dart';
import '../../../account/domain/entities/account_profile.dart';
import '../../domain/usecases/get_showcases_use_case.dart';
import '../cubit/showcases_cubit.dart';
import '../pages/my_showcases_page.dart';
import 'showcase_card.dart';

class MyShowcasesHomeSection extends StatelessWidget {
  const MyShowcasesHomeSection({super.key, required this.profile});

  final AccountProfile profile;

  @override
  Widget build(BuildContext context) {
    if (profile.providerType != ProviderType.freelancer) {
      return const SizedBox.shrink();
    }

    return BlocProvider(
      create: (_) => ShowcasesCubit(
        getShowcases: getIt<GetShowcasesUseCase>(),
        userId: profile.id,
        pageSize: 2,
      )..load(),
      child: _MyShowcasesPreview(title: 'مشاريعي', userId: profile.id),
    );
  }
}

class _MyShowcasesPreview extends StatelessWidget {
  const _MyShowcasesPreview({required this.title, required this.userId});

  final String title;
  final String userId;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocBuilder<ShowcasesCubit, ShowcasesState>(
      builder: (context, state) {
        return _SectionCard(
          title: title,
          onSeeAll: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => MyShowcasesPage(title: title, userId: userId),
            ),
          ),
          child: state.isLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              : state.errorMessage != null
                  ? _RetryWidget(onRetry: () => context.read<ShowcasesCubit>().load())
                  : state.items.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              'لا توجد مشاريع حالياً',
                              style: TextStyle(color: scheme.onSurfaceVariant),
                            ),
                          ),
                        )
                      : Column(
                          children: state.items
                              .map((showcase) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: ShowcaseCard(
                                      showcase: showcase,
                                      onTap: () => context.push(
                                        AppRoutes.showcaseDetails,
                                        extra: showcase,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.onSeeAll});

  final String title;
  final Widget child;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: .05),
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
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
              if (onSeeAll != null)
                TextButton(onPressed: onSeeAll, child: const Text('عرض الكل')),
            ],
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}

class _RetryWidget extends StatelessWidget {
  const _RetryWidget({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('حاول مرة أخرى'),
        ),
      ),
    );
  }
}
