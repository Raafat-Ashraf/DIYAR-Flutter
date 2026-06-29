import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/di/service_locator.dart';
import '../../../admin/presentation/widgets/empty_state_widget.dart';
import '../../../admin/presentation/widgets/loading_state_widget.dart';
import '../../../auth/presentation/widgets/auth_text_field.dart';
import '../../../specializations/domain/entities/specialization.dart';
import '../../domain/entities/request.dart';
import '../cubit/create_request_cubit.dart';

class CreateRequestPage extends StatelessWidget {
  const CreateRequestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CreateRequestCubit>(),
      child: const _CreateRequestView(),
    );
  }
}

class _CreateRequestView extends StatefulWidget {
  const _CreateRequestView();

  @override
  State<_CreateRequestView> createState() => _CreateRequestViewState();
}

class _CreateRequestViewState extends State<_CreateRequestView> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _quantityController = TextEditingController();
  final _budgetController = TextEditingController();
  final _durationController = TextEditingController();
  final _descriptionController = TextEditingController();

  static const _stepTitles = [
    'إضافة طلب - نوع الطلب',
    'التخصص',
    'الموقع',
    'تفاصيل الطلب',
  ];

  @override
  void dispose() {
    _addressController.dispose();
    _quantityController.dispose();
    _budgetController.dispose();
    _durationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: BlocConsumer<CreateRequestCubit, CreateRequestState>(
        listenWhen: (prev, curr) =>
            prev.errorMessage != curr.errorMessage ||
            prev.isSuccess != curr.isSuccess,
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
          if (state.isSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم إنشاء الطلب بنجاح.'),
                backgroundColor: Color(0xFF16A34A),
              ),
            );
            context.go(AppRoutes.home);
          }
        },
        builder: (context, state) {
          final isLoading = state.isLoading || state.isSubmitting;
          final cubit = context.read<CreateRequestCubit>();
          final isLastStep = state.step == 3;

          return Scaffold(
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerLowest,
            appBar: AppBar(
              surfaceTintColor: Colors.transparent,
              // السابق — إذا خطوة أولى يخرج من الشاشة، غيرها يرجع خطوة
              leading: IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded),
                onPressed: isLoading
                    ? null
                    : () {
                        if (state.step == 0) {
                          Navigator.of(context).pop();
                        } else {
                          cubit.goToStep(state.step - 1);
                        }
                      },
              ),
              title: Text(_stepTitles[state.step]),
              actions: [
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else
                  TextButton(
                    onPressed: isLastStep
                        ? () => _onSubmit(context, state)
                        : () => _onNext(context, state),
                    child: Text(
                      isLastStep ? 'نشر' : 'التالي',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
              ],
            ),
            body: Column(
              children: [
                _StepIndicator(currentStep: state.step, totalSteps: 4),
                Expanded(child: _buildStepContent(context, state)),
              ],
            ),
          );
        },
      ),
    );
  }

  bool _canProceed(CreateRequestState state) {
    switch (state.step) {
      case 0:
        return state.requestType != null;
      case 1:
        return state.selectedSpecialization != null;
      case 2:
        return state.selectedCity != null;
      case 3:
        return true;
      default:
        return false;
    }
  }

  void _onNext(BuildContext context, CreateRequestState state) {
    if (!_canProceed(state)) {
      final msg = switch (state.step) {
        0 => 'اختر نوع الطلب أولاً.',
        1 => 'اختر التخصص أولاً.',
        2 => 'اختر المحافظة والمدينة أولاً.',
        _ => 'أكمل البيانات المطلوبة.',
      };
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      return;
    }
    // Validate address when leaving location step
    if (state.step == 2 && _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: const Text('أدخل العنوان التفصيلي.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      return;
    }
    context.read<CreateRequestCubit>().goToStep(state.step + 1);
  }

  void _onSubmit(BuildContext context, CreateRequestState state) {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final qty = _quantityController.text.trim();
    final budget = _budgetController.text.trim();
    final duration = _durationController.text.trim();
    context.read<CreateRequestCubit>().submit(
      address: _addressController.text.trim(),
      quantity: qty.isEmpty ? null : double.tryParse(qty),
      expectedBudget: budget.isEmpty ? null : double.tryParse(budget),
      executionDurationDays: duration.isEmpty ? null : int.tryParse(duration),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
    );
  }

  Widget _buildStepContent(BuildContext context, CreateRequestState state) {
    if (state.isLoading) {
      return const LoadingStateWidget();
    }
    return switch (state.step) {
      0 => _Step1RequestType(
          selected: state.requestType,
          onSelected: context.read<CreateRequestCubit>().selectRequestType,
        ),
      1 => _Step2Specialization(
          specializations: state.specializations,
          selected: state.selectedSpecialization,
          onSelected: context.read<CreateRequestCubit>().selectSpecialization,
        ),
      2 => _Step3Location(state: state, addressController: _addressController),
      3 => _Step4Details(
          formKey: _formKey,
          quantityController: _quantityController,
          budgetController: _budgetController,
          durationController: _durationController,
          descriptionController: _descriptionController,
          requestType: state.requestType,
          measurementUnit: state.selectedSpecialization?.measurementUnitName,
          files: state.files,
        ),
      _ => const SizedBox.shrink(),
    };
  }
}

