import 'package:flutter/material.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/widgets/loading_button.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _oldC = TextEditingController();
  final _newC = TextEditingController();
  final _confirmC = TextEditingController();
  bool _saving = false;
  bool _showOld = false;
  bool _showNew = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _oldC.dispose();
    _newC.dispose();
    _confirmC.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_oldC.text.isEmpty || _newC.text.isEmpty || _confirmC.text.isEmpty) {
      _snack('يرجى ملء جميع الحقول');
      return;
    }
    if (_newC.text != _confirmC.text) {
      _snack('كلمتا المرور الجديدتان غير متطابقتين');
      return;
    }
    if (_newC.text.length < 8) {
      _snack('كلمة المرور يجب أن تكون 8 أحرف على الأقل');
      return;
    }
    setState(() => _saving = true);
    try {
      await getIt<ApiClient>().put<dynamic>(
        ApiConstants.changePassword,
        data: {
          'currentPassword': _oldC.text,
          'newPassword': _newC.text,
        },
      );
      if (mounted) {
        _snack('تم تغيير كلمة المرور بنجاح ✓');
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) _snack('كلمة المرور الحالية غير صحيحة، حاول مرة أخرى');
    }
    if (mounted) setState(() => _saving = false);
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('تغيير كلمة المرور')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PasswordField(
                controller: _oldC,
                label: 'كلمة المرور الحالية',
                show: _showOld,
                onToggle: () => setState(() => _showOld = !_showOld),
                action: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              _PasswordField(
                controller: _newC,
                label: 'كلمة المرور الجديدة',
                show: _showNew,
                onToggle: () => setState(() => _showNew = !_showNew),
                action: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              _PasswordField(
                controller: _confirmC,
                label: 'تأكيد كلمة المرور الجديدة',
                show: _showConfirm,
                onToggle: () => setState(() => _showConfirm = !_showConfirm),
              ),
              const SizedBox(height: 28),
              LoadingButton(
                label: 'تغيير كلمة المرور',
                isLoading: _saving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.show,
    required this.onToggle,
    this.action,
  });
  final TextEditingController controller;
  final String label;
  final bool show;
  final VoidCallback onToggle;
  final TextInputAction? action;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: !show,
      textInputAction: action,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          icon: Icon(show ? Icons.visibility_off : Icons.visibility),
          onPressed: onToggle,
        ),
      ),
    );
  }
}
