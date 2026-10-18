/** Structured injury, healing, fatigue and elapsed-time result with any resistance checks. */
class RpgLiteHealthResult: object
    status = 'resolved'
    knockedDown = nil
    injury = 0
    healed = 0
    fatigue = 0
    check = nil
    checks = []
    seconds = 0
;

/** Apply injury, shock, major wounds, death thresholds and mortal wounds. */
rpgLiteWound(profile, amount)
{
    rpgInteger(amount, 0, 100000);
    return rpgLiteWoundWithKnockdown(profile,amount,amount * 2 > profile.maxHP,0);
}

/** Shared injury commit with an explicitly assessed knockdown trigger/modifier.
 * Ordinary callers use rpgLiteWound; expanded requests preflight their context. */
rpgLiteWoundWithKnockdown(profile, amount, knockdown, modifier)
{
    rpgInteger(amount, 0, 100000); rpgInteger(modifier,-1000,1000);
    local result = new RpgLiteHealthResult();
    if (profile.dead || amount == 0) return result;
    local shock = profile.shockFromInjury(amount);
    local oldHP = profile.hp(); profile.injury += amount; result.injury = amount;
    profile.woundSerial += 1;
    profile.aidUsed = nil;
    if (profile.level('high-pain-threshold') == 0)
    { profile.shock += shock; if (profile.shock > 4) profile.shock = 4; }
    if (knockdown && !profile.unconscious)
    {
        result.check = rpgLiteAttributeCheck(profile, rpgHT, 'major-wound', modifier);
        result.checks = result.checks + [result.check];
        if (!result.check.achieved)
        {
            result.knockedDown = true;
            profile.stunned = true; profile.posture = 'lying';
            foreach (local item in profile.equipment) if (!item.worn) item.ready = nil;
            if (result.check.margin <= -5 || result.check.critical == 'failure') profile.unconscious = true;
        }
    }
    for (local multiple = 1; multiple <= 4 && !profile.dead; multiple += 1)
        if (oldHP > -multiple * profile.maxHP && profile.hp() <= -multiple * profile.maxHP)
        {
            result.check = rpgLiteAttributeCheck(profile, rpgHT, 'death', 0);
            result.checks = result.checks + [result.check];
            if (!result.check.achieved)
            {
                if (profile.mortal || result.check.margin < -2) profile.dead = true;
                else { profile.mortal = true; profile.unconscious = true; }
            }
            else if (result.check.roll > profile.ht)
            { profile.apparentDeath = true; profile.unconscious = true; }
        }
    if (profile.hp() <= -5 * profile.maxHP) profile.dead = true;
    if (profile.dead) profile.unconscious = true;
    return result;
}

/** Apply fatigue and overflow injury, preserving recovery restrictions for named causes. */
rpgLiteFatigue(profile, amount, cause)
{
    rpgInteger(amount, 0, 10000);
    local result = new RpgLiteHealthResult();
    if (profile.dead) return result;
    if (holds(['exertion','battle','thirst'], cause) && amount > 0) amount += profile.heatExtra;
    local remaining = amount;
    while (remaining > 0)
    {
        if (profile.fp() <= 0) result.injury += rpgLiteWound(profile, 1).injury;
        if (profile.fp() > -profile.maxEnergy)
        {
            profile.fatigue += 1; result.fatigue += 1;
            if (cause == 'hunger') profile.hunger += 1;
            if (cause == 'thirst') profile.thirst += 1;
            if (cause == 'sleep') profile.sleepDebt += 1;
        }
        remaining -= 1;
    }
    if (profile.fp() <= -profile.maxEnergy) { profile.unconscious = true; profile.fatigueCollapse = true; }
    return result;
}

/** Check consciousness and effort when necessary; a failed check may incapacitate the character. */
rpgLiteCanAct(profile, doNothing)
{
    if (profile.dead || profile.unconscious || profile.mortal) return nil;
    if (doNothing) return true;
    if (profile.fp() <= 0)
    {
        local check = rpgLiteAttributeCheck(profile, rpgWill, 'effort', 0);
        if (!check.achieved) { profile.unconscious = true; profile.fatigueCollapse = true; return nil; }
    }
    if (profile.hp() <= 0)
    {
        local check = rpgLiteAttributeCheck(profile, rpgHT, 'consciousness', -(-profile.hp() / profile.maxHP));
        if (!check.achieved) { profile.unconscious = true; return nil; }
    }
    return true;
}

