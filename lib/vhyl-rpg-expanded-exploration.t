/* Include after the expanded foundation. Source: full-2008, B346. */

/** Pure task-time assessment. Positive steps select 2/4/8/15/30 times normal;
 * negative steps remove 10% each. The caller must authorize applicability. */
class RpgExpandedTaskTime: object
    baseSeconds = 1
    steps = 0
    applicable = nil
    combat = nil
    assess(rules)
    {
        rpgInteger(self.baseSeconds, 1, 1000000); rpgInteger(self.steps, -10, 5);
        local result = new RpgExpandedResult();
        if (self.steps != 0 && (!self.applicable || self.combat))
        { result.reason = 'task-time-inapplicable'; return result; }
        if (self.steps == -10 && !rules.cinematicInstantTasks)
        { result.reason = 'instant-task-disabled'; return result; }
        result.status = 'ready'; result.modifier = self.steps;
        result.seconds = self.steps >= 0
            ? self.baseSeconds * [1,2,4,8,15,30][self.steps + 1]
            : (self.baseSeconds * (10 + self.steps) + 9) / 10;
        return result;
    }
;

/** Pure breath duration; round the final character feat down (B9, B351-B352). */
rpgExpandedBreathDuration(health, activity, prepared, ventilation, controlSucceeded, reserveLevels)
{
    rpgInteger(health,1,1000); rpgInteger(reserveLevels,0,10);
    if (!holds(['none','mild','heavy'],activity)) rpgExpandedReject('breath-activity');
    if (!holds(['none','air','oxygen'],ventilation)) rpgExpandedReject('breath-ventilation');
    local value = new RpgExpandedResult();
    if (!prepared && ventilation != 'none')
    { value.reason = 'breath-ventilation-preparation'; return value; }
    local numerator = health * (activity == 'none' ? 10 : activity == 'mild' ? 4 : 1);
    local denominator = 1;
    if (!prepared) denominator *= 2;
    if (ventilation != 'none') { numerator *= ventilation == 'air' ? 3 : 5; denominator *= 2; }
    if (controlSucceeded) { numerator *= 3; denominator *= 2; }
    for (local level = 0; level < reserveLevels; level += 1) numerator *= 2;
    value.seconds = numerator / denominator; value.status = 'ready'; return value;
}

class RpgExpandedBreathAssessment: RpgExpandedResult
    elapsedSeconds = 0
    remainingSeconds = 0
    exhausted = nil
;

modify RpgExpandedProfile
    breathReserve = nil
    breathHistory = []
;

/** Owned fixed-activity breath reserve. Preparation is an authored prior action. */
class RpgExpandedBreathReserve: object
    id = nil
    profile = nil
    activity = 'mild'
    prepared = true
    preparation = nil
    boundPreparation = nil
    ventilation = 'none'
    controlSucceeded = nil
    reserveLevels = 0
    usePurchasedReserve = nil
    boundPurchasedReserve = nil
    evidence = nil
    startedAt = nil
    endedAt = nil
    airEvidence = nil
    durationSeconds = 0
    boundId = nil
    boundProfile = nil
    boundActivity = nil
    boundPrepared = nil
    boundVentilation = nil
    boundControl = nil
    boundLevels = 0
    boundEvidence = nil
    startingHealth = 0
    validateBinding()
    {
        if (self.id != self.boundId || self.profile != self.boundProfile || self.activity != self.boundActivity
            || self.prepared != self.boundPrepared || self.ventilation != self.boundVentilation
            || self.controlSucceeded != self.boundControl || self.reserveLevels != self.boundLevels
            || self.preparation != self.boundPreparation || self.usePurchasedReserve != self.boundPurchasedReserve
            || self.evidence != self.boundEvidence || !holds(self.profile.breathHistory,self))
            rpgExpandedReject('breath-binding');
        if (self.preparation != nil)
        {
            self.preparation.validateReceipt();
            if (self.preparation.usedBy != self || self.preparation.profile != self.profile
                || self.preparation.completedAt != self.startedAt
                || self.controlSucceeded != (self.preparation.result.check != nil && self.preparation.result.check.achieved))
                rpgExpandedReject('breath-preparation-reserve-binding');
        }
        return nil;
    }
    start()
    {
        local value = new RpgExpandedResult();
        if (self.startedAt != nil)
        { self.validateBinding(); value.status = 'reused'; value.seconds = self.durationSeconds; return value; }
        if (self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)) rpgExpandedReject('breath-profile');
        if (self.id == nil || self.id == '') rpgExpandedReject('breath-id');
        if (self.evidence == nil || self.evidence == '') { value.reason = 'breath-preparation-evidence'; return value; }
        if (self.profile.dead || self.profile.unconscious || self.profile.stunned || self.profile.mentalStun)
        { value.reason = 'breath-incapacitated'; return value; }
        if (self.profile.breathReserve != nil || self.profile.airClock != 0)
        { value.reason = 'breath-existing-exposure'; return value; }
        self.profile.validateBreathStart();
        foreach (local prior in self.profile.breathHistory)
            if (prior.id == self.id) rpgExpandedReject('breath-duplicate');
        local control = self.controlSucceeded;
        if (self.preparation != nil)
        {
            if (!self.preparation.ofKind(RpgExpandedBreathPreparation)) rpgExpandedReject('breath-preparation-definition');
            if (self.preparation.result == nil) { value.reason = 'breath-preparation-not-completed'; return value; }
            self.preparation.validateReceipt();
            if (self.preparation.profile != self.profile || self.preparation.usedBy != nil
                || self.preparation.completedAt != rpgLedger.seconds || !self.prepared || self.ventilation != 'none')
            { value.reason = 'breath-preparation-not-applicable'; return value; }
            control = self.preparation.result.check != nil && self.preparation.result.check.achieved;
        }
        local levels = self.usePurchasedReserve ? self.profile.purchasedBreathReserveLevels() : self.reserveLevels;
        value = rpgExpandedBreathDuration(self.profile.ht,self.activity,self.prepared,self.ventilation,control,levels);
        if (value.status != 'ready') return value;
        self.reserveLevels = levels; self.boundPurchasedReserve = self.usePurchasedReserve;
        self.controlSucceeded = control; self.boundPreparation = self.preparation;
        if (self.preparation != nil) self.preparation.usedBy = self;
        self.boundId = self.id; self.boundProfile = self.profile; self.boundActivity = self.activity;
        self.boundPrepared = self.prepared; self.boundVentilation = self.ventilation; self.boundControl = self.controlSucceeded;
        self.boundLevels = self.reserveLevels; self.boundEvidence = self.evidence; self.startingHealth = self.profile.ht;
        self.durationSeconds = value.seconds; self.startedAt = rpgLedger.seconds;
        self.profile.breathReserve = self; self.profile.breathHistory = self.profile.breathHistory + [self];
        value.status = 'resolved'; return value;
    }
    assess()
    {
        local value = new RpgExpandedBreathAssessment();
        if (self.startedAt == nil) { value.reason = 'breath-not-started'; return value; }
        self.validateBinding();
        local until = self.endedAt == nil ? rpgLedger.seconds : self.endedAt;
        value.elapsedSeconds = until - self.startedAt;
        value.remainingSeconds = self.durationSeconds - value.elapsedSeconds;
        if (value.remainingSeconds <= 0) { value.remainingSeconds = 0; value.exhausted = true; }
        value.seconds = self.durationSeconds; value.status = 'ready'; return value;
    }
    validateEnd()
    {
        if (self.endedAt < self.startedAt || self.endedAt > rpgLedger.seconds
            || self.endedAt > self.startedAt + self.durationSeconds || self.airEvidence == nil)
            rpgExpandedReject('breath-end-history');
        return nil;
    }
    resumeAir(evidence)
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        if (self.endedAt != nil) { value.status = 'reused'; return value; }
        if (evidence == nil || evidence == '')
        { value.status = 'blocked'; value.reason = 'breath-clean-air-evidence'; return value; }
        if (value.elapsedSeconds > self.durationSeconds)
        { value.status = 'blocked'; value.reason = 'breath-suffocation-unresolved'; return value; }
        if (self.profile.breathReserve != self) rpgExpandedReject('breath-owner');
        self.endedAt = rpgLedger.seconds; self.airEvidence = evidence; self.profile.breathReserve = nil;
        value.status = 'resolved'; return value;
    }
;

modify RpgExpandedProfile
    validateFeatures()
    {
        inherited(); local ids = []; local active = nil;
        foreach (local reserve in self.breathHistory)
        {
            if (reserve == nil || !reserve.ofKind(RpgExpandedBreathReserve) || reserve.profile != self
                || holds(ids,reserve.id) || reserve.startedAt == nil || reserve.startedAt > rpgLedger.seconds)
                rpgExpandedReject('breath-history');
            reserve.validateBinding(); ids = ids + [reserve.id];
            local duration = rpgExpandedBreathDuration(reserve.startingHealth,reserve.activity,reserve.prepared,
                reserve.ventilation,reserve.controlSucceeded,reserve.reserveLevels);
            if (duration.status != 'ready' || duration.seconds != reserve.durationSeconds) rpgExpandedReject('breath-duration-history');
            if (reserve.endedAt == nil)
            {
                if (active != nil) rpgExpandedReject('breath-multiple-reserves');
                active = reserve;
            }
            else reserve.validateEnd();
        }
        if (self.breathReserve != active) rpgExpandedReject('breath-active-history');
        return nil;
    }
;

modify RpgExpandedProfile
    validateSuffocation()
    {
        inherited();
        if (self.breathReserve != nil) rpgExpandedReject('suffocation-breath-reserve-owned');
        return nil;
    }
;

class RpgExpandedSwimmingOutcome: RpgExpandedResult
    nextStage = nil
    fatigue = 0
    inhaledWater = nil
;

/** Deep-water balance modifiers, full-2008 B354. */
rpgExpandedSwimmingModifier(intentionalEntry, encumbrance, build)
{
    rpgInteger(encumbrance,0,4);
    if (!holds(['ordinary','overweight','fat','very-fat'],build)) rpgExpandedReject('swimming-build');
    return (intentionalEntry ? 3 : 0) - 2 * encumbrance
        + (build == 'overweight' ? 1 : build == 'fat' ? 3 : build == 'very-fat' ? 5 : 0);
}

/** Supplied swimming roll selects the next balance-check boundary, B354. */
rpgExpandedSwimmingOutcome(stage, score, roll)
{
    if (!holds(['entry','stable','struggling','recovering'],stage)) rpgExpandedReject('swimming-stage');
    rpgInteger(score,3,1000); local value = new RpgExpandedSwimmingOutcome(); value.check = rpgCheck(score,roll);
    if (!value.check.achieved)
    {
        value.nextStage = 'struggling'; value.seconds = 5; value.fatigue = 1; value.inhaledWater = true;
    }
    else if (stage == 'struggling') { value.nextStage = 'recovering'; value.seconds = 60; }
    else { value.nextStage = 'stable'; value.seconds = 300; }
    value.status = 'ready'; return value;
}

class RpgExpandedLifesavingOutcome: RpgExpandedResult
    fatigue = 0
    inhaledWater = nil
    rescued = nil
    mustBreakOff = nil
;

/** Rescue target modifier before ordinary skill context modifiers, B355. */
rpgExpandedLifesavingModifier(rescuerStrength, victimStrength, techniqueBonus)
{
    rpgInteger(rescuerStrength,1,1000); rpgInteger(victimStrength,1,1000); rpgInteger(techniqueBonus,0,1000);
    return -5 + rescuerStrength - victimStrength + techniqueBonus;
}

/** Failure retry and critical-failure break-off are distinct outcomes, B355. */
rpgExpandedLifesavingOutcome(score, roll)
{
    rpgInteger(score,3,1000); local value = new RpgExpandedLifesavingOutcome(); value.check = rpgCheck(score,roll);
    value.rescued = value.check.achieved;
    if (!value.rescued)
    {
        value.inhaledWater = true;
        if (value.check.critical == 'failure') { value.fatigue = 6; value.mustBreakOff = true; }
        else { value.fatigue = 1; value.seconds = 60; }
    }
    value.status = 'ready'; return value;
}

class RpgExpandedSwimmingDefaultContext: RpgLiteContext
    attribute = rpgHT
    kind = 'swimming'
    scoreFor(profile)
    {
        local health = profile.attributeScore(rpgHT);
        return (health > 20 ? 20 : health) - 4;
    }
;

class RpgExpandedSwimAssessment: RpgExpandedSwimmingOutcome
    wound = nil
    context = nil
;

modify RpgExpandedProfile
    swimmingEncounter = nil
    swimmingHistory = []
;

/** Fixed entry circumstances; equipment load is read afresh for each check. */
class RpgExpandedSwimmingEncounter: object
    submersion = nil
    id = nil
    profile = nil
    skill = nil
    defaultAvailable = nil
    intentionalEntry = nil
    build = 'ordinary'
    pace = 'floating'
    evidence = nil
    startedAt = nil
    endedAt = nil
    exitEvidence = nil
    stage = 'entry'
    nextCheckAt = nil
    nextEnduranceAt = nil
    enduranceChecks = []
    checks = []
    boundId = nil
    boundProfile = nil
    boundSkill = nil
    boundDefaultAvailable = nil
    boundIntentional = nil
    boundBuild = nil
    boundPace = nil
    boundEvidence = nil
    validateBinding()
    {
        if (self.id != self.boundId || self.profile != self.boundProfile || self.skill != self.boundSkill
            || self.defaultAvailable != self.boundDefaultAvailable
            || self.intentionalEntry != self.boundIntentional || self.build != self.boundBuild
            || self.pace != self.boundPace || self.evidence != self.boundEvidence || !holds(self.profile.swimmingHistory,self))
            rpgExpandedReject('swimming-binding');
        return nil;
    }
    assessStart()
    {
        local value = new RpgExpandedResult();
        if (self.startedAt != nil) { self.validateBinding(); value.status = 'reused'; return value; }
        if (self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)) rpgExpandedReject('swimming-profile');
        if (self.id == nil || self.id == '') rpgExpandedReject('swimming-id');
        if (self.evidence == nil || self.evidence == '') { value.reason = 'swimming-entry-evidence'; return value; }
        if (self.profile.swimmingEncounter != nil) { value.reason = 'swimming-encounter-active'; return value; }
        if (self.profile.dead || self.profile.unconscious) { value.reason = 'swimming-incapacitated'; return value; }
        if (self.skill != nil && (!self.skill.ofKind(RpgLiteSkill) || self.skill.id != 'swimming'
            || self.skill.attribute != rpgHT || self.skill.difficulty != 0)) rpgExpandedReject('swimming-skill-definition');
        self.profile.validateSuffocation();
        rpgExpandedSwimmingModifier(self.intentionalEntry,0,self.build);
        if (!holds(['top-speed','slow','floating'],self.pace)) rpgExpandedReject('swimming-pace');
        foreach (local prior in self.profile.swimmingHistory)
            if (prior.id == self.id) rpgExpandedReject('swimming-duplicate');
        rpgInteger(rpgLedger.seconds,0,2147481847);
        value.status = 'ready'; return value;
    }
    start()
    {
        local value = self.assessStart(); if (value.status != 'ready') return value;
        self.boundId = self.id; self.boundProfile = self.profile; self.boundSkill = self.skill;
        self.boundDefaultAvailable = self.defaultAvailable;
        self.boundIntentional = self.intentionalEntry; self.boundBuild = self.build; self.boundEvidence = self.evidence; self.boundPace = self.pace;
        self.startedAt = rpgLedger.seconds; self.nextCheckAt = self.startedAt;
        self.nextEnduranceAt = self.startedAt + (self.pace == 'top-speed' ? 60 : 1800);
        self.profile.swimmingEncounter = self; self.profile.swimmingHistory = self.profile.swimmingHistory + [self];
        if (self.profile.fp() <= 0)
        {
            self.exhaustedOnEntry = true; self.recordExhaustion(); self.lastWillAt = self.startedAt - 1;
        }
        value.status = 'resolved'; return value;
    }
    leave(evidence)
    {
        local value = new RpgExpandedResult();
        if (self.startedAt == nil) { value.reason = 'swimming-not-started'; return value; }
        self.validateBinding();
        if (self.endedAt != nil) { value.status = 'reused'; return value; }
        if (evidence == nil || evidence == '') { value.reason = 'swimming-exit-evidence'; return value; }
        if (self.stage == 'struggling') { value.reason = 'swimming-rescue-required'; return value; }
        if (rpgLedger.seconds >= self.nextCheckAt) { value.reason = 'swimming-unresolved-check'; return value; }
        if (rpgLedger.seconds >= self.nextEnduranceAt) { value.reason = 'swimming-unresolved-endurance'; return value; }
        if (self.profile.swimmingEncounter != self) rpgExpandedReject('swimming-owner');
        self.endedAt = rpgLedger.seconds; self.exitEvidence = evidence; self.profile.swimmingEncounter = nil;
        value.status = 'resolved'; return value;
    }
;

/** Owned balance check; exhausted swimmers require the unfinished drowning path. */
class RpgExpandedSwimCheck: object
    id = nil
    dropDestination = nil
    boundDestination = nil
    encounter = nil
    completedAt = nil
    result = nil
    boundId = nil
    boundEncounter = nil
    stageBefore = nil
    assess()
    {
        local value = new RpgExpandedSwimAssessment();
        if (self.encounter == nil || !self.encounter.ofKind(RpgExpandedSwimmingEncounter)) rpgExpandedReject('swimming-check-encounter');
        if (self.encounter.startedAt == nil) { value.reason = 'swimming-not-started'; return value; }
        self.encounter.validateBinding();
        if (self.result != nil)
        {
            if (self.id != self.boundId || self.encounter != self.boundEncounter || self.dropDestination != self.boundDestination || !holds(self.encounter.checks,self))
                rpgExpandedReject('swimming-check-binding');
            value.status = 'reused'; value.check = self.result.check; value.nextStage = self.result.nextStage;
            value.seconds = self.result.seconds; value.fatigue = self.result.fatigue; value.inhaledWater = self.result.inhaledWater; return value;
        }
        if (self.id == nil || self.id == '') rpgExpandedReject('swimming-check-id');
        foreach (local prior in self.encounter.checks)
            if (prior.id == self.id) rpgExpandedReject('swimming-check-duplicate');
        local patient = self.encounter.profile;
        if (self.encounter.endedAt != nil || patient.swimmingEncounter != self.encounter)
        { value.reason = 'swimming-not-active'; return value; }
        if (patient.dead || patient.unconscious || patient.stunned || patient.mentalStun)
        { value.reason = 'swimming-incapacitated'; return value; }
        if (self.encounter.skill == nil && !self.encounter.defaultAvailable)
        { value.reason = 'swimming-default-unavailable'; return value; }
        if (patient.fp() <= 0)
        {
            if (self.encounter.lastWillAt != rpgLedger.seconds)
            { value.reason = 'swimming-will-check-required'; return value; }
            value.wound = patient.prepareSwimmingWound('swim-fatigue-' + self.encounter.id + '-' + self.id,self.dropDestination);
            if (value.wound == nil) { value.reason = 'swimming-health-adapter-required'; return value; }
            local harm = value.wound.assess();
            if (harm.status != 'ready') { value.reason = harm.reason; return value; }
        }
        if (rpgLedger.seconds != self.encounter.nextCheckAt)
        { value.reason = rpgLedger.seconds < self.encounter.nextCheckAt ? 'swimming-check-not-due' : 'swimming-missed-boundary'; return value; }
        if (rpgLedger.seconds > self.encounter.nextEnduranceAt)
        { value.reason = 'swimming-endurance-overdue'; return value; }
        if (patient.encumbrance() > 4) { value.reason = 'swimming-overloaded'; return value; }
        value.context = self.encounter.skill == nil ? new RpgExpandedSwimmingDefaultContext() : new RpgLiteContext();
        value.context.kind = 'swimming'; value.context.attribute = rpgHT;
        value.context.skill = self.encounter.skill;
        /* A skill context already receives encumbrance in the shared score function. */
        value.context.modifier = rpgExpandedSwimmingModifier(self.encounter.intentionalEntry,
            self.encounter.skill == nil ? patient.encumbrance() : 0,self.encounter.build);
        local score = rpgLiteScore(patient,value.context);
        if (score == nil || score < 3) { value.reason = 'swimming-score-unavailable'; return value; }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        value.check = rpgLiteCheck(self.encounter.profile,value.context);
        local outcome = rpgExpandedSwimmingOutcome(self.encounter.stage,value.check.score,value.check.roll);
        value.nextStage = outcome.nextStage; value.seconds = outcome.seconds; value.inhaledWater = outcome.inhaledWater;
        if (outcome.fatigue > 0)
        {
            if (value.wound != nil && value.wound.apply().status != 'resolved') rpgExpandedReject('swimming-fatigue-wound-changed');
            value.fatigue = rpgLiteFatigueIncrement(self.encounter.profile,'swimming');
        }
        else value.wound = nil;
        self.encounter.recordExhaustion();
        if (self.encounter.profile.fp() <= -self.encounter.profile.maxEnergy)
        { self.encounter.profile.becomeUnconscious(); self.encounter.profile.fatigueCollapse = true; }
        self.boundDestination = self.dropDestination;
        self.boundId = self.id; self.boundEncounter = self.encounter; self.stageBefore = self.encounter.stage;
        self.completedAt = rpgLedger.seconds; self.encounter.stage = value.nextStage;
        self.encounter.nextCheckAt = self.completedAt + value.seconds; self.encounter.checks = self.encounter.checks + [self];
        value.status = 'resolved'; self.result = value; return value;
    }
;

modify RpgExpandedProfile
    validateFeatures()
    {
        inherited(); local active = nil; local ids = [];
        foreach (local encounter in self.swimmingHistory)
        {
            if (encounter == nil || !encounter.ofKind(RpgExpandedSwimmingEncounter) || encounter.profile != self
                || holds(ids,encounter.id) || encounter.startedAt == nil || encounter.startedAt > rpgLedger.seconds)
                rpgExpandedReject('swimming-history');
            encounter.validateBinding(); ids = ids + [encounter.id]; local due = encounter.startedAt; local stage = 'entry'; local checks = [];
            foreach (local check in encounter.checks)
            {
                if (check == nil || !check.ofKind(RpgExpandedSwimCheck) || check.encounter != encounter
                    || holds(checks,check.id) || check.result == nil || check.completedAt != due || check.completedAt > rpgLedger.seconds
                    || check.stageBefore != stage || check.assess().status != 'reused') rpgExpandedReject('swimming-check-history');
                checks = checks + [check.id];
                local outcome = rpgExpandedSwimmingOutcome(stage,check.result.check.score,check.result.check.roll);
                if (outcome.nextStage != check.result.nextStage || outcome.seconds != check.result.seconds
                    || outcome.fatigue != check.result.fatigue || outcome.inhaledWater != check.result.inhaledWater)
                    rpgExpandedReject('swimming-outcome-history');
                stage = outcome.nextStage; due = check.completedAt + outcome.seconds;
            }
            if (encounter.stage != stage || encounter.nextCheckAt != due) rpgExpandedReject('swimming-schedule-history');
            local interval = encounter.pace == 'top-speed' ? 60 : 1800;
            local enduranceDue = encounter.startedAt + interval; local enduranceIds = [];
            foreach (local endurance in encounter.enduranceChecks)
            {
                if (endurance == nil || !endurance.ofKind(RpgExpandedSwimEndurance) || endurance.encounter != encounter
                    || holds(enduranceIds,endurance.id) || endurance.result == nil || endurance.completedAt != enduranceDue
                    || endurance.completedAt > rpgLedger.seconds || endurance.assess().status != 'reused'
                    || endurance.result.fatigue != (endurance.result.check.achieved ? 0 : 1))
                    rpgExpandedReject('swimming-endurance-history');
                enduranceIds = enduranceIds + [endurance.id]; enduranceDue += interval;
            }
            if (encounter.nextEnduranceAt != enduranceDue) rpgExpandedReject('swimming-endurance-schedule');
            if (encounter.endedAt == nil)
            {
                if (active != nil) rpgExpandedReject('swimming-multiple-encounters');
                active = encounter;
            }
            else if (encounter.submersion != nil) encounter.submersion.validateSwimmingExit(encounter);
            else if (encounter.endedAt < encounter.startedAt || encounter.endedAt >= due || encounter.endedAt >= enduranceDue
                || encounter.endedAt > rpgLedger.seconds || encounter.exitEvidence == nil || stage == 'struggling')
                rpgExpandedReject('swimming-exit-history');
        }
        if (self.swimmingEncounter != active) rpgExpandedReject('swimming-active-history');
        return nil;
    }
;

modify RpgExpandedProfile
    validateSuffocation()
    {
        inherited();
        if (self.swimmingEncounter != nil) rpgExpandedReject('suffocation-swimming-encounter-owned');
        return nil;
    }
    validateBreathStart()
    {
        inherited();
        if (self.swimmingEncounter != nil) rpgExpandedReject('breath-swimming-encounter-owned');
        return nil;
    }
    validateNaturalRecovery(seconds, food, allowed)
    {
        inherited(seconds,food,allowed);
        if (self.swimmingEncounter != nil) rpgExpandedReject('swimming-rest-unavailable');
        return nil;
    }
;

class RpgExpandedSwimmingMovement: RpgExpandedResult
    waterMove = 0
    yardsPerTenSeconds = 0
;

/** Ordinary water movement before injury, fatigue or purchased movement changes. B354. */
rpgExpandedSwimmingMovement(basicMove, adapted, encumbrance)
{
    rpgInteger(basicMove,1,1000); rpgInteger(encumbrance,0,4);
    local value = new RpgExpandedSwimmingMovement();
    value.waterMove = adapted ? basicMove : basicMove / 5;
    if (!adapted && value.waterMove < 1) value.waterMove = 1;
    /* Ten-second distance preserves fractional per-second encumbered speed. */
    value.yardsPerTenSeconds = value.waterMove * [10,8,6,4,2][encumbrance + 1];
    value.seconds = 10; value.status = 'ready'; return value;
}

class RpgExpandedSwimmingEnduranceAssessment: RpgExpandedResult
    context = nil
    score = nil
    failureFatigue = 1
;

/** HT or Swimming, whichever is higher, without balance-check entry bonuses. B355. */
rpgExpandedSwimmingEndurance(profile, skill, pace)
{
    if (profile == nil || !profile.ofKind(RpgExpandedProfile)) rpgExpandedReject('swimming-endurance-profile');
    if (!holds(['top-speed','slow','floating'],pace)) rpgExpandedReject('swimming-pace');
    local value = new RpgExpandedSwimmingEnduranceAssessment(); value.seconds = pace == 'top-speed' ? 60 : 1800;
    value.context = new RpgLiteContext(); value.context.attribute = rpgHT; value.context.kind = 'swimming-endurance';
    value.score = rpgLiteScore(profile,value.context);
    if (skill != nil)
    {
        if (!skill.ofKind(RpgLiteSkill) || skill.id != 'swimming' || skill.attribute != rpgHT || skill.difficulty != 0)
            rpgExpandedReject('swimming-skill-definition');
        local alternate = new RpgLiteContext(); alternate.skill = skill; alternate.kind = 'swimming-endurance';
        local score = rpgLiteScore(profile,alternate);
        if (score != nil && (value.score == nil || score > value.score)) { value.score = score; value.context = alternate; }
    }
    if (value.score == nil || value.score < 3) { value.reason = 'swimming-endurance-score'; return value; }
    value.status = 'ready'; return value;
}


class RpgExpandedSwimEnduranceResult: RpgExpandedResult
    wound = nil
    context = nil
    fatigue = 0
;

