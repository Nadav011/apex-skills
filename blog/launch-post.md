# I Maintain 18 Production Projects. I Haven't Manually Debugged a CI Failure in Weeks.

That's not a boast. It's a side effect of a system I built out of desperation.

Let me explain how I got here — and why I'm open-sourcing the parts that made the biggest difference.

---

## The Problem Nobody Talks About

Most developer tooling is designed for a team working on one product. You have a monorepo, a single CI pipeline, a shared on-call rotation. When something breaks, someone investigates. Process is manageable.

I don't have that. I'm a solo developer maintaining 18 production projects: restaurant platforms, scheduling apps, finance tools, a Flutter sports chat app, a video renderer, a personal site, internal tools. Some are on Next.js 16, some are Vite + React, one is Flutter. They span pop-os and an MSI laptop connected via Tailscale. They share exactly one thing: they are all my responsibility, all the time.

For a while, CI was the thing I dreaded most. Not the failures themselves — those are normal. It was the context switching. A GitHub Actions alert at midnight. Tab over, scan the logs, remember which version of which library is in which project, fix the YAML, push, wait four minutes for the runner, find the next error, repeat. By the time I fixed the thing I was supposed to be building was already cold in my head.

It wasn't sustainable. So I started automating my way out.

---

## How It Started: Small Hooks

The first thing I did was write pre-commit hooks. Nothing clever — just RTL checks. I work primarily on Hebrew and Arabic interfaces, and the single most common mistake in that context is writing `ml-4` instead of `ms-4` in Tailwind (logical properties vs. physical properties). A ten-line shell script stopped that class of error from ever reaching a PR.

Then I added a lint hook. Then a type-check on the most commonly changed files. Then a secrets scanner.

Each hook was small. Each one eliminated a category of feedback-loop friction. Over weeks, the commit-time error rate dropped noticeably.

But hooks only cover what happens before a push. The harder problem was what happened after — the CI pipeline, the failures downstream, the 3 AM alerts for things that should have been caught automatically.

---

## The Orchestration Layer

Around March 2026, I built something I call Hydra v2. The name is overdramatic for what it actually is: a task router that looks at a failing job, decides which AI provider is best suited to fix it, dispatches the fix, and verifies the result before writing anything to disk.

Hydra connects to four providers: Claude, Codex, Gemini, and MiniMax. Each has a Bayesian score — a running probability estimate of whether it will succeed on a given type of task. CI repair tasks tend to go to Codex. Test generation goes to MiniMax in parallel batches. Deep analysis goes to Gemini with its two-million-token context window. The routing is not magic; it's just accumulated evidence about what each model is actually good at.

The part that surprised me most was the verification step. Fixing a CI failure is easy. Knowing whether the fix is correct is hard. Hydra runs a verification pass after every dispatch — if the verification fails, the fix is discarded and a different provider tries. The success rate after verification is substantially higher than any single provider on its own.

Since I deployed this in March, I have not manually debugged a CI failure. When something breaks, Hydra opens a task, routes it, verifies a fix, and opens a PR. I review and merge. That's the whole workflow.

---

## The RTL Problem

Here is something that does not get discussed much: there is almost no production-ready tooling for building right-to-left interfaces.

There are roughly 50 million Arabic-speaking developers and tens of millions more working in Hebrew, Urdu, Persian, and other RTL languages. The ecosystem for building apps in those languages is essentially: read the WCAG notes, check the MDN page on CSS logical properties, hope the framework docs have an RTL section, and debug the rest manually.

The RTL mistakes that slip through are embarrassingly consistent. Directional padding written with physical properties (`pl-`, `pr-`) instead of logical ones (`ps-`, `pe-`). Icon rotation applied to vertical icons that don't need it. Gradient directions that reverse when you switch `dir` attribute. Hardcoded `left: 0` in positioned elements. Number strings embedded in right-to-left paragraphs without a `dir="ltr"` wrapper.

