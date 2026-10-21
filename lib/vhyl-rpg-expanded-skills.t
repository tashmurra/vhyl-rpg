/* Include after the expanded foundation. Source: full-2008, B170, B173, B175, B230. */

/** Authored expanded skill. Defaults are explicit [skill, penalty] pairs.
 * A catalogue is not implied by this definition type. */
class RpgExpandedSkill: RpgLiteSkill
    validateDefinition() { return nil; }
    studyIdentity() { rpgExpandedValidateSkill(self); return self.optionalParent == nil ? self.id : self.optionalParent.id; }
    studySpecialty() { rpgExpandedValidateSkill(self); return self.optionalParent == nil ? self.specialty : self.optionalParent.specialty; }
    defaults = []
    attributeDefaults = []
    attributeDefaultAllowed(profile) { return self.optionalParent == nil ? true : self.optionalParent.attributeDefaultAllowed(profile); }
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
    if (skill.defaultPenalty != nil && (!skill.ofKind(RpgExpandedSkill) || skill.attributeDefaultAllowed(profile)))
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
        local phobiaReason = self.phobiaSkillLearningReason(skill); if (phobiaReason != nil) return phobiaReason;
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
        value.reason = self.owner.nonTravelScheduleReason(rpgLedger.seconds,seconds);
        if (value.reason != nil) return value;
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
    taskUnavailableReason(profile)
    {
        if (self.technologyModifierFor(profile) == nil) return self.technologyUnavailableReason(profile);
        return inherited(profile);
    }
    unavailableReason(profile)
    {
        local reason = self.taskUnavailableReason(profile);
        return reason == nil ? inherited(profile) : reason;
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
    parent.validateDefinition();
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
            if (source == self || training.points <= 0) continue;
            local general = source.ofKind(RpgExpandedSkill) && source.optionalParent != nil ? source.optionalParent : source;
            if (general.ofKind(RpgExpandedBiologySkill) && general.specialty == self.planetType)
            { general.validateDefinition(); edges = edges + [[general,-3]]; }
            if (!source.ofKind(RpgExpandedNaturalistSkill)) continue;
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
/** Boating context. Carries eventKind, conditionsPenalty, evidence. Operations: validateBoating, checkRequired, taskUnavailableReason, skillUseModifier. */
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
    taskUnavailableReason(profile)
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


modify RpgExpandedBoatingContext
    boatEntryDefinition()
    {
        self.validateBoating();
        if (self.eventKind != 'enter') rpgExpandedReject('boat-entry-context-event');
        return [self.skill,self.skill.techLevel,self.skill.specialty,self.eventKind,self.conditionsPenalty,
            self.evidence,self.familiarity,self.equipmentTL,self.modifier];
    }
    assessBoatEntry(profile)
    {
        self.boatEntryDefinition(); local value = new RpgExpandedBoatEntryAssessment();
        value.checkRequired = self.checkRequired(profile);
        if (value.checkRequired)
        {
            value.reason = self.taskUnavailableReason(profile); if (value.reason != nil) return value;
            local score = rpgLiteScore(profile,self);
            if (score == nil || score < 3) { value.reason = 'boat-entry-score-unavailable'; return value; }
        }
        value.status = 'ready'; return value;
    }
;

/** Full-2008 B182 trained health-based breath efficiency, without defaults. */
class RpgExpandedBreathControlSkill: RpgExpandedSkill
    id = 'breathing-control'
    attribute = rpgHT
    difficulty = 2
    validateDefinition()
    {
        if (self.id != 'breathing-control' || self.attribute != rpgHT || self.difficulty != 2
            || self.defaultPenalty != nil || self.defaultAttribute != nil || self.alternateAttribute != nil
            || self.defaults.length() != 0 || self.attributeDefaults.length() != 0 || self.wildcard
            || self.optionalParent != nil || self.specialty != nil || self.techLevel != nil)
            rpgExpandedReject('breath-control-skill-definition');
        return nil;
    }
    validateBreathControl() { return self.validateDefinition(); }
;

/** Full-2008 B187: perception-based lie detection and purchased skill defaults. */
class RpgExpandedLieDetectionSkill: RpgExpandedSkill
    id = 'lie-detection'
    attribute = rpgPerception
    difficulty = 2
    defaultPenalty = -6
    validateDefinition()
    {
        if (self.id != 'lie-detection' || self.attribute != rpgPerception || self.difficulty != 2
            || self.defaultPenalty != -6 || self.defaultAttribute != nil || self.alternateAttribute != nil
            || self.defaults.length() != 0 || self.attributeDefaults.length() != 0 || self.wildcard
            || self.optionalParent != nil || self.specialty != nil || self.techLevel != nil)
            rpgExpandedReject('lie-detection-skill-definition');
        return nil;
    }
    validateLieDetection() { return self.validateDefinition(); }
    defaultEdges(profile)
    {
        local edges = inherited(profile);
        foreach (local training in profile.skills)
            if (training.points > 0 && training.skill != self && training.skill.ofKind(RpgLiteSkill)
                && holds(['body-reading','psychology'],training.skill.studyIdentity()) && training.skill.socialInferenceDefaultEligible())
                edges = edges + [[training.skill,-4]];
        return edges;
    }
;

/** Full-2008 B181 visual body reading; no attribute default. */
class RpgExpandedBodyReadingSkill: RpgExpandedSkill
    id = 'body-reading'
    attribute = rpgPerception
    difficulty = 1
    validateDefinition()
    {
        if (self.id != 'body-reading' || self.attribute != rpgPerception || self.difficulty != 1
            || self.defaultPenalty != nil || self.defaultAttribute != nil || self.alternateAttribute != nil
            || self.defaults.length() != 0 || self.attributeDefaults.length() != 0 || self.wildcard
            || self.optionalParent != nil || self.specialty != nil || self.techLevel != nil)
            rpgExpandedReject('body-reading-skill-definition');
        return nil;
    }
    validateBodyReading() { return self.validateDefinition(); }
    defaultEdges(profile)
    {
        local edges = inherited(profile);
        foreach (local training in profile.skills)
            if (training.points > 0 && training.skill != self && training.skill.ofKind(RpgLiteSkill)
                && holds(['lie-detection','psychology'],training.skill.studyIdentity()) && training.skill.socialInferenceDefaultEligible())
                edges = edges + [[training.skill,-4]];
        return edges;
    }
;

/** Full-2008 B181 one physiology check for one authored operation. */
class RpgExpandedPhysiologyCheck: RpgExpandedPhysiologyReceipt
    id = nil
    profile = nil
    subject = nil
    operation = nil
    species = nil
    planetType = nil
    skill = nil
    commonAnimal = nil
    machine = nil
    approved = nil
    evidence = nil
    boundDefinition = nil
    result = nil
    boundSucceeded = nil
    definition()
    { return [self.id,self.profile,self.subject,self.operation,self.species,self.planetType,self.skill,self.commonAnimal,self.machine,self.approved,self.evidence]; }
    validateReceipt()
    {
        if (self.result == nil || self.boundDefinition == nil || !holds(self.profile.physiologyChecks,self))
            rpgExpandedReject('physiology-check-history');
        local facts = self.definition();
        for (local i = 1; i <= facts.length(); i += 1)
            if (facts[i] != self.boundDefinition[i]) rpgExpandedReject('physiology-check-binding');
        if (self.result.check == nil || self.result.check.achieved != self.boundSucceeded)
            rpgExpandedReject('physiology-check-result-binding');
        return nil;
    }
    assess()
    {
        local value = new RpgExpandedResult();
        if (self.result != nil) { self.validateReceipt(); value.status = 'reused'; return value; }
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)
            || self.subject == nil || !self.subject.ofKind(RpgLiteProfile) || self.operation == nil
            || self.species == nil || self.species == '' || self.skill == nil || !self.skill.ofKind(RpgLiteSkill))
            rpgExpandedReject('physiology-check-definition');
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'physiology-check-facts-required'; return value; }
        if (self.machine) { value.reason = 'physiology-check-machine-inapplicable'; return value; }
        if (self.profile.dead || self.profile.unconscious) { value.reason = 'physiology-check-observer-unavailable'; return value; }
        if (self.skill.attribute != rpgIQ || self.skill.techLevel == nil) rpgExpandedReject('physiology-check-skill');
        if (self.skill.id == 'physiology')
        {
            if (self.skill.difficulty != 2 || self.skill.specialty != self.species) rpgExpandedReject('physiology-check-specialty');
        }
        else if (self.skill.id == 'biology')
        {
            if (self.skill.difficulty != 3 || !self.commonAnimal || self.planetType == nil
                || self.skill.specialty != self.planetType) rpgExpandedReject('physiology-check-biology-context');
            value.modifier = -4;
        }
        else rpgExpandedReject('physiology-check-skill');
        foreach (local prior in self.profile.physiologyChecks)
            if (prior.id == self.id || prior.operation == self.operation) rpgExpandedReject('physiology-check-repeat-operation');
        local context = new RpgLiteContext(); context.skill = self.skill; context.kind = 'physiology-familiarity'; context.modifier = value.modifier;
        local score = rpgLiteScore(self.profile,context);
        if (score == nil || score < 3) { value.reason = 'physiology-check-score-unavailable'; return value; }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local context = new RpgLiteContext(); context.skill = self.skill; context.kind = 'physiology-familiarity'; context.modifier = value.modifier;
        value.check = rpgLiteCheck(self.profile,context); self.boundSucceeded = value.check.achieved;
        self.boundDefinition = self.definition(); value.status = 'resolved'; self.result = value;
        self.profile.physiologyChecks = self.profile.physiologyChecks + [self]; return value;
    }
;
modify RpgExpandedProfile
    physiologyChecks = []
;

/** Full-2008 B187 diagnosis at an explicit technology level. */
class RpgExpandedDiagnosisSkill: RpgExpandedSkill
    id = 'diagnosis'
    attribute = rpgIQ
    difficulty = 2
    defaultPenalty = -6
    validateDefinition()
    {
        if (self.id != 'diagnosis' || self.attribute != rpgIQ || self.difficulty != 2 || self.defaultPenalty != -6
            || self.defaultAttribute != nil || self.alternateAttribute != nil || self.defaults.length() != 0
            || self.attributeDefaults.length() != 0 || self.wildcard || self.optionalParent != nil || self.specialty != nil
            || self.techLevel == nil) rpgExpandedReject('diagnosis-skill-definition');
        rpgInteger(self.techLevel,0,12); return nil;
    }
    validateDiagnosis() { return self.validateDefinition(); }
    defaultEdges(profile)
    {
        local edges = inherited(profile);
        foreach (local training in profile.skills)
        {
            local source = training.skill;
            if (training.points <= 0 || source == self || !source.ofKind(RpgLiteSkill) || source.techLevel != self.techLevel) continue;
            local penalty = source.id == 'first-aid' ? -8 : source.id == 'physician' ? -4 : source.id == 'veterinary' ? -5 : nil;
            if (penalty != nil) edges = edges + [[source,penalty]];
        }
        return edges;
    }
;

