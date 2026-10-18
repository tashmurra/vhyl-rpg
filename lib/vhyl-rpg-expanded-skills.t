/* Include after the expanded foundation. Source: full-2008, B170, B173, B175, B230. */

/** Authored expanded skill. Defaults are explicit [skill, penalty] pairs.
 * A catalogue is not implied by this definition type. */
class RpgExpandedSkill: RpgLiteSkill
    defaults = []
    wildcard = nil
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

/** Owned technique investment, counted as a character contribution.
 * Each technique specializes in one trained parent skill. */
class RpgExpandedTechnique: RpgExpandedContribution
    skill = nil
    penalty = 0
    maximumAboveSkill = 0
    hard = nil
    points = 0
    amounts(profile) { return [self.points]; }
    validate(profile)
    {
        rpgInteger(self.penalty, -100, 0); rpgInteger(self.maximumAboveSkill, 0, 100);
        rpgInteger(self.points, 0, 1000000);
        local training = rpgExpandedTrainingFor(profile, self.skill);
        if (training == nil || training.points < 1) rpgExpandedReject('technique-prerequisite');
        if (self.points > self.maximumAboveSkill - self.penalty + (self.hard ? 1 : 0))
            rpgExpandedReject('technique-cap');
        return nil;
    }
    score()
    {
        self.validate(self.owner);
        local base = self.owner.skillScore(self.skill);
        if (base == nil) rpgExpandedReject('technique-prerequisite');
        local improvement = self.points - (self.hard && self.points > 0 ? 1 : 0);
        return base + self.penalty + improvement;
    }
;
