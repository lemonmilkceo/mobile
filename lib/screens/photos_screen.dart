import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/profile_repository.dart';
import '../services/session.dart';
import '../theme.dart';
import '../widgets/photo_add_sheet.dart';
import 'photo_picker_screen.dart';

class PhotosScreen extends StatefulWidget {
  const PhotosScreen({super.key});

  @override
  State<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends State<PhotosScreen> {
  ProfileRepository? _repo;
  List<Map<String, dynamic>> _photos = [];
  final Map<String, String> _urls = {};
  var _loading = true;
  var _busy = false;
  String? _error;

  ProfileRepository get repo =>
      _repo ??= ProfileRepository(Supabase.instance.client);

  bool get _canAdd => !_busy && _photos.length < 5;

  String _photoPolicyText(BuildContext context) {
    final photos = context.watch<AppSession>().memberState?['photos'];
    final min = photos?['minRequired'];
    final nudge = photos?['nudge']?.toString();
    final required = min is num ? min.toInt() : 0;
    final parts = <String>[
      '얼굴이 잘 보이는 사진을 올려 주세요. 첫 장이 소개 카드에 쓰입니다.',
      if (required > 0 && _photos.length < required)
        '새 회원은 사진 $required장이 필요합니다. 지금 ${_photos.length}장입니다.',
      if (nudge != null && nudge.isNotEmpty) nudge,
    ];
    return parts.join('\n');
  }

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
    if (session.isMock) {
      _photos = [];
      _urls.clear();
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      _photos = await repo.fetchPhotos();
      _urls.clear();
      for (final p in _photos) {
        final path = p['storage_path'] as String;
        _urls[path] = await repo.signedPhotoUrl(path, expiresIn: 3600);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _add() async {
    if (!_canAdd) return;
    final source = await showPhotoAddSheet(context);
    if (source == null || !mounted) return;

    if (context.read<AppSession>().isMock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('프로토타입: 사진 업로드를 시뮬레이션했어요.')),
      );
      return;
    }

    Uint8List? bytes;
    if (source == PhotoAddSource.album) {
      bytes = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute(builder: (_) => const PhotoPickerScreen()),
      );
    } else {
      final file = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        imageQuality: 85,
        requestFullMetadata: false,
      );
      if (file != null) bytes = await file.readAsBytes();
    }
    if (bytes == null || !mounted) return;

    setState(() => _busy = true);
    try {
      await repo.uploadPhoto(bytes);
      await context.read<AppSession>().refreshMemberState();
      await _load();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(Map<String, dynamic> photo) async {
    final ok = await showModalBottomSheet<bool>(
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
                '이 사진을 삭제할까요?',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '삭제하면 프로필에서 바로 내려가요. 다시 올리려면 새로 등록해야 합니다.',
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.muted,
                      height: 1.45,
                    ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('삭제'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('취소'),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true || !mounted) return;

    if (context.read<AppSession>().isMock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('프로토타입: 사진 삭제를 시뮬레이션했어요.')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await repo.deletePhoto(
        photo['id'] as String,
        photo['storage_path'] as String,
      );
      await context.read<AppSession>().refreshMemberState();
      await _load();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMock = context.watch<AppSession>().isMock;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('사진')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    children: [
                      Text(
                        '최대 5장 · ${_photos.length}/5',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isMock
                            ? '프로토타입 모드 — 사진은 실제로 업로드되지 않습니다.'
                            : _photoPolicyText(context),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.muted,
                              height: 1.45,
                            ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: const TextStyle(color: AppTheme.danger),
                        ),
                      ],
                      const SizedBox(height: 20),
                      if (_photos.isEmpty)
                        _EmptyState(isMock: isMock)
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _photos.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 4 / 5,
                          ),
                          itemBuilder: (context, i) {
                            final p = _photos[i];
                            final url = _urls[p['storage_path']];
                            return _PhotoTile(
                              url: url,
                              busy: _busy,
                              onDelete: () => _delete(p),
                            );
                          },
                        ),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _canAdd ? _add : null,
                        child: Text(
                          _photos.length >= 5
                              ? '최대 5장까지 등록할 수 있어요'
                              : '사진 추가',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isMock});

  final bool isMock;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.line),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.brandSoft,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: const Icon(
              Icons.photo_outlined,
              size: 32,
              color: AppTheme.brand,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isMock ? '등록된 사진이 없습니다 (프로토타입)' : '등록된 사진이 없습니다',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            '앨범에서 고르거나 카메라로 촬영해 프로필 사진을 올려 주세요.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.muted,
                  height: 1.45,
                ),
          ),
        ],
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.url,
    required this.busy,
    required this.onDelete,
  });

  final String? url;
  final bool busy;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: AppTheme.panel,
            child: url == null
                ? const SizedBox.expand()
                : Image.network(url!, fit: BoxFit.cover),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: Colors.black54,
                foregroundColor: Colors.white,
                minimumSize: const Size(36, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: busy ? null : onDelete,
              icon: const Icon(Icons.close, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
