import 'package:flutter/material.dart';

import '../../../account/presentation/widgets/profile_avatar.dart';
import '../../domain/entities/showcase.dart';
import '../utils/showcase_formatters.dart';
import 'showcase_status_badge.dart';

class ShowcaseCard extends StatelessWidget {
  const ShowcaseCard({super.key, required this.showcase, required this.onTap});

  final Showcase showcase;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final owner = showcase.owner;
    final coverUrl = ProfileAvatar.fullUrl(showcase.coverImageUrl);

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
        height: 128,
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 116,
              child: coverUrl == null
                  ? _coverPlaceholder(scheme)
                  : Image.network(
                      coverUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return _coverPlaceholder(scheme);
                      },
                      errorBuilder: (_, _, _) => _coverPlaceholder(scheme),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          showcase.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          showcase.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        ProfileAvatar(imageUrl: owner?.imageUrl, size: 22),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            owner?.displayName ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (showcase.price != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            formatShowcasePrice(showcase.price),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: scheme.primary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
          ),
          if (showcase.isOpen != null)
            Positioned(
              right: 6,
              top: 6,
              child: ShowcaseStatusBadge(isOpen: showcase.isOpen!, compact: true),
            ),
        ],
      ),
    );
  }

  Widget _coverPlaceholder(ColorScheme scheme) {
    return Container(
      color: scheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_outlined,
        size: 30,
        color: scheme.onSurfaceVariant.withValues(alpha: .5),
      ),
    );
  }
}