/** Apply direct healing and the associated mortal-wound and awakening checks. */
rpgLiteHeal(profile, amount)
{
    rpgInteger(amount, 0, 10000);
    if (profile.dead) return 0;
    if (amount > profile.injury) amount = profile.injury;
    profile.injury -= amount;
    if (amount > 0 && profile.mortal)
    {
        local check = rpgLiteAttributeCheck(profile, rpgHT, 'mortal-recovery', 0);
        if (check.achieved)
        {
            profile.mortal = nil;
            if (!rpgLiteAttributeCheck(profile, rpgHT, 'permanent-health', 0).achieved && profile.ht > 1) profile.ht -= 1;
        }
    }
    if (amount > 0 && profile.unconscious && !profile.mortal && profile.fp() > 0
        && rpgLiteAttributeCheck(profile, rpgHT, 'wake', 0).achieved)
    { profile.unconscious = nil; profile.apparentDeath = nil; profile.needsMedicalHelp = nil; }
    profile.afterHealing();
    return amount;
}

/** Persistent first-aid session with supplies, bandaging and TL-dependent treatment time. */
class RpgLiteTreatment: object
    patient = nil
    healer = nil
    skill = nil
    techLevel = 3
    elapsed = 0
    bandaged = nil
    completed = nil
    modifier = 0
    supplies = 1
    bandageHealing = 0
    advance(seconds)
    {
        rpgInteger(seconds, 1, 86400);
        local result = new RpgLiteHealthResult();
        if (self.completed || self.patient.aidUsed || self.patient.dead
            || self.healer.dead || self.healer.unconscious || self.healer.stunned || self.supplies < 1)
        { result.status = 'blocked'; return result; }
        rpgInteger(self.techLevel, 0, 12);
        local extra = self.techLevel <= 4 ? 1800 : self.techLevel <= 7 ? 1200 : 600;
        local remaining = extra + 60 - self.elapsed;
        if (seconds > remaining) seconds = remaining;
        self.elapsed += seconds; rpgSpendTime(seconds); result.seconds = seconds;
        if (self.elapsed >= 60 && !self.bandaged)
        {
            self.bandaged = true;
            if (self.patient.bandagedSerial != self.patient.woundSerial)
            {
                self.bandageHealing = rpgLiteHeal(self.patient, 1); result.healed += self.bandageHealing;
                self.patient.bandagedSerial = self.patient.woundSerial;
            }
        }
        if (self.elapsed < extra + 60) return result;
        local context = new RpgLiteContext();
        context.skill = self.skill == nil ? rpgLiteTraining(self.healer, 'first-aid', self.techLevel, nil) : self.skill;
        context.modifier = self.modifier;
        result.check = rpgLiteCheck(self.healer, context); self.completed = true; self.supplies -= 1;
        if (result.check.critical == 'failure') result.injury = rpgLiteWound(self.patient, 2 + self.bandageHealing).injury;
        else if (result.check.achieved)
        {
            local bonus = self.techLevel <= 1 ? -4 : self.techLevel <= 3 ? -3
                : self.techLevel <= 5 ? -2 : self.techLevel <= 7 ? -1 : self.techLevel == 8 ? 0 : 1;
            local total = (result.check.critical == 'success' ? 6 : rpgRandom.die()) + bonus;
            if (total > 1) result.healed += rpgLiteHeal(self.patient, total - 1);
        }
        self.patient.aidUsed = true; return result;
    }
;

