import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../services/mock_data.dart';
import '../services/profile_repository.dart';
import '../services/session.dart';
import '../theme.dart';
import 'photos_screen.dart';
import 'profile_edit_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, dynamic>? _me;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final session = context.read<AppSession>();
    if (session.isMock) {
      _me = Map<String, dynamic>.from(MockData.me);
      if (mounted) setState(() => _loading = false);
      return;
    }
    final repo = ProfileRepository(Supabase.instance.client);
    _me = await repo.fetchMyProfile();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _toggleMatching(bool active) async {
    if (context.read<AppSession>().isMock) {
      setState(() {
        _me = {...?_me, 'matching_status': active ? 'active' : 'paused'};
      });
      return;
    }
    final repo = ProfileRepository(Supabase.instance.client);
    await repo.setMatchingStatus(active ? 'active' : 'paused');
    await _load();
  }

  Future<void> _withdraw() async {
    final first = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('회원탈퇴'),
        content: const Text(
          '탈퇴하면 계정, 프로필, 사진, 소개 기록이 바로 삭제됩니다. 같은 이메일로 다시 가입하려면 새 초대 코드가 필요합니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('계속'),
          ),
        ],
      ),
    );
    if (first != true || !mounted) return;

    final second = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('정말 탈퇴할까요?'),
        content: const Text('이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('탈퇴합니다'),
          ),
        ],
      ),
    );
    if (second != true || !mounted) return;

    final session = context.read<AppSession>();
    if (session.isMock) {
      await session.signOut();
      return;
    }
    try {
      await session.api.post('/api/mobile/me/withdraw');
      if (!mounted) return;
      await session.signOut();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _openExternal(String path) async {
    await launchUrl(
      Uri.parse('${AppConfig.apiBase}$path'),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final matching = _me?['matching_status'] == 'active';
    final complete = _me?['profile_complete'] == true;
    final nick = _me?['nickname']?.toString() ?? '회원';
    final job = _me?['job']?.toString() ?? '';
    final district = _me?['district']?.toString() ?? '';
    final meta = [if (job.isNotEmpty) job, if (district.isNotEmpty) district]
        .join(' · ');
    final photo = _me?['photo_url']?.toString();
    final initial =
        nick.isNotEmpty ? String.fromCharCodes(nick.runes.take(1)) : '?';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                children: [
                  Text(
                    '내 정보',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.8,
                          height: 1.1,
                        ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        child: SizedBox(
                          width: 72,
                          height: 72,
                          child: photo != null && photo.isNotEmpty
                              ? Image.network(
                                  photo,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, error, stack) =>
                                      _InitialBlock(initial: initial),
                                )
                              : _InitialBlock(initial: initial),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nick,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.4,
                              ),
                            ),
                            if (meta.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                meta,
                                style: const TextStyle(
                                  color: AppTheme.muted,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: complete
                                    ? AppTheme.success.withValues(alpha: 0.1)
                                    : AppTheme.brandSoft,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                complete
                                    ? (matching ? '매칭 가능' : '매칭 중지')
                                    : '프로필 미완성',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: complete
                                      ? AppTheme.success
                                      : AppTheme.brand,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionTile(
                          label: '프로필 수정',
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ProfileEditScreen(),
                              ),
                            );
                            _load();
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActionTile(
                          label: '사진 관리',
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const PhotosScreen(),
                              ),
                            );
                            _load();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const _SectionLabel('매칭'),
                  const SizedBox(height: 10),
                  _SettingsGroup(
                    children: [
                      _SettingsToggle(
                        title: '매칭 받기',
                        subtitle: '끄면 소개 대상에서 제외됩니다',
                        value: matching,
                        onChanged: complete ? _toggleMatching : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  if (context.watch<AppSession>().isAdmin) ...[
                    const _SectionLabel('운영'),
                    const SizedBox(height: 10),
                    _SettingsGroup(
                      children: [
                        _SettingsLink(
                          title: '운영 콘솔',
                          onTap: () =>
                              context.read<AppSession>().enterAdminConsole(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                  ],
                  const _SectionLabel('지원'),
                  const SizedBox(height: 10),
                  _SettingsGroup(
                    children: [
                      _SettingsLink(
                        title: '이용약관',
                        onTap: () => _openExternal('/terms'),
                      ),
                      _SettingsLink(
                        title: '개인정보 처리방침',
                        onTap: () => _openExternal('/privacy'),
                      ),
                      _SettingsLink(
                        title: '신고 · 문의',
                        onTap: () => _openExternal('/report'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const _SectionLabel('계정'),
                  const SizedBox(height: 10),
                  _SettingsGroup(
                    children: [
                      _SettingsLink(
                        title: '온보딩 다시 보기',
                        subtitle: '다음 실행 시 소개 화면부터',
                        onTap: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.remove('onboarding_done_v1');
                          await prefs.remove('onboarding_done_v2');
                          await prefs.remove('onboarding_done_v3');
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('온보딩이 초기화됐어요. 앱을 다시 실행해 주세요.'),
                            ),
                          );
                        },
                      ),
                      _SettingsLink(
                        title: '회원탈퇴',
                        destructive: true,
                        onTap: _withdraw,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (context.watch<AppSession>().isMock)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: FilledButton(
                        onPressed: () async {
                          await context.read<AppSession>().signOut();
                        },
                        child: const Text('실제 계정으로 로그인'),
                      ),
                    ),
                  TextButton(
                    onPressed: () async {
                      final session = context.read<AppSession>();
                      await session.push.unregisterCurrent();
                      await session.signOut();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.ink,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      '로그아웃',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _InitialBlock extends StatelessWidget {
  const _InitialBlock({required this.initial});
  final String initial;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.panel,
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: AppTheme.ink,
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.panel,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: SizedBox(
          height: 52,
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.muted,
        letterSpacing: 0.2,
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              const Divider(height: 1, thickness: 1, color: AppTheme.line),
          ],
        ],
      ),
    );
  }
}

class _SettingsLink extends StatelessWidget {
  const _SettingsLink({
    required this.title,
    required this.onTap,
    this.subtitle,
    this.destructive = false,
  });

  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: destructive ? AppTheme.danger : AppTheme.ink,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: destructive ? AppTheme.danger : AppTheme.muted,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  const _SettingsToggle({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: AppTheme.muted),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: AppTheme.ink,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
