import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_client.dart';
import '../../../requests/domain/entities/request.dart';
import '../../../requests/presentation/cubit/requests_cubit.dart';
import '../../presentation/widgets/empty_state_widget.dart';
import '../../presentation/widgets/loading_state_widget.dart';

class AdminRequestsPage extends StatelessWidget {
  const AdminRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: BlocProvider(
        create: (_) => getIt<RequestsCubit>()..load(),
        child: const _AdminRequestsView(),
      ),
    );
  }
}

class _AdminRequestsView extends StatefulWidget {
  const _AdminRequestsView();

  @override
  State<_AdminRequestsView> createState() => _AdminRequestsViewState();
}

class _AdminRequestsViewState extends State<_AdminRequestsView> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      context.read<RequestsCubit>().loadMore();
    }
  }

  Future<void> _confirmCancel(BuildContext ctx, Request request) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (d) => AlertDialog(
        title: const Text('إلغاء الطلبية'),
        content: Text('هل تريد إلغاء الطلب #${request.id}؟ سيتم إشعار العميل.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('تراجع')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(d, true),
            child: const Text('إلغاء الطلب'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await getIt<ApiClient>().put<dynamic>(
        '${ApiConstants.adminCancelRequest}/${request.id}',
        data: {},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إلغاء الطلب'), backgroundColor: Colors.orange),
        );
        context.read<RequestsCubit>().load();
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext ctx, Request request) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (d) => AlertDialog(
        title: const Text('حذف الطلبية'),
        content: Text('هل تريد حذف الطلب #${request.id}؟ سيتم إشعار العميل ولن يظهر الطلب بعد ذلك.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('تراجع')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(d, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await getIt<ApiClient>().delete<dynamic>(
        '${ApiConstants.adminDeleteRequest}/${request.id}',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف الطلب'), backgroundColor: Colors.red),
        );
        context.read<RequestsCubit>().load();
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة الطلبيات')),
      body: BlocBuilder<RequestsCubit, RequestsState>(
        builder: (context, state) {
          if (state.isLoading && state.items.isEmpty) {
            return const LoadingStateWidget();
          }
          if (state.items.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.assignment_outlined,
              title: 'لا توجد طلبات',
            );
          }
          return RefreshIndicator(
            onRefresh: () => context.read<RequestsCubit>().load(),
            child: ListView.separated(
              controller: _scrollCtrl,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: state.items.length + (state.hasMore ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                if (i >= state.items.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final req = state.items[i];
                return _AdminRequestCard(
                  request: req,
                  onTap: () => context.push(
                    '${AppRoutes.requestById}?id=${req.id}',
                  ),
                  onCancel: req.status == RequestStatus.cancelled
                      ? null
                      : () => _confirmCancel(context, req),
                  onDelete: () => _confirmDelete(context, req),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _AdminRequestCard extends StatelessWidget {
  const _AdminRequestCard({
    required this.request,
    required this.onTap,
    this.onCancel,
    required this.onDelete,
  });

  final Request request;
  final VoidCallback onTap;
  final VoidCallback? onCancel;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      request.specialization?.name ?? 'طلب #${request.id}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ),
                  if (request.status != null)
                    _StatusChip(status: request.status!),
                ],
              ),
              if (request.client != null) ...[
                const SizedBox(height: 4),
                Text(
                  'العميل: ${request.client!.displayName}',
                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                ),
              ],
              if (request.city != null) ...[
                const SizedBox(height: 2),
                Text(
                  'المدينة: ${request.city!.name}',
                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (onCancel != null)
                    TextButton.icon(
                      onPressed: onCancel,
                      icon: const Icon(Icons.cancel_outlined, size: 16),
                      label: const Text('إلغاء', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded, size: 16),
                    label: const Text('حذف', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: scheme.error,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final RequestStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      RequestStatus.open => (const Color(0xFF16A34A), 'مفتوح'),
      RequestStatus.completed => (const Color(0xFF7C3AED), 'مكتمل'),
      RequestStatus.cancelled => (Colors.red, 'ملغى'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: .4)),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
    );
  }
}
