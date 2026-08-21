import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/widgets/loading_button.dart';

/// Self-service account deletion — required by Google Play's account
/// deletion policy (in-app path for users who created an account).
class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final _passwordC = TextEditingController();
  bool _showPassword = false;
  bool _confirmed = false;
  bool _deleting = false;

  @override
  void dispose() {
    _passwordC.dispose();
    super.dispose();
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _delete() async {
    if (!_confirmed) {
      _snack('يرجى تأكيد أنك تفهم أن هذا الإجراء نهائي');
      return;
    }
    setState(() => _deleting = true);
    try {
      await getIt<ApiClient>().delete<dynamic>(
        ApiConstants.deleteAccount,
        data: {
          if (_passwordC.text.isNotEmpty) 'password': _passwordC.text,
        },
      );
      if (!mounted) return;
      context.read<AuthBloc>().add(const AuthLogoutRequested());
    } catch (_) {
      if (mounted) {
        _snack('تعذر حذف الحساب. تأكد من كلمة المرور وحاول مرة أخرى');
      }
    }
    if (mounted) setState(() => _deleting = false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('حذف الحساب')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.errorContainer.withValues(alpha: .6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scheme.error.withValues(alpha: .2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: scheme.error),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'حذف حسابك إجراء نهائي ولا يمكن التراجع عنه. سيتم:\n'
                        '• إخفاء بياناتك الشخصية ومسح مستنداتك الرسمية.\n'
                        '• إلغاء طلباتك المفتوحة أو عروض أسعارك المعلّقة.\n'
                        '• تسجيل خروجك فورًا من كل الأجهزة.\n\n'
                        'لن تتمكن من استرجاع الحساب بعد الحذف.',
                        style: TextStyle(
                          color: scheme.onErrorContainer,
                          fontWeight: FontWeight.w600,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordC,
                obscureText: !_showPassword,
                decoration: InputDecoration(
                  labelText: 'كلمة المرور (إن وجدت)',
                  helperText:
                      'إذا سجّلت الدخول بجوجل بدون كلمة مرور، اتركه فارغًا',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(_showPassword
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () =>
                        setState(() => _showPassword = !_showPassword),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              CheckboxListTile(
                value: _confirmed,
                onChanged: (v) => setState(() => _confirmed = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'أفهم أن حذف الحساب نهائي ولا يمكن التراجع عنه',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 20),
              LoadingButton(
                label: 'حذف الحساب نهائيًا',
                isLoading: _deleting,
                onPressed: _delete,
                backgroundColor: scheme.error,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
