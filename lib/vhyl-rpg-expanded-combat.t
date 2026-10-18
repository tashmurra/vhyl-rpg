/* Include after expanded foundation. Sources: full-2008, B373-B375, B381-B382, B407, B556-B557.
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

/** Authored attack and weapon facts used by the B556-B557 weapon-miss table. */
class RpgExpandedWeaponMissContext: object
    kind = 'swing'
    damageType = 'cr'
    breakResistant = nil
    cheap = nil
;

/** Pending dice are explicit; no table, damage or displacement dice are drawn here. */
class RpgExpandedWeaponMissResult: RpgExpandedResult
    outcome = nil
    rollsUsed = 0
    selfDamageDivisor = 1
    defenseModifier = 0
    readyActions = 0
    disabilitySeconds = 0
    forbidsFurtherActions = nil
    randomLimb = nil
    randomDisplacement = nil
;

rpgExpandedWeaponBreakResult(roll, cheap)
{
    return holds([3,4,17,18],roll) || cheap && holds([9,10,11],roll);
}

/** Assess supplied critical-miss table rolls, including conditional confirmations. */
rpgExpandedWeaponMiss(context, rolls)
{
    if (context == nil || !context.ofKind(RpgExpandedWeaponMissContext)) rpgExpandedReject('weapon-miss-context');
    if (!holds(['swing','thrust','ranged','parry'],context.kind)) rpgExpandedReject('weapon-miss-kind');
    if (!holds(['cr','cut','imp','pi-','pi','pi+','pi++','burn','cor','tox','fat'],context.damageType))
        rpgExpandedReject('weapon-miss-damage-type');
    if (rolls.length() < 1 || rolls.length() > 3) rpgExpandedReject('weapon-miss-roll-count');
    foreach (local roll in rolls) rpgInteger(roll,3,18);
    local value = new RpgExpandedWeaponMissResult(); value.rollsUsed = 1;
    local selected = rolls[1];
    local confirmSelf = context.kind == 'ranged' || context.kind != 'parry'
        && holds(['imp','pi-','pi','pi+','pi++'],context.damageType);
    if (holds([5,6],selected) && confirmSelf)
    {
        if (rolls.length() == value.rollsUsed)
        { value.status = 'needs-roll'; value.reason = 'self-hit-confirmation'; return value; }
        value.rollsUsed += 1; selected = rolls[value.rollsUsed];
    }
    if (rpgExpandedWeaponBreakResult(selected,context.cheap))
    {
        if (context.breakResistant)
        {
            if (rolls.length() == value.rollsUsed)
            { value.status = 'needs-roll'; value.reason = 'breakage-confirmation'; return value; }
            value.rollsUsed += 1;
            value.outcome = rpgExpandedWeaponBreakResult(rolls[value.rollsUsed],context.cheap) ? 'break-weapon' : 'drop-weapon';
        }
        else value.outcome = 'break-weapon';
    }
    else if (selected == 5 || selected == 6)
    { value.outcome = 'self-hit'; value.randomLimb = true; value.selfDamageDivisor = selected == 6 ? 2 : 1; }
    else if (selected == 7 || selected == 13 || selected == 16 && context.kind == 'ranged')
    { value.outcome = 'off-balance'; value.defenseModifier = -2; value.forbidsFurtherActions = true; }
    else if (selected == 8 || selected == 12)
    { value.outcome = 'weapon-unready'; value.readyActions = 1; }
    else if (holds([9,10,11],selected)) value.outcome = 'drop-weapon';
    else if (selected == 14)
    {
        value.outcome = context.kind == 'swing' ? 'flung-weapon' : 'drop-weapon';
        value.randomDisplacement = context.kind == 'swing';
    }
    else if (selected == 15)
    { value.outcome = 'strained-weapon-arm'; value.disabilitySeconds = 1800; }
    else if (selected == 16) value.outcome = 'fall';
    if (rolls.length() != value.rollsUsed) rpgExpandedReject('weapon-miss-unused-rolls');
    value.status = 'ready'; return value;
}

class RpgExpandedUnarmedMissContext: object
    kind = 'attack'
    limbUsed = true
    naturalWeapon = nil
    kicking = nil
    normalMishapPenalty = nil
    health = 10
    intelligence = 10
    animal = nil
    canFlee = true
    foeReadyImpaling = nil
    highPainThreshold = nil
    mobility = 'ground'
;

