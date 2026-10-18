/* Include after expanded foundation and equipment. Source: full-2008, B507. */

/** Legal assessment distinguishes permission from eligibility to seek a license. */
class RpgExpandedLegalResult: RpgExpandedResult
    requirement = 'none'
    licenseEligible = nil
;

/** Local equipment access policy. The author selects the relevant jurisdiction's
 * control rating, any local exception, and the character's actual credentials. */
class RpgExpandedLegalAccess: object
    subject = nil
    equipment = nil
    controlRating = 0
    legality = nil
    exception = 'table'
    citizen = true
    excluded = nil
    registrationRequired = nil
    registered = nil
    licensed = nil
    legitimateNeed = nil
    governmentEmployment = nil
    role = 'civilian'
    assess()
    {
        rpgInteger(self.controlRating, 0, 6);
        if (self.legality != nil) rpgInteger(self.legality, 0, 4);
        if (!holds(['table','allow','deny'],self.exception)
            || !holds(['civilian','special-police','military','intelligence','secret-police'],self.role))
            rpgExpandedReject('legal-policy');
        local value = new RpgExpandedLegalResult();
        if (self.exception == 'deny') { value.reason = 'local-prohibition'; return value; }
        if (self.exception == 'allow' || self.legality == nil)
        { value.status = 'ready'; return value; }
        local difference = self.legality - self.controlRating;
        if (difference >= 1)
        {
            if (!self.citizen) { value.reason = 'noncitizen-policy-required'; return value; }
        }
        else if (difference == 0)
        {
            if (self.excluded) { value.reason = 'legal-exclusion'; return value; }
            if (self.registrationRequired)
            {
                value.requirement = 'registration';
                if (!self.registered) { value.reason = 'registration-required'; return value; }
            }
        }
        else if (difference == -1)
        {
            value.requirement = 'license';
            value.licenseEligible = self.legitimateNeed || self.governmentEmployment;
            if (!self.licensed) { value.reason = 'license-required'; return value; }
        }
        else if (difference == -2)
        {
            value.requirement = 'special-unit';
            if (!holds(['special-police','military','intelligence','secret-police'],self.role))
            { value.reason = 'special-unit-required'; return value; }
        }
        else
        {
            value.requirement = 'military-or-secret-police';
            if (!holds(['military','secret-police'],self.role))
            { value.reason = 'military-or-secret-police-required'; return value; }
        }
        value.status = 'ready'; return value;
    }
;

modify RpgExpandedAcquisition
    legalAccess = nil
    authorizationReason()
    {
        local reason = inherited();
        if (reason != nil || self.legalAccess == nil) return reason;
        if (!self.legalAccess.ofKind(RpgExpandedLegalAccess)) rpgExpandedReject('legal-policy');
        if (self.legalAccess.subject != self.profile) rpgExpandedReject('legal-policy-subject');
        if (self.legalAccess.equipment != self.item) rpgExpandedReject('legal-policy-item');
        local value = self.legalAccess.assess();
        return value.status == 'ready' ? nil : value.reason;
    }
;

/** B506 comparison for an explicitly uncertain legality/enforcement question. */
rpgExpandedControlOutcome(controlRating, die, kind)
{
    rpgInteger(controlRating, 0, 6); rpgInteger(die, 1, 6);
    if (!holds(['legality','enforcement'],kind)) rpgExpandedReject('control-question-kind');
    if (die == controlRating) return 'encounter-required';
    if (kind == 'legality') return die < controlRating ? 'prohibited' : 'permitted';
    return die < controlRating ? 'intervention' : 'overlooked';
}

class RpgExpandedControlResult: RpgExpandedResult
    outcome = nil
    roll = nil
    evidence = nil
;

/** Owned encounter decision. The author selects the jurisdiction/domain and
 * whether a roll is appropriate. A tie requires an explicit completed encounter. */
class RpgExpandedControlQuestion: object
    subject = nil
    contextId = nil
    kind = 'enforcement'
    controlRating = 0
    approved = nil
    certainOutcome = nil
    resolved = nil
    outcome = nil
    roll = nil
    evidence = nil
    boundSubject = nil
    boundContext = nil
    boundKind = nil
    boundRating = nil
    validate()
    {
        if (self.subject == nil || !self.subject.ofKind(RpgExpandedProfile) || self.contextId == nil)
            rpgExpandedReject('control-question-context');
        rpgInteger(self.controlRating, 0, 6);
        if (!holds(['legality','enforcement'],self.kind)) rpgExpandedReject('control-question-kind');
        if (self.certainOutcome != nil && !self.accepts(self.certainOutcome))
            rpgExpandedReject('control-question-outcome');
        if (self.resolved && (self.subject != self.boundSubject || self.contextId != self.boundContext
            || self.kind != self.boundKind || self.controlRating != self.boundRating))
            rpgExpandedReject('control-question-retargeted');
        return nil;
    }
    accepts(value)
    {
        return self.kind == 'legality' ? holds(['permitted','prohibited'],value)
            : holds(['intervention','overlooked'],value);
    }
    receipt(status)
    {
        local value = new RpgExpandedControlResult(); value.status = status;
        value.outcome = self.outcome; value.roll = self.roll; value.evidence = self.evidence;
        return value;
    }
    assess()
    {
        self.validate();
        if (self.resolved) return self.receipt('reused');
        local value = new RpgExpandedControlResult();
        if (!self.approved) { value.reason = 'control-question-unapproved'; return value; }
        value.status = 'ready'; return value;
    }
    resolve()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local die = self.certainOutcome == nil ? rpgRandom.die() : nil;
        self.outcome = die == nil ? self.certainOutcome
            : rpgExpandedControlOutcome(self.controlRating,die,self.kind);
        self.roll = die; self.resolved = true;
        self.boundSubject = self.subject; self.boundContext = self.contextId;
        self.boundKind = self.kind; self.boundRating = self.controlRating;
        return self.receipt('resolved');
    }
    /** Record the authored encounter/reaction result. evidence identifies that
     * completed encounter; this method itself rolls nothing and imposes no arrest. */
    completeEncounter(result, evidence)
    {
        self.validate();
        if (!self.accepts(result) || evidence == nil) rpgExpandedReject('control-encounter-result');
        if (self.evidence != nil)
        {
            if (self.outcome != result || self.evidence != evidence)
                rpgExpandedReject('control-encounter-already-resolved');
            return self.receipt('reused');
        }
        if (!self.resolved || self.outcome != 'encounter-required')
        {
            local value = new RpgExpandedControlResult(); value.reason = 'no-pending-control-encounter';
            return value;
        }
        self.outcome = result; self.evidence = evidence; return self.receipt('resolved');
    }
