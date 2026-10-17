/* Optional bounded physical and social conflicts. Include after resilience.
 * Copyright (c) 2026 John Cunningham. MIT License. */

/** Authored NPC disposition. Permission to consider a request is separate from
 * the chance of persuasion. A success never overrides an explicit refusal. */
class RpgDisposition: object
    profile = nil
    attitude = 0
    permits(actor, approach) { return nil; }
;

/** Persistent social opposition using ordinary challenge retry records.
 * New facts or concessions, rather than repeated wording, reopen the goal. */
class RpgSocialApproach: RpgApproach
    disposition = nil
    requiresExertion = nil
    oppositionAttribute = rpgWill
    opponent = (disposition.profile)
    successShift = 1
    failureShift = -1
    blockedReason(c)
    {
        local reason = inherited(c);
        return reason != nil ? reason : self.disposition.permits(c.profile, self);
    }
    oppositionModifierFor(c) { return inherited(c) - self.disposition.attitude; }
    apply(c, result)
    {
        inherited(c, result);
        local attitude = self.disposition.attitude + (result.achieved ? self.successShift : self.failureShift);
        self.disposition.attitude = attitude < -3 ? -3 : attitude > 3 ? 3 : attitude;
        return nil;
    }
;

/** One owned combatant. Defaults describe a modest unarmed attack; games
 * explicitly author weapons, armor and permission to use them. */
class RpgCombatant: object
    profile = nil
    skill = nil
    attribute = rpgDX
    attackModifier = 0
    defense = nil
    armor = 0
    damageDice = 1
    damageBonus = -2
    woundNumerator = 1
    woundDenominator = 1
    energyCost = 1
    available(other) { return nil; }
    defenseScore()
    {
        local score = self.defense == nil
            ? (self.profile.attributeScore(rpgDX) + self.profile.attributeScore(rpgHT)) / 4 + 3
            : self.defense;
        local divisor = rpgBody(self.profile).mobilityDivisor();
        return (score + divisor - 1) / divisor;
    }
;

/** Two-sided authored scene. One player maneuver and one eligible reply form
 * an exchange, not a parser-wide combat clock. No unconscious actor attacks.
 * A bounded stalemate, escape and surrender keep nonlethal routes available. */
class RpgConflict: object
    id = nil
    protagonist = nil
    opposition = nil
    active = nil
    finished = nil
    outcome = nil
    exchanges = 0
    maxExchanges = 6
    secondsPerExchange = 2
    discloseRolls = nil
    available() { return nil; }
    ended(result) { return nil; }
;

/** Temporary strike details. Raw checks and damage dice are trusted data. */
class RpgStrike: object
    status = 'blocked'
    reason = nil
    outcome = nil
    attack = nil
    defense = nil
    dice = []
    defenseDice = []
    damageDice = []
    damage = 0
    injury = 0
;

/** Temporary exchange outcome; publishing it is an explicit game decision. */
class RpgConflictResult: object
    conflict = nil
    status = 'blocked'
    reason = nil
    maneuver = nil
    strike = nil
    reply = nil
    escape = nil
    recovery = nil
    outcome = nil
;

/** Begin a fresh authored conflict once. Resuming a finished scene requires a
 * different conflict object, rather than erasing its recorded outcome. */
rpgBeginConflict(conflict)
{
    if (conflict == nil || !conflict.ofKind(RpgConflict)) throw new RpgError();
    local value = new RpgConflictResult(); value.conflict = conflict;
    if (conflict.finished) { value.status = 'complete'; value.outcome = conflict.outcome; return value; }
    if (conflict.active) { value.status = 'reused'; return value; }
    value.reason = conflict.available();
    if (value.reason != nil) return value;
    if (rpgBody(conflict.protagonist.profile).unconscious || rpgBody(conflict.protagonist.profile).dead
        || rpgBody(conflict.opposition.profile).unconscious || rpgBody(conflict.opposition.profile).dead)
    { value.reason = 'rpg.unavailable-combatant'; return value; }
    conflict.active = true; value.status = 'resolved'; value.outcome = 'started'; return value;
}

rpgFinishConflict(value, outcome)
{
    local conflict = value.conflict;
    if (conflict.finished) return nil;
    conflict.active = nil; conflict.finished = true; conflict.outcome = outcome;
    value.outcome = outcome; conflict.ended(value); return nil;
}

rpgCombatMethod(combatant)
{
    local method = new RpgApproach(); method.skill = combatant.skill;
    method.attribute = combatant.attribute; method.modifier = combatant.attackModifier;
    return method;
}

