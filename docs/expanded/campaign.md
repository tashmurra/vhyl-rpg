# Expanded campaign

**Status: partial.** Campaign choices, economics, employment, legal systems and
world travel. Neutral source: `full-2008`, B347; B474; B477; B482–B483;
B486–B546 (mechanical content only).

[Library selection](../libraries.md) · [Integration](index.md) ·
[Coverage ledger](coverage.json)

Include `vhyl-rpg-expanded-campaign.t` after the expanded foundation and equipment
module. The available interface currently covers equipment legal access and uncertain control-rating decisions;
economics, employment, wider legal procedures and world travel remain pending.
The detailed source inventory contains:

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

## Equipment legal access

`RpgExpandedLegalAccess.assess()` implements the B507 comparison of item legality
class (0–4) and the relevant local control rating (0–6). Select the jurisdiction's
rating for this domain explicitly. At one or more classes above control, citizens
may carry the item; noncitizens require an authored policy. At equality, an
excluded person is blocked, and the author can require registration. One class
below requires an existing license. `licenseEligible` separately indicates a
legitimate need or government employment; eligibility alone grants no license.
Two below requires a special police, military or intelligence role. Three or more
below requires military or secret-police status.

Use `exception = 'allow'` or `'deny'` for an explicit local exception, and `'table'`
for the ordinary comparison. `legality = nil` means no assigned restriction in
this policy. Identity and institutional roles are supplied world facts, not inferred
from a character's appearance or a generic social bonus. A government employee
is not automatically a military or secret-police officer.

To gate an acquisition, set `offer.legalAccess`, and bind that policy's `subject`
and `equipment` to the exact buyer and item. The ordinary authored availability
and permission gates still apply. A blocked legal result returns its reason before
money or ownership changes. Merely including the campaign module enables no
restrictions until an author supplies a policy.

Registration fees, license applications and their variable fees, credential expiry,
trials and penalties remain pending. Uncertain enforcement decisions use the
separate interface below. The current
interface assesses supplied credentials; it does not create them or enact a legal
system merely through a callback.

The [minimal fixture](../../tests/fixtures/expanded-campaign.t) includes only the
required modules and demonstrates eligibility without permission. Authored native
cases in `tests/expanded.py::test_legal_access` cover the comparison boundaries,
registration, exclusions, institutional roles, local exceptions and acquisition
blocking with unchanged funds. `test_campaign_minimal` covers the minimal include
set. These checks are unrun while validation is paused.

## Uncertain enforcement or legality

Use an owned `RpgExpandedControlQuestion` for a particular subject and encounter
`contextId`. Set `kind` to `enforcement` or `legality`, select the applicable
`controlRating`, and set `approved` only when the author elects to resolve an
uncertain question with B506's die procedure. A known answer belongs in
`certainOutcome` and consumes no randomness; do not roll when the situation has
only one logical outcome (B507).

`assess()` is pure. Within an action, `resolve()` rolls one die and stores its
result. Below the control rating yields `intervention` or `prohibited`; above it
yields `overlooked` or `permitted`. Equality yields `encounter-required`. A repeated
call reuses the stored result. Retargeting the subject, encounter, kind or rating
after resolution is rejected. `rpgExpandedControlOutcome` exposes the pure table
comparison for authored calculations.

A tie has an explicit author contract: play the encounter or resolve its reaction,
then call `completeEncounter(outcome, evidence)` with one of the two terminal
outcomes for this question kind and a non-nil identifier for that completed
encounter. The method records the decision; it does not itself roll a reaction,
choose dialogue or invent a consequence. Repeating the same completion is a no-op;
a contradictory completion is rejected. The author remains responsible for the
specific delay, harassment, arrest or other consequence and any resulting time or
resource costs. An `intervention` outcome alone never imposes an automatic arrest.

Authored cases cover all 42 control/die combinations, legality meanings, certain
answers without randomness, stored ties, explicit completion, no repeat rolls,
retarget rejection, exception rollback and undo. See `test_control_table`,
`test_control_question` and `test_control_certain` in `tests/expanded.py`. These
checks remain unrun; reaction encounters and their concrete consequences are still
separate pending integrations.

