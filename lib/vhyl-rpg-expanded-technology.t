/* Include after the expanded foundation. Source: full-2008, B483-B485. */

/** A surviving weapon form; replacement statistics come from that form's catalogue. */
class RpgExpandedBrokenPiece: object
    form = nil
    placement = 'held'
    attackModifier = 0
    reach = nil
    damageBase = nil
    damageAdds = nil
    damageType = nil
;

class RpgExpandedBrokenWeaponResult: RpgExpandedResult
    usable = nil
    pieces = []
    retainOriginal = nil
    cuttingDamageModifier = 0
    thrustBase = nil
    thrustDamageType = nil
    reach = nil
;

/** Pure disabled/destroyed weapon assessment. No item, damage, die or clock mutation. */
rpgExpandedBrokenWeapon(state, weightHundredths, missile, family, die, reach)
{
    if (!holds(['disabled','destroyed'],state)) rpgExpandedReject('broken-weapon-state');
    rpgInteger(weightHundredths,0,100000000); rpgInteger(reach,0,1000);
    local value = new RpgExpandedBrokenWeaponResult();
    if (state == 'destroyed' || weightHundredths <= 100 || missile)
    {
        if (die != nil) rpgExpandedReject('broken-weapon-unused-die');
        value.status = 'ready'; return value;
    }
    if (!holds(['axe-mace','polearm','rapier','smallsword','spear','sword','saber','two-handed-axe-mace'],family))
    { value.reason = 'broken-weapon-analogy-required'; return value; }
    if (die == nil) { value.status = 'needs-roll'; value.reason = 'broken-weapon-die-required'; return value; }
    rpgInteger(die,1,6);
    local held = new RpgExpandedBrokenPiece(); local ground = nil;
    if (family == 'axe-mace') { if (die <= 3) held.form = 'light-club'; }
    else if (family == 'polearm')
    {
        if (die <= 2)
        { held.form = 'long-spear'; held.damageBase = 'thrust'; held.damageAdds = 2; held.damageType = 'cr'; }
        else
        {
            ground = new RpgExpandedBrokenPiece(); ground.placement = 'ground';
            held.form = die <= 4 ? 'quarterstaff' : 'light-club';
            ground.form = die <= 4 ? 'axe' : 'great-axe';
            ground.attackModifier = die <= 4 ? -4 : -2; ground.reach = die <= 4 ? 1 : 2;
        }
    }
    else if (family == 'rapier' || family == 'smallsword')
    {
        if (die <= 3) { held.form = family == 'rapier' ? 'smallsword' : 'dagger'; held.damageType = 'imp'; }
    }
    else if (family == 'spear')
    {
        held.form = die <= 3 ? 'quarterstaff' : 'baton';
        if (die >= 4)
        { ground = new RpgExpandedBrokenPiece(); ground.placement = 'ground'; ground.form = 'spear'; ground.reach = 1; }
    }
    else if (family == 'sword' || family == 'saber')
    {
        if (die <= 3)
        {
            held.form = 'original'; value.retainOriginal = true; value.cuttingDamageModifier = -2;
            value.thrustBase = 'thrust'; value.thrustDamageType = 'cr'; value.reach = reach == 2 ? 1 : reach;
        }
    }
    else
    {
        held.form = die <= 3 ? 'quarterstaff' : 'light-club';
        if (die >= 4)
        {
            ground = new RpgExpandedBrokenPiece(); ground.placement = 'ground';
            ground.form = 'axe'; ground.attackModifier = -4; ground.reach = 1;
        }
    }
    if (held.form != nil) { value.usable = true; value.pieces = [held]; }
    if (ground != nil) value.pieces = value.pieces + [ground];
    value.status = 'ready'; return value;
}

/** B483 detailed capacity calculation, rounded up using exact integer arithmetic.
 * Weight is in hundredths of a pound; the bound keeps cubic products in range. */
rpgExpandedObjectCapacity(weightHundredths, construction)
{
    rpgInteger(weightHundredths,1,1000000);
    if (!holds(['unliving','homogenous'],construction)) rpgExpandedReject('object-capacity-construction');
    local factor = construction == 'unliving' ? 4 : 8;
    local target = weightHundredths * factor * factor * factor;
    local low = 1; local high = 173;
    while (low < high)
    {
        local middle = (low + high) / 2;
        if (middle * middle * middle * 100 >= target) high = middle;
        else low = middle + 1;
    }
    return low;
}

class RpgExpandedObjectInjuryResult: RpgExpandedResult
    remaining = 0
    destructionThresholds = []
    automaticDestruction = nil
    stressChecksRequired = nil
    reducedEffectivenessEligible = nil
    majorDamage = nil
