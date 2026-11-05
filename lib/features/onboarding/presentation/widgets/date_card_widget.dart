import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sakina_app/l10n/localization.dart';

import '../../../../core/providers/settings_provider.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/dual_date.dart';

/// Home card showing today's Hijri and Gregorian dates.
///
/// Refreshes itself just after midnight and when the app resumes, so a
/// screen left open overnight never shows yesterday's date.
class DateCardWidget extends StatefulWidget {
  const DateCardWidget({super.key, this.clock = DateTime.now});

  final DateTime Function() clock;

  @override
  State<DateCardWidget> createState() => _DateCardWidgetState();
}

class _DateCardWidgetState extends State<DateCardWidget>
    with WidgetsBindingObserver {
  late DualDate _date;
  Timer? _midnightTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  int _hijriOffsetDays = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Optional so the card still works where settings are not provided.
    final int offset =
        Provider.of<SettingsProvider?>(context)?.hijriOffsetDays ?? 0;
    if (offset != _hijriOffsetDays) {
      _hijriOffsetDays = offset;
      _refresh();
    }
  }

  void _refresh() {
    final DateTime now = widget.clock();
    _date = DualDate.of(now, hijriOffsetDays: _hijriOffsetDays);
    _midnightTimer?.cancel();
    final DateTime nextMidnight = DateTime(now.year, now.month, now.day + 1);
    _midnightTimer = Timer(
      nextMidnight.difference(now) + const Duration(seconds: 1),
      () {
        if (mounted) setState(_refresh);
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) setState(_refresh);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnightTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final String? hijri = _date.hijri;

    return Semantics(
      container: true,
      label: l10nOf(
        context,
      ).dateCardSemantics(_date.weekday, hijri ?? '', _date.gregorian),
      excludeSemantics: true,
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          0,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: AppRadius.card,
          border: Border.all(color: scheme.primary.withValues(alpha: 0.22)),
          boxShadow: AppShadows.subtle,
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.calendar_month_rounded, color: scheme.primary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _date.weekday,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
                  ),
                  if (hijri != null)
                    _DateLine(
                      label: l10nOf(context).dateCardHijriLabel,
                      value: hijri,
                      emphasized: true,
                    ),
                  _DateLine(
                    label: l10nOf(context).dateCardGregorianLabel,
                    value: _date.gregorian,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateLine extends StatelessWidget {
  const _DateLine({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          TextSpan(
            text: '$label: ',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
      style:
          (emphasized ? theme.textTheme.titleSmall : theme.textTheme.bodySmall)
              ?.copyWith(fontFamily: 'Cairo', height: 1.6),
    );
  }
}
