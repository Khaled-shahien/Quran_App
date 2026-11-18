import '../../domain/entities/hadeath_entity.dart';

class HadeathModel extends HadeathEntity {
  const HadeathModel({
    required super.title,
    required super.content,
    super.study,
  });

  /// Factory method to create a HadeathModel from raw text
  factory HadeathModel.fromString(String rawHadeath) {
    // Split the raw string by new lines
    List<String> lines = rawHadeath.split('\n');

    // Remove empty lines and trim whitespace
    lines = lines
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    // The first line is the title of the Hadeath
    String title = lines.isNotEmpty ? lines[0] : '';

    // The rest of the lines are the content
    List<String> content = lines.length > 1 ? lines.sublist(1) : [];

    return HadeathModel(title: title, content: content);
  }
}
