import 'package:flutter/material.dart';

import '../../../../core/constants/api_constants.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.imageUrl,
    this.size = 34,
    this.isActive = false,
  });

  final String? imageUrl;
  final double size;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final fullImageUrl = fullUrl(imageUrl);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: size + (isActive ? 6 : 0),
      height: size + (isActive ? 6 : 0),
      padding: EdgeInsets.all(isActive ? 2 : 0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive ? Colors.black : Colors.transparent,
          width: 2,
        ),
      ),
      child: ClipOval(
        child: DecoratedBox(
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: .06)),
          child: fullImageUrl == null
              ? _fallback()
              : Image.network(
                  fullImageUrl,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                  frameBuilder:
                      (context, child, frame, wasSynchronouslyLoaded) {
                        if (wasSynchronouslyLoaded) return child;
                        return AnimatedOpacity(
                          opacity: frame == null ? 0 : 1,
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          child: child,
                        );
                      },
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        _fallback(),
                        Center(
                          child: SizedBox.square(
                            dimension: size * .34,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                  errorBuilder: (_, _, _) => _fallback(),
                ),
        ),
      ),
    );
  }

  Widget _fallback() => Image.asset('Dyiar-Logo.png', fit: BoxFit.cover);

  static String? fullUrl(String? value) {
    final image = value?.trim();
    if (image == null || image.isEmpty) return null;
    if (image.startsWith('http://') || image.startsWith('https://')) {
      return image;
    }
    final normalized = image.startsWith('/') ? image.substring(1) : image;
    return Uri.parse(ApiConstants.baseUrl).resolve(normalized).toString();
  }
}
