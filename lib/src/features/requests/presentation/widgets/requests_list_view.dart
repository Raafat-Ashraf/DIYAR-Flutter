import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../admin/presentation/widgets/empty_state_widget.dart';
import '../../../admin/presentation/widgets/loading_state_widget.dart';
import '../../../../app/router/app_routes.dart';
import '../../domain/entities/request.dart';
import '../cubit/requests_cubit.dart';
import 'request_card.dart';

class RequestsListView extends StatefulWidget {
  const RequestsListView({
    super.key,
    this.emptyTitle = 'لا توجد طلبات حالياً',
    this.emptySubtitle = 'سيظهر هنا أي طلب جديد من العملاء.',
    this.showTypeFilter = true,
    this.showStatusFilter = true,
  });

  final String emptyTitle;
  final String emptySubtitle;
  final bool showTypeFilter;
  final bool showStatusFilter;

  @override
  State<RequestsListView> createState() => _RequestsListViewState();
}

class _RequestsListViewState extends State<RequestsListView> {
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
      context.read<RequestsCubit>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocBuilder<RequestsCubit, RequestsState>(
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () => context.read<RequestsCubit>().load(),
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search + Sort in same row
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              textInputAction: TextInputAction.search,
                              onChanged: (v) =>
                                  context.read<RequestsCubit>().search(v),
                              decoration: InputDecoration(
                                hintText: 'ابحث عن طلب...',
                                prefixIcon: const Icon(Icons.search_rounded),
                                suffixIcon: _searchController.text.isEmpty
                                    ? null
                                    : IconButton(
                                        icon: const Icon(Icons.close_rounded),
                                        onPressed: () {
                                          _searchController.clear();
                                          context
                                              .read<RequestsCubit>()
                                              .search('');
                                        },
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Sort icon on the left (trailing in RTL)
                          PopupMenuButton<RequestSortOption>(
                            initialValue: state.sort,
                            onSelected: (sort) =>
                                context.read<RequestsCubit>().changeSort(sort),
                            itemBuilder: (context) => RequestSortOption.values
                                .map(
                                  (o) => PopupMenuItem(
                                    value: o,
                                    child: Text(o.label),
                                  ),
                                )
                                .toList(),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.sort_rounded),
                            ),
                          ),
                        ],
                      ),
                      // Filter chips row
                      if (widget.showTypeFilter || widget.showStatusFilter) ...[
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              if (widget.showTypeFilter) ...[
                                _FilterChip(
                                  label: 'الكل',
                                  selected: state.requestType == null,
                                  onSelected: () => context
                                      .read<RequestsCubit>()
                                      .changeRequestType(null),
                                ),
                                const SizedBox(width: 6),
                                _FilterChip(
                                  label: 'مادة',
                                  selected:
                                      state.requestType == RequestType.material,
                                  onSelected: () => context
                                      .read<RequestsCubit>()
                                      .changeRequestType(RequestType.material),
                                ),
                                const SizedBox(width: 6),
                                _FilterChip(
                                  label: 'خدمة',
                                  selected:
                                      state.requestType == RequestType.service,
                                  onSelected: () => context
                                      .read<RequestsCubit>()
                                      .changeRequestType(RequestType.service),
                                ),
                              ],
                              if (widget.showStatusFilter &&
                                  widget.showTypeFilter)
                                const SizedBox(width: 10),
                              if (widget.showStatusFilter)
                                _StatusDropdown(
                                  selected: state.requestStatus,
                                  onChanged: (s) => context
                                      .read<RequestsCubit>()
                                      .changeStatus(s),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (state.isLoading && state.items.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: LoadingStateWidget(),
                )
              else if (state.status == RequestsStatus.failure &&
                  state.items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyStateWidget(
                    icon: Icons.error_outline_rounded,
                    title: state.errorMessage ?? 'حدث خطأ.',
                    subtitle: 'اسحب للأسفل لإعادة المحاولة.',
                  ),
                )
              else if (state.items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyStateWidget(
                    icon: Icons.inbox_outlined,
                    title: widget.emptyTitle,
                    subtitle: widget.emptySubtitle,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  sliver: SliverList.separated(
                    itemCount:
                        state.items.length + (state.hasMore ? 1 : 0),
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      if (index >= state.items.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final req = state.items[index];
                      return RequestCard(
                        request: req,
                        onTap: () => context.push(
                          AppRoutes.requestDetails,
                          extra: req,
                        ),
                        onCommentTap: () => context.push(
                          AppRoutes.requestDetails,
                          extra: req,
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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

class _StatusDropdown extends StatelessWidget {
  const _StatusDropdown({required this.selected, required this.onChanged});

  final RequestStatus? selected;
  final ValueChanged<RequestStatus?> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return PopupMenuButton<RequestStatus?>(
      initialValue: selected,
      onSelected: onChanged,
      itemBuilder: (context) => [
        // onTap ensures null fires even if initialValue == null
        PopupMenuItem<RequestStatus?>(
          value: null,
          onTap: () => Future.microtask(() => onChanged(null)),
          child: const Text('كل الحالات'),
        ),
        ...RequestStatus.values.map(
          (s) => PopupMenuItem(value: s, child: Text(s.arabicLabel)),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected != null
              ? scheme.primary.withValues(alpha: .1)
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected != null
                ? scheme.primary
                : scheme.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selected?.arabicLabel ?? 'الحالة',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected != null
                    ? scheme.primary
                    : scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 18,
              color: selected != null
                  ? scheme.primary
                  : scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
