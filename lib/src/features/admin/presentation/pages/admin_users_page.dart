import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_client.dart';
import '../../../account/domain/entities/account_profile.dart';
import '../../../account/presentation/pages/provider_profile_page.dart';
import '../../../account/presentation/widgets/profile_avatar.dart';
import '../widgets/provider_type_chip.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUserItem {
  final String id;
  final String firstName;
  final String lastName;
  final String? email;
  final String imageUrl;
  final String? phoneNumber;
  final String? providerType;
  final String verificationStatus;
  final bool isBanned;
  final String? banReason;

  const _AdminUserItem({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.email,
    required this.imageUrl,
    this.phoneNumber,
    this.providerType,
    required this.verificationStatus,
    required this.isBanned,
    this.banReason,
  });

  String get displayName => '$firstName $lastName'.trim();

  factory _AdminUserItem.fromJson(Map<String, dynamic> j) => _AdminUserItem(
        id: j['id'] as String,
        firstName: j['firstName'] as String? ?? '',
        lastName: j['lastName'] as String? ?? '',
        email: j['email'] as String?,
        imageUrl: j['imageUrl'] as String? ?? '',
        phoneNumber: j['phoneNumber'] as String?,
        providerType: j['providerType'] as String?,
        verificationStatus: j['verificationStatus'] as String? ?? 'NotSubmitted',
        isBanned: j['isBanned'] as bool? ?? false,
        banReason: j['banReason'] as String?,
      );
}

enum _SortOption {
  dateDesc('الأحدث أولاً', 'createdAt', true),
  dateAsc('الأقدم أولاً', 'createdAt', false),
  nameAsc('الاسم أ-ي', 'name', false),
  nameDesc('الاسم ي-أ', 'name', true);

  const _SortOption(this.label, this.field, this.descending);
  final String label;
  final String field;
  final bool descending;
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  Timer? _debounce;

  List<_AdminUserItem> _items = [];
  bool _loading = false;
  bool _hasMore = true;
  int _page = 1;
  static const _pageSize = 15;

