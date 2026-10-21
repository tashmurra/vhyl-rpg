/** Persistent encounter participant, ready weapons, shield, defenses and aim/concentration. */
class RpgLiteFighter: object
    profile = nil
    weapon = nil
    modeIndex = 1
    offWeapon = nil
    offModeIndex = 1
    shield = nil
    shieldSkill = nil
    unarmedSkill = nil
    turnSerial = 0
    maneuver = 'nothing'
    defenseOption = 'dodge'
    blocks = 0
    parries = 0
    offParries = 0
    attacked = nil
    participated = nil
    aimSeconds = 0
    aimTarget = nil
    aimWeapon = nil
    concentration = 0
    initiativeTie = 0
    freeHands = 2
    unarmedParryCapacity() { return self.freeHands; }
    unarmedParryRequirement(otherHand) { return otherHand && self.weapon == nil ? 2 : 1; }
    mode() { return self.weapon.modes[self.modeIndex]; }
;

/** Authored tactical facts, availability and consequence hooks for one combat turn. */
class RpgLiteManeuver: object
    kind = 'nothing'
    option = nil
    target = nil
    distance = 1
    speed = 0
    sizeModifier = 0
    rangeModifier = nil
    movement = 0
    posture = nil
    offHand = nil
    hands = 2
    braced = nil
    boots = nil
    aware = true
    fromBehind = nil
    shieldSide = true
    visible = true
    immobilized = nil
    inReach = true
    targetThreatens = true
    humanTarget = true
    deadly = nil
    faceVisible = true
    preflight = nil
    attackModifier = 0
    defenseModifier = 0
    darkness = 0
    someLight = true
    defense = 'dodge'
    secondDefense = 'parry'
    available(fighter) { return self.kind == 'wait' ? 'wait-adapter-required' : nil; }
    /* Optional health adapters assess before any permission roll. */
    expandedHealthPermission = nil
    healthAvailable(fighter) { return nil; }
    canAct(fighter) { return rpgLiteCanAct(fighter.profile, self.kind == 'nothing'); }
    /* Optional Ready adapters preserve the default weapon/reload behavior. */
    readyAvailable(fighter)
    {
        if (fighter.weapon == nil) return 'no-weapon';
        if (self.option == 'reload'
            && rpgLiteReloadSeconds(fighter.profile, fighter.weapon, fighter.mode()) == nil)
            return 'cannot-reload';
        return nil;
    }
    performReady(fighter)
    {
        if (self.option == 'reload') return rpgLiteReload(fighter.profile, fighter.weapon, fighter.mode());
        fighter.weapon.ready = true; return nil;
    }
    resolveStrike(attacker, defender) { return rpgLiteDefaultStrike(attacker,defender,self); }
    apply(fighter, result) { return nil; }
    reroll(profile, kind, roll) { return nil; }
;

/** Attack, defense, damage and injury receipt; blocked results include a reason. */
class RpgLiteCombatResult: object
    status = 'blocked'
    reason = nil
    attack = nil
    defenses = []
    successfulDefense = nil
    attackMode = nil
    damage = 0
    injury = 0
    strikes = []
    outcome = nil
    counterInjury = 0
;

/** Look up the printed Lite range table through 100 yards; no missing full rules reference rows are inferred. */
rpgLiteRangeModifier(yards)
{
    rpgInteger(yards, 0, 100);
    local table = [[2,0],[3,-1],[5,-2],[10,-4],[15,-5],[20,-6],[30,-7],[50,-8],[70,-9],[100,-10]];
    foreach (local row in table) if (yards <= row[1]) return row[2];
    throw new RpgError();
}

/** Return the melee attack or defense adjustment for a named posture. */
rpgLitePostureModifier(posture, defense)
{
    if (posture == 'standing') return 0;
    if (posture == 'crouching') return defense ? 0 : -2;
    if (posture == 'sitting' || posture == 'kneeling') return -2;
    if (posture == 'lying' || posture == 'crawling') return defense ? -3 : -4;
    throw new RpgError();
}

