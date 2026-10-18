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
    wealthStatusBonus()
    {
        local rank = self.rank();
        if (rank < 6) return 0;
        if (rank < 9) return 1;
        return self.extraLevels == 1 ? 2 : 3;
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
    boundDefinition = nil
    boundOutcome = nil
    definition() { return [self.profile,self.wealth,self.mobile,self.mobileApproved]; }
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
            local facts = self.definition();
            if (self.boundDefinition == nil || facts.length() != self.boundDefinition.length()) rpgExpandedReject('wealth-allocation-binding');
            for (local index = 1; index <= facts.length(); index += 1)
                if (facts[index] != self.boundDefinition[index]) rpgExpandedReject('wealth-allocation-binding');
            if (self.boundOutcome == nil || self.boundOutcome.length() != 3 || self.total != self.boundOutcome[1]
                || self.cash != self.boundOutcome[2] || self.settledAssets != self.boundOutcome[3])
                rpgExpandedReject('wealth-allocation-outcome');
            value.status = 'reused'; value.total = self.total; value.cash = self.cash;
            value.settledAssets = self.settledAssets; return value;
        }
        if (self.boundDefinition != nil || self.boundOutcome != nil) rpgExpandedReject('wealth-allocation-uncommitted');
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
        self.boundDefinition = self.definition(); self.boundOutcome = [self.total,self.cash,self.settledAssets];
        self.profile.money = value.cash; self.profile.startingWealthAllocation = self;
        value.status = 'resolved'; return value;
    }
;

/** Recurring income or debt, full-2008 B26. One owned contribution per kind.
 * Periods are authored calendar months, not assumed thirty-day durations. */
class RpgExpandedMonthlyFinance: RpgExpandedContribution
    kind = 'income'
    levels = 1
    wealth = nil
    lastPeriod = 0
    history = []
    amounts(profile)
    {
        rpgInteger(self.levels, 1, 20);
        if (!holds(['income','debt'],self.kind)) rpgExpandedReject('monthly-finance-kind');
        return [self.kind == 'income' ? self.levels : -self.levels];
    }
    validate(profile)
    {
        self.amounts(profile);
        if (self.wealth == nil || !self.wealth.ofKind(RpgExpandedWealth)
            || self.wealth.owner != profile || !holds(profile.contributions,self.wealth))
            rpgExpandedReject('monthly-finance-wealth');
        if (self.kind == 'debt' && self.wealth.rank() == 1)
            rpgExpandedReject('monthly-debt-without-wealth');
        foreach (local entry in profile.contributions)
            if (entry != self && entry.ofKind(RpgExpandedMonthlyFinance) && entry.kind == self.kind)
                rpgExpandedReject('duplicate-monthly-finance');
        rpgInteger(self.lastPeriod, 0, 1000000);
        return nil;
    }
    monthlyAmount()
    {
        self.validate(self.owner);
        local base = self.wealth.startingValue(self.owner.campaignTL);
        /* Divide first to avoid overflow; reject fractional money explicitly. */
        local remainder = (base % 100) * self.levels;
        if (remainder % 100 != 0) rpgExpandedReject('monthly-finance-fractional-money');
        return (base / 100) * self.levels + remainder / 100;
    }
;

class RpgExpandedMonthlyFinanceResult: RpgExpandedResult
    money = 0
    outcome = nil
;

/** Settle one explicitly due month. Defaulting requires an authored consequence
 * record; paying debt never automatically removes its character-point cost. */
class RpgExpandedMonthlySettlement: object
    finance = nil
    period = 1
    due = nil
    decision = 'pay'
    consequence = nil
    assess()
    {
        if (self.finance == nil || !self.finance.ofKind(RpgExpandedMonthlyFinance)
            || self.finance.owner == nil || !self.finance.owner.ofKind(RpgExpandedProfile)
            || !holds(self.finance.owner.contributions,self.finance))
            rpgExpandedReject('monthly-finance-owner');
        rpgInteger(self.period, 1, 1000000);
        if (!holds(['pay','default'],self.decision)) rpgExpandedReject('monthly-finance-decision');
        local value = new RpgExpandedMonthlyFinanceResult();
        if (self.period <= self.finance.lastPeriod)
        { value.status = 'reused'; return value; }
        if (self.period != self.finance.lastPeriod + 1)
        { value.reason = 'monthly-finance-period-gap'; return value; }
        local profile = self.finance.owner; rpgExpandedValidate(profile);
        rpgInteger(profile.money, 0, 2147483647);
        if (!self.due) { value.reason = 'monthly-finance-not-due'; return value; }
        local amount = self.finance.monthlyAmount();
        if (self.decision == 'default')
        {
            if (self.finance.kind != 'debt') rpgExpandedReject('monthly-income-default');
            if (self.consequence == nil)
            { value.reason = 'monthly-default-consequence-required'; return value; }
            value.outcome = 'defaulted';
        }
        else if (self.finance.kind == 'income')
        {
            if (profile.money > 2147483647 - amount)
                rpgExpandedReject('monthly-finance-money-limit');
            value.money = amount; value.outcome = 'received';
        }
        else
        {
            if (profile.money < amount) { value.reason = 'monthly-debt-unaffordable'; return value; }
            value.money = -amount; value.outcome = 'paid';
        }
        value.status = 'ready'; return value;
    }
    settle()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.finance.owner.money += value.money;
        self.finance.lastPeriod = self.period;
        self.finance.history = self.finance.history + [[self.period,value.money,value.outcome,self.consequence]];
        value.status = 'resolved'; return value;
    }
;

modify RpgExpandedProfile
    moneyExchanges = []
;

class RpgExpandedMoneyExchangeResult: RpgExpandedResult
    money = 0
;

/** Permanently exchange points for cash, full-2008 B26. The exchange is not a
 * character advantage. Its id identifies an authored opportunity per profile. */
class RpgExpandedMoneyExchange: object
    id = nil
    profile = nil
    points = 1
    permitted = nil
    claimed = nil
    boundProfile = nil
    boundId = nil
    assess()
    {
        if (self.profile == nil || !self.profile.ofKind(RpgExpandedProfile) || self.id == nil)
            rpgExpandedReject('money-exchange-target');
        if (self.claimed && (self.profile != self.boundProfile || self.id != self.boundId))
            rpgExpandedReject('money-exchange-retargeted');
        local value = new RpgExpandedMoneyExchangeResult();
        if (self.claimed || holds(self.profile.moneyExchanges,self.id))
        { value.status = 'reused'; return value; }
        rpgInteger(self.points, 1, 1000000); rpgExpandedValidate(self.profile);
        rpgInteger(self.profile.money, 0, 2147483647);
        if (!self.permitted) { value.reason = 'money-exchange-unapproved'; return value; }
        if (self.profile.creationComplete)
        {
            value.reason = self.profile.developmentSpendingReason();
            if (value.reason != nil) return value;
            rpgInteger(self.profile.unspentPoints, 0, 1000000);
            if (self.profile.unspentPoints < self.points)
            { value.reason = 'money-exchange-points'; return value; }
        }
        else
        {
            value.reason = self.profile.creationMoneyReason(self.points);
            if (value.reason != nil) return value;
        }
        local average = new RpgExpandedWealth();
        local perPoint = average.startingValue(self.profile.campaignTL) / 10;
        if (self.points > (2147483647 - self.profile.money) / perPoint)
            rpgExpandedReject('money-exchange-money-limit');
        value.money = perPoint * self.points; value.points = self.points;
        value.status = 'ready'; return value;
    }
    exchange()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        if (self.profile.creationComplete) self.profile.unspentPoints -= value.points;
        else self.profile.pointBudget -= value.points;
        self.profile.money += value.money;
        self.profile.moneyExchanges = self.profile.moneyExchanges + [self.id];
        self.claimed = true; self.boundProfile = self.profile; self.boundId = self.id;
        value.status = 'resolved'; return value;
    }
;

