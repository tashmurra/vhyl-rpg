/* Include after the expanded foundation. Source: full-2008, B101; B110; B121. */

/** Pure signed percentage pricing, rounded toward positive infinity.
 * This validates arithmetic bounds, not modifier eligibility or effects. */
rpgExpandedSignedModifiedCost(base, percentages)
{
    rpgInteger(base, -1000000, 1000000);
    local percent = 100;
    foreach (local value in percentages) { rpgInteger(value, -1000, 1000); percent += value; }
    if (percent < 20) percent = 20;
    rpgInteger(percent, 20, 2000);
    if (base < 0) return -((-base * percent) / 100);
    return (base * percent + 99) / 100;
}

/** Pure percentage pricing for a positive-cost trait; ceiling, with an 80% floor.
 * Applicability and each modifier's actual effect require a separate definition. */
rpgExpandedModifiedCost(base, percentages)
{
    rpgInteger(base, 1, 1000000);
    return rpgExpandedSignedModifiedCost(base, percentages);
}

/** Pure self-control pricing for a negative base value; discard fractional magnitude.
 * The rating is independent of Will. This does not roll or resolve a trigger. */
rpgExpandedSelfControlCost(base, rating)
{
    rpgInteger(base, -1000000, -1);
    if (!holds([6, 9, 12, 15], rating)) rpgExpandedReject('self-control-rating');
    if (rating == 6) return base * 2;
    if (rating == 9) return -((-base * 3) / 2);
    if (rating == 15) return -((-base) / 2);
    return base;
}

/** An explicitly approved positive trait price specification.
 * This prices the trait; it does not implement modifier effects. */
class RpgExpandedTrait: RpgLiteTrait
    percentages = []
    approved = nil
    creationCost()
    {
        if (!self.approved) rpgExpandedReject('unapproved-trait');
        rpgInteger(self.points, 1, 10000); rpgInteger(self.level, 1, 100);
        return rpgExpandedModifiedCost(self.points * self.level, self.percentages);
    }
;

/** Approved negative price specification, using the shared character cost ledger.
 * Approval covers the authored price only, not completion of catalogue effects. */
class RpgExpandedDisadvantage: RpgLiteTrait
    percentages = []
    approved = nil
    selfControlRating = nil
    selfControlNumber()
    {
        if (!self.approved) rpgExpandedReject('unapproved-trait');
        if (!self.controlled) rpgExpandedReject('self-control-ineligible-trait');
        if (self.selfControlRating == nil) return 12;
        if (!holds([6,9,12,15],self.selfControlRating)) rpgExpandedReject('self-control-rating');
        return self.selfControlRating;
    }
    selfControlPreflight() { return true; }
    creationCost()
    {
        if (!self.approved) rpgExpandedReject('unapproved-trait');
        rpgInteger(self.points, -10000, -1); rpgInteger(self.level, 1, 100);
        local base = self.points * self.level;
        if (self.selfControlRating != nil)
        {
            /* B121: a rating prices only a disadvantage with a resistance procedure. */
            self.selfControlNumber();
            /* Resolve composition/rounding from source before supporting both. */
            if (self.percentages.length() != 0)
                rpgExpandedReject('self-control-modifier-combination');
            return rpgExpandedSelfControlCost(base, self.selfControlRating);
        }
        return rpgExpandedSignedModifiedCost(base, self.percentages);
    }
;

/** B143 staffing base. Above 100, only a full doubling adds another ten points. */
rpgExpandedMaintenanceBase(people)
{
    rpgInteger(people,1,1000000);
    foreach (local row in [[1,-10],[2,-20],[5,-30],[10,-40],[20,-50],[50,-60],[100,-70]])
        if (people <= row[1]) return row[2];
    local base = -70; local threshold = 200;
    while (people >= threshold) { base -= 10; threshold *= 2; }
    return base;
}

/** Pure B143 staffing/frequency price. Negative fractional points round toward zero. */
rpgExpandedMaintenanceCost(people, frequency)
{
    local base = rpgExpandedMaintenanceBase(people);
    if (frequency == 'monthly') return -((-base) / 5);
    if (frequency == 'fortnightly') return -((-base) / 3);
    if (frequency == 'weekly') return -((-base) / 2);
    if (frequency == 'alternate-days') return -((-base * 3) / 4);
    if (frequency == 'daily') return base;
    if (frequency == 'twice-daily') return base * 2;
    if (frequency == 'three-to-five-daily') return base * 3;
    if (frequency == 'constant') return base * 5;
    rpgExpandedReject('maintenance-frequency');
}

/** B56-B57 purchased invention capability; ordinary and rapid tiers are alternatives. */
class RpgExpandedInventor: RpgExpandedTrait
    id = 'inventive-capability'
    tier = 'cinematic'
    points = (tier == 'rapid' ? 50 : 25)
    creationCost()
    {
        if (!self.approved || self.id != 'inventive-capability' || self.level != 1
            || !holds(['cinematic','rapid'],self.tier) || self.percentages.length() != 0)
            rpgExpandedReject('inventor-capability-definition');
        return self.tier == 'rapid' ? 50 : 25;
    }
;

modify RpgExpandedProfile
    inventionCapabilityTier()
    {
        local found = nil;
        foreach (local trait in self.traits)
            if (trait.ofKind(RpgExpandedInventor))
            {
                trait.creationCost();
                if (found != nil) rpgExpandedReject('duplicate-inventor-capability');
                found = trait;
            }
        return found == nil || !found.active || found.mitigated ? nil : found.tier;
    }
;

/** B162-B163 behavioral quirk: a concrete recurring choice, not a passive label. */
class RpgExpandedMentalQuirk: RpgLiteTrait
    id = 'quirk'
    approved = nil
    triggerText = nil
    responseText = nil
    fearAcquisition = nil
    validateBehavior()
    {
        if (!self.approved || self.triggerText == nil || self.triggerText == ''
            || self.responseText == nil || self.responseText == '' || self.id != 'quirk' || self.level != 1)
            rpgExpandedReject('mental-quirk-behavior');
        return nil;
    }
    creationCost() { self.validateBehavior(); return -1; }
;

/** B360-B361 authored mental-quirk consequence; never grants spendable points. */
class RpgExpandedFearQuirkAcquisition: RpgExpandedFearQuirkContract
    id = nil
    eventId = nil
    profile = nil
    quirk = nil
    approved = nil
    relationEvidence = nil
    result = nil
    boundId = nil
    boundEventId = nil
    boundProfile = nil
    boundQuirk = nil
    boundEvidence = nil
    boundTriggerText = nil
    boundResponseText = nil
    assess()
    {
        if (self.id == nil || self.id == '' || self.eventId == nil || self.eventId == ''
            || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)
            || self.quirk == nil || !self.quirk.ofKind(RpgExpandedMentalQuirk)) rpgExpandedReject('fear-quirk-definition');
        local value = new RpgExpandedResult();
        if (self.result != nil)
        {
            if (self.id != self.boundId || self.eventId != self.boundEventId || self.profile != self.boundProfile
                || self.quirk != self.boundQuirk || self.relationEvidence != self.boundEvidence
                || self.quirk.triggerText != self.boundTriggerText || self.quirk.responseText != self.boundResponseText
                || !holds(self.profile.fearQuirkAcquisitions,self)) rpgExpandedReject('fear-quirk-binding');
            value.status = 'reused'; return value;
        }
        rpgExpandedValidate(self.profile); self.quirk.validateBehavior();
        if (!self.profile.creationComplete) { value.reason = 'fear-quirk-after-creation'; return value; }
        if (!self.approved || self.relationEvidence == nil || self.relationEvidence == '')
        { value.reason = 'fear-quirk-relation-required'; return value; }
        if (self.profile.dead) { value.reason = 'fear-quirk-dead'; return value; }
        if (holds(self.profile.traits,self.quirk) || self.quirk.fearAcquisition != nil)
        { value.reason = 'fear-quirk-already-owned'; return value; }
        foreach (local prior in self.profile.fearQuirkAcquisitions)
            if (prior.id == self.id || prior.eventId == self.eventId) rpgExpandedReject('fear-quirk-duplicate');
        rpgInteger(self.profile.developmentRevision,0,2147483646);
        value.points = -1; value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.boundId = self.id; self.boundEventId = self.eventId; self.boundProfile = self.profile;
        self.boundQuirk = self.quirk; self.boundEvidence = self.relationEvidence;
        self.boundTriggerText = self.quirk.triggerText; self.boundResponseText = self.quirk.responseText;
        self.profile.traits = self.profile.traits + [self.quirk]; self.quirk.fearAcquisition = self;
        self.profile.fearQuirkAcquisitions = self.profile.fearQuirkAcquisitions + [self];
        self.profile.developmentRevision += 1; value.status = 'resolved'; self.result = value; return value;
    }
;

modify RpgExpandedProfile
    fearQuirkAcquisitions = []
    quirkPortrayals = []
    quirkCountsTowardCreationLimit(trait)
    {
        if (trait.ofKind(RpgExpandedMentalQuirk) && trait.fearAcquisition != nil)
        {
            local award = trait.fearAcquisition;
            if (!award.ofKind(RpgExpandedFearQuirkAcquisition) || award.profile != self || award.quirk != trait
                || award.result == nil || !holds(self.fearQuirkAcquisitions,award)) rpgExpandedReject('fear-quirk-ownership');
            award.assess(); return nil;
        }
        return inherited(trait);
    }
    postCreationDisadvantageAllowance()
    {
        local value = inherited();
        if (self.creationComplete)
            foreach (local award in self.fearQuirkAcquisitions)
                if (holds(self.traits,award.quirk))
                {
                    award.assess();
                    if (self.quirkCountsTowardCreationLimit(award.quirk)) rpgExpandedReject('fear-quirk-limit');
                    value += 1;
                }
        return value;
    }
;

/** Explicit author adjudication of a behavioral quirk in one scene. */
class RpgExpandedQuirkPortrayal: object
    id = nil
    profile = nil
    quirk = nil
    triggerPresent = nil
    decision = nil
    observedBehavior = nil
    approved = nil
    result = nil
    boundDefinition = nil
    definition() { return [self.id,self.profile,self.quirk,self.triggerPresent,self.decision,self.observedBehavior,self.approved]; }
    assess()
    {
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)
            || self.quirk == nil || !self.quirk.ofKind(RpgExpandedMentalQuirk)) rpgExpandedReject('quirk-portrayal-definition');
        local value = new RpgExpandedResult();
        if (self.result != nil)
        {
            local current = self.definition();
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.boundDefinition[index]) rpgExpandedReject('quirk-portrayal-binding');
            if (!holds(self.profile.quirkPortrayals,self)) rpgExpandedReject('quirk-portrayal-history');
            value.status = 'reused'; return value;
        }
        self.quirk.validateBehavior();
        if (!holds(self.profile.traits,self.quirk)) { value.reason = 'quirk-portrayal-not-owned'; return value; }
        if (!self.approved || self.observedBehavior == nil || self.observedBehavior == '')
        { value.reason = 'quirk-portrayal-evidence'; return value; }
        if (self.triggerPresent ? !holds(['followed','departed'],self.decision) : self.decision != 'inapplicable')
        { value.reason = 'quirk-portrayal-decision'; return value; }
        foreach (local prior in self.profile.quirkPortrayals)
            if (prior.id == self.id) rpgExpandedReject('quirk-portrayal-duplicate');
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.boundDefinition = self.definition(); self.profile.quirkPortrayals = self.profile.quirkPortrayals + [self];
        value.status = 'resolved'; self.result = value; return value;
    }
;

/** B79 dose-resistance tiers. Levels select whole purchases, not stacking factors. */
class RpgExpandedRadiationResistance: RpgExpandedTrait
    id = 'radiation-resistance'
    creationCost()
    {
        if (!self.approved || self.id != 'radiation-resistance' || self.percentages.length() != 0)
            rpgExpandedReject('radiation-resistance-definition');
        rpgInteger(self.level,1,9); return self.level * 5;
    }
    divisor()
    {
        self.creationCost(); local values = [2,5,10,20,50,100,200,500,1000];
        return values[self.level];
    }
;

modify RpgExpandedProfile
    radiationDivisor()
    {
        local found = nil;
        foreach (local trait in self.traits)
            if (trait.id == 'radiation-resistance' || trait.ofKind(RpgExpandedRadiationResistance))
            {
                if (!trait.ofKind(RpgExpandedRadiationResistance)) rpgExpandedReject('radiation-resistance-type');
                trait.creationCost();
                if (found != nil) rpgExpandedReject('radiation-resistance-duplicate');
                found = trait;
            }
        return found == nil || !found.active || found.mitigated ? inherited() : found.divisor();
    }
;


/** B142 fixed purchase; health supplies injury and resistance effects. */
class RpgExpandedPainSensitivity: RpgExpandedDisadvantage
    id = 'low-pain-threshold'
    points = -10
    creationCost()
    {
        if (!self.approved || self.id != 'low-pain-threshold' || self.level != 1
            || self.points != -10 || self.percentages.length() != 0 || self.selfControlRating != nil)
            rpgExpandedReject('pain-sensitivity-definition');
        return -10;
    }
;

/** B138 fixed purchase. The special bleeding/treatment lifecycle remains partial. */
class RpgExpandedImpairedClotting: RpgExpandedDisadvantage
    id = 'impaired-clotting'
    points = -30
    creationCost()
    {
        if (!self.approved || self.id != 'impaired-clotting' || self.points != -30 || self.level != 1
            || self.percentages.length() != 0 || self.selfControlRating != nil)
            rpgExpandedReject('impaired-clotting-definition');
        return -30;
    }
;
modify RpgExpandedProfile
    validateFeatures()
    {
        inherited();
        if (self.level('impaired-clotting') > 0 && self.ht > 10)
            rpgExpandedReject('impaired-clotting-health-limit');
        return nil;
    }
;

/** B162 permanent open wound; buying it does not subtract HP. */
class RpgExpandedPersistentWound: RpgExpandedDisadvantage
    id = 'persistent-wound'
    points = -5
    creationCost()
    {
        if (!self.approved || self.id != 'persistent-wound' || self.points != -5 || self.level != 1
            || self.percentages.length() != 0 || self.selfControlRating != nil)
            rpgExpandedReject('persistent-wound-definition');
        return -5;
    }
;

modify RpgExpandedRules
    pointFundedSelfControl = nil
;
modify RpgExpandedProfile
    selfControlTriggers = []
;
/** B121 one authored occurrence and its resulting obligation, not a reroll loop. */
class RpgExpandedSelfControlTrigger: RpgLiteObligation
    id = nil
    buySuccess = nil
    modifier = 0
    giveIn = nil
    evidence = nil
    result = nil
    boundDefinition = nil
    stressRelation = nil
    intrusiveReplayContent = nil
    intrusiveReplayOccurrence = nil
    boundIntrusiveReplayOccurrence = nil
    phantomVoiceOccurrence = nil
    boundPhantomVoiceOccurrence = nil
    definition() { return [self.id,self.profile,self.trait,self.trigger,self.modifier,self.giveIn,self.evidence,self.buySuccess,self.stressRelation,self.intrusiveReplayContent]; }
    effectiveModifier() { return self.modifier; }
    newResult() { return new RpgExpandedResult(); }
    afterControlResolution(value) { return nil; }
    intrusiveReplayRequest()
    {
        local occurrence = new RpgExpandedIntrusiveReplayOccurrence();
        occurrence.id = 'self-control:' + self.id; occurrence.profile = self.profile; occurrence.stressor = self;
        occurrence.approved = true; occurrence.evidence = self.evidence; occurrence.content = self.intrusiveReplayContent;
        return occurrence;
    }
    phantomVoiceRequest()
    {
        local occurrence = new RpgExpandedPhantomVoiceOccurrence();
        occurrence.id = 'self-control:' + self.id; occurrence.profile = self.profile; occurrence.stressor = self;
        occurrence.approved = true; occurrence.evidence = self.evidence; return occurrence;
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)
            || self.trait == nil || !self.trait.ofKind(RpgExpandedDisadvantage))
            rpgExpandedReject('self-control-trigger-definition');
        local value = self.newResult();
        if (self.result != nil)
        {
            local current = self.definition();
            if (current.length() != self.boundDefinition.length()) rpgExpandedReject('self-control-trigger-binding');
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.boundDefinition[index]) rpgExpandedReject('self-control-trigger-binding');
            if (!holds(self.profile.selfControlTriggers,self)) rpgExpandedReject('self-control-trigger-history');
            if (self.phantomVoiceOccurrence != self.boundPhantomVoiceOccurrence) rpgExpandedReject('self-control-voices-binding');
            if (self.phantomVoiceOccurrence != nil)
            {
                self.profile.validatePhantomVoiceOccurrence(self.phantomVoiceOccurrence);
                if (self.phantomVoiceOccurrence.stressor != self) rpgExpandedReject('self-control-voices-binding');
            }
            if (self.intrusiveReplayOccurrence != self.boundIntrusiveReplayOccurrence) rpgExpandedReject('self-control-replay-binding');
            if (self.intrusiveReplayOccurrence != nil)
            {
                self.intrusiveReplayOccurrence.validateReceipt();
                if (self.intrusiveReplayOccurrence.profile != self.profile || self.intrusiveReplayOccurrence.stressor != self)
                    rpgExpandedReject('self-control-replay-owner');
            }
            value.status = 'reused'; value.check = self.check; value.points = self.result.points; return value;
        }
        if (!holds(self.profile.traits,self.trait) || !self.trait.controlled || !self.trait.active)
            rpgExpandedReject('self-control-trigger-trait');
        self.trait.validateDirectControl();
        if (self.trigger == nil || self.evidence == nil || self.evidence == '')
        { value.reason = 'self-control-trigger-evidence'; return value; }
        foreach (local prior in self.profile.selfControlTriggers)
            if (prior.id == self.id || prior.trait == self.trait && prior.trigger == self.trigger)
                rpgExpandedReject('self-control-trigger-duplicate');
        if ((self.profile.phantomVoiceSeverity() > 0 || self.profile.intrusiveReplayTrait() != nil) && !self.giveIn && !self.buySuccess
            && !holds(['stress-related','unrelated'],self.stressRelation))
        { value.reason = 'self-control-stress-classification'; return value; }
        rpgInteger(self.modifier,-100,100);
        local base = self.trait.selfControlNumber();
        if (self.buySuccess)
        {
            if (self.giveIn) { value.reason = 'self-control-conflicting-choice'; return value; }
            if (self.profile.rules == nil || !self.profile.rules.ofKind(RpgExpandedRules)
                || !self.profile.rules.pointFundedSelfControl)
            { value.reason = 'self-control-point-policy'; return value; }
            value.reason = self.profile.developmentSpendingReason(); if (value.reason != nil) return value;
            rpgInteger(self.profile.earnedPoints,0,1000000);
            rpgInteger(self.profile.unspentPoints,0,self.profile.earnedPoints);
            rpgInteger(self.profile.developmentRevision,0,2147483646);
            if (self.profile.unspentPoints < 1) { value.reason = 'rpg.insufficient-points'; return value; }
            value.points = 1;
        }
        if (!self.buySuccess && !self.giveIn && base + self.effectiveModifier() - (self.profile.sleepPenalty ? 2 : 0)
            + self.profile.healthSelfControlModifier(self.trait) < 3)
        { value.reason = 'self-control-trigger-score'; return value; }
        if (self.stressRelation == 'stress-related' && !self.giveIn && !self.buySuccess && self.profile.phantomVoiceSeverity() > 0)
        {
            local voices = self.phantomVoiceRequest().assess();
            if (voices.status != 'ready') { value.reason = voices.reason; return value; }
        }
        if (self.stressRelation == 'stress-related' && !self.giveIn && !self.buySuccess && self.profile.intrusiveReplayTrait() != nil)
        {
            local replay = self.intrusiveReplayRequest().assess();
            if (replay.status != 'ready') { value.reason = replay.reason; return value; }
        }
        if (self.intrusiveReplayOccurrence != nil || self.boundIntrusiveReplayOccurrence != nil)
            rpgExpandedReject('self-control-replay-uncommitted');
        value.status = 'ready'; return value;
    }
    resolve()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        if (self.buySuccess)
        {
            self.profile.unspentPoints -= 1; self.profile.developmentRevision += 1;
            value.check = new RpgResult(); value.check.status = 'resolved';
            value.check.achieved = true; value.check.outcome = 'automatic';
        }
        else value.check = rpgLiteSelfControlCore(self.profile,self.trait,self.effectiveModifier(),self.giveIn);
        if (value.check.status != 'resolved') rpgExpandedReject('self-control-trigger-changed');
        self.check = value.check; self.active = !self.check.achieved;
        self.boundDefinition = self.definition(); self.profile.selfControlTriggers = self.profile.selfControlTriggers + [self];
        value.status = 'resolved'; self.result = value; self.afterControlResolution(value);
        if (self.stressRelation == 'stress-related' && value.check.roll != nil && !value.check.achieved
            && self.profile.phantomVoiceSeverity() > 0)
        {
            local occurrence = self.phantomVoiceRequest();
            local voices = occurrence.resolve();
            if (voices.status != 'resolved') rpgExpandedReject('self-control-phantom-voices-changed');
            self.phantomVoiceOccurrence = occurrence; self.boundPhantomVoiceOccurrence = occurrence;
        }
        if (self.stressRelation == 'stress-related' && value.check.roll != nil && !value.check.achieved
            && self.profile.intrusiveReplayTrait() != nil)
        {
            local occurrence = self.intrusiveReplayRequest(); local replay = occurrence.resolve();
            if (replay.status != 'resolved') rpgExpandedReject('self-control-replay-changed');
            self.intrusiveReplayOccurrence = occurrence; self.boundIntrusiveReplayOccurrence = occurrence;
        }
        return value;
    }
    begin(modifier,giveIn)
    {
        self.modifier = modifier; self.giveIn = giveIn; self.resolve(); return self.active;
    }
    permits(action) { return self.result != nil && inherited(action); }
;

/** B159 truthfulness; existing shared scoring supplies its permanent skill penalties. */
class RpgExpandedTruthfulness: RpgExpandedDisadvantage
    templatePurchaseKind = 'expanded-truthfulness'
    id = 'truthfulness'
    points = -5
    controlled = true
    validateDefinition()
    {
        if (self.id != 'truthfulness' || self.points != -5 || self.level != 1 || !self.controlled
            || self.percentages.length() != 0) rpgExpandedReject('truthfulness-definition');
        return nil;
    }
    creationCost() { self.validateDefinition(); return inherited(); }
    selfControlNumber() { self.validateDefinition(); return inherited(); }
;
class RpgExpandedTruthfulnessResult: RpgExpandedResult
    communicationKind = nil
    statement = nil
;
/** The author names only the relevant truth and proposed falsehood for this occurrence. */
class RpgExpandedTruthfulnessTrigger: RpgExpandedSelfControlTrigger
    communication = nil
    validateStatementReceipt(receipt)
    {
        self.assess();
        if (self.result == nil || receipt != self.communication || receipt.source != self
            || receipt.speaker != self.profile || receipt.statement != self.result.statement
            || receipt.kind != self.result.communicationKind)
            rpgExpandedReject('truthfulness-statement-binding');
        local expectedKind = self.check.achieved
            ? (self.mode == 'omission' ? 'withheld' : 'falsehood')
            : (self.failureChoice == 'truth' ? 'disclosed-truth' : 'obvious-falsehood');
        local expectedStatement = expectedKind == 'withheld' ? nil
            : expectedKind == 'disclosed-truth' ? self.truth : self.falsehood;
        if (receipt.kind != expectedKind || receipt.statement != expectedStatement)
            rpgExpandedReject('truthfulness-statement-binding');
        return nil;
    }
    mode = 'omission'
    truth = nil
    falsehood = nil
    failureChoice = 'truth'
    definition() { return inherited() + [self.mode,self.truth,self.falsehood,self.failureChoice]; }
    effectiveModifier() { return inherited() - (self.mode == 'falsehood' ? 5 : 0); }
    newResult() { return new RpgExpandedTruthfulnessResult(); }
    assess()
    {
        local value = inherited(); if (value.status != 'ready') return value;
        if (!self.trait.ofKind(RpgExpandedTruthfulness)) rpgExpandedReject('truthfulness-trigger-trait');
        if (!holds(['omission','falsehood'],self.mode) || !holds(['truth','obvious-lie'],self.failureChoice)
            || self.mode == 'omission' && self.failureChoice != 'truth')
            rpgExpandedReject('truthfulness-communication-mode');
        if (self.truth == nil || self.mode == 'falsehood' && self.falsehood == nil)
        { value.status = 'blocked'; value.reason = 'truthfulness-authored-statements'; }
        return value;
    }
    resolve()
    {
        local value = inherited();
        if (value.status == 'reused') return self.result;
        if (value.status != 'resolved') return value;
        if (self.check.achieved)
        {
            value.communicationKind = self.mode == 'omission' ? 'withheld' : 'falsehood';
            value.statement = self.mode == 'omission' ? nil : self.falsehood;
        }
        else
        {
            value.communicationKind = self.failureChoice == 'truth' ? 'disclosed-truth' : 'obvious-falsehood';
            value.statement = self.failureChoice == 'truth' ? self.truth : self.falsehood;
        }
        local receipt = new RpgExpandedStatementReceipt(); receipt.source = self; receipt.speaker = self.profile;
        receipt.statement = value.statement; receipt.kind = value.communicationKind; self.communication = receipt;
        return value;
    }
;

/** B121/B159: preserve the purchased rating and the concrete behavior type. */
modify rpgExpandedTemplateTraits
    rated(id, level, scope, rating)
    {
        if (id != 'truthfulness') rpgExpandedReject('template-rated-trait-unavailable');
        if (!holds([6,9,12,15],rating)) rpgExpandedReject('self-control-rating');
        local trait = new RpgExpandedTruthfulness(); trait.labelId = id;
        trait.level = level; trait.scope = scope; trait.approved = true;
        trait.selfControlRating = rating; trait.creationCost(); return trait;
    }
;

/** B129: a rated investigative compulsion; warnings do not remove its trigger. */
class RpgExpandedCuriosity: RpgExpandedDisadvantage
    id = 'curious'
    points = -5
    controlled = true
    templatePurchaseKind = 'expanded-curiosity'
    validateDefinition()
    {
        if (self.id != 'curious' || self.points != -5 || self.level != 1 || !self.controlled
            || self.percentages.length() != 0) rpgExpandedReject('curiosity-definition');
        return nil;
    }
    creationCost() { self.validateDefinition(); return inherited(); }
    selfControlNumber() { self.validateDefinition(); return inherited(); }
;

/** Authored concrete investigative alternatives for one interesting situation.
 * Call complete only after the ordinary action has committed in the same transaction. */
class RpgExpandedCuriosityTrigger: RpgExpandedSelfControlTrigger
    subject = nil
    interesting = nil
    investigationActions = []
    completedAction = nil
    completionEvidence = nil
    completedAt = nil
    definition()
    { return inherited() + [self.subject,self.interesting,self.investigationActions.length()] + self.investigationActions; }
    assess()
    {
        local value = inherited();
        if (value.status != 'ready') return value;
        if (!self.trait.ofKind(RpgExpandedCuriosity)) rpgExpandedReject('curiosity-trigger-trait');
        if (self.subject == nil || !self.interesting || self.investigationActions.length() == 0)
        { value.status = 'blocked'; value.reason = 'curiosity-investigation-definition'; return value; }
        local seen = [];
        foreach (local action in self.investigationActions)
        {
            if (action == nil || holds(seen,action)) rpgExpandedReject('curiosity-investigation-actions');
            seen = seen + [action];
        }
        return value;
    }
    permits(action)
    {
        if (self.result == nil) return nil;
        self.assess();
        return !self.active || holds(self.investigationActions,action);
    }
    complete(action,evidence)
    {
        local value = new RpgExpandedResult();
        if (self.result == nil) { value.reason = 'curiosity-unresolved'; return value; }
        self.assess();
        if (self.completedAt != nil)
        {
            if (self.completedAction != action || self.completionEvidence != evidence || self.active)
                rpgExpandedReject('curiosity-completion-binding');
            value.status = 'reused'; return value;
        }
        if (!self.active) { value.reason = 'curiosity-no-obligation'; return value; }
        if (!holds(self.investigationActions,action) || evidence == nil || evidence == '')
        { value.reason = 'curiosity-completion-evidence'; return value; }
        self.completedAction = action; self.completionEvidence = evidence;
        self.completedAt = rpgLedger.seconds; self.active = nil;
        value.status = 'resolved'; return value;
    }
;

modify rpgExpandedTemplateTraits
    rated(id, level, scope, rating)
    {
        if (id != 'curious') return inherited(id,level,scope,rating);
        if (!holds([6,9,12,15],rating)) rpgExpandedReject('self-control-rating');
        local trait = new RpgExpandedCuriosity(); trait.labelId = id;
        trait.level = level; trait.scope = scope; trait.approved = true;
        trait.selfControlRating = rating; trait.creationCost(); return trait;
    }
;

/** B129: purchased avoidance of physical danger. */
class RpgExpandedDangerAvoidance: RpgExpandedDisadvantage
    id = 'cowardice'
    points = -10
    controlled = true
    templatePurchaseKind = 'expanded-danger-avoidance'
    validateDefinition()
    {
        if (self.id != 'cowardice' || self.points != -10 || self.level != 1 || !self.controlled
            || self.percentages.length() != 0) rpgExpandedReject('danger-avoidance-definition');
        return nil;
    }
    creationCost() { self.validateDefinition(); return inherited(); }
    selfControlNumber() { self.validateDefinition(); return inherited(); }
    fearPenalty() { return (18 - self.selfControlNumber()) / 3; }
;
modify RpgExpandedProfile
    physicalDangerFearPenalty()
    {
        local found = nil;
        foreach (local trait in self.traits)
            if (trait.ofKind(RpgExpandedDangerAvoidance))
            {
                if (found != nil) rpgExpandedReject('duplicate-danger-avoidance');
                found = trait; trait.creationCost();
            }
        return found == nil ? inherited() : !found.active || found.mitigated ? 0 : found.fearPenalty();
    }
;
/** One proposed risk. The author identifies risky actions and any greater threat. */
class RpgExpandedDangerAvoidanceTrigger: RpgExpandedSelfControlTrigger
    physicalDanger = nil
    risksDeath = nil
    riskyActions = []
    greaterDanger = nil
    greaterDangerEvidence = nil
    definition()
    { return inherited() + [self.physicalDanger,self.risksDeath,self.greaterDanger,self.greaterDangerEvidence,
        self.riskyActions.length()] + self.riskyActions; }
    effectiveModifier() { return inherited() - (self.risksDeath ? 5 : 0); }
    assess()
    {
        local value = inherited(); if (value.status != 'ready') return value;
        if (!self.trait.ofKind(RpgExpandedDangerAvoidance)) rpgExpandedReject('danger-avoidance-trigger-trait');
        if (!self.physicalDanger || self.riskyActions.length() == 0)
        { value.status = 'blocked'; value.reason = 'danger-avoidance-risk-definition'; return value; }
        if (self.greaterDanger && (self.greaterDangerEvidence == nil || self.greaterDangerEvidence == ''))
        { value.status = 'blocked'; value.reason = 'danger-avoidance-greater-threat'; return value; }
        local seen = [];
        foreach (local action in self.riskyActions)
        {
            if (action == nil || holds(seen,action)) rpgExpandedReject('danger-avoidance-risk-actions');
            seen = seen + [action];
        }
        return value;
    }
    permits(action)
    {
        if (self.result == nil) return nil;
        self.assess();
        return !self.active || !holds(self.riskyActions,action) || self.greaterDanger;
    }
;
modify rpgExpandedTemplateTraits
    rated(id, level, scope, rating)
    {
        if (id != 'cowardice') return inherited(id,level,scope,rating);
        if (!holds([6,9,12,15],rating)) rpgExpandedReject('self-control-rating');
        local trait = new RpgExpandedDangerAvoidance(); trait.labelId = id;
        trait.level = level; trait.scope = scope; trait.approved = true;
        trait.selfControlRating = rating; trait.creationCost(); return trait;
    }
;

/** B93 cinematic training permission; purchased skills remain separate. */
class RpgExpandedMartialTraining: RpgExpandedTrait
    id = 'advanced-martial-training'
    points = 30
    prerequisiteEvidence = nil
    creationCost()
    {
        if (!self.approved || self.id != 'advanced-martial-training' || self.level != 1
            || self.percentages.length() != 0 || self.prerequisiteEvidence == nil || self.prerequisiteEvidence == '')
            rpgExpandedReject('martial-training-definition');
        return 30;
    }
;
modify RpgExpandedProfile
    martialParryDivisor()
    {
        local found = nil;
        foreach (local trait in self.traits)
            if (trait.ofKind(RpgExpandedMartialTraining))
            {
                trait.creationCost();
                if (found != nil) rpgExpandedReject('duplicate-martial-training');
                found = trait;
            }
        return found != nil && found.active && !found.mitigated ? 2 : 1;
    }
;

/** B89 fixed-price enhanced jumping; distance consumer is in exploration. */
class RpgExpandedEnhancedJump: RpgExpandedTrait
    id = 'enhanced-jump'
    points = 10
    creationCost()
    {
        if (!self.approved || self.id != 'enhanced-jump' || self.percentages.length() != 0)
            rpgExpandedReject('enhanced-jump-definition');
        rpgInteger(self.level,1,100); return self.level * 10;
    }
;
modify RpgExpandedProfile
    enhancedJumpLevels()
    {
        local found = nil;
        foreach (local trait in self.traits)
            if (trait.ofKind(RpgExpandedEnhancedJump))
            {
                trait.creationCost();
                if (found != nil) rpgExpandedReject('duplicate-enhanced-jump');
                found = trait;
            }
        return found == nil || !found.active || found.mitigated ? 0 : found.level;
    }
