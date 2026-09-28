import 'package:sakina_app/l10n/localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../../../../core/theme/app_colors.dart';
import '../providers/favorites_provider.dart';

class DailyVerseSectionWidget extends StatefulWidget {
  const DailyVerseSectionWidget({super.key});

  @override
  State<DailyVerseSectionWidget> createState() =>
      _DailyVerseSectionWidgetState();
}

class _DailyVerseSectionWidgetState extends State<DailyVerseSectionWidget> {
  final List<Map<String, String>> _dailyVerses = [
    {
      'surah': 'سورة الفاتحة',
      'arabic':
          'الْحَمْدُ لِلَّهِ '
          'رَبِّ الْعَالَمِينَ',
      'english': 'All praise and thanks be to the Lord of the worlds.',
    },
    {
      'surah': 'سورة البقرة',
      'arabic':
          'لَا يُكَلِّفُ اللَّهُ '
          'نَفْسًا إِلَّا وُسْعَهَا',
      'english': 'Allah does not burden a soul beyond that it can bear.',
    },
    {
      'surah': 'سورة غافر',
      'arabic':
          'وَقَالَ رَبُّكُمُ '
          'ادْعُونِي أَسْتَجِبْ لَكُمْ',
      'english': 'And your Lord says, "Call upon Me; I will respond to you."',
    },
    {
      'surah': 'سورة الشرح',
      'arabic': 'فَإِنَّ مَعَ الْعُسْرِ يُسْرًا',
      'english': 'For indeed, with hardship [will be] ease.',
    },
    {
      'surah': 'سورة الرعد',
      'arabic':
          'أَلَا بِذِكْرِ اللَّهِ '
          'تَطْمَئِنِّ الْقُلُوبُ',
      'english':
          'Unquestionably, by the remembrance of Allah hearts are assured.',
    },
    {
      'surah': 'سورة طه',
      'arabic':
          'قَالَ لَا تَخَافَا ۖ '
          'إِنَّنِي مَعَكُمَا '
          'أَسْمَعُ وَأَرَىٰ',
      'english':
          'He said, "Fear not. Indeed, I am with you both; I hear and I see."',
    },
  ];

  late Map<String, String> _selectedVerse;

  @override
  void initState() {
    super.initState();
    _selectedVerse = _dailyVerses[Random().nextInt(_dailyVerses.length)];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10nOf(context).dailyVerseSectionWidgetMessage1,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _selectedVerse['surah']!,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(20),
            border: const Border(
              right: BorderSide(color: AppColors.accent, width: 6),
            ),
          ),
          child: Consumer<FavoritesProvider>(
            builder: (context, favoritesProvider, child) {
              final isFav = favoritesProvider.isFavorite(_selectedVerse);
              return Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: Icon(
                        isFav ? Icons.favorite : Icons.favorite_outline,
                        color: isFav ? Colors.red : Colors.white70,
                      ),
                      onPressed: () {
                        favoritesProvider.toggleFavorite(_selectedVerse);
                      },
                    ),
                  ),
                  Text(
                    _selectedVerse['arabic']!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 26,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _selectedVerse['english']!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.roboto(color: Colors.white70),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }
}