modify RpgExpandedTradeTransfer
    legalAccess = nil
    authorizationReason()
    {
        local reason = inherited();
        if (reason != nil || self.legalAccess == nil) return reason;
        if (!self.legalAccess.ofKind(RpgExpandedLegalAccess)) rpgExpandedReject('legal-policy');
        if (self.legalAccess.subject != self.buyer) rpgExpandedReject('legal-policy-subject');
        if (self.legalAccess.equipment != self.item) rpgExpandedReject('legal-policy-item');
        local value = self.legalAccess.assess();
        return value.status == 'ready' ? nil : value.reason;
    }
;

/** Typical average-wealth monthly wages, full-2008 B517. */
rpgExpandedTypicalJobPay(techLevel)
{
    rpgInteger(techLevel,0,12);
    local wages = [625,650,675,700,800,1100,1600,2100,2600,3600,5600,8100,10600];
    return wages[techLevel + 1];
}

class RpgExpandedJobAssessment: RpgExpandedResult
    score = nil
    skill = nil
    ratings = []
;

/** Job qualifications and roll selection, full-2008 B516. Prerequisite rows
 * are [skill, minimum, relative-to-controlling-attribute]. Defaults do not qualify. */
class RpgExpandedJob: object
    id = nil
    prerequisites = []
    rollMode = 'fixed'
    rollSkill = nil
    rollAttribute = rpgIQ
    fixedScore = 12
    rollModifier = 0
    requirementsApproved = nil
    qualifications(profile)
    {
        if (self.id == nil || profile == nil || !profile.ofKind(RpgExpandedProfile))
            rpgExpandedReject('job-profile');
        rpgExpandedValidate(profile);
        local value = new RpgExpandedJobAssessment(); local seen = []; local ratings = [];
        foreach (local row in self.prerequisites)
        {
            if (row.length() != 3 || row[1] == nil || !row[1].ofKind(RpgSkill) || holds(seen,row[1]))
                rpgExpandedReject('job-prerequisite');
            seen = seen + [row[1]]; rpgInteger(row[2],-1000,1000);
            local paid = nil;
            foreach (local training in profile.skills)
                if (training.skill == row[1] && training.points >= 1) paid = true;
            if (!paid) { value.reason = 'job-purchased-skill-required'; return value; }
            local rating = profile.skillScore(row[1]);
            local minimum = row[2] + (row[3] ? profile.attributeScore(row[1].attribute) : 0);
            if (rating == nil || rating < minimum) { value.reason = 'job-skill-minimum'; return value; }
            ratings = ratings + [[row[1],rating]];
        }
        if (!self.requirementsApproved) { value.reason = 'job-other-requirements'; return value; }
        value.ratings = ratings; value.status = 'ready'; return value;
    }
    assess(profile)
    {
        local value = self.qualifications(profile); if (value.status != 'ready') return value;
        value.status = 'blocked'; local ratings = value.ratings;
        if (!holds(['fixed','attribute','specific','best','worst'],self.rollMode))
            rpgExpandedReject('job-roll-mode');
        rpgInteger(self.rollModifier,-1000,1000);
        if (ratings.length() > 0 && holds(['fixed','attribute'],self.rollMode))
            rpgExpandedReject('job-prerequisite-roll-required');
        if (ratings.length() == 0 && holds(['specific','best','worst'],self.rollMode))
            rpgExpandedReject('job-roll-prerequisite-required');
        if (self.rollMode == 'fixed') { rpgInteger(self.fixedScore,3,1000); value.score = self.fixedScore; }
        else if (self.rollMode == 'attribute') value.score = profile.attributeScore(self.rollAttribute);
        else
        {
            foreach (local row in ratings)
                if (self.rollMode == 'specific' ? row[1] == self.rollSkill
                    : value.score == nil || (self.rollMode == 'best' ? row[2] > value.score : row[2] < value.score))
                { value.skill = row[1]; value.score = row[2]; }
            if (value.score == nil) rpgExpandedReject('job-selected-skill');
        }
        value.score += self.rollModifier; rpgInteger(value.score,-1000,1000);
        if (value.score < 3) { value.reason = 'job-roll-unavailable'; return value; }
        value.status = 'ready'; return value;
    }
;

/** Exact whole-unit job percentages; unresolved fractional currency is rejected. */
rpgExpandedJobPercent(amount, percent)
{
    rpgInteger(amount,0,2147483647); rpgInteger(percent,0,10100);
    local quotient = amount / 100; local remainder = (amount % 100) * percent;
    if (remainder % 100 != 0) rpgExpandedReject('job-fractional-money');
    local tail = remainder / 100;
    if (percent > 0 && quotient > (2147483647 - tail) / percent) rpgExpandedReject('job-money-limit');
    return quotient * percent + tail;
}

class RpgExpandedJobEarnings: RpgExpandedResult
    wealthObligation = nil
    money = 0
    nextPay = 0
    consequenceRequired = nil
;

/** Pure monthly wage outcome from an already selected roll, full-2008 B516.
 * Raise timing is an explicit author choice because the source does not specify
 * whether the permanent increase begins in the rolled month or the next one. */
rpgExpandedJobEarnings(monthlyPay, variable, score, roll, raiseTiming)
{
    rpgInteger(monthlyPay,0,2147483647);
    local value = new RpgExpandedJobEarnings(); value.nextPay = monthlyPay;
    value.check = rpgCheck(score,roll);
    if (value.check.status != 'resolved') { value.reason = value.check.reason; return value; }
    if (value.check.critical == 'failure')
    { value.consequenceRequired = true; value.status = 'ready'; return value; }
    if (value.check.critical == 'success')
    {
        if (variable) value.money = rpgExpandedJobPercent(monthlyPay,300);
        else
        {
            if (!holds(['this-month','next-month'],raiseTiming))
            { value.reason = 'job-raise-timing-required'; return value; }
            value.nextPay = rpgExpandedJobPercent(monthlyPay,110);
            value.money = raiseTiming == 'this-month' ? value.nextPay : monthlyPay;
        }
    }
    else if (!variable) value.money = monthlyPay;
    else
    {
        if (!value.check.achieved && value.check.margin > 0)
        { value.reason = 'job-automatic-failure-margin-unresolved'; return value; }
        local percent = 100 + value.check.margin * 10;
        if (percent < 0) { value.reason = 'job-negative-income-unresolved'; return value; }
        value.money = rpgExpandedJobPercent(monthlyPay,percent);
    }
    value.status = 'ready'; return value;
}

modify RpgExpandedProfile
    employments = []
;

/** Owned employment state. Job definitions may be shared; pay and receipts may not. */
class RpgExpandedEmployment: object
    payer = nil
    id = nil
    owner = nil
    job = nil
    monthlyPay = 0
    variable = nil
    raiseTiming = nil
    failurePolicy = nil
    active = true
    lastMonth = 0
    lastMonthAt = 0
    months = []
    validate()
    {
        if (self.id == nil || self.owner == nil || !self.owner.ofKind(RpgExpandedProfile)
            || !holds(self.owner.employments,self) || self.job == nil || !self.job.ofKind(RpgExpandedJob))
            rpgExpandedReject('employment-owner');
        foreach (local entry in self.owner.employments)
            if (entry != self && entry.id == self.id) rpgExpandedReject('duplicate-employment');
        rpgInteger(self.monthlyPay,0,2147483647); rpgInteger(self.lastMonth,0,1000000);
        return nil;
    }
;

/** Concrete financial/dismissal consequences for critical job failures, B516.
 * Injury/arrest policies require their own subsystem and are not approximated. */
class RpgExpandedJobFailure: object
    kind = 'unpaid'
    evidence = nil
    retainedPayPercent = 90
    lostSavings = 0
    validate(employment)
    {
        if (!holds(['unpaid','demotion','dismissal'],self.kind) || self.evidence == nil)
            rpgExpandedReject('job-failure-policy');
        rpgInteger(self.lostSavings,0,2147483647);
        if (self.lostSavings > employment.owner.money) rpgExpandedReject('job-failure-loss-unfunded');
        if (self.kind == 'demotion')
        { rpgInteger(self.retainedPayPercent,0,90); rpgExpandedJobPercent(employment.monthlyPay,self.retainedPayPercent); }
        return nil;
    }
