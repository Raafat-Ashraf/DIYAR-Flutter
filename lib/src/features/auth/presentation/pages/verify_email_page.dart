import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_message_listener.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/loading_button.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key, required this.email});

  final String email;

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final _otpController = TextEditingController();
  bool _shouldNavigateToLoginOnSuccess = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthMessageListener(
      onSuccess: (context, state) {
        if (_shouldNavigateToLoginOnSuccess) {
          _shouldNavigateToLoginOnSuccess = false;
          context.go(AppRoutes.login);
        }
      },
      child: AuthScaffold(
        title: 'تأكيد البريد الإلكتروني',
        subtitle: 'أدخل رمز التحقق المرسل إلى بريدك الإلكتروني.',
        child: Form(
          key: _formKey,
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              return Column(
                children: [
                  AuthTextField(
                    controller: _emailController,
                    label: 'البريد الإلكتروني',
                    keyboardType: TextInputType.emailAddress,
                    validator: _required,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _otpController,
                    label: 'رمز التحقق',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.pin_outlined,
                    validator: _required,
                  ),
                  const SizedBox(height: 24),
                  LoadingButton(
                    label: 'تأكيد البريد',
                    isLoading: state.isLoading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: state.isLoading
                        ? null
                        : () {
                            _shouldNavigateToLoginOnSuccess = false;
                            context.read<AuthBloc>().add(
                                  AuthResendConfirmationSubmitted(
                                    _emailController.text,
                                  ),
                                );
                          },
                    child: const Text('إعادة إرسال الرمز'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    _shouldNavigateToLoginOnSuccess = true;
    context.read<AuthBloc>().add(
          AuthConfirmEmailSubmitted(
            email: _emailController.text,
            otp: _otpController.text,
          ),
        );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'هذا الحقل مطلوب.';
    return null;
  }
}
