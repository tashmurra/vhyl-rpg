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
            return self.structure.standingFor(profile);
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
    standingFor(profile)
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

/** Reaction bands from full-2008 B560-B561, ordered from 0 (worst) to 7. */
rpgExpandedReactionBand(total)
{
    rpgInteger(total, -10000, 10000);
    return total <= 0 ? 0 : total <= 3 ? 1 : total <= 6 ? 2 : total <= 9 ? 3
        : total <= 12 ? 4 : total <= 15 ? 5 : total <= 18 ? 6 : 7;
}

modify RpgExpandedProfile
    reactionEncounters = []
;

/** Persistent private encounter record; consequences are resolved separately.
 * The author registers it in subject.reactionEncounters with a unique id. */
class RpgExpandedReactionEncounter: object
    id = nil
    subject = nil
    audience = nil
    worstBand = 0
    bestBand = 7
    predeterminedBand = nil
    fighting = nil
    history = []
    skillPreparation = nil
    preparationHistory = []
    nuisanceCount = 0
    validate()
    {
        if (self.id == nil || self.subject == nil || !self.subject.ofKind(RpgExpandedProfile)
            || self.audience == nil || !holds(self.subject.reactionEncounters,self))
            rpgExpandedReject('reaction-encounter-owner');
        foreach (local entry in self.subject.reactionEncounters)
            if (entry != self && entry.id == self.id) rpgExpandedReject('duplicate-reaction-encounter');
        rpgInteger(self.worstBand, 0, 7); rpgInteger(self.bestBand, self.worstBand, 7);
        if (self.predeterminedBand != nil) rpgInteger(self.predeterminedBand,self.worstBand,self.bestBand);
        rpgInteger(self.nuisanceCount,0,1000); return nil;
    }
;

/** Private reaction outcome: band, adjusted total and roll are trusted-author data. */
class RpgExpandedReactionResult: RpgExpandedResult
    band = nil
    total = nil
;

/** A distinct authored approach. assess() never exposes saved attitudes or dice.
 * resolve() is an author-only operation: do not emit its private result directly. */
class RpgExpandedReactionAttempt: object
    socialContext = nil
    mastery = nil
    encounter = nil
    approach = nil
    modifier = 0
    approvedChange = nil
    nuisance = nil
    waitedReasonably = nil
    assess()
    {
        if (self.encounter == nil || !self.encounter.ofKind(RpgExpandedReactionEncounter) || self.approach == nil)
            rpgExpandedReject('reaction-attempt');
        self.encounter.validate(); rpgInteger(self.modifier,-1000,1000);
        local value = new RpgExpandedReactionResult();
        foreach (local row in self.encounter.history)
            if (row[1] == self.approach) { value.status = 'reused'; return value; }
        if (self.encounter.history.length() > 0)
        {
            if (self.encounter.fighting) { value.reason = 'reaction-fight-started'; return value; }
            if (self.encounter.predeterminedBand != nil)
            { value.reason = 'reaction-predetermined'; return value; }
            if (!self.approvedChange) { value.reason = 'reaction-approach-unchanged'; return value; }
        }
        if (self.encounter.nuisanceCount >= 1000) rpgExpandedReject('reaction-retry-limit');
        if (self.socialContext != nil && self.encounter.predeterminedBand == nil)
        {
            if (!self.socialContext.ofKind(RpgLiteSocialContext)) rpgExpandedReject('reaction-social-context');
            self.socialContext.validateParticipants(self.encounter.subject,self.encounter.audience);
            rpgLiteReactionModifier(self.encounter.subject,self.socialContext);
        }
        if (self.encounter.skillPreparation != nil && self.encounter.predeterminedBand == nil)
        {
            local preparation = self.encounter.skillPreparation;
            if (!preparation.ofKind(RpgExpandedReactionPreparation) || preparation.encounter != self.encounter)
                rpgExpandedReject('reaction-preparation-owner');
            if (preparation.assess().status != 'reused' || preparation.result.check == nil)
            { value.reason = 'reaction-preparation-unresolved'; return value; }
        }
        if (self.mastery != nil && self.encounter.predeterminedBand == nil)
        {
            if (!self.mastery.ofKind(RpgExpandedReactionMastery) || self.mastery.encounter != self.encounter)
                rpgExpandedReject('reaction-mastery-encounter');
            local mastery = self.mastery.assess();
            if (mastery.status != 'ready') { value.reason = mastery.reason; return value; }
        }
        value.status = 'ready'; return value;
    }
    resolve()
    {
        local value = self.assess();
        if (value.status == 'reused')
        {
            foreach (local row in self.encounter.history)
                if (row[1] == self.approach)
                { value.check = row[2]; value.total = row[3]; value.band = row[4]; }
            return value;
        }
        if (value.status != 'ready') return value;
        local mastery = self.mastery == nil || self.encounter.predeterminedBand != nil ? nil : self.mastery.assess();
        local contextual = self.socialContext == nil || self.encounter.predeterminedBand != nil ? 0
            : rpgLiteReactionModifier(self.encounter.subject,self.socialContext);
        local count = self.waitedReasonably ? 0 : self.encounter.nuisanceCount;
        if (self.encounter.history.length() > 0 && self.nuisance && !self.waitedReasonably) count += 1;
        if (self.encounter.predeterminedBand != nil) value.band = self.encounter.predeterminedBand;
        else
        {
            value.check = rpgRandom.roll(); value.total = value.check + self.modifier + contextual + (mastery == nil ? 0 : mastery.modifier)
                + (self.encounter.skillPreparation == nil ? 0 : self.encounter.skillPreparation.result.modifier) - count * 2;
            value.band = rpgExpandedReactionBand(value.total);
            if (value.band < self.encounter.worstBand) value.band = self.encounter.worstBand;
            if (value.band > self.encounter.bestBand) value.band = self.encounter.bestBand;
        }
        if (mastery != nil)
            self.encounter.masteryHistory = self.encounter.masteryHistory
                + [[self.approach,self.mastery.skill,mastery.score,mastery.modifier,self.mastery.evidence]];
        self.encounter.nuisanceCount = count;
        self.encounter.history = self.encounter.history + [[self.approach,value.check,value.total,value.band]];
        value.status = 'resolved'; return value;
    }
;

/** Authored combat intent and follow-up conditions; no combat is executed by this result. */
class RpgExpandedCombatReactionResult: RpgExpandedResult
    intent = nil
    aidModifier = 0
    noQuarter = nil
    leaveDemand = nil
;

/** Context-specific potential combat/morale interpretation, B560-B561.
 * Intent describes the next decision; movement and attacks still use combat. */
class RpgExpandedCombatReaction: object
    band = nil
    inCombat = nil
    outnumbered = nil
    hopeless = nil
    escapePossible = nil
    visitorsRemain = nil
    assess()
    {
        rpgInteger(self.band,0,7);
        local value = new RpgExpandedCombatReactionResult(); value.status = 'ready';
        if (self.band == 0) { value.intent = 'attack'; value.noQuarter = true; }
        if (self.band == 1) value.intent = self.hopeless ? 'flee' : 'attack';
        if (self.band == 2) value.intent = self.inCombat ? 'continue-fighting' : self.outnumbered ? 'flee' : 'attack';
        if (self.band == 3)
        {
            if (self.inCombat) value.intent = 'continue-fighting';
            else
            {
                value.leaveDemand = true;
                value.intent = !self.visitorsRemain ? 'demand-departure' : self.outnumbered ? 'flee' : 'attack';
            }
        }
        if (self.band == 4) value.intent = self.inCombat ? 'disengage' : 'pass-peacefully';
        if (self.band == 5)
        { value.intent = self.inCombat ? 'flee' : 'allow-request'; if (!self.inCombat) value.aidModifier = 1; }
        if (self.band == 6)
        {
            value.intent = self.inCombat ? self.escapePossible ? 'flee' : 'surrender' : 'allow-request';
            if (!self.inCombat) value.aidModifier = 3;
        }
        if (self.band == 7)
        { value.intent = self.inCombat ? 'surrender' : 'allow-request'; if (!self.inCombat) value.aidModifier = 5; }
        return value;
    }
;

/** Combat-specific modifiers are explicit perceived facts, not actual stat
 * comparisons. The strength assessment ranges from -5 through +5, B561. */
rpgExpandedCombatReactionModifier(perceivedStrength, commonLanguage, intruders)
{
    rpgInteger(perceivedStrength,-5,5);
    return perceivedStrength - (commonLanguage ? 0 : 2) - (intruders ? 2 : 0);
}

/** Aid decision and any required follow-up, advice or retry conditions. */
class RpgExpandedAidResult: RpgExpandedResult
    granted = nil
    extent = 'none'
    advice = nil
    volunteerInformation = nil
    combatFollowup = nil
    followupModifier = 0
    followupBestBand = 7
    retry = nil
    retryModifier = 0
;

/** Aid decisions, full-2008 B560-B562. A grant expresses willingness; it does
 * not create resources or let the provider perform an impossible task. */
class RpgExpandedAidReaction: object
    band = nil
    simple = nil
    reasonableness = 'reasonable'
    assess()
    {
        rpgInteger(self.band,0,7);
        if (!holds(['reasonable','silly','totally-unreasonable'],self.reasonableness))
            rpgExpandedReject('aid-reasonableness');
        local value = new RpgExpandedAidResult(); value.status = 'ready';
        if (self.band == 0) { value.combatFollowup = true; value.followupModifier = -4; }
        if (self.band == 1) { value.combatFollowup = true; value.followupBestBand = 4; }
        if (self.band == 3) { value.retry = true; value.retryModifier = -2; }
        if (self.band == 4)
        {
            value.granted = self.simple;
            if (!self.simple) { value.retry = true; value.retryModifier = -2; }
        }
        if (self.band == 5)
        { value.granted = self.reasonableness == 'reasonable'; value.advice = !value.granted; }
        if (self.band == 6)
        { value.granted = self.reasonableness != 'totally-unreasonable'; value.volunteerInformation = true; }
        if (self.band == 7) { value.granted = true; value.extent = 'extra-within-capability'; }
        else if (value.granted) value.extent = 'requested';
        return value;
    }
;

/** B562 aid modifiers. Variable risk penalties are explicit authored judgments.
 * A nil risk means absent; a supplied job/status risk must be at least -2. */
class RpgExpandedAidModifiers: object
    verySimple = nil
    complexity = 0
    inconvenience = nil
    standingRisk = nil
    physicalRisk = nil
    assess()
    {
        rpgInteger(self.complexity,-100,0);
        if (self.standingRisk != nil) rpgInteger(self.standingRisk,-100,-2);
        if (self.physicalRisk != nil) rpgInteger(self.physicalRisk,-100,-1);
        local value = new RpgExpandedResult(); value.status = 'ready';
        value.modifier = (self.verySimple ? 1 : 0) + self.complexity - (self.inconvenience ? 1 : 0)
            + (self.standingRisk == nil ? 0 : self.standingRisk)
            + (self.physicalRisk == nil ? 0 : self.physicalRisk);
        return value;
    }
;

/** Information response decision, including research and follow-up requirements. */
class RpgExpandedInformationResult: RpgExpandedResult
    answer = 'none'
    related = nil
    research = nil
    combatFollowup = nil
    followupModifier = 0
    retry = nil
    aidFollowup = nil
    aidModifier = 0
    aidWorstBand = 0
;

/** Information-request decision, B560-B562. Truth means the respondent's
 * belief, not privileged access to world truth. Answer content is separate. */
class RpgExpandedInformationReaction: object
    band = nil
    complexity = 0
    mode = 'enquiry'
    adverseChoice = nil
    paymentReceived = nil
    bribeOffered = nil
    knowledgeIncomplete = nil
    offersHelp = nil
    assess() { return self.assessPayment(self.paymentReceived); }
    assessPayment(paid)
    {
        rpgInteger(self.band,0,7); rpgInteger(self.complexity,0,2);
        local value = new RpgExpandedInformationResult();
        if (self.mode == 'professional') { value.reason = 'information-use-trade'; return value; }
        if (self.mode == 'interrogation') { value.reason = 'information-use-interrogation'; return value; }
        if (self.mode != 'enquiry') rpgExpandedReject('information-mode');
        if (self.band == 0) { value.combatFollowup = true; value.followupModifier = -2; }
        if (self.band == 1) value.answer = 'malicious-lie';
        if (self.band == 2)
        {
            if (!holds(['lie','payment'],self.adverseChoice))
            { value.reason = 'information-adverse-choice-required'; return value; }
            value.answer = self.adverseChoice == 'lie' ? 'malicious-lie'
                : paid ? 'incomplete-belief' : 'demand-payment';
        }
        if (self.band == 3)
        {
            if (!holds(['unknown','partial'],self.adverseChoice))
            { value.reason = 'information-adverse-choice-required'; return value; }
            value.answer = self.adverseChoice == 'unknown' ? 'claims-ignorance' : 'incomplete-belief';
            value.retry = self.bribeOffered;
        }
        if (self.band == 4) value.answer = self.complexity == 0 ? 'requested-belief' : 'incomplete-belief';
        if (self.band >= 5) value.answer = 'requested-belief';
        if (self.band == 6) value.related = true;
        if (self.band == 7)
        {
            value.research = self.knowledgeIncomplete;
            if (self.offersHelp) { value.aidFollowup = true; value.aidModifier = 2; value.aidWorstBand = 3; }
        }
        value.status = 'ready'; return value;
    }
;

/** Information-specific modifiers, B562 and B44-B45. Bribe magnitude uses an
 * authored income-equivalent interval; no universal calendar is assumed. */
class RpgExpandedInformationModifiers: object
    complexity = 0
    intrusive = nil
    danger = nil
    knowledgeProfessionBonus = 0
    bribeScale = 'none'
    discreet = nil
    appropriate = nil
    assess()
    {
        rpgInteger(self.complexity,0,2);
        if (self.danger != nil) rpgInteger(self.danger,-100,-3);
        if (self.knowledgeProfessionBonus != 0)
            rpgInteger(self.knowledgeProfessionBonus,2,4);
        local scales = ['none','day','week','month','year']; local bonus = nil;
        for (local index = 1; index <= scales.length(); index += 1)
            if (scales[index] == self.bribeScale) bonus = index - 1;
        if (bonus == nil) rpgExpandedReject('information-bribe-scale');
        local value = new RpgExpandedResult();
        if (bonus > 0 && (!self.discreet || !self.appropriate))
        { value.reason = 'information-bribe-inappropriate'; return value; }
        value.modifier = -self.complexity - (self.intrusive ? 3 : 0)
            + (self.danger == nil ? 0 : self.danger) + self.knowledgeProfessionBonus + bonus;
        value.status = 'ready'; return value;
    }
;

modify RpgExpandedProfile
    knowledge = nil
;

/** Owned epistemic state. Statements are authored identifiers/objects, not
 * implicit world facts. Hearing a claim does not automatically mean believing it. */
class RpgExpandedKnowledge: object
    owner = nil
    beliefs = []
    fabrications = []
    received = []
    validate()
    {
        if (self.owner == nil || !self.owner.ofKind(RpgExpandedProfile) || self.owner.knowledge != self)
            rpgExpandedReject('knowledge-owner');
        foreach (local statement in self.beliefs)
            if (statement == nil || holds(self.fabrications,statement)) rpgExpandedReject('knowledge-belief-conflict');
        foreach (local statement in self.fabrications)
            if (statement == nil) rpgExpandedReject('knowledge-fabrication');
        return nil;
    }
;

/** Committed statement selection and payment amount; previews do not disclose statements. */
class RpgExpandedInformationDeliveryResult: RpgExpandedResult
    statements = []
    money = 0
;

/** Deliver an authored response once. Lists select existing belief/fabrication
 * records, so a favorable reaction cannot manufacture an answer. */
