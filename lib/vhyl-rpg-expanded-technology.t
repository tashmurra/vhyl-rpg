/* Include after the expanded foundation and equipment. Source: full-2008, B483-B485. */

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

/** Fixed-duration environmental-fault repair; major faults install a purchased parts package. */
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
    boundParts = nil
    assess()
    {
        if (self.failure == nil || !self.failure.ofKind(RpgExpandedBreakdown)
            || self.failure.result == nil) rpgExpandedReject('breakdown-repair-fault');
        local value = new RpgExpandedBreakdownRepairResult();
        if (self.result != nil)
        {
            if (self.id != self.boundId || self.failure != self.boundFailure || self.repairer != self.boundRepairer
                || self.skill != self.boundSkill || self.evidence != self.boundEvidence
                || self.equipmentModifier != self.boundEquipmentModifier || self.failure.parts != self.boundParts || !self.approvedSkill || !self.uninterrupted
                || !holds(self.failure.repairs,self)) rpgExpandedReject('breakdown-repair-binding');
            value.status = 'reused'; value.check = self.result.check; value.repaired = self.result.repaired; return value;
        }
        if (self.id == nil || self.id == '' || self.repairer == nil || !self.repairer.ofKind(RpgLiteProfile)
            || self.skill == nil || !self.skill.ofKind(RpgLiteSkill)) rpgExpandedReject('breakdown-repair-definition');
        self.failure.assess();
        if (self.failure.repairedBy != nil || self.failure.item.environmentFailure != self.failure)
        { value.reason = 'breakdown-repair-not-active'; return value; }
        if (self.failure.result.repair == 'major')
        {
            if (self.failure.parts == nil) { value.reason = 'breakdown-major-parts-unavailable'; return value; }
            value.reason = self.failure.parts.installationReason(); if (value.reason != nil) return value;
        }
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
        value.context.modifier = self.equipmentModifier + rpgExpandedRepairPriceModifier(self.failure.item.cost)
            - (self.failure.result.repair == 'major' ? 2 : 0);
        local score = rpgLiteScore(self.repairer,value.context);
        if (score == nil || score < 3) { value.reason = 'breakdown-repair-score-unavailable'; return value; }
        value.seconds = 1800; value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local reason = self.repairer.repairAttentionReason(self);
        if (reason != nil) { value.status = 'blocked'; value.reason = reason; return value; }
        return self.applyAssessed(value,true);
    }
    applyAttention(control)
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        if (!self.repairer.ofKind(RpgExpandedProfile)) rpgExpandedReject('attention-repair-owner');
        local reason = self.repairer.attentionRepairControlReason(control,self);
        if (reason != nil) rpgExpandedReject(reason);
        control.repairStarted = true;
        return self.applyAssessed(value,control.check.achieved);
    }
    /* Internal settlement; the existing attempt owns time and replacement parts. */
    applyAssessed(value,focused)
    {
        if (self.failure.result.repair == 'major') self.failure.parts.install();
        rpgSpendTime(value.seconds);
        if (focused) value.check = rpgLiteCheck(self.repairer,value.context);
        else
        {
            value.check = new RpgResult(); value.check.status = 'resolved';
            value.check.reason = 'short-attention-task-failure'; value.check.outcome = 'setback';
        }
        if (value.check.achieved)
        {
            self.failure.item.environmentFailure = nil; self.failure.repairedBy = self; value.repaired = true;
        }
        self.boundId = self.id; self.boundFailure = self.failure; self.boundRepairer = self.repairer;
        self.boundSkill = self.skill; self.boundEvidence = self.evidence; self.boundEquipmentModifier = self.equipmentModifier;
        self.boundParts = self.failure.parts;
        self.failure.repairs = self.failure.repairs + [self]; value.status = 'resolved'; self.result = value; return value;
    }
;

modify RpgExpandedBreakdown
    parts = nil
;

class RpgExpandedRepairPartsResult: RpgExpandedResult
    die = nil
    price = 0
;

/** One fault-bound major-repair parts package; purchase reuses equipment acquisition. */
class RpgExpandedRepairParts: object
    failure = nil
    payer = nil
    evidence = nil
    weight = 0
    available = nil
    permitted = nil
    result = nil
    package = nil
    acquisition = nil
    installed = nil
    boundFailure = nil
    boundPayer = nil
    boundEvidence = nil
    boundWeight = nil
    originalPrice = nil
    assess()
    {
        if (self.failure == nil || !self.failure.ofKind(RpgExpandedBreakdown)
            || self.failure.result == nil || self.payer == nil || !self.payer.ofKind(RpgExpandedProfile))
            rpgExpandedReject('repair-parts-definition');
        local value = new RpgExpandedRepairPartsResult();
        if (self.result != nil)
        {
            if (self.failure != self.boundFailure || self.payer != self.boundPayer
                || self.evidence != self.boundEvidence || self.weight != self.boundWeight
                || self.failure.parts != self || self.package == nil || self.acquisition == nil
                || self.acquisition.profile != self.payer || self.acquisition.item != self.package
                || self.acquisition.mode != 'purchase' || self.acquisition.quote != nil || self.acquisition.startingPurchase
                || self.package.cost != self.result.price || self.package.weight != self.boundWeight
                || self.package.quantity != 1) rpgExpandedReject('repair-parts-binding');
            value.status = 'reused'; value.die = self.result.die; value.price = self.result.price; return value;
        }
        self.failure.assess(); rpgExpandedValidate(self.payer); rpgInteger(self.weight,0,100000000);
        rpgInteger(self.failure.item.cost,0,100000000);
        if (self.failure.parts != nil) { value.reason = 'repair-parts-already-quoted'; return value; }
        if (self.failure.item.environmentFailure != self.failure || self.failure.result.repair != 'major')
        { value.reason = 'repair-parts-major-fault-required'; return value; }
        if (self.evidence == nil || self.evidence == '' || !self.available || !self.permitted)
        { value.reason = 'repair-parts-supply-facts'; return value; }
        value.status = 'ready'; return value;
    }
    quote()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.originalPrice = self.failure.item.cost;
        value.die = rpgRandom.die(); value.price = rpgExpandedRepairPartsPrice(self.originalPrice,value.die);
        self.package = new RpgLiteItem(); self.package.id = 'repair-parts'; self.package.cost = value.price;
        self.package.weight = self.weight;
        self.acquisition = new RpgExpandedAcquisition(); self.acquisition.profile = self.payer;
        self.acquisition.item = self.package; self.acquisition.available = self.available; self.acquisition.permitted = self.permitted;
        self.boundFailure = self.failure; self.boundPayer = self.payer; self.boundEvidence = self.evidence; self.boundWeight = self.weight;
        self.failure.parts = self; value.status = 'resolved'; self.result = value; return value;
    }
    purchase()
    {
        if (self.result == nil) rpgExpandedReject('repair-parts-quote-required');
        self.assess();
        self.acquisition.available = self.available; self.acquisition.permitted = self.permitted;
        return self.acquisition.acquire();
    }
    installationReason()
    {
        if (self.result == nil) return 'repair-parts-quote-required';
        self.assess();
        if (!self.acquisition.claimed) return 'repair-parts-not-purchased';
        if (self.installed) return nil;
        local count = 0;
        foreach (local item in self.payer.equipment) if (item == self.package) count += 1;
        if (count > 1) return 'repair-parts-duplicate-inventory';
        if (count == 0 || !self.package.usableBy(self.payer))
            return 'repair-parts-not-carried';
        return nil;
    }
    install()
    {
        local reason = self.installationReason(); if (reason != nil) rpgExpandedReject(reason);
        if (self.installed) return 'reused';
        local kept = []; local count = 0;
        foreach (local item in self.payer.equipment)
            if (item == self.package) count += 1; else kept = kept + [item];
        if (count != 1) rpgExpandedReject('repair-parts-inventory');
        self.payer.equipment = kept; self.installed = true; return 'resolved';
    }
;

/** Exact B472 processing units. The bounded scale supports mixed workloads without fractions. */
rpgExpandedProcessingUnits(complexity)
{
    rpgInteger(complexity,0,8); local units = 1;
    for (local level = 0; level < complexity; level += 1) units *= 10;
    return units;
}

/** An authored installed copy, distinct from any number of running instances. */
class RpgExpandedSoftwareCopy: object
    id = nil
    host = nil
    complexity = 1
    approved = nil
    evidence = nil
;

/** Persistent host reservations. Storage, task effects and connection permissions are separate. */
class RpgExpandedComputer: object
    item = nil
    complexity = 1
    powered = nil
    copies = []
    runs = []
    capacity() { return 2 * rpgExpandedProcessingUnits(self.complexity); }
    used()
    {
        self.validateHardwareHistory();
        local used = 0; local ids = [];
        foreach (local run in self.runs)
        {
            if (run == nil || !run.ofKind(RpgExpandedProgramRun) || run.host != self
                || run.result == nil || holds(ids,run.id)) rpgExpandedReject('computer-run-history');
            run.validateBinding(); ids = ids + [run.id];
            if (run.result.units != rpgExpandedProcessingUnits(run.boundComplexity))
                rpgExpandedReject('computer-reservation-changed');
            if (run.active)
            {
                if (run.result.units > self.capacity() - used) rpgExpandedReject('computer-overcommitted');
                used += run.result.units;
            }
        }
        if (used > self.capacity()) rpgExpandedReject('computer-overcommitted');
        return used;
    }
;

class RpgExpandedProgramResult: RpgExpandedResult
    units = 0
    used = 0
    capacity = 0
;

/** One owned software process; restarting after stop requires a new instance ID. */
class RpgExpandedProgramRun: object
    id = nil
    host = nil
    copy = nil
    active = nil
    result = nil
    startedAt = nil
    stoppedAt = nil
    boundId = nil
    boundHost = nil
    boundCopy = nil
    boundComplexity = nil
    validateBinding()
    {
        if (self.id != self.boundId || self.host != self.boundHost || self.copy != self.boundCopy
            || self.copy == nil || self.copy.host != self.host || self.copy.complexity != self.boundComplexity
            || !holds(self.host.runs,self)) rpgExpandedReject('program-run-binding');
        return nil;
    }
    assess()
    {
        if (self.host == nil || !self.host.ofKind(RpgExpandedComputer)) rpgExpandedReject('program-host');
        local value = new RpgExpandedProgramResult();
        if (self.result != nil)
        {
            self.validateBinding(); value.status = 'reused'; value.units = self.result.units;
            value.used = self.result.used; value.capacity = self.result.capacity; return value;
        }
        if (self.id == nil || self.id == '' || self.copy == nil || !self.copy.ofKind(RpgExpandedSoftwareCopy)
            || self.copy.host != self.host || !holds(self.host.copies,self.copy)) rpgExpandedReject('program-copy');
        if (self.host.item == nil || !self.host.item.ofKind(RpgLiteItem)) rpgExpandedReject('computer-item');
        if (!self.copy.approved || self.copy.evidence == nil || self.copy.evidence == '')
        { value.reason = 'program-copy-authorization'; return value; }
        local copyIds = []; local copies = [];
        foreach (local installed in self.host.copies)
        {
            if (installed == nil || !installed.ofKind(RpgExpandedSoftwareCopy) || installed.host != self.host
                || installed.id == nil || installed.id == '' || holds(copies,installed) || holds(copyIds,installed.id))
                rpgExpandedReject('computer-copy-inventory');
            copies = copies + [installed]; copyIds = copyIds + [installed.id];
        }
        foreach (local prior in self.host.runs)
            if (prior.id == self.id) rpgExpandedReject('program-run-duplicate');
        value.capacity = self.host.capacity(); value.used = self.host.used();
        value.units = rpgExpandedProcessingUnits(self.copy.complexity);
        if (!self.host.powered || !self.host.hardwareAvailable())
        { value.reason = 'computer-unavailable'; return value; }
        if (self.copy.complexity > self.host.complexity)
        { value.reason = 'program-complexity'; return value; }
        if (value.units > value.capacity - value.used)
        { value.reason = 'computer-capacity'; return value; }
        value.status = 'ready'; return value;
    }
    start()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.boundId = self.id; self.boundHost = self.host; self.boundCopy = self.copy; self.boundComplexity = self.copy.complexity;
        self.active = true; self.startedAt = rpgLedger.seconds; self.host.runs = self.host.runs + [self];
        value.used += value.units; value.status = 'resolved'; self.result = value; return value;
    }
    stop()
    {
        if (self.result == nil) rpgExpandedReject('program-not-started');
        self.validateBinding();
        if (!self.active) return 'reused';
        self.active = nil; self.stoppedAt = rpgLedger.seconds; return 'resolved';
    }
;

/** One ordinary human terminal; connected hosts are explicit, pre-authorized world facts. */
class RpgExpandedTerminal: object
    accessReason(host) { return nil; }
    controller = nil
    hosts = []
    current = nil
    powered = nil
    switches = []
    validate()
    {
        if (self.controller == nil || !self.controller.ofKind(RpgLiteProfile) || self.current == nil
            || !holds(self.hosts,self.current)) rpgExpandedReject('terminal-definition');
        local seen = [];
        foreach (local host in self.hosts)
        {
            if (host == nil || !host.ofKind(RpgExpandedComputer) || holds(seen,host))
                rpgExpandedReject('terminal-hosts');
            seen = seen + [host];
        }
        local ids = [];
        foreach (local request in self.switches)
        {
            if (request == nil || !request.ofKind(RpgExpandedTerminalSwitch) || request.terminal != self
                || request.result == nil || holds(ids,request.id)) rpgExpandedReject('terminal-switch-history');
            request.validateBinding(); ids = ids + [request.id];
        }
        return nil;
    }
;

class RpgExpandedTerminalResult: RpgExpandedResult
    previous = nil
    selected = nil
;

/** A recorded one-second terminal switch; replay does not undo a later selection. */
class RpgExpandedTerminalSwitch: object
    id = nil
    terminal = nil
    target = nil
    evidence = nil
    result = nil
    completedAt = nil
    boundId = nil
    boundTerminal = nil
    boundTarget = nil
    boundOperator = nil
    boundEvidence = nil
    validateBinding()
    {
        if (self.id != self.boundId || self.terminal != self.boundTerminal || self.target != self.boundTarget
            || self.evidence != self.boundEvidence || self.terminal.controller != self.boundOperator
            || !holds(self.terminal.switches,self)) rpgExpandedReject('terminal-switch-binding');
        return nil;
    }
    assess()
    {
        if (self.terminal == nil || !self.terminal.ofKind(RpgExpandedTerminal)) rpgExpandedReject('terminal-switch-definition');
        local value = new RpgExpandedTerminalResult();
        if (self.result != nil)
        {
            self.validateBinding(); value.status = 'reused'; value.previous = self.result.previous;
            value.selected = self.result.selected; return value;
        }
        self.terminal.validate();
        if (self.id == nil || self.id == '') rpgExpandedReject('terminal-switch-id');
        foreach (local prior in self.terminal.switches)
            if (prior.id == self.id) rpgExpandedReject('terminal-switch-duplicate');
        if (self.target == nil || !self.target.ofKind(RpgExpandedComputer) || !holds(self.terminal.hosts,self.target))
        { value.reason = 'terminal-host-not-connected'; return value; }
        if (self.evidence == nil || self.evidence == '')
        { value.reason = 'terminal-switch-evidence'; return value; }
        value.reason = self.terminal.accessReason(self.target); if (value.reason != nil) return value;
        if (!self.terminal.powered || !self.target.powered || self.target.item == nil
            || !self.target.item.ofKind(RpgLiteItem) || !self.target.hardwareAvailable())
        { value.reason = 'terminal-switch-unavailable'; return value; }
        local controller = self.terminal.controller;
        if (controller.dead || controller.unconscious || controller.stunned || controller.hp() <= 0 || controller.fp() <= 0)
        { value.reason = 'terminal-switch-operator-unavailable'; return value; }
        value.previous = self.terminal.current; value.selected = self.target;
        value.seconds = self.terminal.current == self.target ? 0 : 1;
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        if (value.seconds > 0) rpgSpendTime(value.seconds);
        if (self.terminal.accessReason(self.target) != nil) rpgExpandedReject('terminal-service-changed');
        self.terminal.current = self.target;
        self.boundId = self.id; self.boundTerminal = self.terminal; self.boundTarget = self.target;
        self.boundOperator = self.terminal.controller; self.boundEvidence = self.evidence;
        self.completedAt = rpgLedger.seconds; self.terminal.switches = self.terminal.switches + [self];
        value.status = 'resolved'; self.result = value; return value;
    }
;

/** B472 decimal storage units; no implicit rounding of fractional megabytes. */
rpgExpandedStorageMB(amount, unit)
{
    if (!holds(['MB','GB','TB'],unit)) rpgExpandedReject('computer-storage-unit');
    local factor = unit == 'MB' ? 1 : unit == 'GB' ? 1000 : 1000000;
    rpgInteger(amount,0,1000000000 / factor); return amount * factor;
}

modify RpgExpandedComputer
    storageMB = 0
    data = []
    usedStorageMB()
    {
        self.validateHardwareHistory();
        rpgInteger(self.storageMB,0,1000000000);
        local used = 0; local ids = [];
        foreach (local record in self.data)
        {
            if (record == nil || !record.ofKind(RpgExpandedStoredData) || record.host != self
                || record.result == nil || holds(ids,record.id)) rpgExpandedReject('computer-data-history');
            record.validateBinding(); ids = ids + [record.id];
            if (record.present)
            {
                if (record.sizeMB > self.storageMB - used) rpgExpandedReject('computer-storage-overcommitted');
                used += record.sizeMB;
            }
        }
        return used;
    }
;

class RpgExpandedStoredDataResult: RpgExpandedResult
    sizeMB = 0
    usedMB = 0
;

/** An owned fictional data allocation, not a filesystem read or write. */
class RpgExpandedStoredData: object
    id = nil
    host = nil
    reference = nil
    sizeMB = 0
    approved = nil
    evidence = nil
    present = nil
    result = nil
    storedAt = nil
    removedAt = nil
    boundId = nil
    boundHost = nil
    boundReference = nil
    boundSizeMB = nil
    boundEvidence = nil
    validateBinding()
    {
        if (self.id != self.boundId || self.host != self.boundHost || self.reference != self.boundReference
            || self.sizeMB != self.boundSizeMB || self.evidence != self.boundEvidence || !self.approved
            || !holds(self.host.data,self)) rpgExpandedReject('computer-data-binding');
        return nil;
    }
    assess()
    {
        if (self.host == nil || !self.host.ofKind(RpgExpandedComputer)) rpgExpandedReject('computer-data-host');
        local value = new RpgExpandedStoredDataResult();
        if (self.result != nil)
        {
            self.validateBinding(); value.status = 'reused'; value.sizeMB = self.result.sizeMB;
            value.usedMB = self.result.usedMB; return value;
        }
        if (self.id == nil || self.id == '' || self.reference == nil || self.reference == '')
            rpgExpandedReject('computer-data-definition');
        rpgInteger(self.sizeMB,1,1000000000);
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'computer-data-author-facts'; return value; }
        value.usedMB = self.host.usedStorageMB(); value.sizeMB = self.sizeMB;
        foreach (local prior in self.host.data)
            if (prior.id == self.id) rpgExpandedReject('computer-data-duplicate');
        if (!self.host.powered || self.host.item == nil || !self.host.item.ofKind(RpgLiteItem)
            || !self.host.hardwareAvailable())
        { value.reason = 'computer-unavailable'; return value; }
        if (self.sizeMB > self.host.storageMB - value.usedMB)
        { value.reason = 'computer-storage-full'; return value; }
        value.status = 'ready'; return value;
    }
    store()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.boundId = self.id; self.boundHost = self.host; self.boundReference = self.reference;
        self.boundSizeMB = self.sizeMB; self.boundEvidence = self.evidence;
        self.present = true; self.storedAt = rpgLedger.seconds; self.host.data = self.host.data + [self];
        value.usedMB += self.sizeMB; value.status = 'resolved'; self.result = value; return value;
    }
    remove()
    {
        if (self.result == nil) rpgExpandedReject('computer-data-not-stored');
        self.validateBinding();
        if (!self.present) return 'reused';
        if (!self.host.powered || self.host.item == nil || !self.host.item.ofKind(RpgLiteItem)
            || !self.host.hardwareAvailable()) rpgExpandedReject('computer-unavailable');
        self.present = nil; self.removedAt = rpgLedger.seconds; return 'resolved';
    }
;

/** B472 reference data sizes in MB; categories describe authored fictional content. */
rpgExpandedReferenceDataMB(category)
{
    foreach (local row in [['long-text',10],['national-road-map',100],['regional-navigation',1000],
        ['vehicle-plans',1000],['global-navigation',100000],['small-library',100000],
        ['city-library',1000000],['large-library',10000000],['research-library',100000000],['human-mind',100000000]])
        if (row[1] == category) return row[2];
    rpgExpandedReject('computer-data-category');
}

