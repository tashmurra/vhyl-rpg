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
    assess(profile)
    {
        if (self.id == nil || profile == nil || !profile.ofKind(RpgExpandedProfile))
            rpgExpandedReject('job-profile');
        rpgExpandedValidate(profile);
        if (!holds(['fixed','attribute','specific','best','worst'],self.rollMode))
            rpgExpandedReject('job-roll-mode');
        rpgInteger(self.rollModifier,-1000,1000);
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
        if (ratings.length() > 0 && holds(['fixed','attribute'],self.rollMode))
            rpgExpandedReject('job-prerequisite-roll-required');
        if (ratings.length() == 0 && holds(['specific','best','worst'],self.rollMode))
            rpgExpandedReject('job-roll-prerequisite-required');
        if (!self.requirementsApproved) { value.reason = 'job-other-requirements'; return value; }
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
        for (local roll = 3; roll <= 18; roll += 1)
        {
            local outcome = rpgExpandedJobEarnings(employment.monthlyPay,employment.variable,qualification.score,roll,employment.raiseTiming);
            if (outcome.status != 'ready') { value.reason = outcome.reason; return value; }
            if (outcome.money > 2147483647 - employment.owner.money) rpgExpandedReject('job-month-money-limit');
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
        employment.owner.money += value.money - loss; employment.monthlyPay = value.nextPay;
        employment.months = employment.months + [[self.month,self.dueAt,value.check,value.money,value.nextPay,loss,employment.active]];
        employment.lastMonth = self.month; employment.lastMonthAt = self.dueAt;
        value.status = 'resolved'; return value;
    }
;