/** Exertion interval, distinct from the balance-check schedule. B355. */
class RpgExpandedSwimEndurance: object
    id = nil
    dropDestination = nil
    boundDestination = nil
    encounter = nil
    boundId = nil
    boundEncounter = nil
    completedAt = nil
    result = nil
    assess()
    {
        local value = new RpgExpandedSwimEnduranceResult();
        if (self.encounter == nil || !self.encounter.ofKind(RpgExpandedSwimmingEncounter)) rpgExpandedReject('swimming-endurance-encounter');
        if (self.encounter.startedAt == nil) { value.reason = 'swimming-not-started'; return value; }
        self.encounter.validateBinding();
        if (self.result != nil)
        {
            if (self.id != self.boundId || self.encounter != self.boundEncounter || self.dropDestination != self.boundDestination || !holds(self.encounter.enduranceChecks,self))
                rpgExpandedReject('swimming-endurance-binding');
            value.status = 'reused'; value.check = self.result.check; value.fatigue = self.result.fatigue; return value;
        }
        if (self.id == nil || self.id == '') rpgExpandedReject('swimming-endurance-id');
        foreach (local prior in self.encounter.enduranceChecks)
            if (prior.id == self.id) rpgExpandedReject('swimming-endurance-duplicate');
        local patient = self.encounter.profile;
        if (self.encounter.endedAt != nil || patient.swimmingEncounter != self.encounter)
        { value.reason = 'swimming-not-active'; return value; }
        if (patient.dead || patient.unconscious || patient.stunned || patient.mentalStun)
        { value.reason = 'swimming-incapacitated'; return value; }
        if (patient.fp() <= 0)
        {
            if (self.encounter.lastWillAt != rpgLedger.seconds)
            { value.reason = 'swimming-will-check-required'; return value; }
            value.wound = patient.prepareSwimmingWound('swim-fatigue-' + self.encounter.id + '-' + self.id,self.dropDestination);
            if (value.wound == nil) { value.reason = 'swimming-health-adapter-required'; return value; }
            local harm = value.wound.assess();
            if (harm.status != 'ready') { value.reason = harm.reason; return value; }
        }
        if (patient.heatExtra != 0) { value.reason = 'swimming-heat-endurance-unavailable'; return value; }
        if (patient.encumbrance() > 4) { value.reason = 'swimming-overloaded'; return value; }
        if (rpgLedger.seconds != self.encounter.nextEnduranceAt)
        { value.reason = rpgLedger.seconds < self.encounter.nextEnduranceAt ? 'swimming-endurance-not-due' : 'swimming-endurance-overdue'; return value; }
        if (self.encounter.nextCheckAt <= rpgLedger.seconds)
        { value.reason = 'swimming-balance-check-required'; return value; }
        local assessment = rpgExpandedSwimmingEndurance(patient,self.encounter.skill,self.encounter.pace);
        if (assessment.status != 'ready') { value.reason = assessment.reason; return value; }
        value.context = assessment.context; value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        value.check = rpgLiteCheck(self.encounter.profile,value.context);
        if (!value.check.achieved)
        {
            if (value.wound != nil && value.wound.apply().status != 'resolved') rpgExpandedReject('swimming-fatigue-wound-changed');
            value.fatigue = rpgLiteFatigueIncrement(self.encounter.profile,'swimming');
        }
        else value.wound = nil;
        self.encounter.recordExhaustion();
        if (self.encounter.profile.fp() <= -self.encounter.profile.maxEnergy)
        { self.encounter.profile.becomeUnconscious(); self.encounter.profile.fatigueCollapse = true; }
        self.boundDestination = self.dropDestination;
        self.boundId = self.id; self.boundEncounter = self.encounter; self.completedAt = rpgLedger.seconds;
        self.encounter.nextEnduranceAt = self.completedAt + (self.encounter.pace == 'top-speed' ? 60 : 1800);
        self.encounter.enduranceChecks = self.encounter.enduranceChecks + [self];
        value.status = 'resolved'; self.result = value; return value;
    }
;

/** B350-B351 exact digging rates. Numerator/denominator are cubic feet per hour. */
class RpgExpandedDiggingAssessment: RpgExpandedResult
    rateNumerator = 0
    rateDenominator = 1
    fatiguePerHour = 0
    workKind = nil
    durationNumerator = 0
    durationDenominator = 1
;
rpgExpandedDiggingRate(liftHundredths, stage, toolMaterial, improvisedDivisor, rockDivisor)
{
    rpgInteger(liftHundredths,1,1000000);
    if (!holds(['metal','wood','improvised'],toolMaterial)) rpgExpandedReject('digging-tool-material');
    rpgInteger(improvisedDivisor,4,1000); rpgInteger(rockDivisor,1,1000);
    local value = new RpgExpandedDiggingAssessment(); local numerator = 1; local denominator = 1;
    value.workKind = 'removed';
    if (stage == 'loose') { numerator = 2; value.fatiguePerHour = 1; }
    else if (stage == 'ordinary') value.fatiguePerHour = 2;
    else if (stage == 'ordinary-pick') { numerator = 4; value.fatiguePerHour = 2; value.workKind = 'loosened'; }
    else if (stage == 'hard-pick') { numerator = 2; value.fatiguePerHour = 3; value.workKind = 'broken'; }
    else if (stage == 'hard-shovel') { numerator = 2; value.fatiguePerHour = 3; }
    else if (stage == 'hard-solo') { numerator = 3; denominator = 5; value.fatiguePerHour = 3; }
    else if (stage == 'rock-pick') { denominator = rockDivisor; value.fatiguePerHour = 4; value.workKind = 'broken'; }
    else if (stage == 'rock-shovel') value.fatiguePerHour = 4;
    else rpgExpandedReject('digging-stage');
    if (rockDivisor != 1 && stage != 'rock-pick') rpgExpandedReject('digging-rock-divisor-stage');
    local tools = toolMaterial == 'metal' ? 1 : toolMaterial == 'wood' ? 2 : improvisedDivisor;
    value.rateNumerator = liftHundredths * numerator;
    value.rateDenominator = 100 * denominator * tools;
    value.status = 'ready'; return value;
}
/** Exact rectangular volume and stage duration. Input dimensions are whole feet.
 * Fractional volumes can instead call the volume-based assessment directly. */
rpgExpandedDiggingVolume(length, width, depth)
{
    rpgInteger(length,1,1000); rpgInteger(width,1,1000); rpgInteger(depth,1,1000);
    return length * width * depth;
}
rpgExpandedDiggingDuration(rate, volumeNumerator, volumeDenominator)
{
    if (rate == nil || !rate.ofKind(RpgExpandedDiggingAssessment) || rate.status != 'ready')
        rpgExpandedReject('digging-rate-assessment');
    rpgInteger(rate.rateNumerator,1,4000000); rpgInteger(rate.rateDenominator,1,100000000);
    rpgInteger(volumeNumerator,1,2147483647 / rate.rateDenominator);
    rpgInteger(volumeDenominator,1,2147483647 / rate.rateNumerator);
    local value = new RpgExpandedDiggingAssessment(); value.rateNumerator = rate.rateNumerator;
    value.rateDenominator = rate.rateDenominator; value.fatiguePerHour = rate.fatiguePerHour;
    value.workKind = rate.workKind;
    value.durationNumerator = volumeNumerator * rate.rateDenominator;
    value.durationDenominator = volumeDenominator * rate.rateNumerator;
    value.status = 'ready'; return value;
}

/** Exact common scale for persistent excavation and prepared-material volumes. */
rpgExpandedDiggingCommonDenominator(first, second)
{
    if (first == nil) return second;
    rpgInteger(first,1,2147483647); rpgInteger(second,1,2147483647);
    local a = first; local b = second;
    while (b != 0) { local remainder = a % b; a = b; b = remainder; }
    local factor = first / a; rpgInteger(factor,1,2147483647 / second);
    return factor * second;
}
modify RpgExpandedDiggingAssessment
    commonDenominator = nil
    commonNumerator = nil
;
/** Excavation and prepared material share a single exact, receipt-backed ledger. */
class RpgExpandedDiggingSite: object
    id = nil
    stage = 'loose'
    capacityCubicFeet = 1
    hours = []
    rateDenominator = nil
    removedNumerator = 0
    preparedNumerator = 0
    definition() { return [self.id,self.stage,self.capacityCubicFeet]; }
    validate()
    {
        if (self.id == nil || self.id == '' || !holds(['loose','ordinary','hard-solo','rock'],self.stage))
            rpgExpandedReject('digging-site-stage');
        rpgInteger(self.capacityCubicFeet,1,1000000); local total = 0; local prepared = 0;
        if (self.rateDenominator != nil) rpgInteger(self.capacityCubicFeet,1,2147483647 / self.rateDenominator);
        foreach (local work in self.hours)
        {
            work.validateReceipt();
            if (work.site != self || self.rateDenominator % work.result.rateDenominator != 0)
                rpgExpandedReject('digging-site-history');
            local scale = self.rateDenominator / work.result.rateDenominator;
            rpgInteger(work.result.rateNumerator,1,2147483647 / scale);
            local amount = work.result.rateNumerator * scale;
            if (work.result.workKind != 'removed') prepared += amount;
            else { total += amount; if (work.usesPrepared()) prepared -= amount; }
            rpgInteger(total,0,self.capacityCubicFeet * self.rateDenominator);
            rpgInteger(prepared,0,self.capacityCubicFeet * self.rateDenominator - total);
        }
        if (total != self.removedNumerator || prepared != self.preparedNumerator) rpgExpandedReject('digging-site-credit');
        return nil;
    }
;
modify RpgExpandedProfile
    diggingHours = []
;
class RpgExpandedDiggingHour: object
    id = nil
    stage = nil
    rockDivisor = 1
    profile = nil
    site = nil
    pick = nil
    shovel = nil
    toolMaterial = 'metal'
    improvisedDivisor = 4
    approved = nil
    evidence = nil
    startedAt = nil
    completedAt = nil
    boundDefinition = nil
    result = nil
    definition()
    { return [self.id,self.profile,self.site,self.pick,self.shovel,self.toolMaterial,self.improvisedDivisor,self.approved,self.evidence,self.stage,self.rockDivisor] + self.site.definition(); }
    effectiveStage() { return self.stage == nil ? self.site.stage : self.stage; }
    usesPrepared() { return holds(['hard-shovel','rock-shovel'],self.effectiveStage())
        || self.site.stage == 'ordinary' && self.effectiveStage() == 'loose'; }
    validateReceipt()
    {
        local current = self.definition();
        for (local index = 1; index <= current.length(); index += 1)
            if (current[index] != self.boundDefinition[index]) rpgExpandedReject('digging-hour-binding');
        if (self.result == nil || self.completedAt != self.startedAt + 3600
            || !holds(self.site.hours,self) || !holds(self.profile.diggingHours,self)) rpgExpandedReject('digging-hour-history');
        return nil;
    }
    toolAvailable(item)
    { return item != nil && item.ofKind(RpgLiteItem) && holds(self.profile.equipment,item) && item.quantity > 0 && item.usableBy(self.profile); }
    prepareWorker()
    {
        local value = new RpgExpandedDiggingAssessment();
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'digging-facts-required'; return value; }
        local stage = self.effectiveStage();
        local allowed = self.site.stage == 'ordinary' ? ['ordinary','ordinary-pick','loose']
            : self.site.stage == 'hard-solo' ? ['hard-solo','hard-pick','hard-shovel']
            : self.site.stage == 'rock' ? ['rock-pick','rock-shovel'] : ['loose'];
        if (!holds(allowed,stage)) { value.reason = 'digging-stage-material'; return value; }
        local picking = holds(['ordinary-pick','hard-pick','rock-pick'],stage);
        if (picking ? !self.toolAvailable(self.pick) : !self.toolAvailable(self.shovel)
            || stage == 'hard-solo' && (!self.toolAvailable(self.pick) || self.pick == self.shovel))
        { value.reason = 'digging-tools-unavailable'; return value; }
        local toolReason = picking ? self.pick.diggingUseReason('pick',self.toolMaterial)
            : self.shovel.diggingUseReason('shovel',self.toolMaterial);
        if (toolReason == nil && stage == 'hard-solo') toolReason = self.pick.diggingUseReason('pick',self.toolMaterial);
        if (toolReason != nil) { value.reason = toolReason; return value; }
        if (self.profile.dead || self.profile.unconscious || self.profile.mortal || self.profile.stunned
            || self.profile.mentalStun || self.profile.hp() <= 0 || self.profile.voluntaryMovementUnavailable()
            || self.profile.healthEffortReason('action',nil,nil,true) != nil)
        { value.reason = 'digging-worker-unavailable'; return value; }
        if (self.profile.heatExtra != 0) { value.reason = 'digging-heat-adapter-required'; return value; }
        value = rpgExpandedDiggingRate(self.profile.basicLiftHundredths(),stage,self.toolMaterial,self.improvisedDivisor,self.rockDivisor);
        if (self.profile.fp() <= value.fatiguePerHour)
        { value.status = 'blocked'; value.reason = 'digging-exhaustion-adapter-required'; return value; }
        value.seconds = 3600; return value;
    }
    prepare()
    {
        local value = self.prepareWorker(); if (value.status != 'ready') return value;
        value.commonDenominator = rpgExpandedDiggingCommonDenominator(self.site.rateDenominator,value.rateDenominator);
        rpgInteger(self.site.capacityCubicFeet,1,2147483647 / value.commonDenominator);
        local scale = self.site.rateDenominator == nil ? 1 : value.commonDenominator / self.site.rateDenominator;
        local rateScale = value.commonDenominator / value.rateDenominator;
        rpgInteger(value.rateNumerator,1,2147483647 / rateScale);
        value.commonNumerator = value.rateNumerator * rateScale;
        local available = self.usesPrepared() ? self.site.preparedNumerator * scale
            : self.site.capacityCubicFeet * value.commonDenominator - (self.site.removedNumerator + self.site.preparedNumerator) * scale;
        if (available < value.commonNumerator)
        { value.status = 'blocked'; value.reason = self.usesPrepared() ? 'digging-prepared-material-required' : 'digging-partial-hour-required'; return value; }
        value.seconds = 3600; return value;
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)
            || self.site == nil || !self.site.ofKind(RpgExpandedDiggingSite)) rpgExpandedReject('digging-hour-definition');
        self.site.validate();
        if (self.result != nil) { self.validateReceipt(); local reused = new RpgExpandedDiggingAssessment(); reused.status = 'reused'; return reused; }
        foreach (local prior in self.profile.diggingHours)
            if (prior.id == self.id) rpgExpandedReject('digging-hour-duplicate');
        local value = self.prepare();
        if (value.status == 'ready')
        {
            value.reason = self.profile.nonTravelScheduleReason(rpgLedger.seconds,3600);
            if (value.reason != nil) { value.status = 'blocked'; return value; }
        }
        if (value.status == 'ready') { rpgInteger(rpgLedger.seconds,0,2147480047); rpgLedger.validateAdvance(3600); }
        return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status == 'reused') return self.result;
        if (value.status != 'ready') return value;
        local definition = self.definition(); local start = rpgLedger.seconds; rpgSpendTime(3600);
        return self.commitPrepared(value,start,definition);
    }
    commitPrepared(value,start,definition)
    {
        if (self.result != nil) rpgExpandedReject('digging-hour-already-committed');
        if (self.profile.nonTravelScheduleReason(start,3600) != nil) rpgExpandedReject('digging-travel-conflict');
        local current = self.definition();
        for (local index = 1; index <= current.length(); index += 1)
            if (current[index] != definition[index]) rpgExpandedReject('digging-hour-interrupted');
        self.site.validate(); local after = self.prepare();
        if (rpgLedger.seconds != start + 3600 || after.status != 'ready' || after.rateNumerator != value.rateNumerator
            || after.rateDenominator != value.rateDenominator) rpgExpandedReject('digging-hour-conditions-changed');
        for (local point = 0; point < value.fatiguePerHour; point += 1) rpgLiteFatigueIncrement(self.profile,'digging');
        self.startedAt = start; self.completedAt = rpgLedger.seconds; self.boundDefinition = definition;
        value.status = 'resolved'; self.result = value;
        local scale = self.site.rateDenominator == nil ? 1 : after.commonDenominator / self.site.rateDenominator;
        self.site.removedNumerator *= scale; self.site.preparedNumerator *= scale;
        self.site.rateDenominator = after.commonDenominator;
        if (value.workKind != 'removed') self.site.preparedNumerator += after.commonNumerator;
        else
        {
            self.site.removedNumerator += after.commonNumerator;
            if (self.usesPrepared()) self.site.preparedNumerator -= after.commonNumerator;
        }
        self.site.hours = self.site.hours + [self]; self.profile.diggingHours = self.profile.diggingHours + [self];
        return value;
    }
;

modify RpgExpandedDiggingSite
    teams = []
;
class RpgExpandedDiggingTeamAssessment: RpgExpandedResult
    ordered = []
;
/** B350 parallel pick/shovel work shares one hour, not one hour per worker. */
class RpgExpandedDiggingTeamHour: object
    id = nil
    site = nil
    members = []
    boundDefinition = nil
    result = nil
    definition()
    {
        local value = [self.id,self.site,self.members.length()];
        foreach (local work in self.members) value = value + [work] + work.definition();
        return value;
    }
    prepare()
    {
        if (self.id == nil || self.id == '' || self.site == nil || !self.site.ofKind(RpgExpandedDiggingSite))
            rpgExpandedReject('digging-team-definition');
        rpgInteger(self.members.length(),1,100); self.site.validate();
        local value = new RpgExpandedDiggingTeamAssessment();
        local workers = []; local tools = []; local entries = []; local denominator = self.site.rateDenominator;
        foreach (local work in self.members)
        {
            if (work == nil || !work.ofKind(RpgExpandedDiggingHour) || work.site != self.site
                || work.profile == nil || !work.profile.ofKind(RpgExpandedProfile) || work.id == nil || work.id == '')
                rpgExpandedReject('digging-team-member');
            if (work.result != nil || holds(workers,work.profile)) rpgExpandedReject('digging-team-worker-reused');
            workers = workers + [work.profile];
            foreach (local prior in work.profile.diggingHours)
                if (prior.id == work.id) rpgExpandedReject('digging-hour-duplicate');
            local assessed = work.prepareWorker();
            if (assessed.status != 'ready') { value.reason = assessed.reason; return value; }
            local used = assessed.workKind != 'removed' ? [work.pick]
                : work.effectiveStage() == 'hard-solo' ? [work.pick,work.shovel] : [work.shovel];
            foreach (local tool in used)
            {
                if (holds(tools,tool)) rpgExpandedReject('digging-team-shared-tool');
                tools = tools + [tool];
            }
            denominator = rpgExpandedDiggingCommonDenominator(denominator,assessed.rateDenominator);
            entries = entries + [[work,assessed,work.definition()]];
        }
        rpgInteger(self.site.capacityCubicFeet,1,2147483647 / denominator);
        local produced = 0; local consumed = 0; local direct = 0;
        foreach (local entry in entries)
        {
            local scale = denominator / entry[2].rateDenominator;
            rpgInteger(entry[2].rateNumerator,1,2147483647 / scale);
            local amount = entry[2].rateNumerator * scale;
            if (entry[2].workKind != 'removed')
            { rpgInteger(amount,1,2147483647 - produced); produced += amount; }
            else if (entry[1].usesPrepared())
            { rpgInteger(amount,1,2147483647 - consumed); consumed += amount; }
            else { rpgInteger(amount,1,2147483647 - direct); direct += amount; }
        }
        local scale = self.site.rateDenominator == nil ? 1 : denominator / self.site.rateDenominator;
        local raw = self.site.capacityCubicFeet * denominator - (self.site.removedNumerator + self.site.preparedNumerator) * scale;
        if (produced > raw || direct > raw - produced)
        { value.reason = 'digging-team-raw-material'; return value; }
        if (consumed > self.site.preparedNumerator * scale + produced)
        { value.reason = 'digging-team-prepared-material'; return value; }
        /* Commit source production before consumption; all receipts share the same interval. */
        foreach (local entry in entries) if (entry[2].workKind != 'removed') value.ordered = value.ordered + [entry];
        foreach (local entry in entries) if (entry[2].workKind == 'removed') value.ordered = value.ordered + [entry];
        value.seconds = 3600; value.status = 'ready'; return value;
    }
    assess()
    {
        if (self.result != nil)
        {
            local current = self.definition();
            if (current.length() != self.boundDefinition.length()) rpgExpandedReject('digging-team-binding');
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.boundDefinition[index]) rpgExpandedReject('digging-team-binding');
            if (!holds(self.site.teams,self)) rpgExpandedReject('digging-team-history');
            foreach (local work in self.members) work.validateReceipt();
            local reused = new RpgExpandedDiggingTeamAssessment(); reused.status = 'reused'; return reused;
        }
        local value = self.prepare();
        if (value.status == 'ready')
            foreach (local work in self.members)
            {
                value.reason = work.profile.nonTravelScheduleReason(rpgLedger.seconds,3600);
                if (value.reason != nil) { value.status = 'blocked'; return value; }
            }
        foreach (local prior in self.site.teams) if (prior.id == self.id) rpgExpandedReject('digging-team-duplicate');
        if (value.status == 'ready') { rpgInteger(rpgLedger.seconds,0,2147480047); rpgLedger.validateAdvance(3600); }
        return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status == 'reused') return self.result;
        if (value.status != 'ready') return value;
        local definition = self.definition(); local start = rpgLedger.seconds; rpgSpendTime(3600);
        local current = self.definition();
        if (current.length() != definition.length()) rpgExpandedReject('digging-team-interrupted');
        for (local index = 1; index <= current.length(); index += 1)
            if (current[index] != definition[index]) rpgExpandedReject('digging-team-interrupted');
        if (self.prepare().status != 'ready') rpgExpandedReject('digging-team-conditions-changed');
        foreach (local entry in value.ordered) entry[1].commitPrepared(entry[2],start,entry[3]);
        self.boundDefinition = definition; value.status = 'resolved'; self.result = value;
        self.site.teams = self.site.teams + [self]; return value;
    }
;

/** B353 capacity assessment; weights are hundredths of a pound. */
class RpgExpandedLoadAssessment: RpgExpandedResult
    capacityHundredths = 0
    effectiveNumerator = 0
    effectiveDenominator = 1
    encumbranceLevel = nil
    fatiguePerSecond = 0
    maneuver = nil
;

/** No action is committed. nil seconds denotes an authored duration still needed. */
rpgExpandedAssessLift(lift,weight,mode,combat,runningStart,braced)
{
    rpgInteger(lift,1,1000000); rpgInteger(weight,1,100000000);
    if (!holds(['one-hand','two-hands','shove','back','shift'],mode)) rpgExpandedReject('lifting-mode');
    if (runningStart && mode != 'shove') rpgExpandedReject('lifting-running-mode');
    local value = new RpgExpandedLoadAssessment(); value.effectiveNumerator = weight;
    value.seconds = nil;
    if (mode == 'one-hand' || mode == 'two-hands')
    {
        value.capacityHundredths = lift * (mode == 'one-hand' ? 2 : 8);
        value.seconds = weight <= lift ? 1 : mode == 'one-hand' ? 2 : 4;
        value.maneuver = combat ? 'ready' : nil;
    }
    if (mode == 'shove')
    {
        value.capacityHundredths = lift * (runningStart ? 24 : 12);
        value.maneuver = combat ? (runningStart ? 'move' : 'attack') : nil;
        if (combat) value.seconds = 1;
    }
    if (mode == 'back')
    {
        value.capacityHundredths = lift * 15;
        if (weight > lift * 10) value.fatiguePerSecond = 1;
    }
    if (mode == 'shift')
    {
        value.capacityHundredths = lift * 50;
        if (!braced) { value.reason = 'lifting-bracing-required'; return value; }
    }
    if (weight > value.capacityHundredths) { value.reason = 'lifting-capacity'; return value; }
    value.status = 'ready'; return value;
}

/** B353 effective dragging load; device is none, snow-sledge, cart or wagon.
 * Includes the device's own weight before dividing, retaining exact fractions. */
rpgExpandedAssessDragging(lift,load,deviceWeight,device,smoothLevel)
{
    rpgInteger(lift,1,1000000); rpgInteger(load,0,100000000);
    rpgInteger(deviceWeight,0,100000000);
    if (!holds(['none','snow-sledge','cart','wagon'],device)) rpgExpandedReject('dragging-device');
    if (device == 'none' && deviceWeight != 0) rpgExpandedReject('dragging-unassisted-device-weight');
    local value = new RpgExpandedLoadAssessment();
    value.effectiveNumerator = load + deviceWeight;
    value.effectiveDenominator = device == 'none' ? 1 : device == 'snow-sledge' ? 2 : device == 'cart' ? 10 : 20;
    if (smoothLevel) value.effectiveDenominator *= 2;
    value.capacityHundredths = lift * 15; value.seconds = nil;
    if (value.effectiveNumerator > value.capacityHundredths * value.effectiveDenominator)
    { value.reason = 'dragging-capacity'; return value; }
    local scaledLift = lift * value.effectiveDenominator;
    value.encumbranceLevel = rpgLiteLoadLevel(value.effectiveNumerator,scaledLift);
    if (value.encumbranceLevel < 5) { value.status = 'ready'; return value; }
    value.reason = 'dragging-overload-execution-required'; return value;
}

modify rpgExpandedLiftingRules
    assess(lift,weight,mode) { return rpgExpandedAssessLift(lift,weight,mode,nil,nil,nil); }
;

class RpgExpandedLiftingSkillResult: RpgExpandedResult
    score = nil
    baseLift = nil
    liftNumerator = 0
    liftDenominator = 100
;
modify RpgExpandedProfile
    liftingSkillAttempts = []
;
/** B205/B353: one skill roll for a concrete lift, without altering carrying capacity. */
class RpgExpandedLiftingSkillAttempt: object
    id = nil
    profile = nil
    skill = nil
    lift = nil
    approved = nil
    evidence = nil
    modifier = 0
    result = nil
    boundDefinition = nil
    boundLiftDefinition = nil
    definition() { return [self.id,self.profile,self.skill,self.lift,self.approved,self.evidence,self.modifier]; }
    assess()
    {
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)
            || self.skill == nil || !self.skill.ofKind(RpgLiteSkill) || self.skill.id != 'lifting'
            || self.skill.attribute != rpgHT || self.skill.difficulty != 1 || self.skill.defaultPenalty != nil
            || self.lift == nil || !self.lift.ofKind(RpgExpandedLiftIdentity)) rpgExpandedReject('lifting-skill-definition');
        local value = new RpgExpandedLiftingSkillResult();
        if (self.result != nil)
        {
            local current = self.definition();
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.boundDefinition[index]) rpgExpandedReject('lifting-skill-binding');
            if (!holds(self.profile.liftingSkillAttempts,self)) rpgExpandedReject('lifting-skill-history');
            value.status = 'reused'; return value;
        }
        foreach (local prior in self.profile.liftingSkillAttempts)
            if (prior.id == self.id || prior.lift == self.lift) rpgExpandedReject('lifting-skill-duplicate');
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'lifting-skill-author-facts'; return value; }
        value.reason = self.lift.skillPreparationReason();
        if (value.reason != nil) return value;
        local trained = nil;
        foreach (local training in self.profile.skills)
            if (training.skill == self.skill && training.points > 0) trained = true;
        if (!trained) { value.reason = 'lifting-skill-training'; return value; }
        if (self.profile.dead || self.profile.unconscious || self.profile.stunned || self.profile.mentalStun
            || self.profile.mortal || self.profile.hp() <= 0 || self.profile.fp() <= 0
            || self.profile.voluntaryMovementUnavailable()
            || self.profile.healthEffortReason('action',nil,nil,true) != nil)
        { value.reason = 'lifting-skill-actor'; return value; }
        rpgInteger(self.modifier,-1000,1000);
        local context = new RpgLiteContext(); context.skill = self.skill; context.kind = 'lifting';
        context.modifier = self.modifier; context.requiresMovement = true;
        value.score = rpgLiteScore(self.profile,context);
        if (value.score == nil || value.score < 3) { value.reason = 'lifting-skill-score'; return value; }
        rpgInteger(value.score,3,1000); value.baseLift = self.profile.basicLiftHundredths();
        rpgInteger(value.baseLift,1,2147483647 / (100 + 5 * value.score));
        value.status = 'ready'; return value;
    }
    resolve()
    {
        local value = self.assess(); if (value.status == 'reused') return self.result;
        if (value.status != 'ready') return value;
        self.boundLiftDefinition = self.lift.liftingDefinition();
        value.check = rpgCheck(value.score,rpgRandom.roll());
        local margin = value.check.achieved && value.check.margin > 0 ? value.check.margin : 0;
        value.liftNumerator = value.baseLift * (100 + 5 * margin);
        self.boundDefinition = self.definition(); self.profile.liftingSkillAttempts = self.profile.liftingSkillAttempts + [self];
        value.status = 'resolved'; self.result = value; return value;
    }
;

modify RpgExpandedLoadAssessment
    capacityNumerator = nil
    capacityDenominator = 100
;
modify rpgExpandedLiftingRules
    assessWithSkill(operation,attempt)
    {
        local value = new RpgExpandedLoadAssessment();
        if (attempt == nil || !attempt.ofKind(RpgExpandedLiftingSkillAttempt)
            || attempt.lift != operation || attempt.profile != operation.profile)
            rpgExpandedReject('lifting-skill-operation');
        if (attempt.result == nil) { value.reason = 'lifting-skill-unresolved'; return value; }
        attempt.assess();
        local current = operation.liftingDefinition();
        if (current.length() != attempt.boundLiftDefinition.length()) rpgExpandedReject('lifting-skill-request-changed');
        for (local index = 1; index <= current.length(); index += 1)
            if (current[index] != attempt.boundLiftDefinition[index]) rpgExpandedReject('lifting-skill-request-changed');
        local result = attempt.result;
        local margin = result.check.achieved && result.check.margin > 0 ? result.check.margin : 0;
        if (result.baseLift != operation.profile.basicLiftHundredths() || result.liftDenominator != 100
            || result.liftNumerator != result.baseLift * (100 + 5 * margin))
            rpgExpandedReject('lifting-skill-capacity-binding');
        local multiple = operation.mode == 'one-hand' ? 2 : 8;
        rpgInteger(result.liftNumerator,1,2147483647 / multiple);
        value.capacityNumerator = result.liftNumerator * multiple;
        value.capacityHundredths = value.capacityNumerator % 100 == 0 ? value.capacityNumerator / 100 : nil;
        local weight = operation.item.weightHundredths(); rpgInteger(weight,1,2147483647 / 100);
        value.seconds = weight * 100 <= result.liftNumerator ? 1 : operation.mode == 'one-hand' ? 2 : 4;
        if (weight * 100 > value.capacityNumerator) { value.reason = 'lifting-capacity'; return value; }
        value.status = 'ready'; return value;
    }
