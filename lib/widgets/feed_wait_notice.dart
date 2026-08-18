import 'package:flutter/material.dart';

import '../theme.dart';

/// Web `FeedWaitNotice` parity.
class FeedWaitNotice extends StatelessWidget {
  const FeedWaitNotice({super.key, this.justRegistered = false});

  final bool justRegistered;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 48),
        if (justRegistered) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F0EC),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Text(
              '프로필이 저장되었어요.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.success,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        Text(
          '프로필을 등록해 주셔서 감사합니다',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 16),
        Text(
          '프로필을 등록해 주셔서 진심으로 감사드립니다. 원활한 소개팅 서비스를 위해 플랫폼을 구축 중이며, 베타 서비스 오픈 시 빠르게 공지해 드리겠습니다.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.55,
                color: AppTheme.muted,
              ),
        ),
      ],
    );
  }
}
