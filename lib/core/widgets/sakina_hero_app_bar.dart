import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sakina_app/l10n/localization.dart';

import '../theme/app_design.dart';
import 'geometric_pattern.dart';

/// The app's large screen header: the design's gradient and ornament with
/// the screen title, which shrinks into a slim bar as the content scrolls.
///
/// Place it first in a [CustomScrollView]'s slivers.
class SakinaHeroAppBar extends StatelessWidget {
  const SakinaHeroAppBar({
    super.key,
    required this.title,
    this.actions,
    this.backTooltip,
    this.expandedHeight = 150,
    this.bottom,
  });

  final String title;

  /// A bar pinned under the title, such as section tabs.
  final PreferredSizeWidget? bottom;
  final List<Widget>? actions;

  /// The back button's tooltip; the app's usual "back" wording when null.
  final String? backTooltip;

  /// Height of the open header, before the content scrolls.
  final double expandedHeight;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SakinaDecor decor = SakinaDecor.of(context);
    final l10n = l10nOf(context);
    // Grows with large text so the title never clips.
    final double textScale = MediaQuery.textScalerOf(context).scale(1);
    return SliverAppBar(
      expandedHeight:
          expandedHeight +
          40 * (textScale - 1).clamp(0, 2) +
          (bottom?.preferredSize.height ?? 0),
      bottom: bottom,
      pinned: true,
      stretch: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: decor.heroColors.last,
      foregroundColor: decor.onFeature,
      // Light status icons: this header is dark in every design.
      systemOverlayStyle: SystemUiOverlayStyle.light,
      iconTheme: IconThemeData(color: decor.onFeature),
      actionsIconTheme: IconThemeData(color: decor.onFeature),
      // Always shown, as on the screens before this header: a screen opened
      // first (from a notification) still offers a way back.
      leading: Semantics(
        button: true,
        label: l10n.azkarDetailsScreenMessage1,
        child: IconButton(
          tooltip: backTooltip ?? l10n.azkarDetailsScreenMessage2,
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: actions,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.fadeTitle],
        centerTitle: true,
        // The title sits above the tabs, never on them.
        titlePadding: EdgeInsetsDirectional.only(
          start: 72,
          end: 72,
          bottom: 16 + (bottom?.preferredSize.height ?? 0),
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            color: decor.onFeature,
            fontWeight: FontWeight.w800,
          ),
        ),
        background: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
              colors: decor.heroColors,
            ),
          ),
          child: GeometricPattern(
            pattern: decor.pattern,
            color: decor.onFeature.withValues(alpha: 0.08),
          ),
        ),
      ),
    );
  }
}

/// A screen with the collapsing hero header and its content in one scroll:
/// the header shrinks to a slim bar as the content moves up.
///
/// [slivers] are the content. Wrap box content in a [SliverToBoxAdapter],
/// use a sliver list for lists, and [SliverFillRemaining] for a message or
/// a loader that should fill the space under the header.
class SakinaHeroScaffold extends StatelessWidget {
  const SakinaHeroScaffold({
    super.key,
    required this.title,
    required this.slivers,
    this.actions,
    this.backTooltip,
    this.backgroundColor,
    this.floatingActionButton,
    this.controller,
    this.onRefresh,
  });

  final String title;
  final List<Widget> slivers;
  final List<Widget>? actions;
  final String? backTooltip;
  final Color? backgroundColor;
  final Widget? floatingActionButton;
  final ScrollController? controller;

  /// When set, pulling down at the top refreshes the content.
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    Widget scroll = CustomScrollView(
      controller: controller,
      // Pull to refresh needs the page to move even when it is short.
      physics: onRefresh == null ? null : const AlwaysScrollableScrollPhysics(),
      slivers: <Widget>[
        SakinaHeroAppBar(
          title: title,
          actions: actions,
          backTooltip: backTooltip,
        ),
        // The header already sits under the status bar; content below it
        // must not pad for it again (inner lists would add a top gap).
        MediaQuery.removePadding(
          context: context,
          removeTop: true,
          child: SliverMainAxisGroup(slivers: slivers),
        ),
        // Clear of the system navigation bar at the end.
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.paddingOf(context).bottom),
        ),
      ],
    );
    if (onRefresh case final refresh?) {
      scroll = RefreshIndicator(
        onRefresh: refresh,
        // Below the open header, not over the status bar.
        edgeOffset: 150 + MediaQuery.paddingOf(context).top,
        child: scroll,
      );
    }
    return Scaffold(
      backgroundColor: backgroundColor,
      floatingActionButton: floatingActionButton,
      body: scroll,
    );
  }
}