modify RpgExpandedComputer
    links = []
;

/** Fictional connection facts, including current credential and physical availability. */
class RpgExpandedComputerLink: object
    id = nil
    first = nil
    second = nil
    compatible = nil
    mediumAvailable = nil
    addressKnown = nil
    credentialsSatisfied = nil
    evidence = nil
    connected = nil
    result = nil
    connectedAt = nil
    disconnectedAt = nil
    boundId = nil
    boundFirst = nil
    boundSecond = nil
    boundEvidence = nil
    validateBinding()
    {
        if (self.id != self.boundId || self.first != self.boundFirst || self.second != self.boundSecond
            || self.evidence != self.boundEvidence || !holds(self.first.links,self) || !holds(self.second.links,self))
            rpgExpandedReject('computer-link-binding');
        return nil;
    }
    availabilityReason()
    {
        if (self.first == nil || !self.first.ofKind(RpgExpandedComputer)
            || self.second == nil || !self.second.ofKind(RpgExpandedComputer) || self.first == self.second)
            rpgExpandedReject('computer-link-endpoints');
        foreach (local host in [self.first,self.second])
            if (!host.powered || host.item == nil || !host.item.ofKind(RpgLiteItem) || !host.hardwareAvailable())
                return 'computer-link-host-unavailable';
        if (!self.compatible) return 'computer-link-incompatible';
        if (!self.mediumAvailable) return 'computer-link-medium-unavailable';
        if (!self.addressKnown) return 'computer-link-address-unknown';
        if (!self.credentialsSatisfied) return 'computer-link-credentials';
        return nil;
    }
    usable()
    {
        if (self.result == nil || !self.connected) return nil;
        self.validateBinding(); return self.availabilityReason() == nil;
    }
    assess()
    {
        local value = new RpgExpandedResult();
        if (self.result != nil)
        { self.validateBinding(); value.status = 'reused'; return value; }
        if (self.id == nil || self.id == '' || self.evidence == nil || self.evidence == '')
            rpgExpandedReject('computer-link-definition');
        value.reason = self.availabilityReason(); if (value.reason != nil) return value;
        foreach (local host in [self.first,self.second])
            foreach (local prior in host.links)
            {
                if (prior == nil || !prior.ofKind(RpgExpandedComputerLink) || prior.result == nil
                    || prior.first != host && prior.second != host) rpgExpandedReject('computer-link-history');
                prior.validateBinding();
                if (prior.id == self.id) rpgExpandedReject('computer-link-duplicate');
            }
        value.status = 'ready'; return value;
    }
    connect()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.boundId = self.id; self.boundFirst = self.first; self.boundSecond = self.second; self.boundEvidence = self.evidence;
        self.first.links = self.first.links + [self]; self.second.links = self.second.links + [self];
        self.connected = true; self.connectedAt = rpgLedger.seconds;
        value.status = 'resolved'; self.result = value; return value;
    }
    disconnect()
    {
        if (self.result == nil) rpgExpandedReject('computer-link-not-connected');
        self.validateBinding(); if (!self.connected) return 'reused';
        self.connected = nil; self.disconnectedAt = rpgLedger.seconds; return 'resolved';
    }
;

modify RpgExpandedSoftwareCopy
    dataSharing = nil
;

modify RpgExpandedComputerLink
    transfers = []
;

rpgExpandedSharingAvailable(program, host)
{
    if (program == nil || !program.ofKind(RpgExpandedProgramRun) || program.result == nil
        || program.host != host || !program.active) return nil;
    program.validateBinding();
    return program.copy.approved && program.copy.dataSharing && holds(host.copies,program.copy);
}

class RpgExpandedDataTransferResult: RpgExpandedResult
    delivery = nil
;

/** Owned fictional data copy over a live link, using existing processing and storage ledgers. */
class RpgExpandedDataTransfer: object
    id = nil
    dataId = nil
    link = nil
    source = nil
    target = nil
    senderProgram = nil
    receiverProgram = nil
    copyApproved = nil
    uninterrupted = nil
    durationSeconds = nil
    evidence = nil
    result = nil
    boundId = nil
    boundDataId = nil
    boundLink = nil
    boundSource = nil
    boundTarget = nil
    boundSender = nil
    boundReceiver = nil
    boundDuration = nil
    boundEvidence = nil
    assess()
    {
        if (self.link == nil || !self.link.ofKind(RpgExpandedComputerLink)
            || self.source == nil || !self.source.ofKind(RpgExpandedStoredData))
            rpgExpandedReject('data-transfer-definition');
        local value = new RpgExpandedDataTransferResult();
        if (self.result != nil)
        {
            if (self.id != self.boundId || self.dataId != self.boundDataId || self.link != self.boundLink
                || self.source != self.boundSource || self.target != self.boundTarget
                || self.senderProgram != self.boundSender || self.receiverProgram != self.boundReceiver
                || self.durationSeconds != self.boundDuration || self.evidence != self.boundEvidence
                || !self.copyApproved || !self.uninterrupted || !holds(self.link.transfers,self))
                rpgExpandedReject('data-transfer-binding');
            self.result.delivery.validateBinding();
            value.status = 'reused'; value.delivery = self.result.delivery; return value;
        }
        if (self.id == nil || self.id == '' || self.dataId == nil || self.dataId == '')
            rpgExpandedReject('data-transfer-id');
        rpgInteger(self.durationSeconds,0,86400);
        if (!self.copyApproved || !self.uninterrupted || self.evidence == nil || self.evidence == '')
        { value.reason = 'data-transfer-author-facts'; return value; }
        if (!self.link.usable()) { value.reason = 'data-transfer-link-unavailable'; return value; }
        if (self.source.result == nil || !self.source.present)
        { value.reason = 'data-transfer-source-unavailable'; return value; }
        self.source.validateBinding();
        if (!(self.source.host == self.link.first && self.target == self.link.second
            || self.source.host == self.link.second && self.target == self.link.first))
            rpgExpandedReject('data-transfer-endpoints');
        if (!rpgExpandedSharingAvailable(self.senderProgram,self.source.host)
            || !rpgExpandedSharingAvailable(self.receiverProgram,self.target))
        { value.reason = 'data-transfer-software-unavailable'; return value; }
        self.source.host.used(); self.target.used(); self.source.host.usedStorageMB();
        foreach (local prior in self.link.transfers)
        {
            if (prior == nil || !prior.ofKind(RpgExpandedDataTransfer) || prior.link != self.link
                || prior.result == nil || prior.assess().status != 'reused') rpgExpandedReject('data-transfer-history');
            if (prior.id == self.id) rpgExpandedReject('data-transfer-duplicate');
        }
        value.delivery = new RpgExpandedStoredData(); value.delivery.id = self.dataId; value.delivery.host = self.target;
        value.delivery.reference = self.source.reference; value.delivery.sizeMB = self.source.sizeMB;
        value.delivery.approved = true; value.delivery.evidence = self.evidence;
        local allocation = value.delivery.assess();
        if (allocation.status != 'ready') { value.reason = allocation.reason; return value; }
        value.seconds = self.durationSeconds; value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        if (value.seconds > 0) rpgSpendTime(value.seconds);
        local refreshed = self.assess();
        if (refreshed.status != 'ready') rpgExpandedReject('data-transfer-conditions-changed');
        value.delivery = refreshed.delivery;
        local stored = value.delivery.store();
        if (stored.status != 'resolved') rpgExpandedReject('data-transfer-storage-changed');
        self.boundId = self.id; self.boundDataId = self.dataId; self.boundLink = self.link;
        self.boundSource = self.source; self.boundTarget = self.target; self.boundSender = self.senderProgram;
        self.boundReceiver = self.receiverProgram; self.boundDuration = self.durationSeconds; self.boundEvidence = self.evidence;
        self.link.transfers = self.link.transfers + [self]; value.status = 'resolved'; self.result = value; return value;
    }
;

modify RpgExpandedComputer
    microphone = nil
    camera = nil
    recordings = []
;

class RpgExpandedRecordingResult: RpgExpandedResult
    data = nil
;

/** One uninterrupted fictional recording, with explicitly authored duration and storage size. */
class RpgExpandedRecording: object
    id = nil
    dataId = nil
    host = nil
    media = 'audio'
    reference = nil
    sizeMB = 0
    durationSeconds = nil
    uninterrupted = nil
    approved = nil
    evidence = nil
    result = nil
    boundId = nil
    boundDataId = nil
    boundHost = nil
    boundMedia = nil
    boundReference = nil
    boundSize = nil
    boundDuration = nil
    boundEvidence = nil
    assess()
    {
        if (self.host == nil || !self.host.ofKind(RpgExpandedComputer)) rpgExpandedReject('recording-host');
        local value = new RpgExpandedRecordingResult();
        if (self.result != nil)
        {
            if (self.id != self.boundId || self.dataId != self.boundDataId || self.host != self.boundHost
                || self.media != self.boundMedia || self.reference != self.boundReference || self.sizeMB != self.boundSize
                || self.durationSeconds != self.boundDuration || self.evidence != self.boundEvidence
                || !self.uninterrupted || !self.approved || !holds(self.host.recordings,self))
                rpgExpandedReject('recording-binding');
            self.result.data.validateBinding(); value.status = 'reused'; value.data = self.result.data; return value;
        }
        if (self.id == nil || self.id == '' || self.dataId == nil || self.dataId == ''
            || !holds(['audio','video','audio-video'],self.media)) rpgExpandedReject('recording-definition');
        rpgInteger(self.sizeMB,1,1000000000); rpgInteger(self.durationSeconds,1,86400);
        if (!self.approved || !self.uninterrupted || self.evidence == nil || self.evidence == '')
        { value.reason = 'recording-author-facts'; return value; }
        if (self.host.item == nil || !self.host.item.ofKind(RpgLiteItem) || self.host.item.techLevel == nil)
        { value.reason = 'recording-technology-required'; return value; }
        rpgInteger(self.host.item.techLevel,0,12);
        if (self.host.item.techLevel < 8) { value.reason = 'recording-technology-unavailable'; return value; }
        if ((self.media == 'audio' || self.media == 'audio-video') && !self.host.microphone
            || (self.media == 'video' || self.media == 'audio-video') && !self.host.camera)
        { value.reason = 'recording-sensor-unavailable'; return value; }
        foreach (local prior in self.host.recordings)
        {
            if (prior == nil || !prior.ofKind(RpgExpandedRecording) || prior.host != self.host
                || prior.result == nil || prior.assess().status != 'reused') rpgExpandedReject('recording-history');
            if (prior.id == self.id) rpgExpandedReject('recording-duplicate');
        }
        value.data = new RpgExpandedStoredData(); value.data.id = self.dataId; value.data.host = self.host;
        value.data.reference = self.reference; value.data.sizeMB = self.sizeMB;
        value.data.approved = true; value.data.evidence = self.evidence;
        local storage = value.data.assess();
        if (storage.status != 'ready') { value.reason = storage.reason; return value; }
        value.seconds = self.durationSeconds; value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        rpgSpendTime(value.seconds);
        local refreshed = self.assess();
        if (refreshed.status != 'ready') rpgExpandedReject('recording-conditions-changed');
        value.data = refreshed.data;
        if (value.data.store().status != 'resolved') rpgExpandedReject('recording-storage-changed');
        self.boundId = self.id; self.boundDataId = self.dataId; self.boundHost = self.host; self.boundMedia = self.media;
        self.boundReference = self.reference; self.boundSize = self.sizeMB; self.boundDuration = self.durationSeconds;
        self.boundEvidence = self.evidence; self.host.recordings = self.host.recordings + [self];
        value.status = 'resolved'; self.result = value; return value;
    }
;

modify RpgExpandedSoftwareCopy
    terminalClient = nil
    terminalServer = nil
;

/** A remote-terminal service declaration, separate from data-sharing permission. */
class RpgExpandedTerminalConnection: object
    link = nil
    clientProgram = nil
    serverProgram = nil
    reason(localHost, remoteHost)
    {
        if (self.link == nil || !self.link.ofKind(RpgExpandedComputerLink)
            || !(self.link.first == localHost && self.link.second == remoteHost
                || self.link.second == localHost && self.link.first == remoteHost))
            rpgExpandedReject('terminal-connection-endpoints');
        if (!self.link.usable()) return 'terminal-connection-unavailable';
        if (localHost.complexity >= remoteHost.complexity) return 'terminal-remote-complexity-unavailable';
        foreach (local pair in [[self.clientProgram,localHost],[self.serverProgram,remoteHost]])
        {
            local program = pair[1];
            if (program == nil || !program.ofKind(RpgExpandedProgramRun) || program.result == nil
                || program.host != pair[2] || !program.active) return 'terminal-service-not-running';
            program.validateBinding();
            if (!program.copy.approved || !holds(program.host.copies,program.copy))
                return 'terminal-service-not-authorized';
        }
        if (!self.clientProgram.copy.terminalClient || !self.serverProgram.copy.terminalServer)
            return 'terminal-service-capability';
        localHost.used(); remoteHost.used(); return nil;
    }
;

/** Terminal implemented by a weaker local host; every remote operation rechecks live service. */
class RpgExpandedRemoteTerminal: RpgExpandedTerminal
    localHost = nil
    connections = []
    accessReason(host)
    {
        if (!self.powered) return 'terminal-switch-unavailable';
        if (self.localHost == nil || !self.localHost.ofKind(RpgExpandedComputer)
            || !holds(self.hosts,self.localHost)) rpgExpandedReject('remote-terminal-local-host');
        if (!self.localHost.powered || self.localHost.item == nil
            || !self.localHost.item.ofKind(RpgLiteItem) || !self.localHost.hardwareAvailable())
            return 'terminal-local-host-unavailable';
        if (host == self.localHost) return nil;
        local found = nil;
        foreach (local connection in self.connections)
        {
            if (connection == nil || !connection.ofKind(RpgExpandedTerminalConnection)
                || connection.link == nil || !connection.link.ofKind(RpgExpandedComputerLink))
                rpgExpandedReject('remote-terminal-connection');
            if (connection.link.first == self.localHost && connection.link.second == host
                || connection.link.second == self.localHost && connection.link.first == host)
            {
                if (found != nil) rpgExpandedReject('remote-terminal-duplicate-service');
                found = connection;
            }
        }
        return found == nil ? 'terminal-service-unavailable' : found.reason(self.localHost,host);
    }
;

/** B472 usual technical-software baseline; individual tasks may specify a different minimum. */
rpgExpandedRequiredSoftwareComplexity(techLevel)
{
    rpgInteger(techLevel,7,12); return (techLevel - 6) * 2;
}

modify RpgExpandedSoftwareCopy
    taskCapabilities = []
;

/** One approved task-specific equipment contribution, not a permanent skill increase. */
class RpgExpandedSoftwareCapability: object
    taskId = nil
    skill = nil
    equipment = nil
    approved = nil
    evidence = nil
;

class RpgExpandedSoftwareUse: object
    program = nil
    terminal = nil
    taskId = nil
    capability = nil
    assess(profile, skill)
    {
        local value = new RpgExpandedResult();
        if (self.program == nil || !self.program.ofKind(RpgExpandedProgramRun) || self.program.result == nil
            || !self.program.active) { value.reason = 'task-software-not-running'; return value; }
        self.program.validateBinding(); local host = self.program.host;
        if (self.terminal == nil || !self.terminal.ofKind(RpgExpandedTerminal)
            || self.terminal.controller != profile || self.terminal.current != host)
        { value.reason = 'task-software-terminal'; return value; }
        self.terminal.validate();
        if (!self.terminal.powered || !host.powered || host.item == nil || !host.item.ofKind(RpgLiteItem)
            || !host.hardwareAvailable()) { value.reason = 'task-software-unavailable'; return value; }
        value.reason = self.terminal.accessReason(host); if (value.reason != nil) return value;
        if (profile.dead || profile.unconscious || profile.stunned || profile.hp() <= 0 || profile.fp() <= 0)
        { value.reason = 'task-software-operator-unavailable'; return value; }
        if (!self.program.copy.approved || !holds(host.copies,self.program.copy))
        { value.reason = 'task-software-copy'; return value; }
        host.used();
        if (self.capability == nil || !self.capability.ofKind(RpgExpandedSoftwareCapability)
            || !holds(self.program.copy.taskCapabilities,self.capability)
            || self.taskId == nil || self.taskId == '' || self.capability.taskId != self.taskId
            || self.capability.skill != skill)
        { value.reason = 'task-software-scope'; return value; }
        if (!self.capability.approved || self.capability.evidence == nil || self.capability.evidence == '')
        { value.reason = 'task-software-capability-approval'; return value; }
        if (self.capability.equipment == nil || !self.capability.equipment.ofKind(RpgExpandedEquipmentAssessment))
            rpgExpandedReject('task-software-equipment');
        return self.capability.equipment.assess(skill);
    }
;

modify RpgLiteContext
    softwareUse = nil
    equipmentUseModifier(profile)
    {
        if (self.softwareUse == nil) return inherited(profile);
        if (!self.softwareUse.ofKind(RpgExpandedSoftwareUse)) rpgExpandedReject('task-software-context');
        if (self.equipmentAssessment != nil) rpgExpandedReject('task-software-equipment-combination');
        local value = self.softwareUse.assess(profile,self.skill);
        return value.status == 'ready' ? value.modifier : nil;
    }
    unavailableReason(profile)
    {
        if (self.softwareUse != nil)
        {
            if (!self.softwareUse.ofKind(RpgExpandedSoftwareUse)) rpgExpandedReject('task-software-context');
            local value = self.softwareUse.assess(profile,self.skill);
            if (value.status != 'ready') return value.reason;
        }
        return inherited(profile);
    }
;


class RpgExpandedSoftwareRequirementResult: RpgExpandedResult
    effectiveTL = nil
    softwareAvailable = nil
    softwareReason = nil
;

/** Authored task-specific technical prerequisite and explicit lower-technology fallback. */
class RpgExpandedSoftwareRequirement: object
    taskId = nil
    skill = nil
    minimumComplexity = nil
    fallbackTL = nil
    use = nil
    approved = nil
    evidence = nil
    assess(profile, subject)
    {
        local value = new RpgExpandedSoftwareRequirementResult();
        if (subject == nil || !subject.ofKind(RpgLiteSkill) || subject.techLevel == nil
            || self.skill != subject || self.taskId == nil || self.taskId == '')
            rpgExpandedReject('software-requirement-scope');
        rpgInteger(subject.techLevel,7,12);
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'software-requirement-approval'; return value; }
        local minimum = self.minimumComplexity == nil
            ? rpgExpandedRequiredSoftwareComplexity(subject.techLevel) : self.minimumComplexity;
        rpgInteger(minimum,0,12);
        if (self.fallbackTL != nil) rpgInteger(self.fallbackTL,0,subject.techLevel-1);
        value.softwareReason = 'required-software-missing';
        if (self.use != nil)
        {
            if (!self.use.ofKind(RpgExpandedSoftwareUse) || self.use.taskId != self.taskId)
                rpgExpandedReject('software-requirement-use');
            local support = self.use.assess(profile,subject);
            value.softwareReason = support.reason;
            if (support.status == 'ready')
            {
                if (self.use.program.copy.complexity >= minimum)
                { value.softwareAvailable = true; value.softwareReason = nil; }
                else value.softwareReason = 'required-software-complexity';
            }
        }
        value.effectiveTL = value.softwareAvailable ? subject.techLevel : self.fallbackTL;
        if (value.effectiveTL == nil) { value.reason = value.softwareReason; return value; }
        value.status = 'ready'; return value;
    }
;

modify RpgLiteContext
    softwareRequirement = nil
    softwareTechnologyEnabled = nil
    technologyUnavailableReason(profile)
    {
        if (self.softwareRequirement != nil)
        {
            if (!self.softwareRequirement.ofKind(RpgExpandedSoftwareRequirement))
                rpgExpandedReject('software-requirement');
            local value = self.softwareRequirement.assess(profile,self.skill);
            if (value.status != 'ready') return value.reason;
        }
        return 'technology-too-advanced';
    }
    technologySkillLevel(profile)
    {
        if (self.softwareRequirement == nil) return self.skill == nil ? nil : self.skill.techLevel;
        if (!self.softwareTechnologyEnabled) rpgExpandedReject('software-requirement-context');
        if (self.equipmentTL == nil) rpgExpandedReject('software-requirement-task-technology');
        if (!self.softwareRequirement.ofKind(RpgExpandedSoftwareRequirement))
            rpgExpandedReject('software-requirement');
        local value = self.softwareRequirement.assess(profile,self.skill);
        return value.status == 'ready' ? value.effectiveTL : nil;
    }
    equipmentUseModifier(profile)
    {
        if (self.softwareRequirement != nil)
        {
            if (!self.softwareTechnologyEnabled) rpgExpandedReject('software-requirement-context');
            if (!self.softwareRequirement.ofKind(RpgExpandedSoftwareRequirement))
                rpgExpandedReject('software-requirement');
            if (self.softwareUse != nil && self.softwareUse != self.softwareRequirement.use)
                rpgExpandedReject('software-requirement-bonus-source');
            local value = self.softwareRequirement.assess(profile,self.skill);
            if (value.status != 'ready') return nil;
        }
        return inherited(profile);
    }