;

/** B154 ordinary social inhibition: three fixed tiers, with no unimplemented modifiers. */
class RpgExpandedSocialInhibition: RpgExpandedDisadvantage
    id = 'social-inhibition'
    creationCost()
    {
        if (!self.approved || self.id != 'social-inhibition' || self.percentages.length() != 0
            || self.selfControlRating != nil || self.controlled) rpgExpandedReject('social-inhibition-definition');
        rpgInteger(self.level,1,3); return [-5,-10,-20][self.level];
    }
;
rpgExpandedSocialInhibitionApplies(skill)
{
    if (skill == nil || !skill.ofKind(RpgLiteSkill)) return nil;
    return skill.requiresSocialInteraction || holds(['acting','carousing','diplomacy','fast-talk','intimidation',
        'leadership','merchant','panhandling','performance','politics','public-speaking','savoir-faire',
        'sex-appeal','streetwise','teaching'],skill.id);
}
modify RpgExpandedProfile
    socialInhibitionPenalty()
    {
        local found = nil;
        foreach (local trait in self.traits)
            if (trait.ofKind(RpgExpandedSocialInhibition))
            {
                trait.creationCost(); if (found != nil) rpgExpandedReject('duplicate-social-inhibition'); found = trait;
            }
        return found == nil || !found.active || found.mitigated ? 0 : [1,2,4][found.level];
    }
    socialSkillLearningReason(skill)
    {
        local reason = inherited(skill); if (reason != nil) return reason;
        return self.socialInhibitionPenalty() == 4 && rpgExpandedSocialInhibitionApplies(skill)
            ? 'social-inhibition-learning-prohibited' : nil;
    }
;
modify RpgLiteContext
    socialTraitModifier(profile)
    {
        local amount = inherited(profile);
        if (!profile.ofKind(RpgExpandedProfile) || !rpgExpandedSocialInhibitionApplies(self.skill)) return amount;
        local penalty = profile.socialInhibitionPenalty();
        if (penalty == 4)
            foreach (local training in profile.skills)
                if (training.skill == self.skill && training.points > 0)
                    rpgExpandedReject('social-inhibition-trained-adapter-required');
        return amount - penalty;
    }
;

/** B142 ordinary emotional-understanding deficit, without modified variants. */
class RpgExpandedEmotionalUnderstandingDeficit: RpgExpandedDisadvantage
    id = 'emotional-understanding-deficit'
    points = -20
    creationCost()
    {
        if (!self.approved || self.id != 'emotional-understanding-deficit' || self.points != -20 || self.level != 1
            || self.percentages.length() != 0 || self.selfControlRating != nil || self.controlled)
            rpgExpandedReject('emotional-understanding-definition');
        return -20;
    }
;
rpgExpandedEmotionalUnderstandingApplies(skill)
{
    if (skill == nil || !skill.ofKind(RpgLiteSkill)) return nil;
    return skill.requiresEmotionalUnderstanding || holds(['acting','carousing','criminology','detect-lies','diplomacy',
        'enthrallment','captivate','persuade','suggest','sway-emotions','fast-talk','interrogation','leadership',
        'merchant','politics','psychology','savoir-faire','sex-appeal','sociology','streetwise'],skill.id);
}
modify RpgExpandedProfile
    emotionalUnderstandingPenalty()
    {
        local found = nil;
        foreach (local trait in self.traits)
            if (trait.ofKind(RpgExpandedEmotionalUnderstandingDeficit))
            {
                trait.creationCost(); if (found != nil) rpgExpandedReject('duplicate-emotional-understanding'); found = trait;
            }
        if (found == nil) return 0;
        foreach (local trait in self.traits)
            if (trait.ofKind(RpgLiteTrait) && holds(['empathy','callous','callousness','oblivious','emotional-obliviousness'],trait.id))
                rpgExpandedReject('emotional-understanding-incompatible');
        return !found.active || found.mitigated ? 0 : 3;
    }
    validateFeatures()
    { inherited(); self.emotionalUnderstandingPenalty(); return nil; }
;
modify RpgLiteContext
    socialTraitModifier(profile)
    {
        local amount = inherited(profile);
        if (!profile.ofKind(RpgExpandedProfile) || !rpgExpandedEmotionalUnderstandingApplies(self.skill)) return amount;
        return amount - profile.emotionalUnderstandingPenalty();
    }
;

/** B140-B141 ordinary loss of pleasure, with fixed cost and skill effects. */
class RpgExpandedPleasureLoss: RpgExpandedDisadvantage
    id = 'pleasure-loss'
    points = -15
    creationCost()
    {
        if (!self.approved || self.id != 'pleasure-loss' || self.points != -15 || self.level != 1
            || self.percentages.length() != 0 || self.selfControlRating != nil || self.controlled)
            rpgExpandedReject('pleasure-loss-definition');
        return -15;
    }
;
modify RpgExpandedProfile
    pleasureLossActive()
    {
        local found = nil;
        foreach (local trait in self.traits)
            if (trait.ofKind(RpgExpandedPleasureLoss))
            {
                trait.creationCost(); if (found != nil) rpgExpandedReject('duplicate-pleasure-loss'); found = trait;
            }
        return found != nil && found.active && !found.mitigated;
    }
    validateFeatures() { inherited(); self.pleasureLossActive(); return nil; }
;
modify RpgLiteContext
    socialTraitModifier(profile)
    {
        local amount = inherited(profile);
        if (profile.ofKind(RpgExpandedProfile) && self.skill != nil && self.skill.ofKind(RpgLiteSkill)
            && holds(['carousing','connoisseur','erotic-art','gambling'],self.skill.id) && profile.pleasureLossActive()) amount -= 3;
        return amount;
    }
;

/** B146 reduced understanding of social motivation, distinct from absent emotional understanding. */
class RpgExpandedEmotionalObliviousness: RpgExpandedDisadvantage
    id = 'emotional-obliviousness'
    points = -5
    creationCost()
    {
        if (!self.approved || self.id != 'emotional-obliviousness' || self.points != -5 || self.level != 1
            || self.percentages.length() != 0 || self.selfControlRating != nil || self.controlled)
            rpgExpandedReject('emotional-obliviousness-definition');
        return -5;
    }
;
rpgExpandedOrdinaryInfluenceSkill(skill)
{
    return skill != nil && skill.ofKind(RpgLiteSkill)
        && holds(['diplomacy','fast-talk','intimidation','savoir-faire','sex-appeal','streetwise'],skill.id);
}
modify RpgExpandedProfile
    emotionalObliviousnessActive()
    {
        local found = nil;
        foreach (local trait in self.traits)
            if (trait.ofKind(RpgExpandedEmotionalObliviousness))
            {
                trait.creationCost(); if (found != nil) rpgExpandedReject('duplicate-emotional-obliviousness'); found = trait;
            }
        if (found != nil) self.emotionalUnderstandingPenalty();
        return found != nil && found.active && !found.mitigated;
    }
    validateFeatures() { inherited(); self.emotionalObliviousnessActive(); return nil; }
;
modify RpgLiteContext
    socialTraitModifier(profile)
    {
        local amount = inherited(profile);
        if (profile.ofKind(RpgExpandedProfile) && rpgExpandedOrdinaryInfluenceSkill(self.skill)
            && profile.emotionalObliviousnessActive()) amount -= 1;
        return amount;
    }
    influenceResistanceModifier(target)
    {
        local amount = inherited(target);
        if (!target.ofKind(RpgExpandedProfile) || !rpgExpandedOrdinaryInfluenceSkill(self.skill)
            || !target.emotionalObliviousnessActive()) return amount;
        target.emotionalUnderstandingPenalty();
        local effective = target.will + amount - 1 + (self.skill.id == 'intimidation' ? target.level('fearlessness') : 0);
        if (effective < 3) rpgExpandedReject('influence-low-resistance-adapter-required');
        return amount - 1;
    }
;

/** B125 ordinary callousness; situational facts belong to the author. */
class RpgExpandedCallousness: RpgExpandedDisadvantage
    id = 'callousness'
    points = -5
    creationCost()
    {
        if (!self.approved || self.id != 'callousness' || self.points != -5 || self.level != 1
            || self.percentages.length() != 0 || self.selfControlRating != nil || self.controlled)
            rpgExpandedReject('callousness-definition');
        return -5;
    }
;
modify RpgExpandedProfile
    callousnessActive()
    {
        local found = nil;
        foreach (local trait in self.traits)
            if (trait.ofKind(RpgExpandedCallousness))
            {
                trait.creationCost(); if (found != nil) rpgExpandedReject('duplicate-callousness'); found = trait;
            }
        if (found != nil) self.emotionalUnderstandingPenalty();
        return found != nil && found.active && !found.mitigated;
    }
    validateFeatures() { inherited(); self.callousnessActive(); return nil; }
;
modify RpgLiteContext
    socialTraitModifier(profile)
    {
        local amount = inherited(profile);
        if (profile.ofKind(RpgExpandedProfile) && self.skill != nil && self.skill.ofKind(RpgLiteSkill)
            && self.skill.id == 'teaching' && profile.callousnessActive()) amount -= 3;
        return amount;
    }
;
/** Use for a specific interaction; a victim flag applies to this target only. */
class RpgExpandedCallousnessContext: RpgLiteContext
    subject = nil
    target = nil
    helpfulPsychology = nil
    pastVictim = nil
    coercive = nil
    approved = nil
    evidence = nil
    socialTraitModifier(profile)
    {
        if (profile != self.subject || self.subject == nil || !self.subject.ofKind(RpgExpandedProfile)
            || self.target == nil || !self.target.ofKind(RpgLiteProfile) || self.target == self.subject
            || self.skill == nil || !self.skill.ofKind(RpgLiteSkill)) rpgExpandedReject('callousness-participants');
        if (!self.approved || self.evidence == nil || self.evidence == '') rpgExpandedReject('callousness-facts-required');
        if (self.helpfulPsychology && self.skill.id != 'psychology') rpgExpandedReject('callousness-helpful-skill');
        if (self.coercive && !holds(['interrogation','intimidation'],self.skill.id)) rpgExpandedReject('callousness-coercive-skill');
        local amount = inherited(profile);
        if (!profile.callousnessActive()) return amount;
        /* One -3 penalty when several descriptions of the same roll apply. */
        if (self.skill.id != 'teaching' && (self.helpfulPsychology || self.pastVictim)) amount -= 3;
        if (self.coercive) amount += 1;
        return amount;
    }
;

/** B125 learning bar. Starting abilities remain valid and usable. */
class RpgExpandedLearningBar: RpgExpandedDisadvantage
    id = 'learning-bar'
    points = -30
    creationCost()
    {
        if (!self.approved || self.id != 'learning-bar' || self.points != -30 || self.level != 1
            || self.percentages.length() != 0 || self.selfControlRating != nil || self.controlled)
            rpgExpandedReject('learning-bar-definition');
        return -30;
    }
;
modify RpgDevelopment
    /** Authored classification for a new trait; never infer it from its name. */
    expandedTraitNature = nil
    expandedTraitEvidence = nil
;
modify RpgExpandedProfile
    learningBarActive()
    {
        local found = nil;
        foreach (local trait in self.traits)
            if (trait.ofKind(RpgExpandedLearningBar))
            {
                trait.creationCost(); if (found != nil) rpgExpandedReject('duplicate-learning-bar'); found = trait;
            }
        return found != nil && found.active && !found.mitigated;
    }
    validateFeatures() { inherited(); self.learningBarActive(); return nil; }
    learningAcquisitionReason(kind)
    {
        local reason = inherited(kind); if (reason != nil) return reason;
        if (self.learningBarActive() && holds(['skill','technique','familiarity'],kind)) return 'learning-bar-acquisition';
        return nil;
    }
    developmentOfferReason(offer)
    {
        local reason = inherited(offer); if (reason != nil || !self.learningBarActive()) return reason;
        if (offer.kind == 'skill') return 'learning-bar-acquisition';
        if (offer.kind == 'attribute')
        {
            if (offer.attribute == rpgDX || offer.attribute == rpgIQ) return 'learning-bar-attribute';
            if (offer.attribute != rpgST && offer.attribute != rpgHT) return 'learning-bar-secondary-adjudication-required';
        }
        if (offer.kind == 'trait')
        {
            if (!holds(['mental','physical'],offer.expandedTraitNature)
                || offer.expandedTraitEvidence == nil || offer.expandedTraitEvidence == '')
                return 'learning-bar-trait-classification-required';
            if (offer.expandedTraitNature == 'mental') return 'learning-bar-mental-trait';
        }
        return nil;
    }
;

/** B125 distinguish articulated speech from all vocal sound. */
class RpgExpandedSpeechLimitation: RpgExpandedDisadvantage
    id = 'speech-limitation'
    points = -15
    total = nil
    creationCost()
    {
        if (!self.approved || self.id != 'speech-limitation' || self.level != 1
            || self.percentages.length() != 0 || self.selfControlRating != nil || self.controlled
            || self.points != (self.total ? -25 : -15)) rpgExpandedReject('speech-limitation-definition');
        return self.total ? -25 : -15;
    }
;
modify RpgExpandedProfile
    speechLimitationLevel()
    {
        local found = nil;
        foreach (local trait in self.traits)
            if (trait.ofKind(RpgExpandedSpeechLimitation))
            {
                trait.creationCost(); if (found != nil) rpgExpandedReject('duplicate-speech-limitation'); found = trait;
            }
        if (found == nil) return 0;
        foreach (local trait in self.traits)
            if (trait != found && trait.ofKind(RpgLiteTrait)
                && (trait.id == 'stuttering' || found.total && (trait.voiceRelated
                    || holds(['voice','mimicry','disturbing-voice'],trait.id))))
                rpgExpandedReject('speech-limitation-incompatible');
        return !found.active || found.mitigated ? 0 : found.total ? 2 : 1;
    }
    validateFeatures() { inherited(); self.speechLimitationLevel(); return nil; }
    healthEffortReasonFor(purpose,mentalAbility,speech,movement,authorization)
    {
        if ((purpose == 'talk' || speech) && self.speechLimitationLevel() > 0)
            return 'articulated-speech-unavailable';
        return inherited(purpose,mentalAbility,speech,movement,authorization);
    }
    healthCheckReason(context)
    {
        local limitation = self.speechLimitationLevel();
        if (context.requiresSpeech && limitation > 0) return 'articulated-speech-unavailable';
        if (context.requiresVocalization && limitation == 2) return 'vocalization-unavailable';
        return inherited(context);
    }
;

modify RpgExpandedProfile
    communicationStudyEligible() { return self.speechLimitationLevel() == 2; }
;

/** B125 assistance compulsion, with the shared four-tier self-control pricing. */
class RpgExpandedCompelledAid: RpgExpandedDisadvantage
    id = 'compelled-aid'
    points = -15
    controlled = true
    validateDefinition()
    {
        if (self.id != 'compelled-aid' || self.points != -15 || self.level != 1 || !self.controlled
            || self.percentages.length() != 0) rpgExpandedReject('compelled-aid-definition');
        return nil;
    }
    creationCost() { self.validateDefinition(); return inherited(); }
    selfControlNumber() { self.validateDefinition(); return inherited(); }
;
class RpgExpandedAidTrigger: RpgExpandedSelfControlTrigger
    recipient = nil
    assistance = nil
    aidAvailable = nil
    shouldResist = nil
    approved = nil
    decision = nil
    definition()
    {
        return inherited() + [self.recipient,self.assistance,self.aidAvailable,self.shouldResist,self.approved];
    }
    assess()
    {
        if (self.trait == nil || !self.trait.ofKind(RpgExpandedCompelledAid)
            || self.recipient == nil || !self.recipient.ofKind(RpgLiteProfile) || self.recipient == self.profile)
            rpgExpandedReject('compelled-aid-participants');
        local value = inherited(); if (value.status != 'ready') return value;
        if (!self.approved || !self.aidAvailable || !self.shouldResist || self.assistance == nil || self.assistance == '')
        { value.status = 'blocked'; value.reason = 'compelled-aid-opportunity-required'; return value; }
        if (self.trait.mitigated)
        { value.status = 'blocked'; value.reason = 'compelled-aid-mitigated'; return value; }
        return value;
    }
;
/** Record the player's response; offering help does not spend the promised resources. */
class RpgExpandedAidDecision: object
    source = nil
    choice = nil
    result = nil
    boundChoice = nil
    boundSource = nil
    assess()
    {
        if (self.source == nil || !self.source.ofKind(RpgExpandedAidTrigger)
            || !holds(['offer','decline'],self.choice)) rpgExpandedReject('compelled-aid-choice');
        local value = new RpgExpandedResult();
        if (self.result != nil)
        {
            if (self.source != self.boundSource || self.choice != self.boundChoice || self.source.decision != self)
                rpgExpandedReject('compelled-aid-choice-binding');
            self.source.assess(); value.status = 'reused'; return value;
        }
        if (self.source.result == nil) { value.reason = 'compelled-aid-unresolved'; return value; }
        self.source.assess();
        if (self.source.decision != nil) { value.reason = 'compelled-aid-already-decided'; return value; }
        if (self.source.active && self.choice != 'offer') { value.reason = 'compelled-aid-offer-required'; return value; }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status == 'reused') return self.result;
        if (value.status != 'ready') return value;
        self.boundSource = self.source; self.boundChoice = self.choice; self.source.decision = self;
        self.source.active = nil; value.reason = self.choice == 'offer' ? 'assistance-offered' : 'assistance-declined';
        value.status = 'resolved'; self.result = value; return value;
    }
;

/** B126 fictional initiative constraint; not a clinical simulation. */
class RpgExpandedLowMotivation: RpgExpandedDisadvantage
    id = 'low-motivation'
    points = -15
    controlled = true
    validateDefinition()
    {
        if (self.id != 'low-motivation' || self.points != -15 || self.level != 1 || !self.controlled
            || self.percentages.length() != 0) rpgExpandedReject('low-motivation-definition');
        return nil;
    }
    creationCost() { self.validateDefinition(); return inherited(); }
    selfControlNumber() { self.validateDefinition(); return inherited(); }
;
class RpgExpandedMotivationTrigger: RpgExpandedSelfControlTrigger
    choices = []
    leastEffort = nil
    minimumNecessitiesOnly = nil
    approved = nil
    decision = nil
    definition() { return inherited() + [self.leastEffort,self.minimumNecessitiesOnly,self.approved] + self.choices; }
    assess()
    {
        if (self.trait == nil || !self.trait.ofKind(RpgExpandedLowMotivation))
            rpgExpandedReject('motivation-trait');
        rpgInteger(self.choices.length(),1,100);
        local seen = [];
        foreach (local choice in self.choices)
        {
            if (dataType(choice) != TypeSString || choice == '' || holds(seen,choice)) rpgExpandedReject('motivation-choices');
            seen = seen + [choice];
        }
        if (!holds(self.choices,self.leastEffort)) rpgExpandedReject('motivation-least-effort');
        local value = inherited(); if (value.status != 'ready') return value;
        if (!self.approved) { value.status = 'blocked'; value.reason = 'motivation-authorship-required'; return value; }
        if (self.trait.mitigated || self.minimumNecessitiesOnly && self.choices.length() == 1)
        { value.status = 'blocked'; value.reason = 'motivation-no-trigger'; return value; }
        return value;
    }
;
class RpgExpandedMotivationDecision: object
    source = nil
    choice = nil
    result = nil
    boundSource = nil
    boundChoice = nil
    assess()
    {
        if (self.source == nil || !self.source.ofKind(RpgExpandedMotivationTrigger)
            || !holds(self.source.choices,self.choice)) rpgExpandedReject('motivation-decision');
        local value = new RpgExpandedResult();
        if (self.result != nil)
        {
            if (self.source != self.boundSource || self.choice != self.boundChoice || self.source.decision != self)
                rpgExpandedReject('motivation-decision-binding');
            self.source.assess(); value.status = 'reused'; return value;
        }
        if (self.source.result == nil) { value.reason = 'motivation-unresolved'; return value; }
        self.source.assess();
        if (self.source.decision != nil) { value.reason = 'motivation-already-decided'; return value; }
        if (self.source.active && self.choice != self.source.leastEffort)
        { value.reason = 'motivation-least-effort-required'; return value; }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status == 'reused') return self.result;
        if (value.status != 'ready') return value;
        self.boundSource = self.source; self.boundChoice = self.choice;
        self.source.decision = self; self.source.active = nil;
        value.status = 'resolved'; value.reason = self.choice; self.result = value; return value;
    }
;

/** B126 recurrent-pain price: multiply both factors before dropping fractions. */
class RpgExpandedRecurrentPain: RpgExpandedDisadvantage
    id = 'recurrent-pain'
    severity = 1
    intervalHours = 2
    frequency = 9
    points = (-5 * severity)
    validateDefinition()
    {
        if (!self.approved || self.id != 'recurrent-pain' || self.level != 1 || self.controlled
            || self.selfControlRating != nil || self.percentages.length() != 0
            || !holds([1,2,3],self.severity) || !holds([1,2,4,8],self.intervalHours)
            || !holds([6,9,12,15],self.frequency) || self.points != -5 * self.severity)
            rpgExpandedReject('recurrent-pain-definition');
        return nil;
    }
    creationCost()
    {
        self.validateDefinition();
        local intervalTwice = self.intervalHours == 1 ? 1 : self.intervalHours == 2 ? 2 : self.intervalHours == 4 ? 3 : 4;
        local frequencyTwice = self.frequency == 6 ? 1 : self.frequency == 9 ? 2 : self.frequency == 12 ? 4 : 6;
        return -(5 * self.severity * intervalTwice * frequencyTwice / 4);
    }
    awakePenalty() { self.validateDefinition(); return -2 * self.severity; }
    intervalSeconds() { self.validateDefinition(); return self.intervalHours * 3600; }
    appears(roll)
    {
        self.validateDefinition(); rpgInteger(roll,3,18);
        return roll <= self.frequency;
    }
;

modify RpgExpandedRecurrentPain
    recurrentPainDefinition() { return true; }
;

/** B126 preference for company; reaction bonuses belong to the observer. */
class RpgExpandedCompanionship: RpgExpandedDisadvantage
    id = 'companionship'
    points = -5
    creationCost()
    {
        if (!self.approved || self.id != 'companionship' || !holds([1,2],self.level) || self.points != -5
            || self.percentages.length() != 0 || self.controlled || self.selfControlRating != nil)
            rpgExpandedReject('companionship-definition');
        return -5 * self.level;
    }
;
modify RpgExpandedProfile
    companionshipLevel()
    {
        local found = nil;
        foreach (local trait in self.traits)
            if (trait.ofKind(RpgExpandedCompanionship))
            {
                trait.creationCost(); if (found != nil) rpgExpandedReject('duplicate-companionship'); found = trait;
            }
        return found == nil || !found.active || found.mitigated ? 0 : found.level;
    }
    validateFeatures() { inherited(); self.companionshipLevel(); return nil; }
;
/** The authored group includes the subject; a one-person group is alone. */
class RpgExpandedCompany: object
    subject = nil
    members = []
    approved = nil
    evidence = nil
    definition() { return [self.subject,self.approved,self.evidence] + self.members; }
    penalty(profile)
    {
        if (self.subject != profile || !holds(self.members,profile)) rpgExpandedReject('company-subject');
        if (!self.approved || self.evidence == nil || self.evidence == '') rpgExpandedReject('company-evidence');
        local seen = [];
        foreach (local member in self.members)
        {
            if (member == nil || !member.ofKind(RpgLiteProfile) || holds(seen,member)) rpgExpandedReject('company-members');
            seen = seen + [member];
        }
        local level = profile.companionshipLevel();
        if (level == 0) return 0;
        if (self.members.length() == 1) return -level;
        return level == 2 && self.members.length() <= 4 ? -1 : 0;
    }
;
modify RpgLiteContext
    socialTraitModifier(profile)
    {
        local amount = inherited(profile);
        if (!profile.ofKind(RpgExpandedProfile) || profile.companionshipLevel() == 0
            || self.skill == nil || self.controllingAttribute() != rpgIQ) return amount;
        if (self.company == nil || !self.company.ofKind(RpgExpandedCompany)) rpgExpandedReject('company-context-required');
        return amount + self.company.penalty(profile);
    }
;

modify RpgExpandedCompelledAid
    templatePurchaseKind = 'expanded-compelled-aid'
;
modify RpgExpandedLowMotivation
    templatePurchaseKind = 'expanded-low-motivation'
;
modify rpgExpandedTemplateTraits
    rated(id,level,scope,rating)
    {
        if (!holds(['compelled-aid','low-motivation'],id)) return inherited(id,level,scope,rating);
        if (!holds([6,9,12,15],rating)) rpgExpandedReject('self-control-rating');
        local trait = id == 'compelled-aid' ? new RpgExpandedCompelledAid() : new RpgExpandedLowMotivation();
        trait.labelId = id; trait.level = level; trait.scope = scope;
        trait.approved = true; trait.selfControlRating = rating; trait.creationCost(); return trait;
    }
;


/** B90-B91 fixed catalogue additions. Each purchase needs campaign approval. */
rpgExpandedTalentCatalogue: object
    ids = ['artificer','outdoorsman','smooth-operator','animal-aptitude','commercial-aptitude',
        'artistic-aptitude','plant-aptitude','medical-aptitude','numerical-aptitude','musical-aptitude']
    price(id)
    {
        if (holds(['animal-aptitude','artistic-aptitude','plant-aptitude','musical-aptitude'],id)) return 5;
        if (holds(['artificer','outdoorsman','commercial-aptitude','medical-aptitude','numerical-aptitude'],id)) return 10;
        if (id == 'smooth-operator') return 15;
        rpgExpandedReject('catalogue-talent-id');
    }
;
class RpgExpandedCatalogueTalent: RpgLiteTrait
    approved = nil
    templatePurchaseKind = 'expanded-catalogue-talent'
    creationCost()
    {
        if (!self.approved) rpgExpandedReject('unapproved-trait');
        if (self.scope != nil || self.controlled || self.skills.length() != 0)
            rpgExpandedReject('catalogue-talent-definition');
        rpgInteger(self.level,1,4);
        local price = rpgExpandedTalentCatalogue.price(self.id);
        if (self.points != price) rpgExpandedReject('catalogue-talent-price');
        return price * self.level;
    }
;
rpgExpandedMakeCatalogueTalent(id,level,approved)
{
    local trait = new RpgExpandedCatalogueTalent(); trait.id = id; trait.labelId = id;
    trait.level = level; trait.points = rpgExpandedTalentCatalogue.price(id); trait.approved = approved;
    trait.creationCost(); return trait;
}

/** B90-B91 author-approved related skills, fixed for this owned purchase. */
class RpgExpandedCustomTalent: RpgLiteTrait
    templatePurchaseKind = 'expanded-custom-talent'
    owner = nil
    boundOwner = nil
    boundId = nil
    skillIds = []
    boundSkillIds = []
    approved = nil
    evidence = nil
    boundEvidence = nil
    creationCost()
    {
        if (!self.approved || self.evidence == nil || self.evidence == '') rpgExpandedReject('custom-talent-approval');
        if (self.owner == nil || !self.owner.ofKind(RpgExpandedProfile) || self.owner != self.boundOwner)
            rpgExpandedReject('custom-talent-owner');
        if (self.id == nil || self.id == '' || self.id != self.boundId || self.labelId != self.id
            || holds(rpgExpandedTalentCatalogue.ids,self.id)) rpgExpandedReject('custom-talent-id');
        if (self.skillIds != self.boundSkillIds || self.evidence != self.boundEvidence)
            rpgExpandedReject('custom-talent-binding');
        if (self.scope != nil || self.controlled || self.skills.length() != 0)
            rpgExpandedReject('custom-talent-definition');
        local count = self.skillIds.length(); rpgInteger(count,1,1000); rpgInteger(self.level,1,4);
        local seen = [];
        foreach (local id in self.skillIds)
        {
            if (id == nil || id == '' || holds(seen,id)) rpgExpandedReject('custom-talent-skills');
            seen = seen + [id];
        }
        local price = count <= 6 ? 5 : count <= 12 ? 10 : 15;
        if (self.points != price) rpgExpandedReject('custom-talent-price');
        return price * self.level;
    }
    validateOwner(profile)
    {
        self.creationCost();
        if (self.owner != profile) rpgExpandedReject('custom-talent-owner');
        for (local other = firstObj(RpgLiteProfile); other != nil; other = nextObj(other,RpgLiteProfile))
            if (other != profile && holds(other.traits,self)) rpgExpandedReject('custom-talent-owner');
        return nil;
    }
;
rpgExpandedMakeCustomTalent(profile,id,skillIds,level,approved,evidence)
{
    local trait = new RpgExpandedCustomTalent();
    trait.owner = profile; trait.boundOwner = profile; trait.id = id; trait.boundId = id; trait.labelId = id;
    trait.skillIds = skillIds; trait.boundSkillIds = skillIds; trait.level = level;
    trait.approved = approved; trait.evidence = evidence; trait.boundEvidence = evidence;
    trait.points = skillIds.length() <= 6 ? 5 : skillIds.length() <= 12 ? 10 : 15;
    trait.creationCost(); return trait;
}

/** B89-B91 shared talent membership for learning and demonstrated reactions. */
modify RpgExpandedProfile
    talentIds()
    {
        local ids = rpgExpandedTalentCatalogue.ids;
        foreach (local trait in self.traits)
            if (trait.ofKind(RpgExpandedCustomTalent))
            {
                trait.validateOwner(self);
                if (!holds(ids,trait.id)) ids = ids + [trait.id];
            }
        return ids;
    }
    validateFeatures()
    {
        inherited();
        foreach (local talentId in self.talentIds())
        {
            local count = 0;
            foreach (local trait in self.traits)
                if (trait.id == talentId)
                {
                    if (!trait.ofKind(RpgLiteTrait)) rpgExpandedReject('catalogue-talent-definition');
                    rpgInteger(trait.level,1,4);
                    if (trait.ofKind(RpgExpandedCatalogueTalent)) trait.creationCost();
                    count += 1;
                }
            if (count > 1) rpgExpandedReject('duplicate-check-talent');
        }
        return nil;
    }
    catalogueTalentApplies(id,skill)
    {
        if (!inherited(id,skill)) return nil;
        if (id != 'musical-aptitude' || skill.studyIdentity() != 'group-performance') return true;
        return skill.studySpecialty() == 'conducting';
    }
    catalogueTalentSkills(id)
    {
        if (id == 'animal-aptitude') return ['animal-handling','falconry','packing','riding','teamster','veterinary'];
        if (id == 'commercial-aptitude') return ['accounting','administration','economics','finance','gambling','market-analysis','merchant','propaganda'];
        if (id == 'artistic-aptitude') return ['artist','jeweler','leatherworking','photography','sewing'];
        if (id == 'plant-aptitude') return ['biology','farming','gardening','herb-lore','naturalist'];
        if (id == 'medical-aptitude') return ['diagnosis','esoteric-medicine','first-aid','pharmacy','physician','physiology','psychology','surgery','veterinary'];
        if (id == 'numerical-aptitude') return ['accounting','astronomy','cryptography','engineer','finance','market-analysis','mathematics','physics'];
        if (id == 'musical-aptitude') return ['group-performance','musical-composition','musical-influence','musical-instrument','singing'];
        if (id == 'artificer') return ['armoury','carpentry','electrician','electronics-repair','engineer','machinist','masonry','mechanic','smith'];
        if (id == 'outdoorsman') return ['camouflage','fishing','mimicry','naturalist','navigation','survival','tracking'];
        if (id == 'smooth-operator') return ['acting','carousing','detect-lies','diplomacy','fast-talk','intimidation','leadership',
            'panhandling','politics','public-speaking','savoir-faire','sex-appeal','streetwise'];
        foreach (local trait in self.traits)
            if (trait.ofKind(RpgExpandedCustomTalent) && trait.id == id)
            { trait.validateOwner(self); return trait.skillIds; }
        return inherited(id);
    }
    catalogueTalentCheckModifier(skill)
    {
        return self.talentBonusInSkillScore() ? 0 : self.catalogueTalentSkillModifier(skill);
    }
    catalogueTalentSkillModifier(skill)
    {
        if (!skill.ofKind(RpgLiteSkill)) return 0;
        local id = skill.studyIdentity(); local bonus = 0;
        foreach (local talentId in self.talentIds())
            if (self.catalogueTalentApplies(talentId,skill))
            {
                local count = 0;
                foreach (local trait in self.traits)
                    if (trait.id == talentId)
                    {
                        count += 1; rpgInteger(trait.level,1,4);
                        if (trait.ofKind(RpgExpandedCatalogueTalent)) trait.creationCost();
                        if (trait.active && !trait.mitigated) bonus += trait.level;
                    }
                if (count > 1) rpgExpandedReject('duplicate-check-talent');
            }
        return bonus;
    }
    studyTimePercent(skill)
    {
        local percent = inherited(skill);
        if (skill == nil || !skill.ofKind(RpgLiteSkill)) return percent;
        local id = skill.studyIdentity(); local level = 0;
        foreach (local talentId in self.talentIds())
            if (self.catalogueTalentApplies(talentId,skill))
            {
                local count = 0;
                foreach (local trait in self.traits)
                    if (trait.id == talentId)
                    {
                        count += 1; rpgInteger(trait.level,1,4);
                        if (trait.ofKind(RpgExpandedCatalogueTalent)) trait.creationCost();
                        if (trait.active && !trait.mitigated && trait.level > level) level = trait.level;
                    }
                if (count > 1) rpgExpandedReject('duplicate-study-talent');
            }
        local talentPercent = 100 - level * 10;
        return talentPercent < percent ? talentPercent : percent;
    }
;