class RpgExpandedInformationDelivery: object
    id = nil
    provider = nil
    recipient = nil
    reaction = nil
    requested = []
    partial = []
    related = []
    lies = []
    available = nil
    price = 0
    paymentApproved = nil
    claimed = nil
    boundProvider = nil
    boundRecipient = nil
    boundId = nil
    validateSubset(selected, source)
    {
        local seen = [];
        foreach (local statement in selected)
        {
            if (statement == nil || !holds(source,statement) || holds(seen,statement))
                rpgExpandedReject('information-statement-selection');
            seen = seen + [statement];
        }
        return nil;
    }
    selectedStatements()
    {
        if (self.reaction == nil || !self.reaction.ofKind(RpgExpandedInformationReaction))
            rpgExpandedReject('information-delivery-reaction');
        local response = self.reaction.assessPayment(self.price > 0 && self.paymentApproved ? true : self.reaction.paymentReceived);
        if (response.status != 'ready') return nil;
        self.validateSubset(self.requested,self.provider.knowledge.beliefs);
        self.validateSubset(self.partial,self.requested);
        self.validateSubset(self.related,self.provider.knowledge.beliefs);
        self.validateSubset(self.lies,self.provider.knowledge.fabrications);
        if (response.answer == 'malicious-lie')
        {
            if (self.lies.length() == 0) rpgExpandedReject('information-lie-required');
            return self.lies;
        }
        if (response.answer == 'incomplete-belief')
        {
            if (self.requested.length() > 0 && self.partial.length() >= self.requested.length())
                rpgExpandedReject('information-partial-is-complete');
            return self.partial;
        }
        if (response.answer == 'requested-belief')
        {
            local result = self.requested;
            if (response.related)
                foreach (local statement in self.related)
                    if (!holds(result,statement)) result = result + [statement];
            return result;
        }
        return nil;
    }
    assess()
    {
        if (self.id == nil || self.provider == nil || !self.provider.ofKind(RpgExpandedProfile)
            || self.recipient == nil || !self.recipient.ofKind(RpgExpandedProfile)
            || self.provider.knowledge == nil || !self.provider.knowledge.ofKind(RpgExpandedKnowledge)
            || self.recipient.knowledge == nil || !self.recipient.knowledge.ofKind(RpgExpandedKnowledge))
            rpgExpandedReject('information-delivery-target');
        if (self.claimed && (self.provider != self.boundProvider || self.recipient != self.boundRecipient || self.id != self.boundId))
            rpgExpandedReject('information-delivery-retargeted');
        self.provider.knowledge.validate(); self.recipient.knowledge.validate();
        local value = new RpgExpandedInformationDeliveryResult();
        foreach (local receipt in self.recipient.knowledge.received)
            if (receipt[1] == self.id)
            {
                if (receipt[2] != self.provider) rpgExpandedReject('information-delivery-id-conflict');
                value.status = 'reused'; return value;
            }
        if (!self.available) { value.reason = 'information-delivery-unavailable'; return value; }
        rpgInteger(self.price,0,2147483647);
        if (self.price > 0)
        {
            if (self.provider == self.recipient) rpgExpandedReject('information-self-payment');
            if (self.reaction == nil || !self.reaction.ofKind(RpgExpandedInformationReaction)
                || self.reaction.band != 2 || self.reaction.adverseChoice != 'payment'
                || self.reaction.paymentReceived)
                rpgExpandedReject('information-payment-contract');
            if (!self.paymentApproved) { value.reason = 'information-payment-unapproved'; return value; }
            rpgInteger(self.recipient.money,0,2147483647); rpgInteger(self.provider.money,0,2147483647);
            if (self.recipient.money < self.price) { value.reason = 'information-payment-funds'; return value; }
            if (self.provider.money > 2147483647 - self.price) rpgExpandedReject('information-payment-limit');
            value.money = self.price;
        }
        local selected = self.selectedStatements();
        if (selected == nil) { value.reason = 'information-no-delivery'; return value; }
        value.status = 'ready'; return value;
    }
    deliver()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        value.statements = self.selectedStatements();
        self.recipient.money -= value.money; self.provider.money += value.money;
        self.recipient.knowledge.received = self.recipient.knowledge.received
            + [[self.id,self.provider,value.statements,value.money]];
        self.claimed = true; self.boundProvider = self.provider; self.boundRecipient = self.recipient; self.boundId = self.id;
        value.status = 'resolved'; return value;
    }
;

modify RpgExpandedKnowledge
    checks = []
;

/** Private knowledge-check result; a failed check does not fabricate a belief. */
class RpgExpandedKnowledgeResult: RpgExpandedResult
    known = nil
;

/** Resolve uncertain prior knowledge once per statement, full-2008 B562.
 * This establishes a belief; it does not perform research or prove world truth. */
class RpgExpandedKnowledgeCheck: object
    knowledge = nil
    statement = nil
    context = nil
    plausible = nil
    assess()
    {
        if (self.knowledge == nil || !self.knowledge.ofKind(RpgExpandedKnowledge) || self.statement == nil)
            rpgExpandedReject('knowledge-check-target');
        self.knowledge.validate();
        local value = new RpgExpandedKnowledgeResult();
        if (holds(self.knowledge.beliefs,self.statement)) { value.status = 'reused'; return value; }
        foreach (local receipt in self.knowledge.checks)
            if (receipt[1] == self.statement) { value.status = 'reused'; return value; }
        if (holds(self.knowledge.fabrications,self.statement)) rpgExpandedReject('knowledge-check-fabrication');
        if (self.context == nil || !self.context.ofKind(RpgLiteContext) || self.context.kind != 'knowledge'
            || self.context.skill == nil && self.context.attribute != rpgIQ)
            rpgExpandedReject('knowledge-check-context');
        rpgExpandedValidate(self.knowledge.owner);
        if (!self.plausible) { value.reason = 'knowledge-check-implausible'; return value; }
        if (self.knowledge.owner.dead || self.knowledge.owner.unconscious)
        { value.reason = 'knowledge-check-unavailable'; return value; }
        local score = rpgLiteScore(self.knowledge.owner,self.context);
        if (score == nil) { value.reason = self.context.unavailableReason(self.knowledge.owner); return value; }
        rpgInteger(score,-1000,1000);
        value.status = 'ready'; return value;
    }
    resolve()
    {
        local value = self.assess();
        if (value.status == 'reused')
        {
            value.known = holds(self.knowledge.beliefs,self.statement);
            foreach (local receipt in self.knowledge.checks)
                if (receipt[1] == self.statement) value.check = receipt[2];
            return value;
        }
        if (value.status != 'ready') return value;
        value.check = rpgLiteCheck(self.knowledge.owner,self.context);
        value.known = value.check.achieved;
        self.knowledge.checks = self.knowledge.checks + [[self.statement,value.check]];
        if (value.known) self.knowledge.beliefs = self.knowledge.beliefs + [self.statement];
        value.status = 'resolved'; return value;
    }
;

/** Exact whole-unit trade arithmetic. Fractional currency needs a separate
 * explicit currency policy; do not silently round a quoted price. */
rpgExpandedTradeFraction(amount, numerator, denominator)
{
    rpgInteger(amount,0,2147483647); rpgInteger(numerator,1,100); rpgInteger(denominator,1,100);
    local quotient = amount / denominator; local remainder = amount % denominator;
    if ((remainder * numerator) % denominator != 0) rpgExpandedReject('trade-fractional-money');
    local tail = remainder * numerator / denominator;
    if (quotient > (2147483647 - tail) / numerator) rpgExpandedReject('trade-price-limit');
    return quotient * numerator + tail;
}

/** Quoted terms and refusal/advice flags; this result does not transfer property. */
class RpgExpandedTradeResult: RpgExpandedResult
    price = 0
    refused = nil
    combatFollowup = nil
    followupModifier = 0
    offersAdvice = nil
;

/** Trade table prices, full-2008 B560-B562. Direction is from the player party's
 * perspective. Altered low-band counteroffers remain blocked by a source conflict. */
class RpgExpandedTradeReaction: object
    band = nil
    direction = 'buy'
    fairPrice = 0
    offeredPrice = nil
    assess()
    {
        rpgInteger(self.band,0,7); rpgInteger(self.fairPrice,1,2147483647);
        if (!holds(['buy','sell'],self.direction)) rpgExpandedReject('trade-direction');
        local offer = self.offeredPrice == nil ? self.fairPrice : self.offeredPrice;
        rpgInteger(offer,0,2147483647);
        local value = new RpgExpandedTradeResult();
        if (self.band == 0)
        {
            value.refused = true; value.combatFollowup = true; value.followupModifier = -2;
            value.status = 'ready'; return value;
        }
        if (self.band <= 5 && offer != self.fairPrice)
        { value.reason = 'trade-counteroffer-source-conflict'; return value; }
        if (self.band == 1)
            value.price = rpgExpandedTradeFraction(self.fairPrice,self.direction == 'buy' ? 3 : 1,self.direction == 'buy' ? 1 : 3);
        if (self.band == 2)
            value.price = rpgExpandedTradeFraction(self.fairPrice,self.direction == 'buy' ? 2 : 1,self.direction == 'buy' ? 1 : 2);
        if (self.band == 3)
            value.price = rpgExpandedTradeFraction(self.fairPrice,self.direction == 'buy' ? 6 : 3,self.direction == 'buy' ? 5 : 4);
        if (self.band == 4 || self.band == 5) value.price = self.fairPrice;
        if (self.band >= 6)
        {
            local limit = self.band == 6
                ? rpgExpandedTradeFraction(self.fairPrice,self.direction == 'buy' ? 4 : 3,self.direction == 'buy' ? 5 : 2)
                : rpgExpandedTradeFraction(self.fairPrice,self.direction == 'buy' ? 1 : 2,self.direction == 'buy' ? 2 : 1);
            value.price = self.direction == 'buy' ? (offer < limit ? limit : offer) : (offer > limit ? limit : offer);
        }
        value.offersAdvice = self.band >= 5; value.status = 'ready'; return value;
    }
;

/** Complete ten-percent steps by which an offer favors either party, B562.
 * Quotient/remainder arithmetic avoids overflowing when multiplying prices. */
rpgExpandedTradeOfferModifier(fairPrice, offeredPrice, direction)
{
    rpgInteger(fairPrice,1,2147483647); rpgInteger(offeredPrice,0,2147483647);
    if (!holds(['buy','sell'],direction)) rpgExpandedReject('trade-direction');
    local difference = offeredPrice - fairPrice; local sign = difference < 0 ? -1 : 1;
    if (difference < 0) difference = -difference;
    local whole = difference / fairPrice; local remainder = difference % fairPrice;
    if (whole > 100) rpgExpandedReject('trade-modifier-limit');
    local steps = whole * 10;
    for (local step = 1; step <= 9; step += 1)
    {
        local threshold = (fairPrice / 10) * step + ((fairPrice % 10) * step + 9) / 10;
        if (remainder >= threshold) steps += 1;
    }
    if (steps > 1000) rpgExpandedReject('trade-modifier-limit');
    return steps * sign * (direction == 'buy' ? 1 : -1);
}

/** Transaction-specific offer and commerce skill bonuses. merchantLevel is the
 * authored applicable skill rating; nil means no qualifying skill bonus. */
class RpgExpandedTradeModifiers: object
    fairPrice = 0
    offeredPrice = 0
    direction = 'buy'
    merchantLevel = nil
    assess()
    {
        local value = new RpgExpandedResult();
        value.modifier = rpgExpandedTradeOfferModifier(self.fairPrice,self.offeredPrice,self.direction);
        if (self.merchantLevel != nil)
        {
            rpgInteger(self.merchantLevel,0,1000);
            value.modifier += self.merchantLevel >= 20 ? 2 : 1;
        }
        value.status = 'ready'; return value;
    }
;

modify RpgExpandedProfile
    loyalties = []
;

/** Private loyalty rating, roll and decision for trusted author interpretation. */
class RpgExpandedLoyaltyResult: RpgExpandedResult
    rating = nil
    loyal = nil
;

/** Private relationship, separate from competence, full-2008 B518-B519/B562. */
class RpgExpandedLoyalty: object
    id = nil
    subject = nil
    employer = nil
    initialModifier = 0
    preset = nil
    initialized = nil
    base = nil
    initialRoll = nil
    incidents = []
    dangerEffects = []
    payBonus = 0
    payUntil = nil
    payChanges = []
    rating()
    {
        self.validate();
        if (!self.initialized) rpgExpandedReject('loyalty-uninitialized');
        local value = self.base + (self.payUntil == nil || rpgLedger.seconds < self.payUntil ? self.payBonus : 0);
        foreach (local effect in self.dangerEffects)
            if (rpgLedger.seconds < effect[2]) value -= 1;
        return value;
    }
    validate()
    {
        if (self.id == nil || self.subject == nil || !self.subject.ofKind(RpgExpandedProfile)
            || self.employer == nil || !holds(self.subject.loyalties,self)) rpgExpandedReject('loyalty-owner');
        foreach (local entry in self.subject.loyalties)
            if (entry != self && (entry.id == self.id || entry.employer == self.employer))
                rpgExpandedReject('duplicate-loyalty');
        rpgInteger(self.payBonus,0,1000);
        if (self.payUntil != nil) rpgInteger(self.payUntil,0,2147483647);
        rpgInteger(self.initialModifier,-1000,1000);
        if (self.preset != nil) rpgInteger(self.preset,-1000,1000);
        if (self.initialized) rpgInteger(self.base,-1000,1018);
        return nil;
    }
    assess()
    {
        self.validate(); local value = new RpgExpandedLoyaltyResult();
        value.status = self.initialized ? 'reused' : 'ready'; return value;
    }
    initialize()
    {
        local value = self.assess();
        if (!self.initialized)
        {
            if (self.preset != nil) self.base = self.preset;
            else { self.initialRoll = rpgRandom.roll(); self.base = self.initialRoll + self.initialModifier; }
            self.initialized = true; value.status = 'resolved';
        }
        value.rating = self.rating(); value.check = self.initialRoll; return value;
    }
;

/** Once-per-incident loyalty check. These are raw 3d comparisons, not success
 * checks with automatic failures at 17/18. A rating of 20+ is automatic. */
class RpgExpandedLoyaltyCheck: object
    loyalty = nil
    incident = nil
    necessary = nil
    modifier = 0
    checkKind = 'ordinary'
    assess()
    {
        if (self.loyalty == nil || !self.loyalty.ofKind(RpgExpandedLoyalty) || self.incident == nil)
            rpgExpandedReject('loyalty-check-target');
        self.loyalty.validate(); rpgInteger(self.modifier,-1000,1000);
        local value = new RpgExpandedLoyaltyResult();
        foreach (local receipt in self.loyalty.incidents)
            if (receipt[1] == self.incident)
            {
                if (receipt[5] != self.checkKind) rpgExpandedReject('loyalty-incident-kind');
                value.status = 'reused'; return value;
            }
        if (!self.loyalty.initialized) { value.reason = 'loyalty-uninitialized'; return value; }
        if (!self.necessary) { value.reason = 'loyalty-check-unnecessary'; return value; }
        value.status = 'ready'; return value;
    }
    resolve()
    {
        local value = self.assess();
        if (value.status == 'reused')
        {
            foreach (local receipt in self.loyalty.incidents)
                if (receipt[1] == self.incident)
                { value.rating = receipt[2]; value.check = receipt[3]; value.loyal = receipt[4]; }
            return value;
        }
        if (value.status != 'ready') return value;
        value.rating = self.loyalty.rating() + self.modifier;
        if (value.rating >= 20) value.loyal = true;
        else { value.check = rpgRandom.roll(); value.loyal = value.check <= value.rating; }
        self.loyalty.incidents = self.loyalty.incidents + [[self.incident,value.rating,value.check,value.loyal,self.checkKind]];
        value.status = 'resolved'; return value;
    }
;


/** Noncombatant combat exposure, full-2008 B519. One failed incident causes
 * a one-week penalty; overlapping exposures require unresolved author policy. */
class RpgExpandedLoyaltyDanger: RpgExpandedLoyaltyCheck
    checkKind = 'noncombatant-danger'
    noncombatant = nil
    assess()
    {
        local value = inherited();
        if (value.status != 'ready') return value;
        if (!self.noncombatant) { value.reason = 'loyalty-danger-noncombatant-required'; value.status = 'blocked'; return value; }
        foreach (local effect in self.loyalty.dangerEffects)
            if (rpgLedger.seconds < effect[2])
            { value.reason = 'loyalty-overlapping-danger-unresolved'; value.status = 'blocked'; return value; }
        rpgInteger(rpgLedger.seconds,0,2146878847);
        return value;
    }
    resolve()
    {
        local value = inherited();
        if (value.status == 'resolved' && !value.loyal)
            self.loyalty.dangerEffects = self.loyalty.dangerEffects + [[self.incident,rpgLedger.seconds + 604800]];
        return value;
    }
;

modify RpgExpandedLoyalty
    changes = []
;

/** Recorded permanent loyalty change with its signed adjustment. */
class RpgExpandedLoyaltyChangeResult: RpgExpandedResult
    change = 0
;

/** Permanent changes from explicit completed-world events, full-2008 B519.
 * IDs identify an adventure or a previously checked incident, not an API call. */
