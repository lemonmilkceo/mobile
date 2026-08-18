import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/api_client.dart';
import '../services/session.dart';
import '../theme.dart';
import 'report_screen.dart';

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({
    super.key,
    required this.roomId,
    required this.title,
    this.counterpartId,
  });

  final String roomId;
  final String title;
  final String? counterpartId;

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _input = TextEditingController();
  var _loading = true;
  var _left = false;
  String? _error;
  List<Map<String, dynamic>> _messages = [];
  Timer? _poll;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 4), (_) => _refreshQuiet());
    _channel = Supabase.instance.client
        .channel('chat-${widget.roomId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: widget.roomId,
          ),
          callback: (_) => _refreshQuiet(),
        )
        .subscribe();
  }

  @override
  void dispose() {
    _poll?.cancel();
    final ch = _channel;
    if (ch != null) {
      Supabase.instance.client.removeChannel(ch);
    }
    _input.dispose();
    super.dispose();
  }

  Future<void> _refreshQuiet() async {
    if (!mounted || _left) return;
    try {
      final res = await context
          .read<AppSession>()
          .api
          .get('/api/mobile/chat/${widget.roomId}');
      if (!mounted) return;
      setState(() {
        _left = res['left'] == true;
        _messages =
            List<Map<String, dynamic>>.from((res['messages'] as List?) ?? []);
      });
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await context
          .read<AppSession>()
          .api
          .get('/api/mobile/chat/${widget.roomId}');
      _left = res['left'] == true;
      _messages = List<Map<String, dynamic>>.from((res['messages'] as List?) ?? []);
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _left) return;
    try {
      await context.read<AppSession>().api.post(
        '/api/mobile/chat/${widget.roomId}/messages',
        {'body': text},
      );
      _input.clear();
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _leave() async {
    await context.read<AppSession>().api.post(
      '/api/mobile/chat/${widget.roomId}/leave',
    );
    if (mounted) Navigator.pop(context);
  }

  Future<void> _hide() async {
    await context.read<AppSession>().api.post(
      '/api/mobile/chat/${widget.roomId}/hide',
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.watch<AppSession>().user?.id;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'leave') await _leave();
              if (v == 'hide') await _hide();
              if (v == 'report' && widget.counterpartId != null && mounted) {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ReportScreen(
                      targetUserId: widget.counterpartId!,
                      chatRoomId: widget.roomId,
                    ),
                  ),
                );
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'leave', child: Text('나가기')),
              const PopupMenuItem(value: 'hide', child: Text('삭제')),
              if (widget.counterpartId != null)
                const PopupMenuItem(value: 'report', child: Text('신고')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(_error!, style: const TextStyle(color: AppTheme.danger)),
            ),
          if (_left)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('이 방에서 나갔습니다. 다시 들어갈 수 없습니다.'),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (ctx, i) {
                      final m = _messages[i];
                      final mine = m['sender_id'] == myId;
                      return Align(
                        alignment:
                            mine ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: mine ? AppTheme.ink : AppTheme.line,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            m['body']?.toString() ?? '',
                            style: TextStyle(
                              color: mine ? Colors.white : AppTheme.ink,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      enabled: !_left,
                      decoration: const InputDecoration(hintText: '메시지'),
                    ),
                  ),
                  IconButton(
                    onPressed: _left ? null : _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
