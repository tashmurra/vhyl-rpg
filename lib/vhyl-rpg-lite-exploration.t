/** Return [surface, modifier, combat rate, regular rate, unit]; rates are feet or rungs per minute. */
rpgLiteClimbData(surface)
{
    local rows = [['ladder-up',nil,180,60,'rungs'],['ladder-down',nil,120,60,'rungs'],
        ['tree',5,60,20,'feet'],['mountain',0,30,10,'feet'],['stone-wall',-3,12,4,'feet'],
        ['building',-3,6,2,'feet'],['rope-up',-2,60,20,'feet'],['rope-down',-1,120,30,'feet'],
        ['rappel',-1,720,720,'feet']];
    foreach (local row in rows) if (row[1] == surface) return row;
    throw new RpgError();
}

/** Calculate high-jump inches or broad-jump feet, including run-up and trained Jumping. */
rpgLiteJumpDistance(profile, skill, runUp, high)
{
    rpgInteger(runUp, 0, 10000);
    local movementScore = profile.basicMove(); local rating = skill == nil ? nil : profile.skillScore(skill);
    if (rating != nil && rating / 2 > movementScore) movementScore = rating / 2;
    local standing = high ? 6 * movementScore - 10 : 2 * movementScore - 3;
    if (standing < 0) standing = 0;
    local running = high ? 6 * (movementScore + runUp) - 10 : 2 * (movementScore + runUp) - 3;
    return running > 2 * standing ? 2 * standing : running;
}

/** Return lift, shove or shift capacity in hundredths of a pound. */
rpgLiteLift(profile, kind, running)
{
    local factor = kind == 'one-hand' ? 2 : kind == 'two-hands' ? 8
        : kind == 'shove' ? (running ? 24 : 12) : kind == 'back' ? 15 : kind == 'shift' ? 50 : 0;
    if (factor == 0) throw new RpgError();
    return profile.basicLiftHundredths() * factor;
}

/** Return throwing range in hundredths of a yard for weight in hundredths of a pound. */
rpgLiteThrowDistance(profile, weight)
{
    rpgInteger(weight, 1, 1000000);
    local lift = profile.basicLiftHundredths();
    if (weight > lift * 8) return 0;
    local table = [[5,350],[10,250],[15,200],[20,150],[40,100],[50,80],[100,60],[150,40],
        [200,30],[250,25],[300,20],[400,15],[600,10],[1000,6],[1200,5]];
    foreach (local row in table) if (weight * 100 <= lift * row[1]) return profile.st * row[2];
    return 0;
}

/** Roll crushing damage for a thrown object's weight relative to Basic Lift. */
rpgLiteThrowDamage(profile, weight, maximum)
{
    local lift = profile.basicLiftHundredths();
    if (weight < 1 || weight > lift * 8) throw new RpgError();
    local damage = rpgLiteDamageDice(profile.st, nil); local dice = damage[1]; local adds = damage[2];
    if (weight * 8 <= lift) adds -= 2 * dice;
    else if (weight * 4 <= lift) adds -= dice;
    else if (weight * 2 <= lift) adds += 0;
    else if (weight <= lift) adds += dice;
    else if (weight <= lift * 2) adds += 0;
    else if (weight <= lift * 4) adds -= (dice + 1) / 2;
    else adds -= dice;
    return rpgLiteRollDamage(dice, adds, 'cr', maximum);
}

/** Look up impact yards per second, rounding height to the next supplied table row. */
rpgLiteFallVelocity(yards)
{
    rpgInteger(yards, 0, 1000);
    if (yards == 0) return 0;
    local table = [[1,5],[2,7],[3,8],[4,9],[5,10],[10,15],[15,18],[20,21],
        [30,26],[40,30],[50,33],[75,40],[100,47],[1000,146]];
    foreach (local row in table) if (yards <= row[1]) return row[2];
    throw new RpgError();
}

/** Roll collision damage from HP and yards per second. */
rpgLiteCollisionDamage(hp, velocity)
{
    rpgInteger(hp, 1, 10000); rpgInteger(velocity, 0, 10000);
    if (velocity == 0) return 0;
    local dice = hp * velocity / 100;
    return rpgLiteRollDamage(dice < 1 ? 1 : dice, dice < 1 ? -2 : 0, 'cr', nil);
}