class RpgExpandedUnarmedMissResult: RpgExpandedResult
    outcome = nil
    injury = 0
    injuryDice = 0
    injuryAdds = 0
    injuryLocation = nil
    recoveryIntervalSeconds = 0
    disabilitySeconds = 0
    painSeconds = 0
    damageMode = nil
    damageDivisor = 1
    naturalDamageModifier = 0
    attackModifier = 0
    defenseModifier = 0
    affectedActionModifier = 0
    guardExposureMultiplier = 1
    forbidsFurtherActions = nil
    movePastYards = 0
    turnAway = nil
    dexterityModifier = 0
;

/** Select the unarmed table's replacement for falling in the current movement mode. */
rpgExpandedUnarmedFall(mobility)
{
    if (!holds(['ground','cannot-fall','flying','swimming'],mobility)) rpgExpandedReject('unarmed-miss-mobility');
    local value = new RpgExpandedUnarmedMissResult(); value.status = 'ready';
    if (mobility == 'ground') value.outcome = 'fall';
    else if (mobility == 'cannot-fall')
    { value.outcome = 'general-injury'; value.injuryDice = 1; value.injuryAdds = -3; value.injuryLocation = 'general'; }
    else
    { value.outcome = 'awkward-position'; value.attackModifier = -4; value.defenseModifier = -3; }
    return value;
}

/** Supplied-roll unarmed critical miss; owns no injury, tactical state or recovery yet. */
rpgExpandedUnarmedMiss(context, roll)
{
    if (context == nil || !context.ofKind(RpgExpandedUnarmedMissContext)) rpgExpandedReject('unarmed-miss-context');
    if (!holds(['attack','parry'],context.kind)) rpgExpandedReject('unarmed-miss-kind');
    rpgInteger(roll,3,18); rpgInteger(context.health,1,1000); rpgInteger(context.intelligence,0,1000);
    if (context.normalMishapPenalty != nil) rpgInteger(context.normalMishapPenalty,-1000,0);
    if (!holds(['ground','cannot-fall','flying','swimming'],context.mobility)) rpgExpandedReject('unarmed-miss-mobility');
    local value = new RpgExpandedUnarmedMissResult();
    if (roll == 3 || roll == 18)
    { value.outcome = 'unconscious'; value.recoveryIntervalSeconds = 1800; }
    else if (roll == 17 && context.animal && context.intelligence >= 3 && context.intelligence <= 5)
        value.outcome = context.canFlee ? 'flee-next-turn' : 'submit-next-turn';
    else if (roll == 4 || roll == 17)
    {
        if (context.limbUsed)
        { value.outcome = 'strained-limb'; value.injury = 1; value.injuryLocation = 'used-limb'; value.disabilitySeconds = 1800; }
        else
        {
            value.outcome = 'moderate-pain'; local minutes = 20 - context.health;
            value.painSeconds = (minutes < 1 ? 1 : minutes) * 60;
        }
    }
    else if (roll == 6 && context.kind == 'attack' && context.naturalWeapon)
    { value.outcome = 'broken-natural-weapon'; value.naturalDamageModifier = -1; }
    else if (roll == 5 || roll == 6 || roll == 16)
    {
        value.outcome = 'self-damage'; value.damageDivisor = roll == 6 ? 2 : 1;
        value.damageMode = context.kind == 'attack' && context.foeReadyImpaling
            ? 'opponent-weapon-own-strength' : 'own-thrust-crushing';
        value.injuryLocation = 'used-body-part';
    }
    else if (roll == 7 || roll == 14)
    {
        if (context.kind == 'parry') return rpgExpandedUnarmedFall(context.mobility);
        value.outcome = 'stumble-past'; value.movePastYards = 1; value.turnAway = true;
    }
    else if (roll == 8) return rpgExpandedUnarmedFall(context.mobility);
    else if (holds([9,10,11],roll))
    { value.outcome = 'off-balance'; value.defenseModifier = -2; value.forbidsFurtherActions = true; }
    else if (roll == 12)
    {
        value.outcome = 'trip-check';
        value.dexterityModifier = context.normalMishapPenalty != nil ? context.normalMishapPenalty * 2
            : context.kicking ? -4 : 0;
    }
    else if (roll == 13)
    { value.outcome = 'open-guard'; value.defenseModifier = -2; value.guardExposureMultiplier = 2; }
    else if (roll == 15)
    {
        value.outcome = 'torn-muscle'; value.injuryDice = 1; value.injuryAdds = -3;
        value.injuryLocation = context.limbUsed ? 'used-limb' : 'neck';
        value.attackModifier = -1; value.defenseModifier = -1;
        value.affectedActionModifier = context.highPainThreshold ? -1 : -3;
    }
    value.status = 'ready'; return value;
}

