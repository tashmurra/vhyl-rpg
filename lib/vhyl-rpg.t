/* Optional mundane character and challenge mechanics. Include after vhyl.t.
 * Copyright (c) 2026 John Cunningham. MIT License; see LICENSE. */

enum rpgST, rpgDX, rpgIQ, rpgHT, rpgWill, rpgPerception;

/** Invalid configuration or an invalid mechanics API argument. */
class RpgError: object;

/** Optional binding from a vhyl world entity to its authored profile. */
modify Thing
    /* Optional authored profile; the resolver also accepts profiles directly. */
    rpgProfile = nil
;

/** A skill's governing attribute, training difficulty and explicit default.
 * difficulty: 0, 1 or 2. defaultPenalty: a nonpositive integer, or nil for
 * training only. Do not infer a default from difficulty. */
class RpgSkill: object
    labelId = nil
    attribute = rpgIQ
    difficulty = 1
    /* A specialized skill may opt into a wider validated difficulty range. */
    maximumDifficulty() { return 2; }
    defaultPenalty = nil
;

/** Investment in one skill. Zero reserves an untrained slot for progression;
 * positive values buy training. The core never awards or spends points itself. */
class RpgTraining: object
    skill = nil
    points = 1
;

/** An authored benefit or limitation. The modifier hook is observational.
 * Use c.skill and c.isOpposition to keep its application appropriately narrow. */
class RpgTrait: object
    labelId = nil
    modifierFor(c) { return 0; }
;

/** Share this model between protagonists and supporting characters.
 * skills and traits are authored lists. Optional modules add injury, recovery
 * and progression; a core-only profile retains the simple energy pool. */
class RpgProfile: object
    actor = nil
    st = 10
    dx = 10
    iq = 10
    ht = 10
    will = (iq)
    perception = (iq)
    maxHP = (st)
    maxEnergy = (ht)
    energy = (maxEnergy)
    skills = []
    traits = []

    /* Observational extension points. Optional modules supply condition state. */
    blockedReason(c) { return nil; }
    modifiersFor(c) { return []; }
    afterAttempt(c, result) { return nil; }

    attributeScore(which)
    {
        switch (which)
        {
        case rpgST: return self.st;
        case rpgDX: return self.dx;
        case rpgIQ: return self.iq;
        case rpgHT: return self.ht;
        case rpgWill: return self.will;
        case rpgPerception: return self.perception;
        }
        throw new RpgError();
    }

    skillScore(skill)
    {
        local base = self.attributeScore(skill.attribute);
        foreach (local training in self.skills)
        {
            if (training.skill != skill) continue;
            local points = training.points;
            if (points == 0) continue;
            if (points >= 8) return base + 3 - skill.difficulty + (points - 8) / 4;
            if (points >= 4) return base + 2 - skill.difficulty;
            if (points >= 2) return base + 1 - skill.difficulty;
            return base - skill.difficulty;
        }
        if (skill.defaultPenalty == nil) return nil;
        return (base > 20 ? 20 : base) + skill.defaultPenalty;
    }
;

/** A shared goal. completed closes every approach for every character.
 * advance() permits fresh attempts after a meaningful, authored world change.
 * Never call advance merely because a command, preview or refresh occurred. */
class RpgChallenge: object
    id = nil
    completed = nil
    revision = 0
    advance() { rpgInteger(self.revision, 0, 2147483646); self.revision += 1; return nil; }
;

/** One method of pursuing a goal. Hooks use original game-specific content.
 * blockedReason, modifierFor and oppositionModifierFor must be observational.
 * apply runs once per fresh resolution, including failures and ties. */
