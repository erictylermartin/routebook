"""Freelance tracker CLI (Layer 1a): clients, projects and time entries in SQLite.

Run `python tracker/cli.py help` for commands, or `python tracker/cli.py help log`
for one command's fields. Standard library only: nothing to install.
"""
import argparse
import os
import sqlite3
import sys
from datetime import date, datetime, timedelta
from decimal import Decimal
from pathlib import Path

HERE = Path(__file__).parent
SCHEMA = HERE / "schema.sql"
# Default DB sits in the repo root (git-ignored). TRACKER_DB overrides it, e.g. to
# point at a file in a synced folder later.
DB_PATH = Path(os.environ.get("TRACKER_DB", HERE.parent / "tracker.db"))


class UserError(Exception):
    """A mistake in the user's input: print the message, no stack trace."""


def connect() -> sqlite3.Connection:
    if not DB_PATH.exists():
        raise UserError(f"No database at {DB_PATH}. Run: python tracker/cli.py init")
    conn = sqlite3.connect(DB_PATH)
    # Foreign keys are OFF by default in SQLite, per connection. Every connection
    # must turn them on, which is why it lives here and nowhere else.
    conn.execute("PRAGMA foreign_keys = ON")
    conn.row_factory = sqlite3.Row  # rows behave like dicts: row["name"]
    return conn


def dollars_to_cents(text: str | None) -> int | None:
    # Decimal, not float: float("0.29") * 100 == 28.999999999999996.
    return None if text is None else int(Decimal(text) * 100)


def find_project(conn, ref: str) -> int:
    """Turn 'Client/Project' into a project id."""
    if "/" not in ref:
        raise UserError(f"Project must be written as CLIENT/PROJECT, got {ref!r}")
    client, project = (part.strip() for part in ref.split("/", 1))
    # ? placeholders: sqlite3 passes the values separately from the SQL text, so a
    # name like  O'Brien  (or something malicious) can never change the query.
    row = conn.execute(
        """SELECT p.id FROM projects p JOIN clients c ON c.id = p.client_id
           WHERE c.name = ? AND p.name = ?""",
        (client, project),
    ).fetchone()
    if row is None:
        raise UserError(f"No project {project!r} for client {client!r}. See: hours")
    return row["id"]


# ---------- commands ----------

def cmd_init(args):
    if DB_PATH.exists():
        raise UserError(f"{DB_PATH} already exists; not overwriting your data.")
    conn = sqlite3.connect(DB_PATH)
    conn.executescript(SCHEMA.read_text())
    conn.close()
    print(f"Created {DB_PATH}")


def cmd_add_client(args):
    with connect() as conn:  # `with` commits on success, rolls back on error
        conn.execute(
            "INSERT INTO clients (name, email, hourly_rate_cents) VALUES (?, ?, ?)",
            (args.name, args.email, dollars_to_cents(args.rate)),
        )
    print(f"Added client {args.name}")


def cmd_add_project(args):
    with connect() as conn:
        client = conn.execute("SELECT id FROM clients WHERE name = ?", (args.client,)).fetchone()
        if client is None:
            raise UserError(f"No client {args.client!r}. Add it first: add-client")
        conn.execute(
            """INSERT INTO projects (client_id, name, hourly_rate_cents, budget_hours)
               VALUES (?, ?, ?, ?)""",
            (client["id"], args.name, dollars_to_cents(args.rate), args.budget),
        )
    print(f"Added project {args.client}/{args.name}")


def cmd_log(args):
    if args.date:
        # Only a date given: time of day unknown, so record midnight.
        started = datetime.combine(date.fromisoformat(args.date), datetime.min.time())
    else:
        # Assume you log right after finishing, so the work started `minutes` ago.
        started = datetime.now() - timedelta(minutes=args.minutes)
    with connect() as conn:
        project_id = find_project(conn, args.project)
        conn.execute(
            """INSERT INTO time_entries
                   (project_id, feature_id, started_at, minutes, note, billable)
               VALUES (?, ?, ?, ?, ?, ?)""",
            (project_id, args.feature, started.isoformat(timespec="seconds"),
             args.minutes, args.note, 0 if args.nonbillable else 1),
        )
    print(f"Logged {args.minutes} min on {args.project}"
          + (" (non-billable)" if args.nonbillable else ""))