modify RpgExpandedDiagnosisSkill
    diagnosisContext(equipmentTL)
    {
        self.validateDefinition(); local context = new RpgExpandedSkillContext();
        context.skill = self; context.kind = 'diagnosis'; context.equipmentTL = equipmentTL; return context;
    }
;

/** Full-2008 B213: an authored relationship between species specialties. */
class RpgExpandedPhysiologyDefault: object
    source = nil
    penalty = nil
    approved = nil
    evidence = nil
    assessFor(target)
    {
        if (self.source == nil || !self.source.ofKind(RpgExpandedPhysiologySkill)
            || self.source == target || self.source.specialty == target.specialty
            || self.source.techLevel != target.techLevel)
            rpgExpandedReject('physiology-default-source');
        if (!self.approved || self.evidence == nil || self.evidence == '')
            rpgExpandedReject('physiology-default-evidence');
        rpgInteger(self.penalty,-100,0); return [self.source,self.penalty];
    }
;

/** B213 printed defaults plus explicit author decisions between species. */
class RpgExpandedPhysiologySkill: RpgExpandedSkill
    id = 'physiology'
    attribute = rpgIQ
    difficulty = 2
    defaultPenalty = -6
    speciesDefaults = []
    validateDefinition()
    {
        if (self.id != 'physiology' || self.attribute != rpgIQ || self.difficulty != 2 || self.defaultPenalty != -6
            || self.defaultAttribute != nil || self.alternateAttribute != nil || self.defaults.length() != 0
            || self.attributeDefaults.length() != 0 || self.wildcard || self.optionalParent != nil
            || self.specialty == nil || self.specialty == '' || self.techLevel == nil)
            rpgExpandedReject('physiology-skill-definition');
        rpgInteger(self.techLevel,0,12);
        local seen = [];
        foreach (local relation in self.speciesDefaults)
        {
            if (relation == nil || !relation.ofKind(RpgExpandedPhysiologyDefault))
                rpgExpandedReject('physiology-default-definition');
            local pair = relation.assessFor(self);
            if (holds(seen,pair[1])) rpgExpandedReject('physiology-default-duplicate');
            seen = seen + [pair[1]];
        }
        return nil;
    }
    defaultEdges(profile)
    {
        local edges = inherited(profile);
        foreach (local training in profile.skills)
        {
            local source = training.skill;
            if (training.points <= 0 || source == self || !source.ofKind(RpgLiteSkill) || source.techLevel != self.techLevel) continue;
            if (holds(['diagnosis','physician','surgery'],source.id)) edges = edges + [[source,-5]];
        }
        foreach (local relation in self.speciesDefaults) edges = edges + [relation.assessFor(self)];
        return edges;
    }
;

/** Full-2008 B213. Early scientific medicine requires a setting decision. */
class RpgExpandedPhysicianSkill: RpgExpandedSkill
    id = 'physician'
    attribute = rpgIQ
    difficulty = 2
    defaultPenalty = -7
    earlyMedicineApproved = nil
    earlyMedicineEvidence = nil
    validateDefinition()
    {
        if (self.id != 'physician' || self.attribute != rpgIQ || self.difficulty != 2 || self.defaultPenalty != -7
            || self.defaultAttribute != nil || self.alternateAttribute != nil || self.defaults.length() != 0
            || self.attributeDefaults.length() != 0 || self.wildcard || self.optionalParent != nil || self.specialty != nil
            || self.techLevel == nil) rpgExpandedReject('physician-skill-definition');
        rpgInteger(self.techLevel,0,12);
        if (self.techLevel <= 4 && (!self.earlyMedicineApproved || self.earlyMedicineEvidence == nil || self.earlyMedicineEvidence == ''))
            rpgExpandedReject('physician-early-medicine-evidence');
        return nil;
    }
    defaultEdges(profile)
    {
        local edges = inherited(profile);
        foreach (local training in profile.skills)
        {
            local source = training.skill;
            if (training.points <= 0 || source == self || !source.ofKind(RpgLiteSkill) || source.techLevel != self.techLevel) continue;
            local penalty = source.id == 'first-aid' ? -11 : source.id == 'veterinary' ? -5 : nil;
            if (penalty != nil) edges = edges + [[source,penalty]];
        }
        return edges;
    }
;

/** Full-2008 B195. Traditional treatment is not technology-qualified (B192). */
class RpgExpandedFirstAidSkill: RpgExpandedSkill
    id = 'first-aid'
    attribute = rpgIQ
    difficulty = 0
    defaultPenalty = -4
    validateDefinition()
    {
        if (self.id != 'first-aid' || self.attribute != rpgIQ || self.difficulty != 0 || self.defaultPenalty != -4
            || self.defaultAttribute != nil || self.alternateAttribute != nil || self.defaults.length() != 0
            || self.attributeDefaults.length() != 0 || self.wildcard || self.optionalParent != nil || self.specialty != nil
            || self.techLevel == nil) rpgExpandedReject('first-aid-skill-definition');
        rpgInteger(self.techLevel,0,12); return nil;
    }
    defaultEdges(profile)
    {
        local edges = inherited(profile);
        foreach (local training in profile.skills)
        {
            local source = training.skill;
            if (training.points <= 0 || source == self || !source.ofKind(RpgLiteSkill)) continue;
            if (source.id == 'traditional-treatment' && source.techLevel == nil) edges = edges + [[source,0]];
            else if (source.techLevel == self.techLevel)
            {
                local penalty = source.id == 'physician' ? 0 : source.id == 'veterinary' ? -4 : nil;
                if (penalty != nil) edges = edges + [[source,penalty]];
            }
        }
        return edges;
    }
;

modify RpgExpandedFirstAidSkill
    firstAidContext(equipmentTL)
    {
        self.validateDefinition(); local context = new RpgExpandedSkillContext();
        context.skill = self; context.kind = 'first-aid'; context.equipmentTL = equipmentTL; return context;
    }
;

/** B180 native background for conditional scientific attribute defaults. */
modify RpgExpandedProfile
    nativePlanetType = nil
    validateFeatures()
    {
        inherited();
        if (self.nativePlanetType != nil
            && !holds(['habitable','gas-giant','hostile-terrestrial','icy-small-body','ice-covered','rocky'],self.nativePlanetType))
            rpgExpandedReject('biology-native-planet-type');
        return nil;
    }
;

/** B180 biology: scientific knowledge of a planet type at an explicit TL. */
class RpgExpandedBiologySkill: RpgExpandedSkill
    id = 'biology'
    attribute = rpgIQ
    difficulty = 3
    defaultPenalty = -6
    validateDefinition()
    {
        if (self.id != 'biology' || self.attribute != rpgIQ || self.difficulty != 3 || self.defaultPenalty != -6
            || self.defaultAttribute != nil || self.alternateAttribute != nil || self.defaults.length() != 0
            || self.attributeDefaults.length() != 0 || self.wildcard || self.optionalParent != nil || self.techLevel == nil
            || !holds(['habitable','gas-giant','hostile-terrestrial','icy-small-body','ice-covered','rocky'],self.specialty))
            rpgExpandedReject('biology-skill-definition');
        rpgInteger(self.techLevel,0,12); return nil;
    }
    attributeDefaultAllowed(profile)
    {
        if (profile.nativePlanetType != nil
            && !holds(['habitable','gas-giant','hostile-terrestrial','icy-small-body','ice-covered','rocky'],profile.nativePlanetType))
            rpgExpandedReject('biology-native-planet-type');
        return profile.nativePlanetType == self.specialty;
    }
    defaultEdges(profile)
    {
        local edges = inherited(profile);
        foreach (local training in profile.skills)
        {
            local source = training.skill;
            if (training.points <= 0 || source == self) continue;
            local general = source.ofKind(RpgExpandedSkill) && source.optionalParent != nil ? source.optionalParent : source;
            if (general.ofKind(RpgExpandedBiologySkill) && general.techLevel == self.techLevel && general.specialty != self.specialty)
            { general.validateDefinition(); edges = edges + [[general,-4]]; }
            if (source.ofKind(RpgExpandedNaturalistSkill) && source.planetType == self.specialty)
            { source.validateDefinition(); edges = edges + [[source,-6]]; }
        }
        return edges;
    }
;

/** B169-B170/B180 approved biology subfield, tied to one planet-type parent. */
class RpgExpandedBiologySubfield: RpgExpandedSkill
    attribute = rpgIQ
    difficulty = 2
    subfieldEvidence = nil
    validateDefinition()
    {
        if (self.optionalParent == nil || !self.optionalParent.ofKind(RpgExpandedBiologySkill)
            || self.attribute != rpgIQ || self.difficulty != 2 || self.defaultPenalty != nil
            || self.defaultAttribute != nil || self.alternateAttribute != nil || self.defaults.length() != 0
            || self.attributeDefaults.length() != 0 || self.wildcard)
            rpgExpandedReject('biology-subfield-definition');
        if (self.subfieldEvidence == nil || self.subfieldEvidence == '') rpgExpandedReject('biology-subfield-evidence');
        return nil;
    }
;
/** Biology subfield. */
rpgExpandedBiologySubfield(parent,id,subfield,approved,evidence)
{
    if (parent == nil || !parent.ofKind(RpgExpandedBiologySkill)) rpgExpandedReject('biology-subfield-parent');
    local value = new RpgExpandedBiologySubfield(); value.optionalParent = parent;
    value.id = id; value.specialty = subfield; value.optionalApproved = approved;
    value.subfieldEvidence = evidence; value.techLevel = parent.techLevel; value.prerequisite = parent.prerequisite;
    rpgExpandedValidateSkill(value); return value;
}

modify RpgExpandedNaturalistSkill
    validateNatureObservation(planet,planetType)
    {
        self.validateDefinition();
        if (self.planet != planet || self.planetType != planetType) rpgExpandedReject('nature-observation-planet');
        return nil;
    }
;

/** Full-2008 B228 veterinary defaults; no attribute default. */
class RpgExpandedVeterinarySkill: RpgExpandedSkill
    id = 'veterinary'
    attribute = rpgIQ
    difficulty = 2
    defaultPenalty = nil
    validateDefinition()
    {
        if (self.id != 'veterinary' || self.attribute != rpgIQ || self.difficulty != 2 || self.defaultPenalty != nil
            || self.defaultAttribute != nil || self.alternateAttribute != nil || self.defaults.length() != 0
            || self.attributeDefaults.length() != 0 || self.wildcard || self.optionalParent != nil || self.specialty != nil
            || self.techLevel == nil) rpgExpandedReject('veterinary-skill-definition');
        rpgInteger(self.techLevel,0,12); return nil;
    }
    defaultEdges(profile)
    {
        local edges = inherited(profile);
        foreach (local training in profile.skills)
        {
            local source = training.skill;
            if (training.points <= 0 || source == self || !source.ofKind(RpgLiteSkill)) continue;
            if (source.id == 'animal-handling' && source.techLevel == nil) edges = edges + [[source,-6]];
            else if (source.techLevel == self.techLevel && holds(['physician','surgery'],source.id)) edges = edges + [[source,-5]];
        }
        return edges;
    }
