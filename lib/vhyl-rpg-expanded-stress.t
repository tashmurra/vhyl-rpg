/* Original optional campaign rules. Include after expanded foundation, health
 * and traits. Inclusion does not configure a character or create stress. */

/** Original campaign policy, frozen by its first configured character state.
 * Gains and thresholds are ordered integer lists; recovery uses the shared clock. */
class RpgExpandedStressPolicy: object
    cap = 12
    gains = [1,2,3]
    thresholds = [4,8,12]
    strainSeconds = 600
    recoverySeconds = 3600
    dailyRecovery = 4
    daySeconds = 86400
    facts() { return [self.cap,self.strainSeconds,self.recoverySeconds,self.dailyRecovery,self.daySeconds,self.gains.length(),self.thresholds.length()] + self.gains + self.thresholds; }
    validate()
    {
        rpgInteger(self.cap,1,1000); rpgInteger(self.strainSeconds,1,86400);
        rpgInteger(self.recoverySeconds,1,86400); rpgInteger(self.dailyRecovery,1,1000);
        rpgInteger(self.daySeconds,self.recoverySeconds,1000000);
        if (self.gains.length() != 3 || self.thresholds.length() == 0) rpgExpandedReject('stress-policy-shape');
        foreach (local amount in self.gains) rpgInteger(amount,1,self.cap);
        local previous = 0;
        foreach (local threshold in self.thresholds) { rpgInteger(threshold,previous+1,self.cap); previous = threshold; }
        return nil;
    }
;
/** Stress state. Carries profile, policy, balance, episode, fired. Operations: facts, bind, configure, validate. */
class RpgExpandedStressState: object
    profile = nil
    policy = nil
    balance = 0
    episode = 1
    fired = []
    gains = []
    decisions = []
    recoveries = []
    strains = []
    rest = nil
    boundPolicy = nil
    boundState = nil
    facts() { return [self.profile,self.policy,self.balance,self.episode,self.rest,self.gains.length(),self.decisions.length(),self.recoveries.length(),self.strains.length(),self.fired.length()] + self.fired + self.gains + self.decisions + self.recoveries + self.strains; }
    bind() { self.boundState = self.facts(); return nil; }
    configure()
    {
        if (self.boundPolicy != nil) { self.validate(); return 'reused'; }
        if (self.profile == nil || !self.profile.ofKind(RpgExpandedProfile) || self.policy == nil || !self.policy.ofKind(RpgExpandedStressPolicy))
            rpgExpandedReject('stress-state-definition');
        if (self.profile.stressState != nil || self.balance != 0 || self.episode != 1 || self.fired.length() != 0
            || self.gains.length() != 0 || self.decisions.length() != 0 || self.recoveries.length() != 0 || self.strains.length() != 0 || self.rest != nil)
            rpgExpandedReject('stress-state-unowned');
        self.policy.validate(); self.boundPolicy = self.policy.facts(); self.profile.stressState = self; self.bind(); return 'resolved';
    }
    validate()
    {
        if (self.profile == nil || self.profile.stressState != self || self.boundPolicy == nil || self.boundState == nil)
            rpgExpandedReject('stress-state-not-configured');
        rpgExpandedAttentionBinding(self.policy.facts(),self.boundPolicy,'stress-policy-changed');
        rpgExpandedAttentionBinding(self.facts(),self.boundState,'stress-state-changed');
        foreach (local gain in self.gains) gain.validateReceipt();
        foreach (local decision in self.decisions) decision.validateReceipt();
        foreach (local recovery in self.recoveries) recovery.validateReceipt();
        foreach (local strain in self.strains) strain.validateReceipt();
        return nil;
    }
    pending()
    { foreach (local decision in self.decisions) if (decision.resolution == nil) return decision; return nil; }
    strainPenalty()
    {
        self.validate(); local active = nil;
        foreach (local strain in self.strains) { strain.validateReceipt(); if (rpgLedger.seconds < strain.expiresAt) active = true; }
        return active ? -1 : 0;
    }
    recoveredOn(day)
    {
        local total = 0;
        foreach (local recovery in self.recoveries)
        {
            recovery.validateReceipt();
            if (recovery.day == day) total += recovery.amount;
        }
        return total;
    }
