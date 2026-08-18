import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/mock_data.dart';
import '../services/session.dart';
import 'candidate_detail_screen.dart';

/// Deep-link / legacy entry → resolves counterpart and opens profile surface.
class InterestDetailScreen extends StatefulWidget {
  const InterestDetailScreen({super.key, required this.interestId});

  final String interestId;

  @override
  State<InterestDetailScreen> createState() => _InterestDetailScreenState();
}

class _InterestDetailScreenState extends State<InterestDetailScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final push = context.read<AppSession>().push;
      push.viewingInterestId = widget.interestId;
      push.dismissBanner();
    });
    _openProfile();
  }

  Future<void> _openProfile() async {
    try {
      final session = context.read<AppSession>();
      String? userId;

      if (session.isMock) {
        final res = MockData.interestDetail(widget.interestId);
        final interest = Map<String, dynamic>.from(res['interest'] as Map);
        final cp = res['counterpart'];
        if (cp is Map && cp['user_id'] != null) {
          userId = cp['user_id'].toString();
        }
        userId ??= interest['from_user_id'] == 'mock-me'
            ? interest['to_user_id']?.toString()
            : interest['from_user_id']?.toString();
      } else {
        final res =
            await session.api.get('/api/mobile/interest/${widget.interestId}');
        final cp = res['counterpart'];
        if (cp is Map) userId = cp['user_id']?.toString();
        final interest = res['interest'];
        if (userId == null && interest is Map) {
          final me = session.user?.id;
          final from = interest['from_user_id']?.toString();
          final to = interest['to_user_id']?.toString();
          if (me != null && from != null && to != null) {
            userId = me == from ? to : from;
          }
        }
      }

      if (!mounted) return;
      if (userId == null) {
        setState(() => _error = '상대 프로필을 찾을 수 없습니다.');
        return;
      }

      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CandidateDetailScreen(
            userId: userId!,
            interestId: widget.interestId,
          ),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('소개 프로필')),
      body: Center(
        child: _error != null
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!, textAlign: TextAlign.center),
              )
            : const CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}