/** Template rows are authored purchase permission; copies preserve purchase kind. */
modify rpgExpandedTemplateTraits
    plain(id,level,scope)
    {
        if (!holds(['animal-aptitude','commercial-aptitude','artistic-aptitude','plant-aptitude',
            'medical-aptitude','numerical-aptitude','musical-aptitude'],id)) return inherited(id,level,scope);
        if (scope != nil) rpgExpandedReject('catalogue-talent-definition');
        return rpgExpandedMakeCatalogueTalent(id,level,true);
    }
    copy(trait)
    {
        if (trait.ofKind(RpgExpandedCustomTalent)) rpgExpandedReject('custom-talent-template-unimplemented');
        if (!trait.ofKind(RpgExpandedCatalogueTalent)) return inherited(trait);
        trait.creationCost();
        if (trait.labelId != trait.id) rpgExpandedReject('template-trait-copy-definition');
        return rpgExpandedMakeCatalogueTalent(trait.id,trait.level,trait.approved);
    }
;

/** B77-B78 uniform ambient pressure protection, not crushing attack armor. */
class RpgExpandedPressureSupport: RpgLiteTrait
    id = 'pressure-support'
    labelId = 'pressure-support'
    points = 5
    approved = nil
    templatePurchaseKind = 'expanded-pressure-support'
    creationCost()
    {
        if (!self.approved) rpgExpandedReject('unapproved-trait');
        rpgInteger(self.level,1,3);
        if (self.id != 'pressure-support' || self.points != 5 || self.scope != nil
            || self.controlled || self.skills.length() != 0) rpgExpandedReject('pressure-support-definition');
        return self.level * 5;
    }
;
modify RpgExpandedProfile
    pressureSupportLevel()
    {
        local count = 0; local level = 0;
        foreach (local trait in self.traits)
            if (trait.id == 'pressure-support')
            {
                if (!trait.ofKind(RpgExpandedPressureSupport)) rpgExpandedReject('pressure-support-definition');
                trait.creationCost(); count += 1;
                if (trait.active && !trait.mitigated) level = trait.level;
            }
        if (count > 1) rpgExpandedReject('pressure-support-duplicate');
        return level;
    }
    validateFeatures() { inherited(); self.pressureSupportLevel(); return nil; }
;
modify rpgExpandedTemplateTraits
    plain(id,level,scope)
    {
        if (id != 'pressure-support') return inherited(id,level,scope);
        local trait = new RpgExpandedPressureSupport(); trait.level = level; trait.scope = scope; trait.approved = true;
        trait.creationCost(); return trait;
    }
    copy(trait)
    {
        if (!trait.ofKind(RpgExpandedPressureSupport)) return inherited(trait);
        trait.creationCost(); return self.plain(trait.id,trait.level,trait.scope);
    }
;

/** B156 susceptibility; scope records the required campaign relevance. */
class RpgExpandedFreeFallSusceptibility: RpgLiteTrait
    id = 'free-fall-susceptibility'
    labelId = 'free-fall-susceptibility'
    points = -10
    approved = nil
    templatePurchaseKind = 'expanded-free-fall-susceptibility'
    creationCost()
    {
        if (!self.approved) rpgExpandedReject('unapproved-trait');
        if (self.id != 'free-fall-susceptibility' || self.points != -10 || self.level != 1
            || self.controlled || self.skills.length() != 0) rpgExpandedReject('free-fall-susceptibility-definition');
        if (self.scope != 'regular-space-travel') rpgExpandedReject('free-fall-susceptibility-campaign');
        return -10;
    }
;
modify RpgExpandedProfile
    freeFallSusceptible(activeOnly)
    {
        local count = 0; local present = nil;
        foreach (local trait in self.traits)
            if (trait.id == 'free-fall-susceptibility')
            {
                if (!trait.ofKind(RpgExpandedFreeFallSusceptibility)) rpgExpandedReject('free-fall-susceptibility-definition');
                trait.creationCost(); count += 1;
                if (!activeOnly || trait.active && !trait.mitigated) present = true;
            }
        if (count > 1) rpgExpandedReject('free-fall-susceptibility-duplicate');
        return present;
    }
    physiologySkillLearningReason(skill)
    {
        if (self.freeFallSusceptible(nil) && skill.ofKind(RpgLiteSkill) && skill.studyIdentity() == 'free-fall')
            return 'free-fall-susceptibility-learning';
        return inherited(skill);
    }
    skillScore(skill)
    {
        if (self.freeFallSusceptible(nil) && skill.ofKind(RpgLiteSkill) && skill.studyIdentity() == 'free-fall')
            foreach (local training in self.skills)
                if (training.points > 0 && training.skill.ofKind(RpgLiteSkill) && training.skill.studyIdentity() == 'free-fall')
                    rpgExpandedReject('free-fall-susceptibility-learning');
        return inherited(skill);
    }
    validateFeatures()
    {
        inherited();
        if (self.freeFallSusceptible(nil))
            foreach (local training in self.skills)
                if (training.points > 0 && training.skill.ofKind(RpgLiteSkill) && training.skill.studyIdentity() == 'free-fall')
                    rpgExpandedReject('free-fall-susceptibility-learning');
        return nil;
    }
;
modify rpgExpandedTemplateTraits
    plain(id,level,scope)
    {
        if (id != 'free-fall-susceptibility') return inherited(id,level,scope);
        local trait = new RpgExpandedFreeFallSusceptibility(); trait.level = level; trait.scope = scope; trait.approved = true;
        trait.creationCost(); return trait;
    }
    copy(trait)
    {
        if (!trait.ofKind(RpgExpandedFreeFallSusceptibility)) return inherited(trait);
        trait.creationCost(); return self.plain(trait.id,trait.level,trait.scope);
    }
;

/** B34 two-tier orientation sense; route/world answers are separate author facts. */
class RpgExpandedOrientationSense: RpgLiteTrait
    id = 'orientation-sense'
    labelId = 'orientation-sense'
    points = 5
    signalDependent = nil
    approved = nil
    templatePurchaseKind = 'expanded-orientation-sense'
    creationCost()
    {
        if (!self.approved) rpgExpandedReject('unapproved-trait');
        rpgInteger(self.level,1,2);
        if (self.id != 'orientation-sense' || self.points != 5 || self.scope != nil || self.controlled || self.skills.length() != 0)
            rpgExpandedReject('orientation-sense-definition');
        return self.level * (self.signalDependent ? 4 : 5);
    }
;
modify RpgExpandedProfile
    orientationEnvironment = nil
    orientationSenseLevel()
    {
        local count = 0; local level = 0;
        foreach (local trait in self.traits)
            if (trait.id == 'orientation-sense')
            {
                if (!trait.ofKind(RpgExpandedOrientationSense)) rpgExpandedReject('orientation-sense-definition');
                trait.creationCost(); count += 1;
                if (trait.active && !trait.mitigated) level = trait.level;
            }
        if (count > 1) rpgExpandedReject('orientation-sense-duplicate');
        return level;
    }
    orientationSkillModifier(skill)
    {
        local level = self.effectiveOrientationSenseLevel();
        if (level == 0 || skill == nil || !skill.ofKind(RpgLiteSkill)) return 0;
        if (!holds(['local','deep-space','cross-dimensional'],self.orientationEnvironment)) rpgExpandedReject('orientation-environment-required');
        if (self.orientationEnvironment == 'cross-dimensional' || level == 1 && self.orientationEnvironment == 'deep-space') return 0;
        local id = skill.studyIdentity(); local specialty = skill.studySpecialty();
        if (id == 'body-sense' || id == 'navigation' && holds(['air','land','sea'],specialty)) return 3;
        if (level == 2)
        {
            if (id == 'piloting') return 1;
            if (holds(['aerobatics','free-fall'],id) || id == 'navigation' && holds(['space','hyperspace'],specialty)) return 2;
        }
        return 0;
    }
    catalogueSkillModifier(skill) { return inherited(skill) + self.orientationSkillModifier(skill); }
    validateFeatures() { inherited(); self.orientationSenseLevel(); return nil; }
;
modify rpgExpandedTemplateTraits
    plain(id,level,scope)
    {
        if (id != 'orientation-sense') return inherited(id,level,scope);
        local trait = new RpgExpandedOrientationSense(); trait.level = level; trait.scope = scope; trait.approved = true;
        trait.creationCost(); return trait;
    }
    copy(trait)
    {
        if (!trait.ofKind(RpgExpandedOrientationSense)) return inherited(trait);
        trait.creationCost(); local copy = self.plain(trait.id,trait.level,trait.scope);
        copy.signalDependent = trait.signalDependent; copy.creationCost(); return copy;
    }
;


/** B35 explicit current navigation-network facts, preserved as immutable reports. */
class RpgExpandedOrientationSignalReport: object
    id = nil
    profile = nil
    frame = nil
    network = nil
    available = nil
    compatible = nil
    jammed = nil
    approved = nil
    evidence = nil
    recordedAt = nil
    boundDefinition = nil
    definition() { return [self.id,self.profile,self.frame,self.network,self.available,self.compatible,self.jammed,self.approved,self.evidence,self.recordedAt]; }
    validateReceipt()
    {
        if (self.recordedAt == nil || !holds(self.profile.orientationSignalReports,self)) rpgExpandedReject('orientation-signal-owner');
        local current = self.definition();
        for (local i = 1; i <= current.length(); i += 1)
            if (current[i] != self.boundDefinition[i]) rpgExpandedReject('orientation-signal-binding');
        return nil;
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile))
            rpgExpandedReject('orientation-signal-definition');
        local value = new RpgExpandedResult();
        if (self.recordedAt != nil) { self.validateReceipt(); value.status = 'reused'; return value; }
        if (!self.approved || self.evidence == nil || self.evidence == '' || self.frame == nil
            || self.frame != self.profile.orientationFrame || self.available && self.network == nil)
        { value.reason = 'orientation-signal-world-facts'; return value; }
        foreach (local prior in self.profile.orientationSignalReports)
        { prior.validateReceipt(); if (prior.id == self.id) rpgExpandedReject('orientation-signal-duplicate'); }
        value.status = 'ready'; return value;
    }
    record()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.recordedAt = rpgLedger.seconds; self.boundDefinition = self.definition();
        self.profile.orientationSignalReports = self.profile.orientationSignalReports + [self];
        self.profile.orientationSignal = self; value.status = 'resolved'; return value;
    }
    functionsFor(profile)
    {
        self.validateReceipt();
        if (self.profile != profile || profile.orientationSignal != self) rpgExpandedReject('orientation-signal-current-owner');
        if (self.recordedAt != rpgLedger.seconds || self.frame != profile.orientationFrame)
            rpgExpandedReject('orientation-signal-observation-stale');
        return self.available && self.compatible && !self.jammed;
    }
;
modify RpgExpandedProfile
    orientationFrame = nil
    orientationSignal = nil
    orientationSignalReports = []
    effectiveOrientationSenseLevel()
    {
        local level = self.orientationSenseLevel(); if (level == 0) return 0;
        foreach (local trait in self.traits)
            if (trait.id == 'orientation-sense' && trait.signalDependent)
            {
                if (self.orientationSignal == nil || !self.orientationSignal.ofKind(RpgExpandedOrientationSignalReport))
                    rpgExpandedReject('orientation-signal-report-required');
                if (!self.orientationSignal.functionsFor(self)) return 0;
            }
        return level;
    }
;
modify RpgExpandedOrientationSense
    templatePurchaseOptions() { return self.signalDependent ? ['signal-dependent'] : []; }
;
modify rpgExpandedTemplateTraits
    configured(id,level,scope,options)
    {
        if (id != 'orientation-sense' || options.length() == 0) return inherited(id,level,scope,options);
        if (options.length() != 1 || options[1] != 'signal-dependent') rpgExpandedReject('template-trait-options-unavailable');
        local trait = self.plain(id,level,scope); trait.signalDependent = true; trait.creationCost(); return trait;
    }
;

/** B146: fixed purchase; observer-specific reactions live in the social module. */
class RpgExpandedHumorlessness: RpgLiteTrait
    id = 'humorlessness'
    labelId = 'humorlessness'
    points = -10
    approved = nil
    templatePurchaseKind = 'expanded-humorlessness'
    creationCost()
    {
        if (!self.approved || self.id != 'humorlessness' || self.points != -10 || self.level != 1
            || self.scope != nil || self.controlled || self.skills.length() != 0) rpgExpandedReject('humorlessness-definition');
        return -10;
    }
;
modify RpgExpandedProfile
    humorlessnessActive()
    {
        local count = 0; local active = nil;
        foreach (local trait in self.traits)
            if (trait.id == 'humorlessness')
            {
                if (!trait.ofKind(RpgExpandedHumorlessness)) rpgExpandedReject('humorlessness-definition');
                trait.creationCost(); count += 1; if (trait.active && !trait.mitigated) active = true;
            }
        if (count > 1) rpgExpandedReject('humorlessness-duplicate'); return active;
    }
    validateFeatures() { inherited(); self.humorlessnessActive(); return nil; }
;
modify rpgExpandedTemplateTraits
    plain(id,level,scope)
    {
        if (id != 'humorlessness') return inherited(id,level,scope);
        local trait = new RpgExpandedHumorlessness(); trait.level = level; trait.scope = scope; trait.approved = true;
        trait.creationCost(); return trait;
    }
    copy(trait)
    {
        if (!trait.ofKind(RpgExpandedHumorlessness)) return inherited(trait);
        trait.creationCost(); return self.plain(trait.id,trait.level,trait.scope);
    }
;

/** B148: fixed cost; reactions require authored observer roles and knowledge. */
class RpgExpandedPervasiveDistrust: RpgLiteTrait
    id = 'pervasive-distrust'
    labelId = 'pervasive-distrust'
    points = -10
    approved = nil
    templatePurchaseKind = 'expanded-pervasive-distrust'
    creationCost()
    {
        if (!self.approved || self.id != 'pervasive-distrust' || self.points != -10 || self.level != 1
            || self.scope != nil || self.controlled || self.skills.length() != 0) rpgExpandedReject('pervasive-distrust-definition');
        return -10;
    }
;
modify RpgExpandedProfile
    pervasiveDistrustActive()
    {
        local count = 0; local active = nil;
        foreach (local trait in self.traits)
            if (trait.id == 'pervasive-distrust')
            {
                if (!trait.ofKind(RpgExpandedPervasiveDistrust)) rpgExpandedReject('pervasive-distrust-definition');
                trait.creationCost(); count += 1; if (trait.active && !trait.mitigated) active = true;
            }
        if (count > 1) rpgExpandedReject('pervasive-distrust-duplicate'); return active;
    }
    validateFeatures() { inherited(); self.pervasiveDistrustActive(); return nil; }
;
modify rpgExpandedTemplateTraits
    plain(id,level,scope)
    {
        if (id != 'pervasive-distrust') return inherited(id,level,scope);
        local trait = new RpgExpandedPervasiveDistrust(); trait.level = level; trait.scope = scope; trait.approved = true;
        trait.creationCost(); return trait;
    }
    copy(trait)
    {
        if (!trait.ofKind(RpgExpandedPervasiveDistrust)) return inherited(trait);
        trait.creationCost(); return self.plain(trait.id,trait.level,trait.scope);
    }
;

/** B148 severity accounting; episode effects require concrete authored context. */
class RpgExpandedPhantomVoices: RpgLiteTrait
    id = 'phantom-voices'
    labelId = 'phantom-voices'
    points = -5
    approved = nil
    templatePurchaseKind = 'expanded-phantom-voices'
    creationCost()
    {
        rpgInteger(self.level,1,3);
        if (!self.approved || self.id != 'phantom-voices' || self.points != -5 * self.level
            || self.scope != nil || self.controlled || self.skills.length() != 0) rpgExpandedReject('phantom-voices-definition');
        return self.points;
    }
;
modify RpgExpandedProfile
    phantomVoiceOccurrences = []
    phantomVoiceSeverity()
    {
        local count = 0; local severity = 0;
        foreach (local trait in self.traits)
            if (trait.id == 'phantom-voices')
            {
                if (!trait.ofKind(RpgExpandedPhantomVoices)) rpgExpandedReject('phantom-voices-definition');
                trait.creationCost(); count += 1; if (trait.active && !trait.mitigated) severity = trait.level;
            }
        if (count > 1) rpgExpandedReject('phantom-voices-duplicate'); return severity;
    }
    validateFeatures() { inherited(); self.phantomVoiceSeverity(); return nil; }
;
modify rpgExpandedTemplateTraits
    plain(id,level,scope)
    {
        if (id != 'phantom-voices') return inherited(id,level,scope);
        local trait = new RpgExpandedPhantomVoices(); trait.level = level; trait.points = -5 * level;
        trait.scope = scope; trait.approved = true; trait.creationCost(); return trait;
    }
    copy(trait)
    {
        if (!trait.ofKind(RpgExpandedPhantomVoices)) return inherited(trait);
        trait.creationCost(); return self.plain(trait.id,trait.level,trait.scope);
    }
;
class RpgExpandedPhantomVoiceResult: RpgExpandedResult
    occurred = nil
    severity = 0
    roll = nil
;
/** One optional author-selected stress check. No invented automatic duration. */
class RpgExpandedPhantomVoiceOccurrence: object
    id = nil
    profile = nil
    stressor = nil
    approved = nil
    evidence = nil
    result = nil
    recordedAt = nil
    boundDefinition = nil
    boundResult = nil
    endedAt = nil
    endEvidence = nil
    boundEnding = nil
    definition() { return [self.id,self.profile,self.stressor,self.approved,self.evidence,self.recordedAt]; }
    validateReceipt()
    {
        if (self.result == nil || !holds(self.profile.phantomVoiceOccurrences,self)) rpgExpandedReject('phantom-voices-history');
        if (self.result.roll != self.boundResult[1] || self.result.severity != self.boundResult[2]
            || self.result.occurred != self.boundResult[3]) rpgExpandedReject('phantom-voices-result-binding');
        local facts = self.definition();
        for (local index = 1; index <= facts.length(); index += 1)
            if (facts[index] != self.boundDefinition[index]) rpgExpandedReject('phantom-voices-binding');
        if (self.boundEnding != nil && (self.endedAt != self.boundEnding[1] || self.endEvidence != self.boundEnding[2]))
            rpgExpandedReject('phantom-voices-ending-binding');
        if (self.boundEnding == nil && (self.endedAt != nil || self.endEvidence != nil))
            rpgExpandedReject('phantom-voices-ending-binding');
        return nil;
    }
    assess()
    {
        if (self.profile == nil || !self.profile.ofKind(RpgExpandedProfile) || self.id == nil || self.id == '')
            rpgExpandedReject('phantom-voices-occurrence');
        local value = new RpgExpandedPhantomVoiceResult();
        if (self.result != nil)
        {
            self.validateReceipt(); value.status = 'reused'; value.occurred = self.result.occurred;
            value.severity = self.result.severity; value.roll = self.result.roll; return value;
        }
        if (self.recordedAt != nil || self.endedAt != nil || self.endEvidence != nil || self.boundDefinition != nil || self.boundEnding != nil || self.boundResult != nil)
            rpgExpandedReject('phantom-voices-uncommitted-state');
        if (!self.approved || self.stressor == nil || self.evidence == nil || self.evidence == '')
        { value.reason = 'phantom-voices-stress-facts'; return value; }
        value.severity = self.profile.phantomVoiceSeverity();
        if (value.severity == 0) { value.reason = 'phantom-voices-inactive'; return value; }
        foreach (local prior in self.profile.phantomVoiceOccurrences)
        {
            prior.validateReceipt();
            if (prior.id == self.id || prior.stressor == self.stressor) rpgExpandedReject('phantom-voices-duplicate-occurrence');
        }
        value.status = 'ready'; return value;
    }
    resolve()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        value.roll = rpgRandom.roll(); value.occurred = value.roll <= 6; value.status = 'resolved';
        self.recordedAt = self.profile.timeElapsed; self.boundDefinition = self.definition(); self.result = value;
        self.boundResult = [value.roll,value.severity,value.occurred];
        self.profile.phantomVoiceOccurrences = self.profile.phantomVoiceOccurrences + [self]; return value;
    }
    active()
    {
        self.validateReceipt(); return self.result.occurred && self.endedAt == nil;
    }
    end(confirmed,evidence)
    {
        self.validateReceipt(); local value = new RpgExpandedPhantomVoiceResult();
        if (!self.result.occurred) { value.reason = 'phantom-voices-no-episode'; return value; }
        if (self.endedAt != nil) { value.status = 'reused'; return value; }
        if (!confirmed || evidence == nil || evidence == '') { value.reason = 'phantom-voices-ending-facts'; return value; }
        self.endedAt = self.profile.timeElapsed; self.endEvidence = evidence; self.boundEnding = [self.endedAt,evidence];
        value.status = 'resolved'; return value;
    }
;

modify RpgExpandedProfile
    validatePhantomVoiceOccurrence(occurrence)
    {
        if (occurrence == nil || !occurrence.ofKind(RpgExpandedPhantomVoiceOccurrence) || occurrence.profile != self)
            rpgExpandedReject('phantom-voices-observation-owner');
        return occurrence.validateReceipt();
    }
;

/* The owned trigger supplies stress classification and the follow-up receipt. */
modify RpgExpandedProfile
    validateDirectSelfControl(giveIn)
    {
        if (!giveIn && self.phantomVoiceSeverity() > 0) rpgExpandedReject('phantom-voices-owned-self-control-required');
        return inherited(giveIn);
    }
    validateDirectFright()
    {
        if (self.phantomVoiceSeverity() > 0) rpgExpandedReject('phantom-voices-full-fear-integration-required');
        return inherited();
    }
;

modify RpgExpandedPhantomVoiceOccurrence
    commands = []
;
class RpgExpandedVoiceCommandResult: RpgExpandedResult
    resisted = nil
    instruction = nil
    score = nil
;
/** B148: author-selected resistance; does not execute the commanded action. */
class RpgExpandedVoiceCommand: object
    id = nil
    occurrence = nil
    command = nil
    instruction = nil
    underStress = nil
    intoxicated = nil
    approved = nil
    evidence = nil
    result = nil
    recordedAt = nil
    boundDefinition = nil
    boundCheck = nil
    definition()
    {
        return [self.id,self.occurrence,self.command,self.instruction,self.underStress,self.intoxicated,
            self.approved,self.evidence,self.recordedAt];
    }
    context()
    {
        local context = new RpgLiteContext(); context.attribute = rpgWill; context.kind = 'resistance'; return context;
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.occurrence == nil
            || !self.occurrence.ofKind(RpgExpandedPhantomVoiceOccurrence)) rpgExpandedReject('voice-command-definition');
        self.occurrence.validateReceipt(); local value = new RpgExpandedVoiceCommandResult();
        if (self.result != nil)
        {
            if (!holds(self.occurrence.commands,self)) rpgExpandedReject('voice-command-history');
            local facts = self.definition();
            for (local index = 1; index <= facts.length(); index += 1)
                if (facts[index] != self.boundDefinition[index]) rpgExpandedReject('voice-command-binding');
            local check = self.result.check;
            if (check != self.boundCheck[1] || check.score != self.boundCheck[2] || check.roll != self.boundCheck[3]
                || check.achieved != self.boundCheck[4] || check.critical != self.boundCheck[5] || check.margin != self.boundCheck[6]
                || self.result.resisted != check.achieved || self.result.instruction != self.instruction)
                rpgExpandedReject('voice-command-check-binding');
            value.status = 'reused'; value.check = check; value.resisted = check.achieved;
            value.instruction = self.instruction; value.score = check.score; return value;
        }
        if (self.recordedAt != nil || self.boundDefinition != nil || self.boundCheck != nil) rpgExpandedReject('voice-command-uncommitted-state');
        if (!self.approved || self.command == nil || self.instruction == nil || self.instruction == ''
            || self.evidence == nil || self.evidence == '') { value.reason = 'voice-command-author-facts'; return value; }
        if (!self.underStress && !self.intoxicated) { value.reason = 'voice-command-qualifying-state'; return value; }
        local profile = self.occurrence.profile;
        if (!self.occurrence.active() || self.occurrence.result.severity != 3 || profile.phantomVoiceSeverity() != 3)
        { value.reason = 'voice-command-active-severity'; return value; }
        if (profile.dead || profile.unconscious) { value.reason = 'voice-command-incapacitated'; return value; }
        foreach (local prior in self.occurrence.commands)
        {
            prior.assess();
            if (prior.id == self.id || prior.command == self.command) rpgExpandedReject('voice-command-duplicate');
        }
        value.score = rpgLiteScore(profile,self.context());
        if (value.score == nil) { value.reason = 'voice-command-check-unavailable'; return value; }
        value.instruction = self.instruction; value.status = 'ready'; return value;
    }
    resolve()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        value.check = rpgLiteCheck(self.occurrence.profile,self.context());
        if (value.check.status != 'resolved') rpgExpandedReject('voice-command-check-changed');
        value.resisted = value.check.achieved; value.status = 'resolved';
        self.recordedAt = self.occurrence.profile.timeElapsed; self.boundDefinition = self.definition();
        self.boundCheck = [value.check,value.check.score,value.check.roll,value.check.achieved,value.check.critical,value.check.margin];
        self.result = value; self.occurrence.commands = self.occurrence.commands + [self]; return value;
    }
;

modify RpgExpandedPhantomVoiceOccurrence
    soundMasks = []
;
/** B148: a concrete authored interval in which ordinary sound is drowned out. */
class RpgExpandedVoiceSoundMask: object
    id = nil
    occurrence = nil
    approved = nil
    evidence = nil
    startedAt = nil
    endedAt = nil
    endEvidence = nil
    boundDefinition = nil
    boundEnding = nil
    definition() { return [self.id,self.occurrence,self.approved,self.evidence,self.startedAt]; }
    validateReceipt()
    {
        self.occurrence.validateReceipt();
        if (self.startedAt == nil || !holds(self.occurrence.soundMasks,self)) rpgExpandedReject('voice-mask-history');
        local facts = self.definition();
        for (local index = 1; index <= facts.length(); index += 1)
            if (facts[index] != self.boundDefinition[index]) rpgExpandedReject('voice-mask-binding');
        if (self.boundEnding == nil && (self.endedAt != nil || self.endEvidence != nil)
            || self.boundEnding != nil && (self.endedAt != self.boundEnding[1] || self.endEvidence != self.boundEnding[2]))
            rpgExpandedReject('voice-mask-ending-binding');
        return nil;
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.occurrence == nil
            || !self.occurrence.ofKind(RpgExpandedPhantomVoiceOccurrence)) rpgExpandedReject('voice-mask-definition');
        self.occurrence.validateReceipt(); local value = new RpgExpandedResult();
        if (self.startedAt != nil) { self.validateReceipt(); value.status = 'reused'; return value; }
        if (self.endedAt != nil || self.endEvidence != nil || self.boundDefinition != nil || self.boundEnding != nil)
            rpgExpandedReject('voice-mask-uncommitted-state');
        if (!self.approved || self.evidence == nil || self.evidence == '') { value.reason = 'voice-mask-author-facts'; return value; }
        if (!self.occurrence.active() || self.occurrence.result.severity != 2 || self.occurrence.profile.phantomVoiceSeverity() != 2)
        { value.reason = 'voice-mask-active-severity'; return value; }
        foreach (local prior in self.occurrence.soundMasks)
        {
            prior.validateReceipt();
            if (prior.id == self.id) rpgExpandedReject('voice-mask-duplicate');
            if (prior.active()) { value.reason = 'voice-mask-already-active'; return value; }
        }
        value.status = 'ready'; return value;
    }
    begin()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.startedAt = self.occurrence.profile.timeElapsed; self.boundDefinition = self.definition();
        self.occurrence.soundMasks = self.occurrence.soundMasks + [self]; value.status = 'resolved'; return value;
    }
    active()
    {
        self.validateReceipt(); return self.endedAt == nil && self.occurrence.active()
            && self.occurrence.profile.phantomVoiceSeverity() == 2;
    }
    end(confirmed,evidence)
    {
        self.validateReceipt(); local value = new RpgExpandedResult();
        if (self.endedAt != nil) { value.status = 'reused'; return value; }
        if (!confirmed || evidence == nil || evidence == '') { value.reason = 'voice-mask-ending-facts'; return value; }
        self.endedAt = self.occurrence.profile.timeElapsed; self.endEvidence = evidence;
        self.boundEnding = [self.endedAt,evidence]; value.status = 'resolved'; return value;
    }
;
modify RpgLiteContext
    auditoryInput = 'auto'
;
modify RpgExpandedProfile
    voiceSoundMasked()
    {
        foreach (local occurrence in self.phantomVoiceOccurrences)
        {
            occurrence.validateReceipt();
            foreach (local mask in occurrence.soundMasks) if (mask.active()) return true;
        }
        return nil;
    }
    healthCheckReason(context)
    {
        local reason = inherited(context); if (reason != nil) return reason;
        if (!self.voiceSoundMasked()) return nil;
        if (!holds(['auto','required','none'],context.auditoryInput)) rpgExpandedReject('voice-mask-auditory-channel');
        local required = context.auditoryInput == 'required' || context.auditoryInput == 'auto'
            && (context.kind == 'hearing' || context.understandsSpeech && !context.written);
        return required ? 'phantom-voices-sound-masked' : nil;
    }
;

modify RpgExpandedProfile
    voiceOrigins = []
;
class RpgExpandedVoiceOrigin: object
    profile = nil
    trait = nil
    origin = nil
    approved = nil
    evidence = nil
    recordedAt = nil
    boundDefinition = nil
    cure = nil
    definition() { return [self.profile,self.trait,self.origin,self.approved,self.evidence,self.recordedAt]; }
    validateReceipt()
    {
        if (self.recordedAt == nil || !holds(self.profile.voiceOrigins,self)) rpgExpandedReject('voice-origin-history');
        local facts = self.definition();
        for (local index = 1; index <= facts.length(); index += 1)
            if (facts[index] != self.boundDefinition[index]) rpgExpandedReject('voice-origin-binding');
        return nil;
    }
    assess()
    {
        if (self.profile == nil || !self.profile.ofKind(RpgExpandedProfile) || self.trait == nil
            || !self.trait.ofKind(RpgExpandedPhantomVoices)) rpgExpandedReject('voice-origin-definition');
        local value = new RpgExpandedResult();
        if (self.recordedAt != nil) { self.validateReceipt(); value.status = 'reused'; return value; }
        if (self.boundDefinition != nil || self.cure != nil) rpgExpandedReject('voice-origin-uncommitted-state');
        if (!holds(self.profile.traits,self.trait)) rpgExpandedReject('voice-origin-purchase');
        self.trait.creationCost(); self.profile.phantomVoiceSeverity();
        if (!holds(['psychological','possession'],self.origin)) rpgExpandedReject('voice-origin-category');
        if (!self.approved || self.evidence == nil || self.evidence == '') { value.reason = 'voice-origin-author-facts'; return value; }
        foreach (local prior in self.profile.voiceOrigins)
        {
            prior.validateReceipt(); if (prior.trait == self.trait) rpgExpandedReject('voice-origin-duplicate');
        }
        value.status = 'ready'; return value;
    }
    record()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.recordedAt = self.profile.timeElapsed; self.boundDefinition = self.definition();
        self.profile.voiceOrigins = self.profile.voiceOrigins + [self]; value.status = 'resolved'; return value;
    }
    assessPsychotherapy()
    {
        self.validateReceipt(); local value = new RpgExpandedResult();
        if (self.origin == 'possession') { value.reason = 'voice-origin-psychotherapy-cannot-discover-or-cure'; return value; }
        value.reason = 'voice-origin-psychotherapy-procedure-required'; return value;
    }
;
/** B148 cure plus B291 funded buyoff; the exorcism's success is an authored fact. */
class RpgExpandedVoiceExorcism: object
    origin = nil
    successful = nil
    approved = nil
    evidence = nil
    result = nil
    recordedAt = nil
    boundDefinition = nil
    chargedPoints = nil
    definition() { return [self.origin,self.successful,self.approved,self.evidence,self.recordedAt]; }
    assess()
    {
        if (self.origin == nil || !self.origin.ofKind(RpgExpandedVoiceOrigin)) rpgExpandedReject('voice-exorcism-origin');
        self.origin.validateReceipt(); local value = new RpgExpandedResult(); local profile = self.origin.profile;
        if (self.result != nil)
        {
            if (self.origin.cure != self) rpgExpandedReject('voice-exorcism-history');
            local facts = self.definition();
            for (local index = 1; index <= facts.length(); index += 1)
                if (facts[index] != self.boundDefinition[index]) rpgExpandedReject('voice-exorcism-binding');
            if (holds(profile.traits,self.origin.trait)) rpgExpandedReject('voice-exorcism-purchase-restored');
            value.status = 'reused'; value.points = self.chargedPoints; return value;
        }
        if (self.recordedAt != nil || self.boundDefinition != nil || self.chargedPoints != nil) rpgExpandedReject('voice-exorcism-uncommitted-state');
        if (self.origin.cure != nil) rpgExpandedReject('voice-exorcism-already-recorded');
        if (self.origin.origin != 'possession') { value.reason = 'voice-exorcism-origin-category'; return value; }
        if (!self.successful || !self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'voice-exorcism-author-facts'; return value; }
        if (!holds(profile.traits,self.origin.trait)) rpgExpandedReject('voice-exorcism-purchase');
        if (!profile.developmentOpen) { value.reason = 'rpg.downtime-required'; return value; }
        local cost = profile.disadvantageBuyoffCost(self.origin.trait);
        if (cost == nil) { value.reason = 'buyoff-original-cost-required'; return value; }
        value.points = cost; value.reason = profile.developmentSpendingReason(); if (value.reason != nil) return value;
        if (profile.unspentPoints < cost) { value.reason = 'rpg.insufficient-points'; return value; }
        foreach (local occurrence in profile.phantomVoiceOccurrences) occurrence.validateReceipt();
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local profile = self.origin.profile;
        if (!rpgLiteBuyOff(profile,self.origin.trait)) rpgExpandedReject('voice-exorcism-buyoff-changed');
        foreach (local occurrence in profile.phantomVoiceOccurrences)
            if (occurrence.result.occurred && occurrence.endedAt == nil)
                occurrence.end(true,self.evidence);
        self.recordedAt = profile.timeElapsed; self.boundDefinition = self.definition(); self.chargedPoints = value.points;
        self.origin.cure = self; value.status = 'resolved'; self.result = value; return value;
    }
