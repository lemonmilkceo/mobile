import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/api_client.dart';
import '../services/mock_data.dart';
import '../services/profile_repository.dart';
import '../services/push_service.dart';
import '../services/session.dart';
import '../theme.dart';
import '../widgets/photo_pager.dart';
import 'chat_room_screen.dart';
import 'report_screen.dart';

/// Shared profile surface for feed browse + inbox interest detail.
class CandidateDetailScreen extends StatefulWidget {
  const CandidateDetailScreen({
    super.key,
    required this.userId,
    this.interestId,
  });

  final String userId;

  /// When set (받은/보낸 소개), show respond/contact instead of 「소개해주세요」.
  final String? interestId;

  @override
  State<CandidateDetailScreen> createState() => _CandidateDetailScreenState();
}

class _CandidateDetailScreenState extends State<CandidateDetailScreen> {
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _interest;
  String? _roomId;
  String? _myGender;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  bool get _isInterest => widget.interestId != null;

  PushService? _push;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _push ??= context.read<AppSession>().push;
    final id = widget.interestId;
    if (id != null) {
      _push!.viewingInterestId = id;
      _push!.dismissBanner();
    }
  }

  @override
  void dispose() {
    if (_push?.viewingInterestId == widget.interestId) {
      _push!.viewingInterestId = null;
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = context.read<AppSession>();
      if (session.isMock) {
        _myGender = MockData.me['gender']?.toString();
        _profile = MockData.profileByUserId(widget.userId);
        if (_isInterest) {
          final res = MockData.interestDetail(widget.interestId!);
          _interest = Map<String, dynamic>.from(res['interest'] as Map);
          _roomId = res['roomId']?.toString();
          // Prefer richer counterpart from interest payload if profile thin
          final cp = res['counterpart'];
          if (cp is Map && (_profile == null || _profile!.isEmpty)) {
            _profile = Map<String, dynamic>.from(cp);
          } else if (cp is Map && _profile != null) {
            _profile = {..._profile!, ...Map<String, dynamic>.from(cp)};
          }
        }
      } else {
        final repo = ProfileRepository(Supabase.instance.client);
        final me = await repo.fetchMyProfile();
        _myGender = me?['gender']?.toString();
        _profile = await repo.fetchCandidate(widget.userId);
        if (_isInterest) {
          final res = await session.api
              .get('/api/mobile/interest/${widget.interestId}');
          _interest = Map<String, dynamic>.from(res['interest'] as Map);
          _roomId = res['roomId']?.toString();
          final cp = res['counterpart'];
          if (cp is Map) {
            final merged = Map<String, dynamic>.from(cp);
            if (_profile != null) {
              final keep = photoUrlsFrom(_profile);
              final extra = photoUrlsFrom(merged);
              _profile = {...merged, ..._profile!};
              if (keep.isEmpty && extra.isNotEmpty) {
                _profile!['photo_urls'] = extra;
                _profile!['photo_url'] = extra.first;
              }
            } else {
              _profile = merged;
            }
          }
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmRequest() async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '소개를 요청할까요?',
              style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              context.read<AppSession>().memberState?['copy']?['applyNotice']
                      ?.toString() ??
                  '진행 중인 소개는 한 건만 보낼 수 있습니다. 상대는 12시간 안에 답합니다. 수락되면 채팅방이 열리고 14일 동안 새 소개가 없습니다.',
              style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.muted,
                    height: 1.45,
                  ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('신중히 요청하기'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) await _request();
  }

  Future<void> _request() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final session = context.read<AppSession>();
      if (session.isMock) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('프로토타입: 소개 요청을 시뮬레이션했어요.')),
        );
        Navigator.of(context).pop();
        return;
      }
      await session.api.post('/api/mobile/interest', {
        'toUserId': widget.userId,
      });
      await session.refreshMemberState();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('소개 요청이 전달되었습니다. 상대에게 앱 알림이 발송됩니다.'),
        ),
      );
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _respond(String action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final session = context.read<AppSession>();
      if (session.isMock) {
        setState(() {
          _interest = {
            ...?_interest,
            'status': action == 'accept' ? 'matched' : 'declined',
          };
          if (action == 'accept') {
            _roomId = 'mock-room';
          }
        });
        return;
      }
      final res = await session.api.post('/api/mobile/interest/respond', {
        'interestId': widget.interestId,
        'action': action,
      });
      await session.refreshMemberState();
      await _load();
      final roomId = res['roomId']?.toString();
      if (action == 'accept' && roomId != null && roomId.isNotEmpty && mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ChatRoomScreen(
              roomId: roomId,
              title: _profile?['nickname']?.toString() ?? '채팅',
              counterpartId: widget.userId,
            ),
          ),
        );
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
        return _interest?['close_reason'] == 'withdrawn' ? '철회됨' : '종료';
      default:
        return status ?? '';
    }
  }

  String? _remainingLabel() {
    final iso = _interest?['expires_at']?.toString();
    if (iso == null || iso.isEmpty) return null;
    final dt = DateTime.tryParse(iso);
    if (dt == null) return null;
    final left = dt.difference(DateTime.now());
    if (left.isNegative) return '응답 기한이 지났습니다';
    final h = left.inHours;
    final m = left.inMinutes.remainder(60);
    return '남은 시간 $h시간 $m분';
  }

  Future<void> _withdraw() async {
    final tickets =
        context.read<AppSession>().memberState?['economy']?['withdrawTickets'];
    final count = tickets is num ? tickets.toInt() : 0;
    if (count < 1) {
      setState(() => _error = '이번 달 철회권을 모두 사용했습니다.');
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('소개를 철회할까요?'),
        content: const Text('철회해도 크레딧은 돌아오지 않습니다. 철회권 1개가 사용됩니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('철회')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final session = context.read<AppSession>();
      await session.api.post('/api/mobile/interest/withdraw', {
        'interestId': widget.interestId,
      });
      await session.refreshMemberState();
      if (!mounted) return;
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _block() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('이 회원을 차단할까요?'),
        content: const Text('차단하면 서로 소개가 오지 않습니다. 제재는 아닙니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('차단')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<AppSession>().api.post('/api/mobile/blocks', {
        'userId': widget.userId,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('차단했습니다.')),
      );
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    }
  }

  void _openReport() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReportScreen(
          targetUserId: widget.userId,
          interestId: widget.interestId,
        ),
      ),
    );
  }

  void _openChat() {
    final id = _roomId;
    if (id == null || id.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatRoomScreen(
          roomId: id,
          title: _profile?['nickname']?.toString() ?? '채팅',
          counterpartId: widget.userId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = _profile;
    final photos = photoUrlsFrom(p);
    final nickname = p?['nickname']?.toString() ?? '프로필';
    final year = p?['birth_year'];
    final age = (year is num && p?['show_birth_year'] != false)
        ? DateTime.now().year - year.toInt()
        : null;
    final status = _interest?['status']?.toString();
    final meId = context.watch<AppSession>().user?.id;
    final canRespond = _isInterest &&
        status == 'offered' &&
        (_interest?['to_user_id']?.toString() == meId ||
            (_interest?['to_user_id'] == null && _myGender == 'female'));
    final canWithdraw = _isInterest &&
        status == 'offered' &&
        _myGender == 'male' &&
        (_interest?['from_user_id']?.toString() == meId ||
            _interest?['from_user_id'] == null);
    final canRequest = !_isInterest && _myGender == 'male';

    return Scaffold(
      appBar: AppBar(
        title: Text(_isInterest ? '소개 프로필' : '인물'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'report') _openReport();
              if (v == 'block') _block();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'report', child: Text('신고')),
              PopupMenuItem(value: 'block', child: Text('차단')),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : p == null
              ? Center(
                  child: Text(_error ?? '프로필을 찾을 수 없습니다.'),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          AspectRatio(
                            aspectRatio: 4 / 5,
                            child: PhotoPager(
                              urls: photos,
                              placeholder: _InitialHero(nickname: nickname),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_isInterest && status != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.brandSoft,
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: Text(
                                      _statusLabel(status),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.brand,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                Text(
                                  age != null ? '$nickname, $age' : nickname,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  [
                                    if (p['show_job'] != false) p['job'],
                                    if (p['show_district'] != false)
                                      p['district'],
                                  ].whereType<String>().join(' · '),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(color: AppTheme.muted),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  '기본 정보',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 12),
                                ..._cells(p).map(
                                  (cell) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 88,
                                          child: Text(
                                            cell.$1,
                                            style: const TextStyle(
                                              color: AppTheme.muted,
                                            ),
                                          ),
                                        ),
                                        Expanded(child: Text(cell.$2)),
                                      ],
                                    ),
                                  ),
                                ),
                                if (canRespond) ...[
                                  const SizedBox(height: 20),
                                  Text(
                                    context
                                            .watch<AppSession>()
                                            .memberState?['copy']?['receiveNotice']
                                            ?.toString() ??
                                        '지금 이 소개만 보고 계십니다. 12시간 안에 수락 또는 거절해 주세요.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppTheme.muted,
                                          height: 1.5,
                                        ),
                                  ),
                                  if (_remainingLabel() != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      _remainingLabel()!,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                                if (_error != null) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    _error!,
                                    style: const TextStyle(
                                      color: AppTheme.danger,
                                    ),
                                  ),
                                ],
                                if (canRequest) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    '요청하면 상대에게 앱 알림으로 디지털 프로필이 전달됩니다.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: AppTheme.muted),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                        child: _isInterest
                            ? Column(
                                children: [
                                  if (canRespond) ...[
                                    SizedBox(
                                      width: double.infinity,
                                      height: AppTheme.touchMin,
                                      child: FilledButton(
                                        onPressed: _busy
                                            ? null
                                            : () => _respond('accept'),
                                        child: Text(
                                          _busy ? '처리 중…' : '수락하고 채팅 시작',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: double.infinity,
                                      height: AppTheme.touchMin,
                                      child: OutlinedButton(
                                        onPressed: _busy
                                            ? null
                                            : () => _respond('reject'),
                                        child: const Text('거절'),
                                      ),
                                    ),
                                  ],
                                  if (status == 'matched' &&
                                      _roomId != null &&
                                      _roomId!.isNotEmpty) ...[
                                    SizedBox(
                                      width: double.infinity,
                                      height: AppTheme.touchMin,
                                      child: FilledButton(
                                        onPressed: _openChat,
                                        child: const Text('채팅하기'),
                                      ),
                                    ),
                                  ],
                                  if (canWithdraw) ...[
                                    if (canRespond) const SizedBox(height: 10),
                                    SizedBox(
                                      width: double.infinity,
                                      height: AppTheme.touchMin,
                                      child: OutlinedButton(
                                        onPressed: _busy ||
                                                (context
                                                            .watch<AppSession>()
                                                            .memberState?['economy']
                                                        ?['withdrawTickets'] ??
                                                    0) ==
                                                0
                                            ? null
                                            : _withdraw,
                                        child: Text(
                                          (context
                                                          .watch<AppSession>()
                                                          .memberState?['economy']
                                                      ?['withdrawTickets'] ??
                                                  0) ==
                                              0
                                              ? '철회권 없음'
                                              : '신청 철회',
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              )
                            : (canRequest
                                ? SizedBox(
                                    width: double.infinity,
                                    height: AppTheme.touchMin,
                                    child: FilledButton(
                                      onPressed:
                                          _busy ? null : _confirmRequest,
                                      child: Text(
                                        _busy ? '요청 중…' : '소개해주세요',
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink()),
                      ),
                    ),
                  ],
                ),
    );
  }

  List<(String, String)> _cells(Map<String, dynamic> p) {
    return [
      if (p['show_birth_year'] != false && p['birth_year'] != null)
        ('출생연도', '${p['birth_year']}'),
      if (p['show_height'] != false && p['height_cm'] != null)
        ('키', '${p['height_cm']}cm'),
      if (p['show_school'] != false && p['school'] != null)
        ('학교', '${p['school']}'),
      if (p['show_job'] != false && p['job'] != null) ('직업', '${p['job']}'),
      if (p['show_district'] != false && p['district'] != null)
        ('지역', '${p['district']}'),
      if (p['show_mbti'] != false && p['mbti'] != null) ('MBTI', '${p['mbti']}'),
    ];
  }
}

class _InitialHero extends StatelessWidget {
  const _InitialHero({required this.nickname});
  final String nickname;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.panel,
      alignment: Alignment.center,
      child: Text(
        String.fromCharCodes(nickname.runes.take(1)),
        style: const TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
