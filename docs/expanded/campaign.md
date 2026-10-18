# Expanded campaign

**Status: partial.** Campaign choices, economics, employment, legal systems and
world travel. Neutral source: `full-2008`, B347; B474; B477; B482–B483;
B486–B546 (mechanical content only).

[Library selection](../libraries.md) · [Integration](index.md) ·
[Coverage ledger](coverage.json)

Include `vhyl-rpg-expanded-campaign.t` after the expanded foundation and equipment
module. Available interfaces cover equipment legal access, uncertain control-rating
decisions, starting wealth, recurring income/debt and point-for-money exchanges.
Employment, wider economic/legal procedures and world travel remain pending.
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


## Trading points for money

`RpgExpandedMoneyExchange` implements full-2008 B26. Supply an authored `id`,
`profile`, positive `points` and explicit `permitted` fact. `assess()` is pure;
`exchange()` commits within an action. Each point yields ten percent of average
starting wealth for the campaign technology level, independent of personal wealth
and personal technology. No elapsed time or random draws are charged.

During creation, include the characters module. The exchange verifies that the
current build leaves enough unused budget, then reduces `pointBudget`. It does not
add an advantage or increase the character's value. Creation exchanges without the
characters module are explicitly unsupported. In play, it deducts `unspentPoints`
from the existing advancement bank. Earned-point history remains intact.

The profile records redeemed opportunity IDs in `moneyExchanges`; creating a second
object with the same ID cannot pay again. Use a fresh ID for an intentionally new
exchange. A claimed receipt cannot be retargeted. Insufficient points and currency
overflow are rejected before changing either balance. These exchanges do not
require downtime or a training offer; authorization is the explicit campaign choice.

For creation, allocate starting wealth before exchanging points: starting-wealth
allocation rejects an already funded opening balance. The exchange then adds to
that same balance, which can fund ordinary equipment purchases.

`tests/expanded.py::test_money_exchange` contains independent expected payouts,
creation-budget accounting, duplicate opportunities, approval/funds rejection,
preview purity, overflow, exception rollback and undo. The cases are authored and
unrun while checks are paused.


## Job qualifications and roll selection

`RpgExpandedJob` defines an authored job `id`, `prerequisites`, `rollMode` and
`rollModifier` (full-2008 B516). Each prerequisite row is
`[skill, minimum, relative]`. False/nil `relative` means an absolute minimum;
true means the minimum is relative to that skill's controlling attribute.
Every required skill must have at least one purchased point. An available default
alone cannot qualify, even if its rating meets the numeric minimum.

Jobs with prerequisite skills choose `specific`, `best` or `worst` roll mode.
`rollSkill` must identify a prerequisite for `specific`. Jobs without skill
prerequisites instead use `fixed` with `fixedScore`, or `attribute` with
`rollAttribute`. Inconsistent combinations are rejected. `assess(profile)` checks
qualifications and returns the selected rating/skill with the job modifier; it
does not roll, spend time or pay wages. Ratings below 3 cannot be attempted.

Set `requirementsApproved` only when other job requirements have been satisfied,
such as licences, guild membership, required traits or excluded traits. This is
an explicit remaining author contract, not automatic execution of those requirements.
Automatic trait prerequisites, job availability, hours, risk and monthly job rolls
still require integration before employment is complete.

`rpgExpandedTypicalJobPay(techLevel)` supplies the printed average-wealth monthly
pay table for technology levels 0–12 (full-2008 B517). Actual job pay remains an
authored economic fact; it belongs to the job's wealth tier, not the worker's.
Wealth scaling, monthly settlement and earnings-driven wealth advancement remain
pending. `tests/expanded.py::test_job_qualifications` contains expected table values,
relative skill thresholds, purchased-skill gates, and fixed/attribute roll cases.
These authored checks remain unrun while checks are paused.


## Monthly earnings assessment

`rpgExpandedJobEarnings(monthlyPay, variable, score, roll, raiseTiming)` is the pure
wage calculation from full-2008 B516. It accepts an already determined check roll;
it never consumes randomness or credits money. The result contains `check`, `money`,
`nextPay` and `consequenceRequired`.