/** Supplied one-die injury for unarmed falls/tears; negative totals do not heal. */
rpgExpandedUnarmedMissInjury(die)
{
    rpgInteger(die,1,6); return die > 3 ? die - 3 : 0;
}

class RpgExpandedCriticalDropResult: RpgExpandedResult
    plans = []
    selectedPlan = nil
    items = []
    selectionRoll = nil
;

modify RpgExpandedProfile
    criticalDrops = []
;

/** Owned B556 forced drop, independent of whether the triggering attack penetrated. */
class RpgExpandedCriticalDrop: object
    id = nil
    profile = nil
    trigger = 'general-12'
    evidence = nil
    destination = nil
    result = nil
    boundId = nil
    boundProfile = nil
    boundTrigger = nil
    boundEvidence = nil
    boundDestination = nil
    assess()
    {
        if (self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)) rpgExpandedReject('critical-drop-profile');
        local value = new RpgExpandedCriticalDropResult();
        if (self.result != nil)
        {
            if (self.id != self.boundId || self.profile != self.boundProfile || self.trigger != self.boundTrigger
                || self.evidence != self.boundEvidence || self.destination != self.boundDestination
                || !holds(self.profile.criticalDrops,self)) rpgExpandedReject('critical-drop-binding');
            value.status = 'reused'; value.items = self.result.items;
            value.selectedPlan = self.result.selectedPlan; value.selectionRoll = self.result.selectionRoll; return value;
        }
        if (self.id == nil || self.id == '' || !holds(['general-12','head-14'],self.trigger))
            rpgExpandedReject('critical-drop-declaration');
        if (self.evidence == nil || self.evidence == '') { value.reason = 'critical-drop-evidence'; return value; }
        foreach (local prior in self.profile.criticalDrops)
            if (prior.id == self.id) rpgExpandedReject('critical-drop-duplicate');
        rpgExpandedValidate(self.profile);
        local held = [];
        foreach (local item in self.profile.equipment)
            if (item.ready && !item.worn)
            {
                if (holds(held,item)) rpgExpandedReject('critical-drop-duplicate-item');
                held = held + [item];
            }
        if (self.trigger == 'general-12')
        {
            local plan = self.profile.prepareKnockdownDrop(self.destination);
            if (plan != nil)
            {
                if (plan.status != 'ready') { value.reason = plan.reason; return value; }
                value.plans = [plan];
            }
        }
        else
        {
            local weapons = [];
            foreach (local item in held)
                if (item.ofKind(RpgLiteWeapon)) weapons = weapons + [item];
            if (weapons.length() > 2) { value.reason = 'critical-drop-many-weapons-unavailable'; return value; }
            foreach (local weapon in weapons)
            {
                local plan = self.profile.prepareForcedDrop([weapon],self.destination);
                if (plan == nil || plan.status != 'ready')
                { value.reason = plan == nil ? 'critical-drop-plan-unavailable' : plan.reason; return value; }
                value.plans = value.plans + [plan];
            }
        }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        if (value.plans.length() > 0)
        {
            local index = 1;
            if (value.plans.length() == 2)
            { value.selectionRoll = rpgRandom.die(); index = value.selectionRoll <= 3 ? 1 : 2; }
            value.selectedPlan = value.plans[index]; value.selectedPlan.commit(); value.items = value.selectedPlan.items;
        }
        self.boundId = self.id; self.boundProfile = self.profile; self.boundTrigger = self.trigger;
        self.boundEvidence = self.evidence; self.boundDestination = self.destination;
        self.profile.criticalDrops = self.profile.criticalDrops + [self];
        value.status = 'resolved'; self.result = value; return value;
    }
;

modify RpgExpandedProfile
    validateFeatures()
    {
        inherited(); local ids = [];
        foreach (local drop in self.criticalDrops)
        {
            if (drop == nil || !drop.ofKind(RpgExpandedCriticalDrop) || drop.profile != self
                || drop.result == nil || holds(ids,drop.id) || drop.assess().status != 'reused'
                || drop.result.selectedPlan != nil && !drop.result.selectedPlan.committed)
                rpgExpandedReject('critical-drop-history');
            ids = ids + [drop.id];
        }
        return nil;
    }