/** Attempt end-of-turn stun recovery; fixed Fright durations cannot be shortened. */
rpgLiteRecoverStun(profile)
{
    if ((!profile.stunned && !profile.mentalStun) || profile.unconscious || profile.dead || profile.fearSeconds > 0) return nil;
    local check = rpgLiteAttributeCheck(profile, profile.mentalStun ? rpgIQ : rpgHT,
        profile.mentalStun ? 'mental-stun' : 'stun', 0);
    if (check.achieved) { profile.stunned = nil; profile.mentalStun = nil; }
    return check;
}

/** Advance quiet rest or sleep and eligible recovery; consumes the stated game time. */
rpgLiteRest(profile, seconds, food, water, sleeping, healingAllowed)
{
    rpgInteger(seconds, 1, 86400);
    local result = new RpgLiteHealthResult(); result.seconds = seconds;
    if (profile.dead) { result.status = 'blocked'; return result; }
    profile.validateNaturalRecovery(seconds,food,healingAllowed);
    local healingInterval = profile.naturalRecoveryInterval();
    local healingModifier = food && healingAllowed && profile.naturalRecoveryNeeded()
        ? profile.naturalRecoveryModifier() : 0;
    local healingAmount = profile.naturalRecoveryAmount();
    rpgSpendTime(seconds);
    for (local elapsed = 0; elapsed < seconds && (profile.stunned || profile.mentalStun)
        && !profile.unconscious && profile.fearSeconds == 0; elapsed += 1) rpgLiteRecoverStun(profile);
    profile.shock = 0;
    if (food) profile.hunger = 0;
    if (water)
    {
        profile.waterRestClock += seconds;
        if (profile.waterRestClock >= 86400)
        { profile.fatigue -= profile.thirst; result.fatigue -= profile.thirst; profile.thirst = 0; profile.waterRestClock = 0; }
    }
    else profile.waterRestClock = 0;
    if (sleeping)
    {
        profile.sleepClock += seconds;
        if (profile.sleepClock >= 28800) { profile.awakeClock = 0; profile.sleepCheckClock = 0; profile.sleepPenalty = nil; }
        while (profile.sleepDebt > 0 && profile.sleepClock >= (profile.sleepRecovered ? 3600 : 28800))
        {
            profile.sleepClock -= profile.sleepRecovered ? 3600 : 28800;
            profile.sleepRecovered = true; profile.sleepDebt -= 1; profile.fatigue -= 1;
        }
    }
    else { profile.sleepClock = 0; profile.sleepRecovered = nil; }
    profile.restClock += seconds;
    local locked = profile.hunger + profile.thirst + profile.sleepDebt + profile.temperatureFatigue;
    while (profile.restClock >= 600)
    {
        profile.restClock -= 600;
        if (profile.fatigue > locked) { profile.fatigue -= 1; result.fatigue -= 1; }
    }
    if (profile.fatigue == locked) profile.restClock = 0;
    if (food && healingAllowed)
    {
        profile.healingClock += seconds;
        while (profile.healingClock >= healingInterval)
        {
            profile.healingClock -= healingInterval;
            if (profile.naturalRecoveryNeeded())
            {
                result.check = rpgLiteAttributeCheck(profile, rpgHT, 'healing', healingModifier);
                if (result.check.achieved && profile.injury > profile.diseaseInjury + profile.temperatureInjury)
                {
                    local available = profile.injury - profile.diseaseInjury - profile.temperatureInjury;
                    result.healed += rpgLiteHeal(profile,healingAmount < available ? healingAmount : available);
                }
            }
        }
    }
    rpgLiteHealthTime(profile, seconds);
    return result;
}

