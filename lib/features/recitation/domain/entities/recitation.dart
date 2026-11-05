/// How a reciter recites.
enum RecitationStyle {
  murattal,
  mujawwad,

  /// Slow teaching recitation, good for children and memorization.
  muallim,
  unspecified;

  static RecitationStyle parse(Object? value) => switch (value) {
    'Murattal' => murattal,
    'Mujawwad' => mujawwad,
    'Muallim' => muallim,
    _ => unspecified,
  };
}

/// A reciter whose full-surah audio has per-ayah timings.
class RecitationReciter {
  const RecitationReciter({
    required this.id,
    required this.name,
    required this.style,
  });

  final int id;
  final String name;
  final RecitationStyle style;

  @override
  bool operator ==(Object other) =>
      other is RecitationReciter && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Where one ayah sits within a surah's audio file.
class AyahTiming {
  const AyahTiming({required this.ayah, required this.from, required this.to});

  final int ayah;
  final Duration from;
  final Duration to;

  bool contains(Duration position) => position >= from && position < to;
}

/// One surah recited by one reciter, with per-ayah timings.
class ChapterRecitation {
  ChapterRecitation({
    required this.reciterId,
    required this.surah,
    required this.audioUrl,
    required List<AyahTiming> timings,
  }) : timings = List<AyahTiming>.unmodifiable(timings);

  final int reciterId;
  final int surah;
  final String audioUrl;
  final List<AyahTiming> timings;

  /// The ayah playing at [position], or null before the first ayah.
  int? ayahAt(Duration position) {
    for (final t in timings) {
      if (t.contains(position)) return t.ayah;
    }
    if (timings.isNotEmpty && position >= timings.last.to) {
      return timings.last.ayah;
    }
    return null;
  }

  AyahTiming? timingOf(int ayah) {
    for (final t in timings) {
      if (t.ayah == ayah) return t;
    }
    return null;
  }
}

/// A surah saved on the device for offline listening.
class DownloadedSurah {
  const DownloadedSurah({
    required this.reciterId,
    required this.surah,
    required this.bytes,
  });

  final int reciterId;
  final int surah;
  final int bytes;
}

/// Progress of a running download; [total] is null when unknown.
class DownloadProgress {
  const DownloadProgress({required this.received, this.total});

  final int received;
  final int? total;

  double? get fraction =>
      total == null || total == 0 ? null : (received / total!).clamp(0, 1);
}
