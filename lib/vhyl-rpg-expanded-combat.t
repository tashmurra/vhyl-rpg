/* Include after expanded foundation. Sources: full-2008, B373-B375, B381-B382, B407, B556.
 * Partial rapid-fire assessments; no automatic attack or injury dispatch. */

/** Ordinary one-target burst assessment and supplied-roll Dodge result. */
class RpgExpandedRapidFireResult: RpgExpandedResult
    shots = 0
    hits = 0
    avoided = 0
    remaining = 0
;

/** Attack bonus from actual shots fired, including the printed doubling extension. */
rpgExpandedRapidFireBonus(shots)
{
    rpgInteger(shots,1,1000000);
    if (shots <= 4) return 0;
    if (shots <= 8) return 1;
    if (shots <= 12) return 2;
    if (shots <= 16) return 3;
    if (shots <= 24) return 4;
    if (shots <= 49) return 5;
    local boundary = 100; local bonus = 6;
    while (shots >= boundary) { bonus += 1; boundary *= 2; }
    return bonus;
}

/** Declare one ordinary burst before an attack roll; this never spends ammunition. */
rpgExpandedAssessBurst(shots, rate, loaded, recoil)
{
    rpgInteger(shots,1,1000000); rpgInteger(rate,1,1000000);
    rpgInteger(loaded,0,1000000); rpgInteger(recoil,1,1000);
    local value = new RpgExpandedRapidFireResult();
    if (shots > rate) { value.reason = 'burst-rate-exceeded'; return value; }
    if (shots > loaded) { value.reason = 'burst-ammunition-insufficient'; return value; }
    value.shots = shots; value.modifier = rpgExpandedRapidFireBonus(shots);
    value.status = 'ready'; return value;
}

/** Potential hits after a successful attack, before defense; not for failed attacks. */
rpgExpandedRapidFireHits(shots, recoil, successMargin)
{
    rpgInteger(shots,1,1000000); rpgInteger(recoil,1,1000);
    rpgInteger(successMargin,-1,1000000);
    /* Automatic success at score three on a four still supplies the first hit. */
    local margin = successMargin < 0 ? 0 : successMargin;
    local hits = 1 + margin / recoil;
    return hits > shots ? shots : hits;
}

/** Assess one already-eligible Dodge using supplied dice, without drawing randomness. */
rpgExpandedRapidFireDodge(hits, score, roll)
{
    rpgInteger(hits,1,1000000); rpgInteger(score,-1000,1000); rpgInteger(roll,3,18);
    local value = new RpgExpandedRapidFireResult(); value.hits = hits;
    value.check = rpgExpandedCombatCheck('defense',score,roll);
    if (value.check.achieved)
    {
        value.avoided = value.check.critical == 'success' ? hits : 1 + value.check.margin;
        if (value.avoided > hits) value.avoided = hits;
    }
    value.remaining = hits - value.avoided; value.status = 'ready'; return value;
}

/** Supplied-dice combat check with ranged-miss and low-defense exceptions. */
rpgExpandedCombatCheck(kind, score, roll)
{
    if (!holds(['melee','ranged','defense'],kind)) rpgExpandedReject('combat-check-kind');
    rpgInteger(score,-1000,1000); rpgInteger(roll,3,18);
    if (kind != 'defense' && score < 3) return rpgCheck(score,roll);
    local value = rpgCheck(score < 3 ? 3 : score,roll);
    value.score = score; value.margin = score - roll;
    value.achieved = roll <= 4 || roll < 17 && roll <= score;
    value.rollSucceeded = value.achieved; value.critical = nil;
    if (value.achieved)
    {
        if (roll <= 4 || roll == 5 && score >= 15 || roll == 6 && score >= 16)
            value.critical = 'success';
    }
    else if (roll == 18 || roll == 17 && score <= 15 || kind != 'ranged' && roll - score >= 10)
        value.critical = 'failure';
    value.outcome = value.achieved ? 'success' : value.critical == 'failure' ? 'complication' : 'setback';
    return value;
}

class RpgExpandedRangedResult: RpgExpandedResult
    outcome = nil
    malfunction = nil
    defenseAllowed = nil
    criticalTable = nil
;

/** Classify an ordinary ranged attack before any optional critical-table roll.
 * A nil malfunction threshold disables that optional procedure. */
rpgExpandedRangedOutcome(score, roll, malfunctionThreshold)
{
    if (malfunctionThreshold != nil) rpgInteger(malfunctionThreshold,3,19);
    local value = new RpgExpandedRangedResult(); value.check = rpgExpandedCombatCheck('ranged',score,roll);
    if (value.check.status != 'resolved') { value.reason = value.check.reason; return value; }
    value.status = 'ready';
    if (malfunctionThreshold != nil && roll >= malfunctionThreshold)
    { value.malfunction = true; value.outcome = 'malfunction'; return value; }
    value.outcome = value.check.achieved ? 'potential-hit' : 'miss';
    if (value.check.critical == 'success') value.criticalTable = 'hit';
    else if (value.check.critical == 'failure') value.criticalTable = 'miss';
    else if (value.check.achieved) value.defenseAllowed = true;
    return value;
}