;

/** B228 situational modifiers, distinct from treatment execution. */
class RpgExpandedVeterinaryContext: RpgExpandedSkillContext
    animal = nil
    animalType = nil
    knowsAndTrusts = nil
    unfamiliarPenalty = 0
    approved = nil
    evidence = nil
    validateVeterinary()
    {
        if (self.skill == nil || !self.skill.ofKind(RpgExpandedSkill) || self.animal == nil
            || !self.animal.ofKind(RpgLiteProfile) || self.animalType == nil || self.animalType == ''
            || self.fixedBase != nil || self.rollAttribute != nil || self.familiarity != nil)
            rpgExpandedReject('veterinary-context-definition');
        rpgExpandedValidateSkill(self.skill);
        local parent = self.skill.optionalParent;
        if (parent == nil)
        { if (!self.skill.ofKind(RpgExpandedVeterinarySkill)) rpgExpandedReject('veterinary-context-skill'); }
        else if (!parent.ofKind(RpgExpandedVeterinarySkill) || self.skill.specialty != self.animalType)
            rpgExpandedReject('veterinary-context-specialty');
        if (!self.approved || self.evidence == nil || self.evidence == '') rpgExpandedReject('veterinary-context-evidence');
        rpgInteger(self.unfamiliarPenalty,-100,0);
        if (self.unfamiliarPenalty == -1) rpgExpandedReject('veterinary-unfamiliar-minimum');
        return nil;
    }
    taskUnavailableReason(profile) { self.validateVeterinary(); return inherited(profile); }
    skillUseModifier(profile)
    {
        self.validateVeterinary(); local base = inherited(profile);
        return base == nil ? nil : base + self.unfamiliarPenalty + (self.knowsAndTrusts ? 5 : 0);
    }
;

/** B175 authored taxonomy relationship; avoids guessing categories for fictional fauna. */
class RpgExpandedAnimalHandlingDefault: object
    source = nil
    relationship = nil
    approved = nil
    evidence = nil
    edge(target)
    {
        if (self.source == nil || !self.source.ofKind(RpgExpandedAnimalHandlingSkill)
            || self.source == target || self.source.specialty == target.specialty)
            rpgExpandedReject('animal-handling-default-source');
        if (!self.approved || self.evidence == nil || self.evidence == '') rpgExpandedReject('animal-handling-default-evidence');
        if (!holds(['same-order','different-order','distant'],self.relationship)) rpgExpandedReject('animal-handling-default-relationship');
        return [self.source,self.relationship == 'same-order' ? -2 : self.relationship == 'different-order' ? -4 : -6];
    }
;
/** Animal handling skill. Carries id, attribute, difficulty, defaultPenalty, relationships. Operations: validateDefinition, defaultEdges. */
class RpgExpandedAnimalHandlingSkill: RpgExpandedSkill
    id = 'animal-handling'
    attribute = rpgIQ
    difficulty = 1
    defaultPenalty = -5
    relationships = []
    validateDefinition()
    {
        if (self.id != 'animal-handling' || self.attribute != rpgIQ || self.difficulty != 1 || self.defaultPenalty != -5
            || self.defaultAttribute != nil || self.alternateAttribute != nil || self.defaults.length() != 0
            || self.attributeDefaults.length() != 0 || self.wildcard || self.optionalParent != nil || self.techLevel != nil
            || self.specialty == nil || self.specialty == '') rpgExpandedReject('animal-handling-skill-definition');
        local sources = [];
        foreach (local relation in self.relationships)
        {
            if (relation == nil || !relation.ofKind(RpgExpandedAnimalHandlingDefault)) rpgExpandedReject('animal-handling-default-definition');
            local edge = relation.edge(self);
            if (holds(sources,edge[1])) rpgExpandedReject('animal-handling-default-duplicate');
            sources = sources + [edge[1]];
        }
        return nil;
    }
    defaultEdges(profile)
    {
        local edges = inherited(profile);
        foreach (local relation in self.relationships) edges = edges + [relation.edge(self)];
        return edges;
    }
;

modify RpgLiteSkill
    socialInferenceDefaultEligible() { return true; }
;

/** B216 psychology, with an explicit optional campaign split. */
class RpgExpandedPsychologySkill: RpgExpandedSkill
    id = 'psychology'
    attribute = rpgIQ
    difficulty = 2
    defaultPenalty = -6
    discipline = 'general'
    splitApproved = nil
    splitEvidence = nil
    speciesDefaults = []
    socialInferenceDefaultEligible() { self.validateDefinition(); return self.discipline != 'experimental'; }
    validateDefinition()
    {
        if (self.id != 'psychology' || self.attribute != rpgIQ || self.difficulty != 2 || self.defaultPenalty != -6
            || self.defaultAttribute != nil || self.alternateAttribute != nil || self.defaults.length() != 0
            || self.attributeDefaults.length() != 0 || self.wildcard || self.optionalParent != nil || self.techLevel != nil
            || self.specialty == nil || self.specialty == '' || !holds(['general','applied','experimental'],self.discipline))
            rpgExpandedReject('psychology-skill-definition');
        if (self.discipline != 'general' && (!self.splitApproved || self.splitEvidence == nil || self.splitEvidence == ''))
            rpgExpandedReject('psychology-split-evidence');
        local seen = [];
        foreach (local relation in self.speciesDefaults)
        {
            if (relation == nil || !relation.ofKind(RpgExpandedPsychologyDefault)) rpgExpandedReject('psychology-default-definition');
            local edge = relation.edge(self);
            if (holds(seen,edge[1])) rpgExpandedReject('psychology-default-duplicate');
            seen = seen + [edge[1]];
        }
        return nil;
    }
    defaultEdges(profile)
    {
        local edges = inherited(profile);
        foreach (local training in profile.skills)
        {
            local source = training.skill;
            if (training.points <= 0 || source == self || !source.ofKind(RpgLiteSkill)) continue;
            if (source.id == 'sociology' && (source.specialty == nil || source.specialty == self.specialty) && source.techLevel == nil) edges = edges + [[source,-4]];
            if (self.discipline == 'applied' && source.ofKind(RpgExpandedPsychologySkill)
                && source.discipline == 'experimental' && source.specialty == self.specialty)
            { source.validateDefinition(); edges = edges + [[source,-5]]; }
        }
        foreach (local relation in self.speciesDefaults) edges = edges + [relation.edge(self)];
        return edges;
    }
;
/** Psychology default. Carries source, penalty, approved, evidence. Operations: edge. */
class RpgExpandedPsychologyDefault: object
    source = nil
    penalty = nil
    approved = nil
    evidence = nil
    edge(target)
    {
        if (self.source == nil || !self.source.ofKind(RpgExpandedPsychologySkill) || self.source == target
            || self.source.specialty == target.specialty || self.source.discipline != target.discipline)
            rpgExpandedReject('psychology-default-source');
        if (!self.approved || self.evidence == nil || self.evidence == '') rpgExpandedReject('psychology-default-evidence');
        rpgInteger(self.penalty,-100,0); return [self.source,self.penalty];
    }
;

/** B216 individual psychology modifiers, with explicit situational evidence. */
class RpgExpandedPsychologyContext: RpgExpandedSkillContext
    subject = nil
    group = nil
    members = []
    smallGroupApproved = nil
    psychologySubjectIdentity() { return self.group == nil ? self.subject : self.group; }
    subjectSpecies = nil
    purpose = 'prediction'
    knownWell = nil
    knownPersonalityType = nil
    subjectPresent = nil
    empathyModifier = 0
    approved = nil
    evidence = nil
    validatePsychology()
    {
        if (self.skill == nil || !self.skill.ofKind(RpgExpandedPsychologySkill)
            || self.subjectSpecies == nil
            || self.subjectSpecies != self.skill.specialty || self.fixedBase != nil || self.rollAttribute != nil)
            rpgExpandedReject('psychology-context-definition');
        if (self.group == nil)
        {
            if (self.subject == nil || !self.subject.ofKind(RpgLiteProfile) || self.members.length() != 0 || self.smallGroupApproved)
                rpgExpandedReject('psychology-context-subject');
        }
        else
        {
            if (self.subject != nil || self.members.length() < 2 || !self.smallGroupApproved)
                rpgExpandedReject('psychology-context-small-group');
            if (self.purpose != 'prediction' || self.knownWell || self.knownPersonalityType || self.subjectPresent || self.empathyModifier != 0)
                rpgExpandedReject('psychology-group-individual-modifiers');
            local seen = [];
            foreach (local member in self.members)
            {
                if (member == nil || !member.ofKind(RpgLiteProfile) || holds(seen,member)) rpgExpandedReject('psychology-group-members');
                seen = seen + [member];
            }
        }
        self.skill.validateDefinition();
        if (self.skill.discipline == 'experimental') rpgExpandedReject('psychology-applied-context-required');
        if (!holds(['prediction','diagnosis','exploit-weakness'],self.purpose)) rpgExpandedReject('psychology-context-purpose');
        if (!self.approved || self.evidence == nil || self.evidence == '') rpgExpandedReject('psychology-context-evidence');
        if (!holds([-3,0,1,3],self.empathyModifier)) rpgExpandedReject('psychology-context-empathy');
        if (self.empathyModifier != 0 && (self.purpose != 'diagnosis' || !self.subjectPresent))
            rpgExpandedReject('psychology-empathy-inapplicable');
        return nil;
    }
    taskUnavailableReason(profile) { self.validatePsychology(); return inherited(profile); }
    skillUseModifier(profile)
    {
        self.validatePsychology(); local base = inherited(profile);
        if (base == nil) return nil;
        return base + (self.knownWell ? 3 : 0) + (self.knownPersonalityType ? 3 : 0) + self.empathyModifier
            - (profile.callousnessActive() && self.purpose != 'exploit-weakness' ? 3 : 0);
    }
;

modify RpgExpandedPsychologyContext
    psychologyFacts()
    {
        self.validatePsychology();
        return [self.skill,self.subject,self.subjectSpecies,self.purpose,self.knownWell,self.knownPersonalityType,
            self.subjectPresent,self.empathyModifier,self.approved,self.evidence,self.modifier,
            self.skill.specialty,self.skill.discipline,self.skill.splitApproved,self.skill.splitEvidence,
            self.group,self.smallGroupApproved,self.members.length()] + self.members + self.culturalTaskFacts();
    }
;

/** One campaign representation per species; split disciplines remain separate purchases. */
modify RpgExpandedProfile
    validateFeatures()
    {
        inherited(); local psychology = [];
        foreach (local training in self.skills)
        {
            local skill = training.skill;
            if (training.points <= 0 || !skill.ofKind(RpgExpandedPsychologySkill)) continue;
            foreach (local prior in psychology)
                if (prior.specialty == skill.specialty)
                {
                    if (prior.discipline == skill.discipline) rpgExpandedReject('psychology-duplicate-discipline');
                    if (prior.discipline == 'general' || skill.discipline == 'general')
                        rpgExpandedReject('psychology-mixed-campaign-split');
                }
            psychology = psychology + [skill];
        }
        return nil;
    }
