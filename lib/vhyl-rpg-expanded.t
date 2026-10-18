/* Include after core, progression and the Lite umbrella. */

/** Expanded configuration error with a stable, author-readable reason. */
class RpgExpandedError: RpgError
    reason = 'invalid-expanded-configuration'
;

/** Raise an expanded configuration error before committing an operation. */
rpgExpandedReject(reason)
{
    local error = new RpgExpandedError(); error.reason = reason; throw error;
}

/** Per-campaign options. Merely including a module never enables these options. */
class RpgExpandedRules: object
    exceptionalCharacteristics = nil
    wildcardSkills = nil
    cinematicInstantTasks = nil
;

/** Expanded profile; keeps the inherited injury, fatigue, inventory and point ledgers.
 * Profiles may share immutable campaign rules; contribution instances are owned. */
class RpgExpandedProfile: RpgLiteProfile
    rules = nil
    contributions = []
    nativePressureHundredths = 100
    pressureSupportLevel() { return 0; }
    ancestrySkillModifier(skill) { return 0; }
    studyTimePercent(skill) { return 100; }
    catalogueTalentSkills(id) { return []; }
    catalogueTalentApplies(id,skill)
    { return skill != nil && skill.ofKind(RpgLiteSkill) && holds(self.catalogueTalentSkills(id),skill.studyIdentity()); }
    catalogueTalentSkillModifier(skill) { return 0; }
    talentBonusInSkillScore() { return nil; }
    /* Character module supplies creation-budget assessment for cash exchanges. */
    creationMoneyReason(points) { return 'creation-money-accounting-unavailable'; }
    validateFeatures() { return nil; }
    physicalDangerFearPenalty() { return nil; }
    onBodySupportLost(part) { return nil; }
    supportReserved(part) { return nil; }
    reservedLiftingHandsReason(hands) { return nil; }
    postCreationDisadvantageAllowance() { return 0; }
    /* Equipment module supplies concrete forced-drop handling when installed. */
    prepareKnockdownDrop(destination)
    {
        foreach (local item in self.equipment)
            if (item.ready && !item.worn)
            {
                local value = new RpgExpandedResult(); value.reason = 'expanded-wound-drop-unavailable';
                return value;
            }
        return nil;
    }
    /* Optional equipment supplies committed storage for anatomy-forced drops. */
    prepareForcedDrop(items, destination)
    {
        if (items.length() == 0) return nil;
        local value = new RpgExpandedResult(); value.reason = 'expanded-wound-drop-unavailable';
        return value;
    }
    hpAdjustment = 0
    fpAdjustment = 0
    willAdjustment = 0
    perceptionAdjustment = 0
    speedQuarterAdjustment = 0
    moveAdjustment = 0
    maxHP = (st + hpAdjustment)
    maxEnergy = (ht + fpAdjustment)
    will = (iq + willAdjustment)
    perception = (iq + perceptionAdjustment)
    basicSpeedQuarters() { return self.dx + self.ht + self.speedQuarterAdjustment; }
    basicMove() { return self.basicSpeedQuarters() / 4 + self.moveAdjustment; }
;

/** Owned point contribution from an optional subsystem; cost queries are pure. */
class RpgExpandedContribution: object
    templateCopy(profile) { rpgExpandedReject('template-contribution-unsupported'); }
    templateCost() { rpgExpandedReject('template-contribution-cost-unsupported'); }
    id = nil
    owner = nil
    amounts(profile) { return []; }
    wealthStatusBonus() { return 0; }
    validate(profile) { return nil; }
;

/** Operation receipt. Blocked operations have a reason and spend nothing. */
class RpgExpandedResult: object
    status = 'blocked'
    reason = nil
    points = 0
    seconds = 0
    check = nil
    modifier = 0
;

/** Validate the foundation contract without requiring any optional module. */
rpgExpandedValidate(profile)
{
    if (profile == nil || !profile.ofKind(RpgExpandedProfile)
        || profile.rules == nil || !profile.rules.ofKind(RpgExpandedRules))
        rpgExpandedReject('profile-or-rules');
    rpgInteger(profile.nativePressureHundredths,1,100000);
    profile.validateFeatures();
    local ids = [];
    foreach (local contribution in profile.contributions)
    {
        if (!contribution.ofKind(RpgExpandedContribution) || contribution.owner != profile
            || contribution.id == nil || holds(ids, contribution.id))
            rpgExpandedReject('contribution-ownership');
        ids = ids + [contribution.id]; contribution.validate(profile);
    }
    return true;
}

modify RpgExpandedProfile
    prepareTechnologyWound(id, amount, destination) { return nil; }
;

modify RpgExpandedProfile
    inventionCapabilityTier() { return nil; }
;

/** Full-reference damage rows, with B15's full-ten-point progression above 100.
 * Missing intermediate rows between 40 and 100 remain explicitly unsupported. */
