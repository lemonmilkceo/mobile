import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/session.dart';
import '../theme.dart';
import 'admin_common.dart';

class AdminInvitesScreen extends StatefulWidget {
  const AdminInvitesScreen({super.key});

  @override
  State<AdminInvitesScreen> createState() => _AdminInvitesScreenState();
}

class _AdminInvitesScreenState extends State<AdminInvitesScreen> {
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
            'id': 'mock-inv-1',
            'prefix': 'BAE7',
            'status': 'active',
            'createdAt': DateTime.now()
                .subtract(const Duration(days: 1))
                .toIso8601String(),
            'expiresAt': DateTime.now()
                .add(const Duration(days: 12))
                .toIso8601String(),
          },
          {
            'id': 'mock-inv-2',
            'prefix': 'LEE3',
            'status': 'redeemed',
            'createdAt': DateTime.now()
                .subtract(const Duration(days: 3))
                .toIso8601String(),
            'expiresAt': DateTime.now()
                .add(const Duration(days: 2))
                .toIso8601String(),
            'redeemerName': '이현승',
          },
        ];
      } else {
        final res = await session.api.get('/api/mobile/admin/invites');
        _items = adminList(res, const ['invites', 'items', 'data']);
      }
    } catch (e) {
      _error = adminErrorMessage(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _inviteId(Map<String, dynamic> item) {
    return adminStr(item, const ['id']) ?? '';
  }

  String _prefix(Map<String, dynamic> item) {
    return adminStr(item, const ['prefix', 'codePrefix', 'code_prefix']) ??
        '----';
  }

  String? _status(Map<String, dynamic> item) {
    return adminStr(item, const ['status']);
  }

  Future<void> _showCode(String code) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('초대 코드'),
        content: SelectableText(
          code,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: code));
              if (ctx.mounted) Navigator.pop(ctx);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('코드를 복사했어요.')),
              );
            },
            child: const Text('복사'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Future<void> _issue() async {
    if (_busy) return;
    final session = context.read<AppSession>();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      String? code;
      if (session.isMock) {
        code = 'BAEL-MOCK14';
        _items = [
          {
            'id': 'mock-inv-new',
            'prefix': 'BAEL',
            'status': 'active',
            'expiresAt': DateTime.now()
                .add(const Duration(days: 14))
                .toIso8601String(),
          },
          ..._items,
        ];
      } else {
        final res = await session.api.post(
          '/api/mobile/admin/invites',
          const {'expiresInDays': 14},
        );
        code = adminStr(res, const ['code']) ??
            adminStr(adminMap(res['invite']), const ['code']);
        await _load();
      }
      if (code != null && code.isNotEmpty) {
        await _showCode(code);
      }
    } catch (e) {
      _error = adminErrorMessage(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disable(Map<String, dynamic> item) async {
    if (_busy) return;
    final id = _inviteId(item);
    if (id.isEmpty) return;
    final ok = await showAdminConfirmSheet(
      context: context,
      title: '초대 코드를 비활성화할까요?',
      body: '비활성화하면 이 코드로는 더 이상 가입할 수 없습니다.',
      confirmLabel: '비활성화',
      destructive: true,
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
            _inviteId(row) == id ? {...row, 'status': 'disabled'} : row,
        ];
      } else {
        await session.api.post('/api/mobile/admin/invites/$id/disable');
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
            const AdminTitleBar(title: '초대'),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: FilledButton(
                onPressed: _busy ? null : _issue,
                child: const Text('초대 코드 발급'),
              ),
            ),
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
                                    '초대 코드가 없습니다.',
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
                                final status = _status(item);
                                final issued = adminDate(
                                  adminStr(item, const [
                                    'createdAt',
                                    'created_at',
                                  ]),
                                );
                                final expiry = adminDate(
                                  adminStr(item, const [
                                    'expiresAt',
                                    'expires_at',
                                  ]),
                                );
                                final redeemer = adminStr(item, const [
                                  'redeemerName',
                                  'redeemer_name',
                                  'redeemerLegalName',
                                  'legalName',
                                  'nickname',
                                ]);
                                final active = status == 'active';
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: AdminPanelCard(
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${_prefix(item)}****',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: -0.2,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                [
                                                  adminInviteStatusLabel(
                                                    status,
                                                  ),
                                                  if (issued.isNotEmpty)
                                                    '발급 $issued',
                                                  if (expiry.isNotEmpty)
                                                    '만료 $expiry',
                                                ].join(' · '),
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: AppTheme.muted,
                                                ),
                                              ),
                                              if (redeemer != null) ...[
                                                const SizedBox(height: 6),
                                                Text(
                                                  '가입자 $redeemer',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppTheme.ink,
                                                  ),
                                                ),
                                              ] else if (status ==
                                                  'redeemed') ...[
                                                const SizedBox(height: 6),
                                                const Text(
                                                  '가입자 정보를 찾을 수 없습니다',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: AppTheme.muted,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        if (active)
                                          TextButton(
                                            onPressed: _busy
                                                ? null
                                                : () => _disable(item),
                                            style: TextButton.styleFrom(
                                              foregroundColor: AppTheme.danger,
                                            ),
                                            child: const Text('비활성'),
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