## Starting wealth

Install one owned `RpgExpandedWealth` in `profile.contributions`. Its `wealthLevel`
selects `none`, `poor`, `struggling`, `average`, `comfortable`, `wealthy`,
`very-wealthy`, `filthy-rich` or `multimillionaire`. The last uses positive
`extraLevels`; other levels require zero. Its point cost contributes to the normal
character ledger. Combining it with another wealth contribution or a Lite wealth
trait is rejected. Spending cash does not automatically change purchased wealth.

`startingValue(campaignTL)` implements B25–B27's wealth factors and technology
values. It uses the campaign level, regardless of personal technology. The ordinary
levels range from no assets through 100 times average; each extra high-wealth
level costs another 25 points and multiplies assets by ten. Values exceeding the
signed integer money bound are rejected before multiplication. Associated employment,
status and ongoing economic effects remain pending.

An owned `RpgExpandedWealthAllocation` references the profile and its wealth
contribution. Before any equipment purchases and before `creationComplete`, use
`assess()` and then `allocate()` inside an action. The default puts 20% in the
existing money ledger and records 80% as `settledAssets` in the allocation receipt.
That property value is not another spendable bank. Set `mobile` and
`mobileApproved` for an authored exception allocating all starting assets to
movable possessions. Poverty alone does not automatically approve the exception.

Allocation requires a zero opening cash balance and empty equipment inventory.
Repeated use returns the stored allocation; another allocation for the same profile
is blocked. A committed allocation cannot be moved to a different profile or wealth
purchase. Validate the completed character with the characters module to enforce
its overall point budget; allocation does not grant permission to bypass that
budget. Actual homes, wardrobes and other settled possessions still require their
item/economic implementation, and existing-inventory reconciliation remains
unsupported rather than crediting starting funds twice.

`tests/expanded.py::test_starting_wealth` includes every technology row, wealth
factors and costs, integer limits, campaign-versus-personal technology, allocation
approval, preview purity, one-time funding, rollback and undo. These cases are
authored but unrun while validation is paused.


## Recurring income and debt

`RpgExpandedMonthlyFinance` is an owned contribution with a unique `id`, `owner`,
`wealth` contribution, `kind` (`income` or `debt`) and `levels` from 1 to 20.
Include it and its wealth contribution in the owner's `contributions`. Each income
level costs one point; each debt level contributes minus one point. Both calculate
a monthly amount of one percent of wealth-adjusted starting wealth per level
(full-2008 B26). Only one contribution of each kind is accepted. Debt cannot use
the zero-wealth tier. Payments do not buy off the disadvantage.

Create `RpgExpandedMonthlySettlement` with `finance`, a sequential `period`
starting at 1, and an explicit `due` fact. The world calendar decides when that
month is due: this module does not equate a month with thirty days or advance the
shared clock. Call pure `assess()` before committing `settle()` in an action.
Income credits the existing money balance; debt debits it. Income can accompany
job earnings, but job earnings must be credited once by their own procedure.
The contribution stores `lastPeriod` and `history`, so a second settlement object
for a settled month is a no-op. Skipped months are rejected; settle them in order.

Insufficient funds blocks payment without mutation. A deliberate debt default uses
`decision = 'default'` and a non-nil `consequence` identifying the authored creditor
encounter or other consequence record. Commit the actual world consequence within
the same action transaction. The settlement records default without inventing an
arrest, repossession or encounter. Automatic consequence execution and creditor
resolution remain unimplemented; a stored reference is not evidence that those
procedures have been completed.

The existing money ledger holds whole units. A monthly amount that requires a
fractional unit is explicitly unsupported, rather than silently rounded. Changes
to wealth during an ongoing obligation also require author review: amounts are
assessed from the currently owned wealth contribution. Calendar scheduling,
fractional currency, and obligation buyoff remain pending.

Authored `test_monthly_finance` and `test_monthly_undo` cases in `tests/expanded.py`
cover costs, amounts, due dates, duplicate receipts, defaults, funds, period gaps,
preview purity, exception rollback and undo. Checks remain paused and unrun.
