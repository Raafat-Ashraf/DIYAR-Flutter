import 'package:flutter/material.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_client.dart';
import '../../../account/domain/entities/account_profile.dart';
import '../../../account/presentation/widgets/profile_avatar.dart';
import '../widgets/provider_type_chip.dart';
import '../widgets/verification_status_badge.dart';
import 'pdf_viewer_page.dart';

class AdminUserDetailsPage extends StatefulWidget {
  const AdminUserDetailsPage({
    super.key,
    required this.userId,
    required this.displayName,
    required this.imageUrl,
  });

  final String userId;
  final String displayName;
  final String imageUrl;

  @override
  State<AdminUserDetailsPage> createState() => _AdminUserDetailsPageState();
}

class _AdminUserDetailsPageState extends State<AdminUserDetailsPage> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await getIt<ApiClient>()
          .get<Map<String, dynamic>>('${ApiConstants.adminGetUserDetails}/${widget.userId}');
      if (mounted) setState(() { _data = result; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = 'تعذر تحميل البيانات'; });
    }
  }

  Future<void> _showBanDialog() async {
    final d = _data!;
    final isBanned = d['isBanned'] as bool? ?? false;
    final isBanning = !isBanned;
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
                ? 'هل تريد حظر ${widget.displayName}؟'
                : 'هل تريد رفع الحظر عن ${widget.displayName}؟'),
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
        '${ApiConstants.adminBanUser}?userId=${widget.userId}',
        data: {
          'isBan': isBanning,
          'reason': isBanning
              ? (reasonCtrl.text.trim().isEmpty ? null : reasonCtrl.text.trim())
              : null,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isBanning ? 'تم حظر المستخدم' : 'تم رفع الحظر'),
          backgroundColor: isBanning ? Colors.red : Colors.green,
        ));
        _load();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final d = _data;

    final isBanned = d?['isBanned'] as bool? ?? false;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: scheme.surfaceContainerLowest,
        appBar: AppBar(
          title: Text(widget.displayName),
          actions: [
            if (d != null)
              TextButton.icon(
                onPressed: _showBanDialog,
                icon: Icon(
                  isBanned ? Icons.lock_open_rounded : Icons.block_rounded,
                  size: 18,
                ),
                label: Text(isBanned ? 'رفع الحظر' : 'حظر'),
                style: TextButton.styleFrom(
                  foregroundColor: isBanned ? Colors.green : Colors.red,
                ),
              ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: _buildContent(d!, scheme, theme),
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }

  List<Widget> _buildContent(
      Map<String, dynamic> d, ColorScheme scheme, ThemeData theme) {
    final firstName = d['firstName'] as String? ?? '';
    final lastName = d['lastName'] as String? ?? '';
    final displayName = '$firstName $lastName'.trim();
    final email = d['email'] as String?;
    final phone = d['phoneNumber'] as String?;
    final imageUrl = d['imageUrl'] as String? ?? widget.imageUrl;
    final providerType = ProviderType.fromApi(d['providerType'] as String?);
    final bio = (d['bio'] as String?)?.trim();
    final companyName = (d['companyName'] as String?)?.trim();
    final yearsOfExp = d['yearsOfExperience'] as int?;
    final govJson = d['governorate'];
    final governorateName = govJson is Map ? govJson['name'] as String? : null;
    final verStatus = VerificationStatus.fromApi(d['verificationStatus'] as String?);
    final rejectionReason = d['rejectionReason'] as String?;
    final isBanned = d['isBanned'] as bool? ?? false;
    final banReason = d['banReason'] as String?;
    final worksInAllEgypt = d['worksInAllEgypt'] as bool? ?? false;
    final createdAt = DateTime.tryParse((d['createdAt'] ?? '').toString());
    final roles = (d['roles'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final documents = (d['officialDocuments'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .toList() ??
        [];
    final specs = (d['specializations'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .toList() ??
        [];
    final cities = (d['workCities'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .toList() ??
        [];

    return [
      // ── Header ──
      _buildHeader(
        scheme: scheme,
        theme: theme,
        displayName: displayName,
        imageUrl: imageUrl,
        providerType: providerType,
        verStatus: verStatus,
        isBanned: isBanned,
        governorateName: governorateName,
      ),
      const SizedBox(height: 14),

      // ── Ban card ──
      if (isBanned) ...[
        _BanCard(reason: banReason, onUnban: _showBanDialog),
        const SizedBox(height: 14),
      ],

      // ── Account info ──
      _InfoCard(
        title: 'بيانات الحساب',
        icon: Icons.badge_outlined,
        rows: [
          if (email != null) _InfoRow('البريد الإلكتروني', email),
          if (phone != null) _InfoRow('رقم الهاتف', phone),
          if (governorateName != null) _InfoRow('المحافظة', governorateName),
          if (createdAt != null) _InfoRow('تاريخ الانضمام', _fmt(createdAt)),
          if (roles.isNotEmpty) _InfoRow('الأدوار', roles.join(', ')),
        ],
      ),
      const SizedBox(height: 14),

      // ── Verification ──
      _InfoCard(
        title: 'حالة التحقق',
        icon: Icons.verified_user_rounded,
        rows: [
          _InfoRow(
            'الحالة',
            _verAr(verStatus),
            color: _verColor(verStatus),
          ),
          if (rejectionReason != null && rejectionReason.isNotEmpty)
            _InfoRow('سبب الرفض', rejectionReason),
        ],
      ),

      // ── Bio ──
      if (bio != null && bio.isNotEmpty) ...[
        const SizedBox(height: 14),
        _InfoCard(
          title: 'نبذة مختصرة',
          icon: Icons.notes_rounded,
          rows: [_InfoRow('', bio)],
        ),
      ],

      // ── Professional ──
      if ((companyName != null && companyName.isNotEmpty) || yearsOfExp != null) ...[
        const SizedBox(height: 14),
        _InfoCard(
          title: 'البيانات المهنية',
          icon: Icons.business_center_rounded,
          rows: [
            if (companyName != null && companyName.isNotEmpty)
              _InfoRow('الشركة', companyName),
            if (yearsOfExp != null) _InfoRow('سنوات الخبرة', '$yearsOfExp سنة'),
          ],
        ),
      ],

      // ── Work cities ──
      if (providerType == ProviderType.supplier ||
          providerType == ProviderType.freelancer) ...[
        const SizedBox(height: 14),
        _ExpandableCard(
          title: 'مدن العمل',
          icon: Icons.location_city_rounded,
          child: worksInAllEgypt
              ? ListTile(
                  leading: Icon(Icons.public_rounded, color: Theme.of(context).colorScheme.primary),
                  title: const Text('يعمل في جميع محافظات مصر',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                )
              : cities.isEmpty
                  ? _emptyHint('لم يتم تحديد مدن العمل')
                  : Column(
                      children: cities.map((g) {
                        final name = g['governorateName'] as String? ?? '';
                        final cityList = (g['cities'] as List?)
                                ?.map((e) => e.toString())
                                .toList() ??
                            [];
                        return ExpansionTile(
                          leading: Icon(Icons.location_on_rounded,
                              color: Theme.of(context).colorScheme.primary),
                          title: Text(name,
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text('${cityList.length} مدينة',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          children: cityList
                              .map((c) => ListTile(
                                    dense: true,
                                    leading: const Icon(Icons.circle, size: 8),
                                    title: Text(c,
                                        style: const TextStyle(fontSize: 14)),
                                    contentPadding:
                                        const EdgeInsets.only(right: 32, left: 16),
                                  ))
                              .toList(),
                        );
                      }).toList(),
                    ),
        ),

        // ── Specializations ──
        const SizedBox(height: 14),
        _ExpandableCard(
          title: 'التخصصات',
          icon: Icons.workspace_premium_rounded,
          child: specs.isEmpty
              ? _emptyHint('لم يتم تحديد التخصصات')
              : Column(
                  children: specs.map((g) {
                    final parent = g['parentName'] as String? ?? '';
                    final children = (g['children'] as List?)
                            ?.map((e) => e.toString())
                            .toList() ??
                        [];
                    if (children.isEmpty) {
                      return ListTile(
                        leading: Icon(Icons.check_circle_outline_rounded,
                            color: Theme.of(context).colorScheme.primary, size: 20),
                        title: Text(parent,
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        dense: true,
                      );
                    }
                    return ExpansionTile(
                      leading: Icon(Icons.workspace_premium_rounded,
                          color: Theme.of(context).colorScheme.primary, size: 20),
                      title: Text(parent,
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      childrenPadding: const EdgeInsetsDirectional.only(start: 16),
                      children: children
                          .map((c) => ListTile(
                                dense: true,
                                leading: Icon(Icons.subdirectory_arrow_right_rounded,
                                    size: 14,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                                title: Text(c, style: const TextStyle(fontSize: 13)),
                              ))
                          .toList(),
                    );
                  }).toList(),
                ),
        ),
      ],

      // ── Documents ──
      if (documents.isNotEmpty) ...[
        const SizedBox(height: 14),
        _DocumentsCard(documents: documents),
      ],

      const SizedBox(height: 24),
    ];
  }

  Widget _buildHeader({
    required ColorScheme scheme,
    required ThemeData theme,
    required String displayName,
    required String imageUrl,
    required ProviderType? providerType,
    required VerificationStatus verStatus,
    required bool isBanned,
    required String? governorateName,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isBanned ? Colors.red.shade300 : scheme.outlineVariant,
          width: isBanned ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          ProfileAvatar(imageUrl: imageUrl, size: 96),
          const SizedBox(height: 14),
          Text(
            displayName,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              if (providerType != null) ProviderTypeChip(type: providerType),
              VerificationStatusBadge(status: verStatus),
              if (isBanned)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: .3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.block_rounded, size: 14, color: Colors.red),
                      const SizedBox(width: 6),
                      Text('محظور',
                          style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w800,
                              fontSize: 12)),
                    ],
                  ),
                ),
              if (governorateName != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on_rounded, size: 14, color: scheme.primary),
                      const SizedBox(width: 4),
                      Text(governorateName,
                          style: TextStyle(
                              fontSize: 12,
                              color: scheme.primary,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyHint(String text) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(text,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      );

  static String _fmt(DateTime d) {
    final l = d.toLocal();
    return '${l.year}/${l.month.toString().padLeft(2, '0')}/${l.day.toString().padLeft(2, '0')}';
  }

  static String _verAr(VerificationStatus s) => switch (s) {
        VerificationStatus.approved => 'موافق عليه',
        VerificationStatus.pending => 'قيد المراجعة',
        VerificationStatus.rejected => 'مرفوض',
        VerificationStatus.notSubmitted => 'لم يتم الإرسال',
      };

  static Color _verColor(VerificationStatus s) => switch (s) {
        VerificationStatus.approved => const Color(0xFF16A34A),
        VerificationStatus.pending => const Color(0xFFF59E0B),
        VerificationStatus.rejected => Colors.red,
        VerificationStatus.notSubmitted => Colors.grey,
      };
}

// ── Ban card ──────────────────────────────────────────────────────────────────

class _BanCard extends StatelessWidget {
  const _BanCard({this.reason, required this.onUnban});
  final String? reason;
  final VoidCallback onUnban;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: .3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.block_rounded, color: Colors.red, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('الحساب محظور',
                    style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w800,
                        fontSize: 14)),
                if (reason != null && reason!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('السبب: $reason',
                      style:
                          const TextStyle(color: Colors.red, fontSize: 13)),
                ],
              ],
            ),
          ),
          TextButton(
            onPressed: onUnban,
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('رفع الحظر'),
          ),
        ],
      ),
    );
  }
}

// ── Info card ─────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.icon,
    required this.rows,
  });

  final String title;
  final IconData icon;
  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 20, color: scheme.primary),
            const SizedBox(width: 8),
            Text(title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900)),
          ]),
          const SizedBox(height: 12),
          ...rows,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value, {this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (label.isEmpty) {
      return Text(value,
          style: TextStyle(
              height: 1.65, color: color ?? scheme.onSurface));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant)),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: color ?? scheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Expandable container card ─────────────────────────────────────────────────

class _ExpandableCard extends StatelessWidget {
  const _ExpandableCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(children: [
              Icon(icon, size: 20, color: scheme.primary),
              const SizedBox(width: 8),
              Text(title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900)),
            ]),
          ),
          const Divider(height: 1),
          child,
        ],
      ),
    );
  }
}