I know these patterns because I make them. My pre-commit hooks catch most of them now. My `rtl-validator` skill catches the rest during code review. But I built those tools myself because nothing equivalent existed.

That's one of the things I'm open-sourcing.

---

## What's in the Release

The APEX skills pack is 15 portable skills extracted from my local setup. They are not tied to my projects, my stack opinions, or my particular Hydra configuration. They are the reusable layer — patterns that any Claude Code user can install and use immediately.

The skills cover:

**Code quality:** `frontend-rules`, `backend-rules`, `testing-rules`, `security-rules` — opinionated rule sets that encode the mistakes I've stopped making and the patterns I've settled on for the current stack (Next.js 16, React 19, Vitest 4, Supabase, Flutter 3.41).

**RTL and internationalization:** `rtl-validator`, `rtl-fix` — the only production toolkit for Hebrew and Arabic development I'm aware of. Covers Tailwind logical properties, Flutter directional widgets, CSS layout, icon rotation rules, and gradient handling. Works on both web and Flutter.

**Review and verification:** `adversarial-review`, `edge-case-hunter`, `apex-guards` — structured review passes that catch the things a happy-path implementation misses. `adversarial-review` asks what an attacker would do. `edge-case-hunter` stress-tests assumptions. `apex-guards` is a pre-merge sanity check.

**Accessibility:** `a11y` — a complete WCAG 2.2 audit skill covering web, mobile, and Flutter. Includes European Accessibility Act compliance checks, which became enforceable in mid-2025.

**PWA and performance:** `pwa-expert` — covers the service worker patterns that make PWAs actually work (update detection, stale chunk recovery, iOS Safari fallbacks, Workbox configuration).

These are the skills I run on every project, every week. They are the reason the baseline error rate is low enough that automated repair is feasible.

---

## The Install

```
npx skills add Nadav011/apex-skills
```

That's it. The skills install into your Claude Code configuration and are available immediately as slash commands.

If you work on Arabic or Hebrew interfaces and want the RTL toolkit specifically:

```
npx skills add Nadav011/rtl-first-dev-kit
```

---

## Why Open Source

A few reasons.

The RTL tooling gap is real and it affects a lot of developers. I built it for my own projects, but there is no reason it should stay locked in my dotfiles.

The skills themselves only stay useful if they stay current. Opening them to contribution means they will track the framework evolution — Next.js breaking changes, Tailwind class renames, new Flutter widget APIs — without that work falling entirely on me.

And honestly: I have learned more about software engineering in the past year from building and iterating on these tools than from almost anything else. The process of encoding a rule precisely enough that a hook or a skill can apply it consistently forces a kind of clarity about what the rule actually means. Contributing to that process seemed like the right thing to do.

---

## What This Is Not

It is not a magic CI fixer you install and walk away from. Hydra v2, the routing system, the Bayesian provider selection — that is not in this release. It requires infrastructure (a local LangGraph process, SQLite state, provider credentials) that is not realistic to distribute as a skill pack. What is in this release is the higher-level layer: the skills that make the code quality good enough that automated repair has a reasonable success rate to work with.

It is also not complete. The skill catalog will grow. Some of the skills in the current release are useful but not polished. The install tooling is functional but not refined. I am shipping the useful version, not the perfect version.

---

## Try It

- GitHub: [github.com/Nadav011/apex-skills](https://github.com/Nadav011/apex-skills)
- RTL toolkit: [github.com/Nadav011/rtl-first-dev-kit](https://github.com/Nadav011/rtl-first-dev-kit)
- Install: `npx skills add Nadav011/apex-skills`

If you work on Hebrew or Arabic interfaces and the RTL toolkit is useful, I'd particularly like to hear about it. The patterns in there reflect my stack and my common mistakes — other developers will have others.

Star the repo if it looks useful. Open an issue if something is wrong or missing. Contributions to the rule files are especially welcome.

---

*Built with Claude Code, Codex, Gemini, Kimi, and MiniMax.*
