/* Include after the expanded foundation. Source: full-2008, B170, B173, B175, B230. */

/** Authored expanded skill. Defaults are explicit [skill, penalty] pairs.
 * A catalogue is not implied by this definition type. */
class RpgExpandedSkill: RpgLiteSkill
    validateDefinition() { return nil; }
    studyIdentity() { rpgExpandedValidateSkill(self); return self.optionalParent == nil ? self.id : self.optionalParent.id; }
    studySpecialty() { rpgExpandedValidateSkill(self); return self.optionalParent == nil ? self.specialty : self.optionalParent.specialty; }
    defaults = []
    attributeDefaults = []
    wildcard = nil
    prerequisite = nil
    optionalParent = nil
    optionalApproved = nil
    maximumDifficulty() { return 3; }
    defaultEdges(profile) { return self.defaults; }
    learningPrerequisiteReason(profile)
    {
        return self.optionalParent == nil ? nil : self.optionalParent.learningPrerequisiteReason(profile);
    }
;

/** B223 medical skill defaults. Sources must be purchased, at the same TL;
 * the shared resolver handles paid improvements and rejects double defaults. */
class RpgExpandedSurgerySkill: RpgExpandedSkill
    id = 'surgery'
    attribute = rpgIQ
    difficulty = 3
    defaultEdges(profile)
    {
        local edges = inherited(profile);
        foreach (local training in profile.skills)
        {
            local source = training.skill;
            if (!source.ofKind(RpgLiteSkill) || source.techLevel != self.techLevel) continue;
            local penalty = source.id == 'first-aid' ? -12 : source.id == 'physician' ? -5
                : source.id == 'physiology' ? -8 : source.id == 'veterinary' ? -5 : nil;
            if (penalty != nil && source != self) edges = edges + [[source,penalty]];
        }
        return edges;
    }
    learningPrerequisiteReason(profile)
    {
        foreach (local training in profile.skills)
            if (training.points > 0 && training.skill.ofKind(RpgLiteSkill)
                && training.skill.techLevel == self.techLevel
                && holds(['first-aid','physician'],training.skill.id)) return nil;
        return 'skill-prerequisite';
    }
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
    local physiologyReason = profile.physiologySkillLearningReason(skill);
    if (physiologyReason != nil) rpgExpandedReject(physiologyReason);
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
        if (skill.defaultPenalty != nil || skill.defaults.length() != 0 || skill.attributeDefaults.length() != 0)
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
        foreach (local pair in skill.attributeDefaults)
        {
            local base = profile.attributeScore(pair[1]);
            local candidate = (base > 20 ? 20 : base) + pair[2];
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
    return score == nil ? nil : score + profile.ancestrySkillModifier(skill) + profile.catalogueTalentSkillModifier(skill) + profile.catalogueSkillModifier(skill);
}

