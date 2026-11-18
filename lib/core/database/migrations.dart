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
  // 1 → 2: the prayer and fasting log. Kept for installs that ran it; the
  // log now lives in PrivateDatabase and these tables stay empty.
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
  // 2 → 3: memorised pages and their review schedule (hifz).
  <String>[
    '''
    CREATE TABLE hifz_pages (
      page INTEGER NOT NULL PRIMARY KEY CHECK (page BETWEEN 1 AND 604),
      step INTEGER NOT NULL DEFAULT 0 CHECK (step BETWEEN 0 AND 4),
      due_day TEXT NOT NULL CHECK (length(due_day) = 10),
      reviews INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
    ''',
    'CREATE INDEX hifz_pages_by_due ON hifz_pages (due_day)',
  ],
];

/// Schema history of [PrivateDatabase] (same rules as [databaseMigrations]).
const List<List<String>> privateDatabaseMigrations = <List<String>>[
  // 0 → 1: the private prayer and fasting log.
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