class RpgExpandedLoyaltyChange: object
    loyalty = nil
    id = nil
    kind = 'performance'
    evidence = nil
    continuing = nil
    adventureComplete = nil
    performance = 'ordinary'
    forgiven = nil
    assess()
    {
        if (self.loyalty == nil || !self.loyalty.ofKind(RpgExpandedLoyalty) || self.id == nil)
            rpgExpandedReject('loyalty-change-target');
        self.loyalty.validate();
        if (!holds(['performance','forgiveness'],self.kind)) rpgExpandedReject('loyalty-change-kind');
        local value = new RpgExpandedLoyaltyChangeResult();
        foreach (local receipt in self.loyalty.changes)
            if (receipt[1] == self.kind && receipt[2] == self.id) { value.status = 'reused'; return value; }
        if (!self.loyalty.initialized) { value.reason = 'loyalty-uninitialized'; return value; }
        if (self.evidence == nil) { value.reason = 'loyalty-change-evidence'; return value; }
        if (self.kind == 'performance')
        {
            if (!holds(['ordinary','great-success','botched'],self.performance)) rpgExpandedReject('loyalty-performance');
            if (!self.continuing || !self.adventureComplete)
            { value.reason = 'loyalty-adventure-incomplete'; return value; }
        }
        else
        {
            if (!self.forgiven) { value.reason = 'loyalty-not-forgiven'; return value; }
            local failed = nil;
            foreach (local receipt in self.loyalty.incidents)
                if (receipt[1] == self.id && !receipt[4]) failed = true;
            if (!failed) { value.reason = 'loyalty-no-failed-incident'; return value; }
        }
        /* Reserve room for either one-point outcome before committing anything. */
        rpgInteger(self.loyalty.base,-999,1017);
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        if (self.kind == 'performance')
            value.change = self.performance == 'great-success' ? 1 : self.performance == 'botched' ? -1 : 0;
        else value.change = self.loyalty.rating() >= 16 ? 1 : 0;
        self.loyalty.base += value.change;
        self.loyalty.changes = self.loyalty.changes + [[self.kind,self.id,value.change,self.evidence]];
        value.status = 'resolved'; return value;
    }
;

modify RpgExpandedLoyalty
    serviceYears = []
    lastServiceYear = 0
    lastAnniversaryAt = 0
;

/** Service-anniversary result and any permanent loyalty increase. */
class RpgExpandedServiceResult: RpgExpandedLoyaltyResult
    change = 0
;

/** B519 annual service check. The campaign calendar supplies an absolute due
 * time; this operation never assumes 365 days or charges elapsed time again. */
class RpgExpandedServiceAnniversary: object
    loyalty = nil
    year = 1
    anniversaryAt = nil
    completedService = nil
    assess()
    {
        if (self.loyalty == nil || !self.loyalty.ofKind(RpgExpandedLoyalty))
            rpgExpandedReject('service-loyalty');
        self.loyalty.validate(); rpgInteger(self.year,1,10000);
        local value = new RpgExpandedServiceResult();
        foreach (local receipt in self.loyalty.serviceYears)
            if (receipt[1] == self.year) { value.status = 'reused'; return value; }
        if (!self.loyalty.initialized) { value.reason = 'loyalty-uninitialized'; return value; }
        if (self.year != self.loyalty.lastServiceYear + 1)
        { value.reason = 'service-year-gap'; return value; }
        rpgInteger(self.anniversaryAt,1,2147483647);
        if (self.anniversaryAt <= self.loyalty.lastAnniversaryAt)
            rpgExpandedReject('service-anniversary-order');
        if (!self.completedService) { value.reason = 'service-year-incomplete'; return value; }
        if (rpgLedger.seconds < self.anniversaryAt) { value.reason = 'service-anniversary-not-due'; return value; }
        rpgInteger(self.loyalty.base,-1000,1017);
        value.status = 'ready'; return value;
    }
    resolve()
    {
        local value = self.assess();
        if (value.status == 'reused')
        {
            foreach (local receipt in self.loyalty.serviceYears)
                if (receipt[1] == self.year)
                { value.rating = receipt[3]; value.check = receipt[4]; value.loyal = receipt[5]; }
            return value;
        }
        if (value.status != 'ready') return value;
        value.rating = self.loyalty.rating();
        if (value.rating >= 20) value.loyal = true;
        else { value.check = rpgRandom.roll(); value.loyal = value.check <= value.rating; }
        value.change = value.loyal ? 1 : 0; self.loyalty.base += value.change;
        self.loyalty.serviceYears = self.loyalty.serviceYears
            + [[self.year,self.anniversaryAt,value.rating,value.check,value.loyal]];
        self.loyalty.lastServiceYear = self.year; self.loyalty.lastAnniversaryAt = self.anniversaryAt;
        value.status = 'resolved'; return value;
    }
;

modify RpgExpandedLoyalty
    rescues = []
;

/** Rescue gratitude result and the resulting private loyalty rating. */
class RpgExpandedRescueResult: RpgExpandedLoyaltyResult
    total = nil
    change = 0
;

/** Rescue gratitude, full-2008 B519. World risk and a completed rescue are
 * explicit facts. A reaction below good never reduces existing loyalty. */
class RpgExpandedRescueLoyalty: object
    loyalty = nil
    id = nil
    evidence = nil
    rescued = nil
    riskedLifeOrMission = nil
    rescueBonus = 3
    otherModifier = 0
    sacrificeBonus = 0
    seriousSacrifice = nil
    assess()
    {
        if (self.loyalty == nil || !self.loyalty.ofKind(RpgExpandedLoyalty) || self.id == nil)
            rpgExpandedReject('rescue-loyalty-target');
        self.loyalty.validate(); local value = new RpgExpandedRescueResult();
        foreach (local receipt in self.loyalty.rescues)
            if (receipt[1] == self.id) { value.status = 'reused'; return value; }
        if (!self.loyalty.initialized) { value.reason = 'loyalty-uninitialized'; return value; }
        if (!self.rescued || !self.riskedLifeOrMission || self.evidence == nil)
        { value.reason = 'rescue-loyalty-evidence'; return value; }
        rpgInteger(self.rescueBonus,3,1000); rpgInteger(self.otherModifier,-1000,1000);
        rpgInteger(self.rescueBonus + self.otherModifier,-1000,1000);
        if (self.loyalty.rating() != self.loyalty.base)
        { value.reason = 'rescue-temporary-loyalty-unresolved'; return value; }
        rpgInteger(self.sacrificeBonus,0,1000);
        if (self.sacrificeBonus > 0 && !self.seriousSacrifice) rpgExpandedReject('rescue-sacrifice-evidence');
        local possible = 18 + self.rescueBonus + self.otherModifier;
        if (possible < self.loyalty.base) possible = self.loyalty.base;
        if (possible > 1018 - self.sacrificeBonus) rpgExpandedReject('rescue-loyalty-limit');
        value.status = 'ready'; return value;
    }
    resolve()
    {
        local value = self.assess();
        if (value.status == 'reused')
        {
            foreach (local receipt in self.loyalty.rescues)
                if (receipt[1] == self.id)
                { value.check = receipt[2]; value.total = receipt[3]; value.rating = receipt[4]; }
            return value;
        }
        if (value.status != 'ready') return value;
        value.check = rpgRandom.roll(); value.total = value.check + self.rescueBonus + self.otherModifier;
        value.rating = self.loyalty.base;
        if (value.total >= 13 && value.total > value.rating) value.rating = value.total;
        value.rating += self.sacrificeBonus;
        value.change = value.rating - self.loyalty.base; self.loyalty.base = value.rating;
        self.loyalty.rescues = self.loyalty.rescues + [[self.id,value.check,value.total,value.rating,self.evidence,self.sacrificeBonus]];
        value.status = 'resolved'; return value;
    }
;


/** B519 higher-pay bonus. The job's normal and actual pay cover the same period.
 * Payment/loot transfer happens in its own operation; evidence identifies it. */
class RpgExpandedLoyaltyPayChange: object
    loyalty = nil
    id = nil
    mode = 'start'
    normalPay = 0
    actualPay = 0
    expiresAt = nil
    evidence = nil
    assess()
    {
        if (self.loyalty == nil || !self.loyalty.ofKind(RpgExpandedLoyalty) || self.id == nil)
            rpgExpandedReject('loyalty-pay-target');
        self.loyalty.validate();
        if (!holds(['start','stop'],self.mode)) rpgExpandedReject('loyalty-pay-mode');
        local value = new RpgExpandedResult();
        foreach (local receipt in self.loyalty.payChanges)
            if (receipt[1] == self.id) { value.status = 'reused'; return value; }
        if (self.evidence == nil) { value.reason = 'loyalty-pay-evidence'; return value; }
        if (self.mode == 'start')
        {
            rpgInteger(self.normalPay,1,2147483647); rpgInteger(self.actualPay,0,2147483647);
            if (self.actualPay <= self.normalPay) { value.reason = 'loyalty-no-extra-pay'; return value; }
            value.modifier = rpgExpandedTradeOfferModifier(self.normalPay,self.actualPay,'buy');
            if (value.modifier == 0) { value.reason = 'loyalty-no-full-pay-step'; return value; }
            if (self.loyalty.payBonus > 0 && (self.loyalty.payUntil == nil || rpgLedger.seconds < self.loyalty.payUntil))
            { value.reason = 'loyalty-pay-overlap-unresolved'; return value; }
        }
        else
        {
            if (self.loyalty.payBonus == 0 || self.loyalty.payUntil != nil)
            { value.reason = 'loyalty-extra-pay-not-active'; return value; }
            rpgInteger(self.expiresAt,1,2147483647);
            if (self.expiresAt <= rpgLedger.seconds) { value.reason = 'loyalty-pay-expiry'; return value; }
        }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        if (self.mode == 'start') { self.loyalty.payBonus = value.modifier; self.loyalty.payUntil = nil; }
        else self.loyalty.payUntil = self.expiresAt;
        self.loyalty.payChanges = self.loyalty.payChanges
            + [[self.id,self.mode,self.loyalty.payBonus,self.loyalty.payUntil,self.evidence]];
        value.status = 'resolved'; return value;
    }
;

/** B202 interrogation. Answers are authored facts/claims, never generated knowledge. */
class RpgExpandedInterrogation: object
    id = nil
    interrogator = nil
    prisoner = nil
    skill = nil
    questions = []
    definition() { return [self.id,self.interrogator,self.prisoner,self.skill]; }
    validate()
    {
        if (self.id == nil || self.id == '' || self.interrogator == nil || self.prisoner == nil
            || !self.interrogator.ofKind(RpgExpandedProfile) || !self.prisoner.ofKind(RpgLiteProfile)
            || self.interrogator == self.prisoner || self.skill == nil || !self.skill.ofKind(RpgLiteSkill)
            || self.skill.id != 'interrogation' || self.skill.attribute != rpgIQ || self.skill.difficulty != 1)
            rpgExpandedReject('interrogation-definition');
        rpgInteger(self.questions.length(),0,10000);
        return nil;
    }
    elapsed() { return self.questions.length() * 300; }
;
class RpgExpandedInterrogationResult: RpgExpandedResult
    actorScore = nil
    prisonerScore = nil
    responseKind = nil
    statement = nil
    margin = nil
;
modify RpgExpandedProfile
    interrogations = []
;
class RpgExpandedInterrogationQuestion: object
    id = nil
    session = nil
    question = nil
    truthfulAnswer = nil
    falseAnswer = nil
    failureResponse = 'silence'
    approved = nil
    evidence = nil
    loyaltyResists = nil
    pastVictim = nil
    company = nil
    means = 'ordinary'
    modifier = 0
    startedAt = nil
    completedAt = nil
    boundDefinition = nil
    result = nil
    definition()
    {
        return [self.id,self.session,self.question,self.truthfulAnswer,self.falseAnswer,self.failureResponse,
            self.approved,self.evidence,self.loyaltyResists,self.means,self.modifier,self.pastVictim,self.company] + self.session.definition()
            + (self.company == nil ? [] : self.company.definition());
    }
    validateReceipt()
    {
        local current = self.definition();
        if (current.length() != self.boundDefinition.length()) rpgExpandedReject('interrogation-question-binding');
        for (local index = 1; index <= current.length(); index += 1)
            if (current[index] != self.boundDefinition[index]) rpgExpandedReject('interrogation-question-binding');
        if (!holds(self.session.questions,self) || !holds(self.session.interrogator.interrogations,self.session)
            || self.completedAt != self.startedAt + 300) rpgExpandedReject('interrogation-question-history');
        return nil;
    }
    prepare()
    {
        local value = new RpgExpandedInterrogationResult();
        local actor = self.session.interrogator; local prisoner = self.session.prisoner;
        if (actor.dead || actor.unconscious || actor.mortal || actor.stunned || actor.mentalStun
            || prisoner.dead || prisoner.unconscious || prisoner.mortal || prisoner.stunned || prisoner.mentalStun
            || actor.healthEffortReason('talk',nil,true,nil) != nil || prisoner.healthEffortReason('talk',nil,true,nil) != nil)
        { value.reason = 'interrogation-participant-unavailable'; return value; }
        if (actor.fp() <= 0 || prisoner.fp() <= 0 || actor.hp() <= 0 || prisoner.hp() <= 0)
        { value.reason = 'interrogation-exhaustion-adapter-required'; return value; }
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'interrogation-facts-required'; return value; }
        if (self.question == nil || self.truthfulAnswer == nil || self.falseAnswer == nil)
        { value.reason = 'interrogation-authored-responses-required'; return value; }
        if (!holds(['silence','lie'],self.failureResponse) || !holds(['ordinary','severe-threat','torture'],self.means))
            rpgExpandedReject('interrogation-response-mode');
        rpgInteger(self.modifier,-100,100);
        value.modifier = self.modifier - (self.loyaltyResists ? 5 : 0) - (actor.level('low-empathy') > 0 ? 3 : 0)
            + (self.session.elapsed() + 300 > 7200 ? 2 : 0);
        if (self.pastVictim && actor.callousnessActive()) value.modifier -= 3;
        if (self.means != 'ordinary') value.modifier += (self.means == 'torture' ? 6 : 3) + (actor.level('callous') > 0 || actor.callousnessActive() ? 1 : 0);
        local context = new RpgLiteContext(); context.skill = self.session.skill; context.kind = 'interrogation'; context.company = self.company;
        context.modifier = value.modifier; value.actorScore = rpgLiteScore(actor,context);
        context = new RpgLiteContext(); context.attribute = rpgWill; context.kind = 'resistance';
        value.prisonerScore = rpgLiteScore(prisoner,context);
        if (value.actorScore == nil || value.actorScore < 3 || value.prisonerScore == nil || value.prisonerScore < 3)
        { value.reason = 'interrogation-score-unavailable'; return value; }
        value.seconds = 300; value.status = 'ready'; return value;
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.session == nil || !self.session.ofKind(RpgExpandedInterrogation))
            rpgExpandedReject('interrogation-question-definition');
        self.session.validate();
        if (self.result != nil)
        { self.validateReceipt(); local reused = new RpgExpandedInterrogationResult(); reused.status = 'reused'; return reused; }
        foreach (local prior in self.session.questions)
        {
            prior.validateReceipt();
            if (prior.id == self.id || prior.question == self.question) rpgExpandedReject('interrogation-repeat-question-unimplemented');
        }
        foreach (local other in self.session.interrogator.interrogations)
            if (other != self.session && other.id == self.session.id) rpgExpandedReject('interrogation-session-duplicate');
        if (self.session.questions.length() > 0
            && self.session.questions[self.session.questions.length()].completedAt != rpgLedger.seconds)
        {
            local interrupted = new RpgExpandedInterrogationResult();
            interrupted.reason = 'interrogation-interrupted-session-unimplemented'; return interrupted;
        }
        local value = self.prepare();
        if (value.status == 'ready')
        { rpgInteger(rpgLedger.seconds,0,2147483347); rpgLedger.validateAdvance(300); }
        return value;
    }
    apply()
    {
        local value = self.assess();
        if (value.status == 'reused') return self.result;
        if (value.status != 'ready') return value;
        local definition = self.definition(); local start = rpgLedger.seconds;
        rpgSpendTime(300);
        local current = self.definition();
        if (current.length() != definition.length()) rpgExpandedReject('interrogation-interrupted');
        for (local index = 1; index <= current.length(); index += 1)
            if (current[index] != definition[index]) rpgExpandedReject('interrogation-interrupted');
        local after = self.prepare();
        if (rpgLedger.seconds != start + 300 || after.status != 'ready'
            || after.actorScore != value.actorScore || after.prisonerScore != value.prisonerScore)
            rpgExpandedReject('interrogation-conditions-changed');
        value.check = rpgEvaluate(value.actorScore,rpgRandom.roll(),value.prisonerScore,rpgRandom.roll(),0);
        value.margin = value.check.margin - value.check.oppositionMargin;
        value.responseKind = value.check.achieved ? 'truth' : value.margin < -5 ? 'believable-lie' : self.failureResponse;
        value.statement = value.responseKind == 'truth' ? self.truthfulAnswer
            : value.responseKind == 'silence' ? nil : self.falseAnswer;
        self.startedAt = start; self.completedAt = rpgLedger.seconds; self.boundDefinition = definition;
        self.session.questions = self.session.questions + [self];
        if (!holds(self.session.interrogator.interrogations,self.session))
            self.session.interrogator.interrogations = self.session.interrogator.interrogations + [self.session];
        value.status = 'resolved'; self.result = value; return value;
    }
;

modify RpgExpandedInterrogationQuestion
    delivery = nil
