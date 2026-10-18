/* Include after the expanded foundation. Source: full-2008, B170, B173, B175, B230. */

/** Authored expanded skill. Defaults are explicit [skill, penalty] pairs.
 * A catalogue is not implied by this definition type. */
class RpgExpandedSkill: RpgLiteSkill
    defaults = []
    wildcard = nil
    prerequisite = nil
    optionalParent = nil
    optionalApproved = nil
    maximumDifficulty() { return 3; }
;

/** Owned investment. defaultFrom explicitly selects a paid-up default basis. */
class RpgExpandedTraining: RpgTraining
    defaultFrom = nil
;

/** Locate a unique training slot without creating or changing one. */
rpgExpandedTrainingFor(profile, skill)
{
    local found = nil;
    foreach (local training in profile.skills)
        if (training.skill == skill)
        {
            if (found != nil) rpgExpandedReject('duplicate-training');
            found = training;
        }
    return found;
}

/** Point cost of a relative skill level; levels below the table cost zero. */
rpgExpandedSkillCost(difficulty, relative, wildcard)
{
    rpgInteger(difficulty, 0, 3); rpgInteger(relative, -1000, 1000);
    if (wildcard && difficulty != 3) rpgExpandedReject('wildcard-difficulty');
    local row = relative + difficulty;
    local cost = row < 0 ? 0 : row == 0 ? 1 : row == 1 ? 2 : (row - 1) * 4;
    return cost * (wildcard ? 3 : 1);
}

/** Trained level from points; nil means no purchased level. */
rpgExpandedSkillLevel(attribute, difficulty, points, wildcard)
{
    rpgInteger(attribute, 1, 1000); rpgInteger(difficulty, 0, 3);
    rpgInteger(points, 0, 1000000);
    if (wildcard && difficulty != 3) rpgExpandedReject('wildcard-difficulty');
    if (wildcard) points /= 3;
    if (points == 0) return nil;
    local relative = points >= 4 ? 2 + (points - 4) / 4 : points >= 2 ? 1 : 0;
    return attribute + relative - difficulty;
}

/** Paid level only. Unpaid default chains never become training. */
rpgExpandedPaidSkill(profile, skill, visited)
{
    if (holds(visited, skill)) rpgExpandedReject('cyclic-paid-default');
    rpgExpandedValidateSkill(skill);
    local training = rpgExpandedTrainingFor(profile, skill);
    if (training == nil || training.points == 0) return nil;
    local wildcard = skill.ofKind(RpgExpandedSkill) && skill.wildcard;
    if (wildcard && !profile.rules.wildcardSkills) rpgExpandedReject('wildcard-disabled');
    local base = profile.attributeScore(skill.attribute); local credit = 0;
    if (training.ofKind(RpgExpandedTraining) && training.defaultFrom != nil)
    {
        if (!skill.ofKind(RpgExpandedSkill) || wildcard) rpgExpandedReject('invalid-paid-default');
        local penalty = nil;
        foreach (local pair in rpgExpandedDefaultEdges(profile, skill))
            if (pair[1] == training.defaultFrom && (penalty == nil || pair[2] > penalty)) penalty = pair[2];
        if (penalty == nil) rpgExpandedReject('missing-paid-default');
        local source = rpgExpandedPaidSkill(profile, training.defaultFrom, visited + [skill]);
        if (source == nil) rpgExpandedReject('untrained-paid-default');
        credit = rpgExpandedSkillCost(skill.difficulty, source + penalty - base, nil);
    }
    return rpgExpandedSkillLevel(base, skill.difficulty, training.points + credit, wildcard);
}

