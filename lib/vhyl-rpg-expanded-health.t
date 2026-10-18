/* Include after expanded foundation. Source: full-2008, B419.
 * This incremental module does not yet supply detailed injury or medical care. */

modify RpgExpandedRules
    scaledInjuryShock = nil
    lastWounds = nil
    expandedNaturalRecovery = nil
    expandedFatigueStrength = nil
    automaticCardiacDeadlines = nil
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
    brainException = nil
    vitalsException = nil
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


/** Apply only the B420 absent-organ exceptions, leaving final injury unchanged.
 * This does not price anatomy traits or implement their other damage effects. */
rpgExpandedAssessAnatomyKnockdown(capacity, injury, location, maleGroin, noBrain, noVitals)
{
    local value = rpgExpandedAssessKnockdown(capacity,injury,location,maleGroin);
    value.brainException = noBrain && holds(['face','skull'],location);
    value.vitalsException = noVitals && holds(['vitals','groin'],location);
    if (value.brainException || value.vitalsException)
    { value.required = value.major; value.modifier = 0; }
    return value;
}


modify RpgExpandedProfile
    expandedWounds = []
;

/** Preflight and receipt envelope for an explicitly selected expanded wound. */
class RpgExpandedWoundResult: RpgExpandedResult
    dropPlan = nil
    limbDrop = nil
    crippling = nil
    healthLoss = 0
    ignored = nil
    assessment = nil
    health = nil
;

/** Owned standard-anatomy wound. Amount is final injury, not raw attack damage.
 * Unsupported anatomy and low-target checks reject before commit; held-item
 * dropping requires the equipment module and an authored destination. Run apply() inside the existing action transaction. */
class RpgExpandedWound: object
    id = nil
    profile = nil
    amount = 0
    location = 'torso'
    criticalHit = nil
    boundCriticalHit = nil
    ignored = nil
    bodyPart = nil
    severing = nil
    boundBodyPart = nil
    boundSevering = nil
    cripplingAssessment = nil
    durationRecord = nil
    droppedLimbEquipment = nil
    maleGroin = nil
    anatomy = 'standard-humanoid'
    dropDestination = nil
    droppedEquipment = nil
    bandage = nil
    committedSerial = nil
    boundProfile = nil
    boundId = nil
    boundAmount = 0
    boundLocation = nil
    boundMaleGroin = nil
    boundDropDestination = nil
    health = nil
    knockdownAssessment = nil
    assess()
    {
        if (self.profile == nil || !self.profile.ofKind(RpgExpandedProfile) || self.id == nil || self.id == '')
            rpgExpandedReject('expanded-wound-owner');
        local value = new RpgExpandedWoundResult();
        if (self.health != nil)
        {
            if (!holds(self.profile.expandedWounds,self)) rpgExpandedReject('expanded-wound-history');
            if (self.profile != self.boundProfile || self.id != self.boundId || self.amount != self.boundAmount
                || self.location != self.boundLocation || self.maleGroin != self.boundMaleGroin
                || self.bodyPart != self.boundBodyPart || self.severing != self.boundSevering
                || self.criticalHit != self.boundCriticalHit
                || self.dropDestination != self.boundDropDestination
                || self.anatomy != 'standard-humanoid') rpgExpandedReject('expanded-wound-retargeted');
            value.status = 'reused'; value.health = self.health; value.assessment = self.knockdownAssessment;
            value.crippling = self.cripplingAssessment; value.healthLoss = self.health.injury; value.ignored = self.ignored; return value;
        }
        rpgExpandedValidate(self.profile);
        foreach (local wound in self.profile.expandedWounds)
            if (wound.id == self.id) rpgExpandedReject('expanded-wound-duplicate');
        if (!self.profile.rules.scaledInjuryShock)
        { value.reason = 'expanded-wound-shock-rule-required'; return value; }
        if (self.anatomy != 'standard-humanoid')
        { value.reason = 'expanded-wound-anatomy-unavailable'; return value; }
        foreach (local traitId in ['homogenous','diffuse','low-pain-threshold'])
            if (self.profile.level(traitId) > 0)
            { value.reason = 'expanded-wound-trait-unavailable'; return value; }
        if (self.profile.dead) { value.reason = 'expanded-wound-dead'; return value; }
        value.healthLoss = self.amount;
        if (self.bodyPart == nil)
            value.assessment = rpgExpandedAssessAnatomyKnockdown(self.profile.maxHP,self.amount,self.location,self.maleGroin,
                self.profile.level('no-brain') > 0,self.profile.level('no-vitals') > 0);
        else
        {
            if (!self.bodyPart.ofKind(RpgExpandedBodyPart) || self.bodyPart.profile != self.profile
                || !holds(self.profile.bodyParts,self.bodyPart) || self.location != self.bodyPart.kind
                || self.maleGroin) rpgExpandedReject('expanded-wound-body-part');
            if (!self.bodyPart.functional())
            { value.reason = 'expanded-wound-disabled-part-unavailable'; return value; }
            local count = 0;
            foreach (local part in self.profile.bodyParts)
                if (part.kind == self.bodyPart.kind) count += 1;
            value.crippling = rpgExpandedAssessCrippling(self.profile.maxHP,self.amount,
                self.bodyPart.kind == 'arm' ? 'limb' : 'extremity',count,self.severing);
            value.healthLoss = value.crippling.healthLoss;
            if (self.profile.rules.lastWounds && self.profile.hp() * 3 < self.profile.maxHP
                && !self.criticalHit && !value.crippling.crippled && self.amount * 3 < self.profile.maxHP)
            { value.ignored = true; value.healthLoss = 0; }
            value.assessment = rpgExpandedAssessKnockdown(self.profile.maxHP,value.healthLoss,'torso',nil);
            if (value.crippling.crippled)
            {
                value.assessment.major = true; value.assessment.required = true;
                value.limbDrop = self.profile.prepareLimbInjuryDrop(self.bodyPart,value.crippling.severed,self.dropDestination);
                if (value.limbDrop != nil && value.limbDrop.status != 'ready')
                { value.reason = value.limbDrop.reason; return value; }
            }
        }
        if (value.assessment.required && !self.profile.unconscious)
        {
            value.dropPlan = self.profile.prepareKnockdownDrop(self.dropDestination);
            if (value.dropPlan != nil && value.dropPlan.status != 'ready')
            { value.reason = value.dropPlan.reason; return value; }
            local context = new RpgLiteContext(); context.attribute = rpgHT;
            context.kind = 'major-wound'; context.modifier = value.assessment.modifier;
            local score = rpgLiteScore(self.profile,context);
            if (score == nil || score < 3)
            { value.reason = 'expanded-knockdown-score-unavailable'; return value; }
        }
        if (value.healthLoss > 0 && self.profile.ht < 3 && self.profile.hp() - value.healthLoss <= -self.profile.maxHP)
        { value.reason = 'expanded-survival-score-unavailable'; return value; }
        self.profile.shockFromInjury(value.healthLoss);
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.health = rpgLiteWoundWithKnockdown(self.profile,value.healthLoss,
            value.assessment.required,value.assessment.modifier);
        if (self.health.knockedDown && value.dropPlan != nil)
        { value.dropPlan.commit(); self.droppedEquipment = value.dropPlan; }
        if (value.crippling != nil && value.crippling.crippled)
        {
            self.bodyPart.disabled = true; self.bodyPart.severed = value.crippling.severed;
            self.bodyPart.disablingWound = self;
            if (value.limbDrop != nil)
            {
                value.limbDrop.commitAfter(self.droppedEquipment);
                self.droppedLimbEquipment = value.limbDrop;
            }
        }
        self.ignored = value.ignored; self.boundCriticalHit = self.criticalHit;
        self.cripplingAssessment = value.crippling;
        self.boundBodyPart = self.bodyPart; self.boundSevering = self.severing;
        self.knockdownAssessment = value.assessment;
        self.boundProfile = self.profile; self.boundId = self.id; self.boundAmount = self.amount;
        self.boundLocation = self.location; self.boundMaleGroin = self.maleGroin;
        self.boundDropDestination = self.dropDestination;
        self.committedSerial = self.profile.woundSerial;
        self.profile.expandedWounds = self.profile.expandedWounds + [self];
        value.health = self.health; value.status = 'resolved'; return value;
    }
;

modify RpgExpandedProfile
    validateFeatures()
    {
        inherited(); local ids = [];
        foreach (local wound in self.expandedWounds)
        {
            if (wound == nil || !wound.ofKind(RpgExpandedWound) || wound.profile != self
                || wound.boundProfile != self || wound.health == nil || wound.id != wound.boundId
                || holds(ids,wound.id)) rpgExpandedReject('expanded-wound-history');
            if (wound.bandage != nil)
            {
                local bandage = wound.bandage;
                if (!bandage.ofKind(RpgExpandedBandage) || bandage.wound != wound
                    || bandage.boundWound != wound || bandage.result == nil
                    || bandage.healer != bandage.boundHealer || bandage.evidence != bandage.boundEvidence
                    || bandage.eligibleInjury != bandage.boundEligibleInjury
                    || bandage.result.status != 'resolved' || bandage.result.seconds != 60)
                    rpgExpandedReject('bandage-history');
                if (bandage.treatment != nil && (!bandage.treatment.ofKind(RpgExpandedFirstAid)
                    || bandage.treatment.bandage != bandage || bandage.treatment.result == nil
                    || bandage.treatment.assess().status != 'reused'))
                    rpgExpandedReject('first-aid-history');
            }
            if (wound.durationRecord != nil && (!wound.durationRecord.ofKind(RpgExpandedCripplingDuration)
                || wound.durationRecord.wound != wound || wound.durationRecord.boundWound != wound
                || wound.durationRecord.result == nil
                || !holds(['temporary','lasting','permanent'],wound.durationRecord.result.duration)))
                rpgExpandedReject('crippling-duration-history');
            if (wound.durationRecord != nil)
            {
                local record = wound.durationRecord; local boundaries = []; local calendar = nil; local ordinal = 0;
                if (record.result.duration == 'lasting') rpgInteger(record.result.months,1,6);
                local previousMonths = record.result.months; local careIds = [];
                foreach (local care in record.laterCare)
                {
                    if (care == nil || !care.ofKind(RpgExpandedCripplingCare) || care.duration != record
                        || care.boundDuration != record || care.result == nil || care.id != care.boundId
                        || care.physician != care.boundPhysician || care.medicalTL != care.boundMedicalTL
                        || care.evidence != care.boundEvidence || holds(careIds,care.id)
                        || record.result.duration != 'lasting' || care.result.monthsBefore != previousMonths
                        || care.result.monthsAfter >= previousMonths || care.result.monthsAfter < 1
                        || care.result.monthsAfter != rpgExpandedCripplingMonths(record.result.monthRoll,care.medicalTL))
                        rpgExpandedReject('crippling-care-history');
                    careIds = careIds + [care.id]; previousMonths = care.result.monthsAfter;
                }
                foreach (local month in record.recoveryMonths)
                {
                    ordinal += 1;
                    if (month == nil || !month.ofKind(RpgExpandedRecoveryMonth) || !month.completed
                        || month.duration != record || month.boundDuration != record || month.ordinal != ordinal
                        || month.boundOrdinal != ordinal || month.calendarId != month.boundCalendarId
                        || month.boundaryId != month.boundBoundaryId || month.evidence != month.boundEvidence
                        || !month.reached || holds(boundaries,month.boundaryId)
                        || calendar != nil && calendar != month.calendarId)
                        rpgExpandedReject('recovery-month-history');
                    boundaries = boundaries + [month.boundaryId]; calendar = month.calendarId;
                }
                if (ordinal > 0 && (record.result.duration != 'lasting' || ordinal > record.result.months
                    || record.result.recovered != (ordinal >= record.requiredMonths())))
                    rpgExpandedReject('recovery-month-history');
            }
            ids = ids + [wound.id];
        }
        return nil;
    }