;
/** Record a heard answer without treating it as an established belief or fact. */
class RpgExpandedInterrogationDelivery: object
    id = nil
    question = nil
    recipient = nil
    completedAt = nil
    boundId = nil
    boundQuestion = nil
    boundRecipient = nil
    boundKnowledge = nil
    boundStatement = nil
    boundKind = nil
    assess()
    {
        if (self.id == nil || self.id == '' || self.question == nil
            || !self.question.ofKind(RpgExpandedInterrogationQuestion) || self.recipient == nil
            || !self.recipient.ofKind(RpgExpandedProfile) || self.recipient.knowledge == nil
            || !self.recipient.knowledge.ofKind(RpgExpandedKnowledge))
            rpgExpandedReject('interrogation-delivery-definition');
        self.recipient.knowledge.validate(); local value = new RpgExpandedInformationDeliveryResult();
        if (self.question.result == nil)
        { value.reason = 'interrogation-answer-unresolved'; return value; }
        self.question.validateReceipt();
        if (self.completedAt != nil)
        {
            if (self.id != self.boundId || self.question != self.boundQuestion || self.recipient != self.boundRecipient
                || self.recipient.knowledge != self.boundKnowledge || self.question.delivery != self
                || self.question.result.statement != self.boundStatement || self.question.result.responseKind != self.boundKind)
                rpgExpandedReject('interrogation-delivery-binding');
            local found = 0;
            foreach (local receipt in self.boundKnowledge.received)
                if (receipt[1] == self.id)
                {
                    if (receipt[2] != self.question.session.prisoner || receipt[3].length() != 1
                        || receipt[3][1] != self.boundStatement || receipt[4] != 0)
                        rpgExpandedReject('interrogation-delivery-receipt');
                    found += 1;
                }
            if (found != 1) rpgExpandedReject('interrogation-delivery-history');
            value.status = 'reused'; return value;
        }
        if (self.recipient != self.question.session.interrogator)
        { value.reason = 'interrogation-delivery-witness-adapter-required'; return value; }
        if (self.question.delivery != nil)
        { value.reason = 'interrogation-answer-already-delivered'; return value; }
        if (self.question.result.responseKind == 'silence' || self.question.result.statement == nil)
        { value.reason = 'interrogation-no-answer'; return value; }
        foreach (local receipt in self.recipient.knowledge.received)
            if (receipt[1] == self.id) rpgExpandedReject('interrogation-delivery-duplicate');
        value.status = 'ready'; return value;
    }
    deliver()
    {
        local value = self.assess();
        if (value.status == 'reused') { value.statements = [self.boundStatement]; return value; }
        if (value.status != 'ready') return value;
        self.boundId = self.id; self.boundQuestion = self.question; self.boundRecipient = self.recipient;
        self.boundKnowledge = self.recipient.knowledge; self.boundStatement = self.question.result.statement;
        self.boundKind = self.question.result.responseKind; self.completedAt = rpgLedger.seconds;
        value.statements = [self.boundStatement];
        self.boundKnowledge.received = self.boundKnowledge.received
            + [[self.id,self.question.session.prisoner,value.statements,0]];
        self.question.delivery = self; value.status = 'resolved'; return value;
    }
;

/** Authored hearing of an already resolved communication. Does not confer belief. */
class RpgExpandedStatementDelivery: object
    id = nil
    communication = nil
    recipient = nil
    heard = nil
    evidence = nil
    completedAt = nil
    boundDefinition = nil
    boundKnowledge = nil
    boundStatement = nil
    definition() { return [self.id,self.communication,self.recipient,self.heard,self.evidence]; }
    assess()
    {
        if (self.id == nil || self.id == '' || self.communication == nil
            || !self.communication.ofKind(RpgExpandedStatementReceipt) || self.recipient == nil
            || !self.recipient.ofKind(RpgExpandedProfile) || self.recipient.knowledge == nil
            || !self.recipient.knowledge.ofKind(RpgExpandedKnowledge))
            rpgExpandedReject('statement-delivery-definition');
        self.communication.validate(); self.recipient.knowledge.validate();
        local value = new RpgExpandedInformationDeliveryResult();
        if (self.completedAt != nil)
        {
            local current = self.definition();
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.boundDefinition[index]) rpgExpandedReject('statement-delivery-binding');
            if (self.boundKnowledge != self.recipient.knowledge || self.boundStatement != self.communication.statement
                || !holds(self.communication.deliveries,self)) rpgExpandedReject('statement-delivery-binding');
            local count = 0;
            foreach (local row in self.boundKnowledge.received)
                if (row[1] == self.id)
                {
                    if (row[2] != self.communication.speaker || row[3].length() != 1
                        || row[3][1] != self.boundStatement || row[4] != 0)
                        rpgExpandedReject('statement-delivery-history');
                    count += 1;
                }
            if (count != 1) rpgExpandedReject('statement-delivery-history');
            value.status = 'reused'; return value;
        }
        if (self.communication.statement == nil) { value.reason = 'statement-withheld'; return value; }
        if (self.recipient == self.communication.speaker) { value.reason = 'statement-delivery-self'; return value; }
        if (!self.heard || self.evidence == nil || self.evidence == '')
        { value.reason = 'statement-hearing-evidence'; return value; }
        foreach (local prior in self.communication.deliveries)
            if (prior.recipient == self.recipient) { value.reason = 'statement-already-delivered'; return value; }
        foreach (local row in self.recipient.knowledge.received)
            if (row[1] == self.id) rpgExpandedReject('statement-delivery-duplicate');
        value.status = 'ready'; return value;
    }
    deliver()
    {
        local value = self.assess();
        if (value.status == 'reused') { value.statements = [self.boundStatement]; return value; }
        if (value.status != 'ready') return value;
        self.boundDefinition = self.definition(); self.boundKnowledge = self.recipient.knowledge;
        self.boundStatement = self.communication.statement; self.completedAt = rpgLedger.seconds;
        value.statements = [self.boundStatement];
        self.boundKnowledge.received = self.boundKnowledge.received
            + [[self.id,self.communication.speaker,value.statements,0]];
        self.communication.deliveries = self.communication.deliveries + [self];
        value.status = 'resolved'; return value;
    }
;

/** B129: informed observers in an authored occupational/cultural setting. */
class RpgExpandedDangerReactionContext: RpgLiteSocialContext
    subject = nil
    observer = nil
    approved = nil
    evidence = nil
    avoidanceKnown = nil
    occupationalExpectation = nil
    traitReactionModifier(profile)
    {
        if (self.subject == nil || !self.subject.ofKind(RpgExpandedProfile)
            || self.observer == nil || !self.observer.ofKind(RpgLiteProfile)
            || self.subject == self.observer || profile != self.subject)
            rpgExpandedReject('danger-reaction-participants');
        if (!self.approved || self.evidence == nil || self.evidence == '')
            rpgExpandedReject('danger-reaction-author-facts');
        local penalty = self.subject.physicalDangerFearPenalty();
        if (!self.avoidanceKnown || !self.occupationalExpectation) return 0;
        if (penalty == nil) rpgExpandedReject('danger-reaction-purchased-trait-required');
        return -penalty;
    }
    validateParticipants(profile,target)
    {
        self.traitReactionModifier(profile);
        if (target != self.observer) rpgExpandedReject('danger-reaction-observer');
        return nil;
    }
;

modify RpgExpandedReactionEncounter
    masteryHistory = []
;
class RpgExpandedReactionMasteryResult: RpgExpandedResult
    score = nil
;
/** B187/B195/B560 one selected automatic social-skill reaction bonus. */
class RpgExpandedReactionMastery: object
    encounter = nil
    skill = nil
    canSpeak = nil
    approved = nil
    evidence = nil
    assess()
    {
        if (self.encounter == nil || !self.encounter.ofKind(RpgExpandedReactionEncounter)
            || self.skill == nil || !self.skill.ofKind(RpgLiteSkill)) rpgExpandedReject('reaction-mastery-definition');
        self.encounter.validate(); local value = new RpgExpandedReactionMasteryResult();
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'reaction-mastery-context'; return value; }
        local diplomacy = self.skill.id == 'diplomacy';
        if ((!diplomacy && self.skill.id != 'fast-talk') || self.skill.attribute != rpgIQ
            || self.skill.difficulty != (diplomacy ? 2 : 1) || self.skill.defaultPenalty != (diplomacy ? -6 : -5)
            || self.skill.techLevel != nil) rpgExpandedReject('reaction-mastery-skill');
        value.score = self.encounter.subject.skillScore(self.skill);
        value.modifier = value.score != nil && value.score >= 20 && (diplomacy || self.canSpeak) ? 2 : 0;
        value.status = 'ready'; return value;
    }
;

class RpgExpandedReactionPreparationResult: RpgExpandedResult
    score = nil
    gate = nil
    allowed = nil
;
/** B174/B183/B560 an owned contextual social task before the encounter's reactions. */
class RpgExpandedReactionPreparation: object
    entertainment = nil
    company = nil
    id = nil
    encounter = nil
    skill = nil
    reactionKind = 'general'
    skillModifier = 0
    requiresMovement = nil
    seconds = 0
    approved = nil
    evidence = nil
    result = nil
    boundDefinition = nil
    definition()
    { return [self.id,self.encounter,self.encounter.subject,self.encounter.audience,self.skill,
        self.skill.id,self.skill.attribute,self.skill.difficulty,self.skill.defaultPenalty,self.reactionKind,
        self.skillModifier,self.requiresMovement,self.seconds,self.approved,self.evidence,self.entertainment,self.company]
        + (self.entertainment == nil ? [] : self.entertainment.definition())
        + (self.company == nil ? [] : self.company.definition()); }
    context()
    {
        local context = new RpgLiteContext(); context.skill = self.skill; context.kind = self.skill.id; context.company = self.company;
        context.modifier = self.skillModifier + (self.entertainment == nil ? 0 : self.entertainment.bonus); context.requiresMovement = self.requiresMovement; return context;
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.encounter == nil || !self.encounter.ofKind(RpgExpandedReactionEncounter)
            || self.skill == nil || !self.skill.ofKind(RpgLiteSkill)) rpgExpandedReject('reaction-preparation-definition');
        if (self.entertainment != nil && (!self.entertainment.ofKind(RpgExpandedCarousingEntertainment)
            || self.entertainment.preparation != self)) rpgExpandedReject('reaction-entertainment-owner');
        self.encounter.validate(); local value = new RpgExpandedReactionPreparationResult();
        if (self.result != nil)
        {
            local current = self.definition();
            if (current.length() != self.boundDefinition.length()) rpgExpandedReject('reaction-preparation-binding');
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.boundDefinition[index]) rpgExpandedReject('reaction-preparation-binding');
            if (!holds(self.encounter.preparationHistory,self) || self.result.check != nil && self.encounter.skillPreparation != self
                || self.result.gate.assess().status != 'reused')
                rpgExpandedReject('reaction-preparation-history');
            if (self.entertainment != nil && self.result.check != nil && self.entertainment.assess().status != 'reused')
                rpgExpandedReject('reaction-entertainment-history');
            value.status = 'reused'; return value;
        }
        if (self.encounter.skillPreparation != nil) rpgExpandedReject('reaction-preparation-duplicate');
        foreach (local prior in self.encounter.preparationHistory)
            if (prior.id == self.id) rpgExpandedReject('reaction-preparation-duplicate');
        if (self.encounter.history.length() > 0 || self.encounter.predeterminedBand != nil)
        { value.reason = 'reaction-preparation-too-late'; return value; }
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'reaction-preparation-context'; return value; }
        local administrative = self.skill.id == 'administration';
        if ((!administrative && self.skill.id != 'carousing') || self.skill.attribute != (administrative ? rpgIQ : rpgHT)
            || self.skill.difficulty != (administrative ? 1 : 0) || self.skill.defaultPenalty != (administrative ? -5 : -4))
            rpgExpandedReject('reaction-preparation-skill');
        if (administrative ? self.reactionKind != 'bureaucracy' : !holds(['general','aid','information'],self.reactionKind))
        { value.reason = 'reaction-preparation-kind'; return value; }
        if (self.entertainment != nil)
        {
            if (administrative) rpgExpandedReject('reaction-entertainment-skill');
            local entertainment = self.entertainment.assess();
            if (!holds(['ready','reused'],entertainment.status)) { value.reason = entertainment.reason; return value; }
        }
        rpgInteger(self.skillModifier,-1000,1000); rpgInteger(self.seconds,0,86400);
        value.score = rpgLiteScore(self.encounter.subject,self.context());
        if (value.score == nil || value.score < 3) { value.reason = 'reaction-preparation-score'; return value; }
        value.gate = self.encounter.subject.prepareSocialGate(self.id,self.evidence,self.requiresMovement);
        if (value.gate == nil) { value.reason = 'reaction-preparation-health-adapter-required'; return value; }
        local permission = value.gate.assess(); if (permission.status != 'ready') { value.reason = permission.reason; return value; }
        rpgInteger(rpgLedger.seconds,0,2147483647-self.seconds); rpgLedger.validateAdvance(self.seconds);
        value.status = 'ready'; return value;
    }
    validateCommit(definition, historyCount)
    {
        local current = self.definition();
        if (current.length() != definition.length()) rpgExpandedReject('reaction-preparation-changed');
        for (local index = 1; index <= current.length(); index += 1)
            if (current[index] != definition[index]) rpgExpandedReject('reaction-preparation-changed');
        self.encounter.validate();
        if (self.encounter.history.length() != 0 || self.encounter.predeterminedBand != nil
            || self.encounter.skillPreparation != nil || self.encounter.preparationHistory.length() != historyCount)
            rpgExpandedReject('reaction-preparation-encounter-changed');
        return nil;
    }
    resolve()
    {
        local value = self.assess(); if (value.status == 'reused') return self.result;
        if (value.status != 'ready') return value;
        local definition = self.definition(); local start = rpgLedger.seconds;
        local historyCount = self.encounter.preparationHistory.length(); local permission = value.gate.apply();
        if (permission.status != 'resolved') rpgExpandedReject('reaction-preparation-permission-changed');
        self.validateCommit(definition,historyCount);
        value.allowed = permission.allowed;
        if (value.allowed)
        {
            rpgSpendTime(self.seconds);
            self.validateCommit(definition,historyCount);
            if (rpgLedger.seconds != start+self.seconds || rpgLiteScore(self.encounter.subject,self.context()) != value.score)
                rpgExpandedReject('reaction-preparation-context-changed');
            if (self.entertainment != nil)
            {
                local paid = self.entertainment.purchase();
                if (!holds(['resolved','reused'],paid.status)) rpgExpandedReject('reaction-entertainment-unpaid');
            }
            value.check = rpgCheck(value.score,rpgRandom.roll());
            value.modifier = value.check.achieved ? 2 : self.skill.id == 'carousing' ? -2 : 0;
        }
        self.validateCommit(definition,historyCount);
        self.boundDefinition = definition; self.result = value;
        self.encounter.preparationHistory = self.encounter.preparationHistory + [self];
        if (value.check != nil) self.encounter.skillPreparation = self;
        value.status = 'resolved'; return value;
    }
;

modify RpgExpandedProfile
    entertainmentPurchases = []
;
/** B183 author-priced drinks/entertainment for one Carousing encounter. */
class RpgExpandedCarousingEntertainment: object
    id = nil
    preparation = nil
    payer = nil
    provider = nil
    price = 0
    bonus = 0
    available = nil
    approved = nil
    evidence = nil
    result = nil
    boundDefinition = nil
    definition() { return [self.id,self.preparation,self.payer,self.provider,self.price,self.bonus,self.available,self.approved,self.evidence]; }
    assess()
    {
        if (self.id == nil || self.id == '' || self.preparation == nil || !self.preparation.ofKind(RpgExpandedReactionPreparation)
            || self.payer == nil || !self.payer.ofKind(RpgExpandedProfile) || self.provider == nil || !self.provider.ofKind(RpgLiteProfile)
            || self.provider == self.payer || self.preparation.entertainment != self || self.preparation.encounter.subject != self.payer
            || self.preparation.skill.id != 'carousing') rpgExpandedReject('entertainment-definition');
        local value = new RpgExpandedResult(); local definition = self.definition();
        if (self.result != nil)
        {
            for (local index = 1; index <= definition.length(); index += 1)
                if (definition[index] != self.boundDefinition[index]) rpgExpandedReject('entertainment-binding');
            if (!holds(self.payer.entertainmentPurchases,self)) rpgExpandedReject('entertainment-history');
            value.status = 'reused'; return value;
        }
        rpgInteger(self.price,1,2147483647); rpgInteger(self.bonus,1,3);
        rpgInteger(self.payer.money,0,2147483647); rpgInteger(self.provider.money,0,2147483647-self.price);
        foreach (local prior in self.payer.entertainmentPurchases)
            if (prior.id == self.id || prior.preparation == self.preparation) rpgExpandedReject('entertainment-duplicate');
        if (!self.available || !self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'entertainment-service-facts'; return value; }
        if (self.payer.money < self.price) { value.reason = 'entertainment-unaffordable'; return value; }
        value.status = 'ready'; return value;
    }
    purchase()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.payer.money -= self.price; self.provider.money += self.price;
        self.boundDefinition = self.definition(); self.result = value;
        self.payer.entertainmentPurchases = self.payer.entertainmentPurchases + [self]; value.status = 'resolved'; return value;
    }
