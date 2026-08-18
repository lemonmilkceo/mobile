import 'package:flutter/material.dart';

import '../theme.dart';

class DualRangeSlider extends StatelessWidget {
  const DualRangeSlider({
    super.key,
    required this.label,
    required this.min,
    required this.max,
    required this.values,
    required this.onChanged,
    required this.format,
    this.divisions,
  });

  final String label;
  final double min;
  final double max;
  final RangeValues values;
  final ValueChanged<RangeValues> onChanged;
  final String Function(int min, int max) format;
  final int? divisions;

  @override
  Widget build(BuildContext context) {
    final lo = values.start.round();
    final hi = values.end.round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              format(lo, hi),
              style: const TextStyle(color: AppTheme.muted),
            ),
          ],
        ),
        RangeSlider(
          min: min,
          max: max,
          divisions: divisions ?? (max - min).round(),
          values: RangeValues(
            values.start.clamp(min, max),
            values.end.clamp(min, max),
          ),
          activeColor: AppTheme.ink,
          inactiveColor: AppTheme.line,
          labels: RangeLabels('$lo', '$hi'),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class HeightSlider extends StatelessWidget {
  const HeightSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 140,
    this.max = 200,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('키', style: TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            Text(
              '${value}cm',
              style: const TextStyle(color: AppTheme.muted),
            ),
          ],
        ),
        Slider(
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          value: value.clamp(min, max).toDouble(),
          activeColor: AppTheme.ink,
          inactiveColor: AppTheme.line,
          label: '${value}cm',
          onChanged: (v) => onChanged(v.round()),
        ),
      ],
    );
  }
}
