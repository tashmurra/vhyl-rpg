/* Include after expanded foundation. Source: full-2008, B419.
 * This incremental module does not yet supply detailed injury or medical care. */

modify RpgExpandedRules
    scaledInjuryShock = nil
;

/** Shock from one wound, before trait exceptions; high capacity scales the divisor. */
rpgExpandedInjuryShock(capacity, injury)
{
    rpgInteger(capacity,1,1000); rpgInteger(injury,0,100000);
    local divisor = capacity < 20 ? 1 : capacity / 10;
    local penalty = injury / divisor;
    return penalty > 4 ? 4 : penalty;
}

modify RpgExpandedProfile
    shockFromInjury(amount)
    {
        if (self.rules == nil || !self.rules.ofKind(RpgExpandedRules))
            rpgExpandedReject('expanded-rules-required');
        if (!self.rules.scaledInjuryShock) return inherited(amount);
        if (self.level('low-pain-threshold') > 0)
            rpgExpandedReject('expanded-low-pain-shock-unavailable');
        return rpgExpandedInjuryShock(self.maxHP,amount);
    }
;

/** Pure location knockdown assessment; injury is already adjusted after protection.
 * This is not a damage multiplier or a wound commit. Source: full-2008 B419-B420. */
class RpgExpandedKnockdownAssessment: RpgExpandedResult
    major = nil
    required = nil
    modifier = 0
    shock = 0
;

/** Standard humanoid locations without crippling. B420 governs the strict
 * greater-than-half threshold; the conflicting appendix equality is not used. */
rpgExpandedAssessKnockdown(capacity, injury, location, maleGroin)
{
    rpgInteger(capacity,1,1000); rpgInteger(injury,0,100000);
    if (!holds(['torso','face','skull','vitals','groin'],location))
        rpgExpandedReject('expanded-knockdown-location-unavailable');
    if (maleGroin && location != 'groin') rpgExpandedReject('expanded-knockdown-groin-context');
    local value = new RpgExpandedKnockdownAssessment();
    value.shock = rpgExpandedInjuryShock(capacity,injury);
    value.major = injury * 2 > capacity;
    value.required = value.major || value.shock > 0 && holds(['face','skull','vitals'],location);
    if (value.major)
    {
        if (location == 'skull') value.modifier = -10;
        else if (holds(['face','vitals'],location) || location == 'groin' && maleGroin)
            value.modifier = -5;
    }
    value.status = 'ready'; return value;
}