Ordinary fixed-pay outcomes receive the normal salary even on ordinary failure.
A critical success raises the ongoing salary by ten percent. The supplied text
does not identify which month first receives that raise, so `raiseTiming` must be
`this-month` or `next-month`; an unspecified choice is blocked on that outcome.
Variable work receives normal pay on an exact success, adjusts it by ten percent
per success/failure margin, and triples the month's income on critical success
without permanently changing the underlying pay.

Critical failure returns zero pay and `consequenceRequired = true`. A settlement
must implement an explicit job consequence before recording the month as complete;
the flag alone is not an implemented demotion, dismissal, loss, accident or arrest.
A variable-pay automatic failure whose numerical margin is positive is blocked as
`job-automatic-failure-margin-unresolved`, rather than paying a success bonus for
failure. Negative-income interpretations are also explicitly unsupported.

`rpgExpandedJobPercent` calculates exact whole-unit amounts and rejects fractional
money or overflow. This preserves the existing currency precision without silently
rounding wages. Monthly commitment, permanent-raise state, critical-failure
consequences, partial months and pay scaling remain implementation work.

`tests/expanded.py::test_job_earnings` runs through the minimal campaign fixture
when checks resume. Its authored cases cover fixed/variable outcomes, both explicit
raise timings, critical failures, unresolved margin handling and arithmetic limits.
No checks have been run for this addition.


## Settling completed work months

Register `RpgExpandedEmployment` in `owner.employments`, with unique `id`, shared
`job` definition, owned `monthlyPay`, `variable`, `raiseTiming` and `failurePolicy`.
Pay changes belong to the employment, so they cannot change every worker sharing
the job definition. `RpgExpandedJobMonth` supplies sequential `month`, authored
calendar `dueAt` and `fullMonthWorked`. It rejects early dates, skipped months,
inactive employment and unqualified workers. Partial-month work is not yet supported.

`assess()` evaluates all possible roll totals without randomness to ensure every
branch has supported arithmetic and sufficient currency headroom. Unsupported
fractional wages or raise choices therefore fail before a roll is consumed.
`settle()` rolls once, credits earnings to the owner's existing money balance,
updates ongoing pay and records the month's outcome. Repeated settlement returns
`reused`, even after dismissal. The operation does not add work time: the authored
work schedule must already have charged the shared clock once.

`RpgExpandedJobFailure` requires a concrete `evidence` reference to the authored
job consequence. Supported `kind` values are `unpaid`, `demotion` and `dismissal`.
All give zero earnings for the failed month. Demotion uses `retainedPayPercent`
from 0 through 90, ensuring at least a ten-percent reduction. `lostSavings` can
add an explicit loss, provided it is affordable before the roll. Dismissal also
marks the employment inactive. Injury, arrest and other unsupported consequences
are rejected rather than approximated by unpaid work.

Each receipt records month, date, check, income, ongoing pay, savings loss and
active state. Fixed/variable pay and critical-failure changes are committed with
that receipt in the same transaction. Independent income, debt and living costs
still use their own monthly operations; integrating their chronological settlement,
work-based study, wealth advancement and real employer payments remains pending.

The authored `test_job_month`, `test_job_demotion`, `test_job_dismissal` and
`test_job_variable_month` cases cover earnings, consequences, clock ownership,
repeat protection, rollback and undo. They remain unrun while checks are paused.


## Living costs and related purchases

`rpgExpandedLivingCost(status)` returns the generic monthly table for status -2
through 8 (full-2008 B265). The author supplies the supported status, including
any organizational support: free standing from rank does not require personally
funding that rank bonus's lifestyle. Choosing a cheaper or more expensive lifestyle
does not itself change purchased status or grant social permissions.

`RpgExpandedLifestyle` takes `status` and `kind`. Available kinds are `monthly`,
`travel-month`, `lodging-day`, `breakfast`, `lunch`, `dinner`, `rations-week`,
`liquor-bottle`, `wardrobe`, `ordinary-outfit`, `winter-outfit`, `formal-outfit` and
`cosmetics-month`. `assess()` returns `money` and, where the source specifies it,
`weight` in hundredths of a pound. Wardrobe weight is a minimum (`minimumWeight`).
Unknown weights remain nil rather than being treated as weightless goods.