;

/** Separate pre-cap trauma from health loss, full-2008 B421. */
class RpgExpandedCripplingAssessment: RpgExpandedResult
    minimumInjury = 0
    healthLoss = 0
    crippled = nil
    destroyed = nil
    severed = nil
;

/** Assess one injury to a limb, extremity or eye. Count is the number of that
 * anatomical kind, not the number currently usable. severing means cutting or
 * explosive trauma; it affects destruction description, not thresholds. */
rpgExpandedAssessCrippling(capacity, injury, kind, count, severing)
{
    rpgInteger(capacity,1,1000); rpgInteger(injury,0,100000); rpgInteger(count,1,1000);
    if (!holds(['limb','extremity','eye'],kind)) rpgExpandedReject('crippling-part-kind');
    local value = new RpgExpandedCripplingAssessment();
    if (kind == 'eye') value.minimumInjury = capacity / 10 + 1;
    else if (kind == 'limb') value.minimumInjury = capacity / (count > 2 ? count : 2) + 1;
    else value.minimumInjury = count > 2 ? (capacity * 2) / (count * 3) + 1 : capacity / 3 + 1;
    value.crippled = injury >= value.minimumInjury;
    value.destroyed = injury >= value.minimumInjury * 2;
    value.severed = value.destroyed && severing && kind != 'eye';
    value.healthLoss = kind == 'eye' || injury < value.minimumInjury ? injury : value.minimumInjury;
    value.status = 'ready'; return value;
}


/** Owned upper-limb anatomy. Disability is functional state, not another HP ledger.
 * Hands name their containing arm; severing implies disability. Source: B421. */
class RpgExpandedBodyPart: object
    id = nil
    profile = nil
    kind = 'arm'
    parent = nil
    disabled = nil
    severed = nil
    disablingWound = nil
    validate()
    {
        if (self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)
            || !holds(self.profile.bodyParts,self) || self.id == nil || self.id == '')
            rpgExpandedReject('body-part-owner');
        if (!holds(['arm','hand'],self.kind)) rpgExpandedReject('body-part-kind-unavailable');
        if (self.severed && !self.disabled) rpgExpandedReject('body-part-severed-state');
        if (self.disablingWound != nil && (!self.disablingWound.ofKind(RpgExpandedWound)
            || self.disablingWound.profile != self.profile || self.disablingWound.boundBodyPart != self
            || !holds(self.profile.expandedWounds,self.disablingWound)))
            rpgExpandedReject('body-part-wound-history');
        if (self.kind == 'arm' && self.parent != nil) rpgExpandedReject('body-part-parent');
        if (self.kind == 'hand' && (self.parent == nil || !self.parent.ofKind(RpgExpandedBodyPart)
            || self.parent.kind != 'arm' || self.parent.profile != self.profile
            || !holds(self.profile.bodyParts,self.parent))) rpgExpandedReject('body-part-parent');
        return nil;
    }
    functional()
    {
        self.validate();
        return !self.disabled && (self.parent == nil || !self.parent.disabled);
    }
;

modify RpgExpandedProfile
    bodyParts = []
    validateBodyParts()
    {
        local ids = []; local armsWithHands = [];
        foreach (local part in self.bodyParts)
        {
            if (part == nil || !part.ofKind(RpgExpandedBodyPart) || part.profile != self)
                rpgExpandedReject('body-part-owner');
            part.validate();
            if (holds(ids,part.id)) rpgExpandedReject('body-part-duplicate');
            ids = ids + [part.id];
            if (part.kind == 'hand')
            {
                if (holds(armsWithHands,part.parent)) rpgExpandedReject('body-part-hand-duplicate');
                armsWithHands = armsWithHands + [part.parent];
            }
        }
        return nil;
    }
    validateFeatures() { inherited(); self.validateBodyParts(); return nil; }
;

/** Bind held gear to hands, or an attached shield to its supporting arm.
 * Empty bindings preserve the existing equipment behavior. Bindings do not
 * automatically drop gear or supply missing anatomy. */
modify RpgLiteItem
    bodySupports = []
    validateBodySupports(profile)
    {
        if (self.bodySupports.length() == 0) return nil;
        if (profile == nil || !profile.ofKind(RpgExpandedProfile))
            rpgExpandedReject('body-support-profile');
        profile.validateBodyParts(); local seen = [];
        foreach (local part in self.bodySupports)
        {
            if (part == nil || !part.ofKind(RpgExpandedBodyPart) || part.profile != profile
                || !holds(profile.bodyParts,part) || holds(seen,part))
                rpgExpandedReject('body-support-owner');
            seen = seen + [part];
        }
        return nil;
    }
    attackUsableBy(profile)
    {
        self.validateBodySupports(profile);
        if (!inherited(profile)) return nil;
        if (profile.ofKind(RpgExpandedProfile) && profile.bodyParts.length() > 0
            && holds(['punch','brass-knuckles'],self.id) && self.bodySupports.length() == 0)
            rpgExpandedReject('unarmed-hand-support-required');
        foreach (local part in self.bodySupports)
        {
            if (!part.functional()) return nil;
            if (part.kind == 'arm')
            {
                local hand = nil;
                foreach (local candidate in profile.bodyParts)
                    if (candidate.parent == part) hand = candidate;
                if (hand == nil) rpgExpandedReject('body-support-hand-required');
                if (!hand.functional()) return nil;
            }
        }
        return true;
    }
    attackHandCount(profile, requested)
    {
        self.validateBodySupports(profile);
        if (self.bodySupports.length() == 0) return inherited(profile,requested);
        local arms = [];
        foreach (local part in self.bodySupports)
            if (part.functional())
            {
                local arm = part.kind == 'hand' ? part.parent : part;
                if (!holds(arms,arm)) arms = arms + [arm];
            }
        return arms.length() < requested ? arms.length() : requested;
    }
    parryUsableBy(profile) { return self.attackUsableBy(profile); }
    blockUsableBy(profile)
    {
        self.validateBodySupports(profile);
        if (!inherited(profile)) return nil;
        foreach (local part in self.bodySupports)
        {
            if (part.kind != 'arm') rpgExpandedReject('shield-arm-support-required');
            if (!part.functional()) return nil;
        }
        return true;
    }
    passiveDefenseBonus(profile)
    {
        self.validateBodySupports(profile);
        local bonus = inherited(profile); local impaired = nil;
        foreach (local part in self.bodySupports)
        {
            if (part.kind != 'arm') rpgExpandedReject('shield-arm-support-required');
            if (part.severed) return 0;
            if (part.disabled) impaired = true;
        }
        return impaired && bonus > 0 ? bonus - 1 : bonus;
    }
;


modify RpgExpandedProfile
    prepareLimbInjuryDrop(part, severed, destination)
    {
        local items = []; local conditional = [];
        foreach (local item in self.equipment)
        {
            item.validateBodySupports(self);
            if (item.usableBy(self))
            {
                if (item.bodySupports.length() == 0)
                {
                    if (item.ready || item.worn && item.db > 0)
                    { local blocked = new RpgExpandedResult(); blocked.reason = 'limb-drop-supports-required'; return blocked; }
                }
                else
                {
                    local affected = nil; local retained = nil;
                    foreach (local support in item.bodySupports)
                    {
                        if (support == part || support.parent == part) affected = true;
                        else if (support.functional()) retained = true;
                    }
                    if (affected)
                    {
                        if (item.worn)
                        {
                            if (item.db <= 0 || item.bodySupports.length() != 1 || item.bodySupports[1].kind != 'arm')
                            { local blocked = new RpgExpandedResult(); blocked.reason = 'limb-drop-worn-support-unavailable'; return blocked; }
                            if (part.kind == 'arm' && severed) items = items + [item];
                        }
                        else
                        {
                            if (retained)
                            {
                                foreach (local support in item.bodySupports)
                                    if (support.kind != 'hand')
                                    { local blocked = new RpgExpandedResult(); blocked.reason = 'limb-retention-hand-grips-required'; return blocked; }
                                conditional = conditional + [item];
                            }
                            items = items + [item];
                        }
                    }
                }
            }
        }
        if (items.length() == 0) return nil;
        local forced = self.prepareForcedDrop(items,destination);
        if (forced.status != 'ready') return forced;
        local value = new RpgExpandedLimbDropPlan(); value.profile = self; value.part = part;
        value.forcedDrop = forced; value.conditionalItems = conditional;
        if (conditional.length() > 0 && !self.unconscious)
        {
            local score = rpgLiteScore(self,new RpgExpandedGripContext());
            if (score == nil || score < 3)
            { value.reason = 'limb-retention-score-unavailable'; return value; }
        }
        value.status = 'ready'; return value;
    }
;


/** B147 permits an unarmed parry with a handless but functioning arm. The
 * authored freeHands limit still represents other restraints or occupations. */
modify RpgLiteFighter
    unarmedParryRequirement(otherHand)
    {
        if (self.profile != nil && self.profile.ofKind(RpgExpandedProfile)
            && self.profile.bodyParts.length() > 0 && otherHand
            && (self.weapon == nil || holds(['punch','kick'],self.weapon.id))) return 2;
        return inherited(otherHand);
    }
    unarmedParryCapacity()
    {
        if (self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)
            || self.profile.bodyParts.length() == 0) return inherited();
        self.profile.validateBodyParts(); rpgInteger(self.freeHands,0,1000);
        local occupied = [];
        foreach (local item in self.profile.equipment)
        {
            item.validateBodySupports(self.profile);
            if (item.usableBy(self.profile) && !item.worn && !holds(['punch','kick'],item.id))
            {
                if (item.ready && item.bodySupports.length() == 0)
                    rpgExpandedReject('unarmed-grip-map-required');
                foreach (local support in item.bodySupports)
                {
                    local arm = support.kind == 'hand' ? support.parent : support;
                    if (!holds(occupied,arm)) occupied = occupied + [arm];
                }
            }
        }
        local count = 0;
        foreach (local part in self.profile.bodyParts)
            if (part.kind == 'arm' && part.functional() && !holds(occupied,part)) count += 1;
        return count < self.freeHands ? count : self.freeHands;
    }
;


/** Immediate retention is a defensive reaction, B419/B421: temporary attribute
 * reductions do not apply. It uses DX without an action or resource charge. */
class RpgExpandedGripContext: RpgLiteContext
    attribute = rpgDX
    kind = 'defense'
    controllingAttribute() { return nil; }
;

/** Owned wound consequence: conditional retention rolls and actual drop receipt. */
class RpgExpandedLimbDropPlan: RpgExpandedResult
    profile = nil
    part = nil
    forcedDrop = nil
    conditionalItems = []
    retainedItems = []
    checks = []
    items = []
    committed = nil
    commitAfter(knockdownDrop)
    {
        if (self.committed) return 'reused';
        if (self.status != 'ready' || self.forcedDrop == nil || self.profile == nil
            || self.part == nil || self.part.profile != self.profile || !self.part.disabled
            || self.part.disablingWound == nil || self.forcedDrop.profile != self.profile
            || !holds(self.profile.bodyParts,self.part)) rpgExpandedReject('limb-drop-unprepared');
        if (knockdownDrop != nil && (!knockdownDrop.committed || knockdownDrop.profile != self.profile))
            rpgExpandedReject('limb-drop-knockdown-owner');
        local dropped = [];
        foreach (local item in self.forcedDrop.items)
        {
            if (knockdownDrop == nil || !holds(knockdownDrop.items,item))
            {
                local retained = nil;
                if (holds(self.conditionalItems,item) && !self.profile.unconscious && !self.profile.dead)
                {
                    local check = rpgLiteCheck(self.profile,new RpgExpandedGripContext());
                    self.checks = self.checks + [check]; retained = check.achieved;
                }
                if (retained)
                {
                    local grips = [];
                    foreach (local support in item.bodySupports)
                        if (support != self.part && support.parent != self.part && !support.disabled)
                            grips = grips + [support];
                    item.bodySupports = grips; self.retainedItems = self.retainedItems + [item];
                }
                else dropped = dropped + [item];
            }
        }
        self.forcedDrop.items = dropped; self.forcedDrop.commit(); self.items = dropped;
        self.committed = true; return 'resolved';
    }
