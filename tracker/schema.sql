-- Freelance tracker schema (SQLite). Source of truth: docs/product.md
--
-- Shape of the data:  clients -> projects -> { time_entries, features, documents }
-- Every table hangs off a project except clients, which sit above it.
--
-- Conventions used throughout (and why):
--   * id INTEGER PRIMARY KEY  -> in SQLite this is an alias for the built-in rowid,
--     so ids are auto-assigned, fast, and need no AUTOINCREMENT keyword.
--   * Dates are TEXT in ISO-8601 ('2026-11-11T14:30:00'). SQLite has no date type;
--     ISO strings sort correctly as text and work with date()/strftime().
--   * Money is INTEGER cents (hourly_rate_cents = 8500 means $85.00). Floats can't
--     represent 0.10 exactly, and rounding errors in invoices are embarrassing.
--   * "Enums" are TEXT + CHECK (...). SQLite has no enum type; CHECK makes the DB
--     reject typos like 'in-progress' instead of silently storing them.
--   * Foreign keys are only enforced if each connection runs:
--         PRAGMA foreign_keys = ON;
--     It is OFF by default (backwards compatibility). The Python code must set it.

PRAGMA foreign_keys = ON;

CREATE TABLE clients (
    id                INTEGER PRIMARY KEY,
    name              TEXT    NOT NULL UNIQUE,      -- UNIQUE so "log time for RVSelfPark" is unambiguous
    email             TEXT,
    hourly_rate_cents INTEGER CHECK (hourly_rate_cents >= 0),
    created_at        TEXT    NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE projects (
    id                INTEGER PRIMARY KEY,
    -- ON DELETE RESTRICT: you can't delete a client that still has projects.
    -- Logged hours are business records; losing them by accident would be bad.
    client_id         INTEGER NOT NULL REFERENCES clients(id) ON DELETE RESTRICT,
    name              TEXT    NOT NULL,
    status            TEXT    NOT NULL DEFAULT 'active'
                      CHECK (status IN ('active', 'paused', 'done')),
    hourly_rate_cents INTEGER CHECK (hourly_rate_cents >= 0),  -- NULL = use the client's rate
    budget_hours      REAL    CHECK (budget_hours > 0),        -- NULL = no budget
    created_at        TEXT    NOT NULL DEFAULT (datetime('now')),
    UNIQUE (client_id, name)   -- same project name is fine across clients, not within one
);

CREATE TABLE features (
    id             INTEGER PRIMARY KEY,
    project_id     INTEGER NOT NULL REFERENCES projects(id) ON DELETE RESTRICT,
    title          TEXT    NOT NULL,
    description    TEXT,
    stage          TEXT    NOT NULL DEFAULT 'idea'
                   CHECK (stage IN ('idea', 'ready', 'in_progress', 'review', 'staging', 'deployed')),
    priority       TEXT    NOT NULL DEFAULT 'med'
                   CHECK (priority IN ('low', 'med', 'high')),
    estimate_hours REAL    CHECK (estimate_hours > 0),
    pr_url         TEXT,
    deployed_at    TEXT,
    created_at     TEXT    NOT NULL DEFAULT (datetime('now')),
    -- Looks redundant (id is already unique), but it lets time_entries point at
    -- the PAIR (feature id, project id). See the composite foreign key below.
    UNIQUE (id, project_id)
);

CREATE TABLE time_entries (
    id          INTEGER PRIMARY KEY,
    project_id  INTEGER NOT NULL REFERENCES projects(id) ON DELETE RESTRICT,
    feature_id  INTEGER,                           -- optional link to a feature
    started_at  TEXT    NOT NULL,
    minutes     INTEGER NOT NULL CHECK (minutes > 0),  -- whole minutes; no float drift when summing
    note        TEXT,
    billable    INTEGER NOT NULL DEFAULT 1 CHECK (billable IN (0, 1)),  -- SQLite has no BOOLEAN
    -- Composite foreign key: if feature_id is set, (feature_id, project_id) must
    -- match a real feature IN THE SAME PROJECT. A plain feature_id FK would happily
    -- let you log project A's time against project B's feature.
    -- When feature_id is NULL, SQLite skips the check, which is what makes it optional.
    -- No ON DELETE action = you can't delete a feature that has time logged on it.
    FOREIGN KEY (feature_id, project_id) REFERENCES features(id, project_id)
);

CREATE TABLE documents (
    id         INTEGER PRIMARY KEY,
    project_id INTEGER NOT NULL REFERENCES projects(id) ON DELETE RESTRICT,
    title      TEXT    NOT NULL,
    doc_type   TEXT    NOT NULL DEFAULT 'other'
               CHECK (doc_type IN ('contract', 'sow', 'spec', 'invoice', 'other')),
    url        TEXT    NOT NULL,                   -- link out, don't store files
    due_date   TEXT,                               -- 'YYYY-MM-DD' or NULL
    created_at TEXT    NOT NULL DEFAULT (datetime('now'))
);

-- Indexes: SQLite does NOT auto-index foreign key columns. These cover the
-- lookups every page makes ("all X for project N", "time in date range").
CREATE INDEX idx_projects_client      ON projects(client_id);
CREATE INDEX idx_features_project     ON features(project_id, stage);
CREATE INDEX idx_time_project_started ON time_entries(project_id, started_at);
CREATE INDEX idx_time_feature         ON time_entries(feature_id);
CREATE INDEX idx_documents_project    ON documents(project_id);