;

/** Full-2008 B221: sociology concerns societies, without a required species specialty. */
class RpgExpandedSociologySkill: RpgExpandedSkill
    id = 'sociology'
    attribute = rpgIQ
    difficulty = 2
    defaultPenalty = -6
    validateDefinition()
    {
        if (self.id != 'sociology' || self.attribute != rpgIQ || self.difficulty != 2 || self.defaultPenalty != -6
            || self.defaultAttribute != nil || self.alternateAttribute != nil || self.defaults.length() != 0
            || self.attributeDefaults.length() != 0 || self.wildcard || self.optionalParent != nil
            || self.specialty != nil || self.techLevel != nil) rpgExpandedReject('sociology-skill-definition');
        return nil;
    }
    defaultEdges(profile)
    {
        local edges = inherited(profile);
        foreach (local training in profile.skills)
        {
            local source = training.skill;
            if (training.points <= 0 || source == self || !source.ofKind(RpgLiteSkill) || source.techLevel != nil) continue;
            local general = source.ofKind(RpgExpandedSkill) && source.optionalParent != nil ? source.optionalParent : source;
            local penalty = general.id == 'anthropology' ? -3
                : general.id == 'psychology' && general.socialInferenceDefaultEligible() ? -4 : nil;
            if (penalty != nil) edges = edges + [[general,penalty]];
        }
        return edges;
    }
;

/** Full-2008 B175: explicit related-species defaults, absent for unrelated species. */
class RpgExpandedAnthropologyDefault: object
    source = nil
    penalty = nil
    approved = nil
    evidence = nil
    edge(target)
    {
        if (self.source == nil || !self.source.ofKind(RpgExpandedAnthropologySkill) || self.source == target
            || self.source.specialty == target.specialty) rpgExpandedReject('anthropology-default-source');
        if (!self.approved || self.evidence == nil || self.evidence == '') rpgExpandedReject('anthropology-default-evidence');
        rpgInteger(self.penalty,-5,-2); return [self.source,self.penalty];
    }
;
/** Anthropology skill. Carries id, attribute, difficulty, defaultPenalty, speciesDefaults. Operations: validateDefinition, defaultEdges. */
class RpgExpandedAnthropologySkill: RpgExpandedSkill
    id = 'anthropology'
    attribute = rpgIQ
    difficulty = 2
    defaultPenalty = -6
    speciesDefaults = []
    validateDefinition()
    {
        if (self.id != 'anthropology' || self.attribute != rpgIQ || self.difficulty != 2 || self.defaultPenalty != -6
            || self.defaultAttribute != nil || self.alternateAttribute != nil || self.defaults.length() != 0
            || self.attributeDefaults.length() != 0 || self.wildcard || self.optionalParent != nil || self.techLevel != nil
            || self.specialty == nil || self.specialty == '') rpgExpandedReject('anthropology-skill-definition');
        local seen = [];
        foreach (local relation in self.speciesDefaults)
        {
            if (relation == nil || !relation.ofKind(RpgExpandedAnthropologyDefault)) rpgExpandedReject('anthropology-default-definition');
            local edge = relation.edge(self);
            if (holds(seen,edge[1])) rpgExpandedReject('anthropology-default-duplicate');
            seen = seen + [edge[1]];
        }
        return nil;
    }
    defaultEdges(profile)
    {
        local edges = inherited(profile);
        foreach (local training in profile.skills)
        {
            local source = training.skill;
            if (training.points <= 0 || source == self || !source.ofKind(RpgLiteSkill)) continue;
            local general = source.ofKind(RpgExpandedSkill) && source.optionalParent != nil ? source.optionalParent : source;
            if (general.id == 'sociology' && general.techLevel == nil) edges = edges + [[general,-3]];
            if (general.id == 'paleontology' && general.specialty == 'human-origins' && general.techLevel != nil)
                edges = edges + [[general,-2]];
        }
        foreach (local relation in self.speciesDefaults) edges = edges + [relation.edge(self)];
        return edges;
    }
;

/** Full-2008 B212 fossil-study specialties and their printed defaults. */
class RpgExpandedPaleontologySkill: RpgExpandedSkill
    id = 'paleontology'
    attribute = rpgIQ
    difficulty = 2
    defaultPenalty = nil
    validateDefinition()
    {
        if (self.id != 'paleontology' || self.attribute != rpgIQ || self.difficulty != 2 || self.defaultPenalty != nil
            || self.defaultAttribute != nil || self.alternateAttribute != nil || self.defaults.length() != 0
            || self.attributeDefaults.length() != 0 || self.wildcard || self.optionalParent != nil || self.techLevel == nil
            || !holds(['microscopic','human-origins','plants','animals'],self.specialty))
            rpgExpandedReject('paleontology-skill-definition');
        rpgInteger(self.techLevel,0,12); return nil;
    }
    defaultEdges(profile)
    {
        local edges = inherited(profile);
        foreach (local training in profile.skills)
        {
            local source = training.skill;
            if (training.points <= 0 || source == self || !source.ofKind(RpgLiteSkill)) continue;
            local general = source.ofKind(RpgExpandedSkill) && source.optionalParent != nil ? source.optionalParent : source;
            if (general.id == 'biology' && general.techLevel == self.techLevel) edges = edges + [[general,-4]];
            if (self.specialty == 'human-origins' && general.id == 'anthropology' && general.techLevel == nil) edges = edges + [[general,-2]];
            if (general.ofKind(RpgExpandedPaleontologySkill) && general.techLevel == self.techLevel && general.specialty != self.specialty)
            { general.validateDefinition(); edges = edges + [[general,-2]]; }
        }
        return edges;
    }
;
/** Paleontology context. Carries laboratoryEquipment, task, laboratory, equipmentModifier, approved. Operations: validatePaleontology, taskUnavailableReason, skillUseModifier, technologyModifierFor. */
class RpgExpandedPaleontologyContext: RpgExpandedSkillContext
    laboratoryEquipment = nil
    task = 'recognition'
    laboratory = nil
    equipmentModifier = 0
    approved = nil
    evidence = nil
    validatePaleontology()
    {
        if (self.skill == nil || !self.skill.ofKind(RpgExpandedPaleontologySkill)
            || !holds(['recognition','habitat','structure','age'],self.task) || self.fixedBase != nil || self.rollAttribute != nil)
            rpgExpandedReject('paleontology-context-definition');
        self.skill.validateDefinition();
        if (!self.approved || self.evidence == nil || self.evidence == '') rpgExpandedReject('paleontology-evidence-required');
        rpgInteger(self.equipmentModifier,-100,100);
        if (self.task != 'age' && self.equipmentModifier != 0) rpgExpandedReject('paleontology-equipment-age-only');
        if (self.laboratoryEquipment != nil)
        {
            if (self.equipmentModifier != 0 || self.equipmentTL != nil) rpgExpandedReject('paleontology-duplicate-equipment');
            rpgExpandedPaleontologyEquipment.definition(self.laboratoryEquipment,self);
        }
        return nil;
    }
    taskUnavailableReason(profile)
    {
        self.validatePaleontology();
        if (self.laboratoryEquipment != nil)
        {
            local tools = rpgExpandedPaleontologyEquipment.assess(self.laboratoryEquipment,profile,self);
            if (tools.status != 'ready') return tools.reason;
        }
        else if (self.skill.specialty == 'microscopic' && !self.laboratory) return 'paleontology-laboratory-required';
        return inherited(profile);
    }
    skillUseModifier(profile)
    {
        self.validatePaleontology(); local base = inherited(profile);
        if (base == nil) return nil;
        if (self.laboratoryEquipment == nil) return base + self.equipmentModifier;
        local tools = rpgExpandedPaleontologyEquipment.assess(self.laboratoryEquipment,profile,self);
        return tools.status == 'ready' ? base + tools.modifier : nil;
    }
    technologyModifierFor(profile)
    {
        if (self.laboratoryEquipment == nil) return inherited(profile);
        local tools = rpgExpandedPaleontologyEquipment.assess(self.laboratoryEquipment,profile,self);
        if (tools.status != 'ready') return nil;
        local level = self.technologySkillLevel(profile);
        if (level == nil) return nil;
        return rpgExpandedTechnologyModifier(level,tools.equipmentTL,true);
    }
;

/** Snapshot the specimen study context for owned exploration results. */
modify RpgExpandedPaleontologyContext
    paleontologyFamiliarityModifier(profile)
    {
        if (self.familiarity == nil) return 0;
        if (!self.familiarity.ofKind(RpgExpandedFamiliarity) || self.familiarity.owner != profile || self.familiarity.skill != self.skill)
            rpgExpandedReject('familiarity-context');
        return self.familiarity.modifier();
    }
    paleontologyFacts()
    {
        self.validatePaleontology();
        if (self.familiarity != nil && !self.familiarity.ofKind(RpgExpandedFamiliarity))
            rpgExpandedReject('familiarity-context');
        local facts = [self.skill,self.task,self.laboratory,self.equipmentModifier,self.approved,self.evidence,
            self.modifier,self.equipmentTL,self.softwareTechnologyEnabled,self.skill.specialty,self.skill.techLevel,self.laboratoryEquipment];
        facts = facts + self.culturalTaskFacts();
        if (self.familiarity != nil)
            facts = facts + [self.familiarity,self.familiarity.owner,self.familiarity.skill,self.familiarity.equipmentType,
                self.familiarity.initial,self.familiarity.requiredSeconds,self.familiarity.penalty];
        return self.laboratoryEquipment == nil ? facts
            : facts + rpgExpandedPaleontologyEquipment.definition(self.laboratoryEquipment,self);
    }
;

/** Full-2008 B212: pack-animal logistics. */
class RpgExpandedPackingSkill: RpgExpandedSkill
    id = 'packing'
    attribute = rpgIQ
    difficulty = 1
    defaultPenalty = -5
    validateDefinition()
    {
        if (self.id != 'packing' || self.attribute != rpgIQ || self.difficulty != 1 || self.defaultPenalty != -5
            || self.defaultAttribute != nil || self.alternateAttribute != nil || self.defaults.length() != 0
            || self.attributeDefaults.length() != 0 || self.wildcard || self.optionalParent != nil
            || self.techLevel != nil || self.specialty != nil) rpgExpandedReject('packing-skill-definition');
        return nil;
    }
    validatePacking() { return self.validateDefinition(); }
    defaultEdges(profile)
    {
        local edges = inherited(profile);
        foreach (local training in profile.skills)
        {
            local source = training.skill;
            if (training.points <= 0 || source == self || !source.ofKind(RpgLiteSkill)) continue;
            local general = source.ofKind(RpgExpandedSkill) && source.optionalParent != nil ? source.optionalParent : source;
            if (general.id == 'animal-handling' && general.specialty == 'equines' && general.techLevel == nil)
                edges = edges + [[general,-5]];
        }
        return edges;
    }
;

