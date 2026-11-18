import 'package:sakina_app/core/theme/app_spacing.dart';
import 'package:sakina_app/l10n/localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/services/location_access_service.dart';
import '../../../../core/services/location_fix.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../onboarding/presentation/widgets/notification_permission_dialog.dart';
import '../../data/prayer_city_catalog.dart';
import '../../domain/prayer_calculation_policy.dart';
import '../../domain/prayer_city.dart';
import '../../domain/prayer_location_source.dart';
import '../providers/prayer_times_provider.dart';

/// Lets the user choose the active prayer location: a listed city, typed
/// coordinates, or the device's position. Shows which one is active now.
///
/// [promptForReminders] false skips the reminder prompts that normally
/// follow a first location (first-run setup has its own steps).
Future<void> showPrayerLocationDialog(
  BuildContext context,
  PrayerTimesProvider provider, {
  bool promptForReminders = true,
}) async {
  // Manual coordinates remain available if the catalog fails to load.
  final PrayerCityCatalog catalog = PrayerCityCatalog.bundled;
  await catalog.cities();
  if (!context.mounted) return;
  final name = TextEditingController(
    text: provider.selectedCoordinates == null ? '' : provider.locationLabel,
  );
  final latitude = TextEditingController(
    text: provider.selectedCoordinates?.latitude.toString(),
  );
  final longitude = TextEditingController(
    text: provider.selectedCoordinates?.longitude.toString(),
  );
  final form = GlobalKey<FormState>();
  var method = provider.selectedMethod;
  var useDevice = false;
  // The timezone is only trusted while the coordinates are still exactly
  // those it came with (a catalog city, or the saved place).
  ({String lat, String lon, String zone})? zoneSource =
      provider.selectedTimeZone == null
      ? null
      : (
          lat: latitude.text,
          lon: longitude.text,
          zone: provider.selectedTimeZone!,
        );
  final save = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(l10nOf(context).prayerLocationDialogMessage1),
        content: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (provider.selectedCoordinates != null) ...[
                  _ActiveLocationSummary(provider: provider),
                  const SizedBox(height: AppSpacing.ms),
                ],
                Autocomplete<PrayerCity>(
                  displayStringForOption: (city) => l10nOf(
                    context,
                  ).prayerLocationDialogMessage2(city.name, city.country),
                  optionsBuilder: (value) => catalog.search(value.text),
                  optionsViewBuilder: (context, onSelected, options) =>
                      _CityOptions(options: options, onSelected: onSelected),
                  fieldViewBuilder: (context, controller, focus, submit) =>
                      TextFormField(
                        controller: controller,
                        focusNode: focus,
                        decoration: InputDecoration(
                          labelText: l10nOf(
                            context,
                          ).prayerLocationDialogMessage3,
                          hintText: l10nOf(context).prayerCitySearchHint,
                          prefixIcon: const Icon(Icons.search),
                        ),
                      ),
                  onSelected: (city) {
                    name.text = l10nOf(
                      context,
                    ).prayerLocationDialogMessage2(city.name, city.country);
                    latitude.text = city.latitude.toString();
                    longitude.text = city.longitude.toString();
                    final zone = city.timeZone;
                    zoneSource = zone != null
                        ? (lat: latitude.text, lon: longitude.text, zone: zone)
                        : null;
                  },
                ),
                const SizedBox(height: AppSpacing.ms),
                Text(l10nOf(context).prayerLocationDialogMessage4),
                Text(l10nOf(context).prayerLocationDialogMessage5),
                TextFormField(
                  controller: name,
                  decoration: InputDecoration(
                    labelText: l10nOf(context).prayerLocationDialogMessage6,
                  ),
                ),
                TextFormField(
                  controller: latitude,
                  textDirection: TextDirection.ltr,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: InputDecoration(
                    labelText: l10nOf(context).prayerLocationDialogMessage7,
                  ),
                  validator: (text) => _coordinateError(text, 90),
                ),
                TextFormField(
                  controller: longitude,
                  textDirection: TextDirection.ltr,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: InputDecoration(
                    labelText: l10nOf(context).prayerLocationDialogMessage8,
                  ),
                  validator: (text) => _coordinateError(text, 180),
                ),
                DropdownButtonFormField<int>(
                  initialValue: method,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10nOf(context).prayerLocationDialogMessage9,
                  ),
                  items: PrayerCalculationPolicy.methods.entries
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => method = value!),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.my_location),
            label: Text(l10nOf(context).prayerTimesProviderMessage8),
            onPressed: () {
              useDevice = true;
              Navigator.pop(context, false);
            },
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10nOf(context).appStringsMessage9),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) Navigator.pop(context, true);
            },
            child: Text(l10nOf(context).appStringsMessage11),
          ),
        ],
      ),
    ),
  );
  if (save == true) {
    final source = zoneSource;
    final bool coordinatesUnchanged =
        source != null &&
        source.lat == latitude.text &&
        source.lon == longitude.text;
    final saved = provider.selectedCoordinates;
    // Saving only a new method keeps a device location a device location;
    // any other change is the user's own choice of place.
    final bool sameAsActive =
        saved != null &&
        latitude.text.trim() == saved.latitude.toString() &&
        longitude.text.trim() == saved.longitude.toString();
    final keepDevice =
        sameAsActive && provider.locationSource == PrayerLocationSource.device;
    await provider.selectLocation(
      double.parse(latitude.text.trim()),
      double.parse(longitude.text.trim()),
      name.text,
      method,
      // Typed coordinates fall back to the device timezone.
      timeZone: coordinatesUnchanged ? source.zone : null,
      source: keepDevice
          ? PrayerLocationSource.device
          : PrayerLocationSource.manual,
      fix: keepDevice && provider.locationFixedAt != null
          ? DeviceLocationFix(
              latitude: saved.latitude,
              longitude: saved.longitude,
              timestamp: provider.locationFixedAt!,
              source: LocationFixSource.fresh,
              accuracyMeters: provider.locationAccuracyMeters,
            )
          : null,
    );
  } else if (useDevice) {
    await provider.useDeviceLocation();
    if (context.mounted) showDeviceLocationOutcome(context, provider);
  }
  // Wait until the dialog's reverse transition releases its text fields.
  await Future<void>.delayed(const Duration(milliseconds: 300));
  name.dispose();
  latitude.dispose();
  longitude.dispose();
  if (promptForReminders && provider.hasData && context.mounted) {
    await promptForNotificationPermissionOnce(context);
  }
}