modify RpgExpandedProfile
    talentBonusInSkillScore() { return true; }
    catalogueFeatureCheckModifier(skill) { return 0; }
    skillScore(skill)
    {
        if (skill.ofKind(RpgExpandedSkill)) return rpgExpandedSkillScore(self, skill);
        local score = inherited(skill);
        return score == nil ? nil : score + self.ancestrySkillModifier(skill) + self.catalogueTalentSkillModifier(skill) + self.catalogueSkillModifier(skill);
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
        if (!self.owner.rules.techniques) rpgExpandedReject('techniques-disabled');
        local reason = self.eligibilityReason(self.owner);
        if (reason != nil) rpgExpandedReject(reason);
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
 * training; its optional minimum is a purchased level with persistent aptitude bonuses,
 * never a better untrained default or a situational check modifier.
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
            if (score == nil) return nil;
            score += profile.ancestrySkillModifier(self.skill) + profile.catalogueTalentSkillModifier(self.skill) + profile.catalogueSkillModifier(self.skill);
            return score >= self.minimum;
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
        local physiologyReason = self.physiologySkillLearningReason(skill); if (physiologyReason != nil) return physiologyReason;
        local socialReason = self.socialSkillLearningReason(skill); if (socialReason != nil) return socialReason;
        if (skill.ofKind(RpgExpandedSkill) && skill.wildcard && !self.rules.wildcardSkills)
            return 'wildcard-disabled';
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
        if (!skill.ofKind(RpgExpandedSkill)) return nil;
        local prerequisiteReason = skill.learningPrerequisiteReason(self);
        if (prerequisiteReason != nil) return prerequisiteReason;
        if (skill.prerequisite == nil) return nil;
        if (!skill.prerequisite.ofKind(RpgExpandedPrerequisite))
            rpgExpandedReject('invalid-prerequisite');
        return skill.prerequisite.satisfied(self, []) ? nil : 'skill-prerequisite';
    }
    skillLearningWithTeacherReason(skill, teacher)
    {
        local reason = self.learningAcquisitionReason('skill');
        if (reason != nil) return reason;
        reason = self.skillLearningReason(skill);
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
            if (training == nil || !training.ofKind(RpgTraining) || training.skill == nil)
                rpgExpandedReject('invalid-training');
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
    sameEquipmentFamiliarity(other) { return self.equipmentType == other.equipmentType; }
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
                if (self.sameEquipmentFamiliarity(entry)) copies += 1;
                if (entry.initial) initialCount += 1;
            }
        }
        if (copies != 1) rpgExpandedReject('duplicate-familiarity');
        local training = rpgExpandedTrainingFor(self.owner, self.skill);
        local points = training == nil ? 0 : training.points;
        if (initialCount > points * 2) rpgExpandedReject('initial-familiarity-limit');
        return nil;
    }
    practiceDefinition()
    {
        return [self.owner,self.skill,self.equipmentType,self.initial,self.requiredSeconds,self.penalty,
            self.practicedSeconds,self.recognized,self.recognitionAttempted,self.recognitionCheck,
            self.practiceOwner,self.practiceSkill,self.practiceType,self.available];
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
        value.reason = self.owner.learningAcquisitionReason('familiarity');
        if (value.reason != nil) return value;
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
        local definition = self.practiceDefinition(); local start = rpgLedger.seconds;
        rpgSpendTime(value.seconds);
        local current = self.practiceDefinition();
        if (rpgLedger.seconds != start + value.seconds || current.length() != definition.length())
            rpgExpandedReject('familiarity-practice-interrupted');
        for (local i = 1; i <= current.length(); i += 1)
            if (current[i] != definition[i]) rpgExpandedReject('familiarity-practice-interrupted');
        if (self.assess(seconds).status != 'ready') rpgExpandedReject('familiarity-practice-conditions-changed');
        self.practiceOwner = self.owner; self.practiceSkill = self.skill;
        self.practiceType = self.equipmentType; self.practicedSeconds += value.seconds;
        value.status = 'resolved'; return value;
    }
;

/** Use through rpgLiteScore/rpgLiteCheck so the familiarity penalty is applied
 * once, alongside (rather than replacing) other contextual modifiers. */
class RpgExpandedSkillContext: RpgLiteContext
    familiarity = nil
    softwareTechnologyEnabled = true
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
    technologyModifierFor(profile)
    {
        local level = self.technologySkillLevel(profile);
        if (level == nil && self.skill != nil && self.skill.techLevel != nil) return nil;
        if (self.skill == nil || level == self.skill.techLevel) return self.technologyModifier();
        if (self.equipmentTL == nil) return 0;
        if (self.skill == nil || !self.skill.ofKind(RpgLiteSkill) || level == nil)
            rpgExpandedReject('technology-skill-required');
        return rpgExpandedTechnologyModifier(level,self.equipmentTL,self.skill.attribute == rpgIQ);
    }
    unavailableReason(profile)
    {
        if (self.technologyModifierFor(profile) == nil) return self.technologyUnavailableReason(profile);
        return inherited(profile);
    }
    skillUseModifier(profile)
    {
        local technology = self.technologyModifierFor(profile);
        if (technology == nil) return nil;
        if (self.familiarity == nil) return technology;
        if (!self.familiarity.ofKind(RpgExpandedFamiliarity)
            || self.familiarity.owner != profile || self.familiarity.skill != self.skill)
            rpgExpandedReject('familiarity-context');
        return technology + self.familiarity.modifier();
    }
