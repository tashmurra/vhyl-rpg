/* Include after expanded foundation. Source: full-2008 B28-B29. */

/** Purchased social standing in one authored culture. Benefits require that the
 * culture and the standing are recognized in the current encounter. */
class RpgExpandedStatus: RpgExpandedContribution
    culture = nil
    level = 0
    minimum = -2
    maximum = 8
    amounts(profile) { rpgInteger(self.level, -100, 100); return [self.level * 5]; }
    validate(profile)
    {
        if (self.culture == nil) rpgExpandedReject('status-culture');
        rpgInteger(self.minimum, -100, 100); rpgInteger(self.maximum, self.minimum, 100);
        rpgInteger(self.level, self.minimum, self.maximum);
        foreach (local entry in profile.contributions)
            if (entry != self && entry.ofKind(RpgExpandedStatus) && entry.culture == self.culture)
                rpgExpandedReject('duplicate-cultural-status');
        foreach (local trait in profile.traits)
            if (trait.ofKind(RpgLiteTrait) && holds(['status','low-status'],trait.id))
                rpgExpandedReject('mixed-status-profiles');
        return nil;
    }
;

/** Pure B29 relative-standing guideline. Resentment is an authored exception:
 * do not turn it into an invented automatic negative bonus. */
rpgExpandedStatusReaction(subjectStatus, observerStatus, recognized, friendly, resents)
{
    rpgInteger(subjectStatus, -100, 100); rpgInteger(observerStatus, -100, 100);
    if (!recognized || subjectStatus == observerStatus) return 0;
    local difference = subjectStatus - observerStatus;
    if (difference > 0) return resents ? 0 : difference;
    if (subjectStatus < 0) return difference < -4 ? -4 : difference;
    if (subjectStatus > 0 && friendly) return 0;
    return difference;
}

/** An encounter's explicit social-standing facts. assess() rolls nothing and
 * reports only this modifier, not a complete reaction or permission decision. */
class RpgExpandedStatusEncounter: object
    subject = nil
    observer = nil
    culture = nil
    recognized = nil
    friendly = nil
    resents = nil
    structure = nil
    statusFor(profile)
    {
        if (profile == nil || !profile.ofKind(RpgExpandedProfile))
            rpgExpandedReject('status-profile');
        if (self.structure != nil)
        {
            if (!self.structure.ofKind(RpgExpandedSocialStructure) || self.structure.culture != self.culture)
                rpgExpandedReject('status-structure-culture');
            return self.structure.standing(profile);
        }
        rpgExpandedValidate(profile);
        foreach (local entry in profile.contributions)
            if (entry.ofKind(RpgExpandedRank) && entry.culture == self.culture)
                rpgExpandedReject('status-structure-required');
        foreach (local entry in profile.contributions)
            if (entry.ofKind(RpgExpandedStatus) && entry.culture == self.culture) return entry.level;
        return 0;
    }
    assess()
    {
        if (self.culture == nil) rpgExpandedReject('status-culture');
        local value = new RpgExpandedResult();
        value.modifier = rpgExpandedStatusReaction(self.statusFor(self.subject),self.statusFor(self.observer),
            self.recognized,self.friendly,self.resents);
        value.status = 'ready'; return value;
    }
;


/** Organizational membership and purchased authority, full-2008 B29-B30.
 * Institutional admission, duties and privileges are separately authored facts. */
class RpgExpandedRank: RpgExpandedContribution
    culture = nil
    institution = nil
    level = 0
    maximum = 8
    replacesStatus = nil
    admitted = nil
    validate(profile)
    {
        if (self.culture == nil || self.institution == nil) rpgExpandedReject('rank-institution');
        rpgInteger(self.maximum, 0, 100); rpgInteger(self.level, 0, self.maximum);
        if (!self.admitted) rpgExpandedReject('rank-admission-required');
        foreach (local entry in profile.contributions)
            if (entry != self && entry.ofKind(RpgExpandedRank) && entry.institution == self.institution)
                rpgExpandedReject('duplicate-institution-rank');
        return nil;
    }
    amounts(profile)
    {
        rpgInteger(self.level, 0, 100);
        return [self.level * (self.replacesStatus ? 10 : 5)];
    }
    statusBonus()
    {
        rpgInteger(self.level, 0, 100);
        if (self.replacesStatus) return self.level;
        return self.level < 2 ? 0 : self.level < 5 ? 1 : self.level < 8 ? 2 : 3;
    }
;

/** Explicit social structure. Wealth-linked standing is opt-in; replacement
 * rank excludes ordinary status and all free standing bonuses. */
class RpgExpandedSocialStructure: object
    culture = nil
    wealthLinked = nil
    replacingInstitution = nil
    purchasedMaximum = 8
    standing(profile)
    {
        if (self.culture == nil || profile == nil || !profile.ofKind(RpgExpandedProfile))
            rpgExpandedReject('social-structure');
        rpgInteger(self.purchasedMaximum, 0, 100); rpgExpandedValidate(profile);
        local total = 0;
        foreach (local entry in profile.contributions)
        {
            if (entry.ofKind(RpgExpandedStatus) && entry.culture == self.culture)
            {
                if (self.replacingInstitution != nil) rpgExpandedReject('rank-replaces-purchased-status');
                if (entry.level > self.purchasedMaximum) rpgExpandedReject('social-purchased-status-limit');
                total += entry.level;
            }
            if (entry.ofKind(RpgExpandedRank) && entry.culture == self.culture)
            {
                if (entry.replacesStatus ? entry.institution != self.replacingInstitution
                    : entry.institution == self.replacingInstitution)
                    rpgExpandedReject('rank-status-policy-mismatch');
                if (self.replacingInstitution == nil || entry.institution == self.replacingInstitution)
                    total += entry.statusBonus();
            }
            if (self.wealthLinked && self.replacingInstitution == nil) total += entry.wealthStatusBonus();
        }
        rpgInteger(total, -100, 100); return total;
    }
;