;

/** Purchase one host-bound copy through the shared money and inventory ledger.
 * item is the authored documentation/license package; no per-instance charge. */
class RpgExpandedSoftwarePurchase: RpgExpandedAcquisition
    copy = nil
    evidence = nil
    boundCopy = nil
    boundHost = nil
    boundId = nil
    boundComplexity = nil
    boundEvidence = nil
    boundQuote = nil
    assess()
    {
        if (self.copy == nil || !self.copy.ofKind(RpgExpandedSoftwareCopy)
            || self.copy.host == nil || !self.copy.host.ofKind(RpgExpandedComputer))
            rpgExpandedReject('software-purchase-copy');
        if (self.mode != 'purchase' || self.startingPurchase)
            rpgExpandedReject('software-purchase-mode');
        if (self.claimed)
        {
            if (self.copy != self.boundCopy || self.copy.host != self.boundHost
                || self.copy.id != self.boundId || self.copy.complexity != self.boundComplexity
                || self.evidence != self.boundEvidence || self.quote != self.boundQuote)
                rpgExpandedReject('software-purchase-binding');
            return inherited();
        }
        local value = new RpgExpandedAcquisitionResult(); value.item = self.item;
        if (self.copy.id == nil || self.copy.id == '') rpgExpandedReject('software-purchase-id');
        rpgInteger(self.copy.complexity,0,8);
        if (self.evidence == nil || self.evidence == '' || !self.copy.approved
            || self.copy.evidence == nil || self.copy.evidence == '')
        { value.reason = 'software-purchase-author-facts'; return value; }
        foreach (local installed in self.copy.host.copies)
        {
            if (installed == nil || !installed.ofKind(RpgExpandedSoftwareCopy))
                rpgExpandedReject('software-purchase-host-copies');
            if (installed == self.copy || installed.id == self.copy.id)
            { value.reason = 'software-copy-already-installed'; return value; }
        }
        for (local host = firstObj(RpgExpandedComputer); host != nil; host = nextObj(host,RpgExpandedComputer))
            if (host != self.copy.host && holds(host.copies,self.copy))
                rpgExpandedReject('software-copy-multiple-hosts');
        return inherited();
    }
    acquire()
    {
        local value = inherited();
        if (value.status != 'resolved') return value;
        self.copy.host.copies = self.copy.host.copies + [self.copy];
        self.boundCopy = self.copy; self.boundHost = self.copy.host; self.boundId = self.copy.id;
        self.boundComplexity = self.copy.complexity; self.boundEvidence = self.evidence;
        self.boundQuote = self.quote; return value;
    }
;

/** Guidance categories, not minimum skill prerequisites, full-2008 B473. */
rpgExpandedInventionPriceCategory(price)
{
    rpgInteger(price,0,100000000);
    return price <= 100 ? 'simple' : price <= 10000 ? 'average' : price <= 1000000 ? 'complex' : 'amazing';
}
rpgExpandedInventionSkillCategory(score)
{
    rpgInteger(score,1,1000);
    return score <= 14 ? 'simple' : score <= 17 ? 'average' : score <= 20 ? 'complex' : 'amazing';
}
rpgExpandedInventionSoftwareCategory(complexity)
{
    rpgInteger(complexity,1,12);
    return complexity <= 3 ? 'simple' : complexity <= 5 ? 'average' : complexity <= 7 ? 'complex' : 'amazing';
}

class RpgExpandedInventionProposalResult: RpgExpandedResult
    skillScore = nil
    category = nil
    conceptModifier = 0
    facilitiesCost = 0
    attemptCost = 0
;

/** Approved realistic proposal. Classification hints never replace author approval. */
class RpgExpandedInventionProposal: object
    inventor = nil
    skill = nil
    relatedSkills = []
    description = nil
    mechanism = nil
    evidence = nil
    approved = nil
    techLevel = nil
    category = nil
    softwareComplexity = nil
    retailPrice = nil
    descriptionBonus = 0
    relatedFacilities = nil
    technologyPermissionReason()
    { return self.techLevel > self.inventor.techLevel + 1 ? 'invention-technology-too-advanced' : nil; }
    finalizeAssessment(value) { return value; }
    noveltyModifier(campaignNew) { return campaignNew ? -5 : 0; }
    prototypeExecutionReason() { return nil; }
    conceptRequestReason(request) { return nil; }
    prototypeBugDiceCount(check, flawed)
    { return flawed || !check.achieved || check.critical == 'success' ? 0 : check.margin >= 3 ? 1 : 2; }
    prototypeOutcome(score, roll, flawed, dice)
    { return rpgExpandedPrototypeOutcome(score,roll,flawed,dice); }
    productionPrice() { return self.retailPrice; }
    prototypeToolsPenalty(penalty) { rpgInteger(penalty,0,10); return penalty; }
    paidScore(subject)
    {
        if (subject == nil || !subject.ofKind(RpgSkill)) rpgExpandedReject('invention-skill');
        local trained = nil;
        foreach (local training in self.inventor.skills)
            if (training.skill == subject && training.points > 0) trained = true;
        return trained ? self.inventor.skillScore(subject) : nil;
    }
    assess()
    {
        if (self.inventor == nil || !self.inventor.ofKind(RpgLiteProfile))
            rpgExpandedReject('invention-inventor');
        local value = new RpgExpandedInventionProposalResult();
        if (!self.approved || self.description == nil || self.description == ''
            || self.mechanism == nil || self.mechanism == '' || self.evidence == nil || self.evidence == '')
        { value.reason = 'invention-proposal-approval'; return value; }
        rpgInteger(self.techLevel,0,12); rpgInteger(self.inventor.techLevel,0,12);
        rpgInteger(self.retailPrice,0,100000000); rpgInteger(self.descriptionBonus,0,2);
        value.reason = self.technologyPermissionReason(); if (value.reason != nil) return value;
        local categories = ['simple','average','complex','amazing'];
        local selected = self.category;
        if (self.softwareComplexity != nil)
        {
            if (selected != nil) rpgExpandedReject('invention-complexity-source');
            selected = rpgExpandedInventionSoftwareCategory(self.softwareComplexity);
            if (self.techLevel < self.inventor.techLevel)
            { value.reason = 'invention-software-historical-complexity-unresolved'; return value; }
        }
        if (!holds(categories,selected)) rpgExpandedReject('invention-category');
        local index = 1;
        while (categories[index] != selected) index += 1;
        if (self.softwareComplexity == nil && self.techLevel < self.inventor.techLevel)
        {
            index -= self.inventor.techLevel - self.techLevel;
            if (index < 1) index = 1;
        }
        value.category = categories[index]; value.skillScore = self.paidScore(self.skill);
        if (value.skillScore == nil) { value.reason = 'invention-skill-not-trained'; return value; }
        local seen = [self.skill];
        foreach (local related in self.relatedSkills)
        {
            if (holds(seen,related)) rpgExpandedReject('invention-duplicate-skill');
            seen = seen + [related]; local score = self.paidScore(related);
            if (score == nil) { value.reason = 'invention-related-skill-not-trained'; return value; }
            if (score < value.skillScore) value.skillScore = score;
        }
        local penalties = [-6,-10,-14,-22]; local facilities = [50000,100000,250000,500000];
        value.conceptModifier = (self.softwareComplexity == nil ? penalties[index] : -2*self.softwareComplexity)
            + self.descriptionBonus;
        value.facilitiesCost = facilities[index]; value.attemptCost = self.retailPrice;
        if (self.techLevel > self.inventor.techLevel)
        {
            value.conceptModifier -= 5; value.facilitiesCost *= 3; value.attemptCost *= 3;
        }
        if (self.relatedFacilities) value.facilitiesCost /= 10;
        value.status = 'ready'; return self.finalizeAssessment(value);
    }
;

modify RpgExpandedInventionProposal
    definition()
    {
        return [self.inventor,self.skill,self.description,self.mechanism,self.evidence,self.approved,
            self.techLevel,self.category,self.softwareComplexity,self.retailPrice,self.descriptionBonus,
            self.relatedFacilities] + self.relatedSkills;
    }
;

class RpgExpandedInventionProject: object
    proposal = nil
    attempts = []
    theory = nil
    definitionSnapshot = nil
    validate()
    {
        if (self.proposal == nil || !self.proposal.ofKind(RpgExpandedInventionProposal))
            rpgExpandedReject('invention-project-proposal');
        if (self.definitionSnapshot == nil) return nil;
        local current = self.proposal.definition();
        if (current.length() != self.definitionSnapshot.length()) rpgExpandedReject('invention-project-retargeted');
        for (local index = 1; index <= current.length(); index += 1)
            if (current[index] != self.definitionSnapshot[index]) rpgExpandedReject('invention-project-retargeted');
        return nil;
    }
;

modify RpgLiteProfile
    inventionConceptAttempts = []
;

class RpgExpandedInventionConceptResult: RpgExpandedResult
    day = nil
    theory = nil
    score = nil
;

/** Secret concept receipt. Authors decide what the inventor learns; no public event is emitted. */
class RpgExpandedInventionConcept: object
    dailyLimited = true
    prepareExecution(value) { return value; }
    id = nil
    project = nil
    knowledge = 'new'
    variantBonus = 0
    campaignNew = nil
    historicalSources = nil
    researchSkill = nil
    evidence = nil
    result = nil
    boundDefinition = nil
    definition()
    { return [self.id,self.project,self.knowledge,self.variantBonus,self.campaignNew,self.historicalSources,self.researchSkill,self.evidence,self.dailyLimited]; }
    validateBinding()
    {
        local current = self.definition();
        if (self.boundDefinition == nil || current.length() != self.boundDefinition.length())
            rpgExpandedReject('invention-concept-binding');
        for (local index = 1; index <= current.length(); index += 1)
            if (current[index] != self.boundDefinition[index]) rpgExpandedReject('invention-concept-binding');
        self.project.validate();
        if (!holds(self.project.attempts,self) || !holds(self.project.proposal.inventor.inventionConceptAttempts,self))
            rpgExpandedReject('invention-concept-history');
    }
    assess()
    {
        if (self.project == nil || !self.project.ofKind(RpgExpandedInventionProject))
            rpgExpandedReject('invention-concept-project');
        self.project.validate();
        local value = new RpgExpandedInventionConceptResult();
        if (self.result != nil)
        {
            self.validateBinding(); value.status = 'reused'; value.check = self.result.check;
            value.theory = self.result.theory; value.day = self.result.day; value.score = self.result.score;
            value.seconds = self.result.seconds; return value;
        }
        if (self.id == nil || self.id == '' || !holds(['new','exists','model'],self.knowledge))
            rpgExpandedReject('invention-concept-definition');
        rpgInteger(self.variantBonus,0,5);
        if (self.evidence == nil || self.evidence == '')
        { value.reason = 'invention-concept-evidence'; return value; }
        local proposal = self.project.proposal; local inventor = proposal.inventor;
        value.reason = proposal.conceptRequestReason(self); if (value.reason != nil) return value;
        local assessment = proposal.assess();
        if (assessment.status != 'ready') { value.reason = assessment.reason; return value; }
        if (self.project.theory != nil) { value.reason = 'invention-theory-already-held'; return value; }
        if (inventor.dead || inventor.unconscious || inventor.stunned || inventor.hp() <= 0 || inventor.fp() <= 0)
        { value.reason = 'invention-inventor-unavailable'; return value; }
        value.day = rpgLedger.seconds / 86400;
        foreach (local prior in inventor.inventionConceptAttempts)
        {
            if (prior == nil || !prior.ofKind(RpgExpandedInventionConcept) || prior.result == nil)
                rpgExpandedReject('invention-concept-history');
            prior.validateBinding();
            if (prior.id == self.id) rpgExpandedReject('invention-concept-duplicate');
            if (self.dailyLimited && prior.dailyLimited && prior.result.day == value.day)
            { value.reason = 'invention-concept-day-used'; return value; }
        }
        local base = assessment.skillScore;
        if (self.historicalSources)
        {
            if (proposal.techLevel >= inventor.techLevel) rpgExpandedReject('invention-historical-context');
            if (self.researchSkill == nil || !self.researchSkill.ofKind(RpgLiteSkill) || self.researchSkill.id != 'research')
                rpgExpandedReject('invention-research-skill');
            local research = inventor.skillScore(self.researchSkill);
            if (research == nil) { value.reason = 'invention-research-unavailable'; return value; }
            if (research > base) base = research;
            foreach (local related in proposal.relatedSkills)
            { local score = proposal.paidScore(related); if (score < base) base = score; }
        }
        value.modifier = assessment.conceptModifier + (self.knowledge == 'model' ? 5 : self.knowledge == 'exists' ? 2 : 0)
            + self.variantBonus + proposal.noveltyModifier(self.campaignNew);
        value.score = base + value.modifier; rpgInteger(value.score,-1000,1000);
        if (value.score < 3) { value.reason = 'too-difficult'; return value; }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        value = self.prepareExecution(value);
        value.check = rpgCheck(value.score,rpgRandom.roll());
        value.theory = value.check.achieved ? 'testable' : value.check.critical == 'failure' ? 'flawed' : nil;
        self.boundDefinition = self.definition();
        if (self.project.definitionSnapshot == nil) self.project.definitionSnapshot = self.project.proposal.definition();
        self.project.attempts = self.project.attempts + [self];
        local inventor = self.project.proposal.inventor;
        inventor.inventionConceptAttempts = inventor.inventionConceptAttempts + [self];
        self.project.theory = value.theory; value.status = 'resolved'; self.result = value; return value;
    }
;

class RpgExpandedPrototypeDuration: object
    numerator = 0
    denominator = 1
    unit = 'days'
    minimumDays = 1
;

/** Supplied dice preserve preview purity; months remain authored calendar units. */
rpgExpandedPrototypeDuration(category, dice, workers)
{
    if (!holds(['simple','average','complex','amazing'],category)) rpgExpandedReject('prototype-category');
    rpgInteger(workers,1,1000000);
    local count = category == 'average' ? 2 : category == 'amazing' ? 3 : 1;
    if (dice.length() != count) rpgExpandedReject('prototype-duration-dice');
    local total = 0;
    foreach (local die in dice) { rpgInteger(die,1,6); total += die; }
    local value = new RpgExpandedPrototypeDuration(); value.denominator = workers;
    value.unit = category == 'simple' || category == 'average' ? 'days' : 'months';
    if (category == 'simple') total -= 2;
    if (value.unit == 'days' && total < workers) total = workers;
    value.numerator = total; return value;
}

class RpgExpandedPrototypeOutcome: RpgExpandedResult
    working = nil
    revealedFlaw = nil
    accident = nil
    minimumDamageDice = 0
    facilitiesDestroyed = nil
    majorBugs = 0
    minorBugs = 0
;

/** Secret result assessment, B474; no damage, purchases or calendar advancement. */
rpgExpandedPrototypeOutcome(score, roll, flawed, bugDice)
{
    local value = new RpgExpandedPrototypeOutcome(); value.check = rpgCheck(score,roll);
    if (value.check.status != 'resolved')
    {
        if (bugDice.length() != 0) rpgExpandedReject('prototype-unused-bug-dice');
        value.reason = value.check.reason; return value;
    }
    value.status = 'resolved';
    if (value.check.critical == 'failure')
    { value.accident = true; value.minimumDamageDice = 2; value.facilitiesDestroyed = true; }
    if (flawed)
    { value.revealedFlaw = value.check.critical == 'success'; }
    else if (value.check.achieved) value.working = true;
    local count = !value.working || value.check.critical == 'success' ? 0 : value.check.margin >= 3 ? 1 : 2;
    if (bugDice.length() != count) rpgExpandedReject('prototype-bug-dice');
    foreach (local die in bugDice) rpgInteger(die,1,6);
    if (count == 1) value.minorBugs = bugDice[1] / 2;
    if (count == 2) { value.majorBugs = bugDice[1] / 2; value.minorBugs = bugDice[2]; }
    return value;
}

/** B474 assistants contribute at most four; tool shortcomings are an authored penalty. */
rpgExpandedPrototypeTeamModifier(proposal, assistants, toolsPenalty)
{
    if (proposal == nil || !proposal.ofKind(RpgExpandedInventionProposal)) rpgExpandedReject('prototype-proposal');
    rpgInteger(toolsPenalty,0,10);
    local seen = [proposal.inventor]; local bonus = 0;
    foreach (local assistant in assistants)
    {
        if (assistant == nil || !assistant.ofKind(RpgLiteProfile) || holds(seen,assistant))
            rpgExpandedReject('prototype-assistant');
        seen = seen + [assistant]; local qualifies = nil;
        foreach (local subject in [proposal.skill] + proposal.relatedSkills)
        {
            local trained = nil;
            foreach (local training in assistant.skills)
                if (training.skill == subject && training.points > 0) trained = true;
            local score = trained ? assistant.skillScore(subject) : nil;
            if (score != nil && score >= 20) qualifies = true;
        }
        if (qualifies && bonus < 4) bonus += 1;
    }
    return bonus - proposal.prototypeToolsPenalty(toolsPenalty);
}

modify RpgExpandedInventionProject
    facilities = nil
    facilityFunding = []
;

class RpgExpandedInventionFundingResult: RpgExpandedResult
    fullCost = 0
    money = 0
    rebuilt = nil
;

/** One inventor's facilities payment, separate from every prototype's retail cost. */
class RpgExpandedInventionFacilities: object
    project = nil
    payer = nil
    approved = nil
    evidence = nil
    destroyed = nil
    result = nil
    boundProject = nil
    boundPayer = nil
    boundEvidence = nil
    predecessor = nil
    assess()
    {
        if (self.project == nil || !self.project.ofKind(RpgExpandedInventionProject)
            || self.payer == nil || !self.payer.ofKind(RpgExpandedProfile))
            rpgExpandedReject('invention-facilities-definition');
        self.project.validate(); local value = new RpgExpandedInventionFundingResult();
        if (self.result != nil)
        {
            if (self.project != self.boundProject || self.payer != self.boundPayer
                || self.evidence != self.boundEvidence || !holds(self.project.facilityFunding,self))
                rpgExpandedReject('invention-facilities-binding');
            value.status = 'reused'; value.rebuilt = self.result.rebuilt; value.fullCost = self.result.fullCost; return value;
        }
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'invention-facilities-approval'; return value; }
        rpgExpandedValidate(self.payer); rpgInteger(self.payer.money,0,2147483647);
        if (!holds(['testable','flawed'],self.project.theory))
        { value.reason = 'invention-facilities-theory-required'; return value; }
        value.reason = self.project.proposal.prototypeExecutionReason(); if (value.reason != nil) return value;
        local prior = self.project.facilities;
        if (prior != nil)
        {
            if (!prior.ofKind(RpgExpandedInventionFacilities) || prior.result == nil || prior.project != self.project)
                rpgExpandedReject('invention-facilities-history');
            prior.assess();
            if (!prior.destroyed) { value.reason = 'invention-facilities-already-funded'; return value; }
            value.rebuilt = true;
        }
        local proposal = self.project.proposal; local assessment = proposal.assess();
        if (assessment.status != 'ready') { value.reason = assessment.reason; return value; }
        value.fullCost = value.rebuilt ? prior.result.fullCost
            : assessment.facilitiesCost * (proposal.relatedFacilities ? 10 : 1);
        // A destroyed installation must be rebuilt at its original full cost.
        value.money = value.rebuilt ? value.fullCost : assessment.facilitiesCost;
        if (self.payer.money < value.money)
        { value.reason = 'invention-facilities-funds'; value.money = 0; return value; }
        value.status = 'ready'; return value;
    }
    fund()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.payer.money -= value.money;
        if (self.project.definitionSnapshot == nil) self.project.definitionSnapshot = self.project.proposal.definition();
        self.boundProject = self.project; self.boundPayer = self.payer; self.boundEvidence = self.evidence;
        self.predecessor = self.project.facilities;
        self.project.facilities = self; self.project.facilityFunding = self.project.facilityFunding + [self];
        value.status = 'resolved'; self.result = value; return value;
    }
;

modify RpgExpandedInventionProject
    blueprintEntry = nil