;

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
    if (skill.ofKind(RpgExpandedSkill)) skill.validateDefinition();
    rpgInteger(skill.difficulty, 0, skill.maximumDifficulty());
    rpgValidateAttribute(skill.attribute);
    if (skill.defaultPenalty != nil) rpgInteger(skill.defaultPenalty, -100, 0);
    if (skill.ofKind(RpgExpandedSkill) && skill.wildcard)
    {
        if (skill.difficulty != 3) rpgExpandedReject('wildcard-difficulty');
        if (skill.defaultPenalty != nil || skill.defaults.length() != 0 || skill.attributeDefaults.length() != 0)
            rpgExpandedReject('wildcard-default');
    }
    if (skill.ofKind(RpgExpandedSkill))
        foreach (local pair in skill.attributeDefaults)
        {
            if (pair.length() != 2) rpgExpandedReject('attribute-default-definition');
            rpgValidateAttribute(pair[1]); rpgInteger(pair[2],-100,0);
        }
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
    local baseEdges = skill.defaultEdges(profile);
    local edges = baseEdges;
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
            foreach (local pair in baseEdges)
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
        value.reason = target.owner.learningAcquisitionReason('familiarity');
        if (value.reason != nil) return value;
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


/** Context-local effective technology; never changes the learned skill definition. */
modify RpgLiteContext
    technologySkillLevel(profile) { return self.skill == nil ? nil : self.skill.techLevel; }
    technologyUnavailableReason(profile) { return 'technology-too-advanced'; }
;

/** B224 terrain and planet default, without traversing another unpaid default. */
rpgExpandedSurvivalDefault(sourceTerrain, targetTerrain, samePlanet, samePlanetType)
{
    local land = ['arctic','desert','island-beach','jungle','mountain','plains','swampland','woodlands'];
    local water = ['bank','deep-ocean-vent','fresh-water-lake','open-ocean','reef','river-stream','salt-water-sea','tropical-lagoon'];
    if (!holds(land+water,sourceTerrain) || !holds(land+water,targetTerrain)) return nil;
    if (!samePlanetType) return nil;
    local penalty = sourceTerrain == targetTerrain ? 0
        : holds(land,sourceTerrain) && holds(land,targetTerrain) ? -3
        : holds(water,sourceTerrain) && holds(water,targetTerrain) ? -4
        : holds(['island-beach','tropical-lagoon'],sourceTerrain) && holds(['island-beach','tropical-lagoon'],targetTerrain) ? -4
        : holds(['swampland','river-stream'],sourceTerrain) && holds(['swampland','river-stream'],targetTerrain) ? -4 : nil;
    return penalty == nil ? nil : penalty - (samePlanet ? 0 : 4);
}

/** B211 planetary practical nature knowledge. Explicit Biology edges remain supported. */
class RpgExpandedNaturalistSkill: RpgExpandedSkill
    id = 'naturalist'
    attribute = rpgIQ
    difficulty = 2
    defaultPenalty = -6
    planet = nil
    planetType = nil
    expandedForageDefaultsReady() { return true; }
    foragingDefinition() { return [self.planet,self.planetType]; }
    validateDefinition()
    {
        if (self.id != 'naturalist' || self.attribute != rpgIQ || self.difficulty != 2 || self.defaultPenalty != -6
            || self.planet == nil || self.planet == '' || self.planetType == nil || self.planetType == ''
            || self.specialty != self.planet || self.techLevel != nil || self.wildcard || self.optionalParent != nil)
            rpgExpandedReject('naturalist-definition');
        return nil;
    }
    defaultEdges(profile)
    {
        local edges = inherited(profile);
        foreach (local training in profile.skills)
        {
            local source = training.skill;
            if (source == self || !source.ofKind(RpgExpandedNaturalistSkill)) continue;
            source.validateDefinition();
            if (source.planet == self.planet && source.planetType != self.planetType)
                rpgExpandedReject('nature-planet-classification');
            if (source.planet != self.planet && source.planetType == self.planetType) edges = edges + [[source,-4]];
        }
        return edges;
    }
;