rpgExpandedDamageDice(strength, swing)
{
    rpgInteger(strength, 1, 1000);
    if (strength > 100) return [(swing ? 13 : 11) + (strength - 100) / 10, 0];
    if (strength <= 20) return rpgLiteDamageDice(strength, swing);
    local rows = [
        [21,2,0,4,-1],[22,2,0,4,0],[23,2,1,4,1],[24,2,1,4,2],
        [25,2,2,5,-1],[26,2,2,5,0],[27,3,-1,5,1],[28,3,-1,5,1],
        [29,3,0,5,2],[30,3,0,5,2],[31,3,1,6,-1],[32,3,1,6,-1],
        [33,3,2,6,0],[34,3,2,6,0],[35,4,-1,6,1],[36,4,-1,6,1],
        [37,4,0,6,2],[38,4,0,6,2],[39,4,1,7,-1],[40,4,1,7,-1],
        [45,5,0,7,1],[50,5,2,8,-1],[55,6,0,8,1],[60,7,-1,9,0],
        [65,7,1,9,2],[70,8,0,10,0],[75,8,2,10,2],[80,9,0,11,0],
        [85,9,2,11,2],[90,10,0,12,0],[95,10,2,12,2],[100,11,0,13,0]];
    foreach (local row in rows)
        if (row[1] == strength) return swing ? [row[4],row[5]] : [row[2],row[3]];
    rpgExpandedReject('unsupported-strength-row'); return nil;
}


modify RpgExpandedProfile
    prepareSwarmWound(id, amount, destination) { return nil; }
;

/** Optional trait-module contract; the foundation alone cannot award a quirk. */
class RpgExpandedFearQuirkContract: object
    profile = nil
    eventId = nil
    assess()
    {
        local value = new RpgExpandedResult(); value.reason = 'fear-quirk-module-required'; return value;
    }
    apply() { return self.assess(); }
;

modify RpgExpandedProfile
    radiationDivisor() { return 1; }
;

/** Equipment-to-skill technology difference, B168. nil means impossible,
 * rather than an arbitrarily large numeric penalty. No familiarity is included. */
rpgExpandedTechnologyModifier(skillTL, equipmentTL, cognitive)
{
    rpgInteger(skillTL, 0, 12); rpgInteger(equipmentTL, 0, 12);
    local difference = equipmentTL - skillTL;
    if (!cognitive) return difference < 0 ? difference : -difference;
    if (difference >= 4) return nil;
    if (difference > 0) return -5 * difference;
    if (difference == 0) return 0;
    return 2 * difference + 1;
}


/** Optional trait module resolves explicit rated template purchases. */
rpgExpandedTemplateTraits: object
    plain(id,level,scope) { return rpgLiteMakeTrait(id,level,scope); }
    copy(trait)
    {
        return trait.templatePurchaseKind == 'shared-catalogue'
            ? self.plain(trait.labelId,trait.level,trait.scope)
            : self.rated(trait.labelId,trait.level,trait.scope,trait.selfControlNumber());
    }
    rated(id, level, scope, rating)
    { rpgExpandedReject('template-rated-trait-unavailable'); }
;

/** A concrete resolved communication, validated by its owning procedure.
 * It is private adjudication data; delivery reveals only its statement. */
class RpgExpandedStatementReceipt: object
    source = nil
    speaker = nil
    statement = nil
    kind = nil
    deliveries = []
    validate()
    {
        if (self.source == nil) rpgExpandedReject('statement-source');
        return self.source.validateStatementReceipt(self);
    }
;

/** Optional exploration supplies physical lifting assessment without an include cycle. */
rpgExpandedLiftingRules: object
    assessWithSkill(operation,attempt)
    { local value = new RpgExpandedResult(); value.reason = 'lifting-exploration-required'; return value; }
    assess(lift,weight,mode)
    { local value = new RpgExpandedResult(); value.reason = 'lifting-exploration-required'; return value; }
;
modify RpgExpandedProfile
    liftingHandsReason(hands,required)
    { return hands.length() == 0 ? nil : 'lifting-anatomy-required'; }
;

/** Concrete physical request used to bind a once-per-lift skill roll. */
class RpgExpandedLiftIdentity: object
    liftingDefinition() { rpgExpandedReject('lifting-identity-unimplemented'); }
    skillPreparationReason() { return 'lifting-identity-unimplemented'; }
;

rpgExpandedSharedCarryRules: object
    assess(carry)
    { local value = new RpgExpandedResult(); value.reason = 'shared-carry-exploration-required'; return value; }
;

/** Extended whole-yard speed/range lookup, rounding up to the next row.
 * Numeric support is bounded to 100 million yards to prevent integer overflow. */
rpgExpandedRangeModifier(yards)
{
    rpgInteger(yards, 0, 100000000);
    if (yards <= 2) return 0;
    local row = 0; local factor = 1;
    while (factor <= 100000000)
    {
        foreach (local limit in [3, 5, 7, 10, 15, 20])
        {
            row += 1;
            if (yards <= limit * factor) return -row;
        }
        factor *= 10;
    }
    throw new RpgError();
}


