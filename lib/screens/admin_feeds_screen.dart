import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/session.dart';
import '../theme.dart';
import 'admin_common.dart';
import 'admin_feed_detail_screen.dart';

class AdminFeedsScreen extends StatefulWidget {
  const AdminFeedsScreen({super.key, required this.gender});

  final String gender;

  @override
  State<AdminFeedsScreen> createState() => _AdminFeedsScreenState();
}

class _AdminFeedsScreenState extends State<AdminFeedsScreen> {
  var _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  bool get _isFemale => widget.gender == 'female';

  String get _title => _isFemale ? '여성 피드' : '남성 피드';

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
        _items = mockAdminFeedProfiles
            .where((p) => adminStr(p, const ['gender']) == widget.gender)
            .map((p) => Map<String, dynamic>.from(p))
            .toList();
      } else {
        final res = await session.api.get(
          '/api/mobile/admin/feeds?gender=${widget.gender}',
        );
        _items = adminList(res, const ['profiles', 'items', 'data']);
      }
    } catch (e) {
      _error = adminErrorMessage(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _userId(Map<String, dynamic> item) {
    return adminStr(item, const ['userId', 'user_id', 'id']) ?? '';
  }

  String _displayName(Map<String, dynamic> item) {
    return adminStr(item, const ['legalName', 'legal_name']) ??
        adminStr(item, const ['nickname']) ??
        '회원';
  }

  Future<void> _open(Map<String, dynamic> item) async {
    final id = _userId(item);
    if (id.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AdminFeedDetailScreen(userId: id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AdminSubpageBar(title: _title),
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
                            children: [
                              const SizedBox(height: 120),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40,
                                ),
                                child: Text(
                                  _isFemale
                                      ? '등록된 여성 회원이 없어요.'
                                      : '등록된 남성 회원이 없어요.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: AppTheme.muted),
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
                              final photos = adminPhotoUrls(item);
                              final photo = photos.isEmpty
                                  ? null
                                  : photos.first;
                              final intro = adminIntroLine(item);
                              final phone = adminStr(item, const ['phone']);
                              final meta = [
                                adminMemberStatusLabel(
                                  adminStr(item, const [
                                    'matchingStatus',
                                    'matching_status',
                                  ]),
                                ),
                                ?phone,
                              ].where((s) => s.isNotEmpty).join(' · ');
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: AdminPanelCard(
                                  onTap: () => _open(item),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: SizedBox(
                                          width: 56,
                                          height: 56,
                                          child: photo != null
                                              ? Image.network(
                                                  photo,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, _, _) =>
                                                      const ColoredBox(
                                                        color: AppTheme.line,
                                                      ),
                                                )
                                              : const ColoredBox(
                                                  color: AppTheme.line,
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _displayName(item),
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: -0.2,
                                              ),
                                            ),
                                            if (intro.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                intro,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: AppTheme.muted,
                                                ),
                                              ),
                                            ],
                                            if (meta.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                meta,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: AppTheme.muted,
                                                ),
                                              ),
                                            ],
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
    );
  }
}
