import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/session.dart';
import '../services/profile_repository.dart';
import '../theme.dart';
import '../widgets/range_sliders.dart';
import 'photos_screen.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key, this.requiredSetup = false});

  final bool requiredSetup;

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _form = GlobalKey<FormState>();
  final _page = PageController();
  var _step = 0;
  var _loading = true;
  var _busy = false;
  String? _error;

  final _legalName = TextEditingController();
  final _phone = TextEditingController();
  final _school = TextEditingController();
  final _job = TextEditingController();
  final _district = TextEditingController();
  final _mbti = TextEditingController();
  final _keywordOther = TextEditingController();
  final _birthYear = TextEditingController(text: '1995');
  var _heightCm = 170;
  var _prefAge = const RangeValues(25, 35);
  var _prefHeight = const RangeValues(155, 185);
  String _gender = 'female';
  bool _privacy = false;
  List<Map<String, dynamic>> _keywords = [];
  final Set<String> _selectedKw = {};

  bool _showBirthYear = true;
  bool _showHeight = true;
  bool _showSchool = true;
  bool _showJob = true;
  bool _showDistrict = true;
  bool _showMbti = true;

  static const _stepLabels = ['사진', '기본', '선택', '공개'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _page.dispose();
    _legalName.dispose();
    _phone.dispose();
    _school.dispose();
    _job.dispose();
    _district.dispose();
    _mbti.dispose();
    _keywordOther.dispose();
    _birthYear.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final session = context.read<AppSession>();
    if (session.isMock) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final repo = ProfileRepository(Supabase.instance.client);
    final profile = await repo.fetchMyProfile();
    final priv = await repo.fetchPrivate();
    _keywords = await repo.fetchKeywords();
    final mine = await repo.fetchMyKeywordIds();
    _selectedKw.addAll(mine);

    if (profile != null) {
      _gender = (profile['gender'] as String?) ?? 'female';
      _birthYear.text = '${profile['birth_year'] ?? 1995}';
      _heightCm = (profile['height_cm'] as num?)?.toInt() ?? 170;
      _prefAge = RangeValues(
        ((profile['pref_age_min'] as num?)?.toDouble() ?? 25).clamp(20, 45),
        ((profile['pref_age_max'] as num?)?.toDouble() ?? 35).clamp(20, 45),
      );
      _prefHeight = RangeValues(
        ((profile['pref_height_min_cm'] as num?)?.toDouble() ?? 155)
            .clamp(140, 200),
        ((profile['pref_height_max_cm'] as num?)?.toDouble() ?? 185)
            .clamp(140, 200),
      );
      _school.text = profile['school']?.toString() ?? '';
      _job.text = profile['job']?.toString() ?? '';
      _district.text = profile['district']?.toString() ?? '';
      _mbti.text = profile['mbti']?.toString() ?? '';
      _keywordOther.text = profile['keyword_other']?.toString() ?? '';
      _privacy = profile['privacy_agreed_at'] != null;
      _showBirthYear = profile['show_birth_year'] != false;
      _showHeight = profile['show_height'] != false;
      _showSchool = profile['show_school'] != false;
      _showJob = profile['show_job'] != false;
      _showDistrict = profile['show_district'] != false;
      _showMbti = profile['show_mbti'] != false;
    }
    if (priv != null) {
      _legalName.text = priv['legal_name']?.toString() ?? '';
      _phone.text = priv['phone']?.toString() ?? '';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (!_privacy) {
      setState(() => _error = '개인정보 수집·이용에 동의해 주세요.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final session = context.read<AppSession>();
    if (session.isMock) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('프로토타입: 프로필 저장을 시뮬레이션했어요.')),
      );
      _leaveAfterSave(session);
      return;
    }
    final repo = ProfileRepository(Supabase.instance.client);
    try {
      await repo.saveProfile(
        legalName: _legalName.text,
        gender: _gender,
        birthYear: int.parse(_birthYear.text),
        heightCm: _heightCm,
        school: _school.text,
        job: _job.text,
        district: _district.text,
        mbti: _mbti.text,
        phone: _phone.text,
        privacyAgreed: _privacy,
        keywordIds: _visibleKeywordIds(),
        prefAgeMin: _prefAge.start.round(),
        prefAgeMax: _prefAge.end.round(),
        prefHeightMin: _prefHeight.start.round(),
        prefHeightMax: _prefHeight.end.round(),
        keywordOther: _keywordOther.text.trim().isEmpty
            ? null
            : _keywordOther.text.trim(),
        showBirthYear: _showBirthYear,
        showHeight: _showHeight,
        showSchool: _showSchool,
        showJob: _showJob,
        showDistrict: _showDistrict,
        showMbti: _showMbti,
      );
      if (!mounted) return;
      _leaveAfterSave(session);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _leaveAfterSave(AppSession session) {
    if (widget.requiredSetup) {
      session.finishProfileSetup();
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _go(int step) async {
    setState(() => _step = step);
    await _page.animateToPage(
      step,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 프로필'),
        automaticallyImplyLeading: !widget.requiredSetup,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: List.generate(_stepLabels.length, (i) {
                final active = i == _step;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i == 3 ? 0 : 6),
                    child: InkWell(
                      onTap: () => _go(i),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      child: Container(
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: active ? AppTheme.ink : AppTheme.panel,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSm),
                        ),
                        child: Text(
                          _stepLabels[i],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: active ? Colors.white : AppTheme.muted,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _form,
              child: Column(
                children: [
                  Expanded(
                    child: PageView(
                      controller: _page,
                      onPageChanged: (i) => setState(() => _step = i),
                      children: [
                        _photoStep(),
                        _basicStep(),
                        _optionalStep(),
                        _visibilityStep(),
                      ],
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                _error!,
                                style: const TextStyle(color: AppTheme.danger),
                              ),
                            ),
                          Row(
                            children: [
                              if (_step > 0)
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _go(_step - 1),
                                    child: const Text('이전'),
                                  ),
                                ),
                              if (_step > 0) const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton(
                                  onPressed: _busy
                                      ? null
                                      : () {
                                          if (_step < 3) {
                                            _go(_step + 1);
                                          } else {
                                            _save();
                                          }
                                        },
                                  child: Text(
                                    _busy
                                        ? '저장 중…'
                                        : (_step < 3 ? '다음' : '프로필 저장'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _photoStep() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          '사진',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          '최소 1장·최대 5장. 사진 관리 화면에서 업로드합니다.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.muted,
              ),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PhotosScreen()),
            );
          },
          icon: const Icon(Icons.photo_library_outlined),
          label: const Text('사진 관리로 이동'),
        ),
      ],
    );
  }

  Widget _basicStep() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          '기본 프로필',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          '본명·연락처는 비공개입니다. 휴대폰은 앱 알림 수신에 사용됩니다.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.muted,
              ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _legalName,
          decoration: const InputDecoration(labelText: '본명'),
          validator: (v) => (v == null || v.trim().length < 2) ? '필수' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: '연락처',
            helperText: '앱 알림 수신용',
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _gender,
          decoration: const InputDecoration(labelText: '성별'),
          items: const [
            DropdownMenuItem(value: 'female', child: Text('여성')),
            DropdownMenuItem(value: 'male', child: Text('남성')),
          ],
          onChanged: (v) => setState(() {
            _gender = v ?? 'female';
            _pruneHiddenKeywords();
          }),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _birthYear,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: '출생 연도'),
        ),
        const SizedBox(height: 8),
        HeightSlider(
          value: _heightCm,
          onChanged: (v) => setState(() => _heightCm = v),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _school,
          decoration: const InputDecoration(labelText: '학교·전공'),
          validator: (v) => (v == null || v.trim().isEmpty) ? '필수' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _job,
          decoration: const InputDecoration(labelText: '직장·직무'),
          validator: (v) => (v == null || v.trim().isEmpty) ? '필수' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _district,
          decoration: const InputDecoration(labelText: '거주 지역'),
          validator: (v) => (v == null || v.trim().isEmpty) ? '필수' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _mbti,
          decoration: const InputDecoration(labelText: 'MBTI'),
        ),
      ],
    );
  }

  /// Male viewer sees female-coded keywords and vice versa.
  String? get _partnerGender {
    if (_gender == 'male') return 'female';
    if (_gender == 'female') return 'male';
    return null;
  }

  List<Map<String, dynamic>> _visibleKeywords() {
    final partner = _partnerGender;
    if (partner == null) return _keywords;
    return _keywords.where((k) {
      final pg = k['partner_gender']?.toString();
      if (pg == null || pg.isEmpty) return true;
      return pg == partner;
    }).toList();
  }

  List<String> _visibleKeywordIds() {
    final ids = _visibleKeywords().map((k) => k['id'] as String).toSet();
    return _selectedKw.where(ids.contains).toList();
  }

  void _pruneHiddenKeywords() {
    final ids = _visibleKeywords().map((k) => k['id'] as String).toSet();
    _selectedKw.removeWhere((id) => !ids.contains(id));
  }

  /// Groups keywords by `topic`, preserving first-seen topic order.
  Map<String, List<Map<String, dynamic>>> _keywordsByTopic() {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final k in _visibleKeywords()) {
      final raw = k['topic']?.toString().trim();
      final topic = (raw == null || raw.isEmpty) ? '기타' : raw;
      map.putIfAbsent(topic, () => []).add(k);
    }
    return map;
  }

  Widget _optionalStep() {
    final byTopic = _keywordsByTopic();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          '선택 정보',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          '관심사 키워드를 골라 주세요.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.muted,
              ),
        ),
        const SizedBox(height: 16),
        for (final entry in byTopic.entries) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 4),
            child: Text(
              entry.key,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: entry.value.map((k) {
              final id = k['id'] as String;
              final selected = _selectedKw.contains(id);
              return FilterChip(
                label: Text(k['name']?.toString() ?? ''),
                selected: selected,
                onSelected: (v) {
                  setState(() {
                    if (v) {
                      _selectedKw.add(id);
                    } else {
                      _selectedKw.remove(id);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
        TextFormField(
          controller: _keywordOther,
          decoration: const InputDecoration(labelText: '기타 관심사'),
        ),
      ],
    );
  }

  Widget _visibilityStep() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          '선호 · 공개',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          '상대에게 보여줄 항목과, 나중에 매칭·필터에 쓸 선호 범위를 정합니다.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.muted,
              ),
        ),
        const SizedBox(height: 16),
        DualRangeSlider(
          label: '선호 나이',
          min: 20,
          max: 45,
          values: _prefAge,
          format: (lo, hi) => '$lo ~ $hi세',
          onChanged: (v) => setState(() => _prefAge = v),
        ),
        DualRangeSlider(
          label: '선호 키',
          min: 140,
          max: 200,
          values: _prefHeight,
          format: (lo, hi) => '${lo}cm ~ ${hi}cm',
          onChanged: (v) => setState(() => _prefHeight = v),
        ),
        const SizedBox(height: 8),
        const Divider(),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('출생연도 공개'),
          value: _showBirthYear,
          onChanged: (v) => setState(() => _showBirthYear = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('키 공개'),
          value: _showHeight,
          onChanged: (v) => setState(() => _showHeight = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('학교 공개'),
          value: _showSchool,
          onChanged: (v) => setState(() => _showSchool = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('직업 공개'),
          value: _showJob,
          onChanged: (v) => setState(() => _showJob = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('지역 공개'),
          value: _showDistrict,
          onChanged: (v) => setState(() => _showDistrict = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('MBTI 공개'),
          value: _showMbti,
          onChanged: (v) => setState(() => _showMbti = v),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _privacy,
          onChanged: (v) => setState(() => _privacy = v ?? false),
          title: const Text('개인정보 수집·이용에 동의합니다'),
        ),
      ],
    );
  }
}
