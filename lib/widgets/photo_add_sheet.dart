import 'package:flutter/material.dart';

import '../theme.dart';

enum PhotoAddSource { album, camera }

Future<PhotoAddSource?> showPhotoAddSheet(BuildContext context) {
  return showModalBottomSheet<PhotoAddSource>(
    context: context,
    backgroundColor: AppTheme.background,
    showDragHandle: true,
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '사진 추가',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                '앨범에서 고르거나 카메라로 바로 촬영할 수 있어요.',
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.muted,
                      height: 1.45,
                    ),
              ),
              const SizedBox(height: 20),
              _SourceTile(
                icon: Icons.photo_library_outlined,
                title: '앨범에서 선택',
                subtitle: '기기에 저장된 사진 중에서 고릅니다',
                onTap: () => Navigator.pop(ctx, PhotoAddSource.album),
              ),
              const SizedBox(height: 10),
              _SourceTile(
                icon: Icons.photo_camera_outlined,
                title: '카메라로 촬영',
                subtitle: '지금 찍은 사진을 프로필에 올립니다',
                onTap: () => Navigator.pop(ctx, PhotoAddSource.camera),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('취소'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.panel,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: AppTheme.touchMin,
                height: AppTheme.touchMin,
                decoration: BoxDecoration(
                  color: AppTheme.brandSoft,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(icon, color: AppTheme.brand),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.muted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.muted),
            ],
          ),
        ),
      ),
    );
  }
}
