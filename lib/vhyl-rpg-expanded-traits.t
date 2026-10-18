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
    definition() { return [self.id,self.profile,self.trait,self.trigger,self.modifier,self.giveIn,self.evidence,self.buySuccess]; }
    effectiveModifier() { return self.modifier; }
    newResult() { return new RpgExpandedResult(); }
    assess()
    {
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)
            || self.trait == nil || !self.trait.ofKind(RpgExpandedDisadvantage))
            rpgExpandedReject('self-control-trigger-definition');
        local value = self.newResult();
        if (self.result != nil)
        {
            local current = self.definition();
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.boundDefinition[index]) rpgExpandedReject('self-control-trigger-binding');
            if (!holds(self.profile.selfControlTriggers,self)) rpgExpandedReject('self-control-trigger-history');
            value.status = 'reused'; value.check = self.check; value.points = self.result.points; return value;
        }
        if (!holds(self.profile.traits,self.trait) || !self.trait.controlled || !self.trait.active)
            rpgExpandedReject('self-control-trigger-trait');
        if (self.trigger == nil || self.evidence == nil || self.evidence == '')
        { value.reason = 'self-control-trigger-evidence'; return value; }
        foreach (local prior in self.profile.selfControlTriggers)
            if (prior.id == self.id || prior.trait == self.trait && prior.trigger == self.trigger)
                rpgExpandedReject('self-control-trigger-duplicate');
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
        else value.check = rpgLiteSelfControl(self.profile,self.trait,self.effectiveModifier(),self.giveIn);
        if (value.check.status != 'resolved') rpgExpandedReject('self-control-trigger-changed');
        self.check = value.check; self.active = !self.check.achieved;
        self.boundDefinition = self.definition(); self.profile.selfControlTriggers = self.profile.selfControlTriggers + [self];
        value.status = 'resolved'; self.result = value; return value;
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
