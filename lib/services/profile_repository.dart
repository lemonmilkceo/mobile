import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  String get _uid {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw StateError('Not signed in');
    return id;
  }

  Future<Map<String, dynamic>?> fetchMyProfile() async {
    final row = await _client
        .from('profiles')
        .select()
        .eq('user_id', _uid)
        .maybeSingle();
    return row;
  }

  Future<Map<String, dynamic>?> fetchPrivate() async {
    return _client
        .from('profile_private')
        .select()
        .eq('user_id', _uid)
        .maybeSingle();
  }

  Future<List<Map<String, dynamic>>> fetchKeywords() async {
    final rows = await _client
        .from('keywords')
        .select('id, name, topic, category, allows_custom_text, partner_gender')
        .eq('is_active', true)
        .order('sort_order');
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<List<String>> fetchMyKeywordIds() async {
    final rows = await _client
        .from('profile_keywords')
        .select('keyword_id')
        .eq('user_id', _uid);
    return (rows as List)
        .map((r) => (r as Map)['keyword_id'] as String)
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchPhotos() async {
    final rows = await _client
        .from('profile_photos')
        .select('id, storage_path, sort_order')
        .eq('user_id', _uid)
        .order('sort_order');
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<String> signedPhotoUrl(String path, {int expiresIn = 900}) async {
    final res = await _client.storage
        .from('profile-photos')
        .createSignedUrl(path, expiresIn);
    return res;
  }

  Future<void> saveProfile({
    required String legalName,
    required String gender,
    required int birthYear,
    required int heightCm,
    required String school,
    required String job,
    required String district,
    String? mbti,
    String? phone,
    required bool privacyAgreed,
    required List<String> keywordIds,
    String? keywordOther,
    int prefAgeMin = 25,
    int prefAgeMax = 35,
    int prefHeightMin = 155,
    int prefHeightMax = 185,
    bool showBirthYear = true,
    bool showHeight = true,
    bool showSchool = true,
    bool showJob = true,
    bool showDistrict = true,
    bool showMbti = true,
  }) async {
    final masked = _maskLegalName(legalName);
    final complete = legalName.trim().length >= 2 &&
        school.trim().isNotEmpty &&
        job.trim().isNotEmpty &&
        district.trim().isNotEmpty;

    final existing = await fetchMyProfile();
    await _client.from('profiles').update({
      'nickname': masked,
      'gender': gender,
      'birth_year': birthYear,
      'height_cm': heightCm,
      'school': school.trim(),
      'job': job.trim(),
      'district': district.trim(),
      'mbti': mbti?.trim().isEmpty == true ? null : mbti?.trim().toUpperCase(),
      'keyword_other': keywordOther,
      'pref_age_min': prefAgeMin,
      'pref_age_max': prefAgeMax,
      'pref_height_min_cm': prefHeightMin,
      'pref_height_max_cm': prefHeightMax,
      'show_birth_year': showBirthYear,
      'show_height': showHeight,
      'show_school': showSchool,
      'show_job': showJob,
      'show_district': showDistrict,
      'show_mbti': showMbti,
      'privacy_agreed_at':
          existing?['privacy_agreed_at'] ?? DateTime.now().toUtc().toIso8601String(),
      'profile_complete': complete,
      'matching_status': complete ? 'active' : 'paused',
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('user_id', _uid);

    await _client.from('profile_private').upsert({
      'user_id': _uid,
      'legal_name': legalName.trim(),
      'phone': phone?.trim().isEmpty == true ? null : phone?.trim(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });

    await _client.from('profile_keywords').delete().eq('user_id', _uid);
    if (keywordIds.isNotEmpty) {
      await _client.from('profile_keywords').insert(
            keywordIds
                .map((id) => {'user_id': _uid, 'keyword_id': id})
                .toList(),
          );
    }

    if (!privacyAgreed && existing?['privacy_agreed_at'] == null) {
      throw Exception('개인정보 수집·이용에 동의해 주세요.');
    }
  }

  Future<void> setMatchingStatus(String status) async {
    await _client.from('profiles').update({
      'matching_status': status,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('user_id', _uid);
  }

  Future<void> uploadPhoto(Uint8List bytes) async {
    final photos = await fetchPhotos();
    if (photos.length >= 5) {
      throw Exception('사진은 최대 5장까지 등록할 수 있습니다.');
    }
    final name =
        '${DateTime.now().millisecondsSinceEpoch}_${photos.length}.jpg';
    final path = '$_uid/$name';
    await _client.storage.from('profile-photos').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: false,
          ),
        );
    await _client.from('profile_photos').insert({
      'user_id': _uid,
      'storage_path': path,
      'sort_order': photos.length,
    });
  }

  Future<void> deletePhoto(String photoId, String storagePath) async {
    await _client.from('profile_photos').delete().eq('id', photoId);
    await _client.storage.from('profile-photos').remove([storagePath]);
  }

  Future<List<Map<String, dynamic>>> fetchCandidates({
    required String myGender,
  }) async {
    final target = myGender == 'male' ? 'female' : 'male';
    final rows = await _client
        .from('profiles')
        .select(
          'user_id, nickname, gender, birth_year, height_cm, school, job, district, mbti, show_height, show_birth_year, show_school, show_job, show_district, show_mbti, show_photos',
        )
        .eq('matching_status', 'active')
        .eq('profile_complete', true)
        .eq('gender', target)
        .neq('user_id', _uid)
        .order('updated_at', ascending: false)
        .limit(40);
    final excluded = await _introExcludeIds();
    final candidates = List<Map<String, dynamic>>.from(rows as List)
        .where((c) => !excluded.contains(c['user_id']))
        .toList();
    return _attachCandidatePhotos(candidates);
  }

  /// Counterpart of any intro the viewer sent or received (reject/match/open).
  Future<Set<String>> _introExcludeIds() async {
    final rows = await _client
        .from('interest_requests')
        .select('from_user_id, to_user_id')
        .or('from_user_id.eq.$_uid,to_user_id.eq.$_uid');
    final ids = <String>{};
    for (final row in List<Map<String, dynamic>>.from(rows as List)) {
      final from = row['from_user_id'] as String?;
      final to = row['to_user_id'] as String?;
      if (from == _uid && to != null) ids.add(to);
      if (to == _uid && from != null) ids.add(from);
    }
    return ids;
  }

  Future<Map<String, dynamic>?> fetchCandidate(String userId) async {
    final row = await _client
        .from('profiles')
        .select(
          'user_id, nickname, gender, birth_year, height_cm, school, job, district, mbti, show_height, show_birth_year, show_school, show_job, show_district, show_mbti, show_photos, keyword_other',
        )
        .eq('user_id', userId)
        .eq('matching_status', 'active')
        .maybeSingle();
    if (row == null) return null;
    final attached = await _attachCandidatePhotos([row]);
    return attached.first;
  }

  /// Batch-load `profile_photos` for [candidates], sign URLs once, attach
  /// `photo_url` (primary) and `photo_urls` (ordered list).
  Future<List<Map<String, dynamic>>> _attachCandidatePhotos(
    List<Map<String, dynamic>> candidates,
  ) async {
    if (candidates.isEmpty) return candidates;

    final ids = candidates
        .map((c) => c['user_id'] as String?)
        .whereType<String>()
        .toList();
    if (ids.isEmpty) return candidates;

    final rows = await _client
        .from('profile_photos')
        .select('user_id, storage_path, sort_order')
        .inFilter('user_id', ids)
        .order('sort_order');

    final pathsByUser = <String, List<String>>{};
    for (final row in List<Map<String, dynamic>>.from(rows as List)) {
      final uid = row['user_id'] as String?;
      final path = row['storage_path'] as String?;
      if (uid == null || path == null || path.isEmpty) continue;
      (pathsByUser[uid] ??= []).add(path);
    }

    final pathsToSign = <String>[];
    for (final c in candidates) {
      if (c['show_photos'] == false) continue;
      final uid = c['user_id'] as String?;
      if (uid == null) continue;
      pathsToSign.addAll(pathsByUser[uid] ?? const []);
    }
    final urlMap = await _signPhotoPaths(pathsToSign);

    return candidates.map((c) {
      final out = Map<String, dynamic>.from(c);
      if (c['show_photos'] == false) {
        out['photo_url'] = null;
        out['photo_urls'] = <String>[];
        return out;
      }
      final uid = c['user_id'] as String?;
      final paths = uid == null ? const <String>[] : (pathsByUser[uid] ?? const []);
      final urls = paths
          .map((p) => urlMap[p])
          .whereType<String>()
          .toList(growable: false);
      out['photo_urls'] = urls;
      out['photo_url'] = urls.isNotEmpty ? urls.first : null;
      return out;
    }).toList();
  }

  Future<Map<String, String>> _signPhotoPaths(List<String> paths) async {
    final unique = paths.where((p) => p.isNotEmpty).toSet().toList();
    if (unique.isEmpty) return {};

    final results = await _client.storage
        .from('profile-photos')
        .createSignedUrlsResult(unique, 900);
    final map = <String, String>{};
    for (final r in results) {
      if (r is SignedUrlSuccess) {
        map[r.path] = r.signedUrl;
      }
    }
    return map;
  }

  String _maskLegalName(String name) {
    final t = name.trim();
    if (t.isEmpty) return '회원';
    if (t.length == 1) return '$t*';
    if (t.length == 2) return '${t[0]}*';
    return '${t[0]}${'*' * (t.length - 2)}${t[t.length - 1]}';
  }
}
