import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';
import '../services/session.dart';
import '../theme.dart';
import 'chat_room_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  var _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rooms = [];

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
    try {
      final res = await context.read<AppSession>().api.get('/api/mobile/chat');
      _rooms = List<Map<String, dynamic>>.from((res['rooms'] as List?) ?? []);
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('채팅')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : ListView(
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(_error!, style: const TextStyle(color: AppTheme.danger)),
                    ),
                  if (_rooms.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('열린 채팅방이 없습니다. 소개가 수락되면 여기에 나타납니다.'),
                    ),
                  for (final room in _rooms)
                    ListTile(
                      title: Text(
                        (room['counterpart']?['nickname'] ?? '상대').toString(),
                      ),
                      subtitle: Text(
                        room['counterpartLeft'] == true
                            ? '상대가 나갔습니다'
                            : (room['lastMessage']?['body'] ?? '대화를 시작해 보세요').toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ChatRoomScreen(
                              roomId: room['id'] as String,
                              title: (room['counterpart']?['nickname'] ?? '채팅')
                                  .toString(),
                              counterpartId:
                                  room['counterpart']?['user_id']?.toString(),
                            ),
                          ),
                        );
                        _load();
                      },
                    ),
                ],
              ),
      ),
    );
  }
}