;

modify RpgExpandedProfile
    criticalReadiness = []
;

/** Owned weapon-table readiness consequence; the ordinary Ready action restores use. */
class RpgExpandedCriticalReadiness: object
    id = nil
    profile = nil
    weapon = nil
    tableRoll = 8
    evidence = nil
    result = nil
    boundId = nil
    boundProfile = nil
    boundWeapon = nil
    boundRoll = nil
    boundEvidence = nil
    assess()
    {
        if (self.profile == nil || !self.profile.ofKind(RpgExpandedProfile))
            rpgExpandedReject('critical-readiness-profile');
        local value = new RpgExpandedResult();
        if (self.result != nil)
        {
            if (self.id != self.boundId || self.profile != self.boundProfile
                || self.weapon != self.boundWeapon || self.tableRoll != self.boundRoll
                || self.evidence != self.boundEvidence || !holds(self.profile.criticalReadiness,self))
                rpgExpandedReject('critical-readiness-binding');
            value.status = 'reused'; return value;
        }
        if (self.id == nil || self.id == '' || !holds([8,12],self.tableRoll))
            rpgExpandedReject('critical-readiness-declaration');
        if (self.weapon == nil || !self.weapon.ofKind(RpgLiteWeapon)
            || !holds(self.profile.equipment,self.weapon)) rpgExpandedReject('critical-readiness-weapon');
        if (self.evidence == nil || self.evidence == '')
        { value.reason = 'critical-readiness-evidence'; return value; }
        foreach (local prior in self.profile.criticalReadiness)
            if (prior.id == self.id) rpgExpandedReject('critical-readiness-duplicate');
        rpgExpandedValidate(self.profile);
        if (!self.weapon.ready || !self.weapon.usableBy(self.profile))
        { value.reason = 'critical-readiness-not-held'; return value; }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.weapon.ready = nil;
        for (local fighter = firstObj(RpgLiteFighter); fighter != nil; fighter = nextObj(fighter,RpgLiteFighter))
            if (fighter.profile == self.profile && fighter.aimWeapon == self.weapon)
            { fighter.aimSeconds = 0; fighter.aimTarget = nil; fighter.aimWeapon = nil; }
        self.boundId = self.id; self.boundProfile = self.profile; self.boundWeapon = self.weapon;
        self.boundRoll = self.tableRoll; self.boundEvidence = self.evidence;
        self.profile.criticalReadiness = self.profile.criticalReadiness + [self];
        value.status = 'resolved'; self.result = value; return value;
    }
;

modify RpgExpandedProfile
    validateFeatures()
    {
        inherited(); local ids = [];
        foreach (local receipt in self.criticalReadiness)
        {
            if (receipt == nil || !receipt.ofKind(RpgExpandedCriticalReadiness) || receipt.profile != self
                || receipt.result == nil || holds(ids,receipt.id) || receipt.assess().status != 'reused')
                rpgExpandedReject('critical-readiness-history');
            ids = ids + [receipt.id];
        }
        return nil;
    }
;

class RpgExpandedDefenseFailureResult: RpgExpandedResult
    shield = nil
;

modify RpgExpandedProfile
    criticalDefenseFailures = []
;

