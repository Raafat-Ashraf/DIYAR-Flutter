import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/widgets/loading_button.dart';
import '../../domain/entities/account_profile.dart';
import '../cubit/account_cubit.dart';

enum _CitiesMode { allEgypt, specific }

class EditCitiesPage extends StatefulWidget {
  const EditCitiesPage({super.key});

  @override
  State<EditCitiesPage> createState() => _EditCitiesPageState();
}

class _EditCitiesPageState extends State<EditCitiesPage> {
  _CitiesMode _mode = _CitiesMode.specific;
  final Set<int> _selectedCityIds = {};
  final Map<int, List<City>> _citiesCache = {};
  final Set<int> _loadingGovIds = {};
  bool _saving = false;
  List<Governorate> _governorates = [];
  bool _loading = true;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    final profile = getIt<AccountCubit>().state.profile;
    _mode = (profile?.worksInAllEgypt ?? false)
        ? _CitiesMode.allEgypt
        : _CitiesMode.specific;
    _selectedCityIds.addAll(profile?.cityIds ?? []);
    for (final g in profile?.workCities ?? <WorkGovernorate>[]) {
      final cities = <City>[];
      for (int i = 0; i < g.cityIds.length; i++) {
        final name = i < g.cities.length ? g.cities[i] : '';
        cities.add(City(id: g.cityIds[i], name: name));
      }
      _citiesCache[g.governorateId] = cities;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _loadGovernorates();
    }
  }

  Future<void> _loadGovernorates() async {
    try {
      final cubit = getIt<AccountCubit>();
      if (cubit.state.governorates.isNotEmpty) {
        if (mounted) setState(() { _governorates = cubit.state.governorates; _loading = false; });
        return;
      }
      await cubit.loadGovernorates();
      if (mounted) setState(() { _governorates = cubit.state.governorates; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadCities(int govId) async {
    if (_citiesCache.containsKey(govId) || _loadingGovIds.contains(govId))
      return;
    setState(() => _loadingGovIds.add(govId));
    try {
      final result =
          await getIt<AccountCubit>().getGovernorateCities(govId);
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
          'cityIds': _mode == _CitiesMode.allEgypt ? [] : _selectedCityIds.toList(),
        },
      );
      await getIt<AccountCubit>().loadProfile();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تم حفظ مدن العمل ✓')));
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('حدث خطأ، حاول مرة أخرى')));
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('تعديل مدن العمل')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                    if (_mode == _CitiesMode.allEgypt)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: .06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: scheme.primary.withValues(alpha: .3)),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.public_rounded, size: 48, color: scheme.primary),
                            const SizedBox(height: 12),
                            Text('يعمل في جميع محافظات مصر',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: scheme.primary)),
                            const SizedBox(height: 6),
                            Text(
                              'سيظهر اسمك في جميع طلبات العملاء',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      Row(
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
                              cb = sel == cities.length ? true : sel > 0 ? null : false;
                            }
                            return ExpansionTile(
                              leading: loading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2))
                                  : Checkbox(
                                      value: cb,
                                      tristate: true,
                                      onChanged: (_) => _toggleGov(gov)),
                              title: Text(gov.name,
                                  style: const TextStyle(fontWeight: FontWeight.w700)),
                              onExpansionChanged: (e) {
                                if (e) _loadCities(gov.id);
                              },
                              children: cities == null
                                  ? []
                                  : cities
                                      .map((c) => CheckboxListTile(
                                            value: _selectedCityIds.contains(c.id),
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
                      ),
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
              ),
      ),
    );
  }
}