/** Best purchased or legal default level. No chained untrained defaults. */
rpgExpandedSkillScore(profile, skill)
{
    rpgExpandedValidate(profile);
    rpgExpandedValidateSkill(skill);
    if (skill.ofKind(RpgExpandedSkill) && skill.wildcard)
    {
        if (!profile.rules.wildcardSkills) rpgExpandedReject('wildcard-disabled');
        if (skill.defaultPenalty != nil || skill.defaults.length() != 0)
            rpgExpandedReject('wildcard-default');
    }
    local score = rpgExpandedPaidSkill(profile, skill, []);
    if (skill.techLevel != nil && skill.techLevel > profile.techLevel && score == nil) return nil;
    if (profile.familiarSkills != nil && !holds(profile.familiarSkills, skill) && score == nil) return nil;
    if (skill.defaultPenalty != nil)
    {
        local which = skill.defaultAttribute == nil ? skill.attribute : skill.defaultAttribute;
        local base = profile.attributeScore(which);
        local candidate = (base > 20 ? 20 : base) + skill.defaultPenalty;
        if (score == nil || candidate > score) score = candidate;
    }
    if (skill.ofKind(RpgExpandedSkill))
        foreach (local pair in rpgExpandedDefaultEdges(profile, skill))
        {
            if (pair.length() != 2 || pair[1] == skill) rpgExpandedReject('invalid-skill-default');
            rpgInteger(pair[2], -100, 0);
            local source = rpgExpandedPaidSkill(profile, pair[1], [skill]);
            if (source != nil && (score == nil || source + pair[2] > score)) score = source + pair[2];
        }
    return score;
}

modify RpgExpandedProfile
    skillScore(skill)
    {
        if (skill.ofKind(RpgExpandedSkill)) return rpgExpandedSkillScore(self, skill);
        return inherited(skill);
    }
;

/** Owned technique investment. Select exactly one default basis. Caps are
 * relative to that basis; nil maximumAboveSkill explicitly means uncapped. */
class RpgExpandedTechnique: RpgExpandedContribution
    skill = nil
    attribute = nil
    parentTechnique = nil
    penalty = 0
    maximumAboveSkill = 0
    hard = nil
    points = 0
    amounts(profile) { return [self.points]; }
    validate(profile) { return self.validateChain(profile, []); }
    validateChain(profile, visited)
    {
        if (holds(visited, self)) rpgExpandedReject('cyclic-technique-default');
        if (self.owner != profile) rpgExpandedReject('technique-ownership');
        local bases = (self.skill != nil ? 1 : 0)
            + (self.attribute != nil ? 1 : 0) + (self.parentTechnique != nil ? 1 : 0);
        if (bases != 1) rpgExpandedReject('technique-default-basis');
        rpgInteger(self.penalty, -100, 0);
        if (self.maximumAboveSkill != nil) rpgInteger(self.maximumAboveSkill, 0, 100);
        rpgInteger(self.points, 0, 1000000);
        if (self.skill != nil)
        {
            local training = rpgExpandedTrainingFor(profile, self.skill);
            if (training == nil || training.points < 1) rpgExpandedReject('technique-prerequisite');
        }
        if (self.attribute != nil) profile.attributeScore(self.attribute);
        if (self.parentTechnique != nil)
        {
            if (!self.parentTechnique.ofKind(RpgExpandedTechnique))
                rpgExpandedReject('technique-default-basis');
            self.parentTechnique.validateChain(profile, visited + [self]);
        }
        if (self.maximumAboveSkill != nil
            && self.points > self.maximumAboveSkill - self.penalty + (self.hard ? 1 : 0))
            rpgExpandedReject('technique-cap');
        return nil;
    }
    score()
    {
        rpgExpandedValidate(self.owner);
        self.validate(self.owner);
        return self.resolvedScore();
    }
    /* Internal recursion after the complete default graph has been validated. */
    resolvedScore()
    {
        local base = self.parentTechnique != nil ? self.parentTechnique.resolvedScore()
            : self.attribute != nil ? self.owner.attributeScore(self.attribute)
            : self.owner.skillScore(self.skill);
        if (base == nil) rpgExpandedReject('technique-prerequisite');
        local improvement = self.points - (self.hard && self.points > 0 ? 1 : 0);
        return base + self.penalty + improvement;
    }
;

/** Declarative learning requirement, B169. A skill leaf requires purchased
 * training; its optional minimum is a paid level, never an untrained default.
 * Trait leaves describe possession, not whether a power is currently active. */