/** B212 begging: fixed ordinary defaults; hourly settlement belongs to social. */
class RpgExpandedBeggingSkill: RpgExpandedSkill
    id = 'begging'
    requiresSocialInteraction = true
    attribute = rpgIQ
    difficulty = 0
    defaultPenalty = -4
    validateDefinition()
    {
        if (self.id != 'begging' || self.attribute != rpgIQ || self.difficulty != 0 || self.defaultPenalty != -4
            || self.defaultAttribute != nil || self.alternateAttribute != nil || self.defaults.length() != 0
            || self.attributeDefaults.length() != 0 || self.wildcard || self.optionalParent != nil
            || self.techLevel != nil || self.specialty != nil || self.influence || !self.requiresSocialInteraction)
            rpgExpandedReject('begging-skill-definition');
        return nil;
    }
    defaultEdges(profile)
    {
        local edges = inherited(profile);
        foreach (local training in profile.skills)
        {
            local source = training.skill;
            if (training.points <= 0 || source == self || !source.ofKind(RpgLiteSkill)) continue;
            local general = source.ofKind(RpgExpandedSkill) && source.optionalParent != nil ? source.optionalParent : source;
            if (general.techLevel != nil || general.specialty != nil) continue;
            local penalty = general.id == 'quick-persuasion' ? -2 : general.id == 'public-speaking' ? -3 : nil;
            if (penalty != nil) edges = edges + [[general,penalty]];
        }
        return edges;
    }
;

/** Explicit local facts, not a general reaction roll or a grant of money. */
class RpgExpandedBeggingContext: RpgExpandedSkillContext
    approved = nil
    evidence = nil
    pitiable = nil
    shynessPenalty = 0
    invertAppearance = nil
    appearanceModifier = 0
    appearanceContext = nil
    extremeAppearance = nil
    crowdModifier = 0
    validateBegging()
    {
        if (self.skill == nil || !self.skill.ofKind(RpgExpandedBeggingSkill)
            || self.fixedBase != nil || self.rollAttribute != nil || self.interaction)
            rpgExpandedReject('begging-context-definition');
        self.skill.validateDefinition();
        if (!self.approved || self.evidence == nil || self.evidence == '') rpgExpandedReject('begging-context-evidence');
        rpgInteger(self.shynessPenalty,-4,0); rpgInteger(self.appearanceModifier,-1000,1000);
        rpgInteger(self.crowdModifier,-1000,1000);
        if (self.invertAppearance && self.extremeAppearance) rpgExpandedReject('begging-appearance-inversion');
        if (self.appearanceContext != nil && (!self.appearanceContext.ofKind(RpgLiteSocialContext)
            || self.appearanceModifier != 0 || self.extremeAppearance)) rpgExpandedReject('begging-appearance-duplicate-facts');
        return nil;
    }
    appearanceAdjustment(profile)
    {
        if (!self.invertAppearance) return 0;
        if (self.appearanceContext != nil) return self.appearanceContext.beggingAppearanceModifier(profile);
        if (profile.ofKind(RpgExpandedProfile) && profile.appearanceTrait() != nil)
            rpgExpandedReject('begging-purchased-appearance-context-required');
        return -self.appearanceModifier;
    }
    taskUnavailableReason(profile)
    {
        self.validateBegging(); self.appearanceAdjustment(profile);
        local reason = profile.beggingAuthoredTraitReason(self.pitiable,self.shynessPenalty);
        return reason == nil ? inherited(profile) : reason;
    }
    skillUseModifier(profile)
    {
        self.validateBegging(); local base = inherited(profile); if (base == nil) return nil;
        local reason = profile.beggingAuthoredTraitReason(self.pitiable,self.shynessPenalty);
        if (reason != nil) rpgExpandedReject(reason);
        return base + profile.level('charisma') + (self.pitiable || profile.sympathyActive() ? 3 : 0) + self.shynessPenalty
            + self.appearanceAdjustment(profile) + self.crowdModifier;
    }
;

modify RpgExpandedBeggingContext
    beggingFacts()
    {
        self.validateBegging();
        local facts = [self.skill,self.approved,self.evidence,self.pitiable,self.shynessPenalty,self.invertAppearance,
            self.appearanceModifier,self.extremeAppearance,self.crowdModifier,self.modifier,self.familiarity,
            self.equipmentTL,self.rollAttribute,self.fixedBase,self.interaction,self.appearanceContext];
        facts = facts + self.culturalTaskFacts();
        return self.appearanceContext == nil ? facts : facts + self.appearanceContext.beggingAppearanceFacts();
    }
;

/** B187 species-qualified disguise; similar-species defaults require concrete facts. */
class RpgExpandedDisguiseSkill: RpgExpandedSkill
    id = 'disguise'
    attribute = rpgIQ
    difficulty = 1
    defaultPenalty = -5
    similarSpeciesDefaults = []
    validateDefinition()
    {
        if (self.id != 'disguise' || self.attribute != rpgIQ || self.difficulty != 1 || self.defaultPenalty != -5
            || self.specialty == nil || self.techLevel == nil || self.defaultAttribute != nil || self.alternateAttribute != nil
            || self.defaults.length() != 0 || self.attributeDefaults.length() != 0 || self.wildcard || self.optionalParent != nil)
            rpgExpandedReject('disguise-skill-definition');
        rpgInteger(self.techLevel,0,12); local seen = [];
        foreach (local row in self.similarSpeciesDefaults)
        {
            if (row.length() != 3 || row[1] == nil || !row[1].ofKind(RpgExpandedDisguiseSkill) || row[1] == self
                || row[1].specialty == self.specialty || row[1].techLevel != self.techLevel
                || self.specialty == 'animals' || row[1].specialty == 'animals' || holds(seen,row[1])
                || row[3] == nil || row[3] == '') rpgExpandedReject('disguise-species-default');
            rpgInteger(row[2],-4,-2); seen = seen + [row[1]];
        }
        return nil;
    }
    defaultEdges(profile)
    {
        self.validateDefinition(); local edges = inherited(profile);
        foreach (local training in profile.skills)
        {
            local source = training.skill;
            if (training.points <= 0 || source == self || !source.ofKind(RpgLiteSkill)) continue;
            local general = source.ofKind(RpgExpandedSkill) && source.optionalParent != nil ? source.optionalParent : source;
            if (general.id == 'makeup' && general.techLevel == self.techLevel) edges = edges + [[general,-3]];
            foreach (local row in self.similarSpeciesDefaults)
                if (general == row[1]) edges = edges + [[general,row[2]]];
        }
        return edges;
    }
;
/** Disguise context. Carries approved, evidence, equipmentModifier, differentAppearancePenalty, sizeModifierDifference. Operations: validateDisguise, taskUnavailableReason, skillUseModifier. */
class RpgExpandedDisguiseContext: RpgExpandedSkillContext
    approved = nil
    evidence = nil
    equipmentModifier = 0
    differentAppearancePenalty = 0
    sizeModifierDifference = 0
    elasticSkin = nil
    sharedByCrowd = nil
    validateDisguise()
    {
        if (self.skill == nil || !self.skill.ofKind(RpgExpandedDisguiseSkill) || self.rollAttribute != nil || self.fixedBase != nil)
            rpgExpandedReject('disguise-context-definition');
        self.skill.validateDefinition();
        if (!self.approved || self.evidence == nil || self.evidence == '') rpgExpandedReject('disguise-context-evidence');
        if (self.skill.specialty == 'animals') rpgExpandedReject('disguise-animal-context-required');
        rpgInteger(self.equipmentModifier,-1000,1000); rpgInteger(self.differentAppearancePenalty,-5,0);
        rpgInteger(self.sizeModifierDifference,-100,100); return nil;
    }
    taskUnavailableReason(profile)
    {
        self.validateDisguise();
        if (self.sizeModifierDifference != 0) return 'disguise-size-difference-unsupported';
        return inherited(profile);
    }
    skillUseModifier(profile)
    {
        self.validateDisguise(); if (self.sizeModifierDifference != 0) return nil;
        local amount = inherited(profile); if (amount == nil) return nil;
        return amount + self.equipmentModifier + self.differentAppearancePenalty + (self.elasticSkin ? 4 : 0)
            - (self.sharedByCrowd ? 0 : profile.distinctiveFeatureLevels());
    }
;

/** B187 one owned Naturalist recall for a concrete animal-disguise encounter. */
class RpgExpandedAnimalHabitsResult: RpgExpandedResult
    score = nil
    gate = nil
    allowed = nil
;
/** Animal habits study. Carries id, profile, skill, animalType, encounter. Operations: outcomeDefinition, definition, assess, resolve. */
class RpgExpandedAnimalHabitsStudy: object
    id = nil
    profile = nil
    skill = nil
    animalType = nil
    encounter = nil
    successMagnitude = 1
    failureMagnitude = 1
    approved = nil
    evidence = nil
    result = nil
    boundDefinition = nil
    boundOutcome = nil
    outcomeDefinition()
    {
        local facts = [self.result.modifier,self.result.gate,self.result.allowed,self.result.check];
        return self.result.check == nil ? facts : facts + [self.result.check.score,self.result.check.roll,
            self.result.check.margin,self.result.check.achieved,self.result.check.critical];
    }
    definition()
    {
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)
            || self.skill == nil || !self.skill.ofKind(RpgExpandedNaturalistSkill) || self.animalType == nil || self.encounter == nil)
            rpgExpandedReject('animal-habits-definition');
        self.skill.validateDefinition(); rpgInteger(self.successMagnitude,1,3); rpgInteger(self.failureMagnitude,1,3);
        return [self.id,self.profile,self.skill,self.animalType,self.encounter,self.successMagnitude,self.failureMagnitude,
            self.approved,self.evidence] + self.skill.foragingDefinition();
    }
    assess()
    {
        local facts = self.definition(); local value = new RpgExpandedAnimalHabitsResult();
        if (self.result != nil)
        {
            if (!holds(self.profile.animalHabitsStudies,self)) rpgExpandedReject('animal-habits-history');
            if (self.boundDefinition == nil || facts.length() != self.boundDefinition.length()) rpgExpandedReject('animal-habits-binding');
            for (local index = 1; index <= facts.length(); index += 1)
                if (facts[index] != self.boundDefinition[index]) rpgExpandedReject('animal-habits-binding');
            local outcome = self.outcomeDefinition();
            if (self.boundOutcome == nil || outcome.length() != self.boundOutcome.length()) rpgExpandedReject('animal-habits-outcome');
            for (local index = 1; index <= outcome.length(); index += 1)
                if (outcome[index] != self.boundOutcome[index]) rpgExpandedReject('animal-habits-outcome');
            if (self.result.gate == nil || self.result.gate.assess().status != 'reused'
                || self.result.gate.result.allowed != self.result.allowed) rpgExpandedReject('animal-habits-gate-history');
            value.status = 'reused'; return value;
        }
        if (!self.approved || self.evidence == nil || self.evidence == '') { value.reason = 'animal-habits-evidence'; return value; }
        if (self.profile.dead || self.profile.unconscious || self.profile.stunned || self.profile.mentalStun)
        { value.reason = 'animal-habits-actor-unavailable'; return value; }
        foreach (local prior in self.profile.animalHabitsStudies)
            if (prior.id == self.id || prior.animalType == self.animalType && prior.encounter == self.encounter)
                rpgExpandedReject('animal-habits-duplicate');
        local context = new RpgExpandedSkillContext(); context.skill = self.skill;
        local score = rpgLiteScore(self.profile,context);
        if (score == nil || score < 3) { value.reason = 'animal-habits-score'; return value; }
        value.gate = self.profile.prepareSocialGate(self.id,self.evidence,nil);
        if (value.gate == nil) { value.reason = 'animal-habits-health-adapter-required'; return value; }
        local permission = value.gate.assess();
        if (permission.status != 'ready') { value.reason = permission.reason; return value; }
        value.score = score; value.status = 'ready'; return value;
    }
    resolve()
    {
        local value = self.assess(); if (value.status == 'reused') return self.result;
        if (value.status != 'ready') return value;
        local facts = self.definition(); local permission = value.gate.resolve();
        if (!holds(['resolved','reused'],permission.status)) rpgExpandedReject('animal-habits-permission-changed');
        value.allowed = permission.allowed;
        local current = self.definition();
        if (current.length() != facts.length()) rpgExpandedReject('animal-habits-changed');
        for (local index = 1; index <= facts.length(); index += 1)
            if (facts[index] != current[index]) rpgExpandedReject('animal-habits-changed');
        if (value.allowed)
        {
            local context = new RpgExpandedSkillContext(); context.skill = self.skill;
            if (rpgLiteScore(self.profile,context) != value.score) rpgExpandedReject('animal-habits-score-changed');
            value.check = rpgCheck(value.score,rpgRandom.roll());
            value.modifier = value.check.achieved ? self.successMagnitude : -self.failureMagnitude;
        }
        else value.reason = permission.reason;
        self.boundDefinition = facts; value.status = 'resolved'; self.result = value; self.boundOutcome = self.outcomeDefinition();
        self.profile.animalHabitsStudies = self.profile.animalHabitsStudies + [self];
        return value;
    }
