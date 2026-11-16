import 'package:sakina_app/core/theme/app_spacing.dart';
import 'package:flutter/widgets.dart';

/// A label beside its controls; the label moves above them when large
/// text would not fit on one line. Children: label, gap, controls...
class LabeledRow extends StatelessWidget {
  const LabeledRow({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.textScalerOf(context).scale(1) <= 1.3) {
      return Row(children: children);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        children.first,
        const SizedBox(height: AppSpacing.sm),
        Row(children: children.skip(2).toList()),
      ],
    );
  }
}
