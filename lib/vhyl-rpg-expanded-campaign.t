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