;
/** Stress gain. Carries id, state, cause, severity, evidence. Operations: facts, validateReceipt, assess, apply. */
class RpgExpandedStressGain: object
    id = nil
    state = nil
    cause = nil
    severity = nil
    evidence = nil
    fearEvent = nil
    requested = nil
    applied = nil
    discarded = nil
    result = nil
    boundReceipt = nil
    facts() { return [self.id,self.state,self.cause,self.severity,self.evidence,self.fearEvent,self.requested,self.applied,self.discarded]; }
    validateReceipt()
    {
        if (self.result == nil || !holds(self.state.gains,self)) rpgExpandedReject('stress-gain-history');
        rpgExpandedAttentionBinding(self.facts(),self.boundReceipt,'stress-gain-binding');
    }
    assess()
    {
        if (self.state == nil || !self.state.ofKind(RpgExpandedStressState) || self.id == nil || self.id == '' || (self.cause == nil || self.cause == '')
            || !holds(['mild','moderate','severe'],self.severity) || self.evidence == nil || self.evidence == '')
            rpgExpandedReject('stress-gain-definition');
        self.state.validate(); local value = new RpgExpandedResult();
        if (self.result != nil) { self.validateReceipt(); value.status = 'reused'; return value; }
        foreach (local prior in self.state.gains)
            if (prior.id == self.id || prior.cause == self.cause) { value.reason = 'stress-cause-already-recorded'; return value; }
        if (self.fearEvent != nil && (!self.fearEvent.ofKind(RpgExpandedFearEvent)
            || self.fearEvent.context.profile != self.state.profile || self.fearEvent.assess().status != 'reused'))
            rpgExpandedReject('stress-gain-fear-owner');
        if (self.requested != nil || self.applied != nil || self.discarded != nil || self.boundReceipt != nil)
            rpgExpandedReject('stress-gain-uncommitted');
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local state = self.state; if (state.rest != nil) state.rest.interrupt(); local old = state.balance;
        self.requested = state.policy.gains[self.severity == 'mild' ? 1 : self.severity == 'moderate' ? 2 : 3];
        self.applied = self.requested < state.policy.cap-old ? self.requested : state.policy.cap-old;
        self.discarded = self.requested-self.applied; state.balance += self.applied;
        foreach (local threshold in state.policy.thresholds)
            if (old < threshold && state.balance >= threshold && !holds(state.fired,threshold))
            {
                local decision = new RpgExpandedStressDecision(); decision.state = state; decision.gain = self;
                decision.threshold = threshold; decision.episode = state.episode; decision.boundReceipt = decision.facts(); decision.bindState();
                state.decisions = state.decisions + [decision]; state.fired = state.fired + [threshold];
            }
        value.status = 'resolved'; self.result = value; self.boundReceipt = self.facts(); state.gains = state.gains + [self]; state.bind(); return value;
    }
;
/** Stress decision. Carries state, gain, threshold, episode, resolution. Operations: bindState, facts, validateReceipt. */
class RpgExpandedStressDecision: object
    state = nil
    gain = nil
    threshold = nil
    episode = nil
    resolution = nil
    pendingFear = nil
    boundState = nil
    bindState() { self.boundState = [self.resolution,self.pendingFear]; return nil; }
    boundReceipt = nil
    facts() { return [self.state,self.gain,self.threshold,self.episode]; }
    validateReceipt()
    {
        if (!holds(self.state.decisions,self)) rpgExpandedReject('stress-decision-history');
        rpgExpandedAttentionBinding(self.facts(),self.boundReceipt,'stress-decision-binding');
        rpgExpandedAttentionBinding([self.resolution,self.pendingFear],self.boundState,'stress-decision-state');
        if (self.resolution != nil) self.resolution.validateReceipt();
        if (self.pendingFear != nil && self.pendingFear.decision != self) rpgExpandedReject('stress-decision-fear-owner');
        return nil;
    }
;
/** Stress strain. Carries resolution, startedAt, expiresAt, boundReceipt. Operations: facts, validateReceipt. */
class RpgExpandedStressStrain: object
    resolution = nil
    startedAt = nil
    expiresAt = nil
    boundReceipt = nil
    facts() { return [self.resolution,self.startedAt,self.expiresAt]; }
    validateReceipt()
    { rpgExpandedAttentionBinding(self.facts(),self.boundReceipt,'stress-strain-binding'); return nil; }
