import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../cubit/account_cubit.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class RejectedAccountPage extends StatelessWidget {
  const RejectedAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.select((AccountCubit cubit) => cubit.state.profile);
    final reason = profile?.rejectionReason;
    final type = profile?.providerType;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تم رفض التحقق'),
        actions: [
          IconButton(
            tooltip: 'تسجيل الخروج',
            onPressed: () =>
                context.read<AuthBloc>().add(const AuthLogoutRequested()),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 20),
            Text(
              'طلب التحقق مرفوض',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text(
              reason == null || reason.trim().isEmpty
                  ? 'لم يتم توضيح سبب الرفض.'
                  : reason,
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: type == null
                  ? null
                  : () => context.go(
                      '${AppRoutes.verifyAccount}?type=${type.apiValue}',
                    ),
              child: const Text('إعادة إرسال التحقق'),
            ),
          ],
        ),
      ),
    );
  }
}
