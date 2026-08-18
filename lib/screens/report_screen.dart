import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';
import '../services/session.dart';
import '../theme.dart';

const _reasons = <(String, String)>[
  ('no_show', '노쇼 신고'),
  ('same_day_cancel', '약속 당일 취소'),
  ('ghosting', '반복적인 연락 두절'),
  ('inappropriate', '부적절한 언행'),
  ('fake_profile', '허위 프로필'),
  ('money_request', '금전 요구'),
  ('sales', '영업'),
  ('mlm', '다단계'),
  ('investment', '투자 권유'),
  ('harassment', '성희롱'),
  ('ai_photo', 'AI 생성(합성) 사진 의심'),
];

class ReportScreen extends StatefulWidget {
  const ReportScreen({
    super.key,
    required this.targetUserId,
    this.interestId,
    this.chatRoomId,
  });

  final String targetUserId;
  final String? interestId;
  final String? chatRoomId;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _selected = <String>{};
  final _body = TextEditingController();
  var _busy = false;

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사유를 하나 이상 선택해 주세요.')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await context.read<AppSession>().api.post('/api/mobile/reports', {
        'targetUserId': widget.targetUserId,
        'reasonIds': _selected.toList(),
        if (_body.text.trim().isNotEmpty) 'body': _body.text.trim(),
        if (widget.interestId != null) 'interestId': widget.interestId,
        if (widget.chatRoomId != null) 'chatRoomId': widget.chatRoomId,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('신고가 접수되었습니다.')),
      );
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('신고')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('해당하는 사유를 모두 골라 주세요. 영상은 첨부할 수 없습니다.'),
          const SizedBox(height: 12),
          for (final reason in _reasons)
            CheckboxListTile(
              value: _selected.contains(reason.$1),
              onChanged: (v) {
                setState(() {
                  if (v == true) {
                    _selected.add(reason.$1);
                  } else {
                    _selected.remove(reason.$1);
                  }
                });
              },
              title: Text(reason.$2),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          TextField(
            controller: _body,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: '상세 (선택)',
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: Text(_busy ? '접수 중…' : '신고하기'),
          ),
        ],
      ),
    );
  }
}
