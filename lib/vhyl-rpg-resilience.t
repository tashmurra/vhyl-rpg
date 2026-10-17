/* Optional injury, effort and recovery for authored adventures.
 * Include after vhyl-rpg.t. Copyright (c) 2026 John Cunningham. MIT License. */

modify RpgProfile
    resilience = nil
    blockedReason(c)
    {
        local reason = inherited(c);
        if (reason != nil || self.resilience == nil) return reason;
        local body = self.resilience;
        if (body.dead) return 'rpg.dead';
        if (body.unconscious) return 'rpg.unconscious';
        if (body.stunned) return 'rpg.stunned';
        if (c.approach.requiresExertion && self.maxEnergy > 0 && self.energy == 0)
            return 'rpg.exhausted';
        return nil;
    }
    modifiersFor(c)
    {
        local values = inherited(c);
        if (self.resilience == nil) return values;
        local attribute = c.skill != nil ? c.skill.attribute
            : c.isOpposition ? c.approach.oppositionAttribute : c.approach.attribute;
        if ((attribute == rpgDX || attribute == rpgIQ) && self.resilience.shock > 0)
            values = values + ['condition', 'rpg.modifier.shock', -self.resilience.shock];
        if (attribute == rpgST && self.maxEnergy > 0 && self.energy * 3 < self.maxEnergy)
            values = values + ['condition', 'rpg.modifier.exhaustion',
                (self.attributeScore(rpgST) + 1) / 2 - self.attributeScore(rpgST)];
        return values;
    }
    afterAttempt(c, result)
    {
        inherited(c, result);
        if (self.resilience != nil) self.resilience.endAction();
        return nil;
    }
;

modify RpgApproach
    requiresExertion = true
;

/** Authored persistent body, bound one-to-one to a profile. Injury is a deficit
 * from current capacity. Defeat at zero HP is deterministic; lethal outcomes
 * require an explicit author opt-in. No parser-turn death or healing timers. */
class RpgBody: object
    profile = nil
    injury = 0
    shock = 0
    stunned = nil
    unconscious = nil
    dead = nil
    lethal = nil
    aidRemaining = 0
    restSeconds = 0
    healingSeconds = 0
    wakingSeconds = 0
    hp() { return self.profile.maxHP - self.injury; }
    mobilityDivisor()
    {
        return self.hp() * 3 < self.profile.maxHP
            || self.profile.maxEnergy > 0 && self.profile.energy * 3 < self.profile.maxEnergy ? 2 : 1;
    }
    condition()
    {
        if (self.dead) return 'dead';
        if (self.unconscious) return 'unconscious';
        if (self.stunned) return 'stunned';
        if (self.hp() * 3 < self.profile.maxHP) return 'badly-hurt';
        if (self.profile.maxEnergy > 0 && self.profile.energy * 3 < self.profile.maxEnergy)
            return 'exhausted';
        return self.injury > 0 ? 'wounded' : 'well';
    }
    endAction()
    {
        self.shock = 0; self.restSeconds = 0; self.healingSeconds = 0;
        self.wakingSeconds = 0;
        return nil;
    }
;

/** Temporary injury/recovery result. Trusted code chooses whether to publish it. */
class RpgCareResult: object
    status = 'blocked'
    reason = nil
    injury = 0
    healed = 0
    energyRestored = 0
    seconds = 0
    check = nil
;

/** Original bounded care procedure: includes bandaging, then one skill check.
 * One charge and the declared duration buy one attempt. Healing is capped by
 * untreated injury; new minor wounds cannot reopen old treatment budgets. */
class RpgTreatment: object
    skill = nil
    modifier = 0
    seconds = 660
    charges = 1
    healingBonus = 0
    available(healer, patient) { return nil; }
;

rpgBody(profile)
{
    if (profile == nil || !profile.ofKind(RpgProfile) || profile.resilience == nil
        || !profile.resilience.ofKind(RpgBody) || profile.resilience.profile != profile)
        throw new RpgError();
    return profile.resilience;
}

/** Pure armor and wounding arithmetic. Positive penetration always wounds at
 * least one HP. Ratios are explicit authored numbers, not weapon taxonomies. */