class RpgExpandedPrerequisite: object
    kind = 'skill'
    skill = nil
    minimum = nil
    traitId = nil
    traitLevel = 1
    children = []
    satisfied(profile, visited)
    {
        if (holds(visited, self)) rpgExpandedReject('cyclic-prerequisite');
        if (self.kind == 'all' || self.kind == 'any')
        {
            if (self.children.length() == 0) rpgExpandedReject('empty-prerequisite');
            local all = true; local any = nil;
            foreach (local child in self.children)
            {
                if (!child.ofKind(RpgExpandedPrerequisite)) rpgExpandedReject('invalid-prerequisite');
                local matches = child.satisfied(profile, visited + [self]);
                if (matches) any = true; else all = nil;
            }
            return self.kind == 'all' ? all : any;
        }
        if (self.kind == 'skill')
        {
            if (self.skill == nil || !self.skill.ofKind(RpgSkill))
                rpgExpandedReject('invalid-prerequisite');
            if (self.minimum != nil) rpgInteger(self.minimum, 1, 1000);
            local training = rpgExpandedTrainingFor(profile, self.skill);
            if (training == nil || training.points < 1) return nil;
            if (self.minimum == nil) return true;
            local score = rpgExpandedPaidSkill(profile, self.skill, []);
            return score != nil && score >= self.minimum;
        }
        if (self.kind == 'trait')
        {
            if (self.traitId == nil) rpgExpandedReject('invalid-prerequisite');
            rpgInteger(self.traitLevel, 1, 1000);
            local trait = profile.trait(self.traitId);
            return trait != nil && trait.level >= self.traitLevel;
        }
        rpgExpandedReject('invalid-prerequisite');
    }
;

modify RpgExpandedProfile
    skillLearningReason(skill)
    {
        rpgExpandedValidateSkill(skill);
        if (skill.ofKind(RpgLiteSkill) && skill.techLevel != nil)
        {
            rpgInteger(skill.techLevel, 0, 12); rpgInteger(self.techLevel, 0, 12);
            if (self.iq < 6) return 'technology-learning-cognition';
            if (skill.techLevel > self.techLevel)
            {
                if (!self.creationComplete) return 'technology-starting-access';
                if (skill.attribute == rpgIQ) return 'technology-personal-level';
            }
        }
        if (!skill.ofKind(RpgExpandedSkill) || skill.prerequisite == nil) return nil;
        if (!skill.prerequisite.ofKind(RpgExpandedPrerequisite))
            rpgExpandedReject('invalid-prerequisite');
        return skill.prerequisite.satisfied(self, []) ? nil : 'skill-prerequisite';
    }
    skillLearningWithTeacherReason(skill, teacher)
    {
        local reason = self.skillLearningReason(skill);
        if (reason != nil) return reason;
        if (!skill.ofKind(RpgLiteSkill) || skill.techLevel == nil || skill.techLevel <= self.techLevel)
            return nil;
        if (teacher == nil || !teacher.ofKind(RpgProfile) || teacher == self)
            return 'technology-teacher-required';
        local training = rpgExpandedTrainingFor(teacher, skill);
        if (training == nil || training.points < 1 || teacher.skillScore(skill) == nil)
            return 'technology-teacher-subject';
        return nil;
    }
;

modify RpgExpandedProfile
    familiarities = []
    validateFeatures()
    {
        inherited();
        local specialties = [];
        foreach (local training in self.skills)
        {
            local skill = training.skill; rpgExpandedValidateSkill(skill);
            if (skill.ofKind(RpgExpandedSkill) && skill.optionalParent != nil)
            {
                foreach (local other in specialties)
                    if (other.optionalParent == skill.optionalParent && other.specialty == skill.specialty)
                        rpgExpandedReject('duplicate-optional-specialty');
                specialties = specialties + [skill];
            }
        }
        foreach (local entry in self.familiarities)
        {
            if (!entry.ofKind(RpgExpandedFamiliarity) || entry.owner != self)
                rpgExpandedReject('familiarity-ownership');
            entry.validate();
        }
        return nil;
    }
;