;

/** One completed full month's work. Author supplies the actual calendar date
 * and worked-month fact; settlement never adds a second month to the clock. */
class RpgExpandedJobMonth: object
    employment = nil
    wealthReview = nil
    month = 1
    dueAt = nil
    fullMonthWorked = nil
    assess()
    {
        if (self.employment == nil || !self.employment.ofKind(RpgExpandedEmployment))
            rpgExpandedReject('job-month-employment');
        self.employment.validate(); rpgInteger(self.month,1,1000000);
        local value = new RpgExpandedJobEarnings(); local employment = self.employment;
        foreach (local receipt in employment.months)
            if (receipt[1] == self.month) { value.status = 'reused'; return value; }
        if (!employment.active) { value.reason = 'employment-inactive'; return value; }
        if (self.month != employment.lastMonth + 1) { value.reason = 'job-month-gap'; return value; }
        rpgInteger(self.dueAt,1,2147483647);
        if (self.dueAt <= employment.lastMonthAt) rpgExpandedReject('job-month-date-order');
        if (!self.fullMonthWorked) { value.reason = 'job-full-month-required'; return value; }
        if (rpgLedger.seconds < self.dueAt) { value.reason = 'job-month-not-due'; return value; }
        local qualification = employment.job.assess(employment.owner);
        if (qualification.status != 'ready') { value.reason = qualification.reason; return value; }
        rpgInteger(employment.owner.money,0,2147483647);
        if (employment.failurePolicy == nil || !employment.failurePolicy.ofKind(RpgExpandedJobFailure))
            rpgExpandedReject('job-failure-policy');
        employment.failurePolicy.validate(employment);
        if (employment.payer != nil)
        {
            if (!employment.payer.ofKind(RpgExpandedProfile) || employment.payer == employment.owner)
                rpgExpandedReject('employment-payroll-payer');
            rpgExpandedValidate(employment.payer); rpgInteger(employment.payer.money,0,2147483647);
        }
        if (employment.job.wealthLevel != nil && self.wealthReview == nil)
        { value.reason = 'employment-wealth-review-required'; return value; }
        if (self.wealthReview != nil && (!self.wealthReview.ofKind(RpgExpandedEmploymentWealthReview)
            || self.wealthReview.employment != employment)) rpgExpandedReject('employment-wealth-owner');
        for (local roll = 3; roll <= 18; roll += 1)
        {
            local outcome = rpgExpandedJobEarnings(employment.monthlyPay,employment.variable,qualification.score,roll,employment.raiseTiming);
            if (outcome.status != 'ready') { value.reason = outcome.reason; return value; }
            if (outcome.money > 2147483647 - employment.owner.money) rpgExpandedReject('job-month-money-limit');
            if (employment.payer != nil && outcome.money > employment.payer.money)
            { value.reason = 'employment-payroll-funds'; return value; }
            if (self.wealthReview != nil)
            {
                local balance = employment.owner.money + outcome.money
                    - (outcome.consequenceRequired ? employment.failurePolicy.lostSavings : 0);
                local review = self.wealthReview.assessMoney(balance);
                if (review.status == 'blocked' && review.reason != 'wealth-advancement-money')
                { value.reason = review.reason; return value; }
            }
        }
        value.status = 'ready'; return value;
    }
    settle()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local employment = self.employment;
        local qualification = employment.job.assess(employment.owner);
        value = rpgExpandedJobEarnings(employment.monthlyPay,employment.variable,qualification.score,rpgRandom.roll(),employment.raiseTiming);
        local loss = 0;
        if (value.consequenceRequired)
        {
            local policy = employment.failurePolicy; loss = policy.lostSavings;
            if (policy.kind == 'demotion') value.nextPay = rpgExpandedJobPercent(employment.monthlyPay,policy.retainedPayPercent);
            if (policy.kind == 'dismissal') employment.active = nil;
        }
        if (employment.payer != nil) employment.payer.money -= value.money;
        employment.owner.money += value.money - loss; employment.monthlyPay = value.nextPay;
        employment.months = employment.months + [[self.month,self.dueAt,value.check,value.money,value.nextPay,loss,employment.active]];
        employment.lastMonth = self.month; employment.lastMonthAt = self.dueAt;
        if (self.wealthReview != nil) value.wealthObligation = self.wealthReview.record().obligation;
        value.status = 'resolved'; return value;
    }
;

/** Generic monthly living costs by supported status, full-2008 B265. */
rpgExpandedLivingCost(status)
{
    rpgInteger(status,-2,8);
    local costs = [100,300,600,1200,3000,12000,60000,600000,6000000,60000000,600000000];
    return costs[status + 3];
}

class RpgExpandedLifestylePrice: RpgExpandedResult
    money = 0
    weight = nil
    minimumWeight = nil
;

/** Living-cost-derived prices, B265-B266. Status is the chosen service level,
 * already adjusted by the author for organizational support or local exceptions. */
class RpgExpandedLifestyle: object
    status = 0
    kind = 'monthly'
    conservativeOutfit = nil
    fashionBenefit = nil
    assess()
    {
        rpgInteger(self.status,-2,8);
        if (!holds(['monthly','travel-month','lodging-day','breakfast','lunch','dinner',
            'rations-week','liquor-bottle','wardrobe','ordinary-outfit','winter-outfit','formal-outfit','cosmetics-month'],self.kind))
            rpgExpandedReject('lifestyle-price-kind');
        local level = self.status;
        local singleOutfit = holds(['ordinary-outfit','winter-outfit','formal-outfit'],self.kind);
        if (holds(['breakfast','lunch','dinner','rations-week','liquor-bottle'],self.kind) || singleOutfit)
            if (level > 3) level = 3;
        if (singleOutfit && self.conservativeOutfit && !(self.fashionBenefit && self.status >= 3) && level > 2)
            level = 2;
        if (self.conservativeOutfit && !singleOutfit) rpgExpandedReject('lifestyle-outfit-convention');
        local percent = 100; local value = new RpgExpandedLifestylePrice();
        if (self.kind == 'travel-month') percent = 600;
        if (self.kind == 'lodging-day') percent = 20;
        if (holds(['breakfast','lunch','liquor-bottle'],self.kind)) percent = 1;
        if (self.kind == 'dinner') percent = 2;
        if (self.kind == 'rations-week') { percent = 5; value.weight = 1400; }
        if (self.kind == 'wardrobe') { value.weight = 2000; value.minimumWeight = true; }
        if (self.kind == 'ordinary-outfit') { percent = 20; value.weight = 200; }
        if (self.kind == 'winter-outfit') { percent = 30; value.weight = 400; }
        if (self.kind == 'formal-outfit') { percent = 40; value.weight = 200; }
        if (self.kind == 'cosmetics-month') { percent = 10; value.weight = 200; }
        value.money = rpgExpandedJobPercent(rpgExpandedLivingCost(level),percent);
        value.status = 'ready'; return value;
    }
;

modify RpgExpandedProfile
    livingPayments = []
    lastLivingPaymentAt = -1
    fundedLivingStatus = nil
;

/** Full-period household payment, B265/B516. Members are [beneficiary, status].
 * Per-beneficiary receipts prevent another payer from charging the same period. */
