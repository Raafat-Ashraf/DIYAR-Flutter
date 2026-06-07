import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../domain/entities/saved_account.dart';
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
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(const AuthSavedAccountsRequested());
  }

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
                  if (state.savedAccounts.isNotEmpty) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'حساباتك',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (state.savedAccounts.length > 1)
                          TextButton(
                            onPressed: state.isLoading
                                ? null
                                : () => _showMoreAccounts(
                                      context,
                                      state.savedAccounts.skip(1).toList(),
                                    ),
                            child: const Text('المزيد'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _SavedAccountTile(
                      account: state.savedAccounts.first,
                      isLoading: state.isLoading,
                      onTap: () {
                        context.read<AuthBloc>().add(
                              AuthSavedAccountSelected(
                                state.savedAccounts.first,
                              ),
                            );
                      },
                    ),
                    if (state.savedAccounts.length > 1) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          'آخر حساب تم تسجيل الدخول به',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('أو'),
                        ),
                        Expanded(
                          child: Divider(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
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

  void _showMoreAccounts(
    BuildContext context,
    List<SavedAccount> accounts,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'كل الحسابات',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: accounts.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final account = accounts[index];
                      return _SavedAccountTile(
                        account: account,
                        isLoading: false,
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          context.read<AuthBloc>().add(
                                AuthSavedAccountSelected(account),
                              );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SavedAccountTile extends StatelessWidget {
  const _SavedAccountTile({
    required this.account,
    required this.isLoading,
    required this.onTap,
  });

  final SavedAccount account;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      leading: Icon(
        account.isGoogle ? Icons.g_mobiledata : Icons.account_circle_outlined,
      ),
      title: Text(account.displayName),
      subtitle: Text(account.isGoogle ? 'Google • ${account.email}' : account.email),
      trailing: const Icon(Icons.login),
      onTap: isLoading ? null : onTap,
    );
  }
}