class RpgApproach: object
    id = nil
    challenge = nil
    skill = nil
    attribute = rpgIQ
    modifier = 0
    modifierLabelId = 'rpg.modifier.situation'
    contextLabelId = 'rpg.modifier.preparation'
    automatic = nil
    completesChallenge = true
    timeCost = 0
    energyCost = 0
    /* Ordinary failures within this margin can achieve the goal at a cost.
     * Zero disables this policy. It never promotes critical failures or ties. */
    costlyMargin = 0
    opponent = nil
    oppositionSkill = nil
    oppositionAttribute = rpgWill
    oppositionModifier = 0
    oppositionModifierLabelId = 'rpg.modifier.opposition'
    oppositionContextLabelId = 'rpg.modifier.opposition-preparation'
    blockedReason(c) { return nil; }
    modifierFor(c) { return 0; }
    oppositionModifierFor(c) { return 0; }
    apply(c, result) { return nil; }
;

/** Temporary execution context. Do not retain it in persistent properties. */
class RpgContext: object
    profile = nil
    actor = nil
    approach = nil
    challenge = nil
    skill = nil
    isOpposition = nil
;

/** Temporary explanation, shared by assessment and execution. Only scalar
 * snapshot data is retained by attempts. Modifier triples are category, label,
 * amount; after 31 components, remaining adjustments are grouped as other. */
class RpgCalculation: object
    abilityLabelId = nil
    attributeId = nil
    training = 'attribute'
    attributeScore = nil
    defaultPenalty = nil
    baseScore = nil
    effectiveScore = nil
    modifiers = []
    otherModifier = 0
    pack()
    {
        return [self.abilityLabelId, self.attributeId, self.training,
            self.attributeScore, self.defaultPenalty, self.baseScore,
            self.effectiveScore, self.modifiers];
    }
;

/** Trusted, observational preparation. Reporting extensions can add odds to
 * this temporary value. ready is the only status that permits a fresh roll. */
class RpgAssessment: object
    profile = nil
    approach = nil
    status = 'blocked'
    reason = nil
    kind = nil
    calculation = nil
    oppositionCalculation = nil
    timeCost = 0
    energyCost = 0
    costlyMargin = 0
    recorded = nil
;

/** Temporary result. Scores and dice are private unless the author discloses
 * them. status: resolved, reused, blocked or complete. outcome: success,
 * costly-success, setback, complication or tie (nil when not resolved). */
class RpgResult: object
    status = 'blocked'
    reason = nil
    profile = nil
    approach = nil
    outcome = nil
    achieved = nil
    score = nil
    roll = nil
    margin = nil
    critical = nil
    oppositionScore = nil
    oppositionRoll = nil
    oppositionMargin = nil
    oppositionCritical = nil
    timeSpent = 0
    energySpent = 0
    recordedTimeSpent = 0
    recordedEnergySpent = 0
    kind = nil
    calculation = nil
    oppositionCalculation = nil
    dice = []
    oppositionDice = []
    rollSucceeded = nil
    oppositionSucceeded = nil
;

/** Predeclare one slot per permitted (profile, approach) pair. Scalar state is
 * journalled without allocating permanent entities during play. The slot is
 * also the retry authority shared by parser, structured and dialogue actions. */
