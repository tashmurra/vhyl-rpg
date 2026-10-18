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
        if (self.failure.result.repair == 'major') self.failure.parts.install();
        rpgSpendTime(value.seconds);
        value.check = rpgLiteCheck(self.repairer,value.context);
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
        if (!self.host.powered || self.host.item.environmentFailure != nil)
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
        if (!self.terminal.powered || !self.target.powered || self.target.item == nil
            || !self.target.item.ofKind(RpgLiteItem) || self.target.item.environmentFailure != nil)
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
            || self.host.item.environmentFailure != nil)
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
            || self.host.item.environmentFailure != nil) rpgExpandedReject('computer-unavailable');
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
