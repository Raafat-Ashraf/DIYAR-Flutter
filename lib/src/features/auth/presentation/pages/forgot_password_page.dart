import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_message_listener.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/loading_button.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthMessageListener(
      onSuccess: (context, state) {
        final email = Uri.encodeComponent(state.pendingEmail ?? _emailController.text);
        context.go('${AppRoutes.resetPassword}?email=$email');
      },
      child: AuthScaffold(
        title: 'استعادة كلمة المرور',
        subtitle: 'سنرسل رمز تحقق إلى بريدك الإلكتروني المؤكد.',
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
                    prefixIcon: Icons.mail_outline,
                    validator: _requiredEmail,
                  ),
                  const SizedBox(height: 24),
                  LoadingButton(
                    label: 'إرسال الرمز',
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
    context.read<AuthBloc>().add(AuthForgotPasswordSubmitted(_emailController.text));
  }

  String? _requiredEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'البريد الإلكتروني مطلوب.';
    }
    if (!value.contains('@')) return 'أدخل بريدًا إلكترونيًا صحيحًا.';
    return null;
  }
}