;

/** B141 observed lack of appreciation. Adverse outcomes must stay nonviolent. */
class RpgExpandedPleasureReactionContext: RpgLiteSocialContext
    subject = nil
    observer = nil
    noticeable = nil
    penalty = 1
    adverseResponse = 'ridicule'
    approved = nil
    evidence = nil
    traitReactionModifier(profile)
    {
        if (self.subject == nil || !self.subject.ofKind(RpgExpandedProfile) || profile != self.subject
            || self.observer == nil || !self.observer.ofKind(RpgLiteProfile) || self.observer == self.subject)
            rpgExpandedReject('pleasure-reaction-participants');
        if (!self.approved || self.evidence == nil || self.evidence == '') rpgExpandedReject('pleasure-reaction-evidence');
        rpgInteger(self.penalty,1,3);
        if (!holds(['ridicule','rejection'],self.adverseResponse)) rpgExpandedReject('pleasure-reaction-nonviolent-response');
        return inherited(profile) - (self.noticeable && self.subject.pleasureLossActive() ? self.penalty : 0);
    }
    validateParticipants(profile, target)
    {
        self.traitReactionModifier(profile);
        if (target != self.observer) rpgExpandedReject('pleasure-reaction-observer');
        return nil;
    }
    consequence(band)
    {
        self.traitReactionModifier(self.subject); rpgInteger(band,0,7);
        local value = new RpgExpandedResult(); value.status = 'ready';
        value.reason = self.noticeable && self.subject.pleasureLossActive() && band < 4
            ? self.adverseResponse : 'ordinary-social-response'; return value;
    }
;

/** B125 observer facts are explicit; victim and empathy do not stack. */
class RpgExpandedCallousnessReactionContext: RpgLiteSocialContext
    subject = nil
    observer = nil
    pastVictim = nil
    empathicObserver = nil
    approved = nil
    evidence = nil
    traitReactionModifier(profile)
    {
        if (profile != self.subject || self.subject == nil || !self.subject.ofKind(RpgExpandedProfile)
            || self.observer == nil || !self.observer.ofKind(RpgLiteProfile) || self.observer == self.subject)
            rpgExpandedReject('callousness-reaction-participants');
        if (!self.approved || self.evidence == nil || self.evidence == '') rpgExpandedReject('callousness-reaction-facts');
        return inherited(profile) - (self.subject.callousnessActive() && (self.pastVictim || self.empathicObserver) ? 1 : 0);
    }
    validateParticipants(profile, target)
    {
        self.traitReactionModifier(profile);
        if (target != self.observer) rpgExpandedReject('callousness-reaction-observer');
        return nil;
    }
;

modify RpgExpandedProfile
    gestureExchanges = []
;
class RpgExpandedGestureResult: RpgExpandedResult
    studyEligible = nil
    intendedMeaning = nil
    interpretedMeaning = nil
    interpretation = nil
;
/** B125 player-authored communication without a shared signing language. */
class RpgExpandedGestureExchange: RpgExpandedCommunicationReceipt
    id = nil
    sender = nil
    recipient = nil
    playerParticipants = nil
    sharedSigningLanguage = nil
    gesture = nil
    intendedMeaning = nil
    interpretedMeaning = nil
    interpretation = nil
    observed = nil
    requiresMovement = true
    approved = nil
    evidence = nil
    seconds = 0
    startedAt = nil
    completedAt = nil
    boundDefinition = nil
    result = nil
    definition()
    {
        return [self.id,self.sender,self.recipient,self.playerParticipants,self.sharedSigningLanguage,
            self.gesture,self.intendedMeaning,self.interpretedMeaning,self.interpretation,self.observed,
            self.requiresMovement,self.approved,self.evidence,self.seconds];
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.sender == nil || !self.sender.ofKind(RpgExpandedProfile)
            || self.recipient == nil || !self.recipient.ofKind(RpgExpandedProfile) || self.sender == self.recipient)
            rpgExpandedReject('gesture-exchange-participants');
        local value = new RpgExpandedGestureResult();
        if (self.result != nil)
        {
            local current = self.definition();
            for (local i = 1; i <= current.length(); i += 1)
                if (current[i] != self.boundDefinition[i]) rpgExpandedReject('gesture-exchange-binding');
            if (!holds(self.sender.gestureExchanges,self) || !holds(self.recipient.gestureExchanges,self)
                || self.completedAt != self.startedAt + self.seconds) rpgExpandedReject('gesture-exchange-history');
            value.status = 'reused'; return value;
        }
        rpgInteger(self.seconds,0,86400);
        foreach (local profile in [self.sender,self.recipient])
            foreach (local prior in profile.gestureExchanges)
                if (prior.id == self.id) rpgExpandedReject('gesture-exchange-duplicate');
        if (!self.playerParticipants || self.sharedSigningLanguage)
        { value.reason = 'gesture-exchange-scope'; return value; }
        if (!self.approved || self.evidence == nil || self.evidence == '' || self.gesture == nil || self.gesture == ''
            || self.intendedMeaning == nil || self.intendedMeaning == '')
        { value.reason = 'gesture-exchange-authorship-required'; return value; }
        if (!holds(['understood','misunderstood','unresolved'],self.interpretation)
            || self.interpretation != 'unresolved' && (self.interpretedMeaning == nil || self.interpretedMeaning == '')
            || self.interpretation == 'unresolved' && self.interpretedMeaning != nil)
        { value.reason = 'gesture-exchange-player-interpretation-required'; return value; }
        if (!self.observed) { value.reason = 'gesture-exchange-not-observed'; return value; }
        value.reason = self.conditionsReason(); if (value.reason != nil) return value;
        rpgInteger(rpgLedger.seconds,0,2147483647-self.seconds); rpgLedger.validateAdvance(self.seconds);
        value.status = 'ready'; value.seconds = self.seconds; return value;
    }
    studySeconds(profile)
    {
        if (self.result == nil || profile != self.sender) return 0;
        self.assess();
        return self.result.studyEligible ? self.result.seconds : 0;
    }
    conditionsReason()
    {
        if (self.sender.dead || self.sender.unconscious || self.recipient.dead || self.recipient.unconscious)
            return 'gesture-exchange-participant-unavailable';
        return self.sender.healthEffortReason('gesture',nil,nil,self.requiresMovement);
    }
    apply()
    {
        local value = self.assess(); if (value.status == 'reused') return self.result;
        if (value.status != 'ready') return value;
        local definition = self.definition(); local start = rpgLedger.seconds;
        local studyEligible = self.sender.communicationStudyEligible();
        local sent = self.sender.gestureExchanges.length(); local received = self.recipient.gestureExchanges.length();
        rpgSpendTime(self.seconds);
        local current = self.definition();
        for (local i = 1; i <= current.length(); i += 1)
            if (current[i] != definition[i]) rpgExpandedReject('gesture-exchange-interrupted');
        if (rpgLedger.seconds != start + value.seconds || self.sender.gestureExchanges.length() != sent
            || self.recipient.gestureExchanges.length() != received) rpgExpandedReject('gesture-exchange-interrupted');
        if (self.conditionsReason() != nil || self.sender.communicationStudyEligible() != studyEligible)
            rpgExpandedReject('gesture-exchange-conditions-changed');
        self.boundDefinition = definition; self.startedAt = start; self.completedAt = rpgLedger.seconds;
        value.studyEligible = studyEligible;
        value.intendedMeaning = self.intendedMeaning; value.interpretedMeaning = self.interpretedMeaning;
        value.interpretation = self.interpretation;
        self.sender.gestureExchanges = self.sender.gestureExchanges + [self];
        self.recipient.gestureExchanges = self.recipient.gestureExchanges + [self];
        value.status = 'resolved'; self.result = value; return value;
    }
;

/** B126 the observer likes company; this does not make the subject charismatic. */
class RpgExpandedCompanionshipReactionContext: RpgLiteSocialContext
    subject = nil
    observer = nil
    usualReaction = nil
    approved = nil
    evidence = nil
    traitReactionModifier(profile)
    {
        if (profile != self.subject || self.subject == nil || !self.subject.ofKind(RpgLiteProfile)
            || self.observer == nil || !self.observer.ofKind(RpgExpandedProfile) || self.observer == self.subject)
            rpgExpandedReject('companionship-reaction-participants');
        if (!self.approved || self.evidence == nil || self.evidence == '') rpgExpandedReject('companionship-reaction-evidence');
        return inherited(profile) + (self.usualReaction ? 2 * self.observer.companionshipLevel() : 0);
    }
    validateParticipants(profile,target)
    {
        self.traitReactionModifier(profile);
        if (target != self.observer) rpgExpandedReject('companionship-reaction-observer');
        return nil;
    }
;


/** B89-B91 observer-specific appreciation of demonstrated catalogue talent. */
class RpgExpandedTalentReactionContext: RpgLiteSocialContext
    subject = nil
    observer = nil
    talent = nil
    demonstratedSkill = nil
    observedPerformance = nil
    eligibleAudience = nil
    impressed = nil
    manipulatingObserver = nil
    approved = nil
    evidence = nil
    traitReactionModifier(profile)
    {
        if (profile != self.subject || self.subject == nil || !self.subject.ofKind(RpgExpandedProfile)
            || self.observer == nil || !self.observer.ofKind(RpgLiteProfile) || self.observer == self.subject)
            rpgExpandedReject('talent-reaction-participants');
        if (!self.approved || self.evidence == nil || self.evidence == '') rpgExpandedReject('talent-reaction-evidence');
        if (self.talent == nil || !self.talent.ofKind(RpgLiteTrait) || !holds(profile.traits,self.talent))
            rpgExpandedReject('talent-reaction-purchase');
        local skills = profile.catalogueTalentSkills(self.talent.id);
        if (skills.length() == 0) rpgExpandedReject('talent-reaction-unavailable');
        local count = 0;
        foreach (local trait in profile.traits) if (trait.id == self.talent.id) count += 1;
        if (count != 1) rpgExpandedReject('talent-reaction-purchase');
        rpgInteger(self.talent.level,1,4); self.talent.creationCost();
        if (self.demonstratedSkill == nil || !self.demonstratedSkill.ofKind(RpgLiteSkill)
            || !profile.catalogueTalentApplies(self.talent.id,self.demonstratedSkill)) rpgExpandedReject('talent-reaction-skill');
        local bonus = self.talent.active && !self.talent.mitigated && self.observedPerformance
            && self.eligibleAudience && self.impressed
            && !(self.talent.id == 'smooth-operator' && self.manipulatingObserver) ? self.talent.level : 0;
        return inherited(profile) + bonus;
    }
    validateParticipants(profile,target)
    {
        self.traitReactionModifier(profile);
        if (target != self.observer) rpgExpandedReject('talent-reaction-observer');
        return nil;
    }
;

/** Immutable, participant-specific observation. Concrete types supply each rule. */
class RpgExpandedSocialObservation: object
    id = nil
    subject = nil
    observer = nil
    approved = nil
    evidence = nil
    recordedAt = nil
    boundDefinition = nil
    kind() { rpgExpandedReject('social-observation-kind'); }
    modifier() { rpgExpandedReject('social-observation-rule'); }
    definition() { return [self.id,self.subject,self.observer,self.approved,self.evidence,self.recordedAt,self.kind()]; }
    validateReceipt()
    {
        if (self.recordedAt == nil || !holds(self.subject.socialObservations,self)) rpgExpandedReject('social-observation-owner');
        local current = self.definition();
        if (current.length() != self.boundDefinition.length()) rpgExpandedReject('social-observation-binding');
        for (local i = 1; i <= current.length(); i += 1)
            if (current[i] != self.boundDefinition[i]) rpgExpandedReject('social-observation-binding');
        return nil;
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.subject == nil || !self.subject.ofKind(RpgExpandedProfile)
            || self.observer == nil || !self.observer.ofKind(RpgLiteProfile) || self.subject == self.observer)
            rpgExpandedReject('social-observation-participants');
        self.kind(); local value = new RpgExpandedResult();
        if (self.recordedAt != nil) { self.validateReceipt(); value.status = 'reused'; return value; }
        if (!self.approved || self.evidence == nil || self.evidence == '') { value.reason = 'social-observation-evidence'; return value; }
        foreach (local prior in self.subject.socialObservations)
        { prior.validateReceipt(); if (prior.id == self.id) rpgExpandedReject('social-observation-duplicate'); }
        value.modifier = self.modifier(); value.status = 'ready'; return value;
    }
    record()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.recordedAt = rpgLedger.seconds; self.boundDefinition = self.definition();
        self.subject.socialObservations = self.subject.socialObservations + [self]; value.status = 'resolved'; return value;
    }
;
modify RpgExpandedProfile
    socialObservations = []
;
class RpgExpandedHumorlessnessObservation: RpgExpandedSocialObservation
    evident = nil
    kind() { return 'humorlessness'; }
    definition() { return inherited() + [self.evident]; }
    modifier() { return self.evident && self.subject.humorlessnessActive() ? -2 : 0; }
;
class RpgExpandedCallousnessObservation: RpgExpandedSocialObservation
    pastVictim = nil
    empathicObserver = nil
    kind() { return 'callousness'; }
    definition() { return inherited() + [self.pastVictim,self.empathicObserver]; }
    modifier() { return (self.pastVictim || self.empathicObserver) && self.subject.callousnessActive() ? -1 : 0; }
;
class RpgExpandedObservedReactionContext: RpgLiteSocialContext
    subject = nil
    observer = nil
    observations = []
    traitReactionModifier(profile)
    {
        if (profile != self.subject || self.subject == nil || !self.subject.ofKind(RpgExpandedProfile)
            || self.observer == nil || !self.observer.ofKind(RpgLiteProfile) || self.observer == self.subject)
            rpgExpandedReject('observed-reaction-participants');
        local amount = inherited(profile); local kinds = [];
        foreach (local fact in self.observations)
        {
            if (fact == nil || !fact.ofKind(RpgExpandedSocialObservation) || fact.subject != profile || fact.observer != self.observer)
                rpgExpandedReject('observed-reaction-fact-owner');
            fact.validateReceipt(); local kind = fact.kind();
            if (holds(kinds,kind)) rpgExpandedReject('observed-reaction-duplicate-effect');
            kinds = kinds + [kind]; amount += fact.modifier();
        }
        return amount;
    }
    validateParticipants(profile,target)
    {
        self.traitReactionModifier(profile);
        if (target != self.observer) rpgExpandedReject('observed-reaction-observer'); return nil;
    }
;
/** Stores the observation selection with the resolved approach, without exposing it to players. */
class RpgExpandedObservedReactionAttempt: RpgExpandedReactionAttempt
    boundObservationDefinition = nil
    observationDefinition()
    {
        if (self.socialContext == nil || !self.socialContext.ofKind(RpgExpandedObservedReactionContext))
            rpgExpandedReject('observed-reaction-context');
        local definition = [self.encounter,self.approach,self.socialContext,self.socialContext.subject,self.socialContext.observer]
            + self.socialContext.observationFacts();
        foreach (local fact in self.socialContext.observations)
        {
            if (fact == nil || !fact.ofKind(RpgExpandedSocialObservation)) rpgExpandedReject('observed-reaction-fact-owner');
            fact.validateReceipt(); definition = definition + [fact] + fact.definition();
        }
        return definition;
    }
    assess()
    {
        local current = self.observationDefinition();
        if (self.boundObservationDefinition != nil)
        {
            if (current.length() != self.boundObservationDefinition.length()) rpgExpandedReject('observed-reaction-binding');
            for (local i = 1; i <= current.length(); i += 1)
                if (current[i] != self.boundObservationDefinition[i]) rpgExpandedReject('observed-reaction-binding');
        }
        return inherited();
    }
    resolve()
    {
        local value = inherited();
        if (value.status == 'resolved') self.boundObservationDefinition = self.observationDefinition();
        return value;
    }
;


modify RpgExpandedObservedReactionContext
    observationFacts() { return []; }
    traitReactionComponents(profile)
    {
        self.traitReactionModifier(profile); local parts = [];
        foreach (local fact in self.observations) parts = parts + [[fact.kind(),fact.modifier()]];
        return parts;
    }
;
class RpgExpandedDistrustObservation: RpgExpandedSocialObservation
    typicalObserver = nil
    kind() { return 'pervasive-distrust'; }
    definition() { return inherited() + [self.typicalObserver]; }
    modifier() { return self.typicalObserver && self.subject.pervasiveDistrustActive() ? -2 : 0; }
