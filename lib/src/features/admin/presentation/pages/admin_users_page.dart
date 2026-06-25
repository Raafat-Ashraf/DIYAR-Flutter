import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_client.dart';
import '../../../account/domain/entities/account_profile.dart';
import '../../../account/presentation/widgets/profile_avatar.dart';
import '../widgets/provider_type_chip.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  bool _loading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _search(String q) async {
    setState(() => _loading = true);
    try {
      final result = await getIt<ApiClient>().get<List<dynamic>>(
        ApiConstants.searchUsers,
        queryParameters: q.isNotEmpty ? {'q': q} : null,
      );
      if (mounted) {
        setState(() {
          _users = result.whereType<Map<String, dynamic>>().toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(v.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('إدارة المستخدمين')),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'بحث بالاسم أو البريد...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: scheme.surfaceContainerLowest,
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _users.isEmpty
                      ? Center(child: Text('لا توجد نتائج', style: TextStyle(color: scheme.onSurfaceVariant)))
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _users.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final u = _users[i];
                            final name = '${u['firstName'] ?? ''} ${u['lastName'] ?? ''}'.trim();
                            final email = u['email'] as String? ?? '';
                            final role = u['providerType'] as String?;
                            final imageUrl = u['imageUrl'] as String?;
                            final verStatus = u['verificationStatus'] as String?;
                            return ListTile(
                              leading: ProfileAvatar(imageUrl: imageUrl, size: 40),
                              title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (email.isNotEmpty) Text(email, style: const TextStyle(fontSize: 12)),
                                  if (verStatus != null)
                                    Text(
                                      _statusAr(verStatus),
                                      style: TextStyle(fontSize: 11, color: _statusColor(verStatus, scheme)),
                                    ),
                                ],
                              ),
                              trailing: role != null ? ProviderTypeChip(type: ProviderType.fromApi(role)) : null,
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusAr(String s) => switch (s.toLowerCase()) {
    'approved' => '✓ موافق عليه',
    'pending' => '⏳ قيد المراجعة',
    'rejected' => '✗ مرفوض',
    'notsubmitted' => 'لم يتقدم بعد',
    _ => s,
  };

  Color _statusColor(String s, ColorScheme scheme) => switch (s.toLowerCase()) {
    'approved' => const Color(0xFF16A34A),
    'pending' => const Color(0xFFF59E0B),
    'rejected' => scheme.error,
    _ => scheme.onSurfaceVariant,
  };

}