/** Roll an active defense, preserving automatic success on 3 or 4 even below score 3. */
rpgLiteDefenseCheck(score)
{
    rpgInteger(score, -1000, 1000);
    local roll = rpgRandom.roll();
    local value = rpgCheck(score < 3 ? 3 : score, roll);
    value.score = score; value.margin = score - roll;
    value.achieved = roll <= 4 || roll < 17 && roll <= score;
    value.outcome = value.achieved ? 'success' : 'setback'; return value;
}

/** Find the skill identity used by the fighter's selected attack mode. */
rpgLiteCombatSkill(fighter, mode)
{
    local profile = fighter.profile;
    local techLevel = mode.skillId == 'guns' || mode.skillId == 'gunner' ? fighter.weapon.techLevel : nil;
    return rpgLiteTraining(profile, mode.skillId, techLevel, mode.specialty);
}

/** Return the highest applicable DX, Brawling or Karate rating. */
rpgLiteUnarmedScore(fighter)
{
    local score = fighter.profile.dx;
    foreach (local id in ['brawling', 'karate'])
    {
        local skill = rpgLiteTraining(fighter.profile, id, nil, nil);
        local value = fighter.profile.skillScore(skill);
        if (value != nil && value > score) score = value;
    }
    return score;
}

/** Query defense eligibility and score without rolling or consuming a defense. */
rpgLiteDefenseScore(fighter, attacker, request, kind)
{
    local profile = fighter.profile; local incoming = attacker.mode();
    if (!request.aware || request.fromBehind || request.immobilized || profile.dead || profile.unconscious
        || fighter.maneuver == 'all-out-attack' || profile.healthBlocksDefense()) return nil;
    local score = 0;
    if (kind == 'dodge')
    {
        score = profile.basicSpeedQuarters() / 4 + 3 - profile.encumbrance();
        if (score < 1) score = 1;
        score += profile.level('enhanced-dodge');
        if (profile.hp() * 3 < profile.maxHP) score = (score + 1) / 2;
        if (profile.fp() * 3 < profile.maxEnergy) score = (score + 1) / 2;
    }
    else if (kind == 'block')
    {
        if (fighter.blocks > 0 || fighter.shield == nil || !fighter.shield.ready || !fighter.shield.blockUsableBy(profile)
            || incoming.ranged && incoming.base == 'fixed') return nil;
        local skill = fighter.shieldSkill == nil ? rpgLiteTraining(profile, 'shield', nil, nil) : fighter.shieldSkill;
        local rating = profile.skillScore(skill);
        if (rating == nil) return nil;
        score = 3 + rating / 2 + profile.level('enhanced-block');
        if (incoming.skillId == 'flail') score -= 2;
    }
    else if (kind == 'parry' || kind == 'parry-other')
    {
        local otherHand = kind == 'parry-other';
        local parryWeapon = otherHand ? fighter.offWeapon : fighter.weapon;
        local parryMode = parryWeapon == nil ? nil : parryWeapon.modes[otherHand ? fighter.offModeIndex : fighter.modeIndex];
        if ((otherHand ? fighter.offParries : fighter.parries) > 0 || fighter.maneuver == 'move-attack'
            || incoming.ranged && !incoming.thrown && !request.inReach) return nil;
        local unarmed = parryWeapon == nil || parryWeapon.id == 'punch' || parryWeapon.id == 'kick';
        if (unarmed)
        {
            if (fighter.unarmedParryCapacity() < fighter.unarmedParryRequirement(otherHand)) return nil;
            score = 3 + (rpgLiteUnarmedScore(fighter) + profile.legUsePenalty()) / 2;
            local karate = profile.skillScore(rpgLiteTraining(profile, 'karate', nil, nil));
            if (attacker.weapon.id != 'punch' && attacker.weapon.id != 'kick'
                && incoming.base != 'thrust' && karate == nil) score -= 3;
            if (karate != nil && karate >= rpgLiteUnarmedScore(fighter)) score -= profile.encumbrance();
        }
        else
        {
            if (!parryWeapon.ready || !parryWeapon.parryUsableBy(profile) || parryMode.ranged
                || parryMode.skillId == 'axe-mace' && fighter.attacked) return nil;
            local rating = profile.skillScore(rpgLiteTraining(profile, parryMode.skillId, nil, parryMode.specialty));
            if (rating == nil) return nil;
            if (otherHand && profile.level('ambidexterity') == 0) rating -= 4;
            rating += profile.legUsePenalty();
            score = 3 + rating / 2;
            if (parryWeapon.id == 'quarterstaff') score += 2;
            if (parryMode.skillId == 'knife') score -= 1;
        }
        score += profile.level('enhanced-parry-all');
        local enhanced = profile.trait('enhanced-parry');
        if (enhanced != nil && enhanced.scope == (unarmed ? 'unarmed' : parryMode.skillId)) score += 1;
        if (incoming.thrown) score -= attacker.weapon.weight <= 100 ? 2 : 1;
        if (incoming.skillId == 'flail') score -= 4;
    }
    else throw new RpgError();
    score += profile.level('combat-reflexes') + request.defenseModifier;
    if (fighter.shield != nil && fighter.shield.ready && request.shieldSide) score += fighter.shield.passiveDefenseBonus(profile);
    score += rpgLitePostureModifier(profile.posture, true);
    local conditionPenalty = profile.healthDefensePenalty();
    if (profile.combatStunned() && conditionPenalty < 4) conditionPenalty = 4;
    score -= conditionPenalty;
    if (fighter.maneuver == 'all-out-defense' && (fighter.defenseOption == kind
        || kind == 'parry-other' && fighter.defenseOption == 'parry')) score += 2;
    if (!request.visible) score -= 4;
    return score;
}