/** Cross-module receipt contract; concrete landing attempts live in exploration. */
class RpgExpandedLandingReceipt: object
    impactFor(profile,fall) { rpgExpandedReject('landing-receipt-unavailable'); }
;

modify RpgLiteItem
    throwingHandsReason(profile, required) { return 'throwing-anatomy-required'; }
;

modify RpgExpandedProfile
    prepareThrowGate(id,evidence) { return nil; }
;

class RpgExpandedThrowReleaseFacts: RpgExpandedResult
    profile = nil
    item = nil
    weight = nil
;
class RpgExpandedThrowReceipt: object
    releaseAssessment() { local value = new RpgExpandedThrowReleaseFacts(); value.reason = 'throw-release-receipt-unavailable'; return value; }
;

class RpgExpandedThrownInjuryFacts: RpgExpandedResult
    profile = nil
    damage = 0
    damageType = 'cr'
;
class RpgExpandedThrownDamageReceipt: object
    injuryAssessment(side) { local value = new RpgExpandedThrownInjuryFacts(); value.reason = 'thrown-injury-receipt-unavailable'; return value; }
;

modify RpgExpandedProfile
    throwLocationReason(part,location) { return 'throw-location-anatomy-required'; }
;
modify RpgExpandedThrownInjuryFacts
    location = 'torso'
    bodyPart = nil
;

/** Supplied-dice combat check with ranged-miss and low-defense exceptions. */
rpgExpandedCombatCheck(kind, score, roll)
{
    if (!holds(['melee','ranged','defense'],kind)) rpgExpandedReject('combat-check-kind');
    rpgInteger(score,-1000,1000); rpgInteger(roll,3,18);
    if (kind != 'defense' && score < 3) return rpgCheck(score,roll);
    local value = rpgCheck(score < 3 ? 3 : score,roll);
    value.score = score; value.margin = score - roll;
    value.achieved = roll <= 4 || roll < 17 && roll <= score;
    value.rollSucceeded = value.achieved; value.critical = nil;
    if (value.achieved)
    {
        if (roll <= 4 || roll == 5 && score >= 15 || roll == 6 && score >= 16)
            value.critical = 'success';
    }
    else if (roll == 18 || roll == 17 && score <= 15 || kind != 'ranged' && roll - score >= 10)
        value.critical = 'failure';
    value.outcome = value.achieved ? 'success' : value.critical == 'failure' ? 'complication' : 'setback';
    return value;
}


modify RpgExpandedThrowReleaseFacts
    recipient = nil
    throwReceipt = nil
;
modify RpgExpandedThrowReceipt
    assessCatch(recipient,score,waiting)
    { local value = new RpgExpandedResult(); value.reason = 'catch-throw-receipt-unavailable'; return value; }
;
class RpgExpandedThrowFlightReceipt: object
    flightAssessment()
    { local value = new RpgExpandedThrowReleaseFacts(); value.reason = 'catch-flight-unavailable'; return value; }
;
modify RpgExpandedProfile
    catchHandReason(hand) { return 'catch-anatomy-required'; }
;

class RpgExpandedCatchFacts: RpgExpandedResult
    flight = nil
    recipient = nil
    hand = nil
;
class RpgExpandedCatchReceipt: object
    captureAssessment()
    { local value = new RpgExpandedCatchFacts(); value.reason = 'catch-receipt-unavailable'; return value; }
;

modify RpgExpandedProfile
    martialParryDivisor() { return 1; }
;

modify RpgExpandedProfile
    enhancedJumpLevels() { return 0; }
;

class RpgExpandedJumpPreparationReceipt: object
    available(fighter) { return 'jump-preparation-unavailable'; }
    record(fighter) { rpgExpandedReject('jump-preparation-unavailable'); }
    readyFor(profile) { return nil; }
;

class RpgExpandedJumpLaunchReceipt: object
    assess() { local value = new RpgExpandedResult(); value.reason = 'jump-launch-unavailable'; return value; }
    commit(value) { rpgExpandedReject('jump-launch-unavailable'); }
;

class RpgExpandedJumpFallPlan: object
    assessFor(profile,fall,velocity)
    { local value = new RpgExpandedResult(); value.reason = 'jump-fall-plan-unavailable'; return value; }
    applyFor(profile,fall,velocity) { rpgExpandedReject('jump-fall-plan-unavailable'); }
    validateResult(profile,fall,velocity) { rpgExpandedReject('jump-fall-plan-unavailable'); }
;

class RpgExpandedJumpPositionPlan: object
    definition() { return []; }
    assessFor(profile,occurrence,direction,distance)
    { local value = new RpgExpandedResult(); value.reason = 'jump-position-unavailable'; return value; }
    applyFor(profile,occurrence,direction,distance,succeeded) { rpgExpandedReject('jump-position-unavailable'); }
    validateResult(profile,occurrence,succeeded) { rpgExpandedReject('jump-position-unavailable'); }
;
modify RpgExpandedProfile
    jumpPositionRequired() { return nil; }
;

