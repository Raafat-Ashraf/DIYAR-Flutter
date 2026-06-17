import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/platform/native_document_picker.dart';
import '../../../account/presentation/cubit/account_cubit.dart';
import '../../../admin/presentation/widgets/empty_state_widget.dart';
import '../../../auth/presentation/widgets/auth_text_field.dart';
import '../../../auth/presentation/widgets/loading_button.dart';
import '../../domain/entities/showcase.dart';
import '../cubit/create_showcase_cubit.dart';

class CreateShowcasePage extends StatelessWidget {
  const CreateShowcasePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CreateShowcaseCubit>(),
      child: const _CreateShowcaseView(),
    );
  }
}

class _CreateShowcaseView extends StatefulWidget {
  const _CreateShowcaseView();

  @override
  State<_CreateShowcaseView> createState() => _CreateShowcaseViewState();
}

class _CreateShowcaseViewState extends State<_CreateShowcaseView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final providerType = context.select(
      (AccountCubit cubit) => cubit.state.profile?.providerType,
    );
    final type = ShowcaseType.fromProviderType(providerType);
    final scheme = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: scheme.surfaceContainerLowest,
        appBar: AppBar(
          title: Text(
            type == ShowcaseType.product ? 'إضافة منتج جديد' : 'إضافة معرض أعمال',
          ),
          surfaceTintColor: Colors.transparent,
        ),
        body: type == null
            ? const EmptyStateWidget(
                icon: Icons.lock_outline_rounded,
                title: 'هذه الميزة غير متاحة لحسابك.',
                subtitle: 'إضافة العروض متاحة للموردين والمهندسين فقط.',
              )
            : BlocConsumer<CreateShowcaseCubit, CreateShowcaseState>(
                listenWhen: (previous, current) =>
                    previous.errorMessage != current.errorMessage ||
                    previous.successMessage != current.successMessage,
                listener: (context, state) {
                  if (state.errorMessage != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.errorMessage!),
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    );
                  }
                  if (state.successMessage != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.successMessage!),
                        backgroundColor: const Color(0xFF16A34A),
                      ),
                    );
                    Navigator.of(context).pop(true);
                  }
                },
                builder: (context, state) {
                  final cubit = context.read<CreateShowcaseCubit>();
                  return Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                      children: [
                        _CoverImagePicker(
                          coverImage: state.coverImage,
                          onTap: cubit.pickCoverImage,
                          onRemove: cubit.removeCoverImage,
                        ),
                        const SizedBox(height: 24),
                        AuthTextField(
                          controller: _titleController,
                          label: 'العنوان',
                          prefixIcon: Icons.title_rounded,
                          textInputAction: TextInputAction.next,
                          validator: _titleValidator,
                        ),
                        const SizedBox(height: 16),
                        AuthTextField(
                          controller: _descriptionController,
                          label: 'الوصف',
                          prefixIcon: Icons.description_outlined,
                          maxLines: 5,
                          validator: _descriptionValidator,
                        ),
                        const SizedBox(height: 16),
                        AuthTextField(
                          controller: _priceController,
                          label: 'السعر (اختياري)',
                          prefixIcon: Icons.payments_outlined,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textInputAction: TextInputAction.done,
                          validator: _priceValidator,
                        ),
                        const SizedBox(height: 24),
                        _AdditionalFilesSection(
                          files: state.files,
                          onAdd: cubit.pickFiles,
                          onRemove: cubit.removeFile,
                          onDescriptionChanged: cubit.updateFileDescription,
                        ),
                        const SizedBox(height: 32),
                        LoadingButton(
                          label: 'نشر العرض',
                          isLoading: state.isSubmitting,
                          onPressed: () => _submit(context, type),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  void _submit(BuildContext context, ShowcaseType type) {
    if (!_formKey.currentState!.validate()) return;
    final cubit = context.read<CreateShowcaseCubit>();
    FocusScope.of(context).unfocus();
    final priceText = _priceController.text.trim();
    cubit.submit(
      type: type,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      price: priceText.isEmpty ? null : double.tryParse(priceText),
    );
  }

  String? _titleValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'العنوان مطلوب.';
    if (text.length > 150) return 'العنوان لا يجب أن يتجاوز 150 حرفًا.';
    return null;
  }

  String? _descriptionValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'الوصف مطلوب.';
    return null;
  }

  String? _priceValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final price = double.tryParse(text);
    if (price == null) return 'أدخل سعرًا صحيحًا.';
    if (price < 0) return 'السعر لا يمكن أن يكون أقل من صفر.';
    return null;
  }
}

class _CoverImagePicker extends StatelessWidget {
  const _CoverImagePicker({
    required this.coverImage,
    required this.onTap,
    required this.onRemove,
  });

  final PickedNativeDocument? coverImage;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: coverImage == null ? onTap : null,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: scheme.surfaceContainerHighest,
            border: Border.all(color: scheme.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: .05),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: coverImage == null
              ? _placeholder(scheme)
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(File(coverImage!.path), fit: BoxFit.cover),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: _RoundIconButton(
                        icon: Icons.close_rounded,
                        onTap: onRemove,
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: _RoundIconButton(
                        icon: Icons.edit_rounded,
                        onTap: onTap,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _placeholder(ColorScheme scheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: .1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.add_photo_alternate_rounded,
              size: 30,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'إضافة صورة الغلاف (اختياري)',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'JPG أو PNG، حتى 10 ميجابايت',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: .45),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
      ),
    );
  }
}

class _AdditionalFilesSection extends StatelessWidget {
  const _AdditionalFilesSection({
    required this.files,
    required this.onAdd,
    required this.onRemove,
    required this.onDescriptionChanged,
  });

  final List<PickedShowcaseFile> files;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;
  final void Function(int index, String description) onDescriptionChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'ملفات إضافية (اختياري)',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('إضافة'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (files.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Text(
              'لم تتم إضافة ملفات بعد',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          )
        else
          ...files.asMap().entries.map(
            (entry) => _FileTile(
              file: entry.value,
              onRemove: () => onRemove(entry.key),
              onDescriptionChanged: (value) =>
                  onDescriptionChanged(entry.key, value),
            ),
          ),
      ],
    );
  }
}

class _FileTile extends StatelessWidget {
  const _FileTile({
    required this.file,
    required this.onRemove,
    required this.onDescriptionChanged,
  });

  final PickedShowcaseFile file;
  final VoidCallback onRemove;
  final ValueChanged<String> onDescriptionChanged;

  bool get _isImage => file.document.contentType.startsWith('image/');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      key: ValueKey(file.document.path),
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
        color: scheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _isImage
                    ? Image.file(
                        File(file.document.path),
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 44,
                        height: 44,
                        color: scheme.primary.withValues(alpha: .08),
                        child: Icon(
                          Icons.picture_as_pdf_rounded,
                          color: scheme.primary,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  file.document.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: file.description,
            decoration: const InputDecoration(
              hintText: 'وصف الملف (اختياري)',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onChanged: onDescriptionChanged,
          ),
        ],
      ),
    );
  }
}