/** One owned skill/equipment-type familiarity, B169. A type is an authored
 * identity shared by equivalent models, not necessarily one inventory object. */
class RpgExpandedFamiliarity: object
    owner = nil
    skill = nil
    equipmentType = nil
    initial = nil
    requiredSeconds = 28800
    penalty = -2
    practicedSeconds = 0
    recognized = nil
    recognitionAttempted = nil
    recognitionCheck = nil
    practiceOwner = nil
    practiceSkill = nil
    practiceType = nil
    available = nil
    validate()
    {
        if (self.owner == nil || !self.owner.ofKind(RpgExpandedProfile)
            || !holds(self.owner.familiarities, self) || self.skill == nil
            || !self.skill.ofKind(RpgSkill) || self.equipmentType == nil)
            rpgExpandedReject('familiarity-ownership');
        rpgInteger(self.requiredSeconds, 1, 1000000);
        rpgInteger(self.practicedSeconds, 0, self.requiredSeconds);
        rpgInteger(self.penalty, -100, 0);
        if (self.practiceOwner != nil && (self.owner != self.practiceOwner
            || self.skill != self.practiceSkill || self.equipmentType != self.practiceType))
            rpgExpandedReject('familiarity-retargeted');
        local initialCount = 0; local copies = 0;
        foreach (local entry in self.owner.familiarities)
        {
            if (!entry.ofKind(RpgExpandedFamiliarity) || entry.owner != self.owner)
                rpgExpandedReject('familiarity-ownership');
            if (entry.skill == self.skill)
            {
                if (entry.equipmentType == self.equipmentType) copies += 1;
                if (entry.initial) initialCount += 1;
            }
        }
        if (copies != 1) rpgExpandedReject('duplicate-familiarity');
        local training = rpgExpandedTrainingFor(self.owner, self.skill);
        local points = training == nil ? 0 : training.points;
        if (initialCount > points * 2) rpgExpandedReject('initial-familiarity-limit');
        return nil;
    }
    known() { return self.initial || self.recognized || self.practicedSeconds == self.requiredSeconds; }
    modifier()
    {
        self.validate(); return self.known() ? 0 : self.penalty;
    }
    assess(seconds)
    {
        self.validate(); rpgInteger(seconds, 1, 86400);
        local value = new RpgExpandedResult();
        if (self.known()) { value.status = 'reused'; return value; }
        if (!self.available) { value.reason = 'familiarity-equipment-unavailable'; return value; }
        if (self.owner.dead || self.owner.unconscious)
        { value.reason = 'cannot-practice'; return value; }
        if (self.owner.skillScore(self.skill) == nil)
        { value.reason = 'familiarity-skill-unavailable'; return value; }
        if (seconds > self.requiredSeconds - self.practicedSeconds)
        { value.reason = 'familiarity-excess-time'; return value; }
        value.status = 'ready'; value.seconds = seconds; return value;
    }
    advance(seconds)
    {
        local value = self.assess(seconds);
        if (value.status != 'ready') return value;
        rpgSpendTime(value.seconds);
        self.practiceOwner = self.owner; self.practiceSkill = self.skill;
        self.practiceType = self.equipmentType; self.practicedSeconds += value.seconds;
        value.status = 'resolved'; return value;
    }
;

/** Use through rpgLiteScore/rpgLiteCheck so the familiarity penalty is applied
 * once, alongside (rather than replacing) other contextual modifiers. */