// ── Documents card ────────────────────────────────────────────────────────────

class _DocumentsCard extends StatelessWidget {
  const _DocumentsCard({required this.documents});
  final List<Map<String, dynamic>> documents;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.folder_open_rounded, size: 20, color: scheme.primary),
            const SizedBox(width: 8),
            Text('المستندات الرسمية',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900)),
          ]),
          const SizedBox(height: 12),
          ...documents.map((doc) {
            final name = (doc['documentName'] ?? 'مستند').toString();
            final rawUrl = (doc['documentUrl'] ?? '').toString();
            final fullUrl = ProfileAvatar.fullUrl(rawUrl);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _DocTile(name: name, url: fullUrl),
            );
          }),
        ],
      ),
    );
  }
}

enum _DocKind { image, pdf, other }

_DocKind _kindFor(String? url) {
  if (url == null) return _DocKind.other;
  final path = (Uri.tryParse(url)?.path ?? url).toLowerCase();
  if (['.jpg', '.jpeg', '.png', '.webp', '.gif'].any(path.endsWith)) return _DocKind.image;
  if (path.endsWith('.pdf')) return _DocKind.pdf;
  return _DocKind.other;
}

class _DocTile extends StatelessWidget {
  const _DocTile({required this.name, required this.url});
  final String name;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final kind = _kindFor(url);

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: url == null
          ? null
          : () {
              if (kind == _DocKind.pdf) {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => PdfViewerPage(url: url!, title: name)));
              } else if (kind == _DocKind.image) {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => _ImagePreview(url: url!, title: name)));
              }
            },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: .5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          children: [
            _DocIcon(kind: kind, url: url),
            const SizedBox(width: 10),
            Expanded(
              child: Text(name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            if (kind != _DocKind.other)
              Icon(Icons.chevron_left_rounded, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _DocIcon extends StatelessWidget {
  const _DocIcon({required this.kind, required this.url});
  final _DocKind kind;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (kind == _DocKind.image && url != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(url!,
            width: 48, height: 48, fit: BoxFit.cover,
            errorBuilder: (ctx, e, s) { return Icon(Icons.broken_image_rounded, color: scheme.onSurfaceVariant); }),
      );
    }
    if (kind == _DocKind.pdf) {
      return Container(
        width: 48, height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.red),
      );
    }
    return Icon(Icons.description_rounded, color: scheme.onSurfaceVariant, size: 40);
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.url, required this.title});
  final String url;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text(title),
        ),
        body: Center(
          child: InteractiveViewer(
            child: Image.network(url,
                errorBuilder: (ctx, e, s) { return const Text('تعذر تحميل الصورة', style: TextStyle(color: Colors.white)); }),
          ),
        ),
      ),
    );
  }
}
