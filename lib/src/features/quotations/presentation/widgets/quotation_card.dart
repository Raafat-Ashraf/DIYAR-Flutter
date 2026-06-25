import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../account/domain/entities/account_profile.dart';
import '../../../account/presentation/pages/provider_profile_page.dart';
import '../../../account/presentation/widgets/profile_avatar.dart';
import '../../domain/entities/quotation.dart';

class QuotationCard extends StatelessWidget {
  const QuotationCard({
    super.key,
    required this.quotation,
    this.isClientView = false,
    this.onAccept,
    this.onReject,
    this.onCancel,
  });

  final Quotation quotation;
  final bool isClientView;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isAccepted = quotation.status == QuotationStatus.accepted;
    final isCancelled = quotation.status == QuotationStatus.cancelled;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isAccepted
            ? BorderSide(color: Colors.green.shade400, width: 1.5)
            : BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Provider info row
            Row(
              children: [
                ProfileAvatar(imageUrl: quotation.provider.imageUrl, size: 38),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quotation.provider.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      if (quotation.provider.providerType != null)
                        Text(
                          quotation.provider.providerType!.arabicName,
                          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                        ),
                      if (isClientView)
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => ProviderProfilePage(
                              userId: quotation.provider.id,
                              displayName: quotation.provider.displayName,
                              imageUrl: quotation.provider.imageUrl,
                              providerType: quotation.provider.providerType,
                            ),
                          )),
                          child: Text('عرض الملف الشخصي',
                              style: TextStyle(fontSize: 12, color: scheme.primary,
                                  fontWeight: FontWeight.w600, decoration: TextDecoration.underline)),
                        ),
                    ],
                  ),
                ),
                _StatusBadge(status: quotation.status),
              ],
            ),

            const SizedBox(height: 12),

            // Price + duration
            Row(
              children: [
                _InfoChip(
                  icon: Icons.attach_money_rounded,
                  label: '${quotation.price.toStringAsFixed(0)} ج.م',
                  color: scheme.primary,
                ),
                if (quotation.executionDurationDays != null) ...[
                  const SizedBox(width: 8),
                  _InfoChip(
                    icon: Icons.schedule_rounded,
                    label: '${quotation.executionDurationDays} يوم',
                    color: scheme.secondary,
                  ),
                ],
              ],
            ),

            if (quotation.description != null && quotation.description!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(quotation.description!, style: const TextStyle(fontSize: 13.5)),
            ],

            // Phone number section
            const SizedBox(height: 12),
            _PhoneRow(
              phone: quotation.provider.phoneNumber,
              isRevealed: quotation.isContactRevealed,
            ),

            // Action buttons
            if (!isCancelled && quotation.status != QuotationStatus.rejected) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              if (isClientView) ...[
                if (!isAccepted)
                  // Pending: رفض + قبول
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: onReject,
                          icon: const Icon(Icons.close_rounded, size: 16),
                          label: const Text('رفض'),
                          style: FilledButton.styleFrom(backgroundColor: Colors.red),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: onAccept,
                          icon: const Icon(Icons.check_rounded, size: 16),
                          label: const Text('قبول'),
                          style: FilledButton.styleFrom(backgroundColor: Colors.green),
                        ),
                      ),
                    ],
                  )
                else
                  // Accepted: رفض فقط بعرض كامل
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: const Text('رفض العرض المقبول'),
                      style: FilledButton.styleFrom(backgroundColor: Colors.red),
                    ),
                  ),
              ],
              // Provider: إلغاء
              if (!isClientView && !isAccepted && onCancel != null)
                TextButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('إلغاء العرض'),
                  style: TextButton.styleFrom(foregroundColor: scheme.error),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PhoneRow extends StatelessWidget {
  const _PhoneRow({required this.phone, required this.isRevealed});

  final String? phone;
  final bool isRevealed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (!isRevealed || phone == null) {
      return Row(
        children: [
          Icon(Icons.phone_locked_rounded, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          ImageFiltered(
            imageFilter: _blurFilter,
            child: Text(
              '01xxxxxxxxx',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '(يظهر بعد القبول)',
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
          ),
        ],
      );
    }

    return InkWell(
      onTap: () => Clipboard.setData(ClipboardData(text: phone!)),
      borderRadius: BorderRadius.circular(6),
      child: Row(
        children: [
          Icon(Icons.phone_rounded, size: 16, color: Colors.green.shade600),
          const SizedBox(width: 6),
          Text(
            phone!,
            style: TextStyle(
              color: Colors.green.shade700,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.copy_rounded, size: 14, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }

  static final _blurFilter = ColorFilter.matrix([
    0, 0, 0, 0, 0.5,
    0, 0, 0, 0, 0.5,
    0, 0, 0, 0, 0.5,
    0, 0, 0, 1, 0,
  ]);
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final QuotationStatus? status;

  @override
  Widget build(BuildContext context) {
    if (status == null) return const SizedBox.shrink();
    Color color;
    switch (status!) {
      case QuotationStatus.pending:
        color = Colors.orange;
      case QuotationStatus.accepted:
        color = Colors.green;
      case QuotationStatus.rejected:
        color = Colors.red;
      case QuotationStatus.cancelled:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: .4)),
      ),
      child: Text(
        status!.arabicLabel,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