;
modify RpgExpandedProfile
    animalHabitsStudies = []
    validateFeatures()
    {
        inherited(); local ids = [];
        foreach (local study in self.animalHabitsStudies)
        {
            if (study == nil || !study.ofKind(RpgExpandedAnimalHabitsStudy) || study.profile != self || holds(ids,study.id)
                || study.assess().status != 'reused') rpgExpandedReject('animal-habits-history');
            ids = ids + [study.id];
        }
        return nil;
    }
;
/** Animal disguise context. Carries study, animalType, encounter, animalCount, herd. Operations: animalDisguiseReason, taskUnavailableReason, skillUseModifier. */
class RpgExpandedAnimalDisguiseContext: RpgExpandedSkillContext
    study = nil
    animalType = nil
    encounter = nil
    animalCount = 1
    herd = nil
    downwind = nil
    skinConditionPenalty = 0
    approved = nil
    evidence = nil
    animalDisguiseReason(profile)
    {
        if (self.skill == nil || !self.skill.ofKind(RpgExpandedDisguiseSkill) || self.skill.specialty != 'animals'
            || self.fixedBase != nil || self.rollAttribute != nil) rpgExpandedReject('animal-disguise-definition');
        self.skill.validateDefinition(); rpgInteger(self.animalCount,1,1000); rpgInteger(self.skinConditionPenalty,-3,0);
        if (!self.approved || self.evidence == nil || self.evidence == '') return 'animal-disguise-evidence';
        if (self.study == nil || !self.study.ofKind(RpgExpandedAnimalHabitsStudy) || self.study.profile != profile
            || self.study.animalType != self.animalType || self.study.encounter != self.encounter)
            rpgExpandedReject('animal-disguise-study-owner');
        if (self.study.assess().status != 'reused') return 'animal-disguise-study-unresolved';
        if (!self.study.result.allowed) return 'animal-disguise-study-denied';
        return nil;
    }
    taskUnavailableReason(profile)
    {
        local reason = self.animalDisguiseReason(profile); return reason == nil ? inherited(profile) : reason;
    }
    skillUseModifier(profile)
    {
        if (self.animalDisguiseReason(profile) != nil) return nil;
        local amount = inherited(profile); if (amount == nil) return nil;
        return amount + self.study.result.modifier + (self.downwind ? 2 : 0) + self.skinConditionPenalty
            - (self.herd ? self.animalCount / 10 : self.animalCount-1);
    }
;

/** B206 theatrical makeup, distinct from a disguise's observer contest. */
class RpgExpandedMakeupSkill: RpgExpandedSkill
    id = 'makeup'
    attribute = rpgIQ
    difficulty = 0
    defaultPenalty = -4
    validateDefinition()
    {
        if (self.id != 'makeup' || self.attribute != rpgIQ || self.difficulty != 0 || self.defaultPenalty != -4
            || self.techLevel == nil || self.specialty != nil || self.defaultAttribute != nil || self.alternateAttribute != nil
            || self.defaults.length() != 0 || self.attributeDefaults.length() != 0 || self.wildcard || self.optionalParent != nil)
            rpgExpandedReject('makeup-skill-definition');
        rpgInteger(self.techLevel,0,12); return nil;
    }
    defaultEdges(profile)
    {
        local edges = inherited(profile);
        foreach (local training in profile.skills)
        {
            local source = training.skill;
            if (training.points <= 0 || source == self || !source.ofKind(RpgLiteSkill)) continue;
            local general = source.ofKind(RpgExpandedSkill) && source.optionalParent != nil ? source.optionalParent : source;
            if (general.id == 'disguise' && general.techLevel == self.techLevel) edges = edges + [[general,-2]];
        }
        return edges;
    }
;
/** Makeup context. Carries toolkitAssessment, subject, presentation, prosthetics, heightChange. Operations: makeupFacts, taskUnavailableReason, skillUseModifier, technologyModifierFor. */
class RpgExpandedMakeupContext: RpgExpandedSkillContext
    toolkitAssessment = nil
    subject = nil
    presentation = nil
    prosthetics = nil
    heightChange = 0
    approved = nil
    evidence = nil
    makeupFacts()
    {
        if (self.skill == nil || !self.skill.ofKind(RpgExpandedMakeupSkill) || self.subject == nil
            || !self.subject.ofKind(RpgExpandedProfile) || self.fixedBase != nil || self.rollAttribute != nil)
            rpgExpandedReject('makeup-context-definition');
        self.skill.validateDefinition(); rpgInteger(self.heightChange,-1000,1000);
        if (!self.approved || self.presentation == nil || self.presentation == '' || self.evidence == nil || self.evidence == '')
            rpgExpandedReject('makeup-context-evidence');
        local facts = [self.skill,self.skill.techLevel,self.subject,self.presentation,self.prosthetics,self.heightChange,
            self.approved,self.evidence,self.modifier,self.equipmentTL,self.familiarity,self.toolkitAssessment];
        facts = facts + self.culturalTaskFacts();
        return self.toolkitAssessment == nil ? facts : facts + rpgExpandedMakeupEquipment.definition(self.toolkitAssessment,self);
    }
    taskUnavailableReason(profile)
    {
        self.makeupFacts();
        if (self.heightChange != 0) return 'makeup-height-change-impossible';
        local technology = self.equipmentTL == nil ? self.skill.techLevel : self.equipmentTL;
        if (self.toolkitAssessment != nil)
        {
            local tools = rpgExpandedMakeupEquipment.assess(self.toolkitAssessment,profile,self);
            if (tools.status != 'ready') return tools.reason;
            technology = tools.equipmentTL;
        }
        if (self.prosthetics && technology < 6) return 'makeup-prosthetics-technology';
        return inherited(profile);
    }
    skillUseModifier(profile)
    {
        if (self.taskUnavailableReason(profile) != nil) return nil;
        local amount = inherited(profile); if (amount == nil || self.toolkitAssessment == nil) return amount;
        local tools = rpgExpandedMakeupEquipment.assess(self.toolkitAssessment,profile,self);
        return tools.status == 'ready' ? amount + tools.modifier : nil;
    }
    technologyModifierFor(profile)
    {
        if (self.toolkitAssessment == nil) return inherited(profile);
        local tools = rpgExpandedMakeupEquipment.assess(self.toolkitAssessment,profile,self);
        if (tools.status != 'ready') return nil;
        local level = self.technologySkillLevel(profile); if (level == nil) return nil;
        return rpgExpandedTechnologyModifier(level,tools.equipmentTL,true);
    }
;

/** Explicit significant-cultural-component task, full-2008 B23. */
class RpgExpandedCulturalSkillContext: RpgExpandedSkillContext
    culture = nil
    culturallySignificant = nil
    cultureEvidence = nil
    cultureReason(profile)
    {
        if (self.taskCulture != nil || self.taskCultureEvidence != nil) rpgExpandedReject('duplicate-cultural-context');
        if (self.skill == nil || !self.skill.ofKind(RpgExpandedSkill) || self.culture == nil)
            rpgExpandedReject('cultural-skill-context');
        if (!self.culturallySignificant || self.cultureEvidence == nil || self.cultureEvidence == '')
            return 'cultural-skill-evidence-required';
        profile.culturalPenalty(self.culture); return nil;
    }
    taskUnavailableReason(profile)
    {
        local reason = self.cultureReason(profile); return reason == nil ? inherited(profile) : reason;
    }
    skillUseModifier(profile)
    {
        if (self.cultureReason(profile) != nil) return nil;
        return inherited(profile);
    }
    culturalUseModifier(profile)
    {
        return self.cultureReason(profile) == nil ? profile.culturalPenalty(self.culture) : nil;
    }
;
/** B198 improvised simple hand signals. */
class RpgExpandedGestureSkill: RpgExpandedSkill
    id = 'gesture'
    attribute = rpgIQ
    difficulty = 0
    defaultPenalty = -4
    validateDefinition()
    {
        if (self.id != 'gesture' || self.attribute != rpgIQ || self.difficulty != 0 || self.defaultPenalty != -4
            || self.techLevel != nil || self.specialty != nil || self.defaultAttribute != nil || self.alternateAttribute != nil
            || self.defaults.length() != 0 || self.attributeDefaults.length() != 0 || self.wildcard || self.optionalParent != nil)
            rpgExpandedReject('gesture-skill-definition');
        return nil;
    }
;
/** Gesture context. Carries operation, simpleIdea, idea, observed, culturallySignificant. Operations: gestureReason, taskUnavailableReason, skillUseModifier, gestureAttemptFacts. */
class RpgExpandedGestureContext: RpgExpandedCulturalSkillContext
    operation = 'convey'
    simpleIdea = nil
    idea = nil
    observed = nil
    culturallySignificant = true
    gestureReason(profile)
    {
        if (self.skill == nil || !self.skill.ofKind(RpgExpandedGestureSkill) || self.fixedBase != nil || self.rollAttribute != nil
            || !holds(['convey','understand'],self.operation)) rpgExpandedReject('gesture-context-definition');
        self.skill.validateDefinition();
        if (!self.simpleIdea || self.idea == nil || self.idea == '') return 'gesture-simple-idea-required';
        if (!self.observed) return 'gesture-not-observed';
        return self.cultureReason(profile);
    }
    taskUnavailableReason(profile)
    {
        local reason = self.gestureReason(profile); return reason == nil ? inherited(profile) : reason;
    }
    skillUseModifier(profile)
    {
        return self.gestureReason(profile) == nil ? inherited(profile) : nil;
    }
