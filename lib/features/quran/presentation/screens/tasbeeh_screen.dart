import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

class TasbeehScreen extends StatefulWidget {
  const TasbeehScreen({super.key});

  @override
  State<TasbeehScreen> createState() => _TasbeehScreenState();
}

class _TasbeehScreenState extends State<TasbeehScreen> {
  int count = 0; // Start from 0 instead of 5
  int totalCounter = 0; // Track total counts across all phrases
  int selectedIndex = 0; // Index of currently selected phrase
  List<Map<String, dynamic>> tasbeehPhrases = [
    {'text': 'سبحان الله', 'count': 0, 'target': 33},
    {'text': 'الحمدلله', 'count': 0, 'target': 33},
    {'text': 'لا اله الا الله', 'count': 0, 'target': 33},
    {'text': 'الله أكبر', 'count': 0, 'target': 33},
  ];

  @override
  Widget build(BuildContext context) {
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
          'التسبيح الإلكتروني',
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
                              'الأدعية',
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
                              itemCount: tasbeehPhrases.length,
                              itemBuilder: (context, index) {
                                final phrase = tasbeehPhrases[index];
                                bool isCompleted =
                                    phrase['count'] >= phrase['target'];

                                return _tasbeehRow(
                                  itemKey: phrase,
                                  index: index,
                                  title: phrase['text'],
                                  counter: phrase['count'].toString(),
                                  isCompleted: isCompleted,
                                  isSelected: index == selectedIndex,
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
                        tasbeehPhrases.isNotEmpty &&
                                selectedIndex < tasbeehPhrases.length
                            ? tasbeehPhrases[selectedIndex]['text']
                            : '',
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
                      count.toString().padLeft(2, '0'),
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
                  label: const Text('تسبيحة'),
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
                      label: const Text(
                        'إضافة جديد',
                        style: TextStyle(
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
                      label: const Text(
                        'إعادة تعيين',
                        style: TextStyle(
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

  void _incrementCounter() {
    setState(() {
      count++;
      totalCounter++;

      // Update the selected phrase count
      if (tasbeehPhrases.isNotEmpty && selectedIndex < tasbeehPhrases.length) {
        tasbeehPhrases[selectedIndex]['count'] = count;
      }
    });
  }

  void _resetCounters() {
    setState(() {
      count = 0;
      totalCounter = 0;
      for (var phrase in tasbeehPhrases) {
        phrase['count'] = 0;
      }
    });
  }

  void _showAddTasbeehDialog() {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog.adaptive(
          title: Text(
            'إضافة تسبيحة جديدة',
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
              hintText: 'أدخل نص التسبيحة',
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
              child: const Text(
                'إلغاء',
                style: TextStyle(fontFamily: 'Cairo', color: Colors.red),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  setState(() {
                    tasbeehPhrases.add({
                      'text': controller.text.trim(),
                      'count': 0,
                      'target': 33, // Default target
                    });
                  });
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
              child: const Text(
                'إضافة',
                style: TextStyle(fontFamily: 'Cairo', color: Colors.white),
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
        // Step 1: Capture the item and its index before removing it
        final deletedItem = tasbeehPhrases[index];
        final deletedIndex = index;
        final wasSelected = selectedIndex == index;

        setState(() {
          tasbeehPhrases.removeAt(index);

          // Adjust selectedIndex if needed
          if (selectedIndex == index) {
            // If we deleted the selected item,
            // select the first item or set to 0.
            selectedIndex = selectedIndex > 0 ? selectedIndex - 1 : 0;
            if (tasbeehPhrases.isNotEmpty &&
                selectedIndex < tasbeehPhrases.length) {
              count = tasbeehPhrases[selectedIndex]['count'];
            } else {
              count = 0;
            }
          } else if (selectedIndex > index) {
            // If we deleted an item before the selected one, adjust the index
            selectedIndex--;
          }
        });

        // Step 2: Show SnackBar with Undo action
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم حذف "$title"',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            action: SnackBarAction(
              label: 'تراجع',
              textColor: AppColors.accent,
              onPressed: () {
                setState(() {
                  // Step 3: Restore the item
                  tasbeehPhrases.insert(deletedIndex, deletedItem);

                  // Restore selection if it was selected
                  // or if we need to adjust index.
                  if (wasSelected) {
                    selectedIndex = deletedIndex;
                    count = deletedItem['count'];
                  } else if (selectedIndex >= deletedIndex) {
                    selectedIndex++;
                  }
                });
              },
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
        onTap: () {
          setState(() {
            selectedIndex = index;
            count = tasbeehPhrases[index]['count'];
          });
        },
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