/** B352 ordinary obstacle threshold; significant hazards use the full procedure. */
rpgExpandedCanJumpAutomatically(actorSize, obstacleSize, significant)
{
    rpgInteger(actorSize,-20,20); rpgInteger(obstacleSize,-20,20);
    return !significant && obstacleSize <= actorSize - 3;
}

class RpgExpandedPathMoveReceipt: object
    assess() { local value = new RpgExpandedResult(); value.reason = 'path-move-unavailable'; return value; }
    commit(value) { rpgExpandedReject('path-move-unavailable'); }
;

modify RpgExpandedProfile
    prepareForageGate(id,evidence) { return nil; }
;

/** Equipment supplies the concrete fishing-tool assessment without a circular include. */
class RpgExpandedForageTools: object
    assessForProfile(profile,skill) { return self.assessFor(skill); }
    definition() { return []; }
    assessFor(skill)
    { local value = new RpgExpandedResult(); value.reason = 'forage-tools-adapter-required'; return value; }
    configure(context) { rpgExpandedReject('forage-tools-adapter-required'); }
;

/** Shared inventory unit: one ordinary meal per quantity, using the existing item ledger. */
class RpgExpandedFoodStock: RpgLiteItem
    validateMealStock() { rpgInteger(self.quantity,0,1000000); return nil; }
    foodKind = nil
    preserved = nil
    smokingBatch = nil
    usableBy(profile) { return self.smokingBatch == nil && inherited(profile); }
    quantity = 0
    readyToEat = nil
    preparationEvidence = nil
    gatheredFrom = nil
;
/** Owned forage source contract; exploration validates the actual recorded roll. */
class RpgExpandedForageYieldReceipt: object
    creditedHarvest = nil
    foodKind() { return nil; }
    availableYield()
    { local value = new RpgExpandedResult(); value.reason = 'forage-yield-unavailable'; return value; }
;

modify RpgExpandedProfile
    foragingDays = []
    foragingDayConflict(day) { return nil; }
    foragingAttemptLimit(day)
    {
        foreach (local reservation in self.foragingDays)
        { reservation.validateBinding(); if (reservation.day == day) return 5; }
        return 1;
    }
    travelScheduleReason(start, seconds)
    {
        rpgInteger(start,0,2147483647); rpgInteger(seconds,0,2147483647-start);
        local last = start + (seconds > 0 ? seconds-1 : 0);
        foreach (local reservation in self.foragingDays)
        {
            reservation.validateBinding();
            if (reservation.day >= start / 86400 && reservation.day <= last / 86400)
                return 'travel-dedicated-foraging-day';
        }
        return nil;
    }
;
/** B427 reserve a whole ledger day before its travel or forage activity begins. */
class RpgExpandedForagingDay: object
    id = nil
    profile = nil
    approved = nil
    evidence = nil
    day = nil
    reservedAt = nil
    boundDefinition = nil
    definition() { return [self.id,self.profile,self.approved,self.evidence]; }
    validateBinding()
    {
        local current = self.definition();
        for (local index = 1; index <= current.length(); index += 1)
            if (current[index] != self.boundDefinition[index]) rpgExpandedReject('foraging-day-binding');
        if (!holds(self.profile.foragingDays,self) || self.day != self.reservedAt / 86400)
            rpgExpandedReject('foraging-day-history');
        return nil;
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile))
            rpgExpandedReject('foraging-day-definition');
        local value = new RpgExpandedResult();
        if (self.reservedAt != nil) { self.validateBinding(); value.status = 'reused'; return value; }
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'foraging-day-choice-required'; return value; }
        if (rpgLedger.seconds % 86400 != 0) { value.reason = 'foraging-day-boundary-required'; return value; }
        local day = rpgLedger.seconds / 86400;
        foreach (local prior in self.profile.foragingDays)
            if (prior.id == self.id || prior.day == day) rpgExpandedReject('foraging-day-duplicate');
        value.reason = self.profile.foragingDayConflict(day); if (value.reason != nil) return value;
        value.status = 'ready'; return value;
    }
    reserve()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.boundDefinition = self.definition(); self.reservedAt = rpgLedger.seconds; self.day = self.reservedAt / 86400;
        self.profile.foragingDays = self.profile.foragingDays + [self]; value.status = 'resolved'; return value;
    }
;

modify RpgLiteSkill
    expandedForageDefaultsReady() { return nil; }
    foragingDefinition() { return []; }
;

modify RpgExpandedProfile
    prepareSocialGate(id, evidence, movement) { return nil; }
;

modify RpgExpandedProfile
    socialSkillLearningReason(skill) { return nil; }
    skillLearningReason(skill)
    {
        local reason = self.physiologySkillLearningReason(skill);
        return reason != nil ? reason : self.socialSkillLearningReason(skill);
    }
;
modify RpgLiteSkill
    requiresSocialInteraction = nil
;

modify RpgLiteSkill
    requiresEmotionalUnderstanding = nil
;

modify RpgExpandedProfile
    pleasureLossActive() { return nil; }
;

modify RpgExpandedProfile
    callousnessActive() { return nil; }
;

