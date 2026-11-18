/// Database schema history. Entry `i` upgrades schema `i` to `i + 1`.
///
/// Rules:
/// - Never edit or reorder an entry that has shipped; add a new one.
/// - Never drop a table or column that holds user data.
/// - Each entry runs in one transaction, so a failed upgrade leaves the
///   previous schema intact and is retried on the next launch.
const List<List<String>> databaseMigrations = <List<String>>[
  // 0 → 1: saved verses (coloured bookmarks) and private verse notes.
  <String>[
    '''
    CREATE TABLE saved_verses (
      surah INTEGER NOT NULL CHECK (surah BETWEEN 1 AND 114),
      ayah INTEGER NOT NULL CHECK (ayah BETWEEN 1 AND 286),
      color INTEGER NOT NULL DEFAULT 0,
      label TEXT,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      PRIMARY KEY (surah, ayah)
    )
    ''',
    '''
    CREATE TABLE verse_notes (
      surah INTEGER NOT NULL CHECK (surah BETWEEN 1 AND 114),
      ayah INTEGER NOT NULL CHECK (ayah BETWEEN 1 AND 286),
      body TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      PRIMARY KEY (surah, ayah)
    )
    ''',
    'CREATE INDEX saved_verses_by_time ON saved_verses (updated_at)',
    'CREATE INDEX verse_notes_by_time ON verse_notes (updated_at)',
  ],
  // 1 → 2: the private prayer and fasting log.
  <String>[
    '''
    CREATE TABLE prayer_log (
      day TEXT NOT NULL CHECK (length(day) = 10),
      prayer TEXT NOT NULL
        CHECK (prayer IN ('fajr', 'dhuhr', 'asr', 'maghrib', 'isha')),
      status TEXT NOT NULL
        CHECK (status IN ('onTime', 'late', 'missed', 'excused')),
      updated_at INTEGER NOT NULL,
      PRIMARY KEY (day, prayer)
    )
    ''',
    '''
    CREATE TABLE fasting_log (
      day TEXT NOT NULL PRIMARY KEY CHECK (length(day) = 10),
      status TEXT NOT NULL
        CHECK (status IN ('fasted', 'qada', 'excused', 'missed')),
      updated_at INTEGER NOT NULL
    )
    ''',
  ],
];
