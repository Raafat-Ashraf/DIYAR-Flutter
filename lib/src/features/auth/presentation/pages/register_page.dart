import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_message_listener.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/loading_button.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthMessageListener(
      onSuccess: (context, state) {
        final email = Uri.encodeComponent(state.pendingEmail ?? _emailController.text);
        context.go('${AppRoutes.verifyEmail}?email=$email');
      },
      child: AuthScaffold(
        title: 'إنشاء حساب',
        subtitle: 'أنشئ حسابك للانضمام إلى منصة ديار.',
        backRoute: AppRoutes.login,
        child: Form(
          key: _formKey,
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final scheme = Theme.of(context).colorScheme;
              return Column(
                children: [
                  // ── Google (fastest) ───────────────────────
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: scheme.primary.withValues(alpha: .4)),
                      color: scheme.primary.withValues(alpha: .06),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.bolt_rounded,
                                  size: 14, color: scheme.primary),
                              const SizedBox(width: 4),
                              Text(
                                'الأسرع — الدخول عبر Google',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: scheme.primary),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: state.isLoading
                              ? null
                              : () => context
                                  .read<AuthBloc>()
                                  .add(const AuthGoogleLoginRequested()),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(12)),
                              side: BorderSide.none,
                            ),
                            side: BorderSide.none,
                            backgroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.g_mobiledata, size: 28),
                          label: const Text(
                            'المتابعة عبر Google',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (Platform.isIOS) ...[
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: state.isLoading
                          ? null
                          : () => context
                              .read<AuthBloc>()
                              .add(const AuthAppleLoginRequested()),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.apple, size: 25),
                      label: const Text('المتابعة عبر Apple'),
                    ),
                  ],
                  const SizedBox(height: 20),
                  // ── Divider ────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Divider(color: scheme.outlineVariant),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('أو أنشئ حسابًا بالبريد الإلكتروني'),
                      ),
                      Expanded(
                        child: Divider(color: scheme.outlineVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: AuthTextField(
                          controller: _firstNameController,
                          label: 'الاسم الأول',
                          validator: _required,
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AuthTextField(
                          controller: _lastNameController,
                          label: 'اسم العائلة',
                          validator: _required,
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
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
                    controller: _phoneController,
                    label: 'رقم الهاتف',
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone_outlined,
                    validator: _required,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _passwordController,
                    label: 'كلمة المرور',
                    obscureText: true,
                    prefixIcon: Icons.lock_outline,
                    validator: _password,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _confirmPasswordController,
                    label: 'تأكيد كلمة المرور',
                    obscureText: true,
                    prefixIcon: Icons.lock_outline,
                    validator: _confirmPassword,
                  ),
                  const SizedBox(height: 24),
                  LoadingButton(
                    label: 'إنشاء الحساب',
                    isLoading: state.isLoading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.login),
                    child: const Text('لديك حساب بالفعل؟'),
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
          AuthRegisterSubmitted(
            firstName: _firstNameController.text,
            lastName: _lastNameController.text,
            email: _emailController.text,
            phoneNumber: _phoneController.text,
            password: _passwordController.text,
            confirmPassword: _confirmPasswordController.text,
          ),
        );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'هذا الحقل مطلوب.';
    return null;
  }

  String? _requiredEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'البريد الإلكتروني مطلوب.';
    }
    if (!value.contains('@')) return 'أدخل بريدًا إلكترونيًا صحيحًا.';
    return null;
  }

  String? _password(String? value) {
    if (value == null || value.length < 6) {
      return 'كلمة المرور يجب ألا تقل عن 6 أحرف.';
    }
    return null;
  }

  String? _confirmPassword(String? value) {
    if (value != _passwordController.text) return 'كلمتا المرور غير متطابقتين.';
    return null;
  }
}