;

/** Assess final object injury, after material/type effects, without choosing subsystem failures. */
rpgExpandedObjectInjury(capacity, priorInjury, injury)
{
    rpgInteger(capacity,1,1000000); rpgInteger(priorInjury,0,100000000); rpgInteger(injury,0,100000000);
    local value = new RpgExpandedObjectInjuryResult();
    local before = capacity - priorInjury; value.remaining = before - injury;
    for (local multiple = 1; multiple <= 4; multiple += 1)
        if (before > -multiple * capacity && value.remaining <= -multiple * capacity)
            value.destructionThresholds = value.destructionThresholds + [multiple];
    value.automaticDestruction = value.remaining <= -5 * capacity;
    value.stressChecksRequired = value.remaining <= 0;
    value.reducedEffectivenessEligible = value.remaining * 3 < capacity;
    value.majorDamage = injury * 2 > capacity;
    value.status = 'ready'; return value;
}

modify RpgLiteItem
    artifactHT = nil
    maintenanceHTLoss = 0
    requiresMaintenance = nil
    environmentFailures = []
    environmentFailure = nil
    usableBy(profile)
    {
        return self.environmentFailure == nil && inherited(profile);
    }
;

class RpgExpandedBreakdownResult: RpgExpandedResult
    repair = nil
    day = nil
;

/** Owned B485 exposure check. World code supplies the exposure; it owns no elapsed time. */
class RpgExpandedBreakdown: object
    id = nil
    item = nil
    trigger = 'careless-exposure'
    evidence = nil
    dailyCleaning = nil
    brutality = 0
    result = nil
    boundId = nil
    boundItem = nil
    boundTrigger = nil
    boundEvidence = nil
    boundCleaning = nil
    boundBrutality = nil
    assessedHT = nil
    assess()
    {
        if (self.item == nil || !self.item.ofKind(RpgLiteItem)) rpgExpandedReject('breakdown-item');
        local value = new RpgExpandedBreakdownResult();
        if (self.result != nil)
        {
            if (self.id != self.boundId || self.item != self.boundItem || self.trigger != self.boundTrigger
                || self.evidence != self.boundEvidence || self.dailyCleaning != self.boundCleaning
                || self.brutality != self.boundBrutality || !holds(self.item.environmentFailures,self))
                rpgExpandedReject('breakdown-binding');
            value.status = 'reused'; value.check = self.result.check; value.repair = self.result.repair;
            value.day = self.result.day; return value;
        }
        if (self.id == nil || self.id == '' || !holds(['careless-exposure','extreme-day'],self.trigger))
            rpgExpandedReject('breakdown-declaration');
        if (self.evidence == nil || self.evidence == '') { value.reason = 'breakdown-evidence'; return value; }
        if (!self.item.requiresMaintenance) { value.reason = 'breakdown-maintenance-not-required'; return value; }
        if (self.item.environmentFailure != nil) { value.reason = 'breakdown-repair-required'; return value; }
        rpgInteger(self.brutality,-2,0); rpgInteger(self.item.maintenanceHTLoss,0,1000);
        local health = self.item.artifactHT == nil ? 10 : self.item.artifactHT;
        rpgInteger(health,1,1000);
        local score = health - self.item.maintenanceHTLoss + 4 + (self.dailyCleaning ? 1 : 0) + self.brutality;
        if (score < 3 || score > 1000) { value.reason = 'breakdown-score-unavailable'; return value; }
        value.modifier = score;
        value.day = rpgLedger.seconds / 86400;
        foreach (local prior in self.item.environmentFailures)
        {
            if (prior == nil || !prior.ofKind(RpgExpandedBreakdown) || prior.item != self.item
                || prior.result == nil || prior.assess().status != 'reused') rpgExpandedReject('breakdown-history');
            if (prior.id == self.id) rpgExpandedReject('breakdown-duplicate');
            if (self.trigger == 'extreme-day' && prior.trigger == 'extreme-day' && prior.result.day == value.day)
            { value.reason = 'breakdown-day-already-checked'; return value; }
        }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        value.check = rpgCheck(value.modifier,rpgRandom.roll());
        if (!value.check.achieved)
        {
            value.repair = value.check.critical == 'failure' ? 'major' : 'minor';
            self.item.environmentFailure = self;
        }
        self.boundId = self.id; self.boundItem = self.item; self.boundTrigger = self.trigger;
        self.boundEvidence = self.evidence; self.boundCleaning = self.dailyCleaning; self.boundBrutality = self.brutality;
        self.assessedHT = value.modifier - 4 - (self.dailyCleaning ? 1 : 0) - self.brutality;
        self.item.environmentFailures = self.item.environmentFailures + [self];
        value.status = 'resolved'; self.result = value; return value;
    }