rpgStrike(attacker, defender, defenseBonus)
{
    local value = new RpgStrike();
    local method = rpgCombatMethod(attacker);
    local context = rpgContext(attacker.profile, method, nil);
    value.reason = attacker.profile.blockedReason(context);
    if (value.reason == nil) value.reason = attacker.available(defender);
    if (value.reason != nil) return value;
    if (attacker.profile.energy < attacker.energyCost)
    { value.reason = 'insufficient-energy'; return value; }
    local score = rpgCalculate(context).effectiveScore;
    if (score == nil) { value.reason = 'training-required'; return value; }
    if (score < 3) { value.reason = 'too-difficult'; return value; }
    value.status = 'resolved'; value.dice = rpgRandom.dice();
    value.attack = rpgCheck(score, rpgDiceTotal(value.dice));
    attacker.profile.energy -= attacker.energyCost;
    rpgBody(attacker.profile).endAction();
    value.outcome = 'miss';
    if (!value.attack.achieved) return value;
    local body = rpgBody(defender.profile);
    if (value.attack.critical != 'success' && !body.unconscious && !body.dead)
    {
        local defense = defender.defenseScore() + defenseBonus - (body.stunned ? 4 : 0);
        value.defenseDice = rpgRandom.dice();
        value.defense = rpgCheck(defense, rpgDiceTotal(value.defenseDice));
        if (value.defense.achieved) { value.outcome = 'defended'; return value; }
    }
    local damage = attacker.damageBonus;
    for (local i = 0; i < attacker.damageDice; i += 1)
    {
        local die = rpgRandom.die(); value.damageDice = value.damageDice + [die]; damage += die;
    }
    value.damage = damage < 0 ? 0 : damage;
    local injury = rpgWound(defender.profile, value.damage, defender.armor,
        attacker.woundNumerator, attacker.woundDenominator);
    value.injury = injury.injury; value.outcome = 'hit'; return value;
}

/** Commit attack, defend, recover, escape or surrender. Only a resolved
 * exchange spends time or advances the bounded encounter. Queries do neither. */
rpgConflictStep(conflict, maneuver)
{
    if (conflict == nil || !conflict.ofKind(RpgConflict)
        || !holds(['attack', 'defend', 'recover', 'escape', 'surrender'], maneuver)) throw new RpgError();
    local value = new RpgConflictResult(); value.conflict = conflict; value.maneuver = maneuver;
    if (conflict.finished) { value.status = 'complete'; value.outcome = conflict.outcome; return value; }
    if (!conflict.active) { value.reason = 'rpg.no-conflict'; return value; }
    value.reason = conflict.available();
    if (value.reason != nil) return value;
    local hero = conflict.protagonist; local enemy = conflict.opposition;
    local ownBody = rpgBody(hero.profile); local enemyBody = rpgBody(enemy.profile);
    value.status = 'resolved';
    if (ownBody.unconscious || ownBody.dead) { rpgFinishConflict(value, 'defeated'); return value; }
    if (enemyBody.unconscious || enemyBody.dead) { rpgFinishConflict(value, 'won'); return value; }
    if (maneuver == 'surrender') { rpgFinishConflict(value, 'surrendered'); return value; }
    if (maneuver == 'recover')
    {
        if (ownBody.stunned)
        {
            value.recovery = rpgCheck(hero.profile.attributeScore(rpgHT), rpgRandom.roll());
            if (value.recovery.achieved) ownBody.stunned = nil;
        }
        ownBody.endAction();
    }
    else
    {
        local method = rpgCombatMethod(hero);
        if (maneuver == 'defend') method.requiresExertion = nil;
        value.reason = hero.profile.blockedReason(rpgContext(hero.profile, method, nil));
        if (value.reason != nil) { value.status = 'blocked'; return value; }
        if (maneuver == 'attack')
        {
            value.strike = rpgStrike(hero, enemy, 0);
            if (value.strike.status != 'resolved')
            { value.status = 'blocked'; value.reason = value.strike.reason; return value; }
        }
        else if (maneuver == 'escape')
        {
            local escapeMethod = new RpgApproach(); escapeMethod.attribute = rpgDX;
            local ownScore = rpgCalculate(rpgContext(hero.profile, escapeMethod, nil)).effectiveScore;
            local otherScore = rpgCalculate(rpgContext(enemy.profile, escapeMethod, nil)).effectiveScore;
            if (ownScore < 3 || otherScore < 3)
            { value.status = 'blocked'; value.reason = 'too-difficult'; return value; }
            local one = rpgRandom.roll(); local two = rpgRandom.roll();
            value.escape = rpgEvaluate(ownScore, one, otherScore, two, 0);
            ownBody.endAction();
            if (value.escape.achieved) rpgFinishConflict(value, 'escaped');
        }
        else ownBody.endAction();
    }
    conflict.exchanges += 1; rpgSpendTime(conflict.secondsPerExchange);
    if (!conflict.finished && (enemyBody.unconscious || enemyBody.dead)) rpgFinishConflict(value, 'won');
    if (!conflict.finished)
    {
        if (enemyBody.stunned)
        {
            local recovery = rpgCheck(enemy.profile.attributeScore(rpgHT), rpgRandom.roll());
            enemyBody.endAction();
            if (recovery.achieved) enemyBody.stunned = nil;
        }
        else value.reply = rpgStrike(enemy, hero, maneuver == 'defend' ? 2 : 0);
        if (ownBody.unconscious || ownBody.dead) rpgFinishConflict(value, 'defeated');
        else if (conflict.exchanges >= conflict.maxExchanges) rpgFinishConflict(value, 'stalemate');
    }
    if (value.outcome == nil) value.outcome = 'continuing';
    return value;
}

