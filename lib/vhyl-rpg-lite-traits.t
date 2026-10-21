modify RpgLiteProfile
    lastCheck = nil
    lastCheckDraw = -1
    griefDays = 0
    phobias = []
;

/** Immediate trusted Luck hook for a raw dice total; return the best of three and start play-time cooldown. */
rpgLiteReroll(profile, original, dice, higherIsBetter)
{
    local interval = profile.level('ridiculous-luck') > 0 ? 600 : profile.level('extraordinary-luck') > 0 ? 1800
        : profile.level('luck') > 0 ? 3600 : 0;
    if (interval == 0 || profile.playSeconds < profile.luckReady) throw new RpgError();
    rpgInteger(dice, 1, 100);
    local chosen = original;
    for (local attempt = 0; attempt < 2; attempt += 1)
    {
        local roll = 0;
        for (local index = 0; index < dice; index += 1) roll += rpgRandom.die();
        if (higherIsBetter ? roll > chosen : roll < chosen) chosen = roll;
    }
    profile.luckReady = profile.playSeconds + interval; profile.lastCheck = nil;
    return chosen;
}

/** Reroll the character's most recent success check before any other random draw. */
rpgLiteLuck(profile, original, higherIsBetter)
{
    if (original != profile.lastCheck || profile.lastCheckDraw != rpgRandom.draws) throw new RpgError();
    return rpgCheck(original.score, rpgLiteReroll(profile, original.roll, 3, higherIsBetter));
}

/** Consume the once-per-session authored misfortune trigger. */
rpgLiteUnluckiness(profile, sessionId)
{
    if (profile.level('unluckiness') == 0 || profile.unluckySession == sessionId) return nil;
    profile.unluckySession = sessionId; return true;
}

/** Resolve secret human or animal empathy; the author supplies true or misleading impressions. */
rpgLiteEmpathy(profile, animal)
{
    if (profile.level(animal ? 'animal-empathy' : 'empathy') == 0) throw new RpgError();
    return rpgLiteAttributeCheck(profile, rpgIQ, 'empathy', 0);
}

/** Resolve sensory detection, optional comprehension and Danger Sense fallback. */
rpgLiteNotice(profile, context, comprehension, danger)
{
    local noticed = rpgLiteCheck(profile, context);
    if (noticed.achieved && comprehension != nil) noticed = rpgLiteCheck(profile, comprehension);
    if (!noticed.achieved && danger && profile.level('danger-sense') > 0)
        noticed = rpgLiteAttributeCheck(profile, rpgPerception, 'danger-sense', 0);
    return noticed;
}

/** Triggered behavioral obligation with self-control and author-defined action satisfaction. */
class RpgLiteObligation: object
    profile = nil
    trait = nil
    trigger = nil
    active = nil
    check = nil
    begin(modifier, giveIn)
    {
        if (!holds(self.profile.traits, self.trait)) throw new RpgError();
        self.check = self.trait.controlled ? rpgLiteSelfControl(self.profile, self.trait, modifier, giveIn) : nil;
        self.active = self.check == nil || !self.check.achieved;
        return self.active;
    }
    permits(action) { return !self.active || action.satisfies(self); }
;

/** Persistent phobic exposure, initial self-control and ten-minute repeated checks. */
class RpgLitePhobia: object
    profile = nil
    trait = nil
    present = nil
    elapsed = 0
    panicking = nil
    enter(threatOnly, modifier)
    {
        self.present = true; self.elapsed = 0;
        self.panicking = !rpgLiteSelfControl(self.profile, self.trait, modifier + (threatOnly ? 4 : 0), nil).achieved;
        return self.panicking;
    }
    advance(seconds)
    {
        rpgInteger(seconds, 0, 86400);
        if (!self.present) return nil;
        self.elapsed += seconds;
        while (self.elapsed >= 600)
        { self.elapsed -= 600; self.panicking = !rpgLiteSelfControl(self.profile, self.trait, 0, nil).achieved; }
        return self.panicking;
    }
    leave() { self.present = nil; self.panicking = nil; self.elapsed = 0; return nil; }
;

/** Time/world travel with concentration, IQ, fatigue and authored safe-destination hooks. */
class RpgLiteJump: object
    profile = nil
    kind = 'world'
    destination = nil
    seconds = 10
    fatigueCost = 1
    safe = true
    available() { return nil; }
    arrived(destination, wrong) { return nil; }
    resolve()
    {
        rpgInteger(self.seconds, 1, 10); rpgInteger(self.fatigueCost, 1, 10);
        if (!holds(['time','world'], self.kind) || self.profile.level(self.kind == 'time' ? 'jumper-time' : 'jumper-world') == 0)
            throw new RpgError();
        if (self.available() != nil || !rpgLiteCanAct(self.profile, nil)) return nil;
        local result = rpgLiteAttributeCheck(self.profile, rpgIQ, 'jump', self.seconds - 10);
        rpgSpendTime(self.seconds); rpgLiteFatigue(self.profile, self.fatigueCost, 'jump');
        if (result.roll >= 14 || !self.safe) { result.achieved = nil; result.outcome = 'setback'; }
        if (result.achieved) self.arrived(self.destination, nil);
        else if (result.critical == 'failure' && self.safe) self.arrived(self.destination, true);
        return result;
    }
;

/** Spend earned points during approved downtime to remove an owned disadvantage. */
rpgLiteBuyOff(profile, trait)
{
    if (!profile.developmentOpen || !holds(profile.traits, trait) || trait.points >= 0) return nil;
    local cost = profile.disadvantageBuyoffCost(trait);
    if (cost == nil || profile.developmentSpendingReason() != nil || profile.unspentPoints < cost) return nil;
    local kept = [];
    foreach (local owned in profile.traits) if (owned != trait) kept = kept + [owned];
    profile.unspentPoints -= cost; profile.traits = kept; return true;
}

/** Spend the incremental investment on an owned or new skill, respecting TL learning restrictions. */
rpgLiteLearn(profile, skill, points, teacher)
{
    rpgInteger(points, 1, 10000);
    if (!profile.developmentOpen) return nil;
    if (profile.skillLearningWithTeacherReason(skill, teacher) != nil) return nil;
    if (skill.techLevel != nil && skill.techLevel > profile.techLevel
        && (skill.attribute == rpgIQ || !teacher)) return nil;
    local training = nil;
    foreach (local candidate in profile.skills) if (candidate.skill == skill) training = candidate;
    if (profile.trainingPurchaseReason(skill,training) != nil || profile.developmentSpendingReason() != nil) return nil;
    local cost = points - (training == nil ? 0 : training.points);
    if (cost <= 0 || cost > profile.unspentPoints) return nil;
    if (training == nil)
    { training = new RpgTraining(); training.skill = skill; profile.skills = profile.skills + [training]; }
    profile.unspentPoints -= cost; training.points = points; return true;
}

modify RpgLiteProfile
    disadvantageBuyoffCost(trait) { return -rpgLiteTraitCost(trait); }
;