modify RpgLiteContext
    requiresSpeech = nil
    requiresVocalization = nil
;
modify RpgLiteTrait
    voiceRelated = nil
;

/** Completed communication adapters expose time already charged to the ledger. */
class RpgExpandedCommunicationReceipt: object
    creditedStudy = nil
    studySeconds(profile) { return 0; }
;
modify RpgExpandedProfile
    communicationStudyEligible() { return nil; }
;

modify RpgLiteTrait
    recurrentPainDefinition() { return nil; }
;

modify RpgExpandedProfile
    companionshipLevel() { return 0; }
;

modify RpgLiteContext
    company = nil
;

modify RpgExpandedProfile
    /** Runtime ownership gate, shared by point purchases and character validation. */
    trainingPurchaseReason(skill,training)
    {
        if (skill == nil || !skill.ofKind(RpgSkill)
            || training != nil && (!training.ofKind(RpgTraining) || training.skill != skill))
            return 'training-purchase-definition';
        local slots = 0;
        foreach (local owned in self.skills)
        {
            if (owned == nil || !owned.ofKind(RpgTraining)) return 'training-purchase-definition';
            if (owned.skill == skill)
            {
                slots += 1;
                if (owned != training) return 'training-purchase-duplicate';
            }
        }
        if (training == nil) return slots == 0 ? nil : 'training-purchase-duplicate';
        if (slots != 1) return 'training-purchase-ownership';
        local owners = 0;
        for (local profile = firstObj(RpgProfile); profile != nil; profile = nextObj(profile,RpgProfile))
            foreach (local owned in profile.skills) if (owned == training) owners += 1;
        return owners == 1 ? nil : 'training-purchase-shared';
    }
;

/** B291 historical award and world justification for one owner's buyoff. */
class RpgExpandedBuyoffBasis: object
    creationReceipt = nil
    owner = nil
    trait = nil
    originalBonus = nil
    approved = nil
    evidence = nil
;
modify RpgExpandedProfile
    buyoffBases = []
    disadvantageBuyoffCost(trait)
    {
        local found = nil;
        foreach (local basis in self.buyoffBases)
        {
            if (basis == nil || !basis.ofKind(RpgExpandedBuyoffBasis) || basis.owner != self)
                rpgExpandedReject('buyoff-basis-ownership');
            if (basis.trait == trait)
            {
                if (found != nil) rpgExpandedReject('buyoff-basis-duplicate'); found = basis;
            }
        }
        if (found == nil || !found.approved || found.evidence == nil || found.evidence == '') return nil;
        rpgInteger(found.originalBonus,0,1000000);
        if (found.creationReceipt != nil) found.creationReceipt.validateOriginalBasis(found);
        return found.originalBonus;
    }
;

modify RpgExpandedProfile
    developmentOfferReason(offer)
    {
        local reason = inherited(offer); if (reason != nil) return reason;
        if (offer.kind != 'remove-trait' || offer.trait == nil || !offer.trait.ofKind(RpgLiteTrait)
            || offer.trait.points >= 0) return nil;
        local original = self.disadvantageBuyoffCost(offer.trait);
        if (original == nil) return 'buyoff-original-cost-required';
        if (offer.cost != original) return 'buyoff-original-cost-mismatch';
        return nil;
    }
;

modify RpgLiteSkill
    studyIdentity() { return self.id; }
    studySpecialty() { return self.specialty; }
;

/* Optional trait module hooks; foundation-only characters keep existing behavior. */
modify RpgExpandedProfile
    freeFallSusceptible(activeOnly) { return nil; }
    physiologySkillLearningReason(skill) { return nil; }
;

modify RpgExpandedProfile
    catalogueSkillModifier(skill) { return 0; }
    catalogueFeatureCheckModifier(skill) { return self.catalogueSkillModifier(skill); }
;
modify RpgExpandedProfile
    orientationSenseLevel() { return 0; }
;

modify RpgExpandedProfile
    effectiveOrientationSenseLevel() { return self.orientationSenseLevel(); }
;
modify RpgLiteTrait
    templatePurchaseOptions() { return []; }
;
modify rpgExpandedTemplateTraits
    configured(id,level,scope,options)
    {
        if (options.length() == 0) return self.plain(id,level,scope);
        rpgExpandedReject('template-trait-options-unavailable');
    }
;
modify RpgExpandedProfile
    humorlessnessActive() { return nil; }
;

modify RpgExpandedProfile
    pervasiveDistrustActive() { return nil; }
;

modify RpgExpandedProfile
    validatePhantomVoiceOccurrence(occurrence) { rpgExpandedReject('phantom-voices-module-required'); }
;

modify RpgExpandedProfile
    validateFixedBeliefPortrayal(portrayal) { rpgExpandedReject('fixed-belief-module-required'); }
    fixedBeliefReactionLevel(belief) { rpgExpandedReject('fixed-belief-module-required'); }
;