;

modify RpgExpandedLoadAssessment
    pickedUp = nil
;

/** B353 authored cooperation: sum individual BL after each profile's calculation. */
class RpgExpandedCooperativeLoad: object
    participants = []
    approved = nil
    evidence = nil
    operation = 'lift'
    mode = 'two-hands'
    weight = 0
    deviceWeight = 0
    device = 'none'
    smoothLevel = nil
    combat = nil
    runningStart = nil
    braced = nil
    assess()
    {
        local blocked = new RpgExpandedLoadAssessment();
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { blocked.reason = 'cooperative-load-arrangement'; return blocked; }
        if (!holds(['lift','drag'],self.operation) || self.participants.length() < 2
            || self.participants.length() > 100) rpgExpandedReject('cooperative-load-definition');
        if (self.operation == 'lift' && (self.device != 'none' || self.deviceWeight != 0 || self.smoothLevel)
            || self.operation == 'drag' && (self.combat || self.runningStart || self.braced))
            rpgExpandedReject('cooperative-load-unused-fields');
        local seen = []; local combined = 0;
        foreach (local profile in self.participants)
        {
            if (profile == nil || !profile.ofKind(RpgExpandedProfile) || holds(seen,profile))
                rpgExpandedReject('cooperative-load-participant');
            seen = seen + [profile];
            if (profile.dead || profile.unconscious || profile.mortal || profile.stunned || profile.mentalStun
                || profile.hp() <= 0 || profile.fp() <= 0 || profile.voluntaryMovementUnavailable()
                || profile.healthEffortReason('action',nil,nil,true) != nil)
            { blocked.reason = 'cooperative-load-worker-unavailable'; return blocked; }
            local lift = profile.basicLiftHundredths(); rpgInteger(lift,1,1000000-combined);
            combined += lift;
        }
        local value = self.operation == 'lift'
            ? rpgExpandedAssessLift(combined,self.weight,self.mode,self.combat,self.runningStart,self.braced)
            : rpgExpandedAssessDragging(combined,self.weight,self.deviceWeight,self.device,self.smoothLevel);
        value.combinedLift = combined; value.participantCount = self.participants.length(); return value;
    }
;
modify RpgExpandedLoadAssessment
    combinedLift = nil
    participantCount = 0
;

class RpgExpandedLoadDistributionResult: RpgExpandedResult
    allocations = []
;
/** Authored physical shares, not a source-prescribed equal division.
 * rows are [profile, shareHundredths]; results add existing-load total and band. */
rpgExpandedAssessLoadDistribution(rows,weight,approved,evidence)
{
    local value = new RpgExpandedLoadDistributionResult();
    if (!approved || evidence == nil || evidence == '')
    { value.reason = 'load-distribution-author-facts'; return value; }
    rpgInteger(weight,1,100000000);
    if (rows.length() < 2 || rows.length() > 100) rpgExpandedReject('load-distribution-participants');
    local seen = []; local allocated = 0; local assessments = [];
    foreach (local row in rows)
    {
        if (row.length() != 2 || row[1] == nil || !row[1].ofKind(RpgExpandedProfile) || holds(seen,row[1]))
            rpgExpandedReject('load-distribution-participant');
        local profile = row[1]; seen = seen + [profile];
        rpgInteger(row[2],1,weight);
        if (row[2] > weight-allocated) { value.reason = 'load-distribution-total'; return value; }
        allocated += row[2];
        local existing = profile.loadHundredths(); rpgInteger(existing,0,100000000);
        local lift = profile.basicLiftHundredths(); rpgInteger(lift,1,1000000);
        local total = existing + row[2]; local level = rpgLiteLoadLevel(total,lift);
        if (level == 5) { value.reason = 'load-distribution-overload-required'; return value; }
        assessments = assessments + [[profile,row[2],total,level]];
    }
    if (allocated != weight) { value.reason = 'load-distribution-total'; return value; }
    value.allocations = assessments; value.status = 'ready'; return value;
}

modify rpgExpandedSharedCarryRules
    assess(carry)
    {
        local task = new RpgExpandedCooperativeLoad(); task.approved = carry.approved;
        task.evidence = carry.evidence; task.weight = carry.item.weightHundredths(); task.mode = carry.mode;
        local shares = [];
        foreach (local row in carry.members)
        { task.participants = task.participants + [row[1]]; shares = shares + [[row[1],row[2]]]; }
        local capacity = task.assess(); if (capacity.status != 'ready') return capacity;
        local distribution = rpgExpandedAssessLoadDistribution(shares,task.weight,carry.approved,carry.evidence);
        if (distribution.status != 'ready') return distribution;
        distribution.seconds = capacity.seconds; return distribution;
    }
;

/** Pure B349 assessment. Distance is whole feet or ladder rungs, never yards. */
class RpgExpandedClimbAssessment: RpgExpandedResult
    unit = nil
    rateNumerator = nil
    rateDenominator = 60
    modifier = nil
    checkCount = 0
    fatigueCost = 0
    maneuver = nil
;
rpgExpandedAssessClimb(surface,distance,encumbrance,combat,ordinaryFatigue)
{
    rpgInteger(distance,1,1000000); rpgInteger(encumbrance,0,4);
    rpgInteger(ordinaryFatigue,0,1000000);
    local row = rpgLiteClimbData(surface); local value = new RpgExpandedClimbAssessment();
    value.unit = row[5]; value.rateNumerator = row[combat ? 3 : 4];
    local numerator = distance * 60;
    value.seconds = (numerator + value.rateNumerator - 1) / value.rateNumerator;
    if (row[2] != nil)
    {
        value.modifier = row[2] - encumbrance;
        value.checkCount = 1 + value.seconds / 300;
    }
    value.fatigueCost = combat ? ordinaryFatigue * 2 : ordinaryFatigue;
    if (combat && value.fatigueCost < 1) value.fatigueCost = 1;
    value.maneuver = combat ? 'move' : nil;
    value.status = 'ready'; return value;
}

class RpgExpandedClimbFallAssessment: RpgExpandedResult
    falls = nil
    ropeLimited = nil
    distanceFeet = 0
    impactRequired = nil
;
/** B349: a secured rope limits an ordinary failed climb, never a critical failure.
 * Heights are authored distances to the first lower obstacle and to rope arrest. */
rpgExpandedAssessClimbFall(score,roll,heightFeet,secured,ropeFallFeet)
{
    rpgInteger(score,3,1000); rpgInteger(roll,3,18); rpgInteger(heightFeet,0,1000000);
    if (secured) rpgInteger(ropeFallFeet,0,1000000);
    else if (ropeFallFeet != nil) rpgExpandedReject('climb-rope-without-security');
    local value = new RpgExpandedClimbFallAssessment(); value.check = rpgCheck(score,roll);
    value.status = 'ready';
    if (value.check.achieved) return value;
    value.falls = true; value.distanceFeet = heightFeet;
    if (secured && value.check.critical != 'failure' && ropeFallFeet < heightFeet)
    { value.distanceFeet = ropeFallFeet; value.ropeLimited = true; }
    value.impactRequired = true; return value;
}

/** Exact printed B431 table at ordinary gravity/atmosphere. No long-fall extrapolation. */
rpgExpandedFallVelocity(yards)
{
    rpgInteger(yards,0,112);
    if (yards == 0) return 0;
    local rows = [[1,5],[2,7],[3,8],[4,9],[5,10],[6,11],[7,12],[8,13],[9,14],
        [11,15],[12,16],[14,17],[15,18],[17,19],[19,20],[21,21],[23,22],[25,23],
        [27,24],[29,25],[32,26],[34,27],[37,28],[39,29],[42,30],[45,31],[48,32],
        [51,33],[54,34],[57,35],[61,36],[64,37],[67,38],[71,39],[75,40],[79,41],
        [82,42],[86,43],[90,44],[95,45],[99,46],[103,47],[108,48],[112,49]];
    foreach (local row in rows) if (yards <= row[1]) return row[2];
    rpgExpandedReject('fall-distance-unsupported');
}

class RpgExpandedLandingAssessment: RpgExpandedResult
    effectiveDistance = 0
    velocity = 0
    negatesDamage = nil
;
/** Pure B431 landing choice. score includes ordinary skill modifiers, not dive speed.
 * The caller supplies one actual roll and must own the attempt to prevent retries. */
rpgExpandedAssessLanding(distance,method,fluid,freeToMove,score,roll)
{
    rpgInteger(distance,1,112); rpgInteger(score,-1000,1000); rpgInteger(roll,3,18);
    if (!holds(['acrobatics','dive'],method)) rpgExpandedReject('landing-method');
    local value = new RpgExpandedLandingAssessment(); value.effectiveDistance = distance;
    value.velocity = rpgExpandedFallVelocity(distance);
    if (!freeToMove) { value.reason = 'landing-movement-required'; return value; }
    if (method == 'dive' && !fluid) { value.reason = 'landing-fluid-required'; return value; }
    value.modifier = method == 'dive' ? rpgExpandedRangeModifier(value.velocity) : 0;
    if (score + value.modifier < 3) { value.reason = 'landing-score'; return value; }
    value.check = rpgCheck(score + value.modifier,roll);
    if (value.check.achieved)
    {
        if (method == 'dive') value.negatesDamage = true;
        else
        {
            value.effectiveDistance = distance > 5 ? distance-5 : 0;
            value.velocity = rpgExpandedFallVelocity(value.effectiveDistance);
        }
    }
    value.status = 'ready'; return value;
}

modify RpgExpandedProfile
    landingAttempts = []
;
modify RpgExpandedLandingAssessment
    score = nil
;
/** One landing choice for a distinct authored fall occurrence. */
class RpgExpandedLandingAttempt: RpgExpandedLandingReceipt
    id = nil
    profile = nil
    fall = nil
    distance = 1
    method = 'acrobatics'
    fluid = nil
    freeToMove = nil
    skill = nil
    modifier = 0
    approved = nil
    evidence = nil
    result = nil
    boundDefinition = nil
    committedAt = nil
    impactFor(profile,fall)
    {
        if (self.result == nil) rpgExpandedReject('landing-receipt-unresolved');
        if (self.profile != profile || self.fall != fall) rpgExpandedReject('landing-receipt-owner');
        self.assess(); return self.result;
    }
    definition()
    { return [self.id,self.profile,self.fall,self.distance,self.method,self.fluid,self.freeToMove,
        self.skill,self.modifier,self.approved,self.evidence]; }
    assess()
    {
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)
            || self.fall == nil || dataType(self.fall) != TypeObject)
            rpgExpandedReject('landing-attempt-definition');
        local value = new RpgExpandedLandingAssessment();
        if (self.result != nil)
        {
            local current = self.definition();
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.boundDefinition[index]) rpgExpandedReject('landing-attempt-binding');
            if (!holds(self.profile.landingAttempts,self)) rpgExpandedReject('landing-attempt-history');
            value.status = 'reused'; return value;
        }
        foreach (local prior in self.profile.landingAttempts)
            if (prior.id == self.id || prior.fall == self.fall) rpgExpandedReject('landing-attempt-duplicate');
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'landing-attempt-author-facts'; return value; }
        rpgInteger(self.distance,1,112); rpgInteger(self.modifier,-1000,1000);
        if (!holds(['acrobatics','dive'],self.method)) rpgExpandedReject('landing-method');
        if (!self.freeToMove) { value.reason = 'landing-movement-required'; return value; }
        if (self.method == 'dive' && !self.fluid) { value.reason = 'landing-fluid-required'; return value; }
        local dive = self.method == 'dive';
        if (self.skill == nil || !self.skill.ofKind(RpgLiteSkill)
            || self.skill.id != (dive ? 'swimming' : 'acrobatics')
            || self.skill.attribute != (dive ? rpgHT : rpgDX)
            || self.skill.difficulty != (dive ? 0 : 2)
            || self.skill.defaultPenalty != (dive ? -4 : -6)) rpgExpandedReject('landing-skill-definition');
        if (self.profile.dead || self.profile.unconscious || self.profile.stunned || self.profile.mentalStun
            || self.profile.voluntaryMovementUnavailable()
            || self.profile.healthEffortReason('action',nil,nil,true) != nil)
        { value.reason = 'landing-actor-unavailable'; return value; }
        local context = new RpgLiteContext(); context.skill = self.skill; context.kind = 'landing';
        context.requiresMovement = true; context.modifier = self.modifier;
        value.score = rpgLiteScore(self.profile,context);
        value.effectiveDistance = self.distance; value.velocity = rpgExpandedFallVelocity(self.distance);
        value.modifier = dive ? rpgExpandedRangeModifier(value.velocity) : 0;
        if (value.score == nil || value.score + value.modifier < 3)
        { value.reason = 'landing-score'; return value; }
        rpgInteger(value.score,-1000,1000);
        value.status = 'ready'; return value;
    }
    resolve()
    {
        local prepared = self.assess(); if (prepared.status == 'reused') return self.result;
        if (prepared.status != 'ready') return prepared;
        local value = rpgExpandedAssessLanding(self.distance,self.method,self.fluid,self.freeToMove,
            prepared.score,rpgRandom.roll());
        value.score = prepared.score; value.status = 'resolved';
        self.boundDefinition = self.definition(); self.committedAt = rpgLedger.seconds;
        self.profile.landingAttempts = self.profile.landingAttempts + [self]; self.result = value; return value;
    }
;

/** B351 daily marching conditions. A homogeneous route segment is an authored
 * fact. Assessment does not advance a character or grant time for other work. */
/** Validate full-day eligibility separately from an unrestricted route preview. */
rpgExpandedHikingDayReason(profiles, reservations)
{
    if (reservations.length() != profiles.length()) rpgExpandedReject('hiking-day-members');
    for (local index = 1; index <= profiles.length(); index += 1)
    {
        local reservation = reservations[index];
        if (reservation == nil || !reservation.ofKind(RpgExpandedTravelDay)
            || reservation.profile != profiles[index]) rpgExpandedReject('hiking-day-owner');
        local reason = reservation.fullMileageReason();
        if (reason != nil) return reason;
        if (reservation.day != rpgLedger.seconds / 86400) return 'hiking-day-expired';
    }
    return nil;
}

class RpgExpandedHikingAssessment: RpgExpandedResult
    packingPercent = 100
    effectiveTerrain = nil
    terrainPercent = 100
    weatherDivisor = 1
    travelSkill = 'hiking'
    milesHundredths = 0
;

class RpgExpandedHikingConditions: object
    packTrain = nil
    terrain = 'average'
    weather = 'dry'
    road = 'none'
    roadCleared = nil
    equipment = 'none'
    deepSnowDivisor = 4
    deepSnowEvidence = nil
    assess()
    {
        if (!holds(['very-bad','bad','average','good'],self.terrain)) rpgExpandedReject('hiking-terrain');
        if (!holds(['dry','rain','shallow-snow','deep-snow','ice-coating','solid-ice'],self.weather))
            rpgExpandedReject('hiking-weather');
        if (!holds(['none','poor','ordinary','best'],self.road)) rpgExpandedReject('hiking-road');
        if (!holds(['none','skis','skates'],self.equipment)) rpgExpandedReject('hiking-equipment');
        rpgInteger(self.deepSnowDivisor,4,1000000);
        local value = new RpgExpandedHikingAssessment(); value.effectiveTerrain = self.terrain;
        local snow = holds(['shallow-snow','deep-snow'],self.weather);
        local frozen = snow || self.weather == 'ice-coating';
        if (self.roadCleared && (self.road == 'none' || !frozen))
        { value.reason = 'hiking-cleared-road-inapplicable'; return value; }
        if (self.equipment == 'skis' && (!snow || self.roadCleared))
        { value.reason = 'hiking-skis-require-snow'; return value; }
        if (self.equipment == 'skates' && (self.weather != 'solid-ice' || self.road != 'none'))
        { value.reason = 'hiking-skates-require-solid-ice'; return value; }
        if (self.weather == 'solid-ice' && self.road != 'none')
        { value.reason = 'hiking-ice-road-adjudication'; return value; }
        if (self.weather == 'deep-snow' && self.equipment != 'skis' && !self.roadCleared
            && self.deepSnowDivisor > 4 && (self.deepSnowEvidence == nil || self.deepSnowEvidence == ''))
        { value.reason = 'hiking-deep-snow-evidence'; return value; }
        if (self.road != 'none')
        {
            value.effectiveTerrain = self.road == 'best' && self.weather == 'dry' ? 'good' : 'average';
            if (self.weather == 'rain' && self.road == 'poor') value.effectiveTerrain = 'very-bad';
        }
        if (self.weather == 'rain' && self.road == 'none') value.weatherDivisor = 2;
        if (frozen && !self.roadCleared)
            value.weatherDivisor = self.weather == 'deep-snow' ? self.deepSnowDivisor : 2;
        if (self.equipment == 'skis')
        { value.effectiveTerrain = 'average'; value.weatherDivisor = 1; value.travelSkill = 'skiing'; }
        if (self.weather == 'solid-ice')
        {
            value.effectiveTerrain = self.equipment == 'skates' ? 'good' : 'bad';
            if (self.equipment == 'skates') value.travelSkill = 'skating';
        }
        value.terrainPercent = value.effectiveTerrain == 'very-bad' ? 20 : value.effectiveTerrain == 'bad' ? 50
            : value.effectiveTerrain == 'good' ? 125 : 100;
        if (self.packTrain != nil)
        {
            if (!self.packTrain.ofKind(RpgExpandedPackTrain)) rpgExpandedReject('hiking-pack-train');
            local packing = self.packTrain.assess();
            if (packing.status != 'ready') { value.reason = packing.reason; return value; }
            value.packingPercent = packing.speedPercent;
        }
        value.status = 'ready'; return value;
    }
;

/** Move is the already adjusted ground Move. Enhanced movement is an explicitly
 * authorized ground-travel multiplier in hundredths (100 means ordinary).
 * The successful daily skill roll supplies its single 20 percent bonus. */
rpgExpandedAssessHiking(move, enhancedPercent, succeeded, conditions)
{
    rpgInteger(move,0,1000000); rpgInteger(enhancedPercent,100,1000000);
    if (conditions == nil || !conditions.ofKind(RpgExpandedHikingConditions)) rpgExpandedReject('hiking-conditions');
    local value = conditions.assess(); if (value.status != 'ready') return value;
    /* hundredths of a mile = Move * terrainPercent * enhancedPercent *
       (success ? 6 : 5) / (50 * weatherDivisor). Round only once. */
    local numerator = move;
    foreach (local factor in [value.terrainPercent,enhancedPercent,succeeded ? 6 : 5])
    {
        if (numerator > 2147483647 / factor) rpgExpandedReject('hiking-distance-limit');
        numerator *= factor;
    }
    if (value.packingPercent == 80)
    {
        if (numerator > 2147483647 / 4) rpgExpandedReject('hiking-distance-limit');
        value.milesHundredths = numerator * 4 / (250 * value.weatherDivisor);
    }
    else value.milesHundredths = numerator / (50 * value.weatherDivisor);
    return value;
}

modify RpgExpandedProfile
    hikingAttempts = []
;
class RpgExpandedHikingRollResult: RpgExpandedResult
    score = nil
    memberScores = []
    day = nil
    staysTogether = nil
;
/** B200/B351/B220-B221: one ordinary daily travel roll per participant.
 * Calendar days use the shared ledger's 86400-second boundaries. Member rows
 * are [profile, skill, authored modifier, modifier evidence]. */
class RpgExpandedHikingAttempt: object
    id = nil
    members = []
    leader = nil
    leadershipSkill = nil
    approved = nil
    evidence = nil
    result = nil
    boundDefinition = nil
    committedAt = nil
    definition()
    {
        local values = [self.id,self.leader,self.leadershipSkill,self.approved,self.evidence,self.members.length()];
        foreach (local row in self.members)
            values = values + row + [row[2].id,row[2].attribute,row[2].difficulty,row[2].defaultPenalty];
        if (self.leadershipSkill != nil)
            values = values + [self.leadershipSkill.id,self.leadershipSkill.attribute,
                self.leadershipSkill.difficulty,self.leadershipSkill.defaultPenalty];
        return values;
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.members.length() == 0 || self.members.length() > 1000)
            rpgExpandedReject('hiking-attempt-definition');
        foreach (local row in self.members)
            if (row.length() != 4 || row[1] == nil || !row[1].ofKind(RpgExpandedProfile)
                || row[2] == nil || !row[2].ofKind(RpgLiteSkill)) rpgExpandedReject('hiking-attempt-member');
        local value = new RpgExpandedHikingRollResult();
        if (self.result != nil)
        {
            local current = self.definition();
            if (current.length() != self.boundDefinition.length()) rpgExpandedReject('hiking-attempt-binding');
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.boundDefinition[index]) rpgExpandedReject('hiking-attempt-binding');
            foreach (local row in self.members)
                if (!holds(row[1].hikingAttempts,self)) rpgExpandedReject('hiking-attempt-history');
            value.status = 'reused'; return value;
        }
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'hiking-attempt-author-facts'; return value; }
        value.day = rpgLedger.seconds / 86400;
        local profiles = []; local total = 0;
        foreach (local row in self.members)
        {
            local profile = row[1]; local skill = row[2];
            if (holds(profiles,profile)) rpgExpandedReject('hiking-attempt-duplicate-member');
            profiles = profiles + [profile];
            value.reason = profile.travelScheduleReason(rpgLedger.seconds,0);
            if (value.reason != nil) return value;
            foreach (local prior in profile.hikingAttempts)
                if (prior.id == self.id || prior.result.day == value.day) rpgExpandedReject('hiking-attempt-duplicate');
            if (!holds(['hiking','skiing','skating'],skill.id) || skill.attribute != rpgHT
                || skill.difficulty != (skill.id == 'hiking' ? 1 : 2)
                || skill.defaultPenalty != (skill.id == 'hiking' ? -5 : -6))
                rpgExpandedReject('hiking-skill-definition');
            rpgInteger(row[3],-1000,1000);
            if (row[3] != 0 && (row[4] == nil || row[4] == ''))
            { value.reason = 'hiking-modifier-evidence'; return value; }
            if (profile.dead || profile.unconscious || profile.stunned || profile.mentalStun
                || profile.voluntaryMovementUnavailable() || profile.healthEffortReason('action',nil,nil,true) != nil)
            { value.reason = 'hiking-actor-unavailable'; return value; }
            local context = new RpgLiteContext(); context.skill = skill; context.kind = 'hiking';
            context.requiresMovement = true; context.modifier = row[3];
            local score = rpgLiteScore(profile,context);
            if (score == nil) { value.reason = 'hiking-score-unavailable'; return value; }
            rpgInteger(score,-1000,1000); value.memberScores = value.memberScores + [score]; total += score;
        }
        value.staysTogether = self.members.length() > 1;
        if (value.staysTogether)
        {
            if (self.leader == nil || !holds(profiles,self.leader) || self.leadershipSkill == nil
                || !self.leadershipSkill.ofKind(RpgLiteSkill) || self.leadershipSkill.id != 'leadership'
                || self.leadershipSkill.attribute != rpgIQ || self.leadershipSkill.difficulty != 1
                || self.leadershipSkill.defaultPenalty != -5) rpgExpandedReject('hiking-leader-definition');
            local leadership = self.leader.skillScore(self.leadershipSkill);
            if (leadership == nil || leadership < 12) { value.reason = 'hiking-leadership-required'; return value; }
        }
        else if (self.leader != nil || self.leadershipSkill != nil) rpgExpandedReject('hiking-solo-leader');
        value.score = total / self.members.length();
        if (value.score < 3) { value.reason = 'hiking-score-too-low'; return value; }
        value.status = 'ready'; return value;
    }
    resolve()
    {
        local value = self.assess(); if (value.status == 'reused') return self.result;
        if (value.status != 'ready') return value;
        value.check = rpgCheck(value.score,rpgRandom.roll()); value.status = 'resolved';
        self.boundDefinition = self.definition(); self.committedAt = rpgLedger.seconds; self.result = value;
        foreach (local row in self.members) row[1].hikingAttempts = row[1].hikingAttempts + [self];
        return value;
    }
    assessFullDayPace(conditions, enhancedPercents, reservations)
    {
        if (self.assess().status != 'reused') rpgExpandedReject('hiking-attempt-unresolved');
        local profiles = []; foreach (local row in self.members) profiles = profiles + [row[1]];
        local value = new RpgExpandedHikingAssessment();
        value.reason = rpgExpandedHikingDayReason(profiles,reservations);
        if (value.reason != nil) return value;
        return self.assessPace(conditions,enhancedPercents);
    }
    /** Current shared route assessment, never a completed journey receipt.
     * Multipliers correspond to member order and require authored trait facts. */
    assessPace(conditions, enhancedPercents)
    {
        local prepared = self.assess();
        if (prepared.status != 'reused') rpgExpandedReject('hiking-attempt-unresolved');
        if (self.result.day != rpgLedger.seconds / 86400) rpgExpandedReject('hiking-attempt-expired');
        if (enhancedPercents.length() != self.members.length()) rpgExpandedReject('hiking-multiplier-members');
        local result = nil;
        for (local index = 1; index <= self.members.length(); index += 1)
        {
            local row = self.members[index];
            local value = rpgExpandedAssessHiking(row[1].move(),enhancedPercents[index],self.result.check.achieved,conditions);
            if (value.status != 'ready') return value;
            if (row[2].id != value.travelSkill) rpgExpandedReject('hiking-travel-skill-mismatch');
            if (result == nil || value.milesHundredths < result.milesHundredths) result = value;
        }
        return result;
    }
;

modify RpgExpandedProfile
    hikingParties = []
;
class RpgExpandedHikingPartyResult: RpgExpandedResult
    day = nil
    profiles = []
    bonusAchieved = nil
;
/** B200/B351 independent-roll party: every member must succeed. Unlike a
 * shared leadership roll, these solo receipts can later support a split party;
 * a new party decision still consumes the same rolls, never new attempts. */
class RpgExpandedHikingParty: object
    id = nil
    attempts = []
    evidence = nil
    result = nil
    boundDefinition = nil
    boundOutcome = nil
    outcomeDefinition() { return [self.result.day,self.result.bonusAchieved,self.result.profiles.length()] + self.result.profiles; }
    definition() { return [self.id,self.evidence,self.attempts.length()] + self.attempts; }
    assessFullDayPace(conditions, enhancedPercents, reservations)
    {
        if (self.assess().status != 'reused') rpgExpandedReject('hiking-party-unresolved');
        local value = new RpgExpandedHikingAssessment();
        value.reason = rpgExpandedHikingDayReason(self.result.profiles,reservations);
        if (value.reason != nil) return value;
        return self.assessPace(conditions,enhancedPercents);
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.attempts.length() < 2 || self.attempts.length() > 1000)
            rpgExpandedReject('hiking-party-definition');
        local value = new RpgExpandedHikingPartyResult();
        foreach (local attempt in self.attempts)
        {
            if (attempt == nil || !attempt.ofKind(RpgExpandedHikingAttempt)) rpgExpandedReject('hiking-party-attempt');
            if (attempt.result == nil) { value.reason = 'hiking-party-unresolved-member'; return value; }
            if (attempt.assess().status != 'reused') rpgExpandedReject('hiking-party-receipt');
            if (attempt.members.length() != 1) rpgExpandedReject('hiking-party-shared-roll');
        }
        if (self.result != nil)
        {
            local current = self.definition();
            if (current.length() != self.boundDefinition.length()) rpgExpandedReject('hiking-party-binding');
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.boundDefinition[index]) rpgExpandedReject('hiking-party-binding');
            local outcome = self.outcomeDefinition();
            if (self.boundOutcome == nil || outcome.length() != self.boundOutcome.length()) rpgExpandedReject('hiking-party-outcome-binding');
            for (local index = 1; index <= outcome.length(); index += 1)
                if (outcome[index] != self.boundOutcome[index]) rpgExpandedReject('hiking-party-outcome-binding');
            foreach (local profile in self.result.profiles)
                if (!holds(profile.hikingParties,self)) rpgExpandedReject('hiking-party-history');
            value.status = 'reused'; return value;
        }
        if (self.evidence == nil || self.evidence == '') { value.reason = 'hiking-party-choice-required'; return value; }
        value.day = rpgLedger.seconds / 86400; value.bonusAchieved = true;
        foreach (local attempt in self.attempts)
        {
            if (attempt.result.day != value.day) rpgExpandedReject('hiking-party-expired-member');
            local profile = attempt.members[1][1];
            if (holds(value.profiles,profile)) rpgExpandedReject('hiking-party-duplicate-member');
            foreach (local prior in profile.hikingParties)
                if (prior.id == self.id) rpgExpandedReject('hiking-party-duplicate-id');
            value.profiles = value.profiles + [profile];
            if (!attempt.result.check.achieved) value.bonusAchieved = nil;
        }
        value.status = 'ready'; return value;
    }
    resolve()
    {
        local value = self.assess(); if (value.status == 'reused') return self.result;
        if (value.status != 'ready') return value;
        self.boundDefinition = self.definition(); self.result = value; value.status = 'resolved';
        self.boundOutcome = self.outcomeDefinition();
        foreach (local profile in value.profiles) profile.hikingParties = profile.hikingParties + [self];
        return value;
    }
    assessPace(conditions, enhancedPercents)
    {
        if (self.assess().status != 'reused') rpgExpandedReject('hiking-party-unresolved');
        if (self.result.day != rpgLedger.seconds / 86400) rpgExpandedReject('hiking-party-expired');
        if (enhancedPercents.length() != self.attempts.length()) rpgExpandedReject('hiking-multiplier-members');
        local result = nil;
        for (local index = 1; index <= self.attempts.length(); index += 1)
        {
            local row = self.attempts[index].members[1];
            local value = rpgExpandedAssessHiking(row[1].move(),enhancedPercents[index],self.result.bonusAchieved,conditions);
            if (value.status != 'ready') return value;
            if (row[2].id != value.travelSkill) rpgExpandedReject('hiking-travel-skill-mismatch');
            if (result == nil || value.milesHundredths < result.milesHundredths) result = value;
        }
        return result;
    }
