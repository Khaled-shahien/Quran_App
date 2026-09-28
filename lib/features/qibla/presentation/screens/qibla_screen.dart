import 'package:sakina_app/l10n/localization.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/qibla_direction.dart';
import '../qibla_controller.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key, this.controller});
  final QiblaController? controller;

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> with WidgetsBindingObserver {
  late final QiblaController controller;

  @override
  void initState() {
    super.initState();
    controller = widget.controller ?? QiblaController();
    WidgetsBinding.instance.addObserver(this);
    unawaited(controller.start());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) controller.pause();
    if (state == AppLifecycleState.resumed) {
      unawaited(controller.start(requestPermission: false));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (widget.controller == null) {
      controller.dispose();
    } else {
      controller.pause();
    }
    super.dispose();
  }

  Future<void> _openSettings() async {
    final opened = await controller.openSettings();
    if (!opened && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(appL10n.qiblaScreenMessage1)));
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: AnimatedBuilder(
      animation: controller,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: Text(l10nOf(context).homeScreenMessage37),
          actions: [
            IconButton(
              tooltip: l10nOf(context).qiblaScreenMessage2,
              onPressed: controller.status == QiblaStatus.loading
                  ? null
                  : () => controller.start(),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: controller.status == QiblaStatus.ready
                    ? _compass(context)
                    : _status(context),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _status(BuildContext context) {
    final (icon, title, message) = switch (controller.status) {
      QiblaStatus.loading => (
        Icons.my_location,
        l10nOf(context).qiblaScreenMessage3,
        l10nOf(context).qiblaScreenMessage4,
      ),
      QiblaStatus.locationOff => (
        Icons.location_off_outlined,
        l10nOf(context).qiblaScreenMessage5,
        l10nOf(context).qiblaScreenMessage6,
      ),
      QiblaStatus.denied => (
        Icons.location_disabled,
        l10nOf(context).qiblaScreenMessage7,
        l10nOf(context).qiblaScreenMessage8,
      ),
      QiblaStatus.deniedForever => (
        Icons.settings_outlined,
        l10nOf(context).qiblaScreenMessage9,
        l10nOf(context).qiblaScreenMessage10,
      ),
      QiblaStatus.unsupported => (
        Icons.explore_off_outlined,
        l10nOf(context).qiblaScreenMessage11,
        l10nOf(context).qiblaScreenMessage12,
      ),
      _ => (
        Icons.location_searching,
        l10nOf(context).qiblaScreenMessage13,
        l10nOf(context).qiblaScreenMessage14,
      ),
    };
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: [
          Icon(icon, size: 64, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          if (controller.status == QiblaStatus.loading)
            const CircularProgressIndicator()
          else if (controller.status != QiblaStatus.unsupported) ...[
            if (controller.status == QiblaStatus.locationOff ||
                controller.status == QiblaStatus.deniedForever)
              FilledButton.icon(
                onPressed: _openSettings,
                icon: const Icon(Icons.settings_outlined),
                label: Text(l10nOf(context).qiblaScreenMessage15),
              ),
            TextButton(
              onPressed: () => controller.start(),
              child: Text(
                controller.status == QiblaStatus.denied
                    ? l10nOf(context).qiblaScreenMessage16
                    : l10nOf(context).retry,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _compass(BuildContext context) {
    final theme = Theme.of(context);
    final heading = controller.heading;
    final turn = controller.turn;
    final needsCalibration = heading?.needsCalibration ?? false;
    if (controller.nearKaaba) {
      return Padding(
        padding: const EdgeInsets.only(top: 48),
        child: Text(
          l10nOf(context).qiblaScreenMessage17,
          textAlign: TextAlign.center,
        ),
      );
    }
    final String guidance;
    if (controller.sensorUnavailable) {
      guidance = l10nOf(context).qiblaScreenMessage18;
    } else if (heading == null) {
      guidance = l10nOf(context).qiblaScreenMessage19;
    } else if (needsCalibration) {
      guidance = l10nOf(context).qiblaScreenMessage20;
    } else if (controller.aligned) {
      guidance = l10nOf(context).qiblaScreenMessage21;
    } else {
      guidance = l10nOf(context).qiblaScreenMessage24(
        (turn! > 0
                ? l10nOf(context).qiblaScreenMessage23
                : l10nOf(context).qiblaScreenMessage22)
            .toString(),
        (turn.abs().round()).toString(),
      );
    }
    return Column(
      children: [
        Text(
          l10nOf(context).qiblaScreenMessage25,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          l10nOf(context).qiblaScreenMessage26,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 28),
        if (heading != null && !controller.sensorUnavailable)
          QiblaDial(
            bearing: controller.bearing!,
            heading: heading.degrees,
            aligned: controller.aligned,
          )
        else
          SizedBox(
            height: 240,
            child: Center(
              child: controller.sensorUnavailable
                  ? Icon(
                      Icons.explore_off_outlined,
                      size: 80,
                      color: theme.colorScheme.primary,
                    )
                  : const CircularProgressIndicator(),
            ),
          ),
        const SizedBox(height: 24),
        Semantics(
          liveRegion: true,
          child: Text(
            guidance,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              color: controller.aligned
                  ? const Color(0xFF28734F)
                  : theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10nOf(context).qiblaScreenMessage27(
            (controller.bearing!.toStringAsFixed(1)).toString(),
          ),
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: .07),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            controller.sensorUnavailable
                ? l10nOf(context).qiblaScreenMessage28
                : l10nOf(context).qiblaScreenMessage29,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class QiblaDial extends StatelessWidget {
  const QiblaDial({
    super.key,
    required this.bearing,
    required this.heading,
    required this.aligned,
  });
  final double bearing;
  final double heading;
  final bool aligned;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = aligned ? const Color(0xFF28734F) : colors.primary;
    return Semantics(
      label: l10nOf(context).qiblaScreenMessage30,
      child: AspectRatio(
        aspectRatio: 1,
        child: CustomPaint(
          painter: _CompassPainter(
            heading: heading,
            bearing: bearing,
            color: accent,
            textColor: colors.onSurface,
          ),
          child: Center(
            child: Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.surface,
                border: Border.all(color: accent.withValues(alpha: .25)),
              ),
              padding: const EdgeInsets.all(14),
              child: Image.asset(
                'assets/images/kaaba.png',
                errorBuilder: (_, _, _) => Icon(Icons.mosque, color: accent),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  _CompassPainter({
    required this.heading,
    required this.bearing,
    required this.color,
    required this.textColor,
  });
  final double heading;
  final double bearing;
  final Color color;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 12;
    final paint = Paint()
      ..color = color.withValues(alpha: .22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(center, radius * .68, paint);
    for (var degree = 0; degree < 360; degree += 5) {
      final angle = (degree - heading - 90) * math.pi / 180;
      final direction = Offset(math.cos(angle), math.sin(angle));
      final major = degree % 30 == 0;
      paint
        ..color = color.withValues(alpha: major ? .8 : .25)
        ..strokeWidth = major ? 2 : 1;
      canvas.drawLine(
        center + direction * (radius - (major ? 14 : 7)),
        center + direction * radius,
        paint,
      );
    }
    for (final entry in {
      0: appL10n.qiblaScreenMessage31,
      90: appL10n.qiblaScreenMessage32,
      180: appL10n.qiblaScreenMessage33,
      270: appL10n.qiblaScreenMessage34,
    }.entries) {
      final angle = (entry.key - heading - 90) * math.pi / 180;
      final label = TextPainter(
        text: TextSpan(
          text: entry.value,
          style: TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.rtl,
      )..layout();
      final point =
          center + Offset(math.cos(angle), math.sin(angle)) * (radius - 32);
      label.paint(canvas, point - Offset(label.width / 2, label.height / 2));
    }
    // Arrow always points toward the bearing relative to the top of the screen.
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(qiblaTurn(bearing, heading) * math.pi / 180);
    paint
      ..color = color
      ..style = PaintingStyle.fill;
    final arrow = Path()
      ..moveTo(0, -radius * .68)
      ..lineTo(-18, -radius * .40)
      ..lineTo(-5, -radius * .45)
      ..lineTo(-5, -28)
      ..lineTo(5, -28)
      ..lineTo(5, -radius * .45)
      ..lineTo(18, -radius * .40)
      ..close();
    canvas.drawPath(arrow, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CompassPainter oldDelegate) =>
      oldDelegate.heading != heading ||
      oldDelegate.bearing != bearing ||
      oldDelegate.color != color ||
      oldDelegate.textColor != textColor;
}
