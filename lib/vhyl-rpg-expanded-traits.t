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
    phantomVoiceOccurrence = nil
    boundPhantomVoiceOccurrence = nil
    definition() { return [self.id,self.profile,self.trait,self.trigger,self.modifier,self.giveIn,self.evidence,self.buySuccess,self.stressRelation]; }
    effectiveModifier() { return self.modifier; }
    newResult() { return new RpgExpandedResult(); }
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
            value.status = 'reused'; value.check = self.check; value.points = self.result.points; return value;
        }
        if (!holds(self.profile.traits,self.trait) || !self.trait.controlled || !self.trait.active)
            rpgExpandedReject('self-control-trigger-trait');
        if (self.trigger == nil || self.evidence == nil || self.evidence == '')
        { value.reason = 'self-control-trigger-evidence'; return value; }
        foreach (local prior in self.profile.selfControlTriggers)
            if (prior.id == self.id || prior.trait == self.trait && prior.trigger == self.trigger)
                rpgExpandedReject('self-control-trigger-duplicate');
        if (self.profile.phantomVoiceSeverity() > 0 && !self.giveIn && !self.buySuccess
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
        value.status = 'resolved'; self.result = value;
        if (self.stressRelation == 'stress-related' && value.check.roll != nil && !value.check.achieved
            && self.profile.phantomVoiceSeverity() > 0)
        {
            local occurrence = self.phantomVoiceRequest();
            local voices = occurrence.resolve();
            if (voices.status != 'resolved') rpgExpandedReject('self-control-phantom-voices-changed');
            self.phantomVoiceOccurrence = occurrence; self.boundPhantomVoiceOccurrence = occurrence;
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
    healthEffortReason(purpose,mentalAbility,speech,movement)
    {
        if ((purpose == 'talk' || speech) && self.speechLimitationLevel() > 0)
            return 'articulated-speech-unavailable';
        return inherited(purpose,mentalAbility,speech,movement);
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