;

/** Acquired actual blueprints authorize prototype work without a concept attempt, B473. */
class RpgExpandedInventionBlueprint: object
    project = nil
    reference = nil
    acquired = nil
    actualDesign = nil
    approved = nil
    evidence = nil
    result = nil
    boundProject = nil
    boundReference = nil
    boundEvidence = nil
    assess()
    {
        if (self.project == nil || !self.project.ofKind(RpgExpandedInventionProject))
            rpgExpandedReject('invention-blueprint-project');
        self.project.validate(); local value = new RpgExpandedResult();
        if (self.result != nil)
        {
            if (self.project != self.boundProject || self.reference != self.boundReference
                || self.evidence != self.boundEvidence || self.project.blueprintEntry != self)
                rpgExpandedReject('invention-blueprint-binding');
            value.status = 'reused'; return value;
        }
        if (!self.acquired || !self.actualDesign || !self.approved || self.reference == nil
            || self.reference == '' || self.evidence == nil || self.evidence == '')
        { value.reason = 'invention-blueprint-author-facts'; return value; }
        if (self.project.theory != nil || self.project.blueprintEntry != nil)
        { value.reason = 'invention-theory-already-held'; return value; }
        local proposal = self.project.proposal.assess();
        if (proposal.status != 'ready') { value.reason = proposal.reason; return value; }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        if (self.project.definitionSnapshot == nil) self.project.definitionSnapshot = self.project.proposal.definition();
        self.project.theory = 'testable'; self.project.blueprintEntry = self;
        self.boundProject = self.project; self.boundReference = self.reference; self.boundEvidence = self.evidence;
        value.status = 'resolved'; self.result = value; return value;
    }
;

modify RpgExpandedInventionProject
    prototypes = []
    activePrototype = nil
;

class RpgExpandedPrototypeStartResult: RpgExpandedResult
    money = 0
    durationDice = []
    duration = nil
;

/** Fund and size one prototype attempt; work advancement and secret completion are separate. */
class RpgExpandedPrototypeStart: object
    id = nil
    project = nil
    payer = nil
    assistants = []
    toolsPenalty = 0
    approved = nil
    evidence = nil
    /* Exact whole-day lengths of successive months beginning at this project's work origin. */
    monthDays = []
    calendarEvidence = nil
    extraSeconds = 0
    result = nil
    facilities = nil
    definitionSnapshot = nil
    startedAt = nil
    workedSeconds = 0
    definition()
    {
        return [self.id,self.project,self.payer,self.toolsPenalty,self.evidence,self.calendarEvidence,
            self.extraSeconds,self.assistants.length(),self.monthDays.length()] + self.assistants + self.monthDays;
    }
    assess()
    {
        if (self.project == nil || !self.project.ofKind(RpgExpandedInventionProject)
            || self.payer == nil || !self.payer.ofKind(RpgExpandedProfile))
            rpgExpandedReject('prototype-start-definition');
        self.project.validate(); local value = new RpgExpandedPrototypeStartResult();
        if (self.result != nil)
        {
            local current = self.definition();
            if (current.length() != self.definitionSnapshot.length()) rpgExpandedReject('prototype-start-binding');
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.definitionSnapshot[index]) rpgExpandedReject('prototype-start-binding');
            if (!holds(self.project.prototypes,self)) rpgExpandedReject('prototype-start-history');
            value.status = 'reused'; value.seconds = self.result.seconds;
            value.duration = self.result.duration; value.durationDice = self.result.durationDice; return value;
        }
        if (self.id == nil || self.id == '') rpgExpandedReject('prototype-start-id');
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'prototype-start-approval'; return value; }
        if (!holds(['testable','flawed'],self.project.theory))
        { value.reason = 'prototype-theory-required'; return value; }
        value.reason = self.project.proposal.prototypeExecutionReason(); if (value.reason != nil) return value;
        if (self.project.activePrototype != nil) { value.reason = 'prototype-already-active'; return value; }
        if (self.project.workingPrototype != nil) { value.reason = 'prototype-already-created'; return value; }
        foreach (local prior in self.project.prototypes)
            if (prior.id == self.id) rpgExpandedReject('prototype-start-duplicate');
        local facility = self.project.facilities;
        if (facility == nil || !facility.ofKind(RpgExpandedInventionFacilities) || facility.result == nil
            || facility.project != self.project || facility.destroyed)
        { value.reason = 'prototype-facilities-required'; return value; }
        facility.assess(); rpgExpandedValidate(self.payer); rpgInteger(self.payer.money,0,2147483647);
        local proposal = self.project.proposal; local assessment = proposal.assess();
        if (assessment.status != 'ready') { value.reason = assessment.reason; return value; }
        value.modifier = rpgExpandedPrototypeTeamModifier(proposal,self.assistants,self.toolsPenalty);
        foreach (local participant in [proposal.inventor] + self.assistants)
        {
            if (participant.dead || participant.unconscious || participant.stunned || participant.hp() <= 0 || participant.fp() <= 0)
            { value.reason = 'prototype-participant-unavailable'; return value; }
            local trained = nil;
            foreach (local subject in [proposal.skill] + proposal.relatedSkills)
                foreach (local training in participant.skills)
                    if (training.skill == subject && training.points > 0) trained = true;
            if (!trained) { value.reason = 'prototype-worker-unskilled'; return value; }
        }
        rpgInteger(self.extraSeconds,0,31536000);
        if (holds(['complex','amazing'],assessment.category))
        {
            local count = assessment.category == 'complex' ? 6 : 18;
            if (self.monthDays.length() != count || self.calendarEvidence == nil || self.calendarEvidence == '')
            { value.reason = 'prototype-calendar-required'; return value; }
            foreach (local days in self.monthDays) rpgInteger(days,1,40);
        }
        else if (self.monthDays.length() != 0) rpgExpandedReject('prototype-unused-calendar');
        if (self.payer.money < assessment.attemptCost) { value.reason = 'prototype-attempt-funds'; return value; }
        value.money = assessment.attemptCost;
        value.duration = assessment.category; value.status = 'ready'; return value;
    }
    begin()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local count = value.duration == 'average' ? 2 : value.duration == 'amazing' ? 3 : 1;
        for (local index = 1; index <= count; index += 1) value.durationDice = value.durationDice + [rpgRandom.die()];
        value.duration = rpgExpandedPrototypeDuration(value.duration,value.durationDice,self.assistants.length()+1);
        local days = value.duration.numerator;
        if (value.duration.unit == 'months')
        {
            days = 0;
            for (local index = 1; index <= value.duration.numerator; index += 1) days += self.monthDays[index];
        }
        value.seconds = days * 86400 / value.duration.denominator;
        if (value.seconds < 86400) value.seconds = 86400;
        value.seconds += self.extraSeconds;
        self.payer.money -= value.money;
        self.facilities = self.project.facilities; self.startedAt = rpgLedger.seconds;
        self.definitionSnapshot = self.definition(); self.project.prototypes = self.project.prototypes + [self];
        self.project.activePrototype = self; value.status = 'resolved'; self.result = value; return value;
    }
;

modify RpgExpandedPrototypeStart
    workIntervals = []
    workReason()
    {
        if (self.result == nil) return 'prototype-not-started';
        self.assess();
        local permission = self.project.proposal.prototypeExecutionReason();
        if (permission != nil) return permission;
        if (self.project.activePrototype != self) return 'prototype-not-active';
        if (self.facilities == nil || self.project.facilities != self.facilities || self.facilities.destroyed)
            return 'prototype-facilities-required';
        self.facilities.assess();
        foreach (local participant in [self.project.proposal.inventor] + self.assistants)
        {
            if (participant.dead || participant.unconscious || participant.stunned || participant.hp() <= 0 || participant.fp() <= 0)
                return 'prototype-participant-unavailable';
            local trained = nil;
            foreach (local subject in [self.project.proposal.skill] + self.project.proposal.relatedSkills)
                foreach (local training in participant.skills)
                    if (training.skill == subject && training.points > 0) trained = true;
            if (!trained) return 'prototype-worker-unskilled';
        }
        return nil;
    }
;

class RpgExpandedPrototypeWork: object
    id = nil
    attempt = nil
    seconds = 0
    uninterrupted = nil
    approved = nil
    evidence = nil
    result = nil
    boundId = nil
    boundAttempt = nil
    boundSeconds = nil
    boundEvidence = nil
    startedAt = nil
    endedAt = nil
    assess()
    {
        if (self.attempt == nil || !self.attempt.ofKind(RpgExpandedPrototypeStart))
            rpgExpandedReject('prototype-work-attempt');
        local value = new RpgExpandedResult();
        if (self.result != nil)
        {
            if (self.id != self.boundId || self.attempt != self.boundAttempt || self.seconds != self.boundSeconds
                || self.evidence != self.boundEvidence || !holds(self.attempt.workIntervals,self))
                rpgExpandedReject('prototype-work-binding');
            self.attempt.assess(); value.status = 'reused'; return value;
        }
        if (self.id == nil || self.id == '') rpgExpandedReject('prototype-work-id');
        rpgInteger(self.seconds,1,86400);
        if (!self.approved || !self.uninterrupted || self.evidence == nil || self.evidence == '')
        { value.reason = 'prototype-work-author-facts'; return value; }
        value.reason = self.attempt.workReason(); if (value.reason != nil) return value;
        rpgInteger(self.attempt.workedSeconds,0,self.attempt.result.seconds);
        foreach (local prior in self.attempt.workIntervals)
        {
            if (prior == nil || !prior.ofKind(RpgExpandedPrototypeWork) || prior.result == nil || prior.attempt != self.attempt)
                rpgExpandedReject('prototype-work-history');
            if (prior.id == self.id) rpgExpandedReject('prototype-work-duplicate');
        }
        if (self.seconds > self.attempt.result.seconds - self.attempt.workedSeconds)
        { value.reason = 'prototype-work-exceeds-remaining'; return value; }
        value.seconds = self.seconds; value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local previous = self.attempt.workedSeconds; local start = rpgLedger.seconds;
        rpgSpendTime(value.seconds);
        local refreshed = self.assess();
        if (refreshed.status != 'ready' || self.attempt.workedSeconds != previous
            || rpgLedger.seconds != start + value.seconds)
            rpgExpandedReject('prototype-work-conditions-changed');
        self.attempt.workedSeconds += value.seconds;
        self.boundId = self.id; self.boundAttempt = self.attempt; self.boundSeconds = self.seconds; self.boundEvidence = self.evidence;
        self.startedAt = start; self.endedAt = rpgLedger.seconds;
        self.attempt.workIntervals = self.attempt.workIntervals + [self];
        value.status = 'resolved'; self.result = value; return value;
    }
;

class RpgExpandedPrototypeAccidentTarget: object
    id = nil
    profile = nil
    dice = 2
    damageType = 'cr'
    protection = 0
    divisor = 1
    destination = nil
    definition() { return [self.id,self.profile,self.dice,self.damageType,self.protection,self.divisor,self.destination]; }
    prepare(raw)
    {
        local amount = rpgLitePenetration(raw,self.protection,self.divisor,self.damageType,nil);
        return self.profile.prepareTechnologyWound(self.id,amount,self.destination);
    }
;

class RpgExpandedPrototypeAccidentResult: RpgExpandedResult
    damage = []
    wounds = []
;

/** Explicit authored accident severity and protection; all participants must be covered. */
class RpgExpandedPrototypeAccident: object
    attempt = nil
    outcome = nil
    targets = []
    approved = nil
    evidence = nil
    result = nil
    definitionSnapshot = nil
    definition()
    {
        local value = [self.attempt,self.outcome,self.evidence,self.targets.length()];
        foreach (local target in self.targets) value = value + [target] + target.definition();
        return value;
    }
    assess()
    {
        if (self.attempt == nil || !self.attempt.ofKind(RpgExpandedPrototypeStart) || self.attempt.result == nil)
            rpgExpandedReject('prototype-accident-attempt');
        self.attempt.assess(); local value = new RpgExpandedPrototypeAccidentResult();
        if (self.result != nil)
        {
            local current = self.definition();
            if (current.length() != self.definitionSnapshot.length()) rpgExpandedReject('prototype-accident-binding');
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.definitionSnapshot[index]) rpgExpandedReject('prototype-accident-binding');
            value.status = 'reused'; value.damage = self.result.damage; value.wounds = self.result.wounds; return value;
        }
        if (self.outcome == nil || !self.outcome.ofKind(RpgExpandedPrototypeOutcome)
            || !self.outcome.accident || !self.outcome.facilitiesDestroyed || self.outcome.check == nil
            || self.outcome.check.critical != 'failure') rpgExpandedReject('prototype-accident-outcome');
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'prototype-accident-author-facts'; return value; }
        if (self.attempt.workedSeconds != self.attempt.result.seconds)
        { value.reason = 'prototype-work-incomplete'; return value; }
        if (self.attempt.facilities == nil || self.attempt.facilities.destroyed)
        { value.reason = 'prototype-accident-facilities'; return value; }
        local participants = [self.attempt.project.proposal.inventor] + self.attempt.assistants;
        if (self.targets.length() != participants.length()) rpgExpandedReject('prototype-accident-team');
        local seen = [];
        foreach (local target in self.targets)
        {
            if (target == nil || !target.ofKind(RpgExpandedPrototypeAccidentTarget)
                || target.profile == nil || !target.profile.ofKind(RpgExpandedProfile)
                || !holds(participants,target.profile) || holds(seen,target.profile))
                rpgExpandedReject('prototype-accident-target');
            seen = seen + [target.profile];
            if (target.id == nil || target.id == '') rpgExpandedReject('prototype-accident-wound-id');
            rpgInteger(target.dice,2,10); rpgInteger(target.protection,0,10000); rpgInteger(target.divisor,1,100);
            if (!holds(['cr','cut','imp','burn','pi-','pi','pi+'],target.damageType))
                rpgExpandedReject('prototype-accident-damage-type');
            for (local raw = target.dice; raw <= target.dice*6; raw += 1)
            {
                local wound = target.prepare(raw);
                if (wound == nil) { value.reason = 'prototype-accident-health-required'; return value; }
                local check = wound.assess();
                if (check.status != 'ready') { value.reason = check.reason; return value; }
            }
        }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        foreach (local target in self.targets)
        {
            local raw = 0;
            for (local index = 1; index <= target.dice; index += 1) raw += rpgRandom.die();
            local wound = target.prepare(raw); local injury = wound.apply();
            if (injury.status != 'resolved') rpgExpandedReject('prototype-accident-injury-changed');
            value.damage = value.damage + [raw]; value.wounds = value.wounds + [wound];
        }
        self.attempt.facilities.destroyed = true; self.definitionSnapshot = self.definition();
        value.status = 'resolved'; self.result = value; return value;
    }
;

modify RpgExpandedInventionProject
    workingPrototype = nil
    flawedTheoryDiscovered = nil
;
modify RpgExpandedPrototypeStart
    completion = nil
;

class RpgExpandedPrototypeCompletionResult: RpgExpandedResult
    productionPrice = nil
    score = nil
    outcome = nil
    delivery = nil
    delivered = nil
    pendingDefects = nil
;

/** Secret completion of a funded, fully worked physical prototype. */
class RpgExpandedPrototypeCompletion: object
    attempt = nil
    recipient = nil
    item = nil
    accident = nil
    knowledge = 'new'
    variantBonus = 0
    campaignNew = nil
    approved = nil
    evidence = nil
    result = nil
    definitionSnapshot = nil
    definition()
    {
        local value = [self.attempt,self.recipient,self.item,self.accident,self.knowledge,self.variantBonus,self.campaignNew,self.evidence];
        return value + self.accident.definition();
    }
    assess()
    {
        if (self.attempt == nil || !self.attempt.ofKind(RpgExpandedPrototypeStart) || self.attempt.result == nil)
            rpgExpandedReject('prototype-completion-attempt');
        self.attempt.assess(); local value = new RpgExpandedPrototypeCompletionResult();
        if (self.result != nil)
        {
            local current = self.definition();
            if (current.length() != self.definitionSnapshot.length()) rpgExpandedReject('prototype-completion-binding');
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.definitionSnapshot[index]) rpgExpandedReject('prototype-completion-binding');
            if (self.attempt.completion != self) rpgExpandedReject('prototype-completion-history');
            value.status = 'reused'; value.score = self.result.score; value.modifier = self.result.modifier;
            value.productionPrice = self.result.productionPrice;
            value.outcome = self.result.outcome; value.delivery = self.result.delivery;
            value.delivered = self.result.delivered; value.pendingDefects = self.result.pendingDefects; return value;
        }
        if (self.attempt.completion != nil) { value.reason = 'prototype-already-completed'; return value; }
        value.reason = self.attempt.completionExecutionReason(); if (value.reason != nil) return value;
        value.reason = self.attempt.workReason(); if (value.reason != nil) return value;
        if (self.attempt.workedSeconds != self.attempt.result.seconds)
        { value.reason = 'prototype-work-incomplete'; return value; }
        local project = self.attempt.project; local proposal = project.proposal;
        if (proposal.softwareComplexity != nil) { value.reason = 'prototype-software-delivery-unavailable'; return value; }
        if (!holds(['testable','flawed'],project.theory)) { value.reason = 'prototype-theory-required'; return value; }
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'prototype-completion-author-facts'; return value; }
        if (!holds(['new','exists','model'],self.knowledge)) rpgExpandedReject('prototype-completion-knowledge');
        rpgInteger(self.variantBonus,0,5);
        local assessment = proposal.assess();
        if (assessment.status != 'ready') { value.reason = assessment.reason; return value; }
        value.productionPrice = proposal.productionPrice();
        rpgInteger(value.productionPrice,0,100000000);
        local base = nil;
        foreach (local subject in [proposal.skill] + proposal.relatedSkills)
        {
            local context = new RpgLiteContext(); context.skill = subject;
            local score = rpgLiteScore(proposal.inventor,context);
            if (score == nil) { value.reason = context.unavailableReason(proposal.inventor); return value; }
            if (base == nil || score < base) base = score;
        }
        value.modifier = assessment.conceptModifier + (self.knowledge == 'model' ? 5 : self.knowledge == 'exists' ? 2 : 0)
            + self.variantBonus + proposal.noveltyModifier(self.campaignNew)
            + rpgExpandedPrototypeTeamModifier(proposal,self.attempt.assistants,self.attempt.toolsPenalty);
        value.score = base + value.modifier; rpgInteger(value.score,-1000,1000);
        if (value.score < 3) { value.reason = 'too-difficult'; return value; }
        if (self.accident == nil || !self.accident.ofKind(RpgExpandedPrototypeAccident)
            || self.accident.attempt != self.attempt || self.accident.result != nil || self.accident.outcome != nil)
            rpgExpandedReject('prototype-completion-accident');
        local potential = new RpgExpandedPrototypeAccident(); potential.attempt = self.attempt;
        potential.targets = self.accident.targets; potential.approved = self.accident.approved; potential.evidence = self.accident.evidence;
        potential.outcome = rpgExpandedPrototypeOutcome(12,17,nil,[]);
        local safety = potential.assess();
        if (safety.status != 'ready') { value.reason = safety.reason; return value; }
        value.delivery = new RpgExpandedAcquisition(); value.delivery.profile = self.recipient;
        value.delivery.item = self.item; value.delivery.mode = 'issue'; value.delivery.available = true; value.delivery.permitted = true;
        local grant = value.delivery.assess();
        if (grant.status != 'ready') { value.reason = grant.reason; return value; }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local check = rpgCheck(value.score,rpgRandom.roll()); local bugs = [];
        local flawed = self.attempt.project.theory == 'flawed';
        local proposal = self.attempt.project.proposal;
        local count = proposal.prototypeBugDiceCount(check,flawed);
        rpgInteger(count,0,2);
        for (local index = 1; index <= count; index += 1) bugs = bugs + [rpgRandom.die()];
        value.outcome = proposal.prototypeOutcome(value.score,check.roll,flawed,bugs);
        if (value.outcome.accident)
        {
            self.accident.outcome = value.outcome;
            if (self.accident.apply().status != 'resolved') rpgExpandedReject('prototype-completion-accident-changed');
        }
        if (value.outcome.working)
        {
            self.attempt.project.workingPrototype = self;
            value.pendingDefects = value.outcome.majorBugs + value.outcome.minorBugs > 0;
            if (!value.pendingDefects)
            {
                if (value.delivery.acquire().status != 'resolved') rpgExpandedReject('prototype-completion-delivery-changed');
                value.delivered = true;
            }
        }
        if (value.outcome.revealedFlaw)
        { self.attempt.project.flawedTheoryDiscovered = true; self.attempt.project.theory = nil; }
        self.attempt.completion = self; self.attempt.project.activePrototype = nil;
        self.definitionSnapshot = self.definition(); value.status = 'resolved'; self.result = value; return value;
    }
