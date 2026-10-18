# Expanded campaign

**Status: pending.** Campaign choices, economics, employment, legal systems and
world travel. Neutral source: `full-2008`, B347; B474; B477; B482–B483;
B486–B546 (mechanical content only).

[Library selection](../libraries.md) · [Integration](index.md) ·
[Coverage ledger](coverage.json)

This module has not been implemented. Its proposed filename,
`vhyl-rpg-expanded-campaign.t`, is reserved in the catalogue; do not include it in
a game yet. The detailed source inventory now contains:

- [Campaign procedures](inventory/campaign-procedures.json): profile choices,
  knowledge, time, reactions, awards, mapping and encounters.
- [Economics and employment](inventory/economy-employment.json): trade, crafting,
  jobs, recruitment, loyalty and their numeric tables.
- [Worlds, law and technology](inventory/worlds-law-technology.json): jurisdiction,
  trials, technology contexts, availability guidance and travel contracts.

These are first-pass requirements. Reaction outcome tables, cross-references, numeric audits and executable
validation remain open. The [world-transit ledger](inventory/world-transit.json)
now records the detailed hardware-assisted transit, accident, portal and world-shift
procedures. A [separate setting-content pass](inventory/setting-mechanics.json)
records the remaining pages' reusable rules and explicit exclusions. A complete
second-pass audit remains necessary; the first pass does not prove full coverage.
Storytelling advice, quoted fiction and example settings are excluded; their presence
in the reference does not imply a missing runtime feature.

## Campaign choices and world state

A campaign explicitly selects optional rules, character budgets and world parameters.
A high point budget does not activate cinematic rules. Required templates, staged
creation budgets, category allocations and attribute limits need distinct validation
policies. Current library inclusion must only make capabilities available.

World records identify physical conditions, cultures, languages, technology by field,
available equipment and permitted abilities. Personal technology, imported equipment
familiarity and native production capability are different facts. A society familiar
with an imported device does not automatically know how to repair or manufacture it.
Divergent technology also needs a path identity, not just a numeric level.

Knowledge remains separate from world truth. An author can specify a hidden fact,
randomly determine it through an explicit procedure or reveal it after an action.
Preview must not reveal private reactions, unidentified technology or an adversary's
unobserved information. Once generated, incidental statistics and encounter facts
must persist rather than changing every time they are queried.

## Time and advancement

Combat, scenes, travel and downtime advance one game clock. A session paused in
mid-encounter does not advance because real time passes. Time skips must process
ongoing studies, jobs, treatments, maintenance and spells at their actual boundaries,
without charging elapsed time again through each subsystem.

The optional real-time conversion paragraph at B498 describes its ratio in
inconsistent directions. The future API must require explicit game-time and real-time
units and document the selected interpretation. It must not infer a silent default
from that paragraph.

Session and story-completion awards are separately identified events. The dependent
restriction, outside-rescue exception and direct trait/skill awards require their own
eligibility and accounting. Suggested award amounts remain author choices. Work-based
study uses one-quarter of actual work time; it does not reserve a second overlapping
workday.

The [task-resolution inventory](inventory/task-resolution.json) also assigns optional
point-funded outcome changes and scene additions to this module. Both require explicit
campaign choices and the ordinary advancement bank. Accepted scene additions become
persistent world facts, not an unrecorded callback result.

## Employment and trade

A job specifies prerequisites, schedule, risk, pay and the exact monthly roll.
Prerequisite skills need purchased investment; an adequate default is insufficient.
Fixed salaries and variable income have different success procedures, and a permanent
raise differs from a one-month windfall. Partial months and unusually large failed
income margins need explicit treatment before execution is supported.

Pay follows the job's wealth category, not the employee's personal wealth. Living
expenses and noncontributing dependents use the same currency accounts as purchases.
Required wealth advancement must not fabricate character points or create a second
balance representing money already held elsewhere.

Recruitment produces a candidate, followed by a hiring decision. Party-wide weekly
search limits cannot be bypassed by constructing a new search object or changing the
recruiter. Job-seeker and recruiter advertising have different price thresholds.
Hirelings remain independent characters with private loyalty, dated modifiers and
service anniversaries. Extra-pay loyalty lasts a month after that pay stops.

