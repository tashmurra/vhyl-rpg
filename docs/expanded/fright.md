# Fright Checks

`vhyl-rpg-expanded-fright.t` adds fear and horror encounters: a Will-based Fright
Check, its situation modifiers, and the full range of results on a failure, from a
moment's stun to coma, catatonia and lasting changes. Source: full-2008, B360–B361,
with trait effects from B127, B129, B135 and B162.

## Including

Include core, progression, Lite, `vhyl-rpg-expanded.t` and
`vhyl-rpg-expanded-traits.t`, then `vhyl-rpg-expanded-fright.t`. Characters must be
`RpgExpandedProfile`s with a `rules` object. Including the module changes nothing
until an author calls `rpgFrightCheck`.

## Making a check

Describe the encounter with an `RpgFrightSituation` and call
`rpgFrightCheck(profile, situation)` from an `Action.exec`, so undo, rollback and
saves cover it. The receipt (`RpgFrightResult`) has a `status`:

| Status | Meaning |
| --- | --- |
| `resisted` | The check succeeded. Nothing else changes. |
| `failed` | `tableRoll` (3d) plus the failure margin gives `total`; `row` is the applied result (totals above 40 use row 40). |
| `exempt` | The character is Unfazeable. No dice are drawn. |
| `blocked` | `reason = 'incapacitated'`: the character is dead or unconscious. |

The target is modified Will, reduced to 13 if higher, so a roll of 14 or more always
fails. Rolls of 3 or 4 always succeed, even when modified Will is below 3.
`rpgFrightScore`, `rpgFrightModifiedWill` and `rpgFrightModifier` are pure queries for
previews; they draw no dice and spend no time.

## Situation fields

All fields are optional and default to no modifier.

| Field | Effect |
| --- | --- |
| `monster` | The creature's own modifier, −10 to 0. |
| `count` | Number of monsters: −1 at 5, −2 at 10, −3 at 20, −4 at 50, −5 at 100+. |
| `body` | `'prepared'` +6, `'peaceful'` +2, `'violent'` 0, `'mutilated'` −`mutilation` (1–3). |
| `dependent` | −6 more when the body was the character's Dependent. Requires `body`. |
| `inCombat` | +5 when the horror appears during combat. |
| `touched`, `isolated`, `dark`, `alone` | −1, −1, −1 and −2. Set `dark` for daylight if the character is nocturnal. |
| `viewing` | `'present'`, `'distant'` (100+ yards, +1) or `'remote'` (+3). |
| `experienced`, `briefing` | +1 for prior experience; +0 to +3 for advance knowledge. |
| `threat` | A stable id. Each earlier exposure to the same threat in the last 24 game hours gives +1. |
| `physicalDanger`, `charging`, `swornFoe`, `strange` | Enable Cowardice, Daredevil, Higher Purpose and Xenophilia. |
| `modifier` | Any further authored modifier. |

Trait ids recognised: `fearlessness` and `combat-reflexes` (through the shared Lite
score), `fearfulness`, `combat-paralysis`, `unfazeable`, `daredevil`,
`higher-purpose`, and `cowardice` and `xenophilia`, which scale with self-control
rating: 4, 3, 2 or 1 at 6, 9, 12 (the default) or 15.

## Results

Each result either starts one timed condition (an `RpgFrightEpisode`), applies
immediate harm, or records a pending acquisition, and some do several. Dice are
drawn in the order shown.