// ── Step 1: Request Type ────────────────────────────────────────────────────

class _Step1RequestType extends StatelessWidget {
  const _Step1RequestType({required this.selected, required this.onSelected});

  final RequestType? selected;
  final ValueChanged<RequestType> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Intro banner ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  scheme.primary.withValues(alpha: .10),
                  scheme.primary.withValues(alpha: .04),
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: scheme.primary.withValues(alpha: .18),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: .14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.handshake_outlined,
                    color: scheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'أضف طلبك',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'سيقدم لك المهندسون والموردون المتخصصون والموثوقون'
                        ' عروض أسعار تنافسية بنظام المناقصة.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.55,
                          color: scheme.onSurface.withValues(alpha: .72),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'اختر نوع الطلب',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _TypeCard(
            type: RequestType.material,
            icon: Icons.inventory_2_outlined,
            selected: selected == RequestType.material,
            onTap: () => onSelected(RequestType.material),
          ),
          const SizedBox(height: 12),
          _TypeCard(
            type: RequestType.service,
            icon: Icons.engineering_outlined,
            selected: selected == RequestType.service,
            onTap: () => onSelected(RequestType.service),
          ),
        ],
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.type,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final RequestType type;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primary.withValues(alpha: .08)
              : scheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: .12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: scheme.primary, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                type.arabicLabel,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: selected ? scheme.primary : scheme.onSurface,
                ),
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: scheme.primary),
          ],
        ),
      ),
    );
  }
}

// ── Step 2: Specialization ─────────────────────────────────────────────────

class _Step2Specialization extends StatefulWidget {
  const _Step2Specialization({
    required this.specializations,
    required this.selected,
    required this.onSelected,
  });

  final List<Specialization> specializations;
  final Specialization? selected;
  final void Function(Specialization) onSelected;

  @override
  State<_Step2Specialization> createState() => _Step2SpecializationState();
}

class _Step2SpecializationState extends State<_Step2Specialization> {
  final _searchController = TextEditingController();
  String _query = '';

  // Collect all nodes (parents + children) matching the query.
  List<Specialization> _flatAll(List<Specialization> specs) {
    final result = <Specialization>[];
    for (final s in specs) {
      result.add(s);
      if (s.hasChildren) result.addAll(_flatAll(s.children));
    }
    return result;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.specializations.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.category_outlined,
        title: 'لا توجد تخصصات متاحة',
      );
    }

    final searching = _query.isNotEmpty;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'ابحث عن تخصص...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: !searching
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    ),
            ),
          ),
        ),
        Expanded(
          child: searching
              ? _SearchResults(
                  all: _flatAll(widget.specializations),
                  query: _query,
                  selected: widget.selected,
                  onSelected: widget.onSelected,
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: widget.specializations.map(
                    (s) => _SpecNode(
                      spec: s,
                      selected: widget.selected,
                      onSelected: widget.onSelected,
                      depth: 0,
                    ),
                  ).toList(),
                ),
        ),
      ],
    );
  }
}

// Flat filtered list shown while searching.
class _SearchResults extends StatelessWidget {
  const _SearchResults({
    required this.all,
    required this.query,
    required this.selected,
    required this.onSelected,
  });

  final List<Specialization> all;
  final String query;
  final Specialization? selected;
  final ValueChanged<Specialization> onSelected;

  @override
  Widget build(BuildContext context) {
    final q = query.toLowerCase();
    // Only show leaf nodes in search (parents are not selectable)
    final hits = all
        .where((s) => !s.hasChildren && s.name.toLowerCase().contains(q))
        .toList();

    if (hits.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.search_off_rounded,
        title: 'لا توجد نتائج لـ "$query"',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: hits.length,
      itemBuilder: (_, i) => _SpecTile(
        spec: hits[i],
        isSelected: selected?.id == hits[i].id,
        onTap: () => onSelected(hits[i]),
      ),
    );
  }
}

// Stateful node: selectable + expandable if has children.
class _SpecNode extends StatefulWidget {
  const _SpecNode({
    required this.spec,
    required this.selected,
    required this.onSelected,
    required this.depth,
  });

  final Specialization spec;
  final Specialization? selected;
  final ValueChanged<Specialization> onSelected;
  final int depth;

  @override
  State<_SpecNode> createState() => _SpecNodeState();
}