;

/** B484 original-price modifier; monetary values use the inventory's whole units. */
rpgExpandedRepairPriceModifier(price)
{
    rpgInteger(price,0,100000000);
    return price <= 1000 ? 1 : price <= 10000 ? 0 : price <= 100000 ? -1 : price <= 1000000 ? -2 : -3;
}

/** Supplied-die major-repair parts quote, rounded up; this does not purchase parts. */
rpgExpandedRepairPartsPrice(price, die)
{
    rpgInteger(price,0,100000000); rpgInteger(die,1,6);
    return (price * die + 9) / 10;
}

modify RpgExpandedBreakdown
    repairs = []
    repairedBy = nil
;

class RpgExpandedBreakdownRepairResult: RpgExpandedResult
    context = nil
    repaired = nil
;

/** A fixed-duration minor environmental-fault repair; major repairs require parts integration. */
class RpgExpandedBreakdownRepair: object
    id = nil
    failure = nil
    repairer = nil
    skill = nil
    approvedSkill = nil
    evidence = nil
    uninterrupted = nil
    equipmentModifier = 0
    result = nil
    boundId = nil
    boundFailure = nil
    boundRepairer = nil
    boundSkill = nil
    boundEvidence = nil
    boundEquipmentModifier = nil
    assess()
    {
        if (self.failure == nil || !self.failure.ofKind(RpgExpandedBreakdown)
            || self.failure.result == nil) rpgExpandedReject('breakdown-repair-fault');
        local value = new RpgExpandedBreakdownRepairResult();
        if (self.result != nil)
        {
            if (self.id != self.boundId || self.failure != self.boundFailure || self.repairer != self.boundRepairer
                || self.skill != self.boundSkill || self.evidence != self.boundEvidence
                || self.equipmentModifier != self.boundEquipmentModifier || !self.approvedSkill || !self.uninterrupted
                || !holds(self.failure.repairs,self)) rpgExpandedReject('breakdown-repair-binding');
            value.status = 'reused'; value.check = self.result.check; value.repaired = self.result.repaired; return value;
        }
        if (self.id == nil || self.id == '' || self.repairer == nil || !self.repairer.ofKind(RpgLiteProfile)
            || self.skill == nil || !self.skill.ofKind(RpgLiteSkill)) rpgExpandedReject('breakdown-repair-definition');
        self.failure.assess();
        if (self.failure.repairedBy != nil || self.failure.item.environmentFailure != self.failure)
        { value.reason = 'breakdown-repair-not-active'; return value; }
        if (self.failure.result.repair != 'minor')
        { value.reason = 'breakdown-major-parts-unavailable'; return value; }
        if (!self.approvedSkill || self.evidence == nil || self.evidence == '' || !self.uninterrupted)
        { value.reason = 'breakdown-repair-author-facts'; return value; }
        if (self.repairer.dead || self.repairer.unconscious || self.repairer.stunned
            || self.repairer.hp() <= 0 || self.repairer.fp() <= 0)
        { value.reason = 'breakdown-repair-condition-unavailable'; return value; }
        foreach (local prior in self.failure.repairs)
        {
            if (prior == nil || !prior.ofKind(RpgExpandedBreakdownRepair) || prior.failure != self.failure
                || prior.result == nil || prior.assess().status != 'reused') rpgExpandedReject('breakdown-repair-history');
            if (prior.id == self.id) rpgExpandedReject('breakdown-repair-duplicate');
        }
        rpgInteger(self.equipmentModifier,-100,100);
        value.context = new RpgLiteContext(); value.context.skill = self.skill; value.context.kind = 'repair';
        value.context.modifier = self.equipmentModifier + rpgExpandedRepairPriceModifier(self.failure.item.cost);
        local score = rpgLiteScore(self.repairer,value.context);
        if (score == nil || score < 3) { value.reason = 'breakdown-repair-score-unavailable'; return value; }
        value.seconds = 1800; value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        rpgSpendTime(value.seconds);
        value.check = rpgLiteCheck(self.repairer,value.context);
        if (value.check.achieved)
        {
            self.failure.item.environmentFailure = nil; self.failure.repairedBy = self; value.repaired = true;
        }
        self.boundId = self.id; self.boundFailure = self.failure; self.boundRepairer = self.repairer;
        self.boundSkill = self.skill; self.boundEvidence = self.evidence; self.boundEquipmentModifier = self.equipmentModifier;
        self.failure.repairs = self.failure.repairs + [self]; value.status = 'resolved'; self.result = value; return value;
    }
;