| Rows | Result |
| --- | --- |
| 4–5 | Stunned 1 second, then recovers automatically. |
| 6–7 | Stunned 1 second, then a Will roll each second. |
| 8–9 | Stunned 1 second, then a roll each second against modified Will (`episode.score`). |
| 10 / 11 | Stunned 1d / 2d seconds, then modified Will each second. |
| 12 | Retching (`retching`) for 25 − HT seconds, then HT each second. |
| 13 | Pending quirk (−1). |
| 14–15 | Lose 1d FP, then stunned 1d seconds as row 10. |
| 16 | Stunned as row 10, plus a pending quirk. |
| 17 | Faint 1d minutes, then HT each minute. |
| 18 | As 17, plus an immediate HT roll; on a failure, 1 HP of injury. |
| 19 | Faint 2d minutes, then HT each minute; 1 HP of injury. |
| 20 | Faint 4d minutes, then wakes; lose 1d FP. |
| 21 | Panic (`panicked`) for 1d minutes, then Will each minute. |
| 22 / 23 | Pending −10 delusion / −10 mental disadvantage. |
| 24 | Pending −15 of physical disadvantages. |
| 25 | Pending: worsen a related disadvantage's self-control one step, or a new −10 mental one. |
| 26 / 27 | Faint as 18, plus pending −10 delusion / −10 mental. |
| 28 | Light coma: HT every 30 minutes; −2 for 6 hours after waking. |
| 29 | Coma: 1d hours, then HT; each failure adds 1d hours; −2 for 6 hours after. |
| 30 | Catatonia: 1d days, then HT; each failure adds 1d days. Without `medicalCare`, lose 1 HP on day one, 2 on day two, and so on. Afterwards −2 for as many days as it lasted. |
| 31 | Seizure 1d minutes, lose 1d FP, then an HT roll: a failure costs 1d injury, and a critical failure also 1 HT permanently. |
| 32 | Collapses with 2d injury. |
| 33 | Total panic: `panicRoll` is a 3d reaction roll for the author to interpret. |
| 34 / 35 | Pending −15 delusion / −15 mental. |
| 36 / 37 | Pending −20 / −30 physical. |
| 38 / 39 | Coma as 29, plus pending −15 delusion / −15 mental. |
| 40+ | As 39, and −1 IQ permanently. |

## Conditions and time

Only one episode is active per character, and a new one replaces it. While it lasts,
it sets `stunned`, `unconscious` (faint, comas, catatonia), `panicked` or `retching`,
and holds Lite's `fearSeconds` so that ordinary stun and wake checks wait for it.
`rpgFrightIncapacitated(profile)` reports whether one is active.

Episodes advance inside `rpgLiteHealthTime` through the new
`RpgLiteProfile.conditionTime` hook, so Lite rest and combat clocks drive them
without extra calls. Total panic does not advance with time: after playing out the
reaction, call `rpgFrightPanicReaction(profile)`. It rolls Will and returns `nil` when
the panic ends, or the next reaction roll. When an episode ends it clears only the
flags it set. A lingering −2 (`lingeringPenalty`) applies to every skill roll and
attribute check except defenses, and counts down only after the character wakes.

## Pending acquisitions

The module never chooses a quirk, phobia or physical change. Failed rows append an
`RpgFrightAcquisition` (`kind`, `points`, `row`) to `profile.frightPending`. Resolve
one with `rpgFrightAcquire(profile, acquisition, traits)`, passing new approved traits
whose `creationCost()` totals exactly `points`. For `'worsen-or-mental'`, pass a single
owned disadvantage with self-control 9, 12 or 15 to move it one step worse. Traits
added this way are marked `acquiredInPlay`, reduce the character's point value, and
may exceed the five-quirk creation limit.

## Interpretations

The book leaves these choices to the GM. The module rules as follows:

- Recovery rolls against modified Will (rows 8–11, 14–16) are not capped at 13. The cap applies to Fright Checks only.
- Row 20 states no recovery roll, so the faint ends automatically.
- Seizures set `stunned` and lying posture rather than unconsciousness.
- Stunning or fainting from other causes is cleared when the fright episode ends.
- Rerolling implausible results is the author's call: substitute any row with `rpgFrightApply(profile, total, modifiedWill)`.
- Lite combat does not yet restrict panicked or retching characters. Check `rpgFrightIncapacitated` before offering actions.