class RpgExpandedLivingPayment: object
    id = nil
    period = nil
    payer = nil
    dueAt = 0
    members = []
    approved = nil
    claimed = nil
    boundPayer = nil
    boundId = nil
    boundPeriod = nil
    assess()
    {
        if (self.id == nil || self.period == nil || self.payer == nil || !self.payer.ofKind(RpgExpandedProfile)
            || self.members.length() == 0) rpgExpandedReject('living-payment-target');
        if (self.claimed && (self.payer != self.boundPayer || self.id != self.boundId || self.period != self.boundPeriod))
            rpgExpandedReject('living-payment-retargeted');
        rpgInteger(self.dueAt,0,2147483647);
        local value = new RpgExpandedAcquisitionResult(); local seen = []; local paid = 0; local total = 0;
        foreach (local member in self.members)
        {
            if (member.length() != 2 || member[1] == nil || !member[1].ofKind(RpgExpandedProfile) || holds(seen,member[1]))
                rpgExpandedReject('living-payment-member');
            seen = seen + [member[1]]; local cost = rpgExpandedLivingCost(member[2]);
            if (cost > 2147483647 - total) rpgExpandedReject('living-payment-limit');
            total += cost; local covered = nil;
            foreach (local receipt in member[1].livingPayments)
                if (receipt[1] == self.period)
                {
                    if (receipt[2] != self.id || receipt[3] != self.payer || receipt[4] != member[2])
                    { value.reason = 'living-period-already-covered'; return value; }
                    paid += 1; covered = true;
                }
            if (!covered && self.dueAt <= member[1].lastLivingPaymentAt)
                rpgExpandedReject('living-payment-date-order');
        }
        if (paid == self.members.length()) { value.status = 'reused'; return value; }
        if (paid != 0) { value.reason = 'living-payment-partial-overlap'; return value; }
        if (self.claimed) rpgExpandedReject('living-payment-members-changed');
        if (!self.approved) { value.reason = 'living-payment-unapproved'; return value; }
        if (rpgLedger.seconds < self.dueAt) { value.reason = 'living-payment-not-due'; return value; }
        rpgExpandedValidate(self.payer); rpgInteger(self.payer.money,0,2147483647);
        if (self.payer.money < total) { value.reason = 'living-payment-funds'; return value; }
        value.money = total; value.status = 'ready'; return value;
    }
    pay()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.payer.money -= value.money;
        foreach (local member in self.members)
        {
            member[1].livingPayments = member[1].livingPayments
                + [[self.period,self.id,self.payer,member[2],rpgExpandedLivingCost(member[2]),self.dueAt]];
            member[1].lastLivingPaymentAt = self.dueAt; member[1].fundedLivingStatus = member[2];
        }
        self.claimed = true; self.boundPayer = self.payer; self.boundId = self.id; self.boundPeriod = self.period;
        value.status = 'resolved'; return value;
    }
;

/** Employment wealth scales belong to the job, not to the worker, B517. */
rpgExpandedJobWealthPay(techLevel, supportedStatus)
{
    rpgInteger(supportedStatus,-2,8);
    local amount = rpgExpandedTypicalJobPay(techLevel);
    if (supportedStatus < 0)
    {
        local divisor = supportedStatus == -2 ? 5 : 2;
        if (amount % divisor != 0) rpgExpandedReject('job-fractional-money');
        return amount / divisor;
    }
    local multipliers = [1,2,5,20,100,1000,10000,100000,1000000];
    local factor = multipliers[supportedStatus + 1];
    if (amount > 2147483647 / factor) rpgExpandedReject('job-money-limit');
    return amount * factor;
}

/** Population modifier shared by recruiting and job seeking, B517-B518. */
rpgExpandedEmploymentPopulation(population)
{
    rpgInteger(population,0,2147483647);
    if (population < 100) return -3;
    if (population < 1000) return -2;
    if (population < 5000) return -1;
    if (population < 10000) return 0;
    if (population < 50000) return 1;
    if (population < 100000) return 2;
    return 3;
}

/** Advertising thresholds are exact fractions of pay; integer budgets must meet
 * the next whole-unit ceiling. Keep the remainder when multiplying thresholds. */
rpgExpandedEmploymentAdvertising(monthlyPay, budget, recruiting)
{
    rpgInteger(monthlyPay,1,2147483647); rpgInteger(budget,0,2147483647);
    local divisor = recruiting ? 2 : 20;
    local quotient = monthlyPay / divisor; local remainder = monthlyPay % divisor;
    local bonus = 0;
    while (quotient < budget || (quotient == budget && remainder == 0))
    {
        bonus += 1;
        local tail = (remainder * 10) / divisor;
        if (quotient > (2147483647 - tail) / 10) return bonus;
        quotient = quotient * 10 + tail; remainder = (remainder * 10) % divisor;
    }
    return bonus;
}

/** Pure recruiting modifiers, B518. The search operation owns expenditure and
 * the weekly attempt limit; this assessment never creates or hires an NPC. */
class RpgExpandedRecruitingModifiers: object
    population = 0
    normalPay = 1
    offeredPay = 1
    advertising = 0
    combatRisk = nil
    combatantRole = nil
    illegal = nil
    streetwiseSearch = nil
    waiveIllegalPenalty = nil
    assess()
    {
        rpgInteger(self.normalPay,1,2147483647); rpgInteger(self.offeredPay,0,2147483647);
        if (self.waiveIllegalPenalty && (!self.illegal || !self.streetwiseSearch))
            rpgExpandedReject('recruiting-illegal-waiver');
        local value = new RpgExpandedResult();
        value.modifier = rpgExpandedEmploymentPopulation(self.population)
            + rpgExpandedEmploymentAdvertising(self.normalPay,self.advertising,true);
        // Compare exact ratios without overflowing a multiplication of large pay.
        local quotient = self.normalPay / 10; local remainder = self.normalPay % 10;
        local factors = [12,15,20]; local bonus = 0; local index = 0;
        foreach (local factor in factors)
        {
            index += 1; local tail = (remainder * factor + 9) / 10;
            if (quotient <= (2147483647 - tail) / factor
                && self.offeredPay >= quotient * factor + tail) bonus = index;
        }
        value.modifier += bonus;
        if (self.combatRisk && !self.combatantRole) value.modifier -= 2;
        if (self.illegal && !self.waiveIllegalPenalty) value.modifier -= 5;
        value.status = 'ready'; return value;
    }
;


/** Job-search modifiers and IQ target, full-2008 B518. Selecting one qualifying
 * skill avoids inventing stacking rules for jobs with several prerequisites. */
class RpgExpandedJobSeekingModifiers: object
    profile = nil
    job = nil
    population = 0
    monthlyPay = 1
    advertising = 0
    supportedStatus = 0
    simultaneousJobs = 1
    qualificationSkill = nil
    otherAbilityBonus = 0
    otherAbilityEvidence = nil
    lazy = nil
    employerRequired = true
    assess() { return self.assessCount(self.simultaneousJobs); }
    assessCount(count)
    {
        if (self.job == nil || !self.job.ofKind(RpgExpandedJob)) rpgExpandedReject('job-search-job');
        local value = self.job.qualifications(self.profile); if (value.status != 'ready') return value;
        value.status = 'blocked';
        if (!self.employerRequired) { value.reason = 'job-search-self-employment'; return value; }
        rpgInteger(self.supportedStatus,-2,8); rpgInteger(count,1,1000);
        rpgInteger(self.otherAbilityBonus,0,1000);
        if (self.otherAbilityBonus != 0 && self.otherAbilityEvidence == nil)
            rpgExpandedReject('job-search-ability-evidence');
        local skill = self.qualificationSkill;
        if (skill == nil && self.job.prerequisites.length() == 1) skill = self.job.prerequisites[1][1];
        if (skill == nil && self.job.prerequisites.length() > 1)
            rpgExpandedReject('job-search-qualification-choice');
        local experience = 0; local found = skill == nil;
        foreach (local row in self.job.prerequisites)
            if (row[1] == skill)
            {
                local minimum = row[2] + (row[3] ? self.profile.attributeScore(skill.attribute) : 0);
                experience = self.profile.skillScore(skill) - minimum; found = true;
            }
        if (!found) rpgExpandedReject('job-search-qualification-skill');
        if (experience > 2) experience = 2;
        value.modifier = rpgExpandedEmploymentPopulation(self.population)
            + rpgExpandedEmploymentAdvertising(self.monthlyPay,self.advertising,nil)
            + experience + self.otherAbilityBonus - 2 * self.supportedStatus
            - (count - 1) - (self.lazy ? 5 : 0);
        value.score = self.profile.attributeScore(rpgIQ) + value.modifier;
        rpgInteger(value.score,-1000,1000);
        value.skill = skill;
        if (value.score < 3) { value.reason = 'job-search-roll-unavailable'; return value; }
        value.status = 'ready'; return value;
    }
