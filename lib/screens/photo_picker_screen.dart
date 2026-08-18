import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../theme.dart';

/// In-app gallery so we never hand control to the English Android Photo Picker.
class PhotoPickerScreen extends StatefulWidget {
  const PhotoPickerScreen({super.key});

  @override
  State<PhotoPickerScreen> createState() => _PhotoPickerScreenState();
}

class _PhotoPickerScreenState extends State<PhotoPickerScreen> {
  static const _pageSize = 60;

  final _scroll = ScrollController();
  final List<AssetEntity> _assets = [];
  AssetPathEntity? _album;
  var _page = 0;
  var _loading = true;
  var _loadingMore = false;
  var _hasMore = true;
  var _denied = false;
  var _picking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _boot();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _boot() async {
    setState(() {
      _loading = true;
      _denied = false;
      _error = null;
    });
    final perm = await PhotoManager.requestPermissionExtend(
      requestOption: const PermissionRequestOption(
        androidPermission: AndroidPermission(
          type: RequestType.image,
          mediaLocation: false,
        ),
      ),
    );
    if (!perm.hasAccess) {
      if (mounted) {
        setState(() {
          _denied = true;
          _loading = false;
        });
      }
      return;
    }
    try {
      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        onlyAll: true,
      );
      if (albums.isEmpty) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      _album = albums.first;
      await _loadPage(reset: true);
    } catch (e) {
      _error = '사진을 불러오지 못했어요.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadPage({bool reset = false}) async {
    final album = _album;
    if (album == null) return;
    if (reset) {
      _page = 0;
      _assets.clear();
      _hasMore = true;
    }
    if (!_hasMore) return;
    final next = await album.getAssetListPaged(page: _page, size: _pageSize);
    _assets.addAll(next);
    _hasMore = next.length >= _pageSize;
    _page += 1;
    if (mounted) setState(() {});
  }

  void _onScroll() {
    if (_loadingMore || !_hasMore || _loading) return;
    if (_scroll.position.extentAfter > 400) return;
    _loadingMore = true;
    _loadPage().whenComplete(() {
      if (mounted) setState(() => _loadingMore = false);
    });
  }

  Future<void> _openSettings() async {
    await PhotoManager.openSetting();
  }

  Future<void> _pick(AssetEntity asset) async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final bytes = await asset.thumbnailDataWithSize(
            const ThumbnailSize(1600, 1600),
            quality: 85,
          ) ??
          await asset.originBytes;
      if (!mounted) return;
      if (bytes == null || bytes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이 사진을 불러오지 못했어요. 다른 사진을 골라 주세요.')),
        );
        return;
      }
      Navigator.of(context).pop<Uint8List>(Uint8List.fromList(bytes));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사진을 준비하는 중 문제가 생겼어요.')),
      );
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('사진 선택'),
      ),
      body: Stack(
        children: [
          _body(),
          if (_picking)
            const ColoredBox(
              color: Color(0x66FFFFFF),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_denied) {
      return _Message(
        icon: Icons.lock_outline,
        title: '사진 접근 권한이 필요해요',
        body: '설정에서 사진 접근을 허용하면 앨범에서 프로필 사진을 고를 수 있어요.',
        actionLabel: '설정 열기',
        onAction: _openSettings,
      );
    }
    if (_error != null) {
      return _Message(
        icon: Icons.error_outline,
        title: '사진을 불러오지 못했어요',
        body: _error!,
        actionLabel: '다시 시도',
        onAction: _boot,
      );
    }
    if (_assets.isEmpty) {
      return const _Message(
        icon: Icons.photo_outlined,
        title: '앨범에 사진이 없어요',
        body: '에뮬레이터나 기기에 사진이 없으면 비어 보여요. 카메라로 촬영하거나 갤러리에 사진을 넣은 뒤 다시 시도해 주세요.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Text(
            '프로필에 올릴 사진을 한 장 골라 주세요',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.muted,
                ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemCount: _assets.length + (_loadingMore ? 1 : 0),
            itemBuilder: (context, i) {
              if (i >= _assets.length) {
                return const Center(child: CircularProgressIndicator());
              }
              return _AssetTile(
                asset: _assets[i],
                onTap: _picking ? null : () => _pick(_assets[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AssetTile extends StatefulWidget {
  const _AssetTile({required this.asset, required this.onTap});

  final AssetEntity asset;
  final VoidCallback? onTap;

  @override
  State<_AssetTile> createState() => _AssetTileState();
}

class _AssetTileState extends State<_AssetTile> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    widget.asset
        .thumbnailDataWithSize(const ThumbnailSize.square(400), quality: 80)
        .then((data) {
      if (mounted) setState(() => _bytes = data);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.panel,
      child: InkWell(
        onTap: widget.onTap,
        child: _bytes == null
            ? const ColoredBox(color: AppTheme.panel)
            : Ink.image(image: MemoryImage(_bytes!), fit: BoxFit.cover),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.brandSoft,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Icon(icon, color: AppTheme.brand, size: 32),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.muted,
                  height: 1.45,
                ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
