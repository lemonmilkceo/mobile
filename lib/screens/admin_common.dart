import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';
import '../services/session.dart';
import '../theme.dart';

String adminErrorMessage(Object e) {
  if (e is ApiException) return e.message;
  return e.toString();
}

int adminInt(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final v = map[key];
    if (v is int) return v;
    if (v is num) return v.toInt();
    final parsed = int.tryParse(v?.toString() ?? '');
    if (parsed != null) return parsed;
  }
  return 0;
}

String? adminStr(Map<String, dynamic>? map, List<String> keys) {
  if (map == null) return null;
  for (final key in keys) {
    final v = map[key];
    if (v == null) continue;
    final s = v.toString().trim();
    if (s.isNotEmpty && s != 'null') return s;
  }
  return null;
}

Map<String, dynamic>? adminMap(dynamic raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return Map<String, dynamic>.from(raw);
  return null;
}

List<Map<String, dynamic>> adminList(
  Map<String, dynamic> res,
  List<String> keys,
) {
  for (final key in keys) {
    if (!res.containsKey(key)) continue;
    return adminListValue(res[key]);
  }
  for (final value in res.values) {
    if (value is List) return adminListValue(value);
  }
  return [];
}

List<Map<String, dynamic>> adminListValue(dynamic raw) {
  if (raw is! List) return [];
  return [
    for (final item in raw)
      if (item is Map) Map<String, dynamic>.from(item),
  ];
}

String adminDate(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) return '';
  final dt = parsed.toUtc().add(const Duration(hours: 9));
  final mm = dt.month.toString().padLeft(2, '0');
  final dd = dt.day.toString().padLeft(2, '0');
  return '${dt.year}.$mm.$dd';
}

String adminRequestStatusLabel(String? status) {
  switch (status) {
    case 'submitted':
      return '접수';
    case 'under_review':
      return '검토 중';
    case 'offered':
      return '응답 대기';
    case 'accepted':
      return '상대 수락';
    case 'intro_in_progress':
      return '소개 진행';
    case 'matched':
      return '성사';
    case 'on_hold':
      return '보류';
    case 'closed':
      return '종료';
    case 'declined':
      return '거절됨';
    case 'expired':
      return '만료';
    case 'admin_cancelled':
      return '운영 중단';
    default:
      return status ?? '';
  }
}

String adminMemberStatusLabel(String? status) {
  switch (status) {
    case 'active':
      return '매칭 가능';
    case 'hidden':
      return '비공개';
    case 'paused':
      return '매칭 중지';
    case 'deleted_requested':
      return '삭제 요청';
    case 'terminated':
      return '이용 종료';
    default:
      return status ?? '';
  }
}

String adminGenderLabel(String? gender) {
  switch (gender) {
    case 'female':
      return '여성';
    case 'male':
      return '남성';
    default:
      return gender ?? '';
  }
}

String adminInviteStatusLabel(String? status) {
  switch (status) {
    case 'active':
      return '활성';
    case 'disabled':
      return '비활성';
    case 'redeemed':
      return '사용됨';
    case 'expired':
      return '만료';
    default:
      return status ?? '';
  }
}

Future<bool> adminConfirm({
  required BuildContext context,
  required String title,
  required String body,
  required String confirmLabel,
  bool destructive = false,
}) {
  return showAdminConfirmSheet(
    context: context,
    title: title,
    body: body,
    confirmLabel: confirmLabel,
    destructive: destructive,
  );
}

List<String> adminPhotoUrls(Map<String, dynamic> item) {
  final raw = item['photoUrls'] ?? item['photo_urls'];
  if (raw is List) {
    return [
      for (final u in raw)
        if (u != null &&
            u.toString().trim().isNotEmpty &&
            u.toString() != 'null')
          u.toString().trim(),
    ];
  }
  final single = adminStr(item, const ['photoUrl', 'photo_url']);
  return single == null ? const [] : [single];
}

String adminIntroLine(Map<String, dynamic> item) {
  final birthYear = adminInt(item, const ['birthYear', 'birth_year']);
  final height = adminInt(item, const ['heightCm', 'height_cm']);
  final school = adminStr(item, const ['school']);
  final job = adminStr(item, const ['job']);
  final district = adminStr(item, const ['district']);
  return [
    if (birthYear > 0) (birthYear % 100).toString().padLeft(2, '0'),
    if (height > 0) '키 $height',
    ?school,
    ?job,
    ?district,
  ].join(' / ');
}

String adminKeywordCategoryLabel(String? category) {
  switch (category) {
    case 'basic':
      return '기본 정보';
    case 'appearance':
      return '외모 선호';
    case 'relationship':
      return '연애 조건';
    case 'lifestyle':
      return '생활 방식';
    case 'values':
      return '가치관';
    default:
      return category ?? '기타';
  }
}

