import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/widgets/loading_button.dart';
import '../../../specializations/domain/entities/specialization.dart';
import '../../domain/entities/account_profile.dart';
import '../cubit/account_cubit.dart';

class EditSpecializationsPage extends StatefulWidget {
  const EditSpecializationsPage({super.key});

  @override
  State<EditSpecializationsPage> createState() =>
      _EditSpecializationsPageState();
}

class _EditSpecializationsPageState extends State<EditSpecializationsPage> {
  final Set<int> _selectedSpecIds = {};
  bool _saving = false;
  List<Specialization> _specs = [];
  bool _loading = true;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _selectedSpecIds
        .addAll(getIt<AccountCubit>().state.profile?.specializationIds ?? []);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final cubit = getIt<AccountCubit>();
      final providerType = cubit.state.profile?.providerType;
      final specType = providerType == ProviderType.supplier
          ? SpecializationType.product
          : SpecializationType.engineeringService;
      if (cubit.state.specializations.isNotEmpty) {
        if (mounted) setState(() { _specs = cubit.state.specializations; _loading = false; });
        return;
      }
      await cubit.loadSpecializations(specType);
      if (mounted) setState(() { _specs = cubit.state.specializations; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Set<int> _allSpecIds(Specialization node) {
    final ids = {node.id};
    for (final child in node.children.where((c) => !c.isDeleted))
      ids.addAll(_allSpecIds(child));
    return ids;
  }

  void _toggle(Specialization node) {
    final ids = _allSpecIds(node);
    final allSel = ids.every(_selectedSpecIds.contains);
    setState(() {
      if (allSel) _selectedSpecIds.removeAll(ids);
      else _selectedSpecIds.addAll(ids);
    });
  }

  bool? _checkboxValue(Specialization node) {
    final ids = _allSpecIds(node);
    final count = ids.where(_selectedSpecIds.contains).length;
    if (count == 0) return false;
    if (count == ids.length) return true;
    return null;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await getIt<ApiClient>().put<dynamic>(
        ApiConstants.updateSpecializations,
        data: {'specializationIds': _selectedSpecIds.toList()},
      );
      await getIt<AccountCubit>().loadProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حفظ التخصصات ✓')));
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('حدث خطأ، حاول مرة أخرى')));
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('تعديل التخصصات')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text('التخصصات',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800)),
                        ),
                        Text('${_selectedSpecIds.length} تخصص',
                            style: TextStyle(color: scheme.primary)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      child: Column(
                        children: _specs
                            .where((s) => !s.isDeleted)
                            .map(_specTile)
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    LoadingButton(
                      label: 'حفظ التخصصات',
                      isLoading: _saving,
                      onPressed: _save,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _specTile(Specialization node, {int depth = 0}) {
    final children = node.children.where((c) => !c.isDeleted).toList();
    if (children.isEmpty) {
      return Padding(
        padding: EdgeInsetsDirectional.only(start: 16.0 * depth),
        child: CheckboxListTile(
          value: _selectedSpecIds.contains(node.id),
          title: Text(node.name, style: const TextStyle(fontSize: 14)),
          dense: true,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          onChanged: (_) => _toggle(node),
        ),
      );
    }
    return _ExpandSpecTile(
      key: PageStorageKey('spec-${node.id}'),
      name: node.name,
      depth: depth,
      checkboxValue: _checkboxValue(node),
      onToggle: () => _toggle(node),
      childTiles:
          children.map((c) => _specTile(c, depth: depth + 1)).toList(),
    );
  }
}

class _ExpandSpecTile extends StatefulWidget {
  const _ExpandSpecTile({
    super.key,
    required this.name,
    required this.depth,
    required this.checkboxValue,
    required this.onToggle,
    required this.childTiles,
  });
  final String name;
  final int depth;
  final bool? checkboxValue;
  final VoidCallback onToggle;
  final List<Widget> childTiles;

  @override
  State<_ExpandSpecTile> createState() => _ExpandSpecTileState();
}

class _ExpandSpecTileState extends State<_ExpandSpecTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsetsDirectional.only(start: 16.0 * widget.depth),
      child: Column(
        children: [
          CheckboxListTile(
            value: widget.checkboxValue,
            tristate: true,
            title: Text(widget.name,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal)),
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            secondary: GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.keyboard_arrow_down_rounded,
                      size: 22, color: scheme.onSurfaceVariant),
                ),
              ),
            ),
            onChanged: (_) => widget.onToggle(),
          ),
          if (_expanded) ...widget.childTiles,
        ],
      ),
    );
  }
}
