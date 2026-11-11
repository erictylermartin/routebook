# Freelance Tracker: Product Spec

A "lightweight Jira for one": a single place to check any project and see its time, its documents, and the features moving toward deployment.

## Principles

- **Single user.** No logins, roles or permissions. Clients see what I export (invoices, reports), not the app.
- **Everything hangs off a Project.** `Client → Project → { Time entries, Features, Documents }`
- **Opinionated over configurable.** Fixed feature stages, with no custom workflows or fields. That's what keeps it light.
- **Link out, don't rebuild.** Documents are URLs (Drive, GitHub, etc.). Deploy status is a PR/deploy link, not a CI integration.

## Pages

**Projects list:** every project with its client, status, hours this month and features in flight.

**Project detail** (click into one), with these tabs:

| Tab | Shows |
|---|---|
| Overview | Status, hours this week/month, earned vs. budget, features in flight, upcoming document dates |
| Time | Time entries, billable flag, optional link to a feature |
| Features | Board: `idea → ready → in_progress → review → staging → deployed`, with priority, estimate vs. actual hours, PR/deploy link |
| Documents | Contracts, SOWs, specs and invoices as links, with type and due/expiry date |
| Invoices | *(later)* Generated from billable time entries |

**Key insight:** time entries can optionally point at a feature, so each feature shows **estimated vs. actual hours**. That data helps me quote future work accurately, and it makes a strong demo for prospective clients.

## Data model (SQLite)

```
clients       (id, name, email, hourly_rate, created_at)
projects      (id, client_id → clients, name, status [active|paused|done],
               hourly_rate NULL  -- overrides client rate,
               budget_hours NULL, created_at)
features      (id, project_id → projects, title, description,
               stage [idea|ready|in_progress|review|staging|deployed],
               priority [low|med|high], estimate_hours NULL,
               pr_url NULL, deployed_at NULL, created_at)
time_entries  (id, project_id → projects, feature_id → features NULL,
               started_at, minutes, note, billable)
documents     (id, project_id → projects, title,
               doc_type [contract|sow|spec|invoice|other],
               url, due_date NULL, created_at)
```

## Build order

See the layers in `CLAUDE.md`. In short: time logging (1a) → features + documents in the CLI (1b) → MCP server (2) → Next.js UI (3) → daily use / demo (4).

## Out of scope (for now)

Multiple users/roles, comments, notifications, sprints, custom workflows or fields, file uploads/storage, CI/CD integration.