Future<bool> showAdminConfirmSheet({
  required BuildContext context,
  required String title,
  required String body,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final ok = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: AppTheme.background,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(
                ctx,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                color: AppTheme.muted,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: destructive
                  ? FilledButton.styleFrom(
                      backgroundColor: AppTheme.danger,
                      foregroundColor: Colors.white,
                    )
                  : null,
              child: Text(confirmLabel),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소'),
            ),
          ],
        ),
      ),
    ),
  );
  return ok == true;
}

final List<Map<String, dynamic>> mockAdminFeedProfiles = [
  {
    'id': 'mock-f1',
    'userId': 'mock-f1',
    'nickname': '김XX',
    'legalName': '김민아',
    'gender': 'female',
    'birthYear': 1996,
    'heightCm': 165,
    'school': '연세대 경영',
    'job': '브랜드 마케터',
    'district': '마포구',
    'mbti': 'ENFP',
    'bio': '주말엔 전시 보러 다니는 걸 좋아해요.',
    'matchingStatus': 'active',
    'profileComplete': true,
    'phone': '010-1234-5678',
    'email': 'mina@example.com',
    'photoUrls': [
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=800&q=80',
      'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=800&q=80',
    ],
    'keywords': [
      {'id': 'k1', 'name': '비흡연', 'category': 'lifestyle', 'topic': '흡연'},
      {'id': 'k2', 'name': '진지한 만남', 'category': 'relationship', 'topic': '연애'},
    ],
  },
  {
    'id': 'mock-f2',
    'userId': 'mock-f2',
    'nickname': '이XX',
    'legalName': '이서연',
    'gender': 'female',
    'birthYear': 1994,
    'heightCm': 168,
    'school': '고려대 심리',
    'job': 'UX 디자이너',
    'district': '성동구',
    'mbti': 'INFJ',
    'bio': '책과 커피를 좋아합니다.',
    'matchingStatus': 'paused',
    'profileComplete': true,
    'phone': '010-2222-3333',
    'email': 'seoyeon@example.com',
    'photoUrls': <String>[],
    'keywords': [
      {'id': 'k3', 'name': '무교', 'category': 'values', 'topic': '종교'},
    ],
  },
  {
    'id': 'mock-m1',
    'userId': 'mock-m1',
    'nickname': '최XX',
    'legalName': '최민수',
    'gender': 'male',
    'birthYear': 1993,
    'heightCm': 180,
    'school': '서울대',
    'job': '변호사',
    'district': '서초구',
    'mbti': 'ISTJ',
    'bio': '주중엔 일하고 주말엔 등산합니다.',
    'matchingStatus': 'active',
    'profileComplete': true,
    'phone': '010-5555-6666',
    'email': 'minsu@example.com',
    'photoUrls': [
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800&q=80',
    ],
    'keywords': [
      {'id': 'k4', 'name': '비흡연', 'category': 'lifestyle', 'topic': '흡연'},
      {'id': 'k5', 'name': '서울 거주', 'category': 'basic', 'topic': '거주'},
    ],
  },
  {
    'id': 'mock-m2',
    'userId': 'mock-m2',
    'nickname': '정XX',
    'legalName': '정우성',
    'gender': 'male',
    'birthYear': 1991,
    'heightCm': 183,
    'school': 'KAIST',
    'job': '프로덕트 매니저',
    'district': '성동구',
    'mbti': 'ENTJ',
    'matchingStatus': 'hidden',
    'profileComplete': true,
    'phone': '010-7777-8888',
    'email': 'woosung@example.com',
    'photoUrls': [
      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=800&q=80',
    ],
    'keywords': [
      {'id': 'k6', 'name': '키 180 이상', 'category': 'appearance', 'topic': '키'},
    ],
  },
];

class AdminSubpageBar extends StatelessWidget implements PreferredSizeWidget {
  const AdminSubpageBar({super.key, required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      leading: IconButton(
        icon: const Icon(Icons.chevron_left_rounded, size: 28),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
    );
  }
}

class AdminTitleBar extends StatelessWidget {
  const AdminTitleBar({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.8,
                height: 1.1,
              ),
            ),
          ),
          TextButton(
            onPressed: () => context.read<AppSession>().enterMemberApp(),
            style: TextButton.styleFrom(foregroundColor: AppTheme.ink),
            child: const Text('회원 앱으로'),
          ),
        ],
      ),
    );
  }
}

class AdminPanelCard extends StatelessWidget {
  const AdminPanelCard({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: child,
    );
    return Material(
      color: AppTheme.panel,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: onTap == null
          ? content
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              child: content,
            ),
    );
  }
}
