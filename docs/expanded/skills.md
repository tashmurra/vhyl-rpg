# Expanded skills

Create `RpgExpandedSkill` definitions with an `id`, governing `attribute`,
`difficulty` (0 easy, 1 average, 2 hard, 3 very hard), optional `techLevel`,
`specialty`, `defaults` and `prerequisite`. Each default edge is `[skill, penalty]`.
Give the profile one owned `RpgExpandedTraining` per skill, containing `skill` and
`points`. `defaultFrom` explicitly selects a paid-up default basis; the engine
rejects cycles and does not treat an unpaid default chain as training.

`rpgExpandedSkillLevel` and `rpgExpandedSkillCost` expose the point table.
`profile.skillScore(skill)` combines legal trained and default scores. Optional
wildcards require `rules.wildcardSkills`; they use the very-hard difficulty and
triple cost. Character validation and learning reject purchased wildcard skills
when the campaign option is disabled. Definition validation rejects a wildcard
with any other difficulty or with attribute/skill defaults, including before a
score is requested.

`RpgExpandedPrerequisite` supports skill, trait, all and any requirements with
explicit definitions. The learning hooks also reject unsupported technology-level
access. Use `skillLearningWithTeacherReason` for advancement above personal
technology where an appropriate teacher is required; do not bypass it by writing
training points directly during play.

Techniques, optional specialties and relative-skill contexts are exposed in the
source-derived API reference. Their prerequisites and default bases must be
explicitly authored. Optional specialties are not a free extra broad skill.
Owned `RpgExpandedFamiliarity` records track equipment-type practice and recognition;
practice consumes the shared clock and recognition retains failure as well as
success. An authored equipment type is an identity, not a second inventory item.

The module supplies mechanisms for authored definitions, not a full skill catalogue.
The Town Registry's two skills are original integration examples. Source mapping:
`full-2008` B168-B175, B230-B233. See the [prerelease validation record](../releases/v1.1.0-alpha.1.md).
