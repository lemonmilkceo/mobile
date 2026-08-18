import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/mock_data.dart';
import '../services/profile_repository.dart';
import '../services/session.dart';
import '../theme.dart';
import '../widgets/economy_header.dart';
import '../widgets/feed_wait_notice.dart';
import '../widgets/media_card.dart';
import '../widgets/photo_pager.dart';
import 'candidate_detail_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  bool _loading = true;
  bool _waitNotice = true;
  String? _error;
  Map<String, dynamic>? _me;
  List<Map<String, dynamic>> _candidates = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  int? _age(Map<String, dynamic> c) {
    final y = c['birth_year'];
    if (y is! int && y is! num) return null;
    if (c['show_birth_year'] == false) return null;
    return DateTime.now().year - (y as num).toInt();
  }

  String _headline(Map<String, dynamic> c) {
    final job = c['show_job'] == false ? null : c['job']?.toString();
    final school = c['show_school'] == false ? null : c['school']?.toString();
    if (job != null && job.isNotEmpty) return job;
    if (school != null && school.isNotEmpty) return school;
    return '프로필을 확인해 보세요';
  }

  String? _meta(Map<String, dynamic> c) {
    final parts = <String>[
      if (c['show_district'] != false && c['district'] != null)
        c['district'].toString(),
      if (c['show_height'] != false && c['height_cm'] != null)
        '${c['height_cm']}cm',
    ];
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final session = context.read<AppSession>();
    try {
      if (session.isMock) {
        _waitNotice = false;
        _me = Map<String, dynamic>.from(MockData.me);
        _candidates = MockData.candidatesFor(MockData.me['gender']?.toString());
      } else {
        final repo = ProfileRepository(Supabase.instance.client);
        try {
          final health = await session.health();
          _waitNotice = health['feedWaitNotice'] == true;
        } catch (_) {
          _waitNotice = false;
        }
        _me = await repo.fetchMyProfile();
        final gender = _me?['gender']?.toString();
        // Flutter-only: both genders browse the opposite-gender feed.
        if (gender == 'male') {
          final feed = await session.api.get('/api/mobile/feed');
          _candidates = List<Map<String, dynamic>>.from(
            (feed['candidates'] as List?) ?? [],
          );
        } else {
          _candidates = [];
        }
        await session.refreshMemberState();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('인물'),
        actions: const [EconomyHeader(), SizedBox(width: 8)],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppTheme.danger),
                      ),
                    ),
                  if (_me?['gender'] == null)
                    const _GuideCard(
                      title: '성별을 먼저 설정해 주세요',
                      body: '내 정보에서 프로필을 저장하면 인물을 볼 수 있어요.',
                    )
                  else ...[
                    if (_me?['gender'] == 'female')
                      const _GuideCard(
                        title: '소개가 오면 알려드릴게요',
                        body:
                            '여성 회원은 인물을 둘러보지 않습니다. 소개가 도착하면 받은 소개 탭과 알림으로 확인할 수 있습니다.\n\n12시간 안에 수락 또는 거절해 주세요. 수락되면 채팅방이 열리고, 전화번호는 공개되지 않습니다.',
                      )
                    else ...[
                    if (_me?['profile_complete'] != true ||
                        _me?['matching_status'] != 'active')
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.panel,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMd),
                          ),
                          child: const Text(
                            '소개를 요청하려면 프로필을 완료하고 매칭 가능 상태여야 합니다. 목록은 미리 볼 수 있어요.',
                            style: TextStyle(height: 1.45),
                          ),
                        ),
                      ),
                    if (_waitNotice)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: FeedWaitNotice(),
                      ),
                    if (_candidates.isEmpty)
                      const _GuideCard(
                        title: '아직 보여줄 분이 없어요',
                        body: '이성 프로필이 등록되면 여기에 표시됩니다.',
                      )
                    else
                      ..._candidates.map((c) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: MediaCard(
                            name: c['nickname']?.toString() ?? '회원',
                            age: _age(c),
                            headline: _headline(c),
                            meta: _meta(c),
                            photoUrl: c['photo_url']?.toString(),
                            photoUrls: photoUrlsFrom(c),
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => CandidateDetailScreen(
                                    userId: c['user_id'] as String,
                                  ),
                                ),
                              );
                              _load();
                            },
                          ),
                        );
                      }),
                    ],
                  ],
                ],
              ),
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.muted,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}