;

modify RpgExpandedGestureContext
    gestureAttemptFacts()
    {
        return [self.skill,self.operation,self.simpleIdea,self.idea,self.observed,self.culture,
            self.culturallySignificant,self.cultureEvidence,self.modifier,self.familiarity,self.equipmentTL];
    }
    gestureAttemptReason(profile) { return self.gestureReason(profile); }
;

/** B198 Geography/TL branches, with explicit B180 planet-type qualification. */
class RpgExpandedGeographySkill: RpgExpandedSkill
    id = 'geography'
    attribute = rpgIQ
    difficulty = 2
    defaultPenalty = -6
    planetType = nil
    region = nil
    validateDefinition()
    {
        if (self.id != 'geography' || self.attribute != rpgIQ || self.difficulty != 2 || self.defaultPenalty != -6
            || self.techLevel == nil || !holds(['physical','political','regional'],self.specialty)
            || self.defaultAttribute != nil || self.alternateAttribute != nil || self.defaults.length() != 0
            || self.attributeDefaults.length() != 0 || self.wildcard || self.optionalParent != nil)
            rpgExpandedReject('geography-skill-definition');
        rpgInteger(self.techLevel,0,12);
        if (self.specialty == 'physical')
        {
            if (!holds(['habitable','gas-giant','hostile-terrestrial','icy-small-body','ice-covered','rocky'],self.planetType))
                rpgExpandedReject('geography-planet-type');
        }
        else if (self.planetType != nil) rpgExpandedReject('geography-planet-type');
        if ((self.specialty == 'regional' && (self.region == nil || self.region == ''))
            || (self.specialty != 'regional' && self.region != nil)) rpgExpandedReject('geography-region');
        return nil;
    }
    defaultEdges(profile)
    {
        local edges = inherited(profile);
        foreach (local training in profile.skills)
        {
            local source = training.skill;
            if (source == self || training.points <= 0 || !source.ofKind(RpgExpandedSkill)) continue;
            local general = source.optionalParent == nil ? source : source.optionalParent;
            if (general.ofKind(RpgExpandedGeographySkill))
            {
                general.validateDefinition(); if (general.techLevel != self.techLevel) continue;
                if (general.specialty != self.specialty) edges = edges + [[general,-5]];
                else if (self.specialty == 'physical' && general.planetType != self.planetType) edges = edges + [[general,-4]];
            }
            else if (self.specialty == 'physical' && holds(['geology','meteorology'],general.id)
                && general.techLevel == self.techLevel && general.specialty == self.planetType) edges = edges + [[general,-4]];
            else if (self.specialty == 'political' && general.id == 'economics' && general.techLevel == nil)
                edges = edges + [[general,-4]];
            else if (self.specialty == 'regional' && general.id == 'area-knowledge' && general.specialty == self.region
                && general.techLevel == nil) edges = edges + [[general,-6]];
        }
        return edges;
    }
;
/** A bounded authored question; a regional skill does not imply unlimited detail. */
class RpgExpandedGeographyContext: RpgExpandedSkillContext
    topic = nil
    planetType = nil
    region = nil
    depthApproved = nil
    approved = nil
    evidence = nil
    geographyReason()
    {
        if (self.skill == nil || !self.skill.ofKind(RpgExpandedGeographySkill) || self.fixedBase != nil || self.rollAttribute != nil)
            rpgExpandedReject('geography-context-definition');
        self.skill.validateDefinition();
        if (!self.approved || self.evidence == nil || self.evidence == '') return 'geography-question-evidence-required';
        if (!holds(['physical','political'],self.topic)) return 'geography-topic-unavailable';
        if (self.skill.specialty != 'regional' && self.topic != self.skill.specialty) return 'geography-branch-mismatch';
        if (self.skill.specialty == 'physical' && self.planetType != self.skill.planetType) return 'geography-planet-mismatch';
        if (self.skill.specialty == 'regional' && (self.region != self.skill.region || !self.depthApproved))
            return 'geography-regional-scope-required';
        return nil;
    }
    taskUnavailableReason(profile)
    {
        local reason = self.geographyReason(); return reason == nil ? inherited(profile) : reason;
    }
    skillUseModifier(profile)
    {
        return self.geographyReason() == nil ? inherited(profile) : nil;
    }
;

/** B198/B180 Geology/TL, qualified by planet type. */
class RpgExpandedGeologySkill: RpgExpandedSkill
    id = 'geology'
    attribute = rpgIQ
    difficulty = 2
    defaultPenalty = -6
    validateDefinition()
    {
        if (self.id != 'geology' || self.attribute != rpgIQ || self.difficulty != 2 || self.defaultPenalty != -6
            || self.techLevel == nil || self.defaultAttribute != nil || self.alternateAttribute != nil
            || self.defaults.length() != 0 || self.attributeDefaults.length() != 0 || self.wildcard || self.optionalParent != nil
            || !holds(['habitable','gas-giant','hostile-terrestrial','icy-small-body','ice-covered','rocky'],self.specialty))
            rpgExpandedReject('geology-skill-definition');
        rpgInteger(self.techLevel,0,12); return nil;
    }
    defaultEdges(profile)
    {
        local edges = inherited(profile);
        foreach (local training in profile.skills)
        {
            local source = training.skill;
            if (source == self || training.points <= 0 || !source.ofKind(RpgExpandedSkill)) continue;
            local general = source.optionalParent == nil ? source : source.optionalParent;
            if (general.ofKind(RpgExpandedGeologySkill) && general.techLevel == self.techLevel && general.specialty != self.specialty)
            { general.validateDefinition(); edges = edges + [[general,-4]]; }
            else if (general.ofKind(RpgExpandedGeographySkill) && general.specialty == 'physical'
                && general.planetType == self.specialty && general.techLevel == self.techLevel)
            { general.validateDefinition(); edges = edges + [[general,-4]]; }
            else if (general.id == 'prospecting' && general.techLevel == self.techLevel) edges = edges + [[general,-5]];
        }
        return edges;
    }
;
/** Terrain search context. Carries planet, planetType, feature. Operations: terrainSearchFacts, taskUnavailableReason, skillUseModifier. */
class RpgExpandedTerrainSearchContext: RpgExpandedSkillContext
    planet = nil
    planetType = nil
    feature = nil
    terrainSearchFacts()
    {
        if (self.skill == nil || self.fixedBase != nil || self.rollAttribute != nil)
            rpgExpandedReject('terrain-search-context');
        if (!self.skill.ofKind(RpgExpandedGeologySkill) && !self.skill.ofKind(RpgExpandedSurvivalSkill))
            rpgExpandedReject('terrain-search-skill');
        self.skill.validateDefinition();
        return [self.skill,self.skill.specialty,self.skill.techLevel,self.planet,self.planetType,self.feature,
            self.modifier,self.equipmentTL,self.familiarity] + self.culturalTaskFacts();
    }
    taskUnavailableReason(profile)
    {
        self.terrainSearchFacts();
        if (self.feature == nil || self.feature == '' || self.planet == nil || self.planetType == nil)
            return 'terrain-search-world-facts-required';
        if (self.skill.ofKind(RpgExpandedGeologySkill))
        {
            if (self.feature != 'flowing-water') return 'geology-search-water-only';
            if (self.skill.specialty != self.planetType) return 'terrain-search-planet-mismatch';
        }
        else if (self.skill.planet != self.planet || self.skill.planetType != self.planetType)
            return 'terrain-search-planet-mismatch';
        return inherited(profile);
    }
    skillUseModifier(profile)
    {
        return self.taskUnavailableReason(profile) == nil ? inherited(profile) : nil;
    }
;

/** B226 fixed tracking catalogue definition and purchased naturalist default. */
class RpgExpandedTrackingSkill: RpgExpandedSkill
    id = 'tracking'
    attribute = rpgPerception
    difficulty = 1
    defaultPenalty = -5
    validateDefinition()
    {
        if (self.id != 'tracking' || self.attribute != rpgPerception || self.difficulty != 1 || self.defaultPenalty != -5
            || self.techLevel != nil || self.specialty != nil || self.defaultAttribute != nil || self.alternateAttribute != nil
            || self.defaults.length() != 0 || self.attributeDefaults.length() != 0 || self.wildcard || self.optionalParent != nil)
            rpgExpandedReject('tracking-skill-definition');
        return nil;
    }
    defaultEdges(profile)
    {
        local edges = inherited(profile);
        foreach (local training in profile.skills)
        {
            local source = training.skill;
            if (training.points > 0 && source != self && source.ofKind(RpgExpandedNaturalistSkill))
            {
                source.validateDefinition();
                edges = edges + [[source,-5]];
            }
        }
        return edges;
    }
;
/** Tracking terrain result. Carries interval. */
class RpgExpandedTrackingTerrainResult: RpgExpandedResult
    interval = nil
;
/** Tracking terrain. */
rpgExpandedTrackingTerrain(terrain)
{
    local value = new RpgExpandedTrackingTerrainResult();
    if (holds(['jungle','plains','woodland'],terrain)) { value.interval = 1800; value.modifier = 0; }
    else if (holds(['arctic','desert','coast','mountain'],terrain)) { value.interval = 900; value.modifier = -2; }
    else if (terrain == 'swamp') { value.interval = 300; value.modifier = -4; }
    else if (terrain == 'urban') { value.interval = 60; value.modifier = -6; }
    else rpgExpandedReject('tracking-terrain');
    value.status = 'ready'; return value;
}
/** Ordinary visible/scent trail scoring. Hidden trails require a contested adapter. */
class RpgExpandedTrackingContext: RpgExpandedSkillContext
    kind = 'tracking'
    someLight = nil
    terrain = nil
    trailAgeSeconds = 0
    subjectCategory = 'animal'
    visualBonusApplicable = nil
    scentBonusApplicable = nil
    trailAvailable = nil
    concealedTrail = nil
    approved = nil
    evidence = nil
    sensoryRecognitionMode() { return self.scentBonusApplicable ? 'smell' : nil; }
    trackingFacts()
    {
        if (self.skill == nil || !self.skill.ofKind(RpgExpandedTrackingSkill) || self.kind != 'tracking'
            || self.fixedBase != nil || self.rollAttribute != nil || self.darkness != 0 || self.someLight
            || !holds(['animal','human-single','human-group'],self.subjectCategory)) rpgExpandedReject('tracking-context');
        self.skill.validateDefinition(); rpgInteger(self.trailAgeSeconds,0,2147483647); rpgExpandedTrackingTerrain(self.terrain);
        return [self.skill,self.terrain,self.trailAgeSeconds,self.subjectCategory,self.visualBonusApplicable,self.scentBonusApplicable,
            self.trailAvailable,self.concealedTrail,self.approved,self.evidence,self.modifier,self.equipmentTL,self.familiarity]
            + self.culturalTaskFacts();
    }
    taskUnavailableReason(profile)
    {
        self.trackingFacts();
        if (!self.approved || self.evidence == nil || self.evidence == '') return 'tracking-world-facts-required';
        if (!self.trailAvailable) return 'tracking-trail-unavailable';
        if (self.concealedTrail) return 'tracking-contest-adapter-required';
        return inherited(profile);
    }
    skillUseModifier(profile)
    {
        if (self.taskUnavailableReason(profile) != nil) return nil;
        local value = inherited(profile); if (value == nil) return nil;
        value += rpgExpandedTrackingTerrain(self.terrain).modifier;
        value += self.trailAgeSeconds > 604800 ? -10 : self.trailAgeSeconds > 86400 ? -5 : 0;
        value += self.subjectCategory == 'human-group' ? 6 : self.subjectCategory == 'human-single' ? 3 : 0;
        if (self.visualBonusApplicable) value += profile.level('acute-vision');
        return value;
    }