/** B223-B224 Survival defaults generated from explicit terrain and world facts. */
class RpgExpandedSurvivalSkill: RpgExpandedSkill
    id = 'survival'
    attribute = rpgPerception
    difficulty = 1
    defaultPenalty = -5
    planet = nil
    planetType = nil
    expandedForageDefaultsReady() { return true; }
    foragingDefinition() { return [self.planet,self.planetType]; }
    validateDefinition()
    {
        if (self.id != 'survival' || self.attribute != rpgPerception || self.difficulty != 1 || self.defaultPenalty != -5
            || self.planet == nil || self.planet == '' || self.planetType == nil || self.planetType == ''
            || self.specialty == nil || self.specialty == '' || self.techLevel != nil || self.wildcard || self.optionalParent != nil)
            rpgExpandedReject('survival-definition');
        if (rpgExpandedSurvivalDefault(self.specialty,self.specialty,true,true) == nil)
            rpgExpandedReject('survival-special-terrain-adapter-required');
        return nil;
    }
    defaultEdges(profile)
    {
        local edges = inherited(profile);
        foreach (local training in profile.skills)
        {
            local source = training.skill; if (source == self) continue;
            if (!source.ofKind(RpgExpandedSurvivalSkill) && !source.ofKind(RpgExpandedNaturalistSkill)) continue;
            source.validateDefinition();
            if (source.planet == self.planet && source.planetType != self.planetType)
                rpgExpandedReject('nature-planet-classification');
            local penalty = source.ofKind(RpgExpandedNaturalistSkill) ? (source.planet == self.planet ? -3 : nil)
                : rpgExpandedSurvivalDefault(source.specialty,self.specialty,source.planet == self.planet,source.planetType == self.planetType);
            if (penalty != nil) edges = edges + [[source,penalty]];
        }
        return edges;
    }
;

modify RpgExpandedRules
    techniques = nil
;
modify RpgExpandedProfile
    techniquePurchases = []
;
modify RpgExpandedTechnique
    /** Additional published prerequisites or an approved authored requirement. */
    purchasePrerequisite = nil
;

/** B229-B230 incremental investment, using the existing advancement bank. */
class RpgExpandedTechniquePurchase: object
    id = nil
    profile = nil
    technique = nil
    targetPoints = 0
    approved = nil
    evidence = nil
    practicedAction = nil
    distinctFromCoreAction = nil
    requiresDowntime = true
    boundDefinition = nil
    result = nil
    definition()
    {
        return [self.id,self.profile,self.technique,self.targetPoints,self.approved,self.evidence,
            self.practicedAction,self.distinctFromCoreAction,self.requiresDowntime,
            self.technique.skill,self.technique.attribute,self.technique.parentTechnique,
            self.technique.penalty,self.technique.maximumAboveSkill,self.technique.hard,
            self.technique.purchasePrerequisite,self.technique.cinematic,self.technique.cinematicRequirement,
            self.technique.cinematicEvidence,self.technique.cinematicApproved,self.technique.ordinaryPistolException];
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)
            || self.technique == nil || !self.technique.ofKind(RpgExpandedTechnique)
            || self.technique.owner != self.profile || !holds(self.profile.contributions,self.technique))
            rpgExpandedReject('technique-purchase-ownership');
        local value = new RpgExpandedResult();
        if (self.result != nil)
        {
            local current = self.definition();
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.boundDefinition[index]) rpgExpandedReject('technique-purchase-binding');
            if (!holds(self.profile.techniquePurchases,self)) rpgExpandedReject('technique-purchase-history');
            value.status = 'reused'; return value;
        }
        rpgExpandedValidate(self.profile); self.technique.validate(self.profile);
        foreach (local prior in self.profile.techniquePurchases)
            if (prior.id == self.id) rpgExpandedReject('technique-purchase-duplicate');
        if (!self.profile.rules.techniques) { value.reason = 'techniques-disabled'; return value; }
        value.reason = self.technique.eligibilityReason(self.profile); if (value.reason != nil) return value;
        if (!self.approved || self.evidence == nil || self.evidence == ''
            || self.practicedAction == nil || self.practicedAction == '' || !self.distinctFromCoreAction)
        { value.reason = 'technique-definition-approval-required'; return value; }
        if (self.requiresDowntime && !self.profile.developmentOpen)
        { value.reason = 'rpg.downtime-required'; return value; }
        value.reason = self.profile.learningAcquisitionReason('technique'); if (value.reason != nil) return value;
        if (self.technique.purchasePrerequisite != nil)
        {
            if (!self.technique.purchasePrerequisite.ofKind(RpgExpandedPrerequisite)) rpgExpandedReject('invalid-prerequisite');
            if (!self.technique.purchasePrerequisite.satisfied(self.profile,[]))
            { value.reason = 'technique-prerequisite'; return value; }
        }
        rpgInteger(self.targetPoints,1,1000000);
        if (self.technique.hard && self.targetPoints == 1)
        { value.reason = 'technique-hard-first-improvement'; return value; }
        if (self.technique.maximumAboveSkill != nil && self.targetPoints
            > self.technique.maximumAboveSkill - self.technique.penalty + (self.technique.hard ? 1 : 0))
        { value.reason = 'technique-cap'; return value; }
        value.points = self.targetPoints - self.technique.points;
        if (value.points <= 0) { value.reason = 'technique-no-improvement'; return value; }
        if (value.points > self.profile.unspentPoints) { value.reason = 'rpg.insufficient-points'; return value; }
        value.reason = self.profile.developmentSpendingReason(); if (value.reason != nil) return value;
        rpgInteger(self.profile.developmentRevision,0,2147483646);
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status == 'reused') return self.result;
        if (value.status != 'ready') return value;
        self.boundDefinition = self.definition();
        self.profile.unspentPoints -= value.points; self.technique.points = self.targetPoints;
        self.profile.developmentRevision += 1;
        self.profile.techniquePurchases = self.profile.techniquePurchases + [self];
        value.status = 'resolved'; self.result = value; return value;
    }
