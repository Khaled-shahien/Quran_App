import 'package:sakina_app/l10n/localization.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class DataSourcesScreen extends StatelessWidget {
  const DataSourcesScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(l10nOf(context).homeScreenMessage25)),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: SelectionArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10nOf(context).dataSourcesScreenMessage1,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(l10nOf(context).dataSourcesScreenMessage2),
              const SizedBox(height: 24),
              Text(
                l10nOf(context).dataSourcesScreenMessage3,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(l10nOf(context).dataSourcesScreenMessage4),
              const SizedBox(height: 24),
              Text(
                l10nOf(context).dataSourcesScreenMessage5,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(l10nOf(context).dataSourcesScreenMessage6),
              const SizedBox(height: 24),
              Text(l10nOf(context).dataSourcesScreenMessage7),
              const SizedBox(height: 24),
              Text(l10nOf(context).dataSourcesScreenMessage8),
              const SizedBox(height: 24),
              const ContentProvenanceView(),
            ],
          ),
        ),
      ),
    ),
  );
}

class ContentProvenanceView extends StatefulWidget {
  const ContentProvenanceView({super.key});
  @override
  State<ContentProvenanceView> createState() => _ContentProvenanceViewState();
}

class _ContentProvenanceViewState extends State<ContentProvenanceView> {
  late final Future<String> manifest = rootBundle.loadString(
    'content_manifest.json',
  );
  @override
  Widget build(BuildContext context) => FutureBuilder<String>(
    future: manifest,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Text(l10nOf(context).dataSourcesScreenMessage9);
      }
      if (!snapshot.hasData) return const LinearProgressIndicator();
      final collections =
          (jsonDecode(snapshot.data!) as Map<String, dynamic>)['collections']
              as List;
      return ExpansionTile(
        title: Text(l10nOf(context).dataSourcesScreenMessage10),
        children: [
          for (final collection in collections)
            ListTile(
              title: Text(
                collection['path'] as String,
                textDirection: TextDirection.ltr,
              ),
              subtitle: Text(
                collection['source'] == 'pending_owner_review'
                    ? l10nOf(context).dataSourcesScreenMessage11
                    : collection['source'] as String,
              ),
            ),
        ],
      );
    },
  );
}