class RpgAttempt: object
    profile = nil
    approach = nil
    revision = -1
    outcome = nil
    achieved = nil
    score = nil
    roll = nil
    margin = nil
    critical = nil
    oppositionScore = nil
    oppositionRoll = nil
    oppositionMargin = nil
    oppositionCritical = nil
    kind = nil
    calculationData = nil
    oppositionCalculationData = nil
    recordedTimeSpent = 0
    recordedEnergySpent = 0
    dice = []
    oppositionDice = []
    rollSucceeded = nil
    oppositionSucceeded = nil

    remember(result)
    {
        self.revision = self.approach.challenge.revision;
        self.outcome = result.outcome; self.achieved = result.achieved;
        self.score = result.score; self.roll = result.roll; self.margin = result.margin;
        self.critical = result.critical; self.oppositionScore = result.oppositionScore;
        self.oppositionRoll = result.oppositionRoll;
        self.oppositionMargin = result.oppositionMargin;
        self.oppositionCritical = result.oppositionCritical;
        self.kind = result.kind;
        self.calculationData = result.calculation == nil ? nil : result.calculation.pack();
        self.oppositionCalculationData = result.oppositionCalculation == nil
            ? nil : result.oppositionCalculation.pack();
        self.dice = result.dice; self.oppositionDice = result.oppositionDice;
        self.rollSucceeded = result.rollSucceeded;
        self.oppositionSucceeded = result.oppositionSucceeded;
        self.recordedTimeSpent = result.recordedTimeSpent;
        self.recordedEnergySpent = result.recordedEnergySpent;
        return nil;
    }
    recall(result)
    {
        if (self.revision < 0) return result;
        result.status = 'reused'; result.outcome = self.outcome;
        result.achieved = self.achieved; result.score = self.score;
        result.roll = self.roll; result.margin = self.margin; result.critical = self.critical;
        result.oppositionScore = self.oppositionScore;
        result.oppositionRoll = self.oppositionRoll;
        result.oppositionMargin = self.oppositionMargin;
        result.oppositionCritical = self.oppositionCritical;
        result.kind = self.kind;
        result.calculation = rpgUnpackCalculation(self.calculationData);
        result.oppositionCalculation = rpgUnpackCalculation(self.oppositionCalculationData);
        result.dice = self.dice; result.oppositionDice = self.oppositionDice;
        result.rollSucceeded = self.rollSucceeded;
        result.oppositionSucceeded = self.oppositionSucceeded;
        result.recordedTimeSpent = self.recordedTimeSpent;
        result.recordedEnergySpent = self.recordedEnergySpent;
        return result;
    }
;

/** Only accounted challenge time, in seconds; not a replacement world clock.
 * vhyl continues to schedule one cycle per accepted command. */
rpgLedger: object
    seconds = 0
    validateAdvance(seconds) { return nil; }
    afterAdvance(previousSeconds) { return nil; }
;

/** Charge explicit adventure time with a checked persistent counter. */
rpgSpendTime(seconds)
{
    rpgInteger(seconds, 0, 86400);
    rpgInteger(rpgLedger.seconds, 0, 2147483647 - seconds);
    rpgLedger.validateAdvance(seconds);
    local previous = rpgLedger.seconds;
    rpgLedger.seconds += seconds; rpgLedger.afterAdvance(previous); return nil;
}

/** Deterministic, journalled generator with overflow-safe arithmetic.
 * Set a seed from 1 through 2147483646 at game initialisation. */
rpgRandom: object
    state = 1
    draws = 0
    seed(value)
    {
        rpgInteger(value, 1, 2147483646);
        self.state = value; self.draws = 0; return nil;
    }
    die()
    {
        local next = 16807 * (self.state % 127773) - 2836 * (self.state / 127773);
        if (next <= 0) next += 2147483647;
        self.state = next; self.draws += 1;
        return self.state % 6 + 1;
    }
    dice()
    {
        /* Separate calls: source argument evaluation order is irrelevant. */
        local one = self.die(); local two = self.die(); local three = self.die();
        return [one, two, three];
    }
    roll() { return rpgDiceTotal(self.dice()); }
;

/** Pure numerical check; no randomness, world writes, output or time costs.
 * Scores below three cannot be attempted. critical is success, failure or nil. */
rpgCheck(score, roll)
{
    rpgInteger(score, -1000, 1000); rpgInteger(roll, 3, 18);
    local result = new RpgResult(); result.score = score;
    if (score < 3) { result.reason = 'too-difficult'; return result; }
    result.status = 'resolved'; result.roll = roll; result.margin = score - roll;
    if (roll == 18 || (roll == 17 && score <= 15) || roll - score >= 10)
        result.critical = 'failure';
    else if (roll <= 4 || (roll == 5 && score >= 15) || (roll == 6 && score >= 16))
        result.critical = 'success';
    result.achieved = (roll <= 4 || roll <= score) && roll < 17;
    result.rollSucceeded = result.achieved;
    result.outcome = result.achieved ? 'success'
        : result.critical == 'failure' ? 'complication' : 'setback';
    return result;
}

