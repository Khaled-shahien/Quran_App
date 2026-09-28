import 'package:flutter/widgets.dart';

import 'app_localizations.dart';
import 'app_localizations_ar.dart';

/// Arabic is the app's only supported locale. This fallback also serves
/// background notifications and providers that have no widget context.
final AppLocalizations appL10n = AppLocalizationsAr();

/// Use the widget locale when available, including isolated widget previews.
AppLocalizations l10nOf(BuildContext context) =>
    AppLocalizations.of(context) ?? appL10n;