/** Apply falling injury, breakable-obstacle cap, armor and eligible Catfall. */
rpgLiteFall(profile, yards, freeToTwist, obstacleHP, obstacleDR)
{
    local catfall = profile.level('catfall') > 0 && freeToTwist;
    if (catfall) { yards -= 5; if (yards < 0) yards = 0; }
    local damage = rpgLiteCollisionDamage(profile.maxHP, rpgLiteFallVelocity(yards));
    if (obstacleHP != nil && damage > obstacleHP + obstacleDR) damage = obstacleHP + obstacleDR;
    if (catfall && rpgLiteAttributeCheck(profile, rpgDX, 'catfall', 0).achieved) damage /= 2;
    return rpgLiteWound(profile, rpgLitePenetration(damage, rpgLiteArmor(profile), 1, 'cr', nil));
}

/** Calculate daily mileage in hundredths, with terrain, weather and successful Hiking. */
rpgLiteHikingMilesHundredths(profile, terrain, weatherPercent, succeeded)
{
    rpgInteger(weatherPercent, 0, 100);
    local multiplier = terrain == 'very-bad' ? 20 : terrain == 'bad' ? 50
        : terrain == 'average' ? 100 : terrain == 'good' ? 125 : 0;
    if (multiplier == 0) throw new RpgError();
    return profile.move() * 10 * multiplier * weatherPercent / 100 * (succeeded ? 120 : 100) / 100;
}

/** Persistent travel/exertion activity with periodic climbing, running and swimming checks. */
class RpgLiteJourney: object
    profile = nil
    skill = nil
    kind = 'hiking'
    elapsed = 0
    clock = 0
    swimmingInterval = 300
    struggling = nil
    intentional = true
    entered = nil
    secured = nil
    combatPace = nil
    surfaceModifier = 0
    surface = 'mountain'
    swimClock = 0
    fallen = nil
    checks = []
    advance(seconds)
    {
        rpgInteger(seconds, 0, 86400);
        if (!holds(['hiking','sprint','paced','swimming','swim-fast','climbing','overload'], self.kind)) throw new RpgError();
        local result = new RpgLiteHealthResult();
        if (self.profile.dead || self.profile.unconscious || self.fallen)
        { result.status = 'blocked'; return result; }
        if (!rpgLiteCanAct(self.profile, nil)) { result.status = 'blocked'; return result; }
        if (self.skill == nil && holds(['climbing','swimming','swim-fast'], self.kind))
            self.skill = rpgLiteTraining(self.profile, self.kind == 'climbing' ? 'climbing' : 'swimming', nil, nil);
        self.profile.restClock = 0;
        if (!self.entered && holds(['swimming','swim-fast','climbing'], self.kind))
        {
            self.entered = true;
            if (self.kind == 'climbing') self.check(0, result);
            else self.afloat(self.intentional ? 3 : 0, result);
        }
        for (local elapsed = 0; elapsed < seconds && !self.profile.dead && !self.profile.unconscious && !self.fallen; elapsed += 1)
        {
            self.clock += 1; self.elapsed += 1; result.seconds += 1;
            if (self.kind == 'swim-fast')
            {
                self.swimClock += 1;
                if (self.swimClock >= self.swimmingInterval)
                { self.swimClock = 0; self.afloat(0, result); }
            }
            local interval = self.kind == 'hiking' ? 3600 : self.kind == 'sprint' ? 15
                : self.kind == 'paced' || self.kind == 'swim-fast' ? 60
                : self.kind == 'swimming' ? self.swimmingInterval : self.kind == 'climbing' ? 300 : 1;
            if (self.clock >= interval)
            {
                self.clock = 0;
                if (self.kind == 'hiking') result.fatigue += rpgLiteFatigue(self.profile, 1 + self.profile.encumbrance(), 'exertion').fatigue;
                else if (self.kind == 'overload')
                {
                    if (self.profile.loadHundredths() > self.profile.basicLiftHundredths() * 10)
                        result.fatigue += rpgLiteFatigue(self.profile, 1, 'exertion').fatigue;
                }
                else if (self.kind == 'swimming') self.afloat(0, result);
                else self.check(0, result);
            }
            if (self.struggling && self.profile.fp() <= 0
                && !rpgLiteAttributeCheck(self.profile, rpgWill, 'drowning', 0).achieved) self.profile.unconscious = true;
        }
        rpgSpendTime(result.seconds); return result;
    }
    afloat(modifier, result)
    {
        local context = new RpgLiteContext(); context.skill = self.skill; context.modifier = modifier;
        result.check = rpgLiteCheck(self.profile, context); self.checks = self.checks + [result.check];
        if (!result.check.achieved)
        { result.fatigue += rpgLiteFatigue(self.profile, 1, 'exertion').fatigue; self.struggling = true; self.swimmingInterval = 5; }
        else { self.swimmingInterval = self.struggling ? 60 : 300; self.struggling = nil; }
        return nil;
    }
    check(modifier, result)
    {
        local context = new RpgLiteContext(); context.skill = self.skill; context.modifier = modifier;
        if (self.kind == 'sprint' || self.kind == 'paced') { context.skill = nil; context.attribute = rpgHT; }
        if (self.kind == 'swim-fast' && (self.skill == nil || self.profile.skillScore(self.skill) < self.profile.ht))
        { context.skill = nil; context.attribute = rpgHT; }
        if (self.kind == 'climbing')
        {
            local data = rpgLiteClimbData(self.surface);
            if (data[2] == nil) return nil;
            context.modifier += self.surfaceModifier + data[2];
        }
        result.check = rpgLiteCheck(self.profile, context); self.checks = self.checks + [result.check];
        if (self.kind == 'climbing')
        {
            if (self.combatPace) result.fatigue += rpgLiteFatigue(self.profile, 1, 'exertion').fatigue;
            if (!result.check.achieved) self.fallen = !self.secured || result.check.critical == 'failure';
        }
        else if (!result.check.achieved)
        {
            result.fatigue += rpgLiteFatigue(self.profile, 1, 'exertion').fatigue;
            if (self.kind == 'swimming') { self.struggling = true; self.swimmingInterval = 5; }
        }
        else if (self.kind == 'swimming')
        {
            self.swimmingInterval = self.struggling ? 60 : 300; self.struggling = nil;
        }
        return nil;
    }
    speedHundredths()
    {
        if (self.kind == 'climbing')
        {
            local data = rpgLiteClimbData(self.surface);
            return data[self.combatPace ? 3 : 4] * 100 / (data[5] == 'feet' ? 180 : 60);
        }
        if (self.kind == 'swimming' || self.kind == 'swim-fast')
        {
            local movementScore = self.profile.basicMove() / 5;
            if (movementScore < 1) movementScore = 1;
            return movementScore * 100 / (self.profile.fp() * 3 <= self.profile.maxEnergy ? 2 : 1);
        }
        local movementScore = self.profile.move() * 100;
        if (self.profile.fp() * 3 == self.profile.maxEnergy) movementScore /= 2;
        if (self.kind == 'sprint' && self.elapsed >= 1 && self.profile.posture == 'standing') movementScore = movementScore * 120 / 100;
        if (self.kind == 'paced') movementScore = movementScore * 60 / 100;
        return movementScore;
    }
