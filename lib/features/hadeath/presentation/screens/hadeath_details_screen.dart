import 'package:sakina_app/l10n/localization.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/hadeath_entity.dart';

class HadeathDetailsScreen extends StatelessWidget {
  final HadeathEntity hadeath;

  const HadeathDetailsScreen({super.key, required this.hadeath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: l10nOf(context).appStringsMessage13,
          icon: Icon(
            Icons.arrow_back_ios,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          hadeath.title
              .replaceAll('  ', ' ')
              .trim(), // Clean up excessive spaces in title
          style: TextStyle(
            fontSize: 20,
            color: Theme.of(context).colorScheme.primary,
            fontFamily: 'Amiri',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              // شريط البسملة الداخلي ليتماشى
              // مع تصميم السور لو أحببنا
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                margin: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(10),
                ),
                width: double.infinity,
                child: Text(
                  l10nOf(context).hadeathDetailsScreenMessage1,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Amiri',
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 16,
                  ),
                ),
              ),

              // محتوى الحديث
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  child: Text(
                    hadeath.content.join(
                      ' ',
                    ), // Join lines with spaces as it's continuous text
                    textAlign: TextAlign.justify,
                    style: TextStyle(
                      fontSize: 24,
                      color: Theme.of(context).colorScheme.primary,
                      height: 1.8,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Amiri',
                    ),
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
