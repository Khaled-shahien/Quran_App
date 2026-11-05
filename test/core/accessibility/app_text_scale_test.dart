import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/core/accessibility/app_text_scale.dart';
import 'package:sakina_app/features/settings/presentation/providers/text_size_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('multiplies the system scale instead of replacing it', () {
    const scaler = AppTextScaler(TextScaler.linear(2), 1.3);
    expect(scaler.scale(10), closeTo(26, 1e-9));
  });

  test('text size defaults to normal and is remembered', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final controller = TextSizeController(prefs);
    expect(controller.size, AppTextSize.normal);
    expect(controller.factor, 1.0);

    await controller.setSize(AppTextSize.larger);
    expect(TextSizeController(prefs).size, AppTextSize.larger);
  });

  test('an unknown stored value falls back to normal', () async {
    SharedPreferences.setMockInitialValues({TextSizeController.key: 'huge'});
    final prefs = await SharedPreferences.getInstance();
    expect(TextSizeController(prefs).size, AppTextSize.normal);
  });

  testWidgets('UI text grows; Quran text keeps the system scale', (
    tester,
  ) async {
    late double ui;
    late double quran;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.2)),
        child: AppTextScale(
          factor: 1.5,
          child: Builder(
            builder: (context) {
              ui = MediaQuery.textScalerOf(context).scale(10);
              return SystemTextScale(
                child: Builder(
                  builder: (context) {
                    quran = MediaQuery.textScalerOf(context).scale(10);
                    return const SizedBox();
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
    expect(ui, closeTo(18, 1e-9));
    expect(quran, closeTo(12, 1e-9));
  });
}
