# Prompt-writing rules — Tilaok!

**Scope update (2026-10-24):** normal Play is local/offline live-build: Lobby → Pugad → shared 10-second BUILD → final 3–2–1/GO cue → active play/build → results. The timer stays in the side HUD, the full-screen cue appears only in BUILD’s final three seconds, and expiry starts Play immediately. A separate three-second GET READY countdown is used when resuming from pause. BUILD lets each player place their one assigned item early or save it for play; two-second preparation jobs stay inert until PLAY and continue during active play. Phone/LAN and Android features are retired; their specifications and evidence are historical records in `archive/retired-networked-live-build/`. Use the current phase tracker and this rules document for new work. Retirement does not mark network work complete.

Standing user preferences consolidated on 2026-10-13. Read this document before drafting or revising any implementation or phase prompt. New explicit user decisions may supersede these preferences; record material changes here. This is reusable guidance, not a generated task prompt.

## Role and output

- When asked to create a prompt, gather context and write the prompt; do not implement its task.
- Deliver the complete paste-ready prompt in chat as ONE fenced block. Never save individual task prompts as files unless explicitly requested. This user-requested rules document is the exception, not permission to create prompt files routinely.
- Use short, plain sentences, concrete acceptance checks and measured numbers. Include the user's requested outcome, clarified intent and explicit non-goals.
- For vague requests ask 1–3 focused questions. Do not invent unknown facts or reopen settled decisions.
- For multiple repositories, provide one self-contained prompt per repository with a shared contract and receiver-before-sender delivery order; explain this exception to the single-prompt format.

## Context before drafting

- Inventory and fully read all project-owned Markdown, including root/nested tracked and untracked documents. Exclude Git internals, generated caches and third-party dependencies; read long documents completely in chunks.
- Verify the current checkout, branch, worktrees, remote, status and relevant history. Never assume an earlier checkout location or commit is still current.
- Inspect the complete requested PHASETASK phase, linked PRD requirements, dependencies, GDD, specialized contracts, actual implementation and evidence. Read relevant code headers and bodies; documentation alone is not proof of implementation.
- Search prior art with `git log --all -i --grep="<keyword>"`, existing systems and available merged-PR history. Report EXISTS / PARTIAL / NONE with current path:line references.
- Identify affected scripts/scenes, assets, input, game-loop contracts and data. The current October build is local/offline; phone/LAN connectivity has been retired. Treat NLB documents under `archive/retired-networked-live-build/` as historical records, not active scope. Do not add network features or persistence without a new approved request.
- Verify actual installed/connected tools, engine, export templates, test runners and lint/format commands. Do not present planned commands, synthetic devices or unavailable integrations as verified resources.
- Research when requested; prefer original/official sources for engine APIs. UCH research is mechanical inspiration only, never permission to copy code, assets, names or characters.

## Required prompt structure and execution

Every implementation prompt contains these sections, filled with verified task-specific context:

1. Task/outcome and non-goals.
2. Setup: verified checkout, rules and tools.
3. Stage A context gathering and dependency checks.
4. Relevant production requirements.
5. Stage A PLAN: goal, approach, rejected alternative, files, interfaces, data, performance budget, acceptance checks, playable slices, abuse/failure cases, tests and open questions.
6. Explicit STOP and wait for the user's `approved` before implementation.
7. Stage B build rules and complete task-by-task scope.
8. PLAYTEST/VERIFY with real output and evidence.
9. DOCUMENT, including mandatory tracker edits.
10. SHIP, including safe Desktop synchronization.
11. Final report and ONE next user action.

After approval, require persistence through the entire approved scope, fixes, reruns, documentation and delivery—not just scaffolding or the first passing test. A “do not stop” request does not bypass the initial approval gate unless explicitly changed by the user, authorize scope expansion, or permit fabricated completion. If a genuine external/human/hardware blocker remains, finish independent authorized work and request the smallest necessary action. Material approach/design changes require approval.

## Programming and human production responsibilities

- AI/LLMs are the approved primary code generators under Francis and Carlos's development leadership. Do not ask for another per-phase AI-authorship exception. Follow `AI_USAGE.md` and current agent instructions.
- Programming authorization includes mechanics, scripts, integration scenes, tests and tooling within scope. It does not authorize AI-generated final art/audio/assets.
- Human production assignments are recorded in `PRODUCTION.md`; recheck them rather than inventing roles, reviewer identities, registration facts or hours.
- Record actual assistance in `AI_USAGE.md` and Form 03 preparation. Do not describe AI-generated code as manually human-written or invent completed human review/organizer approval.
- Keep genuine competition/submission obligations separate from the settled permission to implement with AI. Do not repeatedly block ordinary programming on the obsolete manual-authorship policy.