;


/** Lasting recovery in calendar months, B422; treatment never reduces it below one. */
rpgExpandedCripplingMonths(roll, medicalTL)
{
    rpgInteger(roll,1,6);
    if (medicalTL == nil) return roll;
    rpgInteger(medicalTL,0,12);
    local reduction = medicalTL >= 7 ? 3 : medicalTL == 6 ? 2 : medicalTL == 5 ? 1 : 0;
    return roll - reduction < 1 ? 1 : roll - reduction;
}

/** Stored classification and check; months are calendar units, not ledger seconds. */
class RpgExpandedCripplingDurationResult: RpgExpandedResult
    duration = nil
    months = 0
    monthRoll = 0
    recovered = nil
;

/** One owned duration determination per crippling wound, B422-B423. Physician
 * treatment is an explicit completed-care fact; this does not perform treatment. */
class RpgExpandedCripplingDuration: object
    wound = nil
    recoveryMonths = []
    laterCare = []
    requiredMonths()
    {
        if (self.result == nil || self.result.duration != 'lasting') return 0;
        return self.laterCare.length() == 0 ? self.result.months : self.laterCare[self.laterCare.length()].result.monthsAfter;
    }
    combatEnded = nil
    physician = nil
    medicalTL = nil
    careEvidence = nil
    boundWound = nil
    boundCombatEnded = nil
    boundPhysician = nil
    boundMedicalTL = nil
    boundCareEvidence = nil
    result = nil
    assess()
    {
        if (self.wound == nil || !self.wound.ofKind(RpgExpandedWound)
            || self.wound.health == nil || self.wound.bodyPart == nil
            || self.wound.cripplingAssessment == nil || !self.wound.cripplingAssessment.crippled)
            rpgExpandedReject('crippling-duration-wound');
        local profile = self.wound.profile; rpgExpandedValidate(profile);
        if (!holds(profile.expandedWounds,self.wound)) rpgExpandedReject('crippling-duration-owner');
        local value = new RpgExpandedResult();
        if (self.result != nil)
        {
            if (self.wound.durationRecord != self || self.wound != self.boundWound
                || self.combatEnded != self.boundCombatEnded || self.physician != self.boundPhysician
                || self.medicalTL != self.boundMedicalTL || self.careEvidence != self.boundCareEvidence)
                rpgExpandedReject('crippling-duration-retargeted');
            value.status = 'reused'; return value;
        }
        if (self.wound.durationRecord != nil) rpgExpandedReject('crippling-duration-duplicate');
        if (self.wound.bodyPart.disablingWound != self.wound || !self.wound.bodyPart.disabled)
            rpgExpandedReject('crippling-duration-part');
        if (self.medicalTL != nil)
        {
            rpgInteger(self.medicalTL,0,12);
            if (self.physician == nil || !self.physician.ofKind(RpgLiteProfile)
                || self.careEvidence == nil || self.careEvidence == '')
                rpgExpandedReject('crippling-duration-care-evidence');
        }
        else if (self.physician != nil || self.careEvidence != nil)
            rpgExpandedReject('crippling-duration-care-level');
        if (!self.wound.cripplingAssessment.destroyed)
        {
            if (profile.dead) { value.reason = 'crippling-duration-dead'; return value; }
            if (!self.combatEnded) { value.reason = 'crippling-duration-combat-not-ended'; return value; }
            for (local battle = firstObj(RpgLiteBattle); battle != nil; battle = nextObj(battle,RpgLiteBattle))
                if (battle.active)
                    foreach (local fighter in battle.fighters)
                        if (fighter.profile == profile)
                        { value.reason = 'crippling-duration-combat-active'; return value; }
            local context = new RpgLiteContext(); context.attribute = rpgHT; context.kind = 'crippling-duration';
            context.modifier = profile.level('rapid-healing') > 0 || profile.level('very-rapid-healing') > 0 ? 5 : 0;
            local score = rpgLiteScore(profile,context);
            if (score == nil || score < 3) { value.reason = 'crippling-duration-score-unavailable'; return value; }
        }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local assessment = self.assess(); if (assessment.status != 'ready') return assessment;
        local value = new RpgExpandedCripplingDurationResult(); local profile = self.wound.profile;
        if (self.wound.cripplingAssessment.destroyed) value.duration = 'permanent';
        else
        {
            local modifier = profile.level('rapid-healing') > 0 || profile.level('very-rapid-healing') > 0 ? 5 : 0;
            value.check = rpgLiteAttributeCheck(profile,rpgHT,'crippling-duration',modifier);
            if (value.check.achieved) value.duration = 'temporary';
            else if (value.check.critical == 'failure') value.duration = 'permanent';
            else
            {
                value.duration = 'lasting'; value.monthRoll = rpgRandom.die();
                value.months = rpgExpandedCripplingMonths(value.monthRoll,self.medicalTL);
            }
        }
        value.status = 'resolved'; self.result = value;
        self.boundWound = self.wound; self.boundCombatEnded = self.combatEnded;
        self.boundPhysician = self.physician; self.boundMedicalTL = self.medicalTL;
        self.boundCareEvidence = self.careEvidence; self.wound.durationRecord = self;
        profile.afterHealing(); return value;
    }
;

modify RpgExpandedProfile
    afterHealing()
    {
        inherited();
        if (self.dead || self.injury != 0) return nil;
        foreach (local wound in self.expandedWounds)
        {
            local record = wound.durationRecord;
            if (record != nil && record.result != nil && record.result.duration == 'temporary'
                && !record.result.recovered && wound.bodyPart.disablingWound == wound)
            {
                wound.bodyPart.disabled = nil; wound.bodyPart.severed = nil;
                wound.bodyPart.disablingWound = nil; record.result.recovered = true;
            }
        }
        return nil;
    }
;


/** One observed campaign-calendar anniversary of a lasting injury, B422.
 * Authors identify the actual month boundary; no fixed seconds/month is assumed. */
class RpgExpandedRecoveryMonth: object
    duration = nil
    ordinal = 1
    calendarId = nil
    boundaryId = nil
    reached = nil
    evidence = nil
    boundDuration = nil
    boundOrdinal = 0
    boundCalendarId = nil
    boundBoundaryId = nil
    boundEvidence = nil
    completed = nil
    assess()
    {
        if (self.duration == nil || !self.duration.ofKind(RpgExpandedCripplingDuration)
            || self.duration.result == nil || self.duration.wound == nil
            || !self.duration.wound.ofKind(RpgExpandedWound) || self.duration.wound.durationRecord != self.duration
            || self.duration.boundWound != self.duration.wound)
            rpgExpandedReject('recovery-month-duration');
        local wound = self.duration.wound; local profile = wound.profile; rpgExpandedValidate(profile);
        local value = new RpgExpandedResult();
        if (self.completed)
        {
            if (!holds(self.duration.recoveryMonths,self) || self.duration != self.boundDuration
                || self.ordinal != self.boundOrdinal || self.calendarId != self.boundCalendarId
                || self.boundaryId != self.boundBoundaryId || self.evidence != self.boundEvidence || !self.reached)
                rpgExpandedReject('recovery-month-retargeted');
            value.status = 'reused'; return value;
        }
        rpgInteger(self.ordinal,1,6);
        if (self.calendarId == nil || self.calendarId == '' || self.boundaryId == nil || self.boundaryId == ''
            || self.evidence == nil || self.evidence == '') rpgExpandedReject('recovery-month-calendar-evidence');
        if (self.duration.result.duration != 'lasting')
        { value.reason = 'recovery-month-not-lasting'; return value; }
        foreach (local prior in self.duration.recoveryMonths)
        {
            if (prior.boundaryId == self.boundaryId) rpgExpandedReject('recovery-month-duplicate-boundary');
            if (prior.calendarId != self.calendarId) rpgExpandedReject('recovery-month-calendar-changed');
        }
        if (self.duration.result.recovered) { value.reason = 'recovery-month-already-recovered'; return value; }
        if (self.ordinal != self.duration.recoveryMonths.length() + 1)
        { value.reason = 'recovery-month-gap'; return value; }
        if (!self.reached) { value.reason = 'recovery-month-not-reached'; return value; }
        if (profile.dead) { value.reason = 'recovery-month-dead'; return value; }
        if (!wound.bodyPart.disabled || wound.bodyPart.disablingWound != wound)
            rpgExpandedReject('recovery-month-current-wound');
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.boundDuration = self.duration; self.boundOrdinal = self.ordinal;
        self.boundCalendarId = self.calendarId; self.boundBoundaryId = self.boundaryId;
        self.boundEvidence = self.evidence; self.completed = true;
        self.duration.recoveryMonths = self.duration.recoveryMonths + [self];
        if (self.ordinal >= self.duration.requiredMonths())
        {
            local part = self.duration.wound.bodyPart;
            part.disabled = nil; part.severed = nil; part.disablingWound = nil;
            self.duration.result.recovered = true;
        }
        value.status = 'resolved'; return value;
    }
;


/** Retained calendar effect of completed physician care; no reroll or HP grant. */
class RpgExpandedCripplingCareResult: RpgExpandedResult
    monthsBefore = 0
    monthsAfter = 0
    recovered = nil
;

/** Apply B422's physician adjustment to the original duration die, never to an
 * already discounted number of months. The host supplies completed-care facts. */
class RpgExpandedCripplingCare: object
    id = nil
    duration = nil
    physician = nil
    medicalTL = nil
    evidence = nil
    boundId = nil
    boundDuration = nil
    boundPhysician = nil
    boundMedicalTL = nil
    boundEvidence = nil
    result = nil
    assess()
    {
        if (self.duration == nil || !self.duration.ofKind(RpgExpandedCripplingDuration)
            || self.duration.result == nil || self.duration.wound == nil
            || self.duration.wound.durationRecord != self.duration
            || self.duration.boundWound != self.duration.wound)
            rpgExpandedReject('crippling-care-duration');
        local profile = self.duration.wound.profile; rpgExpandedValidate(profile);
        local value = new RpgExpandedCripplingCareResult();
        if (self.result != nil)
        {
            if (!holds(self.duration.laterCare,self) || self.id != self.boundId
                || self.duration != self.boundDuration || self.physician != self.boundPhysician
                || self.medicalTL != self.boundMedicalTL || self.evidence != self.boundEvidence)
                rpgExpandedReject('crippling-care-retargeted');
            value.status = 'reused'; value.monthsBefore = self.result.monthsBefore;
            value.monthsAfter = self.result.monthsAfter; value.recovered = self.result.recovered; return value;
        }
        if (self.id == nil || self.id == '' || self.physician == nil || !self.physician.ofKind(RpgLiteProfile)
            || self.evidence == nil || self.evidence == '') rpgExpandedReject('crippling-care-evidence');
        rpgInteger(self.medicalTL,0,12);
        foreach (local prior in self.duration.laterCare)
            if (prior.id == self.id) rpgExpandedReject('crippling-care-duplicate');
        if (self.duration.result.duration != 'lasting')
        { value.reason = 'crippling-care-not-lasting'; return value; }
        if (profile.dead) { value.reason = 'crippling-care-dead'; return value; }
        if (self.duration.result.recovered) { value.reason = 'crippling-care-already-recovered'; return value; }
        if (self.duration.wound.bodyPart.disablingWound != self.duration.wound)
            rpgExpandedReject('crippling-care-current-wound');
        value.monthsBefore = self.duration.requiredMonths();
        value.monthsAfter = rpgExpandedCripplingMonths(self.duration.result.monthRoll,self.medicalTL);
        if (value.monthsAfter >= value.monthsBefore)
        { value.reason = 'crippling-care-no-shorter-recovery'; return value; }
        value.recovered = self.duration.recoveryMonths.length() >= value.monthsAfter;
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.boundId = self.id; self.boundDuration = self.duration; self.boundPhysician = self.physician;
        self.boundMedicalTL = self.medicalTL; self.boundEvidence = self.evidence;
        value.status = 'resolved'; self.result = value; self.duration.laterCare = self.duration.laterCare + [self];
        if (value.recovered)
        {
            local part = self.duration.wound.bodyPart; part.disabled = nil; part.severed = nil;
            part.disablingWound = nil; self.duration.result.recovered = true;
        }
        return value;
    }