;

/** B130 severity costs; scope identifies a distinct authored belief. */
class RpgExpandedFixedBelief: RpgLiteTrait
    id = 'fixed-belief'
    labelId = 'fixed-belief'
    points = -5
    approved = nil
    beliefText = nil
    behaviorText = nil
    fearAcquisition = nil
    templatePurchaseKind = 'expanded-fixed-belief'
    creditedPoints = nil
    creationCost()
    {
        rpgInteger(self.level,1,3);
        if (!self.approved || self.id != 'fixed-belief' || self.points != -5 || self.scope == nil || self.scope == '' || self.scope == 'quirk'
            || self.beliefText == nil || self.beliefText == '' || self.behaviorText == nil || self.behaviorText == ''
            || self.controlled || self.skills.length() != 0) rpgExpandedReject('fixed-belief-definition');
        if (self.creditedPoints == nil) return -5 * self.level;
        rpgInteger(self.creditedPoints,0,5 * self.level); return -self.creditedPoints;
    }
;
modify RpgExpandedProfile
    fixedBeliefAcquisitions = []
    traitMayRepeat(trait) { return trait.ofKind(RpgExpandedFixedBelief) || inherited(trait); }
    validateFixedBeliefs(extra)
    {
        local beliefs = self.traits; if (extra != nil) beliefs = beliefs + [extra];
        local scopes = []; local total = 0; local nominal = 0;
        foreach (local trait in beliefs)
            if (trait.id == 'fixed-belief')
            {
                if (!trait.ofKind(RpgExpandedFixedBelief)) rpgExpandedReject('fixed-belief-type');
                total -= trait.creationCost(); nominal += 5 * trait.level;
                if (holds(scopes,trait.scope)) rpgExpandedReject('fixed-belief-duplicate-scope');
                scopes = scopes + [trait.scope];
            }
        if (total > 40) rpgExpandedReject('fixed-belief-point-limit');
        if (!self.creationComplete && total != (nominal > 40 ? 40 : nominal)) rpgExpandedReject('fixed-belief-credit-allocation');
        if (total > 0 && self.trait('delusions') != nil) rpgExpandedReject('fixed-belief-legacy-combination');
        return nil;
    }
    validateFeatures() { inherited(); self.validateFixedBeliefs(nil); return nil; }
    postCreationDisadvantageAllowance()
    {
        local value = inherited();
        if (self.creationComplete)
            foreach (local award in self.fixedBeliefAcquisitions)
                if (holds(self.traits,award.trait)) { award.assess(); value -= award.trait.creationCost(); }
        return value;
    }
;
/** B361 rows 22/34, post-creation character-value loss without point income. */
class RpgExpandedFixedBeliefAcquisition: RpgExpandedFearTraitConsequence
    id = nil
    eventId = nil
    profile = nil
    trait = nil
    tableTotal = 22
    approved = nil
    evidence = nil
    result = nil
    boundDefinition = nil
    definition()
    {
        return [self.id,self.eventId,self.profile,self.trait,self.tableTotal,self.approved,self.evidence,
            self.trait.scope,self.trait.level,self.trait.beliefText,self.trait.behaviorText,self.trait.creditedPoints];
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.eventId == nil || self.eventId == '' || self.profile == nil
            || !self.profile.ofKind(RpgExpandedProfile) || self.trait == nil || !self.trait.ofKind(RpgExpandedFixedBelief))
            rpgExpandedReject('fixed-belief-acquisition-definition');
        local value = new RpgExpandedResult();
        if (self.result != nil)
        {
            if (!holds(self.profile.fixedBeliefAcquisitions,self) || self.trait.fearAcquisition != self)
                rpgExpandedReject('fixed-belief-acquisition-history');
            local facts = self.definition();
            for (local index = 1; index <= facts.length(); index += 1)
                if (facts[index] != self.boundDefinition[index]) rpgExpandedReject('fixed-belief-acquisition-binding');
            self.trait.creationCost(); value.status = 'reused'; value.points = self.trait.creationCost(); return value;
        }
        if (!holds([22,23,34,35],self.tableTotal)) rpgExpandedReject('fixed-belief-fear-row');
        if (!self.profile.creationComplete) { value.reason = 'fixed-belief-after-creation'; return value; }
        if (!self.approved || self.evidence == nil || self.evidence == '') { value.reason = 'fixed-belief-event-evidence'; return value; }
        if (self.profile.dead) { value.reason = 'fixed-belief-dead'; return value; }
        if (holds(self.profile.traits,self.trait) || self.trait.fearAcquisition != nil)
        { value.reason = 'fixed-belief-already-owned'; return value; }
        for (local owner = firstObj(RpgLiteProfile); owner != nil; owner = nextObj(owner,RpgLiteProfile))
            if (holds(owner.traits,self.trait)) rpgExpandedReject('fixed-belief-foreign-owner');
        value.points = self.trait.creationCost();
        if (-5 * self.trait.level != (holds([22,23],self.tableTotal) ? -10 : -15)) rpgExpandedReject('fixed-belief-fear-severity');
        if (holds([23,35],self.tableTotal) && value.points != (self.tableTotal == 23 ? -10 : -15))
            rpgExpandedReject('fixed-belief-mental-outcome-value');
        rpgExpandedValidate(self.profile); self.profile.validateFixedBeliefs(self.trait);
        foreach (local prior in self.profile.fixedBeliefAcquisitions)
            if (prior.id == self.id || prior.eventId == self.eventId) rpgExpandedReject('fixed-belief-event-duplicate');
        rpgInteger(self.profile.developmentRevision,0,2147483646); value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.boundDefinition = self.definition(); self.trait.fearAcquisition = self;
        self.profile.traits = self.profile.traits + [self.trait];
        self.profile.fixedBeliefAcquisitions = self.profile.fixedBeliefAcquisitions + [self];
        self.profile.developmentRevision += 1; value.status = 'resolved'; self.result = value; return value;
    }
;

modify rpgExpandedTemplateTraits
    plain(id,level,scope)
    {
        if (id == 'fixed-belief') rpgExpandedReject('fixed-belief-authored-definition-required');
        return inherited(id,level,scope);
    }
    copy(trait)
    {
        if (!trait.ofKind(RpgExpandedFixedBelief)) return inherited(trait);
        trait.creationCost(); local copy = new RpgExpandedFixedBelief(); copy.level = trait.level; copy.scope = trait.scope;
        copy.beliefText = trait.beliefText; copy.behaviorText = trait.behaviorText; copy.approved = true; copy.creditedPoints = trait.creditedPoints;
        copy.creationCost(); return copy;
    }
;

modify RpgExpandedProfile
    fixedBeliefPortrayals = []
    validateFixedBeliefPortrayal(portrayal)
    {
        if (portrayal == nil || !portrayal.ofKind(RpgExpandedFixedBeliefPortrayal) || portrayal.profile != self)
            rpgExpandedReject('fixed-belief-portrayal-owner');
        return portrayal.validateReceipt();
    }
    fixedBeliefReactionLevel(belief)
    {
        if (belief == nil || !belief.ofKind(RpgExpandedFixedBelief)) rpgExpandedReject('fixed-belief-reaction-definition');
        belief.creationCost();
        return holds(self.traits,belief) && belief.active && !belief.mitigated ? belief.level : 0;
    }
;
/** B130 explicit author adjudication of the belief's behavior in one situation. */
class RpgExpandedFixedBeliefPortrayal: object
    id = nil
    profile = nil
    belief = nil
    situation = nil
    decision = nil
    observedBehavior = nil
    approved = nil
    recordedAt = nil
    boundDefinition = nil
    definition()
    {
        return [self.id,self.profile,self.belief,self.situation,self.decision,self.observedBehavior,self.approved,self.recordedAt,
            self.belief.scope,self.belief.level,self.belief.beliefText,self.belief.behaviorText,self.belief.creditedPoints];
    }
    validateReceipt()
    {
        if (self.recordedAt == nil || !holds(self.profile.fixedBeliefPortrayals,self)) rpgExpandedReject('fixed-belief-portrayal-history');
        local facts = self.definition();
        for (local index = 1; index <= facts.length(); index += 1)
            if (facts[index] != self.boundDefinition[index]) rpgExpandedReject('fixed-belief-portrayal-binding');
        return nil;
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)
            || self.belief == nil || !self.belief.ofKind(RpgExpandedFixedBelief)) rpgExpandedReject('fixed-belief-portrayal-definition');
        local value = new RpgExpandedResult(); self.belief.creationCost();
        if (self.recordedAt != nil) { self.validateReceipt(); value.status = 'reused'; return value; }
        if (self.boundDefinition != nil) rpgExpandedReject('fixed-belief-portrayal-uncommitted-state');
        if (!holds(self.profile.traits,self.belief) || !self.belief.active || self.belief.mitigated)
        { value.reason = 'fixed-belief-portrayal-inactive'; return value; }
        if (!self.approved || self.situation == nil || self.observedBehavior == nil || self.observedBehavior == '')
        { value.reason = 'fixed-belief-portrayal-evidence'; return value; }
        if (!holds(['followed','departed'],self.decision)) rpgExpandedReject('fixed-belief-portrayal-decision');
        foreach (local prior in self.profile.fixedBeliefPortrayals)
        {
            prior.validateReceipt();
            if (prior.id == self.id || prior.belief == self.belief && prior.situation == self.situation)
                rpgExpandedReject('fixed-belief-portrayal-duplicate');
        }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.recordedAt = rpgLedger.seconds; self.boundDefinition = self.definition();
        self.profile.fixedBeliefPortrayals = self.profile.fixedBeliefPortrayals + [self]; value.status = 'resolved'; return value;
    }
;

modify RpgExpandedProfile
    fixedBeliefKnowledge = []
;
/** B130 private author facts; recording does not publish a revelation. */
class RpgExpandedFixedBeliefKnowledge: object
    id = nil
    profile = nil
    belief = nil
    previous = nil
    truthConfirmed = nil
    characterAware = nil
    playersRecognize = nil
    approved = nil
    evidence = nil
    recordedAt = nil
    boundDefinition = nil
    buyoff = nil
    definition()
    {
        return [self.id,self.profile,self.belief,self.previous,self.truthConfirmed,self.characterAware,
            self.playersRecognize,self.approved,self.evidence,self.recordedAt,
            self.belief.scope,self.belief.level,self.belief.beliefText,self.belief.behaviorText,self.belief.creditedPoints];
    }
    validateReceipt()
    {
        if (self.recordedAt == nil || !holds(self.profile.fixedBeliefKnowledge,self) || self.boundDefinition == nil)
            rpgExpandedReject('fixed-belief-knowledge-history');
        local facts = self.definition();
        if (facts.length() != self.boundDefinition.length()) rpgExpandedReject('fixed-belief-knowledge-binding');
        for (local index = 1; index <= facts.length(); index += 1)
            if (facts[index] != self.boundDefinition[index]) rpgExpandedReject('fixed-belief-knowledge-binding');
        return nil;
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)
            || self.belief == nil || !self.belief.ofKind(RpgExpandedFixedBelief)) rpgExpandedReject('fixed-belief-knowledge-definition');
        local value = new RpgExpandedResult(); self.belief.creationCost();
        if (self.recordedAt != nil) { self.validateReceipt(); value.status = 'reused'; return value; }
        if (self.boundDefinition != nil || self.buyoff != nil) rpgExpandedReject('fixed-belief-knowledge-uncommitted-state');
        if (!holds(self.profile.traits,self.belief)) rpgExpandedReject('fixed-belief-knowledge-purchase');
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'fixed-belief-knowledge-author-facts'; return value; }
        local latest = nil;
        foreach (local prior in self.profile.fixedBeliefKnowledge)
        {
            prior.validateReceipt();
            if (prior.id == self.id) rpgExpandedReject('fixed-belief-knowledge-duplicate');
            if (prior.belief == self.belief) latest = prior;
        }
        if (self.previous != latest) rpgExpandedReject('fixed-belief-knowledge-predecessor');
        value.status = 'ready'; return value;
    }
    record()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.recordedAt = rpgLedger.seconds; self.boundDefinition = self.definition();
        self.profile.fixedBeliefKnowledge = self.profile.fixedBeliefKnowledge + [self]; value.status = 'resolved'; return value;
    }
;
/** B130 disclosure condition and B291 funded buyoff, without revealing private facts. */
class RpgExpandedFixedBeliefRevelationBuyoff: object
    knowledge = nil
    approved = nil
    evidence = nil
    result = nil
    chargedPoints = nil
    boundDefinition = nil
    definition() { return [self.knowledge,self.approved,self.evidence]; }
    assess()
    {
        if (self.knowledge == nil || !self.knowledge.ofKind(RpgExpandedFixedBeliefKnowledge))
            rpgExpandedReject('fixed-belief-revelation-knowledge');
        self.knowledge.validateReceipt(); local value = new RpgExpandedResult(); local profile = self.knowledge.profile;
        if (self.result != nil)
        {
            if (self.knowledge.buyoff != self || holds(profile.traits,self.knowledge.belief))
                rpgExpandedReject('fixed-belief-revelation-history');
            local facts = self.definition();
            for (local index = 1; index <= facts.length(); index += 1)
                if (facts[index] != self.boundDefinition[index]) rpgExpandedReject('fixed-belief-revelation-binding');
            value.status = 'reused'; value.points = self.chargedPoints; return value;
        }
        if (self.chargedPoints != nil || self.boundDefinition != nil) rpgExpandedReject('fixed-belief-revelation-uncommitted-state');
        local latest = nil;
        foreach (local prior in profile.fixedBeliefKnowledge)
        { prior.validateReceipt(); if (prior.belief == self.knowledge.belief) latest = prior; }
        // Deliberately one public reason for every unavailable disclosure state.
        if (latest != self.knowledge || !self.knowledge.truthConfirmed || !self.knowledge.playersRecognize
            || !self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'fixed-belief-revelation-unavailable'; return value; }
        if (self.knowledge.buyoff != nil || !holds(profile.traits,self.knowledge.belief))
            rpgExpandedReject('fixed-belief-revelation-purchase');
        if (!profile.developmentOpen) { value.reason = 'rpg.downtime-required'; return value; }
        local cost = profile.disadvantageBuyoffCost(self.knowledge.belief);
        if (cost == nil) { value.reason = 'buyoff-original-cost-required'; return value; }
        value.points = cost; value.reason = profile.developmentSpendingReason(); if (value.reason != nil) return value;
        if (profile.unspentPoints < cost) { value.reason = 'rpg.insufficient-points'; return value; }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        if (!rpgLiteBuyOff(self.knowledge.profile,self.knowledge.belief)) rpgExpandedReject('fixed-belief-revelation-buyoff-changed');
        self.boundDefinition = self.definition(); self.chargedPoints = value.points; self.knowledge.buyoff = self;
        value.status = 'resolved'; self.result = value; return value;
    }
;

/** B130: numerator, denominator, injury interval, fixed dose period, calendar months.
 * Zero fixed period means continuous access or a calendar-based boundary. */
rpgExpandedSustenanceSchedule(frequency)
{
    if (frequency == 'continuous') return [5,1,60,0,0];
    if (frequency == 'hourly') return [4,1,600,3600,0];
    if (frequency == 'daily') return [3,1,3600,86400,0];
    if (frequency == 'weekly') return [2,1,21600,604800,0];
    if (frequency == 'monthly') return [1,1,86400,0,1];
    if (frequency == 'seasonal') return [1,3,259200,0,3];
    if (frequency == 'yearly') return [1,10,1209600,0,12];
    rpgExpandedReject('sustenance-frequency');
}
rpgExpandedSustenanceCost(rarity, illegal, frequency)
{
    local base = 0;
    if (rarity == 'rare') base = 30;
    else if (rarity == 'occasional') base = 20;
    else if (rarity == 'common') base = 10;
    else if (rarity == 'very-common') base = 5;
    else rpgExpandedReject('sustenance-rarity');
    if (illegal) base += 5;
    local row = rpgExpandedSustenanceSchedule(frequency);
    return -((base * row[1]) / row[2]);
}
/** Authored life support, distinct from dietary starvation and skilled maintenance. */
class RpgExpandedSustenanceRequirement: RpgLiteTrait
    id = 'sustenance-requirement'
    labelId = 'sustenance-requirement'
    points = -1
    rarity = nil
    illegal = nil
    acceleratedAging = nil
    frequency = nil
    requirementKind = nil
    requirementText = nil
    approved = nil
    evidence = nil
    templatePurchaseKind = 'expanded-sustenance'
    creationCost()
    {
        if (self.id != 'sustenance-requirement' || self.points != -1 || self.level != 1 || self.controlled
            || self.skills.length() != 0 || self.scope == nil || self.scope == '' || self.scope == 'quirk'
            || !self.approved || self.evidence == nil || self.evidence == ''
            || self.requirementText == nil || self.requirementText == '') rpgExpandedReject('sustenance-definition');
        if (!holds(['substance','object','environment'],self.requirementKind)) rpgExpandedReject('sustenance-kind');
        local cost = rpgExpandedSustenanceCost(self.rarity,self.illegal,self.frequency);
        return self.acceleratedAging ? rpgExpandedSignedModifiedCost(cost,[30]) : cost;
    }
    templatePurchaseOptions()
    {
        return [self.rarity,self.illegal,self.frequency,self.requirementKind,self.requirementText,self.approved,self.evidence,self.acceleratedAging];
    }
    requiredContactSeconds()
    {
        self.creationCost();
        if (self.requirementKind == 'substance') rpgExpandedReject('sustenance-dose-not-contact');
        if (self.frequency == 'continuous') rpgExpandedReject('sustenance-continuous-access-required');
        return rpgExpandedSustenanceSchedule(self.frequency)[3];
    }
;
modify RpgExpandedProfile
    traitMayRepeat(trait) { return trait.ofKind(RpgExpandedSustenanceRequirement) || inherited(trait); }
    validateFeatures()
    {
        inherited(); local scopes = [];
        foreach (local trait in self.traits)
            if (trait.id == 'sustenance-requirement')
            {
                if (!trait.ofKind(RpgExpandedSustenanceRequirement)) rpgExpandedReject('sustenance-type');
                trait.creationCost();
                if (holds(scopes,trait.scope)) rpgExpandedReject('sustenance-duplicate-scope');
                scopes = scopes + [trait.scope];
            }
        return nil;
    }
;
modify rpgExpandedTemplateTraits
    plain(id,level,scope)
    {
        if (id == 'sustenance-requirement') rpgExpandedReject('sustenance-authored-definition-required');
        return inherited(id,level,scope);
    }
    copy(trait)
    {
        if (!trait.ofKind(RpgExpandedSustenanceRequirement)) return inherited(trait);
        trait.creationCost(); local copy = new RpgExpandedSustenanceRequirement();
        copy.acceleratedAging = trait.acceleratedAging; copy.scope = trait.scope; copy.rarity = trait.rarity; copy.illegal = trait.illegal; copy.frequency = trait.frequency;
        copy.requirementKind = trait.requirementKind; copy.requirementText = trait.requirementText;
        copy.approved = trait.approved; copy.evidence = trait.evidence; copy.creationCost(); return copy;
    }
;

modify RpgExpandedProfile
    sustenanceInjuryInterval(trait)
    {
        if (trait == nil || !trait.ofKind(RpgExpandedSustenanceRequirement) || !holds(self.traits,trait))
            rpgExpandedReject('sustenance-owned-requirement');
        trait.creationCost();
        if (!trait.active || trait.mitigated) rpgExpandedReject('sustenance-inactive-requirement');
        return rpgExpandedSustenanceSchedule(trait.frequency)[3];
    }
;

modify RpgExpandedProfile
    sustenanceContactSeconds(trait)
    {
        self.sustenanceInjuryInterval(trait); return trait.requiredContactSeconds();
    }
;

modify RpgExpandedProfile
    validateSustenanceDose(trait)
    {
        self.sustenanceInjuryInterval(trait);
        if (trait.requirementKind != 'substance') rpgExpandedReject('sustenance-substance-required');
        if (trait.frequency == 'continuous') rpgExpandedReject('sustenance-continuous-access-required');
        return nil;
    }
;

modify RpgExpandedProfile
    sustenancePeriod(trait)
    {
        self.sustenanceInjuryInterval(trait); local row = rpgExpandedSustenanceSchedule(trait.frequency);
        if (trait.frequency == 'continuous') rpgExpandedReject('sustenance-continuous-access-required');
        return [row[4],row[5]];
    }
;

modify RpgExpandedProfile
    validateContinuousSustenance(trait)
    {
        self.sustenanceInjuryInterval(trait);
        if (trait.frequency != 'continuous' || !holds(['object','environment'],trait.requirementKind))
            rpgExpandedReject('sustenance-continuous-contact-required');
        return nil;
    }
;

modify RpgExpandedProfile
    sustenanceAgingRequired(trait)
    { self.sustenanceInjuryInterval(trait); return trait.acceleratedAging; }
;

modify RpgExpandedProfile
    dependentReplacementTraitFacts(trait)
    {
        if (!trait.ofKind(RpgExpandedFixedBelief)) return inherited(trait);
        return [trait.id,trait.points,trait.level,trait.scope,trait.approved,trait.beliefText,trait.behaviorText,
            trait.creditedPoints,trait.controlled,trait.skills.length(),trait.fearAcquisition];
    }
    validateDependentReplacementTrait(trait)
    {
        if (!trait.ofKind(RpgExpandedFixedBelief)) return inherited(trait);
        trait.creationCost(); self.validateFixedBeliefs(trait);
        if (trait.fearAcquisition != nil || !trait.active || trait.mitigated)
            rpgExpandedReject('dependent-replacement-trait-existing-state');
        return nil;
    }
;

modify RpgExpandedProfile
    dependentReplacementTraitFacts(trait)
    {
        if (!trait.ofKind(RpgExpandedLowMotivation)) return inherited(trait);
        return [trait.id,trait.points,trait.level,trait.scope,trait.approved,trait.controlled,
            trait.selfControlRating,trait.percentages.length(),trait.skills.length()];
    }
    validateDependentReplacementTrait(trait)
    {
        if (!trait.ofKind(RpgExpandedLowMotivation)) return inherited(trait);
        trait.creationCost();
        if (!trait.active || trait.mitigated || trait.nextCheck != 0 || trait.skills.length() != 0)
            rpgExpandedReject('dependent-replacement-trait-existing-state');
        foreach (local owned in self.traits)
            if (owned.id == trait.id) rpgExpandedReject('dependent-replacement-trait-duplicate-kind');
        return nil;
    }
;

/** B144 purchased susceptibility. Journey effects are owned by hazards. */
class RpgExpandedMotionSusceptibility: RpgLiteTrait
    id = 'motion-susceptibility'
    labelId = 'motion-susceptibility'
    points = -10
    approved = nil
    templatePurchaseKind = 'expanded-motion-susceptibility'
    creationCost()
    {
        if (!self.approved) rpgExpandedReject('unapproved-trait');
        if (self.id != 'motion-susceptibility' || self.points != -10 || self.level != 1
            || self.scope != nil || self.controlled || self.skills.length() != 0)
            rpgExpandedReject('motion-susceptibility-definition');
        return -10;
    }
;
modify RpgSkill
    /* nil means unclassified, 0 non-operation, 1 vehicle operation. */
    vehicleOperationClass = nil
    vehicleOperationClassification() { return self.vehicleOperationClass; }
;
modify RpgLiteSkill
    vehicleOperationClassification()
    {
        if (holds(['bicycling','boating','driving','piloting','submarine'],self.studyIdentity()))
        {
            if (self.vehicleOperationClass != nil && self.vehicleOperationClass != 1)
                rpgExpandedReject('vehicle-operation-class-conflict');
            return 1;
        }
        if (self.vehicleOperationClass != nil) return self.vehicleOperationClass;
        foreach (local row in rpgLiteCatalogue.skills)
            if (row[1] == self.studyIdentity()) return 0;
        return nil;
    }
;
modify RpgExpandedSkill
    vehicleOperationClassification()
    {
        if (self.optionalParent == nil) return inherited();
        rpgExpandedValidateSkill(self);
        local parent = self.optionalParent.vehicleOperationClassification();
        if (self.vehicleOperationClass != nil && self.vehicleOperationClass != parent)
            rpgExpandedReject('vehicle-operation-specialty-conflict');
        return parent;
    }
;
modify RpgExpandedProfile
    motionSusceptible(activeOnly)
    {
        local count = 0; local present = nil;
        foreach (local trait in self.traits)
            if (trait.id == 'motion-susceptibility')
            {
                if (!trait.ofKind(RpgExpandedMotionSusceptibility)) rpgExpandedReject('motion-susceptibility-definition');
                trait.creationCost(); count += 1;
                if (!activeOnly || trait.active && !trait.mitigated) present = true;
            }
        if (count > 1) rpgExpandedReject('motion-susceptibility-duplicate');
        return present;
    }
    motionSkillLearningReason(skill)
    {
        if (!self.motionSusceptible(nil)) return nil;
        if (skill == nil || !skill.ofKind(RpgSkill)) rpgExpandedReject('motion-susceptibility-skill');
        local operation = skill.vehicleOperationClassification();
        if (operation == nil) return 'motion-skill-classification-required';
        rpgInteger(operation,0,1);
        return operation == 1 ? 'motion-susceptibility-learning' : nil;
    }
    physiologySkillLearningReason(skill)
    {
        local reason = self.motionSkillLearningReason(skill);
        return reason == nil ? inherited(skill) : reason;
    }
    validateFeatures()
    {
        inherited();
        if (self.motionSusceptible(nil))
            foreach (local training in self.skills)
                if (training.points > 0)
                {
                    local reason = self.motionSkillLearningReason(training.skill);
                    if (reason != nil) rpgExpandedReject(reason);
                }
        return nil;
    }
    skillScore(skill)
    {
        if (self.motionSusceptible(nil))
            foreach (local training in self.skills)
                if (training.skill == skill && training.points > 0)
                {
                    local reason = self.motionSkillLearningReason(skill);
                    if (reason != nil) rpgExpandedReject(reason);
                }
        return inherited(skill);
    }
;
modify rpgExpandedTemplateTraits
    plain(id,level,scope)
    {
        if (id != 'motion-susceptibility') return inherited(id,level,scope);
        local trait = new RpgExpandedMotionSusceptibility(); trait.level = level; trait.scope = scope; trait.approved = true;
        trait.creationCost(); return trait;
    }
    copy(trait)
    {
        if (!trait.ofKind(RpgExpandedMotionSusceptibility)) return inherited(trait);
        trait.creationCost(); return self.plain(trait.id,trait.level,trait.scope);
    }
;

/** Full-2008 B41 exceptional physiology; ordinary humans are ineligible. */
class RpgExpandedBreathReserveTrait: RpgLiteTrait
    id = 'breath-reserve'
    labelId = 'breath-reserve'
    points = 2
    approved = nil
    eligibility = nil
    evidence = nil
    templatePurchaseKind = 'expanded-breath-reserve'
    templatePurchaseOptions() { return [self.eligibility,self.evidence]; }
    creationCost()
    {
        if (!self.approved) rpgExpandedReject('unapproved-trait');
        if (!holds(['nonhuman','super'],self.eligibility) || self.evidence == nil || self.evidence == '')
            rpgExpandedReject('breath-reserve-eligibility');
        if (self.id != 'breath-reserve' || self.points != 2 || self.scope != nil || self.controlled || self.skills.length() != 0)
            rpgExpandedReject('breath-reserve-trait-definition');
        rpgInteger(self.level,1,10); return self.level * 2;
    }
;
modify RpgExpandedProfile
    purchasedBreathReserveLevels()
    {
        local found = nil; local levels = 0;
        foreach (local trait in self.traits)
            if (trait.id == 'breath-reserve')
            {
                if (found != nil) rpgExpandedReject('breath-reserve-duplicate');
                if (!trait.ofKind(RpgExpandedBreathReserveTrait)) rpgExpandedReject('breath-reserve-trait-definition');
                trait.creationCost(); found = trait;
                if (trait.active && !trait.mitigated) levels = trait.level;
            }
        return levels;
    }
    validateFeatures() { inherited(); self.purchasedBreathReserveLevels(); return nil; }
;
modify rpgExpandedTemplateTraits
    copy(trait)
    {
        if (!trait.ofKind(RpgExpandedBreathReserveTrait)) return inherited(trait);
        trait.creationCost(); local value = new RpgExpandedBreathReserveTrait();
        value.level = trait.level; value.approved = trait.approved; value.eligibility = trait.eligibility;
        value.evidence = trait.evidence; value.creationCost(); return value;
    }
;

modify rpgExpandedTemplateTraits
    configured(id,level,scope,options)
    {
        if (id != 'breath-reserve') return inherited(id,level,scope,options);
        if (options.length() != 2) rpgExpandedReject('breath-reserve-template-options');
        local trait = new RpgExpandedBreathReserveTrait(); trait.level = level; trait.scope = scope;
        trait.approved = true; trait.eligibility = options[1]; trait.evidence = options[2];
        trait.creationCost(); return trait;
    }
    plain(id,level,scope)
    {
        if (id == 'breath-reserve') rpgExpandedReject('breath-reserve-template-options');
        return inherited(id,level,scope);
    }
;

/** B22 ordinary sympathy, with audience need adjudicated by the social context. */
class RpgExpandedSympathy: RpgExpandedTrait
    id = 'sympathy'
    points = 5
    creationCost()
    {
        if (!self.approved || self.id != 'sympathy' || self.points != 5 || self.level != 1
            || self.percentages.length() != 0) rpgExpandedReject('sympathy-definition');
        return 5;
    }
;
modify RpgExpandedProfile
    sympathyActive()
    {
        local found = nil;
        foreach (local trait in self.traits)
            if (trait.ofKind(RpgExpandedSympathy))
            {
                trait.creationCost(); if (found != nil) rpgExpandedReject('duplicate-sympathy'); found = trait;
            }
        return found != nil && found.active && !found.mitigated;
    }
    beggingAuthoredTraitReason(sympathy, shyness)
    {
        if (sympathy && self.sympathyActive()) return 'begging-duplicate-sympathy';
        if (shyness != 0 && self.socialInhibitionPenalty() != 0) return 'begging-duplicate-inhibition';
        return inherited(sympathy,shyness);
    }
    validateFeatures() { inherited(); self.sympathyActive(); return nil; }
;

/** B21 fixed appearance tiers, lowest -5 through highest 4; zero is ordinary. */
class RpgExpandedAppearance: RpgLiteTrait
    id = 'appearance'
    tier = 0
    presentation = 'ordinary'
    universal = nil
    standardized = nil
    approved = nil
    percentages = []
    creationCost()
    {
        if (!self.approved || self.id != 'appearance' || self.level != 1 || self.controlled
            || self.percentages.length() != 0 || !holds(['ordinary','androgynous','impressive'],self.presentation))
            rpgExpandedReject('appearance-definition');
        rpgInteger(self.tier,-5,4);
        if (self.presentation == 'androgynous' && self.tier < 2 || self.presentation == 'impressive' && self.tier < 1)
            rpgExpandedReject('appearance-presentation-tier');
        if (self.standardized && self.tier < 2) rpgExpandedReject('appearance-standardized-tier');
        local base = [-24,-20,-16,-8,-4,0,4,12,16,20][self.tier+6];
        return rpgExpandedSignedModifiedCost(base,[self.universal ? 25 : 0,self.standardized ? -50 : 0]);
    }
    modifierForObserver(sees, compatible, attracted, sameSex, otherPenalties)
    {
        self.creationCost(); rpgInteger(otherPenalties,-1000,0);
        if (!self.active || self.mitigated || !sees || (!compatible && !self.universal)) return 0;
        if (self.tier <= 1) return [-6,-5,-4,-2,-1,0,1][self.tier+6];
        if (self.presentation != 'ordinary' || self.universal) return self.tier+1;
        if (self.tier >= 3 && sameSex && otherPenalties < -4) return -2;
        return attracted ? self.tier*2 : 2;
    }
    cultureModifier(amount, sameCulture)
    {
        self.creationCost(); rpgInteger(amount,-6,8);
        return self.standardized && sameCulture && amount > 0 ? amount / 2 : amount;
    }
;
modify RpgExpandedProfile
    appearanceTrait()
    {
        local found = nil;
        foreach (local trait in self.traits)
            if (trait.ofKind(RpgExpandedAppearance))
            {
                trait.creationCost(); if (found != nil) rpgExpandedReject('duplicate-appearance'); found = trait;
            }
        if (found != nil)
            foreach (local trait in self.traits)
                if (trait != found && holds(['hideous','ugly','unattractive','attractive','handsome','very-handsome'],trait.id))
                    rpgExpandedReject('appearance-legacy-conflict');
        return found;
    }
    validateFeatures() { inherited(); self.appearanceTrait(); return nil; }
;

modify RpgExpandedAppearance
    labelId = 'appearance'
    templatePurchaseKind = 'expanded-appearance'
    templatePurchaseOptions() { return [self.tier,self.presentation,self.universal,self.standardized]; }
;
modify RpgExpandedSympathy
    labelId = 'sympathy'
    templatePurchaseKind = 'expanded-sympathy'
;
modify RpgExpandedSocialInhibition
    labelId = 'social-inhibition'
    templatePurchaseKind = 'expanded-social-inhibition'
