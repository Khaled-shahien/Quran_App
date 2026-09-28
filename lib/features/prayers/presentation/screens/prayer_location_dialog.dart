import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../../../quran/domain/services/quran_search.dart';
import '../../domain/prayer_calculation_policy.dart';
import '../providers/prayer_times_provider.dart';

Future<void> showPrayerLocationDialog(
  BuildContext context,
  PrayerTimesProvider provider,
) async {
  List<Map<String, dynamic>> cities = [];
  try {
    cities =
        (jsonDecode(await rootBundle.loadString('assets/prayer_cities.json'))
                as List)
            .cast<Map<String, dynamic>>();
  } catch (_) {
    /* Manual coordinates remain available if the catalog fails. */
  }
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
  final save = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('موقع الصلاة وطريقة الحساب'),
        content: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Autocomplete<Map<String, dynamic>>(
                  displayStringForOption: (city) =>
                      '${city['name']}، ${city['country']}',
                  optionsBuilder: (value) {
                    final query = normalizeArabicSearch(value.text.trim());
                    if (query.isEmpty) return cities;
                    return cities.where(
                      (city) => normalizeArabicSearch(
                        '${city['name']} ${city['englishName']} ${city['country']}',
                      ).contains(query),
                    );
                  },
                  fieldViewBuilder: (context, controller, focus, submit) =>
                      TextFormField(
                        controller: controller,
                        focusNode: focus,
                        decoration: const InputDecoration(
                          labelText: 'بحث في المدن المتاحة دون اتصال',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                  onSelected: (city) {
                    name.text = '${city['name']}، ${city['country']}';
                    latitude.text = city['latitude'].toString();
                    longitude.text = city['longitude'].toString();
                  },
                ),
                const SizedBox(height: 12),
                const Text(
                  'المدن تستخدم إحداثيات وسط المدينة. إذا لم تجد مدينتك، أدخل الإحداثيات أو استخدم موقع الجهاز.',
                ),
                const Text(
                  'تُرسل الإحداثيات إلى Aladhan لحساب المواقيت. أدخل موقعاً يدوياً أو استخدم موقع الجهاز.',
                ),
                TextFormField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'اسم المكان'),
                ),
                TextFormField(
                  controller: latitude,
                  textDirection: TextDirection.ltr,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'خط العرض (من ‎-90 إلى 90)',
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
                  decoration: const InputDecoration(
                    labelText: 'خط الطول (من ‎-180 إلى 180)',
                  ),
                  validator: (text) => _coordinateError(text, 180),
                ),
                DropdownButtonFormField<int>(
                  initialValue: method,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'طريقة الحساب'),
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
            label: const Text('موقع الجهاز'),
            onPressed: () {
              useDevice = true;
              Navigator.pop(context, false);
            },
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) Navigator.pop(context, true);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    ),
  );
  if (save == true) {
    await provider.selectLocation(
      double.parse(latitude.text.trim()),
      double.parse(longitude.text.trim()),
      name.text,
      method,
    );
  } else if (useDevice) {
    await provider.useDeviceLocation();
  }
  // Wait until the dialog's reverse transition releases its text fields.
  await Future<void>.delayed(const Duration(milliseconds: 300));
  name.dispose();
  latitude.dispose();
  longitude.dispose();
}

String? _coordinateError(String? input, double max) {
  final value = double.tryParse(input?.trim() ?? '');
  return value == null || !value.isFinite || value.abs() > max
      ? 'أدخل إحداثيات صحيحة'
      : null;
}
