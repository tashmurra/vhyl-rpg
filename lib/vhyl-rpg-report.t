/* Optional assessments and disclosure-controlled mechanics events.
 * Include after vhyl-rpg.t. Copyright (c) 2026 John Cunningham. MIT License. */

/** An author ceiling or a player's requested level of detail. Every group is
 * opt-in. A player preference can reduce, but never broaden, author permission. */
class RpgDisclosure: object
    visible = nil
    showAbility = nil
    showCalculation = nil
    showChance = nil
    showCosts = nil
    showAvailability = nil
    showOutcome = nil
    showDice = nil
    showOpposition = nil
    /* Authored qualitative estimate when exact odds cannot be disclosed. */
    estimateLabelId = nil
;

/** Opt in explicitly on an approach; never the implicit disclosure default. */
rpgFullDisclosure: RpgDisclosure
    visible = true showAbility = true showCalculation = true showChance = true
    showCosts = true showAvailability = true showOutcome = true
    showDice = true showOpposition = true
;

modify RpgApproach
    assessmentDisclosure = nil
    rollDisclosure = nil
    /* Observational override for knowledge-dependent disclosure. */
    disclosureFor(c, source)
    {
        return source == 'assessment' ? self.assessmentDisclosure : self.rollDisclosure;
    }
;

modify RpgAssessment
    odds = nil
;

/** Exact integer counts. Outcome categories are mutually exclusive. Raw roll
 * success and critical flags overlap those categories, especially in contests. */
class RpgOdds: object
    total = 0
    achieved = 0
    success = 0
    costlySuccess = 0
    setback = 0
    complication = 0
    tie = 0
    rollSuccess = 0
    criticalSuccess = 0
    criticalFailure = 0
    add(result, weight)
    {
        self.total += weight;
        if (result.achieved) self.achieved += weight;
        if (result.outcome == 'success') self.success += weight;
        else if (result.outcome == 'costly-success') self.costlySuccess += weight;
        else if (result.outcome == 'setback') self.setback += weight;
        else if (result.outcome == 'complication') self.complication += weight;
        else if (result.outcome == 'tie') self.tie += weight;
        if (result.rollSucceeded) self.rollSuccess += weight;
        if (result.critical == 'success') self.criticalSuccess += weight;
        if (result.critical == 'failure') self.criticalFailure += weight;
        return nil;
    }
    /* Rounded hundredths of a percent; retain counts for exact arithmetic. */
    chanceBasisPoints() { return (self.achieved * 10000 + self.total / 2) / self.total; }
;

rpgRollWeight(total)
{
    return [1, 3, 6, 10, 15, 21, 25, 27, 27, 25, 21, 15, 10, 6, 3, 1][total - 2];
}

/** Trusted assessment, not a player-safe disclosure. No dice are drawn, no
 * attempts recorded, and no consequences or persistent writes occur. */
rpgAssess(profile, approach)
{
    local value = rpgPrepare(profile, approach);
    value.odds = rpgOddsFor(value);
    return value;
}

/** Enumerate exact weighted outcomes for a trusted prepared assessment.
 * Returns nil unless ready. This helper does not apply disclosure policy. */
rpgOddsFor(value)
{
    if (value.status != 'ready') return nil;
    local odds = new RpgOdds();
    if (value.kind == 'automatic')
    {
        odds.total = 1; odds.achieved = 1; odds.success = 1;
        odds.rollSuccess = nil; odds.criticalSuccess = nil; odds.criticalFailure = nil;
    }
    else
    {
        for (local total = 3; total <= 18; total += 1)
        {
            if (value.oppositionCalculation == nil)
                odds.add(rpgEvaluate(value.calculation.effectiveScore, total, nil, nil,
                    value.costlyMargin), rpgRollWeight(total));
            else
                for (local other = 3; other <= 18; other += 1)
                    odds.add(rpgEvaluate(value.calculation.effectiveScore, total,
                        value.oppositionCalculation.effectiveScore, other, value.costlyMargin),
                        rpgRollWeight(total) * rpgRollWeight(other));
        }
    }
    return odds;
}

/** Trusted retrieval of the latest recorded attempt, including a completed
 * goal. No current skill/prerequisite hooks are evaluated. nil means no record. */
rpgRecordedResult(profile, approach)
{
    local value = new RpgResult(); value.profile = profile; value.approach = approach;
    rpgAttemptFor(profile, approach).recall(value);
    return value.status == 'reused' ? value : nil;
}

rpgDisclosureFor(value, preferences, source)
{
    if (preferences != nil && !preferences.ofKind(RpgDisclosure)) throw new RpgError();
    local policy = value.approach.disclosureFor(rpgContext(value.profile, value.approach, nil), source);
    if (policy == nil) return nil;
    if (!policy.ofKind(RpgDisclosure)) throw new RpgError();
    return policy.visible && (preferences == nil || preferences.visible) ? policy : nil;
}

rpgDisclosed(policy, preferences, flag)
{
    return policy.(flag) && (preferences == nil || preferences.(flag));
}

/* Existence of a contest is itself opposition information. */
rpgDisclosedKind(value, policy, preferences)
{
    if (value.kind == 'contest' && !rpgDisclosed(policy, preferences, &showOpposition)) return nil;
    return value.kind;
}