;

modify RpgExpandedProfile
    jobSearchReceipts = []
    lastJobSearchAt = nil
;

/** Concrete authored employer and terms revealed by a successful search. */
class RpgExpandedJobOpportunity: object
    job = nil
    employer = nil
    terms = nil
    monthlyPay = 0
    available = nil
;

class RpgExpandedJobSearchResult: RpgExpandedResult
    money = 0
    assessments = []
    outcomes = []
;

/** One weekly batch of employer searches, B518. Rows are [context, opportunity].
 * Every row is validated before any advertising is charged or dice are drawn. */
class RpgExpandedJobSearch: object
    id = nil
    profile = nil
    searches = []
    permitted = nil
    boundProfile = nil
    boundId = nil
    assess()
    {
        if (self.id == nil || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile))
            rpgExpandedReject('job-search-owner');
        if (self.boundProfile != nil && (self.profile != self.boundProfile || self.id != self.boundId))
            rpgExpandedReject('job-search-retargeted');
        local value = new RpgExpandedJobSearchResult();
        foreach (local receipt in self.profile.jobSearchReceipts)
            if (receipt[1] == self.id) { value.status = 'reused'; return value; }
        rpgExpandedValidate(self.profile);
        if (!self.permitted) { value.reason = 'job-search-unapproved'; return value; }
        if (self.profile.dead || self.profile.unconscious) { value.reason = 'cannot-search-jobs'; return value; }
        rpgInteger(rpgLedger.seconds,0,2147483647);
        if (self.profile.lastJobSearchAt != nil)
        {
            rpgInteger(self.profile.lastJobSearchAt,0,2147483647);
            if (rpgLedger.seconds < self.profile.lastJobSearchAt
                || rpgLedger.seconds - self.profile.lastJobSearchAt < 604800)
            { value.reason = 'job-search-week-used'; return value; }
        }
        rpgInteger(self.searches.length(),1,1000); local jobs = []; local total = 0;
        foreach (local row in self.searches)
        {
            if (row.length() != 2 || row[1] == nil || !row[1].ofKind(RpgExpandedJobSeekingModifiers)
                || row[2] == nil || !row[2].ofKind(RpgExpandedJobOpportunity))
                rpgExpandedReject('job-search-row');
            local context = row[1]; local offer = row[2];
            if (context.profile != self.profile) rpgExpandedReject('job-search-context-owner');
            local assessment = context.assessCount(self.searches.length());
            if (assessment.status != 'ready') { value.reason = assessment.reason; return value; }
            if (holds(jobs,context.job.id)) rpgExpandedReject('job-search-duplicate-job');
            jobs = jobs + [context.job.id];
            if (offer.job != context.job || offer.employer == nil || offer.terms == nil
                || offer.monthlyPay != context.monthlyPay) rpgExpandedReject('job-search-opportunity');
            if (!offer.available) { value.reason = 'job-search-opportunity-unavailable'; return value; }
            if (context.advertising > 2147483647 - total) rpgExpandedReject('job-search-cost-limit');
            total += context.advertising; value.assessments = value.assessments + [assessment];
        }
        rpgInteger(self.profile.money,0,2147483647);
        if (total > self.profile.money) { value.reason = 'job-search-funds'; return value; }
        value.money = total; value.status = 'ready'; return value;
    }
    search()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.profile.money -= value.money; local index = 0;
        foreach (local row in self.searches)
        {
            index += 1; local check = rpgCheck(value.assessments[index].score,rpgRandom.roll());
            value.outcomes = value.outcomes + [[row[1].job,check,check.achieved ? row[2] : nil]];
        }
        self.profile.jobSearchReceipts = self.profile.jobSearchReceipts
            + [[self.id,rpgLedger.seconds,value.outcomes,value.money]];
        self.profile.lastJobSearchAt = rpgLedger.seconds;
        self.boundProfile = self.profile; self.boundId = self.id;
        value.status = 'resolved'; return value;
    }
;

modify RpgExpandedEmployment
    employer = nil
    terms = nil
    opportunity = nil
    startedAt = nil
;

modify RpgExpandedJobOpportunity
    payer = nil
    variable = nil
    raiseTiming = 'next-month'
    failurePolicy = nil
    acceptedEmployment = nil
    employmentFor(profile, id)
    {
        local employment = new RpgExpandedEmployment();
        employment.id = id; employment.owner = profile; employment.job = self.job;
        employment.monthlyPay = self.monthlyPay; employment.variable = self.variable; employment.payer = self.payer;
        employment.raiseTiming = self.raiseTiming; employment.employer = self.employer;
        employment.terms = self.terms; employment.opportunity = self;
        if (self.failurePolicy == nil || !self.failurePolicy.ofKind(RpgExpandedJobFailure))
            rpgExpandedReject('job-offer-failure-policy');
        local policy = new RpgExpandedJobFailure(); policy.kind = self.failurePolicy.kind;
        policy.evidence = self.failurePolicy.evidence; policy.retainedPayPercent = self.failurePolicy.retainedPayPercent;
        policy.lostSavings = self.failurePolicy.lostSavings; employment.failurePolicy = policy;
        return employment;
    }
;

class RpgExpandedEmploymentAcceptanceResult: RpgExpandedResult
    employment = nil
;

/** Accept concrete employment terms after discovery or an authored direct offer.
 * No wages accrue merely from accepting. Each opportunity creates at most one post. */
class RpgExpandedEmploymentAcceptance: object
    profile = nil
    opportunity = nil
    employmentId = nil
    applicantAgrees = nil
    employerAgrees = nil
    scheduleApproved = nil
    directOfferEvidence = nil
    recruitingVacancy = nil
    assess()
    {
        if (self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)
            || self.opportunity == nil || !self.opportunity.ofKind(RpgExpandedJobOpportunity)
            || self.employmentId == nil) rpgExpandedReject('employment-acceptance-target');
        local value = new RpgExpandedEmploymentAcceptanceResult(); local offer = self.opportunity;
        if (offer.acceptedEmployment != nil)
        {
            local existing = offer.acceptedEmployment;
            if (existing.owner == self.profile && existing.id == self.employmentId)
            { existing.validate(); value.status = 'reused'; value.employment = existing; return value; }
            value.reason = 'employment-offer-filled'; return value;
        }
        rpgExpandedValidate(self.profile);
        foreach (local existing in self.profile.employments)
            if (existing.id == self.employmentId) rpgExpandedReject('duplicate-employment');
        if (!self.applicantAgrees || !self.employerAgrees || !self.scheduleApproved)
        { value.reason = 'employment-agreement-required'; return value; }
        if (!offer.available) { value.reason = 'employment-offer-unavailable'; return value; }
        if (self.profile.dead || self.profile.unconscious) { value.reason = 'cannot-accept-employment'; return value; }
        if (offer.job == nil || !offer.job.ofKind(RpgExpandedJob) || offer.employer == nil || offer.terms == nil)
            rpgExpandedReject('employment-offer-terms');
        local discovered = self.directOfferEvidence != nil;
        if (self.recruitingVacancy != nil)
        {
            local vacancy = self.recruitingVacancy;
            if (!vacancy.ofKind(RpgExpandedRecruitingVacancy)) rpgExpandedReject('employment-recruiting-vacancy');
            vacancy.validate();
            if (offer.employer != vacancy.party) rpgExpandedReject('employment-recruiting-employer');
            if (!vacancy.open || vacancy.hiredEmployment != nil)
            { value.reason = 'employment-recruiting-closed'; return value; }
            if (vacancy.pendingCandidate != self.profile)
            { value.reason = 'employment-recruiting-interview'; return value; }
            local presented = nil;
            foreach (local receipt in vacancy.attempts)
                if (receipt[5] == self.profile && receipt[4].achieved) presented = true;
            if (!presented) rpgExpandedReject('employment-recruiting-evidence');
            discovered = true;
        }
        foreach (local receipt in self.profile.jobSearchReceipts)
            foreach (local outcome in receipt[3])
                if (outcome[3] == offer && outcome[1] == offer.job && outcome[2].achieved) discovered = true;
        if (!discovered) { value.reason = 'employment-offer-undiscovered'; return value; }
        local qualification = offer.job.assess(self.profile);
        if (qualification.status != 'ready') { value.reason = qualification.reason; return value; }
        rpgInteger(self.profile.money,0,2147483647);
        local employment = offer.employmentFor(self.profile,self.employmentId);
        if (employment.payer != nil)
        {
            if (!employment.payer.ofKind(RpgExpandedProfile) || employment.payer == self.profile)
                rpgExpandedReject('employment-payroll-payer');
            rpgExpandedValidate(employment.payer);
        }
        employment.failurePolicy.validate(employment);
        for (local roll = 3; roll <= 18; roll += 1)
        {
            local outcome = rpgExpandedJobEarnings(employment.monthlyPay,employment.variable,qualification.score,roll,employment.raiseTiming);
            if (outcome.status != 'ready') { value.reason = outcome.reason; return value; }
        }
        value.status = 'ready'; return value;
    }
    accept()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local employment = self.opportunity.employmentFor(self.profile,self.employmentId);
        employment.startedAt = rpgLedger.seconds; employment.lastMonthAt = rpgLedger.seconds;
        self.profile.employments = self.profile.employments + [employment];
        self.opportunity.acceptedEmployment = employment; self.opportunity.available = nil;
        if (self.recruitingVacancy != nil)
        {
            self.recruitingVacancy.hiredEmployment = employment;
            self.recruitingVacancy.open = nil; self.recruitingVacancy.pendingCandidate = nil;
        }
        value.employment = employment; value.status = 'resolved'; return value;
    }