;
modify rpgExpandedTemplateTraits
    plain(id,level,scope)
    {
        if (id == 'appearance') rpgExpandedReject('appearance-template-options');
        if (!holds(['sympathy','social-inhibition'],id)) return inherited(id,level,scope);
        if (scope != nil) rpgExpandedReject('social-trait-template-scope');
        local trait = id == 'sympathy' ? new RpgExpandedSympathy() : new RpgExpandedSocialInhibition();
        trait.approved = true; trait.level = level; trait.creationCost(); return trait;
    }
    configured(id,level,scope,options)
    {
        if (id != 'appearance') return inherited(id,level,scope,options);
        if (level != 1 || scope != nil || options.length() != 4) rpgExpandedReject('appearance-template-options');
        local trait = new RpgExpandedAppearance(); trait.approved = true;
        trait.tier = options[1]; trait.presentation = options[2]; trait.universal = options[3]; trait.standardized = options[4];
        trait.creationCost(); return trait;
    }
    copy(trait)
    {
        if (!trait.ofKind(RpgExpandedAppearance) && !trait.ofKind(RpgExpandedSympathy)
            && !trait.ofKind(RpgExpandedSocialInhibition)) return inherited(trait);
        trait.creationCost();
        if (trait.labelId != trait.id || trait.scope != nil) rpgExpandedReject('social-trait-template-definition');
        local value = trait.ofKind(RpgExpandedAppearance)
            ? self.configured(trait.id,trait.level,trait.scope,trait.templatePurchaseOptions())
            : self.plain(trait.id,trait.level,trait.scope);
        value.approved = trait.approved; return value;
    }
;

/** B21 ordinary styling expertise, with preparation owned by the social library. */
class RpgExpandedStyling: RpgExpandedTrait
    id = 'styling'
    labelId = 'styling'
    points = 5
    templatePurchaseKind = 'expanded-styling'
    creationCost()
    {
        if (!self.approved || self.id != 'styling' || self.points != 5 || self.level != 1
            || self.scope != nil || self.percentages.length() != 0) rpgExpandedReject('styling-definition');
        return 5;
    }
;
modify RpgExpandedProfile
    stylingActive()
    {
        local found = nil;
        foreach (local trait in self.traits)
            if (trait.ofKind(RpgExpandedStyling))
            {
                trait.creationCost(); if (found != nil) rpgExpandedReject('duplicate-styling'); found = trait;
            }
        return found != nil && found.active && !found.mitigated;
    }
    validateFeatures() { inherited(); self.stylingActive(); return nil; }
;
modify rpgExpandedTemplateTraits
    plain(id,level,scope)
    {
        if (id != 'styling') return inherited(id,level,scope);
        local trait = new RpgExpandedStyling(); trait.approved = true; trait.level = level; trait.scope = scope;
        trait.creationCost(); return trait;
    }
    copy(trait)
    {
        if (!trait.ofKind(RpgExpandedStyling)) return inherited(trait);
        trait.creationCost(); if (trait.labelId != trait.id) rpgExpandedReject('styling-template-definition');
        return self.plain(trait.id,trait.level,trait.scope);
    }
;

/** B22 unusual-for-species cosmetic features, with a specified origin. */
class RpgExpandedDistinctiveFeatures: RpgExpandedDisadvantage
    id = 'distinctive-features'
    labelId = 'distinctive-features'
    points = -1
    species = nil
    description = nil
    origin = nil
    templatePurchaseKind = 'expanded-distinctive-features'
    templatePurchaseOptions() { return [self.species,self.description,self.origin]; }
    creationCost()
    {
        if (!self.approved || self.id != 'distinctive-features' || self.points != -1 || self.scope != nil
            || self.percentages.length() != 0 || self.selfControlRating != nil || self.controlled
            || self.species == nil || self.description == nil || self.description == '' || self.origin == nil || self.origin == '')
            rpgExpandedReject('distinctive-features-definition');
        rpgInteger(self.level,1,5); return -self.level;
    }
;
modify RpgExpandedProfile
    distinctiveFeatureLevels()
    {
        local found = nil;
        foreach (local trait in self.traits)
            if (trait.ofKind(RpgExpandedDistinctiveFeatures))
            {
                trait.creationCost(); if (found != nil) rpgExpandedReject('duplicate-distinctive-features'); found = trait;
            }
        return found == nil || !found.active || found.mitigated ? 0 : found.level;
    }
    validateFeatures() { inherited(); self.distinctiveFeatureLevels(); return nil; }
;
/** Explicit actor/subject task and authored crowd exception. */
class RpgExpandedDistinctiveContext: RpgLiteContext
    subject = nil
    purpose = 'disguise'
    sharedByCrowd = nil
    approved = nil
    evidence = nil
    socialTraitModifier(profile)
    {
        local amount = inherited(profile);
        if (self.subject == nil || !self.subject.ofKind(RpgLiteProfile)
            || !holds(['disguise','shadowing','identify','follow'],self.purpose)) rpgExpandedReject('distinctive-context-definition');
        if (!self.approved || self.evidence == nil || self.evidence == '') rpgExpandedReject('distinctive-context-evidence');
        local own = holds(['disguise','shadowing'],self.purpose);
        if (own && (profile != self.subject || self.skill == nil || self.skill.id != self.purpose)
            || !own && profile == self.subject) rpgExpandedReject('distinctive-context-participants');
        local levels = self.sharedByCrowd ? 0 : self.subject.distinctiveFeatureLevels();
        return amount + (own ? -levels : levels);
    }
;
modify rpgExpandedTemplateTraits
    configured(id,level,scope,options)
    {
        if (id != 'distinctive-features') return inherited(id,level,scope,options);
        if (scope != nil || options.length() != 3) rpgExpandedReject('distinctive-features-template-options');
        local trait = new RpgExpandedDistinctiveFeatures(); trait.approved = true; trait.level = level;
        trait.species = options[1]; trait.description = options[2]; trait.origin = options[3]; trait.creationCost(); return trait;
    }
    plain(id,level,scope)
    {
        if (id == 'distinctive-features') rpgExpandedReject('distinctive-features-template-options');
        return inherited(id,level,scope);
    }
    copy(trait)
    {
        if (!trait.ofKind(RpgExpandedDistinctiveFeatures)) return inherited(trait);
        trait.creationCost(); if (trait.labelId != trait.id) rpgExpandedReject('distinctive-features-template-definition');
        return self.configured(trait.id,trait.level,trait.scope,trait.templatePurchaseOptions());
    }
;

/** B46 cinematic cultural coverage; never grants a language or social permission. */
class RpgExpandedCulturalAdaptation: RpgExpandedTrait
    id = 'cultural-adaptation'
    labelId = 'cultural-adaptation'
    coverage = 'own-species'
    world = nil
    evidence = nil
    templatePurchaseKind = 'expanded-cultural-adaptation'
    templatePurchaseOptions() { return [self.coverage,self.world,self.evidence]; }
    creationCost()
    {
        if (self.id != 'cultural-adaptation' || !self.approved || self.level != 1 || self.scope != nil || self.controlled
            || self.percentages.length() != 0 || !holds(['own-species','world'],self.coverage)
            || self.evidence == nil || self.evidence == '' || (self.coverage == 'world' && self.world == nil)
            || (self.coverage == 'own-species' && self.world != nil)) rpgExpandedReject('cultural-adaptation-definition');
        return self.coverage == 'world' ? 20 : 10;
    }
    covers(profile,culture)
    {
        self.creationCost();
        if (!profile.rules.cinematicCulturalAdaptation) rpgExpandedReject('cultural-adaptation-disabled');
        if (!self.active || self.mitigated) return nil;
        if (self.coverage == 'world')
        {
            if (culture.world == nil) rpgExpandedReject('culture-world-required');
            return culture.world == self.world;
        }
        if (profile.culturalSpecies == nil || culture.species.length() == 0) rpgExpandedReject('culture-species-required');
        return holds(culture.species,profile.culturalSpecies);
    }
;
modify RpgExpandedProfile
    culturalAdaptationTrait()
    {
        local found = nil;
        foreach (local trait in self.traits)
            if (trait.ofKind(RpgExpandedCulturalAdaptation))
            {
                trait.creationCost();
                if (found != nil) rpgExpandedReject('duplicate-cultural-adaptation');
                if (!self.rules.cinematicCulturalAdaptation) rpgExpandedReject('cultural-adaptation-disabled');
                if (trait.coverage == 'own-species' && self.culturalSpecies == nil) rpgExpandedReject('culture-species-required');
                found = trait;
            }
        return found;
    }
    culturalAdaptationCovers(culture)
    {
        local trait = self.culturalAdaptationTrait(); return trait != nil && trait.covers(self,culture);
    }
    validateFeatures() { inherited(); self.culturalAdaptationTrait(); return nil; }
;
modify rpgExpandedTemplateTraits
    plain(id,level,scope)
    {
        if (id == 'cultural-adaptation') rpgExpandedReject('cultural-adaptation-template-options');
        return inherited(id,level,scope);
    }
    configured(id,level,scope,options)
    {
        if (id != 'cultural-adaptation') return inherited(id,level,scope,options);
        if (level != 1 || scope != nil || options.length() != 3) rpgExpandedReject('cultural-adaptation-template-options');
        local trait = new RpgExpandedCulturalAdaptation(); trait.approved = true;
        trait.coverage = options[1]; trait.world = options[2]; trait.evidence = options[3]; trait.creationCost(); return trait;
    }
    copy(trait)
    {
        if (!trait.ofKind(RpgExpandedCulturalAdaptation)) return inherited(trait);
        trait.creationCost();
        return self.configured(trait.id,trait.level,trait.scope,trait.templatePurchaseOptions());
    }
;

/** B49 unmodified fine sensory recognition purchases; identity/memory uses separate procedures. */
class RpgExpandedSensoryRecognition: RpgExpandedTrait
    sense = nil
    templatePurchaseKind = 'expanded-sensory-recognition'
    templatePurchaseOptions() { return []; }
    creationCost()
    {
        if (!holds(['hearing','smell','taste'],self.sense) || self.id != 'fine-' + self.sense
            || !self.approved || self.level != 1 || self.scope != nil || self.controlled || self.percentages.length() != 0)
            rpgExpandedReject('sensory-recognition-definition');
        return self.sense == 'taste' ? 10 : 15;
    }
;
modify RpgExpandedProfile
    sensoryRecognitionTrait(sense)
    {
        local found = nil;
        foreach (local trait in self.traits)
            if (trait.ofKind(RpgExpandedSensoryRecognition))
            {
                trait.creationCost();
                if (trait.sense == sense)
                {
                    if (found != nil) rpgExpandedReject('duplicate-sensory-recognition');
                    found = trait;
                }
            }
        return found;
    }
    sensoryRecognitionBonus(sense)
    {
        if (sense == nil) return 0;
        local trait = self.sensoryRecognitionTrait(sense);
        return trait != nil && trait.active && !trait.mitigated ? 4 : 0;
    }
    validateFeatures()
    {
        inherited();
        foreach (local sense in ['hearing','smell','taste']) self.sensoryRecognitionTrait(sense);
        return nil;
    }
;
modify RpgLiteContext
    sensoryUseModifier(profile)
    {
        if (!profile.ofKind(RpgExpandedProfile)) return inherited(profile);
        return profile.sensoryRecognitionBonus(self.sensoryRecognitionMode());
    }
;
modify rpgExpandedTemplateTraits
    plain(id,level,scope)
    {
        if (!holds(['fine-hearing','fine-smell','fine-taste'],id)) return inherited(id,level,scope);
        if (level != 1 || scope != nil) rpgExpandedReject('sensory-recognition-template');
        local trait = new RpgExpandedSensoryRecognition(); trait.approved = true; trait.id = id; trait.labelId = id;
        trait.sense = id == 'fine-hearing' ? 'hearing' : id == 'fine-smell' ? 'smell' : 'taste';
        trait.creationCost(); return trait;
    }
    configured(id,level,scope,options)
    {
        if (!holds(['fine-hearing','fine-smell','fine-taste'],id)) return inherited(id,level,scope,options);
        if (options.length() != 0) rpgExpandedReject('sensory-recognition-template-options');
        return self.plain(id,level,scope);
    }
    copy(trait)
    {
        if (!trait.ofKind(RpgExpandedSensoryRecognition)) return inherited(trait);
        trait.creationCost(); return self.plain(trait.id,trait.level,trait.scope);
    }
;

class RpgExpandedSensoryMemoryResult: RpgExpandedResult
    memorized = nil
    retryAt = nil
    score = nil
    gate = nil
    allowed = nil
;
/** B49 one exposure and IQ attempt; failed attempts share a full-day retry barrier. */
class RpgExpandedSensoryMemoryAttempt: object
    id = nil
    profile = nil
    sense = nil
    signature = nil
    seconds = 60
    sourceAvailable = nil
    approved = nil
    evidence = nil
    result = nil
    completedAt = nil
    boundDefinition = nil
    boundOutcome = nil
    definition()
    {
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)
            || !holds(['hearing','smell'],self.sense) || self.signature == nil)
            rpgExpandedReject('sensory-memory-definition');
        rpgInteger(self.seconds,60,86400);
        return [self.id,self.profile,self.sense,self.signature,self.seconds,self.sourceAvailable,self.approved,self.evidence];
    }
    outcomeDefinition()
    {
        local facts = [self.completedAt,self.result,self.result.memorized,self.result.retryAt,self.result.seconds,
            self.result.allowed,self.result.gate,self.result.check];
        if (self.result.check != nil) facts = facts + [self.result.check.score,self.result.check.roll,
            self.result.check.margin,self.result.check.achieved,self.result.check.critical];
        return facts;
    }
    score()
    {
        local context = new RpgLiteContext(); context.attribute = rpgIQ; context.kind = 'sensory-memory'; context.someLight = nil;
        return rpgLiteScore(self.profile,context);
    }
    assess()
    {
        local facts = self.definition(); local value = new RpgExpandedSensoryMemoryResult();
        if (self.result != nil)
        {
            if (!holds(self.profile.sensoryMemoryAttempts,self) || self.boundDefinition == nil || facts.length() != self.boundDefinition.length())
                rpgExpandedReject('sensory-memory-history');
            for (local index = 1; index <= facts.length(); index += 1)
                if (facts[index] != self.boundDefinition[index]) rpgExpandedReject('sensory-memory-binding');
            local outcome = self.outcomeDefinition();
            if (self.boundOutcome == nil || outcome.length() != self.boundOutcome.length()) rpgExpandedReject('sensory-memory-outcome');
            for (local index = 1; index <= outcome.length(); index += 1)
                if (outcome[index] != self.boundOutcome[index]) rpgExpandedReject('sensory-memory-outcome');
            if (self.completedAt > rpgLedger.seconds || self.result.gate.assess().status != 'reused')
                rpgExpandedReject('sensory-memory-receipt');
            value.status = 'reused'; return value;
        }
        if (self.completedAt != nil || self.boundDefinition != nil || self.boundOutcome != nil)
            rpgExpandedReject('sensory-memory-uncommitted');
        if (self.profile.sensoryRecognitionBonus(self.sense) == 0)
        { value.reason = 'sensory-memory-trait-required'; return value; }
        if (!self.sourceAvailable || !self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'sensory-memory-exposure-required'; return value; }
        foreach (local prior in self.profile.sensoryMemoryAttempts)
        {
            if (prior.id == self.id) rpgExpandedReject('sensory-memory-id-used');
            prior.assess();
            if (prior.sense == self.sense && prior.signature == self.signature)
            {
                if (prior.result.memorized) { value.reason = 'sensory-memory-already-known'; return value; }
                if (prior.result.retryAt != nil && rpgLedger.seconds < prior.result.retryAt)
                { value.reason = 'sensory-memory-retry-delay'; value.retryAt = prior.result.retryAt; return value; }
            }
        }
        value.reason = self.profile.nonTravelScheduleReason(rpgLedger.seconds,self.seconds); if (value.reason != nil) return value;
        value.score = self.score();
        if (value.score == nil || value.score < 3) { value.reason = 'sensory-memory-score'; return value; }
        value.gate = self.profile.prepareSocialGate(self.id,self.evidence,nil);
        if (value.gate == nil) { value.reason = 'sensory-memory-health-adapter-required'; return value; }
        local permission = value.gate.assess();
        if (permission.status != 'ready') { value.reason = permission.reason; return value; }
        rpgInteger(rpgLedger.seconds,0,2147483647-self.seconds-86400); rpgLedger.validateAdvance(self.seconds);
        value.status = 'ready'; return value;
    }
    resolve()
    {
        local value = self.assess(); if (value.status == 'reused') return self.result;
        if (value.status != 'ready') return value;
        local facts = self.definition(); local start = rpgLedger.seconds; local permission = value.gate.resolve();
        if (!holds(['resolved','reused'],permission.status)) rpgExpandedReject('sensory-memory-gate-changed');
        value.allowed = permission.allowed;
        if (value.allowed)
        {
            rpgSpendTime(self.seconds); value.seconds = self.seconds;
            if (rpgLedger.seconds != start+self.seconds || self.score() != value.score
                || self.profile.sensoryRecognitionBonus(self.sense) == 0
                || self.profile.nonTravelScheduleReason(start,self.seconds) != nil)
                rpgExpandedReject('sensory-memory-interrupted');
        }
        local current = self.definition();
        if (current.length() != facts.length()) rpgExpandedReject('sensory-memory-changed');
        for (local index = 1; index <= facts.length(); index += 1)
            if (current[index] != facts[index]) rpgExpandedReject('sensory-memory-changed');
        if (value.allowed)
        {
            value.check = rpgCheck(value.score,rpgRandom.roll()); value.memorized = value.check.achieved;
            if (!value.memorized) value.retryAt = rpgLedger.seconds+86400;
        }
        else value.reason = permission.reason;
        self.completedAt = rpgLedger.seconds; self.boundDefinition = facts; value.status = 'resolved'; self.result = value;
        self.boundOutcome = self.outcomeDefinition(); self.profile.sensoryMemoryAttempts = self.profile.sensoryMemoryAttempts + [self];
        return value;
    }
;
modify RpgExpandedProfile
    sensoryMemoryAttempts = []
    knowsSensorySignature(sense,signature)
    {
        if (!holds(['hearing','smell'],sense) || signature == nil) rpgExpandedReject('sensory-memory-query');
        foreach (local attempt in self.sensoryMemoryAttempts)
        {
            attempt.assess();
            if (attempt.sense == sense && attempt.signature == signature && attempt.result.memorized) return true;
        }
        return nil;
    }
    validateFeatures()
    {
        inherited(); local ids = [];
        foreach (local attempt in self.sensoryMemoryAttempts)
        {
            if (attempt == nil || !attempt.ofKind(RpgExpandedSensoryMemoryAttempt) || attempt.profile != self
                || holds(ids,attempt.id) || attempt.assess().status != 'reused') rpgExpandedReject('sensory-memory-history');
            ids = ids + [attempt.id];
        }
        return nil;
    }
;

/** One ownership boundary for parser, structured action and authored dialogue routes. */
class RpgExpandedSensoryMemoryAction: Action
    attempt = nil
    operation = 'resolve'
    perform(actor)
    {
        if (self.attempt == nil || !self.attempt.ofKind(RpgExpandedSensoryMemoryAttempt)
            || !holds(['preview','resolve'],self.operation)) rpgExpandedReject('sensory-memory-action-definition');
        local value = new RpgExpandedResult();
        if (actor == nil || !actor.ofKind(Thing) || actor.rpgProfile == nil || actor.rpgProfile != self.attempt.profile)
            value.reason = 'sensory-memory-action-owner-required';
        else value = self.operation == 'preview' ? self.attempt.assess() : self.attempt.resolve();
        event('rpg.expanded.sensory-memory'); eventValue(self.operation); eventValue(value.status); eventValue(value.reason);
        return value;
    }
    exec(context) { return self.perform(context.actor); }
;

modify RpgExpandedFearQuirkAcquisition
    fearEventMatches(entry)
    {
        return entry.selectedRow() == 13 && self.profile == entry.context.profile && self.eventId == entry.id;
    }
;
modify RpgExpandedFixedBeliefAcquisition
    fearEventMatches(entry)
    {
        return holds([22,23,34,35],entry.selectedRow()) && self.tableTotal == entry.selectedRow()
            && self.profile == entry.context.profile && self.eventId == entry.id;
    }
;

/** B148 mandatory voice check after failed or exactly successful full fear. */
modify RpgExpandedProfile
    newFearStressFollowup(entry)
    {
        if (self.phantomVoiceSeverity() == 0) return nil;
        local occurrence = new RpgExpandedPhantomVoiceOccurrence(); occurrence.id = 'fear:' + entry.id;
        occurrence.profile = self; occurrence.stressor = entry; occurrence.approved = true;
        occurrence.evidence = entry.context.evidence; return occurrence;
    }
    validateFearStressFollowup(entry,followup)
    {
        self.validatePhantomVoiceOccurrence(followup);
        if (followup.stressor != entry) rpgExpandedReject('fear-stress-event-owner');
        return nil;
    }
;

modify RpgExpandedFixedBeliefAcquisition
    fearCompoundMatches(owner,event,row)
    {
        return self.profile == owner && self.eventId == event
            && ((row == 26 && self.tableTotal == 22) || (row == 38 && self.tableTotal == 34)
                || (row == 27 && self.tableTotal == 23) || (holds([39,40],row) && self.tableTotal == 35));
    }
;

/** B93/B112: sight or hearing aura, with explicit always-on/contact choices. */
class RpgExpandedFearAura: RpgExpandedFearAuraContract
    id = 'fear-aura'
    points = 30
    level = 1
    sense = 'sight'
    penalty = 0
    alwaysOn = nil
    touchOnly = nil
    approved = nil
    templatePurchaseKind = 'expanded-fear-aura'
    creationCost()
    {
        rpgInteger(self.penalty,0,100);
        if (!self.approved || self.id != 'fear-aura' || self.points != 30 || self.level != 1
            || !holds(['sight','hearing'],self.sense) || self.scope != nil || self.controlled || self.skills.length() != 0)
            rpgExpandedReject('fear-aura-definition');
        local modifiers = [];
        if (self.alwaysOn) modifiers = modifiers + [-20];
        if (self.touchOnly) modifiers = modifiers + [-30];
        return rpgExpandedModifiedCost(30+10*self.penalty,modifiers);
    }
    auraFacts()
    {
        self.creationCost();
        return [self.id,self.sense,self.penalty,self.alwaysOn,self.touchOnly,self.approved];
    }
;
modify rpgExpandedTemplateTraits
    plain(id,level,scope)
    {
        if (id == 'fear-aura') rpgExpandedReject('fear-aura-authored-definition-required');
        return inherited(id,level,scope);
    }
    copy(trait)
    {
        if (!trait.ofKind(RpgExpandedFearAura)) return inherited(trait);
        trait.creationCost(); local value = new RpgExpandedFearAura();
        value.sense = trait.sense; value.penalty = trait.penalty; value.alwaysOn = trait.alwaysOn;
        value.touchOnly = trait.touchOnly; value.approved = true; value.creationCost(); return value;
    }
;

/** B150 self-control after an authored battle ending. */
class RpgExpandedPostbattleStress: RpgExpandedDisadvantage
    id = 'postbattle-stress'
    points = -5
    controlled = true
    level = 1
    templatePurchaseKind = 'expanded-postbattle-stress'
    creationCost()
    {
        if (self.id != 'postbattle-stress' || self.points != -5 || self.level != 1 || !self.controlled
            || self.scope != nil || self.percentages.length() != 0 || self.skills.length() != 0)
            rpgExpandedReject('postbattle-trait-definition');
        self.selfControlNumber(); return inherited();
    }
;
modify RpgExpandedProfile
    postbattleFearFacts(trait)
    {
        if (trait == nil || !trait.ofKind(RpgExpandedPostbattleStress)) rpgExpandedReject('postbattle-trait-required');
        trait.creationCost(); return [trait,trait.id,trait.points,trait.level,trait.selfControlNumber()];
    }
    postbattleFearScore(trait,modifier)
    {
        self.postbattleFearFacts(trait);
        if (!holds(self.traits,trait) || !trait.active || trait.mitigated) return nil;
        return trait.selfControlNumber()+modifier-(self.sleepPenalty ? 2 : 0)+self.healthSelfControlModifier(trait);
    }
;
modify rpgExpandedTemplateTraits
    plain(id,level,scope)
    {
        if (id == 'postbattle-stress')
        {
            if (level != 1 || scope != nil) rpgExpandedReject('postbattle-template-definition');
            local value = new RpgExpandedPostbattleStress(); value.approved = true; return value;
        }
        return inherited(id,level,scope);
    }
    copy(trait)
    {
        if (!trait.ofKind(RpgExpandedPostbattleStress)) return inherited(trait);
        trait.creationCost(); local value = new RpgExpandedPostbattleStress(); value.approved = true;
        value.selfControlRating = trait.selfControlRating; value.creationCost(); return value;
    }
;

/** B149-B150 catalogue prices; conditional setting choices remain explicit. */
rpgExpandedPhobiaBase(kind,technology,prevalence)
{
    foreach (local row in [['isolation',-15],['blood',-10],['cats',-5],['crowds',-15],['darkness',-15],
        ['dead',-10],['dirt',-10],['canines',-5],['enclosure',-15],['fire',-5],['heights',-10],['insects',-10],
        ['loud-noise',-10],['monsters',-15],['number-thirteen',-5],['large-water',-10],['open-space',-10],
        ['reptiles',-10],['sexual-contact',-10],['spiders',-5],['unfamiliar',-15],['sunlight',-15],['weapons',-20]])
        if (row[1] == kind) return row[2];
    if (kind == 'machinery' || kind == 'sharp')
    {
        rpgInteger(technology,0,12);
        return kind == 'machinery' ? (technology <= 4 ? -5 : -15) : (technology <= 5 ? -15 : -10);
    }
    if (kind == 'magic' || kind == 'psi')
    {
        if (!holds(['common','uncommon','unknown'],prevalence)) rpgExpandedReject('phobia-prevalence');
        return prevalence == 'common' ? -15 : prevalence == 'uncommon' ? -10 : -5;
    }
    rpgExpandedReject('phobia-catalogue-kind');
}
class RpgExpandedPhobia: RpgExpandedDisadvantage
    id = 'phobia'
    scope = 'blood'
    points = -10
    controlled = true
    level = 1
    technology = 0
    prevalence = 'unknown'
    templatePurchaseKind = 'expanded-phobia'
    creationCost()
    {
        if (self.id != 'phobia' || self.level != 1 || !self.controlled || self.skills.length() != 0
            || self.percentages.length() != 0 || self.points != rpgExpandedPhobiaBase(self.scope,self.technology,self.prevalence))
            rpgExpandedReject('phobia-definition');
        self.selfControlNumber(); return inherited();
    }
;
modify RpgExpandedProfile
    phobiaFacts(trait)
    {
        if (trait == nil || !trait.ofKind(RpgExpandedPhobia)) rpgExpandedReject('phobia-purchase-required');
        trait.creationCost(); return [trait,trait.scope,trait.points,trait.selfControlNumber(),trait.technology,trait.prevalence];
    }
    phobiaScore(trait,modifier)
    {
        self.phobiaFacts(trait);
        if (!holds(self.traits,trait) || !trait.active || trait.mitigated) return nil;
        return trait.selfControlNumber()+modifier-(self.sleepPenalty ? 2 : 0)+self.healthSelfControlModifier(trait);
    }
;
modify rpgExpandedTemplateTraits
    plain(id,level,scope)
    {
        if (id == 'phobia') rpgExpandedReject('phobia-authored-definition-required');
        return inherited(id,level,scope);
    }
    copy(trait)
    {
        if (!trait.ofKind(RpgExpandedPhobia)) return inherited(trait);
        trait.creationCost(); local value = new RpgExpandedPhobia(); value.scope = trait.scope; value.points = trait.points;
        value.selfControlRating = trait.selfControlRating; value.technology = trait.technology; value.prevalence = trait.prevalence;
        value.approved = true; value.creationCost(); return value;
    }
;

/** B361 rows 23/35: a specific new purchased phobia, with no point award. */
class RpgExpandedFearPhobiaAcquisition: RpgExpandedFearTraitConsequence
    id = nil
    eventId = nil
    profile = nil
    trait = nil
    tableTotal = 23
    approved = nil
    evidence = nil
    result = nil
    boundDefinition = nil
    purchaseFacts() { return self.profile.phobiaFacts(self.trait); }
    purchaseConflict(purchase) { return purchase.ofKind(RpgExpandedPhobia) && purchase.scope == self.trait.scope; }
    definition()
    {
        if (self.id == nil || self.id == '' || self.eventId == nil || self.eventId == '' || self.profile == nil
            || !self.profile.ofKind(RpgExpandedProfile)) rpgExpandedReject('fear-phobia-definition');
        return [self.id,self.eventId,self.profile,self.trait,self.tableTotal,self.approved,self.evidence] + self.purchaseFacts();
    }
    assess()
    {
        local facts = self.definition(); local value = new RpgExpandedResult(); value.points = self.trait.creationCost();
        if (self.result != nil)
        {
            if (!holds(self.profile.fearPhobiaAcquisitions,self) || self.trait.fearAcquisition != self || self.boundDefinition == nil)
                rpgExpandedReject('fear-phobia-history');
            for (local i = 1; i <= facts.length(); i += 1)
                if (facts[i] != self.boundDefinition[i]) rpgExpandedReject('fear-phobia-binding');
            value.status = 'reused'; return value;
        }
        if (!holds([23,35],self.tableTotal) || value.points != (self.tableTotal == 23 ? -10 : -15))
            rpgExpandedReject('fear-phobia-value');
        if (!self.profile.creationComplete || !self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'fear-phobia-authored-acquisition'; return value; }
        if (!self.trait.active || self.trait.mitigated) { value.reason = 'fear-acquisition-inactive-purchase'; return value; }
        if (self.profile.dead || self.trait.fearAcquisition != nil) { value.reason = 'fear-phobia-unavailable'; return value; }
        for (local owner = firstObj(RpgLiteProfile); owner != nil; owner = nextObj(owner,RpgLiteProfile))
            if (holds(owner.traits,self.trait)) rpgExpandedReject('fear-phobia-owned-purchase');
        foreach (local purchase in self.profile.traits)
            if (self.purchaseConflict(purchase)) rpgExpandedReject('fear-phobia-duplicate-scope');
        foreach (local prior in self.profile.fearPhobiaAcquisitions)
            if (prior.id == self.id || prior.eventId == self.eventId) rpgExpandedReject('fear-phobia-duplicate-event');
        rpgExpandedValidate(self.profile); rpgInteger(self.profile.developmentRevision,0,2147483646);
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.boundDefinition = self.definition(); self.trait.fearAcquisition = self;
        self.profile.traits = self.profile.traits + [self.trait]; self.profile.fearPhobiaAcquisitions = self.profile.fearPhobiaAcquisitions + [self];
        self.profile.developmentRevision += 1; value.status = 'resolved'; self.result = value; return value;
    }
    fearEventMatches(entry)
    { return holds([23,35],entry.selectedRow()) && entry.selectedRow() == self.tableTotal && entry.context.profile == self.profile && entry.id == self.eventId; }
    fearCompoundMatches(owner,event,row)
    { return owner == self.profile && event == self.eventId && ((row == 27 && self.tableTotal == 23) || (holds([39,40],row) && self.tableTotal == 35)); }
;
modify RpgExpandedPhobia fearAcquisition = nil;
modify RpgExpandedProfile
    fearPhobiaAcquisitions = []
    postCreationDisadvantageAllowance()
    {
        local value = inherited();
        foreach (local award in self.fearPhobiaAcquisitions)
        {
            award.assess();
            if (self.creationComplete && holds(self.traits,self.phobiaCurrentTrait(award.trait))) value -= award.trait.creationCost();
        }
        return value;
    }
;

