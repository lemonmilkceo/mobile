import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/session.dart';
import '../theme.dart';
import 'admin_common.dart';

class AdminFeedDetailScreen extends StatefulWidget {
  const AdminFeedDetailScreen({super.key, required this.userId});

  final String userId;

  @override
  State<AdminFeedDetailScreen> createState() => _AdminFeedDetailScreenState();
}

class _AdminFeedDetailScreenState extends State<AdminFeedDetailScreen> {
  var _loading = true;
  String? _error;
  Map<String, dynamic> _profile = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final session = context.read<AppSession>();
    try {
      if (session.isMock) {
        final matches = mockAdminFeedProfiles.where(
          (p) =>
              adminStr(p, const ['userId', 'user_id', 'id']) == widget.userId,
        );
        if (matches.isEmpty) {
          _profile = {};
          _error = '프로필을 찾을 수 없습니다.';
        } else {
          _profile = Map<String, dynamic>.from(matches.first);
        }
      } else {
        final res = await session.api.get(
          '/api/mobile/admin/feeds/${widget.userId}',
        );
        _profile = adminMap(res['profile']) ?? res;
      }
    } catch (e) {
      _error = adminErrorMessage(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _displayName {
    return adminStr(_profile, const ['legalName', 'legal_name']) ??
        adminStr(_profile, const ['nickname']) ??
        '회원';
  }

  List<Map<String, dynamic>> get _keywords {
    return adminListValue(_profile['keywords'] ?? _profile['keyword']);
  }

  @override
  Widget build(BuildContext context) {
    final photos = adminPhotoUrls(_profile);
    final legalName = adminStr(_profile, const ['legalName', 'legal_name']);
    final nickname = adminStr(_profile, const ['nickname']);
    final email = adminStr(_profile, const ['email']);
    final phone = adminStr(_profile, const ['phone']);
    final gender = adminGenderLabel(adminStr(_profile, const ['gender']));
    final birthYear = adminInt(_profile, const ['birthYear', 'birth_year']);
    final height = adminInt(_profile, const ['heightCm', 'height_cm']);
    final school = adminStr(_profile, const ['school']);
    final job = adminStr(_profile, const ['job']);
    final district = adminStr(_profile, const ['district']);
    final mbti = adminStr(_profile, const ['mbti']);
    final bio = adminStr(_profile, const ['bio']);
    final status = adminMemberStatusLabel(
      adminStr(_profile, const ['matchingStatus', 'matching_status']),
    );

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AdminSubpageBar(title: _loading ? '프로필' : _displayName),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : RefreshIndicator(
              color: AppTheme.ink,
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
                children: [
                  if (_error != null) ...[
                    Text(
                      _error!,
                      style: const TextStyle(color: AppTheme.danger),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _PhotoPager(urls: photos),
                  const SizedBox(height: 20),
                  AdminPanelCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Field(label: '본명', value: legalName ?? '미등록'),
                        _Field(label: '닉네임', value: nickname ?? '미등록'),
                        _Field(label: '이메일', value: email ?? '미등록'),
                        _Field(label: '전화', value: phone ?? '미등록'),
                        if (gender.isNotEmpty)
                          _Field(label: '성별', value: gender),
                        if (birthYear > 0)
                          _Field(label: '출생연도', value: '$birthYear'),
                        if (height > 0) _Field(label: '키', value: '$height cm'),
                        if (school != null) _Field(label: '학교', value: school),
                        if (job != null) _Field(label: '직업', value: job),
                        if (district != null)
                          _Field(label: '지역', value: district),
                        if (mbti != null) _Field(label: 'MBTI', value: mbti),
                        if (status.isNotEmpty)
                          _Field(label: '매칭 상태', value: status),
                        if (bio != null) ...[
                          const SizedBox(height: 8),
                          const Text(
                            '소개',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.muted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            bio,
                            style: const TextStyle(fontSize: 15, height: 1.45),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (_keywords.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text(
                      '키워드',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.muted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final k in _keywords)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.panel,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              [
                                adminStr(k, const ['topic']),
                                adminStr(k, const ['name']),
                              ].whereType<String>().join(' · '),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.muted, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoPager extends StatelessWidget {
  const _PhotoPager({required this.urls});

  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: const ColoredBox(
          color: AppTheme.line,
          child: SizedBox(height: 220, width: double.infinity),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: SizedBox(
        height: 320,
        child: PageView.builder(
          itemCount: urls.length,
          itemBuilder: (context, i) => Image.network(
            urls[i],
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                const ColoredBox(color: AppTheme.line),
          ),
        ),
      ),
    );
  }
}
