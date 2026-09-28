import 'package:sakina_app/l10n/localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MediaTilesWidget extends StatelessWidget {
  const MediaTilesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildListDelegate([
        _mediaTile(
          l10nOf(context).articlesScreenMessage1,
          const Color(0xFF235347),
          Icons.article_outlined,
          () => context.push('/media/articles'),
        ),
        _mediaTile(
          l10nOf(context).audioScreenMessage1,
          const Color(0xFF2D2D2D),
          Icons.graphic_eq_rounded,
          () => context.push('/media/audio'),
        ),
        _mediaTile(
          l10nOf(context).videoScreenMessage1,
          const Color(0xFF8B4242),
          Icons.video_library_outlined,
          () => context.push('/media/videos'),
        ),
      ]),
    );
  }

  Widget _mediaTile(
    String title,
    Color color,
    IconData icon,
    VoidCallback onTap,
  ) => Semantics(
    button: true,
    label: title,
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
