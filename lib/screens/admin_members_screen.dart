import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/session.dart';
import '../theme.dart';
import 'admin_common.dart';

class AdminMembersScreen extends StatefulWidget {
  const AdminMembersScreen({super.key});

  @override
  State<AdminMembersScreen> createState() => _AdminMembersScreenState();
}

class _AdminMembersScreenState extends State<AdminMembersScreen> {
  static const _statusOptions = [
    ('active', '매칭 가능'),
    ('hidden', '비공개'),
    ('paused', '매칭 중지'),
    ('deleted_requested', '삭제 요청'),
    ('terminated', '이용 종료'),
  ];

  var _loading = true;
  var _busy = false;
  String? _error;
  List<Map<String, dynamic>> _items = [];

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
        _items = [
          {
            'id': 'mock-m1',
            'nickname': '김XX',
            'legalName': '김민아',
            'matchingStatus': 'active',
            'gender': 'female',
          },
          {
            'id': 'mock-m2',
            'nickname': '이XX',
            'legalName': '이준호',
            'matchingStatus': 'paused',
            'gender': 'male',
          },
        ];
      } else {
        final res = await session.api.get('/api/mobile/admin/members');
        _items = adminList(res, const ['members', 'items', 'data']);
      }
    } catch (e) {
      _error = adminErrorMessage(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _memberId(Map<String, dynamic> item) {
    return adminStr(item, const ['id', 'userId', 'user_id']) ?? '';
  }

  String _displayName(Map<String, dynamic> item) {
    return adminStr(item, const [
          'nickname',
          'legalName',
          'legal_name',
        ]) ??
        '회원';
  }

  String? _matchingStatus(Map<String, dynamic> item) {
    return adminStr(item, const ['matchingStatus', 'matching_status']);
  }

  Future<void> _changeStatus(Map<String, dynamic> item) async {
    if (_busy) return;
    final id = _memberId(item);
    if (id.isEmpty) return;
    final current = _matchingStatus(item);
    final next = await showModalBottomSheet<String>(
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
                '매칭 상태',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 16),
              for (final option in _statusOptions)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: current == option.$1 ? AppTheme.ink : AppTheme.panel,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    child: InkWell(
                      onTap: () => Navigator.pop(ctx, option.$1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Text(
                          option.$2,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: current == option.$1
                                ? Colors.white
                                : AppTheme.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('취소'),
              ),
            ],
          ),
        ),
      ),
    );
    if (next == null || next == current || !mounted) return;

    final session = context.read<AppSession>();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (session.isMock) {
        _items = [
          for (final row in _items)
            _memberId(row) == id
                ? {...row, 'matchingStatus': next}
                : row,
        ];
      } else {
        await session.api.post(
          '/api/mobile/admin/members/$id/status',
          {'status': next},
        );
        await _load();
        return;
      }
    } catch (e) {
      _error = adminErrorMessage(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AdminTitleBar(title: '회원'),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppTheme.danger),
                ),
              ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : RefreshIndicator(
                      color: AppTheme.ink,
                      onRefresh: _load,
                      child: _items.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: const [
                                SizedBox(height: 120),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 40),
                                  child: Text(
                                    '회원이 없습니다.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: AppTheme.muted),
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                              itemCount: _items.length,
                              itemBuilder: (context, i) {
                                final item = _items[i];
                                final name = _displayName(item);
                                final legal = adminStr(item, const [
                                  'legalName',
                                  'legal_name',
                                ]);
                                final title = legal != null && legal != name
                                    ? '$name · $legal'
                                    : name;
                                final status = _matchingStatus(item);
                                final gender = adminGenderLabel(
                                  adminStr(item, const ['gender']),
                                );
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: AdminPanelCard(
                                    onTap: _busy
                                        ? null
                                        : () => _changeStatus(item),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                title,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: -0.2,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                [
                                                  adminMemberStatusLabel(
                                                    status,
                                                  ),
                                                  gender,
                                                ].where((s) => s.isNotEmpty).join(' · '),
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: AppTheme.muted,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.chevron_right_rounded,
                                          color: AppTheme.muted,
                                          size: 20,
                                        ),
                                      ],
                                    ),
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