/** Explicit conflict report. Roll details are omitted unless authored opt-in
 * permits them. No NPC health, defense rating or hidden calculation is inferred. */
rpgPublishConflict(value)
{
    local c = value.conflict;
    event('rpg.conflict'); eventValue(1); eventValue(c.id); eventValue(value.status);
    eventValue(value.reason); eventValue(value.maneuver); eventValue(value.outcome);
    eventValue(c.exchanges); eventValue(c.active);
    if (c.discloseRolls)
        foreach (local strike in [value.strike, value.reply])
        {
            if (strike == nil || strike.attack == nil) continue;
            event('rpg.strike'); eventValue(1); eventValue(c.id);
            eventValue(strike == value.strike ? 'acting' : 'reply'); eventValue(strike.outcome);
            eventValue(strike.attack.score); eventValue(strike.attack.roll);
            eventValue(strike.defense == nil ? nil : strike.defense.roll);
            eventValue(strike.damage); eventValue(strike.injury);
            eventValue(strike.dice.length()); eventValue(strike.defenseDice.length());
            eventValue(strike.damageDice.length());
            foreach (local die in strike.dice) eventValue(die);
            foreach (local die in strike.defenseDice) eventValue(die);
            foreach (local die in strike.damageDice) eventValue(die);
        }
    return nil;
}

rpgConflictValidation: InitObject
    execute()
    {
        for (local s = firstObj(RpgDisposition); s != nil; s = nextObj(s, RpgDisposition))
        {
            if (s.profile == nil || !s.profile.ofKind(RpgProfile)) throw new RpgError();
            rpgInteger(s.attitude, -3, 3);
        }
        for (local a = firstObj(RpgSocialApproach); a != nil; a = nextObj(a, RpgSocialApproach))
        {
            if (a.disposition == nil || !a.disposition.ofKind(RpgDisposition)) throw new RpgError();
            rpgInteger(a.successShift, 0, 3); rpgInteger(a.failureShift, -3, 0);
        }
        for (local fighter = firstObj(RpgCombatant); fighter != nil; fighter = nextObj(fighter, RpgCombatant))
        {
            rpgBody(fighter.profile); rpgValidateAttribute(fighter.attribute);
            if (fighter.skill != nil && !fighter.skill.ofKind(RpgSkill)) throw new RpgError();
            rpgInteger(fighter.attackModifier, -500, 500);
            if (fighter.defense != nil) rpgInteger(fighter.defense, 3, 100);
            rpgInteger(fighter.armor, 0, 10000); rpgInteger(fighter.damageDice, 0, 10);
            rpgInteger(fighter.damageBonus, -100, 100);
            rpgInteger(fighter.energyCost, 0, 1000);
            rpgInteger(fighter.woundNumerator, 1, 10); rpgInteger(fighter.woundDenominator, 1, 10);
        }
        local ids = [];
        for (local c = firstObj(RpgConflict); c != nil; c = nextObj(c, RpgConflict))
        {
            if (dataType(c.id) != TypeSString || c.id == '' || holds(ids, c.id)
                || c.protagonist == nil || !c.protagonist.ofKind(RpgCombatant)
                || c.opposition == nil || !c.opposition.ofKind(RpgCombatant)
                || c.protagonist.profile == c.opposition.profile) throw new RpgError();
            ids = ids + [c.id]; rpgInteger(c.maxExchanges, 1, 100);
            rpgInteger(c.secondsPerExchange, 1, 86400);
        }
        return nil;
    }
;
