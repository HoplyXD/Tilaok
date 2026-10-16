# Template 01 synopsis, shot list and capture schedule — DRAFT (2026-10-16)

**Status:** first draft for PHASETASK [P17-T03](PHASETASK.md#p17-t03). Claude (AI) drafted this text at Jorge's request ("continue on phase task"). It must be disclosed on Form 03 as AI-drafted submission copy.

It is not reviewed. Before it is used:
- the Compliance owner must edit and approve it;
- the cultural reviewer must check every Filipino-language or tradition claim (marked †);
- the final copy must be reconciled against the frozen release candidate, describing only shipped behavior.

Item and event names are working names.

## Synopsis (draft, 410 words; limit 500)

**Tilaok!** is a local party platformer for two to four players on one PC, built in Godot. Every player is a chicken: a wholesome, comedic take on the barnyard rivalry of sabong†, with no betting, no injury and soft, silly knockouts.

Each round has three steps. In the **Pugad** (nest), every player picks one egg; each egg shows the piece hatching inside. In **Place**, everyone builds at the same time on one shared stage: hollow-block platforms, bamboo bridges, tire springs, spinning trumpo tops on rails, parol light barriers, tsinelas launchers, bubbles that carry chickens away, spikes, cannons, and brooms or bombs that clear old pieces. Then comes **Play**. The stage never resets, so every round is played on the course everyone has built so far. A helpful bridge in round two can become a trap in round seven.

Most rounds are a **Karera**, a race to the flag. Reaching it scores, being first scores more, and being the only finisher scores a bonus. If everyone finishes, the course was too easy and nobody scores. If nobody finishes, nobody scores. Players also earn points when a trap they placed knocks out a rival, and a trailing player who finishes earns a comeback bonus. An optional coin, the Barya, pays extra if it is carried to the flag.

Every fourth round, and sometimes in between, a Filipino laro ng lahi† takes over the stage. **Lagsanay**† (tag†) turns the round into bomb-tag: the taya carries a countdown, a touch passes it on, and whoever holds it at zero is out, until one chicken remains. Traps still count, so the course the players built shapes the chase. **Kangaroo** calls a giant slipper pose; players freeze, climb above a rising wave or hug a rival, and three misses eliminate. In later rounds a second event can stack on the first as a **Twist**, such as a Karera with Bomb-Taya or Kangaroo with Bomb-Taya. The round screen always says which event decides the round.

The first player to 10 points wins, or the leader after round 12. A tie is settled by sudden-death Lagsanay. A guided first match teaches moving, picking an egg, building and reaching the flag. A Library explains every item and event, and each chicken has a number and shape as well as a color.

Tilaok! borrows only the general build-then-race idea from party games. Its events, items, scoring and code are the team's own. AI coding assistance is disclosed on Form 03.

> Word count check: run `python -c "import re;t=open('docs/SYNOPSIS_DRAFT.md',encoding='utf-8').read().split('## Synopsis')[1].split('> Word count')[0];print(len(re.findall(r'\S+',t.split('\n',1)[1])))"`. 410 on 2026-10-16.

† Needs cultural or native-speaker review (ASSETS.md cultural register): sabong framing, "laro ng lahi", Lagsanay as the Ilonggo/Hiligaynon word for tag, and the item names.

Items to reconcile before upload:
- Kangaroo command wording (Freeze, Rising wave, Hug) must match the final command set.
- Remove any item or map that is not in the frozen manifest ([RELEASE_MANIFEST_DRAFT](RELEASE_MANIFEST_DRAFT.md)).
- The disclosure sentence must match the final Form 03 wording.

## Trailer shot list (60–90 s, loops, readable muted)

Capture only real gameplay from the release candidate: no mockups, and no placeholder art once final art lands.

| # | Seconds | Shot | Caption |
|---|---|---|---|
| 1 | 0–5 | Four chickens at the spawn; title card | TILAOK! — chickens, chaos, one shared stage |
| 2 | 5–12 | Pugad: four eggs with item previews, claims landing | PICK AN EGG |
| 3 | 12–22 | Place: four ghosts building at once; a bomb clears a piece | BUILD THE COURSE — TOGETHER |
| 4 | 22–35 | Karera: a run past a trumpo and a parol; one chicken reaches the flag | RACE TO THE FLAG |
| 5 | 35–42 | A trap knockout with the placer's +0.25 Patibong pop | YOUR TRAPS SCORE FOR YOU |
| 6 | 42–55 | Lagsanay: the taya tags, the countdown ends, an elimination | EVERY 4TH ROUND: LAGSANAY — BOMB TAG |
| 7 | 55–65 | Kangaroo: slipper pose, players freeze, climb above the wave or hug, a third miss | KANGAROO — MATCH THE SLIPPER |
| 8 | 65–75 | A stacked round with the Main and Twist banner | MAIN + TWIST |
| 9 | 75–85 | Results chart, winner celebration | FIRST TO 10 WINS |
| 10 | 85–90 | Title, "2–4 players, local, PC", team credit | TILAOK! |

## Demo video outline (3–5 min, captions or voice)

1. **0:00 Join (20 s):** players join on keyboard layouts and gamepads; number and shape markers.
2. **0:20 Guided first match (40 s):** tutorial steps; the build-to-reach-the-flag lesson.
3. **1:00 Pugad and Place (40 s):** claiming, the ghost preview with rotation, "Tile occupied", explosives.
4. **1:40 Karera and scoring (45 s):** Tapos, Una, Bayani, Patibong, Bawi; the all-finish and no-finish rule on the results chart.
5. **2:25 Lagsanay (45 s):** the taya countdown, tag passing, trap eliminations and placement points.
6. **3:10 Kangaroo and a Twist (40 s):** the commands, three misses; a stacked round with its banner.
7. **3:50 Item tell and counterplay (25 s):** one hazard (for example Parol charge, then crossing in the safe phase).
8. **4:15 Match end (30 s):** first to 10, or sudden death; restart to Lobby.
9. **4:45 Theme (15 s):** what laro ng lahi and Lagsanay mean†, the Library entry.

## Capture schedule

| Date | Work | Owner |
|---|---|---|
| Oct 17–20 | Rehearsal captures on the current build: framing, caption timing, OBS settings. Not final footage. | Compliance + a player group |
| Oct 21 | Feature freeze (P16-T01): reconcile this copy and both shot lists with the frozen manifest. | Producer + Compliance |
| Oct 22–23 | Stabilization; capture final footage on the release candidate once art and audio are in. | Compliance + 2–4 players |
| Oct 24 | Edit, caption, muted-playback check, Template 01 word count and cultural review sign-off; upload rehearsal. | Compliance + cultural reviewer |
| Oct 25 | Submission deadline (P17-T07). | Producer |

Physical capture needs real players and devices. Synthetic test captures are not trailer footage.