;

/** One authored party shares vacancy records across all of its recruiters. */
class RpgExpandedRecruitingParty: object
    members = []
    vacancies = []
;

class RpgExpandedRecruitingVacancy: object
    id = nil
    party = nil
    open = true
    attempts = []
    lastAttemptAt = nil
    pendingCandidate = nil
    hiredEmployment = nil
    declined = []
    validate()
    {
        if (self.id == nil || self.party == nil || !self.party.ofKind(RpgExpandedRecruitingParty)
            || !holds(self.party.vacancies,self)) rpgExpandedReject('recruiting-vacancy-owner');
        foreach (local other in self.party.vacancies)
            if (other != self && other.id == self.id) rpgExpandedReject('duplicate-recruiting-vacancy');
        return nil;
    }
    decline(candidate, evidence)
    {
        self.validate();
        if (candidate == nil || candidate != self.pendingCandidate || evidence == nil)
            rpgExpandedReject('recruiting-decline-candidate');
        self.declined = self.declined + [[candidate,evidence,rpgLedger.seconds]];
        self.pendingCandidate = nil; return nil;
    }
;

/** An explicit authored fine for the legal-complication branch. Other sanctions
 * need their own concrete policy, rather than silently disappearing on failure. */
class RpgExpandedRecruitingFine: object
    authority = nil
    evidence = nil
    recipient = nil
    amount = 0
    validate(payer, advertising)
    {
        if (self.authority == nil || self.evidence == nil || self.recipient == nil
            || !self.recipient.ofKind(RpgExpandedProfile) || self.recipient == payer)
            rpgExpandedReject('recruiting-fine-policy');
        rpgExpandedValidate(self.recipient); rpgInteger(self.amount,1,2147483647);
        rpgInteger(self.recipient.money,0,2147483647);
        if (self.amount > 2147483647 - self.recipient.money) rpgExpandedReject('recruiting-fine-limit');
        if (advertising > payer.money || self.amount > payer.money - advertising)
            return 'recruiting-fine-funds';
        return nil;
    }
;

class RpgExpandedRecruitingResult: RpgExpandedResult
    money = 0
    score = nil
    candidate = nil
    fine = 0
;

/** One weekly attempt for a party's vacancy, full-2008 B517-B518. */
class RpgExpandedRecruitingAttempt: object
    id = nil
    vacancy = nil
    recruiter = nil
    context = nil
    modifiers = nil
    permitted = nil
    repeatApproved = nil
    skillEvidence = nil
    streetwiseSkill = nil
    candidate = nil
    candidateAvailable = nil
    candidateEvidence = nil
    legalFine = nil
    boundVacancy = nil
    boundRecruiter = nil
    boundId = nil
    assess()
    {
        if (self.id == nil || self.vacancy == nil || !self.vacancy.ofKind(RpgExpandedRecruitingVacancy))
            rpgExpandedReject('recruiting-attempt-vacancy');
        if (self.boundVacancy != nil && (self.vacancy != self.boundVacancy
            || self.recruiter != self.boundRecruiter || self.id != self.boundId))
            rpgExpandedReject('recruiting-attempt-retargeted');
        self.vacancy.validate(); local value = new RpgExpandedRecruitingResult();
        foreach (local receipt in self.vacancy.attempts)
            if (receipt[1] == self.id) { value.status = 'reused'; return value; }
        if (self.recruiter == nil || !self.recruiter.ofKind(RpgExpandedProfile)
            || !holds(self.vacancy.party.members,self.recruiter)) rpgExpandedReject('recruiting-party-member');
        rpgExpandedValidate(self.recruiter); rpgInteger(self.recruiter.money,0,2147483647);
        if (!self.permitted || !self.vacancy.open) { value.reason = 'recruiting-unavailable'; return value; }
        if (self.recruiter.dead || self.recruiter.unconscious) { value.reason = 'cannot-recruit'; return value; }
        if (self.vacancy.pendingCandidate != nil) { value.reason = 'recruiting-interview-pending'; return value; }
        rpgInteger(rpgLedger.seconds,0,2147483647);
        if (self.vacancy.lastAttemptAt != nil)
        {
            rpgInteger(self.vacancy.lastAttemptAt,0,2147483647);
            if (rpgLedger.seconds < self.vacancy.lastAttemptAt || rpgLedger.seconds - self.vacancy.lastAttemptAt < 604800)
            { value.reason = 'recruiting-week-used'; return value; }
            if (!self.repeatApproved) { value.reason = 'recruiting-repeat-unapproved'; return value; }
        }
        if (self.context == nil || !self.context.ofKind(RpgLiteContext) || self.context.kind != 'recruiting'
            || (self.context.skill == nil && self.context.attribute != rpgIQ)) rpgExpandedReject('recruiting-context');
        if (self.context.skill != nil && self.skillEvidence == nil) rpgExpandedReject('recruiting-skill-evidence');
        if (self.modifiers == nil || !self.modifiers.ofKind(RpgExpandedRecruitingModifiers))
            rpgExpandedReject('recruiting-modifiers');
        local adjustment = self.modifiers.assess();
        if (self.modifiers.waiveIllegalPenalty && (self.streetwiseSkill == nil || self.context.skill != self.streetwiseSkill))
            rpgExpandedReject('recruiting-streetwise-waiver');
        local base = rpgLiteScore(self.recruiter,self.context);
        if (base == nil) { value.reason = self.context.unavailableReason(self.recruiter); return value; }
        value.score = base + adjustment.modifier; rpgInteger(value.score,-1000,1000);
        if (value.score < 3) { value.reason = 'recruiting-roll-unavailable'; return value; }
        if (self.candidate == nil || !self.candidate.ofKind(RpgExpandedProfile) || self.candidateEvidence == nil)
            rpgExpandedReject('recruiting-candidate');
        rpgExpandedValidate(self.candidate);
        if (!self.candidateAvailable) { value.reason = 'recruiting-candidate-unavailable'; return value; }
        value.money = self.modifiers.advertising;
        if (value.money > self.recruiter.money) { value.reason = 'recruiting-advertising-funds'; return value; }
        if (self.modifiers.illegal)
        {
            if (self.legalFine == nil || !self.legalFine.ofKind(RpgExpandedRecruitingFine))
                rpgExpandedReject('recruiting-legal-consequence');
            value.reason = self.legalFine.validate(self.recruiter,value.money);
            if (value.reason != nil) return value;
        }
        value.status = 'ready'; return value;
    }
    search()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.recruiter.money -= value.money;
        value.check = rpgCheck(value.score,rpgRandom.roll());
        if (self.modifiers.illegal && value.check.critical == 'failure')
        {
            value.fine = self.legalFine.amount; self.recruiter.money -= value.fine;
            self.legalFine.recipient.money += value.fine;
        }
        if (value.check.achieved) { value.candidate = self.candidate; self.vacancy.pendingCandidate = self.candidate; }
        self.vacancy.attempts = self.vacancy.attempts
            + [[self.id,self.recruiter,rpgLedger.seconds,value.check,value.candidate,value.money,value.fine]];
        self.boundVacancy = self.vacancy; self.boundRecruiter = self.recruiter; self.boundId = self.id;
        self.vacancy.lastAttemptAt = rpgLedger.seconds; value.status = 'resolved'; return value;
    }
