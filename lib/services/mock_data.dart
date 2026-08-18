import '../config.dart';

/// In-memory mock catalog for prototype / demo without Supabase.
class MockData {
  static const waitNoticeCopy =
      '프로필을 등록해 주셔서 진심으로 감사드립니다. 원활한 소개팅 서비스를 위해 플랫폼을 구축 중이며, 베타 서비스 오픈 시 빠르게 공지해 드리겠습니다.';

  static const me = {
    'user_id': 'mock-me',
    'nickname': '테XX',
    'gender': 'male',
    'birth_year': 1994,
    'height_cm': 178,
    'school': '고려대',
    'job': '소프트웨어 엔지니어',
    'district': '강남구',
    'mbti': 'INTJ',
    'profile_complete': true,
    'matching_status': 'active',
    'photo_url':
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&q=80',
    'show_birth_year': true,
    'show_height': true,
    'show_school': true,
    'show_job': true,
    'show_district': true,
    'show_mbti': true,
  };

  static const candidates = [
    {
      'user_id': 'mock-f1',
      'nickname': '김XX',
      'gender': 'female',
      'birth_year': 1996,
      'height_cm': 165,
      'school': '연세대 경영',
      'job': '브랜드 마케터',
      'district': '마포구',
      'mbti': 'ENFP',
      'photo_url':
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=800&q=80',
      'show_birth_year': true,
      'show_job': true,
      'show_district': true,
      'show_height': true,
      'show_school': true,
      'show_mbti': true,
    },
    {
      'user_id': 'mock-f2',
      'nickname': '이XX',
      'gender': 'female',
      'birth_year': 1994,
      'height_cm': 168,
      'school': '고려대 심리',
      'job': 'UX 디자이너',
      'district': '성동구',
      'mbti': 'INFJ',
      'photo_url':
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800&q=80',
      'show_birth_year': true,
      'show_job': true,
      'show_district': true,
      'show_height': true,
      'show_school': true,
      'show_mbti': true,
    },
    {
      'user_id': 'mock-f3',
      'nickname': '박XX',
      'gender': 'female',
      'birth_year': 1998,
      'height_cm': 162,
      'school': '이화여대',
      'job': '콘텐츠 에디터',
      'district': '용산구',
      'mbti': 'ESFJ',
      'photo_url':
          'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=800&q=80',
      'show_birth_year': true,
      'show_job': true,
      'show_district': true,
      'show_height': true,
      'show_school': true,
      'show_mbti': true,
    },
    {
      'user_id': 'mock-m1',
      'nickname': '최XX',
      'gender': 'male',
      'birth_year': 1993,
      'height_cm': 180,
      'school': '서울대',
      'job': '변호사',
      'district': '서초구',
      'mbti': 'ISTJ',
      'photo_url':
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800&q=80',
      'show_birth_year': true,
      'show_job': true,
      'show_district': true,
      'show_height': true,
      'show_school': true,
      'show_mbti': true,
    },
    {
      'user_id': 'mock-m2',
      'nickname': '정XX',
      'gender': 'male',
      'birth_year': 1991,
      'height_cm': 183,
      'school': 'KAIST',
      'job': '프로덕트 매니저',
      'district': '성동구',
      'mbti': 'ENTJ',
      'photo_url':
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=800&q=80',
      'show_birth_year': true,
      'show_job': true,
      'show_district': true,
      'show_height': true,
      'show_school': true,
      'show_mbti': true,
    },
  ];

  static List<Map<String, dynamic>> candidatesFor(String? myGender) {
    final target = myGender == 'female' ? 'male' : 'female';
    return candidates
        .where((c) => c['gender'] == target)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  static const inboxReceived = [
    {
      'id': 'mock-interest-1',
      'status': 'offered',
      'offered_at': '2026-08-09T10:00:00Z',
      'from_user_id': 'mock-m1',
      'to_user_id': 'mock-me',
      'counterpart': {
        'user_id': 'mock-m1',
        'nickname': '최XX',
        'job': '변호사',
        'birth_year': 1993,
        'height_cm': 180,
        'school': '서울대',
        'district': '서초구',
        'mbti': 'ISTJ',
        'photo_url':
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800&q=80',
        'show_birth_year': true,
        'show_job': true,
        'show_district': true,
        'show_height': true,
        'show_school': true,
        'show_mbti': true,
      },
    },
  ];

  static const inboxSent = [
    {
      'id': 'mock-interest-2',
      'status': 'matched',
      'offered_at': '2026-08-08T09:00:00Z',
      'from_user_id': 'mock-me',
      'to_user_id': 'mock-f1',
      'counterpart': {
        'user_id': 'mock-f1',
        'nickname': '김XX',
        'job': '브랜드 마케터',
        'photo_url':
            'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400&q=80',
      },
    },
  ];

  static Map<String, dynamic>? profileByUserId(String userId) {
    for (final c in candidates) {
      if (c['user_id'] == userId) {
        return Map<String, dynamic>.from(c);
      }
    }
    for (final item in [...inboxReceived, ...inboxSent]) {
      final cp = item['counterpart'];
      if (cp is Map && cp['user_id'] == userId) {
        return Map<String, dynamic>.from(cp);
      }
    }
    if (userId == me['user_id']) {
      return Map<String, dynamic>.from(me);
    }
    return null;
  }

  static Map<String, dynamic> interestDetail(String id) {
    if (id == 'mock-interest-2') {
      return {
        'interest': inboxSent.first,
        'counterpart': candidates.first,
        'contact': {'legalName': '김서연', 'phone': '010-1234-5678'},
      };
    }
    return {
      'interest': inboxReceived.first,
      'counterpart': {
        'nickname': '최XX',
        'birth_year': 1993,
        'job': '변호사',
        'district': '서초구',
        'school': '서울대',
      },
      'contact': null,
    };
  }

  static bool get feedWaitNotice => AppConfig.mockFeedWaitNotice;
}