;

/** B355 full distance table. Ratios above eight remain table data, not lifting
 * permission. Both weight and Basic Lift are hundredths of a pound. */
rpgExpandedThrowDistanceFactor(weight, lift)
{
    rpgInteger(weight,1,1000000); rpgInteger(lift,1,1000000);
    local rows = [[5,350],[10,250],[15,200],[20,150],[25,120],[30,110],[40,100],[50,80],
        [75,70],[100,60],[150,40],[200,30],[250,25],[300,20],[400,15],[500,12],[600,10],
        [700,9],[800,8],[900,7],[1000,6],[1200,5]];
    foreach (local row in rows) if (weight * 100 <= lift * row[1]) return row[2];
    rpgExpandedReject('throw-distance-table-limit');
}
class RpgExpandedThrowSkillAssessment: RpgExpandedResult
    mode = 'unskilled'
    rangeStrengthBonus = 0
    damagePerDieBonus = 0
;
/** B356 skill bonuses, supplied as trained skill relative to DX. No default
 * skill grants these training bonuses; mode selection is an authored fact. */
rpgExpandedAssessThrowSkill(mode, relativeLevel, palmSized, cinematicAllowed)
{
    if (!holds(['unskilled','throwing','throwing-art'],mode)) rpgExpandedReject('throw-skill-mode');
    rpgInteger(relativeLevel,-1000,1000);
    local value = new RpgExpandedThrowSkillAssessment(); value.mode = mode;
    if (mode == 'throwing' && !palmSized) { value.reason = 'throw-skill-palm-size'; return value; }
    if (mode == 'throwing-art' && !cinematicAllowed) { value.reason = 'throw-cinematic-skill-disabled'; return value; }
    if (mode == 'throwing') value.rangeStrengthBonus = relativeLevel >= 2 ? 2 : relativeLevel >= 1 ? 1 : 0;
    if (mode == 'throwing-art')
    {
        value.rangeStrengthBonus = relativeLevel >= 1 ? 2 : relativeLevel >= 0 ? 1 : 0;
        value.damagePerDieBonus = value.rangeStrengthBonus;
    }
    value.status = 'ready'; return value;
}
class RpgExpandedThrowAssessment: RpgExpandedResult
    weightHundredths = 0
    handsRequired = 0
    distanceHundredths = 0
    distanceFactor = 0
    damageDice = 0
    damageAdds = 0
    damageType = 'cr'
    maneuver = 'attack'
    specificTargetModifier = -3
    generalAreaModifier = 0
    skillMode = 'unskilled'
;
/** B355-B356 ordinary-object assessment. A skill's range-strength bonus does
 * not change Basic Lift, eligibility or the strength used for base damage. */
rpgExpandedAssessThrow(strength, lift, weight, skillAssessment)
{
    rpgInteger(strength,1,1000); rpgInteger(lift,1,1000000); rpgInteger(weight,1,1000000);
    local value = new RpgExpandedThrowAssessment(); value.weightHundredths = weight;
    if (weight > lift * 8) { value.reason = 'throw-weight-limit'; return value; }
    local rangeBonus = 0; local damageBonus = 0;
    if (skillAssessment != nil)
    {
        if (!skillAssessment.ofKind(RpgExpandedThrowSkillAssessment)) rpgExpandedReject('throw-skill-assessment');
        if (skillAssessment.status != 'ready') { value.reason = skillAssessment.reason; return value; }
        rpgInteger(skillAssessment.rangeStrengthBonus,0,2); rpgInteger(skillAssessment.damagePerDieBonus,0,2);
        rangeBonus = skillAssessment.rangeStrengthBonus; damageBonus = skillAssessment.damagePerDieBonus;
        value.skillMode = skillAssessment.mode;
        if (value.skillMode != 'unskilled') value.specificTargetModifier = 0;
    }
    value.handsRequired = weight <= lift * 2 ? 1 : 2;
    value.distanceFactor = rpgExpandedThrowDistanceFactor(weight,lift);
    value.distanceHundredths = (strength + rangeBonus) * value.distanceFactor;
    local damage = rpgExpandedDamageDice(strength,nil); value.damageDice = damage[1]; value.damageAdds = damage[2];
    if (weight * 8 <= lift) value.damageAdds -= 2 * value.damageDice;
    else if (weight * 4 <= lift) value.damageAdds -= value.damageDice;
    else if (weight * 2 <= lift) value.damageAdds += 0;
    else if (weight <= lift) value.damageAdds += value.damageDice;
    else if (weight <= lift * 2) value.damageAdds += 0;
    else if (weight <= lift * 4) value.damageAdds -= (value.damageDice + 1) / 2;
    else value.damageAdds -= value.damageDice;
    value.damageAdds += damageBonus * value.damageDice;
    value.status = 'ready'; return value;
}

modify RpgExpandedThrowAssessment
    score = nil
;
/** Pure request for an ordinary object already held. Training, readiness and
 * hand legality come from owned state; execution remains a separate operation. */
class RpgExpandedHeldThrow: object
    hitLocation = 'torso'
    locationPart = nil
    locationEvidence = nil
    shieldAtLocation = nil
    targetEntity = nil
    profile = nil
    item = nil
    skill = nil
    target = 'specific'
    palmSized = nil
    modifier = 0
    offHand = nil
    approved = nil
    evidence = nil
    assess()
    {
        if (self.profile == nil || !self.profile.ofKind(RpgExpandedProfile) || self.item == nil
            || !self.item.ofKind(RpgLiteItem)) rpgExpandedReject('held-throw-definition');
        if (!holds(['specific','area'],self.target)) rpgExpandedReject('held-throw-target');
        rpgInteger(self.modifier,-1000,1000);
        local value = new RpgExpandedThrowAssessment();
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'held-throw-author-facts'; return value; }
        if (!holds(['torso','arm','hand','leg','foot'],self.hitLocation))
        { value.reason = 'throw-location-adapter-required'; return value; }
        if (self.hitLocation == 'torso' && (self.locationPart != nil || self.shieldAtLocation))
            rpgExpandedReject('throw-torso-location-facts');
        if (self.hitLocation != 'torso')
        {
            if (self.target != 'specific' || self.targetEntity == nil || !self.targetEntity.ofKind(RpgExpandedProfile)
                || self.locationEvidence == nil || self.locationEvidence == '')
            { value.reason = 'throw-location-facts-required'; return value; }
            if (self.shieldAtLocation && !holds(['arm','hand'],self.hitLocation)) rpgExpandedReject('throw-shield-location');
            value.reason = self.targetEntity.throwLocationReason(self.locationPart,self.hitLocation);
            if (value.reason != nil) return value;
        }
        if (self.item.ofKind(RpgLiteWeapon)) { value.reason = 'throw-weapon-procedure-required'; return value; }
        if (!holds(self.profile.equipment,self.item) || !self.item.usableBy(self.profile)
            || !self.item.ready || self.item.worn) { value.reason = 'throw-item-not-held'; return value; }
        if (self.item.quantity != 1) { value.reason = 'throw-single-object-required'; return value; }
        if (self.profile.dead || self.profile.unconscious || self.profile.mortal || self.profile.stunned
            || self.profile.mentalStun || self.profile.healthEffortReason('action',nil,nil,true) != nil)
        { value.reason = 'throw-actor-unavailable'; return value; }
        if (self.profile.fp() * 3 < self.profile.maxEnergy)
        { value.reason = 'throw-fatigued-strength-adapter-required'; return value; }
        local trained = nil; local relative = 0;
        if (self.skill != nil)
        {
            if (!self.skill.ofKind(RpgLiteSkill) || self.skill.id != 'throwing' || self.skill.attribute != rpgDX
                || self.skill.difficulty != 1 || self.skill.defaultPenalty != -3)
                rpgExpandedReject('held-throw-skill-definition');
            if (!self.palmSized) { value.reason = 'throw-skill-palm-size'; return value; }
            foreach (local training in self.profile.skills)
                if (training.skill == self.skill && training.points > 0) trained = true;
            if (trained)
            {
                local level = self.profile.skillScore(self.skill);
                if (level == nil) { value.reason = 'throw-skill-unavailable'; return value; }
                relative = level - self.profile.attributeScore(rpgDX);
            }
        }
        local bonuses = rpgExpandedAssessThrowSkill(trained ? 'throwing' : 'unskilled',relative,self.palmSized,nil);
        value = rpgExpandedAssessThrow(self.profile.st,self.profile.basicLiftHundredths(),self.item.weightHundredths(),bonuses);
        if (value.status != 'ready') return value;
        value.reason = self.item.throwingHandsReason(self.profile,value.handsRequired);
        if (value.reason != nil) { value.status = 'blocked'; return value; }
        local context = new RpgLiteContext(); context.kind = 'throwing'; context.attribute = rpgDX;
        context.requiresMovement = true; context.offHand = self.offHand; context.modifier = self.modifier;
        if (self.hitLocation != 'torso') context.modifier -= holds(['arm','leg'],self.hitLocation)
            ? (self.shieldAtLocation ? 4 : 2) : (self.shieldAtLocation ? 8 : 4);
        if (self.skill != nil && (trained || self.target == 'specific')) context.skill = self.skill;
        else if (self.target == 'specific') context.modifier -= 3;
        value.score = rpgLiteScore(self.profile,context);
        if (value.score == nil || value.score < 3) { value.status = 'blocked'; value.reason = 'throw-score-unavailable'; }
        return value;
    }
;

class RpgExpandedCatchAssessment: RpgExpandedResult
    throwCheck = nil
    score = nil
    throwBonus = 0
    waitPenalty = 0
    countsAsParry = nil
    caught = nil
;
/** B355 deliberate pass only. score is DX or the authored suitable sports
 * score, before the waiting penalty and the thrower's success-margin bonus. */
rpgExpandedAssessCatch(score, waiting, throwScore, throwRoll, deliberate)
{
    rpgInteger(score,-1000,1000); rpgInteger(throwScore,-1000,1000); rpgInteger(throwRoll,3,18);
    local value = new RpgExpandedCatchAssessment();
    if (!deliberate) { value.reason = 'catch-defense-procedure-required'; return value; }
    value.throwCheck = rpgExpandedCombatCheck('ranged',throwScore,throwRoll);
    if (!value.throwCheck.achieved) { value.reason = 'catch-lob-not-successful'; return value; }
    /* An automatic low-roll success with a negative margin supplies no bonus. */
    value.throwBonus = value.throwCheck.margin > 0 ? value.throwCheck.margin / 2 : 0;
    value.waitPenalty = waiting ? 0 : -4;
    value.modifier = value.throwBonus + value.waitPenalty; value.score = score + value.modifier;
    rpgInteger(value.score,-1000,1000);
    value.countsAsParry = true; value.status = 'ready'; return value;
}

/** Pure interpretation of a supplied catcher roll, not a second thrower roll.
 * Inventory transfer and parry consumption belong to the owned catch action. */
rpgExpandedResolveCatch(score, waiting, throwScore, throwRoll, deliberate, catchRoll)
{
    local value = rpgExpandedAssessCatch(score,waiting,throwScore,throwRoll,deliberate);
    if (value.status != 'ready') return value;
    rpgInteger(catchRoll,3,18); value.check = rpgExpandedCombatCheck('defense',value.score,catchRoll);
    value.caught = value.check.achieved; return value;
}

modify RpgExpandedHeldThrow
    definition()
    {
        local values = [self.profile,self.item,self.skill,self.target,self.palmSized,self.modifier,
            self.offHand,self.approved,self.evidence,self.targetEntity,self.hitLocation,self.locationPart,self.locationEvidence,self.shieldAtLocation];
        if (self.skill != nil) values = values + [self.skill.id,self.skill.attribute,self.skill.difficulty,self.skill.defaultPenalty];
        return values;
    }
;
modify RpgExpandedProfile
    throwAttempts = []
;
class RpgExpandedThrowAttemptResult: RpgExpandedResult
    assessment = nil
    gate = nil
    allowed = nil
;
/** Owned roll stage for one authored throw occurrence. It does not release the
 * object, charge maneuver time, resolve critical consequences or apply damage. */
class RpgExpandedThrowAttempt: RpgExpandedThrowReceipt
    id = nil
    request = nil
    occurrence = nil
    recipient = nil
    result = nil
    boundDefinition = nil
    committedAt = nil
    definition()
    { return [self.id,self.request,self.occurrence,self.recipient] + self.request.definition(); }
    assess()
    {
        if (self.id == nil || self.id == '' || self.request == nil || !self.request.ofKind(RpgExpandedHeldThrow)
            || self.occurrence == nil || dataType(self.occurrence) != TypeObject)
            rpgExpandedReject('throw-attempt-definition');
        local value = new RpgExpandedThrowAttemptResult();
        if (self.result != nil)
        {
            local current = self.definition();
            if (current.length() != self.boundDefinition.length()) rpgExpandedReject('throw-attempt-binding');
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.boundDefinition[index]) rpgExpandedReject('throw-attempt-binding');
            if (!holds(self.request.profile.throwAttempts,self) || self.result.gate.assess().status != 'reused')
                rpgExpandedReject('throw-attempt-history');
            value.status = 'reused'; return value;
        }
        value.assessment = self.request.assess();
        if (value.assessment.status != 'ready') { value.reason = value.assessment.reason; return value; }
        if (self.recipient != nil && (!self.recipient.ofKind(RpgExpandedProfile)
            || self.recipient == self.request.profile || self.request.target != 'area'))
            rpgExpandedReject('throw-pass-recipient');
        foreach (local prior in self.request.profile.throwAttempts)
            if (prior.id == self.id || prior.occurrence == self.occurrence) rpgExpandedReject('throw-attempt-duplicate');
        value.gate = self.request.profile.prepareThrowGate(self.id,self.request.evidence);
        if (value.gate == nil) { value.reason = 'throw-permission-adapter-required'; return value; }
        local permission = value.gate.assess();
        if (permission.status != 'ready') { value.reason = permission.reason; return value; }
        value.status = 'ready'; return value;
    }
    resolve()
    {
        local value = self.assess(); if (value.status == 'reused') return self.result;
        if (value.status != 'ready') return value;
        local definition = self.definition(); local permission = value.gate.apply();
        if (permission.status != 'resolved') rpgExpandedReject('throw-permission-changed');
        local current = self.definition();
        if (current.length() != definition.length()) rpgExpandedReject('throw-attempt-interrupted');
        for (local index = 1; index <= current.length(); index += 1)
            if (current[index] != definition[index]) rpgExpandedReject('throw-attempt-interrupted');
        value.allowed = permission.allowed; value.reason = permission.reason;
        if (value.allowed)
        {
            local after = self.request.assess();
            if (after.status != 'ready' || after.score != value.assessment.score
                || after.distanceHundredths != value.assessment.distanceHundredths
                || after.damageDice != value.assessment.damageDice || after.damageAdds != value.assessment.damageAdds)
                rpgExpandedReject('throw-assessment-changed');
            value.check = rpgExpandedCombatCheck('ranged',after.score,rpgRandom.roll());
        }
        self.boundDefinition = definition; self.committedAt = rpgLedger.seconds; self.result = value;
        self.request.profile.throwAttempts = self.request.profile.throwAttempts + [self];
        value.status = 'resolved'; return value;
    }
    assessCatch(recipient, score, waiting)
    {
        local prepared = self.assess();
        if (prepared.status != 'reused') rpgExpandedReject('catch-throw-unresolved');
        if (self.recipient == nil || self.recipient != recipient) rpgExpandedReject('catch-throw-recipient');
        if (!self.result.allowed || self.result.check == nil)
        { local value = new RpgExpandedCatchAssessment(); value.reason = 'catch-throw-not-permitted'; return value; }
        return rpgExpandedAssessCatch(score,waiting,self.result.check.score,self.result.check.roll,true);
    }
;

modify RpgExpandedProfile
    thrownDamageRolls = []
;
class RpgExpandedThrownDamageResult: RpgExpandedResult
    targetDice = []
    objectDice = []
    targetDamage = 0
    objectDamage = nil
    dice = 0
    adds = 0
;
/** B355 damage-roll stage for one confirmed ordinary hit. Defense adjudication
 * precedes this stage; protection and injury follow it. A fragile thrown object
 * or character receives a separate damage roll, not a copy of the target roll. */
class RpgExpandedThrownDamage: RpgExpandedThrownDamageReceipt
    objectProfile = nil
    id = nil
    attempt = nil
    objectKind = 'durable'
    damageType = 'cr'
    shapeEvidence = nil
    defensesResolved = nil
    hitConfirmed = nil
    approved = nil
    evidence = nil
    result = nil
    boundDefinition = nil
    definition()
    { return [self.id,self.attempt,self.objectKind,self.damageType,self.shapeEvidence,
        self.defensesResolved,self.hitConfirmed,self.approved,self.evidence,self.objectProfile]; }
    assess()
    {
        if (self.id == nil || self.id == '' || self.attempt == nil || !self.attempt.ofKind(RpgExpandedThrowAttempt))
            rpgExpandedReject('thrown-damage-definition');
        local value = new RpgExpandedThrownDamageResult();
        if (self.attempt.result == nil) { value.reason = 'thrown-damage-throw-unresolved'; return value; }
        if (self.attempt.assess().status != 'reused') rpgExpandedReject('thrown-damage-throw-history');
        if (self.result != nil)
        {
            local current = self.definition();
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.boundDefinition[index]) rpgExpandedReject('thrown-damage-binding');
            if (!holds(self.attempt.request.profile.thrownDamageRolls,self)) rpgExpandedReject('thrown-damage-history');
            value.status = 'reused'; return value;
        }
        foreach (local prior in self.attempt.request.profile.thrownDamageRolls)
            if (prior.id == self.id || prior.attempt == self.attempt) rpgExpandedReject('thrown-damage-duplicate');
        if (!self.approved || !self.defensesResolved || !self.hitConfirmed || self.evidence == nil || self.evidence == '')
        { value.reason = 'thrown-damage-hit-facts'; return value; }
        if (!holds(['durable','fragile','character'],self.objectKind)) rpgExpandedReject('thrown-damage-object-kind');
        if (!holds(['cr','cut','pi','imp'],self.damageType)) rpgExpandedReject('thrown-damage-type');
        if (self.damageType != 'cr' && (self.shapeEvidence == nil || self.shapeEvidence == ''))
        { value.reason = 'thrown-damage-shape-evidence'; return value; }
        if (self.attempt.request.target != 'specific' || self.attempt.request.targetEntity == nil
            || dataType(self.attempt.request.targetEntity) != TypeObject)
        { value.reason = 'thrown-damage-specific-target-required'; return value; }
        local check = self.attempt.result.check;
        if (!self.attempt.result.allowed || check == nil || !check.achieved)
        { value.reason = 'thrown-damage-no-hit'; return value; }
        if (check.critical != nil) { value.reason = 'thrown-damage-critical-procedure-required'; return value; }
        value.dice = self.attempt.result.assessment.damageDice; value.adds = self.attempt.result.assessment.damageAdds;
        rpgInteger(value.dice,1,100); rpgInteger(value.adds,-1000,1000);
        value.status = 'ready'; return value;
    }
    resolve()
    {
        local value = self.assess(); if (value.status == 'reused') return self.result;
        if (value.status != 'ready') return value;
        local targetTotal = value.adds;
        for (local index = 0; index < value.dice; index += 1)
        { local die = rpgRandom.die(); value.targetDice = value.targetDice + [die]; targetTotal += die; }
        local minimum = self.damageType == 'cr' ? 0 : 1;
        value.targetDamage = targetTotal < minimum ? minimum : targetTotal;
        if (self.objectKind != 'durable')
        {
            local objectTotal = value.adds;
            for (local index = 0; index < value.dice; index += 1)
            { local die = rpgRandom.die(); value.objectDice = value.objectDice + [die]; objectTotal += die; }
            value.objectDamage = objectTotal < minimum ? minimum : objectTotal;
        }
        self.boundDefinition = self.definition(); self.result = value;
        self.attempt.request.profile.thrownDamageRolls = self.attempt.request.profile.thrownDamageRolls + [self];
        value.status = 'resolved'; return value;
    }
;


modify RpgExpandedThrowAttempt
    releaseAssessment()
    {
        local value = new RpgExpandedThrowReleaseFacts();
        if (self.result == nil) { value.reason = 'throw-release-unresolved'; return value; }
        if (self.assess().status != 'reused') rpgExpandedReject('throw-release-receipt-history');
        if (!self.result.allowed || self.result.check == nil)
        { value.reason = 'throw-release-not-permitted'; return value; }
        if (self.result.check.critical == 'failure')
        { value.reason = 'throw-release-critical-failure-required'; return value; }
        value.profile = self.request.profile; value.item = self.request.item; value.recipient = self.recipient;
        value.weight = self.result.assessment.weightHundredths; value.status = 'ready'; return value;
    }
;


modify RpgExpandedThrownDamage
    injuryAssessment(side)
    {
        if (!holds(['target','object'],side)) rpgExpandedReject('thrown-injury-side');
        local value = new RpgExpandedThrownInjuryFacts();
        if (self.result == nil) { value.reason = 'thrown-injury-damage-unresolved'; return value; }
        if (self.assess().status != 'reused') rpgExpandedReject('thrown-injury-damage-history');
        if (side == 'object' && self.objectKind != 'character')
        { value.reason = 'thrown-injury-object-health-unavailable'; return value; }
        value.profile = side == 'target' ? self.attempt.request.targetEntity : self.objectProfile;
        if (value.profile == nil || !value.profile.ofKind(RpgExpandedProfile))
        { value.reason = 'thrown-injury-profile-required'; return value; }
        if (side == 'target')
        { value.location = self.attempt.request.hitLocation; value.bodyPart = self.attempt.request.locationPart; }
        value.damage = side == 'target' ? self.result.targetDamage : self.result.objectDamage;
        value.damageType = self.damageType; value.status = 'ready'; return value;
    }
;

modify RpgExpandedProfile
    catchAttempts = []
;
class RpgExpandedCatchAttemptResult: RpgExpandedResult
    assessment = nil
    caught = nil
    concentrationScore = nil
    concentrationCheck = nil
    concentrationLost = nil
;
/** Owned first hand-parry catch of a deliberate pass. The fighter owns turn
 * counters; this stage owns the roll but not the later inventory transfer. */
class RpgExpandedCatchAttempt: RpgExpandedCatchReceipt
    id = nil
    flight = nil
    fighter = nil
    hand = nil
    otherHand = nil
    skill = nil
    sportEvidence = nil
    waiting = nil
    modifier = 0
    aware = nil
    approved = nil
    evidence = nil
    result = nil
    boundDefinition = nil
    definition()
    { return [self.id,self.flight,self.fighter,self.hand,self.otherHand,self.skill,self.sportEvidence,
        self.waiting,self.modifier,self.aware,self.approved,self.evidence,self.fighter.profile,
        self.skill == nil ? nil : self.skill.id,self.skill == nil ? nil : self.skill.attribute,
        self.skill == nil ? nil : self.skill.specialty]; }
    assess()
    {
        if (self.id == nil || self.id == '' || self.flight == nil || !self.flight.ofKind(RpgExpandedThrowFlightReceipt)
            || self.fighter == nil || !self.fighter.ofKind(RpgLiteFighter) || self.fighter.profile == nil
            || !self.fighter.profile.ofKind(RpgExpandedProfile)) rpgExpandedReject('catch-attempt-definition');
        local value = new RpgExpandedCatchAttemptResult(); local profile = self.fighter.profile;
        if (self.result != nil)
        {
            local current = self.definition();
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.boundDefinition[index]) rpgExpandedReject('catch-attempt-binding');
            if (!holds(profile.catchAttempts,self)) rpgExpandedReject('catch-attempt-history');
            value.status = 'reused'; return value;
        }
        foreach (local prior in profile.catchAttempts)
            if (prior.id == self.id || prior.flight == self.flight) rpgExpandedReject('catch-attempt-duplicate');
        if (!self.approved || !self.aware || self.evidence == nil || self.evidence == '')
        { value.reason = 'catch-attempt-author-facts'; return value; }
        local facts = self.flight.flightAssessment();
        if (facts.status != 'ready') { value.reason = facts.reason; return value; }
        if (facts.recipient != profile) rpgExpandedReject('catch-attempt-recipient');
        if (profile.dead || profile.unconscious || profile.healthBlocksDefense()
            || holds(['all-out-attack','move-attack'],self.fighter.maneuver))
        { value.reason = 'catch-defense-unavailable'; return value; }
        local previousParries = self.otherHand ? self.fighter.offParries : self.fighter.parries;
        rpgInteger(previousParries,0,1000);
        local repeatPenalty = previousParries * (4 / profile.martialParryDivisor());
        rpgInteger(self.fighter.concentration,0,1000000);
        if (self.fighter.concentration > 0)
        {
            local distraction = new RpgLiteContext(); distraction.attribute = rpgWill;
            distraction.kind = 'concentration'; distraction.modifier = -3;
            value.concentrationScore = rpgLiteScore(profile,distraction);
            if (value.concentrationScore == nil)
            { value.reason = 'catch-concentration-score-unavailable'; return value; }
            rpgInteger(value.concentrationScore,-1000,1000);
        }
        value.reason = profile.catchHandReason(self.hand); if (value.reason != nil) return value;
        if (facts.weight > profile.basicLiftHundredths() * 2)
        { value.reason = 'catch-heavy-object-adapter-required'; return value; }
        if (self.skill != nil && (!self.skill.ofKind(RpgLiteSkill) || self.skill.id != 'sports'
            || self.skill.attribute != rpgDX || self.skill.specialty == nil || self.sportEvidence == nil || self.sportEvidence == ''))
            rpgExpandedReject('catch-sports-definition');
        rpgInteger(self.modifier,-1000,1000);
        local context = new RpgLiteContext(); context.kind = 'defense'; context.attribute = rpgDX;
        context.skill = self.skill; context.offHand = self.otherHand; context.modifier = self.modifier;
        local score = rpgLiteScore(profile,context);
        if (score == nil) { value.reason = 'catch-score-unavailable'; return value; }
        local penalty = profile.healthDefensePenalty();
        if ((profile.stunned || profile.mentalStun) && penalty < 4) penalty = 4;
        score += profile.level('combat-reflexes') + rpgLitePostureModifier(profile.posture,true) - penalty - repeatPenalty;
        if (self.fighter.maneuver == 'all-out-defense' && self.fighter.defenseOption == 'parry') score += 2;
        value.assessment = facts.throwReceipt.assessCatch(profile,score,self.waiting);
        if (value.assessment.status != 'ready') { value.reason = value.assessment.reason; return value; }
        value.status = 'ready'; return value;
    }
    resolve()
    {
        local value = self.assess(); if (value.status == 'reused') return self.result;
        if (value.status != 'ready') return value;
        if (self.otherHand) self.fighter.offParries += 1; else self.fighter.parries += 1;
        self.fighter.participated = true; self.fighter.aimSeconds = 0;
        value.check = rpgExpandedCombatCheck('defense',value.assessment.score,rpgRandom.roll());
        value.caught = value.check.achieved;
        if (value.concentrationScore != nil)
        {
            value.concentrationCheck = rpgCheck(value.concentrationScore,
                value.concentrationScore < 3 ? 3 : rpgRandom.roll());
            value.concentrationLost = !value.concentrationCheck.achieved;
            if (value.concentrationLost) self.fighter.concentration = 0;
        }
        self.boundDefinition = self.definition(); self.result = value;
        self.fighter.profile.catchAttempts = self.fighter.profile.catchAttempts + [self];
        value.status = 'resolved'; return value;
    }