/// After a device lookup: says when the last known position was used, or
/// why the lookup failed while the saved location stays active, with the
/// settings page that can fix it.
void showDeviceLocationOutcome(
  BuildContext context,
  PrayerTimesProvider provider,
) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  final l10n = l10nOf(context);
  final error = provider.lastLocationError;
  if (error != null && provider.hasData) {
    final access = error.access;
    messenger.showSnackBar(
      SnackBar(
        content: Text(error.message),
        action: error.needsSettings && access != null
            ? SnackBarAction(
                label: access == LocationAccessStatus.servicesDisabled
                    ? l10n.permissionIntroOpenLocationSettings
                    : l10n.permissionIntroOpenSettings,
                onPressed: () => LocationAccessService().openSettings(access),
              )
            : null,
      ),
    );
  } else if (error == null && provider.lastFixWasStale) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.staleLocationNotice)));
  }
}

/// The active location, where it came from and, for a device location,
/// how precise it is.
class _ActiveLocationSummary extends StatelessWidget {
  const _ActiveLocationSummary({required this.provider});

  final PrayerTimesProvider provider;

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final device = provider.locationSource == PrayerLocationSource.device;
    final accuracy = provider.locationAccuracyMeters;
    final lines = [
      device ? l10n.locationSourceDevice : l10n.locationSourceManual,
      if (device &&
          accuracy != null &&
          accuracy > LocationQuality.approximateAccuracyMeters)
        l10n.locationAccuracyApproximate(_distance(l10n, accuracy)),
    ];
    return Container(
      key: const Key('active-prayer-location'),
      padding: const EdgeInsets.all(AppSpacing.ms),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.06),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Icon(
              device ? Icons.my_location_rounded : Icons.location_city_rounded,
              color: colors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(provider.locationLabel, style: theme.textTheme.titleSmall),
                for (final line in lines)
                  Text(line, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _distance(AppLocalizations l10n, double meters) =>
      meters >= 1000
      ? l10n.distanceKilometers(
          (meters / 1000).toStringAsFixed(meters < 10000 ? 1 : 0),
        )
      : l10n.distanceMeters('${(meters / 10).round() * 10}');
}

String? _coordinateError(String? input, double max) {
  final value = double.tryParse(input?.trim() ?? '');
  return value == null || !value.isFinite || value.abs() > max
      ? appL10n.prayerLocationDialogMessage10
      : null;
}

/// Search results: the Arabic name with its country, and the Latin name
/// underneath so a name taken from GeoNames can be recognised.
class _CityOptions extends StatelessWidget {
  const _CityOptions({required this.options, required this.onSelected});

  final Iterable<PrayerCity> options;
  final AutocompleteOnSelected<PrayerCity> onSelected;

  @override
  Widget build(BuildContext context) {
    final List<PrayerCity> cities = options.toList();
    return Align(
      alignment: AlignmentDirectional.topStart,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 280, maxWidth: 360),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: cities.length,
            itemBuilder: (context, index) {
              final PrayerCity city = cities[index];
              final bool showLatin =
                  city.englishName.isNotEmpty && city.englishName != city.name;
              return ListTile(
                dense: true,
                title: Text(
                  l10nOf(
                    context,
                  ).prayerLocationDialogMessage2(city.name, city.country),
                ),
                subtitle: showLatin
                    ? Text(
                        city.englishName,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.end,
                      )
                    : null,
                onTap: () => onSelected(city),
              );
            },
          ),
        ),
      ),
    );
  }
}