modify RpgExpandedProfile
    sustenanceInjuryInterval(trait) { rpgExpandedReject('sustenance-traits-module-required'); }
    sustenanceContactSeconds(trait) { rpgExpandedReject('sustenance-traits-module-required'); }
    validateSustenanceDose(trait) { rpgExpandedReject('sustenance-traits-module-required'); }
;

modify RpgExpandedProfile
    sustenancePeriod(trait) { rpgExpandedReject('sustenance-traits-module-required'); }
;

modify RpgExpandedProfile
    validateContinuousSustenance(trait) { rpgExpandedReject('sustenance-traits-module-required'); }
;

modify RpgExpandedProfile
    sustenanceAgingRequired(trait) { rpgExpandedReject('sustenance-traits-module-required'); }
;


/** Historical contribution credit captured by character finalization. */
class RpgExpandedContributionBasis: object
    owner = nil
    contribution = nil
    originalBonus = nil
    creationReceipt = nil
;
modify RpgExpandedProfile
    contributionBuyoffBases = []
    originalContributionBonus(contribution)
    {
        if (self.creationReceipt != nil) self.creationReceipt.assess();
        local found = nil;
        foreach (local basis in self.contributionBuyoffBases)
        {
            if (basis == nil || !basis.ofKind(RpgExpandedContributionBasis) || basis.owner != self)
                rpgExpandedReject('contribution-basis-owner');
            if (basis.contribution == contribution)
            {
                if (found != nil) rpgExpandedReject('contribution-basis-duplicate');
                found = basis;
            }
        }
        if (found == nil) return nil;
        if (found.creationReceipt == nil) rpgExpandedReject('contribution-basis-receipt');
        found.creationReceipt.validateContributionBasis(found);
        return found.originalBonus;
    }
;

modify RpgExpandedProfile
    dependentReplacementTraitFacts(trait) { rpgExpandedReject('dependent-replacement-trait-unsupported'); }
    validateDependentReplacementTrait(trait) { rpgExpandedReject('dependent-replacement-trait-unsupported'); }
;


modify RpgExpandedProfile
    initialWardrobeStanding(culture,structure)
    { rpgExpandedReject('initial-wardrobe-social-adapter-required'); return nil; }
;

modify RpgExpandedProfile
    motionSusceptible(activeOnly) { return nil; }
;


class RpgExpandedBoatEntryAssessment: RpgExpandedResult
    checkRequired = nil
    boarded = nil
    fellInWater = nil
;
modify RpgLiteContext
    boatEntryDefinition() { rpgExpandedReject('boat-entry-skill-adapter-required'); return []; }
    assessBoatEntry(profile)
    { local value = new RpgExpandedBoatEntryAssessment(); value.reason = 'boat-entry-skill-adapter-required'; return value; }
;


modify RpgExpandedProfile
    prepareSwimmingWound(id,destination) { return nil; }
;

modify RpgLiteSkill
    validateBreathControl() { rpgExpandedReject('breath-control-expanded-skill-required'); }
;

modify RpgExpandedProfile
    purchasedBreathReserveLevels() { rpgExpandedReject('breath-reserve-traits-required'); }
;

modify RpgLiteSkill
    validateLieDetection() { rpgExpandedReject('lie-detection-expanded-skill-required'); }
;

modify RpgLiteSkill
    validateBodyReading() { rpgExpandedReject('body-reading-expanded-skill-required'); }
;

/** Optional skill-module receipt contract for cross-species observations. */
class RpgExpandedPhysiologyReceipt: object
    operation = nil
    profile = nil
    subject = nil
    species = nil
    result = nil
    validateReceipt() { rpgExpandedReject('physiology-check-skills-required'); }
;

modify RpgLiteSkill
    validateDiagnosis() { rpgExpandedReject('diagnosis-expanded-skill-required'); }
;

/** Optional live diagnostic equipment; health does not require the equipment catalogue. */
rpgExpandedDiagnosticEquipment: object
    definition(assessment) { rpgExpandedReject('diagnosis-equipment-module-required'); }
    assess(assessment,profile,skill) { rpgExpandedReject('diagnosis-equipment-module-required'); }
;

class RpgExpandedDiagnosticEquipmentResult: RpgExpandedResult
    equipmentTL = nil
;
modify RpgLiteSkill
    diagnosisContext(equipmentTL) { rpgExpandedReject('diagnosis-expanded-skill-required'); }
;

/** Optional equipment bridge for first-aid treatment; no equipment dependency. */
rpgExpandedFirstAidEquipment: object
    definition(assessment) { rpgExpandedReject('first-aid-equipment-module-required'); }
    assess(assessment,profile,skill) { rpgExpandedReject('first-aid-equipment-module-required'); }
;
modify RpgLiteSkill
    firstAidContext(equipmentTL) { rpgExpandedReject('first-aid-expanded-skill-required'); }
;

modify RpgLiteSkill
    validateNatureObservation(planet,planetType) { rpgExpandedReject('nature-observation-expanded-skill-required'); }
;

/** Cross-module contract for an owned practical nature result. */
class RpgExpandedNatureReceipt: object
    profile = nil
    result = nil
    disclosure = nil
    validateReceipt() { rpgExpandedReject('nature-observation-exploration-required'); }