/** Advance condition clocks without charging game time; compose with one activity clock. */
rpgLiteHealthTime(profile, seconds)
{
    if (profile.dead) return nil;
    if (profile.fatigueCollapse && profile.fp() > 0 && !profile.mortal)
    { profile.unconscious = nil; profile.fatigueCollapse = nil; }
    if (profile.fearSeconds > 0)
    {
        profile.fearSeconds -= seconds;
        if (profile.fearSeconds <= 0)
        { profile.fearSeconds = 0; profile.stunned = nil; if (profile.hp() > 0 && profile.fp() > 0) profile.unconscious = nil; }
    }
    if (profile.mortal)
    {
        profile.mortalClock += seconds;
        while (profile.mortalClock >= 1800 && !profile.dead && profile.mortal)
        {
            profile.mortalClock -= 1800;
            local check = rpgLiteAttributeCheck(profile, rpgHT, 'mortal-wound', 0);
            if (!check.achieved) profile.dead = true;
            else if (check.critical == 'success')
            {
                profile.mortal = nil;
                if (!rpgLiteAttributeCheck(profile, rpgHT, 'permanent-health', 0).achieved && profile.ht > 1) profile.ht -= 1;
            }
        }
    }
    if (profile.unconscious && !profile.mortal && !profile.dead && profile.fearSeconds == 0)
    {
        profile.unconsciousClock += seconds;
        if (profile.fp() > 0 && profile.hp() > 0 && profile.unconsciousClock >= 900)
        { profile.unconscious = nil; profile.apparentDeath = nil; }
        else if (profile.fp() > 0 && profile.hp() <= 0)
        {
            local interval = profile.hp() > -profile.maxHP ? 3600 : 43200;
            while (profile.unconsciousClock >= interval && profile.unconscious && !profile.dead)
            {
                profile.unconsciousClock -= interval;
                local check = rpgLiteAttributeCheck(profile, rpgHT, 'wake', 0);
                if (check.achieved && !profile.needsMedicalHelp) profile.unconscious = nil;
                else if (profile.hp() <= -profile.maxHP)
                {
                    if (profile.needsMedicalHelp && !check.achieved) profile.dead = true;
                    profile.needsMedicalHelp = true;
                }
            }
        }
    }
    if (!profile.unconscious) profile.unconsciousClock = 0;
    return nil;
}

/** Resolve fear and set the Lite stun or fainting duration on failure. */
rpgLiteFright(profile, modifier)
{
    local result = rpgLiteAttributeCheck(profile, rpgWill, 'fright', modifier);
    if (!result.achieved)
    {
        if (result.critical == 'failure')
        { profile.fearSeconds = (-result.margin + rpgRandom.die()) * 60; profile.unconscious = true; }
        else { profile.fearSeconds = -result.margin + rpgRandom.die() + rpgRandom.die(); profile.stunned = true; }
    }
    return result;
}

modify RpgLiteProfile
    sleepClock = 0
    sleepRecovered = nil
    needsMedicalHelp = nil
    fatigueCollapse = nil
    woundSerial = 0
    bandagedSerial = -1
    waterRestClock = 0
    awakeClock = 0
    sleepCheckClock = 0
    sleepPenalty = nil
    burningPenalty = 0
    diseaseInjury = 0
    temperatureInjury = 0
    temperatureFatigue = 0
    heatExtra = 0
;

/** Authored poison or disease parameters: resistance, delay, cycle, damage and recovery modifier. */
class RpgLiteHazard: object
    kind = 'poison'
    resistanceModifier = 0
    delay = 0
    interval = 1
    cycles = 1
    dice = 1
    adds = 0
    fatigueDamage = nil
    resistible = true
    recoveryModifier = 0
;

