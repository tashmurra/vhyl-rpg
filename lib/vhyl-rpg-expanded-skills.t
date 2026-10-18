/* Include after the expanded foundation. Source: full-2008, B170, B173, B175, B230. */

/** Authored expanded skill. Defaults are explicit [skill, penalty] pairs.
 * A catalogue is not implied by this definition type. */
class RpgExpandedSkill: RpgLiteSkill
    defaults = []
    wildcard = nil
    prerequisite = nil
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
    local training = rpgExpandedTrainingFor(profile, skill);
    if (training == nil || training.points == 0) return nil;
    local wildcard = skill.ofKind(RpgExpandedSkill) && skill.wildcard;
    if (wildcard && !profile.rules.wildcardSkills) rpgExpandedReject('wildcard-disabled');
    local base = profile.attributeScore(skill.attribute); local credit = 0;
    if (training.ofKind(RpgExpandedTraining) && training.defaultFrom != nil)
    {
        if (!skill.ofKind(RpgExpandedSkill) || wildcard) rpgExpandedReject('invalid-paid-default');
        local penalty = nil;
        foreach (local pair in skill.defaults)
            if (pair[1] == training.defaultFrom) penalty = pair[2];
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
        foreach (local pair in skill.defaults)
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
        if (!skill.ofKind(RpgExpandedSkill) || skill.prerequisite == nil) return nil;
        if (!skill.prerequisite.ofKind(RpgExpandedPrerequisite))
            rpgExpandedReject('invalid-prerequisite');
        return skill.prerequisite.satisfied(self, []) ? nil : 'skill-prerequisite';
    }
;

modify RpgExpandedProfile
    familiarities = []
    validateFeatures()
    {
        inherited();
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
    known() { return self.initial || self.practicedSeconds == self.requiredSeconds; }
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
    skillUseModifier(profile)
    {
        if (self.familiarity == nil) return 0;
        if (!self.familiarity.ofKind(RpgExpandedFamiliarity)
            || self.familiarity.owner != profile || self.familiarity.skill != self.skill)
            rpgExpandedReject('familiarity-context');
        return self.familiarity.modifier();
    }
;
