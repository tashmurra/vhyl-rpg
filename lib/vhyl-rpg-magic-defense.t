/* Defenses operate after the paid casting roll and before delivery. */
class RpgMagicCounter: object
    state = nil
    participants = []
    ready = true
    interrupted = nil
;
class RpgMagicDefense: object
    target = nil
    margin = 0
    resisted = nil
    check = nil
    countered = 0
;
modify RpgMagicIntent
    counters = []
;
modify RpgMagicResult
    scope = 0
    defenses = []
;
modify RpgMagicEffect
    personalPerception = nil
    targets = []
    possession = nil
    defend(intent, result) { return nil; }
;

/** Declaration order is authoritative initiative order, fixed before the roll. */
rpgMagicCounterScope(intent, result)
{
    local scope = result.check.margin; local seen = [];
    if (!result.check.rollSucceeded) return scope;
    foreach (local counter in intent.counters)
    {
        local participants = counter.participants.length() == 0 ? [counter.state] : counter.participants;
        local eligible = counter.ready; local amount = 0; local critical = nil;
        foreach (local s in participants)
        {
            if (s == nil || holds(seen,s)) rpgExpandedReject('magic-counter-duplicate'); seen = seen + [s];
            foreach (local pair in result.effect.requirements)
                if (rpgMagicSkill(s,pair[1],1) == nil) eligible = nil;
        }
        if (eligible)
        {
            foreach (local s in participants)
            {
                if (s.ritual != nil || s.work != nil) rpgInterruptMagic(s,'defense');
                local score = s.mastery == 10 ? 20 : 10 + s.mastery;
                local check = rpgCheck(score,rpgRandom.roll());
                local d = new RpgMagicDefense(); d.check = check;
                if (check.rollSucceeded) amount += check.margin;
                if (check.critical == 'failure') critical = true;
                result.defenses = result.defenses + [d];
            }
            if (!critical && amount > 0) scope -= amount;
        }
    }
    return scope;
}

/** Direct living/sapient resistance: capped original dice, independent of scope.
 * A failed defender loses to a successful attacker; ties defend. */
rpgMagicResist(target, score, dice, scope, possession)
{
    local d = new RpgMagicDefense(); d.target = target; d.margin = scope;
    if (!(target.alive || target.sapient) || target.willing && target.aware && target.conscious && !possession)
        return d;
    if (target.profile == nil) rpgExpandedReject('magic-resistance-profile');
    local will = target.profile.attributeScore(rpgWill);
    local cap = will > 16 ? will : 16; if (score > cap) score = cap;
    local attack = rpgCheck(score,dice);
    if (!attack.rollSucceeded) { d.resisted = true; return d; }
    if (d.margin > attack.margin) d.margin = attack.margin;
    d.check = rpgCheck(will,rpgRandom.roll());
    d.resisted = d.check.rollSucceeded && d.check.margin >= d.margin;
    return d;
}

/** Indirect attacks use the target's authored physical delivery adapter. */
class RpgMagicPhysicalDefense: object
    score = 0
    enabled = nil
    cover = 0
    armor = nil
    resolve(target)
    { return self.enabled && rpgLiteDefenseCheck(self.score).rollSucceeded; }
;
modify RpgMagicSubject
    physicalDefense = nil
;

/** Complete result scope without consuming surplus margin as undeclared benefits. */
rpgMagicFinishScope(intent, result)
{
    local e = result.effect;
    result.scope = rpgMagicCounterScope(intent,result);
    local required = e.requiredMargin(result.check);
    result.outcome = !result.check.rollSucceeded ? 'failure'
        : result.scope >= required ? 'full'
        : e.partialMargin != nil && result.scope >= e.partialMargin ? 'partial' : 'insufficient';
    result.delivered = result.outcome == 'full' || result.outcome == 'partial';
    if (result.delivered) e.defend(intent,result);
    return nil;
}

modify RpgMagicResult
    resistanceRolls = []
;

/** Cooperative resistance caps each successful contribution using its original
 * dice, then bounds the sum by surviving scope. No new attack roll is made. */
rpgMagicResistContributions(target,result,possession)
{
    if (result.resistanceRolls.length() == 0)
        return rpgMagicResist(target,result.score,result.check.roll,result.scope,possession);
    local d = new RpgMagicDefense(); d.target = target; d.margin = result.scope;
    if (!(target.alive || target.sapient) || target.willing && target.aware && target.conscious && !possession) return d;
    if (target.profile == nil) rpgExpandedReject('magic-resistance-profile');
    local will = target.profile.attributeScore(rpgWill); local cap = will > 16 ? will : 16;
    local margin = 0; local success = nil;
    foreach (local contribution in result.resistanceRolls)
        if (contribution.check.rollSucceeded)
        {
            local score = contribution.score > cap ? cap : contribution.score;
            local check = rpgCheck(score,contribution.check.roll);
            if (check.rollSucceeded) { success = true; margin += check.margin; }
        }
    if (!success) { d.resisted = true; return d; }
    if (margin < d.margin) d.margin = margin;
    d.check = rpgCheck(will,rpgRandom.roll()); d.resisted = d.check.rollSucceeded && d.check.margin >= d.margin;
    return d;
}
