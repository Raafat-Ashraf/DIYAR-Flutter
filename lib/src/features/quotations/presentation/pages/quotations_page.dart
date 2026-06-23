import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../account/domain/entities/account_profile.dart';
import '../../../account/presentation/cubit/account_cubit.dart';
import '../../../admin/presentation/widgets/empty_state_widget.dart';
import '../../../admin/presentation/widgets/loading_state_widget.dart';
import '../../domain/entities/quotation.dart';
import '../../domain/usecases/accept_quotation_use_case.dart';
import '../../domain/usecases/cancel_quotation_use_case.dart';
import '../../domain/usecases/get_quotations_use_case.dart';
import '../cubit/quotations_cubit.dart';
import '../cubit/quotations_state.dart';
import '../widgets/quotation_card.dart';

class QuotationsPage extends StatelessWidget {
  const QuotationsPage({super.key, required this.requestId});

  final int requestId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => QuotationsCubit(
        getQuotations: getIt<GetQuotationsUseCase>(),
        cancelQuotation: getIt<CancelQuotationUseCase>(),
        acceptQuotation: getIt<AcceptQuotationUseCase>(),
        requestId: requestId,
      )..load(),
      child: _QuotationsView(requestId: requestId),
    );
  }
}

class _QuotationsView extends StatefulWidget {
  const _QuotationsView({required this.requestId});
  final int requestId;

  @override
  State<_QuotationsView> createState() => _QuotationsViewState();
}

class _QuotationsViewState extends State<_QuotationsView> {
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
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      context.read<QuotationsCubit>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.select((AccountCubit c) => c.state.profile);
    final isClient = profile?.providerType == ProviderType.client;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('عروض الأسعار')),
      body: BlocConsumer<QuotationsCubit, QuotationsState>(
        listener: (context, state) {
          if (state.actionError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.actionError!), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () => context.read<QuotationsCubit>().load(),
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Search + Sort
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                textInputAction: TextInputAction.search,
                                onChanged: (v) =>
                                    context.read<QuotationsCubit>().search(v),
                                decoration: InputDecoration(
                                  hintText: 'ابحث في العروض...',
                                  prefixIcon: const Icon(Icons.search_rounded),
                                  suffixIcon: _searchController.text.isEmpty
                                      ? null
                                      : IconButton(
                                          icon: const Icon(Icons.close_rounded),
                                          onPressed: () {
                                            _searchController.clear();
                                            context.read<QuotationsCubit>().search('');
                                          },
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            PopupMenuButton<QuotationSortOption>(
                              initialValue: state.sort,
                              onSelected: (s) =>
                                  context.read<QuotationsCubit>().changeSort(s),
                              itemBuilder: (_) => QuotationSortOption.values
                                  .map((o) => PopupMenuItem(
                                        value: o,
                                        child: Text(o.label),
                                      ))
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
                        // Status filter chips
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _StatusChip(
                                label: 'الكل',
                                selected: state.filterStatus == null,
                                onTap: () => context
                                    .read<QuotationsCubit>()
                                    .changeStatus(null),
                              ),
                              const SizedBox(width: 6),
                              // Client sees Pending + Accepted only
                              // Provider sees all including Cancelled
                              for (final s in _visibleStatuses(isClient)) ...[
                                _StatusChip(
                                  label: s.arabicLabel,
                                  selected: state.filterStatus == s,
                                  onTap: () => context
                                      .read<QuotationsCubit>()
                                      .changeStatus(s),
                                ),
                                const SizedBox(width: 6),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Content
                if (state.isLoading && state.items.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: LoadingStateWidget(),
                  )
                else if (state.status == QuotationsStatus.failure && state.items.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyStateWidget(
                      icon: Icons.error_outline_rounded,
                      title: state.errorMessage ?? 'حدث خطأ',
                      subtitle: 'اسحب للأسفل لإعادة المحاولة.',
                    ),
                  )
                else if (state.items.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyStateWidget(
                      icon: Icons.local_offer_outlined,
                      title: 'لا توجد عروض أسعار',
                      subtitle: 'لم يتم تقديم أي عروض بعد.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    sliver: SliverList.separated(
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemCount: state.items.length + (state.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= state.items.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final q = state.items[index];
                        return QuotationCard(
                          quotation: q,
                          isClientView: isClient,
                          onAccept: isClient
                              ? () => _confirmAccept(context,
                                  requestId: widget.requestId,
                                  quotationId: q.id)
                              : null,
                          onCancel: !isClient
                              ? () => _confirmCancel(context, quotationId: q.id)
                              : null,
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<QuotationStatus> _visibleStatuses(bool isClient) {
    if (isClient) return [QuotationStatus.pending, QuotationStatus.accepted];
    return [QuotationStatus.pending, QuotationStatus.accepted, QuotationStatus.cancelled];
  }

  void _confirmAccept(BuildContext context,
      {required int requestId, required int quotationId}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد القبول'),
        content: const Text('هل أنت متأكد من قبول هذا العرض؟ لا يمكن التراجع.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<QuotationsCubit>().acceptQuotation(
                    requestId: requestId,
                    quotationId: quotationId,
                  );
            },
            child: const Text('قبول'),
          ),
        ],
      ),
    );
  }

  void _confirmCancel(BuildContext context, {required int quotationId}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إلغاء العرض'),
        content: const Text('هل تريد إلغاء هذا العرض؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('لا')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<QuotationsCubit>().cancelQuotation(quotationId);
            },
            child: const Text('إلغاء العرض'),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}
