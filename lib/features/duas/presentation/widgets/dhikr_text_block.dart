import 'package:flutter/material.dart';

import '../../data/models/azkar_model.dart';

/// Dhikr text with any source guidance (before/after) set apart in a smaller,
/// quieter style, so the guidance is never read as part of the dhikr.
class DhikrTextBlock extends StatelessWidget {
  const DhikrTextBlock({super.key, required this.item});

  final AzkarItemModel item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final guidance = TextStyle(
      fontFamily: 'Cairo',
      fontSize: 15,
      height: 1.7,
      color: scheme.onSurfaceVariant,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (item.instructionBefore.isNotEmpty) ...[
          Text(
            item.instructionBefore,
            key: const Key('dhikr-instruction-before'),
            style: guidance,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
        ],
        Text(
          item.text,
          key: const Key('dhikr-text'),
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 22,
            height: 2.0,
            color: scheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        if (item.instructionAfter.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            item.instructionAfter,
            key: const Key('dhikr-instruction-after'),
            style: guidance,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
