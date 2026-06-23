import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/platform/native_document_picker.dart';
import '../../domain/entities/quotation.dart';
import '../../domain/usecases/create_quotation_use_case.dart';
import '../cubit/create_quotation_cubit.dart';
import '../cubit/create_quotation_state.dart';

class CreateQuotationPage extends StatefulWidget {
  const CreateQuotationPage({super.key, required this.requestId});

  final int requestId;

  @override
  State<CreateQuotationPage> createState() => _CreateQuotationPageState();
}

class _CreateQuotationPageState extends State<CreateQuotationPage> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _picker = const NativeDocumentPicker();

  final List<PickedNativeDocument> _attachments = [];

  @override
  void dispose() {
    _priceController.dispose();
    _durationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickAttachment() async {
    if (_attachments.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الحد الأقصى 10 مرفقات')),
      );
      return;
    }
    final doc = await _picker.pickDocument();
    if (doc != null) setState(() => _attachments.add(doc));
  }

  void _removeAttachment(int index) => setState(() => _attachments.removeAt(index));

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CreateQuotationCubit(createQuotation: getIt<CreateQuotationUseCase>()),
      child: Builder(builder: (context) {
        return Scaffold(
          appBar: AppBar(title: const Text('تقديم عرض سعر')),
          body: BlocConsumer<CreateQuotationCubit, CreateQuotationState>(
            listener: (context, state) {
              if (state.status == CreateQuotationStatus.success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم تقديم العرض بنجاح'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context, true);
              } else if (state.status == CreateQuotationStatus.error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.errorMessage ?? 'حدث خطأ'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            builder: (context, state) {
              final isLoading = state.status == CreateQuotationStatus.loading;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Price
                      TextFormField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'السعر (ج.م) *',
                          prefixIcon: Icon(Icons.attach_money_rounded),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'السعر مطلوب';
                          final price = double.tryParse(v.trim());
                          if (price == null || price <= 0) return 'أدخل سعرًا صحيحًا';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Duration
                      TextFormField(
                        controller: _durationController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'مدة التنفيذ (أيام)',
                          prefixIcon: Icon(Icons.schedule_rounded),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          final d = int.tryParse(v.trim());
                          if (d == null || d <= 0) return 'أدخل عدد أيام صحيح';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        maxLength: 2000,
                        decoration: const InputDecoration(
                          labelText: 'وصف العرض',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Attachments section
                      _AttachmentsSection(
                        attachments: _attachments,
                        onAdd: _pickAttachment,
                        onRemove: _removeAttachment,
                      ),

                      const SizedBox(height: 28),

                      FilledButton(
                        onPressed: isLoading ? null : () => _submit(context),
                        child: isLoading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('تقديم العرض', style: TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    context.read<CreateQuotationCubit>().submit(
          CreateQuotationInput(
            requestId: widget.requestId,
            price: double.parse(_priceController.text.trim()),
            executionDurationDays: _durationController.text.trim().isNotEmpty
                ? int.parse(_durationController.text.trim())
                : null,
            description: _descriptionController.text.trim().isNotEmpty
                ? _descriptionController.text.trim()
                : null,
            attachments: _attachments
                .map((f) => QuotationLocalFile(
                      path: f.path,
                      name: f.name,
                      contentType: f.contentType,
                    ))
                .toList(),
          ),
        );
  }
}

class _AttachmentsSection extends StatelessWidget {
  const _AttachmentsSection({
    required this.attachments,
    required this.onAdd,
    required this.onRemove,
  });

  final List<PickedNativeDocument> attachments;
  final VoidCallback onAdd;
  final void Function(int) onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'المرفقات (${attachments.length}/10)',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.attach_file_rounded, size: 18),
              label: const Text('إضافة ملف'),
            ),
          ],
        ),
        if (attachments.isEmpty)
          Container(
            height: 64,
            decoration: BoxDecoration(
              border: Border.all(color: scheme.outlineVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'لا توجد مرفقات (اختياري)',
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
              ),
            ),
          )
        else
          ...attachments.asMap().entries.map(
                (e) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.insert_drive_file_rounded),
                  title: Text(e.value.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    '${(e.value.size / 1024).toStringAsFixed(1)} KB',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.red),
                    onPressed: () => onRemove(e.key),
                  ),
                ),
              ),
      ],
    );
  }
}