;

/** B230 technique base with the parent skill's ordinary contextual modifiers. */
class RpgExpandedTechniqueContext: RpgExpandedSkillContext
    technique = nil
    scoreFor(profile)
    {
        if (self.technique == nil || !self.technique.ofKind(RpgExpandedTechnique)
            || self.technique.owner != profile) rpgExpandedReject('technique-context-ownership');
        if (self.rollAttribute != nil || self.fixedBase != nil)
            rpgExpandedReject('technique-relative-context-unimplemented');
        /* Validate the entire graph before following it to its root. */
        local score = self.technique.score();
        local root = self.technique;
        while (root.parentTechnique != nil) root = root.parentTechnique;
        if (self.skill != root.skill || root.skill == nil && self.attribute != root.attribute)
            rpgExpandedReject('technique-context-basis');
        return score;
    }
;

modify RpgExpandedRules
    /** Explicit choice for marked techniques: restricted or unrestricted. */
    cinematicTechniquePolicy = nil
;
modify RpgExpandedTechnique
    cinematic = nil
    cinematicRequirement = nil
    cinematicEvidence = nil
    cinematicApproved = nil
    ordinaryPistolException = nil
    eligibilityReason(profile)
    {
        if (self.parentTechnique != nil)
        {
            local parentReason = self.parentTechnique.eligibilityReason(profile);
            if (parentReason != nil) return parentReason;
        }
        if (!self.cinematic) return nil;
        if (self.ordinaryPistolException)
        {
            if (self.id != 'paired-weapon-attack' || self.skill == nil || !self.skill.ofKind(RpgLiteSkill)
                || self.skill.id != 'guns' || self.skill.specialty != 'pistol'
                || self.skill.techLevel == nil || self.attribute != nil || self.parentTechnique != nil
                || !self.hard || self.penalty != -4 || self.maximumAboveSkill != 0)
                rpgExpandedReject('technique-pistol-exception-definition');
            return nil;
        }
        if (!holds(['restricted','unrestricted'],profile.rules.cinematicTechniquePolicy))
            return 'technique-cinematic-policy-required';
        if (profile.rules.cinematicTechniquePolicy == 'unrestricted') return nil;
        if (!self.cinematicApproved || self.cinematicEvidence == nil || self.cinematicEvidence == ''
            || self.cinematicRequirement == nil || !self.cinematicRequirement.ofKind(RpgExpandedPrerequisite))
            return 'technique-cinematic-requirement-required';
        /* The author binds the applicable training/mastery permission, including weapon scope. */
        if (self.cinematicRequirement.kind != 'trait'
            || !holds(['advanced-martial-training','weapon-mastery'],self.cinematicRequirement.traitId))
            rpgExpandedReject('technique-cinematic-requirement-kind');
        return self.cinematicRequirement.satisfied(profile,[]) ? nil : 'technique-cinematic-prerequisite';
    }