rpgInteger(value, low, high)
{
    if (dataType(value) != TypeInt || value < low || value > high)
        throw new RpgError();
    return nil;
}

rpgContext(profile, approach, opposing)
{
    local c = new RpgContext(); c.profile = profile; c.actor = profile.actor;
    c.approach = approach; c.challenge = approach.challenge;
    c.isOpposition = opposing;
    c.skill = opposing ? approach.oppositionSkill : approach.skill;
    return c;
}

rpgAttributeId(attribute)
{
    switch (attribute)
    {
    case rpgST: return 'rpg.strength';
    case rpgDX: return 'rpg.coordination';
    case rpgIQ: return 'rpg.intelligence';
    case rpgHT: return 'rpg.health';
    case rpgWill: return 'rpg.will';
    case rpgPerception: return 'rpg.perception';
    }
    throw new RpgError();
}

rpgUnpackCalculation(data)
{
    if (data == nil) return nil;
    local value = new RpgCalculation();
    value.abilityLabelId = data[1]; value.attributeId = data[2];
    value.training = data[3]; value.attributeScore = data[4];
    value.defaultPenalty = data[5]; value.baseScore = data[6];
    value.effectiveScore = data[7]; value.modifiers = data[8];
    return value;
}

rpgAddModifier(calculation, category, label, amount)
{
    rpgInteger(amount, -1000, 1000);
    if (amount == 0) return nil;
    if (calculation.modifiers.length() < 93)
        calculation.modifiers = calculation.modifiers + [category, label, amount];
    else calculation.otherModifier += amount;
    return nil;
}

rpgCalculate(c)
{
    local a = c.approach;
    local value = new RpgCalculation();
    local attribute = c.skill == nil
        ? c.isOpposition ? a.oppositionAttribute : a.attribute : c.skill.attribute;
    value.attributeId = rpgAttributeId(attribute);
    value.attributeScore = c.profile.attributeScore(attribute);
    value.abilityLabelId = c.skill == nil ? value.attributeId : c.skill.labelId;
    value.baseScore = c.skill == nil ? value.attributeScore : c.profile.skillScore(c.skill);
    if (c.skill != nil)
    {
        value.training = value.baseScore == nil ? 'unavailable' : 'default';
        foreach (local training in c.profile.skills)
            if (training.skill == c.skill && training.points > 0) value.training = 'trained';
        if (value.training == 'default')
        {
            value.defaultPenalty = c.skill.defaultPenalty;
            if (value.attributeScore > 20) value.attributeScore = 20;
        }
    }
    if (value.baseScore == nil) return value;
    local fixed = c.isOpposition ? a.oppositionModifier : a.modifier;
    local contextual = c.isOpposition ? a.oppositionModifierFor(c) : a.modifierFor(c);
    rpgAddModifier(value, 'situation', c.isOpposition
        ? a.oppositionModifierLabelId : a.modifierLabelId, fixed);
    rpgAddModifier(value, 'context', c.isOpposition
        ? a.oppositionContextLabelId : a.contextLabelId, contextual);
    local modifier = fixed + contextual;
    foreach (local trait in c.profile.traits)
    {
        local adjustment = trait.modifierFor(c); modifier += adjustment;
        rpgAddModifier(value, 'trait', trait.labelId, adjustment);
    }
    local extras = c.profile.modifiersFor(c);
    if (extras.length() % 3 != 0) throw new RpgError();
    for (local i = 1; i <= extras.length(); i += 3)
    {
        modifier += extras[i + 2];
        rpgAddModifier(value, extras[i], extras[i + 1], extras[i + 2]);
    }
    rpgInteger(modifier, -500, 500);
    if (value.otherModifier != 0)
        value.modifiers = value.modifiers + ['other', 'rpg.modifier.other', value.otherModifier];
    value.effectiveScore = value.baseScore + modifier;
    rpgInteger(value.effectiveScore, -1000, 1000);
    return value;
}

