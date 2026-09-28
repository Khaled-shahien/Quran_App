import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import '../../../../core/widgets/pulse_loader.dart';
import '../providers/azkar_provider.dart';

class AzkarDetailsScreen extends StatelessWidget {
  final String categoryName;

  const AzkarDetailsScreen({super.key, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          categoryName,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Semantics(
          button: true,
          label: 'الرجوع للشاشة السابقة',
          child: IconButton(
            tooltip: 'رجوع',
            icon: Icon(
              Icons.arrow_back_ios,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Consumer<AzkarProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const Center(child: PulseLoader(lines: 6));
              }

              if (provider.errorMessage != null) {
                return const Center(
                  child: Text(
                    'حدث خطأ في تحميل الأذكار',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.red,
                      fontSize: 18,
                    ),
                  ),
                );
              }

              final category = provider.getCategoryByName(categoryName);

              if (category == null || category.items.isEmpty) {
                return Center(
                  child: Text(
                    'لا توجد بيانات لهذا القسم حالياً',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: category.items.length,
                itemBuilder: (context, index) {
                  final item = category.items[index];
                  return _AzkarItemCard(item: item);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AzkarItemCard extends StatelessWidget {
  final dynamic item;

  const _AzkarItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'ذكر ${item.title}',
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title and Repeat count
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  if (item.repeat > 1) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'التكرار: ${item.repeat}',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // Azkar Text
              Text(
                item.text,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 22,
                  height: 2.0,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),

              // Reference if available
              if (item.reference != null && item.reference.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(thickness: 0.5),
                const SizedBox(height: 8),
                Text(
                  item.reference,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.left,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