The default travel-month estimate is six times monthly cost; daily lodging is one
fifth. Meals, rations and liquor use their B265 percentages and cap ordinary status
pricing at 3. Single outfits also cap at 3, while complete wardrobes use full
status. `conservativeOutfit` selects the B266 conservative-clothing convention,
which the author must verify applies to that world and character; it lowers the
single-outfit cap to 2. `fashionBenefit` at status 3+ retains the full status-3 cost.
The convention cannot be applied to non-outfit purchases.

These are price assessments, not money deductions or inventory creation. Use an
acquisition for physical goods and assign authored weights where the table supplies
none. Hospitality exceptions, regional price variations and consequences of living
below status remain pending. Values beyond
the supported money range are explicitly rejected.

`tests/expanded.py::test_lifestyle_prices` covers the complete monthly table, price
percentages, weight units, status caps and clothing exceptions. These cases remain
unrun while checks are paused.


## Paying household expenses

`RpgExpandedLivingPayment` pays one full period for an explicit household. Set an
`id`, shared calendar `period` identifier, `payer`, `dueAt`, `approved`, and
`members` as `[beneficiary, supportedStatus]` pairs. Include the payer as a member
when paying their own expenses; dependents can be members without contributing
money. The period identifier must be canonical across every payer in the campaign.
Use this operation only when the campaign requires living-expense accounting.

`assess()` sums the generic monthly costs and checks approval, chronology, available
funds and prior beneficiary receipts without spending money, time or randomness.
`pay()` deducts the total from the payer's existing balance and saves each member's
period, payment ID, payer, supported status, cost and date. A repeated payment
returns `reused`; a different payer cannot pay an already covered period again.
Partly overlapping households are rejected before any deduction. Perform payment
inside the normal action transaction so exceptions and undo restore every member.

`fundedLivingStatus` records the most recently funded lifestyle. It does not change
purchased status or automatically influence an encounter. Authors still supply
calendar boundaries, organizational support and the consequences of living above
or below status. Installments, partial periods and local price overrides are not
supported by this full-period operation. It does not advance the shared clock.

The authored `test_household_payment` and `test_living_persistence` cover independent
cost totals, preview purity, repeated payment, competing payers, rollback, undo and
cross-process receipt preservation. These tests remain unrun while checks are paused.


## Employment markets and recruitment modifiers

`rpgExpandedJobWealthPay(techLevel, supportedStatus)` applies the B517 employment
wealth scale to typical monthly pay. Supported status -2 through 8 selects the
corresponding job category, from poor employment through the highest tabulated
fortune category. This is a job classification, not the worker's purchased status
or personal wealth. At technology level 8, the category supporting status 1 pays
5,200; its adjacent-level range is 4,200 to 7,200. Use explicit authored ranges at
technology endpoints rather than extrapolating unavailable levels. Fractional
currency and amounts exceeding the money limit are rejected.

`rpgExpandedEmploymentPopulation(population)` supplies the shared population
modifier for recruiting and job seeking. `rpgExpandedEmploymentAdvertising(pay,
budget, recruiting)` uses prospective monthly pay and the actual advertising
budget: recruiting starts at half a month's pay, job seeking at one twentieth.
Each subsequent bonus requires ten times the previous threshold. Whole-unit
budgets must reach the exact threshold; fractional thresholds are rounded up only
for that comparison. These helpers neither spend the budget nor consume time.

`RpgExpandedRecruitingModifiers` combines population, advertising, offered pay,
combat risk and illegality. Set `normalPay`, `offeredPay`, `advertising`,
`population`, `combatRisk`, `combatantRole` and `illegal`. Offered pay gives bonuses
at 120%, 150% and 200% of normal pay, capped at +3. An authored combatant role
avoids the obvious-combat-risk penalty. Waiving the illegal-work penalty requires
both `streetwiseSearch` and `waiveIllegalPenalty`; using that skill alone does not
silently grant the waiver.

This assessment returns a modifier only. It does not resolve a search, spend
advertising funds, create a candidate or establish employment. Weekly party-wide
attempt limits, qualification checks, repeat permission, candidate selection and
critical-failure legal consequences still require the search operation. In
particular, waiving the illegal-work penalty must not waive those consequences.