;

modify RpgLiteItem
    prototypeDefects = nil
;

/** Concrete author-selected fault behavior; severity and effect are separate facts. */
class RpgExpandedPrototypeDefect: object
    id = nil
    severity = nil
    effect = nil
    penalty = 0
    evidence = nil
    active = nil
    discovered = nil
    owner = nil
    definition() { return [self.id,self.severity,self.effect,self.penalty,self.evidence]; }
;

/** Exact-count defect installation and pending prototype delivery. */
class RpgExpandedPrototypeDefectSet: object
    completion = nil
    defects = []
    approved = nil
    evidence = nil
    result = nil
    definitionSnapshot = nil
    definition()
    {
        local value = [self.completion,self.evidence,self.defects.length()];
        foreach (local defect in self.defects) value = value + [defect] + defect.definition();
        return value;
    }
    assess()
    {
        if (self.completion == nil || !self.completion.ofKind(RpgExpandedPrototypeCompletion)
            || self.completion.result == nil) rpgExpandedReject('prototype-defects-completion');
        self.completion.assess(); local value = new RpgExpandedResult();
        if (self.result != nil)
        {
            local current = self.definition();
            if (current.length() != self.definitionSnapshot.length()) rpgExpandedReject('prototype-defects-binding');
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.definitionSnapshot[index]) rpgExpandedReject('prototype-defects-binding');
            if (self.completion.item.prototypeDefects != self) rpgExpandedReject('prototype-defects-history');
            foreach (local defect in self.defects)
                if (defect.owner != self) rpgExpandedReject('prototype-defect-owner');
            value.status = 'reused'; return value;
        }
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'prototype-defects-approval'; return value; }
        local completed = self.completion.result;
        if (!completed.outcome.working || !completed.pendingDefects || completed.delivered
            || self.completion.item.prototypeDefects != nil)
        { value.reason = 'prototype-defects-not-pending'; return value; }
        local major = 0; local minor = 0; local ids = [];
        foreach (local defect in self.defects)
        {
            if (defect == nil || !defect.ofKind(RpgExpandedPrototypeDefect) || defect.owner != nil
                || defect.id == nil || defect.id == '' || holds(ids,defect.id)) rpgExpandedReject('prototype-defect-definition');
            ids = ids + [defect.id];
            if (!holds(['major','minor'],defect.severity)) rpgExpandedReject('prototype-defect-severity');
            if (defect.severity == 'major') major += 1; else minor += 1;
            if (defect.evidence == nil || defect.evidence == '')
            { value.reason = 'prototype-defect-evidence'; return value; }
            if (defect.severity == 'minor' && defect.effect == 'operation-penalty') rpgInteger(defect.penalty,1,10);
            else if (defect.severity == 'major' && defect.effect == 'operation-block')
            { if (defect.penalty != 0) rpgExpandedReject('prototype-defect-unused-penalty'); }
            else { value.reason = 'prototype-defect-effect-unavailable'; return value; }
            if (defect.active || defect.discovered) rpgExpandedReject('prototype-defect-initial-state');
        }
        if (major != completed.outcome.majorBugs || minor != completed.outcome.minorBugs)
        { value.reason = 'prototype-defect-count'; return value; }
        local delivery = completed.delivery.assess();
        if (delivery.status != 'ready') { value.reason = delivery.reason; return value; }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local completed = self.completion.result;
        if (completed.delivery.acquire().status != 'resolved') rpgExpandedReject('prototype-defect-delivery-changed');
        foreach (local defect in self.defects) defect.owner = self;
        self.completion.item.prototypeDefects = self;
        completed.pendingDefects = nil; completed.delivered = true;
        self.definitionSnapshot = self.definition(); value.status = 'resolved'; self.result = value; return value;
    }
    operationAssessment()
    {
        if (self.result == nil) rpgExpandedReject('prototype-defects-not-installed');
        self.assess(); local value = new RpgExpandedResult();
        foreach (local defect in self.defects)
            if (defect.active)
            {
                if (defect.effect == 'operation-block') { value.reason = 'prototype-defect-blocked'; return value; }
                value.modifier -= defect.penalty;
            }
        value.status = 'ready'; return value;
    }
;

modify RpgLiteContext
    prototypeItem = nil
    prototypeOperation(profile)
    {
        local value = new RpgExpandedResult(); value.status = 'ready';
        if (self.prototypeItem == nil) return value;
        if (!self.prototypeItem.ofKind(RpgLiteItem)) rpgExpandedReject('prototype-context-item');
        if (!holds(profile.equipment,self.prototypeItem) || !self.prototypeItem.usableBy(profile))
        { value.status = 'blocked'; value.reason = 'prototype-item-unavailable'; return value; }
        if (self.prototypeItem.prototypeDefects == nil) return value;
        if (!self.prototypeItem.prototypeDefects.ofKind(RpgExpandedPrototypeDefectSet))
            rpgExpandedReject('prototype-context-defects');
        return self.prototypeItem.prototypeDefects.operationAssessment();
    }
    equipmentUseModifier(profile)
    {
        local base = inherited(profile); if (base == nil) return nil;
        local value = self.prototypeOperation(profile);
        return value.status == 'ready' ? base + value.modifier : nil;
    }
    unavailableReason(profile)
    {
        local value = self.prototypeOperation(profile);
        if (value.status != 'ready') return value.reason;
        return inherited(profile);
    }
;

modify RpgExpandedPrototypeDefectSet
    operations = []
;

class RpgExpandedPrototypeOperationResult: RpgExpandedResult
    activated = nil
    score = nil
;

/** One explicit operation check and its fault consequence, B474. */
class RpgExpandedPrototypeOperation: object
    id = nil
    profile = nil
    item = nil
    skill = nil
    modifier = 0
    seconds = 0
    marginDefect = nil
    criticalDefect = nil
    approved = nil
    uninterrupted = nil
    evidence = nil
    result = nil
    definitionSnapshot = nil
    defects = nil
    context()
    {
        local value = new RpgLiteContext(); value.skill = self.skill; value.prototypeItem = self.item;
        value.modifier = self.modifier; return value;
    }
    definition()
    { return [self.id,self.profile,self.item,self.skill,self.modifier,self.seconds,self.marginDefect,self.criticalDefect,self.evidence]; }
    assess()
    {
        if (self.profile == nil || !self.profile.ofKind(RpgLiteProfile) || self.item == nil || !self.item.ofKind(RpgLiteItem)
            || self.skill == nil || !self.skill.ofKind(RpgSkill)) rpgExpandedReject('prototype-operation-definition');
        local value = new RpgExpandedPrototypeOperationResult();
        if (self.result != nil)
        {
            local current = self.definition();
            if (current.length() != self.definitionSnapshot.length()) rpgExpandedReject('prototype-operation-binding');
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.definitionSnapshot[index]) rpgExpandedReject('prototype-operation-binding');
            if (self.item.prototypeDefects != self.defects || !holds(self.defects.operations,self))
                rpgExpandedReject('prototype-operation-history');
            value.status = 'reused'; value.check = self.result.check; value.activated = self.result.activated;
            value.score = self.result.score; return value;
        }
        if (self.id == nil || self.id == '') rpgExpandedReject('prototype-operation-id');
        rpgInteger(self.seconds,0,86400); rpgInteger(self.modifier,-1000,1000);
        if (!self.approved || !self.uninterrupted || self.evidence == nil || self.evidence == '')
        { value.reason = 'prototype-operation-author-facts'; return value; }
        if (self.profile.dead || self.profile.unconscious || self.profile.stunned || self.profile.hp() <= 0 || self.profile.fp() <= 0)
        { value.reason = 'prototype-operator-unavailable'; return value; }
        local faults = self.item.prototypeDefects;
        if (faults == nil || !faults.ofKind(RpgExpandedPrototypeDefectSet) || faults.result == nil)
        { value.reason = 'prototype-operation-defects-required'; return value; }
        faults.assess();
        foreach (local prior in faults.operations)
            if (prior.id == self.id) rpgExpandedReject('prototype-operation-duplicate');
        local unknown = []; local major = [];
        foreach (local defect in faults.defects)
        {
            if (!defect.discovered) unknown = unknown + [defect];
            if (defect.severity == 'major') major = major + [defect];
        }
        if (unknown.length() > 0 && !holds(unknown,self.marginDefect)
            || major.length() > 0 && !holds(major,self.criticalDefect))
        { value.reason = 'prototype-operation-fault-choice'; return value; }
        if (unknown.length() == 0 && self.marginDefect != nil || major.length() == 0 && self.criticalDefect != nil)
            rpgExpandedReject('prototype-operation-unused-fault');
        local context = self.context(); value.score = rpgLiteScore(self.profile,context);
        if (value.score == nil) { value.reason = context.unavailableReason(self.profile); return value; }
        if (value.score < 3) { value.reason = 'too-difficult'; return value; }
        value.seconds = self.seconds; value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local start = rpgLedger.seconds;
        rpgSpendTime(value.seconds);
        local refreshed = self.assess();
        if (refreshed.status != 'ready' || rpgLedger.seconds != start + value.seconds)
            rpgExpandedReject('prototype-operation-conditions-changed');
        value.score = refreshed.score; value.check = rpgLiteCheck(self.profile,self.context());
        if (value.check.status != 'resolved') rpgExpandedReject('prototype-operation-check-changed');
        if (!value.check.achieved)
        {
            if (value.check.critical == 'failure' && self.criticalDefect != nil) value.activated = self.criticalDefect;
            else if (value.check.margin <= -5) value.activated = self.marginDefect;
        }
        if (value.activated != nil) { value.activated.active = true; value.activated.discovered = true; }
        self.defects = self.item.prototypeDefects; self.defects.operations = self.defects.operations + [self];
        self.definitionSnapshot = self.definition(); value.status = 'resolved'; self.result = value; return value;
    }
;

modify RpgExpandedPrototypeDefectSet
    tests = []
;
class RpgExpandedPrototypeTestResult: RpgExpandedResult
    discovered = []
    activated = nil
    falseConfidence = nil
    score = nil
;

/** One complete uninterrupted testing week. Critical failure policy is explicit. */
class RpgExpandedPrototypeTest: object
    id = nil
    profile = nil
    item = nil
    skill = nil
    discoveryDefect = nil
    failureDefect = nil
    criticalPolicy = 'false-confidence'
    approved = nil
    uninterrupted = nil
    evidence = nil
    result = nil
    defects = nil
    definitionSnapshot = nil
    startedAt = nil
    endedAt = nil
    definition()
    { return [self.id,self.profile,self.item,self.skill,self.discoveryDefect,self.failureDefect,self.criticalPolicy,self.evidence]; }
    context()
    {
        local value = new RpgLiteContext(); value.skill = self.skill; value.prototypeItem = self.item;
        value.modifier = -3; return value;
    }
    assess()
    {
        if (self.profile == nil || !self.profile.ofKind(RpgLiteProfile) || self.item == nil || !self.item.ofKind(RpgLiteItem)
            || self.skill == nil || !self.skill.ofKind(RpgSkill)) rpgExpandedReject('prototype-test-definition');
        local value = new RpgExpandedPrototypeTestResult();
        if (self.result != nil)
        {
            local current = self.definition();
            if (current.length() != self.definitionSnapshot.length()) rpgExpandedReject('prototype-test-binding');
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.definitionSnapshot[index]) rpgExpandedReject('prototype-test-binding');
            if (self.item.prototypeDefects != self.defects || !holds(self.defects.tests,self))
                rpgExpandedReject('prototype-test-history');
            value.status = 'reused'; value.check = self.result.check; value.discovered = self.result.discovered;
            value.activated = self.result.activated; value.falseConfidence = self.result.falseConfidence; value.score = self.result.score; return value;
        }
        if (self.id == nil || self.id == '') rpgExpandedReject('prototype-test-id');
        if (!self.approved || !self.uninterrupted || self.evidence == nil || self.evidence == '')
        { value.reason = 'prototype-test-author-facts'; return value; }
        if (self.criticalPolicy != 'false-confidence')
        { value.reason = 'prototype-test-incident-policy-unavailable'; return value; }
        if (self.profile.dead || self.profile.unconscious || self.profile.stunned || self.profile.hp() <= 0 || self.profile.fp() <= 0)
        { value.reason = 'prototype-tester-unavailable'; return value; }
        local faults = self.item.prototypeDefects;
        if (faults == nil || !faults.ofKind(RpgExpandedPrototypeDefectSet) || faults.result == nil)
        { value.reason = 'prototype-test-defects-required'; return value; }
        faults.assess();
        foreach (local prior in faults.tests)
            if (prior.id == self.id) rpgExpandedReject('prototype-test-duplicate');
        local unknown = []; local major = [];
        foreach (local defect in faults.defects)
        {
            if (!defect.discovered) unknown = unknown + [defect];
            if (defect.severity == 'major') major = major + [defect];
        }
        if (unknown.length() > 0 && !holds(unknown,self.discoveryDefect)
            || major.length() > 0 && !holds(major,self.failureDefect))
        { value.reason = 'prototype-test-fault-choice'; return value; }
        if (unknown.length() == 0 && self.discoveryDefect != nil || major.length() == 0 && self.failureDefect != nil)
            rpgExpandedReject('prototype-test-unused-fault');
        local context = self.context(); value.score = rpgLiteScore(self.profile,context);
        if (value.score == nil) { value.reason = context.unavailableReason(self.profile); return value; }
        if (value.score < 3) { value.reason = 'too-difficult'; return value; }
        value.seconds = 604800; value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local start = rpgLedger.seconds;
        for (local day = 1; day <= 7; day += 1)
        {
            rpgSpendTime(86400);
            if (self.assess().status != 'ready' || rpgLedger.seconds != start + day*86400)
                rpgExpandedReject('prototype-test-conditions-changed');
        }
        value.check = rpgLiteCheck(self.profile,self.context()); value.score = value.check.score;
        if (value.check.status != 'resolved') rpgExpandedReject('prototype-test-check-changed');
        self.defects = self.item.prototypeDefects;
        if (value.check.achieved)
        {
            if (value.check.critical == 'success')
            {
                foreach (local defect in self.defects.defects)
                    if (!defect.discovered) value.discovered = value.discovered + [defect];
            }
            else if (self.discoveryDefect != nil) value.discovered = [self.discoveryDefect];
        }
        else if (value.check.critical == 'failure') value.falseConfidence = true;
        else if (self.failureDefect != nil) value.activated = self.failureDefect;
        foreach (local defect in value.discovered) defect.discovered = true;
        if (value.activated != nil) { value.activated.active = true; value.activated.discovered = true; }
        self.startedAt = start; self.endedAt = rpgLedger.seconds;
        self.defects.tests = self.defects.tests + [self]; self.definitionSnapshot = self.definition();
        value.status = 'resolved'; self.result = value; return value;
    }
;

class RpgExpandedProductionAssessment: RpgExpandedResult
    setupMoney = 0
    moneyNumerator = 0
    moneyDenominator = 1
    secondsNumerator = 0
    secondsDenominator = 1
;

/** Exact fractions avoid an invented rounding rule for currency and subsecond work. */
rpgExpandedProductionFraction(numerator, denominator)
{
    rpgInteger(numerator,0,1000000000); rpgInteger(denominator,1,7);
    local left = numerator; local right = denominator;
    while (right != 0) { local remainder = left % right; left = right; right = remainder; }
    return [numerator / left,denominator / left];
}

/** B474 production table; supplied prototype duration must have an explicit author basis. */
rpgExpandedAssessProduction(retailPrice, prototypeSeconds, line, paidLabor)
{
    rpgInteger(retailPrice,0,100000000); rpgInteger(prototypeSeconds,1,1000000000);
    local value = new RpgExpandedProductionAssessment();
    local money = rpgExpandedProductionFraction(retailPrice,paidLabor ? (line ? 2 : 1) : 5);
    value.moneyNumerator = money[1]; value.moneyDenominator = money[2];
    local time = nil;
    if (line)
    {
        value.setupMoney = retailPrice * 20;
        // Compare before multiplication: the chosen price-based branch cannot overflow.
        time = retailPrice <= prototypeSeconds / 252
            ? rpgExpandedProductionFraction(retailPrice * 36,1)
            : rpgExpandedProductionFraction(prototypeSeconds,7);
    }
    else time = rpgExpandedProductionFraction(prototypeSeconds,2);
    value.secondsNumerator = time[1]; value.secondsDenominator = time[2];
    value.status = 'ready'; return value;
}

modify RpgExpandedInventionProject
    productionLines = []
;

/** One approved production-line capital payment, B474. */
class RpgExpandedProductionLine: object
    id = nil
    project = nil
    payer = nil
    approved = nil
    available = nil
    permitted = nil
    evidence = nil
    result = nil
    boundId = nil
    boundProject = nil
    boundPayer = nil
    boundEvidence = nil
    retailPrice = nil
    assess()
    {
        if (self.project == nil || !self.project.ofKind(RpgExpandedInventionProject)
            || self.payer == nil || !self.payer.ofKind(RpgExpandedProfile))
            rpgExpandedReject('production-line-definition');
        self.project.validate(); local value = new RpgExpandedInventionFundingResult();
        if (self.result != nil)
        {
            if (self.id != self.boundId || self.project != self.boundProject || self.payer != self.boundPayer
                || self.evidence != self.boundEvidence || self.retailPrice != self.project.workingPrototype.result.productionPrice
                || !holds(self.project.productionLines,self))
                rpgExpandedReject('production-line-binding');
            value.status = 'reused'; return value;
        }
        if (self.id == nil || self.id == '') rpgExpandedReject('production-line-id');
        if (!self.approved || !self.available || !self.permitted || self.evidence == nil || self.evidence == '')
        { value.reason = 'production-line-author-facts'; return value; }
        local prototype = self.project.workingPrototype;
        if (prototype == nil || !prototype.ofKind(RpgExpandedPrototypeCompletion)
            || prototype.result == nil || !prototype.result.outcome.working)
        { value.reason = 'production-line-working-prototype-required'; return value; }
        prototype.assess();
        foreach (local line in self.project.productionLines)
            if (line.id == self.id) rpgExpandedReject('production-line-duplicate');
        rpgExpandedValidate(self.payer); rpgInteger(self.payer.money,0,2147483647);
        rpgInteger(prototype.result.productionPrice,0,100000000);
        local cost = prototype.result.productionPrice * 20;
        if (cost > self.payer.money) { value.reason = 'production-line-funds'; return value; }
        value.money = cost; value.status = 'ready'; return value;
    }
    establish()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.payer.money -= value.money;
        self.retailPrice = self.project.workingPrototype.result.productionPrice;
        self.boundId = self.id; self.boundProject = self.project; self.boundPayer = self.payer; self.boundEvidence = self.evidence;
        self.project.productionLines = self.project.productionLines + [self];
        value.status = 'resolved'; self.result = value; return value;
    }
;

modify RpgExpandedInventionProject
    productionOrders = []
;
modify RpgExpandedProductionLine
    activeOrder = nil
;
class RpgExpandedProductionOrderResult: RpgExpandedResult
    money = 0
;