;

/** Timed or opposed skill activity with repeated attempts and skill-specific outcomes. */
class RpgLiteSkillTask: object
    profile = nil
    skill = nil
    context = nil
    opponentScore = nil
    attempts = 0
    certified = nil
    reactionModifier = 0
    companions = []
    resolve()
    {
        if (self.skill == nil) throw new RpgError();
        if (self.context == nil) { self.context = new RpgLiteContext(); self.context.skill = self.skill; }
        local score = rpgLiteScore(self.profile, self.context);
        if (score == nil || score < 3) return nil;
        if (self.skill.id == 'forgery' && self.certified) return rpgCheck(score, 3);
        local ownRoll = rpgRandom.roll();
        if (self.context.reroll(self.profile,rpgCheck(score,ownRoll))) ownRoll = rpgLiteReroll(self.profile,ownRoll,3,nil);
        local result = rpgEvaluate(score, ownRoll, self.opponentScore,
            self.opponentScore == nil ? nil : rpgRandom.roll(), 0);
        local seconds = self.skill.id == 'escape' ? (self.attempts == 0 ? 60 : 600)
            : self.skill.id == 'lockpicking' ? 60 : self.skill.id == 'interrogation' ? 300
            : self.skill.id == 'scrounging' ? 3600 : self.skill.id == 'shadowing' ? 600
            : self.skill.id == 'tracking' ? (self.attempts == 0 ? 0 : 900) : self.skill.id == 'survival' ? 86400 : self.skill.interval;
        if (self.skill.id == 'lockpicking' && result.achieved)
        { seconds -= result.margin * 5; if (seconds < 0) seconds = 0; }
        if (self.skill.id == 'forgery' && self.attempts == 0 && result.critical == 'success') self.certified = true;
        if (self.skill.id == 'carousing') self.reactionModifier = result.achieved ? 2 : -2;
        if (self.skill.id == 'survival' && !result.achieved)
        {
            rpgLiteWound(self.profile, rpgLiteRollDamage(2, -4, 'cr', nil));
            foreach (local companion in self.companions) rpgLiteWound(companion, rpgLiteRollDamage(2, -4, 'cr', nil));
        }
        rpgSpendTime(seconds); self.attempts += 1; return result;
    }
;