`test_employment_market` independently enumerates employment pay categories,
population boundaries, advertising thresholds, offered-pay thresholds and risk
exceptions. The minimal campaign fixture includes these cases. They remain unrun
while checks are paused.


## Assessing a job search

`RpgExpandedJob.qualifications(profile)` validates purchased prerequisite skills,
minimum scores and authored non-skill requirements independently of the monthly
performance roll. Its result includes `ratings` as `[skill, score]` pairs.
`assess(profile)` still supplies the monthly performance target. A difficult
performance roll does not itself lower the intelligence target for finding work.

`RpgExpandedJobSeekingModifiers` takes `profile`, `job`, `population`,
`monthlyPay`, `advertising`, the job's `supportedStatus`, and `simultaneousJobs`.
Its assessment combines the population and advertising modifiers with the job's
scarcity penalty and the penalty for additional simultaneous searches. Set `lazy`
only when the authored character has the relevant work-avoidance disadvantage;
the full trait catalogue does not yet supply that effect automatically.

A single prerequisite is selected automatically for overqualification. For jobs
with several prerequisites, explicitly select `qualificationSkill` from the job's
requirements. This author choice resolves which skill the employer considers;
bonuses are not summed across prerequisites. The selected skill gives +1 for
exceeding its minimum by one level, or +2 for two or more. Other helpful abilities
may supply `otherAbilityBonus` only with an `otherAbilityEvidence` reference to the
concrete authored qualification. Meeting every prerequisite is still required.

The result contains `modifier` and intelligence-based `score`; a target below
three is unavailable. Self-employment (`employerRequired = nil`) is rejected by
this employer-search procedure. Assessment does not spend advertising money or
perform the weekly roll, and `simultaneousJobs` must describe the actual search
batch rather than being independently chosen to avoid its penalty. The weekly search batch below derives the count from its rows and enforces the
interval on the character.

`test_job_seeking` covers qualification boundaries, the capped experience bonus,
scarcity, advertising, simultaneous searches, the disadvantage penalty, author
bonus evidence, and separation from monthly performance difficulty. The authored
cases remain unrun while checks are paused.


## Executing a weekly job-search batch

Create `RpgExpandedJobSearch` with a unique `id`, `profile`, `permitted` and
`searches` containing `[seekingContext, opportunity]` pairs. Each context must
belong to that profile and identify a different job ID. The batch overrides the
standalone `simultaneousJobs` setting with the actual number of rows; splitting
searches into separate objects cannot bypass the character's weekly limit.

A `RpgExpandedJobOpportunity` binds a job to an authored `employer`, `terms`,
`monthlyPay` and `available` fact. Its pay must match the search context. These
concrete employer terms are required before rolling. They describe the work that
can be found, not an automatic hiring or salary transaction. A successful result
returns the opportunity; failure returns no opportunity. Authors resolve acceptance
and subsequent employment separately. Unavailable opportunities block the request
before spending; this API does not invent an employer for an empty local market.

`assess()` validates every row and the entire advertising budget without drawing
dice or exposing successful offers. `search()` charges that total once, rolls each
IQ target in row order, and records `[job, check, opportunity-or-nil]` outcomes in
`profile.jobSearchReceipts`. Each receipt also stores the batch ID, shared-clock
time and advertising cost. A duplicate ID returns `reused` with no extra charge or
roll. The receipt remains available for the author to inspect.

The weekly limit uses seven elapsed days (604,800 seconds) from the previous
batch. A new batch at 604,799 seconds is blocked; one at 604,800 is eligible. The
operation does not itself advance time, so an authored activity schedule must
account for search activity using the shared clock. Sleeping, travel or other
activities must not charge that same elapsed interval twice. Dead or unconscious
characters cannot initiate a new batch. The transaction owns money, random state,
receipts and the attempt timestamp together; invoke it through an action.

`test_job_search_batch` covers all-row preflight, aggregate affordability,
qualification/offer binding, simultaneous-search penalties, replay protection,
rollback, undo and the interval boundary. `test_job_search_persistence` covers
receipt and random-state preservation across save/restore in separate processes.
These cases are authored and remain unrun. Recruiting candidates and calendar-week
alternatives remain unfinished integrations.


## Accepting an employment offer