rpgInjuryFor(damage, armor, numerator, denominator)
{
    rpgInteger(damage, 0, 10000); rpgInteger(armor, 0, 10000);
    rpgInteger(numerator, 1, 10); rpgInteger(denominator, 1, 10);
    local penetration = damage - armor;
    if (penetration <= 0) return 0;
    local injury = penetration * numerator / denominator;
    return injury < 1 ? 1 : injury;
}

/** Commit injury after armor. Major wounds make one health check; zero HP
 * incapacitates. A lethal body dies at minus five times its maximum HP. */
rpgWound(profile, damage, armor, numerator, denominator)
{
    local body = rpgBody(profile);
    local amount = rpgInjuryFor(damage, armor, numerator, denominator);
    local value = new RpgCareResult();
    if (body.dead) { value.reason = 'rpg.dead'; return value; }
    value.status = 'resolved';
    if (amount == 0) return value;
    local capacity = profile.maxHP;
    local room = capacity * 6 - body.injury;
    if (amount > room) amount = room;
    if (amount == 0) return value;
    body.injury += amount; body.aidRemaining += amount;
    local shock = body.shock + amount;
    body.endAction();
    body.shock = shock > 4 ? 4 : shock;
    value.injury = amount;
    if (amount * 2 > capacity && !body.unconscious)
    {
        local health = profile.attributeScore(rpgHT); local roll = rpgRandom.roll();
        value.check = rpgCheck(health, roll);
        if (!value.check.achieved)
        {
            body.stunned = true;
            if (health - roll <= -5 || value.check.critical == 'failure')
                body.unconscious = true;
        }
    }
    if (body.hp() <= 0) body.unconscious = true;
    if (body.lethal && body.hp() <= -5 * capacity) body.dead = true;
    return value;
}

/** Treat only untreated injury. Ordinary failure still supplies one HP of
 * bandaging; critical failure adds two HP instead. Never grants a free retry. */
rpgTreat(healer, patient, treatment)
{
    local body = rpgBody(patient);
    if (healer == nil || !healer.ofKind(RpgProfile)
        || treatment == nil || !treatment.ofKind(RpgTreatment)) throw new RpgError();
    local value = new RpgCareResult();
    if (body.dead) { value.reason = 'rpg.dead'; return value; }
    if (healer.resilience != nil && (healer.resilience.dead || healer.resilience.unconscious
        || healer.resilience.stunned)) { value.reason = 'rpg.unable-to-treat'; return value; }
    if (body.injury == 0) { value.status = 'complete'; return value; }
    if (body.aidRemaining == 0) { value.reason = 'rpg.already-treated'; return value; }
    value.reason = treatment.available(healer, patient);
    if (value.reason != nil) return value;
    if (treatment.charges <= 0) { value.reason = 'rpg.no-medical-supplies'; return value; }
    local method = new RpgApproach(); method.skill = treatment.skill;
    method.modifier = treatment.modifier; method.requiresExertion = nil;
    local score = rpgCalculate(rpgContext(healer, method, nil)).effectiveScore;
    if (score == nil) { value.reason = 'training-required'; return value; }
    if (score < 3) { value.reason = 'too-difficult'; return value; }
    value.status = 'resolved'; value.seconds = treatment.seconds;
    value.check = rpgCheck(score, rpgRandom.roll());
    treatment.charges -= 1; rpgSpendTime(treatment.seconds);
    if (healer.resilience != nil) healer.resilience.endAction();
    if (value.check.critical == 'failure')
    {
        local injury = rpgWound(patient, 2, 0, 1, 1);
        value.injury = injury.injury;
    }
    else
    {
        local amount = 1;
        if (value.check.achieved)
            amount = value.check.critical == 'success' ? 6 : rpgRandom.die();
        amount += value.check.achieved ? treatment.healingBonus : 0;
        if (amount < 1) amount = 1;
        if (amount > body.aidRemaining) amount = body.aidRemaining;
        if (amount > body.injury) amount = body.injury;
        body.injury -= amount; value.healed = amount;
        if (body.hp() > 0 && (patient.maxEnergy == 0 || patient.energy > 0)) body.unconscious = nil;
    }
    body.aidRemaining = 0;
    return value;
}

