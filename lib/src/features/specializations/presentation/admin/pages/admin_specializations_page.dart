import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/service_locator.dart';
import '../../../../admin/presentation/widgets/empty_state_widget.dart';
import '../../../../admin/presentation/widgets/loading_state_widget.dart';
import '../../../domain/entities/specialization.dart';
import '../cubit/admin_specializations_cubit.dart';
import '../widgets/admin_specialization_tile.dart';
import '../widgets/specialization_form_sheet.dart';

class AdminSpecializationsPage extends StatelessWidget {
  const AdminSpecializationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AdminSpecializationsCubit>()..load(),
      child: const _AdminSpecializationsView(),
    );
  }
}

class _AdminSpecializationsView extends StatelessWidget {
  const _AdminSpecializationsView();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: BlocConsumer<AdminSpecializationsCubit, AdminSpecializationsState>(
        listenWhen: (previous, current) =>
            previous.errorMessage != current.errorMessage ||
            previous.successMessage != current.successMessage,
        listener: (context, state) {
          final message = state.errorMessage ?? state.successMessage;
          if (message == null || message.isEmpty) return;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: state.errorMessage != null
                    ? scheme.error
                    : const Color(0xFF16A34A),
              ),
            );
        },
        builder: (context, state) {
          final cubit = context.read<AdminSpecializationsCubit>();

          return PopScope(
            canPop: !state.canGoBack,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) cubit.goBack();
            },
            child: Scaffold(
              backgroundColor: scheme.surfaceContainerLowest,
              appBar: AppBar(
                title: Text(state.currentParent?.name ?? 'التخصصات'),
                surfaceTintColor: Colors.transparent,
                actions: [
                  IconButton(
                    tooltip: 'تحديث',
                    onPressed: state.isLoading ? null : cubit.load,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              body: _buildBody(context, state, cubit),
              floatingActionButton:
                  state.status == AdminSpecializationsStatus.loaded
                  ? FloatingActionButton(
                      onPressed: () => _addSpecialization(context, cubit, state),
                      tooltip: 'إضافة تخصص',
                      child: const Icon(Icons.add_rounded),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AdminSpecializationsState state,
    AdminSpecializationsCubit cubit,
  ) {
    if (state.isLoading || state.status == AdminSpecializationsStatus.initial) {
      return const LoadingStateWidget();
    }

    if (state.status == AdminSpecializationsStatus.failure &&
        state.productRoots.isEmpty &&
        state.engineeringRoots.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.error_outline_rounded,
        title: state.errorMessage ?? 'حدث خطأ غير متوقع.',
        subtitle: 'اضغط على زر التحديث لإعادة المحاولة.',
      );
    }

    return RefreshIndicator(
      onRefresh: cubit.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          if (!state.canGoBack) ...[
            Center(
              child: _TypeSelector(
                selected: state.selectedType,
                onChanged: cubit.selectType,
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (state.currentList.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: EmptyStateWidget(
                icon: Icons.inbox_rounded,
                title: 'لا توجد عناصر',
                subtitle: 'اضغط على + لإضافة تخصص جديد.',
              ),
            )
          else
            ...state.currentList.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AdminSpecializationTile(
                  specialization: item,
                  isProcessing: state.isProcessing(item.id),
                  onOpen: () => cubit.drillInto(item),
                  onEdit: () => _editSpecialization(context, cubit, state, item),
                  onToggleDelete: () =>
                      _confirmToggleDelete(context, cubit, item),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _addSpecialization(
    BuildContext context,
    AdminSpecializationsCubit cubit,
    AdminSpecializationsState state,
  ) async {
    final result = await SpecializationFormSheet.show(
      context,
      title: 'إضافة تخصص جديد',
      confirmLabel: 'إضافة',
      measurementUnits: state.measurementUnits,
    );
    if (result == null) return;
    await cubit.createNode(
      name: result.name,
      measurementUnitId: result.measurementUnitId,
    );
  }

  Future<void> _editSpecialization(
    BuildContext context,
    AdminSpecializationsCubit cubit,
    AdminSpecializationsState state,
    Specialization item,
  ) async {
    final result = await SpecializationFormSheet.show(
      context,
      title: 'تعديل التخصص',
      confirmLabel: 'حفظ',
      measurementUnits: state.measurementUnits,
      initialName: item.name,
      initialMeasurementUnitId: item.measurementUnitId,
    );
    if (result == null) return;
    await cubit.updateNode(
      item,
      name: result.name,
      measurementUnitId: result.measurementUnitId,
    );
  }

  Future<void> _confirmToggleDelete(
    BuildContext context,
    AdminSpecializationsCubit cubit,
    Specialization item,
  ) async {
    final isDeleted = item.isDeleted;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isDeleted ? 'تأكيد الاستعادة' : 'تأكيد الحذف'),
        content: Text(
          isDeleted
              ? 'هل تريد استعادة "${item.name}" وجميع عناصره الفرعية؟'
              : 'هل تريد حذف "${item.name}"؟ سيتم حذف جميع العناصر الفرعية التابعة له.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(isDeleted ? 'استعادة' : 'حذف'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await cubit.toggleDelete(item);
    }
  }
}

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({required this.selected, required this.onChanged});

  final SpecializationType selected;
  final ValueChanged<SpecializationType> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<SpecializationType>(
      segments: SpecializationType.values
          .map(
            (type) => ButtonSegment(value: type, label: Text(type.arabicLabel)),
          )
          .toList(),
      selected: {selected},
      onSelectionChanged: (value) => onChanged(value.first),
    );
  }
}
