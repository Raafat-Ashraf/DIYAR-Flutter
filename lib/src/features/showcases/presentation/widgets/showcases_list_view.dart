import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../admin/presentation/widgets/empty_state_widget.dart';
import '../../../admin/presentation/widgets/loading_state_widget.dart';
import '../../domain/entities/showcase.dart';
import '../cubit/showcases_cubit.dart';
import 'showcase_card.dart';

class ShowcasesListView extends StatefulWidget {
  const ShowcasesListView({
    super.key,
    this.emptyTitle = 'لا توجد عروض حالياً',
    this.emptySubtitle = 'سيظهر هنا أي عرض جديد من المهندسين والموردين.',
    this.showTypeFilter = true,
  });

  final String emptyTitle;
  final String emptySubtitle;
  final bool showTypeFilter;

  @override
  State<ShowcasesListView> createState() => _ShowcasesListViewState();
}

class _ShowcasesListViewState extends State<ShowcasesListView> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      context.read<ShowcasesCubit>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocBuilder<ShowcasesCubit, ShowcasesState>(
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () => context.read<ShowcasesCubit>().load(),
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        onChanged: (value) =>
                            context.read<ShowcasesCubit>().search(value),
                        decoration: InputDecoration(
                          hintText: 'ابحث عن عرض...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () {
                                    _searchController.clear();
                                    context.read<ShowcasesCubit>().search('');
                                  },
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (widget.showTypeFilter)
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _TypeFilterChip(
                                      label: 'الكل',
                                      selected: state.type == null,
                                      onSelected: () => context
                                          .read<ShowcasesCubit>()
                                          .changeType(null),
                                    ),
                                    const SizedBox(width: 8),
                                    _TypeFilterChip(
                                      label: 'مهندسون',
                                      selected:
                                          state.type == ShowcaseType.portfolio,
                                      onSelected: () => context
                                          .read<ShowcasesCubit>()
                                          .changeType(ShowcaseType.portfolio),
                                    ),
                                    const SizedBox(width: 8),
                                    _TypeFilterChip(
                                      label: 'موردون',
                                      selected:
                                          state.type == ShowcaseType.product,
                                      onSelected: () => context
                                          .read<ShowcasesCubit>()
                                          .changeType(ShowcaseType.product),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            const Spacer(),
                          const SizedBox(width: 8),
                          PopupMenuButton<ShowcaseSortOption>(
                            initialValue: state.sort,
                            onSelected: (sort) =>
                                context.read<ShowcasesCubit>().changeSort(sort),
                            itemBuilder: (context) => ShowcaseSortOption.values
                                .map(
                                  (option) => PopupMenuItem(
                                    value: option,
                                    child: Text(option.label),
                                  ),
                                )
                                .toList(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.sort_rounded),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (state.isLoading && state.items.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: LoadingStateWidget(),
                )
              else if (state.status == ShowcasesStatus.failure &&
                  state.items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyStateWidget(
                    icon: Icons.error_outline_rounded,
                    title: state.errorMessage ?? 'حدث خطأ غير متوقع.',
                    subtitle: 'اسحب للأسفل لإعادة المحاولة.',
                  ),
                )
              else if (state.items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyStateWidget(
                    icon: Icons.storefront_outlined,
                    title: widget.emptyTitle,
                    subtitle: widget.emptySubtitle,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  sliver: SliverList.separated(
                    itemCount: state.items.length + (state.hasMore ? 1 : 0),
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      if (index >= state.items.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final showcase = state.items[index];
                      return ShowcaseCard(
                        showcase: showcase,
                        onTap: () => context.push(
                          AppRoutes.showcaseDetails,
                          extra: showcase,
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TypeFilterChip extends StatelessWidget {
  const _TypeFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}