/** Paid one-copy order using the recorded prototype duration. */
class RpgExpandedProductionOrder: object
    id = nil
    project = nil
    line = nil
    payer = nil
    recipient = nil
    worker = nil
    item = nil
    paidLabor = nil
    approved = nil
    available = nil
    permitted = nil
    uninterrupted = nil
    evidence = nil
    result = nil
    delivered = nil
    delivery = nil
    definitionSnapshot = nil
    startedAt = nil
    endedAt = nil
    definition()
    { return [self.id,self.project,self.line,self.payer,self.recipient,self.worker,self.item,self.paidLabor,self.evidence]; }
    validateBinding()
    {
        local current = self.definition();
        if (current.length() != self.definitionSnapshot.length()) rpgExpandedReject('production-order-binding');
        for (local index = 1; index <= current.length(); index += 1)
            if (current[index] != self.definitionSnapshot[index]) rpgExpandedReject('production-order-binding');
        if (!holds(self.project.productionOrders,self)) rpgExpandedReject('production-order-history');
        if (self.delivery == nil || self.delivery.profile != self.recipient || self.delivery.item != self.item
            || self.delivery.mode != 'issue' || self.delivery.quote != nil || self.delivery.startingPurchase)
            rpgExpandedReject('production-order-delivery-binding');
        self.project.validate();
    }
    liveReason()
    {
        if (!self.approved || !self.available || !self.permitted || !self.uninterrupted || self.evidence == nil || self.evidence == '')
            return 'production-order-author-facts';
        if (self.worker == nil || !self.worker.ofKind(RpgLiteProfile)) rpgExpandedReject('production-worker');
        if (self.worker.dead || self.worker.unconscious || self.worker.stunned || self.worker.hp() <= 0 || self.worker.fp() <= 0)
            return 'production-worker-unavailable';
        if (self.line != nil)
        {
            if (!self.line.ofKind(RpgExpandedProductionLine) || self.line.project != self.project || self.line.result == nil)
                rpgExpandedReject('production-order-line');
            self.line.assess();
            if (!self.line.available || !self.line.permitted) return 'production-line-unavailable';
            if (self.line.activeOrder != nil && self.line.activeOrder != self) return 'production-line-busy';
            if (self.result != nil && !self.delivered && self.line.activeOrder != self) return 'production-line-reservation-lost';
        }
        return nil;
    }
    assess()
    {
        if (self.project == nil || !self.project.ofKind(RpgExpandedInventionProject)
            || self.payer == nil || !self.payer.ofKind(RpgExpandedProfile)) rpgExpandedReject('production-order-definition');
        self.project.validate(); local value = new RpgExpandedProductionOrderResult();
        if (self.result != nil)
        { self.validateBinding(); value.status = 'reused'; value.seconds = self.result.seconds; return value; }
        if (self.id == nil || self.id == '') rpgExpandedReject('production-order-id');
        value.reason = self.liveReason(); if (value.reason != nil) return value;
        local prototype = self.project.workingPrototype;
        if (prototype == nil || !prototype.ofKind(RpgExpandedPrototypeCompletion) || prototype.result == nil
            || !prototype.result.outcome.working || !prototype.result.delivered)
        { value.reason = 'production-working-prototype-required'; return value; }
        prototype.assess();
        if (prototype.result.outcome.majorBugs != 0 || prototype.result.outcome.minorBugs != 0)
        { value.reason = 'production-defect-propagation-unavailable'; return value; }
        foreach (local prior in self.project.productionOrders)
            if (prior.id == self.id) rpgExpandedReject('production-order-duplicate');
        for (local prior = firstObj(RpgExpandedProductionOrder); prior != nil; prior = nextObj(prior,RpgExpandedProductionOrder))
            if (prior != self && prior.result != nil && !prior.delivered && prior.item == self.item)
            { value.reason = 'production-item-reserved'; return value; }
        local quote = rpgExpandedAssessProduction(prototype.result.productionPrice,prototype.attempt.result.seconds,self.line != nil,self.paidLabor);
        if (quote.moneyDenominator != 1 || quote.secondsDenominator != 1)
        { value.reason = 'production-fractional-ledger-unavailable'; return value; }
        rpgExpandedValidate(self.payer); rpgInteger(self.payer.money,0,2147483647);
        if (self.payer.money < quote.moneyNumerator) { value.reason = 'production-order-funds'; return value; }
        local grant = new RpgExpandedAcquisition(); grant.profile = self.recipient; grant.item = self.item;
        grant.mode = 'issue'; grant.available = true; grant.permitted = true;
        local access = grant.assess();
        if (access.status != 'ready') { value.reason = access.reason; return value; }
        value.money = quote.moneyNumerator; value.seconds = quote.secondsNumerator; value.status = 'ready'; return value;
    }
    begin()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.payer.money -= value.money;
        self.delivery = new RpgExpandedAcquisition(); self.delivery.profile = self.recipient; self.delivery.item = self.item;
        self.delivery.mode = 'issue'; self.delivery.available = true; self.delivery.permitted = true;
        self.definitionSnapshot = self.definition(); self.project.productionOrders = self.project.productionOrders + [self];
        if (self.line != nil) self.line.activeOrder = self;
        value.status = 'resolved'; self.result = value; return value;
    }
    finish()
    {
        if (self.result == nil) rpgExpandedReject('production-order-not-started');
        self.validateBinding(); local value = new RpgExpandedProductionOrderResult();
        if (self.delivered) { value.status = 'reused'; return value; }
        value.reason = self.liveReason(); if (value.reason != nil) return value;
        local grant = self.delivery.assess();
        if (grant.status != 'ready') { value.reason = grant.reason; return value; }
        local remaining = self.result.seconds; local start = rpgLedger.seconds; local elapsed = 0;
        while (remaining > 0)
        {
            local step = remaining > 86400 ? 86400 : remaining;
            rpgSpendTime(step); elapsed += step; remaining -= step;
            if (self.liveReason() != nil || rpgLedger.seconds != start + elapsed)
                rpgExpandedReject('production-order-conditions-changed');
        }
        if (self.delivery.acquire().status != 'resolved') rpgExpandedReject('production-delivery-changed');
        self.startedAt = start; self.endedAt = rpgLedger.seconds; self.delivered = true;
        if (self.line != nil) self.line.activeOrder = nil;
        value.seconds = self.result.seconds; value.status = 'resolved'; return value;
    }
;

class RpgExpandedCinematicInventionCost: RpgExpandedResult
    facilities = 0
    adjustedRetail = 0
;

/** B475 costs compare with campaign technology, not the inventor's personal level. */
rpgExpandedCinematicInventionCosts(category, retailPrice, campaignTL, deviceTL, reusedFacilities)
{
    local categories = ['simple','average','complex','amazing'];
    if (!holds(categories,category)) rpgExpandedReject('cinematic-invention-category');
    rpgInteger(retailPrice,0,100000000); rpgInteger(campaignTL,0,12); rpgInteger(deviceTL,0,12);
    local index = 1; while (categories[index] != category) index += 1;
    local base = [50000,100000,250000,500000]; local increment = [100000,250000,500000,1000000];
    local difference = deviceTL > campaignTL ? deviceTL-campaignTL : 0;
    local value = new RpgExpandedCinematicInventionCost();
    value.facilities = base[index] + difference * increment[index];
    if (reusedFacilities) value.facilities /= 10;
    local term = retailPrice; value.adjustedRetail = term;
    for (local level = 1; level <= difference; level += 1)
    {
        if (term > 1073741823) rpgExpandedReject('cinematic-invention-price-limit');
        term *= 2;
        if (value.adjustedRetail > 2147483647-term) rpgExpandedReject('cinematic-invention-price-limit');
        value.adjustedRetail += term;
    }
    value.status = 'ready'; return value;
}

/** B475 base concept/prototype modifier; other authored circumstances remain separate. */
rpgExpandedCinematicInventionModifier(category, softwareComplexity, personalTL, deviceTL)
{
    rpgInteger(personalTL,0,12); rpgInteger(deviceTL,0,12);
    local penalty = 0;
    if (softwareComplexity != nil)
    {
        if (category != nil) rpgExpandedReject('cinematic-invention-complexity-source');
        rpgInteger(softwareComplexity,1,12); penalty = -softwareComplexity;
    }
    else
    {
        local categories = ['simple','average','complex','amazing'];
        if (!holds(categories,category)) rpgExpandedReject('cinematic-invention-category');
        local index = 1; while (categories[index] != category) index += 1;
        local penalties = [0,-2,-4,-8]; penalty = penalties[index];
    }
    if (deviceTL > personalTL) penalty -= 5 * (deviceTL-personalTL);
    return penalty;
}

/** B476 rapid construction uses its own dice and units, with no ordinary one-day minimum. */
rpgExpandedRapidPrototypeSeconds(category, dice)
{
    if (!holds(['simple','average','complex','amazing'],category)) rpgExpandedReject('rapid-prototype-category');
    local count = category == 'simple' ? 2 : category == 'amazing' ? 4 : 1;
    if (dice.length() != count) rpgExpandedReject('rapid-prototype-dice');
    local total = 0; foreach (local die in dice) { rpgInteger(die,1,6); total += die; }
    if (category == 'simple') return total * 60;
    if (category == 'average') return total <= 2 ? 1800 : (total-2)*3600;
    return total * 3600;
}
rpgExpandedRapidConceptSeconds(die)
{
    rpgInteger(die,1,6); return die * 60;
}

modify RpgExpandedRules
    cinematicInvention = nil
    rapidInvention = nil
    speculativePhysics = nil
;

/** Campaign permission and purchased capability are independent of technical training. */
class RpgExpandedInventionPermission: object
    inventor = nil
    mode = 'cinematic'
    violatesOrdinaryPhysics = nil
    designApproved = nil
    evidence = nil
    assess()
    {
        if (self.inventor == nil || !self.inventor.ofKind(RpgExpandedProfile))
            rpgExpandedReject('invention-permission-owner');
        rpgExpandedValidate(self.inventor);
        if (!holds(['cinematic','rapid'],self.mode)) rpgExpandedReject('invention-permission-mode');
        local value = new RpgExpandedResult();
        if (!self.inventor.rules.cinematicInvention || self.mode == 'rapid' && !self.inventor.rules.rapidInvention)
        { value.reason = 'invention-campaign-option'; return value; }
        local tier = self.inventor.inventionCapabilityTier();
        if (tier == nil || self.mode == 'rapid' && tier != 'rapid')
        { value.reason = 'invention-capability-required'; return value; }
        if (self.violatesOrdinaryPhysics && !self.inventor.rules.speculativePhysics)
        { value.reason = 'invention-world-physics'; return value; }
        if (!self.designApproved || self.evidence == nil || self.evidence == '')
        { value.reason = 'invention-design-approval'; return value; }
        value.status = 'ready'; return value;
    }
;


/** Owned concept-compatible cinematic proposal. Prototype execution remains gated. */
class RpgExpandedCinematicProposal: RpgExpandedInventionProposal
    permission = nil
    waiveToolsPenalty = nil
    toolsWaiverEvidence = nil
    prototypeToolsPenalty(penalty)
    {
        rpgInteger(penalty,0,10);
        if (!self.waiveToolsPenalty) return penalty;
        if (self.toolsWaiverEvidence == nil || self.toolsWaiverEvidence == '')
            rpgExpandedReject('cinematic-tools-waiver-evidence');
        return 0;
    }
    technologyPermissionReason()
    {
        if (self.permission == nil || !self.permission.ofKind(RpgExpandedInventionPermission)
            || self.permission.inventor != self.inventor) rpgExpandedReject('cinematic-proposal-permission');
        if (self.permission.mode != 'cinematic') return 'rapid-proposal-execution-unavailable';
        local value = self.permission.assess(); return value.status == 'ready' ? nil : value.reason;
    }
    finalizeAssessment(value)
    {
        value.conceptModifier = rpgExpandedCinematicInventionModifier(
            self.softwareComplexity == nil ? value.category : nil,self.softwareComplexity,self.inventor.techLevel,self.techLevel)
            + self.descriptionBonus;
        local costs = rpgExpandedCinematicInventionCosts(value.category,self.retailPrice,
            self.inventor.campaignTL,self.techLevel,self.relatedFacilities);
        value.facilitiesCost = costs.facilities; value.attemptCost = costs.adjustedRetail; return value;
    }
    noveltyModifier(campaignNew) { return 0; }
    prototypeExecutionReason()
    {
        local reason = self.technologyPermissionReason();
        if (reason != nil) return reason;
        return self.techLevel > self.inventor.techLevel ? 'cinematic-advanced-defects-unavailable' : nil;
    }
    prototypeBugDiceCount(check, flawed)
    { return flawed || !check.achieved || check.critical == 'success' || check.margin >= 3 ? 0 : 1; }
    prototypeOutcome(score, roll, flawed, dice)
    { return rpgExpandedCinematicPrototypeOutcome(score,roll,flawed,dice); }
    productionPrice()
    {
        local value = self.assess();
        if (value.status != 'ready') rpgExpandedReject(value.reason);
        return value.attemptCost;
    }
    definition()
    {
        if (self.permission == nil || !self.permission.ofKind(RpgExpandedInventionPermission))
            rpgExpandedReject('cinematic-proposal-permission');
        return inherited() + [self.waiveToolsPenalty,self.toolsWaiverEvidence,self.permission,self.permission.inventor,self.permission.mode,
            self.permission.violatesOrdinaryPhysics,self.permission.designApproved,self.permission.evidence];
    }
;

/** Full-2008 B476: cinematic success has only minor defects. */
rpgExpandedCinematicPrototypeOutcome(score, roll, flawed, bugDice)
{
    local check = rpgCheck(score,roll);
    if (!check.achieved || flawed || check.critical == 'success')
        return rpgExpandedPrototypeOutcome(score,roll,flawed,bugDice);
    local count = check.margin >= 3 ? 0 : 1;
    if (bugDice.length() != count) rpgExpandedReject('prototype-bug-dice');
    foreach (local die in bugDice) rpgInteger(die,1,6);
    local value = new RpgExpandedPrototypeOutcome();
    value.status = 'resolved'; value.check = check; value.working = true;
    if (count == 1) value.minorBugs = bugDice[1] / 2;
    return value;
}

/** B476: rapid concepts require their own timed request and purchased tier. */
class RpgExpandedRapidProposal: RpgExpandedCinematicProposal
    technologyPermissionReason()
    {
        if (self.permission == nil || !self.permission.ofKind(RpgExpandedInventionPermission)
            || self.permission.inventor != self.inventor) rpgExpandedReject('rapid-proposal-permission');
        if (self.permission.mode != 'rapid') return 'rapid-proposal-mode';
        local value = self.permission.assess(); return value.status == 'ready' ? nil : value.reason;
    }
    conceptRequestReason(request)
    { return request.ofKind(RpgExpandedRapidConcept) ? nil : 'rapid-concept-timed-request-required'; }
    prototypeExecutionReason() { return 'rapid-prototype-components-unavailable'; }
;

class RpgExpandedRapidConcept: RpgExpandedInventionConcept
    dailyLimited = nil
    approved = nil
    uninterrupted = nil
    definition() { return inherited() + [self.approved,self.uninterrupted]; }
    assess()
    {
        if (self.project == nil || !self.project.ofKind(RpgExpandedInventionProject)
            || self.project.proposal == nil || !self.project.proposal.ofKind(RpgExpandedRapidProposal))
            rpgExpandedReject('rapid-concept-proposal');
        local value = inherited();
        if (value.status != 'ready') return value;
        if (!self.approved || !self.uninterrupted)
        { value.status = 'blocked'; value.reason = 'rapid-concept-author-facts'; return value; }
        return value;
    }
    prepareExecution(value)
    {
        local definition = self.definition(); local proposal = self.project.proposal.definition();
        for (local die = 1; die <= 6; die += 1) rpgLedger.validateAdvance(rpgExpandedRapidConceptSeconds(die));
        local seconds = rpgExpandedRapidConceptSeconds(rpgRandom.die()); local start = rpgLedger.seconds;
        rpgSpendTime(seconds);
        local current = self.definition(); local design = self.project.proposal.definition();
        if (current.length() != definition.length() || design.length() != proposal.length())
            rpgExpandedReject('rapid-concept-definition-changed');
        for (local index = 1; index <= current.length(); index += 1)
            if (current[index] != definition[index]) rpgExpandedReject('rapid-concept-definition-changed');
        for (local index = 1; index <= design.length(); index += 1)
            if (design[index] != proposal[index]) rpgExpandedReject('rapid-concept-definition-changed');
        local updated = self.assess();
        if (updated.status != 'ready' || rpgLedger.seconds != start + seconds)
            rpgExpandedReject('rapid-concept-interrupted');
        updated.seconds = seconds; return updated;
    }
;

modify RpgExpandedInventionProject
    rapidPurchases = []
    rapidFacilityPurchase = nil
;

class RpgExpandedRapidPurchaseResult: RpgExpandedResult
    money = 0
    facilitiesMoney = 0
    partsMoney = 0
    acquisition = nil
;

/** B477 bought components: shared inventory and currency, one facilities payment. */
class RpgExpandedRapidPurchase: object
    id = nil
    project = nil
    payer = nil
    item = nil
    approved = nil
    available = nil
    permitted = nil
    evidence = nil
    result = nil
    definitionSnapshot = nil
    facilityReceipt = nil
    definition() { return [self.id,self.project,self.payer,self.item,self.evidence]; }
    assess()
    {
        if (self.project == nil || !self.project.ofKind(RpgExpandedInventionProject)
            || self.project.proposal == nil || !self.project.proposal.ofKind(RpgExpandedRapidProposal)
            || self.payer == nil || !self.payer.ofKind(RpgExpandedProfile)
            || self.item == nil || !self.item.ofKind(RpgLiteItem))
            rpgExpandedReject('rapid-purchase-definition');
        self.project.validate(); local value = new RpgExpandedRapidPurchaseResult();
        if (self.result != nil)
        {
            local current = self.definition();
            if (self.definitionSnapshot == nil || current.length() != self.definitionSnapshot.length())
                rpgExpandedReject('rapid-purchase-binding');
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.definitionSnapshot[index]) rpgExpandedReject('rapid-purchase-binding');
            if (!holds(self.project.rapidPurchases,self) || self.facilityReceipt != self.project.rapidFacilityPurchase
                || self.result.acquisition.profile != self.payer || self.result.acquisition.item != self.item
                || !self.result.acquisition.claimed)
                rpgExpandedReject('rapid-purchase-history');
            value.status = 'reused'; value.facilitiesMoney = self.result.facilitiesMoney;
            value.partsMoney = self.result.partsMoney; value.acquisition = self.result.acquisition; return value;
        }
        if (self.id == nil || self.id == '') rpgExpandedReject('rapid-purchase-id');
        if (!self.approved || !self.available || !self.permitted || self.evidence == nil || self.evidence == '')
        { value.reason = 'rapid-purchase-author-facts'; return value; }
        if (!holds(['testable','flawed'],self.project.theory))
        { value.reason = 'rapid-purchase-theory-required'; return value; }
        foreach (local prior in self.project.rapidPurchases)
            if (prior.id == self.id) rpgExpandedReject('rapid-purchase-duplicate');
        local proposal = self.project.proposal; local quote = proposal.assess();
        if (quote.status != 'ready') { value.reason = quote.reason; return value; }
        // Parts with unsupported advanced defects cannot yet enter construction.
        if (proposal.techLevel > proposal.inventor.techLevel)
        { value.reason = 'cinematic-advanced-defects-unavailable'; return value; }
        local facilities = self.project.rapidFacilityPurchase;
        if (facilities != nil)
        {
            if (!facilities.ofKind(RpgExpandedRapidPurchase) || facilities.project != self.project || facilities.result == nil)
                rpgExpandedReject('rapid-purchase-facilities');
            facilities.assess();
        }
        local setup = facilities == nil ? quote.facilitiesCost : 0;
        if (setup % 100 != 0 || quote.attemptCost % 100 != 0)
        { value.reason = 'rapid-purchase-fractional-ledger-unavailable'; return value; }
        value.facilitiesMoney = setup / 100; value.partsMoney = quote.attemptCost / 100;
        value.money = value.facilitiesMoney + value.partsMoney;
        value.acquisition = new RpgExpandedAcquisition(); value.acquisition.profile = self.payer;
        value.acquisition.item = self.item; value.acquisition.mode = 'purchase'; value.acquisition.quote = value.money;
        value.acquisition.available = true; value.acquisition.permitted = true;
        local access = value.acquisition.assess();
        if (access.status != 'ready') { value.reason = access.reason; return value; }
        value.status = 'ready'; return value;
    }
    acquire()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        if (value.acquisition.acquire().status != 'resolved') rpgExpandedReject('rapid-purchase-changed');
        if (self.project.definitionSnapshot == nil) self.project.definitionSnapshot = self.project.proposal.definition();
        if (self.project.rapidFacilityPurchase == nil) self.project.rapidFacilityPurchase = self;
        self.facilityReceipt = self.project.rapidFacilityPurchase; self.definitionSnapshot = self.definition();
        self.project.rapidPurchases = self.project.rapidPurchases + [self];
        value.status = 'resolved'; self.result = value; return value;
    }
;

rpgExpandedRapidScroungePenalty(category)
{
    if (category == 'simple') return 0;
    if (category == 'average') return -2;
    if (category == 'complex') return -6;
    if (category == 'amazing') return -10;
    rpgExpandedReject('rapid-scrounge-category');
}

modify RpgExpandedInventionProject
    rapidSearches = []
;

class RpgExpandedRapidSearchResult: RpgExpandedResult
    score = nil
    projectCost = nil
;