;


/** B197: both attribute defaults feed the common skill resolver. */
class RpgExpandedFreeFallSkill: RpgExpandedSkill
    id = 'free-fall'
    attribute = rpgDX
    difficulty = 1
    defaultPenalty = -5
    attributeDefaults = [[rpgHT,-5]]
    validateDefinition()
    {
        if (self.id != 'free-fall' || self.attribute != rpgDX || self.difficulty != 1
            || self.defaultPenalty != -5 || self.defaultAttribute != nil || self.defaults.length() != 0
            || self.attributeDefaults.length() != 1 || self.attributeDefaults[1].length() != 2
            || self.attributeDefaults[1][1] != rpgHT || self.attributeDefaults[1][2] != -5
            || self.wildcard || self.optionalParent != nil || self.techLevel != nil)
            rpgExpandedReject('free-fall-skill-definition');
        return nil;
    }
;

/** B188 ground-vehicle specialties and directed defaults. */
class RpgExpandedDrivingSkill: RpgExpandedSkill
    id = 'driving'
    attribute = rpgDX
    difficulty = 1
    defaultPenalty = -5
    attributeDefaults = [[rpgIQ,-5]]
    validateDefinition()
    {
        if (self.id != 'driving' || self.attribute != rpgDX || self.difficulty != 1 || self.defaultPenalty != -5
            || self.defaultAttribute != nil || self.defaults.length() != 0
            || self.attributeDefaults.length() != 1 || self.attributeDefaults[1].length() != 2
            || self.attributeDefaults[1][1] != rpgIQ || self.attributeDefaults[1][2] != -5
            || self.techLevel == nil || self.wildcard || self.optionalParent != nil
            || !holds(['automobile','construction-equipment','halftrack','heavy-wheeled','hovercraft',
                'locomotive','mecha','motorcycle','tracked'],self.specialty))
            rpgExpandedReject('driving-skill-definition');
        rpgInteger(self.techLevel,0,12); return nil;
    }
    defaultEdges(profile)
    {
        local edges = inherited(profile);
        foreach (local training in profile.skills)
        {
            local source = training.skill;
            if (source == self || training.points <= 0 || !source.ofKind(RpgLiteSkill)) continue;
            if (self.specialty == 'motorcycle')
            {
                if (source.studyIdentity() == 'bicycling') edges = edges + [[source,-4]];
                continue;
            }
            if (self.specialty == 'mecha' && source.studyIdentity() == 'battlesuit' && source.techLevel == self.techLevel)
                edges = edges + [[source,-3]];
            if (source.id != 'driving' || source.techLevel != self.techLevel) continue;
            if (!source.ofKind(RpgExpandedDrivingSkill)) rpgExpandedReject('driving-expanded-source-required');
            source.validateDefinition();
            if (source.specialty == self.specialty) continue;
            local penalty = holds(['construction-equipment','hovercraft','locomotive','mecha'],self.specialty) ? -5 : -4;
            if (self.specialty == 'automobile' && source.specialty == 'heavy-wheeled'
                || self.specialty == 'heavy-wheeled' && source.specialty == 'automobile'
                || self.specialty == 'halftrack' && source.specialty == 'tracked'
                || self.specialty == 'tracked' && source.specialty == 'halftrack') penalty = -2;
            edges = edges + [[source,penalty]];
        }
        return edges;
    }
;
/** B188 authored driving conditions, with IQ-based knowledge tasks. */
class RpgExpandedDrivingContext: RpgExpandedSkillContext
    task = 'operation'
    rollAttribute = (self.task == 'operation' ? nil : rpgIQ)
    conditionsPenalty = 0
    repairPenalty = 0
    unfamiliarControls = nil
    unfamiliarTypePenalty = 0
    evidence = nil
    skillUseModifier(profile)
    {
        if (self.skill == nil || !self.skill.ofKind(RpgExpandedDrivingSkill)
            || !holds(['operation','map-reading','simple-malfunction','traffic-rules'],self.task)
            || self.fixedBase != nil || self.familiarity != nil)
            rpgExpandedReject('driving-context-definition');
        self.skill.validateDefinition();
        rpgInteger(self.conditionsPenalty,-100,0); rpgInteger(self.repairPenalty,-100,0);
        rpgInteger(self.unfamiliarTypePenalty,-100,0);
        if (self.conditionsPenalty == -1 || self.repairPenalty == -1
            || self.unfamiliarTypePenalty < 0 && self.unfamiliarTypePenalty > -4)
            rpgExpandedReject('driving-context-minimum-penalty');
        local penalty = self.conditionsPenalty + self.repairPenalty + self.unfamiliarTypePenalty
            + (self.unfamiliarControls ? -2 : 0);
        if (penalty != 0 && (self.evidence == nil || self.evidence == ''))
            rpgExpandedReject('driving-context-evidence');
        local base = inherited(profile); return base == nil ? nil : base + penalty;
    }