/** Commit a supplied critical Dodge/Block failure without a second defense roll. */
class RpgExpandedDefenseFailure: object
    id = nil
    fighter = nil
    kind = 'dodge'
    score = 10
    roll = 18
    mobility = 'ground'
    evidence = nil
    result = nil
    boundId = nil
    boundFighter = nil
    boundProfile = nil
    boundKind = nil
    boundScore = nil
    boundRoll = nil
    boundMobility = nil
    boundEvidence = nil
    assess()
    {
        if (self.fighter == nil || !self.fighter.ofKind(RpgLiteFighter)
            || self.fighter.profile == nil || !self.fighter.profile.ofKind(RpgExpandedProfile))
            rpgExpandedReject('critical-defense-fighter');
        local profile = self.fighter.profile; local value = new RpgExpandedDefenseFailureResult();
        if (self.result != nil)
        {
            if (self.id != self.boundId || self.fighter != self.boundFighter || profile != self.boundProfile
                || self.kind != self.boundKind || self.score != self.boundScore || self.roll != self.boundRoll
                || self.mobility != self.boundMobility || self.evidence != self.boundEvidence
                || !holds(profile.criticalDefenseFailures,self)) rpgExpandedReject('critical-defense-binding');
            value.status = 'reused'; value.shield = self.result.shield; value.check = self.result.check; return value;
        }
        if (self.id == nil || self.id == '' || !holds(['dodge','block'],self.kind))
            rpgExpandedReject('critical-defense-declaration');
        if (self.evidence == nil || self.evidence == '')
        { value.reason = 'critical-defense-evidence'; return value; }
        foreach (local prior in profile.criticalDefenseFailures)
            if (prior.id == self.id) rpgExpandedReject('critical-defense-duplicate');
        rpgExpandedValidate(profile);
        value.check = rpgExpandedCombatCheck('defense',self.score,self.roll);
        if (value.check.rollSucceeded || !value.check.critical)
        { value.reason = 'critical-defense-not-critical'; return value; }
        if (self.kind == 'dodge')
        {
            if (self.mobility != 'ground')
            { value.reason = 'critical-dodge-mobility-unavailable'; return value; }
        }
        else
        {
            value.shield = self.fighter.shield;
            if (value.shield == nil || !value.shield.ofKind(RpgLiteItem)
                || !holds(profile.equipment,value.shield) || !value.shield.ready
                || !value.shield.blockUsableBy(profile))
            { value.reason = 'critical-block-shield-unavailable'; return value; }
        }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local profile = self.fighter.profile;
        if (self.kind == 'dodge') profile.posture = 'lying';
        else value.shield.ready = nil;
        self.boundId = self.id; self.boundFighter = self.fighter; self.boundProfile = profile;
        self.boundKind = self.kind; self.boundScore = self.score; self.boundRoll = self.roll;
        self.boundMobility = self.mobility; self.boundEvidence = self.evidence;
        profile.criticalDefenseFailures = profile.criticalDefenseFailures + [self];
        value.status = 'resolved'; self.result = value; return value;
    }
;

modify RpgExpandedProfile
    validateFeatures()
    {
        inherited(); local ids = [];
        foreach (local receipt in self.criticalDefenseFailures)
        {
            if (receipt == nil || !receipt.ofKind(RpgExpandedDefenseFailure) || receipt.boundProfile != self
                || receipt.result == nil || holds(ids,receipt.id) || receipt.assess().status != 'reused')
                rpgExpandedReject('critical-defense-history');
            ids = ids + [receipt.id];
        }
        return nil;
    }
;

/** One ordinary Ready turn to recover the shield grip lost by a recorded critical Block. */
class RpgExpandedShieldReadyManeuver: RpgLiteManeuver
    kind = 'ready'
    failure = nil
    healthAdapter = nil
    healthAvailable(fighter)
    {
        if (self.healthAdapter == self) rpgExpandedReject('shield-ready-health-cycle');
        if (self.healthAdapter != nil)
        {
            if (!self.healthAdapter.ofKind(RpgLiteManeuver) || !self.healthAdapter.expandedHealthPermission
                || self.healthAdapter.kind != 'ready')
                rpgExpandedReject('shield-ready-health-adapter');
            return self.healthAdapter.healthAvailable(fighter);
        }
        if (fighter.profile.fp() <= 0 || fighter.profile.hp() <= 0)
            return 'shield-ready-health-adapter-required';
        return nil;
    }
    canAct(fighter)
    {
        if (self.healthAdapter != nil) return self.healthAdapter.canAct(fighter);
        return inherited(fighter);
    }
    available(fighter)
    {
        if (self.kind != 'ready' || self.option != nil) return 'shield-ready-maneuver';
        return self.readyAvailable(fighter);
    }
    readyAvailable(fighter)
    {
        if (self.failure == nil || !self.failure.ofKind(RpgExpandedDefenseFailure)
            || self.failure.result == nil || self.failure.kind != 'block'
            || self.failure.fighter != fighter) return 'shield-ready-failure-required';
        self.failure.assess();
        local shield = self.failure.result.shield;
        if (shield == nil || fighter.shield != shield || !holds(fighter.profile.equipment,shield)
            || !shield.blockUsableBy(fighter.profile)) return 'shield-ready-unavailable';
        if (shield.ready) return 'shield-already-ready';
        return nil;
    }
    performReady(fighter)
    {
        local reason = self.readyAvailable(fighter);
        if (reason != nil) rpgExpandedReject(reason);
        self.failure.result.shield.ready = true; return nil;
    }
;

class RpgExpandedWeaponMissDropResult: RpgExpandedResult
    assessment = nil
    plan = nil
