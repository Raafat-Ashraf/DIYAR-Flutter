import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/account_cubit.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class AccountErrorPage extends StatelessWidget {
  const AccountErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final message = context.select(
      (AccountCubit cubit) => cubit.state.errorMessage,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('بيانات الحساب')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 20),
            Text(
              message ?? 'تعذر تحميل بيانات الحساب.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.read<AccountCubit>().loadProfile(),
              child: const Text('إعادة المحاولة'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () =>
                  context.read<AuthBloc>().add(const AuthLogoutRequested()),
              child: const Text('تسجيل الخروج'),
            ),
          ],
        ),
      ),
    );
  }
}
