import 'package:flutter/material.dart';

import '../../../account/presentation/widgets/profile_avatar.dart';
import '../../../showcases/presentation/utils/showcase_formatters.dart';
import '../../domain/entities/request.dart';

export '../../domain/entities/request.dart' show RequestType, RequestStatus;

class RequestCard extends StatelessWidget {
  const RequestCard({
    super.key,
    required this.request,
    required this.onTap,
    this.onCommentTap,
  });

  final Request request;
  final VoidCallback onTap;
  final VoidCallback? onCommentTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final client = request.client;
    final files = request.files;
    final firstImage = files.where((f) => f.isImage).firstOrNull;
    final thumbUrl = ProfileAvatar.fullUrl(firstImage?.fileUrl);
    final comments = request.comments;
    final firstComment = comments.isNotEmpty ? comments.first : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: .05),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Main row (thumbnail + content) ──────────────────
            SizedBox(
              height: 130,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Thumbnail
                  SizedBox(
                    width: 112,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        thumbUrl != null
                            ? Image.network(
                                thumbUrl,
                                fit: BoxFit.cover,
                                loadingBuilder: (_, c, p) =>
                                    p == null ? c : _typePlaceholder(request.requestType),
                                errorBuilder: (ctx, e, s) =>
                                    _typePlaceholder(request.requestType),
                              )
                            : _typePlaceholder(request.requestType),
                        if (files.isNotEmpty)
                          Positioned(
                            bottom: 6,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: .60),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.attach_file_rounded,
                                      size: 11, color: Colors.white),
                                  const SizedBox(width: 2),
                                  Text('${files.length}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              _TypeBadge(requestType: request.requestType),
                              const SizedBox(width: 6),
                              if (request.status != null)
                                _StatusBadge(status: request.status!),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (request.specialization != null)
                                Text(
                                  request.specialization!.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800, fontSize: 13.5),
                                ),
                              if (request.description != null &&
                                  request.description!.isNotEmpty)
                                Text(
                                  request.description!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: scheme.onSurfaceVariant, fontSize: 12),
                                ),
                            ],
                          ),
                          Wrap(
                            spacing: 10,
                            children: [
                              if (request.city != null)
                                _InfoChip(
                                    icon: Icons.location_on_outlined,
                                    label: request.city!.name),
                              if (request.quantity != null &&
                                  request.specialization?.measurementUnitName != null)
                                _InfoChip(
                                    icon: Icons.inventory_2_outlined,
                                    label:
                                        '${_fmt(request.quantity!)} ${request.specialization!.measurementUnitName}'),
                              if (request.expectedBudget != null)
                                _InfoChip(
                                    icon: Icons.payments_outlined,
                                    label: formatShowcasePrice(
                                        request.expectedBudget)),
                            ],
                          ),
                          Row(
                            children: [
                              ProfileAvatar(
                                  imageUrl: client?.imageUrl, size: 20),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  client?.displayName ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700, fontSize: 11),
                                ),
                              ),
                              if (request.createdAt != null)
                                Text(
                                  formatShowcaseDate(request.createdAt),
                                  style: TextStyle(
                                      color: scheme.onSurfaceVariant,
                                      fontSize: 10),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── First comment preview + comment icon on left ──────
            if (firstComment != null) ...[
              Divider(height: 1, color: scheme.outlineVariant),
              InkWell(
                onTap: onCommentTap ?? onTap,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ProfileAvatar(
                          imageUrl: firstComment.user.imageUrl, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            style: TextStyle(
                                fontSize: 12, color: scheme.onSurface),
                            children: [
                              TextSpan(
                                text: '${firstComment.user.displayName}  ',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700),
                              ),
                              TextSpan(text: firstComment.content),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Comment icon on the LEFT (trailing in RTL)
                      GestureDetector(
                        onTap: onCommentTap ?? onTap,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded,
                                size: 14,
                                color: scheme.primary),
                            const SizedBox(width: 3),
                            Text(
                              '${comments.length}',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // No comments — show just the comment icon in a small bar
              Divider(height: 1, color: scheme.outlineVariant),
              InkWell(
                onTap: onCommentTap ?? onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded,
                          size: 14, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 3),
                      Text('0',
                          style: TextStyle(
                              fontSize: 11,
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _typePlaceholder(RequestType? type) {
    final isMaterial = type == RequestType.material;
    final colors = isMaterial
        ? [const Color(0xFF0EA5E9), const Color(0xFF0369A1)]
        : [const Color(0xFF10B981), const Color(0xFF065F46)];
    final bgIcon =
        isMaterial ? Icons.warehouse_rounded : Icons.architecture_rounded;
    final fgIcon =
        isMaterial ? Icons.inventory_2_rounded : Icons.engineering_rounded;
    final label = isMaterial ? 'مادة' : 'خدمة';

    return Container(
      decoration: BoxDecoration(
        gradient:
            LinearGradient(colors: colors, begin: Alignment.topRight, end: Alignment.bottomLeft),
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: -12, left: -8,
            child: Icon(bgIcon, size: 80,
                color: Colors.white.withValues(alpha: .12)),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(fgIcon, color: Colors.white, size: 28),
                const SizedBox(height: 4),
                Text(label, style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.requestType});
  final RequestType? requestType;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isMaterial = requestType == RequestType.material;
    final color = isMaterial ? const Color(0xFF0EA5E9) : scheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(5)),
      child: Text(requestType?.arabicLabel ?? '',
          style: TextStyle(
              color: color, fontWeight: FontWeight.w700, fontSize: 10)),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final RequestStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, bg) = switch (status) {
      RequestStatus.open => (const Color(0xFF16A34A), const Color(0xFFDCFCE7)),
      RequestStatus.completed =>
        (const Color(0xFF2563EB), const Color(0xFFDBEAFE)),
      RequestStatus.cancelled =>
        (const Color(0xFFDC2626), const Color(0xFFFEE2E2)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(5)),
      child: Text(status.arabicLabel,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w700, fontSize: 10)),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: scheme.onSurfaceVariant),
        const SizedBox(width: 2),
        Text(label,
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
      ],
    );
  }
}