;

modify RpgExpandedProfile
    weaponMissDrops = []
;

/** Drop the actual attacking/parrying weapon after a supplied critical-miss resolution. */
class RpgExpandedWeaponMissDrop: object
    id = nil
    profile = nil
    weapon = nil
    context = nil
    rolls = []
    evidence = nil
    destination = nil
    result = nil
    boundId = nil
    boundProfile = nil
    boundWeapon = nil
    boundContext = nil
    boundKind = nil
    boundDamageType = nil
    boundBreakResistant = nil
    boundCheap = nil
    boundRolls = []
    boundEvidence = nil
    boundDestination = nil
    assess()
    {
        if (self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)
            || self.context == nil || !self.context.ofKind(RpgExpandedWeaponMissContext))
            rpgExpandedReject('weapon-miss-drop-owner');
        local value = new RpgExpandedWeaponMissDropResult();
        if (self.result != nil)
        {
            if (self.id != self.boundId || self.profile != self.boundProfile || self.weapon != self.boundWeapon
                || self.context != self.boundContext || self.context.kind != self.boundKind
                || self.context.damageType != self.boundDamageType
                || self.context.breakResistant != self.boundBreakResistant || self.context.cheap != self.boundCheap
                || self.evidence != self.boundEvidence || self.destination != self.boundDestination
                || self.rolls.length() != self.boundRolls.length() || !holds(self.profile.weaponMissDrops,self))
                rpgExpandedReject('weapon-miss-drop-binding');
            for (local i = 1; i <= self.rolls.length(); i += 1)
                if (self.rolls[i] != self.boundRolls[i]) rpgExpandedReject('weapon-miss-drop-binding');
            value.status = 'reused'; value.assessment = self.result.assessment; value.plan = self.result.plan; return value;
        }
        if (self.id == nil || self.id == '' || self.weapon == nil || !self.weapon.ofKind(RpgLiteWeapon)
            || !holds(self.profile.equipment,self.weapon)) rpgExpandedReject('weapon-miss-drop-declaration');
        if (self.evidence == nil || self.evidence == '')
        { value.reason = 'weapon-miss-drop-evidence'; return value; }
        foreach (local prior in self.profile.weaponMissDrops)
            if (prior.id == self.id) rpgExpandedReject('weapon-miss-drop-duplicate');
        rpgExpandedValidate(self.profile);
        value.assessment = rpgExpandedWeaponMiss(self.context,self.rolls);
        if (value.assessment.status != 'ready')
        { value.status = value.assessment.status; value.reason = value.assessment.reason; return value; }
        if (value.assessment.outcome != 'drop-weapon')
        { value.reason = 'weapon-miss-not-drop'; return value; }
        if (!self.weapon.ready || self.weapon.worn || !self.weapon.usableBy(self.profile))
        { value.reason = 'weapon-miss-drop-not-held'; return value; }
        value.plan = self.profile.prepareForcedDrop([self.weapon],self.destination);
        if (value.plan == nil || value.plan.status != 'ready')
        { value.reason = value.plan == nil ? 'weapon-miss-drop-plan-unavailable' : value.plan.reason; return value; }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        value.plan.commit();
        self.boundId = self.id; self.boundProfile = self.profile; self.boundWeapon = self.weapon;
        self.boundContext = self.context; self.boundKind = self.context.kind; self.boundDamageType = self.context.damageType;
        self.boundBreakResistant = self.context.breakResistant; self.boundCheap = self.context.cheap;
        self.boundRolls = []; foreach (local roll in self.rolls) self.boundRolls = self.boundRolls + [roll];
        self.boundEvidence = self.evidence; self.boundDestination = self.destination;
        self.profile.weaponMissDrops = self.profile.weaponMissDrops + [self];
        value.status = 'resolved'; self.result = value; return value;
    }
;

modify RpgExpandedProfile
    validateFeatures()
    {
        inherited(); local ids = [];
        foreach (local receipt in self.weaponMissDrops)
        {
            if (receipt == nil || !receipt.ofKind(RpgExpandedWeaponMissDrop) || receipt.profile != self
                || receipt.result == nil || holds(ids,receipt.id) || receipt.assess().status != 'reused'
                || receipt.result.plan == nil || !receipt.result.plan.committed)
                rpgExpandedReject('weapon-miss-drop-history');
            ids = ids + [receipt.id];
        }
        return nil;
    }
;