;
/** Stress resolution. Carries decision, choice, evidence, fearEvent, strain. Operations: facts, validateReceipt, assess, finish. */
class RpgExpandedStressResolution: object
    decision = nil
    choice = nil
    evidence = nil
    fearEvent = nil
    strain = nil
    result = nil
    boundReceipt = nil
    resolvingFear = nil
    committing = nil
    facts() { return [self.decision,self.choice,self.evidence,self.fearEvent,self.strain]; }
    validateReceipt()
    {
        if (self.result == nil || self.decision.resolution != self) rpgExpandedReject('stress-resolution-history');
        rpgExpandedAttentionBinding(self.facts(),self.boundReceipt,'stress-resolution-binding');
        if (self.strain != nil) self.strain.validateReceipt();
        if (self.fearEvent != nil && self.fearEvent.assess().status != 'reused') rpgExpandedReject('stress-resolution-fear-history');
        return nil;
    }
    assess()
    {
        if (self.decision == nil || !self.decision.ofKind(RpgExpandedStressDecision) || !holds(['strain','fear','coping'],self.choice)
            || self.evidence == nil || self.evidence == '') rpgExpandedReject('stress-resolution-definition');
        self.decision.state.validate(); local value = new RpgExpandedResult();
        if (self.result != nil) { self.validateReceipt(); value.status = 'reused'; return value; }
        if (self.decision.state.pending() != self.decision) { value.reason = 'stress-decision-order'; return value; }
        if (self.decision.pendingFear != nil && self.decision.pendingFear != self)
        { value.reason = 'stress-decision-fear-pending'; return value; }
        if (self.choice == 'fear')
        {
            if (self.fearEvent == nil || !self.fearEvent.ofKind(RpgExpandedFearEvent)
                || self.fearEvent.context.profile != self.decision.state.profile) rpgExpandedReject('stress-resolution-fear-owner');
            if (self.decision.pendingFear == self)
            {
                rpgExpandedAttentionBinding(self.facts(),self.boundReceipt,'stress-resolution-pending-binding');
                if (self.fearEvent.assess().status != 'reused') rpgExpandedReject('stress-resolution-pending-fear');
            }
            else
            {
                local fear = self.fearEvent.assess();
                if (fear.status != 'ready') { value.reason = 'stress-resolution-new-fear-required'; return value; }
            }
        }
        else if (self.fearEvent != nil || self.decision.pendingFear != nil) rpgExpandedReject('stress-resolution-unused-fear');
        value.status = 'ready'; return value;
    }
    finish()
    {
        if (!self.committing || self.result != nil) rpgExpandedReject('stress-resolution-commit-required');
        self.result = new RpgExpandedResult(); self.result.status = 'resolved'; self.boundReceipt = self.facts();
        self.decision.resolution = self; self.decision.pendingFear = nil; self.decision.bindState(); self.decision.state.bind(); self.committing = nil; return self.result;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        if (self.choice == 'fear')
        {
            self.resolvingFear = true; local fear = self.fearEvent.resolve(); self.resolvingFear = nil;
            if (fear.status != 'resolved') rpgExpandedReject('stress-resolution-fear-changed');
            if (fear.row != nil && self.fearEvent.consequence == nil)
            {
                self.decision.pendingFear = self; self.decision.bindState(); self.boundReceipt = self.facts();
                value.status = 'awaiting-consequence'; return value;
            }
        }
        if (self.choice == 'strain')
        {
            self.strain = new RpgExpandedStressStrain(); self.strain.resolution = self;
            self.strain.startedAt = rpgLedger.seconds; self.strain.expiresAt = rpgLedger.seconds+self.decision.state.policy.strainSeconds;
            self.strain.boundReceipt = self.strain.facts(); self.decision.state.strains = self.decision.state.strains + [self.strain];
        }
        self.committing = true; return self.finish();
    }
    completeFear(consequence)
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        if (self.choice != 'fear' || self.decision.pendingFear != self) rpgExpandedReject('stress-fear-consequence-owner');
        self.resolvingFear = true; value = self.fearEvent.applyConsequence(consequence); self.resolvingFear = nil;
        if (!holds(['resolved','reused'],value.status)) return value;
        self.committing = true; return self.finish();
    }