class _SpecNodeState extends State<_SpecNode> {
  bool _expanded = false;

  int _countAll(Specialization s) {
    if (!s.hasChildren) return 0;
    return s.children.fold(s.children.length, (sum, c) => sum + _countAll(c));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final spec = widget.spec;
    final isParent = spec.hasChildren;
    // Only leaf nodes are selectable
    final isSelected = !isParent && widget.selected?.id == spec.id;
    final indent = widget.depth * 16.0;
    final total = isParent ? _countAll(spec) : null;

    return Padding(
      padding: EdgeInsets.only(right: indent, top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Parent: tap anywhere → expand/collapse (not selectable) ──
          // ── Leaf:   tap → select ──────────────────────────────────────
          GestureDetector(
            onTap: isParent
                ? () => setState(() => _expanded = !_expanded)
                : () => widget.onSelected(spec),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? scheme.primary.withValues(alpha: .08)
                    : isParent
                        ? scheme.surfaceContainerHighest.withValues(alpha: .5)
                        : scheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? scheme.primary : scheme.outlineVariant,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  if (isParent) ...[
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      spec.name,
                      style: TextStyle(
                        fontWeight:
                            isParent ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected
                            ? scheme.primary
                            : isParent
                                ? scheme.onSurface
                                : scheme.onSurface,
                      ),
                    ),
                  ),
                  if (spec.measurementUnitName != null && !isParent) ...[
                    const SizedBox(width: 6),
                    Text(
                      spec.measurementUnitName!,
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (total != null) ...[
                    const SizedBox(width: 6),
                    _CountBadge(count: total, scheme: scheme),
                  ],
                  if (isSelected) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.check_circle_rounded,
                        color: scheme.primary, size: 18),
                  ],
                ],
              ),
            ),
          ),
          // ── Children ──
          if (isParent && _expanded)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                children: spec.children.map(
                  (child) => _SpecNode(
                    spec: child,
                    selected: widget.selected,
                    onSelected: widget.onSelected,
                    depth: widget.depth + 1,
                  ),
                ).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

// Reusable flat tile (used in search results).
class _SpecTile extends StatelessWidget {
  const _SpecTile({
    required this.spec,
    required this.isSelected,
    required this.onTap,
  });

  final Specialization spec;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? scheme.primary.withValues(alpha: .08)
                : scheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? scheme.primary : scheme.outlineVariant,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  spec.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isSelected ? scheme.primary : scheme.onSurface,
                  ),
                ),
              ),
              if (spec.measurementUnitName != null) ...[
                const SizedBox(width: 6),
                Text(
                  spec.measurementUnitName!,
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (isSelected) ...[
                const SizedBox(width: 6),
                Icon(Icons.check_circle_rounded,
                    color: scheme.primary, size: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count, required this.scheme});

  final int count;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: scheme.primary,
        ),
      ),
    );
  }
}

// ── Step 3: Location ───────────────────────────────────────────────────────

class _Step3Location extends StatelessWidget {
  const _Step3Location({
    required this.state,
    required this.addressController,
  });

  final CreateRequestState state;
  final TextEditingController addressController;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cubit = context.read<CreateRequestCubit>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Text(
          'المحافظة',
          style: TextStyle(fontWeight: FontWeight.w800, color: scheme.onSurface),
        ),
        const SizedBox(height: 8),
        _DropdownField<dynamic>(
          hint: 'اختر المحافظة',
          value: state.selectedGovernorate,
          items: state.governorates
              .map((g) => DropdownMenuItem(value: g, child: Text(g.name)))
              .toList(),
          onChanged: (g) {
            if (g != null) cubit.selectGovernorate(g);
          },
        ),
        const SizedBox(height: 20),
        Text(
          'المدينة',
          style: TextStyle(fontWeight: FontWeight.w800, color: scheme.onSurface),
        ),
        const SizedBox(height: 8),
        if (state.status == CreateRequestStatus.loadingCities)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          )
        else
          _DropdownField<dynamic>(
            hint: state.selectedGovernorate == null
                ? 'اختر المحافظة أولاً'
                : 'اختر المدينة',
            value: state.selectedCity,
            enabled: state.cities.isNotEmpty,
            items: state.cities
                .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                .toList(),
            onChanged: (c) {
              if (c != null) cubit.selectCity(c);
            },
          ),
        const SizedBox(height: 20),
        Text(
          'العنوان التفصيلي',
          style: TextStyle(fontWeight: FontWeight.w800, color: scheme.onSurface),
        ),
        const SizedBox(height: 8),
        AuthTextField(
          controller: addressController,
          label: 'مثال: شارع النيل، بجوار مسجد النور',
          prefixIcon: Icons.location_on_outlined,
          textInputAction: TextInputAction.done,
          maxLines: 2,
        ),
      ],
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    this.enabled = true,
  });

  final String hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: enabled ? scheme.surface : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          menuMaxHeight: 220,
          hint: Text(
            hint,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          items: items,
          onChanged: enabled ? onChanged : null,
        ),
      ),
    );
  }
}

