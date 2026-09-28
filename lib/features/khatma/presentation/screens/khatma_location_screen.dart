import 'package:sakina_app/l10n/localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';

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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = isDarkMode ? Colors.white70 : const Color(0xFF6B6A66);
    final cardColor = isDarkMode ? AppColors.darkCardContent : Colors.white;
    final dropdownTextColor = isDarkMode ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          l10nOf(context).khatmaDurationScreenMessage1,
          style: const TextStyle(
            fontFamily: 'Cairo',
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle:
            false, // In RTL, this puts it to the left of the back button
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title text
              Text(
                l10nOf(context).khatmaLocationScreenMessage2,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: textColor, // Dark brownish-grey or light
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 60),

              // Dropdown
              Directionality(
                textDirection: TextDirection.rtl,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      l10nOf(context).khatmaLocationScreenMessage3,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedStartMode,
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: isDarkMode ? Colors.white54 : Colors.grey,
                            ),
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 16,
                              color: dropdownTextColor,
                              fontWeight: FontWeight.w600,
                            ),
                            isExpanded: true,
                            items: _startModes.map((String mode) {
                              return DropdownMenuItem<String>(
                                value: mode,
                                child: Text(mode),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedStartMode = newValue;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Show Juz selector if manual is selected
              if (_selectedStartMode == 'جزء مخصص')
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Row(
                    children: [
                      Text(
                        l10nOf(context).khatmaLocationScreenMessage4,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _selectedJuz,
                              icon: Icon(
                                Icons.arrow_drop_down,
                                color: isDarkMode
                                    ? Colors.white54
                                    : Colors.grey,
                              ),
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 16,
                                color: dropdownTextColor,
                                fontWeight: FontWeight.w600,
                              ),
                              isExpanded: true,
                              items: List.generate(30, (index) => index + 1)
                                  .map((int juz) {
                                    return DropdownMenuItem<int>(
                                      value: juz,
                                      child: Text(
                                        l10nOf(
                                          context,
                                        ).khatmaLocationScreenMessage5(
                                          (juz).toString(),
                                        ),
                                      ),
                                    );
                                  })
                                  .toList(),
                              onChanged: (int? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedJuz = newValue;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const Spacer(),

              // Continue Button
              ElevatedButton(
                onPressed: () {
                  context.push(
                    '/khatma/duration',
                    extra: {
                      'startMode': _selectedStartMode,
                      'startJuz': _selectedJuz,
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  l10nOf(context).khatmaDurationScreenMessage14,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
