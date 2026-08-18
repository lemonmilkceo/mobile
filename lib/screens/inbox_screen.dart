import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/mock_data.dart';
import '../services/session.dart';
import '../theme.dart';
import 'candidate_detail_screen.dart';
import 'interest_detail_screen.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key, this.highlightInterestId, this.shareToken});

  final String? highlightInterestId;
  final String? shareToken;

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  var _segment = 0; // 0 received, 1 sent
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _received = [];
  List<Map<String, dynamic>> _sent = [];

  @override
  void initState() {
    super.initState();
    _load().then((_) {
      if (widget.shareToken != null) {
        _openByShareToken(widget.shareToken!);
      } else if (widget.highlightInterestId != null) {
        _openInterest(widget.highlightInterestId!);
      }
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = context.read<AppSession>();
      if (session.isMock) {
        _received = MockData.inboxReceived
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _sent =
            MockData.inboxSent.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        final res = await session.api.get('/api/mobile/interest/inbox');
        _received = List<Map<String, dynamic>>.from(
          (res['received'] as List?) ?? [],
        );
        _sent = List<Map<String, dynamic>>.from((res['sent'] as List?) ?? []);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openByShareToken(String token) {
    final all = [..._received, ..._sent];
    final hit = all.cast<Map<String, dynamic>?>().firstWhere(
          (r) =>
              r?['share_token'] == token || r?['male_contact_token'] == token,
          orElse: () => null,
        );
    if (hit != null) {
      _openInterest(hit['id'] as String);
    }
  }

  Future<void> _openInterest(String id) async {
    final all = [..._received, ..._sent];
    final item = all.cast<Map<String, dynamic>?>().firstWhere(
          (r) => r?['id'] == id,
          orElse: () => null,
        );
    final session = context.read<AppSession>();
    String? userId = _counterpartUserId(item);

    // Real API: load detail once to resolve counterpart user_id if missing
    if (userId == null && !session.isMock) {
      try {
        final res = await session.api.get('/api/mobile/interest/$id');
        final cp = res['counterpart'];
        if (cp is Map) {
          userId = cp['user_id']?.toString();
        }
        final interest = res['interest'];
        if (userId == null && interest is Map) {
          final me = session.user?.id;
          final from = interest['from_user_id']?.toString();
          final to = interest['to_user_id']?.toString();
          if (me != null && from != null && to != null) {
            userId = me == from ? to : from;
          }
        }
      } catch (_) {}
    }

    if (!mounted) return;
    if (userId == null || userId.isEmpty) {
      // Fallback sparse detail
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => InterestDetailScreen(interestId: id),
        ),
      );
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CandidateDetailScreen(
            userId: userId!,
            interestId: id,
          ),
        ),
      );
    }
    _load();
  }

  String? _counterpartUserId(Map<String, dynamic>? item) {
    if (item == null) return null;
    final raw = item['counterpart'];
    if (raw is Map && raw['user_id'] != null) {
      return raw['user_id'].toString();
    }
    final session = context.read<AppSession>();
    final me = session.isMock ? 'mock-me' : session.user?.id;
    final from = item['from_user_id']?.toString();
    final to = item['to_user_id']?.toString();
    if (me != null && from != null && to != null) {
      return me == from ? to : from;
    }
    return item['counterpart_user_id']?.toString() ??
        item['from_user_id']?.toString();
  }

  ({String? nickname, String? job, String? photoUrl}) _meta(
    Map<String, dynamic> item,
  ) {
    final raw = item['counterpart'];
    final Map<String, dynamic>? nested =
        raw is Map ? Map<String, dynamic>.from(raw) : null;
    String? nick = nested?['nickname']?.toString() ??
        item['nickname']?.toString() ??
        item['counterpart_nickname']?.toString();
    String? job = nested?['job']?.toString() ??
        item['job']?.toString() ??
        item['counterpart_job']?.toString();
    String? photo = nested?['photo_url']?.toString() ??
        item['photo_url']?.toString() ??
        item['counterpart_photo_url']?.toString();
    if (nick != null && nick.isEmpty) nick = null;
    if (job != null && job.isEmpty) job = null;
    if (photo != null && photo.isEmpty) photo = null;
    return (nickname: nick, job: job, photoUrl: photo);
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'offered':
        return '응답 대기';
      case 'matched':
        return '수락됨';
      case 'declined':
        return '거절됨';
      case 'expired':
        return '만료';
      case 'closed':
        return '종료';
      default:
        return status ?? '';
    }
  }

  String _statusLabelFor(Map<String, dynamic> item) {
    final status = item['status']?.toString();
    if (status == 'closed' && item['close_reason'] == 'withdrawn') {
      return '철회됨';
    }
    if (status == 'closed' && item['close_reason'] == 'rejected') {
      return '거절됨';
    }
    if (status == 'offered') {
      final remain = _remaining(item['expires_at']?.toString());
      if (remain != null) return remain;
    }
    return _statusLabel(status);
  }

  String? _remaining(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    final dt = DateTime.tryParse(iso);
    if (dt == null) return null;
    final left = dt.difference(DateTime.now());
    if (left.isNegative) return '기한 만료';
    return '남은 시간 ${left.inHours}시간 ${left.inMinutes.remainder(60)}분';
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'matched':
        return AppTheme.success;
      case 'declined':
      case 'expired':
        return AppTheme.muted;
      case 'offered':
        return AppTheme.brand;
      default:
        return AppTheme.muted;
    }
  }

  String _relativeDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes.clamp(1, 59)}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return '${dt.month}.${dt.day}';
  }

  @override
  Widget build(BuildContext context) {
    final items = _segment == 0 ? _received : _sent;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '소개',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.8,
                          height: 1.1,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '요청과 응답을 한곳에서 확인하세요',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.muted,
                        ),
                  ),
                  if (_segment == 0 &&
                      _received.any((e) => e['status'] == 'offered'))
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        context
                                .watch<AppSession>()
                                .memberState?['copy']?['receiveNotice']
                                ?.toString() ??
                            '지금 이 소개만 보고 계십니다. 12시간 안에 수락 또는 거절해 주세요.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.muted,
                              height: 1.45,
                            ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
              child: _SegmentControl(
                labels: const ['받은 소개', '보낸 소개'],
                index: _segment,
                onChanged: (i) => setState(() => _segment = i),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppTheme.danger),
                ),
              ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                  : RefreshIndicator(
                      color: AppTheme.ink,
                      onRefresh: _load,
                      child: items.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(
                                  height:
                                      MediaQuery.sizeOf(context).height * 0.35,
                                ),
                                _EmptyState(
                                  title: _segment == 0
                                      ? '아직 받은 소개가 없어요'
                                      : '보낸 소개가 없어요',
                                  body: _segment == 0
                                      ? '소개 요청이 오면 여기에 표시됩니다.'
                                      : '인물 탭에서 소개를 요청해 보세요.',
                                ),
                              ],
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                              itemCount: items.length,
                              itemBuilder: (context, i) {
                                final item = items[i];
                                final meta = _meta(item);
                                final status = item['status']?.toString();
                                final title = meta.nickname ??
                                    meta.job ??
                                    (_segment == 0 ? '소개 요청' : '보낸 소개');
                                final subtitle = [
                                  if (meta.nickname != null && meta.job != null)
                                    meta.job!,
                                  _relativeDate(
                                    item['offered_at']?.toString(),
                                  ),
                                ].where((s) => s.isNotEmpty).join(' · ');

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _InterestRow(
                                    title: title,
                                    subtitle: subtitle,
                                    photoUrl: meta.photoUrl,
                                    statusLabel: _statusLabelFor(item),
                                    statusColor: _statusColor(status),
                                    onTap: () =>
                                        _openInterest(item['id'] as String),
                                  ),
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentControl extends StatelessWidget {
  const _SegmentControl({
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final selected = i == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.background : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? AppTheme.ink : AppTheme.muted,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _InterestRow extends StatelessWidget {
  const _InterestRow({
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.statusColor,
    required this.onTap,
    this.photoUrl,
  });

  final String title;
  final String subtitle;
  final String statusLabel;
  final Color statusColor;
  final String? photoUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initial =
        title.isNotEmpty ? String.fromCharCodes(title.runes.take(1)) : '?';

    return Material(
      color: AppTheme.background,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.line),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: photoUrl != null
                        ? Image.network(
                            photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, error, stack) =>
                                _AvatarFallback(initial: initial),
                          )
                        : _AvatarFallback(initial: initial),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.muted,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.muted,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.initial});
  final String initial;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.panel,
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.ink,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppTheme.brandSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mail_outline_rounded,
              color: AppTheme.brand,
              size: 28,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.muted,
                  height: 1.45,
                ),
          ),
        ],
      ),
    );
  }
}
