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

Each layer should be usable on its own. Don't start a layer until the previous one works.

1. Python core: a CLI that logs time entries and clients to SQLite.
2. Python MCP server: lets Claude read and log hours ("log 90 min on client X").
3. Next.js front end: dashboard, invoice generation, monthly income view.
4. Launch: use it daily, then use it as the demo when looking for local clients.

### Quick win (between layers 1 and 2)

Road-trip CD builder (Python, one weekend): packs a playlist into 80-minute discs, ordered by mood or energy. Its purpose is to prove that finishing things still happens.

## Backlog (later, not now)

- Camping trip planner for the Tacoma and Tune M1 (free/dispersed sites, route, weather, fuel cost)
- Local LLM lab on own hardware (Ollama, RAG over personal notes, benchmark desktop vs laptop)
- Switchbox upgrades (AI opponent, online two-player)
- Open-source "good first issue" contributions
- Personal model eval harness (quality / cost / speed)

## First milestone, due Sun Nov 15

- [ ] Step 0 setup done on both machines
- [ ] Repo created for the freelance tracker
- [ ] Python script that saves one time entry to SQLite

## How to work with me (Claude)

- Talk through proposed changes and get my approval before building. It saves tokens and gets the product I want.
- Be token-efficient. Use lighter or faster models for simple tasks.
- Hold me accountable firmly, like a coach I'm paying, not a tolerant friend. If I'm drifting or starting new things instead of finishing, call it out.
- Teach, don't just do. The goal is rebuilding my skills, so explain the why on anything non-trivial and let me write parts myself when it's useful practice.