;
/** B148 observer behavior: double each other negative contribution, not the net. */
class RpgExpandedDistrustReactionContext: RpgExpandedObservedReactionContext
    observerIsNpc = nil
    stranger = nil
    approved = nil
    evidence = nil
    adjustments = []
    observationFacts()
    {
        local facts = [self.observerIsNpc,self.stranger,self.approved,self.evidence,self.modifier];
        foreach (local row in self.adjustments) facts = facts + row;
        return facts;
    }
    validateObserverFacts()
    {
        if (self.observer == nil || !self.observer.ofKind(RpgExpandedProfile)) rpgExpandedReject('distrust-reaction-observer');
        if (!self.approved || self.evidence == nil || self.evidence == '') rpgExpandedReject('distrust-reaction-facts');
        if (self.modifier != 0) rpgExpandedReject('distrust-itemized-modifiers-required');
        return nil;
    }
    baseReactionComponents(profile)
    {
        self.validateObserverFacts(); local parts = []; local ids = [];
        foreach (local row in self.adjustments)
        {
            if (row.length() != 3 || row[1] == nil || row[1] == '' || row[3] == nil || row[3] == '' || holds(ids,row[1]))
                rpgExpandedReject('distrust-reaction-adjustment');
            rpgInteger(row[2],-1000,1000); ids = ids + [row[1]]; parts = parts + [[row[1],row[2]]];
        }
        return parts;
    }
    adjustReactionComponent(profile,id,amount)
    {
        self.validateObserverFacts();
        return self.observerIsNpc && self.observer.pervasiveDistrustActive() && amount < 0 ? amount * 2 : amount;
    }
    observerReactionModifier(profile)
    {
        self.validateObserverFacts();
        return self.observerIsNpc && self.stranger && self.observer.pervasiveDistrustActive() ? -4 : 0;
    }
;

/** B148: observers who witness a response to unheard voices, not all encounters. */
class RpgExpandedPhantomVoiceObservation: RpgExpandedSocialObservation
    occurrence = nil
    witnessedResponse = nil
    typicalObserver = nil
    kind() { return 'phantom-voices'; }
    definition() { return inherited() + [self.occurrence,self.witnessedResponse,self.typicalObserver]; }
    modifier()
    {
        self.subject.validatePhantomVoiceOccurrence(self.occurrence);
        if (!self.occurrence.result.occurred) rpgExpandedReject('phantom-voices-observation-episode');
        if (self.occurrence.result.severity == 3) rpgExpandedReject('phantom-voices-commanding-reaction-unresolved');
        return self.witnessedResponse && self.typicalObserver ? -2 : 0;
    }
;

/** B130: a witnessed portrayal, not an automatic penalty for owning the belief. */
class RpgExpandedFixedBeliefObservation: RpgExpandedSocialObservation
    portrayal = nil
    noticed = nil
    kind() { return 'fixed-belief'; }
    definition()
    {
        if (self.portrayal == nil) rpgExpandedReject('fixed-belief-observation-portrayal');
        return inherited() + [self.portrayal,self.noticed] + self.portrayal.definition();
    }
    modifier()
    {
        self.subject.validateFixedBeliefPortrayal(self.portrayal);
        local level = self.subject.fixedBeliefReactionLevel(self.portrayal.belief);
        return self.noticed ? -level : 0;
    }
;

/** B131 competence bracket; the nonpositive dependent-total row is absolute. */
rpgExpandedDependentBase(principalPoints,dependentPoints)
{
    rpgInteger(principalPoints,-1000000,1000000); rpgInteger(dependentPoints,-1000000,1000000);
    if (dependentPoints <= 0) return -15;
    if (principalPoints <= 0) rpgExpandedReject('dependent-nonpositive-principal');
    if (dependentPoints * 4 <= principalPoints) return -10;
    if (dependentPoints * 2 <= principalPoints) return -5;
    if (dependentPoints * 4 <= principalPoints * 3) return -2;
    if (dependentPoints <= principalPoints) return -1;
    rpgExpandedReject('dependent-above-principal');
}
/** B36 frequency fraction; zero denotes the restricted constant-presence option. */
rpgExpandedAppearanceMultiplier(frequency)
{
    if (frequency == 0) return [4,1];
    if (frequency == 15) return [3,1];
    if (frequency == 12) return [2,1];
    if (frequency == 9) return [1,1];
    if (frequency == 6) return [1,2];
    rpgExpandedReject('associated-appearance-frequency');
}
rpgExpandedDependentCost(principalPoints,dependentPoints,importance,frequency,group)
{
    local numerator = -rpgExpandedDependentBase(principalPoints,dependentPoints); local denominator = 1;
    if (importance == 'acquaintance') denominator = 2;
    else if (importance == 'loved-one') numerator *= 2;
    else if (importance != 'friend') rpgExpandedReject('dependent-importance');
    local appearance = rpgExpandedAppearanceMultiplier(frequency);
    local memberCost = -((numerator * appearance[1]) / (denominator * appearance[2]));
    return group ? memberCost * 2 : memberCost;
}
class RpgExpandedDependent: RpgExpandedContribution
    dependent = nil
    principalPoints = nil
    dependentPoints = nil
    importance = nil
    frequency = 9
    group = nil
    credited = true
    constantAttachment = nil
    approved = nil
    evidence = nil
    definition()
    {
        return [self.id,self.owner,self.dependent,self.principalPoints,self.dependentPoints,self.importance,self.frequency,
            self.group,self.credited,self.constantAttachment,self.approved,self.evidence];
    }
    cost() { return rpgExpandedDependentCost(self.principalPoints,self.dependentPoints,self.importance,self.frequency,self.group); }
    amounts(profile) { self.validate(profile); return [self.credited && self.retiredBy == nil ? self.cost() : 0]; }
    validate(profile)
    {
        if (self.owner != profile || self.id == nil || self.id == '' || self.dependent == nil || self.dependent == profile
            || !self.approved || self.evidence == nil || self.evidence == '') rpgExpandedReject('dependent-definition');
        self.cost();
        if (self.frequency == 0 && !holds(['implanted','worn','supernatural'],self.constantAttachment))
            rpgExpandedReject('dependent-constant-attachment-required');
        if (self.frequency != 0 && self.constantAttachment != nil) rpgExpandedReject('dependent-unneeded-attachment');
        local slots = 0;
        foreach (local entry in profile.contributions)
            if (entry.ofKind(RpgExpandedDependent))
            {
                if (entry != self && entry.dependent == self.dependent && entry.retiredBy == nil && self.retiredBy == nil)
                    rpgExpandedReject('dependent-duplicate-person');
                if (entry.credited && entry.retiredBy == nil) slots += entry.group ? 2 : 1;
            }
        if (slots > 2) rpgExpandedReject('dependent-credit-slots');
        if (self.loss != nil && (self.loss.relationship != self || self.loss.assess().status != 'reused'))
            rpgExpandedReject('dependent-loss-receipt');
        if (self.retiredBy != nil && (self.loss == nil || self.retiredBy.loss != self.loss
            || self.retiredBy.assess().status != 'reused')) rpgExpandedReject('dependent-retirement-receipt');
        return nil;
    }
;
modify RpgExpandedProfile
    dependentAppearances = []
;
class RpgExpandedDependentAppearanceResult: RpgExpandedResult
    appeared = nil
    roll = nil
;
/** One appearance check per relationship/adventure, separate from any helpful role. */
class RpgExpandedDependentAppearance: object
    relationship = nil
    adventure = nil
    approved = nil
    evidence = nil
    result = nil
    boundDefinition = nil
    boundOutcome = nil
    definition() { return [self.relationship,self.adventure,self.approved,self.evidence] + self.relationship.definition(); }
    assess()
    {
        if (self.relationship == nil || !self.relationship.ofKind(RpgExpandedDependent) || self.adventure == nil)
            rpgExpandedReject('dependent-appearance-definition');
        local value = new RpgExpandedDependentAppearanceResult(); local profile = self.relationship.owner;
        if (profile == nil || !profile.ofKind(RpgExpandedProfile)) rpgExpandedReject('dependent-appearance-ownership');
        if (self.result != nil)
        {
            if (!holds(profile.dependentAppearances,self)) rpgExpandedReject('dependent-appearance-history');
            local facts = self.definition();
            if (self.boundDefinition == nil || facts.length() != self.boundDefinition.length()
                || self.boundOutcome == nil || self.boundOutcome.length() != 2)
                rpgExpandedReject('dependent-appearance-binding');
            for (local index = 1; index <= facts.length(); index += 1)
                if (facts[index] != self.boundDefinition[index]) rpgExpandedReject('dependent-appearance-binding');
            if (self.result.roll != self.boundOutcome[1] || self.result.appeared != self.boundOutcome[2])
                rpgExpandedReject('dependent-appearance-outcome');
            value.status = 'reused'; value.roll = self.result.roll; value.appeared = self.result.appeared; return value;
        }
        if (self.boundDefinition != nil || self.boundOutcome != nil) rpgExpandedReject('dependent-appearance-uncommitted-state');
        if (profile == nil || !profile.ofKind(RpgExpandedProfile) || !holds(profile.contributions,self.relationship))
            rpgExpandedReject('dependent-appearance-ownership');
        rpgExpandedValidate(profile);
        if (self.relationship.loss != nil) { value.reason = 'dependent-unavailable'; return value; }
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'dependent-adventure-start-required'; return value; }
        foreach (local prior in profile.dependentAppearances)
            if (prior.relationship == self.relationship && prior.adventure == self.adventure)
                rpgExpandedReject('dependent-appearance-duplicate-adventure');
        value.status = 'ready'; return value;
    }
    resolve()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        value.roll = self.relationship.frequency == 0 ? nil : rpgRandom.roll();
        value.appeared = self.relationship.frequency == 0 || value.roll <= self.relationship.frequency;
        self.boundDefinition = self.definition(); self.boundOutcome = [value.roll,value.appeared];
        self.relationship.owner.dependentAppearances = self.relationship.owner.dependentAppearances + [self];
        value.status = 'resolved'; self.result = value; return value;
    }
;

/** B131: close authored dependent outcomes before granting session points. */
class RpgExpandedDependentSession: object
    profile = nil
    session = nil
    approved = nil
    evidence = nil
    /* [relationship, peril, prompt aid, killed/badly hurt, deny bonus, evidence] */
    outcomes = []
    recorded = nil
    boundDefinition = nil
    definition()
    {
        local facts = [self.profile,self.session,self.approved,self.evidence,self.outcomes.length()];
        foreach (local row in self.outcomes) facts = facts + row + row[1].definition();
        return facts;
    }
    assess()
    {
        local value = new RpgExpandedResult();
        if (self.profile == nil || !self.profile.ofKind(RpgExpandedProfile) || self.session == nil)
            rpgExpandedReject('dependent-session-owner');
        if (self.recorded)
        {
            if (!holds(self.profile.dependentSessions,self)) rpgExpandedReject('dependent-session-history');
            local facts = self.definition();
            if (self.boundDefinition == nil || facts.length() != self.boundDefinition.length())
                rpgExpandedReject('dependent-session-binding');
            for (local index = 1; index <= facts.length(); index += 1)
                if (facts[index] != self.boundDefinition[index]) rpgExpandedReject('dependent-session-binding');
            value.status = 'reused'; return value;
        }
        if (self.boundDefinition != nil) rpgExpandedReject('dependent-session-uncommitted');
        rpgExpandedValidate(self.profile);
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'dependent-session-adjudication-required'; return value; }
        local seen = [];
        foreach (local row in self.outcomes)
        {
            if (row.length() != 6 || row[1] == nil || !row[1].ofKind(RpgExpandedDependent)
                || !holds(self.profile.contributions,row[1]) || holds(seen,row[1])
                || row[6] == nil || row[6] == '') rpgExpandedReject('dependent-session-outcome');
            if (row[5] && (!row[2] || row[3])) rpgExpandedReject('dependent-session-bonus-judgment');
            seen = seen + [row[1]];
        }
        foreach (local relationship in self.profile.contributions)
            if (relationship.ofKind(RpgExpandedDependent) && relationship.retiredBy == nil && !holds(seen,relationship))
                rpgExpandedReject('dependent-session-missing-relationship');
        foreach (local prior in self.profile.dependentSessions)
            if (prior.session == self.session) rpgExpandedReject('dependent-session-duplicate');
        for (local award = firstObj(RpgAward); award != nil; award = nextObj(award,RpgAward))
            if (award.profile == self.profile && award.claimed && award.milestone.awardSession == self.session)
                rpgExpandedReject('dependent-session-already-awarded');
        value.status = 'ready'; return value;
    }
    record()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.boundDefinition = self.definition(); self.recorded = true;
        self.profile.dependentSessions = self.profile.dependentSessions + [self];
        value.status = 'resolved'; return value;
    }
    awardReason(bonus)
    {
        if (self.assess().status != 'reused') return 'dependent-session-not-closed';
        foreach (local row in self.outcomes)
            if (row[4]) return 'dependent-serious-harm-no-session-points';
        foreach (local row in self.outcomes)
            if (bonus && row[5]) return 'dependent-rescue-bonus-denied';
        return nil;
    }
;
modify RpgExpandedProfile
    dependentSessions = []
    milestoneAwardReason(milestone)
    {
        local reason = inherited(milestone); if (reason != nil) return reason;
        local required = nil;
        foreach (local relationship in self.contributions)
            if (relationship.ofKind(RpgExpandedDependent) && relationship.retiredBy == nil) required = true;
        if (self.dependentLosses.length() != 0 && milestone.awardSession == nil) return 'dependent-award-session-required';
        foreach (local loss in self.dependentLosses)
            if (loss.session == milestone.awardSession)
            { loss.assess(); return 'dependent-serious-harm-no-session-points'; }
        foreach (local closure in self.dependentSessions)
            if (closure.session == milestone.awardSession) return closure.awardReason(milestone.bonusAward);
        return required ? 'dependent-session-closure-required' : nil;
    }
;


modify RpgExpandedDependent
    /** Copy only authored purchase facts; no profile or adventure histories. */
    templateCopy(profile)
    {
        if (self.owner != nil) rpgExpandedReject('dependent-template-owned-definition');
        local copy = new RpgExpandedDependent();
        copy.id = self.id; copy.owner = profile; copy.dependent = self.dependent;
        copy.principalPoints = self.principalPoints; copy.dependentPoints = self.dependentPoints;
        copy.importance = self.importance; copy.frequency = self.frequency;
        copy.group = self.group; copy.credited = self.credited; copy.constantAttachment = self.constantAttachment;
        copy.approved = self.approved; copy.evidence = self.evidence;
        return copy;
    }
;

modify RpgExpandedDependent
    templateCost()
    {
        local profile = new RpgExpandedProfile(); local purchase = self.templateCopy(profile);
        profile.contributions = [purchase]; purchase.validate(profile);
        return purchase.credited ? purchase.cost() : 0;
    }
;

/** Exact whole-point proportional build total, without overflowing cross-products. */
rpgExpandedDependentGrowthTotal(principalPoints,dependentPoints,newPrincipalPoints)
{
    rpgInteger(principalPoints,1,1000000); rpgInteger(dependentPoints,1,principalPoints);
    rpgInteger(newPrincipalPoints,principalPoints,1000000);
    local a = principalPoints; local b = dependentPoints;
    while (b != 0) { local remainder = a % b; a = b; b = remainder; }
    local denominator = principalPoints / a; local numerator = dependentPoints / a;
    if (newPrincipalPoints % denominator != 0) rpgExpandedReject('dependent-growth-fractional-total');
    return (newPrincipalPoints / denominator) * numerator;
}
modify RpgExpandedDependent
    growthHistory = []