;


/** Scale a base healing amount for full health capacity, full-2008 B424. */
rpgExpandedHealingAmount(capacity, amount)
{
    rpgInteger(capacity,1,1000); rpgInteger(amount,0,100000);
    return amount * (capacity < 20 ? 1 : capacity / 10);
}

modify RpgExpandedProfile
    naturalRecoveryConditions = 0
    naturalRecoveryInterval()
    {
        if (!self.rules.expandedNaturalRecovery) return inherited();
        local level = self.level('slow-healing'); rpgInteger(level,0,3);
        local interval = 86400;
        for (local index = 0; index < level; index += 1) interval *= 2;
        return interval;
    }
    naturalRecoveryModifier()
    {
        if (!self.rules.expandedNaturalRecovery) return inherited();
        rpgInteger(self.naturalRecoveryConditions,-100,100);
        rpgInteger(self.level('rapid-healing'),0,2); rpgInteger(self.level('very-rapid-healing'),0,1);
        local bonus = 0;
        if (self.medicalSupervision != nil)
        {
            if (!self.medicalSupervision.ofKind(RpgExpandedMedicalPractice)
                || !holds(self.medicalSupervision.patients,self)) rpgExpandedReject('medical-supervision-owner');
            local care = self.medicalSupervision.assess();
            if (care.status != 'ready') rpgExpandedReject(care.reason);
            bonus = 1;
        }
        return self.naturalRecoveryConditions + bonus
            + (self.level('rapid-healing') > 0 || self.level('very-rapid-healing') > 0 ? 5 : 0);
    }
    naturalRecoveryAmount()
    {
        if (!self.rules.expandedNaturalRecovery) return inherited();
        local base = self.level('rapid-healing') == 2 || self.level('very-rapid-healing') > 0 ? 2 : 1;
        return rpgExpandedHealingAmount(self.maxHP,base);
    }
    naturalRecoveryNeeded()
    {
        if (!self.rules.expandedNaturalRecovery) return inherited();
        return self.injury > self.diseaseInjury + self.temperatureInjury;
    }
    validateNaturalRecovery(seconds, food, allowed)
    {
        inherited(seconds,food,allowed);
        if (self.rules == nil || !self.rules.ofKind(RpgExpandedRules)) rpgExpandedReject('expanded-rules-required');
        if (!self.rules.expandedNaturalRecovery) return nil;
        rpgInteger(self.healingClock,0,2147483647 - seconds);
        rpgInteger(self.diseaseInjury,0,self.injury); rpgInteger(self.temperatureInjury,0,self.injury);
        if (self.diseaseInjury + self.temperatureInjury > self.injury)
            rpgExpandedReject('natural-recovery-protected-injury');
        local interval = self.naturalRecoveryInterval(); self.naturalRecoveryAmount();
        local modifier = food && allowed && self.naturalRecoveryNeeded() ? self.naturalRecoveryModifier() : 0;
        if (food && allowed && self.naturalRecoveryNeeded())
        {
            if (self.level('unhealing') > 0) rpgExpandedReject('natural-recovery-unhealing-context-required');
            if (self.mortal) rpgExpandedReject('natural-recovery-mortal-regimen-unavailable');
            if (self.healingClock + seconds >= interval)
            {
                local context = new RpgLiteContext(); context.attribute = rpgHT; context.kind = 'healing';
                context.modifier = modifier; local score = rpgLiteScore(self,context);
                if (score == nil || score < 3) rpgExpandedReject('natural-recovery-score-unavailable');
            }
        }
        return nil;
    }
;


/** B425 medical-help capacity and interval, before patient-specific slow healing. */
class RpgExpandedMedicalSchedule: RpgExpandedResult
    effectiveTL = 0
    patientLimit = 0
    intervalSeconds = 0
    rating = 0
;

/** Pure table lookup. Level twelve and above share the final printed row. */
rpgExpandedMedicalSchedule(techLevel)
{
    rpgInteger(techLevel,0,1000); local value = new RpgExpandedMedicalSchedule(); value.effectiveTL = techLevel;
    if (techLevel == 0) { value.reason = 'medical-no-physicians'; return value; }
    if (techLevel <= 3) { value.patientLimit = 10; value.intervalSeconds = 604800; }
    else if (techLevel == 4) { value.patientLimit = 10; value.intervalSeconds = 259200; }
    else if (techLevel == 5) { value.patientLimit = 15; value.intervalSeconds = 172800; }
    else if (techLevel == 6) { value.patientLimit = 20; value.intervalSeconds = 86400; }
    else if (techLevel == 7) { value.patientLimit = 25; value.intervalSeconds = 86400; }
    else if (techLevel == 8) { value.patientLimit = 50; value.intervalSeconds = 86400; }
    else if (techLevel == 9) { value.patientLimit = 50; value.intervalSeconds = 43200; }
    else if (techLevel == 10) { value.patientLimit = 50; value.intervalSeconds = 28800; }
    else if (techLevel == 11) { value.patientLimit = 100; value.intervalSeconds = 21600; }
    else { value.patientLimit = 200; value.intervalSeconds = 17280; }
    value.status = 'ready'; return value;
}

modify RpgLiteProfile
    medicalPractice = nil
;
modify RpgExpandedProfile
    medicalSupervision = nil
    medicalCareSince = nil
    medicalAdmittedAt = nil
    medicalCareInterval = 0
    medicalLastCheckAt = nil
    medicalChecks = []
    validateFeatures()
    {
        inherited();
        local ids = []; local latest = nil;
        foreach (local treatment in self.medicalChecks)
        {
            if (treatment == nil || !treatment.ofKind(RpgExpandedPhysicianCheck) || treatment.patient != self
                || treatment.boundPatient != self || treatment.result == nil || treatment.id != treatment.boundId
                || holds(ids,treatment.id) || treatment.completedAt == nil
                || latest != nil && treatment.completedAt < latest) rpgExpandedReject('physician-check-history');
            rpgInteger(treatment.completedAt,0,rpgLedger.seconds);
            ids = ids + [treatment.id]; latest = treatment.completedAt;
        }
        if (self.medicalLastCheckAt != latest) rpgExpandedReject('physician-check-history');
        if (self.medicalSupervision != nil)
        {
            local practice = self.medicalSupervision;
            if (!practice.ofKind(RpgExpandedMedicalPractice) || !holds(practice.patients,self)
                || practice.physician == nil || practice.physician != practice.boundPhysician
                || practice.physician.medicalPractice != practice || practice.id != practice.boundId)
                rpgExpandedReject('medical-supervision-owner');
            if (self.medicalAdmittedAt == nil || self.medicalCareSince == nil
                || self.medicalAdmittedAt > self.medicalCareSince || self.medicalCareSince > rpgLedger.seconds)
                rpgExpandedReject('medical-supervision-clock');
        }
        return nil;
    }
;

/** One physician's owned active roster. Admission selects supervision; it does
 * not execute the additional periodic physician healing check. B424-B425. */
class RpgExpandedMedicalPractice: object
    id = nil
    physician = nil
    skill = nil
    advancedEquipment = nil
    clean = nil
    available = true
    patients = []
    boundPhysician = nil
    boundId = nil
    assess()
    {
        if (self.id == nil || self.id == '' || self.physician == nil || !self.physician.ofKind(RpgLiteProfile)
            || self.skill == nil || !self.skill.ofKind(RpgLiteSkill) || self.skill.id != 'physician'
            || self.skill.techLevel == nil) rpgExpandedReject('medical-practice-definition');
        if (self.boundPhysician != nil && (self.physician != self.boundPhysician || self.id != self.boundId))
            rpgExpandedReject('medical-practice-retargeted');
        if (self.physician.medicalPractice != nil && self.physician.medicalPractice != self)
            rpgExpandedReject('medical-practice-physician-assigned');
        rpgInteger(self.skill.techLevel,0,1000); local level = self.skill.techLevel;
        local value = rpgExpandedMedicalSchedule(level);
        if (value.status != 'ready') return value;
        if (level >= 6 && !self.advancedEquipment)
        {
            if (!self.clean) { value.status = 'blocked'; value.reason = 'medical-equipment-fallback-unavailable'; return value; }
            value = rpgExpandedMedicalSchedule(6);
        }
        if (!self.available || self.physician.dead || self.physician.unconscious)
        { value.status = 'blocked'; value.reason = 'medical-physician-unavailable'; return value; }
        value.rating = self.physician.skillScore(self.skill);
        if (value.rating == nil || value.rating < 12)
        { value.status = 'blocked'; value.reason = 'medical-physician-not-qualified'; return value; }
        local seen = [];
        foreach (local patient in self.patients)
        {
            if (patient == nil || !patient.ofKind(RpgExpandedProfile) || patient.medicalSupervision != self
                || holds(seen,patient)) rpgExpandedReject('medical-practice-roster');
            seen = seen + [patient];
        }
        if (self.patients.length() > 0 && self.physician.medicalPractice != self)
            rpgExpandedReject('medical-practice-owner');
        if (self.patients.length() > value.patientLimit)
        { value.status = 'blocked'; value.reason = 'medical-practice-over-capacity'; }
        return value;
    }
    admit(patient)
    {
        if (patient == nil || !patient.ofKind(RpgExpandedProfile)) rpgExpandedReject('medical-patient-profile');
        local value = self.assess(); if (value.status != 'ready') return value;
        if (patient.medicalSupervision == self && holds(self.patients,patient))
        { value.status = 'reused'; return value; }
        if (patient.medicalSupervision != nil) rpgExpandedReject('medical-patient-already-assigned');
        if (self.patients.length() >= value.patientLimit)
        { value.status = 'blocked'; value.reason = 'medical-practice-full'; return value; }
        local slow = patient.level('slow-healing'); rpgInteger(slow,0,3);
        local interval = value.intervalSeconds;
        for (local index = 0; index < slow; index += 1) interval *= 2;
        patient.medicalAdmittedAt = rpgLedger.seconds;
        patient.medicalCareSince = rpgLedger.seconds; patient.medicalCareInterval = interval;
        self.boundPhysician = self.physician; self.boundId = self.id;
        self.physician.medicalPractice = self; self.patients = self.patients + [patient];
        patient.medicalSupervision = self; value.status = 'resolved'; return value;
    }
    release(patient)
    {
        if (self.physician == nil || self.physician != self.boundPhysician || self.id != self.boundId
            || self.physician.medicalPractice != self || patient == nil || patient.medicalSupervision != self
            || !holds(self.patients,patient)) rpgExpandedReject('medical-release-owner');
        local remaining = [];
        foreach (local member in self.patients) if (member != patient) remaining = remaining + [member];
        self.patients = remaining; patient.medicalSupervision = nil;
        patient.medicalAdmittedAt = nil;
        patient.medicalCareSince = nil; patient.medicalCareInterval = 0;
        if (remaining.length() == 0) self.physician.medicalPractice = nil;
        local value = new RpgExpandedResult(); value.status = 'resolved'; return value;
    }
;


/** Assessed or committed additional physician healing; the original check persists. */
class RpgExpandedPhysicianResult: RpgExpandedResult
    healed = 0
    injury = 0
    context = nil
    failureWound = nil
;

