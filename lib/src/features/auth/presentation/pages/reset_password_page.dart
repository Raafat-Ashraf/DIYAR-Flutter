import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_message_listener.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/loading_button.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key, required this.email});

  final String email;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthMessageListener(
      onSuccess: (context, _) => context.go(AppRoutes.login),
      child: AuthScaffold(
        title: 'تعيين كلمة مرور جديدة',
        subtitle: 'استخدم رمز التحقق من بريدك لإكمال العملية.',
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
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _passwordController,
                    label: 'كلمة المرور الجديدة',
                    obscureText: true,
                    prefixIcon: Icons.lock_outline,
                    validator: _password,
                  ),
                  const SizedBox(height: 24),
                  LoadingButton(
                    label: 'تغيير كلمة المرور',
                    isLoading: state.isLoading,
                    onPressed: _submit,
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
    context.read<AuthBloc>().add(
          AuthResetPasswordSubmitted(
            email: _emailController.text,
            otp: _otpController.text,
            newPassword: _passwordController.text,
          ),
        );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'هذا الحقل مطلوب.';
    return null;
  }

  String? _password(String? value) {
    if (value == null || value.length < 6) {
      return 'كلمة المرور يجب ألا تقل عن 6 أحرف.';
    }
    return null;
  }
}