/** Lose aim and check whether ongoing concentration survives distraction. */
rpgLiteDistract(fighter)
{
    fighter.aimSeconds = 0;
    if (fighter.concentration > 0 && !rpgLiteAttributeCheck(fighter.profile, rpgWill, 'concentration', -3).achieved)
        fighter.concentration = 0;
    return nil;
}

/** Resolve one legal strike; normally invoked by the battle turn scheduler. */
rpgLiteStrike(attacker, defender, request)
{
    return request.resolveStrike(attacker,defender);
}
rpgLiteDefaultStrike(attacker, defender, request)
{
    local weapon = attacker.weapon;
    local result = rpgLiteResolveStrike(attacker,defender,request);
    if (weapon != nil && result.status == 'resolved') weapon.afterStrike(attacker,result.attackMode,result);
    if (result.status == 'resolved') defender.profile.recordDirectPhysicalAttack(attacker,defender,result);
    return result;
}
rpgLiteResolveStrike(attacker, defender, request)
{
    local result = new RpgLiteCombatResult();
    local profile = attacker.profile; local weapon = attacker.weapon;
    if (weapon == nil || !weapon.ready || !weapon.attackUsableBy(profile)) { result.reason = 'weapon-not-ready'; return result; }
    profile.validateCombatVision(); defender.profile.validateCombatVision();
    local mode = attacker.mode(); result.attackMode = mode; weapon.validateStrike(attacker,mode);
    local hands = weapon.attackHandCount(profile,request.hands);
    if (profile.combatStunned() || profile.unconscious || profile.dead)
    { result.reason = 'unable-to-attack'; return result; }
    if (!mode.ranged && !request.inReach) { result.reason = 'out-of-reach'; return result; }
    if (request.deadly && !request.targetThreatens && profile.level('cannot-harm-innocents') > 0)
    { result.reason = 'cannot-harm-innocents'; return result; }
    local handlingStrength = profile.handlingStrength();
    if (mode.hands == 2 && hands < 2 && (mode.requiresTwoHands || handlingStrength * 2 < mode.minimumST * 3)
        || hands == 2 && attacker.shield != nil && attacker.shield.ready && attacker.shield.usableBy(profile))
    { result.reason = 'hands-unavailable'; return result; }
    local strength = profile.weaponStrength(weapon);
    local maximum = mode.rangeScale == 10 ? mode.maximumRange * strength / 10 : mode.maximumRange;
    local half = mode.rangeScale == 10 ? mode.halfRange * strength / 10 : mode.halfRange;
    if (mode.ranged && request.distance > maximum) { result.reason = 'out-of-range'; return result; }
    if (mode.ranged && !mode.thrown && weapon.ammunition < 1) { result.reason = 'empty'; return result; }
    local context = new RpgLiteContext(); context.kind = 'attack';
    context.legUse = mode.ranged ? 'none' : 'required';
    context.skill = rpgLiteCombatSkill(attacker, mode); context.offHand = request.offHand;
    context.darkness = request.darkness; context.someLight = request.someLight;
    context.modifier = request.attackModifier;
    local unarmed = holds(['punch','kick','brass-knuckles'], weapon.id);
    if (unarmed || weapon.id == 'blackjack')
    {
        context.skill = nil; context.attribute = rpgDX;
        local rating = weapon.id == 'blackjack' ? profile.skillScore(rpgLiteTraining(profile, 'brawling', nil, nil)) : rpgLiteUnarmedScore(attacker);
        context.modifier += rating == nil || rating < profile.dx ? 0 : rating - profile.dx;
    }
    if (weapon.id == 'kick') context.modifier -= 2;
    local effectiveST = profile.fp() * 3 < profile.maxEnergy ? (handlingStrength + 1) / 2 : handlingStrength;
    local minimumST = weapon.bipod && profile.posture == 'lying' ? (mode.minimumST * 2 + 2) / 3 : mode.minimumST;
    if (effectiveST < minimumST) context.modifier -= minimumST - effectiveST;
    if (mode.ranged)
    {
        context.modifier += request.sizeModifier + (request.rangeModifier == nil
            ? rpgLiteRangeModifier(request.distance + request.speed) : request.rangeModifier);
        if (defender.profile.posture != 'standing') context.modifier -= 2;
        if (attacker.aimSeconds > 0 && attacker.aimTarget == defender && attacker.aimWeapon == weapon
            && request.kind != 'move-attack')
        {
            context.modifier += mode.acc + (attacker.aimSeconds >= 3 ? 2 : attacker.aimSeconds == 2 ? 1 : 0);
            context.modifier += attacker.aimSeconds < weapon.scopeBonus ? attacker.aimSeconds : weapon.scopeBonus;
            if ((request.braced || weapon.bipod && profile.posture == 'lying' || mode.hands == 1 && hands == 2)
                && (mode.base == 'fixed' || weapon.id == 'crossbow')) context.modifier += 1;
        }
    }
    else
    {
        context.modifier += rpgLitePostureModifier(profile.posture, nil);
        if (attacker.shield != nil && attacker.shield.ready && attacker.shield.usableBy(profile) && attacker.shield.db == 3) context.modifier -= 2;
    }
    if (request.kind == 'all-out-attack' && (request.option == 'determined' || mode.ranged)) context.modifier += mode.ranged ? 1 : 4;
    if (request.kind == 'move-attack') context.modifier -= 4;
    if (profile.level('reluctant-killer') > 0 && request.deadly && request.humanTarget)
        context.modifier -= request.faceVisible ? 4 : 2;
    local score = rpgLiteScore(profile, context);
    if (score == nil) { result.reason = 'training-required'; return result; }
    if (request.kind == 'move-attack' && !mode.ranged && score > 9) score = 9;
    if (score < 3) { result.reason = 'too-difficult'; return result; }
    if (request.preflight) { result.status = 'ready'; return result; }
    result.status = 'resolved'; result.attack = rpgCheck(score, rpgRandom.roll());
    if (request.reroll(profile, 'attack', result.attack.roll))
        result.attack = rpgCheck(score, rpgLiteReroll(profile, result.attack.roll, 3, nil));
    else if (request.reroll(defender.profile, 'enemy-attack', result.attack.roll))
        result.attack = rpgCheck(score, rpgLiteReroll(defender.profile, result.attack.roll, 3, true));
    attacker.attacked = true; attacker.participated = true;
    if (mode.ranged && !mode.thrown) weapon.ammunition -= 1;
    if (mode.thrown || mode.unready && handlingStrength * 2 < mode.minimumST * 3
        || mode.hands == 2 && hands == 1 && handlingStrength < mode.minimumST * (mode.unready ? 3 : 2)) weapon.ready = nil;
    attacker.aimSeconds = 0;
    if (!result.attack.achieved)
    {
        result.outcome = 'miss';
        if (weapon.id == 'kick' && !rpgLiteAttributeCheck(profile, rpgDX, 'keep-feet', 0).achieved) profile.posture = 'lying';
        return result;
    }
    if (result.attack.critical != 'success')
    {
        local choices = [request.defense];
        if (defender.maneuver == 'all-out-defense' && defender.defenseOption == 'double'
            && request.secondDefense != request.defense) choices = choices + [request.secondDefense];
        foreach (local kind in choices)
        {
            local defense = rpgLiteDefenseScore(defender, attacker, request, kind);
            if (defense == nil) continue;
            if (!request.visible && kind != 'dodge'
                && !rpgLiteAttributeCheck(defender.profile, rpgPerception, 'hearing', -2).achieved) continue;
            if (defender.maneuver == 'nothing' && defender.profile.hp() <= 0 && !rpgLiteCanAct(defender.profile, nil)) break;
            if (kind == 'block') defender.blocks += 1;
            if (kind == 'parry') defender.parries += 1;
            if (kind == 'parry-other') defender.offParries += 1;
            defender.participated = true; rpgLiteDistract(defender);
            local check = rpgLiteDefenseCheck(defense);
            if (request.reroll(defender.profile, 'defense', check.roll))
            {
                local rolled = rpgLiteReroll(defender.profile, check.roll, 3, nil);
                check = rpgCheck(defense < 3 ? 3 : defense, rolled);
                check.score = defense; check.margin = defense - rolled;
                check.achieved = rolled <= 4 || rolled < 17 && rolled <= defense;
            }
            result.defenses = result.defenses + [check];
            if (check.achieved)
            {
                result.outcome = 'defended'; result.successfulDefense = kind;
                if (kind == 'parry' && unarmed && defender.weapon != nil
                    && !holds(['punch','kick','brass-knuckles'], defender.weapon.id))
                {
                    local counter = new RpgLiteContext(); counter.kind = 'attack';
                    counter.legUse = 'required';
                    counter.skill = rpgLiteCombatSkill(defender, defender.mode());
                    if (profile.skillScore(rpgLiteTraining(profile, 'karate', nil, nil)) != nil) counter.modifier = -4;
                    if (rpgLiteCheck(defender.profile, counter).achieved)
                    {
                        local retaliation = defender.mode();
                        local damage = rpgLiteDamageDice(defender.profile.muscleDamageStrength(), retaliation.base == 'swing');
                        local rolled = rpgLiteRollDamage(damage[1], damage[2] + retaliation.adds, retaliation.damageType, nil);
                        result.counterInjury = rpgLiteWound(profile, rpgLitePenetration(rolled, rpgLiteArmor(profile), 1, retaliation.damageType, nil)).injury;
                    }
                }
                return result;
            }
        }
    }
    local dice = mode.dice; local adds = mode.adds;
    if (mode.base != 'fixed')
    {
        strength = profile.weaponStrength(weapon);
        if (mode.minimumST > 0 && !mode.ranged && strength > mode.minimumST * 3) strength = mode.minimumST * 3;
        local damage = rpgLiteDamageDice(strength, mode.base == 'swing'); dice = damage[1]; adds += damage[2];
        if (unarmed)
        {
            local karate = profile.skillScore(rpgLiteTraining(profile, 'karate', nil, nil));
            if (karate != nil && karate >= profile.dx) adds += dice * (karate > profile.dx ? 2 : 1);
            if (weapon.id == 'kick' && request.boots) adds += 1;
        }
        if (request.kind == 'all-out-attack' && request.option == 'strong' && !mode.ranged) adds += dice > 2 ? dice : 2;
    }
    local rawDamage = 0;
    for (local index = 0; index < dice; index += 1) rawDamage += result.attack.roll == 3 ? 6 : rpgRandom.die();
    if (result.attack.roll != 3 && request.reroll(profile, 'damage', rawDamage))
        rawDamage = rpgLiteReroll(profile, rawDamage, dice, true);
    result.damage = rawDamage + adds;
    if (result.damage < (mode.damageType == 'cr' ? 0 : 1)) result.damage = mode.damageType == 'cr' ? 0 : 1;
    result.injury = rpgLitePenetration(result.damage, rpgLiteArmor(defender.profile), mode.armorDivisor,
        mode.damageType, mode.ranged && half > 0 && request.distance >= half);
    rpgLiteWound(defender.profile, result.injury);
    if (result.injury > 0) rpgLiteDistract(defender);
    result.outcome = 'hit'; return result;
}