## Production and verification requirements

- Use relevant engine/game requirements, not irrelevant template boilerplate: config-driven tuning, lifecycle cleanup, bounded spawning, readable number/shape identities, supported-device parity, licensed/original content and platform compliance.
- Preserve provisional values and inactive proposals until explicitly revised. Risky economy, monetization or save-format changes, if ever requested, need a flag and rollback path. Networked or saved-data work, if requested later, needs authority/validation and versioning/recovery safeguards.
- Name applicable measured budgets. Offline provisional targets are 60 FPS / 16.67 ms at 1080p, 512 MiB process memory and 0 B/s gameplay traffic. Networked targets are proposed and unmeasured in `archive/retired-networked-live-build/NETWORKED_LIVE_BUILD.md`; reverify the applicable document before quoting a budget.
- Include lint/format, import/parse, existing regressions, focused tests, actual rendered playtests, screenshots/clips, performance/cleanup checks and export smoke checks as applicable.
- Record build/revision, engine, date, profile/seed, player count, actual devices or synthetic input, procedure, expected/actual result, evidence and actual reviewer.
- Mark checks PASSED / FAILED / COULD-NOT-RUN with reasons. Never check an unrun test. Synthetic input is not physical-controller/rollover/reconnect evidence; fixture testing is not full-game or release verification.

## Mandatory PHASETASK and documentation updates

- Require updates to `docs/PHASETASK.md` ON DISK throughout implementation and before shipping—not merely a statement in the final report.
- Cover every task in the requested phase, including paired verification tasks and its exit criteria.
- Preserve IDs, traceability and genuine dependencies. Document approved acceptance/dependency revisions transparently; never silently weaken them to force completion.
- Check `[x]` only when that specific task's acceptance is implemented and verified. Keep partial, failed, blocked or unrun tasks `[ ]` with exact reasons and next actions.
- Attach implementation references and real evidence, update statuses/phase roll-ups, and recount global totals from actual checkboxes.
- Do not mark unrelated hardware tests, human review or other phases complete without their own evidence. Partial overall prerequisites do not block a phase when its specific required dependencies genuinely pass.
- Update affected PRD, GDD (approved design changes), specifications, defaults, PLAYTEST, PROJECT_STRUCTURE, README/INDEX, production/roadmap and AI_USAGE records. Preserve dated history and reconcile stale current-status claims.
- Finish by rereading the phase and auditing every checked item against evidence.

## Ship and Desktop testing copy

- Future implementation prompts use an existing suitable `main` checkout and direct delivery to `origin/main`; no new branch, worktree or PR by default. Explicitly state commit/push authorization in the generated prompt. Drafting a prompt does not itself authorize executing its Git actions.
- Discover current checkout state first. Protect unrelated edits and commits, stage named task files only, use Conventional Commits, and never use `git add .`, `--no-verify`, force-push or destructive reset. Do not alter Git author identity or attribute work to an invented human identity.
- Include required docs/evidence in the reviewed delivery. Verify remote synchronization and distinguish partial delivery from phase completion.
- After verified delivery, safely update the user's testing checkout at `C:\Users\roman\Desktop\Vscode Projects\Tilaok` to include the delivered implementation and documents.
- Inspect its actual branch, dirty files, untracked files and unique commits first. Do not assume it is `main`, detached, clean or stale. If it is already the implementation checkout, do not perform redundant synchronization.
- Use a safe fast-forward where possible. If another integration method or conflict resolution is necessary, explain it and obtain direction before risking local work. Never overwrite, discard, force-reset, blindly copy files over the checkout or silently stash user changes.
- Recheck Desktop state and run an appropriate smoke check. Report the delivered revision, Desktop HEAD/branch, any local differences, and exact launch instructions. Do not claim it is synchronized when blocked.

Every generated prompt MUST include this line verbatim in its Ship section:

**When committing or pushing: do NOT add a `Co-Authored-By:` trailer, "Generated with" line, or any AI attribution to commits, PR titles or PR bodies. Commits are authored by me only.**

Keep truthful AI disclosure in project documents and Form 03 preparation; this attribution preference does not permit false provenance claims.

## Final report required from the implementing agent

State what changed/how it plays, actual phase completion X/Y, remaining unchecked tasks and reasons, real verification/performance evidence, confirmation of on-disk tracker updates, commit/push result, Desktop sync/launch result and ONE next user action. Never call the phase complete unless its evidence and exit criteria support it.
