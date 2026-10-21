# Abridged and expanded rules comparison

These are profiles within the same rules generation. `abridged-2004` identifies
the August 2004 reference, revision 07/12/04. `full-2008` identifies the supplied
character volume's February 2008 third printing and campaign volume's April 2008
fourth printing. Printed full-reference pages retain their B prefix. These labels
are neutral source identifiers; no private book URLs or source files are shipped.
No later corrections or supplements are silently incorporated.

| Area | Abridged profile | Full-reference difference | Expansion destination |
| --- | --- | --- | --- |
| Resolution | Three dice, success margins and contests | Additional task conditions and optional procedures (B343–B349) | Exploration |
| Secondary characteristics | Derived from basic attributes (pp. 4–6) | Independent purchases and limits (B16–B17) | Characters |
| Skills | Three difficulties and a smaller catalogue (pp. 12–17) | Fourth difficulty, paid defaults, specialties, techniques and wildcard option (B167–B233) | Skills |
| Traits | Selected benefits and restrictions (pp. 7–12) | Larger catalogues and percentage customization (B32–B166) | Traits |
| Templates | No general template subsystem | Character and ancestry composition (B258–B263; B445–B454) | Templates |
| Fear | Stun/faint duration procedure (p. 24) | Effective-score cap and separate consequence table (B360–B361) | Health |
| Range | Short table with omitted intermediate rows (p. 28) | Extended progression including seven yards (B550) | Equipment / combat |
| Combat | One-projectile strike and abridged maneuvers | Rapid fire, hit locations, grappling, critical outcomes and other special procedures (B362–B417) | Combat |
| Position | Author-supplied circumstances | Hex movement, facing and close combat (B384–B392) | Tactical |
| Health | Injury, fatigue, treatment and selected hazards | More detailed injury and exposure procedures (B418–B444) | Health / hazards |
| Advancement | Earned-point improvements (p. 17) | Study, teachers, jobs and transformations (B290–B296) | Development |
| Supernatural | Selected trait hooks | Separate spell and ability-based systems (B234–B257) | Magic / psionics |
| World interaction | Authored tasks and world facts | Creatures, vehicles, inventions, object damage, economics and world travel (B455–B522) | Remaining optional modules |

This table describes source scope, **not implemented coverage**. Consult the
[library catalogue](libraries.md) and [coverage ledger](expanded/coverage.json).
Preserving the abridged profile matters where rules differ: installing an expanded
module must not silently substitute fear tables, fill omitted range rows or change
existing random-number consumption.

The fear difference is procedural. In the abridged reference (p. 24), ordinary
failure stuns for the failure margin plus two dice of seconds; critical failure
causes fainting for the failure margin plus one die of minutes. In the full
reference (B360–B361), the initial effective score is capped at thirteen, then a
failed check triggers a separate three-dice-plus-margin table lookup. Outcomes
have their own recovery checks and can create lasting traits or attribute loss.
The [fear inventory](expanded/inventory/senses-influence-fear.json) tracks those
outcomes individually; their expanded implementation remains pending.

Some differences refine an existing procedure rather than add a new subsystem.
For example, the abridged influence text assigns a very bad reaction after failed
intimidation (p. 24), while the full text reserves that worsening for specious
intimidation (B359). This distinction needs an explicit profile-aware resolution
path and source-specific tests, not a blanket replacement of existing behavior.

A mechanical resolution and its fictional interpretation are separate. World
geometry, legal permission, a teacher's availability, motives and narrative
consequences remain explicit author inputs. That distinction must not hide an
unimplemented numeric procedure behind a generic hook.

The full reference also contains its own condensed combat appendix (B324–B328).
This is a separate source section from `abridged-2004`. For example, B326 makes
an attack roll of three inflict maximum damage without a damage roll; the detailed
critical tables use another procedure (B556–B557). The expanded implementation
must document its selection policy and test random-number consumption for each
supported choice. The [appendix inventory](expanded/inventory/condensed-combat.json)
records this distinction; it does not imply that either procedure is implemented.