class RpgExpandedSkillContext: RpgLiteContext
    familiarity = nil
    equipmentTL = nil
    rollAttribute = nil
    fixedBase = nil
    scoreFor(profile)
    {
        if (self.rollAttribute == nil && self.fixedBase == nil) return inherited(profile);
        if (self.skill == nil || self.rollAttribute != nil && self.fixedBase != nil)
            rpgExpandedReject('relative-skill-context');
        local relative = rpgExpandedRelativeSkill(profile, self.skill);
        if (relative == nil) return nil;
        if (self.fixedBase != nil)
        {
            rpgInteger(self.fixedBase, 1, 1000); return self.fixedBase + relative;
        }
        return profile.attributeScore(self.rollAttribute) + relative;
    }
    controllingAttribute()
    {
        if (self.fixedBase != nil) return nil;
        if (self.rollAttribute != nil) return self.rollAttribute;
        return inherited();
    }
    technologyModifier()
    {
        if (self.equipmentTL == nil) return 0;
        if (self.skill == nil || !self.skill.ofKind(RpgLiteSkill) || self.skill.techLevel == nil)
            rpgExpandedReject('technology-skill-required');
        return rpgExpandedTechnologyModifier(self.skill.techLevel, self.equipmentTL,
            self.skill.attribute == rpgIQ);
    }
    unavailableReason(profile)
    {
        if (self.technologyModifier() == nil) return 'technology-too-advanced';
        return inherited(profile);
    }
    skillUseModifier(profile)
    {
        local technology = self.technologyModifier();
        if (technology == nil) return nil;
        if (self.familiarity == nil) return technology;
        if (!self.familiarity.ofKind(RpgExpandedFamiliarity)
            || self.familiarity.owner != profile || self.familiarity.skill != self.skill)
            rpgExpandedReject('familiarity-context');
        return technology + self.familiarity.modifier();
    }
;

/** Equipment-to-skill technology difference, B168. nil means impossible,
 * rather than an arbitrarily large numeric penalty. No familiarity is included. */
rpgExpandedTechnologyModifier(skillTL, equipmentTL, cognitive)
{
    rpgInteger(skillTL, 0, 12); rpgInteger(equipmentTL, 0, 12);
    local difference = equipmentTL - skillTL;
    if (!cognitive) return difference < 0 ? difference : -difference;
    if (difference >= 4) return nil;
    if (difference > 0) return -5 * difference;
    if (difference == 0) return 0;
    return 2 * difference + 1;
}

/** Create an author-approved optional specialty, B169-B170. generalSkill may
 * already represent a required specialty, but cannot itself be optional. */
rpgExpandedOptionalSpecialty(generalSkill, id, specialty, approved)
{
    local skill = new RpgExpandedSkill();
    skill.optionalParent = generalSkill; skill.optionalApproved = approved;
    skill.id = id; skill.specialty = specialty;
    if (generalSkill == nil || !generalSkill.ofKind(RpgExpandedSkill))
        rpgExpandedReject('optional-specialty-parent');
    skill.attribute = generalSkill.attribute; skill.difficulty = generalSkill.difficulty - 1;
    skill.techLevel = generalSkill.techLevel; skill.prerequisite = generalSkill.prerequisite;
    rpgExpandedValidateSkill(skill); return skill;
}

/** Validate the mechanical identity without evaluating skill scores. */
rpgExpandedValidateSkill(skill)
{
    if (skill == nil || !skill.ofKind(RpgSkill)) rpgExpandedReject('invalid-skill');
    if (!skill.ofKind(RpgExpandedSkill) || skill.optionalParent == nil) return nil;
    local parent = skill.optionalParent;
    if (!parent.ofKind(RpgExpandedSkill) || parent.optionalParent != nil || parent.wildcard)
        rpgExpandedReject('optional-specialty-parent');
    if (!skill.optionalApproved) rpgExpandedReject('optional-specialty-approval');
    if (parent.attribute != rpgIQ || parent.difficulty < 1 || parent.difficulty > 3
        || skill.attribute != rpgIQ || skill.difficulty != parent.difficulty - 1
        || skill.techLevel != parent.techLevel || skill.wildcard)
        rpgExpandedReject('optional-specialty-definition');
    if (skill.id == nil || skill.specialty == nil || skill.specialty == '')
        rpgExpandedReject('optional-specialty-identity');
    if (skill.prerequisite != parent.prerequisite)
        rpgExpandedReject('optional-specialty-prerequisite');
    return nil;
}

/** Expand the explicit B170 optional-specialty edges. This does not traverse
 * untrained defaults: each generated edge still requires purchased training. */