;

/** Purchased wealth contribution, B25-B27. Financial status is separate from
 * current cash: neither spending nor receiving money changes this purchase. */
class RpgExpandedWealth: RpgExpandedContribution
    id = 'wealth'
    wealthLevel = 'average'
    extraLevels = 0
    rank()
    {
        local levels = ['none','poor','struggling','average','comfortable','wealthy','very-wealthy','filthy-rich','multimillionaire'];
        rpgInteger(self.extraLevels, 0, 8);
        if (self.wealthLevel == 'multimillionaire' ? self.extraLevels < 1 : self.extraLevels != 0)
            rpgExpandedReject('wealth-level');
        for (local index = 1; index <= levels.length(); index += 1)
            if (levels[index] == self.wealthLevel) return index;
        rpgExpandedReject('wealth-level'); return nil;
    }
    amounts(profile)
    {
        local prices = [-25,-15,-10,0,10,20,30,50,50];
        return [prices[self.rank()] + self.extraLevels * 25];
    }
    validate(profile)
    {
        self.rank();
        foreach (local entry in profile.contributions)
            if (entry != self && entry.ofKind(RpgExpandedWealth)) rpgExpandedReject('duplicate-wealth');
        foreach (local trait in profile.traits)
            if (trait.ofKind(RpgLiteTrait) && holds(['dead-broke','poor','struggling','comfortable','wealthy','very-wealthy','filthy-rich'],trait.id))
                rpgExpandedReject('duplicate-wealth');
        return nil;
    }
    startingValue(campaignTL)
    {
        rpgInteger(campaignTL, 0, 12);
        local values = [250,500,750,1000,2000,5000,10000,15000,20000,30000,50000,75000,100000];
        local amount = values[campaignTL + 1]; local rank = self.rank();
        if (rank == 1) return 0;
        if (rank == 2) return amount / 5;
        if (rank == 3) return amount / 2;
        if (rank == 5) amount *= 2;
        if (rank == 6) amount *= 5;
        if (rank == 7) amount *= 20;
        if (rank >= 8) amount *= 100;
        for (local index = 0; index < self.extraLevels; index += 1)
        {
            if (amount > 214748364) rpgExpandedReject('wealth-value-limit');
            amount *= 10;
        }
        return amount;
    }
;

modify RpgExpandedProfile
    startingWealthAllocation = nil
;

class RpgExpandedWealthResult: RpgExpandedResult
    total = 0
    cash = 0
    settledAssets = 0
;

/** Allocate starting property once, before item purchases. Settled assets are
 * an earmarked property value in this receipt, never a second spendable bank. */
class RpgExpandedWealthAllocation: object
    profile = nil
    wealth = nil
    mobile = nil
    mobileApproved = nil
    boundProfile = nil
    boundWealth = nil
    total = 0
    cash = 0
    settledAssets = 0
    assess()
    {
        if (self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)
            || self.wealth == nil || !self.wealth.ofKind(RpgExpandedWealth)
            || self.wealth.owner != self.profile || !holds(self.profile.contributions,self.wealth))
            rpgExpandedReject('wealth-allocation-owner');
        if (self.boundProfile != nil && (self.profile != self.boundProfile || self.wealth != self.boundWealth))
            rpgExpandedReject('wealth-allocation-retargeted');
        local value = new RpgExpandedWealthResult();
        if (self.profile.startingWealthAllocation != nil)
        {
            if (self.profile.startingWealthAllocation != self)
            { value.reason = 'starting-wealth-already-allocated'; return value; }
            value.status = 'reused'; value.total = self.total; value.cash = self.cash;
            value.settledAssets = self.settledAssets; return value;
        }
        rpgExpandedValidate(self.profile);
        if (self.profile.creationComplete) { value.reason = 'starting-wealth-creation-only'; return value; }
        if (self.profile.money != 0 || self.profile.equipment.length() != 0)
        { value.reason = 'starting-wealth-opening-balance'; return value; }
        if (self.mobile && !self.mobileApproved)
        { value.reason = 'mobile-wealth-unapproved'; return value; }
        value.total = self.wealth.startingValue(self.profile.campaignTL);
        value.cash = self.mobile ? value.total : value.total / 5;
        value.settledAssets = value.total - value.cash; value.status = 'ready'; return value;
    }
    allocate()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.total = value.total; self.cash = value.cash; self.settledAssets = value.settledAssets;
        self.boundProfile = self.profile; self.boundWealth = self.wealth;
        self.profile.money = value.cash; self.profile.startingWealthAllocation = self;
        value.status = 'resolved'; return value;
    }
;