;

/** One uninterrupted safe interval. begin/complete use the shared clock; neither
 * invents elapsed time. interrupt retains a zero-credit receipt. */
class RpgExpandedStressRecovery: object
    id = nil
    state = nil
    safe = nil
    evidence = nil
    startedAt = nil
    endedAt = nil
    day = nil
    amount = nil
    interrupted = nil
    boundStart = nil
    boundReceipt = nil
    facts() { return [self.id,self.state,self.safe,self.evidence,self.startedAt]; }
    receiptFacts() { return self.facts() + [self.endedAt,self.day,self.amount,self.interrupted]; }
    validateReceipt()
    {
        if (self.endedAt == nil || !holds(self.state.recoveries,self)) rpgExpandedReject('stress-recovery-history');
        rpgExpandedAttentionBinding(self.receiptFacts(),self.boundReceipt,'stress-recovery-binding');
    }
    begin()
    {
        if (self.id == nil || self.id == '' || self.state == nil || !self.state.ofKind(RpgExpandedStressState)
            || !self.safe || self.evidence == nil || self.evidence == '') rpgExpandedReject('stress-recovery-definition');
        self.state.validate();
        if (self.endedAt != nil) { self.validateReceipt(); return 'reused'; }
        if (self.startedAt != nil)
        { rpgExpandedAttentionBinding(self.facts(),self.boundStart,'stress-rest-binding'); return 'reused'; }
        if (self.state.rest != nil) rpgExpandedReject('stress-rest-overlap');
        foreach (local prior in self.state.recoveries)
            if (prior.id == self.id) rpgExpandedReject('stress-rest-duplicate');
        self.startedAt = rpgLedger.seconds; self.boundStart = self.facts(); self.state.rest = self; self.state.bind(); return 'resolved';
    }
    settle(interrupted) { return self.settleAt(interrupted,rpgLedger.seconds); }
    settleAt(interrupted,ending)
    {
        self.state.validate();
        if (self.endedAt != nil) { self.validateReceipt(); return 'reused'; }
        if (self.startedAt == nil || self.state.rest != self) rpgExpandedReject('stress-rest-not-started');
        rpgExpandedAttentionBinding(self.facts(),self.boundStart,'stress-rest-binding');
        if (ending > rpgLedger.seconds || ending < self.startedAt || !interrupted && ending != self.startedAt+self.state.policy.recoverySeconds)
            rpgExpandedReject('stress-rest-exact-hour-required');
        local day = ending/self.state.policy.daySeconds;
        local used = self.state.recoveredOn(day);
        self.endedAt = ending; self.day = day; self.interrupted = interrupted;
        self.amount = !interrupted && self.state.balance > 0 && used < self.state.policy.dailyRecovery ? 1 : 0;
        self.state.balance -= self.amount;
        if (self.amount > 0 && self.state.balance == 0) { self.state.episode += 1; self.state.fired = []; }
        self.boundReceipt = self.receiptFacts(); self.state.recoveries = self.state.recoveries + [self];
        self.state.rest = nil; self.state.bind(); return 'resolved';
    }
    complete() { return self.settle(nil); }
    interrupt() { return self.settle(true); }
;
modify RpgExpandedProfile
    stressState = nil
    stressPendingReason()
    {
        if (self.stressState == nil) return nil;
        self.stressState.validate(); return self.stressState.pending() == nil ? nil : 'stress-decision-required';
    }
    healthAttributeModifier(context)
    { return inherited(context) + (self.stressState == nil ? 0 : self.stressState.strainPenalty()); }
    blockedReason(context)
    { local reason = self.stressPendingReason(); return reason == nil ? inherited(context) : reason; }
    stressInvoluntary(request)
    { return request != nil && (self.timedPanicAuthorization(request) || self.panicAuthorization(request)
        || self.frenzyActive() && self.frenzyManeuverReason(request) == nil); }
    healthEffortReasonFor(purpose,mentalAbility,speech,movement,authorization)
    {
        if (!holds(['rest','care','do-nothing'],purpose) && !self.stressInvoluntary(authorization))
        { local reason = self.stressPendingReason(); if (reason != nil) return reason; }
        return inherited(purpose,mentalAbility,speech,movement,authorization);
    }
    healthManeuverRequestReason(request)
    {
        if (request.kind != 'nothing' && !self.stressInvoluntary(request)) { local reason = self.stressPendingReason(); if (reason != nil) return reason; }
        return inherited(request);
    }
