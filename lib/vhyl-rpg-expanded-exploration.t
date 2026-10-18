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