;

modify RpgLiteContext
    paleontologyFamiliarityModifier(profile) { rpgExpandedReject('paleontology-assessment-skills-required'); }
    paleontologyFacts() { rpgExpandedReject('paleontology-assessment-skills-required'); }
    psychologyFacts() { rpgExpandedReject('psychology-assessment-skills-required'); }
    psychologySubjectIdentity() { rpgExpandedReject('psychology-assessment-skills-required'); }
;

/** Cross-module contract for an owned fossil-study result. */
class RpgExpandedPaleontologyReceipt: object
    profile = nil
    result = nil
    disclosure = nil
    validateReceipt() { rpgExpandedReject('paleontology-assessment-exploration-required'); }
    resolve() { rpgExpandedReject('paleontology-assessment-exploration-required'); }
;

/** Laboratory access is optional; absent equipment modules fail explicitly. */
rpgExpandedPaleontologyEquipment: object
    definition(assessment,context) { rpgExpandedReject('paleontology-equipment-module-required'); }
    assess(assessment,profile,context) { rpgExpandedReject('paleontology-equipment-module-required'); }
;

modify RpgLiteSkill
    validatePacking() { rpgExpandedReject('packing-expanded-skill-required'); }
;

rpgExpandedPackingHandling: object
    definition(attempt) { rpgExpandedReject('packing-creatures-required'); }
    assess(attempt,profile,animal,occurrence) { rpgExpandedReject('packing-creatures-required'); }
;

/** Shared contract for exploration packing outcomes consumed by social. */
class RpgExpandedPackingReceipt: object
    inventoryTransfer = nil
    profile = nil
    result = nil
    disclosure = nil
    validateReceipt() { rpgExpandedReject('packing-exploration-required'); }
    resolve() { rpgExpandedReject('packing-exploration-required'); }
;


rpgExpandedPackingOverload: object
    definition(carry) { rpgExpandedReject('packing-overload-exploration-required'); }
    assess(carry,profile,load) { rpgExpandedReject('packing-overload-exploration-required'); }
    start(carry) { rpgExpandedReject('packing-overload-exploration-required'); }
;

/** B351 full daily mileage reserves preparation, marching and rest for that day. */
class RpgExpandedTravelDay: object
    id = nil
    profile = nil
    approved = nil
    evidence = nil
    day = nil
    boundReservedAt = nil
    interruptedAt = nil
    interruptionEvidence = nil
    boundInterruption = nil
    reservedAt = nil
    boundDefinition = nil
    definition() { return [self.id,self.profile,self.approved,self.evidence]; }
    validateBinding()
    {
        if (self.reservedAt == nil || self.boundDefinition == nil || !holds(self.profile.travelDays,self)
            || self.reservedAt != self.boundReservedAt || self.reservedAt % 86400 != 0 || self.day != self.reservedAt / 86400 || self.reservedAt > rpgLedger.seconds) rpgExpandedReject('travel-day-history');
        if (self.interruptedAt != nil && (self.boundInterruption == nil || self.interruptedAt != self.boundInterruption[1]
            || self.interruptionEvidence != self.boundInterruption[2] || self.interruptedAt < self.reservedAt
            || self.interruptedAt >= self.dayEnd() || self.interruptedAt > rpgLedger.seconds)) rpgExpandedReject('travel-day-interruption-binding');
        if (self.interruptedAt == nil && self.boundInterruption != nil) rpgExpandedReject('travel-day-interruption-binding');
        local facts = self.definition();
        for (local i = 1; i <= facts.length(); i += 1)
            if (facts[i] != self.boundDefinition[i]) rpgExpandedReject('travel-day-binding');
        return nil;
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile))
            rpgExpandedReject('travel-day-definition');
        local value = new RpgExpandedResult();
        if (self.reservedAt != nil) { self.validateBinding(); value.status = 'reused'; return value; }
        if (!self.approved || self.evidence == nil || self.evidence == '') { value.reason = 'travel-day-choice-required'; return value; }
        if (rpgLedger.seconds % 86400 != 0) { value.reason = 'travel-day-boundary-required'; return value; }
        local day = rpgLedger.seconds / 86400;
        foreach (local prior in self.profile.travelDays)
            if (prior.id == self.id || prior.day == day) rpgExpandedReject('travel-day-duplicate');
        value.reason = self.profile.travelScheduleReason(rpgLedger.seconds,86400);
        if (value.reason == nil) value.reason = self.profile.travelDayConflict(day);
        if (value.reason != nil) return value;
        value.status = 'ready'; return value;
    }
    reserve()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.boundDefinition = self.definition(); self.reservedAt = rpgLedger.seconds; self.day = self.reservedAt / 86400; self.boundReservedAt = self.reservedAt;
        self.profile.travelDays = self.profile.travelDays + [self]; value.status = 'resolved'; return value;
    }
    dayEnd() { return self.reservedAt > 2147397247 ? 2147483647 : self.reservedAt + 86400; }
    fullMileageReason()
    {
        if (self.reservedAt == nil) return 'travel-day-not-reserved';
        self.validateBinding(); return self.interruptedAt == nil ? nil : 'travel-day-interrupted';
    }
    interrupt(evidence)
    {
        local value = new RpgExpandedResult();
        if (self.reservedAt == nil) { value.reason = 'travel-day-not-reserved'; return value; }
        self.validateBinding();
        if (evidence == nil || evidence == '') rpgExpandedReject('travel-day-interruption-evidence');
        if (self.interruptedAt != nil)
        {
            if (self.interruptionEvidence != evidence) rpgExpandedReject('travel-day-interruption-binding');
            value.status = 'reused'; return value;
        }
        if (rpgLedger.seconds >= self.dayEnd()) { value.reason = 'travel-day-already-ended'; return value; }
        self.interruptedAt = rpgLedger.seconds; self.interruptionEvidence = evidence;
        self.boundInterruption = [self.interruptedAt,evidence]; value.status = 'resolved'; return value;
    }