/** B361 row 25. Replace a purchase, preserving historical exposure/check facts. */
class RpgExpandedFearPhobiaWorsening: RpgExpandedFearTraitConsequence
    id = nil
    eventId = nil
    profile = nil
    previous = nil
    replacement = nil
    fallback = nil
    related = nil
    approved = nil
    evidence = nil
    result = nil
    boundDefinition = nil
    delta = 0
    boundDelta = nil
    purchaseFacts(trait) { return self.profile.phobiaFacts(trait); }
    definition()
    {
        if (self.id == nil || self.id == '' || self.eventId == nil || self.eventId == '' || self.profile == nil
            || !self.profile.ofKind(RpgExpandedProfile)) rpgExpandedReject('fear-worsening-definition');
        local facts = [self.id,self.eventId,self.profile,self.previous,self.replacement,self.fallback,self.related,self.approved,self.evidence];
        if (self.previous != nil) facts = facts + self.purchaseFacts(self.previous);
        if (self.replacement != nil) facts = facts + self.purchaseFacts(self.replacement);
        return facts;
    }
    assess()
    {
        local facts = self.definition(); local value = new RpgExpandedResult();
        if (self.result != nil)
        {
            if (!holds(self.profile.fearPhobiaWorsenings,self) || self.boundDefinition == nil
                || facts.length() != self.boundDefinition.length() || self.delta != self.boundDelta)
                rpgExpandedReject('fear-worsening-history');
            for (local i = 1; i <= facts.length(); i += 1)
                if (facts[i] != self.boundDefinition[i]) rpgExpandedReject('fear-worsening-binding');
            if (self.fallback != nil && self.fallback.assess().status != 'reused') rpgExpandedReject('fear-worsening-fallback-history');
            value.status = 'reused'; return value;
        }
        if (self.boundDefinition != nil || self.boundDelta != nil || self.delta != 0) rpgExpandedReject('fear-worsening-uncommitted');
        if (!self.approved || self.evidence == nil || self.evidence == '' || !self.profile.creationComplete)
        { value.reason = 'fear-worsening-authored-relation'; return value; }
        if (self.profile.dead) { value.reason = 'fear-worsening-dead'; return value; }
        foreach (local prior in self.profile.fearPhobiaWorsenings)
            if (prior.id == self.id || prior.eventId == self.eventId) rpgExpandedReject('fear-worsening-duplicate');
        if (self.previous != nil && (!holds(self.profile.traits,self.previous) || !self.previous.active || self.previous.mitigated))
        { value.reason = 'fear-worsening-current-purchase'; return value; }
        if (self.related && self.previous != nil && self.previous.controlled && self.previous.selfControlNumber() > 6)
        {
            if (self.fallback != nil || self.replacement == nil) rpgExpandedReject('fear-worsening-replacement-required');
            local before = self.purchaseFacts(self.previous); local after = self.purchaseFacts(self.replacement);
            if (after[4] != before[4]-3 || after[2] != before[2] || after[3] != before[3]
                || after[5] != before[5] || after[6] != before[6] || !self.replacement.active || self.replacement.mitigated)
                rpgExpandedReject('fear-worsening-one-step');
            for (local owner = firstObj(RpgLiteProfile); owner != nil; owner = nextObj(owner,RpgLiteProfile))
                if (holds(owner.traits,self.replacement)) rpgExpandedReject('fear-worsening-owned-replacement');
        }
        else
        {
            if (self.replacement != nil || self.fallback == nil || !(self.fallback.ofKind(RpgExpandedFearPhobiaAcquisition) || self.fallback.ofKind(RpgExpandedFixedBeliefAcquisition))
                || self.fallback.tableTotal != 23 || self.fallback.profile != self.profile || self.fallback.eventId != self.eventId)
                rpgExpandedReject('fear-worsening-fallback-required');
            local acquired = self.fallback.assess();
            if (acquired.status == 'reused') rpgExpandedReject('fear-worsening-used-fallback');
            if (acquired.status != 'ready') { value.reason = acquired.reason; return value; }
        }
        rpgExpandedValidate(self.profile); rpgInteger(self.profile.developmentRevision,0,2147483646);
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.boundDefinition = self.definition();
        if (self.fallback != nil)
        {
            if (self.fallback.apply().status != 'resolved') rpgExpandedReject('fear-worsening-fallback-changed');
        }
        else
        {
            local purchases = [];
            foreach (local purchase in self.profile.traits) purchases = purchases + [purchase == self.previous ? self.replacement : purchase];
            self.delta = self.previous.creationCost()-self.replacement.creationCost();
            self.profile.traits = purchases; self.profile.developmentRevision += 1;
        }
        self.boundDelta = self.delta; self.profile.fearPhobiaWorsenings = self.profile.fearPhobiaWorsenings + [self];
        value.status = 'resolved'; self.result = value; return value;
    }
    fearEventMatches(entry)
    { return entry.selectedRow() == 25 && entry.context.profile == self.profile && entry.id == self.eventId; }
;
modify RpgExpandedProfile
    fearPhobiaWorsenings = []
    phobiaCurrentTrait(trait)
    {
        local current = trait;
        foreach (local change in self.fearPhobiaWorsenings)
        {
            change.assess();
            if (change.previous == current && change.replacement != nil) current = change.replacement;
        }
        return current;
    }
    phobiaControlNumber(trait) { return self.phobiaCurrentTrait(trait).selfControlNumber(); }
    phobiaScore(trait,modifier) { return inherited(self.phobiaCurrentTrait(trait),modifier); }
    postCreationDisadvantageAllowance()
    {
        local value = inherited();
        foreach (local change in self.fearPhobiaWorsenings)
        {
            change.assess();
            if (change.replacement != nil && holds(self.traits,self.phobiaCurrentTrait(change.replacement))) value += change.delta;
        }
        return value;
    }
;
modify RpgExpandedProfile
    traitMayRepeat(trait) { return trait.ofKind(RpgExpandedPhobia) || inherited(trait); }
    validateFeatures()
    {
        inherited(); local scopes = [];
        foreach (local trait in self.traits)
            if (trait.ofKind(RpgExpandedPhobia))
            {
                trait.creationCost();
                if (holds(scopes,trait.scope)) rpgExpandedReject('phobia-duplicate-scope');
                scopes = scopes + [trait.scope];
            }
        local ids = []; local events = [];
        foreach (local change in self.fearPhobiaWorsenings)
        {
            if (change == nil || !change.ofKind(RpgExpandedFearPhobiaWorsening) || change.profile != self
                || holds(ids,change.id) || holds(events,change.eventId) || change.assess().status != 'reused')
                rpgExpandedReject('fear-worsening-profile-history');
            ids = ids + [change.id]; events = events + [change.eventId];
        }
        return nil;
    }
;

/** B361 physical-change rows: concrete existing effects, not a price-only callback. */
class RpgExpandedFearPhysicalAcquisition: RpgExpandedFearTraitConsequence
    id = nil
    eventId = nil
    profile = nil
    tableTotal = 24
    purchases = []
    aging = nil
    approved = nil
    evidence = nil
    result = nil
    boundDefinition = nil
    purchaseFacts(trait)
    {
        if (trait == nil || !(trait.ofKind(RpgExpandedPainSensitivity) || trait.ofKind(RpgExpandedPersistentWound)
            || trait.ofKind(RpgExpandedSpeechLimitation) || trait.ofKind(RpgExpandedAppearance)
            || trait.ofKind(RpgExpandedDistinctiveFeatures) || trait.ofKind(RpgExpandedRecurrentPain)
            || trait.ofKind(RpgExpandedHearingImpairment) || trait.ofKind(RpgExpandedHearingLoss)
            || trait.ofKind(RpgExpandedMotionSusceptibility) || trait.ofKind(RpgExpandedFreeFallSusceptibility)))
            rpgExpandedReject('fear-physical-effect-unsupported');
        local cost = trait.creationCost();
        if (trait.skills.length() != 0 || trait.scope != nil && !trait.ofKind(RpgExpandedFreeFallSusceptibility)
            || cost >= 0) rpgExpandedReject('fear-physical-effect-fields');
        local facts = [trait,trait.id,trait.level,trait.points,trait.scope,trait.approved,cost,
            trait.ofKind(RpgExpandedSpeechLimitation) ? trait.total : nil];
        if (trait.ofKind(RpgExpandedAppearance))
            facts = facts + [trait.tier,trait.presentation,trait.universal,trait.standardized];
        if (trait.ofKind(RpgExpandedDistinctiveFeatures))
            facts = facts + [trait.species,trait.description,trait.origin];
        if (trait.ofKind(RpgExpandedRecurrentPain))
            facts = facts + [trait.severity,trait.intervalHours,trait.frequency];
        return facts;
    }
    definition()
    {
        if (self.id == nil || self.id == '' || self.eventId == nil || self.eventId == '' || self.profile == nil
            || !self.profile.ofKind(RpgExpandedProfile) || !holds([24,36,37],self.tableTotal) || self.purchases.length() == 0 && self.aging == nil)
            rpgExpandedReject('fear-physical-definition');
        local facts = [self.id,self.eventId,self.profile,self.tableTotal,self.approved,self.evidence,self.purchases.length(),self.aging];
        foreach (local trait in self.purchases) facts = facts + self.purchaseFacts(trait);
        if (self.aging != nil)
        {
            if (!self.aging.ofKind(RpgExpandedFearAgingContract) || self.aging.profile != self.profile) rpgExpandedReject('fear-physical-aging-owner');
            facts = facts + self.aging.definition();
        }
        return facts;
    }
    assess()
    {
        local facts = self.definition(); local value = new RpgExpandedResult(); value.points = 0;
        foreach (local trait in self.purchases) value.points += trait.creationCost();
        if (self.aging != nil) { rpgInteger(self.aging.years,1,10); value.points -= self.aging.years*3; }
        if (self.result != nil)
        {
            if (!holds(self.profile.fearPhysicalAcquisitions,self) || self.boundDefinition == nil
                || facts.length() != self.boundDefinition.length()) rpgExpandedReject('fear-physical-history');
            for (local i = 1; i <= facts.length(); i += 1)
                if (facts[i] != self.boundDefinition[i]) rpgExpandedReject('fear-physical-binding');
            if (self.aging != nil && self.aging.assess().status != 'reused') rpgExpandedReject('fear-physical-aging-history');
            value.status = 'reused'; return value;
        }
        if (self.boundDefinition != nil) rpgExpandedReject('fear-physical-uncommitted');
        if (value.points != (self.tableTotal == 24 ? -15 : self.tableTotal == 36 ? -20 : -30)) rpgExpandedReject('fear-physical-point-total');
        if (!self.approved || self.evidence == nil || self.evidence == '' || !self.profile.creationComplete)
        { value.reason = 'fear-physical-author-selection'; return value; }
        if (self.profile.dead) { value.reason = 'fear-physical-dead'; return value; }
        rpgExpandedValidate(self.profile); rpgInteger(self.profile.developmentRevision,0,2147483646);
        foreach (local prior in self.profile.fearPhysicalAcquisitions)
            if (prior.id == self.id || prior.eventId == self.eventId) rpgExpandedReject('fear-physical-duplicate-event');
        local ids = []; local speech = nil;
        foreach (local trait in self.purchases)
        {
            if (!trait.active || trait.mitigated) rpgExpandedReject('fear-physical-effect-inactive');
            if (holds(ids,trait.id)) rpgExpandedReject('fear-physical-duplicate-purchase');
            ids = ids + [trait.id];
            for (local owner = firstObj(RpgLiteProfile); owner != nil; owner = nextObj(owner,RpgLiteProfile))
                if (holds(owner.traits,trait)) rpgExpandedReject('fear-physical-purchase-owned');
            foreach (local existing in self.profile.traits)
                if (existing.id == trait.id || trait.ofKind(RpgExpandedPainSensitivity) && existing.id == 'high-pain-threshold'
                    || trait.ofKind(RpgExpandedHearingImpairment) && holds(['acute-hearing','deaf'],existing.id)
                    || trait.ofKind(RpgExpandedHearingLoss) && holds(['acute-hearing','hard-of-hearing','fine-hearing'],existing.id))
                    rpgExpandedReject('fear-physical-existing-effect');
            if (trait.ofKind(RpgExpandedAppearance))
                foreach (local existing in self.profile.traits)
                    if (holds(['hideous','ugly','unattractive','attractive','handsome','very-handsome'],existing.id))
                        rpgExpandedReject('fear-appearance-existing-tier');
            if (trait.ofKind(RpgExpandedMotionSusceptibility) || trait.ofKind(RpgExpandedFreeFallSusceptibility))
                foreach (local training in self.profile.skills)
                    if (training.points > 0)
                    {
                        if (trait.ofKind(RpgExpandedFreeFallSusceptibility))
                        {
                            if (training.skill.ofKind(RpgLiteSkill) && training.skill.studyIdentity() == 'free-fall')
                            { value.reason = 'fear-free-fall-existing-training'; return value; }
                        }
                        else
                        {
                            local operation = training.skill.vehicleOperationClassification();
                            if (operation == nil) { value.reason = 'motion-skill-classification-required'; return value; }
                            rpgInteger(operation,0,1);
                            if (operation == 1) { value.reason = 'fear-motion-existing-training'; return value; }
                        }
                    }
            if (trait.ofKind(RpgExpandedSpeechLimitation)) speech = trait;
        }
        if (speech != nil)
            foreach (local existing in self.profile.traits)
                if (existing.id == 'stuttering' || speech.total && (existing.voiceRelated
                    || holds(['voice','mimicry','disturbing-voice'],existing.id))) rpgExpandedReject('fear-physical-speech-conflict');
        if (self.aging != nil)
        {
            local age = self.aging.assess();
            if (age.status == 'reused') rpgExpandedReject('fear-physical-aging-used');
            if (age.status != 'ready') return age;
        }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.boundDefinition = self.definition(); self.profile.traits = self.profile.traits + self.purchases;
        self.profile.fearPhysicalAcquisitions = self.profile.fearPhysicalAcquisitions + [self];
        if (self.aging != nil && self.aging.apply().status != 'resolved') rpgExpandedReject('fear-physical-aging-changed');
        self.profile.developmentRevision += 1; value.status = 'resolved'; self.result = value; return value;
    }
    fearEventMatches(entry)
    { return entry.context.profile == self.profile && entry.id == self.eventId && entry.selectedRow() == self.tableTotal; }
;
modify RpgExpandedProfile
    fearPhysicalAcquisitions = []
    postCreationDisadvantageAllowance()
    {
        local value = inherited();
        foreach (local award in self.fearPhysicalAcquisitions)
        {
            award.assess();
            foreach (local trait in award.purchases) if (holds(self.traits,trait)) value -= trait.creationCost();
        }
        return value;
    }
;
modify RpgExpandedProfile
    validateFeatures()
    {
        inherited(); local ids = []; local events = [];
        foreach (local award in self.fearPhysicalAcquisitions)
        {
            if (award == nil || !award.ofKind(RpgExpandedFearPhysicalAcquisition) || award.profile != self
                || holds(ids,award.id) || holds(events,award.eventId) || award.assess().status != 'reused')
                rpgExpandedReject('fear-physical-profile-history');
            ids = ids + [award.id]; events = events + [award.eventId];
        }
        return nil;
    }
;

/** B149: classify the actual subject instead of inferring restrictions from skill labels. */
modify RpgExpandedProfile
    phobiaSkillLearningReason(skill)
    {
        local reason = inherited(skill); if (reason != nil) return reason;
        local machinery = nil; local magic = nil;
        foreach (local trait in self.traits)
            if (trait.ofKind(RpgExpandedPhobia) && trait.active && !trait.mitigated)
            {
                trait.creationCost();
                if (trait.scope == 'machinery') machinery = true;
                if (trait.scope == 'magic') magic = true;
            }
        if (!machinery && !magic) return nil;
        if (skill.phobiaLearningKinds.length() == 0 || skill.phobiaLearningEvidence == nil || skill.phobiaLearningEvidence == '')
            return 'phobia-learning-classification-required';
        foreach (local kind in skill.phobiaLearningKinds)
        {
            if (!holds(['machine-repair','complex-machine-use','simple-machine-use','magic','other'],kind))
                rpgExpandedReject('phobia-learning-kind');
            if (machinery && holds(['machine-repair','complex-machine-use'],kind)) return 'phobia-machine-learning';
            if (magic && kind == 'magic') return 'phobia-magic-learning';
        }
        return nil;
    }
;

modify RpgExpandedPhobia
    validateDirectControl() { rpgExpandedReject('phobia-owned-exposure-required'); }
;
modify RpgExpandedPostbattleStress
    validateDirectControl() { rpgExpandedReject('postbattle-owned-event-required'); }
;

/** B149-B150 explicit voluntary height and power-consent prohibitions. */
class RpgExpandedPhobiaActivity: RpgExpandedPhobiaActivityContract
    kind = nil
    approved = nil
    evidence = nil
    heightFeet = 0
    insideBuilding = nil
    awayFromWindows = nil
    activityFacts()
    {
        if (self.profile == nil || !self.profile.ofKind(RpgExpandedProfile) || !holds(['height','power-consent'],self.kind))
            rpgExpandedReject('phobia-activity-definition');
        rpgInteger(self.heightFeet,0,1000000);
        if (self.kind != 'height' && (self.heightFeet != 0 || self.insideBuilding || self.awayFromWindows)
            || self.awayFromWindows && !self.insideBuilding) rpgExpandedReject('phobia-activity-unused-facts');
        return [self.profile,self.kind,self.approved,self.evidence,self.heightFeet,self.insideBuilding,self.awayFromWindows];
    }
    assess()
    {
        self.activityFacts(); local value = new RpgExpandedResult();
        if (!self.approved || self.evidence == nil || self.evidence == '') { value.reason = 'phobia-activity-evidence'; return value; }
        foreach (local trait in self.profile.traits)
            if (trait.ofKind(RpgExpandedPhobia) && trait.active && !trait.mitigated)
            {
                trait.creationCost();
                if (self.kind == 'height' && trait.scope == 'heights' && self.heightFeet > 15
                    && !(self.insideBuilding && self.awayFromWindows))
                { value.reason = 'phobia-voluntary-height'; return value; }
                if (self.kind == 'power-consent' && trait.scope == 'psi')
                { value.reason = 'phobia-power-consent'; return value; }
            }
        value.status = 'ready'; return value;
    }
;
modify RpgExpandedProfile
    voiceFearFacts(occurrence)
    {
        if (occurrence == nil || !occurrence.ofKind(RpgExpandedPhantomVoiceOccurrence) || occurrence.profile != self)
            rpgExpandedReject('voice-fear-occurrence-owner');
        occurrence.validateReceipt();
        if (!occurrence.result.occurred || occurrence.result.severity != 2) rpgExpandedReject('voice-fear-disturbing-occurrence');
        return [occurrence,occurrence.recordedAt,occurrence.result.severity];
    }
    voiceFearReason(occurrence)
    {
        self.voiceFearFacts(occurrence);
        return !occurrence.active() || self.phantomVoiceSeverity() != 2 ? 'voice-fear-occurrence-inactive' : nil;
    }
;


/** Explicit supported mental purchases with existing executable consequences. */
rpgExpandedFearMentalFacts(trait)
{
    if (trait == nil || !(trait.ofKind(RpgExpandedTruthfulness) || trait.ofKind(RpgExpandedCuriosity)
        || trait.ofKind(RpgExpandedDangerAvoidance) || trait.ofKind(RpgExpandedCompelledAid)
        || trait.ofKind(RpgExpandedLowMotivation) || trait.ofKind(RpgExpandedPostbattleStress)
        || trait.ofKind(RpgExpandedPleasureLoss) || trait.ofKind(RpgExpandedPhantomVoices)
        || trait.ofKind(RpgExpandedHumorlessness) || trait.ofKind(RpgExpandedPervasiveDistrust)
        || trait.ofKind(RpgExpandedSocialInhibition) || trait.ofKind(RpgExpandedCompanionship)
        || trait.ofKind(RpgExpandedOverstimulation) || trait.ofKind(RpgExpandedGoalFixation)
        || trait.ofKind(RpgExpandedImpulsiveAction) || trait.ofKind(RpgExpandedVolatileTemper) || trait.ofKind(RpgExpandedNightmares) || trait.ofKind(RpgExpandedOverconfidence) || trait.ofKind(RpgExpandedSolitude) || trait.ofKind(RpgExpandedStatusSensitivity) || trait.ofKind(RpgExpandedSelfSacrifice) || trait.ofKind(RpgExpandedIntrusiveReplay) || trait.ofKind(RpgExpandedLowConfidence) || trait.ofKind(RpgExpandedIncuriosity)))
        rpgExpandedReject('fear-mental-purchase-unsupported');
    trait.creationCost();
    if (trait.skills.length() != 0 || trait.scope != nil) rpgExpandedReject('fear-mental-purchase-fields');
    local facts = [trait,trait.id,trait.points,trait.controlled ? trait.selfControlNumber() : nil,
        trait.level,trait.scope,trait.approved,trait.controlled];
    if (trait.ofKind(RpgExpandedGoalFixation)) facts = facts + [trait.term,trait.initialGoal];
    if (trait.ofKind(RpgExpandedIntrusiveReplay)) facts = facts + [trait.replayType];
    return facts;
}
/** B361 rows 23/35 and matching compounds: retain the concrete typed trait. */
class RpgExpandedFearMentalAcquisition: RpgExpandedFearPhobiaAcquisition
    purchaseFacts() { return rpgExpandedFearMentalFacts(self.trait); }
    purchaseConflict(purchase) { return purchase.id == self.trait.id; }
;
/** Preserve the old phobia interface and receipt list while admitting typed mental controls. */
class RpgExpandedFearMentalWorsening: RpgExpandedFearPhobiaWorsening
    purchaseFacts(trait)
    {
        if (trait.ofKind(RpgExpandedPhobia)) return inherited(trait);
        if (trait.ofKind(RpgExpandedEmotionalUnderstandingDeficit) || trait.ofKind(RpgExpandedEmotionalObliviousness)
            || trait.ofKind(RpgExpandedCallousness) || trait.ofKind(RpgExpandedLearningBar))
        {
            trait.creationCost();
            if (trait.skills.length() != 0 || trait.scope != nil) rpgExpandedReject('fear-mental-purchase-fields');
            return [trait,trait.id,trait.points,nil,trait.level,trait.scope,trait.approved,nil];
        }
        return rpgExpandedFearMentalFacts(trait);
    }
    assess()
    {
        if (self.previous != nil && self.previous.ofKind(RpgExpandedIntrusiveReplay) && self.replacement != nil
            && (!self.replacement.ofKind(RpgExpandedIntrusiveReplay) || self.replacement.replayType != self.previous.replayType))
            rpgExpandedReject('replay-worsening-type');
        if (self.previous != nil && self.previous.ofKind(RpgExpandedGoalFixation) && self.replacement != nil
            && (!self.replacement.ofKind(RpgExpandedGoalFixation) || self.replacement.term != self.previous.term
                || self.replacement.initialGoal != self.previous.initialGoal)) rpgExpandedReject('fixation-worsening-goal');
        return inherited();
    }
;


/** B138 hearing loss uses the shared -4 hearing/speech-comprehension scoring path. */
class RpgExpandedHearingImpairment: RpgLiteTrait
    id = 'hard-of-hearing'
    points = -10
    approved = nil
    creationCost()
    {
        if (!self.approved || self.id != 'hard-of-hearing' || self.points != -10 || self.level != 1
            || self.controlled || self.scope != nil || self.skills.length() != 0)
            rpgExpandedReject('hearing-impairment-definition');
        return -10;
    }
;

/** B129 complete hearing loss; alternative communication remains available. */
class RpgExpandedHearingLoss: RpgLiteTrait
    id = 'deaf'
    points = -20
    approved = nil
    templatePurchaseKind = 'expanded-hearing-loss'
    creationCost()
    {
        if (!self.approved || self.id != 'deaf' || self.points != -20 || self.level != 1
            || self.controlled || self.scope != nil || self.skills.length() != 0)
            rpgExpandedReject('hearing-loss-definition');
        return -20;
    }
;
modify RpgExpandedProfile
    completeHearingLoss()
    {
        local found = nil;
        foreach (local trait in self.traits)
            if (trait.id == 'deaf')
            {
                if (!trait.ofKind(RpgExpandedHearingLoss) || found != nil) rpgExpandedReject('hearing-loss-purchase');
                trait.creationCost(); found = trait;
            }
        if (found != nil)
            foreach (local trait in self.traits)
                if (holds(['acute-hearing','hard-of-hearing','fine-hearing'],trait.id))
                    rpgExpandedReject('hearing-loss-conflicting-purchase');
        return found != nil && found.active && !found.mitigated;
    }
    validateFeatures() { inherited(); self.completeHearingLoss(); return nil; }
    healthCheckReason(context)
    {
        if (self.completeHearingLoss() && (context.kind == 'hearing' || context.auditoryInput == 'required'
            || context.understandsSpeech && !context.written)) return 'complete-hearing-loss';
        return inherited(context);
    }
    fearAuraPerceptionReason(aura)
    {
        if (self.completeHearingLoss() && aura.sense == 'hearing') return 'fear-aura-hearing-unavailable';
        return inherited(aura);
    }
    communicationStudyEligible() { return self.completeHearingLoss() || inherited(); }
    receivedCommunicationStudyEligible() { return self.completeHearingLoss() || inherited(); }
    studyCommunicationReason(study)
    {
        local reason = inherited(study); if (reason != nil) return reason;
        if (!self.completeHearingLoss() || !holds(['education','intensive'],study.mode)) return nil;
        if (!holds(['written','signed','visual'],study.communicationMode)
            || study.communicationEvidence == nil || study.communicationEvidence == '') return 'study-accessible-communication-required';
        if (study.communicationMode != 'visual')
        {
            if (study.communicationLanguage == nil || study.teacher == nil || !study.teacher.ofKind(RpgLiteProfile))
                return 'study-accessible-language-required';
            local written = study.communicationMode == 'written';
            if (self.language(study.communicationLanguage,written) == 0
                || study.teacher.language(study.communicationLanguage,written) == 0) return 'study-accessible-language-required';
        }
        return nil;
    }
;
modify rpgExpandedTemplateTraits
    plain(id,level,scope)
    {
        if (id != 'deaf') return inherited(id,level,scope);
        local trait = new RpgExpandedHearingLoss(); trait.level = level; trait.scope = scope; trait.approved = true;
        trait.creationCost(); return trait;
    }
    copy(trait)
    {
        if (!trait.ofKind(RpgExpandedHearingLoss)) return inherited(trait);
        trait.creationCost(); return self.plain(trait.id,trait.level,trait.scope);
    }
;

/** B129: a controlled response to unfamiliar surroundings or excessive stimulation. */
class RpgExpandedOverstimulation: RpgExpandedDisadvantage
    id = 'overstimulation'
    points = -10
    controlled = true
    templatePurchaseKind = 'expanded-overstimulation'
    validateDefinition()
    {
        if (!self.approved || self.id != 'overstimulation' || self.points != -10 || self.level != 1
            || !self.controlled || self.scope != nil || self.skills.length() != 0 || self.percentages.length() != 0)
            rpgExpandedReject('overstimulation-definition');
    }
    creationCost() { self.validateDefinition(); return inherited(); }
    selfControlNumber() { self.validateDefinition(); return inherited(); }
;
class RpgExpandedOverstimulationTrigger: RpgExpandedSelfControlTrigger
    situation = nil
    approved = nil
    endedAt = nil
    endReason = nil
    endEvidence = nil
    boundEnding = nil
    boundCheck = nil
    attacks = []
    definition() { return inherited() + [self.situation,self.approved]; }
    checkFacts() { return [self.check,self.check.score,self.check.roll,self.check.margin,self.check.achieved,self.check.critical]; }
    afterControlResolution(value) { self.boundCheck = self.checkFacts(); return nil; }
    assess()
    {
        local value = inherited();
        if (!self.trait.ofKind(RpgExpandedOverstimulation)) rpgExpandedReject('overstimulation-trigger-trait');
        if (value.status == 'reused')
        {
            local facts = self.checkFacts();
            if (self.boundCheck == nil || facts.length() != self.boundCheck.length()
                || self.active != (!self.check.achieved && self.endedAt == nil)) rpgExpandedReject('overstimulation-state');
            for (local i = 1; i <= facts.length(); i += 1)
                if (facts[i] != self.boundCheck[i]) rpgExpandedReject('overstimulation-check-binding');
            if (self.endedAt != nil)
            {
                if (self.boundEnding == nil || self.boundEnding[1] != self.endedAt || self.boundEnding[2] != self.endReason
                    || self.boundEnding[3] != self.endEvidence) rpgExpandedReject('overstimulation-ending-binding');
            }
            else if (self.endReason != nil || self.endEvidence != nil || self.boundEnding != nil)
                rpgExpandedReject('overstimulation-unused-ending');
            return value;
        }
        if (value.status != 'ready') return value;
        if (!self.approved || !holds(['unfamiliar-place','commotion'],self.situation))
        { value.status = 'blocked'; value.reason = 'overstimulation-stimulus-facts'; return value; }
        if (self.trait.mitigated || self.profile.dead || self.profile.unconscious)
        { value.status = 'blocked'; value.reason = 'overstimulation-unavailable'; return value; }
        if (self.profile.activeOverstimulation() != nil)
        { value.status = 'blocked'; value.reason = 'overstimulation-existing-episode'; return value; }
        return value;
    }
    end(reason,evidence)
    {
        local value = self.assess();
        if (value.status != 'reused') { value.status = 'blocked'; value.reason = 'overstimulation-not-started'; return value; }
        if (self.endedAt != nil)
        {
            if (reason != self.endReason || evidence != self.endEvidence) rpgExpandedReject('overstimulation-ending-replay');
            return value;
        }
        if (!self.active) { value.status = 'blocked'; value.reason = 'overstimulation-not-active'; return value; }
        if (!holds(['stimulus-ended','quiet-familiar-place'],reason) || evidence == nil || evidence == '')
        { value.status = 'blocked'; value.reason = 'overstimulation-ending-facts'; return value; }
        self.endedAt = rpgLedger.seconds; self.endReason = reason; self.endEvidence = evidence;
        self.boundEnding = [self.endedAt,reason,evidence]; self.active = nil;
        value.status = 'resolved'; return value;
    }
;
/** Retained evidence of an actual resolved physical attack during this episode. */
class RpgExpandedOverstimulationAttackNotice: object
    episode = nil
    attacker = nil
    defender = nil
    attack = nil
    recordedAt = nil
    boundFacts = nil
    facts()
    {
        return [self,self.episode,self.attacker,self.defender,self.attack,self.recordedAt,self.attack.status,
            self.attack.attack,self.attack.attack.score,self.attack.attack.roll,self.attack.attack.achieved,
            self.attack.outcome,self.attack.injury,self.attacker.profile,self.defender.profile,
            self.attack.attack.margin,self.attack.attack.critical];
    }
    validate()
    {
        if (self.episode == nil || !self.episode.ofKind(RpgExpandedOverstimulationTrigger)
            || self.attacker == nil || !self.attacker.ofKind(RpgLiteFighter)
            || self.defender == nil || !self.defender.ofKind(RpgLiteFighter)
            || self.episode.profile != self.defender.profile || self.attacker == self.defender
            || self.attack == nil || self.attack.attack == nil || self.attack.status != 'resolved'
            || !holds(self.episode.attacks,self) || self.boundFacts == nil) rpgExpandedReject('overstimulation-attack-notice');
        local facts = self.facts();
        if (facts.length() != self.boundFacts.length()) rpgExpandedReject('overstimulation-attack-binding');
        for (local i = 1; i <= facts.length(); i += 1)
            if (facts[i] != self.boundFacts[i]) rpgExpandedReject('overstimulation-attack-binding');
        return nil;
    }
;
modify RpgExpandedProfile
    activeOverstimulation()
    {
        local active = nil;
        foreach (local trigger in self.selfControlTriggers)
            if (trigger.ofKind(RpgExpandedOverstimulationTrigger))
            {
                trigger.assess();
                foreach (local notice in trigger.attacks) notice.validate();
                if (trigger.active)
                {
                    if (active != nil) rpgExpandedReject('overstimulation-overlapping-episodes');
                    active = trigger;
                }
            }
        return active;
    }
    validateFeatures() { inherited(); self.activeOverstimulation(); return nil; }
    healthCheckReason(context)
    {
        local reason = inherited(context); if (reason != nil) return reason;
        if (self.activeOverstimulation() != nil && (context.deliberatePlanning || context.kind == 'planning'
            || context.skill != nil && holds(['tactics','strategy'],context.skill.id))) return 'overstimulation-planning';
        return nil;
    }
    healthEffortReasonFor(purpose,mentalAbility,speech,movement,authorization)
    {
        local reason = inherited(purpose,mentalAbility,speech,movement,authorization); if (reason != nil) return reason;
        if (self.activeOverstimulation() != nil && !holds(['rest','do-nothing'],purpose)
            && !self.overstimulationCounterAllowed(authorization)) return 'overstimulation-reactive-only';
        return nil;
    }
    healthManeuverReasonFor(kind,request)
    {
        local reason = inherited(kind,request); if (reason != nil) return reason;
        if (self.activeOverstimulation() != nil && kind != 'nothing' && !self.overstimulationCounterAllowed(request))
            return 'overstimulation-do-nothing';
        return nil;
    }
    recordDirectPhysicalAttack(attacker,defender,result)
    {
        inherited(attacker,defender,result); local episode = self.activeOverstimulation();
        if (episode == nil || result == nil || result.status != 'resolved' || result.attack == nil) return nil;
        if (defender.profile != self || attacker == defender) rpgExpandedReject('overstimulation-attack-owner');
        foreach (local prior in episode.attacks) if (prior.attack == result) return prior;
        local notice = new RpgExpandedOverstimulationAttackNotice(); notice.episode = episode;
        notice.attacker = attacker; notice.defender = defender; notice.attack = result; notice.recordedAt = rpgLedger.seconds;
        episode.attacks = episode.attacks + [notice]; notice.boundFacts = notice.facts(); return notice;
    }
    overstimulationNoticeReason(notice,target)
    {
        local episode = self.activeOverstimulation();
        if (episode == nil || notice == nil || !notice.ofKind(RpgExpandedOverstimulationAttackNotice)
            || notice.episode != episode) return 'overstimulation-counterattack-notice';
        notice.validate();
        return target == notice.attacker ? nil : 'overstimulation-counterattack-target';
    }
;
modify rpgExpandedTemplateTraits
    rated(id,level,scope,rating)
    {
        if (id != 'overstimulation') return inherited(id,level,scope,rating);
        local trait = new RpgExpandedOverstimulation(); trait.level = level; trait.scope = scope;
        trait.selfControlRating = rating; trait.approved = true; trait.creationCost(); return trait;
    }
    copy(trait)
    {
        if (!trait.ofKind(RpgExpandedOverstimulation)) return inherited(trait);
        trait.creationCost(); return self.rated(trait.id,trait.level,trait.scope,trait.selfControlNumber());
    }
;

/** Complete muteness blocks panic sounds; loss of articulated speech does not. */
modify RpgExpandedProfile
    panicVocalizationReason()
    { return self.speechLimitationLevel() == 2 ? 'panic-vocalization-unavailable' : inherited(); }
;

/** B146: an authored overriding goal, with ordinary self-control pricing. */
class RpgExpandedGoalFixation: RpgExpandedDisadvantage
    id = 'goal-fixation'
    labelId = 'goal-fixation'
    templatePurchaseKind = 'expanded-goal-fixation'
    templatePurchaseOptions() { return [self.term,self.initialGoal,self.selfControlNumber()]; }
    points = -10
    controlled = true
    term = 'long-term'
    initialGoal = nil
    creationCost()
    {
        if (!self.approved || self.id != 'goal-fixation' || !self.controlled || self.level != 1
            || !holds(['short-term','long-term'],self.term) || self.points != (self.term == 'short-term' ? -5 : -10)
            || self.initialGoal == nil || self.initialGoal == '' || self.scope != nil || self.skills.length() != 0
            || self.percentages.length() != 0) rpgExpandedReject('goal-fixation-definition');
        return inherited();
    }
