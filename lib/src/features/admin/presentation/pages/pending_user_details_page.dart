import 'package:flutter/material.dart';

import '../../../account/presentation/widgets/profile_avatar.dart';
import '../../domain/entities/pending_user.dart';
import '../widgets/provider_type_chip.dart';
import '../widgets/verification_status_badge.dart';
import 'pdf_viewer_page.dart';

class PendingUserDetailsPage extends StatelessWidget {
  const PendingUserDetailsPage({super.key, required this.user});

  final PendingUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: scheme.surfaceContainerLowest,
        appBar: AppBar(title: const Text('تفاصيل الطلب')),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Center(
                    child: ProfileAvatar(imageUrl: user.imageUrl, size: 96),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: Text(
                      user.displayName.isEmpty ? user.email : user.displayName,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        ProviderTypeChip(type: user.providerType),
                        VerificationStatusBadge(status: user.verificationStatus),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _DetailsCard(
                    title: 'بيانات الحساب',
                    icon: Icons.badge_outlined,
                    rows: [
                      _DetailRow(label: 'البريد الإلكتروني', value: user.email),
                      _DetailRow(
                        label: 'المحافظة',
                        value: user.governorate?.name ?? '-',
                      ),
                      if (user.submittedAt != null)
                        _DetailRow(
                          label: 'تاريخ التقديم',
                          value: _formatDate(user.submittedAt!),
                        ),
                    ],
                  ),
                  if (user.bio != null && user.bio!.trim().isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _DetailsCard(
                      title: 'نبذة مختصرة',
                      icon: Icons.notes_rounded,
                      rows: [_DetailRow(label: '', value: user.bio!.trim())],
                    ),
                  ],
                  if ((user.companyName != null &&
                          user.companyName!.trim().isNotEmpty) ||
                      user.yearsOfExperience != null) ...[
                    const SizedBox(height: 14),
                    _DetailsCard(
                      title: 'البيانات المهنية',
                      icon: Icons.business_center_rounded,
                      rows: [
                        if (user.companyName != null &&
                            user.companyName!.trim().isNotEmpty)
                          _DetailRow(
                            label: 'اسم الشركة',
                            value: user.companyName!.trim(),
                          ),
                        if (user.yearsOfExperience != null)
                          _DetailRow(
                            label: 'سنوات الخبرة',
                            value: '${user.yearsOfExperience}',
                          ),
                      ],
                    ),
                  ],
                  if (user.specializations.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _ExpandableGroupCard(
                      title: 'التخصصات',
                      icon: Icons.workspace_premium_rounded,
                      groups: user.specializations
                          .map((g) => _GroupItem(
                                header: g.parentName,
                                children: g.children,
                              ))
                          .toList(),
                    ),
                  ],
                  if (user.workCities.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _ExpandableGroupCard(
                      title: 'مدن العمل',
                      icon: Icons.location_city_rounded,
                      groups: user.workCities
                          .map((g) => _GroupItem(
                                header: g.governorateName,
                                children: g.cities,
                              ))
                          .toList(),
                    ),
                  ],
                  if (user.documents.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _DocumentsCard(documents: user.documents),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.year}/${local.month.toString().padLeft(2, '0')}/${local.day.toString().padLeft(2, '0')}';
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({
    required this.title,
    required this.icon,
    required this.rows,
  });

  final String title;
  final IconData icon;
  final List<_DetailRow> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...rows,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (label.isEmpty) {
      return Text(
        value,
        style: TextStyle(height: 1.6, color: scheme.onSurface),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupItem {
  const _GroupItem({required this.header, required this.children});
  final String header;
  final List<String> children;
}

class _ExpandableGroupCard extends StatelessWidget {
  const _ExpandableGroupCard({
    required this.title,
    required this.icon,
    required this.groups,
  });

  final String title;
  final IconData icon;
  final List<_GroupItem> groups;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Icon(icon, size: 20, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...groups.map((g) => _ExpandableTile(item: g)),
        ],
      ),
    );
  }
}

class _ExpandableTile extends StatefulWidget {
  const _ExpandableTile({required this.item});
  final _GroupItem item;

  @override
  State<_ExpandableTile> createState() => _ExpandableTileState();
}

class _ExpandableTileState extends State<_ExpandableTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasChildren = widget.item.children.isNotEmpty;

    return Column(
      children: [
        InkWell(
          onTap: hasChildren ? () => setState(() => _expanded = !_expanded) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 8,
                  color: scheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.item.header,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                if (hasChildren)
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: scheme.onSurfaceVariant,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
        if (_expanded && hasChildren)
          Container(
            color: scheme.surfaceContainerLowest,
            child: Column(
              children: widget.item.children
                  .map(
                    (child) => Padding(
                      padding: const EdgeInsets.fromLTRB(40, 8, 16, 8),
                      child: Row(
                        children: [
                          Icon(Icons.subdirectory_arrow_right_rounded,
                              size: 14, color: scheme.onSurfaceVariant),
                          const SizedBox(width: 6),
                          Text(
                            child,
                            style: TextStyle(
                              fontSize: 13,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        Divider(height: 1, color: scheme.outlineVariant),
      ],
    );
  }
}

class _DocumentsCard extends StatelessWidget {
  const _DocumentsCard({required this.documents});

  final List<PendingUserDocument> documents;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.folder_open_rounded, size: 20, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                'المستندات المرفوعة',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final document in documents) _DocumentTile(document: document),
        ],
      ),
    );
  }
}

enum _DocumentKind { image, pdf, other, invalid }

_DocumentKind _kindFor(String? url) {
  if (url == null || url.trim().isEmpty) return _DocumentKind.invalid;

  final path = (Uri.tryParse(url)?.path ?? url).toLowerCase();

  if (const ['.jpg', '.jpeg', '.png', '.webp', '.gif'].any(path.endsWith)) {
    return _DocumentKind.image;
  }
  if (path.endsWith('.pdf')) return _DocumentKind.pdf;

  return _DocumentKind.other;
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({required this.document});

  final PendingUserDocument document;

  @override
  Widget build(BuildContext context) {
    final url = ProfileAvatar.fullUrl(document.fileUrl);
    final name = document.documentName.isEmpty ? 'مستند' : document.documentName;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: switch (_kindFor(url)) {
        _DocumentKind.image => _ImageDocumentTile(url: url!, name: name),
        _DocumentKind.pdf => _PdfDocumentTile(url: url!, name: name),
        _DocumentKind.other => _UnsupportedDocumentTile(
          name: name,
          available: true,
        ),
        _DocumentKind.invalid => _UnsupportedDocumentTile(
          name: name,
          available: false,
        ),
      },
    );
  }
}

class _ImageDocumentTile extends StatelessWidget {
  const _ImageDocumentTile({required this.url, required this.name});

  final String url;
  final String name;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => _ImagePreviewPage(url: url, title: name),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: .5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                url,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        value: progress.expectedTotalBytes != null
                            ? (progress.cumulativeBytesLoaded /
                                  progress.expectedTotalBytes!)
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  color: scheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.broken_image_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.chevron_left_rounded, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _PdfDocumentTile extends StatelessWidget {
  const _PdfDocumentTile({required this.url, required this.name});

  final String url;
  final String name;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: .5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.red),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonalIcon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PdfViewerPage(url: url, title: name),
              ),
            ),
            icon: const Icon(Icons.open_in_new_rounded, size: 18),
            label: const Text('فتح'),
          ),
        ],
      ),
    );
  }
}

class _UnsupportedDocumentTile extends StatelessWidget {
  const _UnsupportedDocumentTile({
    required this.name,
    required this.available,
  });

  final String name;
  final bool available;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: .5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.description_rounded, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  available ? 'تعذر معاينة هذا الملف' : 'الملف غير متاح',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePreviewPage extends StatelessWidget {
  const _ImagePreviewPage({required this.url, required this.title});

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
            child: Image.network(
              url,
              errorBuilder: (context, error, stackTrace) => const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'تعذر تحميل الصورة',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const CircularProgressIndicator(color: Colors.white);
              },
            ),
          ),
        ),
      ),
    );
  }
}
