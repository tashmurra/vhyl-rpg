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

/** Reputation uses its explicit downward rounding exception, B27-B28. */
rpgExpandedReputationFraction(amount, numerator, denominator)
{
    rpgInteger(amount, -1000000, 1000000);
    rpgInteger(numerator, 0, 1000); rpgInteger(denominator, 1, 1000);
    local product = amount * numerator;
    return product < 0 ? -((-product + denominator - 1) / denominator) : product / denominator;
}

/** Facets are [audience-id, modifier, breadth]. Multifaceted audiences must be
 * authored as disjoint. A zero-net reputation remains an owned contribution. */
class RpgExpandedReputation: RpgExpandedContribution
    details = nil
    facets = []
    disjoint = nil
    frequency = 'always'
    recognitions = []
    validateDefinition()
    {
        if (self.details == nil || self.facets.length() == 0) rpgExpandedReject('reputation-description');
        if (!holds(['always','sometimes','occasionally'],self.frequency)) rpgExpandedReject('reputation-frequency');
        if (self.facets.length() > 1 && !self.disjoint) rpgExpandedReject('reputation-overlapping-facets');
        local ids = [];
        foreach (local facet in self.facets)
        {
            if (facet.length() != 3 || facet[1] == nil || holds(ids,facet[1]))
                rpgExpandedReject('reputation-facet');
            ids = ids + [facet[1]]; rpgInteger(facet[2], -4, 4);
            if (!holds(['all','most','large','small','negligible'],facet[3]))
                rpgExpandedReject('reputation-breadth');
        }
        return nil;
    }
    amounts(profile)
    {
        self.validateDefinition(); local total = 0;
        foreach (local facet in self.facets)
        {
            local cost = facet[2] * 5;
            if (facet[3] == 'most') cost = rpgExpandedReputationFraction(cost,2,3);
            if (facet[3] == 'large') cost = rpgExpandedReputationFraction(cost,1,2);
            if (facet[3] == 'small') cost = rpgExpandedReputationFraction(cost,1,3);
            if (facet[3] == 'negligible') cost = 0;
            total += cost;
        }
        if (self.frequency == 'sometimes') total = rpgExpandedReputationFraction(total,1,2);
        if (self.frequency == 'occasionally') total = rpgExpandedReputationFraction(total,1,3);
        return [total];
    }
    validate(profile)
    {
        self.validateDefinition();
        foreach (local trait in profile.traits)
            if (trait.ofKind(RpgLiteTrait) && holds(['reputation','bad-reputation'],trait.id))
                rpgExpandedReject('mixed-reputation-profiles');
        return nil;
    }
;

/** Recognition is retained per reputation/audience, including failure. The
 * author supplies audience membership, geographic scope and identity exposure. */
class RpgExpandedReputationRecognition: object
    reputation = nil
    audience = nil
    facet = nil
    inArea = nil
    identityExposed = nil
    assess()
    {
        if (self.reputation == nil || !self.reputation.ofKind(RpgExpandedReputation)
            || self.reputation.owner == nil || !self.reputation.owner.ofKind(RpgExpandedProfile)
            || !holds(self.reputation.owner.contributions,self.reputation) || self.audience == nil)
            rpgExpandedReject('reputation-recognition-target');
        rpgExpandedValidate(self.reputation.owner);
        local value = new RpgExpandedResult(); local selected = nil;
        foreach (local row in self.reputation.facets) if (row[1] == self.facet) selected = row;
        if (selected == nil) rpgExpandedReject('reputation-audience-facet');
        foreach (local row in self.reputation.recognitions)
            if (row[1] == self.audience)
            {
                if (row[2] != self.facet) rpgExpandedReject('reputation-audience-changed');
                value.status = 'reused'; value.check = row[3]; value.modifier = row[4]; return value;
            }
        if (!self.inArea) { value.reason = 'reputation-outside-area'; return value; }
        if (!self.identityExposed) { value.reason = 'reputation-identity-hidden'; return value; }
        value.modifier = selected[2]; value.status = 'ready'; return value;
    }
    resolve()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        if (self.reputation.frequency != 'always')
        {
            value.check = rpgRandom.roll();
            if (value.check > (self.reputation.frequency == 'sometimes' ? 10 : 7)) value.modifier = 0;
        }
        self.reputation.recognitions = self.reputation.recognitions
            + [[self.audience,self.facet,value.check,value.modifier]];
        value.status = 'resolved'; return value;
    }
;

/** Combine already-resolved reputations for one person/group, capped at +/-4. */
rpgExpandedReputationModifier(recognitions)
{
    local seen = []; local audience = nil; local subject = nil; local total = 0;
    foreach (local recognition in recognitions)
    {
        if (!recognition.ofKind(RpgExpandedReputationRecognition)) rpgExpandedReject('reputation-recognition-list');
        local value = recognition.assess();
        if (value.status != 'reused') rpgExpandedReject('reputation-recognition-unresolved');
        if (holds(seen,recognition.reputation)) rpgExpandedReject('duplicate-reputation-recognition');
        if (seen.length() > 0 && (recognition.audience != audience || recognition.reputation.owner != subject))
            rpgExpandedReject('reputation-recognition-audience');
        seen = seen + [recognition.reputation]; audience = recognition.audience;
        subject = recognition.reputation.owner; total += value.modifier;
    }
    return total > 4 ? 4 : total < -4 ? -4 : total;
}
