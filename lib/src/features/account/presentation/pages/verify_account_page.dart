import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/platform/native_document_picker.dart';
import '../../../auth/presentation/widgets/auth_text_field.dart';
import '../../../auth/presentation/widgets/loading_button.dart';
import '../../domain/entities/account_profile.dart';
import '../cubit/account_cubit.dart';

class VerifyAccountPage extends StatefulWidget {
  const VerifyAccountPage({super.key, required this.providerType});

  final ProviderType providerType;

  @override
  State<VerifyAccountPage> createState() => _VerifyAccountPageState();
}

class _VerifyAccountPageState extends State<VerifyAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _bioController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _yearsController = TextEditingController();
  final _documents = <String, VerificationDocument>{};

  int? _governorateId;
  int _stepIndex = 0;

  bool get _needsDocuments => widget.providerType != ProviderType.client;
  int get _totalSteps => _needsDocuments ? 3 : 2;
  bool get _isLastStep => _stepIndex == _totalSteps - 1;

  @override
  void initState() {
    super.initState();
    context.read<AccountCubit>().loadGovernorates();
  }

  @override
  void dispose() {
    _bioController.dispose();
    _companyNameController.dispose();
    _yearsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AccountCubit, AccountState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage ||
          previous.successMessage != current.successMessage,
      listener: (context, state) {
        final message = state.errorMessage ?? state.successMessage;
        if (message == null || message.isEmpty) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      },
      child: Scaffold(
        appBar: AppBar(title: Text('تحقق ${widget.providerType.arabicName}')),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: BlocBuilder<AccountCubit, AccountState>(
                builder: (context, state) {
                  return Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        _StepHeader(
                          currentStep: _stepIndex + 1,
                          totalSteps: _totalSteps,
                          title: _stepTitle,
                        ),
                        const SizedBox(height: 20),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 160),
                          child: _currentStep(state),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            if (_stepIndex > 0) ...[
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: state.isSubmitting
                                      ? null
                                      : () => setState(() => _stepIndex -= 1),
                                  child: const Text('السابق'),
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              flex: 2,
                              child: _isLastStep
                                  ? LoadingButton(
                                      label: 'إرسال التحقق',
                                      isLoading: state.isSubmitting,
                                      onPressed: _submit,
                                    )
                                  : ElevatedButton(
                                      onPressed: state.isSubmitting
                                          ? null
                                          : _nextStep,
                                      child: const Text('التالي'),
                                    ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _stepTitle {
    if (_stepIndex == 0) return 'بيانات الحساب';
    if (_needsDocuments && _stepIndex == 1) return 'المستندات';
    return 'مراجعة وإرسال';
  }

  Widget _currentStep(AccountState state) {
    if (_stepIndex == 0) return _detailsStep(state);
    if (_needsDocuments && _stepIndex == 1) return _documentsStep();
    return _reviewStep();
  }

  Widget _detailsStep(AccountState state) {
    return Column(
      key: const ValueKey('details'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<int>(
          initialValue: _governorateId,
          items: state.governorates
              .map(
                (item) =>
                    DropdownMenuItem(value: item.id, child: Text(item.name)),
              )
              .toList(),
          onChanged: (value) => setState(() => _governorateId = value),
          decoration: const InputDecoration(
            labelText: 'المحافظة',
            prefixIcon: Icon(Icons.location_on_outlined),
          ),
          validator: (value) => value == null ? 'اختر المحافظة.' : null,
        ),
        const SizedBox(height: 16),
        AuthTextField(
          controller: _bioController,
          label: 'نبذة مختصرة',
          prefixIcon: Icons.notes_outlined,
          validator: _bio,
          textInputAction: TextInputAction.next,
        ),
        if (widget.providerType == ProviderType.supplier) ...[
          const SizedBox(height: 16),
          AuthTextField(
            controller: _companyNameController,
            label: 'اسم الشركة',
            prefixIcon: Icons.business_outlined,
            validator: _companyName,
          ),
        ],
        if (widget.providerType == ProviderType.freelancer) ...[
          const SizedBox(height: 16),
          AuthTextField(
            controller: _yearsController,
            label: 'سنوات الخبرة',
            keyboardType: TextInputType.number,
            prefixIcon: Icons.timeline_outlined,
            validator: _years,
          ),
        ],
      ],
    );
  }

  Widget _documentsStep() {
    final isSupplier = widget.providerType == ProviderType.supplier;
    final documentNames = isSupplier
        ? const ['Tax Card', 'Commercial Register']
        : const ['Syndicate ID', 'Qualification'];
    final arabicNames = <String, String>{
      'Tax Card': 'البطاقة الضريبية',
      'Commercial Register': 'السجل التجاري',
      'Syndicate ID': 'كارنيه النقابة',
      'Qualification': 'مؤهل أو شهادة خبرة',
    };

    return Column(
      key: const ValueKey('documents'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isSupplier
              ? 'المورد يجب أن يرفع البطاقة الضريبية والسجل التجاري.'
              : 'يمكن للمستقل رفع كارنيه النقابة أو مؤهل/شهادة خبرة.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        ...documentNames.map(
          (name) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _DocumentTile(
              title: arabicNames[name] ?? name,
              document: _documents[name],
              required: isSupplier,
              onPick: () => _pickDocument(name),
              onRemove: () => setState(() => _documents.remove(name)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _reviewStep() {
    return Column(
      key: const ValueKey('review'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ReviewRow(label: 'نوع الحساب', value: widget.providerType.arabicName),
        _ReviewRow(label: 'المحافظة', value: _governorateId?.toString() ?? '-'),
        if (_bioController.text.trim().isNotEmpty)
          _ReviewRow(label: 'النبذة', value: _bioController.text.trim()),
        if (widget.providerType == ProviderType.supplier)
          _ReviewRow(
            label: 'الشركة',
            value: _companyNameController.text.trim(),
          ),
        if (widget.providerType == ProviderType.freelancer)
          _ReviewRow(
            label: 'سنوات الخبرة',
            value: _yearsController.text.trim(),
          ),
        if (_documents.isNotEmpty)
          _ReviewRow(label: 'المستندات', value: '${_documents.length} ملف'),
      ],
    );
  }

  void _nextStep() {
    if (!_formKey.currentState!.validate()) return;
    if (_needsDocuments &&
        _stepIndex == 1 &&
        !_documentsValid(showMessage: true)) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _stepIndex += 1);
  }

  Future<void> _pickDocument(String documentName) async {
    try {
      final picked = await const NativeDocumentPicker().pickDocument();
      if (picked == null) return;
      if (!_isAllowedContentType(picked.contentType)) {
        _showMessage('اختر ملف PDF أو صورة JPG/PNG فقط.');
        return;
      }
      if (picked.size > 10 * 1024 * 1024) {
        _showMessage('حجم الملف يجب ألا يتجاوز 10 ميجابايت.');
        return;
      }
      setState(() {
        _documents[documentName] = VerificationDocument(
          documentName: documentName,
          filePath: picked.path,
          fileName: picked.name,
          contentType: picked.contentType,
        );
      });
    } catch (_) {
      _showMessage('تعذر اختيار الملف. حاول مرة أخرى.');
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (!_documentsValid(showMessage: true)) return;

    context.read<AccountCubit>().submitVerification(
      VerifyAccountInput(
        providerType: widget.providerType,
        governorateId: _governorateId,
        bio: _bioController.text,
        companyName: widget.providerType == ProviderType.supplier
            ? _companyNameController.text
            : null,
        yearsOfExperience: widget.providerType == ProviderType.freelancer
            ? int.tryParse(_yearsController.text.trim())
            : null,
        documents: _documents.values.toList(),
      ),
    );
  }

  bool _documentsValid({required bool showMessage}) {
    if (widget.providerType != ProviderType.supplier) return true;
    final valid =
        _documents.containsKey('Tax Card') &&
        _documents.containsKey('Commercial Register');
    if (!valid && showMessage) {
      _showMessage('يجب رفع البطاقة الضريبية والسجل التجاري.');
    }
    return valid;
  }

  bool _isAllowedContentType(String contentType) {
    return const {
      'application/pdf',
      'image/jpeg',
      'image/png',
    }.contains(contentType);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String? _bio(String? value) {
    final text = value?.trim() ?? '';
    if (widget.providerType == ProviderType.client && text.isEmpty) {
      return 'النبذة مطلوبة.';
    }
    if (text.length > 500) return 'النبذة لا يجب أن تتجاوز 500 حرف.';
    return null;
  }

  String? _companyName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'اسم الشركة مطلوب.';
    if (text.length > 150) return 'اسم الشركة لا يجب أن يتجاوز 150 حرفًا.';
    return null;
  }

  String? _years(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'سنوات الخبرة مطلوبة للمستقل.';
    final years = int.tryParse(text);
    if (years == null) return 'أدخل رقمًا صحيحًا.';
    if (years < 0) return 'سنوات الخبرة لا يمكن أن تكون أقل من صفر.';
    return null;
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.currentStep,
    required this.totalSteps,
    required this.title,
  });

  final int currentStep;
  final int totalSteps;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'خطوة $currentStep من $totalSteps',
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: currentStep / totalSteps,
          ),
        ),
      ],
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({
    required this.title,
    required this.document,
    required this.required,
    required this.onPick,
    required this.onRemove,
  });

  final String title;
  final VerificationDocument? document;
  final bool required;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(
            document == null ? Icons.upload_file_outlined : Icons.check_circle,
            color: document == null
                ? colorScheme.onSurfaceVariant
                : colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  required ? '$title *' : title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  document?.fileName ?? 'PDF أو JPG أو PNG',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: document == null ? 'اختيار ملف' : 'تغيير الملف',
            onPressed: onPick,
            icon: const Icon(Icons.attach_file),
          ),
          if (document != null)
            IconButton(
              tooltip: 'حذف الملف',
              onPressed: onRemove,
              icon: const Icon(Icons.close),
            ),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: Text(value.isEmpty ? '-' : value)),
        ],
      ),
    );
  }
}