rpgScore(c) { return rpgCalculate(c).effectiveScore; }

rpgDiceTotal(dice) { return dice[1] + dice[2] + dice[3]; }

/** Pure outcome policy shared by actual attempts and probability enumeration. */
rpgEvaluate(score, roll, oppositionScore, oppositionRoll, costlyMargin)
{
    local result = rpgCheck(score, roll);
    if (result.status == 'blocked') return result;
    if (oppositionScore != nil)
    {
        local defense = rpgCheck(oppositionScore, oppositionRoll);
        if (defense.status == 'blocked')
        { result.status = 'blocked'; result.reason = 'opposition-unavailable'; return result; }
        result.oppositionScore = defense.score; result.oppositionRoll = defense.roll;
        result.oppositionMargin = defense.margin; result.oppositionCritical = defense.critical;
        result.oppositionSucceeded = defense.achieved;
        local won = result.achieved && !defense.achieved
            || result.achieved == defense.achieved && result.margin > defense.margin;
        local tied = result.achieved == defense.achieved && result.margin == defense.margin;
        result.achieved = won;
        result.outcome = won ? 'success' : tied ? 'tie'
            : result.critical == 'failure' ? 'complication' : 'setback';
    }
    if (result.outcome == 'setback' && costlyMargin > 0
        && result.margin < 0 && -result.margin <= costlyMargin && oppositionScore == nil)
    { result.outcome = 'costly-success'; result.achieved = true; }
    return result;
}

rpgAttemptFor(profile, approach)
{
    local found = nil;
    for (local slot = firstObj(RpgAttempt); slot != nil; slot = nextObj(slot, RpgAttempt))
    {
        if (slot.profile != profile || slot.approach != approach) continue;
        if (found != nil) throw new RpgError();
        found = slot;
    }
    if (found == nil) throw new RpgError();
    return found;
}

/** Trusted observational preparation shared by assessment and resolution.
 * Configuration errors throw. Ordinary impossibility returns blocked without
 * rolling, charging or caching it. Prerequisite and modifier hooks must be pure. */
rpgPrepare(profile, approach)
{
    if (profile == nil || !profile.ofKind(RpgProfile)
        || approach == nil || !approach.ofKind(RpgApproach)) throw new RpgError();
    local slot = rpgAttemptFor(profile, approach);
    local result = new RpgAssessment(); result.profile = profile; result.approach = approach;
    local challenge = approach.challenge;
    if (challenge.completed) { result.status = 'complete'; return result; }
    local c = rpgContext(profile, approach, nil);
    result.reason = profile.blockedReason(c);
    if (result.reason != nil) return result;
    result.reason = approach.blockedReason(c);
    if (result.reason != nil) return result;
    if (slot.revision == challenge.revision)
    {
        result.status = 'settled';
        local recorded = new RpgResult(); recorded.profile = profile; recorded.approach = approach;
        result.recorded = slot.recall(recorded); result.kind = result.recorded.kind;
        result.calculation = result.recorded.calculation;
        result.oppositionCalculation = result.recorded.oppositionCalculation;
        return result;
    }
    if (profile.energy < approach.energyCost)
    { result.reason = 'insufficient-energy'; return result; }

    result.kind = approach.automatic ? 'automatic' : approach.opponent == nil ? 'check' : 'contest';
    if (!approach.automatic)
    {
        result.calculation = rpgCalculate(c);
        local score = result.calculation.effectiveScore;
        if (score == nil) { result.reason = 'training-required'; return result; }
        if (score < 3) { result.reason = 'too-difficult'; return result; }
        if (approach.opponent != nil)
        {
            local defense = rpgContext(approach.opponent, approach, true);
            if (approach.opponent.blockedReason(defense) != nil)
            { result.reason = 'opposition-unavailable'; return result; }
            result.oppositionCalculation = rpgCalculate(defense);
            local opposingScore = result.oppositionCalculation.effectiveScore;
            if (opposingScore == nil || opposingScore < 3)
            { result.reason = 'opposition-unavailable'; return result; }
        }
    }
    result.status = 'ready'; result.timeCost = approach.timeCost; result.energyCost = approach.energyCost;
    result.costlyMargin = approach.costlyMargin;
    return result;
}

