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
    ventilation = 'none'
    controlSucceeded = nil
    reserveLevels = 0
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
            || self.evidence != self.boundEvidence || !holds(self.profile.breathHistory,self))
            rpgExpandedReject('breath-binding');
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
        value = rpgExpandedBreathDuration(self.profile.ht,self.activity,self.prepared,self.ventilation,self.controlSucceeded,self.reserveLevels);
        if (value.status != 'ready') return value;
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
            else if (reserve.endedAt < reserve.startedAt || reserve.endedAt > rpgLedger.seconds
                || reserve.endedAt > reserve.startedAt + reserve.durationSeconds || reserve.airEvidence == nil)
                rpgExpandedReject('breath-end-history');
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
    context = nil
;

modify RpgExpandedProfile
    swimmingEncounter = nil
    swimmingHistory = []
;

/** Fixed entry circumstances; equipment load is read afresh for each check. */
class RpgExpandedSwimmingEncounter: object
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
    start()
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
        self.boundId = self.id; self.boundProfile = self.profile; self.boundSkill = self.skill;
        self.boundDefaultAvailable = self.defaultAvailable;
        self.boundIntentional = self.intentionalEntry; self.boundBuild = self.build; self.boundEvidence = self.evidence; self.boundPace = self.pace;
        self.startedAt = rpgLedger.seconds; self.nextCheckAt = self.startedAt;
        self.nextEnduranceAt = self.startedAt + (self.pace == 'top-speed' ? 60 : 1800);
        self.profile.swimmingEncounter = self; self.profile.swimmingHistory = self.profile.swimmingHistory + [self];
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
            if (self.id != self.boundId || self.encounter != self.boundEncounter || !holds(self.encounter.checks,self))
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
        if (patient.fp() <= 1) { value.reason = 'swimming-exhaustion-unavailable'; return value; }
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
        if (outcome.fatigue > 0) value.fatigue = rpgLiteFatigueIncrement(self.encounter.profile,'swimming');
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
    context = nil
    fatigue = 0
;

/** Exertion interval, distinct from the balance-check schedule. B355. */
class RpgExpandedSwimEndurance: object
    id = nil
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
            if (self.id != self.boundId || self.encounter != self.boundEncounter || !holds(self.encounter.enduranceChecks,self))
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
        if (patient.fp() <= 1) { value.reason = 'swimming-exhaustion-unavailable'; return value; }
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
        if (!value.check.achieved) value.fatigue = rpgLiteFatigueIncrement(self.encounter.profile,'swimming');
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
class RpgExpandedHikingAssessment: RpgExpandedResult
    effectiveTerrain = nil
    terrainPercent = 100
    weatherDivisor = 1
    travelSkill = 'hiking'
    milesHundredths = 0
;

class RpgExpandedHikingConditions: object
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
    value.milesHundredths = numerator / (50 * value.weatherDivisor);
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
    definition() { return [self.id,self.evidence,self.attempts.length()] + self.attempts; }
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
    local value = new RpgExpandedThrowAssessment();
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
