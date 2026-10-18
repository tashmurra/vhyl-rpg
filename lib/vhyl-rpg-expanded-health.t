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
