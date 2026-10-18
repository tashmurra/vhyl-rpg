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
    rating()
    {
        self.validate();
        if (!self.initialized) rpgExpandedReject('loyalty-uninitialized');
        local value = self.base;
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
        value.rating = self.base; value.check = self.initialRoll; return value;
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
