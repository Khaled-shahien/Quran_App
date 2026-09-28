import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class AsmaItemCard extends StatelessWidget {
  final String number;
  final String arabicName;
  final String meaning;

  const AsmaItemCard({
    super.key,
    required this.number,
    required this.arabicName,
    required this.meaning,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 1,
        ),
      ),
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    number,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                arabicName,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                meaning,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.secondaryText,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
