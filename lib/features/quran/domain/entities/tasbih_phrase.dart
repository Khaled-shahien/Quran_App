/// One tasbih phrase and its progress.
///
/// Built-in phrases are stored by [id] only and their text is resolved from
/// localization at display time, so a corrected spelling reaches existing
/// users. Phrases the user adds keep their own [customText].
class TasbihPhrase {
  const TasbihPhrase({
    required this.id,
    this.customText,
    this.count = 0,
    this.target = defaultTarget,
  });

  static const int defaultTarget = 33;

  final String id;
  final String? customText;
  final int count;
  final int target;

  bool get isBuiltIn => customText == null;
  bool get isComplete => target > 0 && count >= target;

  TasbihPhrase copyWith({int? count}) => TasbihPhrase(
    id: id,
    customText: customText,
    count: count ?? this.count,
    target: target,
  );

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    if (customText != null) 'text': customText,
    'count': count,
    'target': target,
  };

  /// Returns null for malformed entries so one bad record never drops the rest.
  static TasbihPhrase? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final text = json['text'];
    final count = json['count'];
    final target = json['target'];
    if (id is! String || id.isEmpty) return null;
    if (text != null && (text is! String || text.isEmpty)) return null;
    return TasbihPhrase(
      id: id,
      customText: text as String?,
      count: count is int && count >= 0 ? count : 0,
      target: target is int && target > 0 ? target : defaultTarget,
    );
  }
}

/// Everything the tasbih screen needs to restore after the app is killed.
class TasbihSnapshot {
  const TasbihSnapshot({required this.phrases, required this.selectedIndex});

  final List<TasbihPhrase> phrases;
  final int selectedIndex;
}