;

modify RpgExpandedProfile
    wealthAdvancements = []
;

/** Receipt for a purchased wealth increase, full-2008 B291. */
class RpgExpandedWealthAdvancementResult: RpgExpandedResult
    requiredMoney = 0
;

/** Increase an owned wealth contribution after accumulating the required money.
 * obligationsSettled and evidence describe the authored tax/bribe adjudication.
 * Qualification does not consume money or create a second opening allocation. */
class RpgExpandedWealthAdvancement: object
    id = nil
    profile = nil
    wealth = nil
    targetLevel = 'comfortable'
    targetExtraLevels = 0
    permitted = nil
    obligationsSettled = nil
    evidence = nil
    employmentSources = []
    purchased = nil
    boundProfile = nil
    boundWealth = nil
    boundId = nil
    boundLevel = nil
    boundExtraLevels = 0
    boundEvidence = nil
    paidPoints = 0
    requiredMoney = 0
    assess()
    {
        if (self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)
            || self.wealth == nil || !self.wealth.ofKind(RpgExpandedWealth)
            || self.wealth.owner != self.profile || !holds(self.profile.contributions,self.wealth)
            || self.id == nil || self.id == '') rpgExpandedReject('wealth-advancement-owner');
        local value = new RpgExpandedWealthAdvancementResult();
        if (self.purchased)
        {
            if (self.profile != self.boundProfile || self.wealth != self.boundWealth
                || self.id != self.boundId || self.targetLevel != self.boundLevel
                || self.targetExtraLevels != self.boundExtraLevels)
                rpgExpandedReject('wealth-advancement-retargeted');
            value.status = 'reused'; value.requiredMoney = self.requiredMoney; return value;
        }
        foreach (local previous in self.profile.wealthAdvancements)
            if (previous.id == self.id) rpgExpandedReject('wealth-advancement-duplicate');
        rpgExpandedValidate(self.profile);
        rpgInteger(self.profile.money, 0, 2147483647);
        rpgInteger(self.profile.unspentPoints, 0, 1000000);
        rpgInteger(self.profile.developmentRevision, 0, 2147483646);
        local target = new RpgExpandedWealth(); target.wealthLevel = self.targetLevel;
        target.extraLevels = self.targetExtraLevels;
        value.points = target.amounts(self.profile)[1] - self.wealth.amounts(self.profile)[1];
        if (value.points <= 0) { value.reason = 'wealth-advancement-not-increase'; return value; }
        value.requiredMoney = target.startingValue(self.profile.campaignTL);
        if (!self.profile.creationComplete) { value.reason = 'wealth-advancement-after-creation'; return value; }
        if (!self.permitted) { value.reason = 'wealth-advancement-unapproved'; return value; }
        if (!self.obligationsSettled || self.evidence == nil || self.evidence == '')
        { value.reason = 'wealth-advancement-obligations'; return value; }
        if (self.profile.money < value.requiredMoney)
        { value.reason = 'wealth-advancement-money'; return value; }
        if (self.profile.unspentPoints < value.points)
        { value.reason = 'wealth-advancement-points'; return value; }
        if (self.profile.pendingWealthObligation(self) != nil)
        { value.reason = 'employment-wealth-priority'; return value; }
        foreach (local employment in self.employmentSources)
        {
            local review = self.continuingReview(employment);
            local next = review.assessWealth(self.profile.money,target,self);
            if (next.status == 'blocked' && !holds(['wealth-advancement-money','employment-inactive'],next.reason))
            { value.reason = next.reason; return value; }
        }
        value.status = 'ready'; return value;
    }
    advance()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.boundProfile = self.profile; self.boundWealth = self.wealth; self.boundId = self.id;
        self.boundLevel = self.targetLevel; self.boundExtraLevels = self.targetExtraLevels;
        self.boundEvidence = self.evidence;
        self.paidPoints = value.points; self.requiredMoney = value.requiredMoney;
        self.profile.unspentPoints -= value.points;
        self.wealth.wealthLevel = self.targetLevel; self.wealth.extraLevels = self.targetExtraLevels;
        self.profile.developmentRevision += 1; self.purchased = true;
        self.profile.wealthAdvancements = self.profile.wealthAdvancements + [self];
        foreach (local employment in self.employmentSources) self.continuingReview(employment).record();
        value.status = 'resolved'; return value;
    }
    /* Pure construction from the same settled money; paying points changes no cash. */
    continuingReview(employment)
    {
        if (employment == nil || !employment.ofKind(RpgExpandedEmployment)
            || employment.owner != self.profile || !holds(employment.wealthObligations,self))
            rpgExpandedReject('employment-wealth-owner');
        local review = new RpgExpandedEmploymentWealthReview(); review.employment = employment;
        review.wealth = self.wealth; review.obligationsSettled = self.obligationsSettled;
        review.evidence = self.evidence; return review;
    }
;

modify RpgExpandedJob
    /* Explicit category: pay alone does not determine the job's wealth level. */
    wealthLevel = nil
    wealthExtraLevels = 0
;

modify RpgExpandedEmployment
    wealthObligations = []
;

/** Next mandatory purchased level for higher-wealth employment, B517.
 * Authors review after settling income and relevant obligations. A recorded
 * obligation persists even when points are insufficient or savings later fall. */