Set the opportunity's `variable`, `raiseTiming` and concrete `failurePolicy` before
acceptance. `RpgExpandedEmploymentAcceptance` takes the applicant `profile`, that
`opportunity`, a unique `employmentId`, `applicantAgrees`, `employerAgrees` and
`scheduleApproved`. The schedule approval is an explicit author decision about
whether the offered work fits the character's existing commitments. It does not
reserve hours or grant simultaneous work and study credit.

The offer must appear in a successful job-search receipt for this character.
Alternatively, `directOfferEvidence` may identify an authored invitation that does
not require a search. This is a concrete world event, not a bonus or a fabricated
successful roll. Acceptance rechecks current qualifications, availability, monthly
roll selection and every possible wage outcome before creating employment.
Unsupported wage arithmetic or failure policies block acceptance.

`assess()` is pure. `accept()` adds an owned `RpgExpandedEmployment` to
`profile.employments`, copying the agreed pay, variable-pay mode, raise timing,
employer, terms and financial failure policy. The copied policy cannot be changed
by later edits to a shared offer's policy. `startedAt` and `lastMonthAt` use the
shared clock. Acceptance neither advances that clock nor awards income: completed
work is settled through `RpgExpandedJobMonth`.

The opportunity stores `acceptedEmployment` and becomes unavailable. Repeating
acceptance with the same worker and employment ID returns that record as `reused`;
a competing worker receives `employment-offer-filled`. Dismissal does not reopen
the same offer: a fresh hiring decision needs a new opportunity. Invoke acceptance
inside the normal action transaction so rollback and undo restore both vacancy
and worker state.

`test_employment_acceptance` covers discovery, preview purity, copied terms,
rollback, undo, replay and competing applicants. Its cross-process persistence
case checks the created employment and vacancy link after save/restore. Both are
authored and unrun while checks are paused. Automatic schedule planning, injury or
arrest failure effects and a full employer payroll ledger remain unfinished.


## Recruiting candidates for a party

A `RpgExpandedRecruitingParty` owns `members` and `vacancies`. Register each
`RpgExpandedRecruitingVacancy` in that party with a unique `id`. The vacancy
represents one sought hireling, so all recruiters for that position must use the
same object. Replacing an attempt or switching party members cannot reset its
weekly interval. Distinct vacancies can be searched independently.

`RpgExpandedRecruitingAttempt` supplies an `id`, `vacancy`, `recruiter`,
`permitted`, a `RpgLiteContext` of kind `recruiting`, and the recruiting `modifiers`.
The context uses intelligence unless an appropriate skill is explicitly selected;
a skill choice requires `skillEvidence` explaining its relevance to this search.
The normal context arithmetic applies before adding recruiting modifiers. An
illegal-work penalty waiver also requires `streetwiseSkill` to match the actual
selected skill, rather than merely setting a modifier flag.

Before attempting, supply the concrete `candidate`, `candidateAvailable` and
`candidateEvidence` describing the person who could be found. A successful roll
presents that candidate; it never transfers control of the NPC or automatically
hires them. The vacancy's `pendingCandidate` prevents further searches while that
interview is unresolved. `decline(candidate, evidence)` records an explicit refusal
and clears the pending interview without resetting the weekly clock. A subsequent
attempt requires `repeatApproved`, reflecting authored availability. Hiring and
closing the vacancy use the acceptance integration described below.

`assess()` validates the entire attempt, budget and possible legal consequence
without revealing a candidate result. `search()` spends advertising once, rolls
once, and records the recruiter, time, check, presented candidate, advertising cost
and fine. Duplicate attempt IDs return `reused`. New attempts are permitted after
seven elapsed days, including when a different party member pays. Search does not
advance the shared clock; the activity schedule accounts for elapsed time.

Illegal recruitment requires a `RpgExpandedRecruitingFine` with an authored
`authority`, concrete `evidence`, a distinct `recipient` profile and positive
`amount`. This policy specifically chooses a financial sanction for the source's
open-ended legal-complication branch. Before rolling, the recruiter must be able
to fund both advertising and the possible fine, and the recipient must have money
capacity. Critical failure transfers the fine even if the search's illegal-work
penalty was waived. Arrest and other sanctions are unsupported by this policy;
they must not be replaced with an arbitrary fine just to permit execution.