/** Persistent exposure timeline; partial intervals and disease recovery locks survive saves. */
class RpgLiteExposure: object
    profile = nil
    hazard = nil
    elapsed = 0
    remaining = 0
    started = nil
    finished = nil
    lockedInjury = 0
    advance(seconds)
    {
        rpgInteger(seconds, 0, 86400);
        local result = new RpgLiteHealthResult();
        if (self.finished || self.profile.dead) return result;
        rpgInteger(self.hazard.interval, 1, 31536000); rpgInteger(self.hazard.cycles, 1, 10000);
        rpgInteger(self.hazard.delay, 0, 31536000);
        if (!self.started)
        {
            self.remaining = self.hazard.cycles; self.started = true;
            if (self.hazard.kind == 'disease' && self.hazard.resistible)
            {
                result.check = rpgLiteAttributeCheck(self.profile, rpgHT, 'disease', self.hazard.resistanceModifier);
                if (result.check.achieved) { self.finished = true; return result; }
            }
        }
        self.elapsed += seconds;
        local due = self.hazardDelayDone ? self.hazard.interval : self.hazard.delay;
        while (self.elapsed >= due && !self.finished)
        {
            self.elapsed -= due;
            result.check = self.hazard.resistible && (self.hazard.kind != 'disease' || self.hazardDelayDone)
                ? rpgLiteAttributeCheck(self.profile, rpgHT, self.hazard.kind,
                    self.hazard.resistanceModifier + (self.hazard.kind == 'disease' ? self.hazard.recoveryModifier : 0)) : nil;
            if (self.hazard.kind == 'disease' && result.check != nil && result.check.achieved)
            { self.finished = true; break; }
            if (result.check == nil || !result.check.achieved)
            {
                local amount = rpgLiteRollDamage(self.hazard.dice, self.hazard.adds, 'cr', nil);
                if (self.hazard.fatigueDamage) result.fatigue += rpgLiteFatigue(self.profile, amount, self.hazard.kind).fatigue;
                else
                {
                    local injury = rpgLiteWound(self.profile, amount).injury; result.injury += injury;
                    if (self.hazard.kind == 'disease')
                    { self.lockedInjury += injury; self.profile.diseaseInjury += injury; }
                }
            }
            self.remaining -= 1;
            if (self.remaining == 0 || self.profile.dead) self.finished = true;
            due = self.hazard.interval;
            self.hazardDelayDone = true;
        }
        if (self.finished && self.lockedInjury > 0)
        { self.profile.diseaseInjury -= self.lockedInjury; self.lockedInjury = 0; }
        return result;
    }
    hazardDelayDone = nil
;

/** Apply seconds without air, or resume clean air and check lasting injury. */
rpgLiteSuffocate(profile, seconds, cleanAir)
{
    rpgInteger(seconds, 0, 86400);
    if (cleanAir)
    {
        if (profile.airClock > 120 && !rpgLiteAttributeCheck(profile, rpgHT, 'brain-injury', 0).achieved && profile.iq > 1)
            profile.iq -= 1;
        profile.airClock = 0; return nil;
    }
    for (local elapsed = 0; elapsed < seconds && !profile.dead; elapsed += 1)
    {
        profile.airClock += 1; rpgLiteFatigue(profile, 1, 'air');
        if (profile.fp() <= 0 && !profile.unconscious
            && !rpgLiteAttributeCheck(profile, rpgWill, 'air', 0).achieved)
        { profile.unconscious = true; profile.fatigueCollapse = true; }
        if (profile.airClock >= 240) { profile.dead = true; profile.unconscious = true; }
    }
    return nil;
}

/** Persistent heat/cold exposure and shelter-dependent recovery restrictions. */
class RpgLiteClimate: object
    profile = nil
    fahrenheit = 70
    wind = 0
    clothing = 0
    wet = nil
    active = true
    sheltered = nil
    elapsed = 0
    advance(seconds)
    {
        rpgInteger(seconds, 0, 86400);
        self.profile.heatExtra = self.fahrenheit >= 121 ? 2 : self.fahrenheit >= 91 ? 1 : 0;
        if (self.sheltered || self.fahrenheit >= 35 && self.fahrenheit <= 80)
        {
            self.elapsed = 0; self.profile.temperatureFatigue = 0; self.profile.temperatureInjury = 0;
            if (self.sheltered) self.profile.heatExtra = 0;
            return 0;
        }
        if (self.fahrenheit > 80 && !self.active) return 0;
        local interval = self.fahrenheit < 35 ? (self.wind >= 30 ? 600 : self.wind >= 10 ? 900 : 1800) : 1800;
        local modifier = self.fahrenheit < 35 ? self.clothing - (self.wet ? 5 : 0)
            - (self.fahrenheit < 0 ? -self.fahrenheit / 10 : 0) : 0;
        local total = 0; self.elapsed += seconds;
        while (self.elapsed >= interval)
        {
            self.elapsed -= interval;
            local check = rpgLiteAttributeCheck(self.profile, rpgHT, 'temperature', modifier);
            if (!check.achieved)
            {
                local amount = self.fahrenheit > 80 && check.critical == 'failure' ? rpgRandom.die() : 1;
                local damage = rpgLiteFatigue(self.profile, amount, 'temperature'); total += damage.fatigue;
                self.profile.temperatureFatigue += damage.fatigue; self.profile.temperatureInjury += damage.injury;
            }
        }
        return total;
    }
