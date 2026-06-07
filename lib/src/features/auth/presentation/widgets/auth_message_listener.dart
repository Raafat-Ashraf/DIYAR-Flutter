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
}