;


/** Owned B188 unfamiliarity with controls or vehicle type; B169 practice. */
class RpgExpandedDrivingFamiliarity: RpgExpandedFamiliarity
    sameEquipmentFamiliarity(other)
    {
        return self.equipmentType == other.equipmentType
            && (!other.ofKind(RpgExpandedDrivingFamiliarity) || self.kind == other.kind);
    }
    kind = 'controls'
    evidence = nil
    validate()
    {
        inherited();
        if (self.skill == nil || !self.skill.ofKind(RpgExpandedDrivingSkill)
            || !holds(['controls','vehicle-type'],self.kind) || self.evidence == nil || self.evidence == '')
            rpgExpandedReject('driving-familiarity-definition');
        if (self.requiredSeconds != 28800 || (self.kind == 'controls' ? self.penalty != -2 : self.penalty > -4))
            rpgExpandedReject('driving-familiarity-penalty');
        return nil;
    }
    practiceDefinition() { return inherited() + [self.kind,self.evidence]; }
;
modify RpgExpandedDrivingContext
    controlsFamiliarity = nil
    typeFamiliarity = nil
    drivingFamiliarityPenalty(profile,record,kind)
    {
        if (!record.ofKind(RpgExpandedDrivingFamiliarity) || record.owner != profile
            || record.skill != self.skill || record.kind != kind)
            rpgExpandedReject('driving-familiarity-context');
        return record.modifier();
    }
    skillUseModifier(profile)
    {
        if (self.controlsFamiliarity != nil && self.unfamiliarControls
            || self.typeFamiliarity != nil && self.unfamiliarTypePenalty != 0)
            rpgExpandedReject('driving-familiarity-double-charge');
        local base = inherited(profile); if (base == nil) return nil;
        if (self.controlsFamiliarity != nil)
            base += self.drivingFamiliarityPenalty(profile,self.controlsFamiliarity,'controls');
        if (self.typeFamiliarity != nil)
            base += self.drivingFamiliarityPenalty(profile,self.typeFamiliarity,'vehicle-type');
        return base;
    }
;
/** One practice session can teach both aspects of the same authored vehicle.
 * Every record must name the same equipmentType. Spend the shared clock once. */
rpgExpandedPracticeDriving(profile,skill,records,seconds)
{
    if (records.length() == 0 || records.length() > 2) rpgExpandedReject('driving-practice-records');
    local seen = []; local pending = []; local definitions = []; local equipment = nil;
    foreach (local record in records)
    {
        if (record == nil || !record.ofKind(RpgExpandedDrivingFamiliarity)
            || record.owner != profile || record.skill != skill || holds(seen,record.kind))
            rpgExpandedReject('driving-practice-record');
        seen = seen + [record.kind];
        if (equipment != nil && record.equipmentType != equipment) rpgExpandedReject('driving-practice-vehicle');
        equipment = record.equipmentType;
        local assessment = record.assess(seconds);
        if (!holds(['ready','reused'],assessment.status)) return assessment;
        if (assessment.status == 'ready')
        { pending = pending + [record]; definitions = definitions + [record.practiceDefinition()]; }
    }
    local value = new RpgExpandedResult();
    if (pending.length() == 0) { value.status = 'reused'; return value; }
    local start = rpgLedger.seconds; rpgSpendTime(seconds);
    if (rpgLedger.seconds != start + seconds) rpgExpandedReject('driving-practice-interrupted');
    for (local i = 1; i <= pending.length(); i += 1)
    {
        local record = pending[i]; local facts = record.practiceDefinition(); local original = definitions[i];
        if (facts.length() != original.length()) rpgExpandedReject('driving-practice-interrupted');
        for (local j = 1; j <= facts.length(); j += 1)
            if (facts[j] != original[j]) rpgExpandedReject('driving-practice-interrupted');
        if (record.assess(seconds).status != 'ready') rpgExpandedReject('driving-practice-interrupted');
    }
    foreach (local record in pending)
    {
        record.practiceOwner = profile; record.practiceSkill = skill; record.practiceType = record.equipmentType;
        record.practicedSeconds += seconds;
    }
    value.seconds = seconds; value.status = 'resolved'; return value;
}

