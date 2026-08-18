import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/session.dart';
import '../theme.dart';

class EconomyHeader extends StatelessWidget {
  const EconomyHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();
    final state = session.memberState;
    final gender = state?['profile']?['gender']?.toString();
    if (gender != 'male') return const SizedBox.shrink();
    final credits = state?['economy']?['credits'] ?? 0;
    final tickets = state?['economy']?['withdrawTickets'] ?? 0;
    final creditTip = state?['copy']?['creditTooltip']?.toString() ?? '';
    final withdrawTip = state?['copy']?['withdrawTooltip']?.toString() ?? '';

    return Row(
      children: [
        _IconTip(
          label: '💰 $credits',
          title: '크레딧',
          body: creditTip,
        ),
        const SizedBox(width: 8),
        _IconTip(
          label: '🔖 $tickets',
          title: '철회권',
          body: withdrawTip,
        ),
      ],
    );
  }
}

class _IconTip extends StatelessWidget {
  const _IconTip({
    required this.label,
    required this.title,
    required this.body,
  });

  final String label;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(title),
            content: Text(body),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.ink,
          ),
        ),
      ),
    );
  }
}