class RpgExpandedEmploymentWealthReview: object
    employment = nil
    wealth = nil
    obligationsSettled = nil
    evidence = nil
    assess() { return self.assessMoney(nil); }
    /** Project a wage outcome without changing the character money ledger. */
    assessMoney(balance) { return self.assessWealth(balance,nil,nil); }
    /* Internal projection for the next obligation after a proposed purchase. */
    assessWealth(balance, prospectiveWealth, exempt)
    {
        if (self.employment == nil || !self.employment.ofKind(RpgExpandedEmployment))
            rpgExpandedReject('employment-wealth-owner');
        self.employment.validate(); local profile = self.employment.owner;
        if (self.wealth == nil || !self.wealth.ofKind(RpgExpandedWealth)
            || self.wealth.owner != profile || !holds(profile.contributions,self.wealth))
            rpgExpandedReject('employment-wealth-owner');
        rpgExpandedValidate(profile);
        local value = new RpgExpandedEmploymentWealthResult();
        foreach (local obligation in self.employment.wealthObligations)
        {
            if (obligation.profile != profile || obligation.wealth != self.wealth)
                rpgExpandedReject('employment-wealth-retargeted');
            if (!obligation.purchased && obligation != exempt)
            { value.status = 'pending'; value.obligation = obligation; return value; }
        }
        if (!self.employment.active) { value.reason = 'employment-inactive'; return value; }
        if (self.employment.job.wealthLevel == nil)
        { value.reason = 'employment-wealth-unspecified'; return value; }
        local jobWealth = new RpgExpandedWealth(); jobWealth.wealthLevel = self.employment.job.wealthLevel;
        jobWealth.extraLevels = self.employment.job.wealthExtraLevels;
        local current = prospectiveWealth == nil ? self.wealth : prospectiveWealth;
        local jobCost = jobWealth.amounts(profile); local currentCost = current.amounts(profile);
        if (jobCost[1] <= currentCost[1]) { value.status = 'satisfied'; return value; }
        local target = new RpgExpandedWealth(); local rank = current.rank();
        if (rank >= 8)
        { target.wealthLevel = 'multimillionaire'; target.extraLevels = rank == 8 ? 1 : current.extraLevels + 1; }
        else
        {
            local levels = ['none','poor','struggling','average','comfortable','wealthy','very-wealthy','filthy-rich'];
            target.wealthLevel = levels[rank + 1];
        }
        local nextCost = target.amounts(profile); value.points = nextCost[1] - currentCost[1];
        value.targetLevel = target.wealthLevel; value.targetExtraLevels = target.extraLevels;
        value.requiredMoney = target.startingValue(profile.campaignTL);
        if (!profile.creationComplete) { value.reason = 'wealth-advancement-after-creation'; return value; }
        if (!self.obligationsSettled || self.evidence == nil || self.evidence == '')
        { value.reason = 'wealth-advancement-obligations'; return value; }
        if (balance == nil) balance = profile.money;
        rpgInteger(balance,0,2147483647);
        if (balance < value.requiredMoney)
        { value.reason = 'wealth-advancement-money'; return value; }
        local existing = profile.pendingWealthObligation(exempt);
        if (existing != nil && (existing.wealth != self.wealth || existing.targetLevel != value.targetLevel
            || existing.targetExtraLevels != value.targetExtraLevels))
            rpgExpandedReject('employment-wealth-obligation-conflict');
        value.status = 'required'; return value;
    }
    record()
    {
        local value = self.assess(); if (value.status != 'required') return value;
        local existing = self.employment.owner.pendingWealthObligation(nil);
        if (existing != nil)
        {
            if (existing.wealth != self.wealth || existing.targetLevel != value.targetLevel
                || existing.targetExtraLevels != value.targetExtraLevels)
                rpgExpandedReject('employment-wealth-obligation-conflict');
            self.employment.wealthObligations = self.employment.wealthObligations + [existing];
            if (!holds(existing.employmentSources,self.employment))
                existing.employmentSources = existing.employmentSources + [self.employment];
            value.obligation = existing; value.status = 'pending'; return value;
        }
        local obligation = new RpgExpandedWealthAdvancement();
        /* Object identity supplies an unambiguous opportunity key across saves. */
        obligation.id = obligation; obligation.profile = self.employment.owner; obligation.wealth = self.wealth;
        obligation.targetLevel = value.targetLevel; obligation.targetExtraLevels = value.targetExtraLevels;
        obligation.permitted = true; obligation.obligationsSettled = true; obligation.evidence = self.evidence;
        obligation.employmentSources = [self.employment];
        self.employment.wealthObligations = self.employment.wealthObligations + [obligation];
        value.obligation = obligation; value.status = 'recorded'; return value;
    }
;

/** Authored employment review outcome; no points are granted to fund a duty. */
class RpgExpandedEmploymentWealthResult: RpgExpandedWealthAdvancementResult
    targetLevel = nil
    targetExtraLevels = 0
    obligation = nil
;

modify RpgExpandedProfile
    /** Shared pending obligations have priority; exempt only the receipt being paid. */
    pendingWealthObligation(exempt)
    {
        foreach (local employment in self.employments)
        {
            if (employment == nil || !employment.ofKind(RpgExpandedEmployment) || employment.owner != self)
                rpgExpandedReject('employment-wealth-owner');
            foreach (local obligation in employment.wealthObligations)
            {
                if (obligation == nil || !obligation.ofKind(RpgExpandedWealthAdvancement)
                    || obligation.profile != self) rpgExpandedReject('employment-wealth-owner');
                if (!obligation.purchased && obligation != exempt) return obligation;
            }
        }
        return nil;
    }
    developmentSpendingReason()
    {
        local reason = inherited(); if (reason != nil) return reason;
        return self.pendingWealthObligation(nil) == nil ? nil : 'employment-wealth-priority';
    }
;

/** Physical lifestyle packages, full-2008 B265-B266. One item is one listed
 * package; services and monthly household coverage are not inventory objects. */
class RpgExpandedLifestyleItem: RpgLiteItem
    lifestyle = nil
    exactWeight = nil
    approved = nil
    evidence = nil
    packagePrice()
    {
        if (self.lifestyle == nil || !self.lifestyle.ofKind(RpgExpandedLifestyle)
            || !holds(['rations-week','wardrobe','ordinary-outfit','winter-outfit',
                'formal-outfit','cosmetics-month'],self.lifestyle.kind))
            rpgExpandedReject('lifestyle-item-kind');
        return self.lifestyle.assess();
    }
    cost = (self.packagePrice().money)
    weight = (self.packageWeight())
    packageWeight()
    {
        local value = self.packagePrice();
        if (value.minimumWeight)
        {
            if (self.exactWeight == nil) rpgExpandedReject('lifestyle-item-exact-weight');
            rpgInteger(self.exactWeight,value.weight,2147483647); return self.exactWeight;
        }
        if (self.exactWeight != nil && self.exactWeight != value.weight)
            rpgExpandedReject('lifestyle-item-weight-mismatch');
        return value.weight;
    }
    validateAcquisition()
    {
        if (self.id == nil || self.id == '' || !self.approved || self.evidence == nil || self.evidence == '')
            rpgExpandedReject('lifestyle-item-definition');
        rpgInteger(self.quantity,1,1); self.packagePrice(); self.packageWeight(); return nil;
    }
;

modify RpgExpandedProfile
    initialWardrobe = nil
;
/** B266 included starting clothes. The author supplies the applicable full
 * cultural standing; payment support from rank does not reduce wardrobe value. */
class RpgExpandedInitialWardrobe: RpgExpandedAcquisition
    mode = 'issue'
    applicableStatus = nil
    culture = nil
    approved = nil
    evidence = nil
    boundDefinition = nil
    definition()
    {
        if (self.item == nil || !self.item.ofKind(RpgExpandedLifestyleItem))
            rpgExpandedReject('initial-wardrobe-item');
        local price = self.item.packagePrice();
        return [self.profile,self.item,self.mode,self.quote,self.startingPurchase,self.marketOffer,self.coinTender,
            self.applicableStatus,self.culture,self.approved,self.evidence,self.item.lifestyle,
            self.item.lifestyle.status,self.item.lifestyle.kind,self.item.exactWeight,
            self.item.approved,self.item.evidence,price.money];
    }
    assess()
    {
        local facts = self.definition();
        if (self.claimed)
        {
            if (self.boundDefinition == nil || facts.length() != self.boundDefinition.length())
                rpgExpandedReject('initial-wardrobe-binding');
            for (local i = 1; i <= facts.length(); i += 1)
                if (facts[i] != self.boundDefinition[i]) rpgExpandedReject('initial-wardrobe-binding');
            if (self.profile.initialWardrobe != self) rpgExpandedReject('initial-wardrobe-history');
            return inherited();
        }
        if (self.profile == nil || !self.profile.ofKind(RpgExpandedProfile))
            rpgExpandedReject('initial-wardrobe-profile');
        if (self.mode != 'issue' || self.quote != nil || self.startingPurchase
            || self.marketOffer != nil || self.coinTender != nil)
            rpgExpandedReject('initial-wardrobe-price-source');
        rpgInteger(self.applicableStatus,-2,8);
        if (self.item.lifestyle.kind != 'wardrobe' || self.item.lifestyle.status != self.applicableStatus)
            rpgExpandedReject('initial-wardrobe-status');
        local value = new RpgExpandedAcquisitionResult();
        if (self.profile.initialWardrobe != nil) { value.reason = 'initial-wardrobe-already-issued'; return value; }
        if (self.profile.creationComplete) { value.reason = 'initial-wardrobe-creation-only'; return value; }
        if (!self.approved || self.culture == nil || self.evidence == nil || self.evidence == '')
        { value.reason = 'initial-wardrobe-standing-required'; return value; }
        return inherited();
    }
    acquire()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local facts = self.definition(); value = inherited();
        if (value.status == 'resolved')
        { self.boundDefinition = facts; self.profile.initialWardrobe = self; }
        return value;
    }
;