/** Explicit uninterrupted quiet rest, charged in seconds. One energy per ten
 * minutes; one health check per full day of rest for one HP. No WAIT hook. */
rpgRest(profile, seconds)
{
    local body = rpgBody(profile); rpgInteger(seconds, 1, 86400);
    local value = new RpgCareResult();
    if (body.dead) { value.reason = 'rpg.dead'; return value; }
    value.status = 'resolved'; value.seconds = seconds; rpgSpendTime(seconds);
    body.shock = 0;
    local needed = profile.maxEnergy - profile.energy;
    local effortTime = body.restSeconds + seconds;
    local restored = effortTime / 600;
    if (restored > needed) restored = needed;
    profile.energy += restored; value.energyRestored = restored;
    body.restSeconds = profile.energy < profile.maxEnergy ? effortTime % 600 : 0;
    if (body.injury > 0)
    {
        body.healingSeconds += seconds;
        if (body.healingSeconds >= 86400)
        {
            body.healingSeconds -= 86400;
            value.check = rpgCheck(profile.attributeScore(rpgHT), rpgRandom.roll());
            if (value.check.achieved)
            {
                body.injury -= 1; value.healed = 1;
                if (body.aidRemaining > body.injury) body.aidRemaining = body.injury;
            }
        }
    }
    else body.healingSeconds = 0;
    if (body.hp() > 0 && (profile.maxEnergy == 0 || profile.energy > 0))
    {
        body.wakingSeconds += seconds;
        if (body.wakingSeconds >= 900)
        { body.wakingSeconds = 900; body.unconscious = nil; body.stunned = nil; }
    }
    return value;
}

/** One committed recovery maneuver. A failed health check leaves stun in place. */
rpgRecoverStun(profile)
{
    local body = rpgBody(profile); local value = new RpgCareResult();
    if (body.dead || body.unconscious) { value.reason = 'rpg.unconscious'; return value; }
    if (!body.stunned) { value.status = 'complete'; return value; }
    value.status = 'resolved'; value.seconds = 1; rpgSpendTime(1);
    value.check = rpgCheck(profile.attributeScore(rpgHT), rpgRandom.roll());
    body.endAction();
    if (value.check.achieved) body.stunned = nil;
    return value;
}

/** Explicit player-visible condition summary. Calling this is a disclosure
 * decision; hidden NPC bodies must not be published automatically. */
rpgPublishBody(profile)
{
    local body = rpgBody(profile);
    event('rpg.body'); eventValue(1); eventValue(profile.actor);
    eventValue(body.condition()); eventValue(body.hp()); eventValue(profile.maxHP);
    eventValue(profile.energy); eventValue(profile.maxEnergy); eventValue(body.mobilityDivisor());
    return nil;
}

rpgResilienceValidation: InitObject
    execute()
    {
        for (local body = firstObj(RpgBody); body != nil; body = nextObj(body, RpgBody))
        {
            if (rpgBody(body.profile) != body) throw new RpgError();
            rpgInteger(body.injury, 0, body.profile.maxHP * 6);
            rpgInteger(body.aidRemaining, 0, body.injury);
            rpgInteger(body.shock, 0, 4);
            rpgInteger(body.restSeconds, 0, 599); rpgInteger(body.healingSeconds, 0, 86399);
            rpgInteger(body.wakingSeconds, 0, 900);
            if (body.hp() <= 0 || body.dead) body.unconscious = true;
            if (body.lethal && body.hp() <= -5 * body.profile.maxHP) body.dead = true;
        }
        for (local p = firstObj(RpgProfile); p != nil; p = nextObj(p, RpgProfile))
            if (p.resilience != nil) rpgBody(p);
        for (local care = firstObj(RpgTreatment); care != nil; care = nextObj(care, RpgTreatment))
        {
            if (care.skill == nil || !care.skill.ofKind(RpgSkill)) throw new RpgError();
            rpgInteger(care.modifier, -500, 500); rpgInteger(care.seconds, 60, 86400);
            rpgInteger(care.charges, 0, 10000); rpgInteger(care.healingBonus, -5, 10);
        }
        return nil;
    }
;