/** B476-B477 discovery receipt; acquisition and construction are separate commitments. */
class RpgExpandedRapidSearch: object
    id = nil
    project = nil
    source = nil
    sourceKind = 'limited'
    skill = nil
    approved = nil
    available = nil
    permitted = nil
    uninterrupted = nil
    seconds = 0
    evidence = nil
    result = nil
    definitionSnapshot = nil
    definition()
    { return [self.id,self.project,self.source,self.sourceKind,self.skill,self.seconds,self.evidence]; }
    context()
    {
        local value = new RpgLiteContext(); value.skill = self.skill;
        value.modifier = rpgExpandedRapidScroungePenalty(self.project.proposal.assess().category); return value;
    }
    assess()
    {
        if (self.project == nil || !self.project.ofKind(RpgExpandedInventionProject)
            || self.project.proposal == nil || !self.project.proposal.ofKind(RpgExpandedRapidProposal))
            rpgExpandedReject('rapid-search-project');
        self.project.validate(); local value = new RpgExpandedRapidSearchResult();
        if (self.result != nil)
        {
            local current = self.definition();
            if (self.definitionSnapshot == nil || current.length() != self.definitionSnapshot.length())
                rpgExpandedReject('rapid-search-binding');
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.definitionSnapshot[index]) rpgExpandedReject('rapid-search-binding');
            if (!holds(self.project.rapidSearches,self)) rpgExpandedReject('rapid-search-history');
            value.status = 'reused'; value.check = self.result.check; value.score = self.result.score;
            value.projectCost = self.result.projectCost; value.seconds = self.result.seconds; return value;
        }
        if (self.id == nil || self.id == '' || self.source == nil || !holds(['plentiful','limited'],self.sourceKind)
            || self.skill == nil || !self.skill.ofKind(RpgLiteSkill)) rpgExpandedReject('rapid-search-definition');
        rpgInteger(self.seconds,0,86400);
        if (!self.approved || !self.available || !self.permitted || !self.uninterrupted || self.evidence == nil || self.evidence == '')
        { value.reason = 'rapid-search-author-facts'; return value; }
        if (self.sourceKind == 'plentiful' && self.skill.id != 'scrounging')
        { value.reason = 'rapid-search-scrounging-required'; return value; }
        if (!holds(['testable','flawed'],self.project.theory))
        { value.reason = 'rapid-search-theory-required'; return value; }
        foreach (local prior in self.project.rapidSearches)
            if (prior.id == self.id) rpgExpandedReject('rapid-search-duplicate');
        local quote = self.project.proposal.assess();
        if (quote.status != 'ready') { value.reason = quote.reason; return value; }
        local inventor = self.project.proposal.inventor;
        if (inventor.dead || inventor.unconscious || inventor.stunned || inventor.hp() <= 0 || inventor.fp() <= 0)
        { value.reason = 'rapid-search-inventor-unavailable'; return value; }
        local context = self.context(); value.score = rpgLiteScore(inventor,context);
        if (value.score == nil) { value.reason = context.unavailableReason(inventor); return value; }
        if (value.score < 3) { value.reason = 'too-difficult'; return value; }
        value.modifier = context.modifier; value.seconds = self.seconds; value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local current = self.definition(); local design = self.project.proposal.definition(); local start = rpgLedger.seconds;
        rpgSpendTime(value.seconds);
        local changed = self.definition(); local changedDesign = self.project.proposal.definition();
        if (changed.length() != current.length() || changedDesign.length() != design.length())
            rpgExpandedReject('rapid-search-definition-changed');
        for (local index = 1; index <= current.length(); index += 1)
            if (current[index] != changed[index]) rpgExpandedReject('rapid-search-definition-changed');
        for (local index = 1; index <= design.length(); index += 1)
            if (design[index] != changedDesign[index]) rpgExpandedReject('rapid-search-definition-changed');
        local refreshed = self.assess();
        if (refreshed.status != 'ready' || rpgLedger.seconds != start + value.seconds)
            rpgExpandedReject('rapid-search-interrupted');
        value.score = refreshed.score; value.check = rpgLiteCheck(self.project.proposal.inventor,self.context());
        if (value.check.status != 'resolved') rpgExpandedReject('rapid-search-check-changed');
        if (value.check.achieved) value.projectCost = (rpgRandom.die()-1)*100;
        self.definitionSnapshot = current;
        if (self.project.definitionSnapshot == nil) self.project.definitionSnapshot = design;
        self.project.rapidSearches = self.project.rapidSearches + [self];
        value.status = 'resolved'; self.result = value; return value;
    }
;

modify RpgExpandedRapidSearch
    claimedBy = nil
;

modify RpgExpandedInventionProject
    rapidSalvages = []
;

/** One successful search authorizes one acquisition at its recorded total cost. */
class RpgExpandedRapidSalvage: object
    search = nil
    payer = nil
    item = nil
    approved = nil
    available = nil
    permitted = nil
    evidence = nil
    result = nil
    definitionSnapshot = nil
    definition() { return [self.search,self.payer,self.item,self.evidence]; }
    assess()
    {
        if (self.search == nil || !self.search.ofKind(RpgExpandedRapidSearch)
            || self.search.result == nil || self.payer == nil || !self.payer.ofKind(RpgExpandedProfile)
            || self.item == nil || !self.item.ofKind(RpgLiteItem)) rpgExpandedReject('rapid-salvage-definition');
        self.search.assess(); local project = self.search.project;
        local value = new RpgExpandedRapidPurchaseResult();
        if (self.result != nil)
        {
            local current = self.definition();
            if (self.definitionSnapshot == nil || current.length() != self.definitionSnapshot.length())
                rpgExpandedReject('rapid-salvage-binding');
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.definitionSnapshot[index]) rpgExpandedReject('rapid-salvage-binding');
            if (self.search.claimedBy != self || !holds(project.rapidSalvages,self)
                || self.result.acquisition.profile != self.payer || self.result.acquisition.item != self.item
                || !self.result.acquisition.claimed) rpgExpandedReject('rapid-salvage-history');
            value.status = 'reused'; value.partsMoney = self.result.partsMoney;
            value.acquisition = self.result.acquisition; return value;
        }
        if (!self.search.result.check.achieved || self.search.result.projectCost == nil)
        { value.reason = 'rapid-salvage-success-required'; return value; }
        if (self.search.claimedBy != nil) { value.reason = 'rapid-salvage-already-claimed'; return value; }
        if (!self.approved || !self.available || !self.permitted || self.evidence == nil || self.evidence == ''
            || !self.search.available || !self.search.permitted || !self.search.approved)
        { value.reason = 'rapid-salvage-author-facts'; return value; }
        local quote = project.proposal.assess();
        if (quote.status != 'ready') { value.reason = quote.reason; return value; }
        if (project.proposal.techLevel > project.proposal.inventor.techLevel)
        { value.reason = 'cinematic-advanced-defects-unavailable'; return value; }
        if (!holds(['testable','flawed'],project.theory))
        { value.reason = 'rapid-salvage-theory-required'; return value; }
        rpgInteger(self.search.result.projectCost,0,500);
        value.money = self.search.result.projectCost; value.partsMoney = value.money;
        value.acquisition = new RpgExpandedAcquisition(); value.acquisition.profile = self.payer;
        value.acquisition.item = self.item; value.acquisition.mode = 'purchase'; value.acquisition.quote = value.money;
        value.acquisition.available = true; value.acquisition.permitted = true;
        local access = value.acquisition.assess();
        if (access.status != 'ready') { value.reason = access.reason; return value; }
        value.status = 'ready'; return value;
    }
    acquire()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        if (value.acquisition.acquire().status != 'resolved') rpgExpandedReject('rapid-salvage-changed');
        self.search.claimedBy = self;
        self.search.project.rapidSalvages = self.search.project.rapidSalvages + [self];
        self.definitionSnapshot = self.definition(); value.status = 'resolved'; self.result = value; return value;
    }
;

modify RpgLiteItem
    rapidPrototypeReservation = nil
;
modify RpgExpandedRapidPurchase
    componentProject() { return self.project; }
;
modify RpgExpandedRapidSalvage
    componentProject() { return self.search.project; }
;
modify RpgExpandedRapidProposal
    rapidPrototypeReason()
    {
        local reason = self.technologyPermissionReason();
        if (reason != nil) return reason;
        return self.techLevel > self.inventor.techLevel ? 'cinematic-advanced-defects-unavailable' : nil;
    }
;
modify RpgExpandedPrototypeStart
    completionExecutionReason() { return nil; }
;

/** B476: reserve an acquired bundle and size rapid work without a second payment. */
class RpgExpandedRapidPrototypeStart: RpgExpandedPrototypeStart
    components = nil
    definition() { return inherited() + [self.components]; }
    completionExecutionReason() { return 'rapid-prototype-completion-unavailable'; }
    componentReason()
    {
        if (self.components == nil || !(self.components.ofKind(RpgExpandedRapidPurchase)
            || self.components.ofKind(RpgExpandedRapidSalvage)) || self.components.result == nil
            || self.components.componentProject() != self.project || self.components.payer != self.payer)
            rpgExpandedReject('rapid-prototype-components');
        self.components.assess();
        local item = self.components.item;
        if (item.rapidComponentSpent != nil) return 'rapid-prototype-components-spent';
        if (!holds(self.payer.equipment,item) || !item.usableBy(self.payer)) return 'rapid-prototype-components-unavailable';
        if (item.rapidPrototypeReservation != nil && item.rapidPrototypeReservation != self)
            return 'rapid-prototype-components-reserved';
        return nil;
    }
    participantReason()
    {
        local inventor = self.project.proposal.inventor;
        if (inventor.dead || inventor.unconscious || inventor.stunned || inventor.hp() <= 0 || inventor.fp() <= 0)
            return 'prototype-participant-unavailable';
        return nil;
    }
    assess()
    {
        if (self.project == nil || !self.project.ofKind(RpgExpandedInventionProject)
            || self.project.proposal == nil || !self.project.proposal.ofKind(RpgExpandedRapidProposal)
            || self.payer == nil || !self.payer.ofKind(RpgExpandedProfile)) rpgExpandedReject('rapid-prototype-definition');
        self.project.validate(); local value = new RpgExpandedPrototypeStartResult();
        if (self.result != nil)
        {
            local current = self.definition();
            if (self.definitionSnapshot == nil || current.length() != self.definitionSnapshot.length())
                rpgExpandedReject('prototype-start-binding');
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.definitionSnapshot[index]) rpgExpandedReject('prototype-start-binding');
            if (!holds(self.project.prototypes,self)) rpgExpandedReject('prototype-start-history');
            value.status = 'reused'; value.seconds = self.result.seconds;
            value.duration = self.result.duration; value.durationDice = self.result.durationDice; return value;
        }
        if (self.id == nil || self.id == '') rpgExpandedReject('prototype-start-id');
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'prototype-start-approval'; return value; }
        if (self.assistants.length() != 0 || self.monthDays.length() != 0 || self.extraSeconds != 0)
        { value.reason = 'rapid-prototype-team-calendar-unavailable'; return value; }
        value.reason = self.project.proposal.rapidPrototypeReason(); if (value.reason != nil) return value;
        if (!holds(['testable','flawed'],self.project.theory)) { value.reason = 'prototype-theory-required'; return value; }
        if (self.project.activePrototype != nil) { value.reason = 'prototype-already-active'; return value; }
        if (self.project.workingPrototype != nil) { value.reason = 'prototype-already-created'; return value; }
        foreach (local prior in self.project.prototypes)
            if (prior.id == self.id) rpgExpandedReject('prototype-start-duplicate');
        value.reason = self.componentReason(); if (value.reason != nil) return value;
        value.reason = self.participantReason(); if (value.reason != nil) return value;
        local quote = self.project.proposal.assess();
        if (quote.status != 'ready') { value.reason = quote.reason; return value; }
        value.modifier = rpgExpandedPrototypeTeamModifier(self.project.proposal,[],self.toolsPenalty);
        value.duration = quote.category; value.status = 'ready'; return value;
    }
    begin()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local count = value.duration == 'simple' ? 2 : value.duration == 'amazing' ? 4 : 1;
        for (local index = 1; index <= count; index += 1) value.durationDice = value.durationDice + [rpgRandom.die()];
        value.seconds = rpgExpandedRapidPrototypeSeconds(value.duration,value.durationDice);
        self.components.item.rapidPrototypeReservation = self; self.startedAt = rpgLedger.seconds;
        self.definitionSnapshot = self.definition(); self.project.prototypes = self.project.prototypes + [self];
        self.project.activePrototype = self; value.status = 'resolved'; self.result = value; return value;
    }
    workReason()
    {
        if (self.result == nil) return 'prototype-not-started';
        self.assess();
        if (self.project.activePrototype != self) return 'prototype-not-active';
        local reason = self.project.proposal.rapidPrototypeReason(); if (reason != nil) return reason;
        reason = self.componentReason(); if (reason != nil) return reason;
        if (self.components.item.rapidPrototypeReservation != self) return 'rapid-prototype-reservation-lost';
        reason = self.participantReason(); if (reason != nil) return reason;
        local quote = self.project.proposal.assess(); return quote.status == 'ready' ? nil : quote.reason;
    }
;

modify RpgLiteItem
    rapidComponentSpent = nil
;
modify RpgExpandedRapidPrototypeStart
    materialSettlement = nil
;
class RpgExpandedRapidMaterialResult: RpgExpandedResult
    disposition = nil
    item = nil
;

/** Settle the confirmed material consequence of a supplied secret prototype result. */
class RpgExpandedRapidMaterialSettlement: object
    attempt = nil
    outcome = nil
    result = nil
    definitionSnapshot = nil
    definition()
    {
        return [self.attempt,self.outcome,self.outcome.working,self.outcome.check.roll,
            self.outcome.check.critical,self.outcome.check.achieved];
    }
    assess()
    {
        if (self.attempt == nil || !self.attempt.ofKind(RpgExpandedRapidPrototypeStart)
            || self.attempt.result == nil || self.outcome == nil || !self.outcome.ofKind(RpgExpandedPrototypeOutcome)
            || self.outcome.check == nil || self.outcome.check.status != 'resolved')
            rpgExpandedReject('rapid-material-definition');
        self.attempt.assess(); local value = new RpgExpandedRapidMaterialResult();
        if (self.result != nil)
        {
            local current = self.definition();
            if (self.definitionSnapshot == nil || current.length() != self.definitionSnapshot.length())
                rpgExpandedReject('rapid-material-binding');
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.definitionSnapshot[index]) rpgExpandedReject('rapid-material-binding');
            if (self.attempt.materialSettlement != self) rpgExpandedReject('rapid-material-history');
            value.status = 'reused'; value.disposition = self.result.disposition; value.item = self.result.item; return value;
        }
        if (self.attempt.materialSettlement != nil) { value.reason = 'rapid-material-already-settled'; return value; }
        value.reason = self.attempt.workReason(); if (value.reason != nil) return value;
        if (self.attempt.workedSeconds != self.attempt.result.seconds)
        { value.reason = 'prototype-work-incomplete'; return value; }
        if (self.outcome.working && !self.outcome.check.achieved) rpgExpandedReject('rapid-material-outcome');
        value.item = self.attempt.components.item;
        value.disposition = self.outcome.check.critical == 'failure' ? 'ruined' : self.outcome.working ? 'incorporated' : 'retained';
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        if (value.disposition != 'retained')
        {
            local inventory = [];
            foreach (local item in self.attempt.payer.equipment)
                if (item != value.item) inventory = inventory + [item];
            self.attempt.payer.equipment = inventory;
            value.item.rapidComponentSpent = value.disposition; value.item.ready = nil; value.item.worn = nil;
        }
        value.item.rapidPrototypeReservation = nil;
        self.attempt.materialSettlement = self; self.definitionSnapshot = self.definition();
        value.status = 'resolved'; self.result = value; return value;
    }
;

modify RpgLiteItem
    inventionAnalyses = []
    inventionRevision = 0
;
class RpgExpandedDeviceAnalysisResult: RpgExpandedResult
    score = nil
    understood = nil
    deviceRevision = nil
;

/** B477: analyze an existing device; this does not create an invention theory. */
class RpgExpandedDeviceAnalysis: object
    id = nil
    proposal = nil
    item = nil
    knowledge = 'new'
    variantBonus = 0
    approved = nil
    available = nil
    permitted = nil
    uninterrupted = nil
    evidence = nil
    result = nil
    definitionSnapshot = nil
    definition()
    { return [self.id,self.proposal,self.item,self.knowledge,self.variantBonus,self.evidence] + self.proposal.definition(); }
    assess()
    {
        if (self.proposal == nil || !self.proposal.ofKind(RpgExpandedCinematicProposal)
            || self.item == nil || !self.item.ofKind(RpgLiteItem)) rpgExpandedReject('device-analysis-definition');
        local value = new RpgExpandedDeviceAnalysisResult();
        if (self.result != nil)
        {
            local current = self.definition();
            if (self.definitionSnapshot == nil || current.length() != self.definitionSnapshot.length())
                rpgExpandedReject('device-analysis-binding');
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.definitionSnapshot[index]) rpgExpandedReject('device-analysis-binding');
            if (!holds(self.item.inventionAnalyses,self)) rpgExpandedReject('device-analysis-history');
            value.status = 'reused'; value.check = self.result.check; value.score = self.result.score;
            value.understood = self.result.understood; value.deviceRevision = self.result.deviceRevision;
            value.seconds = self.result.seconds; return value;
        }
        if (self.id == nil || self.id == '' || !holds(['new','exists','model'],self.knowledge))
            rpgExpandedReject('device-analysis-request');
        rpgInteger(self.variantBonus,0,5); rpgInteger(self.item.inventionRevision,0,2147483647);
        if (!self.approved || !self.available || !self.permitted || !self.uninterrupted || self.evidence == nil || self.evidence == '')
        { value.reason = 'device-analysis-author-facts'; return value; }
        foreach (local prior in self.item.inventionAnalyses)
            if (prior.id == self.id) rpgExpandedReject('device-analysis-duplicate');
        local quote = self.proposal.assess();
        if (quote.status != 'ready') { value.reason = quote.reason; return value; }
        local inventor = self.proposal.inventor;
        if (inventor.dead || inventor.unconscious || inventor.stunned || inventor.hp() <= 0 || inventor.fp() <= 0)
        { value.reason = 'device-analysis-inventor-unavailable'; return value; }
        value.modifier = quote.conceptModifier + (self.knowledge == 'model' ? 5 : self.knowledge == 'exists' ? 2 : 0)
            + self.variantBonus;
        value.score = quote.skillScore + value.modifier; rpgInteger(value.score,-1000,1000);
        if (value.score < 3) { value.reason = 'too-difficult'; return value; }
        value.deviceRevision = self.item.inventionRevision; value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local current = self.definition(); local start = rpgLedger.seconds;
        local unit = self.proposal.permission.mode == 'rapid' ? 60 : 600;
        for (local die = 1; die <= 6; die += 1) rpgLedger.validateAdvance(die * unit);
        value.seconds = rpgRandom.die() * unit; rpgSpendTime(value.seconds);
        local changed = self.definition();
        if (changed.length() != current.length()) rpgExpandedReject('device-analysis-definition-changed');
        for (local index = 1; index <= current.length(); index += 1)
            if (current[index] != changed[index]) rpgExpandedReject('device-analysis-definition-changed');
        local refreshed = self.assess();
        if (refreshed.status != 'ready' || refreshed.deviceRevision != value.deviceRevision
            || rpgLedger.seconds != start + value.seconds) rpgExpandedReject('device-analysis-interrupted');
        value.score = refreshed.score; value.modifier = refreshed.modifier;
        value.check = rpgCheck(value.score,rpgRandom.roll()); value.understood = value.check.achieved;
        self.definitionSnapshot = current; self.item.inventionAnalyses = self.item.inventionAnalyses + [self];
        value.status = 'resolved'; self.result = value; return value;
    }
;

