import 'package:flutter/material.dart';

import '../theme.dart';

List<String> photoUrlsFrom(Map<String, dynamic>? data, {String? fallback}) {
  if (data != null) {
    final raw = data['photo_urls'] ?? data['photoUrls'];
    if (raw is List) {
      final urls = raw
          .map((e) => e.toString())
          .where((s) => s.isNotEmpty)
          .toList();
      if (urls.isNotEmpty) return urls;
    }
  }
  final one = fallback ?? data?['photo_url']?.toString();
  if (one != null && one.isNotEmpty) return [one];
  return [];
}

/// Horizontal photo pager with Instagram-style top segment indicators.
class PhotoPager extends StatefulWidget {
  const PhotoPager({
    super.key,
    required this.urls,
    this.onTap,
    this.placeholder,
    this.fit = BoxFit.cover,
  });

  final List<String> urls;
  final VoidCallback? onTap;
  final Widget? placeholder;
  final BoxFit fit;

  @override
  State<PhotoPager> createState() => _PhotoPagerState();
}

class _PhotoPagerState extends State<PhotoPager> {
  var _index = 0;

  @override
  void didUpdateWidget(covariant PhotoPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.urls != widget.urls) {
      _index = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.urls;
    if (urls.isEmpty) {
      return widget.placeholder ?? const ColoredBox(color: AppTheme.panel);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          itemCount: urls.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (context, i) {
            return GestureDetector(
              onTap: widget.onTap,
              child: Image.network(
                urls[i],
                fit: widget.fit,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, _, _) =>
                    widget.placeholder ??
                    const ColoredBox(color: AppTheme.panel),
              ),
            );
          },
        ),
        if (urls.length > 1)
          Positioned(
            left: 12,
            right: 12,
            top: 10,
            child: Row(
              children: [
                for (var i = 0; i < urls.length; i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: i == 0 ? 0 : 3,
                        right: i == urls.length - 1 ? 0 : 3,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        height: 3,
                        decoration: BoxDecoration(
                          color: i == _index
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
