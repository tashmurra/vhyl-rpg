# Expanded traits

The [trait inventory](inventory/traits-foundation.json) begins the detailed
catalogue pass at B32–B37. It records categories, origins, activation, potential
purchases and the initial ability definitions. The existing pricing helper does
not implement these effects; their coverage remains pending.

Abilities need explicit permanent, switchable or attack behavior. A switchable
ability ordinarily changes immediately through a ready action and defaults on
during unconsciousness; an attack ability only acts through its attack procedure.
Mental and physical traits also follow different owners during body transfer,
while social identity requires a concrete campaign policy.

Potential purchases reserve character value without creating a freely spendable
point balance. Revelation, fulfillment and remaining payment have different rules
for inheritance, emergent abilities and secret traits. Hidden abilities must not
leak through preview or public accounting reports.

Condition attacks require actual resistance, effect phases, recovery and expiry.
Temporary attribute penalties have specific derived-stat exceptions. Repeated
effects normally use the worst severity; only eligible enhanced definitions can
stack. Suppression must restore the affected contribution without undoing unrelated
advancement or injuries that occurred during the effect.

Companion pricing is separate from companion agency and appearance. Adventure-level
appearance checks, invested replacement value, betrayal consequences and growth
need owned relationship records. The following catalogue pages and special
modifiers still need review before the companion definition is complete.

The [second catalogue segment](inventory/traits-catalogue-b.json) adds companion
modifiers and abilities through B42. Summoning reuses an existing companion and
retains failed-attempt deadlines. Shared-fate effects need propagation identities
to prevent cycles. Companion-granted powers retain their purchases while the link
is unavailable, rather than being deleted and repurchased.

Arm-specific attributes affect only eligible tasks and use different combination
rules for multiple hands. Accelerated subjective time adds maneuvers without
changing initiative and still respects actions that depend on another actor's
reaction. Neither feature can be represented by a blanket attribute or speed bonus.

Restraint powers own their strength, layers, damage, escape progress and retry
restrictions. Remote perception owns a viewpoint and displaced senses, while
ordinary ability ranges still originate at the body. Hidden impressions and
failed viewpoint placement require specific author contracts without revealing
private world facts through assessment. These effects remain unimplemented.

The [third catalogue segment](inventory/traits-catalogue-c.json) adds mental
compartments, contacts and protection modifiers. Mental compartments can act and
receive influence independently, but share one body and its physical limits.
Vehicle control stations likewise grant operator access without creating extra
weapons or movement capacity.

Contact availability belongs to the contact, including when several characters
share that person. Question penalties, research delays, reliability and private
information need persistent records. An abstract information score must not
silently replace the contact's actual character skills.

Protection layers retain fixed order, coverage, attack restrictions, depletion
and recovery. Absorbed damage creates temporary capability investment rather
than advancement points. Reflection applies to eligible direct hits only and
must not combine with absorption. These effects need integrated damage tests;
the existing trait-cost helper supplies none of this runtime behavior.

**Status: partial.** Trait catalogues, modifiers, benefits and restrictions. Neutral source: `full-2008`, B32-B166.

[Library selection](../libraries.md) · [Integration](index.md) · [Coverage ledger](coverage.json)

## Available interfaces

- `rpgExpandedModifiedCost` — B101; tested in `tests/expanded.py::test_numbers`.

The module provides only these interfaces. Its full catalogue and remaining chapter procedures are not implemented. See the integration guide for restrictions.


The [fourth catalogue segment](inventory/traits-catalogue-d.json) records detection,
respiration and nutrition exceptions, controlled infection, duplication, memory,
empathic impressions and cinematic defense purchases. These remain pending effects.
Detection and empathic impressions need separate private evidence and public output:
a pure assessment must not reveal that a hidden target exists or whether an
impression is truthful. Retry deadlines belong to the character's observation
history, so constructing a fresh action cannot reset a failed memorization attempt.

Duplication requires separately owned bodies connected to one character origin.
Ordinary merging averages current health and fatigue; shared reserves instead
conserve allocations and add them on reunion. Copied signature equipment needs
origin records even after transfer or dropping, because merging removes those
copies. Copy deaths, replacement purchases and optional extra lives must use one
advancement ledger. Rounding, absent participants and secondary death propagation
remain explicit source decisions, not implemented behavior.

Respiration exceptions are specific: independence from oxygen does not protect
against contact toxins, pressure or vacuum. Reduced respiration variants can
still require environmental oxygen or a finite reserve. Nutrition and sleep
independence do not grant arbitrary recovery. Infectious control likewise separates
infection, delayed transformation, purchased companion control and later release;
insufficient advancement points cannot prevent an otherwise valid infection.


