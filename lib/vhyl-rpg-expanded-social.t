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
        local count = self.waitedReasonably ? 0 : self.encounter.nuisanceCount;
        if (self.encounter.history.length() > 0 && self.nuisance && !self.waitedReasonably) count += 1;
        if (self.encounter.predeterminedBand != nil) value.band = self.encounter.predeterminedBand;
        else
        {
            value.check = rpgRandom.roll(); value.total = value.check + self.modifier - count * 2;
            value.band = rpgExpandedReactionBand(value.total);
            if (value.band < self.encounter.worstBand) value.band = self.encounter.worstBand;
            if (value.band > self.encounter.bestBand) value.band = self.encounter.bestBand;
        }
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
    means = 'ordinary'
    modifier = 0
    startedAt = nil
    completedAt = nil
    boundDefinition = nil
    result = nil
    definition()
    {
        return [self.id,self.session,self.question,self.truthfulAnswer,self.falseAnswer,self.failureResponse,
            self.approved,self.evidence,self.loyaltyResists,self.means,self.modifier] + self.session.definition();
    }
    validateReceipt()
    {
        local current = self.definition();
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
        if (self.means != 'ordinary') value.modifier += (self.means == 'torture' ? 6 : 3) + (actor.level('callous') > 0 ? 1 : 0);
        local context = new RpgLiteContext(); context.skill = self.session.skill; context.kind = 'interrogation';
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
