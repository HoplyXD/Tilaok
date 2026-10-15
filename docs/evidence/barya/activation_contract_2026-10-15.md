# Barya scoped activation and behavior contract — 2026-10-15

## Decision

The project owner explicitly authorized implementation of the approved Barya plan on 2026-10-15. Barya remains **Should / optional** content and is enabled only on the default scheduled P12 match after the technical verification recorded in [the Barya evidence index](README.md). The P07 first-playable route stays disabled. `--barya-disabled` provides a P12 rollback switch.

This is a Barya-only implementation disposition under P19-T01. It does not confirm or ratify the full release manifest, change any other family/event scope, close P00-T04, or claim competition-organizer approval. P00-T04 remains BLOCKED. No individual Barya owner/capacity assignment or independent reviewer was recorded.

## Contract

- Before each Pugad, commit the P12 schedule entry. Offer only when the Main is Karera, including Karera + Bomb-Taya and Karera + Kangaroo; never offer for standalone event rounds, Kangaroo + Lagsanay, or sudden death.
- Use a separate seeded `barya` stream. Default offer probability is 1/3. A successful roll replaces one uniformly selected egg without changing the existing pool size. Disabled/ineligible Barya consumes no Barya randomness and preserves baseline egg results.
- There is at most one round-scoped 1×1 objective. The ordinary Pugad claim path assigns it; the ordinary Place flow validates and reserves its cell and first-confirm lock. Invalid or expired placement discards it. It is not an obstacle or an `ItemManager` piece: no construction-cap cost, solid body, support, Rising interaction, Walis target, or persistent construction state.
- Resolve pickup candidates from one physics-step snapshot. The closest chicken controller root wins; exact-distance ties go to the lower seat index. Carrying follows the controller and survives capture. There is no manual drop or stealing.
- Only a committed elimination drops the coin, at the chicken controller root. If that cell is invalid, move the same coin to the nearest valid cell; equal-distance cells use row-major `(y, x)` order. Show a recovery cue. If no valid cell exists, discard it. A death-step drop cannot be picked up again until the next physics step.
- Resolve pickup before same-step terminal commit. Barya pays only when the same seat's committed outcome is `FINISHED` while carrying; a committed `ELIMINATED` outcome drops it. A losing terminal candidate does neither. A finisher receives +0.5 (four eighth-point units) exactly once even when all players finish; nobody finishing means zero Barya points.
- Pause freezes the objective. An aborted attempt preserves the pre-Play cell, increments the attempt identity, and clears temporary carrier/receipt data without rerolling Pugad. At normal round end, copy receipt into results/history, then remove the coin.
- Provide a non-color carrier/feedback cue, score/results/history row, conditional Library entry and Barya tutorial prompt. The current coin/preview uses code-drawn DEBUG geometry only. Final art/audio and human accessibility, cultural, balance and player review stay with the team.

## Approval and verification boundaries

The code and technical evidence were produced by AI-assisted programming after the user's explicit implementation authorization, under the repository's standing AI programming workflow. No manual authorship, human code review, named gameplay owner, QA reviewer, play session, physical-device use, production art/audio, independent approval, or organizer approval is claimed here. Human-team responsibility for integration/review/delivery remains in force. The unchanged full-release-manifest decision remains open under P00-T04.