  _SortOption _sort = _SortOption.dateDesc;
  String? _filterRole;       // null = all
  String? _filterStatus;     // null = all
  bool? _filterBanned;       // null = all

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _load(reset: true);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      _load();
    }
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading) return;
    if (!reset && !_hasMore) return;

    setState(() => _loading = true);
    if (reset) {
      _page = 1;
      _hasMore = true;
    }

    try {
      final params = <String, dynamic>{
        'pageNumber': _page,
        'pageSize': _pageSize,
        'sortBy': _sort.field,
        'descending': _sort.descending,
      };
      final q = _searchCtrl.text.trim();
      if (q.isNotEmpty) params['search'] = q;
      if (_filterRole != null) params['providerType'] = _filterRole;
      if (_filterStatus != null) params['verificationStatus'] = _filterStatus;
      if (_filterBanned != null) params['isBanned'] = _filterBanned;

      final result = await getIt<ApiClient>().get<Map<String, dynamic>>(
        ApiConstants.adminGetAllPaged,
        queryParameters: params,
      );

      final raw = (result['items'] as List<dynamic>?) ?? [];
      final newItems = raw.whereType<Map<String, dynamic>>().map(_AdminUserItem.fromJson).toList();
      final totalCount = (result['totalCount'] as int?) ?? 0;

      if (mounted) {
        setState(() {
          if (reset) {
            _items = newItems;
          } else {
            _items = [..._items, ...newItems];
          }
          _loading = false;
          _hasMore = _items.length < totalCount;
          _page++;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _load(reset: true));
  }

  void _applySort(_SortOption s) {
    setState(() => _sort = s);
    _load(reset: true);
  }

  void _applyRoleFilter(String? role) {
    setState(() => _filterRole = role);
    _load(reset: true);
  }

  void _applyStatusFilter(String? status) {
    setState(() => _filterStatus = status);
    _load(reset: true);
  }

  void _applyBannedFilter(bool? banned) {
    setState(() => _filterBanned = banned);
    _load(reset: true);
  }

  Future<void> _showBanDialog(_AdminUserItem user) async {
    final isBanning = !user.isBanned;
    final reasonCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isBanning ? 'حظر المستخدم' : 'رفع الحظر'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isBanning
                ? 'هل تريد حظر ${user.displayName}؟'
                : 'هل تريد رفع الحظر عن ${user.displayName}؟'),
            if (isBanning) ...[
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(
                  labelText: 'سبب الحظر (اختياري)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: isBanning ? Colors.red : Colors.green,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isBanning ? 'حظر' : 'رفع الحظر'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await getIt<ApiClient>().put<dynamic>(
        '${ApiConstants.adminBanUser}?userId=${user.id}',
        data: {
          'isBan': isBanning,
          'reason': isBanning ? (reasonCtrl.text.trim().isEmpty ? null : reasonCtrl.text.trim()) : null,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isBanning ? 'تم حظر المستخدم' : 'تم رفع الحظر'),
          backgroundColor: isBanning ? Colors.red : Colors.green,
        ));
        _load(reset: true);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _openProfile(_AdminUserItem user) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ProviderProfilePage(
        userId: user.id,
        displayName: user.displayName,
        imageUrl: user.imageUrl,
        providerType: ProviderType.fromApi(user.providerType),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إدارة المستخدمين'),
          actions: [
            PopupMenuButton<_SortOption>(
              initialValue: _sort,
              onSelected: _applySort,
              icon: const Icon(Icons.sort_rounded),
              tooltip: 'ترتيب',
              itemBuilder: (_) => _SortOption.values
                  .map((o) => PopupMenuItem(
                        value: o,
                        child: Row(
                          children: [
                            if (_sort == o) ...[
                              Icon(Icons.check_rounded, size: 18, color: scheme.primary),
                              const SizedBox(width: 8),
                            ],
                            Text(o.label),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () => _load(reset: true),
          child: CustomScrollView(
            controller: _scrollCtrl,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Search
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: _onSearch,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'بحث بالاسم أو البريد أو الهاتف...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchCtrl.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                _searchCtrl.clear();
                                _load(reset: true);
                              },
                            ),
                    ),
                  ),
                ),
              ),

              // Filters
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                  child: Row(
                    children: [
                      // Role filter
                      _FilterChip(
                        label: 'الكل',
                        selected: _filterRole == null,
                        onTap: () => _applyRoleFilter(null),
                      ),
                      const SizedBox(width: 6),
                      _FilterChip(
                        label: 'عملاء',
                        selected: _filterRole == 'Client',
                        onTap: () => _applyRoleFilter(_filterRole == 'Client' ? null : 'Client'),
                      ),
                      const SizedBox(width: 6),
                      _FilterChip(
                        label: 'موردون',
                        selected: _filterRole == 'Supplier',
                        onTap: () => _applyRoleFilter(_filterRole == 'Supplier' ? null : 'Supplier'),
                      ),
                      const SizedBox(width: 6),
                      _FilterChip(
                        label: 'مهندسون',
                        selected: _filterRole == 'Freelancer',
                        onTap: () => _applyRoleFilter(_filterRole == 'Freelancer' ? null : 'Freelancer'),
                      ),
                      const SizedBox(width: 14),
                      const VerticalDivider(width: 1, thickness: 1),
                      const SizedBox(width: 14),
                      // Status filter
                      _FilterChip(
                        label: 'قيد المراجعة',
                        selected: _filterStatus == 'Pending',
                        color: Colors.orange,
                        onTap: () => _applyStatusFilter(_filterStatus == 'Pending' ? null : 'Pending'),
                      ),
                      const SizedBox(width: 6),
                      _FilterChip(
                        label: 'موافق عليه',
                        selected: _filterStatus == 'Approved',
                        color: Colors.green,
                        onTap: () => _applyStatusFilter(_filterStatus == 'Approved' ? null : 'Approved'),
                      ),
                      const SizedBox(width: 6),
                      _FilterChip(
                        label: 'مرفوض',
                        selected: _filterStatus == 'Rejected',
                        color: Colors.red,
                        onTap: () => _applyStatusFilter(_filterStatus == 'Rejected' ? null : 'Rejected'),
                      ),
                      const SizedBox(width: 14),
                      const VerticalDivider(width: 1, thickness: 1),
                      const SizedBox(width: 14),
                      // Ban filter
                      _FilterChip(
                        label: 'محظورون',
                        selected: _filterBanned == true,
                        color: Colors.red,
                        onTap: () => _applyBannedFilter(_filterBanned == true ? null : true),
                      ),
                    ],
                  ),
                ),
              ),

              // Count hint
              if (!_loading || _items.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: Text(
                      '${_items.length} مستخدم',
                      style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                    ),
                  ),
                ),

              // List
              if (_loading && _items.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text('لا توجد نتائج', style: TextStyle(color: scheme.onSurfaceVariant)),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverList.separated(
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemCount: _items.length + (_hasMore ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (i >= _items.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return _UserCard(
                        user: _items[i],
                        onTap: () => _openProfile(_items[i]),
                        onBan: () => _showBanDialog(_items[i]),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user, required this.onTap, required this.onBan});

  final _AdminUserItem user;
  final VoidCallback onTap;
  final VoidCallback onBan;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusColor = _statusColor(user.verificationStatus);

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: user.isBanned
            ? BorderSide(color: Colors.red.shade300, width: 1.2)
            : BorderSide(color: scheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ProfileAvatar(imageUrl: user.imageUrl, size: 46),
                  if (user.isBanned)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Icon(Icons.block_rounded, size: 10, color: Colors.white),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.displayName,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                        ),
                        if (user.providerType != null)
                          ProviderTypeChip(type: ProviderType.fromApi(user.providerType)),
                      ],
                    ),
                    if (user.email != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        user.email!,
                        style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: statusColor.withValues(alpha: .4)),
                          ),
                          child: Text(
                            _statusAr(user.verificationStatus),
                            style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: onBan,
                          icon: Icon(
                            user.isBanned ? Icons.lock_open_rounded : Icons.block_rounded,
                            size: 15,
                          ),
                          label: Text(user.isBanned ? 'رفع الحظر' : 'حظر', style: const TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            foregroundColor: user.isBanned ? Colors.green : Colors.red,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                    if (user.isBanned && user.banReason != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'السبب: ${user.banReason}',
                        style: const TextStyle(fontSize: 11, color: Colors.red),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusAr(String s) => switch (s.toLowerCase()) {
        'approved' => 'موافق عليه',
        'pending' => 'قيد المراجعة',
        'rejected' => 'مرفوض',
        'notsubmitted' => 'لم يتقدم',
        _ => s,
      };

  Color _statusColor(String s) => switch (s.toLowerCase()) {
        'approved' => const Color(0xFF16A34A),
        'pending' => const Color(0xFFF59E0B),
        'rejected' => Colors.red,
        _ => Colors.grey,
      };
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? c.withValues(alpha: .15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? c : Theme.of(context).colorScheme.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: selected ? c : Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
