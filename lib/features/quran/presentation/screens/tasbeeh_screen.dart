import 'package:sakina_app/l10n/app_localizations.dart';
import 'package:sakina_app/l10n/localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/tasbih_phrase.dart';
import '../providers/tasbih_controller.dart';

/// Display text for a phrase: built-ins come from l10n, custom ones as typed.
String tasbihPhraseText(TasbihPhrase phrase, AppLocalizations l10n) {
  if (phrase.customText case final text?) return text;
  return switch (phrase.id) {
    'builtin_subhan_allah' => l10n.tasbeehScreenMessage1,
    'builtin_alhamdulillah' => l10n.tasbeehScreenMessage2,
    'builtin_la_ilaha_illallah' => l10n.tasbeehScreenMessage3,
    'builtin_allahu_akbar' => l10n.tasbeehScreenMessage4,
    _ => '',
  };
}

class TasbeehScreen extends StatefulWidget {
  const TasbeehScreen({super.key});

  @override
  State<TasbeehScreen> createState() => _TasbeehScreenState();
}

class _TasbeehScreenState extends State<TasbeehScreen> {
  TasbihController get _controller => context.read<TasbihController>();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TasbihController>();
    final l10n = l10nOf(context);
    final phrases = controller.phrases;
    final selected = controller.selected;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10nOf(context).tasbeehScreenMessage5,
          style: TextStyle(
            fontFamily: 'Cairo',
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.kPaddingLarge),
            child: Column(
              children: [
                // Tasbeeh phrases list
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      borderRadius: BorderRadius.circular(
                        AppConstants.kBorderRadiusLarge,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(
                        AppConstants.kPaddingMedium,
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            child: Text(
                              l10nOf(context).appStringsMessage30,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: AppConstants.kPaddingSmall),
                          Expanded(
                            child: ListView.builder(
                              itemCount: phrases.length,
                              itemBuilder: (context, index) {
                                final phrase = phrases[index];

                                return _tasbeehRow(
                                  itemKey: phrase.id,
                                  index: index,
                                  title: tasbihPhraseText(phrase, l10n),
                                  counter: phrase.count.toString(),
                                  isCompleted: phrase.isComplete,
                                  isSelected: index == controller.selectedIndex,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppConstants.kPaddingLarge),

                // Current tasbeeh display
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(
                            context,
                          ).colorScheme.primary.withAlpha((0.2 * 255).round()),
                          Theme.of(context).colorScheme.secondary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(
                        AppConstants.kBorderRadiusLarge,
                      ),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        selected == null
                            ? ''
                            : tasbihPhraseText(selected, l10n),
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 28,
                          color: Theme.of(context).colorScheme.primary,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppConstants.kPaddingMedium),

                // Counter display
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      controller.count.toString().padLeft(2, '0'),
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppConstants.kPaddingMedium),

                // Increment button
                FloatingActionButton.extended(
                  onPressed: _incrementCounter,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  label: Text(l10nOf(context).tasbeehScreenMessage6),
                  icon: const Icon(Icons.add),
                ),

                const SizedBox(height: AppConstants.kPaddingSmall),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Add new tasbeeh button
                    ElevatedButton.icon(
                      onPressed: _showAddTasbeehDialog,
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: Text(
                        l10nOf(context).tasbeehScreenMessage7,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.kPaddingMedium,
                          vertical: AppConstants.kPaddingSmall,
                        ),
                      ),
                    ),
                    // Reset button
                    OutlinedButton.icon(
                      onPressed: _resetCounters,
                      icon: const Icon(
                        Icons.refresh,
                        color: Colors.red,
                        size: 18,
                      ),
                      label: Text(
                        l10nOf(context).tasbeehScreenMessage8,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          color: Colors.red,
                          fontSize: 14,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red, width: 1.5),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.kPaddingMedium,
                          vertical: AppConstants.kPaddingSmall,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _incrementCounter() => _controller.increment();

  void _resetCounters() => _controller.reset();

  void _showAddTasbeehDialog() {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog.adaptive(
          title: Text(
            l10nOf(context).tasbeehScreenMessage9,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
              fontSize: 18,
            ),
          ),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: l10nOf(context).tasbeehScreenMessage10,
              hintStyle: const TextStyle(fontFamily: 'Cairo'),
              filled: true,
              fillColor: Theme.of(context).scaffoldBackgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  AppConstants.kBorderRadiusMedium,
                ),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  AppConstants.kBorderRadiusMedium,
                ),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'Cairo',
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                l10nOf(context).appStringsMessage9,
                style: const TextStyle(fontFamily: 'Cairo', color: Colors.red),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  _controller.add(controller.text);
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
              child: Text(
                l10nOf(context).tasbeehScreenMessage11,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _tasbeehRow({
    required Object itemKey,
    required int index,
    required String title,
    required String counter,
    required bool isCompleted,
    required bool isSelected,
  }) {
    return Dismissible(
      key: ObjectKey(itemKey),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        final removed = _controller.removeAt(index);
        if (removed == null) return;

        // Offer undo so a swipe never loses the phrase or its count.
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              appL10n.tasbeehScreenMessage12((title).toString()),
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            action: SnackBarAction(
              label: appL10n.currentWirdWidgetMessage13,
              textColor: AppColors.accent,
              onPressed: () => _controller.restore(removed),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(AppConstants.kBorderRadiusMedium),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 24),
      ),
      child: GestureDetector(
        onTap: () => _controller.select(index),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              AppConstants.kBorderRadiusMedium,
            ),
            color: isSelected
                ? AppColors.accent.withValues(alpha: 0.2)
                : Theme.of(context).scaffoldBackgroundColor,
            border: Border.all(
              color: isCompleted
                  ? Colors.green
                  : (isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    color: isCompleted
                        ? Colors.green
                        : Theme.of(context).colorScheme.primary,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(
                      AppConstants.kBorderRadiusSmall,
                    ),
                  ),
                  child: Text(
                    counter,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
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