The [fifth catalogue segment](inventory/traits-catalogue-e.json) distinguishes top
speed from basic movement, and faster perception from extra actions. Additional
arms, heads and mouths have separate occupancy and injury consequences. They do
not automatically grant attacks, spell actions or mental compartments. All-out
attack and rapid-strike allocations must share the existing turn ledger.

Replacement lives need a durable consumption record even when restoring an older
character snapshot. Backup location, preparation duration, permitted tampering and
body acquisition require explicit authored decisions. Favors likewise retain
adventure-level retry restrictions and can be consumed only once per successful
call, subject to their specified exceptional roll.

Fitness changes recovery according to fatigue cause. Exertion and supernatural
power costs must retain their provenance within one fatigue ledger, including
when both occur between rest periods. Fractional loss rates cannot be rounded
independently for every newly constructed action. These capabilities remain
inventory requirements and are not provided by the current trait pricing helper.


The [sixth catalogue segment](inventory/traits-catalogue-f.json) records flexibility,
flight variants, contingency equipment, growth, restorative touch and scoped
bonuses. Flight mode is part of the capability definition: powered flight,
gliding and reaction-mass space travel use different movement and reserve rules.
Neither flight nor greater size automatically supplies environmental protection,
strength or resized equipment. These definitions remain pending implementation.

Contingency equipment requires a session allowance and explicit item eligibility.
An existing owned item must retain its identity when revealed. Improvised devices
also need materials, skill resolution and a committed failed-use cost. Growth
requires separate supporting strength and checks against actual surrounding
space, with timed barrier penetration when eligible.


The [seventh catalogue segment](inventory/traits-catalogue-g.json) covers sensory
bands, injury anatomy, damaging powers, alternate attacks, phasing and invisibility.
Anatomical protections compose through explicit included traits and incompatible
body forms. A purchased attack retains damage type, delivery and exact fractional
dice pricing; an alternate family also owns shared failure and suppression state.

Phasing needs region-level material state, barrier eligibility, respiration and
carried-object transitions. Invisibility needs observer and sensing-domain checks,
with separate evidence for sound, tracks, shadows and reflection. Neither is a
single universal immunity flag. Intuitive guidance also retains a question identity
and bounded authored outputs so repeated previews cannot reveal hidden answers.
All of these effects remain pending implementation and validation.


The [eighth catalogue segment](inventory/traits-catalogue-h.json) records innate
travel, legal permissions, real-play rerolls, magical aptitude and mental effects.
Real-play cooldowns need an explicit clock policy and roll-event window; advancing
the fictional clock cannot refresh them. A reroll must replace the selected result
before its consequences are committed, including when the roll remains private.

Mental command, conditioning, probing and thought reading have different subject
histories, expiry rules and output contracts. A question identity must survive
rephrasing; a new action object cannot bypass a subject cooldown. A mental shield
also retains its voluntary state while unconscious. These effects are pending,
and the rapport continuation is now recorded in the ninth segment.


The [ninth catalogue segment](inventory/traits-catalogue-i.json) completes the
rapport text and adds temporary ability pools, patrons, payload and consciousness
transfer. Pool assignments own temporary contributions; reallocating capacity
must not refund permanent advancement or retain removed capabilities. Borrowed
powers similarly retain their source, modifiers and expiry.

Body transfer separates the acting mind, physical host, suppressed occupant and
original body. Host attributes and relative physical skills change while mental
traits persist. Failed transfers can create permanent subject immunity. Memory
attempts, purchased return access and remote-control termination need persistent
records. The module remains incomplete; these are implementation obligations.


The [tenth catalogue segment](inventory/traits-catalogue-j.json) adds foresight,
ancestral and object histories, recovery, active sensors and shadow form. Sensors
retain their own range, emission visibility, environmental limits and detail
outputs. A targeting lock is distinct from discovery, and switching sensor modes
must not accumulate bonuses from incompatible modes. These effects remain pending.


The [eleventh catalogue segment](inventory/traits-catalogue-k.json) records fixed
and adaptive transformations, shrinking, protected equipment, parallel item
acquisition and natural appendages. Shrinking scales different quantities from
stretching, and each full-value exception applies only to its selected quantity.
Acquired items retain origin, expiry and retry-family records; transferred or
consumed items must not evade their return rule. These effects remain pending.