/** Commit an attempt using the shared preparation. Call only from a gameplay
 * execution/selection hook. Exceptions roll back the enclosing turn. */
rpgResolve(profile, approach)
{
    local prepared = rpgPrepare(profile, approach);
    if (prepared.recorded != nil) return prepared.recorded;
    local result = new RpgResult(); result.profile = profile; result.approach = approach;
    result.reason = prepared.reason;
    if (prepared.status != 'ready') { result.status = prepared.status; return result; }
    if (prepared.kind == 'automatic')
    { result.status = 'resolved'; result.outcome = 'success'; result.achieved = true; }
    else
    {
        local dice = rpgRandom.dice(); local oppositionDice = [];
        local opposingScore = nil; local opposingRoll = nil;
        if (prepared.oppositionCalculation != nil)
        {
            opposingScore = prepared.oppositionCalculation.effectiveScore;
            oppositionDice = rpgRandom.dice(); opposingRoll = rpgDiceTotal(oppositionDice);
        }
        result = rpgEvaluate(prepared.calculation.effectiveScore, rpgDiceTotal(dice),
            opposingScore, opposingRoll, prepared.costlyMargin);
        result.dice = dice; result.oppositionDice = oppositionDice;
        result.profile = profile; result.approach = approach;
    }
    result.kind = prepared.kind; result.calculation = prepared.calculation;
    result.oppositionCalculation = prepared.oppositionCalculation;
    profile.energy -= approach.energyCost;
    rpgSpendTime(approach.timeCost);
    result.timeSpent = approach.timeCost; result.energySpent = approach.energyCost;
    result.recordedTimeSpent = result.timeSpent; result.recordedEnergySpent = result.energySpent;
    /* Cache before consequences, preventing a hook from resolving itself twice. */
    rpgAttemptFor(profile, approach).remember(result);
    if (result.achieved && approach.completesChallenge) approach.challenge.completed = true;
    profile.afterAttempt(rpgContext(profile, approach, nil), result);
    approach.apply(rpgContext(profile, approach, nil), result);
    return result;
}

/** Explicit, player-safe result envelope. No skill scores, rolls, opponent
 * identities, margins or critical flags are published automatically. */
rpgPublish(result)
{
    event('rpg.result'); eventValue(1);
    eventValue(result.approach.challenge.id); eventValue(result.approach.id);
    eventValue(result.profile.actor); eventValue(result.status);
    eventValue(result.outcome); eventValue(result.reason);
    eventValue(result.achieved); eventValue(result.timeSpent); eventValue(result.energySpent);
    return nil;
}

/** Validate declarations before play. Lists/slots are intentionally explicit:
 * misspelled training and duplicate retry slots must not silently change play. */