/** Critical-hit effects awaiting the appropriate damage, injury and equipment commits. */
class RpgExpandedCriticalHitResult: RpgExpandedResult
    location = nil
    basicDamageMultiplier = 1
    maximumDamage = nil
    ignoreArmor = nil
    halveArmor = nil
    roundArmorUp = nil
    majorWoundOnPenetration = nil
    doubleShockOnPenetration = nil
    temporaryCrippleOnPenetration = nil
    dropHeld = nil
    dropWeapon = nil
    forcedDoNothing = nil
    deafenOnPenetration = nil
    appearanceLossOnPenetration = 0
;

/** Assess B556 general/head critical hits with an authored eye-accessibility fact. */
rpgExpandedCriticalHit(roll, location, damageType, eyePossible)
{
    rpgInteger(roll,3,18);
    if (!holds(['torso','vitals','groin','neck','arm','hand','leg','foot','face','skull','eye'],location))
        rpgExpandedReject('critical-hit-location');
    if (!holds(['cr','cut','imp','pi-','pi','pi+','pi++','burn','cor','tox','fat'],damageType))
        rpgExpandedReject('critical-hit-damage-type');
    if (location == 'eye' && !eyePossible) rpgExpandedReject('critical-hit-eye-unavailable');
    local value = new RpgExpandedCriticalHitResult(); value.location = location;
    local head = holds(['face','skull','eye'],location);
    if (!head)
    {
        if (roll == 3 || roll == 18) value.basicDamageMultiplier = 3;
        else if (roll == 4 || roll == 17) value.halveArmor = true;
        else if (roll == 5 || roll == 16) value.basicDamageMultiplier = 2;
        else if (roll == 6 || roll == 15) value.maximumDamage = true;
        else if (roll == 7 || roll == 13 || roll == 14) value.majorWoundOnPenetration = true;
        else if (roll == 8)
        {
            value.doubleShockOnPenetration = true;
            value.temporaryCrippleOnPenetration = holds(['arm','hand','leg','foot'],location);
        }
        else if (roll == 12) value.dropHeld = true;
    }
    else
    {
        if (roll == 3) { value.maximumDamage = true; value.ignoreArmor = true; }
        else if (roll == 4 || roll == 5 || (roll == 6 || roll == 7) && !eyePossible)
        { value.halveArmor = true; value.roundArmorUp = true; value.majorWoundOnPenetration = true; }
        else if (roll == 6 || roll == 7) value.location = 'eye';
        else if (roll == 8) value.forcedDoNothing = true;
        else if (roll == 12 || roll == 13)
        {
            if (damageType == 'cr') value.deafenOnPenetration = true;
            else value.appearanceLossOnPenetration = holds(['burn','cor'],damageType) ? 2 : 1;
        }
        else if (roll == 14) value.dropWeapon = true;
        else if (roll == 15) value.maximumDamage = true;
        else if (roll == 16) value.basicDamageMultiplier = 2;
        else if (roll == 17) { value.halveArmor = true; value.roundArmorUp = true; }
        else if (roll == 18) value.basicDamageMultiplier = 3;
    }
    value.status = 'ready'; return value;
}

/** Apply a critical effect to DR that has already received ordinary armor divisors. */
rpgExpandedCriticalArmor(effect, dividedArmor)
{
    if (effect == nil || !effect.ofKind(RpgExpandedCriticalHitResult)) rpgExpandedReject('critical-hit-effect');
    rpgInteger(dividedArmor,0,1000000);
    if (effect.ignoreArmor) return 0;
    if (effect.halveArmor) return (dividedArmor + (effect.roundArmorUp ? 1 : 0)) / 2;
    return dividedArmor;
}

/** Temporary limb/extremity duration when critical injury did not already cripple it. */
rpgExpandedCriticalCrippleSeconds(health)
{
    rpgInteger(health,1,1000); local seconds = 16 - health; return seconds < 2 ? 2 : seconds;
}

/** Critical damage multiplication occurs before protection and wound multipliers. */
rpgExpandedCriticalDamage(effect, rolledBasic, maximumBasic)
{
    if (effect == nil || !effect.ofKind(RpgExpandedCriticalHitResult)) rpgExpandedReject('critical-hit-effect');
    rpgInteger(rolledBasic,0,1000000); rpgInteger(maximumBasic,rolledBasic,1000000);
    return (effect.maximumDamage ? maximumBasic : rolledBasic) * effect.basicDamageMultiplier;
}

/** Double normal shock only after penetration, capped at eight for this effect. */
rpgExpandedCriticalShock(effect, normalShock, penetrated)
{
    if (effect == nil || !effect.ofKind(RpgExpandedCriticalHitResult)) rpgExpandedReject('critical-hit-effect');
    rpgInteger(normalShock,0,1000);
    if (!effect.doubleShockOnPenetration || !penetrated) return normalShock;
    local shock = normalShock * 2; return shock > 8 ? 8 : shock;
}