;
modify RpgExpandedProfile
    fixationFulfillments = []
    fixationGoalVersion(trait)
    {
        local version = nil;
        foreach (local entry in self.fixationFulfillments)
        {
            entry.validateReceipt();
            if (self.phobiaCurrentTrait(entry.trait) == self.phobiaCurrentTrait(trait)) version = entry;
        }
        return version;
    }
    fixationGoal(trait)
    {
        if (trait == nil || !trait.ofKind(RpgExpandedGoalFixation)) rpgExpandedReject('fixation-goal-trait');
        trait.creationCost(); local current = trait.initialGoal; local ids = [];
        foreach (local entry in self.fixationFulfillments)
        {
            entry.validateReceipt();
            if (entry.profile != self || holds(ids,entry.id)) rpgExpandedReject('fixation-goal-history');
            ids = ids + [entry.id];
            if (self.phobiaCurrentTrait(entry.trait) == self.phobiaCurrentTrait(trait))
            {
                if (entry.previousGoal != current) rpgExpandedReject('fixation-goal-sequence');
                current = entry.nextGoal;
            }
        }
        return current;
    }
;
/** One authored occasion when deviation would be wise; all alternatives are explicit. */
class RpgExpandedFixationTrigger: RpgExpandedSelfControlTrigger
    goal = nil
    goalVersion = nil
    deviationWise = nil
    pursuitActions = []
    boundCheck = nil
    definition() { return inherited() + [self.goal,self.goalVersion,self.deviationWise,self.pursuitActions.length()] + self.pursuitActions; }
    afterControlResolution(value)
    { self.boundCheck = [self.check,self.check.score,self.check.roll,self.check.achieved,self.check.margin,self.check.critical]; return nil; }
    assess()
    {
        local value = inherited();
        if (!self.trait.ofKind(RpgExpandedGoalFixation)) rpgExpandedReject('fixation-trigger-trait');
        if (value.status == 'reused')
        {
            local facts = [self.check,self.check.score,self.check.roll,self.check.achieved,self.check.margin,self.check.critical];
            if (self.boundCheck == nil || self.active != !self.check.achieved) rpgExpandedReject('fixation-check-binding');
            for (local i = 1; i <= facts.length(); i += 1)
                if (facts[i] != self.boundCheck[i]) rpgExpandedReject('fixation-check-binding');
            return value;
        }
        if (value.status != 'ready') return value;
        self.trait.creationCost();
        if (!self.deviationWise || self.goal == nil || self.goal != self.profile.fixationGoal(self.trait)
            || self.goalVersion != self.profile.fixationGoalVersion(self.trait)
            || self.pursuitActions.length() == 0) { value.status = 'blocked'; value.reason = 'fixation-trigger-facts'; return value; }
        local seen = [];
        foreach (local action in self.pursuitActions)
        {
            if (action == nil || holds(seen,action)) rpgExpandedReject('fixation-pursuit-actions');
            seen = seen + [action];
        }
        return value;
    }
    permits(action)
    {
        if (self.result == nil) return nil;
        self.assess();
        local current = self.profile.phobiaCurrentTrait(self.trait);
        if (!holds(self.profile.traits,current) || !current.active || current.mitigated
            || self.profile.fixationGoalVersion(self.trait) != self.goalVersion) return true;
        return !self.active || holds(self.pursuitActions,action);
    }
;
/** Completed goal: retain the authored world fact and either replace it or fund buyoff. */
class RpgExpandedFixationFulfillment: object
    id = nil
    profile = nil
    trait = nil
    previousGoal = nil
    nextGoal = nil
    approved = nil
    evidence = nil
    result = nil
    boundFacts = nil
    recordedAt = nil
    chargedPoints = nil
    facts()
    {
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)
            || self.trait == nil || !self.trait.ofKind(RpgExpandedGoalFixation)) rpgExpandedReject('fixation-fulfillment-definition');
        self.trait.creationCost();
        return [self.id,self.profile,self.trait,self.previousGoal,self.nextGoal,self.approved,self.evidence,
            self.trait.initialGoal,self.trait.term,self.recordedAt,self.chargedPoints];
    }
    validateReceipt()
    {
        local facts = self.facts();
        if (self.result == nil || self.boundFacts == nil || !holds(self.profile.fixationFulfillments,self))
            rpgExpandedReject('fixation-fulfillment-history');
        for (local i = 1; i <= facts.length(); i += 1)
            if (facts[i] != self.boundFacts[i]) rpgExpandedReject('fixation-fulfillment-binding');
        return nil;
    }
    assess()
    {
        self.facts(); local value = new RpgExpandedResult();
        if (self.result != nil) { self.validateReceipt(); value.status = 'reused'; value.points = self.chargedPoints; return value; }
        if (self.recordedAt != nil || self.chargedPoints != nil || self.boundFacts != nil) rpgExpandedReject('fixation-fulfillment-uncommitted');
        if (!self.approved || self.evidence == nil || self.evidence == '') { value.reason = 'fixation-fulfillment-evidence'; return value; }
        if (!holds(self.profile.traits,self.trait) || self.profile.phobiaCurrentTrait(self.trait) != self.trait
            || self.previousGoal == nil || self.previousGoal != self.profile.fixationGoal(self.trait))
        { value.reason = 'fixation-fulfillment-current-goal'; return value; }
        foreach (local entry in self.profile.fixationFulfillments)
            if (entry.id == self.id) rpgExpandedReject('fixation-fulfillment-duplicate');
        if (self.nextGoal != nil)
        {
            if (self.nextGoal == '' || self.nextGoal == self.previousGoal) rpgExpandedReject('fixation-replacement-goal');
            value.points = 0;
        }
        else
        {
            if (!self.profile.developmentOpen) { value.reason = 'rpg.downtime-required'; return value; }
            value.points = self.profile.disadvantageBuyoffCost(self.trait);
            if (value.points == nil) { value.reason = 'buyoff-original-cost-required'; return value; }
            value.reason = self.profile.developmentSpendingReason(); if (value.reason != nil) return value;
            if (self.profile.unspentPoints < value.points) { value.reason = 'rpg.insufficient-points'; return value; }
        }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        if (self.nextGoal == nil && !rpgLiteBuyOff(self.profile,self.trait)) rpgExpandedReject('fixation-buyoff-changed');
        self.recordedAt = rpgLedger.seconds; self.chargedPoints = value.points; self.result = value;
        self.boundFacts = self.facts(); self.profile.fixationFulfillments = self.profile.fixationFulfillments + [self];
        value.status = 'resolved'; return value;
    }
;

/** Specific author interface: rationalize a concrete action or resolve wise deviation. */
class RpgExpandedFixationActionPermission: object
    profile = nil
    trait = nil
    goal = nil
    action = nil
    rationale = nil
    deviation = nil
    approved = nil
    assess()
    {
        if (self.profile == nil || !self.profile.ofKind(RpgExpandedProfile) || self.trait == nil
            || !self.trait.ofKind(RpgExpandedGoalFixation) || self.action == nil) rpgExpandedReject('fixation-action-definition');
        local value = new RpgExpandedResult(); local current = self.profile.phobiaCurrentTrait(self.trait);
        if (!holds(self.profile.traits,current) || !current.active || current.mitigated) { value.status = 'ready'; return value; }
        if (!self.approved || self.rationale == nil || self.rationale == '' || self.goal != self.profile.fixationGoal(self.trait))
        { value.reason = 'fixation-action-rationale'; return value; }
        if (self.deviation != nil)
        {
            if (!self.deviation.ofKind(RpgExpandedFixationTrigger) || self.deviation.profile != self.profile
                || self.profile.phobiaCurrentTrait(self.deviation.trait) != current || self.deviation.goal != self.goal
                || self.deviation.goalVersion != self.profile.fixationGoalVersion(self.trait))
                rpgExpandedReject('fixation-action-deviation-owner');
            if (!self.deviation.permits(self.action)) { value.reason = 'fixation-action-pursuit-required'; return value; }
        }
        value.status = 'ready'; return value;
    }
;

modify rpgExpandedTemplateTraits
    configured(id,level,scope,options)
    {
        if (id != 'goal-fixation') return inherited(id,level,scope,options);
        if (scope != nil || options.length() != 3) rpgExpandedReject('goal-fixation-template-options');
        local trait = new RpgExpandedGoalFixation(); trait.approved = true; trait.level = level;
        trait.term = options[1]; trait.initialGoal = options[2]; trait.selfControlRating = options[3];
        if (!holds([6,9,12,15],trait.selfControlRating)) rpgExpandedReject('self-control-rating');
        trait.points = trait.term == 'short-term' ? -5 : -10; trait.creationCost(); return trait;
    }
    plain(id,level,scope)
    {
        if (id == 'goal-fixation') rpgExpandedReject('goal-fixation-template-options');
        return inherited(id,level,scope);
    }
    rated(id,level,scope,rating)
    {
        if (id == 'goal-fixation') rpgExpandedReject('goal-fixation-template-options');
        return inherited(id,level,scope,rating);
    }
    copy(trait)
    {
        if (!trait.ofKind(RpgExpandedGoalFixation)) return inherited(trait);
        trait.creationCost();
        if (trait.labelId != trait.id) rpgExpandedReject('goal-fixation-template-definition');
        return self.configured(trait.id,trait.level,trait.scope,trait.templatePurchaseOptions());
    }
;

/** B139: impulsive action at an authored opportunity for wise deliberation. */
class RpgExpandedImpulsiveAction: RpgExpandedDisadvantage
    id = 'impulsive-action'
    labelId = 'impulsive-action'
    points = -10
    controlled = true
    templatePurchaseKind = 'expanded-impulsive-action'
    validateDefinition()
    {
        if (!self.approved || self.id != 'impulsive-action' || self.points != -10 || self.level != 1
            || !self.controlled || self.scope != nil || self.skills.length() != 0 || self.percentages.length() != 0)
            rpgExpandedReject('impulsive-action-definition');
        return nil;
    }
    creationCost() { self.validateDefinition(); return inherited(); }
    selfControlNumber() { self.validateDefinition(); return inherited(); }
;
class RpgExpandedImpulsiveActionTrigger: RpgExpandedSelfControlTrigger
    waitingWise = nil
    immediateActions = []
    deliberativeActions = []
    completedAction = nil
    completedAt = nil
    completionEvidence = nil
    boundCompletion = nil
    boundCheck = nil
    definition()
    { return inherited() + [self.waitingWise,self.immediateActions.length(),self.deliberativeActions.length()]
        + self.immediateActions + self.deliberativeActions; }
    afterControlResolution(value)
    { self.boundCheck = [self.check,self.check.score,self.check.roll,self.check.achieved,self.check.margin,self.check.critical]; return nil; }
    assess()
    {
        local value = inherited();
        if (!self.trait.ofKind(RpgExpandedImpulsiveAction)) rpgExpandedReject('impulsive-action-trigger-trait');
        if (value.status == 'reused')
        {
            local facts = [self.check,self.check.score,self.check.roll,self.check.achieved,self.check.margin,self.check.critical];
            if (self.boundCheck == nil || self.active != (!self.check.achieved && self.completedAt == nil))
                rpgExpandedReject('impulsive-action-check-binding');
            for (local i = 1; i <= facts.length(); i += 1)
                if (facts[i] != self.boundCheck[i]) rpgExpandedReject('impulsive-action-check-binding');
            if (self.completedAt != nil)
            {
                if (self.boundCompletion == nil || self.completedAction != self.boundCompletion[1]
                    || self.completedAt != self.boundCompletion[2] || self.completionEvidence != self.boundCompletion[3])
                    rpgExpandedReject('impulsive-action-completion-binding');
            }
            else if (self.completedAction != nil || self.completionEvidence != nil || self.boundCompletion != nil)
                rpgExpandedReject('impulsive-action-uncommitted-completion');
            return value;
        }
        if (self.completedAction != nil || self.completedAt != nil || self.completionEvidence != nil
            || self.boundCompletion != nil || self.boundCheck != nil)
            rpgExpandedReject('impulsive-action-uncommitted-completion');
        if (value.status != 'ready') return value;
        if (!self.waitingWise || self.immediateActions.length() == 0 || self.deliberativeActions.length() == 0)
        { value.status = 'blocked'; value.reason = 'impulsive-action-alternatives'; return value; }
        local seen = [];
        foreach (local action in self.immediateActions + self.deliberativeActions)
        {
            if (action == nil || holds(seen,action)) rpgExpandedReject('impulsive-action-classification');
            seen = seen + [action];
        }
        return value;
    }
    permits(action)
    {
        if (self.result == nil) return nil;
        self.assess();
        if (self.completedAt != nil) return action == self.completedAction;
        local current = self.profile.phobiaCurrentTrait(self.trait);
        if (!holds(self.profile.traits,current) || !current.active || current.mitigated) return true;
        return holds(self.immediateActions,action) || self.check.achieved && holds(self.deliberativeActions,action);
    }
    recordAction(action,evidence)
    {
        if (self.result == nil || evidence == nil || evidence == '' || !self.permits(action))
            rpgExpandedReject('impulsive-action-execution-required');
        local value = new RpgExpandedResult();
        if (self.completedAt != nil)
        {
            if (self.completedAction != action || self.completionEvidence != evidence) rpgExpandedReject('impulsive-action-completion-binding');
            value.status = 'reused'; return value;
        }
        self.completedAction = action; self.completedAt = rpgLedger.seconds; self.completionEvidence = evidence;
        self.boundCompletion = [action,self.completedAt,evidence]; self.active = nil;
        value.status = 'resolved'; return value;
    }
;
modify rpgExpandedTemplateTraits
    rated(id,level,scope,rating)
    {
        if (id != 'impulsive-action') return inherited(id,level,scope,rating);
        if (!holds([6,9,12,15],rating)) rpgExpandedReject('self-control-rating');
        local trait = new RpgExpandedImpulsiveAction(); trait.approved = true; trait.level = level;
        trait.scope = scope; trait.selfControlRating = rating; trait.creationCost(); return trait;
    }
    copy(trait)
    {
        if (!trait.ofKind(RpgExpandedImpulsiveAction)) return inherited(trait);
        trait.creationCost(); return self.rated(trait.id,trait.level,trait.scope,trait.selfControlNumber());
    }
;

/** B124: an authored hostile response to the specific cause of stress. */
class RpgExpandedVolatileTemper: RpgExpandedDisadvantage
    id = 'bad-temper'
    labelId = 'bad-temper'
    points = -10
    controlled = true
    templatePurchaseKind = 'expanded-volatile-temper'
    validateDefinition()
    {
        if (!self.approved || self.id != 'bad-temper' || self.points != -10 || self.level != 1
            || !self.controlled || self.scope != nil || self.skills.length() != 0 || self.percentages.length() != 0)
            rpgExpandedReject('volatile-temper-definition');
        return nil;
    }
    creationCost() { self.validateDefinition(); return inherited(); }
    selfControlNumber() { self.validateDefinition(); return inherited(); }
;
class RpgExpandedVolatileTemperTrigger: RpgExpandedSelfControlTrigger
    matchesTrait() { return self.trait.ofKind(RpgExpandedVolatileTemper); }
    stressful = nil
    stressor = nil
    stressRelation = 'stress-related'
    hostileActions = []
    restrainedActions = []
    completedAction = nil
    completedAt = nil
    completionEvidence = nil
    boundCompletion = nil
    boundCheck = nil
    definition()
    { return inherited() + [self.stressful,self.stressor,self.hostileActions.length(),self.restrainedActions.length()]
        + self.hostileActions + self.restrainedActions; }
    afterControlResolution(value)
    { self.boundCheck = [self.check,self.check.score,self.check.roll,self.check.achieved,self.check.margin,self.check.critical]; return nil; }
    assess()
    {
        local value = inherited();
        if (!self.matchesTrait()) rpgExpandedReject('volatile-temper-trigger-trait');
        if (value.status == 'reused')
        {
            local facts = [self.check,self.check.score,self.check.roll,self.check.achieved,self.check.margin,self.check.critical];
            if (self.boundCheck == nil || self.active != (!self.check.achieved && self.completedAt == nil))
                rpgExpandedReject('volatile-temper-check-binding');
            for (local i = 1; i <= facts.length(); i += 1)
                if (facts[i] != self.boundCheck[i]) rpgExpandedReject('volatile-temper-check-binding');
            if (self.completedAt != nil)
            {
                if (self.boundCompletion == nil || self.completedAction != self.boundCompletion[1]
                    || self.completedAt != self.boundCompletion[2] || self.completionEvidence != self.boundCompletion[3])
                    rpgExpandedReject('volatile-temper-completion-binding');
            }
            else if (self.completedAction != nil || self.completionEvidence != nil || self.boundCompletion != nil)
                rpgExpandedReject('volatile-temper-uncommitted-completion');
            return value;
        }
        if (self.completedAction != nil || self.completedAt != nil || self.completionEvidence != nil
            || self.boundCompletion != nil || self.boundCheck != nil)
            rpgExpandedReject('volatile-temper-uncommitted-completion');
        if (value.status != 'ready') return value;
        foreach (local purchase in self.profile.traits)
            if (purchase.active && !purchase.mitigated && holds(['uncontrolled-rage','berserk'],purchase.id))
            { value.status = 'blocked'; value.reason = 'volatile-temper-rage-adapter-required'; return value; }
        if (!self.stressful || self.stressor == nil || self.stressRelation != 'stress-related' || self.hostileActions.length() == 0 || self.restrainedActions.length() == 0)
        { value.status = 'blocked'; value.reason = 'volatile-temper-alternatives'; return value; }
        local seen = [];
        foreach (local action in self.hostileActions + self.restrainedActions)
        {
            if (action == nil || holds(seen,action)) rpgExpandedReject('volatile-temper-classification');
            seen = seen + [action];
        }
        return value;
    }
    permits(action)
    {
        if (self.result == nil) return nil;
        self.assess();
        if (self.completedAt != nil) return action == self.completedAction;
        local current = self.profile.phobiaCurrentTrait(self.trait);
        if (!holds(self.profile.traits,current) || !current.active || current.mitigated) return true;
        return holds(self.hostileActions,action) || self.check.achieved && holds(self.restrainedActions,action);
    }
    recordAction(action,evidence)
    {
        if (self.result == nil || evidence == nil || evidence == '' || !self.permits(action))
            rpgExpandedReject('volatile-temper-execution-required');
        local value = new RpgExpandedResult();
        if (self.completedAt != nil)
        {
            if (self.completedAction != action || self.completionEvidence != evidence) rpgExpandedReject('volatile-temper-completion-binding');
            value.status = 'reused'; return value;
        }
        self.completedAction = action; self.completedAt = rpgLedger.seconds; self.completionEvidence = evidence;
        self.boundCompletion = [action,self.completedAt,evidence]; self.active = nil;
        value.status = 'resolved'; return value;
    }
;
modify rpgExpandedTemplateTraits
    rated(id,level,scope,rating)
    {
        if (id != 'bad-temper') return inherited(id,level,scope,rating);
        if (!holds([6,9,12,15],rating)) rpgExpandedReject('self-control-rating');
        local trait = new RpgExpandedVolatileTemper(); trait.approved = true; trait.level = level;
        trait.scope = scope; trait.selfControlRating = rating; trait.creationCost(); return trait;
    }
    copy(trait)
    {
        if (!trait.ofKind(RpgExpandedVolatileTemper)) return inherited(trait);
        trait.creationCost(); return self.rated(trait.id,trait.level,trait.scope,trait.selfControlNumber());
    }
;

/** B144-B145: rated nightmares; waking owns the check and its consequences. */
class RpgExpandedNightmares: RpgExpandedDisadvantage
    id = 'nightmares'
    labelId = 'nightmares'
    points = -5
    controlled = true
    templatePurchaseKind = 'expanded-nightmares'
    validateDefinition()
    {
        if (!self.approved || self.id != 'nightmares' || self.points != -5 || self.level != 1
            || !self.controlled || self.scope != nil || self.skills.length() != 0 || self.percentages.length() != 0)
            rpgExpandedReject('nightmares-definition');
        return nil;
    }
    creationCost() { self.validateDefinition(); return inherited(); }
    selfControlNumber() { self.validateDefinition(); return inherited(); }
;
class RpgExpandedNightmareWaking: object
    id = nil
    profile = nil
    control = nil
    day = nil
    dayEndsAt = nil
    morningConfirmed = nil
    evidence = nil
    dropDestination = nil
    loss = nil
    result = nil
    recordedAt = nil
    boundFacts = nil
    boundOutcome = nil
    facts()
    {
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)
            || self.control == nil || !self.control.ofKind(RpgExpandedSelfControlTrigger)
            || self.control.profile != self.profile || self.control.trait == nil
            || !self.control.trait.ofKind(RpgExpandedNightmares)) rpgExpandedReject('nightmare-waking-definition');
        return [self.id,self.profile,self.control,self.day,self.dayEndsAt,self.morningConfirmed,self.evidence,
            self.dropDestination] + self.control.definition();
    }
    outcomeFacts()
    {
        local check = self.control.check;
        return [self.result,self.result.status,self.recordedAt,self.loss,check,
            check.score,check.roll,check.achieved,check.margin,check.critical];
    }
    validateReceipt()
    {
        local facts = self.facts();
        if (self.result == nil || !holds(self.profile.nightmareWakings,self) || self.boundFacts == nil
            || facts.length() != self.boundFacts.length()) rpgExpandedReject('nightmare-waking-history');
        for (local i = 1; i <= facts.length(); i += 1)
            if (facts[i] != self.boundFacts[i]) rpgExpandedReject('nightmare-waking-binding');
        facts = self.outcomeFacts();
        if (self.boundOutcome == nil || facts.length() != self.boundOutcome.length()) rpgExpandedReject('nightmare-waking-outcome');
        for (local i = 1; i <= facts.length(); i += 1)
            if (facts[i] != self.boundOutcome[i]) rpgExpandedReject('nightmare-waking-outcome');
        if (self.control.active || self.control.assess().status != 'reused') rpgExpandedReject('nightmare-control-receipt');
        if (!self.control.check.achieved)
        {
            if (self.loss == nil || self.loss.id != self.id || self.loss.profile != self.profile
                || self.loss.amount != 1 || self.loss.dropDestination != self.dropDestination
                || self.loss.assess().status != 'reused') rpgExpandedReject('nightmare-fatigue-receipt');
        }
        else if (self.loss != nil) rpgExpandedReject('nightmare-unexpected-fatigue');
        return nil;
    }
    assess()
    {
        self.facts(); local value = new RpgExpandedResult();
        if (self.result != nil) { self.validateReceipt(); value.status = 'reused'; return value; }
        if (self.loss != nil || self.recordedAt != nil || self.boundFacts != nil || self.boundOutcome != nil)
            rpgExpandedReject('nightmare-uncommitted');
        if (!self.morningConfirmed || self.day == nil || self.evidence == nil || self.evidence == '')
        { value.reason = 'nightmare-waking-evidence'; return value; }
        rpgInteger(self.dayEndsAt,rpgLedger.seconds+1,2147483647);
        if (self.control.trait.mitigated) { value.reason = 'nightmare-trait-mitigated'; return value; }
        if (self.profile.dead || self.profile.unconscious) { value.reason = 'nightmare-not-awake'; return value; }
        foreach (local prior in self.profile.nightmareWakings)
        {
            prior.validateReceipt();
            if (prior.id == self.id || prior.day == self.day || prior.dayEndsAt > rpgLedger.seconds)
            { value.reason = 'nightmare-day-already-recorded'; return value; }
        }
        local check = self.control.assess();
        if (check.status == 'reused') { value.reason = 'nightmare-control-already-used'; return value; }
        if (check.status != 'ready') return check;
        local loss = self.profile.newNightmareFatigueLoss(); loss.id = self.id; loss.profile = self.profile;
        loss.dropDestination = self.dropDestination;
        local fatigue = loss.assess(); if (fatigue.status != 'ready') return fatigue;
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local facts = self.facts(); local check = self.control.resolve();
        if (check.status != 'resolved') rpgExpandedReject('nightmare-control-changed');
        if (!check.check.achieved)
        {
            local loss = self.profile.newNightmareFatigueLoss(); loss.id = self.id; loss.profile = self.profile;
            loss.dropDestination = self.dropDestination;
            if (loss.apply().status != 'resolved') rpgExpandedReject('nightmare-fatigue-changed');
            self.loss = loss;
        }
        self.control.active = nil;
        self.recordedAt = rpgLedger.seconds; value.status = 'resolved'; self.result = value;
        self.boundFacts = facts; self.boundOutcome = self.outcomeFacts();
        self.profile.nightmareWakings = self.profile.nightmareWakings + [self]; return value;
    }
    shaking()
    {
        self.validateReceipt();
        return rpgLedger.seconds >= self.recordedAt && rpgLedger.seconds < self.dayEndsAt
            && holds([17,18],self.control.check.roll);
    }
;
modify RpgExpandedProfile
    nightmareWakings = []
    validateFeatures() { inherited(); self.nightmareShaking(); return nil; }
    nightmareShaking()
    {
        local active = nil;
        foreach (local waking in self.nightmareWakings) if (waking.shaking()) active = true;
        return active;
    }
    healthAttributeModifier(context)
    {
        local value = inherited(context);
        if ((context.skill != nil || context.controllingAttribute() == rpgPerception) && self.nightmareShaking()) value -= 1;
        return value;
    }
;
modify rpgExpandedTemplateTraits
    rated(id,level,scope,rating)
    {
        if (id != 'nightmares') return inherited(id,level,scope,rating);
        if (!holds([6,9,12,15],rating)) rpgExpandedReject('self-control-rating');
        local trait = new RpgExpandedNightmares(); trait.approved = true; trait.level = level;
        trait.scope = scope; trait.selfControlRating = rating; trait.creationCost(); return trait;
    }
    copy(trait)
    {
        if (!trait.ofKind(RpgExpandedNightmares)) return inherited(trait);
        trait.creationCost(); return self.rated(trait.id,trait.level,trait.scope,trait.selfControlNumber());
    }
;

/** B148: an authored challenge where caution is unreasonably excessive. */
class RpgExpandedOverconfidence: RpgExpandedDisadvantage
    id = 'overconfidence'
    labelId = 'overconfidence'
    points = -5
    controlled = true
    templatePurchaseKind = 'expanded-overconfidence'
    validateDefinition()
    {
        if (!self.approved || self.id != 'overconfidence' || self.points != -5 || self.level != 1
            || !self.controlled || self.scope != nil || self.skills.length() != 0 || self.percentages.length() != 0)
            rpgExpandedReject('overconfidence-definition');
        return nil;
    }
    creationCost() { self.validateDefinition(); return inherited(); }
    selfControlNumber() { self.validateDefinition(); return inherited(); }
;
class RpgExpandedOverconfidenceTrigger: RpgExpandedSelfControlTrigger
    cautionUnreasonable = nil
    confidentActions = []
    cautiousActions = []
    completedAction = nil
    completedAt = nil
    completionEvidence = nil
    boundCompletion = nil
    boundCheck = nil
    definition()
    { return inherited() + [self.cautionUnreasonable,self.confidentActions.length(),self.cautiousActions.length()]
        + self.confidentActions + self.cautiousActions; }
    afterControlResolution(value)
    { self.boundCheck = [self.check,self.check.score,self.check.roll,self.check.achieved,self.check.margin,self.check.critical]; return nil; }
    assess()
    {
        local value = inherited();
        if (!self.trait.ofKind(RpgExpandedOverconfidence)) rpgExpandedReject('overconfidence-trigger-trait');
        if (value.status == 'reused')
        {
            local facts = [self.check,self.check.score,self.check.roll,self.check.achieved,self.check.margin,self.check.critical];
            if (self.boundCheck == nil || self.active != (!self.check.achieved && self.completedAt == nil))
                rpgExpandedReject('overconfidence-check-binding');
            for (local i = 1; i <= facts.length(); i += 1)
                if (facts[i] != self.boundCheck[i]) rpgExpandedReject('overconfidence-check-binding');
            if (self.completedAt != nil)
            {
                if (self.boundCompletion == nil || self.completedAction != self.boundCompletion[1]
                    || self.completedAt != self.boundCompletion[2] || self.completionEvidence != self.boundCompletion[3])
                    rpgExpandedReject('overconfidence-completion-binding');
            }
            else if (self.completedAction != nil || self.completionEvidence != nil || self.boundCompletion != nil)
                rpgExpandedReject('overconfidence-uncommitted-completion');
            return value;
        }
        if (self.completedAction != nil || self.completedAt != nil || self.completionEvidence != nil
            || self.boundCompletion != nil || self.boundCheck != nil)
            rpgExpandedReject('overconfidence-uncommitted-completion');
        if (value.status != 'ready') return value;
        if (!self.cautionUnreasonable || self.confidentActions.length() == 0 || self.cautiousActions.length() == 0)
        { value.status = 'blocked'; value.reason = 'overconfidence-alternatives'; return value; }
        local seen = [];
        foreach (local action in self.confidentActions + self.cautiousActions)
        {
            if (action == nil || holds(seen,action)) rpgExpandedReject('overconfidence-classification');
            seen = seen + [action];
        }
        return value;
    }
    permits(action)
    {
        if (self.result == nil) return nil;
        self.assess();
        if (self.completedAt != nil) return action == self.completedAction;
        local current = self.profile.phobiaCurrentTrait(self.trait);
        if (!holds(self.profile.traits,current) || !current.active || current.mitigated) return true;
        return holds(self.confidentActions,action) || self.check.achieved && holds(self.cautiousActions,action);
    }
    recordAction(action,evidence)
    {
        if (self.result == nil || evidence == nil || evidence == '' || !self.permits(action))
            rpgExpandedReject('overconfidence-execution-required');
        local value = new RpgExpandedResult();
        if (self.completedAt != nil)
        {
            if (self.completedAction != action || self.completionEvidence != evidence) rpgExpandedReject('overconfidence-completion-binding');
            value.status = 'reused'; return value;
        }
        self.completedAction = action; self.completedAt = rpgLedger.seconds; self.completionEvidence = evidence;
        self.boundCompletion = [action,self.completedAt,evidence]; self.active = nil;
        value.status = 'resolved'; return value;
    }
;
modify rpgExpandedTemplateTraits
    rated(id,level,scope,rating)
    {
        if (id != 'overconfidence') return inherited(id,level,scope,rating);
        if (!holds([6,9,12,15],rating)) rpgExpandedReject('self-control-rating');
        local trait = new RpgExpandedOverconfidence(); trait.approved = true; trait.level = level;
        trait.scope = scope; trait.selfControlRating = rating; trait.creationCost(); return trait;
    }
    copy(trait)
    {
        if (!trait.ofKind(RpgExpandedOverconfidence)) return inherited(trait);
        trait.creationCost(); return self.rated(trait.id,trait.level,trait.scope,trait.selfControlNumber());
    }
;


modify RpgExpandedProfile
    overconfidenceActive()
    {
        local found = nil;
        foreach (local trait in self.traits)
            if (trait.id == 'overconfidence')
            {
                if (!trait.ofKind(RpgExpandedOverconfidence) || found != nil) rpgExpandedReject('overconfidence-purchase');
                trait.creationCost(); found = trait;
            }
        return found != nil && found.active && !found.mitigated;
    }
    validateFeatures() { inherited(); self.overconfidenceActive(); return nil; }
;


/** B142: unwanted proximity invokes the same owned hostile-response procedure. */
class RpgExpandedSolitude: RpgExpandedDisadvantage
    id = 'solitude'
    labelId = 'solitude'
    points = -5
    controlled = true
    templatePurchaseKind = 'expanded-solitude'
    validateDefinition()
    {
        if (!self.approved || self.id != 'solitude' || self.points != -5 || self.level != 1
            || !self.controlled || self.scope != nil || self.skills.length() != 0 || self.percentages.length() != 0)
            rpgExpandedReject('solitude-definition');
        return nil;
    }
    creationCost() { self.validateDefinition(); return inherited(); }
    selfControlNumber() { self.validateDefinition(); return inherited(); }
;
class RpgExpandedSolitudeTrigger: RpgExpandedVolatileTemperTrigger
    stressful = true
    proximityUnwanted = nil
    person = nil
    matchesTrait() { return self.trait.ofKind(RpgExpandedSolitude); }
    definition() { return inherited() + [self.proximityUnwanted,self.person]; }
    assess()
    {
        local value = inherited(); if (value.status != 'ready') return value;
        if (!self.proximityUnwanted || self.person == nil || !self.person.ofKind(RpgLiteProfile)
            || self.person == self.profile || self.stressor != self.person)
        { value.status = 'blocked'; value.reason = 'solitude-proximity-facts'; }
        return value;
    }
;
modify RpgExpandedProfile
    solitudeReactionPenalty()
    {
        local found = nil;
        foreach (local trait in self.traits)
            if (trait.id == 'solitude')
            {
                if (!trait.ofKind(RpgExpandedSolitude) || found != nil) rpgExpandedReject('solitude-purchase');
                trait.creationCost(); found = trait;
            }
        return found == nil || !found.active || found.mitigated ? 0 : -(18-found.selfControlNumber()) / 3;
    }
    validateFeatures() { inherited(); self.solitudeReactionPenalty(); return nil; }