;

modify RpgExpandedCatchAttempt
    captureAssessment()
    {
        local value = new RpgExpandedCatchFacts();
        if (self.result == nil) { value.reason = 'catch-roll-unresolved'; return value; }
        if (self.assess().status != 'reused') rpgExpandedReject('catch-roll-history');
        if (!self.result.caught) { value.reason = 'catch-roll-unsuccessful'; return value; }
        value.flight = self.flight; value.recipient = self.fighter.profile; value.hand = self.hand;
        value.status = 'ready'; return value;
    }
;

class RpgExpandedJumpAssessment: RpgExpandedResult
    basis = 0
    highInchTenths = 0
    broadInchTenths = 0
;
/** B352 ordinary jump distances. -1 disables the optional encumbrance rule.
 * Integer tenths of an inch preserve preparation and fifth-based load factors. */
rpgExpandedAssessJump(basicMove, runYards, jumpingSkill, prepared, encumbrance)
{
    rpgInteger(basicMove,0,1000); rpgInteger(runYards,0,1000);
    rpgInteger(encumbrance,-1,4);
    local value = new RpgExpandedJumpAssessment(); local basis = basicMove;
    if (jumpingSkill != nil)
    { rpgInteger(jumpingSkill,0,1000); basis = jumpingSkill / 2; }
    value.basis = basis;
    if (basis < 2) { value.reason = 'jump-low-movement-adapter-required'; return value; }
    local standingHigh = 6 * basis - 10; local standingBroad = 2 * basis - 3;
    local high = 6 * (basis + runYards) - 10;
    local broad = 2 * (basis + runYards) - 3;
    if (high > standingHigh * 2) high = standingHigh * 2;
    if (broad > standingBroad * 2) broad = standingBroad * 2;
    local factor = encumbrance < 0 ? 5 : 5 - encumbrance;
    value.highInchTenths = high * (prepared ? 2 : 1) * factor;
    value.broadInchTenths = broad * 12 * (prepared ? 2 : 1) * factor;
    value.status = 'ready'; return value;
}

/** B352 optional strength basis; weight and lift share hundredths of a pound. */
rpgExpandedJumpStrengthBasis(basicMove, strength, lift, bodyWeight, enabled)
{
    rpgInteger(basicMove,0,1000); rpgInteger(strength,1,1000);
    rpgInteger(lift,1,100000000); rpgInteger(bodyWeight,1,100000000);
    if (enabled && lift > bodyWeight && strength / 4 > basicMove) return strength / 4;
    return basicMove;
}

/** Pure profile-backed distance request. Preparation/route commitment is separate. */
class RpgExpandedJumpDistance: object
    profile = nil
    skill = nil
    runYards = 0
    prepared = nil
    encumbranceOption = nil
    strengthOption = nil
    bodyWeightHundredths = nil
    bodyWeightEvidence = nil
    assess()
    {
        if (self.profile == nil || !self.profile.ofKind(RpgExpandedProfile))
            rpgExpandedReject('jump-profile-required');
        local basis = self.profile.basicMove(); local skillScore = nil;
        if (self.strengthOption)
        {
            if (self.bodyWeightEvidence == nil || self.bodyWeightEvidence == '')
                rpgExpandedReject('jump-body-weight-evidence');
            basis = rpgExpandedJumpStrengthBasis(basis,self.profile.st,self.profile.basicLiftHundredths(),
                self.bodyWeightHundredths,true);
        }
        if (self.skill != nil)
        {
            if (!self.skill.ofKind(RpgLiteSkill) || self.skill.id != 'jumping'
                || self.skill.attribute != rpgDX || self.skill.difficulty != 0 || self.skill.defaultPenalty != nil)
                rpgExpandedReject('jump-skill-definition');
            local trained = nil;
            foreach (local training in self.profile.skills)
                if (training.skill == self.skill && training.points > 0) trained = true;
            if (!trained) rpgExpandedReject('jump-skill-untrained');
            skillScore = self.profile.skillScore(self.skill);
            if (skillScore == nil) rpgExpandedReject('jump-skill-unavailable');
        }
        local value = rpgExpandedAssessJump(basis,self.runYards,skillScore,self.prepared,
            self.encumbranceOption ? self.profile.encumbrance() : -1);
        if (value.status != 'ready') return value;
        local levels = self.profile.enhancedJumpLevels(); rpgInteger(levels,0,100);
        for (local index = 0; index < levels; index += 1)
        {
            if (value.highInchTenths > 1073741823 || value.broadInchTenths > 1073741823)
            { value.status = 'blocked'; value.reason = 'jump-distance-numeric-limit'; return value; }
            value.highInchTenths *= 2; value.broadInchTenths *= 2;
        }
        return value;
    }
;

modify RpgExpandedJumpDistance
    maximumAssessment()
    {
        local request = new RpgExpandedJumpDistance(); request.profile = self.profile;
        request.runYards = 1000; request.prepared = true;
        request.encumbranceOption = self.encumbranceOption; request.strengthOption = self.strengthOption;
        request.bodyWeightHundredths = self.bodyWeightHundredths; request.bodyWeightEvidence = self.bodyWeightEvidence;
        local best = request.assess(); if (best.status != 'ready') return best;
        foreach (local training in self.profile.skills)
            if (training.points > 0 && training.skill.ofKind(RpgLiteSkill) && training.skill.id == 'jumping')
            {
                request.skill = training.skill; local candidate = request.assess();
                if (candidate.status != 'ready') return candidate;
                if (candidate.highInchTenths > best.highInchTenths) best = candidate;
            }
        return best;
    }
;
modify RpgExpandedProfile
    jumpFallProtections = []
;
/** B89 passive fall immunity, optionally using one already owned B431 acrobatics roll. */
class RpgExpandedJumpFallProtection: RpgExpandedLandingReceipt
    id = nil
    profile = nil
    fall = nil
    distance = 1
    jumping = nil
    acrobatics = nil
    result = nil
    boundDefinition = nil
    definition()
    { return [self.id,self.profile,self.fall,self.distance,self.jumping,self.acrobatics,
        self.jumping.encumbranceOption,self.jumping.strengthOption,
        self.jumping.bodyWeightHundredths,self.jumping.bodyWeightEvidence]; }
    assess()
    {
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)
            || self.fall == nil || dataType(self.fall) != TypeObject || self.jumping == nil
            || !self.jumping.ofKind(RpgExpandedJumpDistance) || self.jumping.profile != self.profile)
            rpgExpandedReject('jump-fall-definition');
        local value = new RpgExpandedLandingAssessment();
        if (self.result != nil)
        {
            local current = self.definition();
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.boundDefinition[index]) rpgExpandedReject('jump-fall-binding');
            if (!holds(self.profile.jumpFallProtections,self)) rpgExpandedReject('jump-fall-history');
            if (self.acrobatics != nil) self.acrobatics.impactFor(self.profile,self.fall);
            value.status = 'reused'; return value;
        }
        foreach (local prior in self.profile.jumpFallProtections)
            if (prior.id == self.id || prior.fall == self.fall) rpgExpandedReject('jump-fall-duplicate');
        rpgInteger(self.distance,1,112);
        if (self.profile.enhancedJumpLevels() == 0)
        { value.reason = 'jump-fall-trait-required'; return value; }
        local maximum = self.jumping.maximumAssessment();
        if (maximum.status != 'ready') { value.reason = maximum.reason; return value; }
        value.effectiveDistance = self.distance;
        if (self.acrobatics != nil)
        {
            if (!self.acrobatics.ofKind(RpgExpandedLandingAttempt) || self.acrobatics.method != 'acrobatics'
                || self.acrobatics.distance != self.distance) rpgExpandedReject('jump-fall-acrobatics');
            local landing = self.acrobatics.impactFor(self.profile,self.fall);
            value.effectiveDistance = landing.effectiveDistance; value.check = landing.check;
        }
        value.negatesDamage = value.effectiveDistance * 360 <= maximum.highInchTenths;
        value.velocity = value.negatesDamage ? 0 : rpgExpandedFallVelocity(value.effectiveDistance);
        value.status = 'ready'; return value;
    }
    resolve()
    {
        local value = self.assess(); if (value.status == 'reused') return self.result;
        if (value.status != 'ready') return value;
        self.boundDefinition = self.definition(); self.result = value;
        self.profile.jumpFallProtections = self.profile.jumpFallProtections + [self];
        value.status = 'resolved'; return value;
    }
    impactFor(profile,fall)
    {
        if (self.result == nil || self.profile != profile || self.fall != fall)
            rpgExpandedReject('jump-fall-receipt-owner');
        self.assess(); return self.result;
    }
;

class RpgExpandedJumpTravelAssessment: RpgExpandedResult
    speedNumerator = 0
    speedDenominator = 1800
    distanceInchTenths = 0
    maximumInchTenths = 0
;
/** B89 speed is max(ground Move, maximum broad jump / five seconds).
 * Numerator uses tenths of inches per five seconds, denominator yards per second. */
rpgExpandedAssessJumpTravel(groundMove, maximumInchTenths, distanceInchTenths)
{
    rpgInteger(groundMove,0,1000); rpgInteger(maximumInchTenths,1,2147483647);
    rpgInteger(distanceInchTenths,0,2147483647);
    local value = new RpgExpandedJumpTravelAssessment();
    value.maximumInchTenths = maximumInchTenths; value.distanceInchTenths = distanceInchTenths;
    if (distanceInchTenths > maximumInchTenths) { value.reason = 'jump-travel-distance'; return value; }
    value.speedNumerator = groundMove * 1800;
    if (value.speedNumerator < maximumInchTenths) value.speedNumerator = maximumInchTenths;
    /* Compare to floor(speed * elapsed) without multiplying large distances. */
    while (value.seconds < 5 && distanceInchTenths >
        (value.speedNumerator / 5) * value.seconds + (value.speedNumerator % 5) * value.seconds / 5)
        value.seconds += 1;
    value.status = 'ready'; return value;
}

modify RpgExpandedJumpDistance
    travelAssessment(distanceInchTenths)
    {
        local actual = self.assess(); if (actual.status != 'ready') return actual;
        local value = new RpgExpandedJumpTravelAssessment();
        if (self.profile.enhancedJumpLevels() == 0)
        { value.reason = 'jump-travel-trait-required'; return value; }
        rpgInteger(distanceInchTenths,0,2147483647);
        if (distanceInchTenths > actual.broadInchTenths)
        { value.reason = 'jump-travel-launch-distance'; return value; }
        local maximum = self.maximumAssessment(); if (maximum.status != 'ready') return maximum;
        return rpgExpandedAssessJumpTravel(self.profile.move(),maximum.broadInchTenths,distanceInchTenths);
    }
;

/** B352 two consecutive concentration turns owned by an existing battle. */
class RpgExpandedJumpPreparation: RpgExpandedJumpPreparationReceipt
    fighter = nil
    battle = nil
    turns = 0
    lastBattleSecond = nil
    lastConcentration = nil
    lastLedgerSecond = nil
    boundFighter = nil
    boundBattle = nil
    available(fighter)
    {
        if (self.fighter == nil || !self.fighter.ofKind(RpgLiteFighter) || self.fighter != fighter
            || self.battle == nil || !self.battle.ofKind(RpgLiteBattle))
            rpgExpandedReject('jump-preparation-definition');
        if (self.turns > 0 && (self.fighter != self.boundFighter || self.battle != self.boundBattle))
            rpgExpandedReject('jump-preparation-binding');
        if (!self.battle.active || self.battle.current() != fighter) return 'jump-preparation-turn';
        if (self.lastBattleSecond == self.battle.seconds) return 'jump-preparation-duplicate-turn';
        return nil;
    }
    record(fighter)
    {
        local reason = self.available(fighter); if (reason != nil) rpgExpandedReject(reason);
        if (fighter.maneuver != 'concentrate' || fighter.concentration < 1)
            rpgExpandedReject('jump-preparation-maneuver');
        if (self.lastBattleSecond == self.battle.seconds) rpgExpandedReject('jump-preparation-duplicate-turn');
        if (self.lastBattleSecond != nil && self.battle.seconds == self.lastBattleSecond + 1
            && rpgLedger.seconds == self.lastLedgerSecond + 1 && fighter.concentration == self.lastConcentration + 1) self.turns = 2;
        else self.turns = 1;
        self.boundFighter = fighter; self.boundBattle = self.battle; self.lastLedgerSecond = rpgLedger.seconds;
        self.lastBattleSecond = self.battle.seconds; self.lastConcentration = fighter.concentration;
        return nil;
    }
    readyFor(profile)
    {
        if (self.fighter == nil || self.battle == nil || self.fighter.profile != profile
            || self.fighter != self.boundFighter || self.battle != self.boundBattle
            || !self.battle.active || self.turns < 2 || self.fighter.concentration != self.lastConcentration
            || self.fighter.maneuver != 'concentrate') return nil;
        return self.battle.seconds >= self.lastBattleSecond && self.battle.seconds <= self.lastBattleSecond + 1
            && rpgLedger.seconds - self.lastLedgerSecond == self.battle.seconds - self.lastBattleSecond;
    }
;
modify RpgExpandedJumpDistance
    preparation = nil
    combatAssessment()
    {
        if (self.preparation == nil || !self.preparation.ofKind(RpgExpandedJumpPreparationReceipt))
            rpgExpandedReject('jump-preparation-receipt-required');
        local request = new RpgExpandedJumpDistance(); request.profile = self.profile; request.skill = self.skill;
        request.runYards = self.runYards; request.prepared = self.preparation.readyFor(self.profile);
        request.encumbranceOption = self.encumbranceOption; request.strengthOption = self.strengthOption;
        request.bodyWeightHundredths = self.bodyWeightHundredths; request.bodyWeightEvidence = self.bodyWeightEvidence;
        return request.assess();
    }
;

class RpgExpandedJumpLaunchResult: RpgExpandedResult
    launch = nil
    definition = []
    distance = nil
    score = nil
    succeeded = nil
    fallRequired = nil
    fallOutcome = nil
    positionOutcome = nil
    fallVelocity = 0
;
modify RpgExpandedProfile
    jumpLaunches = []
;
/** B352 whole-turn jump outcome; route and fall consequences remain separate. */
class RpgExpandedJumpLaunch: RpgExpandedJumpLaunchReceipt
    id = nil
    occurrence = nil
    fighter = nil
    battle = nil
    jumping = nil
    direction = 'horizontal'
    requiredInchTenths = 0
    fallYards = nil
    fallPlan = nil
    positionPlan = nil
    difficult = nil
    penalty = 0
    approved = nil
    evidence = nil
    result = nil
    boundDefinition = nil
    definition()
    { return [self.id,self.occurrence,self.fighter,self.battle,self.jumping,self.direction,
        self.requiredInchTenths,self.difficult,self.penalty,self.approved,self.evidence,
        self.jumping.profile,self.jumping.skill,self.jumping.runYards,self.jumping.preparation,
        self.jumping.strengthOption,self.jumping.bodyWeightHundredths,self.jumping.bodyWeightEvidence,
        self.jumping.encumbranceOption,self.fallYards,self.fallPlan,self.positionPlan]
        + (self.positionPlan == nil ? [] : self.positionPlan.definition()); }
    assess()
    {
        if (self.id == nil || self.id == '' || self.occurrence == nil || dataType(self.occurrence) != TypeObject
            || self.fighter == nil || !self.fighter.ofKind(RpgLiteFighter)
            || self.battle == nil || !self.battle.ofKind(RpgLiteBattle)
            || self.jumping == nil || !self.jumping.ofKind(RpgExpandedJumpDistance)
            || self.jumping.profile != self.fighter.profile) rpgExpandedReject('jump-launch-definition');
        local value = new RpgExpandedJumpLaunchResult(); value.launch = self; value.definition = self.definition();
        if (self.result != nil)
        {
            for (local index = 1; index <= value.definition.length(); index += 1)
                if (value.definition[index] != self.boundDefinition[index]) rpgExpandedReject('jump-launch-binding');
            if (!holds(self.fighter.profile.jumpLaunches,self)) rpgExpandedReject('jump-launch-history');
            if (self.result.fallRequired) self.fallPlan.validateResult(self.fighter.profile,self.occurrence,self.result.fallVelocity);
            if (self.positionPlan != nil) self.positionPlan.validateResult(self.fighter.profile,self.occurrence,self.result.succeeded);
            value.status = 'reused'; return value;
        }
        foreach (local prior in self.fighter.profile.jumpLaunches)
            if (prior.id == self.id || prior.occurrence == self.occurrence) rpgExpandedReject('jump-launch-duplicate');
        if (!self.battle.active || self.battle.current() != self.fighter)
        { value.reason = 'jump-launch-turn'; return value; }
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'jump-launch-author-facts'; return value; }
        if (!holds(['horizontal','vertical'],self.direction)) rpgExpandedReject('jump-launch-direction');
        rpgInteger(self.requiredInchTenths,1,2147483647); rpgInteger(self.penalty,-5,0);
        if (!self.difficult && self.penalty != 0) rpgExpandedReject('jump-launch-penalty');
        value.distance = self.jumping.combatAssessment();
        if (value.distance.status != 'ready') { value.reason = value.distance.reason; return value; }
        if (self.requiredInchTenths > (self.direction == 'vertical' ? value.distance.highInchTenths : value.distance.broadInchTenths))
        { value.reason = 'jump-launch-range'; return value; }
        if (self.positionPlan == nil && self.fighter.profile.jumpPositionRequired())
        { value.reason = 'jump-position-plan-required'; return value; }
        if (self.positionPlan != nil)
        {
            if (!self.positionPlan.ofKind(RpgExpandedJumpPositionPlan)) rpgExpandedReject('jump-position-plan-definition');
            if (self.fighter.profile.enhancedJumpLevels() > 0)
            {
                local maximum = self.jumping.maximumAssessment();
                if (maximum.status != 'ready') { value.reason = maximum.reason; return value; }
                local travel = rpgExpandedAssessJumpTravel(self.fighter.profile.move(),maximum.broadInchTenths,self.requiredInchTenths);
                if (travel.status != 'ready') { value.reason = travel.reason; return value; }
                if (travel.seconds > 1) { value.reason = 'jump-multiturn-travel-required'; return value; }
            }
            local position = self.positionPlan.assessFor(self.fighter.profile,self.occurrence,self.direction,self.requiredInchTenths);
            if (position.status != 'ready') { value.reason = position.status == 'reused' ? 'jump-position-plan-used' : position.reason; return value; }
        }
        if (self.difficult || self.direction == 'vertical')
        {
            local context = new RpgLiteContext(); context.attribute = rpgDX; context.kind = 'jumping';
            context.requiresMovement = true; context.modifier = self.penalty;
            value.score = rpgLiteScore(self.fighter.profile,context);
            if (self.jumping.skill != nil)
            {
                context.skill = self.jumping.skill; local trained = rpgLiteScore(self.fighter.profile,context);
                if (trained != nil && (value.score == nil || trained > value.score)) value.score = trained;
            }
            if (value.score == nil || value.score < 3) { value.reason = 'jump-launch-score'; return value; }
            rpgInteger(value.score,3,1000);
            if (self.fallPlan == nil || !self.fallPlan.ofKind(RpgExpandedJumpFallPlan))
            { value.reason = 'jump-launch-fall-plan-required'; return value; }
            rpgInteger(self.fallYards,0,112); value.fallVelocity = rpgExpandedFallVelocity(self.fallYards);
            local fallAssessment = self.fallPlan.assessFor(self.fighter.profile,self.occurrence,value.fallVelocity);
            if (fallAssessment.status != 'ready') { value.reason = fallAssessment.reason; return value; }
        }
        value.status = 'ready'; return value;
    }
    commit(value)
    {
        if (self.result != nil) rpgExpandedReject('jump-launch-already-committed');
        if (value == nil || !value.ofKind(RpgExpandedJumpLaunchResult) || value.launch != self || value.status != 'ready'
            || self.battle.current() != self.fighter || self.fighter.maneuver != 'move')
            rpgExpandedReject('jump-launch-commit');
        local current = self.definition();
        for (local index = 1; index <= current.length(); index += 1)
            if (current[index] != value.definition[index]) rpgExpandedReject('jump-launch-changed');
        if (value.score != nil) value.check = rpgCheck(value.score,rpgRandom.roll());
        value.succeeded = value.check == nil || value.check.achieved;
        value.fallRequired = value.check != nil && value.check.critical == 'failure';
        if (!value.succeeded)
        { self.fighter.profile.posture = 'lying'; self.fighter.profile.onKnockdown(); }
        if (value.fallRequired)
        {
            value.fallOutcome = self.fallPlan.applyFor(self.fighter.profile,self.occurrence,value.fallVelocity);
            if (value.fallOutcome.status != 'resolved') rpgExpandedReject('jump-fall-unresolved');
        }
        if (self.positionPlan != nil)
            value.positionOutcome = self.positionPlan.applyFor(self.fighter.profile,self.occurrence,self.direction,
                self.requiredInchTenths,value.succeeded);
        self.boundDefinition = value.definition; self.result = value;
        self.fighter.profile.jumpLaunches = self.fighter.profile.jumpLaunches + [self];
        value.status = 'resolved'; return value;
    }
;

class RpgExpandedForageResult: RpgExpandedResult
    meals = 0
    poisonScope = nil
    group = nil
    score = nil
;
/** B427 one supplied forage roll; hunting includes its printed -4 here. */
rpgExpandedAssessForage(method, score, roll)
{
    if (!holds(['plants','hunting','fishing'],method)) rpgExpandedReject('forage-method');
    rpgInteger(score,-1000,1000); rpgInteger(roll,3,18);
    local value = new RpgExpandedForageResult();
    value.group = method == 'plants' ? 'plants' : 'animal-food';
    value.modifier = method == 'hunting' ? -4 : 0; value.score = score + value.modifier;
    if (value.score < 3) { value.reason = 'forage-score'; return value; }
    value.check = method == 'hunting' ? rpgExpandedCombatCheck('ranged',value.score,roll) : rpgCheck(value.score,roll);
    if (method == 'plants' && (roll == 17 || roll == 18))
        value.poisonScope = roll == 17 ? 'forager' : 'party';
    else if (value.check.achieved) value.meals = method == 'plants' ? 1 : 2;
    value.status = 'ready'; return value;
}

/** Author owns resource availability and scarcity, including cumulative local depletion. */
class RpgExpandedForageSite: object
    id = nil
    plantsAvailable = nil
    gameAvailable = nil
    waterAvailable = nil
    scarcityPenalty = 0
    repeatedUsePenalty = 0
    evidence = nil
    assess(method,score,roll)
    {
        if (self.id == nil || self.id == '' || self.evidence == nil || self.evidence == '')
            rpgExpandedReject('forage-site-facts');
        if (!holds(['plants','hunting','fishing'],method)) rpgExpandedReject('forage-method');
        rpgInteger(self.scarcityPenalty,-1000,0); rpgInteger(self.repeatedUsePenalty,-1000,0);
        rpgInteger(score,-1000,1000); rpgInteger(roll,3,18);
        if (!(method == 'plants' ? self.plantsAvailable : method == 'hunting' ? self.gameAvailable : self.waterAvailable))
        { local value = new RpgExpandedForageResult(); value.reason = 'forage-resources-unavailable'; return value; }
        local adjusted = score + self.scarcityPenalty + self.repeatedUsePenalty;
        if (adjusted < -1000)
        { local value = new RpgExpandedForageResult(); value.reason = 'forage-score-range'; return value; }
        return rpgExpandedAssessForage(method,adjusted,roll);
    }
;

class RpgExpandedTravelForageResult: RpgExpandedResult
    resourceState = nil
    day = 0
    score = nil
    gate = nil
    allowed = nil
    forage = nil
    siteFacts = []
;
class RpgExpandedPlantForageResult: RpgExpandedTravelForageResult;
modify RpgExpandedProfile
    plantForageAttempts = []
;
/** Shared owned travel-day roll; concrete adapters select the attempt category. */
class RpgExpandedTravelForageAttempt: RpgExpandedForageYieldReceipt
    id = nil
    profile = nil
    site = nil
    skill = nil
    modifier = 0
    approved = nil
    evidence = nil
    result = nil
    boundDefinition = nil
    newResult() { return new RpgExpandedTravelForageResult(); }
    forageMethod() { return 'plants'; }
    reason(suffix) { return 'plant-forage-' + suffix; }
    history() { return self.profile.plantForageAttempts; }
    remember() { self.profile.plantForageAttempts = self.history() + [self]; }
    extraDefinition() { return self.skill.foragingDefinition(); }
    foodKind() { return self.forageMethod() == 'plants' ? 'plants' : self.forageMethod() == 'fishing' ? 'fish' : 'meat'; }
    availableYield()
    {
        if (self.result == nil || self.result.forage == nil)
        { local value = new RpgExpandedResult(); value.reason = 'forage-yield-unresolved'; return value; }
        self.assess(); return self.result.forage;
    }
    captureResources() { return nil; }
    commitResources(value) { return nil; }
    skillReason()
    {
        local naturalist = self.skill.id == 'naturalist';
        if ((!naturalist && self.skill.id != 'survival') || self.skill.attribute != (naturalist ? rpgIQ : rpgPerception)
            || self.skill.difficulty != (naturalist ? 2 : 1) || self.skill.defaultPenalty != (naturalist ? -6 : -5)
            || self.skill.specialty == nil || self.skill.specialty == '') rpgExpandedReject(self.reason('skill-definition'));
        foreach (local training in self.profile.skills)
            if (training.skill == self.skill && training.points > 0) return nil;
        return self.skill.expandedForageDefaultsReady() ? nil : self.reason('default-adapter-required');
    }
    definition()
    { return [self.id,self.profile,self.site,self.skill,self.skill.id,self.skill.attribute,
        self.skill.difficulty,self.skill.defaultPenalty,self.skill.specialty,self.skill.techLevel,self.modifier,self.approved,self.evidence] + self.extraDefinition(); }
    siteFacts()
    { return [self.site.id,self.site.plantsAvailable,self.site.waterAvailable,self.site.gameAvailable,self.site.scarcityPenalty,self.site.repeatedUsePenalty,self.site.evidence]; }
    context()
    {
        local context = new RpgLiteContext(); context.skill = self.skill; context.kind = 'foraging';
        context.requiresMovement = true; context.modifier = self.modifier; return context;
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)
            || self.site == nil || !self.site.ofKind(RpgExpandedForageSite)
            || self.skill == nil || !self.skill.ofKind(RpgLiteSkill)) rpgExpandedReject(self.reason('definition'));
        local value = self.newResult(); local definition = self.definition();
        if (self.result != nil)
        {
            if (definition.length() != self.boundDefinition.length()) rpgExpandedReject(self.reason('binding'));
            for (local index = 1; index <= definition.length(); index += 1)
                if (definition[index] != self.boundDefinition[index]) rpgExpandedReject(self.reason('binding'));
            if (!holds(self.history(),self) || self.result.gate.assess().status != 'reused')
                rpgExpandedReject(self.reason('history'));
            value.status = 'reused'; return value;
        }
        value.day = rpgLedger.seconds / 86400;
        local attempts = 0;
        foreach (local prior in self.history())
        {
            if (prior.id == self.id) rpgExpandedReject(self.reason('duplicate'));
            if (prior.result.day == value.day && prior.result.forage != nil) attempts += 1;
        }
        if (attempts >= self.profile.foragingAttemptLimit(value.day))
        { value.reason = self.reason('daily-limit'); return value; }
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = self.reason('travel-facts'); return value; }
        local skillReason = self.skillReason();
        if (skillReason != nil) { value.reason = skillReason; return value; }
        rpgInteger(self.modifier,-1000,1000); value.score = rpgLiteScore(self.profile,self.context());
        if (value.score == nil) { value.reason = self.reason('score-unavailable'); return value; }
        local preview = self.site.assess(self.forageMethod(),value.score,3);
        if (preview.status != 'ready') { value.reason = preview.reason; return value; }
        value.resourceState = self.captureResources();
        value.siteFacts = self.siteFacts(); value.gate = self.profile.prepareForageGate(self.forageMethod() + '-' + self.id,self.evidence);
        if (value.gate == nil) { value.reason = self.reason('health-adapter-required'); return value; }
        local permission = value.gate.assess();
        if (permission.status != 'ready') { value.reason = permission.reason; return value; }
        value.status = 'ready'; return value;
    }
    resolve()
    {
        local value = self.assess(); if (value.status == 'reused') return self.result;
        if (value.status != 'ready') return value;
        local definition = self.definition(); local permission = value.gate.apply();
        if (permission.status != 'resolved') rpgExpandedReject(self.reason('permission-changed'));
        value.allowed = permission.allowed;
        if (value.allowed)
        {
            local facts = self.siteFacts();
            for (local index = 1; index <= facts.length(); index += 1)
                if (facts[index] != value.siteFacts[index]) rpgExpandedReject(self.reason('site-changed'));
            if (rpgLedger.seconds / 86400 != value.day || rpgLiteScore(self.profile,self.context()) != value.score)
                rpgExpandedReject(self.reason('context-changed'));
            value.forage = self.site.assess(self.forageMethod(),value.score,rpgRandom.roll());
            if (value.forage.status != 'ready') rpgExpandedReject(self.reason('outcome-changed'));
            self.commitResources(value);
        }
        local current = self.definition();
        if (current.length() != definition.length()) rpgExpandedReject(self.reason('changed'));
        for (local index = 1; index <= current.length(); index += 1)
            if (current[index] != definition[index]) rpgExpandedReject(self.reason('changed'));
        self.boundDefinition = definition; self.result = value;
        self.remember();
        value.status = 'resolved'; return value;
    }
