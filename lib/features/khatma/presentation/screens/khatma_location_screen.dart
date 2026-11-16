import 'package:sakina_app/core/widgets/sakina_hero_app_bar.dart';
import 'package:sakina_app/core/accessibility/digit_style.dart';
import 'package:sakina_app/core/theme/app_motion.dart';
import 'package:sakina_app/core/theme/app_spacing.dart';
import 'package:sakina_app/core/widgets/sakina_card.dart';
import 'package:sakina_app/l10n/localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/khatma_dropdown.dart';
import '../widgets/labeled_row.dart';

class KhatmaLocationScreen extends StatefulWidget {
  const KhatmaLocationScreen({super.key});

  @override
  State<KhatmaLocationScreen> createState() => _KhatmaLocationScreenState();
}

class _KhatmaLocationScreenState extends State<KhatmaLocationScreen> {
  // Option: 'بداية المصحف' or 'جزء مخصص' etc.
  String _selectedStartMode = appL10n.appRouterMessage4;
  int _selectedJuz = 1;

  final List<String> _startModes = [
    appL10n.appRouterMessage4,
    appL10n.khatmaLocationScreenMessage1,
  ];

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme text = theme.textTheme;
    final bool customJuz =
        _selectedStartMode == appL10n.khatmaLocationScreenMessage1;

    return SakinaHeroScaffold(
      title: l10nOf(context).khatmaDurationScreenMessage1,
      // Scrolls when large text needs more room; the continue button stays
      // at the bottom when everything fits.
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10nOf(context).khatmaLocationScreenMessage2,
                  textAlign: TextAlign.center,
                  style: text.titleLarge,
                ),
                const SizedBox(height: AppSpacing.xl),
                SakinaCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LabeledRow(
                        children: [
                          Text(
                            l10nOf(context).khatmaLocationScreenMessage3,
                            style: text.titleSmall,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: KhatmaDropdown<String>(
                              value: _selectedStartMode,
                              items: [
                                for (final mode in _startModes)
                                  DropdownMenuItem<String>(
                                    value: mode,
                                    child: Text(mode),
                                  ),
                              ],
                              onChanged: (value) =>
                                  setState(() => _selectedStartMode = value),
                            ),
                          ),
                        ],
                      ),
                      // The juz picker opens only for a custom start.
                      AnimatedSize(
                        duration: AppMotion.of(context, AppMotion.base),
                        curve: AppMotion.standard,
                        alignment: AlignmentDirectional.topStart,
                        child: !customJuz
                            ? const SizedBox(width: double.infinity)
                            : Padding(
                                padding: const EdgeInsets.only(
                                  top: AppSpacing.md,
                                ),
                                child: LabeledRow(
                                  children: [
                                    Text(
                                      l10nOf(
                                        context,
                                      ).khatmaLocationScreenMessage4,
                                      style: text.titleSmall,
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: KhatmaDropdown<int>(
                                        value: _selectedJuz,
                                        items: [
                                          for (var juz = 1; juz <= 30; juz++)
                                            DropdownMenuItem<int>(
                                              value: juz,
                                              child: Text(
                                                l10nOf(
                                                  context,
                                                ).khatmaLocationScreenMessage5(
                                                  context.digits(juz),
                                                ),
                                              ),
                                            ),
                                        ],
                                        onChanged: (value) => setState(
                                          () => _selectedJuz = value,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: () {
                    context.push(
                      '/khatma/duration',
                      extra: {
                        'startMode': _selectedStartMode,
                        'startJuz': _selectedJuz,
                      },
                    );
                  },
                  child: Text(l10nOf(context).khatmaDurationScreenMessage14),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