;
/** B131 approved NPC build changes, not points granted to the principal. */
class RpgExpandedDependentGrowth: object
    id = nil
    relationship = nil
    previous = nil
    newPrincipalPoints = nil
    newDependentPoints = nil
    approved = nil
    evidence = nil
    /* Authored build changes: [unique change ID, positive point cost, description]. */
    improvements = []
    recorded = nil
    boundDefinition = nil
    definition()
    {
        local facts = [self.id,self.relationship,self.previous,self.newPrincipalPoints,self.newDependentPoints,
            self.approved,self.evidence,self.improvements.length()] + self.relationship.definition();
        foreach (local row in self.improvements) facts = facts + row;
        return facts;
    }
    assess()
    {
        local value = new RpgExpandedResult();
        if (self.relationship == nil || !self.relationship.ofKind(RpgExpandedDependent)
            || self.id == nil || self.id == '') rpgExpandedReject('dependent-growth-definition');
        local history = self.relationship.growthHistory;
        if (self.recorded)
        {
            if (!holds(history,self)) rpgExpandedReject('dependent-growth-history');
            local facts = self.definition();
            if (self.boundDefinition == nil || facts.length() != self.boundDefinition.length())
                rpgExpandedReject('dependent-growth-binding');
            for (local index = 1; index <= facts.length(); index += 1)
                if (facts[index] != self.boundDefinition[index]) rpgExpandedReject('dependent-growth-binding');
            if (self.previous != nil && self.previous.assess().status != 'reused')
                rpgExpandedReject('dependent-growth-previous');
            value.status = 'reused'; return value;
        }
        if (self.boundDefinition != nil) rpgExpandedReject('dependent-growth-uncommitted');
        local profile = self.relationship.owner;
        rpgExpandedValidate(profile);
        if (!holds(profile.contributions,self.relationship)) rpgExpandedReject('dependent-growth-owner');
        if (self.relationship.loss != nil) { value.reason = 'dependent-unavailable'; return value; }
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'dependent-growth-approval-required'; return value; }
        local latest = history.length() == 0 ? nil : history[history.length()];
        if (self.previous != latest) rpgExpandedReject('dependent-growth-previous');
        local oldPrincipal = self.relationship.principalPoints; local oldDependent = self.relationship.dependentPoints;
        if (latest != nil)
        {
            if (latest.assess().status != 'reused') rpgExpandedReject('dependent-growth-previous');
            oldPrincipal = latest.newPrincipalPoints; oldDependent = latest.newDependentPoints;
        }
        foreach (local prior in history) if (prior.id == self.id) rpgExpandedReject('dependent-growth-duplicate');
        rpgInteger(self.newPrincipalPoints,oldPrincipal + 1,1000000);
        local expected = rpgExpandedDependentGrowthTotal(self.relationship.principalPoints,
            self.relationship.dependentPoints,self.newPrincipalPoints);
        if (self.newDependentPoints != expected) rpgExpandedReject('dependent-growth-proportion');
        local total = 0; local ids = [];
        foreach (local row in self.improvements)
        {
            if (row.length() != 3 || row[1] == nil || row[1] == '' || holds(ids,row[1])
                || row[3] == nil || row[3] == '') rpgExpandedReject('dependent-growth-improvement');
            rpgInteger(row[2],1,1000000 - total); total += row[2]; ids = ids + [row[1]];
        }
        if (total != self.newDependentPoints - oldDependent) rpgExpandedReject('dependent-growth-improvement-accounting');
        value.status = 'ready'; return value;
    }
    record()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.boundDefinition = self.definition(); self.recorded = true;
        self.relationship.growthHistory = self.relationship.growthHistory + [self];
        value.status = 'resolved'; return value;
    }
;

modify RpgExpandedProfile
    dependentSkillGrowthApplications = []
;
/** Execute a fully itemized skill-only NPC growth record on existing owned slots. */
class RpgExpandedDependentSkillGrowth: object
    growth = nil
    /* [improvement ID, owned training, old points, new points, teacher or nil] */
    purchases = []
    recorded = nil
    boundDefinition = nil
    profile() { return self.growth.relationship.dependent; }
    definition()
    {
        local facts = [self.growth,self.purchases.length()] + self.growth.definition();
        foreach (local row in self.purchases) facts = facts + row + [row[2].skill];
        return facts;
    }
    assess()
    {
        local value = new RpgExpandedResult();
        if (self.growth == nil || !self.growth.ofKind(RpgExpandedDependentGrowth)
            || self.growth.assess().status != 'reused') rpgExpandedReject('dependent-skill-growth-record-required');
        local profile = self.profile();
        if (profile == nil || !profile.ofKind(RpgExpandedProfile)) rpgExpandedReject('dependent-skill-growth-profile');
        if (self.recorded)
        {
            if (!holds(profile.dependentSkillGrowthApplications,self)) rpgExpandedReject('dependent-skill-growth-history');
            local facts = self.definition();
            if (self.boundDefinition == nil || facts.length() != self.boundDefinition.length())
                rpgExpandedReject('dependent-skill-growth-binding');
            for (local index = 1; index <= facts.length(); index += 1)
                if (facts[index] != self.boundDefinition[index]) rpgExpandedReject('dependent-skill-growth-binding');
            value.status = 'reused'; return value;
        }
        if (self.boundDefinition != nil) rpgExpandedReject('dependent-skill-growth-uncommitted');
        if (self.growth.relationship.loss != nil) { value.reason = 'dependent-unavailable'; return value; }
        rpgExpandedValidate(profile);
        foreach (local prior in profile.dependentSkillGrowthApplications)
            if (prior.growth == self.growth) rpgExpandedReject('dependent-skill-growth-duplicate');
        local ids = []; local slots = [];
        foreach (local row in self.purchases)
        {
            if (row.length() != 5 || row[2] == nil || !row[2].ofKind(RpgTraining)
                || holds(ids,row[1]) || holds(slots,row[2])) rpgExpandedReject('dependent-skill-growth-purchase');
            rpgInteger(row[3],0,1000000); rpgInteger(row[4],row[3] + 1,1000000);
            local improvement = nil;
            foreach (local item in self.growth.improvements) if (item[1] == row[1]) improvement = item;
            if (improvement == nil || improvement[2] != row[4] - row[3])
                rpgExpandedReject('dependent-skill-growth-accounting');
            if (row[2].points != row[3]) rpgExpandedReject('dependent-skill-growth-stale-points');
            value.reason = profile.trainingPurchaseReason(row[2].skill,row[2]);
            if (value.reason != nil) return value;
            value.reason = profile.skillLearningWithTeacherReason(row[2].skill,row[5]);
            if (value.reason != nil) return value;
            local offer = new RpgDevelopment(); offer.profile = profile; offer.kind = 'skill';
            offer.training = row[2]; offer.teacher = row[5]; offer.target = row[4];
            value.reason = profile.developmentOfferReason(offer);
            if (value.reason != nil) return value;
            ids = ids + [row[1]]; slots = slots + [row[2]];
        }
        if (ids.length() != self.growth.improvements.length()) rpgExpandedReject('dependent-skill-growth-incomplete');
        rpgInteger(profile.developmentRevision,0,2147483646);
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local profile = self.profile(); self.boundDefinition = self.definition();
        foreach (local row in self.purchases) row[2].points = row[4];
        profile.developmentRevision += 1; self.recorded = true;
        profile.dependentSkillGrowthApplications = profile.dependentSkillGrowthApplications + [self];
        value.status = 'resolved'; return value;
    }
;

/** Authored group membership snapshot; membership does not multiply point credit. */
class RpgExpandedDependentRoster: object
    relationship = nil
    members = []
    approved = nil
    evidence = nil
    definition()
    {
        return [self.relationship,self.approved,self.evidence,self.members.length()] + self.members
            + self.relationship.definition();
    }
    validate(profile)
    {
        if (self.relationship == nil || !self.relationship.ofKind(RpgExpandedDependent)
            || !self.relationship.group || self.relationship.owner != profile
            || !holds(profile.contributions,self.relationship)) rpgExpandedReject('dependent-roster-owner');
        if (!self.approved || self.evidence == nil || self.evidence == '' || self.members.length() == 0)
            rpgExpandedReject('dependent-roster-facts');
        local seen = [];
        foreach (local member in self.members)
        {
            if (member == nil || member == profile || member == self.relationship.dependent || holds(seen,member))
                rpgExpandedReject('dependent-roster-member');
            seen = seen + [member];
        }
        return nil;
    }
;
/** B131: member-specific outcomes reduce to the ordinary session award gate. */
class RpgExpandedDependentGroupSession: RpgExpandedDependentSession
    rosters = []
    /* [roster, member, peril, prompt aid, serious harm, deny bonus, evidence] */
    memberOutcomes = []
    definition()
    {
        local facts = inherited() + [self.rosters.length(),self.memberOutcomes.length()];
        foreach (local roster in self.rosters) facts = facts + [roster] + roster.definition();
        foreach (local row in self.memberOutcomes) facts = facts + row;
        return facts;
    }
    assess()
    {
        local value = inherited(); if (value.status != 'ready') return value;
        local relationships = [];
        foreach (local roster in self.rosters)
        {
            if (roster == nil || !roster.ofKind(RpgExpandedDependentRoster)) rpgExpandedReject('dependent-group-roster');
            roster.validate(self.profile);
            if (holds(relationships,roster.relationship)) rpgExpandedReject('dependent-group-duplicate-roster');
            relationships = relationships + [roster.relationship];
            local seen = []; local peril = nil; local missedAid = nil; local harm = nil; local denied = nil;
            foreach (local row in self.memberOutcomes)
            {
                if (row.length() != 7 || !holds(self.rosters,row[1]) || row[7] == nil || row[7] == '')
                    rpgExpandedReject('dependent-group-member-outcome');
                if (row[1] != roster) continue;
                if (!holds(roster.members,row[2]) || holds(seen,row[2])) rpgExpandedReject('dependent-group-member-outcome');
                if (row[6] && (!row[3] || row[4])) rpgExpandedReject('dependent-group-bonus-judgment');
                seen = seen + [row[2]];
                if (row[3]) peril = true;
                if (row[3] && !row[4]) missedAid = true;
                if (row[5]) harm = true;
                if (row[6]) denied = true;
            }
            if (seen.length() != roster.members.length()) rpgExpandedReject('dependent-group-missing-member');
            local summary = nil;
            foreach (local row in self.outcomes) if (row[1] == roster.relationship) summary = row;
            if (summary == nil || (summary[2] ? 1 : 0) != (peril ? 1 : 0)
                || (summary[3] ? 1 : 0) != (peril && !missedAid ? 1 : 0)
                || (summary[4] ? 1 : 0) != (harm ? 1 : 0) || (summary[5] ? 1 : 0) != (denied ? 1 : 0))
                rpgExpandedReject('dependent-group-summary');
        }
        foreach (local row in self.outcomes)
            if (row[1].group && !holds(relationships,row[1])) rpgExpandedReject('dependent-group-missing-roster');
        if (self.rosters.length() == 0 && self.memberOutcomes.length() != 0)
            rpgExpandedReject('dependent-group-member-outcome');
        return value;
    }
;


modify RpgExpandedDependent
    loss = nil
    retiredBy = nil
;
modify RpgExpandedProfile
    dependentLosses = []
    dependentLossSettlements = []
;
/** B131 permanent removal and the historically awarded credit to replace. */
class RpgExpandedDependentLoss: object
    relationship = nil
    session = nil
    disposition = nil
    entireGroupUnavailable = nil
    originalBonus = nil
    approved = nil
    evidence = nil
    bonusEvidence = nil
    recorded = nil
    boundDefinition = nil
    bonus()
    {
        local captured = self.relationship.owner.originalContributionBonus(self.relationship);
        if (captured != nil)
        {
            if (self.originalBonus != nil && self.originalBonus != captured) rpgExpandedReject('dependent-loss-original-credit-mismatch');
            return captured;
        }
        rpgInteger(self.originalBonus,0,1000000); return self.originalBonus;
    }
    definition()
    {
        return [self.relationship,self.session,self.disposition,self.entireGroupUnavailable,self.originalBonus,
            self.approved,self.evidence,self.bonusEvidence] + self.relationship.definition();
    }
    assess()
    {
        local value = new RpgExpandedResult();
        if (self.relationship == nil || !self.relationship.ofKind(RpgExpandedDependent))
            rpgExpandedReject('dependent-loss-relationship');
        local profile = self.relationship.owner;
        if (profile == nil || !profile.ofKind(RpgExpandedProfile)) rpgExpandedReject('dependent-loss-owner');
        if (self.recorded)
        {
            if (self.relationship.loss != self || !holds(profile.dependentLosses,self)) rpgExpandedReject('dependent-loss-history');
            local facts = self.definition();
            if (self.boundDefinition == nil || facts.length() != self.boundDefinition.length()) rpgExpandedReject('dependent-loss-binding');
            for (local index = 1; index <= facts.length(); index += 1)
                if (facts[index] != self.boundDefinition[index]) rpgExpandedReject('dependent-loss-binding');
            value.status = 'reused'; value.points = self.bonus(); return value;
        }
        if (self.boundDefinition != nil || self.relationship.loss != nil || self.relationship.retiredBy != nil)
            rpgExpandedReject('dependent-loss-duplicate');
        rpgExpandedValidate(profile);
        if (!holds(profile.contributions,self.relationship)) rpgExpandedReject('dependent-loss-owner');
        local bonus = self.bonus();
        if (!self.relationship.credited && bonus != 0) rpgExpandedReject('dependent-loss-uncredited-bonus');
        if (self.session == nil) rpgExpandedReject('dependent-loss-session-required');
        if (!holds(['dead','permanently-incapacitated'],self.disposition)) rpgExpandedReject('dependent-loss-disposition');
        if (self.relationship.group && !self.entireGroupUnavailable) rpgExpandedReject('dependent-loss-group-still-present');
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'dependent-loss-adjudication-required'; return value; }
        if (profile.originalContributionBonus(self.relationship) == nil && (self.bonusEvidence == nil || self.bonusEvidence == ''))
        { value.reason = 'dependent-loss-original-credit-evidence-required'; return value; }
        value.points = bonus; value.status = 'ready'; return value;
    }
    record()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.boundDefinition = self.definition(); self.recorded = true; self.relationship.loss = self;
        self.relationship.owner.dependentLosses = self.relationship.owner.dependentLosses + [self];
        value.status = 'resolved'; return value;
    }
;
class RpgExpandedDependentLossBuyoff: object
    loss = nil
    recorded = nil
    boundLoss = nil
    boundPoints = nil
    assess()
    {
        local value = new RpgExpandedResult();
        if (self.loss == nil || !self.loss.ofKind(RpgExpandedDependentLoss) || self.loss.assess().status != 'reused')
            rpgExpandedReject('dependent-loss-buyoff-record');
        local relationship = self.loss.relationship; local profile = relationship.owner;
        if (self.recorded)
        {
            if (self.boundLoss != self.loss || self.boundPoints != self.loss.bonus() || relationship.retiredBy != self
                || !holds(profile.dependentLossSettlements,self)) rpgExpandedReject('dependent-loss-buyoff-binding');
            value.status = 'reused'; return value;
        }
        if (self.boundLoss != nil || self.boundPoints != nil || relationship.retiredBy != nil)
            rpgExpandedReject('dependent-loss-buyoff-duplicate');
        if (!holds(profile.contributions,relationship)) rpgExpandedReject('dependent-loss-buyoff-owner');
        value.points = self.loss.bonus();
        rpgInteger(profile.unspentPoints,0,1000000); rpgInteger(profile.developmentRevision,0,2147483646);
        if (profile.unspentPoints < value.points) { value.reason = 'rpg.insufficient-points'; return value; }
        value.reason = profile.developmentSpendingReason(); if (value.reason != nil) return value;
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local relationship = self.loss.relationship; local profile = relationship.owner;
        self.boundLoss = self.loss; self.boundPoints = value.points; self.recorded = true;
        profile.unspentPoints -= value.points; profile.developmentRevision += 1;
        relationship.retiredBy = self; profile.dependentLossSettlements = profile.dependentLossSettlements + [self];
        value.status = 'resolved'; return value;
    }
;