rpgPublishCalculation(calculation, value, source, side, policy, preferences)
{
    local ability = rpgDisclosed(policy, preferences, &showAbility);
    local numbers = rpgDisclosed(policy, preferences, &showCalculation);
    if (calculation == nil || (!ability && !numbers)) return nil;
    event('rpg.calculation'); eventValue(1); eventValue(source);
    eventValue(value.approach.challenge.id); eventValue(value.approach.id);
    eventValue(value.profile.actor); eventValue(side);
    eventValue(ability ? calculation.abilityLabelId : nil);
    eventValue(ability ? calculation.attributeId : nil);
    eventValue(ability ? calculation.training : nil);
    eventValue(numbers ? calculation.attributeScore : nil);
    eventValue(numbers ? calculation.defaultPenalty : nil);
    eventValue(numbers ? calculation.baseScore : nil);
    eventValue(numbers ? calculation.effectiveScore : nil);
    local modifiers = numbers ? calculation.modifiers : [];
    eventValue(modifiers.length() / 3);
    foreach (local item in modifiers) eventValue(item);
    return nil;
}

/** Emit a redacted assessment and optional calculation events. nil preferences
 * means use the author's ceiling. Hidden checks emit nothing, including IDs. */
rpgPublishAssessment(value, preferences)
{
    local policy = rpgDisclosureFor(value, preferences, 'assessment');
    if (policy == nil) return nil;
    local availability = rpgDisclosed(policy, preferences, &showAvailability);
    local costs = rpgDisclosed(policy, preferences, &showCosts);
    local chance = rpgDisclosed(policy, preferences, &showChance)
        && (value.kind != 'contest' || rpgDisclosed(policy, preferences, &showOpposition));
    local odds = chance ? value.odds : nil;
    local estimate = odds == nil && (preferences == nil || preferences.showChance)
        ? policy.estimateLabelId : nil;
    event('rpg.assessment'); eventValue(1);
    eventValue(value.approach.challenge.id); eventValue(value.approach.id);
    eventValue(value.profile.actor);
    eventValue(availability ? value.status : nil); eventValue(availability ? value.reason : nil);
    eventValue(rpgDisclosedKind(value, policy, preferences));
    eventValue(costs ? value.timeCost : nil); eventValue(costs ? value.energyCost : nil);
    eventValue(estimate);
    eventValue(odds == nil ? nil : odds.total); eventValue(odds == nil ? nil : odds.achieved);
    eventValue(odds == nil ? nil : odds.success); eventValue(odds == nil ? nil : odds.costlySuccess);
    eventValue(odds == nil ? nil : odds.setback); eventValue(odds == nil ? nil : odds.complication);
    eventValue(odds == nil ? nil : odds.tie); eventValue(odds == nil ? nil : odds.rollSuccess);
    eventValue(odds == nil ? nil : odds.criticalSuccess); eventValue(odds == nil ? nil : odds.criticalFailure);
    rpgPublishCalculation(value.calculation, value, 'assessment', 'acting', policy, preferences);
    if (rpgDisclosed(policy, preferences, &showOpposition))
        rpgPublishCalculation(value.oppositionCalculation, value, 'assessment', 'opposition', policy, preferences);
    return nil;
}

/** Report recorded faces and calculation snapshots, never a fresh roll or a
 * recalculation against today's attributes. Automatic attempts have no dice. */
rpgPublishRoll(value, preferences)
{
    if (value.status != 'resolved' && value.status != 'reused') return nil;
    local policy = rpgDisclosureFor(value, preferences, 'roll');
    if (policy == nil) return nil;
    local dice = rpgDisclosed(policy, preferences, &showDice);
    local opposition = rpgDisclosed(policy, preferences, &showOpposition);
    local numbers = rpgDisclosed(policy, preferences, &showCalculation);
    local outcome = rpgDisclosed(policy, preferences, &showOutcome);
    local costs = rpgDisclosed(policy, preferences, &showCosts);
    local ownDice = dice ? value.dice : [];
    local otherDice = dice && opposition ? value.oppositionDice : [];
    event('rpg.roll'); eventValue(1);
    eventValue(value.approach.challenge.id); eventValue(value.approach.id);
    eventValue(value.profile.actor);
    eventValue(rpgDisclosed(policy, preferences, &showAvailability) ? value.status : nil);
    eventValue(rpgDisclosedKind(value, policy, preferences));
    eventValue(outcome ? value.outcome : nil); eventValue(outcome ? value.achieved : nil);
    eventValue(costs ? value.recordedTimeSpent : nil); eventValue(costs ? value.recordedEnergySpent : nil);
    eventValue(dice ? value.roll : nil); eventValue(dice && numbers ? value.margin : nil);
    eventValue(dice && outcome ? value.critical : nil);
    eventValue(dice && opposition ? value.oppositionRoll : nil);
    eventValue(dice && opposition && numbers ? value.oppositionMargin : nil);
    eventValue(dice && opposition && outcome ? value.oppositionCritical : nil);
    eventValue(dice ? ownDice.length() : nil);
    eventValue(dice && opposition ? otherDice.length() : nil);
    foreach (local face in ownDice) eventValue(face);
    foreach (local face in otherDice) eventValue(face);
    rpgPublishCalculation(value.calculation, value, 'roll', 'acting', policy, preferences);
    if (opposition)
        rpgPublishCalculation(value.oppositionCalculation, value, 'roll', 'opposition', policy, preferences);
    return nil;
}