/** B180-B181 small-watercraft specialties; crewed-bridge ships are excluded. */
class RpgExpandedBoatingSkill: RpgExpandedSkill
    id = 'boating'
    attribute = rpgDX
    difficulty = 1
    defaultPenalty = -5
    attributeDefaults = [[rpgIQ,-5]]
    validateDefinition()
    {
        if (self.id != 'boating' || self.attribute != rpgDX || self.difficulty != 1 || self.defaultPenalty != -5
            || self.defaultAttribute != nil || self.defaults.length() != 0
            || self.attributeDefaults.length() != 1 || self.attributeDefaults[1].length() != 2
            || self.attributeDefaults[1][1] != rpgIQ || self.attributeDefaults[1][2] != -5
            || self.techLevel == nil || self.wildcard || self.optionalParent != nil
            || !holds(['large-powerboat','motorboat','sailboat','unpowered'],self.specialty))
            rpgExpandedReject('boating-skill-definition');
        rpgInteger(self.techLevel,0,12); return nil;
    }
    defaultEdges(profile)
    {
        local edges = inherited(profile);
        foreach (local training in profile.skills)
        {
            local source = training.skill;
            if (source == self || training.points <= 0 || !source.ofKind(RpgLiteSkill) || source.techLevel != self.techLevel) continue;
            if (self.specialty == 'large-powerboat' && source.studyIdentity() == 'seamanship')
                edges = edges + [[source,-4]];
            if (source.id != 'boating') continue;
            if (!source.ofKind(RpgExpandedBoatingSkill)) rpgExpandedReject('boating-expanded-source-required');
            source.validateDefinition(); if (source.specialty == self.specialty) continue;
            local penalty = self.specialty == 'large-powerboat' || source.specialty == 'large-powerboat' ? -4 : -3;
            if (self.specialty == 'large-powerboat' && source.specialty == 'motorboat'
                || self.specialty == 'motorboat' && source.specialty == 'large-powerboat') penalty = -2;
            edges = edges + [[source,penalty]];
        }
        return edges;
    }
;
class RpgExpandedBoatingContext: RpgExpandedSkillContext
    eventKind = 'hazard'
    conditionsPenalty = 0
    evidence = nil
    validateBoating()
    {
        if (self.skill == nil || !self.skill.ofKind(RpgExpandedBoatingSkill)
            || !holds(['enter','get-underway','dock','hazard','routine'],self.eventKind)
            || self.fixedBase != nil || self.rollAttribute != nil)
            rpgExpandedReject('boating-context-definition');
        self.skill.validateDefinition(); rpgInteger(self.conditionsPenalty,-100,0);
        if (self.conditionsPenalty < 0 && self.conditionsPenalty > -3)
            rpgExpandedReject('boating-context-minimum-penalty');
        if (self.conditionsPenalty != 0 && (self.evidence == nil || self.evidence == ''))
            rpgExpandedReject('boating-context-evidence');
        if (self.familiarity != nil && self.familiarity.penalty != -2)
            rpgExpandedReject('boating-familiarity-penalty');
        return nil;
    }
    checkRequired(profile)
    {
        self.validateBoating();
        if (self.eventKind == 'routine') return nil;
        return self.eventKind != 'enter' || rpgExpandedPaidSkill(profile,self.skill,[]) == nil;
    }
    unavailableReason(profile)
    {
        if (!self.checkRequired(profile)) return 'boating-check-not-required';
        return inherited(profile);
    }
    skillUseModifier(profile)
    {
        self.validateBoating(); local base = inherited(profile);
        return base == nil ? nil : base + self.conditionsPenalty;
    }
;