def cmd_hours(args):
    # Month start computed in Python, in LOCAL time, to match how `log` stores
    # started_at. SQL's date('now') is UTC and could disagree near midnight.
    month = args.month or date.today().strftime("%Y-%m")
    start = f"{month}-01"
    y, m = map(int, month.split("-"))
    end = f"{y + m // 12:04d}-{m % 12 + 1:02d}-01"  # first day of next month
    with connect() as conn:
        # Same shape as examples.sql Q2: filter in ON so empty projects show 0.0.
        rows = conn.execute(
            """SELECT c.name AS client, p.name AS project, p.status,
                      ROUND(COALESCE(SUM(t.minutes), 0) / 60.0, 1) AS hours
               FROM projects p
               JOIN clients c ON c.id = p.client_id
               LEFT JOIN time_entries t
                      ON t.project_id = p.id
                     AND t.started_at >= ? AND t.started_at < ?
               GROUP BY p.id
               ORDER BY hours DESC, client, project""",
            (start, end),
        ).fetchall()
    if not rows:
        print("No projects yet. Start with: add-client, then add-project")
        return
    print(f"Hours for {month}")
    for r in rows:
        print(f"  {r['hours']:>6.1f}  {r['client']}/{r['project']}  [{r['status']}]")


# ---------- argument parsing ----------

def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="tracker",
        description="Log clients, projects and time to SQLite.",
        epilog="Run 'help COMMAND' (or 'COMMAND -h') for a command's fields.",
    )
    sub = parser.add_subparsers(dest="command", metavar="COMMAND", required=True)

    def add(name, func, help_text, example):
        p = sub.add_parser(name, help=help_text, description=help_text,
                           epilog=f"example: python tracker/cli.py {example}")
        p.set_defaults(func=func)
        return p

    p = add("help", None, "Show all commands, or one command's fields.", "help log")
    p.add_argument("topic", nargs="?", help="command to describe")

    add("init", cmd_init, "Create the database from schema.sql.", "init")

    p = add("add-client", cmd_add_client, "Add a client.",
            'add-client RVSelfPark --rate 85')
    p.add_argument("name", help="client name (unique)")
    p.add_argument("--rate", help="hourly rate in dollars, e.g. 85 or 92.50")
    p.add_argument("--email", help="contact email")

    p = add("add-project", cmd_add_project, "Add a project under a client.",
            'add-project RVSelfPark Redesign --budget 40')
    p.add_argument("client", help="existing client name")
    p.add_argument("name", help="project name (unique per client)")
    p.add_argument("--rate", help="hourly rate in dollars; overrides the client's rate")
    p.add_argument("--budget", type=float, help="budget in hours")

    p = add("log", cmd_log, "Log time on a project.",
            'log "RVSelfPark/Redesign" 90 "Scoping call"')
    p.add_argument("project", help="CLIENT/PROJECT (quote it if names have spaces)")
    p.add_argument("minutes", type=int, help="minutes worked, e.g. 90")
    p.add_argument("note", nargs="?", help="what you did")
    p.add_argument("--date", help="YYYY-MM-DD, if not today (time recorded as midnight)")
    p.add_argument("--nonbillable", action="store_true", help="don't bill this time")
    p.add_argument("--feature", type=int, help="feature id (must be in the same project)")

    p = add("hours", cmd_hours, "Hours per project for a month (default: this month).",
            "hours --month 2026-11")
    p.add_argument("--month", help="YYYY-MM")

    return parser


def main(argv=None):
    parser = build_parser()
    args = parser.parse_args(argv)
    if args.command == "help":
        if args.topic:
            parser.parse_args([args.topic, "-h"])  # prints that command's help, exits
        parser.print_help()
        return 0
    try:
        args.func(args)
    except UserError as e:
        print(f"error: {e}", file=sys.stderr)
        return 1
    except sqlite3.IntegrityError as e:
        # The schema's CHECK / UNIQUE / FOREIGN KEY rules caught bad data.
        print(f"error: rejected by the database ({e})", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