/** One-second turn scheduler with stable initiative, maneuvers and end-of-battle fatigue. */
class RpgLiteBattle: object
    fighters = []
    order = []
    index = 1
    seconds = 0
    active = nil
    begin()
    {
        if (self.active || self.order.length() > 0 || self.fighters.length() < 2) throw new RpgError();
        foreach (local fighter in self.fighters)
        {
            if (holds(self.order, fighter)) throw new RpgError();
            fighter.initiativeTie = rpgRandom.roll();
            local updated = []; local inserted = nil;
            foreach (local other in self.order)
            {
                local ownSpeed = fighter.profile.basicSpeedQuarters(); local otherSpeed = other.profile.basicSpeedQuarters();
                if (!inserted && (ownSpeed > otherSpeed || ownSpeed == otherSpeed &&
                    (fighter.profile.dx > other.profile.dx || fighter.profile.dx == other.profile.dx
                    && fighter.initiativeTie > other.initiativeTie)))
                { updated = updated + [fighter]; inserted = true; }
                updated = updated + [other];
            }
            if (!inserted) updated = updated + [fighter];
            self.order = updated;
        }
        self.active = true; return self.order[1];
    }
    current() { return self.active ? self.order[self.index] : nil; }
    step(fighter, request)
    {
        local result = new RpgLiteCombatResult();
        if (fighter != self.current()) { result.reason = 'not-your-turn'; return result; }
        if (!holds(['nothing','move','posture','aim','attack','all-out-attack','move-attack',
            'all-out-defense','concentrate','ready','wait'], request.kind)) throw new RpgError();
        local limit = holds(['move','move-attack','all-out-defense'], request.kind) ? fighter.profile.move()
            : request.kind == 'all-out-attack' ? fighter.profile.move() / 2 : 1;
        if (request.movement < 0 || request.movement > limit
            || request.kind == 'all-out-defense' && request.option != 'dodge' && request.movement > 1)
        { result.reason = 'movement-limit'; return result; }
        result.reason = request.available(fighter); if (result.reason != nil) return result;
        result.reason = fighter.profile.healthManeuverRequestReason(request);
        if (result.reason != nil) return result;
        if (request.target != nil && !holds(self.fighters, request.target)) throw new RpgError();
        if (fighter.profile.combatStunned() && request.kind != 'nothing')
        { result.reason = 'stunned'; return result; }
        if (request.kind == 'posture' && (request.posture == nil
            || fighter.profile.posture == 'lying' && request.posture == 'standing'))
        { result.reason = 'invalid-posture-change'; return result; }
        if (request.kind == 'posture')
        {
            rpgLitePostureModifier(request.posture, nil);
            result.reason = fighter.profile.postureChangeReason(request.posture);
            if (result.reason != nil) return result;
        }
        if (holds(['attack','all-out-attack','move-attack','aim'], request.kind) && request.target == nil)
            throw new RpgError();
        if (request.kind == 'all-out-attack' && !holds(['determined','double','strong'], request.option)
            || request.kind == 'all-out-defense' && !holds(['dodge','block','parry','double'], request.option))
            throw new RpgError();
        if (request.kind == 'aim' && (fighter.weapon == nil || !fighter.weapon.ready || !fighter.mode().ranged || !request.visible))
        { result.reason = 'cannot-aim'; return result; }
        if (request.kind == 'ready')
        {
            result.reason = request.readyAvailable(fighter);
            if (result.reason != nil) return result;
        }
        if (holds(['attack','all-out-attack','move-attack'], request.kind))
        {
            request.preflight = true; result = rpgLiteStrike(fighter, request.target, request); request.preflight = nil;
            if (result.status != 'ready') return result;
        }
        result.reason = request.healthAvailable(fighter);
        if (result.reason != nil) { result.status = 'blocked'; return result; }
        rpgInteger(fighter.turnSerial,0,2147483646); fighter.turnSerial += 1;
        if (!request.canAct(fighter))
        { result.status = 'resolved'; result.outcome = 'incapacitated'; self.advance(); return result; }
        fighter.blocks = 0; fighter.parries = 0; fighter.offParries = 0; fighter.attacked = nil;
        if (request.kind != 'concentrate') fighter.concentration = 0;
        fighter.maneuver = request.kind; fighter.defenseOption = request.option;
        if (holds(['attack','all-out-attack','move-attack'], request.kind))
        {
            result = rpgLiteStrike(fighter, request.target, request);
            if (result.status != 'resolved') return result;
            if (request.kind == 'all-out-attack' && request.option == 'double' && !fighter.mode().ranged
                && (fighter.weapon.ready || fighter.offWeapon != nil && fighter.offWeapon.ready)
                && !fighter.profile.physicalStunned() && !fighter.profile.unconscious && !request.target.profile.dead)
            {
                local primary = fighter.weapon; local modeIndex = fighter.modeIndex; local offHand = request.offHand;
                if (fighter.offWeapon != nil && fighter.offWeapon.ready)
                { fighter.weapon = fighter.offWeapon; fighter.modeIndex = fighter.offModeIndex; request.offHand = true; }
                result.strikes = result.strikes + [rpgLiteStrike(fighter, request.target, request)];
                fighter.weapon = primary; fighter.modeIndex = modeIndex; request.offHand = offHand;
            }
        }
        else
        {
            result.status = 'resolved'; result.outcome = request.kind;
            if (request.kind == 'aim')
            {
                if (fighter.aimTarget != request.target || fighter.aimWeapon != fighter.weapon) fighter.aimSeconds = 0;
                fighter.aimTarget = request.target; fighter.aimWeapon = fighter.weapon; fighter.aimSeconds += 1;
            }
            else fighter.aimSeconds = 0;
            if (request.kind == 'posture') fighter.profile.posture = request.posture;
            if (request.kind == 'concentrate') fighter.concentration += 1;
            if (request.kind == 'ready') request.performReady(fighter);
            if (request.kind == 'nothing' && fighter.profile.fearSeconds == 0 && (fighter.profile.stunned || fighter.profile.mentalStun))
                rpgLiteRecoverStun(fighter.profile);
        }
        fighter.profile.shock = fighter.profile.shockAfterTurn(result.counterInjury);
        request.apply(fighter, result); self.advance(); return result;
    }
    advance()
    {
        self.index += 1;
        if (self.index > self.order.length())
        {
            self.index = 1; self.seconds += 1; self.advanceClock();
            foreach (local fighter in self.order) rpgLiteHealthTime(fighter.profile, 1);
        }
        return nil;
    }
    advanceClock() { return rpgSpendTime(1); }
    finish()
    {
        if (!self.active) return nil;
        self.active = nil;
        if (self.seconds > 10)
            foreach (local fighter in self.fighters)
                if (fighter.participated)
                {
                    local cost = 1 + fighter.profile.encumbrance();
                    if (fighter.weapon != nil && fighter.mode().minimumST > fighter.profile.handlingStrength()) cost += 1;
                    rpgLiteFatigue(fighter.profile, cost, 'battle');
                }
        return true;
    }
;
