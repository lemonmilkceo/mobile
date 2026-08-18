import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/session.dart';
import '../theme.dart';
import 'admin_common.dart';

class AdminKeywordsScreen extends StatefulWidget {
  const AdminKeywordsScreen({super.key});

  @override
  State<AdminKeywordsScreen> createState() => _AdminKeywordsScreenState();
}

class _AdminKeywordsScreenState extends State<AdminKeywordsScreen> {
  static const _categoryOrder = [
    'basic',
    'appearance',
    'relationship',
    'lifestyle',
    'values',
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
            'id': 'k1',
            'category': 'lifestyle',
            'name': '비흡연',
            'topic': '흡연',
            'isActive': true,
            'sortOrder': 1,
          },
          {
            'id': 'k2',
            'category': 'lifestyle',
            'name': '흡연',
            'topic': '흡연',
            'isActive': true,
            'sortOrder': 2,
          },
          {
            'id': 'k3',
            'category': 'values',
            'name': '무교',
            'topic': '종교',
            'isActive': false,
            'sortOrder': 1,
          },
          {
            'id': 'k4',
            'category': 'basic',
            'name': '서울 거주',
            'topic': '거주',
            'isActive': true,
            'sortOrder': 1,
          },
          {
            'id': 'k5',
            'category': 'appearance',
            'name': '키 170 이상',
            'topic': '키',
            'isActive': true,
            'sortOrder': 1,
            'partnerGender': 'female',
          },
          {
            'id': 'k6',
            'category': 'relationship',
            'name': '진지한 만남',
            'topic': '연애',
            'isActive': true,
            'sortOrder': 1,
          },
        ];
      } else {
        final res = await session.api.get('/api/mobile/admin/keywords');
        _items = adminList(res, const ['keywords', 'items', 'data']);
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

  bool _isActive(Map<String, dynamic> item) {
    final v = item['isActive'] ?? item['is_active'];
    return v == true || v == 1 || v == 'true';
  }

  List<(String, List<Map<String, dynamic>>)> _grouped() {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final item in _items) {
      final cat = adminStr(item, const ['category']) ?? 'other';
      map.putIfAbsent(cat, () => []).add(item);
    }
    for (final list in map.values) {
      list.sort((a, b) {
        final sa = adminInt(a, const ['sortOrder', 'sort_order']);
        final sb = adminInt(b, const ['sortOrder', 'sort_order']);
        if (sa != sb) return sa.compareTo(sb);
        return (adminStr(a, const ['name']) ?? '').compareTo(
          adminStr(b, const ['name']) ?? '',
        );
      });
    }
    final keys = [
      ..._categoryOrder.where(map.containsKey),
      ...map.keys.where((k) => !_categoryOrder.contains(k)),
    ];
    return [for (final k in keys) (k, map[k]!)];
  }

  Future<void> _toggle(Map<String, dynamic> item) async {
    if (_busy) return;
    final id = _id(item);
    if (id.isEmpty) return;
    final next = !_isActive(item);

    final session = context.read<AppSession>();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (session.isMock) {
        _items = [
          for (final row in _items)
            _id(row) == id ? {...row, 'isActive': next} : row,
        ];
      } else {
        await session.api.post('/api/mobile/admin/keywords/$id/toggle', {
          'isActive': next,
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
    final groups = _grouped();
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const AdminSubpageBar(title: '키워드'),
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
                                  '키워드가 없습니다.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: AppTheme.muted),
                                ),
                              ),
                            ],
                          )
                        : ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                            children: [
                              for (final group in groups) ...[
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    4,
                                    8,
                                    4,
                                    8,
                                  ),
                                  child: Text(
                                    adminKeywordCategoryLabel(group.$1),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.muted,
                                    ),
                                  ),
                                ),
                                for (final item in group.$2)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _KeywordRow(
                                      item: item,
                                      active: _isActive(item),
                                      busy: _busy,
                                      onToggle: () => _toggle(item),
                                    ),
                                  ),
                              ],
                            ],
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _KeywordRow extends StatelessWidget {
  const _KeywordRow({
    required this.item,
    required this.active,
    required this.busy,
    required this.onToggle,
  });

  final Map<String, dynamic> item;
  final bool active;
  final bool busy;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final topic = adminStr(item, const ['topic']) ?? '기타';
    final name = adminStr(item, const ['name']) ?? '';
    return AdminPanelCard(
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$topic · $name${active ? '' : ' (비활성)'}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
                color: active ? AppTheme.ink : AppTheme.muted,
              ),
            ),
          ),
          if (active)
            TextButton(
              onPressed: busy ? null : onToggle,
              style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
              child: const Text('비활성화'),
            )
          else
            FilledButton.tonal(
              onPressed: busy ? null : onToggle,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('활성화'),
            ),
        ],
      ),
    );
  }
}
