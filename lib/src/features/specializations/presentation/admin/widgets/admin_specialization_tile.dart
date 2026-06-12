import 'package:flutter/material.dart';

import '../../../domain/entities/specialization.dart';

class AdminSpecializationTile extends StatelessWidget {
  const AdminSpecializationTile({
    super.key,
    required this.specialization,
    required this.isProcessing,
    required this.onOpen,
    required this.onEdit,
    required this.onToggleDelete,
  });

  final Specialization specialization;
  final bool isProcessing;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onToggleDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDeleted = specialization.isDeleted;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDeleted ? scheme.error.withValues(alpha: .3) : scheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: (isDeleted ? scheme.error : scheme.primary)
                      .withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.category_rounded,
                  color: isDeleted ? scheme.error : scheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      specialization.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        decoration: isDeleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color: isDeleted
                            ? scheme.onSurfaceVariant
                            : scheme.onSurface,
                      ),
                    ),
                    if (specialization.measurementUnitName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        specialization.measurementUnitName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (isDeleted) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.error.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'محذوف',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: scheme.error,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isProcessing)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'تعديل التخصص',
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 20),
                    ),
                    IconButton(
                      tooltip: isDeleted ? 'استعادة' : 'حذف',
                      onPressed: onToggleDelete,
                      icon: Icon(
                        isDeleted
                            ? Icons.restore_from_trash_rounded
                            : Icons.delete_outline_rounded,
                        size: 20,
                        color: isDeleted ? scheme.primary : scheme.error,
                      ),
                    ),
                  ],
                ),
              Icon(Icons.chevron_left_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
