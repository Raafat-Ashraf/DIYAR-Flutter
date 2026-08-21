import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// In-app privacy policy + account/data deletion summary.
/// A full copy is also hosted at [_fullPolicyUrl] (required by Google Play
/// as the Data Safety form's privacy policy URL and account-deletion web
/// resource).
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  static const _fullPolicyUrl =
      'https://diyarapi.dogethertech.com/legal/privacy-policy.html';

  Future<void> _openFullPolicy() async {
    final uri = Uri.parse(_fullPolicyUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('سياسة الخصوصية')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ديار — سياسة الخصوصية',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                'آخر تحديث: 1 أغسطس 2026',
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
              ),
              const SizedBox(height: 18),
              _Section(
                title: 'البيانات التي نجمعها',
                body:
                    'الاسم والبريد الإلكتروني ورقم الهاتف، الموقع الجغرافي '
                    '(المحافظة/المدينة والإحداثيات)، المستندات الرسمية '
                    'للتحقق من هوية الموردين والمهندسين، الصورة الشخصية '
                    'وبيانات الملف، ومحتوى الطلبات وعروض الأسعار والتقييمات.',
              ),
              _Section(
                title: 'كيف نستخدم بياناتك',
                body:
                    'لتشغيل حسابك وربطك بالطرف الآخر في الطلب، إرسال '
                    'الإشعارات، والتحقق من هوية الموردين/المهندسين قبل '
                    'تفعيل حساباتهم. لا نبيع بياناتك لأي طرف ثالث.',
              ),
              _Section(
                title: 'المشاركة مع أطراف أخرى',
                body:
                    'Firebase/Google لإرسال الإشعارات وتسجيل الدخول بجوجل '
                    'فقط إن اخترت ذلك، والطرف الآخر في نفس المعاملة '
                    '(اسمك وتقييمك وعرضك).',
              ),
              _Section(
                title: 'حذف الحساب والبيانات',
                body:
                    'يمكنك حذف حسابك نهائيًا في أي وقت من "الملف الشخصي ← '
                    'إجراءات الحساب ← حذف الحساب". عند الحذف تُمحى بياناتك '
                    'الشخصية ومستنداتك الرسمية فورًا، وتُلغى طلباتك '
                    'المفتوحة وعروضك المعلّقة، ويتم تسجيل خروجك من كل '
                    'الأجهزة تلقائيًا. لو تعذّر عليك استخدام التطبيق، '
                    'يمكنك طلب الحذف عبر البريد الإلكتروني الموضح بالأسفل.',
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _openFullPolicy,
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('عرض النسخة الكاملة على الموقع'),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'للتواصل بخصوص بياناتك أو طلب حذف الحساب عبر البريد:\n'
                  'dogethertech@gmail.com',
                  style: TextStyle(fontWeight: FontWeight.w600, height: 1.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(height: 1.7)),
        ],
      ),
    );
  }
}
