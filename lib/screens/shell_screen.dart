import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../services/session.dart';
import 'chat_list_screen.dart';
import 'feed_screen.dart';
import 'inbox_screen.dart';
import 'review_screen.dart';
import 'settings_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key, this.initialInterestId});

  final String? initialInterestId;

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialInterestId != null ? 1 : 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppSession>().refreshMemberState();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const FeedScreen(),
      InboxScreen(highlightInterestId: widget.initialInterestId),
      const ChatListScreen(),
      const SettingsScreen(),
    ];
    final pending =
        context.watch<AppSession>().memberState?['pendingReviewId']?.toString();

    return Scaffold(
      body: Column(
        children: [
          if (pending != null && pending.isNotEmpty)
            SafeArea(
              bottom: false,
              child: Material(
                color: const Color(0xFF111111),
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ReviewScreen(interestId: pending),
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.fromLTRB(16, 10, 16, 10),
                    child: Text(
                      '평가를 완료해야 다음 소개를 이용할 수 있습니다. 이 평가는 상대에게 보이지 않습니다.',
                      style: TextStyle(color: Colors.white, height: 1.4),
                    ),
                  ),
                ),
              ),
            ),
          Expanded(child: IndexedStack(index: _index, children: pages)),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: '인물',
          ),
          NavigationDestination(
            icon: Icon(Icons.mail_outline),
            selectedIcon: Icon(Icons.mail),
            label: '받은 소개',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: '채팅',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '내 정보',
          ),
        ],
      ),
    );
  }
}