;
modify rpgExpandedTemplateTraits
    rated(id,level,scope,rating)
    {
        if (id != 'solitude') return inherited(id,level,scope,rating);
        if (!holds([6,9,12,15],rating)) rpgExpandedReject('self-control-rating');
        local trait = new RpgExpandedSolitude(); trait.approved = true; trait.level = level;
        trait.scope = scope; trait.selfControlRating = rating; trait.creationCost(); return trait;
    }
    copy(trait)
    {
        if (!trait.ofKind(RpgExpandedSolitude)) return inherited(trait);
        trait.creationCost(); return self.rated(trait.id,trait.level,trait.scope,trait.selfControlNumber());
    }
;

/** B153: a clear social slight invokes the same owned hostile-response procedure. */
class RpgExpandedStatusSensitivity: RpgExpandedDisadvantage
    id = 'status-sensitivity'
    labelId = 'status-sensitivity'
    points = -5
    controlled = true
    templatePurchaseKind = 'expanded-status-sensitivity'
    validateDefinition()
    {
        if (!self.approved || self.id != 'status-sensitivity' || self.points != -5 || self.level != 1
            || !self.controlled || self.scope != nil || self.skills.length() != 0 || self.percentages.length() != 0)
            rpgExpandedReject('status-sensitivity-definition');
        return nil;
    }
    creationCost() { self.validateDefinition(); return inherited(); }
    selfControlNumber() { self.validateDefinition(); return inherited(); }
;
class RpgExpandedStatusSensitivityTrigger: RpgExpandedVolatileTemperTrigger
    stressful = true
    clearSlight = nil
    person = nil
    matchesTrait() { return self.trait.ofKind(RpgExpandedStatusSensitivity); }
    definition() { return inherited() + [self.clearSlight,self.person]; }
    assess()
    {
        local value = inherited(); if (value.status != 'ready') return value;
        if (!self.clearSlight || self.person == nil || !self.person.ofKind(RpgLiteProfile)
            || self.person == self.profile || self.stressor != self.person)
        { value.status = 'blocked'; value.reason = 'status-sensitivity-slight-facts'; }
        return value;
    }
;
modify RpgExpandedProfile
    statusSensitivityReactionPenalty()
    {
        local found = nil;
        foreach (local trait in self.traits)
            if (trait.id == 'status-sensitivity')
            {
                if (!trait.ofKind(RpgExpandedStatusSensitivity) || found != nil) rpgExpandedReject('status-sensitivity-purchase');
                trait.creationCost(); found = trait;
            }
        return found == nil || !found.active || found.mitigated ? 0 : -(21-found.selfControlNumber()) / 3;
    }
    validateFeatures() { inherited(); self.statusSensitivityReactionPenalty(); return nil; }
;
modify rpgExpandedTemplateTraits
    rated(id,level,scope,rating)
    {
        if (id != 'status-sensitivity') return inherited(id,level,scope,rating);
        if (!holds([6,9,12,15],rating)) rpgExpandedReject('self-control-rating');
        local trait = new RpgExpandedStatusSensitivity(); trait.approved = true; trait.level = level;
        trait.scope = scope; trait.selfControlRating = rating; trait.creationCost(); return trait;
    }
    copy(trait)
    {
        if (!trait.ofKind(RpgExpandedStatusSensitivity)) return inherited(trait);
        trait.creationCost(); return self.rated(trait.id,trait.level,trait.scope,trait.selfControlNumber());
    }
;

modify RpgExpandedProfile
    validateStatusOutburst(trigger,observer)
    {
        if (trigger == nil || !trigger.ofKind(RpgExpandedStatusSensitivityTrigger)
            || trigger.profile != self || trigger.person != observer)
            rpgExpandedReject('status-outburst-participants');
        if (trigger.result == nil || trigger.assess().status != 'reused' || trigger.check.achieved
            || trigger.completedAt == nil || !holds(trigger.hostileActions,trigger.completedAction))
            rpgExpandedReject('status-outburst-execution-required');
        return nil;
    }
;

/** full-2008 B153: choosing between another person's needs and one's own. */
class RpgExpandedSelfSacrifice: RpgExpandedDisadvantage
    id = 'self-sacrifice'
    labelId = 'self-sacrifice'
    points = -5
    controlled = true
    templatePurchaseKind = 'expanded-self-sacrifice'
    validateDefinition()
    {
        if (!self.approved || self.id != 'self-sacrifice' || self.points != -5 || self.level != 1
            || !self.controlled || self.scope != nil || self.skills.length() != 0 || self.percentages.length() != 0)
            rpgExpandedReject('self-sacrifice-definition');
        return nil;
    }
    creationCost() { self.validateDefinition(); return inherited(); }
    selfControlNumber() { self.validateDefinition(); return inherited(); }
;
class RpgExpandedSelfSacrificeTrigger: RpgExpandedSelfControlTrigger
    person = nil
    competingNeeds = nil
    otherFirstActions = []
    selfFirstActions = []
    completedAction = nil
    completedAt = nil
    completionEvidence = nil
    boundCompletion = nil
    boundCheck = nil
    definition()
    { return inherited() + [self.person,self.competingNeeds,self.otherFirstActions.length(),self.selfFirstActions.length()]
        + self.otherFirstActions + self.selfFirstActions; }
    afterControlResolution(value)
    { self.boundCheck = [self.check,self.check.score,self.check.roll,self.check.achieved,self.check.margin,self.check.critical]; return nil; }
    assess()
    {
        local value = inherited();
        if (!self.trait.ofKind(RpgExpandedSelfSacrifice)) rpgExpandedReject('self-sacrifice-trigger-trait');
        if (value.status == 'reused')
        {
            local facts = [self.check,self.check.score,self.check.roll,self.check.achieved,self.check.margin,self.check.critical];
            if (self.boundCheck == nil || self.active != (!self.check.achieved && self.completedAt == nil))
                rpgExpandedReject('self-sacrifice-check-binding');
            for (local i = 1; i <= facts.length(); i += 1)
                if (facts[i] != self.boundCheck[i]) rpgExpandedReject('self-sacrifice-check-binding');
            if (self.completedAt != nil)
            {
                if (self.boundCompletion == nil || self.completedAction != self.boundCompletion[1]
                    || self.completedAt != self.boundCompletion[2] || self.completionEvidence != self.boundCompletion[3])
                    rpgExpandedReject('self-sacrifice-completion-binding');
            }
            else if (self.completedAction != nil || self.completionEvidence != nil || self.boundCompletion != nil)
                rpgExpandedReject('self-sacrifice-uncommitted-completion');
            return value;
        }
        if (self.completedAction != nil || self.completedAt != nil || self.completionEvidence != nil
            || self.boundCompletion != nil || self.boundCheck != nil)
            rpgExpandedReject('self-sacrifice-uncommitted-completion');
        if (value.status != 'ready') return value;
        if (self.person == nil || !self.person.ofKind(RpgLiteProfile) || self.person == self.profile
            || !self.competingNeeds || self.otherFirstActions.length() == 0 || self.selfFirstActions.length() == 0)
        { value.status = 'blocked'; value.reason = 'self-sacrifice-alternatives'; return value; }
        local seen = [];
        foreach (local action in self.otherFirstActions + self.selfFirstActions)
        {
            if (action == nil || holds(seen,action)) rpgExpandedReject('self-sacrifice-classification');
            seen = seen + [action];
        }
        return value;
    }
    permits(action)
    {
        if (self.result == nil) return nil;
        self.assess();
        if (self.completedAt != nil) return action == self.completedAction;
        local current = self.profile.phobiaCurrentTrait(self.trait);
        if (!holds(self.profile.traits,current) || !current.active || current.mitigated) return true;
        return holds(self.otherFirstActions,action) || self.check.achieved && holds(self.selfFirstActions,action);
    }
    recordAction(action,evidence)
    {
        if (self.result == nil || evidence == nil || evidence == '' || !self.permits(action))
            rpgExpandedReject('self-sacrifice-execution-required');
        local value = new RpgExpandedResult();
        if (self.completedAt != nil)
        {
            if (self.completedAction != action || self.completionEvidence != evidence) rpgExpandedReject('self-sacrifice-completion-binding');
            value.status = 'reused'; return value;
        }
        self.completedAction = action; self.completedAt = rpgLedger.seconds; self.completionEvidence = evidence;
        self.boundCompletion = [action,self.completedAt,evidence]; self.active = nil;
        value.status = 'resolved'; return value;
    }
;
modify rpgExpandedTemplateTraits
    rated(id,level,scope,rating)
    {
        if (id != 'self-sacrifice') return inherited(id,level,scope,rating);
        if (!holds([6,9,12,15],rating)) rpgExpandedReject('self-control-rating');
        local trait = new RpgExpandedSelfSacrifice(); trait.approved = true; trait.level = level;
        trait.scope = scope; trait.selfControlRating = rating; trait.creationCost(); return trait;
    }
    copy(trait)
    {
        if (!trait.ofKind(RpgExpandedSelfSacrifice)) return inherited(trait);
        trait.creationCost(); return self.rated(trait.id,trait.level,trait.scope,trait.selfControlNumber());
    }
;


/** full-2008 B136: timed intrusive replays with owned stress dispatch. */
class RpgExpandedIntrusiveReplay: RpgLiteTrait
    id = 'intrusive-replay'
    labelId = 'intrusive-replay'
    points = -5
    approved = nil
    replayType = nil
    templatePurchaseKind = 'expanded-intrusive-replay'
    templatePurchaseOptions() { return [self.replayType]; }
    creationCost()
    {
        rpgInteger(self.level,1,3);
        if (!self.approved || self.id != 'intrusive-replay' || self.points != [-5,-10,-20][self.level]
            || self.controlled || self.scope != nil || self.skills.length() != 0
            || self.replayType == nil || self.replayType == '') rpgExpandedReject('intrusive-replay-definition');
        return self.points;
    }
;
modify rpgExpandedTemplateTraits
    configured(id,level,scope,options)
    {
        if (id != 'intrusive-replay') return inherited(id,level,scope,options);
        rpgInteger(level,1,3);
        if (options.length() != 1) rpgExpandedReject('intrusive-replay-template-options');
        local trait = new RpgExpandedIntrusiveReplay(); trait.approved = true; trait.level = level;
        trait.points = [-5,-10,-20][level]; trait.scope = scope; trait.replayType = options[1];
        trait.creationCost(); return trait;
    }
    copy(trait)
    {
        if (!trait.ofKind(RpgExpandedIntrusiveReplay)) return inherited(trait);
        trait.creationCost(); return self.configured(trait.id,trait.level,trait.scope,trait.templatePurchaseOptions());
    }
;
modify RpgExpandedProfile
    intrusiveReplayOccurrences = []
    intrusiveReplayOverlapPolicy = nil
    intrusiveReplayOverlapEvidence = nil
    intrusiveReplayTrait()
    {
        local found = nil;
        foreach (local trait in self.traits)
            if (trait.id == 'intrusive-replay')
            {
                if (found != nil || !trait.ofKind(RpgExpandedIntrusiveReplay)) rpgExpandedReject('intrusive-replay-purchase');
                trait.creationCost(); found = trait;
            }
        return found == nil || !found.active || found.mitigated ? nil : found;
    }
    validateFeatures() { inherited(); self.intrusiveReplayTrait(); return nil; }
    intrusiveReplaySeverity()
    {
        local severity = 0;
        foreach (local entry in self.intrusiveReplayOccurrences)
            if (entry.active())
            {
                if (entry.result.severity > severity) severity = entry.result.severity;
            }
        return severity;
    }
    intrusiveReplaySkillPenalty()
    {
        local total = 0; local worst = 0; local policy = nil;
        foreach (local entry in self.intrusiveReplayOccurrences)
            if (entry.active())
            {
                local penalty = entry.result.severity == 1 ? 2 : entry.result.severity == 2 ? 5 : 0;
                total += penalty; if (penalty > worst) worst = penalty;
                if (entry.overlapPolicy != nil)
                {
                    if (policy != nil && policy != entry.overlapPolicy) rpgExpandedReject('intrusive-replay-overlap-policy-conflict');
                    policy = entry.overlapPolicy;
                }
            }
        return policy == 'sum' ? total : worst;
    }
    healthAttributeModifier(context)
    { return inherited(context) - (context.skill != nil ? self.intrusiveReplaySkillPenalty() : 0); }
    healthCheckReason(context)
    {
        if (context.skill != nil && self.intrusiveReplaySeverity() == 3) return 'intrusive-replay-skill-unavailable';
        return inherited(context);
    }
;
class RpgExpandedIntrusiveReplayResult: RpgExpandedResult
    roll = nil
    occurred = nil
    severity = 0
    duration = 0
    replayType = nil
    overlapPolicy = nil
    overlapEvidence = nil
;
/** The author owns the stress occurrence and narrative content; dice own onset/duration. */
class RpgExpandedIntrusiveReplayOccurrence: object
    id = nil
    profile = nil
    stressor = nil
    approved = nil
    evidence = nil
    content = nil
    result = nil
    recordedAt = nil
    expiresAt = nil
    replayType = nil
    overlapPolicy = nil
    overlapEvidence = nil
    boundDefinition = nil
    boundResult = nil
    definition() { return [self.id,self.profile,self.stressor,self.approved,self.evidence,self.content,self.recordedAt,self.expiresAt,self.replayType,self.overlapPolicy,self.overlapEvidence]; }
    validateReceipt()
    {
        if (self.result == nil || !holds(self.profile.intrusiveReplayOccurrences,self)
            || self.boundDefinition == nil || self.boundResult == nil) rpgExpandedReject('intrusive-replay-history');
        local facts = self.definition();
        if (facts.length() != self.boundDefinition.length()) rpgExpandedReject('intrusive-replay-binding');
        for (local i = 1; i <= facts.length(); i += 1)
            if (facts[i] != self.boundDefinition[i]) rpgExpandedReject('intrusive-replay-binding');
        local outcome = [self.result,self.result.status,self.result.roll,self.result.occurred,self.result.severity,self.result.duration,self.result.replayType,self.result.overlapPolicy,self.result.overlapEvidence];
        if (outcome.length() != self.boundResult.length()) rpgExpandedReject('intrusive-replay-result-binding');
        for (local i = 1; i <= outcome.length(); i += 1)
            if (outcome[i] != self.boundResult[i]) rpgExpandedReject('intrusive-replay-result-binding');
        return nil;
    }
    active()
    { self.validateReceipt(); return self.result.occurred && rpgLedger.seconds >= self.recordedAt && rpgLedger.seconds < self.expiresAt; }
    assess()
    {
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile))
            rpgExpandedReject('intrusive-replay-occurrence-definition');
        local value = new RpgExpandedIntrusiveReplayResult();
        if (self.result != nil) { self.validateReceipt(); value.status = 'reused'; return value; }
        if (self.recordedAt != nil || self.expiresAt != nil || self.boundDefinition != nil || self.boundResult != nil || self.replayType != nil || self.overlapPolicy != nil || self.overlapEvidence != nil)
            rpgExpandedReject('intrusive-replay-uncommitted-state');
        if (!self.approved || self.stressor == nil || self.evidence == nil || self.evidence == ''
            || self.content == nil || self.content == '') { value.reason = 'intrusive-replay-authored-facts'; return value; }
        local trait = self.profile.intrusiveReplayTrait();
        if (trait == nil) { value.reason = 'intrusive-replay-inactive'; return value; }
        value.overlapPolicy = self.profile.intrusiveReplayOverlapPolicy;
        value.overlapEvidence = self.profile.intrusiveReplayOverlapEvidence;
        if (value.overlapPolicy != nil || value.overlapEvidence != nil)
            if (!holds(['sum','worst'],value.overlapPolicy) || value.overlapEvidence == nil || value.overlapEvidence == '')
                rpgExpandedReject('intrusive-replay-overlap-ruling');
        foreach (local prior in self.profile.intrusiveReplayOccurrences)
        {
            prior.validateReceipt();
            if (prior.id == self.id || prior.stressor == self.stressor) rpgExpandedReject('intrusive-replay-duplicate');
            if (prior.active())
            {
                if (value.overlapPolicy == nil) { value.reason = 'intrusive-replay-overlap-ruling-required'; return value; }
                if (prior.overlapPolicy != nil && prior.overlapPolicy != value.overlapPolicy)
                { value.reason = 'intrusive-replay-overlap-policy-conflict'; return value; }
            }
        }
        rpgInteger(rpgLedger.seconds,0,2147482567);
        value.severity = trait.level; value.replayType = trait.replayType; value.status = 'ready'; return value;
    }
    resolve()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        value.roll = rpgRandom.roll(); value.occurred = value.roll <= 6;
        if (value.occurred)
        {
            local count = value.severity == 1 ? 2 : value.severity == 2 ? 1 : 3;
            for (local i = 1; i <= count; i += 1) value.duration += rpgRandom.die();
            if (value.severity != 1) value.duration *= 60;
        }
        self.recordedAt = rpgLedger.seconds; self.expiresAt = self.recordedAt + value.duration;
        self.replayType = value.replayType; self.overlapPolicy = value.overlapPolicy; self.overlapEvidence = value.overlapEvidence;
        value.status = 'resolved'; self.result = value; self.boundDefinition = self.definition();
        self.boundResult = [value,value.status,value.roll,value.occurred,value.severity,value.duration,value.replayType,value.overlapPolicy,value.overlapEvidence];
        self.profile.intrusiveReplayOccurrences = self.profile.intrusiveReplayOccurrences + [self]; return value;
    }
;

/* Reject unintegrated automatic routes instead of silently dropping required rolls. */
modify RpgExpandedProfile
    validateDirectFright()
    {
        if (self.intrusiveReplayTrait() != nil) rpgExpandedReject('intrusive-replay-fear-dispatch-required');
        return inherited();
    }
    newFearReplayFollowup(entry)
    {
        if (self.intrusiveReplayTrait() == nil) return nil;
        local occurrence = new RpgExpandedIntrusiveReplayOccurrence(); occurrence.id = 'fear:' + entry.id;
        occurrence.profile = self; occurrence.stressor = entry; occurrence.approved = true;
        occurrence.evidence = entry.context.evidence; occurrence.content = entry.context.intrusiveReplayContent;
        return occurrence;
    }
    validateFearReplayFollowup(entry,followup)
    {
        if (followup == nil || !followup.ofKind(RpgExpandedIntrusiveReplayOccurrence)
            || followup.profile != self || followup.stressor != entry) rpgExpandedReject('fear-replay-owner');
        return followup.validateReceipt();
    }
    validateDirectSelfControl(giveIn)
    {
        if (!giveIn && self.intrusiveReplayTrait() != nil) rpgExpandedReject('intrusive-replay-control-dispatch-required');
        return inherited(giveIn);
    }
;

modify RpgExpandedProfile
    externalInputReason()
    { return self.intrusiveReplaySeverity() == 3 ? 'intrusive-replay-external-input-unavailable' : inherited(); }
    healthCheckReason(context)
    {
        local reason = inherited(context); if (reason != nil) return reason;
        if (!holds(['auto','required','none'],context.externalInput)) rpgExpandedReject('external-input-classification');
        local required = context.externalInput == 'required' || context.controllingAttribute() == rpgPerception
            || holds(['vision','hearing','taste-smell','touch','nature-observation'],context.kind)
            || context.understandsSpeech || context.written;
        return required ? self.externalInputReason() : nil;
    }
    fearAuraPerceptionReason(aura)
    {
        local reason = self.externalInputReason();
        return reason == nil ? inherited(aura) : reason;
    }
;

/** full-2008 B143: author-assessed confidence affects skills, not raw attributes. */
class RpgExpandedLowConfidence: RpgExpandedDisadvantage
    id = 'low-confidence'
    labelId = 'low-confidence'
    points = -10
    templatePurchaseKind = 'expanded-low-confidence'
    creationCost()
    {
        if (!self.approved || self.id != 'low-confidence' || self.points != -10 || self.level != 1
            || self.controlled || self.selfControlRating != nil || self.scope != nil || self.skills.length() != 0 || self.percentages.length() != 0)
            rpgExpandedReject('low-confidence-definition');
        return -10;
    }
;
modify RpgLiteContext
    confidenceSituation = nil
    confidenceEvidence = nil
    confidenceFacts() { return [self.confidenceSituation,self.confidenceEvidence]; }
;
modify RpgExpandedProfile
    lowConfidenceActive()
    {
        local found = nil;
        foreach (local trait in self.traits)
            if (trait.id == 'low-confidence')
            {
                if (found != nil || !trait.ofKind(RpgExpandedLowConfidence)) rpgExpandedReject('low-confidence-purchase');
                trait.creationCost(); found = trait;
            }
        return found != nil && found.active && !found.mitigated;
    }
    validateFeatures() { inherited(); self.lowConfidenceActive(); return nil; }
    lowConfidenceContextReason(context)
    {
        if (!self.lowConfidenceActive() || context.skill == nil) return nil;
        if (!holds(['ordinary','adverse'],context.confidenceSituation)
            || context.confidenceEvidence == nil || context.confidenceEvidence == '')
            return 'low-confidence-scene-judgment-required';
        return nil;
    }
    healthCheckReason(context)
    {
        local reason = inherited(context);
        return reason == nil ? self.lowConfidenceContextReason(context) : reason;
    }
    healthAttributeModifier(context)
    {
        local value = inherited(context);
        local reason = self.lowConfidenceContextReason(context); if (reason != nil) rpgExpandedReject(reason);
        return value - (context.skill != nil && self.lowConfidenceActive() && context.confidenceSituation == 'adverse' ? 3 : 0);
    }
;
modify rpgExpandedTemplateTraits
    plain(id,level,scope)
    {
        if (id != 'low-confidence') return inherited(id,level,scope);
        local trait = new RpgExpandedLowConfidence(); trait.approved = true; trait.level = level; trait.scope = scope;
        trait.creationCost(); return trait;
    }
    copy(trait)
    {
        if (!trait.ofKind(RpgExpandedLowConfidence)) return inherited(trait);
        trait.creationCost(); return self.plain(trait.id,trait.level,trait.scope);
    }
;

/** full-2008 B140: responding to an authored strange occurrence. */
class RpgExpandedIncuriosity: RpgExpandedDisadvantage
    id = 'incuriosity'
    labelId = 'incuriosity'
    points = -5
    controlled = true
    templatePurchaseKind = 'expanded-incuriosity'
    validateDefinition()
    {
        if (!self.approved || self.id != 'incuriosity' || self.points != -5 || self.level != 1
            || !self.controlled || self.scope != nil || self.skills.length() != 0 || self.percentages.length() != 0)
            rpgExpandedReject('incuriosity-definition');
        return nil;
    }
    creationCost() { self.validateDefinition(); return inherited(); }
    selfControlNumber() { self.validateDefinition(); return inherited(); }
;
class RpgExpandedIncuriosityTrigger: RpgExpandedSelfControlTrigger
    novelty = nil
    strangeConfirmed = nil
    ignoreActions = []
    investigationActions = []
    completedAction = nil
    completedAt = nil
    completionEvidence = nil
    boundCompletion = nil
    boundCheck = nil
    definition()
    { return inherited() + [self.novelty,self.strangeConfirmed,self.ignoreActions.length(),self.investigationActions.length()]
        + self.ignoreActions + self.investigationActions; }
    afterControlResolution(value)
    { self.boundCheck = [self.check,self.check.score,self.check.roll,self.check.achieved,self.check.margin,self.check.critical]; return nil; }
    assess()
    {
        local value = inherited();
        if (!self.trait.ofKind(RpgExpandedIncuriosity)) rpgExpandedReject('incuriosity-trigger-trait');
        if (value.status == 'reused')
        {
            local facts = [self.check,self.check.score,self.check.roll,self.check.achieved,self.check.margin,self.check.critical];
            if (self.boundCheck == nil || self.active != (!self.check.achieved && self.completedAt == nil))
                rpgExpandedReject('incuriosity-check-binding');
            for (local i = 1; i <= facts.length(); i += 1)
                if (facts[i] != self.boundCheck[i]) rpgExpandedReject('incuriosity-check-binding');
            if (self.completedAt != nil)
            {
                if (self.boundCompletion == nil || self.completedAction != self.boundCompletion[1]
                    || self.completedAt != self.boundCompletion[2] || self.completionEvidence != self.boundCompletion[3])
                    rpgExpandedReject('incuriosity-completion-binding');
            }
            else if (self.completedAction != nil || self.completionEvidence != nil || self.boundCompletion != nil)
                rpgExpandedReject('incuriosity-uncommitted-completion');
            return value;
        }
        if (self.completedAction != nil || self.completedAt != nil || self.completionEvidence != nil
            || self.boundCompletion != nil || self.boundCheck != nil)
            rpgExpandedReject('incuriosity-uncommitted-completion');
        if (value.status != 'ready') return value;
        if (self.novelty == nil
            || !self.strangeConfirmed || self.ignoreActions.length() == 0 || self.investigationActions.length() == 0)
        { value.status = 'blocked'; value.reason = 'incuriosity-alternatives'; return value; }
        local seen = [];
        foreach (local action in self.ignoreActions + self.investigationActions)
        {
            if (action == nil || holds(seen,action)) rpgExpandedReject('incuriosity-classification');
            seen = seen + [action];
        }
        return value;
    }
    permits(action)
    {
        if (self.result == nil) return nil;
        self.assess();
        if (self.completedAt != nil) return action == self.completedAction;
        local current = self.profile.phobiaCurrentTrait(self.trait);
        if (!holds(self.profile.traits,current) || !current.active || current.mitigated) return true;
        return holds(self.ignoreActions,action) || self.check.achieved && holds(self.investigationActions,action);
    }
    recordAction(action,evidence)
    {
        if (self.result == nil || evidence == nil || evidence == '' || !self.permits(action))
            rpgExpandedReject('incuriosity-execution-required');
        local value = new RpgExpandedResult();
        if (self.completedAt != nil)
        {
            if (self.completedAction != action || self.completionEvidence != evidence) rpgExpandedReject('incuriosity-completion-binding');
            value.status = 'reused'; return value;
        }
        self.completedAction = action; self.completedAt = rpgLedger.seconds; self.completionEvidence = evidence;
        self.boundCompletion = [action,self.completedAt,evidence]; self.active = nil;
        value.status = 'resolved'; return value;
    }
;
modify rpgExpandedTemplateTraits
    rated(id,level,scope,rating)
    {
        if (id != 'incuriosity') return inherited(id,level,scope,rating);
        if (!holds([6,9,12,15],rating)) rpgExpandedReject('self-control-rating');
        local trait = new RpgExpandedIncuriosity(); trait.approved = true; trait.level = level;
        trait.scope = scope; trait.selfControlRating = rating; trait.creationCost(); return trait;
    }
    copy(trait)
    {
        if (!trait.ofKind(RpgExpandedIncuriosity)) return inherited(trait);
        trait.creationCost(); return self.rated(trait.id,trait.level,trait.scope,trait.selfControlNumber());
    }
;



modify RpgExpandedProfile
    incuriosityActive()
    {
        local found = nil;
        foreach (local trait in self.traits)
            if (trait.id == 'incuriosity')
            {
                if (found != nil || !trait.ofKind(RpgExpandedIncuriosity)) rpgExpandedReject('incuriosity-purchase');
                trait.creationCost(); found = trait;
            }
        return found != nil && found.active && !found.mitigated;
    }
    validateFeatures() { inherited(); self.incuriosityActive(); return nil; }
;

/** full-2008 B140: visible alternatives and clocked retries belong to one decision. */
class RpgExpandedIndecision: RpgExpandedDisadvantage
    id = 'indecision'
    labelId = 'indecision'
    points = -10
    controlled = true
    templatePurchaseKind = 'expanded-indecision'
    validateDefinition()
    {
        if (!self.approved || self.id != 'indecision' || self.points != -10 || self.level != 1
            || !self.controlled || self.scope != nil || self.skills.length() != 0 || self.percentages.length() != 0)
            rpgExpandedReject('indecision-definition');
    }
    creationCost() { self.validateDefinition(); return inherited(); }
    selfControlNumber() { self.validateDefinition(); return inherited(); }
;
modify rpgExpandedTemplateTraits
    rated(id,level,scope,rating)
    {
        if (id != 'indecision') return inherited(id,level,scope,rating);
        if (!holds([6,9,12,15],rating)) rpgExpandedReject('self-control-rating');
        local trait = new RpgExpandedIndecision(); trait.approved = true; trait.level = level;
        trait.scope = scope; trait.selfControlRating = rating; trait.creationCost(); return trait;
    }
    copy(trait)
    {
        if (!trait.ofKind(RpgExpandedIndecision)) return inherited(trait);
        trait.creationCost(); return self.rated(trait.id,trait.level,trait.scope,trait.selfControlNumber());
    }
;
class RpgExpandedIndecisionEpisode: object
    id = nil
    profile = nil
    trait = nil
    choices = []
    highStress = nil
    approved = nil
    evidence = nil
    attempts = []
    boundFacts = nil
    facts() { return [self.id,self.profile,self.trait,self.highStress,self.approved,self.evidence,self.choices.length()] + self.choices; }
    validate()
    {
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)
            || self.trait == nil || !self.trait.ofKind(RpgExpandedIndecision)) rpgExpandedReject('indecision-episode-definition');
        self.trait.creationCost();
        if (!self.approved || self.evidence == nil || self.evidence == '' || self.choices.length() < 2)
            rpgExpandedReject('indecision-decision-facts');
        local seen = [];
        foreach (local choice in self.choices)
        {
            if (choice == nil || holds(seen,choice)) rpgExpandedReject('indecision-distinct-choices');
            seen = seen + [choice];
        }
        if (self.boundFacts != nil)
        {
            local facts = self.facts();
            if (facts.length() != self.boundFacts.length() || !holds(self.profile.indecisionEpisodes,self))
                rpgExpandedReject('indecision-episode-history');
            for (local i = 1; i <= facts.length(); i += 1)
                if (facts[i] != self.boundFacts[i]) rpgExpandedReject('indecision-episode-binding');
        }
        else if (self.attempts.length() != 0) rpgExpandedReject('indecision-uncommitted-attempts');
        return nil;
    }
    active()
    {
        self.validate();
        foreach (local attempt in self.attempts) attempt.assess();
        if (self.attempts.length() == 0) return nil;
        local current = self.profile.phobiaCurrentTrait(self.trait);
        return holds(self.profile.traits,current) && current.active && !current.mitigated
            && !self.attempts[self.attempts.length()].check.achieved;
    }
;
class RpgExpandedIndecisionCheck: RpgExpandedSelfControlTrigger
    episode = nil
    recordedAt = nil
    boundCheck = nil
    definition() { return inherited() + [self.episode]; }
    effectiveModifier() { return -self.episode.choices.length(); }
    assess()
    {
        if (self.episode == nil || !self.episode.ofKind(RpgExpandedIndecisionEpisode)) rpgExpandedReject('indecision-check-episode');
        self.episode.validate();
        if (self.profile != self.episode.profile || self.trait != self.episode.trait || self.modifier != 0)
            rpgExpandedReject('indecision-check-owner');
        local value = inherited();
        if (value.status == 'reused')
        {
            if (!holds(self.episode.attempts,self) || self.boundCheck == nil) rpgExpandedReject('indecision-check-history');
            local facts = [self.recordedAt,self.check,self.check.score,self.check.roll,self.check.achieved,self.check.margin,self.check.critical];
            for (local i = 1; i <= facts.length(); i += 1)
                if (facts[i] != self.boundCheck[i]) rpgExpandedReject('indecision-check-binding');
            return value;
        }
        if (self.recordedAt != nil || self.boundCheck != nil) rpgExpandedReject('indecision-check-uncommitted');
        if (value.status != 'ready') return value;
        if (self.profile.dead || self.profile.unconscious || self.trait.mitigated)
        { value.reason = 'indecision-observer-unavailable'; value.status = 'blocked'; return value; }
        foreach (local purchase in self.profile.traits)
            if (purchase.active && !purchase.mitigated && purchase.id == 'overstimulation')
            { value.reason = 'indecision-confusion-adapter-required'; value.status = 'blocked'; return value; }
        foreach (local prior in self.profile.indecisionEpisodes)
            if (prior != self.episode && (prior.id == self.episode.id || prior.active()))
                rpgExpandedReject('indecision-concurrent-decision');
        if (self.episode.attempts.length() != 0)
        {
            local prior = self.episode.attempts[self.episode.attempts.length()]; prior.assess();
            if (prior.check.achieved) { value.reason = 'indecision-already-decided'; value.status = 'blocked'; return value; }
            if (rpgLedger.seconds < prior.recordedAt + (self.episode.highStress ? 1 : 60))
            { value.reason = 'indecision-retry-not-due'; value.status = 'blocked'; return value; }
        }
        return value;
    }
    afterControlResolution(value)
    {
        self.recordedAt = rpgLedger.seconds;
        self.boundCheck = [self.recordedAt,self.check,self.check.score,self.check.roll,self.check.achieved,self.check.margin,self.check.critical];
        if (self.episode.boundFacts == nil)
        { self.episode.boundFacts = self.episode.facts(); self.profile.indecisionEpisodes = self.profile.indecisionEpisodes + [self.episode]; }
        self.episode.attempts = self.episode.attempts + [self]; return nil;
    }
;
modify RpgExpandedProfile
    indecisionEpisodes = []
    activeIndecision()
    {
        local found = nil;
        foreach (local episode in self.indecisionEpisodes)
            if (episode.active())
            {
                if (found != nil) rpgExpandedReject('indecision-concurrent-decision');
                found = episode;
            }
        return found;
    }
    healthEffortReasonFor(purpose,mentalAbility,speech,movement,authorization)
    {
        local reason = inherited(purpose,mentalAbility,speech,movement,authorization);
        if (reason == nil && self.activeIndecision() != nil && !holds(['rest','do-nothing'],purpose))
            return 'indecision-do-nothing';
        return reason;
    }
    healthManeuverReasonFor(kind,request)
    {
        local reason = inherited(kind,request);
        if (reason == nil && self.activeIndecision() != nil && kind != 'nothing') return 'indecision-do-nothing';
        return reason;
    }
;
