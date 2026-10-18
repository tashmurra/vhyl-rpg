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