;

/** Tracking window result. Carries interval, elapsed, remaining, unusedSeconds, checkDue. */
class RpgExpandedTrackingWindowResult: RpgExpandedResult
    interval = nil
    elapsed = nil
    remaining = nil
    unusedSeconds = nil
    checkDue = nil
;
/** Pure B226 homogeneous-terrain boundary. It never consumes time or rolls a check. */
rpgExpandedTrackingWindow(terrain,elapsed,requestedSeconds)
{
    local table = rpgExpandedTrackingTerrain(terrain);
    rpgInteger(elapsed,0,table.interval); rpgInteger(requestedSeconds,0,2147483647);
    local value = new RpgExpandedTrackingWindowResult(); value.interval = table.interval; value.modifier = table.modifier;
    value.elapsed = elapsed; value.remaining = table.interval-elapsed; value.unusedSeconds = requestedSeconds;
    if (value.remaining == 0)
    { value.checkDue = true; value.reason = 'tracking-continuation-check-due'; return value; }
    value.seconds = requestedSeconds < value.remaining ? requestedSeconds : value.remaining;
    value.elapsed += value.seconds; value.remaining -= value.seconds; value.unusedSeconds -= value.seconds;
    value.checkDue = value.remaining == 0; value.status = 'ready'; return value;
}

modify RpgExpandedTrackingContext
    trackingWindow(elapsed,seconds) { self.trackingFacts(); return rpgExpandedTrackingWindow(self.terrain,elapsed,seconds); }
;

/** B219 unconditional defaults; the foot-only default is selected by the task context. */
class RpgExpandedShadowingSkill: RpgExpandedSkill
    id = 'shadowing'
    attribute = rpgIQ
    difficulty = 1
    defaultPenalty = -5
    validateDefinition()
    {
        if (self.id != 'shadowing' || self.attribute != rpgIQ || self.difficulty != 1 || self.defaultPenalty != -5
            || self.techLevel != nil || self.specialty != nil || self.defaultAttribute != nil || self.alternateAttribute != nil
            || self.defaults.length() != 0 || self.attributeDefaults.length() != 0 || self.wildcard || self.optionalParent != nil)
            rpgExpandedReject('shadowing-skill-definition');
        return nil;
    }
    defaultEdges(profile)
    {
        local edges = inherited(profile);
        foreach (local training in profile.skills)
            if (training.points > 0 && training.skill != self && training.skill.ofKind(RpgExpandedSkill)
                && training.skill.id == 'observation' && training.skill.techLevel == nil)
                edges = edges + [[training.skill,-5]];
        return edges;
    }
;
/** Shadowing context. Carries kind, mode, crowdAvailable, targetKnowsFollower, noisyTarget. Operations: sensoryRecognitionMode, shadowingFacts, taskUnavailableReason, scoreFor. */
class RpgExpandedShadowingContext: RpgExpandedSkillContext
    kind = 'shadowing'
    mode = 'foot'
    crowdAvailable = nil
    targetKnowsFollower = nil
    noisyTarget = nil
    distinctiveModifier = 0
    visiblyDifferent = nil
    sizeDifference = 0
    crowdModifier = 0
    approved = nil
    evidence = nil
    sensoryRecognitionMode() { return self.noisyTarget ? 'hearing' : nil; }
    shadowingFacts()
    {
        if (self.skill == nil || !self.skill.ofKind(RpgExpandedShadowingSkill) || self.kind != 'shadowing'
            || self.fixedBase != nil || self.rollAttribute != nil || !holds(['foot','vehicle'],self.mode))
            rpgExpandedReject('shadowing-context');
        self.skill.validateDefinition(); rpgInteger(self.distinctiveModifier,-100,0);
        rpgInteger(self.sizeDifference,0,100); rpgInteger(self.crowdModifier,-100,0);
        if ((!self.visiblyDifferent && (self.sizeDifference != 0 || self.crowdModifier != 0))
            || (self.visiblyDifferent && self.crowdModifier > -self.sizeDifference)) rpgExpandedReject('shadowing-crowd-penalty');
        return [self.skill,self.mode,self.crowdAvailable,self.targetKnowsFollower,self.noisyTarget,self.distinctiveModifier,
            self.visiblyDifferent,self.sizeDifference,self.crowdModifier,self.approved,self.evidence,self.modifier,
            self.equipmentTL,self.familiarity] + self.culturalTaskFacts();
    }
    taskUnavailableReason(profile)
    {
        self.shadowingFacts();
        if (!self.approved || self.evidence == nil || self.evidence == '') return 'shadowing-world-facts-required';
        if (!self.crowdAvailable) return 'shadowing-crowd-required';
        return inherited(profile);
    }
    scoreFor(profile)
    {
        self.shadowingFacts(); local score = inherited(profile);
        if (score == nil || self.mode != 'foot') return score;
        foreach (local training in profile.skills)
            if (training.points > 0 && training.skill.ofKind(RpgExpandedSkill) && training.skill.id == 'stealth'
                && training.skill.techLevel == nil)
            {
                local paid = rpgExpandedPaidSkill(profile,training.skill,[self.skill]);
                if (paid != nil)
                {
                    local candidate = paid-4 + profile.ancestrySkillModifier(self.skill)
                        + profile.catalogueTalentSkillModifier(self.skill) + profile.catalogueSkillModifier(self.skill);
                    if (candidate > score) score = candidate;
                }
            }
        return score;
    }
    skillUseModifier(profile)
    {
        if (self.taskUnavailableReason(profile) != nil) return nil;
        local modifier = inherited(profile); if (modifier == nil) return nil;
        return modifier + (self.mode == 'vehicle' ? -2 : 0) + (self.targetKnowsFollower ? -3 : 0)
            + self.distinctiveModifier + self.crowdModifier;
    }
;

/** B222 Stealth has both DX and IQ attribute defaults. */
class RpgExpandedStealthSkill: RpgExpandedSkill
    id = 'stealth'
    attribute = rpgDX
    difficulty = 1
    defaultPenalty = -5
    attributeDefaults = [[rpgIQ,-5]]
    validateDefinition()
    {
        if (self.id != 'stealth' || self.attribute != rpgDX || self.difficulty != 1 || self.defaultPenalty != -5
            || self.techLevel != nil || self.specialty != nil || self.defaultAttribute != nil || self.alternateAttribute != nil
            || self.defaults.length() != 0 || self.attributeDefaults.length() != 1
            || self.attributeDefaults[1].length() != 2 || self.attributeDefaults[1][1] != rpgIQ || self.attributeDefaults[1][2] != -5
            || self.wildcard || self.optionalParent != nil) rpgExpandedReject('stealth-skill-definition');
        return nil;
    }
;
/** Stealth context. Carries kind, hiding, movingSilently, bareRoom, naturalCover. Operations: stealthFacts, taskUnavailableReason, skillUseModifier, shadowingContestRole. */
class RpgExpandedStealthContext: RpgExpandedSkillContext
    kind = 'stealth'
    hiding = nil
    movingSilently = nil
    bareRoom = nil
    naturalCover = 'ordinary'
    coverBonus = 0
    fasterThanMoveOne = nil
    scentObserver = nil
    approved = nil
    evidence = nil
    stealthFacts()
    {
        if (self.skill == nil || !self.skill.ofKind(RpgExpandedStealthSkill) || self.kind != 'stealth'
            || self.fixedBase != nil || self.rollAttribute != nil || (!self.hiding && !self.movingSilently)
            || !holds(['none','ordinary','many'],self.naturalCover)) rpgExpandedReject('stealth-context');
        self.skill.validateDefinition(); rpgInteger(self.coverBonus,0,100);
        if ((self.naturalCover == 'many' && self.coverBonus < 3) || (self.naturalCover != 'many' && self.coverBonus != 0)
            || (!self.hiding && (self.naturalCover != 'ordinary' || self.bareRoom))
            || (!self.movingSilently && self.fasterThanMoveOne)) rpgExpandedReject('stealth-task-facts');
        if (self.scentObserver != nil && !self.scentObserver.ofKind(RpgExpandedProfile)) rpgExpandedReject('stealth-scent-observer');
        return [self.skill,self.hiding,self.movingSilently,self.bareRoom,self.naturalCover,self.coverBonus,
            self.fasterThanMoveOne,self.scentObserver,self.approved,self.evidence,self.modifier,self.equipmentTL,self.familiarity]
            + self.culturalTaskFacts();
    }
    taskUnavailableReason(profile)
    {
        self.stealthFacts();
        if (!self.approved || self.evidence == nil || self.evidence == '') return 'stealth-world-facts-required';
        if (self.hiding && self.bareRoom) return 'stealth-no-concealment-possible';
        return inherited(profile);
    }
    skillUseModifier(profile)
    {
        if (self.taskUnavailableReason(profile) != nil) return nil;
        local modifier = inherited(profile); if (modifier == nil) return nil;
        modifier -= profile.encumbrance();
        if (self.hiding) modifier += self.naturalCover == 'none' ? -5 : self.coverBonus;
        if (self.movingSilently && self.fasterThanMoveOne) modifier -= 5;
        if (self.scentObserver != nil && self.scentObserver.sensoryRecognitionBonus('smell') > 0) modifier -= 5;
        return modifier;
    }
;

modify RpgExpandedShadowingContext
    shadowingContestRole() { return 'shadowing'; }
    shadowingContestFacts() { return self.shadowingFacts(); }
;
modify RpgExpandedStealthContext
    shadowingContestRole() { return 'stealth'; }
    shadowingContestFacts() { return self.stealthFacts(); }
;

modify RpgExpandedSkill
    vehicleOperationClassification()
    {
        if (self.optionalParent == nil) return inherited();
        rpgExpandedValidateSkill(self);
        local parent = self.optionalParent.vehicleOperationClassification();
        if (self.vehicleOperationClass != nil && self.vehicleOperationClass != parent)
            rpgExpandedReject('vehicle-operation-specialty-conflict');
        return parent;
    }
;
