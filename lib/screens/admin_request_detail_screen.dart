import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/session.dart';
import '../theme.dart';
import 'admin_common.dart';

class AdminRequestDetailScreen extends StatefulWidget {
  const AdminRequestDetailScreen({super.key, required this.requestId});

  final String requestId;

  @override
  State<AdminRequestDetailScreen> createState() =>
      _AdminRequestDetailScreenState();
}

class _AdminRequestDetailScreenState extends State<AdminRequestDetailScreen> {
  var _loading = true;
  var _busy = false;
  String? _error;
  Map<String, dynamic> _data = {};

  static const _statusOptions = [
    ('offered', '응답 대기'),
    ('matched', '성사'),
    ('closed', '종료'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Map<String, dynamic> get _request {
    return adminMap(_data['request']) ??
        adminMap(_data['interest']) ??
        _data;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final session = context.read<AppSession>();
    try {
      if (session.isMock) {
        _data = {
          'id': widget.requestId,
          'fromNickname': '김XX',
          'toNickname': '이XX',
          'status': 'offered',
          'createdAt': DateTime.now()
              .subtract(const Duration(hours: 6))
              .toIso8601String(),
        };
      } else {
        _data = await session.api.get(
          '/api/mobile/admin/requests/${widget.requestId}',
        );
      }
    } catch (e) {
      _error = adminErrorMessage(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _name(List<String> keys, String nestedKey, String fallback) {
    final nested = adminMap(_data[nestedKey]) ?? adminMap(_request[nestedKey]);
    return adminStr(_data, keys) ??
        adminStr(_request, keys) ??
        adminStr(nested, const ['nickname', 'legalName', 'legal_name']) ??
        fallback;
  }

  String? get _status =>
      adminStr(_request, const ['status']) ?? adminStr(_data, const ['status']);

  Future<void> _post(Map<String, dynamic> body) async {
    final session = context.read<AppSession>();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (session.isMock) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('프로토타입: 요청을 반영했어요.')),
        );
        final next = Map<String, dynamic>.from(_request);
        if (body['action'] == 'cancel') {
          next['status'] = 'closed';
        } else if (body['status'] != null) {
          next['status'] = body['status'];
        }
        _data = next;
      } else {
        await session.api.post(
          '/api/mobile/admin/requests/${widget.requestId}',
          body,
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

  Future<void> _cancel() async {
    final ok = await showAdminConfirmSheet(
      context: context,
      title: '소개를 중단할까요?',
      body: '운영 중단하면 요청이 종료되고, 관련 알림이 발송될 수 있습니다.',
      confirmLabel: '운영 중단',
      destructive: true,
    );
    if (!ok || !mounted) return;
    await _post(const {'action': 'cancel'});
  }

  Future<void> _setStatus(String status) async {
    if (_status == status || _busy) return;
    await _post({'action': 'status', 'status': status});
  }

  @override
  Widget build(BuildContext context) {
    final fromName = _name(
      const ['fromNickname', 'from_nickname'],
      'from',
      '회원',
    );
    final toName = _name(
      const ['toNickname', 'to_nickname'],
      'to',
      '회원',
    );
    final date = adminDate(
      adminStr(_request, const ['createdAt', 'created_at']) ??
          adminStr(_data, const ['createdAt', 'created_at']),
    );

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('요청')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
              children: [
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: const TextStyle(color: AppTheme.danger),
                  ),
                  const SizedBox(height: 16),
                ],
                AdminPanelCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$fromName → $toName',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        [
                          adminRequestStatusLabel(_status),
                          date,
                        ].where((s) => s.isNotEmpty).join(' · '),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '상태',
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
                    for (final option in _statusOptions)
                      _StatusChip(
                        label: option.$2,
                        selected: _status == option.$1,
                        onTap: _busy ? null : () => _setStatus(option.$1),
                      ),
                  ],
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _busy ? null : _cancel,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.danger,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('운영 중단'),
                  ),
                ),
              ],
            ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppTheme.ink : AppTheme.panel,
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppTheme.ink,
            ),
          ),
        ),
      ),
    );
  }
}