/** B131 author-approved replacement carrying the original outstanding credit. */
class RpgExpandedDependentReplacement: object
    loss = nil
    replacement = nil
    approved = nil
    evidence = nil
    recorded = nil
    boundDefinition = nil
    boundPoints = nil
    basis = nil
    definition()
    {
        return [self.loss,self.replacement,self.approved,self.evidence] + self.replacement.definition();
    }
    validateContributionBasis(candidate)
    {
        if (candidate != self.basis || !self.recorded || candidate.creationReceipt != self
            || candidate.owner != self.loss.relationship.owner || candidate.contribution != self.replacement
            || candidate.originalBonus != self.boundPoints
            || !holds(candidate.owner.contributionBuyoffBases,candidate)) rpgExpandedReject('dependent-replacement-basis');
        if (self.assess().status != 'reused') rpgExpandedReject('dependent-replacement-basis');
        return nil;
    }
    assess()
    {
        local value = new RpgExpandedResult();
        if (self.loss == nil || !self.loss.ofKind(RpgExpandedDependentLoss) || self.loss.assess().status != 'reused')
            rpgExpandedReject('dependent-replacement-loss');
        local old = self.loss.relationship; local profile = old.owner;
        if (self.replacement == nil || !self.replacement.ofKind(RpgExpandedDependent) || self.replacement == old
            || self.replacement.owner != profile) rpgExpandedReject('dependent-replacement-owner');
        if (self.recorded)
        {
            if (old.retiredBy != self || !holds(profile.dependentLossSettlements,self)
                || !holds(profile.contributions,self.replacement) || self.boundPoints != self.loss.bonus())
                rpgExpandedReject('dependent-replacement-history');
            if (self.basis == nil || self.basis.owner != profile || self.basis.contribution != self.replacement
                || self.basis.creationReceipt != self || self.basis.originalBonus != self.boundPoints
                || !holds(profile.contributionBuyoffBases,self.basis)) rpgExpandedReject('dependent-replacement-basis');
            local facts = self.definition();
            if (self.boundDefinition == nil || facts.length() != self.boundDefinition.length())
                rpgExpandedReject('dependent-replacement-binding');
            for (local index = 1; index <= facts.length(); index += 1)
                if (facts[index] != self.boundDefinition[index]) rpgExpandedReject('dependent-replacement-binding');
            value.status = 'reused'; return value;
        }
        if (self.boundDefinition != nil || self.boundPoints != nil || self.basis != nil || old.retiredBy != nil)
            rpgExpandedReject('dependent-replacement-duplicate');
        rpgExpandedValidate(profile);
        if (!holds(profile.contributions,old) || holds(profile.contributions,self.replacement)
            || self.replacement.loss != nil || self.replacement.retiredBy != nil
            || self.replacement.growthHistory.length() != 0) rpgExpandedReject('dependent-replacement-existing-history');
        if (self.replacement.dependent == old.dependent) rpgExpandedReject('dependent-replacement-same-identity');
        self.replacement.validate(profile);
        value.points = self.loss.bonus();
        if (!self.replacement.credited || -self.replacement.cost() != value.points || value.points == 0)
            rpgExpandedReject('dependent-replacement-credit');
        local slots = self.replacement.group ? 2 : 1;
        foreach (local entry in profile.contributions)
        {
            if (entry.id == self.replacement.id) rpgExpandedReject('dependent-replacement-duplicate-id');
            if (entry != old && entry.ofKind(RpgExpandedDependent) && entry.retiredBy == nil && entry.credited)
                slots += entry.group ? 2 : 1;
        }
        if (slots > 2) rpgExpandedReject('dependent-credit-slots');
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'dependent-replacement-story-approval-required'; return value; }
        rpgInteger(profile.developmentRevision,0,2147483646);
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local old = self.loss.relationship; local profile = old.owner;
        self.boundDefinition = self.definition(); self.boundPoints = value.points; self.recorded = true;
        old.retiredBy = self; profile.contributions = profile.contributions + [self.replacement];
        profile.dependentLossSettlements = profile.dependentLossSettlements + [self];
        local basis = new RpgExpandedContributionBasis(); basis.owner = profile; basis.contribution = self.replacement;
        basis.originalBonus = value.points; basis.creationReceipt = self; self.basis = basis;
        profile.contributionBuyoffBases = profile.contributionBuyoffBases + [basis];
        profile.developmentRevision += 1; value.status = 'resolved'; return value;
    }
;

/** B131 an approved replacement disadvantage, supported through installed trait adapters. */
class RpgExpandedDependentTraitReplacement: object
    loss = nil
    trait = nil
    approved = nil
    evidence = nil
    recorded = nil
    boundDefinition = nil
    boundPoints = nil
    basis = nil
    definition()
    {
        return [self.loss,self.trait,self.approved,self.evidence]
            + self.loss.relationship.owner.dependentReplacementTraitFacts(self.trait);
    }
    validateOriginalBasis(candidate)
    {
        if (candidate != self.basis || !self.recorded || candidate.owner != self.loss.relationship.owner
            || candidate.trait != self.trait || candidate.originalBonus != self.boundPoints
            || candidate.creationReceipt != self || !holds(candidate.owner.buyoffBases,candidate))
            rpgExpandedReject('dependent-replacement-trait-basis');
        self.assess(); return nil;
    }
    assess()
    {
        local value = new RpgExpandedResult();
        if (self.loss == nil || !self.loss.ofKind(RpgExpandedDependentLoss) || self.loss.assess().status != 'reused'
            || self.trait == nil || !self.trait.ofKind(RpgLiteTrait)) rpgExpandedReject('dependent-replacement-trait-definition');
        local profile = self.loss.relationship.owner;
        if (self.recorded)
        {
            if (self.loss.relationship.retiredBy != self || !holds(profile.dependentLossSettlements,self)
                || self.boundPoints != self.loss.bonus() || self.basis == nil || self.basis.owner != profile
                || self.basis.trait != self.trait || self.basis.originalBonus != self.boundPoints
                || self.basis.creationReceipt != self || !holds(profile.buyoffBases,self.basis))
                rpgExpandedReject('dependent-replacement-trait-history');
            local facts = self.definition();
            if (self.boundDefinition == nil || facts.length() != self.boundDefinition.length())
                rpgExpandedReject('dependent-replacement-trait-binding');
            for (local index = 1; index <= facts.length(); index += 1)
                if (facts[index] != self.boundDefinition[index]) rpgExpandedReject('dependent-replacement-trait-binding');
            value.status = 'reused'; return value;
        }
        if (self.boundDefinition != nil || self.boundPoints != nil || self.basis != nil || self.loss.relationship.retiredBy != nil)
            rpgExpandedReject('dependent-replacement-trait-duplicate');
        rpgExpandedValidate(profile);
        if (!holds(profile.contributions,self.loss.relationship)) rpgExpandedReject('dependent-replacement-trait-owner');
        for (local owner = firstObj(RpgLiteProfile); owner != nil; owner = nextObj(owner,RpgLiteProfile))
            if (holds(owner.traits,self.trait)) rpgExpandedReject('dependent-replacement-trait-already-owned');
        foreach (local prior in profile.buyoffBases)
            if (prior.trait == self.trait) rpgExpandedReject('dependent-replacement-trait-existing-basis');
        profile.validateDependentReplacementTrait(self.trait);
        local offer = new RpgDevelopment(); offer.profile = profile; offer.kind = 'trait'; offer.trait = self.trait;
        value.reason = profile.developmentOfferReason(offer); if (value.reason != nil) return value;
        value.points = self.loss.bonus();
        if (value.points == 0 || self.trait.creationCost() != -value.points) rpgExpandedReject('dependent-replacement-trait-credit');
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'dependent-replacement-trait-story-required'; return value; }
        rpgInteger(profile.developmentRevision,0,2147483646); value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local profile = self.loss.relationship.owner;
        self.boundDefinition = self.definition(); self.boundPoints = value.points; self.recorded = true;
        self.loss.relationship.retiredBy = self; profile.traits = profile.traits + [self.trait];
        profile.dependentLossSettlements = profile.dependentLossSettlements + [self];
        local basis = new RpgExpandedBuyoffBasis(); basis.owner = profile; basis.trait = self.trait;
        basis.originalBonus = value.points; basis.creationReceipt = self; basis.approved = true; basis.evidence = self.evidence;
        self.basis = basis; profile.buyoffBases = profile.buyoffBases + [basis];
        profile.developmentRevision += 1; value.status = 'resolved'; return value;
    }
;


/** Full cultural standing for the included wardrobe, B266. Keep this adapter
 * here so campaign equipment does not require the social catalogue. */
modify RpgExpandedProfile
    initialWardrobeStanding(culture,structure)
    {
        if (structure == nil || !structure.ofKind(RpgExpandedSocialStructure)
            || culture == nil || structure.culture != culture)
            rpgExpandedReject('initial-wardrobe-social-structure');
        local level = structure.standingFor(self);
        rpgInteger(level,-2,8); return level;
    }
;

class RpgExpandedLieDetectionResult: RpgExpandedResult
    observerScore = nil
    subjectScore = nil
    conclusion = nil
;

/** B187 private opposed assessment. Truth and modifier facts are authored. */
class RpgExpandedLieDetection: object
    id = nil
    observer = nil
    subject = nil
    skill = nil
    defenseSkill = nil
    statement = nil
    truthKnown = nil
    subjectLying = nil
    failureConclusion = 'uncertain'
    empathyModifier = 0
    easyToRead = nil
    speciesModifier = 0
    approved = nil
    evidence = nil
    boundDefinition = nil
    result = nil
    boundConclusion = nil
    disclosure = nil
    definition()
    {
        return [self.id,self.observer,self.subject,self.skill,self.defenseSkill,self.statement,self.truthKnown,
            self.subjectLying,self.failureConclusion,self.empathyModifier,self.easyToRead,self.speciesModifier,self.approved,self.evidence];
    }
    validateReceipt()
    {
        if (self.result == nil || self.boundDefinition == nil || !holds(self.observer.lieDetections,self))
            rpgExpandedReject('lie-detection-history');
        local facts = self.definition();
        for (local i = 1; i <= facts.length(); i += 1)
            if (facts[i] != self.boundDefinition[i]) rpgExpandedReject('lie-detection-binding');
        if (self.result.conclusion != self.boundConclusion) rpgExpandedReject('lie-detection-conclusion-binding');
        return nil;
    }
    validateReadingSkill() { return self.skill.validateLieDetection(); }
    readingConditions()
    {
        local value = new RpgExpandedResult(); value.status = 'ready'; return value;
    }
    assess()
    {
        local value = new RpgExpandedLieDetectionResult();
        if (self.result != nil)
        {
            self.validateReceipt();
            value.status = 'reused'; return value;
        }
        if (self.id == nil || self.id == '' || self.observer == nil || !self.observer.ofKind(RpgExpandedProfile)
            || self.subject == nil || !self.subject.ofKind(RpgLiteProfile) || self.observer == self.subject
            || self.skill == nil || !self.skill.ofKind(RpgLiteSkill)) rpgExpandedReject('lie-detection-definition');
        self.validateReadingSkill();
        if (!self.approved || !self.truthKnown || self.statement == nil || self.statement == '' || self.evidence == nil || self.evidence == '')
        { value.reason = 'lie-detection-authored-facts-required'; return value; }
        if (self.observer.dead || self.subject.dead || self.observer.unconscious || self.subject.unconscious)
        { value.reason = 'lie-detection-participant-unavailable'; return value; }
        if (!holds(['uncertain','lying','truthful'],self.failureConclusion) || !holds([-3,0,1,3],self.empathyModifier))
            rpgExpandedReject('lie-detection-modifiers');
        rpgInteger(self.speciesModifier,-100,0);
        foreach (local prior in self.observer.lieDetections)
            if (prior.id == self.id || prior.subject == self.subject && prior.statement == self.statement)
                rpgExpandedReject('lie-detection-repeat-statement');
        local conditions = self.readingConditions();
        if (conditions.status != 'ready') { value.reason = conditions.reason; return value; }
        local reading = new RpgLiteContext(); reading.skill = self.skill; reading.kind = 'lie-detection';
        reading.modifier = self.empathyModifier + (self.easyToRead ? 4 : 0) + self.speciesModifier + conditions.modifier;
        local defense = new RpgLiteContext(); defense.attribute = rpgIQ; defense.kind = 'lie-detection-defense';
        if (self.defenseSkill != nil)
        {
            if (!self.defenseSkill.ofKind(RpgLiteSkill) || !holds(['fast-talk','acting'],self.defenseSkill.id)
                || self.defenseSkill.attribute != rpgIQ || self.defenseSkill.difficulty != 1)
                rpgExpandedReject('lie-detection-defense-skill');
            defense.skill = self.defenseSkill;
        }
        value.observerScore = rpgLiteScore(self.observer,reading); value.subjectScore = rpgLiteScore(self.subject,defense);
        if (value.observerScore == nil || value.subjectScore == nil || value.observerScore < 3 || value.subjectScore < 3)
        { value.reason = 'lie-detection-score-unavailable'; return value; }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        value.check = rpgEvaluate(value.observerScore,rpgRandom.roll(),value.subjectScore,rpgRandom.roll(),0);
        value.conclusion = value.check.achieved ? (self.subjectLying ? 'lying' : 'truthful') : self.failureConclusion;
        self.boundConclusion = value.conclusion; self.boundDefinition = self.definition(); value.status = 'resolved'; self.result = value;
        self.observer.lieDetections = self.observer.lieDetections + [self]; return value;
    }
;
modify RpgExpandedProfile
    lieDetections = []
;

/** Disclose only the observer's impression, never establish its truth as belief. */
class RpgExpandedLieDetectionDisclosure: object
    id = nil
    assessment = nil
    recipient = nil
    lyingStatement = nil
    truthfulStatement = nil
    uncertainStatement = nil
    completedAt = nil
    boundDefinition = nil
    boundKnowledge = nil
    boundStatement = nil
    definition()
    { return [self.id,self.assessment,self.recipient,self.lyingStatement,self.truthfulStatement,self.uncertainStatement]; }
    assess()
    {
        local value = new RpgExpandedInformationDeliveryResult();
        if (self.id == nil || self.id == '' || self.assessment == nil || !self.assessment.ofKind(RpgExpandedLieDetection)
            || self.recipient == nil || !self.recipient.ofKind(RpgExpandedProfile) || self.recipient.knowledge == nil
            || !self.recipient.knowledge.ofKind(RpgExpandedKnowledge)) rpgExpandedReject('lie-disclosure-definition');
        if (self.assessment.result == nil) { value.reason = 'lie-disclosure-unresolved'; return value; }
        self.assessment.validateReceipt(); self.recipient.knowledge.validate();
        if (self.recipient != self.assessment.observer) { value.reason = 'lie-disclosure-observer-required'; return value; }
        if (self.completedAt != nil)
        {
            local facts = self.definition();
            for (local i = 1; i <= facts.length(); i += 1)
                if (facts[i] != self.boundDefinition[i]) rpgExpandedReject('lie-disclosure-binding');
            if (self.boundKnowledge != self.recipient.knowledge || self.assessment.disclosure != self)
                rpgExpandedReject('lie-disclosure-binding');
            local count = 0;
            foreach (local row in self.boundKnowledge.received)
                if (row[1] == self.id)
                {
                    if (row[2] != self.assessment.observer || row[3].length() != 1
                        || row[3][1] != self.boundStatement || row[4] != 0) rpgExpandedReject('lie-disclosure-history');
                    count += 1;
                }
            if (count != 1) rpgExpandedReject('lie-disclosure-history');
            value.status = 'reused'; return value;
        }
        if (self.assessment.disclosure != nil) { value.reason = 'lie-disclosure-already-recorded'; return value; }
        if (self.lyingStatement == nil || self.truthfulStatement == nil || self.uncertainStatement == nil)
        { value.reason = 'lie-disclosure-statements-required'; return value; }
        foreach (local row in self.recipient.knowledge.received)
            if (row[1] == self.id) rpgExpandedReject('lie-disclosure-duplicate');
        value.status = 'ready'; return value;
    }
    deliver()
    {
        local value = self.assess();
        if (value.status == 'reused') { value.statements = [self.boundStatement]; return value; }
        if (value.status != 'ready') return value;
        self.boundDefinition = self.definition(); self.boundKnowledge = self.recipient.knowledge;
        local conclusion = self.assessment.result.conclusion;
        self.boundStatement = conclusion == 'lying' ? self.lyingStatement
            : conclusion == 'truthful' ? self.truthfulStatement : self.uncertainStatement;
        value.statements = [self.boundStatement];
        self.boundKnowledge.received = self.boundKnowledge.received + [[self.id,self.assessment.observer,value.statements,0]];
        self.completedAt = rpgLedger.seconds; self.assessment.disclosure = self;
        value.status = 'resolved'; return value;
    }
;

/** B181 visual lie inference. Combat feints and emotion inference are distinct. */
class RpgExpandedBodyReadingLieDetection: RpgExpandedLieDetection
    visible = nil
    bodyVisible = true
    concealment = 'none'
    coverPenalty = -2
    visionModifier = 0
    physiology = 'same'
    combat = nil
    visualEvidence = nil
    validateReadingSkill() { return self.skill.validateBodyReading(); }
    definition()
    {
        return inherited() + [self.visible,self.bodyVisible,self.concealment,self.coverPenalty,
            self.visionModifier,self.physiology,self.combat,self.visualEvidence];
    }
    readingConditions()
    {
        local value = new RpgExpandedResult();
        if (self.combat) { value.reason = 'body-reading-use-combat-feint'; return value; }
        if (!self.visible || self.visualEvidence == nil || self.visualEvidence == '')
        { value.reason = 'body-reading-visible-subject-required'; return value; }
        if (!holds(['none','baggy','shield','cloak','mask'],self.concealment)
            || !holds(['same','similar','different','alien','machine'],self.physiology))
            rpgExpandedReject('body-reading-conditions');
        if (self.physiology == 'machine') { value.reason = 'body-reading-machine-inapplicable'; return value; }
        if (self.physiology == 'same' && self.speciesModifier != 0
            || self.physiology == 'similar' && !holds([-2,-3,-4],self.speciesModifier)
            || self.physiology == 'different' && self.speciesModifier != -5
            || self.physiology == 'alien' && self.speciesModifier > -6)
            rpgExpandedReject('body-reading-physiology');
        if (self.empathyModifier != 0) rpgExpandedReject('body-reading-empathy-modifier-unsupported');
        if (self.concealment == 'mask' && !self.bodyVisible)
        { value.reason = 'body-reading-mask-no-body'; return value; }
        rpgInteger(self.visionModifier,-100,100); rpgInteger(self.coverPenalty,-4,-2);
        value.modifier = self.visionModifier + (self.concealment == 'baggy' ? -1 : self.concealment == 'mask' ? -5
            : holds(['shield','cloak'],self.concealment) ? self.coverPenalty : 0);
        value.status = 'ready'; return value;
    }
;
