import 'package:flutter/material.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/di/service_locator.dart';
import '../../../account/domain/entities/account_profile.dart';

enum _TargetType { all, roles, users }

class AdminBroadcastPage extends StatefulWidget {
  const AdminBroadcastPage({super.key});

  @override
  State<AdminBroadcastPage> createState() => _AdminBroadcastPageState();
}

class _AdminBroadcastPageState extends State<AdminBroadcastPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _searchController = TextEditingController();

  _TargetType _targetType = _TargetType.all;
  final Set<String> _selectedRoles = {};
  final List<_UserResult> _searchResults = [];
  final Set<String> _selectedUserIds = {};
  final Map<String, String> _selectedUserNames = {};

  bool _searching = false;
  bool _sending = false;

  static const _roles = [
    (ProviderType.client, 'عملاء'),
    (ProviderType.supplier, 'موردون'),
    (ProviderType.freelancer, 'مهندسون'),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults.clear());
      return;
    }
    setState(() => _searching = true);
    try {
      final res = await getIt<ApiClient>().get<List<dynamic>>(
        ApiConstants.searchUsers,
        queryParameters: {'q': query.trim()},
      );
      final results = res.whereType<Map<String, dynamic>>()
          .map((j) => _UserResult(
                id: j['id']?.toString() ?? '',
                name: '${j['firstName'] ?? ''} ${j['lastName'] ?? ''}'.trim(),
              ))
          .where((u) => u.id.isNotEmpty)
          .toList();
      setState(() => _searchResults
        ..clear()
        ..addAll(results));
    } catch (_) {}
    setState(() => _searching = false);
  }

  Future<void> _send() async {
    if (_titleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty) {
      _showSnack('الرجاء ملء العنوان والمحتوى');
      return;
    }

    if (_targetType == _TargetType.roles && _selectedRoles.isEmpty) {
      _showSnack('اختر دوراً واحداً على الأقل');
      return;
    }
    if (_targetType == _TargetType.users && _selectedUserIds.isEmpty) {
      _showSnack('اختر مستخدماً واحداً على الأقل');
      return;
    }

    setState(() => _sending = true);
    try {
      final body = <String, dynamic>{
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
      };
      if (_targetType == _TargetType.roles) {
        body['targetRoles'] = _selectedRoles.toList();
      } else if (_targetType == _TargetType.users) {
        body['targetUserIds'] = _selectedUserIds.toList();
      }

      final res = await getIt<ApiClient>().post<Map<String, dynamic>>(
        ApiConstants.broadcastNotification,
        data: body,
      );
      final count = res['sent'] as int? ?? 0;
      if (mounted) {
        _showSnack('تم الإرسال بنجاح إلى $count مستخدم');
        _titleController.clear();
        _contentController.clear();
        setState(() {
          _selectedRoles.clear();
          _selectedUserIds.clear();
          _selectedUserNames.clear();
          _searchResults.clear();
          _targetType = _TargetType.all;
        });
      }
    } catch (_) {
      if (mounted) _showSnack('حدث خطأ، حاول مرة أخرى');
    }
    setState(() => _sending = false);
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('إرسال إشعار')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Title ──────────────────────────────────────────
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'عنوان الإشعار *',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
              ),
              const SizedBox(height: 12),

              // ── Content ────────────────────────────────────────
              TextField(
                controller: _contentController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'محتوى الإشعار *',
                  prefixIcon: Icon(Icons.message_outlined),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),

              // ── Target type ────────────────────────────────────
              Text('الجمهور المستهدف',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              _TargetChip(
                label: 'الكل',
                icon: Icons.people_alt_rounded,
                selected: _targetType == _TargetType.all,
                onTap: () => setState(() => _targetType = _TargetType.all),
              ),
              const SizedBox(height: 6),
              _TargetChip(
                label: 'دور محدد',
                icon: Icons.badge_outlined,
                selected: _targetType == _TargetType.roles,
                onTap: () => setState(() => _targetType = _TargetType.roles),
              ),
              const SizedBox(height: 6),
              _TargetChip(
                label: 'مستخدمون محددون',
                icon: Icons.person_search_rounded,
                selected: _targetType == _TargetType.users,
                onTap: () => setState(() => _targetType = _TargetType.users),
              ),

              // ── Roles ──────────────────────────────────────────
              if (_targetType == _TargetType.roles) ...[
                const SizedBox(height: 16),
                Text('اختر الأدوار',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: scheme.onSurfaceVariant)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _roles.map((r) {
                    final (type, label) = r;
                    final selected = _selectedRoles.contains(type.apiValue);
                    return FilterChip(
                      label: Text(label),
                      selected: selected,
                      onSelected: (_) => setState(() {
                        if (selected) {
                          _selectedRoles.remove(type.apiValue);
                        } else {
                          _selectedRoles.add(type.apiValue);
                        }
                      }),
                    );
                  }).toList(),
                ),
              ],

              // ── User search ────────────────────────────────────
              if (_targetType == _TargetType.users) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'ابحث باسم أو بريد إلكتروني',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searching
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                  ),
                  onChanged: _search,
                ),
                if (_searchResults.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: scheme.outlineVariant),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: _searchResults.map((u) {
                        final selected = _selectedUserIds.contains(u.id);
                        return CheckboxListTile(
                          value: selected,
                          title: Text(u.name,
                              style: const TextStyle(fontSize: 14)),
                          dense: true,
                          onChanged: (_) => setState(() {
                            if (selected) {
                              _selectedUserIds.remove(u.id);
                              _selectedUserNames.remove(u.id);
                            } else {
                              _selectedUserIds.add(u.id);
                              _selectedUserNames[u.id] = u.name;
                            }
                          }),
                        );
                      }).toList(),
                    ),
                  ),
                ],
                if (_selectedUserIds.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: _selectedUserIds.map((id) {
                      final name = _selectedUserNames[id] ?? id;
                      return Chip(
                        label: Text(name, style: const TextStyle(fontSize: 12)),
                        onDeleted: () => setState(() {
                          _selectedUserIds.remove(id);
                          _selectedUserNames.remove(id);
                        }),
                      );
                    }).toList(),
                  ),
                ],
              ],

              // ── Send button ────────────────────────────────────
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _sending ? null : _send,
                icon: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded),
                label: const Text('إرسال الإشعار'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TargetChip extends StatelessWidget {
  const _TargetChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
          color: selected ? scheme.primary.withValues(alpha: .08) : null,
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color: selected ? scheme.primary : scheme.onSurfaceVariant),
            const SizedBox(width: 10),
            Text(label,
                style: TextStyle(
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? scheme.primary : scheme.onSurface,
                )),
            if (selected) ...[
              const Spacer(),
              Icon(Icons.check_circle_rounded,
                  size: 18, color: scheme.primary),
            ],
          ],
        ),
      ),
    );
  }
}

class _UserResult {
  const _UserResult({required this.id, required this.name});
  final String id;
  final String name;
}
