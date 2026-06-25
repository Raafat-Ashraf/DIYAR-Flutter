import 'package:flutter/material.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_client.dart';
import '../../../account/presentation/cubit/account_cubit.dart';
import '../../../account/presentation/widgets/profile_avatar.dart';
import '../../../admin/presentation/pages/pdf_viewer_page.dart';
import '../../../admin/presentation/widgets/provider_type_chip.dart';
import '../../domain/entities/showcase.dart';
import '../utils/showcase_formatters.dart';
import '../widgets/showcase_status_badge.dart';

class ShowcaseDetailsPage extends StatefulWidget {
  const ShowcaseDetailsPage({super.key, required this.showcase});

  final Showcase showcase;

  @override
  State<ShowcaseDetailsPage> createState() => _ShowcaseDetailsPageState();
}

class _ShowcaseDetailsPageState extends State<ShowcaseDetailsPage> {
  late Showcase _showcase;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _showcase = widget.showcase;
  }

  bool get _isOwner {
    final myId = getIt<AccountCubit>().state.profile?.id;
    return myId != null && myId == _showcase.owner?.id;
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف المشروع'),
        content: const Text('هل أنت متأكد من حذف هذا المشروع؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('حذف', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _loading = true);
    try {
      await getIt<ApiClient>().delete<dynamic>('${ApiConstants.deleteShowcase}/${_showcase.id}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف المشروع')));
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ، حاول مرة أخرى')));
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _toggleOpen() async {
    setState(() => _loading = true);
    try {
      await getIt<ApiClient>().put<dynamic>('${ApiConstants.toggleShowcaseOpen}/${_showcase.id}');
      if (mounted) setState(() => _showcase = _showcase.copyWith(isOpen: !(_showcase.isOpen ?? true)));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ، حاول مرة أخرى')));
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final showcase = _showcase;
    final scheme = Theme.of(context).colorScheme;
    final coverUrl = ProfileAvatar.fullUrl(showcase.coverImageUrl);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: scheme.surfaceContainerLowest,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 260,
              pinned: true,
              surfaceTintColor: Colors.transparent,
              actions: _isOwner ? [
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                  )
                else
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                    onSelected: (v) {
                      if (v == 'toggle') _toggleOpen();
                      if (v == 'delete') _delete();
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'toggle',
                        child: Row(children: [
                          Icon(showcase.isOpen == true ? Icons.lock_outline_rounded : Icons.lock_open_rounded),
                          const SizedBox(width: 8),
                          Text(showcase.isOpen == true ? 'إغلاق المشروع' : 'فتح المشروع'),
                        ]),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          Icon(Icons.delete_outline_rounded, color: scheme.error),
                          const SizedBox(width: 8),
                          Text('حذف المشروع', style: TextStyle(color: scheme.error)),
                        ]),
                      ),
                    ],
                  ),
              ] : null,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    coverUrl == null
                        ? _coverPlaceholder(scheme)
                        : Image.network(
                            coverUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                _coverPlaceholder(scheme),
                          ),
                    if (showcase.isOpen != null)
                      Positioned(
                        left: 12,
                        bottom: 12,
                        child: ShowcaseStatusBadge(isOpen: showcase.isOpen!),
                      ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      showcase.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (showcase.price != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        formatShowcasePrice(showcase.price),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: scheme.primary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _OwnerCard(
                      owner: showcase.owner,
                      createdAt: showcase.createdAt,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'الوصف',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      showcase.description,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                    if (showcase.files.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        'ملفات إضافية',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _FilesGallery(files: showcase.files),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _coverPlaceholder(ColorScheme scheme) {
    return Container(
      color: scheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_outlined,
        size: 48,
        color: scheme.onSurfaceVariant.withValues(alpha: .5),
      ),
    );
  }
}

class _OwnerCard extends StatelessWidget {
  const _OwnerCard({required this.owner, required this.createdAt});

  final ShowcaseOwner? owner;
  final DateTime? createdAt;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final phoneNumber = owner?.phoneNumber?.trim();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: .05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          ProfileAvatar(imageUrl: owner?.imageUrl, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  owner?.displayName ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  formatShowcaseDate(createdAt),
                  style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                ),
                if (phoneNumber != null && phoneNumber.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.phone_rounded,
                        size: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        phoneNumber,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          ProviderTypeChip(type: owner?.providerType),
        ],
      ),
    );
  }
}

class _FilesGallery extends StatelessWidget {
  const _FilesGallery({required this.files});

  final List<ShowcaseFileItem> files;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: files.map((file) {
        final url = ProfileAvatar.fullUrl(file.url);
        final description = file.description?.trim();
        final hasDescription = description != null && description.isNotEmpty;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: () => _openFile(context, file, url),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: file.isPdf || url == null
                          ? Container(
                              color: scheme.primary.withValues(alpha: .08),
                              alignment: Alignment.center,
                              child: Icon(
                                file.isPdf
                                    ? Icons.picture_as_pdf_rounded
                                    : Icons.broken_image_outlined,
                                color: scheme.primary,
                                size: 26,
                              ),
                            )
                          : Image.network(
                              url,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                color: scheme.surfaceContainerHighest,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.broken_image_outlined,
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      hasDescription
                          ? description
                          : (file.isPdf ? 'ملف PDF' : 'صورة'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_left_rounded,
                    color: scheme.onSurfaceVariant.withValues(alpha: .5),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _openFile(BuildContext context, ShowcaseFileItem file, String? url) {
    if (url == null) return;
    if (file.isPdf) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PdfViewerPage(url: url, title: 'عرض الملف'),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => _ImagePreviewPage(url: url)),
    );
  }
}

class _ImagePreviewPage extends StatelessWidget {
  const _ImagePreviewPage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: InteractiveViewer(
            child: Image.network(
              url,
              errorBuilder: (_, _, _) => const Icon(
                Icons.broken_image_outlined,
                color: Colors.white,
                size: 48,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