/** B424 outcomes: critical success doubles healing; critical failure adds one
 * injury, which is not multiplied by the B424 healing-capacity rule. */
rpgExpandedPhysicianOutcome(capacity, score, roll)
{
    rpgInteger(capacity,1,1000); rpgInteger(score,3,1000);
    local value = new RpgExpandedPhysicianResult(); value.check = rpgCheck(score,roll);
    if (value.check.achieved)
        value.healed = rpgExpandedHealingAmount(capacity,value.check.critical == 'success' ? 2 : 1);
    else if (value.check.critical == 'failure') value.injury = 1;
    value.status = 'ready'; return value;
}

/** One optional check after a completed care interval. Time was spent by the
 * parent activity; this operation observes the shared ledger and never charges it. */
class RpgExpandedPhysicianCheck: object
    id = nil
    patient = nil
    practice = nil
    continuousCare = nil
    evidence = nil
    modifier = 0
    dropDestination = nil
    boundDropDestination = nil
    boundId = nil
    boundPatient = nil
    boundPractice = nil
    boundEvidence = nil
    boundModifier = 0
    completedAt = nil
    result = nil
    assess()
    {
        if (self.patient == nil || !self.patient.ofKind(RpgExpandedProfile) || self.id == nil || self.id == '')
            rpgExpandedReject('physician-check-patient');
        rpgExpandedValidate(self.patient); local value = new RpgExpandedPhysicianResult();
        if (self.result != nil)
        {
            if (!holds(self.patient.medicalChecks,self) || self.patient != self.boundPatient || self.id != self.boundId
                || self.practice != self.boundPractice || self.evidence != self.boundEvidence
                || self.modifier != self.boundModifier || self.dropDestination != self.boundDropDestination || !self.continuousCare)
                rpgExpandedReject('physician-check-retargeted');
            value.status = 'reused'; value.check = self.result.check;
            value.healed = self.result.healed; value.injury = self.result.injury;
            value.failureWound = self.result.failureWound; return value;
        }
        foreach (local prior in self.patient.medicalChecks)
            if (prior.id == self.id) rpgExpandedReject('physician-check-duplicate');
        if (self.practice == nil || !self.practice.ofKind(RpgExpandedMedicalPractice)
            || self.patient.medicalSupervision != self.practice || !holds(self.practice.patients,self.patient))
            rpgExpandedReject('physician-check-practice');
        local schedule = self.practice.assess();
        if (schedule.status != 'ready') { value.reason = schedule.reason; return value; }
        if (!self.continuousCare || self.evidence == nil || self.evidence == '')
        { value.reason = 'physician-check-care-evidence'; return value; }
        local slow = self.patient.level('slow-healing'); rpgInteger(slow,0,3);
        local interval = schedule.intervalSeconds;
        for (local index = 0; index < slow; index += 1) interval *= 2;
        if (interval != self.patient.medicalCareInterval)
        { value.reason = 'physician-check-schedule-changed'; return value; }
        if (self.patient.medicalCareSince == nil || rpgLedger.seconds < self.patient.medicalCareSince
            || self.patient.medicalLastCheckAt != nil && rpgLedger.seconds < self.patient.medicalLastCheckAt)
            rpgExpandedReject('physician-check-clock');
        if (rpgLedger.seconds - self.patient.medicalCareSince < interval
            || self.patient.medicalLastCheckAt != nil && rpgLedger.seconds - self.patient.medicalLastCheckAt < interval)
        { value.reason = 'physician-check-not-due'; return value; }
        if (self.patient.dead || self.patient.mortal)
        { value.reason = 'physician-check-patient-condition'; return value; }
        if (self.patient.diseaseInjury > 0 || self.patient.temperatureInjury > 0 || self.patient.level('unhealing') > 0)
        { value.reason = 'physician-check-injury-eligibility-unavailable'; return value; }
        if (self.patient.injury <= 0) { value.reason = 'physician-check-no-injury'; return value; }
        rpgInteger(self.modifier,-100,100);
        value.context = new RpgLiteContext(); value.context.skill = self.practice.skill;
        value.context.kind = 'physician-care'; value.context.modifier = self.modifier;
        local score = rpgLiteScore(self.practice.physician,value.context);
        if (score == nil || score < 3) { value.reason = 'physician-check-score-unavailable'; return value; }
        value.failureWound = new RpgExpandedWound(); value.failureWound.id = 'physician-injury-' + self.id;
        value.failureWound.profile = self.patient; value.failureWound.amount = 1; value.failureWound.dropDestination = self.dropDestination;
        local failure = value.failureWound.assess();
        if (failure.status != 'ready') { value.reason = failure.reason; return value; }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local prepared = self.assess(); if (prepared.status != 'ready') return prepared;
        local check = rpgLiteCheck(self.practice.physician,prepared.context);
        local value = rpgExpandedPhysicianOutcome(self.patient.maxHP,check.score,check.roll); value.check = check;
        if (value.healed > 0) value.healed = rpgLiteHeal(self.patient,value.healed);
        else if (value.injury > 0)
        {
            local harm = prepared.failureWound.apply();
            if (harm.status != 'resolved') rpgExpandedReject('physician-injury-commit-changed');
            value.failureWound = prepared.failureWound; value.injury = harm.health.injury;
        }
        self.boundPatient = self.patient; self.boundPractice = self.practice; self.boundId = self.id;
        self.boundEvidence = self.evidence; self.boundModifier = self.modifier; self.boundDropDestination = self.dropDestination;
        self.completedAt = rpgLedger.seconds; self.patient.medicalLastCheckAt = self.completedAt;
        self.patient.medicalCareSince = self.completedAt;
        value.status = 'resolved'; self.result = value; self.patient.medicalChecks = self.patient.medicalChecks + [self];
        return value;
    }
;


/** Printed first-aid table values, full-2008 B424. tableSeconds describes the
 * table's treatment interval; bandaging is a separately described 60-second step. */
class RpgExpandedFirstAidTable: RpgExpandedResult
    tableSeconds = 0
    bandageSeconds = 60
    healingAdjustment = 0
;

/** Pure first-aid technology table, including its open-ended highest row. */
rpgExpandedFirstAidTable(techLevel)
{
    rpgInteger(techLevel,0,1000); local value = new RpgExpandedFirstAidTable();
    value.tableSeconds = techLevel <= 4 ? 1800 : techLevel <= 7 ? 1200 : 600;
    value.healingAdjustment = techLevel <= 1 ? -4 : techLevel <= 3 ? -3
        : techLevel <= 5 ? -2 : techLevel <= 7 ? -1 : techLevel == 8 ? 0 : 1;
    value.status = 'ready'; return value;
}

/** Numerical treatment outcome; healing allowances are not committed recovery. */
class RpgExpandedFirstAidOutcome: RpgExpandedResult
    bandageAllowance = 0
    bandageCredit = 0
    healingAllowance = 0
    additionalHealing = 0
    injury = 0
;

/** Assess a supplied first-aid check and recovery die. The latter is required
 * only for ordinary success. Prior actual bandage credit is reversed on critical
 * failure so the complete treatment's net effect is loss of two health. */
rpgExpandedFirstAidOutcome(capacity, techLevel, score, roll, healingRoll, bandageCredit)
{
    rpgInteger(capacity,1,1000); rpgInteger(score,3,1000);
    local table = rpgExpandedFirstAidTable(techLevel);
    local value = new RpgExpandedFirstAidOutcome(); value.check = rpgCheck(score,roll);
    value.bandageAllowance = rpgExpandedHealingAmount(capacity,1);
    rpgInteger(bandageCredit,0,value.bandageAllowance); value.bandageCredit = bandageCredit;
    if (value.check.achieved)
    {
        local die = 6;
        if (value.check.critical != 'success') { rpgInteger(healingRoll,1,6); die = healingRoll; }
        local base = die + table.healingAdjustment; if (base < 1) base = 1;
        value.healingAllowance = rpgExpandedHealingAmount(capacity,base);
        value.additionalHealing = value.healingAllowance - value.bandageAllowance;
    }
    else if (value.check.critical == 'failure') value.injury = 2 + bandageCredit;
    value.status = 'ready'; return value;
}


/** Owned bandaging of the latest supported wound. Author evidence establishes
 * that pressure or a tourniquet is appropriate for the eligible injury. B424. */
class RpgExpandedBandageResult: RpgExpandedResult
    healed = 0
    seconds = 0
;

class RpgExpandedBandage: object
    wound = nil
    healer = nil
    evidence = nil
    eligibleInjury = 0
    boundWound = nil
    boundHealer = nil
    boundEvidence = nil
    boundEligibleInjury = 0
    result = nil
    assess()
    {
        local value = new RpgExpandedBandageResult();
        if (self.wound == nil || !self.wound.ofKind(RpgExpandedWound))
            rpgExpandedReject('bandage-wound');
        if (self.result != nil)
        {
            if (self.wound != self.boundWound || self.healer != self.boundHealer
                || self.evidence != self.boundEvidence || self.eligibleInjury != self.boundEligibleInjury
                || self.wound.bandage != self) rpgExpandedReject('bandage-binding');
            value.status = 'reused'; value.healed = self.result.healed;
            return value;
        }
        if (self.wound.health == nil || self.wound.boundProfile != self.wound.profile
            || !holds(self.wound.profile.expandedWounds,self.wound))
            rpgExpandedReject('bandage-uncommitted-wound');
        local patient = self.wound.profile;
        if (self.wound.bandage != nil || patient.bandagedSerial == patient.woundSerial)
        { value.reason = 'bandage-already-treated'; return value; }
        if (self.wound.committedSerial == nil || self.wound.committedSerial != patient.woundSerial)
        { value.reason = 'bandage-earlier-wound-unavailable'; return value; }
        if (self.healer == nil || !self.healer.ofKind(RpgLiteProfile))
            rpgExpandedReject('bandage-healer');
        if (patient.dead || patient.mortal || self.healer.dead || self.healer.unconscious || self.healer.stunned)
        { value.reason = 'bandage-condition'; return value; }
        if (patient.diseaseInjury > 0 || patient.temperatureInjury > 0 || patient.level('unhealing') > 0)
        { value.reason = 'bandage-injury-eligibility-unavailable'; return value; }
        if (self.evidence == nil || self.evidence == '')
        { value.reason = 'bandage-evidence'; return value; }
        rpgInteger(self.eligibleInjury,0,100000);
        if (self.eligibleInjury == 0 || self.eligibleInjury > patient.injury
            || self.eligibleInjury > self.wound.health.injury)
        { value.reason = 'bandage-eligible-injury'; return value; }
        if (patient.unconscious && patient.fp() > 0 && patient.ht < 3)
        { value.reason = 'bandage-wake-score-unavailable'; return value; }
        value.healed = rpgExpandedHealingAmount(patient.maxHP,1);
        if (value.healed > self.eligibleInjury) value.healed = self.eligibleInjury;
        value.seconds = 60; value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local patient = self.wound.profile;
        rpgSpendTime(value.seconds);
        value.healed = rpgLiteHeal(patient,value.healed);
        patient.bandagedSerial = patient.woundSerial;
        self.boundWound = self.wound; self.boundHealer = self.healer;
        self.boundEvidence = self.evidence; self.boundEligibleInjury = self.eligibleInjury;
        self.wound.bandage = self; value.status = 'resolved'; self.result = value;
        return value;
    }
;

/** Post-bandaging treatment for an uninterrupted authored care interval, B424. */
class RpgExpandedFirstAidResult: RpgExpandedResult
    healed = 0
    injury = 0
    healingRoll = nil
    context = nil
    failureWound = nil
;

modify RpgExpandedBandage
    treatment = nil
;

