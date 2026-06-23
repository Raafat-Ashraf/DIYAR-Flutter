import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../cubit/pending_verification_cubit.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/loading_state_widget.dart';
import '../widgets/pending_user_card.dart';
import '../widgets/reject_reason_dialog.dart';
import '../widgets/stats_card.dart';
import 'pending_user_details_page.dart';

class PendingVerificationScreen extends StatelessWidget {
  const PendingVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PendingVerificationCubit>()..loadPendingUsers(),
      child: const _PendingVerificationView(),
    );
  }
}

class _PendingVerificationView extends StatelessWidget {
  const _PendingVerificationView();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: scheme.surfaceContainerLowest,
        appBar: AppBar(
          title: const Text('طلبات التحقق'),
          surfaceTintColor: Colors.transparent,
        ),
        body: BlocConsumer<PendingVerificationCubit, PendingVerificationState>(
          listenWhen: (previous, current) =>
              previous.errorMessage != current.errorMessage ||
              previous.successMessage != current.successMessage,
          listener: (context, state) {
            final message = state.errorMessage ?? state.successMessage;
            if (message == null || message.isEmpty) return;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(message),
                  backgroundColor: state.errorMessage != null
                      ? scheme.error
                      : const Color(0xFF16A34A),
                ),
              );
          },
          builder: (context, state) {
            return RefreshIndicator(
              onRefresh: () =>
                  context.read<PendingVerificationCubit>().loadPendingUsers(),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 640),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'مراجعة حسابات الموردين والمهندسين',
                                style: TextStyle(
                                  color: scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              StatsCard(
                                label: 'عدد الحسابات المعلقة',
                                value: '${state.users.length}',
                                icon: Icons.hourglass_top_rounded,
                                color: const Color(0xFFF59E0B),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (state.isLoading)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: LoadingStateWidget(),
                    )
                  else if (state.status == PendingVerificationStatus.failure &&
                      state.users.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyStateWidget(
                        icon: Icons.error_outline_rounded,
                        title: state.errorMessage ?? 'حدث خطأ غير متوقع.',
                        subtitle: 'اسحب للأسفل لإعادة المحاولة.',
                      ),
                    )
                  else if (state.users.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyStateWidget(
                        icon: Icons.task_alt_rounded,
                        title: 'لا توجد طلبات تحقق حالياً',
                        subtitle: 'سيظهر هنا أي حساب جديد بانتظار المراجعة.',
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                      sliver: SliverList.separated(
                        itemCount: state.users.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final user = state.users[index];
                          return Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 640),
                              child: PendingUserCard(
                                user: user,
                                isProcessing: state.isProcessing(user.id),
                                onApprove: () => _confirmApprove(context, user.id),
                                onReject: () => _reject(context, user.id),
                                onViewDetails: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        PendingUserDetailsPage(user: user),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmApprove(BuildContext context, String userId) async {
    final cubit = context.read<PendingVerificationCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد القبول'),
        content: const Text('هل أنت متأكد من قبول هذا الحساب؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('قبول'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await cubit.approveUser(userId);
    }
  }

  Future<void> _reject(BuildContext context, String userId) async {
    final cubit = context.read<PendingVerificationCubit>();
    final reason = await RejectReasonDialog.show(context);
    if (reason == null || reason.trim().isEmpty) return;
    await cubit.rejectUser(userId, reason.trim());
  }
}
