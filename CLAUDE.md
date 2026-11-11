# Back-to-Software Practice Plan

## Context

- Developer with 9+ years of experience, on a break since Dec 2025. Skills are rusty, not gone.
- Goal right now: rebuild coding habits using AI tools. Finding freelance clients comes later, once there's a working demo to show.
- One freelance client so far (RVSelfPark redesign). Unsure yet whether freelancing becomes a real side income; that gets judged later, with data.
- Time budget: ~1–5 hrs/week. Scope everything small, in finishable chunks.

## Stack goals

- Python: relearn it (most AI tooling is written in it).
- Next.js: learn it (widely used, marketable).
- Be open to new tools. Learning them is part of the point.

## Work setup ("develop anywhere")

- GitHub is home base. Every project lives in a repo so any machine can pick it up.
- Work computer: Claude Code in the browser against GitHub repos, with nothing installed locally. (Confirm personal projects on that machine are okay with the employer.)
- Main PC: Python, Node, VS Code, and Claude Code in the terminal. This is the full setup, where the other tools get learned.
- Step 0 is done when: a change started on one machine can be finished on the other.

## Main project: Freelance tracker (built in layers)

Vision: a "lightweight Jira for one". Each project gets one page covering its time, documents and features moving toward deployment. Full spec and data model: `docs/product.md`.

Each layer should be usable on its own. Don't start a layer until the previous one works.

1a. Python core: a CLI that logs clients, projects and time entries to SQLite. The schema covers features and documents from day 1.
    Gate: log real hours with it for ~2 weeks before 1b (RVSelfPark scoping calls and proposal writing count, and so does time spent on this tracker).
1b. CLI commands for features (fixed stages, through to deployed) and documents (links).
2. Python MCP server: lets Claude read and log hours ("log 90 min on client X") and move features to another stage.
3. Next.js front end: project list, then a project page with tabs (Overview, Time, Features board, Documents, Invoices).
4. Launch: use it daily, then use it as the demo when looking for local clients.

## How to work with me (Claude)

- Talk through proposed changes and get my approval before building. It saves tokens and gets the product I want.
- Be token-efficient. Use lighter or faster models for simple tasks.
- Hold me accountable firmly, like a coach I'm paying, not a tolerant friend. If I'm drifting or starting new things instead of finishing, call it out.
- Teach, don't just do. The goal is rebuilding my skills, so explain the why on anything non-trivial.
- I'll mostly work with generated code, so the skill I'm practising is reading and reviewing it, not syntax. Claude writes the code (SQL especially) with comments that explain the reasoning. Check my understanding by having me explain key pieces back. No syntax drills unless I ask.