class RpgExpandedFirstAid: object
    bandage = nil
    healer = nil
    skill = nil
    modifier = 0
    careEvidence = nil
    comfortable = nil
    dropDestination = nil
    boundBandage = nil
    boundHealer = nil
    boundSkill = nil
    boundModifier = 0
    boundEvidence = nil
    boundDestination = nil
    result = nil
    assess()
    {
        local value = new RpgExpandedFirstAidResult();
        if (self.bandage == nil || !self.bandage.ofKind(RpgExpandedBandage))
            rpgExpandedReject('first-aid-bandage');
        if (self.result != nil)
        {
            if (self.bandage != self.boundBandage || self.healer != self.boundHealer
                || self.skill != self.boundSkill || self.modifier != self.boundModifier
                || self.careEvidence != self.boundEvidence || self.dropDestination != self.boundDestination
                || !self.comfortable || self.bandage.treatment != self)
                rpgExpandedReject('first-aid-binding');
            value.status = 'reused'; value.check = self.result.check; value.healed = self.result.healed;
            value.injury = self.result.injury; value.healingRoll = self.result.healingRoll;
            value.failureWound = self.result.failureWound; return value;
        }
        if (self.bandage.result == nil || self.bandage.assess().status != 'reused')
            rpgExpandedReject('first-aid-bandage-incomplete');
        local wound = self.bandage.wound; local patient = wound.profile;
        if (self.bandage.treatment != nil || patient.aidUsed)
        { value.reason = 'first-aid-already-treated'; return value; }
        if (wound.committedSerial != patient.woundSerial)
        { value.reason = 'first-aid-earlier-wound-unavailable'; return value; }
        if (self.healer == nil || !self.healer.ofKind(RpgLiteProfile)
            || self.skill == nil || !self.skill.ofKind(RpgLiteSkill)
            || self.skill.id != 'first-aid' || self.skill.techLevel == nil)
            rpgExpandedReject('first-aid-definition');
        if (patient.dead || patient.mortal || self.healer.dead || self.healer.unconscious || self.healer.stunned)
        { value.reason = 'first-aid-condition'; return value; }
        if (patient.diseaseInjury > 0 || patient.temperatureInjury > 0 || patient.level('unhealing') > 0)
        { value.reason = 'first-aid-injury-eligibility-unavailable'; return value; }
        if (!self.comfortable || self.careEvidence == nil || self.careEvidence == '')
        { value.reason = 'first-aid-care-evidence'; return value; }
        if (patient.injury <= 0)
        { value.reason = 'first-aid-no-injury'; return value; }
        rpgInteger(self.modifier,-100,100);
        value.seconds = rpgExpandedFirstAidTable(self.skill.techLevel).tableSeconds;
        value.context = new RpgLiteContext(); value.context.skill = self.skill;
        value.context.kind = 'first-aid'; value.context.modifier = self.modifier;
        local score = rpgLiteScore(self.healer,value.context);
        if (score == nil || score < 3)
        { value.reason = 'first-aid-score-unavailable'; return value; }
        if (patient.unconscious && patient.fp() > 0 && patient.ht < 3)
        { value.reason = 'first-aid-wake-score-unavailable'; return value; }
        value.failureWound = new RpgExpandedWound(); value.failureWound.id = 'first-aid-injury-' + wound.id;
        value.failureWound.profile = patient; value.failureWound.amount = 2 + self.bandage.result.healed;
        value.failureWound.dropDestination = self.dropDestination;
        local failure = value.failureWound.assess();
        if (failure.status != 'ready') { value.reason = failure.reason; return value; }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local patient = self.bandage.wound.profile;
        rpgSpendTime(value.seconds);
        value.check = rpgLiteCheck(self.healer,value.context);
        if (value.check.achieved && value.check.critical != 'success') value.healingRoll = rpgRandom.die();
        local outcome = rpgExpandedFirstAidOutcome(patient.maxHP,self.skill.techLevel,
            value.check.score,value.check.roll,value.healingRoll,self.bandage.result.healed);
        if (outcome.injury > 0)
        {
            local harm = value.failureWound.apply();
            if (harm.status != 'resolved') rpgExpandedReject('first-aid-injury-commit-changed');
            value.injury = harm.health.injury;
        }
        else
        {
            value.failureWound = nil;
            local eligible = self.bandage.eligibleInjury - self.bandage.result.healed;
            if (outcome.additionalHealing < eligible) eligible = outcome.additionalHealing;
            if (eligible > 0) value.healed = rpgLiteHeal(patient,eligible);
        }
        patient.aidUsed = true; self.bandage.treatment = self;
        self.boundBandage = self.bandage; self.boundHealer = self.healer; self.boundSkill = self.skill;
        self.boundModifier = self.modifier; self.boundEvidence = self.careEvidence; self.boundDestination = self.dropDestination;
        value.status = 'resolved'; self.result = value; return value;
    }
;

/** Surgical roll inputs from full-2008 B223/B424. No operation is committed. */
class RpgExpandedSurgeryAssessment: RpgExpandedResult
    equipmentModifier = 0
    anestheticModifier = 0
    cleanlinessModifier = 0
    siteModifier = 0
    diagnosisModifier = 0
    trainingModifier = 0
    infectionCheckRequired = nil
;

class RpgExpandedSurgeryContext: object
    techLevel = 8
    anesthetic = true
    sterile = true
    site = 'other'
    diagnosed = true
    physicianTrained = true
    fieldExpedient = nil
    equipmentQualityModifier = 0
    physiologyModifier = 0
    otherMissingEquipmentModifier = 0
    earlyAntisepsis = nil
    assess()
    {
        rpgInteger(self.techLevel,0,1000);
        rpgInteger(self.equipmentQualityModifier,-100,100);
        rpgInteger(self.physiologyModifier,-100,100);
        rpgInteger(self.otherMissingEquipmentModifier,-100,0);
        if (!holds(['head','chest','other'],self.site)) rpgExpandedReject('surgery-site');
        local value = new RpgExpandedSurgeryAssessment();
        if (self.techLevel == 0) { value.reason = 'surgery-technology-unavailable'; return value; }
        value.equipmentModifier = self.techLevel == 1 ? -6 : self.techLevel <= 3 ? -5
            : self.techLevel == 4 ? -4 : self.techLevel == 5 ? -2 : self.techLevel - 6;
        value.anestheticModifier = self.techLevel >= 5 && !self.anesthetic ? -2 : 0;
        value.cleanlinessModifier = self.sterile ? 0 : -3;
        value.siteModifier = self.site == 'other' ? 0 : -3;
        value.diagnosisModifier = self.diagnosed ? 0 : -5;
        value.trainingModifier = self.physicianTrained || self.fieldExpedient ? 0 : -5;
        value.infectionCheckRequired = self.techLevel < 5 || self.techLevel == 5 && self.earlyAntisepsis;
        value.modifier = value.equipmentModifier + value.anestheticModifier + value.cleanlinessModifier
            + value.siteModifier + value.diagnosisModifier + value.trainingModifier
            + self.equipmentQualityModifier + self.physiologyModifier + self.otherMissingEquipmentModifier;
        value.status = 'ready'; return value;
    }
;

/** Source failure damage only; operation-specific consequences remain separate. */
class RpgExpandedSurgeryOutcome: RpgExpandedResult
    damageDice = 0
    damage = 0
;

rpgExpandedSurgeryOutcome(score, roll, simpleAmputation, damageRolls)
{
    rpgInteger(score,3,1000);
    local value = new RpgExpandedSurgeryOutcome(); value.check = rpgCheck(score,roll);
    if (!value.check.achieved)
    {
        value.damageDice = simpleAmputation ? 2 : 3;
        if (damageRolls == nil || damageRolls.length() != value.damageDice)
            rpgExpandedReject('surgery-damage-dice');
        foreach (local die in damageRolls) { rpgInteger(die,1,6); value.damage += die; }
    }
    value.status = 'ready'; return value;
}

/** Resuscitation skill and cause modifiers, full-2008 B425. No attempt committed. */
rpgExpandedResuscitationProcedure(skillKind, medicalTL, trained, modernTechnique, cause)
{
    rpgInteger(medicalTL,0,1000);
    if (!holds(['physician','first-aid'],skillKind)) rpgExpandedReject('resuscitation-skill');
    if (!holds(['drowning','asphyxiation','heart-attack'],cause)) rpgExpandedReject('resuscitation-cause');
    local value = new RpgExpandedResult();
    if (medicalTL < 7) { value.reason = 'resuscitation-technology-unavailable'; return value; }
    value.seconds = 60;
    if (skillKind == 'first-aid')
        value.modifier = trained && modernTechnique && cause != 'heart-attack' ? -2 : -4;
    value.status = 'ready'; return value;
}

class RpgExpandedCardiacHealth: RpgExpandedResult
    totalInjury = 0
    addedInjury = 0
;

/** Post-arrest health floor, B429; this is a condition consequence, not an attack. */
rpgExpandedCardiacHealth(capacity, injury, survived)
{
    rpgInteger(capacity,1,1000); rpgInteger(injury,0,100000);
    local value = new RpgExpandedCardiacHealth(); local minimum = capacity * (survived ? 1 : 2);
    value.totalInjury = injury > minimum ? injury : minimum;
    value.addedInjury = value.totalInjury - injury; value.status = 'ready'; return value;
}

class RpgExpandedCardiacResult: RpgExpandedResult
    prevented = nil
    fatigueAdded = 0
    injuryAdded = 0
    deadline = nil
;

modify RpgExpandedProfile
    cardiacArrest = nil
    cardiacHistory = []
;

/** Owned onset, treatment receipts and untreated deadline. */
class RpgExpandedCardiacArrest: object
    id = nil
    profile = nil
    evidence = nil
    startedAt = nil
    deadline = nil
    startingHealth = nil
    onset = nil
    fatalResult = nil
    automaticDeadline = nil
    attempts = []
    revivedBy = nil
    endedAt = nil
    boundId = nil
    boundProfile = nil
    boundEvidence = nil
    validateBinding()
    {
        if (self.id != self.boundId || self.profile != self.boundProfile || self.evidence != self.boundEvidence
            || !holds(self.profile.cardiacHistory,self)) rpgExpandedReject('cardiac-binding');
        return nil;
    }
    assessOnset()
    {
        local value = new RpgExpandedCardiacResult();
        if (self.startedAt != nil)
        {
            self.validateBinding(); value.status = 'reused'; value.prevented = self.onset.prevented;
            value.fatigueAdded = self.onset.fatigueAdded; value.deadline = self.onset.deadline; return value;
        }
        if (self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)) rpgExpandedReject('cardiac-profile');
        if (self.id == nil || self.id == '') rpgExpandedReject('cardiac-id');
        if (self.evidence == nil || self.evidence == '') { value.reason = 'cardiac-trigger-evidence'; return value; }
        if (self.profile.dead) { value.reason = 'cardiac-patient-dead'; return value; }
        if (self.profile.cardiacArrest != nil) { value.reason = 'cardiac-already-active'; return value; }
        foreach (local prior in self.profile.cardiacHistory)
            if (prior.id == self.id) rpgExpandedReject('cardiac-duplicate');
        rpgInteger(self.profile.ht,1,1000); rpgInteger(self.profile.maxEnergy,1,1000);
        rpgInteger(self.profile.fatigue,0,2 * self.profile.maxEnergy);
        value.prevented = self.profile.level('diffuse') > 0 || self.profile.level('homogenous') > 0
            || self.profile.level('no-vitals') > 0;
        if (!value.prevented)
        {
            value.fatigueAdded = 2 * self.profile.maxEnergy - self.profile.fatigue;
            rpgInteger(rpgLedger.seconds,0,2147483647 - self.profile.ht * 20);
            value.deadline = rpgLedger.seconds + self.profile.ht * 20;
        }
        value.status = 'ready'; return value;
    }
    start()
    {
        local value = self.assessOnset(); if (value.status != 'ready') return value;
        if (!value.prevented)
        {
            self.profile.fatigue = 2 * self.profile.maxEnergy;
            self.profile.unconscious = true; self.profile.fatigueCollapse = true;
            self.profile.cardiacArrest = self;
        }
        self.boundId = self.id; self.boundProfile = self.profile; self.boundEvidence = self.evidence;
        self.startingHealth = self.profile.ht; self.startedAt = rpgLedger.seconds; self.deadline = value.deadline;
        if (value.prevented) self.endedAt = self.startedAt;
        self.profile.cardiacHistory = self.profile.cardiacHistory + [self];
        value.status = 'resolved'; self.onset = value;
        self.automaticDeadline = !value.prevented && self.profile.rules != nil
            && self.profile.rules.automaticCardiacDeadlines;
        if (self.automaticDeadline) rpgExpandedCardiacClock.arrests = rpgExpandedCardiacClock.arrests + [self];
        return value;
    }
    assessExpiry()
    {
        local value = new RpgExpandedCardiacResult();
        if (self.startedAt == nil) { value.reason = 'cardiac-not-started'; return value; }
        self.validateBinding();
        if (self.fatalResult != nil)
        { value.status = 'reused'; value.injuryAdded = self.fatalResult.injuryAdded; value.deadline = self.deadline; return value; }
        if (self.onset.prevented) { value.reason = 'cardiac-immune'; return value; }
        if (self.revivedBy != nil) { value.reason = 'cardiac-already-revived'; return value; }
        if (self.profile.dead) { value.reason = 'cardiac-other-death-unavailable'; return value; }
        if (self.profile.cardiacArrest != self) rpgExpandedReject('cardiac-owner');
        if (rpgLedger.seconds < self.deadline) { value.reason = 'cardiac-deadline-not-reached'; return value; }
        value.injuryAdded = rpgExpandedCardiacHealth(self.profile.maxHP,self.profile.injury,nil).addedInjury;
        value.deadline = self.deadline; value.status = 'ready'; return value;
    }
    expire()
    {
        local value = self.assessExpiry(); if (value.status != 'ready') return value;
        self.profile.injury += value.injuryAdded;
        self.profile.dead = true; self.profile.unconscious = true; self.profile.cardiacArrest = nil;
        self.endedAt = self.deadline; value.status = 'resolved'; self.fatalResult = value; return value;
    }