All mutations belong in the normal action transaction. The authored
`test_recruiting_search` covers preview privacy, rollback, undo, duplicate requests,
interviews, switching recruiters and the weekly boundary. The authored
`test_recruiting_legal_consequence` covers the critical-failure transfer and rollback.
These cases remain unrun. Recruitment in settings with additional labor-market
rules and nonfinancial sanctions remain incomplete.


## Hiring a presented candidate

To use employment acceptance after recruiting, set its `recruitingVacancy` and
set the opportunity's `employer` to that vacancy's party object. The worker must
be the current `pendingCandidate`, backed by a successful attempt receipt. The
vacancy must remain open and unfilled. A direct-offer evidence reference does not
bypass these checks when a recruiting vacancy is supplied.

The ordinary acceptance requirements still apply: both parties agree to the
terms, the schedule is approved, and the candidate meets the job's actual
qualifications. A successful interview alone supplies no skills, attributes or
qualification exceptions. Use an authored job definition appropriate to the
position and pay actually agreed with the candidate.

Acceptance commits the worker's employment, the opportunity's filled state and
the vacancy's `hiredEmployment` together, then closes the vacancy and clears the
pending interview. It leaves `party.members` unchanged: employment does not give
the hireling the party members' authority to recruit. NPC decisions and any
social-module loyalty record remain independently authored. No wage is paid at
hiring; monthly work settlement remains the income operation.

`test_hire_candidate` covers pre-interview rejection, successful hiring, preview
purity, rollback, undo, replay and closed-vacancy protection. Its persistence case
checks that the owned employment and vacancy link survive cross-process save and
restore. These cases remain unrun. Coordinated work schedules and automatic loyalty initialization remain separate
integration work.


## Funding wages from an employer account

Set `opportunity.payer` to the actual profile whose money funds wages before
accepting the offer. Acceptance copies that payer into the owned employment.
The payer must differ from the worker. With no payer, the existing external-economy
income behavior remains available; do not also debit another account manually
when a payer is configured.

Monthly settlement validates the payer and requires enough money for every
possible wage result before rolling. On commit, it deducts precisely the earned
amount from the payer and credits the worker in the same transaction as the
month's receipt. Failed-month savings losses remain the separate, explicitly
authored consequence; they are not automatically awarded to the employer.
A repeated month cannot debit the payer again. No money moves when hiring, so the
author must arrange funding by the date the month's settlement becomes due.

`test_hire_payroll` covers the complete recruit/hire/pay sequence, conserved wages,
rollback, undo and repeat protection. `test_hire_payroll_unfunded` checks that an
unaffordable payroll is blocked without consuming randomness or crediting wages.
These cases remain unrun. Partial wages, unpaid wage obligations and employer
insolvency require explicit future procedures rather than silent partial payment.

## Purchasing improved wealth

`RpgExpandedWealthAdvancement` implements the purchased increase in `full-2008`
B291. Bind it to a profile and that profile's installed `RpgExpandedWealth`, give
it a unique opportunity `id`, and choose `targetLevel` and `targetExtraLevels`.
Set `permitted` only after approving the in-play justification. Set
`obligationsSettled` and a nonempty `evidence` reference after resolving applicable
taxes, bribes and similar payments through the campaign's money operations.
These fields do not calculate or waive those payments.

`assess()` reports the point difference and target starting-wealth threshold.
It blocks unfinished creation, unapproved or unsettled requests, decreases,
insufficient current money and insufficient unspent advancement points. `advance()`
must run inside the usual action transaction. It spends only the point difference,
updates the existing wealth contribution and development revision, and retains an
owned receipt in `profile.wealthAdvancements`. The qualifying money remains in
the existing account; the operation neither spends it nor grants starting wealth
again. Repeating the receipt spends nothing. A different receipt with the same
opportunity ID is rejected, as is retargeting a committed receipt.

The current threshold uses the existing money balance. Non-cash property does not
automatically qualify as money, and this API does not sell assets or decide taxes.
Compulsory advancement associated with sustained higher-level employment remains
separate work. `test_wealth_advancement` covers the threshold, point cost, rejection
paths, preview purity, rollback, undo and repeat protection. These authored cases
have not run while build checks are paused; cross-process continuation is still
pending for this operation.