;
modify RpgExpandedProfile
    travelDays = []
    travelDayConflict(day) { return nil; }
    nonTravelScheduleReason(start,seconds)
    {
        rpgInteger(start,0,2147483647); rpgInteger(seconds,0,2147483647-start);
        local last = start + (seconds > 0 ? seconds-1 : 0);
        foreach (local reservation in self.travelDays)
        {
            reservation.validateBinding();
            local end = reservation.interruptedAt == nil ? reservation.dayEnd() : reservation.interruptedAt;
            if (start < end && last >= reservation.reservedAt) return 'activity-dedicated-travel-day';
        }
        return nil;
    }
    foragingDayConflict(day)
    {
        local reason = inherited(day); if (reason != nil) return reason;
        foreach (local reservation in self.travelDays)
        { reservation.validateBinding(); if (reservation.day == day) return 'foraging-dedicated-travel-day'; }
        return nil;
    }
    validateFeatures()
    {
        inherited(); local ids = []; local days = [];
        foreach (local reservation in self.travelDays)
        {
            if (reservation == nil || !reservation.ofKind(RpgExpandedTravelDay) || reservation.profile != self
                || holds(ids,reservation.id) || holds(days,reservation.day)) rpgExpandedReject('travel-day-history');
            reservation.validateBinding(); ids = ids + [reservation.id]; days = days + [reservation.day];
        }
        return nil;
    }
;

modify RpgLiteContext
    beggingFacts() { rpgExpandedReject('begging-context-required'); }
;

/** Optional social execution contract consumed by equipment reward adapters. */
class RpgExpandedBeggingReceipt: object
    profile = nil
    result = nil
    gift = nil
    beggingBonusReason() { rpgExpandedReject('begging-social-required'); }
;

modify RpgLiteProfile
    sympathyActive() { return nil; }
    beggingAuthoredTraitReason(sympathy, shyness) { return nil; }
;

modify RpgExpandedProfile
    appearanceTrait() { return nil; }
;

modify RpgLiteSocialContext
    beggingAppearanceFacts() { rpgExpandedReject('begging-appearance-context-required'); }
    beggingAppearanceModifier(profile) { rpgExpandedReject('begging-appearance-context-required'); }
;

modify RpgExpandedProfile
    stylingActive() { return nil; }
;

/** Optional equipment-backed outfit contract, independent of social includes. */
class RpgExpandedStylingOutfit: object
    definition() { rpgExpandedReject('styling-outfit-equipment-required'); }
    preparationReason(wearer) { return 'styling-outfit-equipment-required'; }
    wornBy(wearer) { return nil; }
;

modify RpgLiteItem
    stylingUseReason(profile) { return nil; }
;

modify RpgLiteProfile
    distinctiveFeatureLevels() { return 0; }
;

modify RpgLiteContext
    makeupFacts() { rpgExpandedReject('makeup-context-required'); }
;

class RpgExpandedMakeupEquipmentResult: RpgExpandedResult
    equipmentTL = nil
;
rpgExpandedMakeupEquipment: object
    definition(assessment,context) { rpgExpandedReject('makeup-equipment-module-required'); }
    assess(assessment,profile,context) { rpgExpandedReject('makeup-equipment-module-required'); }
;

/** Optional inventory debit owned by one cosmetic application. */
class RpgExpandedMakeupMaterials: object
    definition(application) { rpgExpandedReject('makeup-materials-equipment-required'); }
    assess(application) { return 'makeup-materials-equipment-required'; }
    consume(application) { rpgExpandedReject('makeup-materials-equipment-required'); }
    validateReceipt(application,consumed) { rpgExpandedReject('makeup-materials-equipment-required'); }
;

modify RpgExpandedProfile
    culturalPenalty(culture) { rpgExpandedReject('culture-characters-module-required'); }
;

modify RpgExpandedRules
    cinematicCulturalAdaptation = nil
;
modify RpgExpandedProfile
    culturalSpecies = nil
    culturalAdaptationCovers(culture) { return nil; }
;
