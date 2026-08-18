import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/session.dart';
import '../theme.dart';
import 'admin_common.dart';

class AdminAuditScreen extends StatefulWidget {
  const AdminAuditScreen({super.key});

  @override
  State<AdminAuditScreen> createState() => _AdminAuditScreenState();
}

class _AdminAuditScreenState extends State<AdminAuditScreen> {
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
            'id': 'mock-a1',
            'action': 'member.status',
            'entityType': 'profile',
            'entityId': 'mock-m2-aaaaaaaa',
            'metadata': {'from': 'active', 'to': 'paused'},
            'createdAt': DateTime.now()
                .subtract(const Duration(hours: 2))
                .toIso8601String(),
            'actorId': 'admin-1',
          },
          {
            'id': 'mock-a2',
            'action': 'report.close',
            'entityType': 'report',
            'entityId': 'mock-r2',
            'metadata': {'note': '확인 완료'},
            'createdAt': DateTime.now()
                .subtract(const Duration(days: 1))
                .toIso8601String(),
            'actorId': 'admin-1',
          },
          {
            'id': 'mock-a3',
            'action': 'keyword.toggle',
            'entityType': 'keyword',
            'entityId': 'k3',
            'metadata': {'isActive': false},
            'createdAt': DateTime.now()
                .subtract(const Duration(days: 3))
                .toIso8601String(),
            'actorId': 'admin-1',
          },
        ];
      } else {
        final res = await session.api.get('/api/mobile/admin/audit');
        _items = adminList(res, const ['logs', 'items', 'data']);
      }
    } catch (e) {
      _error = adminErrorMessage(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _truncateId(String? id) {
    if (id == null || id.isEmpty) return '';
    if (id.length <= 8) return id;
    return '${id.substring(0, 8)}…';
  }

  String _metaText(dynamic meta) {
    if (meta == null) return '';
    if (meta is String) return meta;
    try {
      return jsonEncode(meta);
    } catch (_) {
      return meta.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const AdminSubpageBar(title: '감사 로그'),
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
                                  '감사 로그가 없습니다.',
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
                              final action =
                                  adminStr(item, const ['action']) ?? '';
                              final entityType =
                                  adminStr(item, const [
                                    'entityType',
                                    'entity_type',
                                  ]) ??
                                  '';
                              final date = adminDate(
                                adminStr(item, const [
                                  'createdAt',
                                  'created_at',
                                ]),
                              );
                              final entityId = _truncateId(
                                adminStr(item, const ['entityId', 'entity_id']),
                              );
                              final meta = _metaText(
                                item['metadata'] ?? item['meta'],
                              );
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: AdminPanelCard(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        [action, entityType]
                                            .where((s) => s.isNotEmpty)
                                            .join(' · '),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                      if (date.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          date,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.muted,
                                          ),
                                        ),
                                      ],
                                      if (entityId.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          entityId,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.muted,
                                          ),
                                        ),
                                      ],
                                      if (meta.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          meta,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.muted,
                                            height: 1.35,
                                          ),
                                        ),
                                      ],
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