;

/** B427 plant category, preserving the original public interface. */
class RpgExpandedPlantForageAttempt: RpgExpandedTravelForageAttempt
    newResult() { return new RpgExpandedPlantForageResult(); }
;

modify RpgExpandedProfile
    animalFoodForageAttempts = []
;
/** B195/B427 fishing uses the animal-food allowance and explicit available tools. */
class RpgExpandedFishingForageAttempt: RpgExpandedTravelForageAttempt
    tools = nil
    forageMethod() { return 'fishing'; }
    reason(suffix) { return 'fishing-forage-' + suffix; }
    history() { return self.profile.animalFoodForageAttempts; }
    remember() { self.profile.animalFoodForageAttempts = self.history() + [self]; }
    extraDefinition()
    {
        if (self.tools == nil || !self.tools.ofKind(RpgExpandedForageTools))
            rpgExpandedReject('fishing-forage-tools-definition');
        return [self.tools] + self.tools.definition();
    }
    skillReason()
    {
        if (self.skill.id != 'fishing' || self.skill.attribute != rpgPerception
            || self.skill.difficulty != 0 || self.skill.defaultPenalty != -4 || self.skill.techLevel != nil)
            rpgExpandedReject('fishing-forage-skill-definition');
        local tools = self.tools.assessForProfile(self.profile,self.skill);
        return tools.status == 'ready' ? nil : tools.reason;
    }
    context()
    { local context = inherited(); return self.tools.configure(context); }
;

/** B427 abstract hunt: ammunition expenditure is an explicit author fact, not a rule-derived shot count. */
class RpgExpandedHuntingForageAttempt: RpgExpandedTravelForageAttempt
    weapon = nil
    mode = nil
    hands = 2
    ammunitionUsed = nil
    ammunitionEvidence = nil
    ordinaryHunt = nil
    forageMethod() { return 'hunting'; }
    reason(suffix) { return 'hunting-forage-' + suffix; }
    history() { return self.profile.animalFoodForageAttempts; }
    remember() { self.profile.animalFoodForageAttempts = self.history() + [self]; }
    extraDefinition()
    {
        if (self.weapon == nil || !self.weapon.ofKind(RpgLiteWeapon)
            || self.mode == nil || !self.mode.ofKind(RpgLiteAttackMode)) rpgExpandedReject('hunting-forage-weapon-definition');
        return [self.weapon,self.mode,self.weapon.id,self.weapon.techLevel,self.mode.skillId,self.mode.specialty,
            self.mode.ranged,self.mode.thrown,self.mode.hands,self.mode.minimumST,self.hands,
            self.ammunitionUsed,self.ammunitionEvidence,self.ordinaryHunt];
    }
    skillReason()
    {
        if (!self.ordinaryHunt || self.ammunitionEvidence == nil || self.ammunitionEvidence == '')
            return 'hunting-forage-ammunition-facts';
        rpgInteger(self.ammunitionUsed,1,1000); rpgInteger(self.hands,1,2);
        if (!holds(self.weapon.modes,self.mode) || !self.mode.ranged) return 'hunting-forage-missile-mode-required';
        if (self.mode.thrown) return 'hunting-forage-thrown-adapter-required';
        if (!holds(self.profile.equipment,self.weapon) || self.weapon.quantity != 1 || !self.weapon.ready
            || !self.weapon.attackUsableBy(self.profile)) return 'hunting-forage-weapon-unavailable';
        rpgInteger(self.mode.hands,1,2); rpgInteger(self.mode.minimumST,0,1000);
        if (self.weapon.attackHandCount(self.profile,self.hands) < self.mode.hands)
            return 'hunting-forage-hands-unavailable';
        local technological = holds(['guns','gunner','beam-weapons'],self.mode.skillId);
        if (self.skill.id != self.mode.skillId || self.skill.specialty != self.mode.specialty
            || self.skill.attribute != rpgDX || self.skill.techLevel != (technological ? self.weapon.techLevel : nil))
            rpgExpandedReject('hunting-forage-skill-definition');
        if (self.weapon.ammunition < self.ammunitionUsed) return 'hunting-forage-ammunition-unavailable';
        return nil;
    }
    context()
    {
        local context = inherited(); context.kind = 'attack';
        local strength = self.profile.fp() * 3 < self.profile.maxEnergy ? (self.profile.st + 1) / 2 : self.profile.st;
        if (strength < self.mode.minimumST) context.modifier -= self.mode.minimumST - strength;
        return context;
    }
    captureResources() { return self.weapon.ammunition; }
    commitResources(value)
    {
        local reason = self.skillReason();
        if (reason != nil || self.weapon.ammunition != value.resourceState) rpgExpandedReject('hunting-forage-resources-changed');
        self.weapon.ammunition -= self.ammunitionUsed;
    }
;

modify RpgExpandedProfile
    foragingDayConflict(day)
    {
        local reason = inherited(day); if (reason != nil) return reason;
        foreach (local attempt in self.plantForageAttempts + self.animalFoodForageAttempts)
            if (attempt.result.day == day) return 'foraging-day-activity-started';
        foreach (local attempt in self.hikingAttempts)
            if (attempt.result.day == day) return 'foraging-day-travel-started';
        return nil;
    }
;

/** B34 world facts stay authored; remembered travel has an owned journey receipt. */
class RpgExpandedOrientationResult: RpgExpandedResult
    north = nil
    path = []
;
rpgExpandedOrientationAvailable(profile)
{
    if (profile == nil || !profile.ofKind(RpgExpandedProfile)) rpgExpandedReject('orientation-profile');
    local level = profile.effectiveOrientationSenseLevel();
    if (level == 0) return 'orientation-trait-required';
    if (!holds(['local','deep-space','cross-dimensional'],profile.orientationEnvironment)) return 'orientation-environment-required';
    if (profile.orientationEnvironment == 'cross-dimensional' || level == 1 && profile.orientationEnvironment == 'deep-space')
        return 'orientation-environment-unavailable';
    return nil;
}
class RpgExpandedNorthAssessment: object
    profile = nil
    northDirection = nil
    approved = nil
    evidence = nil
    assess()
    {
        local value = new RpgExpandedOrientationResult(); value.reason = rpgExpandedOrientationAvailable(self.profile);
        if (value.reason != nil) return value;
        if (!self.approved || self.evidence == nil || self.evidence == '' || self.northDirection == nil)
        { value.reason = 'orientation-north-world-facts'; return value; }
        value.north = self.northDirection; value.status = 'ready'; return value;
    }
;
modify RpgExpandedProfile
    orientationRoutes = []
;
class RpgExpandedOrientationRoute: object
    id = nil
    journey = nil
    waypoints = []
    approved = nil
    evidence = nil
    startedAt = nil
    startElapsed = nil
    abandonedAt = nil
    boundAbandonment = nil
    abandonmentEvidence = nil
    completedAt = nil
    endElapsed = nil
    arrivalEvidence = nil
    boundArrivalEvidence = nil
    boundDefinition = nil
    boundCompletion = nil
    profile() { return self.journey.profile; }
    definition() { return [self.id,self.journey,self.profile(),self.approved,self.evidence,self.startedAt,self.startElapsed] + self.waypoints; }
    validateReceipt()
    {
        if (self.startedAt == nil || !holds(self.profile().orientationRoutes,self)) rpgExpandedReject('orientation-route-owner');
        local current = self.definition();
        if (current.length() != self.boundDefinition.length()) rpgExpandedReject('orientation-route-binding');
        for (local i = 1; i <= current.length(); i += 1)
            if (current[i] != self.boundDefinition[i]) rpgExpandedReject('orientation-route-binding');
        if (self.completedAt != nil && (self.boundCompletion == nil || self.completedAt != self.boundCompletion[1]
            || self.endElapsed != self.boundCompletion[2] || self.arrivalEvidence != self.boundArrivalEvidence))
            rpgExpandedReject('orientation-route-completion-binding');
        if (self.abandonedAt != nil && (self.boundAbandonment == nil || self.abandonedAt != self.boundAbandonment[1]
            || self.abandonmentEvidence != self.boundAbandonment[2])) rpgExpandedReject('orientation-route-abandonment-binding');
        if (self.abandonedAt == nil && self.boundAbandonment != nil) rpgExpandedReject('orientation-route-abandonment-binding');
        if (self.completedAt == nil && self.boundCompletion != nil) rpgExpandedReject('orientation-route-completion-binding');
        return nil;
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.journey == nil || !self.journey.ofKind(RpgLiteJourney)
            || self.profile() == nil || !self.profile().ofKind(RpgExpandedProfile)) rpgExpandedReject('orientation-route-definition');
        local value = new RpgExpandedResult();
        if (self.startedAt != nil) { self.validateReceipt(); value.status = 'reused'; return value; }
        if (!self.approved || self.evidence == nil || self.evidence == '' || self.waypoints.length() < 2)
        { value.reason = 'orientation-route-world-facts'; return value; }
        foreach (local point in self.waypoints) if (point == nil) rpgExpandedReject('orientation-route-waypoint');
        foreach (local prior in self.profile().orientationRoutes)
        {
            prior.validateReceipt();
            if (prior.id == self.id || prior.completedAt == nil && prior.abandonedAt == nil) rpgExpandedReject('orientation-route-overlap');
        }
        rpgInteger(self.journey.elapsed,0,2147483647); value.status = 'ready'; return value;
    }
    begin()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.startedAt = rpgLedger.seconds; self.startElapsed = self.journey.elapsed; self.boundDefinition = self.definition();
        self.profile().orientationRoutes = self.profile().orientationRoutes + [self]; value.status = 'resolved'; return value;
    }
    complete(arrived,evidence)
    {
        self.validateReceipt(); local value = new RpgExpandedResult();
        if (self.completedAt != nil) { value.status = 'reused'; return value; }
        if (self.abandonedAt != nil) { value.reason = 'orientation-route-abandoned'; return value; }
        if (!arrived || evidence == nil || evidence == '') { value.reason = 'orientation-route-arrival-facts'; return value; }
        local elapsed = self.journey.elapsed - self.startElapsed;
        if (elapsed <= 0 || rpgLedger.seconds-self.startedAt < elapsed || self.journey.fallen)
        { value.reason = 'orientation-route-travel-required'; return value; }
        self.completedAt = rpgLedger.seconds; self.endElapsed = self.journey.elapsed;
        self.arrivalEvidence = evidence; self.boundArrivalEvidence = evidence;
        self.boundCompletion = [self.completedAt,self.endElapsed]; value.status = 'resolved'; return value;
    }
    abandon(evidence)
    {
        self.validateReceipt(); local value = new RpgExpandedResult();
        if (self.abandonedAt != nil) { value.status = 'reused'; return value; }
        if (self.completedAt != nil) { value.reason = 'orientation-route-already-complete'; return value; }
        if (evidence == nil || evidence == '') { value.reason = 'orientation-route-abandonment-evidence'; return value; }
        self.abandonedAt = rpgLedger.seconds; self.abandonmentEvidence = evidence;
        self.boundAbandonment = [self.abandonedAt,evidence]; value.status = 'resolved'; return value;
    }
    retrace(profile,monthCutoffAt,calendarEvidence,currentWaypoint,positionConfirmed)
    {
        self.validateReceipt(); local value = new RpgExpandedOrientationResult();
        value.reason = rpgExpandedOrientationAvailable(profile); if (value.reason != nil) return value;
        if (profile != self.profile()) rpgExpandedReject('orientation-route-wrong-traveler');
        rpgInteger(monthCutoffAt,0,rpgLedger.seconds);
        if (calendarEvidence == nil || calendarEvidence == '') { value.reason = 'orientation-calendar-required'; return value; }
        if (self.abandonedAt != nil) { value.reason = 'orientation-route-abandoned'; return value; }
        if (self.completedAt == nil) { value.reason = 'orientation-route-unfinished'; return value; }
        if (self.startedAt < monthCutoffAt) { value.reason = 'orientation-route-too-old'; return value; }
        if (!positionConfirmed || currentWaypoint != self.waypoints[self.waypoints.length()])
        { value.reason = 'orientation-route-position'; return value; }
        for (local i = self.waypoints.length(); i >= 1; i -= 1) value.path = value.path + [self.waypoints[i]];
        value.status = 'ready'; return value;
    }
;

modify RpgExpandedProfile
    boatEntries = []
;
/** B180-B181 failed defaulted entry begins involuntary water entry, B354. */
class RpgExpandedBoatEntry: object
    id = nil
    profile = nil
    context = nil
    swimming = nil
    approved = nil
    evidence = nil
    result = nil
    boundDefinition = nil
    definition()
    { return [self.id,self.profile,self.context,self.swimming,self.approved,self.evidence] + self.context.boatEntryDefinition(); }
    assess()
    {
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)
            || self.context == nil || !self.context.ofKind(RpgLiteContext)) rpgExpandedReject('boat-entry-definition');
        local facts = self.definition(); local value = new RpgExpandedBoatEntryAssessment();
        if (self.result != nil)
        {
            if (facts.length() != self.boundDefinition.length()) rpgExpandedReject('boat-entry-binding');
            for (local i = 1; i <= facts.length(); i += 1)
                if (facts[i] != self.boundDefinition[i]) rpgExpandedReject('boat-entry-binding');
            if (!holds(self.profile.boatEntries,self)) rpgExpandedReject('boat-entry-history');
            if (self.result.fellInWater) self.swimming.validateBinding();
            value.status = 'reused'; return value;
        }
        rpgExpandedValidate(self.profile);
        if (!self.approved || self.evidence == nil || self.evidence == '') { value.reason = 'boat-entry-evidence'; return value; }
        if (self.profile.dead || self.profile.unconscious || self.profile.swimmingEncounter != nil)
        { value.reason = 'boat-entry-unavailable'; return value; }
        foreach (local prior in self.profile.boatEntries)
            if (prior.id == self.id) rpgExpandedReject('boat-entry-duplicate');
        value = self.context.assessBoatEntry(self.profile); if (value.status != 'ready') return value;
        if (value.checkRequired)
        {
            if (self.swimming == nil || !self.swimming.ofKind(RpgExpandedSwimmingEncounter)
                || self.swimming.profile != self.profile || self.swimming.intentionalEntry || self.swimming.startedAt != nil)
                rpgExpandedReject('boat-entry-water-definition');
            if (self.swimming.assessStart().status != 'ready')
            { value.status = 'blocked'; value.reason = 'boat-entry-water-unavailable'; return value; }
        }
        return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        if (value.checkRequired) value.check = rpgLiteCheck(self.profile,self.context);
        value.fellInWater = value.checkRequired && !value.check.achieved;
        value.boarded = !value.fellInWater;
        if (value.fellInWater && self.swimming.start().status != 'resolved') rpgExpandedReject('boat-entry-water-changed');
        self.boundDefinition = self.definition(); self.profile.boatEntries = self.profile.boatEntries + [self];
        self.result = value; value.status = 'resolved'; return value;
    }
;


modify RpgExpandedSwimmingEncounter
    exhaustedAt = nil
    exhaustedOnEntry = nil
    lastWillAt = nil
    willChecks = []
    validateWillHistory()
    {
        if (self.exhaustedAt == nil)
        {
            if (self.lastWillAt != nil || self.willChecks.length() != 0 || self.exhaustedOnEntry)
                rpgExpandedReject('swimming-will-history');
            return nil;
        }
        if (self.exhaustedAt < self.startedAt || self.exhaustedAt > rpgLedger.seconds
            || self.exhaustedOnEntry && self.exhaustedAt != self.startedAt)
            rpgExpandedReject('swimming-exhaustion-time');
        local previous = self.exhaustedAt - (self.exhaustedOnEntry ? 1 : 0);
        local ids = []; local failed = nil;
        foreach (local check in self.willChecks)
        {
            if (check == nil || !check.ofKind(RpgExpandedSwimConsciousness) || check.encounter != self
                || check.boundEncounter != self || check.id != check.boundId || holds(ids,check.id)
                || check.result == nil || check.result.check == nil || failed
                || check.completedAt != check.boundCompletedAt || check.completedAt != previous + 1
                || check.completedAt > rpgLedger.seconds || check.result.check.achieved != check.boundSucceeded)
                rpgExpandedReject('swimming-will-history');
            ids = ids + [check.id]; previous = check.completedAt; failed = !check.boundSucceeded;
        }
        if (self.lastWillAt != previous) rpgExpandedReject('swimming-will-schedule');
        return nil;
    }
    recordExhaustion()
    {
        if (self.profile.fp() <= 0 && self.exhaustedAt == nil)
        { self.exhaustedAt = rpgLedger.seconds; self.lastWillAt = self.exhaustedAt; }
        return nil;
    }
;
/** B354/B437 consciousness checks do not impose complete-airlessness fatigue. */
class RpgExpandedSwimConsciousness: object
    id = nil
    encounter = nil
    result = nil
    completedAt = nil
    boundId = nil
    boundCompletedAt = nil
    boundSucceeded = nil
    boundEncounter = nil
    assess()
    {
        local value = new RpgExpandedResult();
        if (self.id == nil || self.id == '' || self.encounter == nil || !self.encounter.ofKind(RpgExpandedSwimmingEncounter))
            rpgExpandedReject('swimming-will-definition');
        self.encounter.validateBinding(); self.encounter.validateWillHistory();
        if (self.result != nil)
        {
            if (self.id != self.boundId || self.encounter != self.boundEncounter || !holds(self.encounter.willChecks,self))
                rpgExpandedReject('swimming-will-binding');
            value.status = 'reused'; value.check = self.result.check; return value;
        }
        local p = self.encounter.profile;
        if (self.encounter.endedAt != nil || p.swimmingEncounter != self.encounter || p.dead || p.unconscious
            || p.fp() > 0 || self.encounter.exhaustedAt == nil)
        { value.reason = 'swimming-will-not-active'; return value; }
        if (rpgLedger.seconds != self.encounter.lastWillAt + 1)
        { value.reason = 'swimming-will-not-due'; return value; }
        foreach (local prior in self.encounter.willChecks)
            if (prior.id == self.id) rpgExpandedReject('swimming-will-duplicate');
        local c = new RpgLiteContext(); c.attribute = rpgWill; c.kind = 'air';
        local score = rpgLiteScore(p,c);
        if (score == nil || score < 3) { value.reason = 'swimming-will-score-unavailable'; return value; }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local p = self.encounter.profile;
        value.check = rpgLiteAttributeCheck(p,rpgWill,'air',0);
        if (!value.check.achieved) { p.becomeUnconscious(); p.fatigueCollapse = true; }
        self.boundId = self.id; self.boundEncounter = self.encounter; self.completedAt = rpgLedger.seconds;
        self.boundCompletedAt = self.completedAt; self.boundSucceeded = value.check.achieved;
        self.encounter.lastWillAt = self.completedAt; self.encounter.willChecks = self.encounter.willChecks + [self];
        value.status = 'resolved'; self.result = value; return value;
    }
;
modify rpgLedger
    validateAdvance(seconds)
    {
        inherited(seconds);
        for (local e = firstObj(RpgExpandedSwimmingEncounter); e != nil; e = nextObj(e,RpgExpandedSwimmingEncounter))
            if (e.exhaustedAt != nil && e.endedAt == nil && e.profile.fp() <= 0 && !e.profile.dead && !e.profile.unconscious)
            {
                e.validateBinding(); e.validateWillHistory();
                if (self.seconds + seconds > e.lastWillAt + 1) rpgExpandedReject('swimming-will-boundary');
            }
        return nil;
    }
;


modify RpgExpandedProfile
    validateFeatures()
    {
        inherited();
        foreach (local encounter in self.swimmingHistory) encounter.validateWillHistory();
        return nil;
    }
;

class RpgExpandedBreathPreparation: object
    id = nil
    profile = nil
    controlSkill = nil
    approved = nil
    evidence = nil
    combat = nil
    completedAt = nil
    boundCompletedAt = nil
    boundSucceeded = nil
    boundDefinition = nil
    result = nil
    usedBy = nil
    definition() { return [self.id,self.profile,self.controlSkill,self.approved,self.evidence,self.combat]; }
    validateReceipt()
    {
        if (self.result == nil || self.completedAt == nil || self.completedAt != self.boundCompletedAt || self.completedAt > rpgLedger.seconds
            || !holds(self.profile.breathPreparations,self)) rpgExpandedReject('breath-preparation-history');
        if ((self.result.check != nil && self.result.check.achieved) != self.boundSucceeded)
            rpgExpandedReject('breath-preparation-result-binding');
        local facts = self.definition();
        for (local i = 1; i <= facts.length(); i += 1)
            if (facts[i] != self.boundDefinition[i]) rpgExpandedReject('breath-preparation-binding');
        return nil;
    }
    assess()
    {
        local value = new RpgExpandedResult();
        if (self.result != nil) { self.validateReceipt(); value.status = 'reused'; return value; }
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile))
            rpgExpandedReject('breath-preparation-definition');
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'breath-preparation-air-required'; return value; }
        if (self.combat) { value.reason = 'breath-preparation-combat-adapter-required'; return value; }
        if (self.profile.dead || self.profile.unconscious || self.profile.stunned || self.profile.mentalStun
            || self.profile.fp() <= 0) { value.reason = 'breath-preparation-incapacitated'; return value; }
        if (self.profile.breathReserve != nil || self.profile.airClock != 0)
        { value.reason = 'breath-existing-exposure'; return value; }
        self.profile.validateBreathStart();
        foreach (local prior in self.profile.breathPreparations)
            if (prior.id == self.id) rpgExpandedReject('breath-preparation-duplicate');
        if (self.controlSkill != nil)
        {
            if (!self.controlSkill.ofKind(RpgLiteSkill)) rpgExpandedReject('breath-control-skill-definition');
            self.controlSkill.validateBreathControl();
            local trained = nil;
            foreach (local training in self.profile.skills)
                if (training.skill == self.controlSkill && training.points > 0) trained = true;
            if (!trained) { value.reason = 'breath-control-training-required'; return value; }
            local context = new RpgLiteContext(); context.skill = self.controlSkill; context.kind = 'breath-control';
            local score = rpgLiteScore(self.profile,context);
            if (score == nil || score < 3) { value.reason = 'breath-control-score-unavailable'; return value; }
        }
        rpgLedger.validateAdvance(1);
        value.seconds = 1; value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        rpgSpendTime(1);
        if (self.controlSkill != nil)
        {
            local context = new RpgLiteContext(); context.skill = self.controlSkill; context.kind = 'breath-control';
            value.check = rpgLiteCheck(self.profile,context);
        }
        self.completedAt = rpgLedger.seconds; self.boundCompletedAt = self.completedAt;
        self.boundSucceeded = value.check != nil && value.check.achieved; self.boundDefinition = self.definition();
        value.status = 'resolved'; self.result = value;
        self.profile.breathPreparations = self.profile.breathPreparations + [self]; return value;
    }
;
modify RpgExpandedProfile
    breathPreparations = []
    validateFeatures()
    {
        inherited(); local ids = [];
        foreach (local preparation in self.breathPreparations)
        {
            if (preparation == nil || !preparation.ofKind(RpgExpandedBreathPreparation)
                || preparation.profile != self || holds(ids,preparation.id)) rpgExpandedReject('breath-preparation-history');
            preparation.validateReceipt(); ids = ids + [preparation.id];
            if (preparation.usedBy != nil && (!holds(self.breathHistory,preparation.usedBy)
                || preparation.usedBy.preparation != preparation)) rpgExpandedReject('breath-preparation-reserve-binding');
        }
        return nil;
    }
;

class RpgExpandedBreathingRecoveryResult: RpgExpandedResult
    rest = nil
    recovered = 0
;

/** B182 two minutes of quiet breathing, sharing the ordinary recovery ledger. */
class RpgExpandedBreathingRecovery: object
    id = nil
    profile = nil
    skill = nil
    approved = nil
    evidence = nil
    restorativeMagic = nil
    completedAt = nil
    startedAt = nil
    boundStartedAt = nil
    boundCompletedAt = nil
    boundRecovered = nil
    boundSucceeded = nil
    boundDefinition = nil
    result = nil
    definition() { return [self.id,self.profile,self.skill,self.approved,self.evidence,self.restorativeMagic]; }
    validateReceipt()
    {
        if (self.result == nil || self.boundDefinition == nil || self.startedAt == nil
            || self.startedAt != self.boundStartedAt || self.completedAt != self.boundCompletedAt
            || self.completedAt != self.startedAt + 120 || self.completedAt > rpgLedger.seconds
            || !holds(self.profile.breathingRecoveries,self)) rpgExpandedReject('breathing-recovery-history');
        local facts = self.definition();
        for (local i = 1; i <= facts.length(); i += 1)
            if (facts[i] != self.boundDefinition[i]) rpgExpandedReject('breathing-recovery-binding');
        if (self.result.check == nil || self.result.check.achieved != self.boundSucceeded
            || self.result.recovered != self.boundRecovered || self.result.rest == nil
            || self.result.rest.status != 'resolved' || self.result.rest.seconds != 120)
            rpgExpandedReject('breathing-recovery-result-binding');
        return nil;
    }
    assess()
    {
        local value = new RpgExpandedBreathingRecoveryResult();
        if (self.result != nil)
        {
            self.validateReceipt();
            value.status = 'reused'; return value;
        }
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)
            || self.skill == nil || !self.skill.ofKind(RpgLiteSkill)) rpgExpandedReject('breathing-recovery-definition');
        self.skill.validateBreathControl();
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'breathing-recovery-quiet-rest-required'; return value; }
        if (self.restorativeMagic) { value.reason = 'breathing-recovery-magic-incompatible'; return value; }
        if (self.profile.dead || self.profile.unconscious || self.profile.stunned || self.profile.mentalStun
            || self.profile.mortal) { value.reason = 'breathing-recovery-incapacitated'; return value; }
        local trained = nil;
        foreach (local training in self.profile.skills)
            if (training.skill == self.skill && training.points > 0) trained = true;
        if (!trained) { value.reason = 'breath-control-training-required'; return value; }
        if (self.profile.breathReserve != nil || self.profile.airClock != 0)
        { value.reason = 'breathing-recovery-needs-air'; return value; }
        self.profile.validateBreathStart();
        self.profile.validateNaturalRecovery(120,nil,nil);
        rpgLedger.validateAdvance(120);
        local locked = self.profile.hunger + self.profile.thirst + self.profile.sleepDebt + self.profile.temperatureFatigue
            + self.profile.additionalRecoveryLockedFatigue();
        if (self.profile.fatigue <= locked) { value.reason = 'breathing-recovery-no-ordinary-fatigue'; return value; }
        foreach (local prior in self.profile.breathingRecoveries)
            if (prior.id == self.id) rpgExpandedReject('breathing-recovery-duplicate');
        local context = new RpgLiteContext(); context.skill = self.skill; context.kind = 'breathing-recovery';
        local score = rpgLiteScore(self.profile,context);
        if (score == nil || score < 3) { value.reason = 'breath-control-score-unavailable'; return value; }
        value.seconds = 120; value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local context = new RpgLiteContext(); context.skill = self.skill; context.kind = 'breathing-recovery';
        self.startedAt = rpgLedger.seconds; self.boundStartedAt = self.startedAt;
        value.check = rpgLiteCheck(self.profile,context);
        local before = self.profile.fatigue;
        value.rest = rpgLiteRest(self.profile,120,nil,nil,nil,nil);
        if (value.rest.status != 'resolved') rpgExpandedReject('breathing-recovery-rest-changed');
        if (value.check.achieved)
        {
            local locked = self.profile.hunger + self.profile.thirst + self.profile.sleepDebt + self.profile.temperatureFatigue
                + self.profile.additionalRecoveryLockedFatigue();
            /* The same interval cannot earn both accelerated and ordinary FP. */
            if (self.profile.fatigue == before && self.profile.fatigue > locked) self.profile.fatigue -= 1;
            self.profile.restClock = 0; self.profile.afterFatigueRecovery();
        }
        value.recovered = before - self.profile.fatigue;
        self.completedAt = rpgLedger.seconds; self.boundCompletedAt = self.completedAt;
        self.boundRecovered = value.recovered; self.boundSucceeded = value.check.achieved; self.boundDefinition = self.definition();
        value.status = 'resolved'; self.result = value;
        self.profile.breathingRecoveries = self.profile.breathingRecoveries + [self]; return value;
    }