;

modify RpgExpandedProfile
    validateNaturalRecovery(seconds, food, allowed)
    {
        inherited(seconds,food,allowed);
        if (self.cardiacArrest != nil) rpgExpandedReject('cardiac-resuscitation-required');
        return nil;
    }
    validateFeatures()
    {
        inherited(); local ids = []; local active = nil;
        foreach (local arrest in self.cardiacHistory)
        {
            if (arrest == nil || !arrest.ofKind(RpgExpandedCardiacArrest) || arrest.profile != self
                || holds(ids,arrest.id) || arrest.startedAt == nil || arrest.startedAt > rpgLedger.seconds || arrest.onset == nil)
                rpgExpandedReject('cardiac-history');
            arrest.validateBinding(); ids = ids + [arrest.id];
            if (arrest.automaticDeadline != holds(rpgExpandedCardiacClock.arrests,arrest))
                rpgExpandedReject('cardiac-clock-registration');
            local attempts = []; local lastAttemptAt = arrest.startedAt;
            foreach (local attempt in arrest.attempts)
            {
                if (attempt == nil || !attempt.ofKind(RpgExpandedCardiacResuscitation) || attempt.arrest != arrest
                    || holds(attempts,attempt.id) || attempt.result == nil || attempt.startedAt < lastAttemptAt
                    || attempt.completedAt != attempt.startedAt + 60 || attempt.completedAt >= arrest.deadline
                    || attempt.completedAt > rpgLedger.seconds || attempt.assess().status != 'reused')
                    rpgExpandedReject('cardiac-treatment-history');
                if (attempt.result.revived && arrest.revivedBy != attempt) rpgExpandedReject('cardiac-revival-owner');
                attempts = attempts + [attempt.id]; lastAttemptAt = attempt.completedAt;
            }
            if (arrest.onset.prevented)
            {
                if (arrest.deadline != nil || arrest.endedAt != arrest.startedAt || arrest.fatalResult != nil
                    || arrest.onset.fatigueAdded != 0 || arrest.attempts.length() > 0 || arrest.revivedBy != nil) rpgExpandedReject('cardiac-immunity-history');
            }
            else
            {
                if (arrest.deadline != arrest.startedAt + arrest.startingHealth * 20 || arrest.onset.deadline != arrest.deadline)
                    rpgExpandedReject('cardiac-deadline-history');
                if (arrest.revivedBy != nil)
                {
                    if (!holds(arrest.attempts,arrest.revivedBy) || !arrest.revivedBy.result.revived
                        || arrest.fatalResult != nil || arrest.endedAt != arrest.revivedBy.completedAt || lastAttemptAt != arrest.endedAt)
                        rpgExpandedReject('cardiac-revival-history');
                }
                else if (arrest.fatalResult == nil)
                {
                    if (active != nil || arrest.endedAt != nil) rpgExpandedReject('cardiac-active-history');
                    active = arrest;
                }
                else if (arrest.endedAt != arrest.deadline || arrest.endedAt > rpgLedger.seconds || !self.dead)
                    rpgExpandedReject('cardiac-fatal-history');
            }
        }
        if (self.cardiacArrest != active) rpgExpandedReject('cardiac-owner-history');
        return nil;
    }
;


class RpgExpandedCardiacResuscitationResult: RpgExpandedResult
    context = nil
    revived = nil
    injuryAdded = 0
;

/** One uninterrupted minute of cardiac resuscitation. B425, B429. */
class RpgExpandedCardiacResuscitation: object
    id = nil
    arrest = nil
    healer = nil
    skill = nil
    modifier = 0
    careEvidence = nil
    startedAt = nil
    completedAt = nil
    result = nil
    boundId = nil
    boundArrest = nil
    boundHealer = nil
    boundSkill = nil
    boundModifier = 0
    boundEvidence = nil
    assess()
    {
        local value = new RpgExpandedCardiacResuscitationResult();
        if (self.arrest == nil || !self.arrest.ofKind(RpgExpandedCardiacArrest)) rpgExpandedReject('resuscitation-arrest');
        if (self.arrest.startedAt == nil) { value.reason = 'cardiac-not-started'; return value; }
        self.arrest.validateBinding();
        if (self.result != nil)
        {
            if (self.id != self.boundId || self.arrest != self.boundArrest || self.healer != self.boundHealer
                || self.skill != self.boundSkill || self.modifier != self.boundModifier || self.careEvidence != self.boundEvidence
                || !holds(self.arrest.attempts,self)) rpgExpandedReject('resuscitation-binding');
            value.status = 'reused'; value.check = self.result.check; value.revived = self.result.revived;
            value.injuryAdded = self.result.injuryAdded; return value;
        }
        if (self.id == nil || self.id == '') rpgExpandedReject('resuscitation-id');
        foreach (local attempt in self.arrest.attempts)
            if (attempt.id == self.id) rpgExpandedReject('resuscitation-duplicate');
        local patient = self.arrest.profile;
        if (patient.dead || self.arrest.onset.prevented || self.arrest.revivedBy != nil || patient.cardiacArrest != self.arrest)
        { value.reason = 'resuscitation-no-active-arrest'; return value; }
        if (self.healer == nil || !self.healer.ofKind(RpgLiteProfile) || self.skill == nil || !self.skill.ofKind(RpgLiteSkill)
            || !holds(['first-aid','physician'],self.skill.id) || self.skill.techLevel == nil
            || self.skill.attribute != rpgIQ || self.skill.difficulty != (self.skill.id == 'first-aid' ? 0 : 2))
            rpgExpandedReject('resuscitation-definition');
        if (self.healer.dead || self.healer.unconscious || self.healer.stunned || self.healer.mentalStun
            || self.healer.mortal || self.healer.fp() <= 0 || patient.mortal)
        { value.reason = 'resuscitation-condition-unavailable'; return value; }
        if (self.careEvidence == nil || self.careEvidence == '')
        { value.reason = 'resuscitation-care-evidence'; return value; }
        rpgInteger(self.modifier,-100,100);
        local trained = nil;
        foreach (local training in self.healer.skills)
            if (training.skill == self.skill && training.points > 0) trained = true;
        local procedure = rpgExpandedResuscitationProcedure(self.skill.id,self.skill.techLevel,trained,nil,'heart-attack');
        if (procedure.status != 'ready') { value.reason = procedure.reason; return value; }
        if (rpgLedger.seconds + procedure.seconds >= self.arrest.deadline)
        { value.reason = 'resuscitation-insufficient-time'; return value; }
        value.context = new RpgLiteContext(); value.context.skill = self.skill; value.context.kind = 'resuscitation';
        value.context.modifier = procedure.modifier + self.modifier;
        local score = rpgLiteScore(self.healer,value.context);
        if (score == nil || score < 3) { value.reason = 'resuscitation-score-unavailable'; return value; }
        rpgExpandedCardiacHealth(patient.maxHP,patient.injury,true);
        value.seconds = procedure.seconds; value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.startedAt = rpgLedger.seconds; rpgSpendTime(value.seconds);
        value.check = rpgLiteCheck(self.healer,value.context); value.revived = value.check.achieved;
        if (value.revived)
        {
            local patient = self.arrest.profile;
            value.injuryAdded = rpgExpandedCardiacHealth(patient.maxHP,patient.injury,true).addedInjury;
            patient.injury += value.injuryAdded; patient.cardiacArrest = nil;
            self.arrest.revivedBy = self; self.arrest.endedAt = rpgLedger.seconds;
        }
        self.boundId = self.id; self.boundArrest = self.arrest; self.boundHealer = self.healer; self.boundSkill = self.skill;
        self.boundModifier = self.modifier; self.boundEvidence = self.careEvidence; self.completedAt = rpgLedger.seconds;
        self.arrest.attempts = self.arrest.attempts + [self]; value.status = 'resolved'; self.result = value; return value;
    }
;

class RpgExpandedExhaustionOutcome: RpgExpandedResult
    allowed = nil
    incapacitated = nil
    unconscious = nil
    cardiacTrigger = nil
    healthCheck = nil
;

/** Pure B426 action assessment with supplied rolls and existing collapse state. */
rpgExpandedExhaustionOutcome(remaining, capacity, collapsed, purpose, willScore, willRoll, healthScore, healthRoll)
{
    rpgInteger(capacity,1,1000); rpgInteger(remaining,-capacity,capacity);
    if (!holds(['action','talk','rest','do-nothing'],purpose)) rpgExpandedReject('exhaustion-purpose');
    local value = new RpgExpandedExhaustionOutcome(); value.status = 'ready';
    if (remaining <= -capacity)
    {
        value.unconscious = true; value.incapacitated = true;
        value.allowed = purpose == 'rest' || purpose == 'do-nothing';
        if (!value.allowed) value.reason = 'exhaustion-unconscious';
        return value;
    }
    if (collapsed && remaining <= 0)
    {
        value.incapacitated = true; value.allowed = purpose == 'rest' || purpose == 'do-nothing';
        if (!value.allowed) value.reason = 'exhaustion-collapse';
        return value;
    }
    if (remaining > 0 || purpose != 'action') { value.allowed = true; return value; }
    rpgInteger(willScore,3,1000); value.check = rpgCheck(willScore,willRoll);
    value.allowed = value.check.achieved;
    if (!value.allowed)
    {
        value.incapacitated = true; value.reason = 'exhaustion-effort-failed';
        if (value.check.critical == 'failure')
        {
            rpgInteger(healthScore,3,1000); value.healthCheck = rpgCheck(healthScore,healthRoll);
            value.cardiacTrigger = !value.healthCheck.achieved;
        }
    }
    return value;
}