;
/** Explicit classification for authored actions; custom verify overrides must
 * delegate to this shared gate. Decision/rest actions name their owned object. */
modify Action
    stressRecovery = nil
    stressResolution = nil
    stressInvoluntaryRequest = nil
    verify(context)
    {
        local profile = context.actor == nil ? nil : context.actor.rpgProfile;
        if (profile != nil && profile.ofKind(RpgExpandedProfile) && profile.stressState != nil)
        {
            local state = profile.stressState; local allowed = profile.stressInvoluntary(self.stressInvoluntaryRequest);
            if (self.stressRecovery != nil) allowed = self.stressRecovery.ofKind(RpgExpandedStressRecovery) && self.stressRecovery.state == state;
            if (self.stressResolution != nil) allowed = self.stressResolution.ofKind(RpgExpandedStressResolution)
                && self.stressResolution.decision == state.pending();
            if (!allowed && profile.stressPendingReason() != nil) return verificationFailure('action.nothing',nil,nil);
        }
        return inherited(context);
    }
;

modify rpgLedger
    afterAdvance(previous)
    {
        inherited(previous);
        for (local state = firstObj(RpgExpandedStressState); state != nil; state = nextObj(state,RpgExpandedStressState))
            if (state.boundPolicy != nil && state.rest != nil)
            {
                local ending = state.rest.startedAt+state.policy.recoverySeconds;
                if (self.seconds >= ending) state.rest.settleAt(nil,ending);
            }
        return nil;
    }
;
modify RpgExpandedProfile
    afterInjuryShock(amount,result)
    {
        inherited(amount,result);
        if (amount > 0 && self.stressState != nil && self.stressState.rest != nil) self.stressState.rest.interrupt();
        return nil;
    }
;
modify Action
    check(context)
    {
        local result = inherited(context); if (result != nil) return result;
        local profile = context.actor == nil ? nil : context.actor.rpgProfile;
        if (profile != nil && profile.ofKind(RpgExpandedProfile) && profile.stressState != nil
            && profile.stressState.rest != nil && self.stressRecovery == nil && self.stressResolution == nil)
            profile.stressState.rest.interrupt();
        return nil;
    }
;

modify RpgExpandedProfile
    healthCheckReason(context)
    {
        /* These checks are passive, involuntary or care/recovery procedures.
         * Authored voluntary contexts use the default skill/action gate. */
        if (!holds(['defense','death','consciousness','major-wound','stun','poison','disease','aging',
            'fear','fear-faint-collapse','fear-faint-recovery','fear-coma-recovery','catatonia-recovery',
            'fear-seizure-health','retching-recovery','recurrent-pain-recovery','cardiac-resistance',
            'crippling-duration','pain-cry','motion','motion-hour','nausea-trigger','bleeding',
            'natural-recovery','healing','mortal-recovery','wake','first-aid','physician-care','resuscitation',
            'temperature','brain-injury','air','radiation','resistance','motion-sickness',
            'permanent-health','mortal-wound','trauma-maintenance','persistent-dressing','poison-treatment'],context.kind))
        { local reason = self.stressPendingReason(); if (reason != nil) return reason; }
        return inherited(context);
    }
;
modify RpgExpandedProfile
    directStrikeReason(request)
    { local reason = self.stressInvoluntary(request) ? nil : self.stressPendingReason(); return reason == nil ? inherited(request) : reason; }
;
modify RpgExpandedProfile
    validateFeatures() { inherited(); if (self.stressState != nil) self.stressState.validate(); return nil; }
;

modify RpgExpandedProfile fearStressModifier() { return self.stressState == nil ? 0 : self.stressState.strainPenalty(); };
