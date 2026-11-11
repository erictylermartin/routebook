-- Example data + queries. Try it:
--   python3 -c "import sqlite3; c=sqlite3.connect(':memory:'); c.executescript(open('tracker/schema.sql').read()+open('tracker/examples.sql').read())"
-- or with the sqlite3 CLI:  sqlite3 :memory: < tracker/schema.sql  (then paste queries)

-- ---------- Sample data ----------
INSERT INTO clients (name, email, hourly_rate_cents) VALUES
    ('RVSelfPark', NULL, 8500),          -- $85/hr
    ('Me',         NULL, 0);             -- internal work, e.g. building this tracker

INSERT INTO projects (client_id, name, budget_hours) VALUES
    (1, 'Redesign', 40),
    (2, 'Freelance tracker', NULL);

INSERT INTO features (project_id, title, stage, estimate_hours) VALUES
    (1, 'New booking page', 'in_progress', 6),
    (2, 'schema.sql',       'review',      1);

INSERT INTO time_entries (project_id, feature_id, started_at, minutes, note, billable) VALUES
    (1, NULL, '2026-11-03T10:00:00', 60,  'Scoping call',      1),
    (1, NULL, '2026-11-04T19:00:00', 90,  'Proposal writing',  1),
    (1, 1,    '2026-11-10T20:00:00', 120, 'Booking page HTML', 1),
    (2, 2,    '2026-11-11T09:00:00', 45,  'Schema review',     0);


-- ---------- Q1: Log time (what `tracker log` will run) ----------
-- The ? placeholders are filled in by Python. NEVER build SQL with f-strings:
-- placeholders prevent SQL injection and handle quoting for you.
--   INSERT INTO time_entries (project_id, feature_id, started_at, minutes, note, billable)
--   VALUES (?, ?, ?, ?, ?, ?);


-- ---------- Q2: Hours per project this month ----------
-- LEFT JOIN keeps projects with zero hours (an inner JOIN would drop them).
-- The date filter sits in the ON clause, not WHERE: in WHERE it would discard
-- the NULL rows the LEFT JOIN just kept, turning it back into an inner join.
SELECT c.name AS client,
       p.name AS project,
       ROUND(COALESCE(SUM(t.minutes), 0) / 60.0, 1) AS hours_this_month
FROM projects p
JOIN clients c        ON c.id = p.client_id
LEFT JOIN time_entries t
       ON t.project_id = p.id
      AND t.started_at >= date('now', 'start of month')
GROUP BY p.id
ORDER BY hours_this_month DESC;


-- ---------- Q3: Earned vs. budget (Overview tab) ----------
-- COALESCE(project rate, client rate) implements "project rate overrides client rate".
-- Only billable minutes count toward earnings. Integer cents in, dollars out at the end.
SELECT p.name AS project,
       ROUND(SUM(t.minutes) / 60.0, 1)                                          AS hours_total,
       p.budget_hours,
       SUM(CASE WHEN t.billable = 1 THEN t.minutes ELSE 0 END)
         * COALESCE(p.hourly_rate_cents, c.hourly_rate_cents, 0) / 60 / 100.0   AS earned_dollars
FROM projects p
JOIN clients c      ON c.id = p.client_id
JOIN time_entries t ON t.project_id = p.id
GROUP BY p.id;


-- ---------- Q4: Estimated vs. actual hours per feature (the "key insight") ----------
SELECT f.title,
       f.stage,
       f.estimate_hours,
       ROUND(COALESCE(SUM(t.minutes), 0) / 60.0, 1) AS actual_hours
FROM features f
LEFT JOIN time_entries t ON t.feature_id = f.id
GROUP BY f.id
ORDER BY f.project_id, f.id;