;
modify RpgExpandedProfile
    breathingRecoveries = []
    validateFeatures()
    {
        inherited(); local ids = []; local until = 0;
        foreach (local recovery in self.breathingRecoveries)
        {
            if (recovery == nil || !recovery.ofKind(RpgExpandedBreathingRecovery) || recovery.profile != self
                || holds(ids,recovery.id) || recovery.startedAt < until) rpgExpandedReject('breathing-recovery-history');
            recovery.validateReceipt(); ids = ids + [recovery.id]; until = recovery.completedAt;
        }
        return nil;
    }
;

/** Full-2008 B211: an authored practical finding, not a resource-producing action. */
class RpgExpandedNatureFinding: RpgExpandedResult
    finding = nil
    score = nil
;
class RpgExpandedNatureObservation: RpgExpandedNatureReceipt
    id = nil
    profile = nil
    skill = nil
    occurrence = nil
    purpose = nil
    planet = nil
    planetType = nil
    accessible = nil
    approved = nil
    evidence = nil
    finding = nil
    modifier = 0
    result = nil
    boundDefinition = nil
    boundFinding = nil
    boundSucceeded = nil
    definition()
    { return [self.id,self.profile,self.skill,self.occurrence,self.purpose,self.planet,self.planetType,self.accessible,self.approved,self.evidence,self.finding,self.modifier]; }
    context()
    { local value = new RpgLiteContext(); value.skill = self.skill; value.kind = 'nature-observation'; value.modifier = self.modifier; return value; }
    validateReceipt()
    {
        if (self.result == nil || self.boundDefinition == nil || !holds(self.profile.natureObservations,self))
            rpgExpandedReject('nature-observation-history');
        local facts = self.definition();
        for (local i = 1; i <= facts.length(); i += 1)
            if (facts[i] != self.boundDefinition[i]) rpgExpandedReject('nature-observation-binding');
        if (self.result.check == nil || self.result.check.achieved != self.boundSucceeded || self.result.finding != self.boundFinding) rpgExpandedReject('nature-observation-result-binding');
        return nil;
    }
    assess()
    {
        local value = new RpgExpandedNatureFinding();
        if (self.result != nil)
        { self.validateReceipt(); value.status = 'reused'; value.finding = self.result.finding; value.check = self.result.check; return value; }
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)
            || self.skill == nil || !self.skill.ofKind(RpgLiteSkill) || self.occurrence == nil
            || self.planet == nil || self.planet == '' || self.planetType == nil || self.planetType == '')
            rpgExpandedReject('nature-observation-definition');
        if (!holds(['plant-safety','animal-safety','shelter','weather'],self.purpose)) rpgExpandedReject('nature-observation-purpose');
        self.skill.validateNatureObservation(self.planet,self.planetType);
        if (!self.approved || self.evidence == nil || self.evidence == '' || self.finding == nil || self.finding == '')
        { value.reason = 'nature-observation-facts-required'; return value; }
        if (!self.accessible) { value.reason = 'nature-observation-inaccessible'; return value; }
        if (self.profile.dead || self.profile.unconscious || self.profile.stunned)
        { value.reason = 'nature-observation-observer-unavailable'; return value; }
        foreach (local prior in self.profile.natureObservations)
            if (prior.id == self.id || prior.occurrence == self.occurrence && prior.purpose == self.purpose)
                rpgExpandedReject('nature-observation-repeat');
        rpgInteger(self.modifier,-100,100); value.score = rpgLiteScore(self.profile,self.context());
        if (value.score == nil || value.score < 3) { value.reason = 'nature-observation-score-unavailable'; return value; }
        value.status = 'ready'; return value;
    }
    resolve()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        value.check = rpgLiteCheck(self.profile,self.context());
        if (value.check.achieved) value.finding = self.finding;
        self.boundDefinition = self.definition(); self.boundFinding = value.finding; self.boundSucceeded = value.check.achieved;
        value.status = 'resolved'; self.result = value;
        self.profile.natureObservations = self.profile.natureObservations + [self]; return value;
    }
;
modify RpgExpandedProfile
    natureObservations = []
    validateFeatures()
    {
        inherited(); local ids = []; local seen = [];
        foreach (local observation in self.natureObservations)
        {
            if (observation == nil || !observation.ofKind(RpgExpandedNatureObservation) || observation.profile != self
                || holds(ids,observation.id)) rpgExpandedReject('nature-observation-history');
            foreach (local prior in seen)
                if (prior.occurrence == observation.occurrence && prior.purpose == observation.purpose)
                    rpgExpandedReject('nature-observation-history');
            observation.validateReceipt(); ids = ids + [observation.id]; seen = seen + [observation];
        }
        return nil;
    }
;

/** Bind authored command/dialogue routes to the same owned observation. */
class RpgExpandedNatureObservationAction: Action
    observation = nil
    perform(actor)
    {
        if (self.observation == nil || !self.observation.ofKind(RpgExpandedNatureObservation))
            rpgExpandedReject('nature-action-definition');
        local value = new RpgExpandedNatureFinding();
        if (actor == nil || !actor.ofKind(Thing) || actor.rpgProfile != self.observation.profile)
            value.reason = 'nature-action-observer-required';
        else value = self.observation.resolve();
        event('rpg.expanded.nature-observation'); eventValue(value.status); eventValue(value.reason);
        return value;
    }
    exec(context) { return self.perform(context.actor); }
;

/** Full-2008 B212: one authored fossil finding per specimen and study task. */
class RpgExpandedPaleontologyResult: RpgExpandedResult
    finding = nil
    score = nil
    familiarityModifier = 0
;
class RpgExpandedPaleontologyAssessment: RpgExpandedPaleontologyReceipt
    id = nil
    profile = nil
    context = nil
    specimen = nil
    finding = nil
    approved = nil
    evidence = nil
    accessible = nil
    result = nil
    boundDefinition = nil
    boundFinding = nil
    boundSucceeded = nil
    boundScore = nil
    boundFamiliarityModifier = nil
    definition()
    { return [self.id,self.profile,self.context,self.specimen,self.finding,self.approved,self.evidence,self.accessible] + self.context.paleontologyFacts(); }
    validateReceipt()
    {
        if (self.result == nil || self.boundDefinition == nil || !holds(self.profile.paleontologyAssessments,self))
            rpgExpandedReject('paleontology-assessment-history');
        local facts = self.definition();
        if (facts.length() != self.boundDefinition.length()) rpgExpandedReject('paleontology-assessment-binding');
        for (local i = 1; i <= facts.length(); i += 1)
            if (facts[i] != self.boundDefinition[i]) rpgExpandedReject('paleontology-assessment-binding');
        if (self.result.score != self.boundScore || self.result.familiarityModifier != self.boundFamiliarityModifier || self.result.finding != self.boundFinding || self.result.check == nil || self.result.check.achieved != self.boundSucceeded)
            rpgExpandedReject('paleontology-assessment-result-binding');
        return nil;
    }
    assess()
    {
        local value = new RpgExpandedPaleontologyResult();
        if (self.result != nil)
        { self.validateReceipt(); value.status = 'reused'; value.check = self.result.check; value.finding = self.result.finding; value.score = self.result.score; value.familiarityModifier = self.result.familiarityModifier; return value; }
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)
            || self.context == nil || !self.context.ofKind(RpgLiteContext) || self.specimen == nil)
            rpgExpandedReject('paleontology-assessment-definition');
        self.context.paleontologyFacts();
        if (!self.approved || self.evidence == nil || self.evidence == '' || self.finding == nil || self.finding == '')
        { value.reason = 'paleontology-assessment-finding-required'; return value; }
        if (!self.accessible) { value.reason = 'paleontology-assessment-inaccessible'; return value; }
        if (self.profile.dead || self.profile.unconscious || self.profile.stunned)
        { value.reason = 'paleontology-assessment-observer-unavailable'; return value; }
        foreach (local prior in self.profile.paleontologyAssessments)
        {
            prior.validateReceipt();
            if (prior.id == self.id || prior.specimen == self.specimen && prior.context.task == self.context.task) rpgExpandedReject('paleontology-assessment-repeat');
        }
        local reason = self.context.taskUnavailableReason(self.profile);
        if (reason != nil) { value.reason = reason; return value; }
        value.familiarityModifier = self.context.paleontologyFamiliarityModifier(self.profile);
        value.score = rpgLiteScore(self.profile,self.context);
        if (value.score == nil || value.score < 3) { value.reason = 'paleontology-assessment-score-unavailable'; return value; }
        value.status = 'ready'; return value;
    }
    resolve()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        value.check = rpgLiteCheck(self.profile,self.context);
        if (value.check.achieved) value.finding = self.finding;
        self.boundScore = value.score; self.boundFamiliarityModifier = value.familiarityModifier;
        self.boundDefinition = self.definition(); self.boundFinding = value.finding; self.boundSucceeded = value.check.achieved;
        self.result = value; value.status = 'resolved'; self.profile.paleontologyAssessments = self.profile.paleontologyAssessments + [self]; return value;
    }
;
modify RpgExpandedProfile
    paleontologyAssessments = []
    validateFeatures()
    {
        inherited(); local seen = [];
        foreach (local assessment in self.paleontologyAssessments)
        {
            if (assessment == nil || !assessment.ofKind(RpgExpandedPaleontologyAssessment) || assessment.profile != self)
                rpgExpandedReject('paleontology-assessment-history');
            foreach (local prior in seen)
                if (prior.id == assessment.id || prior.specimen == assessment.specimen && prior.context.task == assessment.context.task) rpgExpandedReject('paleontology-assessment-history');
            assessment.validateReceipt(); seen = seen + [assessment];
        }
        return nil;
    }
;


class RpgExpandedPackTrainResult: RpgExpandedResult
    speedPercent = nil
    master = nil
;
/** B212: members are [profile, packing skill] pairs participating in this caravan. */
class RpgExpandedPackTrain: object
    members = []
    approved = nil
    evidence = nil
    assess()
    {
        local value = new RpgExpandedPackTrainResult();
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'pack-train-participation-required'; return value; }
        local seen = [];
        foreach (local row in self.members)
        {
            if (row.length() != 2 || row[1] == nil || !row[1].ofKind(RpgExpandedProfile)
                || row[2] == nil || !row[2].ofKind(RpgLiteSkill)) rpgExpandedReject('pack-train-member');
            if (holds(seen,row[1])) rpgExpandedReject('pack-train-duplicate-member');
            seen = seen + [row[1]]; row[2].validatePacking();
            if (row[1].dead || row[1].unconscious || row[1].stunned) continue;
            local score = row[1].skillScore(row[2]);
            if (score != nil && score >= 15 && value.master == nil) value.master = row[1];
        }
        value.speedPercent = value.master == nil ? 80 : 100;
        value.status = 'ready'; return value;
    }
;

/** B212: an owned packing roll after any required handling, with authored load/route facts. */
class RpgExpandedPackingResult: RpgExpandedResult
    score = nil
    finding = nil
;
class RpgExpandedPackingAttempt: RpgExpandedPackingReceipt
    id = nil
    profile = nil
    animal = nil
    skill = nil
    occurrence = nil
    task = 'load'
    finding = nil
    difficult = nil
    handling = nil
    approved = nil
    evidence = nil
    modifier = 0
    result = nil
    boundDefinition = nil
    boundSucceeded = nil
    boundFinding = nil
    definition()
    {
        local facts = [self.id,self.profile,self.animal,self.skill,self.occurrence,self.task,self.difficult,self.handling,
            self.approved,self.evidence,self.modifier,self.finding];
        return self.handling == nil ? facts : facts + rpgExpandedPackingHandling.definition(self.handling);
    }
    context() { local value = new RpgLiteContext(); value.skill = self.skill; value.modifier = self.modifier; return value; }
    validateReceipt()
    {
        if (self.result == nil || self.boundDefinition == nil || !holds(self.profile.packingAttempts,self))
            rpgExpandedReject('packing-history');
        self.skill.validatePacking();
        if (self.handling != nil && rpgExpandedPackingHandling.assess(self.handling,self.profile,self.animal,self.occurrence).status != 'ready')
            rpgExpandedReject('packing-handling-binding');
        local facts = self.definition();
        if (facts.length() != self.boundDefinition.length()) rpgExpandedReject('packing-binding');
        for (local i = 1; i <= facts.length(); i += 1)
            if (facts[i] != self.boundDefinition[i]) rpgExpandedReject('packing-binding');
        if (self.result.finding != self.boundFinding || self.result.check == nil || self.result.check.achieved != self.boundSucceeded) rpgExpandedReject('packing-result-binding');
        return nil;
    }
    assess()
    {
        local value = new RpgExpandedPackingResult();
        if (self.result != nil)
        { self.validateReceipt(); value.status = 'reused'; value.check = self.result.check; value.finding = self.result.finding; return value; }
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)
            || self.animal == nil || !self.animal.ofKind(RpgExpandedProfile) || self.animal == self.profile
            || self.skill == nil || !self.skill.ofKind(RpgLiteSkill) || self.occurrence == nil
            || !holds(['load','unload','evaluate','route'],self.task)) rpgExpandedReject('packing-definition');
        self.skill.validatePacking(); rpgInteger(self.modifier,-100,100);
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'packing-facts-required'; return value; }
        if (holds(['evaluate','route'],self.task))
        {
            if (self.finding == nil || self.finding == '') { value.reason = 'packing-finding-required'; return value; }
        }
        else if (self.finding != nil) rpgExpandedReject('packing-finding-inapplicable');
        foreach (local participant in [self.profile,self.animal])
            if (participant.dead || participant.unconscious || participant.stunned)
            { value.reason = 'packing-participant-unavailable'; return value; }
        foreach (local prior in self.profile.packingAttempts)
        {
            prior.validateReceipt();
            if (prior.id == self.id || prior.animal == self.animal && prior.occurrence == self.occurrence && prior.task == self.task)
                rpgExpandedReject('packing-repeat');
        }
        if (self.difficult && self.handling == nil) { value.reason = 'packing-handling-required'; return value; }
        if (self.handling != nil)
        {
            local handled = rpgExpandedPackingHandling.assess(self.handling,self.profile,self.animal,self.occurrence);
            if (handled.status != 'ready') { value.reason = handled.reason; return value; }
        }
        value.score = rpgLiteScore(self.profile,self.context());
        if (value.score == nil || value.score < 3) { value.reason = 'packing-score-unavailable'; return value; }
        value.status = 'ready'; return value;
    }
    resolve()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        value.check = rpgLiteCheck(self.profile,self.context()); self.boundSucceeded = value.check.achieved;
        if (value.check.achieved) value.finding = self.finding;
        self.boundFinding = value.finding;
        self.boundDefinition = self.definition(); self.result = value; value.status = 'resolved';
        self.profile.packingAttempts = self.profile.packingAttempts + [self]; return value;
    }
;
modify RpgExpandedProfile
    packingAttempts = []
    validateFeatures()
    {
        inherited(); local seen = [];
        foreach (local attempt in self.packingAttempts)
        {
            if (attempt == nil || !attempt.ofKind(RpgExpandedPackingAttempt) || attempt.profile != self) rpgExpandedReject('packing-history');
            foreach (local prior in seen)
                if (prior.id == attempt.id || prior.animal == attempt.animal && prior.occurrence == attempt.occurrence && prior.task == attempt.task)
                    rpgExpandedReject('packing-history');
            attempt.validateReceipt(); seen = seen + [attempt];
        }
        return nil;
    }
;

/** B353: supported back loads above 10 BL lose one FP per elapsed second. */
class RpgExpandedOverloadCarry: object
    id = nil
    profile = nil
    approved = nil
    evidence = nil
    startedAt = nil
    endedAt = nil
    lastProcessedAt = nil
    chargedSeconds = 0
    boundDefinition = nil
    definition() { return [self.id,self.profile,self.approved,self.evidence]; }
    validateReceipt()
    {
        if (self.startedAt == nil || !holds(self.profile.overloadCarries,self) || self.boundDefinition == nil)
            rpgExpandedReject('overload-history');
        local facts = self.definition();
        for (local i = 1; i <= facts.length(); i += 1)
            if (facts[i] != self.boundDefinition[i]) rpgExpandedReject('overload-binding');
        if (self.endedAt == nil && self.profile.overloadCarry != self) rpgExpandedReject('overload-owner');
        rpgInteger(self.startedAt,0,rpgLedger.seconds); rpgInteger(self.chargedSeconds,0,rpgLedger.seconds - self.startedAt);
        rpgInteger(self.lastProcessedAt,self.startedAt,rpgLedger.seconds);
        if (self.endedAt != nil) rpgInteger(self.endedAt,self.startedAt,rpgLedger.seconds);
        return nil;
    }
    assess()
    {
        local value = new RpgExpandedResult();
        if (self.startedAt != nil) { self.validateReceipt(); value.status = 'reused'; return value; }
        if (self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)) rpgExpandedReject('overload-definition');
        return self.assessProjected(self.profile.loadHundredths());
    }
    assessProjected(load)
    {
        local value = new RpgExpandedResult();
        if (self.startedAt != nil) { value.reason = 'overload-already-started'; return value; }
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile))
            rpgExpandedReject('overload-definition');
        if (!self.approved || self.evidence == nil || self.evidence == '') { value.reason = 'overload-support-required'; return value; }
        if (self.profile.overloadCarry != nil) { value.reason = 'overload-already-active'; return value; }
        foreach (local prior in self.profile.overloadCarries)
            if (prior.id == self.id) rpgExpandedReject('overload-duplicate');
        if (self.profile.dead || self.profile.unconscious) { value.reason = 'overload-carrier-unavailable'; return value; }
        local lift = self.profile.basicLiftHundredths();
        rpgInteger(load,0,100000000); rpgInteger(lift,1,100000000);
        if (load <= lift * 10) { value.reason = 'overload-not-required'; return value; }
        if (load > lift * 15) { value.reason = 'overload-capacity'; return value; }
        value.status = 'ready'; return value;
    }
    start()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.boundDefinition = self.definition(); self.startedAt = rpgLedger.seconds; self.lastProcessedAt = self.startedAt;
        self.profile.overloadCarries = self.profile.overloadCarries + [self]; self.profile.overloadCarry = self;
        value.status = 'resolved'; return value;
    }
    charge(previousSeconds)
    {
        self.validateReceipt(); if (self.endedAt != nil || rpgLedger.seconds <= self.lastProcessedAt) return nil;
        if (rpgLedger.seconds != self.lastProcessedAt + 1) rpgExpandedReject('overload-clock-gap');
        self.lastProcessedAt = rpgLedger.seconds;
        if (self.profile.loadHundredths() <= self.profile.basicLiftHundredths() * 10 || self.profile.dead || self.profile.unconscious)
        { self.endedAt = rpgLedger.seconds; self.profile.overloadCarry = nil; return nil; }
        self.profile.restClock = 0; rpgLiteFatigue(self.profile,1,'exertion'); self.chargedSeconds += 1;
        if (self.profile.dead || self.profile.unconscious) { self.endedAt = rpgLedger.seconds; self.profile.overloadCarry = nil; }
        return nil;
    }
;
modify RpgExpandedProfile
    overloadCarry = nil
    overloadCarries = []
    validateFeatures()
    {
        inherited(); local ids = [];
        foreach (local carry in self.overloadCarries)
        {
            if (carry == nil || !carry.ofKind(RpgExpandedOverloadCarry) || carry.profile != self || holds(ids,carry.id))
                rpgExpandedReject('overload-history');
            carry.validateReceipt(); ids = ids + [carry.id];
        }
        if (self.overloadCarry != nil && !holds(self.overloadCarries,self.overloadCarry)) rpgExpandedReject('overload-owner');
        return nil;
    }
;
modify rpgLedger
    validateAdvance(seconds)
    {
        inherited(seconds);
        for (local profile = firstObj(RpgExpandedProfile); profile != nil; profile = nextObj(profile,RpgExpandedProfile))
            if (profile.overloadCarry != nil)
            {
                profile.overloadCarry.validateReceipt();
                if (seconds > 1) rpgExpandedReject('overload-one-second-step-required');
                if (profile.loadHundredths() > profile.basicLiftHundredths() * 15) rpgExpandedReject('overload-capacity');
            }
        return nil;
    }
    afterAdvance(previousSeconds)
    {
        inherited(previousSeconds);
        for (local profile = firstObj(RpgExpandedProfile); profile != nil; profile = nextObj(profile,RpgExpandedProfile))
            if (profile.overloadCarry != nil) profile.overloadCarry.charge(previousSeconds);
        return nil;
    }
;
modify RpgLiteJourney
    advance(seconds)
    {
        if (self.kind == 'overload' && self.profile.ofKind(RpgExpandedProfile) && self.profile.overloadCarry != nil)
            rpgExpandedReject('overload-duplicate-clock');
        return inherited(seconds);
    }
;

modify rpgExpandedPackingOverload
    definition(carry)
    {
        if (carry == nil || !carry.ofKind(RpgExpandedOverloadCarry)) rpgExpandedReject('packing-overload-state');
        return carry.definition();
    }
    assess(carry,profile,load)
    {
        self.definition(carry);
        if (carry.profile != profile) rpgExpandedReject('packing-overload-owner');
        if (carry.startedAt == nil) return carry.assessProjected(load);
        carry.validateReceipt(); local value = new RpgExpandedResult();
        if (carry.endedAt != nil || profile.overloadCarry != carry) { value.reason = 'overload-ended'; return value; }
        if (profile.dead || profile.unconscious) { value.reason = 'overload-carrier-unavailable'; return value; }
        local lift = profile.basicLiftHundredths(); rpgInteger(lift,1,100000000); rpgInteger(load,0,100000000);
        if (load <= lift * 10) { value.reason = 'overload-not-required'; return value; }
        if (load > lift * 15) { value.reason = 'overload-capacity'; return value; }
        value.status = 'ready'; return value;
    }
    start(carry)
    {
        self.definition(carry);
        if (carry.startedAt != nil)
        {
            if (self.assess(carry,carry.profile,carry.profile.loadHundredths()).status != 'ready')
                rpgExpandedReject('packing-overload-interrupted');
            return nil;
        }
        if (carry.start().status != 'resolved') rpgExpandedReject('packing-overload-interrupted');
        return nil;
    }
;

class RpgExpandedTerrainSearchResult: RpgExpandedResult
    direction = nil
    score = nil
    gate = nil
    allowed = nil
;
/** B223/B198 reading terrain identifies a direction; it supplies no water or travel. */
class RpgExpandedTerrainSearch: object
    id = nil
    profile = nil
    context = nil
    observation = nil
    observationApplicable = nil
    observationEvidence = nil
    site = nil
    occurrence = nil
    featureExists = nil
    direction = nil
    seconds = nil
    approved = nil
    evidence = nil
    result = nil
    completedAt = nil
    boundDefinition = nil
    boundOutcome = nil
    definition()
    {
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)
            || self.context == nil || !self.context.ofKind(RpgLiteContext) || self.site == nil || self.occurrence == nil)
            rpgExpandedReject('terrain-search-definition');
        rpgInteger(self.seconds,0,86400);
        if ((self.featureExists && self.direction == nil) || (!self.featureExists && self.direction != nil))
            rpgExpandedReject('terrain-search-direction');
        if (self.observation != nil && !self.observation.ofKind(RpgExpandedVisionObservation))
            rpgExpandedReject('terrain-search-observation-definition');
        return [self.id,self.profile,self.context,self.site,self.occurrence,self.featureExists,self.direction,
            self.seconds,self.approved,self.evidence,self.observation,self.observationApplicable,self.observationEvidence]
            + self.context.terrainSearchFacts();
    }
    observationReason()
    {
        if (self.observation == nil)
        {
            if (self.observationApplicable || self.observationEvidence != nil) rpgExpandedReject('terrain-search-observation-required');
            return nil;
        }
        if (self.observation.profile != self.profile) return 'terrain-search-observation-owner';
        if (self.observation.target != self.site || self.observation.occurrence != self.occurrence)
            return 'terrain-search-observation-scope';
        if (self.observation.result == nil) return 'terrain-search-observation-unresolved';
        if (self.observation.assess().status != 'reused') rpgExpandedReject('terrain-search-observation-receipt');
        if (!self.observation.result.noticed) return 'terrain-search-not-observed';
        if (!self.observationApplicable || self.observationEvidence == nil || self.observationEvidence == '')
            return 'terrain-search-observation-applicability-required';
        return nil;
    }
    outcomeDefinition()
    {
        local facts = [self.completedAt,self.result,self.result.direction,self.result.seconds,self.result.allowed,self.result.gate,self.result.check];
        if (self.result.check != nil) facts = facts + [self.result.check.score,self.result.check.roll,
            self.result.check.margin,self.result.check.achieved,self.result.check.critical];
        return facts;
    }
    assess()
    {
        local facts = self.definition(); local value = new RpgExpandedTerrainSearchResult();
        if (self.result != nil)
        {
            if (!holds(self.profile.terrainSearches,self) || self.boundDefinition == nil || facts.length() != self.boundDefinition.length())
                rpgExpandedReject('terrain-search-history');
            for (local index = 1; index <= facts.length(); index += 1)
                if (facts[index] != self.boundDefinition[index]) rpgExpandedReject('terrain-search-binding');
            local outcome = self.outcomeDefinition();
            if (self.boundOutcome == nil || outcome.length() != self.boundOutcome.length()) rpgExpandedReject('terrain-search-outcome');
            for (local index = 1; index <= outcome.length(); index += 1)
                if (outcome[index] != self.boundOutcome[index]) rpgExpandedReject('terrain-search-outcome');
            if (self.completedAt > rpgLedger.seconds || self.result.gate.assess().status != 'reused') rpgExpandedReject('terrain-search-gate');
            if (self.observation != nil && self.observation.assess().status != 'reused') rpgExpandedReject('terrain-search-observation-receipt');
            value.status = 'reused'; return value;
        }
        if (self.completedAt != nil || self.boundDefinition != nil || self.boundOutcome != nil) rpgExpandedReject('terrain-search-uncommitted');
        if (!self.approved || self.evidence == nil || self.evidence == '') { value.reason = 'terrain-search-evidence-required'; return value; }
        foreach (local prior in self.profile.terrainSearches)
            if (prior.id == self.id || prior.site == self.site && prior.occurrence == self.occurrence && prior.context.feature == self.context.feature)
                rpgExpandedReject('terrain-search-repeat');
        value.reason = self.observationReason(); if (value.reason != nil) return value;
        value.reason = self.context.taskUnavailableReason(self.profile); if (value.reason != nil) return value;
        value.reason = self.profile.nonTravelScheduleReason(rpgLedger.seconds,self.seconds); if (value.reason != nil) return value;
        value.score = rpgLiteScore(self.profile,self.context);
        if (value.score == nil || value.score < 3) { value.reason = 'terrain-search-score'; return value; }
        value.gate = self.profile.prepareSocialGate(self.id,self.evidence,nil);
        if (value.gate == nil) { value.reason = 'terrain-search-health-adapter-required'; return value; }
        local permission = value.gate.assess();
        if (permission.status != 'ready') { value.reason = permission.reason; return value; }
        rpgInteger(rpgLedger.seconds,0,2147483647-self.seconds); rpgLedger.validateAdvance(self.seconds);
        value.status = 'ready'; return value;
    }
    resolve()
    {
        local value = self.assess(); if (value.status == 'reused') return self.result;
        if (value.status != 'ready') return value;
        local facts = self.definition(); local start = rpgLedger.seconds;
        local permission = value.gate.resolve();
        if (!holds(['resolved','reused'],permission.status)) rpgExpandedReject('terrain-search-gate-changed');
        value.allowed = permission.allowed;
        if (value.allowed)
        {
            rpgSpendTime(self.seconds); value.seconds = self.seconds;
            if (rpgLedger.seconds != start+self.seconds || self.context.taskUnavailableReason(self.profile) != nil
                || rpgLiteScore(self.profile,self.context) != value.score || self.profile.nonTravelScheduleReason(start,self.seconds) != nil)
                rpgExpandedReject('terrain-search-interrupted');
        }
        local current = self.definition();
        if (current.length() != facts.length()) rpgExpandedReject('terrain-search-changed');
        for (local index = 1; index <= facts.length(); index += 1)
            if (current[index] != facts[index]) rpgExpandedReject('terrain-search-changed');
        if (self.observation != nil && self.observation.assess().status != 'reused') rpgExpandedReject('terrain-search-observation-receipt');
        if (value.allowed)
        {
            value.check = rpgCheck(value.score,rpgRandom.roll());
            if (value.check.achieved && self.featureExists) value.direction = self.direction;
        }
        else value.reason = permission.reason;
        self.completedAt = rpgLedger.seconds; self.boundDefinition = facts; value.status = 'resolved';
        self.result = value; self.boundOutcome = self.outcomeDefinition();
        self.profile.terrainSearches = self.profile.terrainSearches + [self]; return value;
    }
