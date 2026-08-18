import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/session.dart';
import '../theme.dart';
import 'admin_audit_screen.dart';
import 'admin_common.dart';
import 'admin_feeds_screen.dart';
import 'admin_keywords_screen.dart';
import 'admin_reports_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key, this.onOpenTab});

  final ValueChanged<int>? onOpenTab;

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  var _loading = true;
  String? _error;
  var _memberCount = 0;
  var _requestCount = 0;
  var _inviteCount = 0;
  var _reportCount = 0;

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
        _memberCount = 12;
        _requestCount = 3;
        _inviteCount = 5;
        _reportCount = 1;
      } else {
        final res = await session.api.get('/api/mobile/admin/summary');
        _memberCount = adminInt(res, const ['memberCount', 'member_count']);
        _requestCount = adminInt(res, const ['requestCount', 'request_count']);
        _inviteCount = adminInt(res, const ['inviteCount', 'invite_count']);
        _reportCount = adminInt(res, const ['reportCount', 'report_count']);
      }
    } catch (e) {
      _error = adminErrorMessage(e);
      if (session.isMock) {
        _memberCount = 0;
        _requestCount = 0;
        _inviteCount = 0;
        _reportCount = 0;
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => screen));
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AdminTitleBar(title: '운영'),
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
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                        children: [
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 1.35,
                            children: [
                              _CountCard(
                                label: '회원',
                                count: _memberCount,
                                onTap: () => widget.onOpenTab?.call(2),
                              ),
                              _CountCard(
                                label: '진행 요청',
                                count: _requestCount,
                                onTap: () => widget.onOpenTab?.call(1),
                              ),
                              _CountCard(
                                label: '활성 초대',
                                count: _inviteCount,
                                onTap: () => widget.onOpenTab?.call(3),
                              ),
                              _CountCard(
                                label: '미처리 신고',
                                count: _reportCount,
                                onTap: () => _open(const AdminReportsScreen()),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          _LinkRow(
                            label: '여성 피드',
                            onTap: () =>
                                _open(const AdminFeedsScreen(gender: 'female')),
                          ),
                          _LinkRow(
                            label: '남성 피드',
                            onTap: () =>
                                _open(const AdminFeedsScreen(gender: 'male')),
                          ),
                          _LinkRow(
                            label: '신고',
                            onTap: () => _open(const AdminReportsScreen()),
                          ),
                          _LinkRow(
                            label: '키워드',
                            onTap: () => _open(const AdminKeywordsScreen()),
                          ),
                          _LinkRow(
                            label: '감사 로그',
                            onTap: () => _open(const AdminAuditScreen()),
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
}

class _CountCard extends StatelessWidget {
  const _CountCard({required this.label, required this.count, this.onTap});

  final String label;
  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.panel,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.muted,
                ),
              ),
              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.8,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AdminPanelCard(
        onTap: onTap,
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
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
  }
}