/** Persistent B483-B484 condition of one ordinary, non-sentient artifact. */
class RpgExpandedArtifactCondition: object
    item = nil
    capacity = nil
    health = (construction == 'unliving' ? 10 : 12)
    computer = nil
    construction = 'homogenous'
    sentient = nil
    fragile = nil
    subsystems = nil
    approved = nil
    evidence = nil
    injury = 0
    destroyed = nil
    disabled = nil
    wounds = []
    stresses = []
    facts()
    {
        if (self.item == nil || !self.item.ofKind(RpgLiteItem) || self.item.artifactCondition != self
            || self.item.quantity != 1) rpgExpandedReject('artifact-condition-owner');
        if (!holds(['homogenous','unliving'],self.construction) || self.sentient || self.fragile || self.subsystems)
            rpgExpandedReject('artifact-condition-special-adapter-required');
        if (self.computer != nil && (!self.computer.ofKind(RpgExpandedComputer)
            || self.computer.item != self.item || self.construction != 'unliving')) rpgExpandedReject('artifact-computer-owner');
        for (local host = firstObj(RpgExpandedComputer); host != nil; host = nextObj(host,RpgExpandedComputer))
            if (host.item == self.item && host != self.computer) rpgExpandedReject('artifact-computer-destruction-adapter-required');
        rpgInteger(self.capacity,1,1000000); rpgInteger(self.health,3,1000);
        if (!self.approved || self.evidence == nil || self.evidence == '') rpgExpandedReject('artifact-condition-author-facts');
        return [self,self.item,self.capacity,self.health,self.approved,self.evidence,self.construction,self.sentient,self.fragile,self.subsystems,self.computer];
    }
    validate()
    {
        self.facts(); local injury = 0; local destroyed = nil; local disabled = nil; local ids = [];
        foreach (local wound in self.wounds)
        {
            if (wound == nil || !wound.ofKind(RpgExpandedObjectWound) || wound.condition != self || holds(ids,wound.id)
                || destroyed || wound.before != injury || wound.recordedAt == nil || wound.recordedAt > rpgLedger.seconds) rpgExpandedReject('artifact-wound-history');
            wound.validateReceipt(); ids = ids + [wound.id]; injury += wound.amount;
            destroyed = wound.result.destroyed;
        }
        local lastAt = nil; ids = [];
        foreach (local stress in self.stresses)
        {
            if (stress == nil || !stress.ofKind(RpgExpandedArtifactStress) || stress.condition != self
                || holds(ids,stress.id) || disabled || lastAt != nil && stress.recordedAt <= lastAt)
                rpgExpandedReject('artifact-stress-history');
            stress.validateReceipt();
            rpgInteger(stress.woundCount,1,self.wounds.length()); local priorInjury = 0;
            for (local i = 1; i <= stress.woundCount; i += 1)
            {
                if (self.wounds[i].recordedAt > stress.recordedAt || self.wounds[i].result.destroyed)
                    rpgExpandedReject('artifact-stress-injury-order');
                priorInjury += self.wounds[i].amount;
            }
            if (priorInjury < self.capacity || stress.recordedAt > rpgLedger.seconds) rpgExpandedReject('artifact-stress-injury-basis');
            ids = ids + [stress.id]; lastAt = stress.recordedAt;
            if (!stress.result.check.achieved) disabled = true;
        }
        if (injury != self.injury || destroyed != self.destroyed || disabled != self.disabled) rpgExpandedReject('artifact-condition-history');
        if (self.computer != nil)
        {
            self.computer.validateHardwareHistory(); self.computer.used(); self.computer.usedStorageMB();
            local copyIds = [];
            foreach (local copy in self.computer.copies)
            {
                if (copy == nil || !copy.ofKind(RpgExpandedSoftwareCopy) || copy.host != self.computer
                    || copy.id == nil || copy.id == '' || holds(copyIds,copy.id)) rpgExpandedReject('artifact-computer-copy-inventory');
                copyIds = copyIds + [copy.id];
            }
            if ((destroyed || disabled) && self.computer.hardwareFailure == nil) rpgExpandedReject('artifact-computer-failure-missing');
        }
        return nil;
    }
    usable()
    {
        self.validate();
        if (self.destroyed || self.disabled) return nil;
        if (self.injury < self.capacity) return true;
        if (self.stresses.length() == 0) return nil;
        local stress = self.stresses[self.stresses.length()];
        return stress.recordedAt == rpgLedger.seconds && stress.result.check.achieved;
    }
    notifyUnavailable(cause)
    {
        if (self.computer != nil) self.computer.failArtifact(self,cause);
        self.item.ready = nil;
        for (local profile = firstObj(RpgLiteProfile); profile != nil; profile = nextObj(profile,RpgLiteProfile))
            if (holds(profile.equipment,self.item)) profile.onEquipmentUnavailable(self.item,cause);
        for (local fighter = firstObj(RpgLiteFighter); fighter != nil; fighter = nextObj(fighter,RpgLiteFighter))
            if (fighter.aimWeapon == self.item) { fighter.aimSeconds = 0; fighter.aimTarget = nil; fighter.aimWeapon = nil; }
        return nil;
    }
    shockModifier()
    {
        self.validate(); local penalty = 0;
        foreach (local wound in self.wounds)
            if (rpgLedger.seconds <= wound.recordedAt+1)
            {
                local divisor = self.capacity < 20 ? 1 : self.capacity/10;
                local amount = wound.amount/divisor; if (amount > 4) amount = 4;
                if (amount > penalty) penalty = amount;
            }
        return -penalty;
    }
;
modify RpgLiteItem
    artifactCondition = nil
    usableBy(profile)
    { return (self.artifactCondition == nil || self.artifactCondition.usable()) && inherited(profile); }
    artifactUseModifier() { return self.artifactCondition == nil ? 0 : self.artifactCondition.shockModifier(); }
;
class RpgExpandedObjectWoundResult: RpgExpandedResult
    checks = []
    destroyed = nil
    assessment = nil
;
/** Final injury after protection/type effects. The author supplies that resolved injury, not a callback. */
class RpgExpandedObjectWound: object
    id = nil
    condition = nil
    amount = 0
    approved = nil
    evidence = nil
    result = nil
    before = nil
    recordedAt = nil
    boundFacts = nil
    boundOutcome = nil
    facts()
    {
        if (self.id == nil || self.id == '' || self.condition == nil || !self.condition.ofKind(RpgExpandedArtifactCondition))
            rpgExpandedReject('object-wound-definition');
        rpgInteger(self.amount,0,100000000);
        return [self,self.id,self.condition,self.amount,self.approved,self.evidence] + self.condition.facts();
    }
    outcomeFacts()
    {
        local assessment = self.result.assessment;
        local facts = [self.result,self.result.status,self.result.destroyed,self.before,self.recordedAt,self.result.checks.length(),
            assessment,assessment.remaining,assessment.automaticDestruction,assessment.stressChecksRequired,
            assessment.reducedEffectivenessEligible,assessment.majorDamage,assessment.destructionThresholds.length()]
            + assessment.destructionThresholds;
        foreach (local check in self.result.checks) facts = facts + [check,check.score,check.roll,check.achieved,check.margin,check.critical];
        return facts;
    }
    validateReceipt()
    {
        if (self.result == nil || !holds(self.condition.wounds,self)) rpgExpandedReject('object-wound-receipt');
        local facts = self.facts();
        if (self.boundFacts == nil || facts.length() != self.boundFacts.length()) rpgExpandedReject('object-wound-binding');
        for (local i = 1; i <= facts.length(); i += 1) if (facts[i] != self.boundFacts[i]) rpgExpandedReject('object-wound-binding');
        facts = self.outcomeFacts();
        if (self.boundOutcome == nil || facts.length() != self.boundOutcome.length()) rpgExpandedReject('object-wound-outcome');
        for (local i = 1; i <= facts.length(); i += 1) if (facts[i] != self.boundOutcome[i]) rpgExpandedReject('object-wound-outcome');
        return nil;
    }
    assess()
    {
        self.facts(); local value = new RpgExpandedObjectWoundResult();
        if (self.result != nil) { self.validateReceipt(); value.status = 'reused'; return value; }
        if (self.before != nil || self.recordedAt != nil || self.boundFacts != nil || self.boundOutcome != nil)
            rpgExpandedReject('object-wound-uncommitted');
        self.condition.validate();
        if (self.condition.destroyed) { value.reason = 'object-already-destroyed'; return value; }
        if (!self.approved || self.evidence == nil || self.evidence == '') { value.reason = 'object-injury-evidence'; return value; }
        foreach (local prior in self.condition.wounds) if (prior.id == self.id) rpgExpandedReject('object-wound-duplicate');
        rpgInteger(self.amount,0,100000000-self.condition.injury);
        value.assessment = rpgExpandedObjectInjury(self.condition.capacity,self.condition.injury,self.amount);
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.before = self.condition.injury; self.recordedAt = rpgLedger.seconds; self.boundFacts = self.facts();
        value.destroyed = value.assessment.automaticDestruction;
        if (!value.destroyed)
            foreach (local threshold in value.assessment.destructionThresholds)
            {
                local check = rpgCheck(self.condition.health,rpgRandom.roll()); value.checks = value.checks + [check];
                if (!check.achieved) { value.destroyed = true; break; }
            }
        self.condition.injury += self.amount; self.condition.destroyed = value.destroyed;
        self.condition.wounds = self.condition.wounds + [self]; value.status = 'resolved'; self.result = value;
        self.boundOutcome = self.outcomeFacts();
        if (value.destroyed) self.condition.notifyUnavailable('destroyed');
        return value;
    }
;
/** B483: a damaged artifact's actual use requires one retained HT check for this second. */
class RpgExpandedArtifactStress: object
    id = nil
    condition = nil
    approved = nil
    evidence = nil
    recordedAt = nil
    woundCount = nil
    result = nil
    boundFacts = nil
    facts()
    { return [self,self.id,self.condition,self.approved,self.evidence,self.recordedAt,self.woundCount] + self.condition.facts(); }
    validateReceipt()
    {
        if (self.result == nil || !holds(self.condition.stresses,self)) rpgExpandedReject('artifact-stress-receipt');
        local check = self.result.check; local facts = self.facts() + [check,check.score,check.roll,check.achieved,check.margin,check.critical];
        if (self.boundFacts == nil || facts.length() != self.boundFacts.length()) rpgExpandedReject('artifact-stress-binding');
        for (local i = 1; i <= facts.length(); i += 1) if (facts[i] != self.boundFacts[i]) rpgExpandedReject('artifact-stress-binding');
        return nil;
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.condition == nil || !self.condition.ofKind(RpgExpandedArtifactCondition))
            rpgExpandedReject('artifact-stress-definition');
        local value = new RpgExpandedResult();
        if (self.result != nil) { self.validateReceipt(); value.status = 'reused'; return value; }
        if (self.recordedAt != nil || self.woundCount != nil || self.boundFacts != nil) rpgExpandedReject('artifact-stress-uncommitted');
        self.condition.validate();
        if (self.condition.injury < self.condition.capacity || self.condition.destroyed || self.condition.disabled)
        { value.reason = 'artifact-stress-inapplicable'; return value; }
        if (!self.approved || self.evidence == nil || self.evidence == '') { value.reason = 'artifact-stress-use-evidence'; return value; }
        foreach (local prior in self.condition.stresses)
            if (prior.id == self.id || prior.recordedAt == rpgLedger.seconds) rpgExpandedReject('artifact-stress-duplicate');
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        value.check = rpgCheck(self.condition.health,rpgRandom.roll()); self.recordedAt = rpgLedger.seconds;
        self.woundCount = self.condition.wounds.length();
        if (!value.check.achieved) self.condition.disabled = true;
        self.condition.stresses = self.condition.stresses + [self]; value.status = 'resolved'; self.result = value;
        local check = value.check;
        self.boundFacts = self.facts() + [check,check.score,check.roll,check.achieved,check.margin,check.critical];
        if (!check.achieved) self.condition.notifyUnavailable('disabled'); return value;
    }
;

/** A B361 authored destructive reaction commits the separately adjudicated object injury. */
class RpgExpandedPanicObjectOperation: RpgExpandedPanicOperation
    owner = nil
    wound = nil
    permission = nil
    targetOwner = nil
    approved = nil
    evidence = nil
    result = nil
    boundFacts = nil
    boundOutcome = nil
    facts(reaction)
    {
        if (self.wound == nil || !self.wound.ofKind(RpgExpandedObjectWound)
            || self.targetOwner == nil || !self.targetOwner.ofKind(RpgLiteProfile)
            || self.permission == nil || !self.permission.ofKind(RpgExpandedPanicObjectPermission)
            || reaction.operation != self || self.ownsTime)
            rpgExpandedReject('panic-object-definition');
        return [self,self.profile,reaction,self.wound,self.targetOwner,self.approved,self.evidence,self.permission]
            + self.wound.facts() + self.permission.facts(reaction);
    }
    permitsAuthorization(request)
    { return self.result == nil && self.permission != nil && request == self.permission.gate; }
    outcomeFacts()
    { return [self.result,self.result.status,self.result.allowed,self.result.reason,
        self.permission.gate.result,self.permission.gate.result.allowed,self.wound.result]; }
    validateReceipt(reaction)
    {
        local facts = self.facts(reaction);
        if (self.owner != reaction || self.result == nil || self.boundOutcome == nil
            || self.boundFacts == nil || facts.length() != self.boundFacts.length()) rpgExpandedReject('panic-object-receipt');
        for (local i = 1; i <= facts.length(); i += 1) if (facts[i] != self.boundFacts[i]) rpgExpandedReject('panic-object-binding');
        self.permission.validateReceipt(reaction); facts = self.outcomeFacts();
        if (facts.length() != self.boundOutcome.length()) rpgExpandedReject('panic-object-outcome');
        for (local i = 1; i <= facts.length(); i += 1) if (facts[i] != self.boundOutcome[i]) rpgExpandedReject('panic-object-outcome');
        if (self.result.allowed) self.wound.validateReceipt();
        else if (self.wound.result != nil) rpgExpandedReject('panic-object-incapacitated-injury');
        return nil;
    }
    assess(reaction)
    {
        self.facts(reaction); local value = new RpgExpandedResult();
        if (self.result != nil) { self.validateReceipt(reaction); value.status = 'reused'; return value; }
        if (self.owner != nil || self.boundFacts != nil || self.boundOutcome != nil) rpgExpandedReject('panic-object-uncommitted');
        if (!self.approved || self.evidence == nil || self.evidence == '') { value.reason = 'panic-object-target-adjudication'; return value; }
        if (!holds(self.targetOwner.equipment,self.wound.condition.item)) { value.reason = 'panic-object-target-owner'; return value; }
        local permission = self.permission.assess(reaction);
        if (permission.status == 'reused') rpgExpandedReject('panic-object-used-permission');
        if (permission.status != 'ready') return permission;
        if (self.wound.assess().status == 'reused') rpgExpandedReject('panic-object-used-injury');
        return self.wound.assess();
    }
    apply(reaction)
    {
        local value = self.assess(reaction); if (value.status != 'ready') return value;
        if (reaction.episode.settlingReaction != reaction) rpgExpandedReject('panic-object-reaction-owner');
        self.owner = reaction; self.boundFacts = self.facts(reaction);
        local permission = self.permission.apply(reaction);
        if (permission.status != 'resolved') rpgExpandedReject('panic-object-permission-changed');
        value = new RpgExpandedResult(); value.allowed = permission.allowed; value.reason = permission.reason;
        if (value.allowed && self.wound.apply().status != 'resolved') rpgExpandedReject('panic-object-injury-changed');
        value.status = 'resolved'; self.result = value; self.boundOutcome = self.outcomeFacts(); return value;
    }
;

/** B483-B484 computer hardware failure: process/storage history survives, contents do not. */
class RpgExpandedComputerFailure: object
    host = nil
    condition = nil
    cause = nil
    trigger = nil
    recordedAt = nil
    stoppedRuns = []
    erasedCopies = []
    erasedData = []
    boundFacts = nil
    facts()
    {
        if (self.host == nil || !self.host.ofKind(RpgExpandedComputer) || self.condition == nil
            || !self.condition.ofKind(RpgExpandedArtifactCondition) || self.condition.computer != self.host
            || self.host.item != self.condition.item || !holds(['disabled','destroyed'],self.cause))
            rpgExpandedReject('computer-failure-owner');
        local facts = [self,self.host,self.condition,self.cause,self.trigger,self.recordedAt,
            self.stoppedRuns.length(),self.erasedCopies.length(),self.erasedData.length()] + self.condition.facts();
        foreach (local run in self.stoppedRuns) facts = facts + [run,run.id,run.host,run.copy,run.startedAt,run.stoppedAt];
        foreach (local copy in self.erasedCopies) facts = facts + [copy,copy.id,copy.host,copy.complexity];
        foreach (local record in self.erasedData)
            facts = facts + [record,record.id,record.host,record.reference,record.sizeMB,record.storedAt,record.removedAt];
        return facts;
    }
    validateReceipt()
    {
        local facts = self.facts();
        if (self.boundFacts == nil || facts.length() != self.boundFacts.length() || self.recordedAt == nil
            || self.recordedAt > rpgLedger.seconds || !holds(self.host.hardwareFailures,self))
            rpgExpandedReject('computer-failure-history');
        for (local i = 1; i <= facts.length(); i += 1)
            if (facts[i] != self.boundFacts[i]) rpgExpandedReject('computer-failure-binding');
        if (self.cause == 'destroyed')
        {
            if (!self.trigger.ofKind(RpgExpandedObjectWound) || self.trigger.condition != self.condition
                || !self.trigger.result.destroyed || !self.condition.destroyed) rpgExpandedReject('computer-destruction-trigger');
            self.trigger.validateReceipt();
        }
        else
        {
            if (!self.trigger.ofKind(RpgExpandedArtifactStress) || self.trigger.condition != self.condition
                || self.trigger.result.check.achieved || !self.condition.disabled) rpgExpandedReject('computer-disable-trigger');
            self.trigger.validateReceipt();
        }
        if (self.trigger.recordedAt != self.recordedAt) rpgExpandedReject('computer-failure-time');
        foreach (local run in self.stoppedRuns)
        {
            run.validateBinding();
            if (run.active || run.stoppedAt != self.recordedAt) rpgExpandedReject('computer-failure-running-process');
        }
        foreach (local copy in self.erasedCopies)
            if (holds(self.host.copies,copy)) rpgExpandedReject('computer-failure-restored-copy');
        foreach (local record in self.erasedData)
        {
            record.validateBinding();
            if (record.present || record.removedAt != self.recordedAt) rpgExpandedReject('computer-failure-restored-data');
        }
        return nil;
    }
;
modify RpgExpandedComputer
    hardwareFailures = []
    hardwareFailure = nil
    validateHardwareHistory()
    {
        local previous = nil;
        foreach (local failure in self.hardwareFailures)
        {
            if (failure == nil || !failure.ofKind(RpgExpandedComputerFailure) || failure.host != self
                || previous != nil && (previous.cause == 'destroyed' || previous.recordedAt > failure.recordedAt))
                rpgExpandedReject('computer-failure-order');
            failure.validateReceipt(); previous = failure;
        }
        if (self.hardwareFailure != previous) rpgExpandedReject('computer-current-failure');
        if (previous != nil)
        {
            foreach (local run in self.runs) if (run.active) rpgExpandedReject('computer-failed-process-active');
            if (previous.cause == 'destroyed')
            {
                if (self.copies.length() != 0) rpgExpandedReject('computer-destroyed-software');
                foreach (local record in self.data) if (record.present) rpgExpandedReject('computer-destroyed-data');
            }
        }
        return nil;
    }
    hardwareAvailable()
    {
        self.validateHardwareHistory();
        if (self.item == nil || !self.item.ofKind(RpgLiteItem) || self.item.environmentFailure != nil
            || self.hardwareFailure != nil) return nil;
        return self.item.artifactCondition == nil || self.item.artifactCondition.usable();
    }
    failArtifact(condition,cause)
    {
        if (condition == nil || condition.computer != self || condition.item != self.item
            || !holds(['disabled','destroyed'],cause)) rpgExpandedReject('computer-failure-request');
        self.validateHardwareHistory();
        local trigger = cause == 'destroyed' ? condition.wounds[condition.wounds.length()]
            : condition.stresses[condition.stresses.length()];
        foreach (local prior in self.hardwareFailures)
            if (prior.trigger == trigger) { prior.validateReceipt(); return prior; }
        if (cause == 'destroyed' && !condition.destroyed || cause == 'disabled' && !condition.disabled)
            rpgExpandedReject('computer-failure-state');
        local failure = new RpgExpandedComputerFailure(); failure.host = self; failure.condition = condition;
        failure.cause = cause; failure.trigger = trigger; failure.recordedAt = rpgLedger.seconds;
        foreach (local run in self.runs)
        {
            run.validateBinding();
            if (run.active) { run.stop(); failure.stoppedRuns = failure.stoppedRuns + [run]; }
        }
        if (cause == 'destroyed')
        {
            local ids = [];
            foreach (local copy in self.copies)
            {
                if (copy == nil || !copy.ofKind(RpgExpandedSoftwareCopy) || copy.host != self
                    || holds(ids,copy.id)) rpgExpandedReject('computer-destruction-copy-inventory');
                ids = ids + [copy.id]; failure.erasedCopies = failure.erasedCopies + [copy];
            }
            self.copies = [];
            foreach (local record in self.data)
            {
                record.validateBinding();
                if (record.present)
                {
                    record.present = nil; record.removedAt = rpgLedger.seconds;
                    failure.erasedData = failure.erasedData + [record];
                }
            }
        }
        self.powered = nil; self.hardwareFailures = self.hardwareFailures + [failure]; self.hardwareFailure = failure;
        failure.boundFacts = failure.facts(); failure.validateReceipt(); return failure;
    }
;

modify RpgExpandedProfile
    validateAttentionRepair(repair)
    {
        if (repair == nil || !repair.ofKind(RpgExpandedBreakdownRepair) || repair.repairer != self)
            rpgExpandedReject('attention-repair-ownership');
        return nil;
    }
;