;
modify RpgExpandedProfile
    terrainSearches = []
    validateFeatures()
    {
        inherited(); local ids = [];
        foreach (local search in self.terrainSearches)
        {
            if (search == nil || !search.ofKind(RpgExpandedTerrainSearch) || search.profile != self || holds(ids,search.id)
                || search.assess().status != 'reused') rpgExpandedReject('terrain-search-history');
            ids = ids + [search.id];
        }
        return nil;
    }
;

/** B358 ordinary sight. Special senses and concealment contests need distinct procedures. */
class RpgExpandedVisionContext: RpgLiteContext
    attribute = rpgPerception
    kind = 'vision'
    someLight = true
    distanceHundredths = 100
    sizeModifier = 0
    plainSight = nil
    task = 'spot'
    withinHorizon = nil
    withinVisualArc = nil
    ordinarySightAvailable = nil
    badSightMode = nil
    approved = nil
    evidence = nil
    visionFacts()
    {
        if (self.attribute != rpgPerception || self.kind != 'vision' || self.skill != nil || !self.someLight
            || !holds(['spot','read','identify'],self.task)) rpgExpandedReject('vision-context-definition');
        rpgInteger(self.distanceHundredths,1,100000000); rpgInteger(self.sizeModifier,-100,100); rpgInteger(self.darkness,0,10);
        if (self.badSightMode != nil && !holds(['near','far'],self.badSightMode)) rpgExpandedReject('vision-bad-sight-mode');
        return [self.distanceHundredths,self.sizeModifier,self.plainSight,self.task,self.withinHorizon,
            self.withinVisualArc,self.ordinarySightAvailable,self.badSightMode,self.approved,self.evidence,self.darkness,self.modifier];
    }
    taskUnavailableReason(profile)
    {
        self.visionFacts();
        if (!self.approved || self.evidence == nil || self.evidence == '') return 'vision-world-facts-required';
        if (!self.ordinarySightAvailable) return 'vision-ordinary-sight-unavailable';
        if (!self.withinHorizon || !self.withinVisualArc) return 'vision-outside-boundaries';
        if (self.darkness == 10) return 'vision-total-darkness';
        if (profile.level('bad-sight') > 0 && self.badSightMode == nil) return 'vision-bad-sight-mode-required';
        return nil;
    }
    unavailableReason(profile)
    {
        local reason = self.taskUnavailableReason(profile); return reason == nil ? inherited(profile) : reason;
    }
    skillUseModifier(profile)
    {
        if (self.taskUnavailableReason(profile) != nil) return nil;
        local amount = self.sizeModifier + rpgExpandedRangeModifier((self.distanceHundredths+99)/100);
        if (self.plainSight && self.task == 'spot') amount += 10;
        /* Shared scoring already deducts six; restore it outside the impaired range. */
        if (profile.level('bad-sight') > 0
            && ((self.badSightMode == 'near' && self.distanceHundredths <= 100)
                || (self.badSightMode == 'far' && self.distanceHundredths > 100))) amount += 6;
        return amount;
    }
;
class RpgExpandedVisionResult: RpgExpandedResult
    noticed = nil
    score = nil
;
/** Noticing is recorded independently from a subsequent comprehension skill. */
class RpgExpandedVisionObservation: object
    id = nil
    profile = nil
    context = nil
    target = nil
    occurrence = nil
    result = nil
    recordedAt = nil
    boundDefinition = nil
    boundOutcome = nil
    definition()
    {
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)
            || self.context == nil || !self.context.ofKind(RpgExpandedVisionContext) || self.target == nil || self.occurrence == nil)
            rpgExpandedReject('vision-observation-definition');
        return [self.id,self.profile,self.context,self.target,self.occurrence] + self.context.visionFacts();
    }
    outcomeDefinition()
    {
        return [self.recordedAt,self.result,self.result.noticed,self.result.check,self.result.check.score,self.result.check.roll,
            self.result.check.margin,self.result.check.achieved,self.result.check.critical];
    }
    assess()
    {
        local facts = self.definition(); local value = new RpgExpandedVisionResult();
        if (self.result != nil)
        {
            if (!holds(self.profile.visionObservations,self) || self.boundDefinition == nil || facts.length() != self.boundDefinition.length())
                rpgExpandedReject('vision-observation-history');
            for (local index = 1; index <= facts.length(); index += 1)
                if (facts[index] != self.boundDefinition[index]) rpgExpandedReject('vision-observation-binding');
            local outcome = self.outcomeDefinition();
            if (self.boundOutcome == nil || outcome.length() != self.boundOutcome.length()) rpgExpandedReject('vision-observation-outcome');
            for (local index = 1; index <= outcome.length(); index += 1)
                if (outcome[index] != self.boundOutcome[index]) rpgExpandedReject('vision-observation-outcome');
            if (self.recordedAt > rpgLedger.seconds) rpgExpandedReject('vision-observation-time');
            value.status = 'reused'; return value;
        }
        if (self.recordedAt != nil || self.boundDefinition != nil || self.boundOutcome != nil) rpgExpandedReject('vision-observation-uncommitted');
        if (self.profile.dead || self.profile.unconscious) { value.reason = 'vision-observer-unavailable'; return value; }
        foreach (local prior in self.profile.visionObservations)
            if (prior.id == self.id || prior.target == self.target && prior.occurrence == self.occurrence)
                rpgExpandedReject('vision-observation-repeat');
        value.reason = self.context.taskUnavailableReason(self.profile); if (value.reason != nil) return value;
        value.score = rpgLiteScore(self.profile,self.context);
        if (value.score == nil || value.score < 3) { value.reason = 'vision-score-unavailable'; return value; }
        value.status = 'ready'; return value;
    }
    resolve()
    {
        local value = self.assess(); if (value.status == 'reused') return self.result;
        if (value.status != 'ready') return value;
        self.boundDefinition = self.definition(); value.check = rpgCheck(value.score,rpgRandom.roll());
        value.noticed = value.check.achieved; self.recordedAt = rpgLedger.seconds; value.status = 'resolved'; self.result = value;
        self.boundOutcome = self.outcomeDefinition(); self.profile.visionObservations = self.profile.visionObservations + [self]; return value;
    }
;
modify RpgExpandedProfile
    visionObservations = []
    validateFeatures()
    {
        inherited(); local ids = [];
        foreach (local observation in self.visionObservations)
        {
            if (observation == nil || !observation.ofKind(RpgExpandedVisionObservation) || observation.profile != self
                || holds(ids,observation.id) || observation.assess().status != 'reused') rpgExpandedReject('vision-observation-history');
            ids = ids + [observation.id];
        }
        return nil;
    }
;

class RpgExpandedHearingDistanceResult: RpgExpandedResult
    quarterYardsNumerator = nil
    quarterYardsDenominator = 1
;
/** B358 exact table steps; rational quarter-yard distances avoid fractional truncation. */
rpgExpandedHearingDistance(sound,steps)
{
    local sounds = ['rustling','quiet-speech','ordinary-speech','light-traffic','loud-speech','busy-office',
        'ordinary-traffic','moderate-amplified-music','heavy-traffic','jet-departure',
        'very-loud-amplified-music','extreme-amplified-sound'];
    local base = 1; local found = nil;
    foreach (local name in sounds)
    {
        if (sound == name) { found = true; break; }
        base *= 2;
    }
    if (!found) rpgExpandedReject('hearing-sound-category');
    rpgInteger(steps,-20,19);
    local value = new RpgExpandedHearingDistanceResult(); value.quarterYardsNumerator = base;
    if (steps >= 0)
        for (local index = 0; index < steps; index += 1) value.quarterYardsNumerator *= 2;
    else
        for (local index = 0; index < -steps; index += 1) value.quarterYardsDenominator *= 2;
    value.modifier = -steps; value.status = 'ready'; return value;
}
/** Ordinary audible sound detection; not language comprehension or a stealth contest. */
class RpgExpandedHearingContext: RpgLiteContext
    attribute = rpgPerception
    kind = 'hearing'
    someLight = nil
    sound = nil
    distanceSteps = 0
    ambientModifier = 0
    ordinaryHearingAvailable = nil
    ordinaryFrequency = nil
    approved = nil
    evidence = nil
    hearingFacts()
    {
        if (self.attribute != rpgPerception || self.kind != 'hearing' || self.skill != nil || self.language != nil
            || self.understandsSpeech || self.darkness != 0 || self.someLight)
            rpgExpandedReject('hearing-context-definition');
        rpgExpandedHearingDistance(self.sound,self.distanceSteps); rpgInteger(self.ambientModifier,-100,100);
        return [self.sound,self.distanceSteps,self.ambientModifier,self.ordinaryHearingAvailable,
            self.ordinaryFrequency,self.approved,self.evidence,self.modifier];
    }
    taskUnavailableReason(profile)
    {
        self.hearingFacts();
        if (!self.approved || self.evidence == nil || self.evidence == '') return 'hearing-world-facts-required';
        if (!self.ordinaryHearingAvailable) return 'hearing-ordinary-sense-unavailable';
        if (!self.ordinaryFrequency) return 'hearing-special-frequency-required';
        return nil;
    }
    unavailableReason(profile)
    {
        local reason = self.taskUnavailableReason(profile); return reason == nil ? inherited(profile) : reason;
    }
    skillUseModifier(profile)
    {
        if (self.taskUnavailableReason(profile) != nil) return nil;
        return rpgExpandedHearingDistance(self.sound,self.distanceSteps).modifier + self.ambientModifier;
    }
;

class RpgExpandedHearingResult: RpgExpandedResult
    noticed = nil
    score = nil
;
/** Noticing is recorded independently from a subsequent comprehension skill. */
class RpgExpandedHearingObservation: object
    id = nil
    profile = nil
    context = nil
    target = nil
    occurrence = nil
    result = nil
    recordedAt = nil
    boundDefinition = nil
    boundOutcome = nil
    definition()
    {
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)
            || self.context == nil || !self.context.ofKind(RpgExpandedHearingContext) || self.target == nil || self.occurrence == nil)
            rpgExpandedReject('hearing-observation-definition');
        return [self.id,self.profile,self.context,self.target,self.occurrence] + self.context.hearingFacts();
    }
    outcomeDefinition()
    {
        return [self.recordedAt,self.result,self.result.noticed,self.result.check,self.result.check.score,self.result.check.roll,
            self.result.check.margin,self.result.check.achieved,self.result.check.critical];
    }
    assess()
    {
        local facts = self.definition(); local value = new RpgExpandedHearingResult();
        if (self.result != nil)
        {
            if (!holds(self.profile.hearingObservations,self) || self.boundDefinition == nil || facts.length() != self.boundDefinition.length())
                rpgExpandedReject('hearing-observation-history');
            for (local index = 1; index <= facts.length(); index += 1)
                if (facts[index] != self.boundDefinition[index]) rpgExpandedReject('hearing-observation-binding');
            local outcome = self.outcomeDefinition();
            if (self.boundOutcome == nil || outcome.length() != self.boundOutcome.length()) rpgExpandedReject('hearing-observation-outcome');
            for (local index = 1; index <= outcome.length(); index += 1)
                if (outcome[index] != self.boundOutcome[index]) rpgExpandedReject('hearing-observation-outcome');
            if (self.recordedAt > rpgLedger.seconds) rpgExpandedReject('hearing-observation-time');
            value.status = 'reused'; return value;
        }
        if (self.recordedAt != nil || self.boundDefinition != nil || self.boundOutcome != nil) rpgExpandedReject('hearing-observation-uncommitted');
        if (self.profile.dead || self.profile.unconscious) { value.reason = 'hearing-observer-unavailable'; return value; }
        foreach (local prior in self.profile.hearingObservations)
            if (prior.id == self.id || prior.target == self.target && prior.occurrence == self.occurrence)
                rpgExpandedReject('hearing-observation-repeat');
        value.reason = self.context.taskUnavailableReason(self.profile); if (value.reason != nil) return value;
        value.score = rpgLiteScore(self.profile,self.context);
        if (value.score == nil || value.score < 3) { value.reason = 'hearing-score-unavailable'; return value; }
        value.status = 'ready'; return value;
    }
    resolve()
    {
        local value = self.assess(); if (value.status == 'reused') return self.result;
        if (value.status != 'ready') return value;
        self.boundDefinition = self.definition(); value.check = rpgCheck(value.score,rpgRandom.roll());
        value.noticed = value.check.achieved; self.recordedAt = rpgLedger.seconds; value.status = 'resolved'; self.result = value;
        self.boundOutcome = self.outcomeDefinition(); self.profile.hearingObservations = self.profile.hearingObservations + [self]; return value;
    }
;
modify RpgExpandedProfile
    hearingObservations = []
    validateFeatures()
    {
        inherited(); local ids = [];
        foreach (local observation in self.hearingObservations)
        {
            if (observation == nil || !observation.ofKind(RpgExpandedHearingObservation) || observation.profile != self
                || holds(ids,observation.id) || observation.assess().status != 'reused') rpgExpandedReject('hearing-observation-history');
            ids = ids + [observation.id];
        }
        return nil;
    }
;


/** Native action parity for ordinary vision/hearing receipts; meaning stays private. */
class RpgExpandedSenseObservationAction: Action
    observation = nil
    operation = 'resolve'
    perform(actor)
    {
        if (self.observation == nil || (!self.observation.ofKind(RpgExpandedVisionObservation)
                && !self.observation.ofKind(RpgExpandedHearingObservation)) || !holds(['preview','resolve'],self.operation))
            rpgExpandedReject('sense-action-definition');
        local value = new RpgExpandedResult();
        if (actor == nil || !actor.ofKind(Thing) || actor.rpgProfile == nil || actor.rpgProfile != self.observation.profile)
            value.reason = 'sense-action-owner-required';
        else value = self.operation == 'preview' ? self.observation.assess() : self.observation.resolve();
        event('rpg.expanded.sense'); eventValue(self.observation.ofKind(RpgExpandedVisionObservation) ? 'vision' : 'hearing');
        eventValue(self.operation); eventValue(value.status); eventValue(value.reason); return value;
    }
    exec(context) { return self.perform(context.actor); }
;

/** B358 interpretation after noticing; ordinary and speech checks use IQ. */
class RpgExpandedComprehensionContext: RpgLiteContext
    attribute = rpgIQ
    kind = 'comprehension'
    someLight = nil
    purpose = 'ordinary'
    expertiseApproved = nil
    evidence = nil
    comprehensionFacts()
    {
        if (self.attribute != rpgIQ || self.kind != 'comprehension' || self.darkness != 0 || self.someLight
            || !holds(['ordinary','expert','speech'],self.purpose) || self.understandsSpeech || self.written)
            rpgExpandedReject('comprehension-context-definition');
        if ((self.purpose == 'expert' && (self.skill == nil || !self.skill.ofKind(RpgLiteSkill) || !self.expertiseApproved))
            || (self.purpose != 'expert' && self.skill != nil)) rpgExpandedReject('comprehension-skill-definition');
        if ((self.purpose == 'speech' && self.language == nil) || (self.purpose != 'speech' && self.language != nil))
            rpgExpandedReject('comprehension-language-definition');
        if (self.evidence == nil || self.evidence == '') rpgExpandedReject('comprehension-context-evidence');
        return [self.purpose,self.skill,self.language,self.modifier,self.expertiseApproved,self.evidence] + self.culturalTaskFacts();
    }
    skillUseModifier(profile) { self.comprehensionFacts(); return 0; }
;
class RpgExpandedComprehensionResult: RpgExpandedResult
    meaning = nil
    score = nil
    gate = nil
    allowed = nil
;
class RpgExpandedSenseComprehension: object
    id = nil
    profile = nil
    observation = nil
    context = nil
    meaning = nil
    seconds = nil
    applicable = nil
    evidence = nil
    result = nil
    completedAt = nil
    boundDefinition = nil
    boundOutcome = nil
    definition()
    {
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)
            || self.observation == nil || (!self.observation.ofKind(RpgExpandedVisionObservation)
                && !self.observation.ofKind(RpgExpandedHearingObservation))
            || self.context == nil || !self.context.ofKind(RpgExpandedComprehensionContext))
            rpgExpandedReject('sense-comprehension-definition');
        rpgInteger(self.seconds,0,86400);
        if (self.context.purpose == 'speech' && !self.observation.ofKind(RpgExpandedHearingObservation))
            rpgExpandedReject('speech-comprehension-hearing-required');
        return [self.id,self.profile,self.observation,self.context,self.meaning,self.seconds,self.applicable,self.evidence]
            + self.context.comprehensionFacts();
    }
    outcomeDefinition()
    {
        local facts = [self.completedAt,self.result,self.result.meaning,self.result.seconds,self.result.allowed,self.result.gate,self.result.check];
        if (self.result.check != nil) facts = facts + [self.result.check.score,self.result.check.roll,
            self.result.check.margin,self.result.check.achieved,self.result.check.critical];
        return facts;
    }
    assess()
    {
        local facts = self.definition(); local value = new RpgExpandedComprehensionResult();
        if (self.result != nil)
        {
            if (!holds(self.profile.senseComprehensions,self) || self.boundDefinition == nil || facts.length() != self.boundDefinition.length())
                rpgExpandedReject('sense-comprehension-history');
            for (local index = 1; index <= facts.length(); index += 1)
                if (facts[index] != self.boundDefinition[index]) rpgExpandedReject('sense-comprehension-binding');
            local outcome = self.outcomeDefinition();
            if (self.boundOutcome == nil || outcome.length() != self.boundOutcome.length()) rpgExpandedReject('sense-comprehension-outcome');
            for (local index = 1; index <= outcome.length(); index += 1)
                if (outcome[index] != self.boundOutcome[index]) rpgExpandedReject('sense-comprehension-outcome');
            if (self.completedAt > rpgLedger.seconds || self.observation.assess().status != 'reused'
                || self.result.gate.assess().status != 'reused') rpgExpandedReject('sense-comprehension-receipt');
            value.status = 'reused'; return value;
        }
        if (self.completedAt != nil || self.boundDefinition != nil || self.boundOutcome != nil) rpgExpandedReject('sense-comprehension-uncommitted');
        if (self.observation.profile != self.profile) { value.reason = 'sense-comprehension-observer'; return value; }
        if (self.observation.result == nil) { value.reason = 'sense-comprehension-not-observed'; return value; }
        self.observation.assess();
        if (!self.observation.result.noticed) { value.reason = 'sense-comprehension-not-observed'; return value; }
        if (!self.applicable || self.evidence == nil || self.evidence == '' || self.meaning == nil || self.meaning == '')
        { value.reason = 'sense-comprehension-evidence-required'; return value; }
        foreach (local prior in self.profile.senseComprehensions)
            if (prior.id == self.id || prior.observation == self.observation) rpgExpandedReject('sense-comprehension-repeat');
        value.reason = self.profile.nonTravelScheduleReason(rpgLedger.seconds,self.seconds); if (value.reason != nil) return value;
        value.score = rpgLiteScore(self.profile,self.context);
        if (value.score == nil || value.score < 3) { value.reason = 'sense-comprehension-score'; return value; }
        value.gate = self.profile.prepareSocialGate(self.id,self.evidence,nil);
        if (value.gate == nil) { value.reason = 'sense-comprehension-health-adapter-required'; return value; }
        local permission = value.gate.assess();
        if (permission.status != 'ready') { value.reason = permission.reason; return value; }
        rpgInteger(rpgLedger.seconds,0,2147483647-self.seconds); rpgLedger.validateAdvance(self.seconds);
        value.status = 'ready'; return value;
    }
    resolve()
    {
        local value = self.assess(); if (value.status == 'reused') return self.result;
        if (value.status != 'ready') return value;
        local facts = self.definition(); local start = rpgLedger.seconds; local permission = value.gate.resolve();
        if (!holds(['resolved','reused'],permission.status)) rpgExpandedReject('sense-comprehension-gate-changed');
        value.allowed = permission.allowed;
        if (value.allowed)
        {
            rpgSpendTime(self.seconds); value.seconds = self.seconds;
            if (rpgLedger.seconds != start+self.seconds || rpgLiteScore(self.profile,self.context) != value.score
                || self.profile.nonTravelScheduleReason(start,self.seconds) != nil) rpgExpandedReject('sense-comprehension-interrupted');
        }
        local current = self.definition();
        if (current.length() != facts.length()) rpgExpandedReject('sense-comprehension-changed');
        for (local index = 1; index <= facts.length(); index += 1)
            if (current[index] != facts[index]) rpgExpandedReject('sense-comprehension-changed');
        if (self.observation.assess().status != 'reused') rpgExpandedReject('sense-comprehension-receipt');
        if (value.allowed)
        {
            value.check = rpgCheck(value.score,rpgRandom.roll()); if (value.check.achieved) value.meaning = self.meaning;
        }
        else value.reason = permission.reason;
        self.completedAt = rpgLedger.seconds; self.boundDefinition = facts; value.status = 'resolved'; self.result = value;
        self.boundOutcome = self.outcomeDefinition(); self.profile.senseComprehensions = self.profile.senseComprehensions + [self]; return value;
    }
;
modify RpgExpandedProfile
    senseComprehensions = []
    validateFeatures()
    {
        inherited(); local ids = []; local observations = [];
        foreach (local attempt in self.senseComprehensions)
        {
            if (attempt == nil || !attempt.ofKind(RpgExpandedSenseComprehension) || attempt.profile != self
                || holds(ids,attempt.id) || holds(observations,attempt.observation) || attempt.assess().status != 'reused')
                rpgExpandedReject('sense-comprehension-history');
            ids = ids + [attempt.id]; observations = observations + [attempt.observation];
        }
        return nil;
    }
;

class RpgExpandedOrdinaryWarningResult: RpgExpandedResult
    warning = nil
;
/** B47/B358 ordinary danger warning. The check remains private to the receipt. */
class RpgExpandedOrdinaryDangerWarning: object
    id = nil
    profile = nil
    situation = nil
    failedAttempt = nil
    hazardPresent = nil
    approved = nil
    evidence = nil
    warningText = nil
    detailText = nil
    result = nil
    secretCheck = nil
    recordedAt = nil
    boundDefinition = nil
    boundOutcome = nil
    definition()
    {
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile) || self.situation == nil)
            rpgExpandedReject('ordinary-warning-definition');
        if (self.failedAttempt != nil && !self.failedAttempt.ofKind(RpgExpandedVisionObservation)
            && !self.failedAttempt.ofKind(RpgExpandedHearingObservation) && !self.failedAttempt.ofKind(RpgExpandedSenseComprehension))
            rpgExpandedReject('ordinary-warning-trigger');
        return [self.id,self.profile,self.situation,self.failedAttempt,self.hazardPresent,self.approved,
            self.evidence,self.warningText,self.detailText];
    }
    outcomeDefinition()
    {
        return [self.recordedAt,self.result,self.result.warning,self.secretCheck,self.secretCheck.score,self.secretCheck.roll,
            self.secretCheck.margin,self.secretCheck.achieved,self.secretCheck.critical];
    }
    triggerReason()
    {
        if (self.failedAttempt == nil) return nil;
        if (self.failedAttempt.profile != self.profile) return 'ordinary-warning-trigger-owner';
        if (self.failedAttempt.result == nil) return 'ordinary-warning-trigger-unresolved';
        if (self.failedAttempt.assess().status != 'reused') rpgExpandedReject('ordinary-warning-trigger-receipt');
        if (self.failedAttempt.result.check == nil || self.failedAttempt.result.check.achieved)
            return 'ordinary-warning-failed-check-required';
        return nil;
    }
    assess()
    {
        local facts = self.definition(); local value = new RpgExpandedOrdinaryWarningResult();
        if (self.result != nil)
        {
            if (!holds(self.profile.ordinaryDangerWarnings,self) || self.boundDefinition == nil || facts.length() != self.boundDefinition.length())
                rpgExpandedReject('ordinary-warning-history');
            for (local index = 1; index <= facts.length(); index += 1)
                if (facts[index] != self.boundDefinition[index]) rpgExpandedReject('ordinary-warning-binding');
            local outcome = self.outcomeDefinition();
            if (self.boundOutcome == nil || outcome.length() != self.boundOutcome.length()) rpgExpandedReject('ordinary-warning-outcome');
            for (local index = 1; index <= outcome.length(); index += 1)
                if (outcome[index] != self.boundOutcome[index]) rpgExpandedReject('ordinary-warning-outcome');
            if (self.recordedAt > rpgLedger.seconds || self.triggerReason() != nil) rpgExpandedReject('ordinary-warning-receipt');
            value.status = 'reused'; value.warning = self.result.warning; return value;
        }
        if (self.secretCheck != nil || self.recordedAt != nil || self.boundDefinition != nil || self.boundOutcome != nil)
            rpgExpandedReject('ordinary-warning-uncommitted');
        if (self.profile.level('danger-sense') <= 0) { value.reason = 'ordinary-warning-trait-required'; return value; }
        if (self.profile.level('precognition') > 0 || self.profile.level('psionic-danger-warning') > 0)
            rpgExpandedReject('ordinary-warning-duplicate-ability');
        if (self.profile.dead || self.profile.unconscious) { value.reason = 'ordinary-warning-observer-unavailable'; return value; }
        if (!self.approved || !self.hazardPresent || self.evidence == nil || self.evidence == ''
            || self.warningText == nil || self.warningText == '' || self.detailText == nil || self.detailText == '')
        { value.reason = 'ordinary-warning-hazard-facts-required'; return value; }
        foreach (local prior in self.profile.ordinaryDangerWarnings)
            if (prior.id == self.id || prior.situation == self.situation) rpgExpandedReject('ordinary-warning-situation-used');
        value.reason = self.triggerReason(); if (value.reason != nil) return value;
        if (self.profile.attributeScore(rpgPerception) < 3) { value.reason = 'ordinary-warning-score'; return value; }
        value.status = 'ready'; return value;
    }
    resolve()
    {
        local value = self.assess(); if (value.status == 'reused') return self.result;
        if (value.status != 'ready') return value;
        self.boundDefinition = self.definition(); self.secretCheck = rpgCheck(self.profile.attributeScore(rpgPerception),rpgRandom.roll());
        if (self.secretCheck.achieved) value.warning = self.secretCheck.roll <= 4 ? self.detailText : self.warningText;
        self.recordedAt = rpgLedger.seconds; value.status = 'resolved'; self.result = value; self.boundOutcome = self.outcomeDefinition();
        self.profile.ordinaryDangerWarnings = self.profile.ordinaryDangerWarnings + [self]; return value;
    }
;
modify RpgExpandedProfile
    ordinaryDangerWarnings = []
    validateFeatures()
    {
        inherited(); local ids = []; local situations = [];
        foreach (local warning in self.ordinaryDangerWarnings)
        {
            if (warning == nil || !warning.ofKind(RpgExpandedOrdinaryDangerWarning) || warning.profile != self
                || holds(ids,warning.id) || holds(situations,warning.situation) || warning.assess().status != 'reused')
                rpgExpandedReject('ordinary-warning-history');
            ids = ids + [warning.id]; situations = situations + [warning.situation];
        }
        return nil;
    }
;

/** Shared comprehension entry point; authored meaning is never broadcast here. */
class RpgExpandedSenseComprehensionAction: Action
    comprehension = nil
    operation = 'resolve'
    perform(actor)
    {
        if (self.comprehension == nil || !self.comprehension.ofKind(RpgExpandedSenseComprehension)
            || !holds(['preview','resolve'],self.operation)) rpgExpandedReject('comprehension-action-definition');
        local value = new RpgExpandedResult();
        if (actor == nil || !actor.ofKind(Thing) || actor.rpgProfile == nil || actor.rpgProfile != self.comprehension.profile)
            value.reason = 'comprehension-action-owner-required';
        else value = self.operation == 'preview' ? self.comprehension.assess() : self.comprehension.resolve();
        event('rpg.expanded.comprehension'); eventValue(self.operation); eventValue(value.status); eventValue(value.reason);
        return value;
    }
    exec(context) { return self.perform(context.actor); }
;
