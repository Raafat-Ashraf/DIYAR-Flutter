import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pageController = PageController();
  int _current = 0;

  static const _slides = [_SlideData.client, _SlideData.freelancer, _SlideData.supplier];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_current < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _goStart();
    }
  }

  void _goStart() => context.go(AppRoutes.login);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLast = _current == _slides.length - 1;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: scheme.surfaceContainerLowest,
        body: Stack(
          children: [
            // ── Slides ───────────────────────────────────────
            PageView.builder(
              controller: _pageController,
              itemCount: _slides.length,
              onPageChanged: (i) => setState(() => _current = i),
              itemBuilder: (_, i) => _OnboardingSlide(data: _slides[i]),
            ),

            // ── Skip button ──────────────────────────────────
            SafeArea(
              child: Align(
                alignment: AlignmentDirectional.topEnd,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: AnimatedOpacity(
                    opacity: isLast ? 0 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: TextButton(
                      onPressed: isLast ? null : _goStart,
                      child: Text(
                        'تخطي',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Bottom bar (dots + button) ───────────────────
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_slides.length, (i) {
                          final active = i == _current;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: active ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: active
                                  ? scheme.primary
                                  : scheme.primary.withValues(alpha: .25),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 24),
                      // Action button
                      ElevatedButton(
                        onPressed: _next,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          isLast ? 'ابدأ الآن' : 'التالي',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Slide widget ──────────────────────────────────────────────────────────────

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({required this.data});
  final _SlideData data;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Column(
      children: [
        // ── Illustration ───────────────────────────────────
        SizedBox(
          height: size.height * .52,
          child: _Illustration(data: data),
        ),

        // ── Text content ───────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Emoji badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: data.color.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    data.badge,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(height: 12),
                // Title
                Text(
                  data.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.3,
                      ),
                ),
                const SizedBox(height: 12),
                // Description
                Text(
                  data.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                        height: 1.7,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Illustration ──────────────────────────────────────────────────────────────

class _Illustration extends StatelessWidget {
  const _Illustration({required this.data});
  final _SlideData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            data.color.withValues(alpha: .18),
            data.color.withValues(alpha: .06),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Subtle background blob
          Positioned(
            top: 30,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: data.color.withValues(alpha: .10),
              ),
            ),
          ),
          // Main icon cluster
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Primary icon
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: .15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  data.mainIcon,
                  size: 60,
                  color: data.color,
                ),
              ),
              const SizedBox(height: 20),
              // Secondary icons row
              Row(
                mainAxisSize: MainAxisSize.min,
                children: data.subIcons.map((icon) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: data.color.withValues(alpha: .18),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(icon, size: 26, color: data.color),
                  );
                }).toList(),
              ),
            ],
          ),
          // Floating label
          Positioned(
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: data.color.withValues(alpha: .2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(data.mainIcon, size: 16, color: data.color),
                  const SizedBox(width: 6),
                  Text(
                    data.floatingLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: data.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Slide data ────────────────────────────────────────────────────────────────

class _SlideData {
  const _SlideData({
    required this.badge,
    required this.title,
    required this.description,
    required this.color,
    required this.mainIcon,
    required this.subIcons,
    required this.floatingLabel,
  });

  final String badge;
  final String title;
  final String description;
  final Color color;
  final IconData mainIcon;
  final List<IconData> subIcons;
  final String floatingLabel;

  static const client = _SlideData(
    badge: '🏠 للعميل',
    title: 'ابنِ وشطّب بيتك بذكاء وأقل تكلفة!',
    description:
        'سواء كنت بتبني بيت جديد أو بتشطّب شقتك، ارفع طلبك الحين (مواد بناء أو خدمات هندسية) واستقبل عروض أسعار تنافسية من أفضل الموردين والمهندسين في منطقتك. قارن الأسعار، وشوف التقييمات، واختار العرض اللي يناسب ميزانيتك!',
    color: Color(0xFFD97706),
    mainIcon: Icons.home_work_rounded,
    subIcons: [
      Icons.request_quote_outlined,
      Icons.compare_arrows_rounded,
      Icons.star_rounded,
    ],
    floatingLabel: 'استقبل عروض أسعار تنافسية',
  );

  static const freelancer = _SlideData(
    badge: '📐 للمهندس',
    title: 'كبّر شغلك واصنع مكانتك كمهندس مستقل!',
    description:
        'إذا كنت مهندس معماري، إنشائي، أو مصمم ديكور؛ ديار هو بوابتك للوصول لعملاء حقيقيين في محيطك الجغرافي. تابع الطلبات المطابقة لتخصصك، قدّم عروضك واشرح خدماتك بكل حرية، وابنِ بروفايل قوي بتقييمات ممتازة.',
    color: Color(0xFF2563EB),
    mainIcon: Icons.architecture_rounded,
    subIcons: [
      Icons.design_services_rounded,
      Icons.people_rounded,
      Icons.trending_up_rounded,
    ],
    floatingLabel: 'اوصل للعملاء المناسبين',
  );

  static const supplier = _SlideData(
    badge: '🚛 للمورد والمقاول',
    title: 'ضاعف مبيعاتك وافتح سوق جديد لمنتجاتك!',
    description:
        'لكل أصحاب معارض ومخازن مواد البناء والتشطيب؛ مع ديار طلبات العملاء بتجيلك لحد عندك بناءً على تخصصك ومدينتك. قدم عروض أسعارك فوراً، تواصل مع العملاء مباشرة، وزوّد حجم مبيعاتك ووسع شبكة عملائك بكل سهولة.',
    color: Color(0xFF16A34A),
    mainIcon: Icons.local_shipping_rounded,
    subIcons: [
      Icons.storefront_rounded,
      Icons.handshake_outlined,
      Icons.bar_chart_rounded,
    ],
    floatingLabel: 'طلبات العملاء تجيك أنت',
  );
}