rpgExpandedDefaultEdges(profile, skill)
{
    local edges = skill.defaults;
    foreach (local pair in edges)
    {
        if (pair.length() != 2 || pair[1] == skill) rpgExpandedReject('invalid-skill-default');
        rpgInteger(pair[2], -100, 0);
    }
    foreach (local training in profile.skills)
    {
        local candidate = training.skill;
        rpgExpandedValidateSkill(candidate);
        if (candidate.ofKind(RpgExpandedSkill) && candidate.optionalParent != nil && candidate != skill)
        {
            if (candidate.optionalParent == skill) edges = edges + [[candidate,-2]];
            foreach (local pair in skill.defaults)
                if (pair[1] == candidate.optionalParent) edges = edges + [[candidate,pair[2]-2]];
        }
    }
    return edges;
}

/** Relative level from the selected skill rating, B171-B172. Unavailable
 * skills stay unavailable; this query does not purchase or improve training. */
rpgExpandedRelativeSkill(profile, skill)
{
    local score = profile.skillScore(skill);
    return score == nil ? nil : score - profile.attributeScore(skill.attribute);
}

/** Use only for procedures that add positive relative training to strength.
 * Ordinary strength-based skill checks instead use rollAttribute = rpgST. */
rpgExpandedSkillStrength(profile, skill)
{
    local relative = rpgExpandedRelativeSkill(profile, skill);
    if (relative == nil) return nil;
    return profile.st + (relative > 0 ? relative : 0);
}

/** Authored B169 recognition decision. Similar/improved/obsolete decisions must
 * identify a known type; optional rolls require six known types of this skill.
 * One attempted recognition is retained on the target record, even on failure. */
class RpgExpandedFamiliarityRecognition: object
    familiarity = nil
    mode = 'roll'
    similarTo = nil
    approved = nil
    assess()
    {
        if (self.familiarity == nil || !self.familiarity.ofKind(RpgExpandedFamiliarity))
            rpgExpandedReject('familiarity-recognition-target');
        local target = self.familiarity; target.validate();
        rpgExpandedValidate(target.owner);
        if (!holds(['roll','similar','improved','obsolete'], self.mode))
            rpgExpandedReject('familiarity-recognition-mode');
        local value = new RpgExpandedResult();
        if (target.known() || target.recognitionAttempted)
        { value.status = 'reused'; value.check = target.recognitionCheck; return value; }
        if (!self.approved) { value.reason = 'familiarity-recognition-unapproved'; return value; }
        if (!target.available) { value.reason = 'familiarity-equipment-unavailable'; return value; }
        if (target.owner.dead || target.owner.unconscious)
        { value.reason = 'cannot-recognize'; return value; }
        if (self.mode == 'roll')
        {
            local count = 0;
            foreach (local entry in target.owner.familiarities)
                if (entry.skill == target.skill && entry.known()) count += 1;
            if (count < 6) { value.reason = 'familiarity-recognition-experience'; return value; }
            local score = target.owner.skillScore(target.skill);
            if (score == nil || score < 3)
            { value.reason = 'familiarity-skill-unavailable'; return value; }
            rpgInteger(score, 3, 1000); value.check = score;
        }
        else
        {
            if (self.similarTo == nil || !self.similarTo.ofKind(RpgExpandedFamiliarity)
                || self.similarTo == target || self.similarTo.owner != target.owner
                || self.similarTo.skill != target.skill)
                rpgExpandedReject('familiarity-recognition-source');
            self.similarTo.validate();
            if (!self.similarTo.known())
            { value.reason = 'familiarity-recognition-source-unknown'; return value; }
        }
        value.status = 'ready'; return value;
    }
    resolve()
    {
        local value = self.assess();
        if (value.status != 'ready') return value;
        local target = self.familiarity;
        if (self.mode == 'roll') value.check = rpgCheck(value.check, rpgRandom.roll());
        target.practiceOwner = target.owner; target.practiceSkill = target.skill;
        target.practiceType = target.equipmentType;
        target.recognitionAttempted = true; target.recognitionCheck = value.check;
        target.recognized = self.mode != 'roll' || value.check.achieved;
        value.status = 'resolved'; return value;
    }
;
