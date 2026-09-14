import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sakina_app/core/theme/app_radius.dart';
import 'package:sakina_app/core/theme/app_spacing.dart';
import 'package:sakina_app/features/media/domain/entities/reciter.dart';
import 'package:sakina_app/features/media/domain/entities/surah_audio.dart';
import 'package:url_launcher/url_launcher.dart';

class AudioPlayerSheet extends StatelessWidget {
  const AudioPlayerSheet({
    super.key,
    required this.reciter,
    required this.surahs,
  });

  final Reciter reciter;
  final List<SurahAudio> surahs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final height = MediaQuery.sizeOf(context).height * 0.78;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: SizedBox(
          height: height,
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.35,
                  ),
                  borderRadius: AppRadius.pill,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    Text(
                      reciter.name,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      reciter.moshafName,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: surahs.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.xs),
                  itemBuilder: (context, index) {
                    final surah = surahs[index];
                    return _SurahAudioTile(surah: surah);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SurahAudioTile extends StatelessWidget {
  const _SurahAudioTile({required this.surah});

  final SurahAudio surah;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary,
          child: Text(
            surah.surahNumber.toString(),
            style: GoogleFonts.cairo(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          'سورة ${surah.surahName}',
          textDirection: TextDirection.rtl,
          style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          'فتح التلاوة في مشغل الصوت',
          textDirection: TextDirection.rtl,
          style: GoogleFonts.cairo(fontSize: 12),
        ),
        trailing: IconButton.filledTonal(
          tooltip: 'تشغيل',
          onPressed: () => _openAudio(context),
          icon: const Icon(Icons.play_arrow_rounded),
        ),
        onTap: () => _openAudio(context),
      ),
    );
  }

  Future<void> _openAudio(BuildContext context) async {
    final opened = await launchUrl(
      Uri.parse(surah.audioUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تعذر فتح ملف الصوت',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(),
          ),
        ),
      );
    }
  }
}