;

/** Advance food, water and waking-time needs using the day's supplied meals and quarts. */
class RpgLiteNeeds: object
    profile = nil
    waterQuarts = 2
    requiredQuarts = 2
    meals = 3
    active = true
    elapsed = 0
    advance(seconds)
    {
        rpgInteger(seconds, 0, 86400); rpgInteger(self.meals, 0, 3);
        rpgInteger(self.waterQuarts, 0, 100); rpgInteger(self.requiredQuarts, 1, 100);
        for (local index = 0; index < seconds && !self.profile.dead; index += 1)
        {
            self.elapsed += 1; self.profile.awakeClock += 1;
            if (self.elapsed % 28800 == 0 && self.waterQuarts < self.requiredQuarts)
                rpgLiteFatigue(self.profile, 1, 'thirst');
            if (self.elapsed >= 86400)
            {
                self.elapsed = 0; rpgLiteFatigue(self.profile, 3 - self.meals, 'hunger');
                if (self.waterQuarts < 1)
                { rpgLiteFatigue(self.profile, 1, 'thirst'); rpgLiteWound(self.profile, 1); }
            }
            if (self.profile.awakeClock >= 57600 && (self.profile.awakeClock - 57600) % 14400 == 0)
                rpgLiteFatigue(self.profile, 1, 'sleep');
            local interval = self.profile.sleepDebt > 0 && self.profile.fp() * 3 < self.profile.maxEnergy
                ? (self.active ? 7200 : 1800) : self.profile.sleepDebt * 2 >= self.profile.maxEnergy && !self.active ? 7200 : 0;
            if (interval > 0)
            {
                self.profile.sleepCheckClock += 1;
                if (self.profile.sleepCheckClock >= interval)
                {
                    self.profile.sleepCheckClock = 0;
                    if (!rpgLiteAttributeCheck(self.profile, rpgWill, 'sleep', 0).achieved)
                    { self.profile.unconscious = true; return nil; }
                    self.profile.sleepPenalty = true;
                }
            }
            else self.profile.sleepCheckClock = 0;
        }
        return nil;
    }
;

/** Track burning clothes, distraction, damage and extinguishing maneuvers. */
class RpgLiteFire: object
    profile = nil
    burning = 0
    extinguishProgress = 0
    ignite(basicDamage)
    {
        if (basicDamage >= 10) self.burning = 2;
        else if (basicDamage >= 3 && self.burning == 0) self.burning = 1;
        self.profile.burningPenalty = self.burning == 2 ? 3 : self.burning == 1 ? 2 : 0;
        return self.burning;
    }
    tick(seconds)
    {
        rpgInteger(seconds, 0, 86400);
        for (local elapsed = 0; elapsed < seconds && self.burning > 0 && !self.profile.dead; elapsed += 1)
        {
            local damage = rpgLiteRollDamage(1, self.burning == 1 ? -4 : -1, 'burn', nil);
            self.profile.burningPenalty = damage > rpgLiteArmor(self.profile) ? (self.burning == 1 ? 2 : 3) : 0;
            rpgLiteWound(self.profile, rpgLitePenetration(damage, rpgLiteArmor(self.profile), 1, 'burn', nil));
        }
        return nil;
    }
    extinguish(water)
    {
        if (water) { self.burning = 0; self.extinguishProgress = 0; self.profile.burningPenalty = 0; return true; }
        self.extinguishProgress += 1;
        if (self.extinguishProgress < (self.burning == 2 ? 3 : 1)) return nil;
        self.extinguishProgress = 0;
        if (rpgLiteAttributeCheck(self.profile, rpgDX, 'extinguish', 0).achieved) self.burning = 0;
        if (self.burning == 0) self.profile.burningPenalty = 0;
        return self.burning == 0;
    }
;
