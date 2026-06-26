import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_bloc.dart';

class AuthMessageListener extends StatelessWidget {
  const AuthMessageListener({
    super.key,
    required this.child,
    this.onSuccess,
  });

  final Widget child;
  final void Function(BuildContext context, AuthState state)? onSuccess;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage ||
          previous.successMessage != current.successMessage,
      listener: (context, state) {
        if (state.isBanned && state.errorMessage != null) {
          _showBanDialog(context, state.errorMessage!);
          return;
        }

        final message = state.errorMessage ?? state.successMessage;
        if (message == null || message.isEmpty) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message,
              textAlign: TextAlign.start,
              style: TextStyle(
                color: state.errorMessage == null
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onError,
                height: 1.35,
              ),
            ),
            duration: Duration(seconds: message.contains('\n') ? 7 : 4),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            backgroundColor: state.errorMessage == null
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.error,
          ),
        );

        if (state.successMessage != null) {
          onSuccess?.call(context, state);
        }
      },
      child: child,
    );
  }

  void _showBanDialog(BuildContext context, String message) {
    // Split message: first line is title, rest is reason
    final lines = message.split('\n');
    final title = lines.first;
    final reason = lines.length > 1 ? lines.sublist(1).join('\n') : null;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          icon: const Icon(Icons.block_rounded, color: Colors.red, size: 44),
          title: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
          ),
          content: reason != null
              ? Text(
                  reason,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, height: 1.6),
                )
              : const Text(
                  'تواصل مع الإدارة لمزيد من المعلومات.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('حسناً'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
