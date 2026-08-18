import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/session.dart';
import '../theme.dart';
import 'admin_common.dart';
import 'admin_request_detail_screen.dart';

class AdminRequestsScreen extends StatefulWidget {
  const AdminRequestsScreen({super.key});

  @override
  State<AdminRequestsScreen> createState() => _AdminRequestsScreenState();
}

class _AdminRequestsScreenState extends State<AdminRequestsScreen> {
  var _loading = true;
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
            'id': 'mock-req-1',
            'fromNickname': '김XX',
            'toNickname': '이XX',
            'status': 'offered',
            'createdAt': DateTime.now()
                .subtract(const Duration(hours: 6))
                .toIso8601String(),
          },
          {
            'id': 'mock-req-2',
            'fromNickname': '박XX',
            'toNickname': '최XX',
            'status': 'matched',
            'createdAt': DateTime.now()
                .subtract(const Duration(days: 2))
                .toIso8601String(),
          },
        ];
      } else {
        final res = await session.api.get('/api/mobile/admin/requests');
        _items = adminList(res, const ['requests', 'items', 'data']);
      }
    } catch (e) {
      _error = adminErrorMessage(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fromName(Map<String, dynamic> item) {
    return adminStr(item, const ['fromNickname', 'from_nickname']) ??
        adminStr(adminMap(item['from']), const ['nickname', 'legalName']) ??
        '회원';
  }

  String _toName(Map<String, dynamic> item) {
    return adminStr(item, const ['toNickname', 'to_nickname']) ??
        adminStr(adminMap(item['to']), const ['nickname', 'legalName']) ??
        '회원';
  }

  Future<void> _open(Map<String, dynamic> item) async {
    final id = adminStr(item, const ['id']);
    if (id == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminRequestDetailScreen(requestId: id),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AdminTitleBar(title: '요청'),
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
                                _EmptyCopy(text: '소개 요청이 없습니다.'),
                              ],
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                              itemCount: _items.length,
                              itemBuilder: (context, i) {
                                final item = _items[i];
                                final status = adminStr(
                                  item,
                                  const ['status'],
                                );
                                final date = adminDate(
                                  adminStr(item, const [
                                    'createdAt',
                                    'created_at',
                                    'offeredAt',
                                    'offered_at',
                                  ]),
                                );
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: AdminPanelCard(
                                    onTap: () => _open(item),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${_fromName(item)} → ${_toName(item)}',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: -0.2,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                [
                                                  adminRequestStatusLabel(
                                                    status,
                                                  ),
                                                  date,
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

class _EmptyCopy extends StatelessWidget {
  const _EmptyCopy({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppTheme.muted),
      ),
    );
  }
}
