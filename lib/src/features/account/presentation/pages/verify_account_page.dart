import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/platform/native_document_picker.dart';
import '../../../auth/presentation/widgets/auth_text_field.dart';
import '../../../auth/presentation/widgets/loading_button.dart';
import '../../../specializations/domain/entities/specialization.dart';
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
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _yearsController = TextEditingController();
  final _documents = <String, VerificationDocument>{};

  int? _governorateId;
  bool _worksInAllEgypt = false;
  final Set<int> _selectedCityIds = {};
  final Map<int, List<City>> _governorateCitiesCache = {};
  final Set<int> _loadingGovernorateIds = {};
  final Set<int> _selectedSpecializationIds = {};
  int _stepIndex = 0;
  final _scrollController = ScrollController();

  bool get _isClient => widget.providerType == ProviderType.client;
  bool get _isSupplier => widget.providerType == ProviderType.supplier;
  bool get _isEngineer => widget.providerType == ProviderType.freelancer;

  bool get _needsCities => _isSupplier || _isEngineer;
  bool get _needsDocuments => !_isClient;
  bool get _needsSpecializations => _isSupplier || _isEngineer;

  SpecializationType get _specializationType => _isSupplier
      ? SpecializationType.product
      : SpecializationType.engineeringService;

  late final List<String> _steps = [
    'details',
    if (_needsSpecializations) 'specializations',
    if (_needsCities) 'cities',
    if (_needsDocuments) 'documents',
    'review',
  ];

  int get _totalSteps => _steps.length;
  bool get _isLastStep => _stepIndex == _totalSteps - 1;
  String get _currentStepKey => _steps[_stepIndex];

  @override
  void initState() {
    super.initState();
    context.read<AccountCubit>().loadGovernorates();
    if (_needsSpecializations) {
      context.read<AccountCubit>().loadSpecializations(_specializationType);
    }
    _prefillIfRejected();
  }

  void _prefillIfRejected() {
    final profile = context.read<AccountCubit>().state.profile;
    if (profile == null || profile.verificationStatus != VerificationStatus.rejected) return;

    _phoneController.text = profile.phoneNumber ?? '';
    _bioController.text = profile.bio ?? '';
    _companyNameController.text = profile.companyName ?? '';
    _yearsController.text = profile.yearsOfExperience?.toString() ?? '';
    _governorateId = profile.governorate?.id;
    _selectedCityIds.addAll(profile.cityIds);
    _selectedSpecializationIds.addAll(profile.specializationIds);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _bioController.dispose();
    _companyNameController.dispose();
    _yearsController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
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
        appBar: AppBar(
          title: Text('تحقق ${widget.providerType.arabicName}'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () => context.go(AppRoutes.roleSelection),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: BlocBuilder<AccountCubit, AccountState>(
                builder: (context, state) {
                  return Form(
                    key: _formKey,
                    child: ListView(
                      controller: _scrollController,
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
                                      : () { setState(() => _stepIndex -= 1); _scrollToTop(); },
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
    switch (_currentStepKey) {
      case 'details':
        return 'بيانات الحساب';
      case 'specializations':
        return 'تخصصاتك';
      case 'cities':
        return 'المحافظات والمدن التي تعمل بها';
      case 'documents':
        return 'المستندات';
      default:
        return 'مراجعة وإرسال';
    }
  }

  Widget _currentStep(AccountState state) {
    switch (_currentStepKey) {
      case 'details':
        return _detailsStep(state);
      case 'specializations':
        return _specializationsStep(state);
      case 'cities':
        return _citiesStep(state);
      case 'documents':
        return _documentsStep();
      default:
        return _reviewStep(state);
    }
  }

  Widget _detailsStep(AccountState state) {
    return Column(
      key: const ValueKey('details'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthTextField(
          controller: _phoneController,
          label: 'رقم الهاتف',
          keyboardType: TextInputType.phone,
          prefixIcon: Icons.phone_outlined,
          validator: _phoneNumber,
          textInputAction: TextInputAction.next,
        ),
        if (_isClient) ...[
          const SizedBox(height: 16),
          _governorateDropdown(state),
        ],
        if (_isEngineer) ...[
          const SizedBox(height: 16),
          AuthTextField(
            controller: _bioController,
            label: 'نبذة مختصرة (اختياري)',
            prefixIcon: Icons.notes_outlined,
            validator: _bio,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _yearsController,
            label: 'سنوات الخبرة *',
            keyboardType: TextInputType.number,
            prefixIcon: Icons.timeline_outlined,
            validator: _years,
          ),
        ],
        if (_isSupplier) ...[
          const SizedBox(height: 16),
          AuthTextField(
            controller: _companyNameController,
            label: 'اسم الشركة',
            prefixIcon: Icons.business_outlined,
            validator: _companyName,
          ),
        ],
      ],
    );
  }

  Widget _governorateDropdown(AccountState state) {
    return DropdownButtonFormField<int>(
      initialValue: _governorateId,
      isExpanded: true,
      menuMaxHeight: 280,
      borderRadius: BorderRadius.circular(12),
      icon: const Icon(Icons.expand_more_rounded),
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: const InputDecoration(
        labelText: 'المحافظة',
        prefixIcon: Icon(Icons.location_on_outlined),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      items: state.governorates
          .map(
            (item) => DropdownMenuItem(
              value: item.id,
              child: Text(item.name, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (value) => setState(() => _governorateId = value),
      validator: (value) => value == null ? 'اختر المحافظة.' : null,
    );
  }

  Widget _citiesStep(AccountState state) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      key: const ValueKey('cities'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Toggle: يعمل في مصر كلها
        SwitchListTile(
          value: _worksInAllEgypt,
          onChanged: (v) => setState(() {
            _worksInAllEgypt = v;
            if (v) _selectedCityIds.clear();
          }),
          title: const Text('يعمل في مصر كلها',
              style: TextStyle(fontWeight: FontWeight.w700)),
          subtitle: const Text('لن تحتاج لاختيار مدن محددة'),
          contentPadding: EdgeInsets.zero,
        ),
        if (!_worksInAllEgypt) ...[
        Text(
          'يمكنك اختيار محافظة كاملة بجميع مدنها، أو فتح المحافظة واختيار مدن معينة منها. يمكن اختيار مدن من أكثر من محافظة.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        if (_selectedCityIds.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'تم اختيار ${_selectedCityIds.length} مدينة.',
              style: TextStyle(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        if (state.governorates.isEmpty)
          Text(
            'تعذر تحميل المحافظات.',
            style: TextStyle(color: scheme.onSurfaceVariant),
          )
        else
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: Column(
                children: state.governorates
                    .map(_governorateTile)
                    .toList(),
              ),
            ),
          ),
        ], // end if (!_worksInAllEgypt)
      ],
    );
  }

  Widget _governorateTile(Governorate governorate) {
    final cities = _governorateCitiesCache[governorate.id];
    final isLoading = _loadingGovernorateIds.contains(governorate.id);

    bool? checkboxValue = false;
    if (cities != null && cities.isNotEmpty) {
      final selectedCount = cities
          .where((city) => _selectedCityIds.contains(city.id))
          .length;
      if (selectedCount == cities.length) {
        checkboxValue = true;
      } else if (selectedCount > 0) {
        checkboxValue = null;
      }
    }

    return ExpansionTile(
      key: PageStorageKey('governorate-${governorate.id}'),
      leading: isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: Padding(
                padding: EdgeInsets.all(2),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : Checkbox(
              value: checkboxValue,
              tristate: true,
              onChanged: (_) => _toggleGovernorateSelection(governorate),
            ),
      title: Text(
        governorate.name,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      onExpansionChanged: (expanded) {
        if (expanded) _ensureCitiesLoaded(governorate.id);
      },
      children: isLoading
          ? const [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
            ]
          : cities == null
          ? const []
          : cities.isEmpty
          ? const [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('لا توجد مدن متاحة لهذه المحافظة.'),
              ),
            ]
          : cities
                .map(
                  (city) => CheckboxListTile(
                    value: _selectedCityIds.contains(city.id),
                    title: Text(city.name),
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                    onChanged: (checked) => setState(() {
                      if (checked ?? false) {
                        _selectedCityIds.add(city.id);
                      } else {
                        _selectedCityIds.remove(city.id);
                      }
                    }),
                  ),
                )
                .toList(),
    );
  }

  Future<void> _ensureCitiesLoaded(int governorateId) async {
    if (_governorateCitiesCache.containsKey(governorateId) ||
        _loadingGovernorateIds.contains(governorateId)) {
      return;
    }
    setState(() => _loadingGovernorateIds.add(governorateId));
    try {
      final result = await context.read<AccountCubit>().getGovernorateCities(
        governorateId,
      );
      if (!mounted) return;
      setState(() {
        _governorateCitiesCache[governorateId] = result.cities;
        _loadingGovernorateIds.remove(governorateId);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingGovernorateIds.remove(governorateId));
      _showMessage('تعذر تحميل المدن. حاول مرة أخرى.');
    }
  }

  Future<void> _toggleGovernorateSelection(Governorate governorate) async {
    await _ensureCitiesLoaded(governorate.id);
    final cities = _governorateCitiesCache[governorate.id];
    if (cities == null || cities.isEmpty) return;

    final allSelected = cities.every(
      (city) => _selectedCityIds.contains(city.id),
    );
    setState(() {
      for (final city in cities) {
        if (allSelected) {
          _selectedCityIds.remove(city.id);
        } else {
          _selectedCityIds.add(city.id);
        }
      }
    });
  }

  int? _primaryGovernorateId() {
    for (final entry in _governorateCitiesCache.entries) {
      if (entry.value.any((city) => _selectedCityIds.contains(city.id))) {
        return entry.key;
      }
    }
    return null;
  }

  String? _governorateName(AccountState state) {
    for (final governorate in state.governorates) {
      if (governorate.id == _governorateId) return governorate.name;
    }
    return null;
  }

  String _selectedGovernorateNames(AccountState state) {
    final names = <String>[];
    for (final governorate in state.governorates) {
      final cities = _governorateCitiesCache[governorate.id];
      if (cities != null &&
          cities.any((city) => _selectedCityIds.contains(city.id))) {
        names.add(governorate.name);
      }
    }
    return names.isEmpty ? '-' : names.join('، ');
  }

  Widget _specializationsStep(AccountState state) {
    final scheme = Theme.of(context).colorScheme;
    final items = state.specializations.where((item) => !item.isDeleted).toList();
    return Column(
      key: const ValueKey('specializations'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'اختر التخصصات التي تعمل بها. اختيار تخصص رئيسي يحدد جميع التخصصات الفرعية التابعة له.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        if (_selectedSpecializationIds.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'تم اختيار ${_selectedSpecializationIds.length} تخصص.',
              style: TextStyle(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        if (items.isEmpty)
          Text(
            'تعذر تحميل التخصصات.',
            style: TextStyle(color: scheme.onSurfaceVariant),
          )
        else
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: Column(
                children: items.map((item) => _specializationTile(item)).toList(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _specializationTile(Specialization node, {int depth = 0}) {
    final children = node.children.where((item) => !item.isDeleted).toList();

    if (children.isEmpty) {
      // Leaf — identical tile, no expand arrow
      return Padding(
        padding: EdgeInsetsDirectional.only(start: 16.0 * depth),
        child: CheckboxListTile(
          value: _selectedSpecializationIds.contains(node.id),
          title: Text(node.name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal)),
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          onChanged: (_) => _toggleSpecialization(node),
        ),
      );
    }

    // Parent — same tile style + expand arrow
    return _ExpandSpecTile(
      key: PageStorageKey('spec-${node.id}'),
      name: node.name,
      depth: depth,
      checkboxValue: _checkboxValue(node),
      onToggle: () => _toggleSpecialization(node),
      childTiles: children
          .map((child) => _specializationTile(child, depth: depth + 1))
          .toList(),
    );
  }

  Set<int> _allIds(Specialization node) {
    final ids = <int>{node.id};
    for (final child in node.children) {
      if (child.isDeleted) continue;
      ids.addAll(_allIds(child));
    }
    return ids;
  }

  bool? _checkboxValue(Specialization node) {
    final ids = _allIds(node);
    final selectedCount = ids.where(_selectedSpecializationIds.contains).length;
    if (selectedCount == 0) return false;
    if (selectedCount == ids.length) return true;
    return null;
  }

  void _toggleSpecialization(Specialization node) {
    final ids = _allIds(node);
    final allSelected = ids.every(_selectedSpecializationIds.contains);
    setState(() {
      if (allSelected) {
        _selectedSpecializationIds.removeAll(ids);
      } else {
        _selectedSpecializationIds.addAll(ids);
      }
    });
  }

  Widget _documentsStep() {
    final documentNames = _isSupplier
        ? const ['National Id', 'Tax Card', 'Commercial Register']
        : const ['National Id', 'Syndicate ID', 'Qualification'];
    final arabicNames = <String, String>{
      'National Id': 'البطاقة الشخصية',
      'Tax Card': 'البطاقة الضريبية',
      'Commercial Register': 'السجل التجاري',
      'Syndicate ID': 'كارنيه النقابة',
      'Qualification': 'المؤهل',
    };

    return Column(
      key: const ValueKey('documents'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _isSupplier
              ? 'المورد يجب أن يرفع البطاقة الشخصية والبطاقة الضريبية والسجل التجاري.'
              : 'المهندس يجب أن يرفع البطاقة الشخصية وكارنيه النقابة والمؤهل.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        ...documentNames.map(
          (name) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _DocumentTile(
              title: arabicNames[name] ?? name,
              document: _documents[name],
              required: true,
              onPick: () => _pickDocument(name),
              onRemove: () => setState(() => _documents.remove(name)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _reviewStep(AccountState state) {
    return Column(
      key: const ValueKey('review'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ReviewRow(label: 'نوع الحساب', value: widget.providerType.arabicName),
        _ReviewRow(label: 'رقم الهاتف', value: _phoneController.text.trim()),
        if (_isClient) ...[
          _ReviewRow(
            label: 'المحافظة',
            value: _governorateName(state) ?? '-',
          ),
        ],
        if (_needsSpecializations) ...[
          _ReviewRow(
            label: 'التخصصات',
            value: '${_selectedSpecializationIds.length} تخصص',
          ),
        ],
        if (_needsCities) ...[
          _ReviewRow(
            label: 'المحافظات',
            value: _selectedGovernorateNames(state),
          ),
          _ReviewRow(
            label: 'المدن',
            value: '${_selectedCityIds.length} مدينة',
          ),
        ],
        if (_isEngineer && _bioController.text.trim().isNotEmpty)
          _ReviewRow(label: 'النبذة', value: _bioController.text.trim()),
        if (_isSupplier && _companyNameController.text.trim().isNotEmpty)
          _ReviewRow(
            label: 'الشركة',
            value: _companyNameController.text.trim(),
          ),
        if (_isEngineer && _yearsController.text.trim().isNotEmpty)
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
    if (_currentStepKey == 'specializations' &&
        !_specializationsValid(showMessage: true)) {
      return;
    }
    if (_currentStepKey == 'cities' && !_citiesValid(showMessage: true)) {
      return;
    }
    if (_currentStepKey == 'documents' &&
        !_documentsValid(showMessage: true)) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _stepIndex += 1);
    _scrollToTop();
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
    if (!_specializationsValid(showMessage: true)) return;
    if (!_citiesValid(showMessage: true)) return;
    if (!_documentsValid(showMessage: true)) return;

    context.read<AccountCubit>().submitVerification(
      VerifyAccountInput(
        providerType: widget.providerType,
        phoneNumber: _phoneController.text.trim(),
        governorateId: _isClient ? _governorateId : _primaryGovernorateId(),
        bio: _isEngineer ? _bioController.text : null,
        companyName: _isSupplier ? _companyNameController.text : null,
        yearsOfExperience: _isEngineer
            ? int.tryParse(_yearsController.text.trim())
            : null,
        worksInAllEgypt: _needsCities && _worksInAllEgypt,
        cities: (_needsCities && !_worksInAllEgypt) ? _selectedCityIds.toList() : const [],
        specializations: _needsSpecializations
            ? _selectedSpecializationIds.toList()
            : const [],
        documents: _documents.values.toList(),
      ),
    );
  }

  bool _specializationsValid({required bool showMessage}) {
    if (!_needsSpecializations) return true;
    if (_selectedSpecializationIds.isEmpty) {
      if (showMessage) {
        _showMessage('اختر تخصصًا واحدًا على الأقل.');
      }
      return false;
    }
    return true;
  }

  bool _citiesValid({required bool showMessage}) {
    if (!_needsCities) return true;
    if (_worksInAllEgypt) return true;
    if (_selectedCityIds.isEmpty) {
      if (showMessage) {
        _showMessage('اختر مدينة واحدة على الأقل أو فعّل "يعمل في مصر كلها".');
      }
      return false;
    }
    return true;
  }

  bool _documentsValid({required bool showMessage}) {
    if (_isClient) return true;
    final required = _isSupplier
        ? const ['National Id', 'Tax Card', 'Commercial Register']
        : const ['National Id', 'Syndicate ID', 'Qualification'];
    final valid = required.every(_documents.containsKey);
    if (!valid && showMessage) {
      _showMessage(
        _isSupplier
            ? 'يجب رفع البطاقة الشخصية والبطاقة الضريبية والسجل التجاري.'
            : 'يجب رفع البطاقة الشخصية وكارنيه النقابة والمؤهل.',
      );
    }
    return valid;
  }

  bool _isAllowedContentType(String contentType) {
    if (contentType.startsWith('image/')) return true;
    return const {'application/pdf'}.contains(contentType);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String? _phoneNumber(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'رقم الهاتف مطلوب.';
    if (!RegExp(r'^[0-9+]{8,15}$').hasMatch(text)) {
      return 'أدخل رقم هاتف صحيح.';
    }
    return null;
  }

  String? _bio(String? value) {
    final text = value?.trim() ?? '';
    // Bio is optional for engineers
    if (text.length > 500) return 'النبذة لا يجب أن تتجاوز 500 حرف.';
    return null;
  }

  String? _companyName(String? value) {
    final text = value?.trim() ?? '';
    if (text.length > 150) return 'اسم الشركة لا يجب أن يتجاوز 150 حرفًا.';
    return null;
  }

  String? _years(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'سنوات الخبرة مطلوبة.';
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

// ── Expandable parent specialization tile ─────────────────────────────────────

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
            title: Text(
              widget.name,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.normal),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            secondary: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 22,
                    color: scheme.onSurfaceVariant,
                  ),
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
