import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_message_listener.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/loading_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthMessageListener(
      child: AuthScaffold(
        title: 'أهلًا بعودتك',
        subtitle: 'سجّل الدخول بحساب ديار للمتابعة.',
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
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _passwordController,
                    label: 'كلمة المرور',
                    obscureText: true,
                    prefixIcon: Icons.lock_outline,
                    validator: _required,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.go(AppRoutes.forgotPassword),
                      child: const Text('نسيت كلمة المرور؟'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  LoadingButton(
                    label: 'تسجيل الدخول',
                    isLoading: state.isLoading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: state.isLoading
                        ? null
                        : () => context
                            .read<AuthBloc>()
                            .add(const AuthGoogleLoginRequested()),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.g_mobiledata, size: 28),
                    label: const Text('المتابعة عبر Google'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.register),
                    child: const Text('إنشاء حساب جديد'),
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
          AuthLoginSubmitted(
            email: _emailController.text,
            password: _passwordController.text,
          ),
        );
  }

  String? _requiredEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'البريد الإلكتروني مطلوب.';
    }
    if (!value.contains('@')) return 'أدخل بريدًا إلكترونيًا صحيحًا.';
    return null;
  }

  String? _required(String? value) {
    if (value == null || value.isEmpty) return 'كلمة المرور مطلوبة.';
    return null;
  }

}