Purchases and sales validate ownership, availability, permissions, transport and funds
together. Foreign currency is valued as a local commodity. Crafting requires an actual
authored recipe, time, skills and failure effects; the suggested materials percentage
does not supply all of those requirements.

## Jurisdictions and travel

Legality classes interact with the applicable local control rating, which may differ
by domain. Known laws do not reroll whenever queried. Registration, licenses, access
restrictions and criminal records need explicit state. Trials distinguish procedural
arrest defects, a judge's reaction, adversarial contests and physical ordeals. Sentences
are authored consequences applied through the appropriate currency, time, social or
health systems.

Routes between worlds declare eligibility, duration, clock relationships, payload,
return access and the actual travel ability or device. Physical transit moves the same
body and permitted inventory atomically. Projection retains an exposed body at its
origin and a defined projected form; it cannot create duplicate spendable resources.
World-context changes must reject unsupported combinations before committing arrival.

## Detailed transit requirements

The optional hardware-assisted travel model distinguishes a capsule's own generator
from an external projector. Every unassisted capsule stays within its current transit
band. Longer trips require the matching generator and projector; two-band trips also
need an actual open window. Hourly predictions can schedule a one-hour window four
hours later, and only the projector has the instruments to predict it. A passenger
preview must not expose that private prediction without communication.

Rated capacity includes the complete capsule and payload. Pulse energy depends on
rated capacity, while calibration depends on actual mass and local conditions. A
charged pulse bank, known origin and destination coordinates, a course for the actual
launch point and a valid calibration are separate eligibility requirements. Being
ready for retrieval does not make a projector appear or guarantee that its scheduled
pickup will occur.

Transit accidents use both operators' failed margins where applicable. Their outcomes
can damage equipment, alter location, prevent retrieval or cause a time delay. Outside
elapsed time and passenger-experienced time must be recorded separately. Further
results can combine, so resource loss, damage, displacement and arrival cannot each
be committed as unrelated operations that leave half a transit behind on failure.

The supplied accident text leaves details requiring an explicit implementation policy:
the dice/modifiers for compound rerolls, recovery from temporary electronic disruption,
and what a duplicated living shipment means. These remain pending. A generic author
callback does not settle them; each needs a documented input/output contract and
independent tests. Named source worlds and organizations are excluded.

Natural portals are distinct from capsule travel. They can be one-way, periodic,
keyed, summoned, variable or hidden, with specific visibility and discovery rules.
A shifting region can move terrain and its occupants. A changed world band can strand
a working capsule, while a magic-free world can prevent a magical return. These cases
must resolve through the actual route and world context rather than a universal
return-to-origin action.

The setting-content pass adds method-specific world restrictions: a destination
can forbid unassisted entry and exit while permitting assisted travel, or admit
travelers but block particular return methods. An institution's access permission
cannot override those physical restrictions. Conversely, working hardware does
not grant permission to enter a legally closed world.

The source also describes some group-assisted travel without enough procedure to
implement it. Its stated carrying capacity alone is insufficient: eligibility,
ability construction, activation and costs remain required author inputs. Such a
capability remains pending, rather than becoming a free generic party-transport rule.

## Required validation

Independent cases must cover all pay, population, wealth, control and legality rows;
job and recruitment advertising; monthly and annual boundaries; dated loyalty;
prerequisite investment; trial ties; and cross-world permissions. Shared-operation
fixtures must verify parser, structured-action and dialogue parity.

Preview purity, deterministic replay, rollback, undo and save continuation must cover
employment, recruitment, transit, private knowledge and long downtime intervals.
Build checks remain suspended during implementation. These inventories and authoring
requirements are not evidence of completed runtime behavior.


[Innate travel and fictional legal permissions](inventory/traits-catalogue-h.json)
need specific author contracts. Travel distinguishes same-location arrival safety
from other hazards, memorized worlds from unknown destinations, ordinary passengers
from following travelers, and combined teleport/travel partial successes. Artifact
attempts and temporary portals retain identities and expiry. Legal authority and
exemptions use authored jurisdictions, duties and sanctions; the source's game
models are not descriptions of current real-world law. These effects remain pending.
