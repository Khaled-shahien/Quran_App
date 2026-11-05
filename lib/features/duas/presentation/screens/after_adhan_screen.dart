import 'package:flutter/material.dart';
import 'package:sakina_app/core/result/result.dart';
import 'package:sakina_app/core/result/failure_messages.dart';
import 'package:sakina_app/l10n/localization.dart';

import '../../data/models/azkar_model.dart';
import '../../domain/repositories/adhan_adhkar_repository.dart';
import '../widgets/dhikr_text_block.dart';

/// Opened from a prayer notification: the adhkar for the adhan, including
/// the dua after it.
class AfterAdhanScreen extends StatefulWidget {
  const AfterAdhanScreen({
    super.key,
    required this.repository,
    this.prayerName,
  });

  final AdhanAdhkarRepository repository;
  final String? prayerName;

  @override
  State<AfterAdhanScreen> createState() => _AfterAdhanScreenState();
}

class _AfterAdhanScreenState extends State<AfterAdhanScreen> {
  late final Future<Result<List<AzkarItemModel>>> _items = widget.repository
      .getAdhanAdhkar();

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.afterAdhanTitle)),
      body: FutureBuilder<Result<List<AzkarItemModel>>>(
        future: _items,
        builder: (context, snapshot) {
          final result = snapshot.data;
          if (result == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return switch (result) {
            Err(:final failure) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  failureMessage(failure),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Success(:final value) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (widget.prayerName case final name?)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      l10n.prayerTimeArrived(name),
                      style: theme.textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                for (final item in value)
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DhikrTextBlock(item: item),
                          const SizedBox(height: 8),
                          Text(
                            item.reference,
                            style: theme.textTheme.bodySmall,
                            textAlign: TextAlign.start,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          };
        },
      ),
    );
  }
}
