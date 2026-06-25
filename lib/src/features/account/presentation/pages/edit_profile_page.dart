import 'dart:io';

import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/platform/native_document_picker.dart';
import '../../../auth/presentation/widgets/auth_text_field.dart';
import '../../../auth/presentation/widgets/loading_button.dart';
import '../../../specializations/domain/entities/specialization.dart';
import '../../domain/entities/account_profile.dart';
import '../cubit/account_cubit.dart';
import '../widgets/profile_avatar.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  @override
  Widget build(BuildContext context) {
    final profile = getIt<AccountCubit>().state.profile;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('تعديل الملف الشخصي')),
        body: _BasicInfoTab(profile: profile),
      ),
    );
  }
}

// ── Basic Info Tab ────────────────────────────────────────────────────────────

class _BasicInfoTab extends StatefulWidget {
  const _BasicInfoTab({required this.profile});
  final AccountProfile? profile;

  @override
  State<_BasicInfoTab> createState() => _BasicInfoTabState();
}

class _BasicInfoTabState extends State<_BasicInfoTab>
    with AutomaticKeepAliveClientMixin {
  final _firstNameC = TextEditingController();
  final _lastNameC = TextEditingController();
  final _phoneC = TextEditingController();
  final _bioC = TextEditingController();
  final _companyC = TextEditingController();
  final _yearsC = TextEditingController();

  int? _governorateId;
  String? _imagePath;
  bool _saving = false;
  List<Governorate> _governorates = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    if (p != null) {
      _firstNameC.text = p.firstName;
      _lastNameC.text = p.lastName;
      _phoneC.text = p.phoneNumber ?? '';
      _bioC.text = p.bio ?? '';
      _companyC.text = p.companyName ?? '';
      _yearsC.text = p.yearsOfExperience?.toString() ?? '';
      _governorateId = p.governorate?.id;
    }
    _loadGovernorates();
  }

  Future<void> _loadGovernorates() async {
    await context.read<AccountCubit>().loadGovernorates();
    if (mounted)
      setState(
          () => _governorates = context.read<AccountCubit>().state.governorates);
  }

  Future<void> _pickImage() async {
    try {
      final picked = await const NativeDocumentPicker().pickDocument();
      if (picked == null) return;
      if (!picked.contentType.startsWith('image/')) {
        _snack('اختر صورة فقط (JPG أو PNG)');
        return;
      }
      setState(() => _imagePath = picked.path);
    } catch (_) {
      _snack('تعذر اختيار الصورة');
    }
  }

  Future<void> _save() async {
    if (_phoneC.text.trim().isNotEmpty) {
      final phone = _phoneC.text.trim();
      if (!RegExp(r'^(010|011|012|015)\d{8}$').hasMatch(phone)) {
        _snack('رقم الهاتف يجب أن يبدأ بـ 010/011/012/015 ويكون 11 رقماً');
        return;
      }
    }
    setState(() => _saving = true);
    try {
      final formData = dio.FormData();
      if (_firstNameC.text.trim().isNotEmpty)
        formData.fields.add(MapEntry('FirstName', _firstNameC.text.trim()));
      if (_lastNameC.text.trim().isNotEmpty)
        formData.fields.add(MapEntry('LastName', _lastNameC.text.trim()));
      if (_phoneC.text.trim().isNotEmpty)
        formData.fields.add(MapEntry('PhoneNumber', _phoneC.text.trim()));
      if (_governorateId != null)
        formData.fields
            .add(MapEntry('GovernorateId', _governorateId.toString()));
      formData.fields.add(MapEntry('Bio', _bioC.text));
      formData.fields.add(MapEntry('CompanyName', _companyC.text));
      if (_yearsC.text.trim().isNotEmpty)
        formData.fields
            .add(MapEntry('YearsOfExperience', _yearsC.text.trim()));
      if (_imagePath != null)
        formData.files.add(MapEntry(
          'ProfileImage',
          await dio.MultipartFile.fromFile(_imagePath!),
        ));

      await getIt<ApiClient>()
          .put<dynamic>(ApiConstants.updateProfile, data: formData);
      await context.read<AccountCubit>().loadProfile();
      if (mounted) {
        _snack('تم حفظ البيانات بنجاح ✓');
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) _snack('حدث خطأ، حاول مرة أخرى');
    }
    if (mounted) setState(() => _saving = false);
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final profile = widget.profile;
    final isEngineer = profile?.providerType == ProviderType.freelancer;
    final isSupplier = profile?.providerType == ProviderType.supplier;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Stack(
              children: [
                _imagePath != null
                    ? CircleAvatar(
                        radius: 52,
                        backgroundImage: FileImage(File(_imagePath!)))
                    : ProfileAvatar(imageUrl: profile?.imageUrl, size: 104),
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt_rounded,
                          size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: AuthTextField(
                  controller: _firstNameC,
                  label: 'الاسم الأول',
                  prefixIcon: Icons.person_outline,
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AuthTextField(
                  controller: _lastNameC,
                  label: 'الاسم الأخير',
                  prefixIcon: Icons.person_outline,
                  textInputAction: TextInputAction.next,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AuthTextField(
            controller: _phoneC,
            label: 'رقم الهاتف',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: _governorateId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'المحافظة',
              prefixIcon: Icon(Icons.location_on_outlined),
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            items: _governorates
                .map((g) => DropdownMenuItem(
                    value: g.id,
                    child:
                        Text(g.name, overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: (v) => setState(() => _governorateId = v),
          ),
          if (isEngineer) ...[
            const SizedBox(height: 12),
            AuthTextField(
              controller: _bioC,
              label: 'نبذة مختصرة',
              prefixIcon: Icons.notes_outlined,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            AuthTextField(
              controller: _yearsC,
              label: 'سنوات الخبرة',
              prefixIcon: Icons.timeline_outlined,
              keyboardType: TextInputType.number,
            ),
          ],
          if (isSupplier) ...[
            const SizedBox(height: 12),
            AuthTextField(
              controller: _companyC,
              label: 'اسم الشركة',
              prefixIcon: Icons.business_outlined,
              textInputAction: TextInputAction.next,
            ),
          ],
          const SizedBox(height: 24),
          LoadingButton(
            label: 'حفظ البيانات',
            isLoading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _firstNameC.dispose();
    _lastNameC.dispose();
    _phoneC.dispose();
    _bioC.dispose();
    _companyC.dispose();
    _yearsC.dispose();
    super.dispose();
  }
}

// ── Cities Tab ────────────────────────────────────────────────────────────────

enum _CitiesMode { allEgypt, specific }

class _CitiesTab extends StatefulWidget {
  const _CitiesTab({required this.profile});
  final AccountProfile? profile;

  @override
  State<_CitiesTab> createState() => _CitiesTabState();
}

class _CitiesTabState extends State<_CitiesTab>
    with AutomaticKeepAliveClientMixin {
  _CitiesMode _mode = _CitiesMode.specific;
  final Set<int> _selectedCityIds = {};
  final Map<int, List<City>> _citiesCache = {};
  final Set<int> _loadingGovIds = {};
  bool _saving = false;
  List<Governorate> _governorates = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _mode = (widget.profile?.worksInAllEgypt ?? false)
        ? _CitiesMode.allEgypt
        : _CitiesMode.specific;
    _selectedCityIds.addAll(widget.profile?.cityIds ?? []);
    for (final g in widget.profile?.workCities ?? []) {
      _citiesCache[g.governorateId] = g.cityIds.asMap().entries.map((e) {
        final name = e.key < g.cities.length ? g.cities[e.key] : '';
        return City(id: e.value, name: name);
      }).toList();
    }
    _load();
  }

  Future<void> _load() async {
    await context.read<AccountCubit>().loadGovernorates();
    if (mounted) {
      final govs = context.read<AccountCubit>().state.governorates;
      setState(() => _governorates = govs);
      // If still empty, force reload
      if (govs.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          setState(() =>
              _governorates = context.read<AccountCubit>().state.governorates);
        }
      }
    }
  }

  Future<void> _loadCities(int govId) async {
    if (_citiesCache.containsKey(govId) || _loadingGovIds.contains(govId))
      return;
    setState(() => _loadingGovIds.add(govId));
    try {
      final result =
          await context.read<AccountCubit>().getGovernorateCities(govId);
      if (mounted)
        setState(() {
          _citiesCache[govId] = result.cities;
          _loadingGovIds.remove(govId);
        });
    } catch (_) {
      if (mounted) setState(() => _loadingGovIds.remove(govId));
    }
  }

  void _toggleGov(Governorate gov) {
    final cities = _citiesCache[gov.id];
    if (cities == null || cities.isEmpty) return;
    final allSelected = cities.every((c) => _selectedCityIds.contains(c.id));
    setState(() {
      for (final c in cities) {
        if (allSelected) _selectedCityIds.remove(c.id);
        else _selectedCityIds.add(c.id);
      }
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await getIt<ApiClient>().put<dynamic>(
        ApiConstants.updateWorkCities,
        data: {
          'worksInAllEgypt': _mode == _CitiesMode.allEgypt,
          'cityIds': _mode == _CitiesMode.allEgypt
              ? []
              : _selectedCityIds.toList(),
        },
      );
      await context.read<AccountCubit>().loadProfile();
      if (mounted) {
        _snack('تم حفظ مدن العمل ✓');
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) _snack('حدث خطأ، حاول مرة أخرى');
    }
    if (mounted) setState(() => _saving = false);
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Mode selector ─────────────────────────────────────
          SegmentedButton<_CitiesMode>(
            segments: const [
              ButtonSegment(
                value: _CitiesMode.allEgypt,
                label: Text('جميع محافظات مصر'),
                icon: Icon(Icons.map_rounded, size: 18),
              ),
              ButtonSegment(
                value: _CitiesMode.specific,
                label: Text('تحديد المدن'),
                icon: Icon(Icons.location_on_rounded, size: 18),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() {
              _mode = s.first;
              if (_mode == _CitiesMode.allEgypt) _selectedCityIds.clear();
            }),
          ),
          const SizedBox(height: 16),

          // ── All Egypt ─────────────────────────────────────────
          if (_mode == _CitiesMode.allEgypt)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: .06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: scheme.primary.withValues(alpha: .3)),
              ),
              child: Column(
                children: [
                  Icon(Icons.public_rounded,
                      size: 48, color: scheme.primary),
                  const SizedBox(height: 12),
                  Text(
                    'يعمل في جميع محافظات مصر',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'سيظهر اسمك في جميع طلبات العملاء بغض النظر عن موقعهم',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),

          // ── Specific cities ───────────────────────────────────
          if (_mode == _CitiesMode.specific) ...[
            if (_governorates.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else Row(
              children: [
                Expanded(
                  child: Text('المدن التي تعمل بها',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                ),
                Text('${_selectedCityIds.length} مدينة',
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
                children: _governorates.map((gov) {
                  final cities = _citiesCache[gov.id];
                  final loading = _loadingGovIds.contains(gov.id);
                  bool? cb = false;
                  if (cities != null && cities.isNotEmpty) {
                    final sel = cities
                        .where((c) => _selectedCityIds.contains(c.id))
                        .length;
                    cb = sel == cities.length
                        ? true
                        : sel > 0
                            ? null
                            : false;
                  }
                  return ExpansionTile(
                    leading: loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                strokeWidth: 2))
                        : Checkbox(
                            value: cb,
                            tristate: true,
                            onChanged: (_) => _toggleGov(gov)),
                    title: Text(gov.name,
                        style:
                            const TextStyle(fontWeight: FontWeight.w700)),
                    onExpansionChanged: (e) {
                      if (e) _loadCities(gov.id);
                    },
                    children: cities == null
                        ? []
                        : cities
                            .map((c) => CheckboxListTile(
                                  value:
                                      _selectedCityIds.contains(c.id),
                                  title: Text(c.name),
                                  dense: true,
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  onChanged: (_) => setState(() {
                                    if (_selectedCityIds.contains(c.id))
                                      _selectedCityIds.remove(c.id);
                                    else
                                      _selectedCityIds.add(c.id);
                                  }),
                                ))
                            .toList(),
                  );
                }).toList(),
              ),
            ), // end else (governorates loaded)
          ],

          const SizedBox(height: 20),
          LoadingButton(
            label: 'حفظ مدن العمل',
            isLoading: _saving,
            onPressed: _save,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Specializations Tab ───────────────────────────────────────────────────────

class _SpecsTab extends StatefulWidget {
  const _SpecsTab({required this.profile});
  final AccountProfile? profile;

  @override
  State<_SpecsTab> createState() => _SpecsTabState();
}

class _SpecsTabState extends State<_SpecsTab>
    with AutomaticKeepAliveClientMixin {
  final Set<int> _selectedSpecIds = {};
  bool _saving = false;
  List<Specialization> _specs = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _selectedSpecIds.addAll(widget.profile?.specializationIds ?? []);
    _load();
  }

  Future<void> _load() async {
    final cubit = context.read<AccountCubit>();
    final providerType = widget.profile?.providerType;
    final specType = providerType == ProviderType.supplier
        ? SpecializationType.product
        : SpecializationType.engineeringService;
    await cubit.loadSpecializations(specType);
    if (mounted) setState(() => _specs = cubit.state.specializations);
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
      await context.read<AccountCubit>().loadProfile();
      if (mounted) {
        _snack('تم حفظ التخصصات ✓');
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) _snack('حدث خطأ، حاول مرة أخرى');
    }
    if (mounted) setState(() => _saving = false);
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
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
              children: _specs.where((s) => !s.isDeleted).map(_specTile).toList(),
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
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.normal)),
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