// ── Step 4: Details ────────────────────────────────────────────────────────

class _Step4Details extends StatelessWidget {
  const _Step4Details({
    required this.formKey,
    required this.quantityController,
    required this.budgetController,
    required this.durationController,
    required this.descriptionController,
    required this.requestType,
    required this.measurementUnit,
    required this.files,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController quantityController;
  final TextEditingController budgetController;
  final TextEditingController durationController;
  final TextEditingController descriptionController;
  final RequestType? requestType;
  final String? measurementUnit;
  final List<PickedRequestFile> files;

  bool get _isMaterial => requestType == RequestType.material;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CreateRequestCubit>();

    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          if (_isMaterial) ...[
            AuthTextField(
              controller: quantityController,
              label: 'الكمية${measurementUnit != null ? ' ($measurementUnit)' : ''} *',
              prefixIcon: Icons.inventory_2_outlined,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.isEmpty) return 'الكمية مطلوبة لطلبات المواد.';
                final n = double.tryParse(t);
                if (n == null || n <= 0) return 'أدخل كمية صحيحة أكبر من صفر.';
                return null;
              },
            ),
            const SizedBox(height: 16),
          ],
          AuthTextField(
            controller: budgetController,
            label: 'الميزانية المتوقعة (اختياري)',
            prefixIcon: Icons.payments_outlined,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            validator: (v) {
              final t = v?.trim() ?? '';
              if (t.isEmpty) return null;
              final n = double.tryParse(t);
              if (n == null || n <= 0) return 'الميزانية يجب أن تكون أكبر من صفر.';
              return null;
            },
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: durationController,
            label: 'مدة التنفيذ بالأيام (اختياري)',
            prefixIcon: Icons.calendar_today_outlined,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            validator: (v) {
              final t = v?.trim() ?? '';
              if (t.isEmpty) return null;
              final n = int.tryParse(t);
              if (n == null || n <= 0) return 'المدة يجب أن تكون أكبر من صفر.';
              return null;
            },
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: descriptionController,
            label: 'الوصف (اختياري)',
            prefixIcon: Icons.description_outlined,
            maxLines: 4,
            validator: (v) {
              final t = v?.trim() ?? '';
              if (t.length > 2000) return 'الوصف لا يجب أن يتجاوز 2000 حرف.';
              return null;
            },
          ),
          const SizedBox(height: 24),
          _FilesSection(files: files, cubit: cubit),
        ],
      ),
    );
  }
}

class _FilesSection extends StatelessWidget {
  const _FilesSection({required this.files, required this.cubit});

  final List<PickedRequestFile> files;
  final CreateRequestCubit cubit;

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
                'ملفات مرفقة (اختياري)',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
            if (files.length < 10)
              TextButton.icon(
                onPressed: cubit.pickFiles,
                icon: const Icon(Icons.attach_file_rounded),
                label: const Text('إرفاق'),
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
              borderRadius: BorderRadius.circular(12),
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
              key: ValueKey(entry.value.document.path),
              file: entry.value,
              onRemove: () => cubit.removeFile(entry.key),
              onDescriptionChanged: (v) =>
                  cubit.updateFileDescription(entry.key, v),
            ),
          ),
      ],
    );
  }
}

class _FileTile extends StatelessWidget {
  const _FileTile({
    super.key,
    required this.file,
    required this.onRemove,
    required this.onDescriptionChanged,
  });

  final PickedRequestFile file;
  final VoidCallback onRemove;
  final ValueChanged<String> onDescriptionChanged;

  bool get _isImage => file.document.contentType.startsWith('image/');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
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
                          Icons.insert_drive_file_outlined,
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
            maxLength: 500,
            onChanged: onDescriptionChanged,
          ),
        ],
      ),
    );
  }
}

// ── Shared ─────────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep, required this.totalSteps});

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: List.generate(totalSteps * 2 - 1, (i) {
          if (i.isOdd) {
            return Expanded(
              child: Container(
                height: 2,
                color: i ~/ 2 < currentStep
                    ? scheme.primary
                    : scheme.outlineVariant,
              ),
            );
          }
          final step = i ~/ 2;
          final done = step < currentStep;
          final active = step == currentStep;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done || active ? scheme.primary : scheme.surfaceContainerHighest,
              border: active
                  ? Border.all(color: scheme.primary, width: 2)
                  : null,
            ),
            child: Center(
              child: done
                  ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                  : Text(
                      '${step + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: active
                            ? Colors.white
                            : scheme.onSurfaceVariant,
                      ),
                    ),
            ),
          );
        }),
      ),
    );
  }
}

