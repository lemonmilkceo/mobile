import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/session.dart';
import '../theme.dart';
import 'admin_common.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
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
            'id': 'mock-r1',
            'body': '프로필 사진이 본인과 다른 것 같아요.',
            'status': 'open',
            'createdAt': DateTime.now()
                .subtract(const Duration(hours: 3))
                .toIso8601String(),
            'reporterId': 'mock-m1',
            'targetUserId': 'mock-f1',
            'reporterName': '최XX',
            'targetName': '김민아',
          },
          {
            'id': 'mock-r2',
            'body': '연락이 되지 않습니다.',
            'status': 'closed',
            'createdAt': DateTime.now()
                .subtract(const Duration(days: 4))
                .toIso8601String(),
            'reporterId': 'mock-f2',
            'targetUserId': 'mock-m2',
            'reporterName': '이XX',
            'targetName': '정우성',
          },
        ];
      } else {
        final res = await session.api.get('/api/mobile/admin/reports');
        _items = adminList(res, const ['reports', 'items', 'data']);
      }
    } catch (e) {
      _error = adminErrorMessage(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _id(Map<String, dynamic> item) {
    return adminStr(item, const ['id']) ?? '';
  }

  String? _status(Map<String, dynamic> item) {
    return adminStr(item, const ['status']);
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'open':
        return '미처리';
      case 'closed':
        return '처리됨';
      default:
        return status ?? '';
    }
  }

  Future<void> _setStatus(Map<String, dynamic> item, String next) async {
    if (_busy) return;
    final id = _id(item);
    if (id.isEmpty) return;
    final closing = next == 'closed';
    final ok = await adminConfirm(
      context: context,
      title: closing ? '신고를 처리할까요?' : '신고를 다시 열까요?',
      body: closing ? '처리됨으로 표시합니다.' : '미처리 상태로 되돌립니다.',
      confirmLabel: closing ? '처리' : '재오픈',
      destructive: closing,
    );
    if (!ok || !mounted) return;

    final session = context.read<AppSession>();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (session.isMock) {
        _items = [
          for (final row in _items)
            _id(row) == id ? {...row, 'status': next} : row,
        ];
      } else {
        await session.api.post('/api/mobile/admin/reports/$id', {
          'status': next,
        });
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
      appBar: const AdminSubpageBar(title: '신고'),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppTheme.danger),
                    ),
                  ),
                Expanded(
                  child: RefreshIndicator(
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
                                  '신고가 없습니다',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: AppTheme.muted),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                            itemCount: _items.length,
                            itemBuilder: (context, i) {
                              final item = _items[i];
                              final status = _status(item);
                              final open = status == 'open';
                              final date = adminDate(
                                adminStr(item, const [
                                  'createdAt',
                                  'created_at',
                                ]),
                              );
                              final reporter =
                                  adminStr(item, const [
                                    'reporterName',
                                    'reporter_name',
                                  ]) ??
                                  '회원';
                              final target =
                                  adminStr(item, const [
                                    'targetName',
                                    'target_name',
                                  ]) ??
                                  '회원';
                              final body = adminStr(item, const ['body']) ?? '';
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: AdminPanelCard(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              [_statusLabel(status), date]
                                                  .where((s) => s.isNotEmpty)
                                                  .join(' · '),
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: open
                                                    ? AppTheme.danger
                                                    : AppTheme.muted,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              '$reporter → $target',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: -0.2,
                                              ),
                                            ),
                                            if (body.isNotEmpty) ...[
                                              const SizedBox(height: 8),
                                              Text(
                                                body,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  height: 1.45,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      if (open)
                                        TextButton(
                                          onPressed: _busy
                                              ? null
                                              : () =>
                                                    _setStatus(item, 'closed'),
                                          style: TextButton.styleFrom(
                                            foregroundColor: AppTheme.danger,
                                          ),
                                          child: const Text('처리'),
                                        )
                                      else
                                        TextButton(
                                          onPressed: _busy
                                              ? null
                                              : () => _setStatus(item, 'open'),
                                          style: TextButton.styleFrom(
                                            foregroundColor: AppTheme.ink,
                                          ),
                                          child: const Text('재오픈'),
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
    );
  }
}
