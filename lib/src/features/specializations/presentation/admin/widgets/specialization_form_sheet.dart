import 'package:flutter/material.dart';

import '../../../domain/entities/specialization.dart';

class SpecializationFormResult {
  const SpecializationFormResult({
    required this.name,
    required this.measurementUnitId,
  });

  final String name;
  final int measurementUnitId;
}

class SpecializationFormSheet {
  const SpecializationFormSheet._();

  static Future<SpecializationFormResult?> show(
    BuildContext context, {
    required String title,
    required String confirmLabel,
    required List<MeasurementUnit> measurementUnits,
    String? initialName,
    int? initialMeasurementUnitId,
  }) {
    return showModalBottomSheet<SpecializationFormResult>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _SpecializationFormSheetContent(
        title: title,
        confirmLabel: confirmLabel,
        measurementUnits: measurementUnits,
        initialName: initialName,
        initialMeasurementUnitId: initialMeasurementUnitId,
      ),
    );
  }
}

class _SpecializationFormSheetContent extends StatefulWidget {
  const _SpecializationFormSheetContent({
    required this.title,
    required this.confirmLabel,
    required this.measurementUnits,
    this.initialName,
    this.initialMeasurementUnitId,
  });

  final String title;
  final String confirmLabel;
  final List<MeasurementUnit> measurementUnits;
  final String? initialName;
  final int? initialMeasurementUnitId;

  @override
  State<_SpecializationFormSheetContent> createState() =>
      _SpecializationFormSheetContentState();
}

class _SpecializationFormSheetContentState
    extends State<_SpecializationFormSheetContent> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.initialName);
  int? _selectedMeasurementUnitId;

  @override
  void initState() {
    super.initState();
    _selectedMeasurementUnitId = widget.initialMeasurementUnitId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Text(
              widget.title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'اسم التخصص',
                prefixIcon: Icon(Icons.label_outline_rounded),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'اسم التخصص مطلوب.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _selectedMeasurementUnitId,
              isExpanded: true,
              menuMaxHeight: 280,
              borderRadius: BorderRadius.circular(12),
              icon: const Icon(Icons.expand_more_rounded),
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: const InputDecoration(
                labelText: 'وحدة القياس',
                prefixIcon: Icon(Icons.straighten_rounded),
              ),
              items: widget.measurementUnits
                  .map(
                    (unit) => DropdownMenuItem(
                      value: unit.id,
                      child: Text(unit.name, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (value) =>
                  setState(() => _selectedMeasurementUnitId = value),
              validator: (value) {
                if (value == null) return 'وحدة القياس مطلوبة.';
                return null;
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('إلغاء'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _submit,
                    child: Text(widget.confirmLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      SpecializationFormResult(
        name: _nameController.text.trim(),
        measurementUnitId: _selectedMeasurementUnitId!,
      ),
    );
  }
}
