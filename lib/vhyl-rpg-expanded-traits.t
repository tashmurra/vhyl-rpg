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
    creationCost()
    {
        if (!self.approved) rpgExpandedReject('unapproved-trait');
        rpgInteger(self.points, -10000, -1); rpgInteger(self.level, 1, 100);
        local base = self.points * self.level;
        if (self.selfControlRating != nil)
        {
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