/** Low-fatigue Move/Dodge/effective ST arithmetic; do not use for HP or damage. */
rpgExpandedLowFatigueValue(value, remaining, capacity)
{
    rpgInteger(value,0,100000); rpgInteger(capacity,1,1000); rpgInteger(remaining,-capacity,capacity);
    return remaining * 3 < capacity ? (value + 1) / 2 : value;
}

modify RpgExpandedProfile
    exhaustionCollapsed = nil
    effortHistory = []
    afterFatigueRecovery()
    {
        inherited(); if (self.fp() > 0) self.exhaustionCollapsed = nil; return nil;
    }
    exhaustionBlocksAction() { return inherited() || self.exhaustionCollapsed && self.fp() <= 0; }
    healthBlocksDefense() { return inherited() || self.exhaustionBlocksAction() || self.cardiacArrest != nil; }
;

class RpgExpandedEffortResult: RpgExpandedExhaustionOutcome
    consciousnessContext = nil
    consciousnessCheck = nil
    willContext = nil
    healthContext = nil
    cardiac = nil
    requiresCheck = nil
;

/** One permission request for an authored action; the action owns time and costs. */
class RpgExpandedEffort: object
    id = nil
    profile = nil
    purpose = 'action'
    evidence = nil
    result = nil
    completedAt = nil
    boundId = nil
    boundProfile = nil
    boundPurpose = nil
    boundEvidence = nil
    assess()
    {
        local value = new RpgExpandedEffortResult();
        if (self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)) rpgExpandedReject('effort-profile');
        if (self.result != nil)
        {
            if (self.id != self.boundId || self.profile != self.boundProfile || self.purpose != self.boundPurpose
                || self.evidence != self.boundEvidence || !holds(self.profile.effortHistory,self)) rpgExpandedReject('effort-binding');
            value.status = 'reused'; value.allowed = self.result.allowed; value.incapacitated = self.result.incapacitated;
            value.unconscious = self.result.unconscious; value.cardiacTrigger = self.result.cardiacTrigger;
            value.check = self.result.check; value.healthCheck = self.result.healthCheck; value.cardiac = self.result.cardiac;
            value.consciousnessCheck = self.result.consciousnessCheck;
            value.reason = self.result.reason; return value;
        }
        if (self.id == nil || self.id == '') rpgExpandedReject('effort-id');
        if (!holds(['action','talk','rest','do-nothing'],self.purpose)) rpgExpandedReject('exhaustion-purpose');
        if (self.evidence == nil || self.evidence == '') { value.reason = 'effort-action-evidence'; return value; }
        foreach (local prior in self.profile.effortHistory)
            if (prior.id == self.id) rpgExpandedReject('effort-duplicate');
        if (self.profile.dead || self.profile.cardiacArrest != nil)
        { value.reason = 'effort-condition-unavailable'; return value; }
        if (holds(['action','talk'],self.purpose) && (self.profile.unconscious || self.profile.mortal
            || self.profile.stunned || self.profile.mentalStun))
        { value.reason = 'effort-other-incapacity'; return value; }
        rpgInteger(self.profile.maxEnergy,1,1000); rpgInteger(self.profile.fp(),-self.profile.maxEnergy,self.profile.maxEnergy);
        value.requiresCheck = self.purpose == 'action' && self.profile.fp() <= 0
            && self.profile.fp() > -self.profile.maxEnergy && !self.profile.exhaustionCollapsed;
        if (value.requiresCheck)
        {
            value.willContext = new RpgLiteContext(); value.willContext.attribute = rpgWill; value.willContext.kind = 'effort';
            value.healthContext = new RpgLiteContext(); value.healthContext.attribute = rpgHT; value.healthContext.kind = 'cardiac-resistance';
            local will = rpgLiteScore(self.profile,value.willContext); local health = rpgLiteScore(self.profile,value.healthContext);
            if (will == nil || will < 3 || health == nil || health < 3)
            { value.reason = 'effort-score-unavailable'; return value; }
            value.cardiac = new RpgExpandedCardiacArrest(); value.cardiac.id = 'effort-' + self.id;
            value.cardiac.profile = self.profile; value.cardiac.evidence = 'Critical exhausted effort followed by failed health resistance';
            local cardiac = value.cardiac.assessOnset();
            if (cardiac.status != 'ready') { value.reason = cardiac.reason; return value; }
        }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local willScore = 0; local willRoll = 0; local healthScore = 0; local healthRoll = 0;
        if (value.requiresCheck)
        {
            value.check = rpgLiteCheck(self.profile,value.willContext); willScore = value.check.score; willRoll = value.check.roll;
            if (value.check.critical == 'failure')
            {
                value.healthCheck = rpgLiteCheck(self.profile,value.healthContext);
                healthScore = value.healthCheck.score; healthRoll = value.healthCheck.roll;
            }
        }
        local outcome = rpgExpandedExhaustionOutcome(self.profile.fp(),self.profile.maxEnergy,
            self.profile.exhaustionCollapsed,self.purpose,willScore,willRoll,healthScore,healthRoll);
        value.allowed = outcome.allowed; value.incapacitated = outcome.incapacitated; value.unconscious = outcome.unconscious;
        value.cardiacTrigger = outcome.cardiacTrigger; value.reason = outcome.reason;
        if (self.profile.fp() > 0) self.profile.exhaustionCollapsed = nil;
        else if (value.incapacitated) self.profile.exhaustionCollapsed = true;
        if (value.unconscious) { self.profile.unconscious = true; self.profile.fatigueCollapse = true; }
        if (value.cardiacTrigger)
        {
            local cardiac = value.cardiac.start();
            if (cardiac.status != 'resolved') rpgExpandedReject('effort-cardiac-commit-changed');
            value.unconscious = self.profile.unconscious;
        }
        else value.cardiac = nil;
        self.boundId = self.id; self.boundProfile = self.profile; self.boundPurpose = self.purpose; self.boundEvidence = self.evidence;
        self.completedAt = rpgLedger.seconds; self.profile.effortHistory = self.profile.effortHistory + [self];
        value.status = 'resolved'; self.result = value; return value;
    }
;

modify RpgExpandedProfile
    validateFeatures()
    {
        inherited(); local ids = [];
        foreach (local effort in self.effortHistory)
        {
            if (effort == nil || !effort.ofKind(RpgExpandedEffort) || effort.profile != self || effort.result == nil
                || holds(ids,effort.id) || effort.completedAt == nil || effort.completedAt > rpgLedger.seconds
                || effort.assess().status != 'reused') rpgExpandedReject('effort-history');
            if (effort.result.cardiac != nil && (!effort.result.cardiacTrigger
                || effort.result.cardiac.profile != self || !holds(self.cardiacHistory,effort.result.cardiac)))
                rpgExpandedReject('effort-cardiac-history');
            ids = ids + [effort.id];
        }
        return nil;
    }
;

/** One owned active-turn permission combining exhaustion and injury consciousness. */
class RpgExpandedActionGate: RpgExpandedEffort
    assess()
    {
        local value = inherited();
        if (value.status != 'ready') return value;
        if (!holds(['action','do-nothing'],self.purpose)) rpgExpandedReject('action-gate-purpose');
        if (self.profile.unconscious || self.profile.mortal)
        { value.status = 'blocked'; value.reason = 'action-gate-incapacity'; return value; }
        if (self.purpose != 'do-nothing' && self.profile.hp() <= 0)
        {
            rpgInteger(self.profile.maxHP,1,1000);
            value.consciousnessContext = new RpgLiteContext();
            value.consciousnessContext.attribute = rpgHT;
            value.consciousnessContext.kind = 'consciousness';
            value.consciousnessContext.modifier = -(-self.profile.hp() / self.profile.maxHP);
            local score = rpgLiteScore(self.profile,value.consciousnessContext);
            if (score == nil || score < 3)
            { value.status = 'blocked'; value.reason = 'action-gate-consciousness-score'; }
        }
        return value;
    }
    apply()
    {
        local value = inherited();
        if (value.status != 'resolved' || !value.allowed || value.consciousnessContext == nil) return value;
        value.consciousnessCheck = rpgLiteCheck(self.profile,value.consciousnessContext);
        if (!value.consciousnessCheck.achieved)
        {
            self.profile.unconscious = true; value.unconscious = true; value.incapacitated = true;
            value.allowed = nil; value.reason = 'action-gate-unconscious';
        }
        return value;
    }
;


/** Opt-in maneuver adapter; each authored turn owns one fresh action gate. */
class RpgExpandedHealthManeuver: RpgLiteManeuver
    healthGate = nil
    healthAvailable(fighter)
    {
        if (self.healthGate == nil || !self.healthGate.ofKind(RpgExpandedActionGate)
            || self.healthGate.profile != fighter.profile
            || self.healthGate.purpose != (self.kind == 'nothing' ? 'do-nothing' : 'action'))
            rpgExpandedReject('maneuver-health-gate');
        if (self.healthGate.result != nil) return 'maneuver-health-gate-used';
        local value = self.healthGate.assess();
        return value.status == 'ready' ? nil : value.reason;
    }
    canAct(fighter)
    {
        local reason = self.healthAvailable(fighter);
        if (reason != nil) rpgExpandedReject(reason);
        local value = self.healthGate.apply();
        if (value.status != 'resolved') rpgExpandedReject('maneuver-health-gate-changed');
        return value.allowed;
    }
;


modify RpgExpandedProfile
    healthAttributeModifier(context)
    {
        local amount = inherited(context);
        if (self.rules == nil || !self.rules.ofKind(RpgExpandedRules)) rpgExpandedReject('expanded-rules-required');
        if (!self.rules.expandedFatigueStrength || context.controllingAttribute() != rpgST) return amount;
        local effective = rpgExpandedLowFatigueValue(self.st,self.fp(),self.maxEnergy);
        if (effective == self.st) return amount;
        if (context.skill != nil)
        {
            local trained = nil;
            foreach (local training in self.skills)
                if (training.skill == context.skill && training.points > 0) trained = true;
            if (!trained) rpgExpandedReject('fatigue-strength-default-unavailable');
        }
        return amount + effective - self.st;
    }
;


/** Only registered cardiac deadlines; all entries retain their owned receipts. */
rpgExpandedCardiacClock: object
    arrests = []
    validateThrough(target)
    {
        local seen = [];
        foreach (local arrest in self.arrests)
        {
            if (arrest == nil || !arrest.ofKind(RpgExpandedCardiacArrest) || !arrest.automaticDeadline
                || holds(seen,arrest) || arrest.onset == nil || arrest.onset.prevented)
                rpgExpandedReject('cardiac-clock-registration');
            seen = seen + [arrest]; arrest.validateBinding();
            if (arrest.deadline != arrest.startedAt + arrest.startingHealth * 20
                || arrest.deadline != arrest.onset.deadline) rpgExpandedReject('cardiac-deadline-history');
            if (arrest.revivedBy != nil || arrest.fatalResult != nil) continue;
            if (arrest.profile.cardiacArrest != arrest) rpgExpandedReject('cardiac-clock-owner');
            if (target >= arrest.deadline)
            {
                if (arrest.profile.dead) rpgExpandedReject('cardiac-other-death-unavailable');
                rpgExpandedCardiacHealth(arrest.profile.maxHP,arrest.profile.injury,nil);
            }
        }
        return nil;
    }
    dispatch()
    {
        foreach (local arrest in self.arrests)
            if (arrest.revivedBy == nil && arrest.fatalResult == nil && rpgLedger.seconds >= arrest.deadline)
            {
                local value = arrest.expire();
                if (value.status != 'resolved') rpgExpandedReject('cardiac-clock-expiry-changed');
            }
        return nil;
    }
;

modify rpgLedger
    validateAdvance(seconds)
    {
        inherited(seconds); rpgExpandedCardiacClock.validateThrough(self.seconds + seconds); return nil;
    }
    afterAdvance(previousSeconds)
    {
        inherited(previousSeconds); rpgExpandedCardiacClock.dispatch(); return nil;
    }
;
