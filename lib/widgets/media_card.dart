import 'package:flutter/material.dart';

import '../theme.dart';
import 'photo_pager.dart';

/// Web `MediaCard` equivalent — aspect 4/5, overlays, nickname/age + headline/meta.
class MediaCard extends StatelessWidget {
  const MediaCard({
    super.key,
    required this.name,
    required this.headline,
    this.age,
    this.meta,
    this.photoUrl,
    this.photoUrls,
    this.onTap,
  });

  final String name;
  final String headline;
  final int? age;
  final String? meta;
  final String? photoUrl;
  final List<String>? photoUrls;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final title = age != null ? '$name, $age' : name;
    final initial =
        name.isNotEmpty ? String.fromCharCodes(name.runes.take(1)) : '?';
    final hue = _hashHue(name);
    final urls = (photoUrls != null && photoUrls!.isNotEmpty)
        ? photoUrls!
        : (photoUrl != null && photoUrl!.isNotEmpty ? [photoUrl!] : <String>[]);

    return Material(
      color: Colors.transparent,
      child: AspectRatio(
        aspectRatio: 4 / 5,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Stack(
            fit: StackFit.expand,
            children: [
              PhotoPager(
                urls: urls,
                onTap: onTap,
                placeholder: _Placeholder(hue: hue, initial: initial),
              ),
              const IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.center,
                      colors: [
                        Color(0x99000000),
                        Color(0x00000000),
                      ],
                    ),
                  ),
                ),
              ),
              const IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.center,
                      colors: [
                        Color(0xB3000000),
                        Color(0x00000000),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                top: urls.length > 1 ? 22 : 18,
                child: IgnorePointer(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white24,
                        backgroundImage: urls.isNotEmpty
                            ? NetworkImage(urls.first)
                            : null,
                        onBackgroundImageError:
                            urls.isNotEmpty ? (_, _) {} : null,
                        child: urls.isEmpty
                            ? Text(
                                initial,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            shadows: [
                              Shadow(blurRadius: 2, color: Colors.black54),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 18,
                child: IgnorePointer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (headline.isNotEmpty)
                        Text(
                          headline,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                            shadows: [
                              Shadow(blurRadius: 3, color: Colors.black54),
                            ],
                          ),
                        ),
                      if (meta != null && meta!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          meta!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            shadows: const [
                              Shadow(blurRadius: 2, color: Colors.black45),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static int _hashHue(String seed) {
    var h = 0;
    for (final c in seed.codeUnits) {
      h = (h * 31 + c) % 360;
    }
    return h;
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.hue, required this.initial});
  final int hue;
  final String initial;

  @override
  Widget build(BuildContext context) {
    final c1 = HSLColor.fromAHSL(1, hue.toDouble(), 0.18, 0.32).toColor();
    final c2 = HSLColor.fromAHSL(1, hue.toDouble(), 0.14, 0.18).toColor();
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c1, c2],
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }
}
