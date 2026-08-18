import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';
import '../services/session.dart';
import '../theme.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key, required this.interestId});

  final String interestId;

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  var _rating = 0;
  final _selected = <String>{};
  final _body = TextEditingController();
  var _busy = false;

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('별점을 선택해 주세요.')),
      );
      return;
    }
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('키워드를 하나 이상 선택해 주세요.')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await context.read<AppSession>().api.post('/api/mobile/reviews', {
        'interestId': widget.interestId,
        'rating': _rating,
        'keywords': _selected.toList(),
        if (_body.text.trim().isNotEmpty) 'body': _body.text.trim(),
      });
      if (!mounted) return;
      await context.read<AppSession>().refreshMemberState();
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notice = context.watch<AppSession>().memberState?['copy']?['reviewNotice']
            ?.toString() ??
        '이 평가는 상대에게 보이지 않습니다. 평가를 완료해야 다음 소개를 이용할 수 있습니다.';
    final keywords = List<String>.from(
      (context.watch<AppSession>().memberState?['copy']?['reviewKeywords'] as List?) ??
          const [],
    );

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('소개 평가')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(notice, style: const TextStyle(height: 1.5, color: AppTheme.muted)),
          const SizedBox(height: 16),
          Row(
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  onPressed: () => setState(() => _rating = i),
                  icon: Icon(
                    i <= _rating ? Icons.star : Icons.star_border,
                    color: AppTheme.ink,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          for (final key in keywords)
            CheckboxListTile(
              value: _selected.contains(key),
              onChanged: (v) {
                setState(() {
                  if (v == true) {
                    _selected.add(key);
                  } else {
                    _selected.remove(key);
                  }
                });
              },
              title: Text(key),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          TextField(
            controller: _body,
            maxLines: 4,
            decoration: const InputDecoration(labelText: '상세 (선택)'),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: Text(_busy ? '저장 중…' : '평가 제출'),
          ),
        ],
      ),
    );
  }
}