rpgValidation: InitObject
    execute()
    {
        for (local skill = firstObj(RpgSkill); skill != nil; skill = nextObj(skill, RpgSkill))
        {
            rpgInteger(skill.difficulty, 0, skill.maximumDifficulty());
            rpgValidateAttribute(skill.attribute);
            if (skill.defaultPenalty != nil) rpgInteger(skill.defaultPenalty, -100, 0);
        }
        for (local p = firstObj(RpgProfile); p != nil; p = nextObj(p, RpgProfile))
        {
            foreach (local attribute in [rpgST, rpgDX, rpgIQ, rpgHT, rpgWill, rpgPerception])
                rpgInteger(p.attributeScore(attribute), 1, 100);
            rpgInteger(p.maxHP, 1, 1000); rpgInteger(p.maxEnergy, 0, 1000);
            rpgInteger(p.energy, 0, p.maxEnergy);
            local seen = [];
            foreach (local training in p.skills)
            {
                if (!training.ofKind(RpgTraining) || training.skill == nil
                    || !training.skill.ofKind(RpgSkill) || holds(seen, training.skill))
                    throw new RpgError();
                rpgInteger(training.points, 0, 10000); seen = seen + [training.skill];
            }
            foreach (local trait in p.traits)
                if (!trait.ofKind(RpgTrait)) throw new RpgError();
        }
        for (local a = firstObj(RpgApproach); a != nil; a = nextObj(a, RpgApproach))
        {
            if (a.challenge == nil || !a.challenge.ofKind(RpgChallenge)
                || dataType(a.id) != TypeSString || a.id == ''
                || dataType(a.challenge.id) != TypeSString || a.challenge.id == '')
                throw new RpgError();
            rpgInteger(a.timeCost, 0, 86400); rpgInteger(a.energyCost, 0, 1000);
            rpgInteger(a.costlyMargin, 0, 100); rpgInteger(a.modifier, -500, 500);
            rpgInteger(a.oppositionModifier, -500, 500);
            rpgInteger(a.challenge.revision, 0, 2147483646);
            rpgValidateAttribute(a.attribute); rpgValidateAttribute(a.oppositionAttribute);
            if (a.skill != nil && !a.skill.ofKind(RpgSkill)) throw new RpgError();
            if (a.oppositionSkill != nil && !a.oppositionSkill.ofKind(RpgSkill))
                throw new RpgError();
            if (a.opponent != nil && (!a.opponent.ofKind(RpgProfile) || a.automatic))
                throw new RpgError();
            for (local other = firstObj(RpgApproach); other != nil; other = nextObj(other, RpgApproach))
                if (other != a && other.challenge == a.challenge && other.id == a.id)
                    throw new RpgError();
        }
        for (local challenge = firstObj(RpgChallenge); challenge != nil;
             challenge = nextObj(challenge, RpgChallenge))
            for (local other = firstObj(RpgChallenge); other != nil;
                 other = nextObj(other, RpgChallenge))
                if (other != challenge && other.id == challenge.id) throw new RpgError();
        for (local slot = firstObj(RpgAttempt); slot != nil; slot = nextObj(slot, RpgAttempt))
        {
            if (slot.profile == nil || !slot.profile.ofKind(RpgProfile)
                || slot.approach == nil || !slot.approach.ofKind(RpgApproach))
                throw new RpgError();
            rpgAttemptFor(slot.profile, slot.approach);
        }
        return nil;
    }
;

rpgValidateAttribute(value)
{
    if (!holds([rpgST, rpgDX, rpgIQ, rpgHT, rpgWill, rpgPerception], value))
        throw new RpgError();
    return nil;
}

/** Structured-action boundary with explicit exception cleanup and journal rollback.
 * Use at the exported host boundary, not inside another action. This releases
 * caught mechanics exceptions before returning to the host's save boundary. */
rpgDispatchAction(verb,subjects)
{
    try { return vhylAct(verb,subjects); }
    catch (RpgError error) { }
    if (turnJournalLength() > 0) { endTurn(); undo(); beginTurn(); }
    local result = new RpgResult(); result.reason = 'exception-rolled-back'; return result;
}
/** Parser counterpart of rpgDispatchAction, with the same journal boundary. */
rpgDispatchTurn(tokens)
{
    try { return vhylTurn(tokens); }
    catch (RpgError error) { }
    if (turnJournalLength() > 0) { endTurn(); undo(); beginTurn(); }
    local result = new RpgResult(); result.reason = 'exception-rolled-back'; return result;
}
