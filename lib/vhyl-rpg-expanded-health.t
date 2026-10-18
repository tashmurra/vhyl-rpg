/* Include after expanded foundation. Sources: full-2008, B360-B361, B419-B429.
 * Partial owned injury, medical care and condition support; see the module guide. */

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
        return rpgExpandedInjuryShock(self.maxHP,amount) * (self.level('low-pain-threshold') > 0 ? 2 : 1);
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

/** Location modifier for a major wound, including the supported absent-organ exceptions. */
rpgExpandedMajorWoundModifier(location, maleGroin, noBrain, noVitals)
{
    if (!holds(['torso','face','skull','vitals','groin'],location)) rpgExpandedReject('expanded-knockdown-location-unavailable');
    if (maleGroin && location != 'groin') rpgExpandedReject('expanded-knockdown-groin-context');
    if (noBrain && holds(['face','skull'],location) || noVitals && holds(['vitals','groin'],location)) return 0;
    if (location == 'skull') return -10;
    if (holds(['face','vitals'],location) || location == 'groin' && maleGroin) return -5;
    return 0;
}

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
    if (value.major) value.modifier = rpgExpandedMajorWoundModifier(location,maleGroin,nil,nil);
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
    forceMajorWound = nil
    boundForceMajorWound = nil
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
    committedAt = nil
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
                || self.criticalHit != self.boundCriticalHit || self.forceMajorWound != self.boundForceMajorWound
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
        foreach (local traitId in ['homogenous','diffuse'])
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
        if (self.forceMajorWound)
        {
            if (!self.criticalHit || self.amount <= 0) rpgExpandedReject('critical-major-wound-evidence');
            value.assessment.major = true; value.assessment.required = true;
            value.assessment.modifier = self.bodyPart != nil ? 0
                : rpgExpandedMajorWoundModifier(self.location,self.maleGroin,
                    self.profile.level('no-brain') > 0,self.profile.level('no-vitals') > 0);
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
        self.profile.validateInjury(value.healthLoss);
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
        self.boundForceMajorWound = self.forceMajorWound;
        self.cripplingAssessment = value.crippling;
        self.boundBodyPart = self.bodyPart; self.boundSevering = self.severing;
        self.knockdownAssessment = value.assessment;
        self.boundProfile = self.profile; self.boundId = self.id; self.boundAmount = self.amount;
        self.boundLocation = self.location; self.boundMaleGroin = self.maleGroin;
        self.boundDropDestination = self.dropDestination;
        self.committedSerial = self.profile.woundSerial; self.committedAt = rpgLedger.seconds;
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
                || holds(ids,wound.id) || wound.forceMajorWound != wound.boundForceMajorWound) rpgExpandedReject('expanded-wound-history');
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
        patient.validateHealing(value.healed);
        value.seconds = 60; value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        rpgSpendTime(value.seconds);
        return self.commitHealing(value);
    }
    applyAfterBleedingCare(care)
    {
        if (care == nil || !care.ofKind(RpgExpandedBleedingAid) || care.bandage != self
            || care.episode.classification.wound != self.wound || care.healer != self.healer
            || care.result == nil || !care.result.stopped || care.completedAt != care.completesAt
            || !holds(care.episode.aidAttempts,care)) rpgExpandedReject('bandage-bleeding-care');
        care.assess();
        local value = self.assess(); if (value.status != 'ready') return value;
        if (rpgLedger.seconds != care.completedAt) { value.reason = 'bandage-care-completion-time'; return value; }
        value.seconds = 0; return self.commitHealing(value);
    }
    commitHealing(value)
    {
        local patient = self.wound.profile;
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
    context = nil
    score = nil
    technologyModifier = 0
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

/** Pure surgeon eligibility and current score, full-2008 B223/B424.
 * A ready assessment is not a completed operation or a healing grant. */
class RpgExpandedSurgicalAssessment: object
    surgeon = nil
    skill = nil
    conditions = nil
    assess()
    {
        if (self.surgeon == nil || !self.surgeon.ofKind(RpgLiteProfile)
            || self.skill == nil || !self.skill.ofKind(RpgLiteSkill)
            || self.skill.id != 'surgery' || self.skill.attribute != rpgIQ
            || self.skill.difficulty != 3 || self.skill.techLevel == nil
            || self.conditions == nil || !self.conditions.ofKind(RpgExpandedSurgeryContext))
            rpgExpandedReject('surgical-assessment-definition');
        local value = new RpgExpandedSurgeryAssessment();
        if (self.surgeon.dead || self.surgeon.unconscious || self.surgeon.stunned
            || self.surgeon.mentalStun || self.surgeon.mortal || self.surgeon.fp() <= 0)
        { value.reason = 'surgical-assessment-incapacity'; return value; }
        local technology = rpgExpandedTechnologyModifier(self.skill.techLevel,self.conditions.techLevel,true);
        if (technology == nil)
        { value.reason = 'surgical-assessment-technology-too-advanced'; return value; }
        local trained = nil; local prerequisite = nil; local physician = nil;
        foreach (local training in self.surgeon.skills)
        {
            if (training.points <= 0) continue;
            if (training.skill == self.skill) trained = true;
            if (training.skill.techLevel == self.skill.techLevel
                && holds(['first-aid','physician'],training.skill.id))
            {
                prerequisite = true;
                if (training.skill.id == 'physician') physician = true;
            }
        }
        /* B169 prerequisites govern learning. B173 permits use of a published
         * default without purchasing the advanced skill or its prerequisites. */
        if (trained && !prerequisite) { value.reason = 'surgical-assessment-prerequisite'; return value; }
        /* Derive training from owned investments without modifying the author's
         * conditions object or trusting its standalone physicianTrained flag. */
        local prepared = new RpgExpandedSurgeryContext();
        prepared.techLevel = self.conditions.techLevel;
        prepared.anesthetic = self.conditions.anesthetic;
        prepared.sterile = self.conditions.sterile;
        prepared.site = self.conditions.site;
        prepared.diagnosed = self.conditions.diagnosed;
        prepared.physicianTrained = physician;
        prepared.fieldExpedient = self.conditions.fieldExpedient;
        prepared.equipmentQualityModifier = self.conditions.equipmentQualityModifier;
        prepared.physiologyModifier = self.conditions.physiologyModifier;
        prepared.otherMissingEquipmentModifier = self.conditions.otherMissingEquipmentModifier;
        prepared.earlyAntisepsis = self.conditions.earlyAntisepsis;
        value = prepared.assess();
        if (value.status != 'ready') return value;
        value.technologyModifier = technology;
        value.modifier += technology;
        value.context = new RpgLiteContext(); value.context.skill = self.skill;
        value.context.kind = 'surgery'; value.context.modifier = value.modifier;
        value.score = rpgLiteScore(self.surgeon,value.context);
        if (value.score == nil || value.score < 3)
        { value.status = 'blocked'; value.reason = 'surgical-assessment-score-unavailable'; }
        return value;
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
            self.profile.becomeUnconscious(); self.profile.fatigueCollapse = true;
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
        self.profile.dead = true; self.profile.becomeUnconscious(); self.profile.cardiacArrest = nil;
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
        if (value.unconscious) { self.profile.becomeUnconscious(); self.profile.fatigueCollapse = true; }
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
            self.profile.becomeUnconscious(); value.unconscious = true; value.incapacitated = true;
            value.allowed = nil; value.reason = 'action-gate-unconscious';
        }
        return value;
    }
;


/** Opt-in maneuver adapter; each authored turn owns one fresh action gate. */
class RpgExpandedHealthManeuver: RpgLiteManeuver
    expandedHealthPermission = true
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

/** Technology accidents use the same owned torso wound and injury ledger. */
modify RpgExpandedProfile
    prepareTechnologyWound(id, amount, destination)
    {
        local wound = new RpgExpandedWound(); wound.id = id; wound.profile = self;
        wound.amount = amount; wound.dropDestination = destination; return wound;
    }
;

/** Swarm attacks share the same owned wound, shock and survival procedure. */
modify RpgExpandedProfile
    prepareSwarmWound(id, amount, destination)
    {
        local wound = new RpgExpandedWound(); wound.id = id; wound.profile = self;
        wound.amount = amount; wound.dropDestination = destination; return wound;
    }
;

class RpgExpandedFearAssessment: RpgExpandedResult
    score = nil
    immune = nil
;

/** B360: cap only the initial fear check, after all explicit modifiers. */
rpgExpandedAssessFear(will, modifier, unfazeable)
{
    rpgInteger(will,1,1000); rpgInteger(modifier,-1000,1000);
    local value = new RpgExpandedFearAssessment();
    if (unfazeable) { value.immune = true; value.status = 'ready'; return value; }
    value.score = will + modifier; if (value.score > 13) value.score = 13;
    if (value.score < 3) { value.reason = 'fear-score-unavailable'; return value; }
    value.status = 'ready'; return value;
}

class RpgExpandedFearTableResult: RpgExpandedResult
    row = 0
    kind = nil
    durationDice = 0
    durationUnit = 1
    fixedSeconds = 0
    recovery = nil
    recoveryInterval = 0
    fatigueDice = 0
    injuryDice = 0
    fixedInjury = 0
    traitPoints = 0
    traitKind = nil
    iqLoss = 0
    durationFormula = nil
    injuryCondition = nil
    criticalHealthLoss = 0
    repeatDurationDice = 0
    aftereffectPenalty = 0
    aftereffectSeconds = 0
    aftereffectMatchesDuration = nil
    escalatingNeglectInjury = nil
    reactionDice = 0
    fallbackTraitPoints = 0
;

/** Pure B361/B428-B429 assessment; the owning episode must execute its costs. */
class RpgExpandedRetchingAssessment: RpgExpandedResult
    initialSeconds = nil
    recoveryScore = nil
    recoveryInterval = 1
    actionAllowed = true
    automaticFailure = nil
    defensePenalty = -4
    finishingFatigue = 1
    oralBenefitsLost = true
;

rpgExpandedAssessFearRetching(health,attribute,requiresConcentration)
{
    rpgInteger(health,1,1000);
    if (!holds([rpgST,rpgDX,rpgIQ,rpgHT,rpgWill,rpgPerception],attribute))
        rpgExpandedReject('retching-attribute');
    local value = new RpgExpandedRetchingAssessment();
    /* No minimum duration is stated for the exceptional HT >= 25 case. */
    if (health >= 25) { value.reason = 'retching-duration-source-required'; return value; }
    value.initialSeconds = 25 - health; value.recoveryScore = health;
    value.modifier = holds([rpgDX,rpgIQ,rpgPerception],attribute) ? -5 : 0;
    value.actionAllowed = !requiresConcentration; value.automaticFailure = requiresConcentration;
    value.status = 'ready'; return value;
}

/** B360-B361 consequence specification only; caller supplies the table roll. */
rpgExpandedFearTable(total)
{
    rpgInteger(total,4,1000000);
    local value = new RpgExpandedFearTableResult(); value.row = total > 40 ? 40 : total;
    local row = value.row;
    if (row <= 11)
    {
        value.kind = 'stun'; value.fixedSeconds = row <= 9 ? 1 : 0;
        value.durationDice = row == 10 ? 1 : row == 11 ? 2 : 0;
        value.recovery = row <= 5 ? 'automatic' : row <= 7 ? 'unmodified-will' : 'modified-will';
        value.recoveryInterval = row <= 5 ? 0 : 1;
    }
    if (row == 12) { value.kind = 'retch'; value.recovery = 'health'; value.recoveryInterval = 1; }
    if (row == 13 || row == 16) { value.traitKind = 'mental-quirk'; value.traitPoints = -1; }
    if (row == 13) value.kind = 'trait';
    if (row >= 14 && row <= 16)
    {
        value.kind = 'stun'; value.durationDice = 1; value.recovery = 'modified-will'; value.recoveryInterval = 1;
        if (row <= 15) value.fatigueDice = 1;
    }
    if ((row >= 17 && row <= 20) || row == 26 || row == 27)
    {
        value.kind = 'faint'; value.durationUnit = 60;
        value.durationDice = row == 19 ? 2 : row == 20 ? 4 : 1;
        value.recovery = row == 20 ? 'source-followup-required' : 'health'; value.recoveryInterval = row == 20 ? 0 : 60;
        if (row == 19) value.fixedInjury = 1;
        if (row == 18 || row == 26 || row == 27) value.recovery = 'immediate-health-injury-then-health';
        if (row == 20) value.fatigueDice = 1;
    }
    if (row == 21)
    { value.kind = 'panic'; value.durationDice = 1; value.durationUnit = 60; value.recovery = 'unmodified-will'; value.recoveryInterval = 60; }
    if (holds([22,23,24,25,34,35,36,37],row)) value.kind = 'trait';
    if (holds([22,26,34,38],row)) value.traitKind = 'delusion';
    if (holds([23,27,35,39,40],row)) value.traitKind = 'mental-disadvantage';
    if (holds([24,36,37],row)) value.traitKind = 'physical-disadvantages';
    if (row == 25) value.traitKind = 'worsen-self-control-or-mental-disadvantage';
    if (holds([22,23,25,26,27],row)) value.traitPoints = -10;
    if (holds([24,34,35,38,39,40],row)) value.traitPoints = -15;
    if (row == 36) value.traitPoints = -20;
    if (row == 37) value.traitPoints = -30;
    if (row == 28 || row == 29 || row >= 38)
    {
        value.kind = 'coma'; value.recovery = 'health';
        value.durationDice = row == 28 ? 0 : 1; value.durationUnit = 3600;
        value.recoveryInterval = row == 28 ? 1800 : 0;
    }
    if (row == 30) { value.kind = 'catatonia'; value.durationDice = 1; value.durationUnit = 86400; value.recovery = 'health'; }
    if (row == 31)
    { value.kind = 'seizure'; value.durationDice = 1; value.durationUnit = 60; value.fatigueDice = 1; value.injuryDice = 1; value.recovery = 'immediate-health-injury'; }
    if (row == 32) { value.kind = 'injury'; value.injuryDice = 2; }
    if (row == 33) { value.kind = 'extreme-panic'; value.recovery = 'unmodified-will-after-authored-reaction'; }
    if (row == 12) value.durationFormula = '25-minus-health';
    if (holds([18,26,27],row)) { value.fixedInjury = 1; value.injuryCondition = 'failed-health'; }
    if (row == 31) { value.injuryCondition = 'failed-health'; value.criticalHealthLoss = 1; }
    if (row == 29 || row == 30 || row >= 38) value.repeatDurationDice = 1;
    if (row == 28 || row == 29 || row >= 38) { value.aftereffectPenalty = -2; value.aftereffectSeconds = 21600; }
    if (row == 30) { value.aftereffectPenalty = -2; value.aftereffectMatchesDuration = true; value.escalatingNeglectInjury = true; }
    if (row == 33) value.reactionDice = 3;
    if (row == 25) { value.traitPoints = 0; value.fallbackTraitPoints = -10; }
    if (row == 40) value.iqLoss = 1;
    value.status = 'ready'; return value;
}

/** B360 explicit scene facts, with owned trait bonuses applied exactly once. */
class RpgExpandedFearContext: object
    profile = nil
    approved = nil
    evidence = nil
    physicalRisk = nil
    cowardicePenalty = 0
    charging = nil
    purposeThreat = nil
    monsters = nil
    xenophiliaBonus = 0
    body = 'none'
    mutilationPenalty = 0
    dependentVictim = nil
    inCombat = nil
    monsterPenalty = 0
    hordeBand = 0
    touching = nil
    distance = 0
    remote = nil
    isolated = nil
    adverseLighting = nil
    believesAlone = nil
    priorExperience = nil
    priorExposures24h = 0
    briefingBonus = 0
    assess()
    {
        if (self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)) rpgExpandedReject('fear-context-profile');
        local blocked = new RpgExpandedFearAssessment();
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { blocked.reason = 'fear-context-author-facts'; return blocked; }
        rpgInteger(self.cowardicePenalty,0,4); rpgInteger(self.xenophiliaBonus,0,4);
        rpgInteger(self.mutilationPenalty,0,3); rpgInteger(self.monsterPenalty,0,10);
        rpgInteger(self.hordeBand,0,5); rpgInteger(self.distance,0,100000000);
        rpgInteger(self.priorExposures24h,0,100); rpgInteger(self.briefingBonus,0,3);
        if (!holds(['none','prepared','nonviolent','violent','mutilated'],self.body)) rpgExpandedReject('fear-body-category');
        if ((self.body == 'mutilated') != (self.mutilationPenalty > 0)) rpgExpandedReject('fear-mutilation-category');
        if (self.body == 'none' && self.dependentVictim) rpgExpandedReject('fear-dependent-body-required');
        if (!self.monsters && (self.monsterPenalty != 0 || self.hordeBand != 0 || self.xenophiliaBonus != 0))
            rpgExpandedReject('fear-unused-monster-fields');
        local coward = self.profile.level('cowardice') > 0 && self.physicalRisk;
        if (coward != (self.cowardicePenalty > 0)) rpgExpandedReject('fear-cowardice-classification');
        local interested = self.profile.level('xenophilia') > 0 && self.monsters;
        if (interested != (self.xenophiliaBonus > 0)) rpgExpandedReject('fear-xenophilia-classification');
        if (self.touching && (self.remote || self.distance != 0)) rpgExpandedReject('fear-contact-distance');
        local modifier = self.profile.level('fearlessness') - self.profile.level('fearfulness');
        if (self.profile.level('combat-reflexes') > 0) modifier += 2;
        if (self.profile.level('combat-paralysis') > 0) modifier -= 2;
        modifier -= self.cowardicePenalty; modifier += self.xenophiliaBonus;
        if (self.charging && self.profile.level('daredevil') > 0) modifier += 1;
        if (self.purposeThreat && self.profile.level('higher-purpose') > 0) modifier += 1;
        if (self.body == 'prepared') modifier += 6;
        if (self.body == 'nonviolent') modifier += 2;
        modifier -= self.mutilationPenalty;
        if (self.dependentVictim) modifier -= 6;
        if (self.inCombat) modifier += 5;
        modifier -= self.monsterPenalty + self.hordeBand;
        if (self.touching) modifier -= 1;
        modifier += self.remote ? 3 : self.distance >= 100 ? 1 : 0;
        if (self.isolated) modifier -= 1;
        if (self.adverseLighting) modifier -= 1;
        if (self.believesAlone) modifier -= 2;
        if (self.priorExperience) modifier += 1;
        modifier += self.priorExposures24h + self.briefingBonus;
        local value = rpgExpandedAssessFear(self.profile.attributeScore(rpgWill),modifier,self.profile.level('unfazeable') > 0);
        value.modifier = modifier; return value;
    }
;

modify RpgExpandedProfile
    expandedFearStun = nil
    fearStunEpisodes = []
    stunRecoveryOwned() { return self.expandedFearStun != nil || inherited(); }
;

class RpgExpandedFearStunResult: RpgExpandedResult
    fatigueLoss = nil
;

/** Owned execution for short stun, including the fatigue-plus-stun rows. */
class RpgExpandedFearStun: object
    id = nil
    context = nil
    tableTotal = 4
    approved = nil
    evidence = nil
    startedAt = nil
    initialEnd = nil
    recoveryModifier = 0
    completed = nil
    boundProfile = nil
    boundId = nil
    boundTotal = nil
    boundContext = nil
    boundEvidence = nil
    recoveries = []
    lastRecoveryStartedAt = nil
    dropDestination = nil
    boundDropDestination = nil
    fatigueLoss = nil
    quirkAcquisition = nil
    boundQuirkAcquisition = nil
    assess()
    {
        if (self.id == nil || self.id == '' || self.context == nil || !self.context.ofKind(RpgExpandedFearContext))
            rpgExpandedReject('fear-stun-definition');
        rpgInteger(self.tableTotal,4,16);
        if (self.tableTotal == 12 || self.tableTotal == 13) rpgExpandedReject('fear-stun-row');
        local value = new RpgExpandedFearStunResult();
        if (self.startedAt != nil)
        {
            if (self.context != self.boundContext || self.evidence != self.boundEvidence || self.dropDestination != self.boundDropDestination
                || self.context.profile != self.boundProfile || self.id != self.boundId || self.tableTotal != self.boundTotal
                || self.quirkAcquisition != self.boundQuirkAcquisition
                || !holds(self.boundProfile.fearStunEpisodes,self)) rpgExpandedReject('fear-stun-binding');
            value.status = 'reused'; return value;
        }
        local assessment = self.context.assess();
        if (assessment.status != 'ready') { value.reason = assessment.reason; return value; }
        if (assessment.immune) { value.reason = 'fear-stun-immune'; return value; }
        local profile = self.context.profile;
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'fear-stun-outcome-evidence'; return value; }
        if (profile.expandedFearStun != nil || profile.stunned || profile.mentalStun || profile.fearSeconds > 0)
        { value.reason = 'fear-stun-existing-condition'; return value; }
        if (profile.dead || profile.unconscious) { value.reason = 'fear-stun-observer-unavailable'; return value; }
        foreach (local prior in profile.fearStunEpisodes)
            if (prior.id == self.id) rpgExpandedReject('fear-stun-duplicate');
        rpgInteger(rpgLedger.seconds,0,2147483647 - (self.tableTotal == 11 ? 12 : self.tableTotal >= 10 ? 6 : 1));
        if (self.tableTotal == 16)
        {
            if (self.quirkAcquisition == nil) { value.reason = 'fear-stun-quirk-required'; return value; }
            if (!self.quirkAcquisition.ofKind(RpgExpandedFearQuirkContract)
                || self.quirkAcquisition.profile != profile || self.quirkAcquisition.eventId != self.id)
                rpgExpandedReject('fear-stun-quirk-owner');
            local quirk = self.quirkAcquisition.assess();
            if (quirk.status != 'ready')
            { value.reason = quirk.status == 'reused' ? 'fear-stun-quirk-used' : quirk.reason; return value; }
        }
        else if (self.quirkAcquisition != nil) rpgExpandedReject('fear-stun-unexpected-quirk');
        if (self.tableTotal == 14 || self.tableTotal == 15)
        {
            value.fatigueLoss = new RpgExpandedFearFatigueLoss(); value.fatigueLoss.id = 'stun-' + self.id;
            value.fatigueLoss.profile = profile; value.fatigueLoss.amount = 6; value.fatigueLoss.dropDestination = self.dropDestination;
            local fatigue = value.fatigueLoss.assess();
            if (fatigue.status != 'ready') { value.reason = fatigue.reason; return value; }
        }
        value.modifier = assessment.modifier; value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local duration = 1;
        if (value.fatigueLoss != nil) value.fatigueLoss.amount = rpgRandom.die();
        if (self.tableTotal >= 10)
        {
            duration = rpgRandom.die(); if (self.tableTotal == 11) duration += rpgRandom.die();
        }
        if (value.fatigueLoss != nil)
        {
            local fatigue = value.fatigueLoss.apply();
            if (fatigue.status != 'resolved') rpgExpandedReject('fear-stun-fatigue-changed');
            self.fatigueLoss = value.fatigueLoss;
        }
        if (self.quirkAcquisition != nil)
        {
            local quirk = self.quirkAcquisition.apply();
            if (quirk.status != 'resolved') rpgExpandedReject('fear-stun-quirk-changed');
        }
        self.startedAt = rpgLedger.seconds; self.initialEnd = self.startedAt + duration;
        self.recoveryModifier = self.tableTotal <= 7 ? 0 : value.modifier;
        self.boundProfile = self.context.profile; self.boundId = self.id; self.boundTotal = self.tableTotal;
        self.boundContext = self.context; self.boundEvidence = self.evidence;
        self.boundDropDestination = self.dropDestination;
        self.boundQuirkAcquisition = self.quirkAcquisition;
        if (self.boundProfile.dead) self.completed = true;
        else { self.boundProfile.mentalStun = true; self.boundProfile.expandedFearStun = self; }
        self.boundProfile.fearStunEpisodes = self.boundProfile.fearStunEpisodes + [self];
        value.status = 'resolved'; return value;
    }
    finish()
    {
        if (self.boundProfile.expandedFearStun != self) rpgExpandedReject('fear-stun-ownership');
        self.boundProfile.mentalStun = nil; self.boundProfile.expandedFearStun = nil; self.completed = true;
        return nil;
    }
;

/** Rows 4/5 recover at their deadline without a check or additional clock charge. */
modify rpgLedger
    afterAdvance(previousSeconds)
    {
        inherited(previousSeconds);
        for (local episode = firstObj(RpgExpandedFearStun); episode != nil; episode = nextObj(episode,RpgExpandedFearStun))
            if (episode.startedAt != nil && !episode.completed && episode.tableTotal <= 5 && self.seconds >= episode.initialEnd)
            { episode.assess(); episode.finish(); }
        return nil;
    }
;

class RpgExpandedFearStunRecovery: object
    id = nil
    episode = nil
    result = nil
    boundId = nil
    boundEpisode = nil
    startedAt = nil
    completedAt = nil
    assess()
    {
        if (self.id == nil || self.id == '' || self.episode == nil || !self.episode.ofKind(RpgExpandedFearStun))
            rpgExpandedReject('fear-recovery-definition');
        local value = new RpgExpandedResult();
        if (self.result != nil)
        {
            if (self.id != self.boundId || self.episode != self.boundEpisode || !holds(self.episode.recoveries,self))
                rpgExpandedReject('fear-recovery-binding');
            value.status = 'reused'; value.check = self.result.check; return value;
        }
        if (self.episode.startedAt == nil) { value.reason = 'fear-recovery-episode-required'; return value; }
        self.episode.assess(); local profile = self.episode.boundProfile;
        if (self.episode.completed || self.episode.tableTotal <= 5)
        { value.reason = 'fear-recovery-not-required'; return value; }
        if (profile.expandedFearStun != self.episode || !profile.mentalStun) rpgExpandedReject('fear-recovery-owner');
        if (profile.dead || profile.unconscious) { value.reason = 'fear-recovery-observer-unavailable'; return value; }
        if (rpgLedger.seconds < self.episode.initialEnd) { value.reason = 'fear-recovery-initial-duration'; return value; }
        if (self.episode.lastRecoveryStartedAt != nil && rpgLedger.seconds <= self.episode.lastRecoveryStartedAt)
        { value.reason = 'fear-recovery-already-attempted'; return value; }
        foreach (local prior in self.episode.recoveries)
            if (prior.id == self.id) rpgExpandedReject('fear-recovery-duplicate');
        local score = profile.attributeScore(rpgWill) + self.episode.recoveryModifier;
        if (score < 3 || score > 1000) { value.reason = 'fear-recovery-score-unavailable'; return value; }
        rpgInteger(rpgLedger.seconds,0,2147483646);
        value.seconds = 1; value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local originalId = self.id; local originalEpisode = self.episode;
        local start = rpgLedger.seconds; rpgSpendTime(1);
        if (self.id != originalId || self.episode != originalEpisode || rpgLedger.seconds != start + 1 || self.assess().status != 'ready') rpgExpandedReject('fear-recovery-interrupted');
        return self.resolve(value,start);
    }
    /* The battle scheduler owns the time charge for this explicit turn route. */
    applyInTurn(battle,fighter)
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        if (battle == nil || !battle.ofKind(RpgLiteBattle) || battle.current() != fighter
            || fighter.profile != self.episode.boundProfile || fighter.maneuver != 'nothing')
            rpgExpandedReject('fear-recovery-turn');
        value.seconds = 0; return self.resolve(value,rpgLedger.seconds);
    }
    resolve(value,start)
    {
        local profile = self.episode.boundProfile;
        value.check = rpgCheck(profile.attributeScore(rpgWill) + self.episode.recoveryModifier,rpgRandom.roll());
        if (value.check.achieved) self.episode.finish();
        self.boundId = self.id; self.boundEpisode = self.episode;
        self.startedAt = start; self.completedAt = rpgLedger.seconds; self.episode.lastRecoveryStartedAt = start;
        self.episode.recoveries = self.episode.recoveries + [self]; value.status = 'resolved'; self.result = value; return value;
    }
;

/** One authored Do Nothing turn, using the shared health gate and battle clock. */
class RpgExpandedFearRecoveryManeuver: RpgExpandedHealthManeuver
    battle = nil
    recovery = nil
    available(fighter)
    {
        if (self.kind != 'nothing' || self.movement != 0 || self.battle == nil
            || !self.battle.ofKind(RpgLiteBattle) || self.battle.current() != fighter
            || self.recovery == nil || !self.recovery.ofKind(RpgExpandedFearStunRecovery))
            rpgExpandedReject('fear-recovery-maneuver');
        if (self.recovery.result != nil) return 'fear-recovery-maneuver-used';
        local value = self.recovery.assess();
        if (value.status != 'ready') return value.reason;
        if (self.recovery.episode.boundProfile != fighter.profile) rpgExpandedReject('fear-recovery-profile');
        return nil;
    }
    apply(fighter,result)
    {
        local value = self.recovery.applyInTurn(self.battle,fighter);
        if (value.status != 'resolved') rpgExpandedReject('fear-recovery-turn-changed');
        return nil;
    }
;

/** Owned retching state; meal and oral-treatment consequences need explicit review. */
modify RpgExpandedProfile
    retchingEpisode = nil
    retchingHistory = []
    healthAttributeModifier(context)
    {
        local value = inherited(context);
        if (self.retchingEpisode != nil && holds([rpgDX,rpgIQ,rpgPerception],context.controllingAttribute())) value -= 5;
        return value;
    }
    healthCheckReason(context)
    {
        if (self.retchingEpisode != nil && (context.requiresConcentration || context.kind == 'concentrate'))
            return 'retching-concentration-failure';
        return inherited(context);
    }
    healthManeuverReason(kind)
    {
        if (self.retchingEpisode != nil && kind == 'concentrate') return 'retching-concentration-failure';
        return inherited(kind);
    }
    healthDefensePenalty()
    {
        local value = inherited(); return self.retchingEpisode != nil && value < 4 ? 4 : value;
    }
;

class RpgExpandedRetching: object
    recoveryCheckRequired() { return nil; }
    id = nil
    context = nil
    approved = nil
    evidence = nil
    oralEffectsReviewed = nil
    affectedOralBenefits = []
    boundOralBenefits = []
    contextAccepted() { return self.context != nil && self.context.ofKind(RpgExpandedRetchingContext); }
    startedAt = nil
    initialEnd = nil
    boundProfile = nil
    boundId = nil
    boundContext = nil
    boundEvidence = nil
    completedAt = nil
    recoveries = []
    lastRecoveryStartedAt = nil
    assess()
    {
        if (self.id == nil || self.id == '' || !self.contextAccepted())
            rpgExpandedReject('retching-definition');
        local value = new RpgExpandedResult();
        if (self.startedAt != nil)
        {
            if (self.id != self.boundId || self.context != self.boundContext || self.context.profile != self.boundProfile
                || self.evidence != self.boundEvidence || !holds(self.boundProfile.retchingHistory,self))
                rpgExpandedReject('retching-binding');
            value.status = 'reused'; return value;
        }
        local scene = self.context.assess();
        if (scene.status != 'ready') { value.reason = scene.reason; return value; }
        if (scene.immune) { value.reason = 'retching-fear-immune'; return value; }
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'retching-outcome-evidence'; return value; }
        value.reason = self.oralBenefitReason(); if (value.reason != nil) return value;
        local profile = self.context.profile;
        rpgExpandedValidate(profile);
        if (profile.dead || profile.unconscious || profile.retchingEpisode != nil)
        { value.reason = 'retching-observer-unavailable'; return value; }
        foreach (local prior in profile.retchingHistory)
            if (prior.id == self.id) rpgExpandedReject('retching-duplicate');
        local condition = rpgExpandedAssessFearRetching(profile.ht,rpgHT,nil);
        if (condition.status != 'ready') { value.reason = condition.reason; return value; }
        rpgInteger(rpgLedger.seconds,0,2147483647 - condition.initialSeconds);
        value.seconds = condition.initialSeconds; value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        foreach (local benefit in self.affectedOralBenefits) benefit.revoke(self);
        self.boundOralBenefits = [] + self.affectedOralBenefits;
        self.startedAt = rpgLedger.seconds; self.initialEnd = self.startedAt + value.seconds;
        self.boundProfile = self.context.profile; self.boundId = self.id;
        self.boundContext = self.context; self.boundEvidence = self.evidence;
        self.boundProfile.retchingEpisode = self;
        self.boundProfile.retchingHistory = self.boundProfile.retchingHistory + [self];
        value.seconds = 0; value.status = 'resolved'; return value;
    }
;

class RpgExpandedRetchingRecoveryResult: RpgExpandedResult
    context = nil
    wound = nil
    fatigueAdded = 0
    injuryAdded = 0
;

/** A one-second health recovery attempt with preflighted fatigue and injury. */
class RpgExpandedRetchingRecovery: object
    id = nil
    episode = nil
    result = nil
    boundId = nil
    boundEpisode = nil
    dropDestination = nil
    boundDropDestination = nil
    startedAt = nil
    completedAt = nil
    assess()
    {
        if (self.id == nil || self.id == '' || self.episode == nil || !self.episode.ofKind(RpgExpandedRetching))
            rpgExpandedReject('retching-recovery-definition');
        local value = new RpgExpandedRetchingRecoveryResult();
        if (self.result != nil)
        {
            if (self.id != self.boundId || self.episode != self.boundEpisode || self.dropDestination != self.boundDropDestination
                || !holds(self.episode.recoveries,self))
                rpgExpandedReject('retching-recovery-binding');
            value.status = 'reused'; value.check = self.result.check; return value;
        }
        if (self.episode.startedAt == nil) { value.reason = 'retching-episode-required'; return value; }
        self.episode.assess(); local profile = self.episode.boundProfile;
        if (self.episode.completedAt != nil) { value.reason = 'retching-already-ended'; return value; }
        if (profile.retchingEpisode != self.episode) rpgExpandedReject('retching-ownership');
        if (profile.dead || profile.unconscious && self.episode.recoveryCheckRequired()) { value.reason = 'retching-observer-unavailable'; return value; }
        if (rpgLedger.seconds < self.episode.initialEnd) { value.reason = 'retching-initial-duration'; return value; }
        if (self.episode.lastRecoveryStartedAt != nil && rpgLedger.seconds <= self.episode.lastRecoveryStartedAt)
        { value.reason = 'retching-recovery-already-attempted'; return value; }
        value.reason = self.episode.oralBenefitReason(); if (value.reason != nil) return value;
        rpgInteger(profile.maxEnergy,1,1000); rpgInteger(profile.fatigue,0,2 * profile.maxEnergy);
        if (profile.fp() <= 0)
        {
            value.wound = new RpgExpandedWound(); value.wound.profile = profile;
            value.wound.id = 'retching-' + self.episode.id + '-' + self.id;
            value.wound.amount = 1; value.wound.dropDestination = self.dropDestination;
            local injury = value.wound.assess();
            if (injury.status != 'ready') { value.reason = injury.reason; return value; }
        }
        if (self.episode.recoveryCheckRequired())
        {
            value.context = new RpgLiteContext(); value.context.attribute = rpgHT; value.context.kind = 'retching-recovery';
            local score = rpgLiteScore(profile,value.context);
            if (score == nil || score < 3) { value.reason = 'retching-recovery-score-unavailable'; return value; }
        }
        else if (rpgLedger.seconds != self.episode.initialEnd)
        { value.reason = 'retching-fixed-end-required'; return value; }
        foreach (local prior in self.episode.recoveries)
            if (prior.id == self.id) rpgExpandedReject('retching-recovery-duplicate');
        rpgInteger(rpgLedger.seconds,0,2147483646);
        value.seconds = self.episode.recoveryCheckRequired() ? 1 : 0; value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        if (value.seconds == 0) return self.resolve(value,rpgLedger.seconds);
        local originalId = self.id; local originalEpisode = self.episode; local originalDrop = self.dropDestination;
        local start = rpgLedger.seconds;
        rpgSpendTime(1);
        if (self.id != originalId || self.episode != originalEpisode || self.dropDestination != originalDrop
            || rpgLedger.seconds != start + 1) rpgExpandedReject('retching-recovery-interrupted');
        value = self.assess();
        if (value.status != 'ready') rpgExpandedReject('retching-recovery-interrupted');
        return self.resolve(value,start);
    }
    applyInTurn(battle,fighter)
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        if (battle == nil || !battle.ofKind(RpgLiteBattle) || battle.current() != fighter
            || fighter.profile != self.episode.boundProfile || fighter.maneuver != 'nothing')
            rpgExpandedReject('retching-recovery-turn');
        value.seconds = 0; return self.resolve(value,rpgLedger.seconds);
    }
    resolve(value,start)
    {
        local profile = self.episode.boundProfile;
        value.check = self.episode.recoveryCheckRequired() ? rpgCheck(rpgLiteScore(profile,value.context),rpgRandom.roll()) : nil;
        if (value.check == nil || value.check.achieved)
        {
            if (value.wound != nil)
            {
                local injury = value.wound.apply();
                if (injury.status != 'resolved') rpgExpandedReject('retching-injury-changed');
                value.injuryAdded = injury.healthLoss;
            }
            value.fatigueAdded = rpgLiteFatigueIncrement(profile,'retching');
            if (profile.fp() <= -profile.maxEnergy) { profile.becomeUnconscious(); profile.fatigueCollapse = true; }
            profile.retchingEpisode = nil; self.episode.completedAt = rpgLedger.seconds;
        }
        else value.wound = nil;
        self.boundId = self.id; self.boundEpisode = self.episode;
        self.boundDropDestination = self.dropDestination;
        self.startedAt = start; self.completedAt = rpgLedger.seconds; self.episode.lastRecoveryStartedAt = start;
        self.episode.recoveries = self.episode.recoveries + [self]; value.status = 'resolved'; self.result = value; return value;
    }
;

/** Do Nothing recovery using the battle's time charge and a fresh health gate. */
class RpgExpandedRetchingRecoveryManeuver: RpgExpandedHealthManeuver
    battle = nil
    recovery = nil
    available(fighter)
    {
        if (self.kind != 'nothing' || self.movement != 0 || self.battle == nil
            || !self.battle.ofKind(RpgLiteBattle) || self.battle.current() != fighter
            || self.recovery == nil || !self.recovery.ofKind(RpgExpandedRetchingRecovery))
            rpgExpandedReject('retching-recovery-maneuver');
        if (self.recovery.result != nil) return 'retching-recovery-maneuver-used';
        local value = self.recovery.assess(); if (value.status != 'ready') return value.reason;
        if (self.recovery.episode.boundProfile != fighter.profile) rpgExpandedReject('retching-recovery-profile');
        return nil;
    }
    apply(fighter,result)
    {
        local value = self.recovery.applyInTurn(self.battle,fighter);
        if (value.status != 'resolved') rpgExpandedReject('retching-recovery-turn-changed');
        return nil;
    }
;

/** One meal credited to the existing daily needs ledger, with an owned revocation. */
class RpgExpandedMealCredit: object
    id = nil
    profile = nil
    needs = nil
    meals = 1
    approved = nil
    evidence = nil
    creditedAt = nil
    boundId = nil
    boundProfile = nil
    boundNeeds = nil
    boundMeals = nil
    boundCycle = nil
    boundEvidence = nil
    revokedBy = nil
    validateBinding()
    {
        if (self.id != self.boundId || self.profile != self.boundProfile || self.needs != self.boundNeeds
            || self.meals != self.boundMeals || self.evidence != self.boundEvidence
            || self.needs.profile != self.profile || !holds(self.profile.mealCredits,self))
            rpgExpandedReject('meal-credit-binding');
        return nil;
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)
            || self.needs == nil || !self.needs.ofKind(RpgLiteNeeds) || self.needs.profile != self.profile)
            rpgExpandedReject('meal-credit-definition');
        rpgInteger(self.meals,1,3); local value = new RpgExpandedResult();
        if (self.creditedAt != nil) { self.validateBinding(); value.status = 'reused'; return value; }
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'meal-credit-evidence'; return value; }
        if (self.profile.retchingEpisode != nil) { value.reason = 'meal-credit-retching'; return value; }
        if (self.profile.dead || self.profile.unconscious) { value.reason = 'meal-credit-observer-unavailable'; return value; }
        rpgInteger(self.needs.meals,0,3);
        if (self.needs.meals + self.meals > 3) { value.reason = 'meal-credit-capacity'; return value; }
        foreach (local prior in self.profile.mealCredits)
            if (prior.id == self.id) rpgExpandedReject('meal-credit-duplicate');
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.boundId = self.id; self.boundProfile = self.profile; self.boundNeeds = self.needs;
        self.boundMeals = self.meals; self.boundCycle = self.needs.cycle; self.boundEvidence = self.evidence;
        self.creditedAt = rpgLedger.seconds; self.needs.meals += self.meals;
        self.profile.mealCredits = self.profile.mealCredits + [self]; value.status = 'resolved'; return value;
    }
    revocationReason(profile,episode)
    {
        if (self.creditedAt == nil) return 'meal-credit-not-recorded';
        self.validateBinding();
        if (self.profile != profile) return 'meal-credit-wrong-owner';
        if (self.revokedBy != nil) return self.revokedBy == episode ? nil : 'meal-credit-already-revoked';
        if (self.needs.cycle != self.boundCycle) return 'meal-credit-cycle-consumed';
        if (self.needs.meals < self.meals) return 'meal-credit-ledger-changed';
        return nil;
    }
    revoke(episode)
    {
        local reason = self.revocationReason(episode.context.profile,episode);
        if (reason != nil) rpgExpandedReject(reason);
        if (self.revokedBy != nil) return nil;
        self.needs.meals -= self.meals; self.revokedBy = episode; return nil;
    }
;

modify RpgExpandedProfile
    mealCredits = []
    afterNeedsCycle(needs)
    {
        inherited(needs); local consumed = 0;
        foreach (local credit in self.mealCredits)
            if (credit.needs == needs && credit.boundCycle == needs.cycle - 1 && credit.revokedBy == nil)
            { credit.validateBinding(); consumed += credit.meals; }
        if (consumed > needs.meals) rpgExpandedReject('meal-credit-ledger-changed');
        needs.meals -= consumed; return nil;
    }
;

modify RpgExpandedRetching
    oralBenefitReason()
    {
        if (!self.oralEffectsReviewed) return 'retching-oral-review-required';
        if (self.startedAt != nil)
        {
            if (self.affectedOralBenefits.length() != self.boundOralBenefits.length()) return 'retching-oral-review-changed';
            for (local index = 1; index <= self.boundOralBenefits.length(); index += 1)
                if (self.affectedOralBenefits[index] != self.boundOralBenefits[index]) return 'retching-oral-review-changed';
        }
        local seen = [];
        foreach (local benefit in self.affectedOralBenefits)
        {
            if (dataType(benefit) != TypeObject || (!benefit.ofKind(RpgExpandedMealCredit)
                && !benefit.ofKind(RpgExpandedOralNauseaRemedy))) return 'retching-oral-revocation-unavailable';
            if (holds(seen,benefit)) rpgExpandedReject('retching-oral-benefit-duplicate');
            seen = seen + [benefit];
            local reason = benefit.revocationReason(self.context.profile,self); if (reason != nil) return reason;
            if (self.startedAt != nil && benefit.revokedBy != self) return 'retching-oral-review-changed';
            if (benefit.ofKind(RpgExpandedMealCredit))
            {
                local total = 0;
                foreach (local other in self.affectedOralBenefits)
                    if (dataType(other) == TypeObject && other.ofKind(RpgExpandedMealCredit) && other.needs == benefit.needs && other.revokedBy == nil)
                        total += other.meals;
                if (total > benefit.needs.meals) return 'meal-credit-ledger-changed';
            }
        }
        return nil;
    }
;

/** Owned B428 nausea remedy; onset and expiry are explicit authored treatment facts. */
class RpgExpandedOralNauseaRemedy: object
    id = nil
    profile = nil
    effectStartsAt = nil
    effectEndsAt = nil
    approved = nil
    evidence = nil
    recordedAt = nil
    boundId = nil
    boundProfile = nil
    boundStartsAt = nil
    boundEndsAt = nil
    boundEvidence = nil
    revokedBy = nil
    validateBinding()
    {
        if (self.id != self.boundId || self.profile != self.boundProfile || self.effectStartsAt != self.boundStartsAt
            || self.effectEndsAt != self.boundEndsAt || self.evidence != self.boundEvidence
            || !holds(self.profile.oralNauseaRemedies,self)) rpgExpandedReject('nausea-remedy-binding');
        return nil;
    }
    effective()
    {
        if (self.recordedAt == nil) return nil;
        self.validateBinding();
        return self.revokedBy == nil && rpgLedger.seconds >= self.effectStartsAt && rpgLedger.seconds < self.effectEndsAt;
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile))
            rpgExpandedReject('nausea-remedy-definition');
        local value = new RpgExpandedResult();
        if (self.recordedAt != nil) { self.validateBinding(); value.status = 'reused'; return value; }
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'nausea-remedy-evidence'; return value; }
        if (self.effectStartsAt == nil || self.effectEndsAt == nil)
        { value.reason = 'nausea-remedy-timing-required'; return value; }
        rpgInteger(self.effectStartsAt,0,2147483646); rpgInteger(self.effectEndsAt,self.effectStartsAt + 1,2147483647);
        if (rpgLedger.seconds >= self.effectEndsAt) { value.reason = 'nausea-remedy-expired'; return value; }
        if (self.profile.retchingEpisode != nil) { value.reason = 'nausea-remedy-retching'; return value; }
        if (self.profile.dead || self.profile.unconscious) { value.reason = 'nausea-remedy-observer-unavailable'; return value; }
        foreach (local prior in self.profile.oralNauseaRemedies)
            if (prior.id == self.id) rpgExpandedReject('nausea-remedy-duplicate');
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.boundId = self.id; self.boundProfile = self.profile; self.boundStartsAt = self.effectStartsAt;
        self.boundEndsAt = self.effectEndsAt; self.boundEvidence = self.evidence; self.recordedAt = rpgLedger.seconds;
        self.profile.oralNauseaRemedies = self.profile.oralNauseaRemedies + [self];
        value.status = 'resolved'; return value;
    }
    revocationReason(profile,episode)
    {
        if (self.recordedAt == nil) return 'nausea-remedy-not-recorded';
        self.validateBinding();
        if (self.profile != profile) return 'nausea-remedy-wrong-owner';
        if (self.revokedBy != nil) return self.revokedBy == episode ? nil : 'nausea-remedy-already-revoked';
        if (rpgLedger.seconds >= self.effectEndsAt) return 'nausea-remedy-expired';
        return nil;
    }
    revoke(episode)
    {
        local reason = self.revocationReason(episode.context.profile,episode);
        if (reason != nil) rpgExpandedReject(reason);
        self.revokedBy = episode; return nil;
    }
;

modify RpgExpandedProfile
    oralNauseaRemedies = []
;

/** B428 trigger modifiers only: neither global nausea penalties nor trigger scheduling. */
rpgExpandedNauseaTriggerModifier(profile,richMealWithinHour)
{
    if (profile == nil || !profile.ofKind(RpgExpandedProfile)) rpgExpandedReject('nausea-trigger-profile');
    local remedy = nil;
    foreach (local dose in profile.oralNauseaRemedies)
        if (dose.effective()) remedy = true;
    return (remedy ? 2 : 0) - (richMealWithinHour ? 2 : 0);
}

class RpgExpandedFearFatigueResult: RpgExpandedResult
    fatigueAdded = 0
    injuryAdded = 0
    wounds = []
;

/** One source fear-table fatigue loss of one through six points, without a time charge. */
class RpgExpandedFearFatigueLoss: object
    id = nil
    profile = nil
    amount = 1
    dropDestination = nil
    result = nil
    boundId = nil
    boundProfile = nil
    boundAmount = nil
    boundDropDestination = nil
    assess()
    {
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile))
            rpgExpandedReject('fear-fatigue-definition');
        rpgInteger(self.amount,1,6); local value = new RpgExpandedFearFatigueResult();
        if (self.result != nil)
        {
            if (self.id != self.boundId || self.profile != self.boundProfile || self.amount != self.boundAmount
                || self.dropDestination != self.boundDropDestination || !holds(self.profile.fearFatigueLosses,self))
                rpgExpandedReject('fear-fatigue-binding');
            value.status = 'reused'; return value;
        }
        rpgExpandedValidate(self.profile);
        if (self.profile.dead) { value.reason = 'fear-fatigue-dead'; return value; }
        rpgInteger(self.profile.maxEnergy,1,1000); rpgInteger(self.profile.fatigue,0,2 * self.profile.maxEnergy);
        foreach (local prior in self.profile.fearFatigueLosses)
            if (prior.id == self.id) rpgExpandedReject('fear-fatigue-duplicate');
        local positive = self.profile.fp() > 0 ? self.profile.fp() : 0;
        local injury = self.amount > positive ? self.amount - positive : 0;
        local suffixes = ['one','two','three','four','five','six'];
        for (local index = 1; index <= injury; index += 1)
        {
            local wound = new RpgExpandedWound(); wound.profile = self.profile; wound.amount = 1;
            wound.id = 'fear-fatigue-' + self.id + '-' + suffixes[index]; wound.dropDestination = self.dropDestination;
            local assessment = wound.assess();
            if (assessment.status != 'ready') { value.reason = assessment.reason; return value; }
            value.wounds = value.wounds + [wound];
        }
        for (local multiple = 1; multiple <= 4; multiple += 1)
            if (self.profile.hp() > -multiple * self.profile.maxHP && self.profile.hp() - injury <= -multiple * self.profile.maxHP)
            {
                local context = new RpgLiteContext(); context.attribute = rpgHT; context.kind = 'death';
                local score = rpgLiteScore(self.profile,context);
                if (score == nil || score < 3) { value.reason = 'fear-fatigue-survival-score'; return value; }
            }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local prepared = value.wounds; value.wounds = []; local woundIndex = 1;
        for (local point = 1; point <= self.amount && !self.profile.dead; point += 1)
        {
            if (self.profile.fp() <= 0)
            {
                local wound = prepared[woundIndex]; local injury = wound.apply();
                if (injury.status != 'resolved') rpgExpandedReject('fear-fatigue-injury-changed');
                value.injuryAdded += injury.healthLoss; value.wounds = value.wounds + [wound]; woundIndex += 1;
            }
            value.fatigueAdded += rpgLiteFatigueIncrement(self.profile,'fear');
            if (self.profile.fp() <= -self.profile.maxEnergy)
            {
                if (!self.profile.unconscious) self.profile.becomeUnconscious();
                self.profile.fatigueCollapse = true;
            }
        }
        self.boundId = self.id; self.boundProfile = self.profile; self.boundAmount = self.amount;
        self.boundDropDestination = self.dropDestination;
        self.profile.fearFatigueLosses = self.profile.fearFatigueLosses + [self];
        value.status = 'resolved'; self.result = value; return value;
    }
;

modify RpgExpandedProfile
    fearFatigueLosses = []
;

modify RpgExpandedProfile
    fearFaint = nil
    fearFaints = []
    unconsciousRecoveryOwned() { return self.fearFaint != nil || inherited(); }
;

class RpgExpandedFearFaintResult: RpgExpandedResult
    dropPlan = nil
    wound = nil
;

/** B361 rows seventeen through nineteen: owned fainting and prescribed injury. */
class RpgExpandedFearFaint: object
    id = nil
    context = nil
    approved = nil
    evidence = nil
    dropDestination = nil
    tableTotal = 17
    onset = nil
    startedAt = nil
    nextCheckAt = nil
    completedAt = nil
    boundDefinition = nil
    recoveries = []
    definition() { return [self.id,self.context,self.context.profile,self.evidence,self.dropDestination,self.tableTotal]; }
    assess()
    {
        if (self.id == nil || self.id == '' || self.context == nil || !self.context.ofKind(RpgExpandedFearContext))
            rpgExpandedReject('fear-faint-definition');
        rpgInteger(self.tableTotal,17,19);
        local value = new RpgExpandedFearFaintResult();
        if (self.startedAt != nil)
        {
            local current = self.definition();
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.boundDefinition[index]) rpgExpandedReject('fear-faint-binding');
            if (!holds(self.context.profile.fearFaints,self)) rpgExpandedReject('fear-faint-history');
            value.status = 'reused'; return value;
        }
        local scene = self.context.assess();
        if (scene.status != 'ready') { value.reason = scene.reason; return value; }
        if (scene.immune) { value.reason = 'fear-faint-immune'; return value; }
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'fear-faint-evidence'; return value; }
        local profile = self.context.profile; rpgExpandedValidate(profile);
        if (profile.dead || profile.unconscious || profile.mortal || profile.hp() <= 0 || profile.fp() <= 0
            || profile.unconsciousRecoveryOwned() || profile.fearSeconds > 0)
        { value.reason = 'fear-faint-existing-condition'; return value; }
        foreach (local prior in profile.fearFaints)
            if (prior.id == self.id) rpgExpandedReject('fear-faint-duplicate');
        value.dropPlan = profile.prepareKnockdownDrop(self.dropDestination);
        if (value.dropPlan != nil && value.dropPlan.status != 'ready')
        { value.reason = value.dropPlan.reason; return value; }
        if (self.tableTotal >= 18)
        {
            value.wound = new RpgExpandedWound(); value.wound.profile = profile;
            value.wound.id = 'faint-' + self.id; value.wound.amount = 1; value.wound.dropDestination = self.dropDestination;
            local injury = value.wound.assess();
            if (injury.status != 'ready') { value.reason = injury.reason; return value; }
        }
        if (self.tableTotal == 18)
        {
            local context = new RpgLiteContext(); context.attribute = rpgHT; context.kind = 'fear-faint-collapse';
            local score = rpgLiteScore(profile,context);
            if (score == nil || score < 3) { value.reason = 'fear-faint-collapse-score'; return value; }
        }
        rpgInteger(rpgLedger.seconds,0,2147483647 - (self.tableTotal == 19 ? 720 : 360));
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local minutes = rpgRandom.die(); if (self.tableTotal == 19) minutes += rpgRandom.die();
        self.nextCheckAt = rpgLedger.seconds + 60 * minutes; self.startedAt = rpgLedger.seconds;
        self.boundDefinition = self.definition(); local profile = self.context.profile;
        if (value.dropPlan != nil) value.dropPlan.commit();
        profile.fearFaint = self; profile.fearFaints = profile.fearFaints + [self];
        profile.posture = 'lying'; profile.becomeUnconscious();
        if (self.tableTotal == 18)
        {
            local context = new RpgLiteContext(); context.attribute = rpgHT; context.kind = 'fear-faint-collapse';
            value.check = rpgLiteCheck(profile,context);
            if (value.check.achieved) value.wound = nil;
        }
        if (value.wound != nil)
        {
            local injury = value.wound.apply();
            if (injury.status != 'resolved') rpgExpandedReject('fear-faint-injury-changed');
        }
        if (profile.dead) { profile.fearFaint = nil; self.completedAt = rpgLedger.seconds; }
        value.status = 'resolved'; self.onset = value; return value;
    }
;

/** A due boundary check: elapsed time is already charged by the shared clock. */
class RpgExpandedFearFaintRecovery: object
    id = nil
    episode = nil
    result = nil
    boundId = nil
    boundEpisode = nil
    assess()
    {
        if (self.id == nil || self.id == '' || self.episode == nil || !self.episode.ofKind(RpgExpandedFearFaint))
            rpgExpandedReject('fear-faint-recovery-definition');
        local value = new RpgExpandedResult();
        if (self.result != nil)
        {
            if (self.id != self.boundId || self.episode != self.boundEpisode || !holds(self.episode.recoveries,self))
                rpgExpandedReject('fear-faint-recovery-binding');
            value.status = 'reused'; value.check = self.result.check; return value;
        }
        if (self.episode.startedAt == nil) { value.reason = 'fear-faint-episode-required'; return value; }
        self.episode.assess(); local profile = self.episode.context.profile;
        if (self.episode.completedAt != nil) { value.reason = 'fear-faint-already-ended'; return value; }
        if (profile.dead) { value.reason = 'fear-faint-dead'; return value; }
        if (profile.fearFaint != self.episode || !profile.unconscious) rpgExpandedReject('fear-faint-owner');
        if (rpgLedger.seconds < self.episode.nextCheckAt) { value.reason = 'fear-faint-not-due'; return value; }
        foreach (local prior in self.episode.recoveries)
            if (prior.id == self.id) rpgExpandedReject('fear-faint-recovery-duplicate');
        local context = new RpgLiteContext(); context.attribute = rpgHT; context.kind = 'fear-faint-recovery';
        local score = rpgLiteScore(profile,context);
        if (score == nil || score < 3) { value.reason = 'fear-faint-health-score'; return value; }
        rpgInteger(rpgLedger.seconds,0,2147483587);
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local profile = self.episode.context.profile;
        local context = new RpgLiteContext(); context.attribute = rpgHT; context.kind = 'fear-faint-recovery';
        value.check = rpgLiteCheck(profile,context);
        if (value.check.achieved)
        {
            profile.fearFaint = nil; self.episode.completedAt = rpgLedger.seconds;
            if (!profile.unconsciousRecoveryOwned() && !profile.dead && !profile.mortal && profile.hp() > 0 && profile.fp() > 0
                && profile.cardiacArrest == nil && profile.fearSeconds == 0 && !profile.apparentDeath && !profile.needsMedicalHelp)
            { profile.unconscious = nil; profile.unconsciousClock = 0; }
        }
        else self.episode.nextCheckAt = rpgLedger.seconds + 60;
        self.boundId = self.id; self.boundEpisode = self.episode;
        self.episode.recoveries = self.episode.recoveries + [self]; value.status = 'resolved'; self.result = value; return value;
    }
;

/** Stop at a pending faint check instead of skipping required minute boundaries. */
modify rpgLedger
    validateAdvance(seconds)
    {
        inherited(seconds);
        for (local episode = firstObj(RpgExpandedFearFaint); episode != nil; episode = nextObj(episode,RpgExpandedFearFaint))
            if (episode.startedAt != nil && episode.completedAt == nil && !episode.context.profile.dead
                && self.seconds + seconds > episode.nextCheckAt) rpgExpandedReject('fear-faint-recovery-boundary');
        return nil;
    }
;

/** Pure optional bleeding-minute outcome, full-2008 B420. The caller supplies
 * the verified loss basis and actual die roll; this never draws or spends. */
rpgExpandedBleedingOutcome(health, lossBasis, modifier, roll, clearMinutes)
{
    rpgInteger(health,1,1000); rpgInteger(lossBasis,0,1000000);
    rpgInteger(modifier,-1000,1000); rpgInteger(roll,3,18); rpgInteger(clearMinutes,0,2);
    local value = new RpgExpandedBleedingResult();
    value.modifier = modifier - lossBasis / 5;
    local score = health + value.modifier;
    if (score < 3) { value.reason = 'bleeding-score-unavailable'; return value; }
    value.check = rpgCheck(score,roll);
    if (value.check.critical == 'success')
    { value.stopped = true; value.clearMinutes = clearMinutes + 1; }
    else if (value.check.achieved)
    { value.clearMinutes = clearMinutes + 1; value.stopped = value.clearMinutes >= 3; }
    else
    { value.injury = value.check.critical == 'failure' ? 3 : 1; value.clearMinutes = 0; }
    value.status = 'ready'; return value;
}

/** A minute's bleeding consequence, before shared injury-ledger execution. */
class RpgExpandedBleedingResult: RpgExpandedResult
    injury = 0
    clearMinutes = 0
    stopped = nil
;


modify RpgExpandedRules
    bleeding = nil
;

modify RpgExpandedProfile
    bleedingEpisode = nil
    bleedingHistory = []
;

/** Concrete author classification for one actual wound, B420. Damage category
 * and exceptions remain explicit; no generic predicate counts as eligibility. */
class RpgExpandedBleedingWound: object
    wound = nil
    damageKind = nil
    bleeds = nil
    approved = nil
    evidence = nil
    exceptionEvidence = nil
    assess()
    {
        if (self.wound == nil || !self.wound.ofKind(RpgExpandedWound)
            || self.wound.health == nil || self.wound.committedAt == nil)
            rpgExpandedReject('bleeding-committed-wound-required');
        self.wound.assess();
        if (!holds(['cutting','impaling','piercing','crushing','burning','corrosion','other'],self.damageKind))
            rpgExpandedReject('bleeding-damage-kind');
        local value = new RpgExpandedResult();
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'bleeding-wound-evidence'; return value; }
        if (self.wound.health.injury <= 0) { value.reason = 'bleeding-no-injury'; return value; }
        local ordinary = holds(['cutting','impaling','piercing'],self.damageKind);
        if (self.damageKind == 'burning' || self.damageKind == 'corrosion')
            ordinary = self.wound.knockdownAssessment.major;
        if (self.damageKind == 'other' || (self.bleeds ? true : nil) != (ordinary ? true : nil))
            if (self.exceptionEvidence == nil || self.exceptionEvidence == '')
            { value.reason = 'bleeding-exception-evidence'; return value; }
        value.status = 'ready'; return value;
    }
;

/** Owned onset for a classified wound. Late registration and overlapping wounds
 * require the still-pending aggregation procedure, never a reset of the clock. */
class RpgExpandedBleedingEpisode: object
    id = nil
    classification = nil
    result = nil
    startedAt = nil
    nextCheckAt = nil
    stoppedAt = nil
    clearMinutes = 0
    minutes = []
    boundDefinition = nil
    definition()
    {
        local entry = self.classification;
        return [self.id,entry,entry.wound,entry.wound.profile,entry.damageKind,entry.bleeds,
            entry.approved,entry.evidence,entry.exceptionEvidence];
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.classification == nil
            || !self.classification.ofKind(RpgExpandedBleedingWound)) rpgExpandedReject('bleeding-episode-definition');
        local eligible = self.classification.assess();
        local profile = self.classification.wound.profile; local value = new RpgExpandedResult();
        if (self.result != nil)
        {
            local current = self.definition();
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.boundDefinition[index]) rpgExpandedReject('bleeding-episode-binding');
            if (!holds(profile.bleedingHistory,self)) rpgExpandedReject('bleeding-episode-history');
            value.status = 'reused'; return value;
        }
        if (eligible.status != 'ready') return eligible;
        rpgExpandedValidate(profile);
        if (profile.level('impaired-clotting') > 0)
        { value.reason = 'bleeding-impaired-clotting-procedure-required'; return value; }
        if (!profile.rules.bleeding) { value.reason = 'bleeding-rule-disabled'; return value; }
        if (!self.classification.bleeds) { value.reason = 'bleeding-wound-ineligible'; return value; }
        if (profile.dead) { value.reason = 'bleeding-dead'; return value; }
        if (profile.bleedingEpisode != nil) { value.reason = 'bleeding-aggregation-required'; return value; }
        if (self.classification.wound.committedAt != rpgLedger.seconds)
        { value.reason = 'bleeding-late-registration'; return value; }
        foreach (local prior in profile.bleedingHistory)
            if (prior.id == self.id || prior.classification.wound == self.classification.wound)
                rpgExpandedReject('bleeding-episode-duplicate');
        rpgInteger(rpgLedger.seconds,0,2147483587);
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local profile = self.classification.wound.profile;
        self.boundDefinition = self.definition(); self.startedAt = rpgLedger.seconds;
        self.nextCheckAt = self.startedAt + 60; profile.bleedingEpisode = self;
        profile.bleedingHistory = profile.bleedingHistory + [self];
        value.status = 'resolved'; self.result = value; return value;
    }
;

/** Pending bleeding checks cannot be silently skipped by an unrelated action. */
modify rpgLedger
    validateAdvance(seconds)
    {
        inherited(seconds);
        for (local episode = firstObj(RpgExpandedBleedingEpisode); episode != nil;
            episode = nextObj(episode,RpgExpandedBleedingEpisode))
            if (episode.startedAt != nil && episode.stoppedAt == nil && !episode.classification.wound.profile.dead)
            {
                episode.assess();
                if (self.seconds + seconds > episode.nextCheckAt) rpgExpandedReject('bleeding-minute-boundary');
            }
        return nil;
    }
;

modify RpgExpandedBleedingResult
    wound = nil
    context = nil
;

/** One owned due-minute check. Loss-basis policy is explicit author evidence
 * until multi-wound/healing aggregation is reconciled from the reference. */
class RpgExpandedBleedingMinute: object
    id = nil
    episode = nil
    lossBasis = 0
    basisEvidence = nil
    approved = nil
    dropDestination = nil
    result = nil
    boundDefinition = nil
    resolvedAt = nil
    definition()
    {
        return [self.id,self.episode,self.lossBasis,self.basisEvidence,self.approved,self.dropDestination];
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.episode == nil
            || !self.episode.ofKind(RpgExpandedBleedingEpisode)) rpgExpandedReject('bleeding-minute-definition');
        local value = new RpgExpandedBleedingResult();
        if (self.result != nil)
        {
            local current = self.definition();
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.boundDefinition[index]) rpgExpandedReject('bleeding-minute-binding');
            if (!holds(self.episode.minutes,self)) rpgExpandedReject('bleeding-minute-history');
            value.status = 'reused'; return value;
        }
        if (self.episode.result == nil) { value.reason = 'bleeding-episode-not-started'; return value; }
        self.episode.assess();
        local profile = self.episode.classification.wound.profile;
        if (profile.level('impaired-clotting') > 0)
        { value.reason = 'bleeding-impaired-clotting-procedure-required'; return value; }
        if (self.episode.stoppedAt != nil || profile.dead || profile.bleedingEpisode != self.episode)
        { value.reason = 'bleeding-episode-inactive'; return value; }
        if (rpgLedger.seconds != self.episode.nextCheckAt)
        { value.reason = 'bleeding-minute-not-due'; return value; }
        if (!self.approved || self.basisEvidence == nil || self.basisEvidence == '')
        { value.reason = 'bleeding-loss-basis-required'; return value; }
        rpgInteger(self.lossBasis,0,1000000); rpgInteger(rpgLedger.seconds,0,2147483587);
        foreach (local prior in self.episode.minutes)
            if (prior.id == self.id || prior.resolvedAt == rpgLedger.seconds) rpgExpandedReject('bleeding-minute-duplicate');
        /* The ordinary wound interface would add a major-wound check below this
         * capacity. Blood-loss-specific small-body handling needs its own rule. */
        if (profile.maxHP < 6 || profile.rules.lastWounds)
        { value.reason = 'bleeding-injury-policy-unimplemented'; return value; }
        local context = new RpgLiteContext(); context.attribute = rpgHT; context.kind = 'bleeding';
        context.modifier = -(self.lossBasis / 5);
        local score = rpgLiteScore(profile,context);
        if (score == nil || score < 3) { value.reason = 'bleeding-score-unavailable'; return value; }
        value.context = context;
        value.wound = new RpgExpandedWound(); value.wound.id = 'bleeding-' + self.episode.id + '-' + self.id;
        value.wound.profile = profile; value.wound.amount = 3; value.wound.dropDestination = self.dropDestination;
        local maximumLoss = value.wound.assess();
        if (maximumLoss.status != 'ready') { value.reason = maximumLoss.reason; return value; }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local prepared = self.assess(); if (prepared.status != 'ready') return prepared;
        local profile = self.episode.classification.wound.profile;
        local check = rpgLiteCheck(profile,prepared.context);
        local value = rpgExpandedBleedingOutcome(profile.ht,self.lossBasis,
            check.score - profile.ht + self.lossBasis / 5,check.roll,self.episode.clearMinutes);
        if (value.status != 'ready') rpgExpandedReject('bleeding-minute-outcome-changed');
        value.check = check;
        if (value.injury > 0)
        {
            prepared.wound.amount = value.injury;
            local committed = prepared.wound.apply();
            if (committed.status != 'resolved') rpgExpandedReject('bleeding-injury-changed');
            value.wound = prepared.wound; value.injury = committed.health.injury;
        }
        self.episode.clearMinutes = value.clearMinutes;
        if (value.stopped || profile.dead)
        {
            self.episode.stoppedAt = rpgLedger.seconds; profile.bleedingEpisode = nil;
        }
        else self.episode.nextCheckAt += 60;
        self.boundDefinition = self.definition(); self.resolvedAt = rpgLedger.seconds;
        self.episode.minutes = self.episode.minutes + [self];
        value.status = 'resolved'; self.result = value; return value;
    }
;

modify RpgExpandedBleedingEpisode
    aidAttempts = []
;

/** One minute of pressure/tourniquet care followed by the optional bleeding
 * First Aid check, full-2008 B424. Bandage healing credit is a separate procedure. */
class RpgExpandedBleedingAid: object
    id = nil
    episode = nil
    healer = nil
    bandage = nil
    skill = nil
    modifier = 0
    approved = nil
    careEvidence = nil
    uninterrupted = nil
    startedAt = nil
    completesAt = nil
    completedAt = nil
    boundDefinition = nil
    result = nil
    definition()
    {
        return [self.id,self.episode,self.healer,self.skill,self.modifier,self.approved,self.careEvidence,self.bandage];
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.episode == nil
            || !self.episode.ofKind(RpgExpandedBleedingEpisode) || self.healer == nil
            || !self.healer.ofKind(RpgLiteProfile) || self.skill == nil
            || !self.skill.ofKind(RpgLiteSkill) || self.skill.id != 'first-aid' || self.skill.techLevel == nil)
            rpgExpandedReject('bleeding-aid-definition');
        rpgInteger(self.modifier,-100,100);
        local value = new RpgExpandedBleedingResult();
        if (self.startedAt != nil)
        {
            local current = self.definition();
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.boundDefinition[index]) rpgExpandedReject('bleeding-aid-binding');
            if (!holds(self.episode.aidAttempts,self)) rpgExpandedReject('bleeding-aid-history');
            if (self.result != nil) { value.status = 'reused'; return value; }
        }
        if (self.episode.result == nil) { value.reason = 'bleeding-episode-not-started'; return value; }
        self.episode.assess();
        local patient = self.episode.classification.wound.profile;
        if (self.episode.stoppedAt != nil || patient.dead || patient.bleedingEpisode != self.episode)
        { value.reason = 'bleeding-episode-inactive'; return value; }
        if (self.healer.dead || self.healer.unconscious || self.healer.mortal
            || self.healer.stunned || self.healer.mentalStun)
        { value.reason = 'bleeding-aid-healer-incapacity'; return value; }
        if (!self.approved || self.careEvidence == nil || self.careEvidence == '')
        { value.reason = 'bleeding-aid-care-required'; return value; }
        if (self.startedAt == nil)
        {
            foreach (local prior in self.episode.aidAttempts)
            {
                if (prior.id == self.id) rpgExpandedReject('bleeding-aid-duplicate');
                if (prior.result == nil) { value.reason = 'bleeding-aid-overlap-unimplemented'; return value; }
            }
            rpgInteger(rpgLedger.seconds,0,2147483587);
        }
        if (self.bandage != nil)
        {
            if (!self.bandage.ofKind(RpgExpandedBandage) || self.bandage.wound != self.episode.classification.wound
                || self.bandage.healer != self.healer) rpgExpandedReject('bleeding-aid-bandage');
            local credit = self.bandage.assess();
            if (credit.status != 'ready')
            { value.reason = credit.status == 'reused' ? 'bleeding-aid-bandage-used' : credit.reason; return value; }
        }
        value.context = new RpgLiteContext(); value.context.skill = self.skill;
        value.context.kind = 'first-aid'; value.context.modifier = self.modifier;
        local score = rpgLiteScore(self.healer,value.context);
        if (score == nil || score < 3) { value.reason = 'bleeding-aid-score-unavailable'; return value; }
        value.status = 'ready'; return value;
    }
    start()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        if (self.startedAt != nil) { value.status = 'reused'; return value; }
        self.startedAt = rpgLedger.seconds; self.completesAt = self.startedAt + 60;
        self.boundDefinition = self.definition(); self.episode.aidAttempts = self.episode.aidAttempts + [self];
        value.status = 'resolved'; return value;
    }
    assessCompletion()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        if (self.startedAt == nil) { value.status = 'blocked'; value.reason = 'bleeding-aid-not-started'; return value; }
        if (rpgLedger.seconds != self.completesAt)
        { value.status = 'blocked'; value.reason = 'bleeding-aid-not-due'; return value; }
        if (!self.uninterrupted)
        { value.status = 'blocked'; value.reason = 'bleeding-aid-interrupted'; return value; }
        return value;
    }
    cancel()
    {
        local value = new RpgExpandedBleedingResult();
        if (self.startedAt == nil) { value.reason = 'bleeding-aid-not-started'; return value; }
        /* Validate bindings even when a changed world condition blocks care. */
        self.assess();
        if (self.result != nil) { value.status = 'reused'; return value; }
        value.reason = 'bleeding-aid-interrupted'; value.status = 'resolved';
        self.completedAt = rpgLedger.seconds; self.result = value; return value;
    }
    complete()
    {
        local value = self.assessCompletion(); if (value.status != 'ready') return value;
        value.check = rpgLiteCheck(self.healer,value.context); value.stopped = value.check.achieved;
        if (value.stopped)
        {
            self.episode.stoppedAt = rpgLedger.seconds;
            self.episode.classification.wound.profile.bleedingEpisode = nil;
        }
        self.completedAt = rpgLedger.seconds; value.status = 'resolved'; self.result = value;
        if (value.stopped && self.bandage != nil)
        {
            local credit = self.bandage.applyAfterBleedingCare(self);
            if (credit.status != 'resolved') rpgExpandedReject('bleeding-aid-bandage-changed');
            value.healed = credit.healed;
        }
        return value;
    }
;

modify RpgExpandedBleedingResult
    healed = 0
;

/** Care and blood-loss checks have independent deadlines. Never skip a due
 * treatment decision just because the next bleeding check is later. */
modify rpgLedger
    validateAdvance(seconds)
    {
        inherited(seconds);
        for (local care = firstObj(RpgExpandedBleedingAid); care != nil; care = nextObj(care,RpgExpandedBleedingAid))
            if (care.startedAt != nil && care.result == nil && care.episode.stoppedAt == nil
                && !care.episode.classification.wound.profile.dead)
            {
                care.assess();
                if (self.seconds + seconds > care.completesAt) rpgExpandedReject('bleeding-care-boundary');
            }
        return nil;
    }
;


/** B142 pain sensitivity uses the shared wound pipeline, including fatigue injury. */
modify RpgLiteHealthResult
    painCryCheck = nil
    criedOut = nil
;
modify RpgExpandedProfile
    shockLimit() { return self.level('low-pain-threshold') > 0 ? 8 : inherited(); }
    validateInjury(amount)
    {
        inherited(amount);
        if (self.level('low-pain-threshold') == 0) return nil;
        if (self.level('high-pain-threshold') > 0) rpgExpandedReject('pain-threshold-conflict');
        if (!self.rules.scaledInjuryShock) rpgExpandedReject('pain-sensitivity-shock-rule-required');
        if (amount > 1)
        {
            local context = new RpgLiteContext(); context.attribute = rpgWill; context.kind = 'pain-cry';
            local score = rpgLiteScore(self,context);
            if (score == nil || score < 3) rpgExpandedReject('pain-cry-score-unavailable');
        }
        return nil;
    }
    afterInjuryShock(amount, result)
    {
        inherited(amount,result);
        if (amount > 1 && self.level('low-pain-threshold') > 0)
        {
            local context = new RpgLiteContext(); context.attribute = rpgWill; context.kind = 'pain-cry';
            result.painCryCheck = rpgLiteCheck(self,context);
            result.checks = result.checks + [result.painCryCheck];
            result.criedOut = !result.painCryCheck.achieved;
        }
        return nil;
    }
    healthAttributeModifier(context)
    {
        local value = inherited(context);
        if (self.level('low-pain-threshold') > 0 && holds(['major-wound','physical-stun','torture'],context.kind))
            value -= 4;
        return value;
    }
;

/** B158 one-year terminal condition acquired during play. Calendar length is authored. */
class RpgExpandedTerminalCondition: RpgLiteTrait
    id = 'terminal-condition'
    points = -75
    profile = nil
    yearSeconds = nil
    approved = nil
    calendarEvidence = nil
    meaningfulDuration = nil
    acquiredAt = nil
    deathDue = nil
    deathAt = nil
    boundDefinition = nil
    definition() { return [self.id,self.profile,self.yearSeconds,self.approved,self.calendarEvidence,self.meaningfulDuration]; }
    creationCost()
    {
        if (self.id != 'terminal-condition' || self.points != -75 || self.level != 1
            || !self.active || self.mitigated) rpgExpandedReject('terminal-condition-definition');
        return -75;
    }
    validateReceipt()
    {
        if (self.acquiredAt == nil || self.boundDefinition == nil) rpgExpandedReject('terminal-condition-unacquired');
        local current = self.definition();
        for (local index = 1; index <= current.length(); index += 1)
            if (current[index] != self.boundDefinition[index]) rpgExpandedReject('terminal-condition-binding');
        self.creationCost();
        if (!holds(self.profile.terminalConditions,self) || !holds(self.profile.traits,self))
            rpgExpandedReject('terminal-condition-ownership');
        if (self.deathDue != self.acquiredAt + self.yearSeconds) rpgExpandedReject('terminal-condition-deadline');
        return nil;
    }
    assess()
    {
        if (self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)) rpgExpandedReject('terminal-condition-profile');
        local value = new RpgExpandedResult(); self.creationCost();
        if (self.acquiredAt != nil) { self.validateReceipt(); value.status = 'reused'; return value; }
        rpgExpandedValidate(self.profile); rpgInteger(self.yearSeconds,1,2147483647);
        if (!self.approved || !self.meaningfulDuration || self.calendarEvidence == nil || self.calendarEvidence == '')
        { value.reason = 'terminal-condition-author-evidence'; return value; }
        if (!self.profile.creationComplete) { value.reason = 'terminal-condition-after-creation'; return value; }
        if (self.profile.dead) { value.reason = 'terminal-condition-patient-dead'; return value; }
        foreach (local trait in self.profile.traits)
            if (trait.id == self.id) { value.reason = 'terminal-condition-existing'; return value; }
        if (self.profile.terminalConditions.length() != 0) { value.reason = 'terminal-condition-reacquisition-unimplemented'; return value; }
        if (rpgLedger.seconds > 2147483647 - self.yearSeconds) rpgExpandedReject('terminal-condition-time-capacity');
        rpgInteger(self.profile.developmentRevision,0,2147483646);
        value.points = -75; value.status = 'ready'; return value;
    }
    acquire()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.acquiredAt = rpgLedger.seconds; self.deathDue = self.acquiredAt + self.yearSeconds;
        self.boundDefinition = self.definition();
        self.profile.traits = self.profile.traits + [self];
        self.profile.terminalConditions = self.profile.terminalConditions + [self];
        self.profile.developmentRevision += 1; value.status = 'resolved'; return value;
    }
    assessDeath()
    {
        self.validateReceipt(); local value = new RpgExpandedResult();
        if (self.deathAt != nil) { value.status = 'reused'; return value; }
        if (self.profile.dead) { value.reason = 'terminal-condition-already-dead'; return value; }
        if (rpgLedger.seconds != self.deathDue) { value.reason = 'terminal-condition-not-due'; return value; }
        value.status = 'ready'; return value;
    }
    resolveDeath()
    {
        local value = self.assessDeath(); if (value.status != 'ready') return value;
        self.profile.dead = true; self.profile.becomeUnconscious(); self.deathAt = rpgLedger.seconds;
        value.status = 'resolved'; return value;
    }
;

modify RpgExpandedProfile
    terminalConditions = []
    postCreationDisadvantageAllowance()
    {
        local value = inherited();
        foreach (local condition in self.terminalConditions)
        {
            if (!condition.ofKind(RpgExpandedTerminalCondition) || condition.profile != self)
                rpgExpandedReject('terminal-condition-history');
            condition.validateReceipt(); value += 75;
        }
        return value;
    }
;
modify rpgLedger
    validateAdvance(seconds)
    {
        inherited(seconds);
        for (local condition = firstObj(RpgExpandedTerminalCondition); condition != nil;
            condition = nextObj(condition,RpgExpandedTerminalCondition))
            if (condition.acquiredAt != nil && condition.deathAt == nil && !condition.profile.dead)
            {
                condition.validateReceipt();
                if (self.seconds + seconds > condition.deathDue) rpgExpandedReject('terminal-condition-death-boundary');
            }
        return nil;
    }
;

/** B165 simple sterility is a zero-point feature, not the broader sexual trait. */
class RpgExpandedSterility: RpgLiteTrait
    id = 'sterility'
    points = 0
    creationCost()
    {
        if (self.id != 'sterility' || self.points != 0 || self.level != 1)
            rpgExpandedReject('sterility-definition');
        return 0;
    }
;
modify RpgExpandedProfile
    fertilityBlocked() { return self.level('sterility') > 0; }
;

/** B428 nausea duration belongs to the causing disease, hazard or authored effect. */
class RpgExpandedNausea: object
    id = nil
    profile = nil
    approved = nil
    causeEvidence = nil
    durationSeconds = nil
    startedAt = nil
    expiresAt = nil
    endedAt = nil
    endEvidence = nil
    boundDefinition = nil
    boundEndEvidence = nil
    definition() { return [self.id,self.profile,self.approved,self.causeEvidence,self.durationSeconds]; }
    validateReceipt()
    {
        if (self.startedAt == nil || self.boundDefinition == nil) rpgExpandedReject('nausea-unstarted');
        local current = self.definition();
        for (local index = 1; index <= current.length(); index += 1)
            if (current[index] != self.boundDefinition[index]) rpgExpandedReject('nausea-binding');
        if (!holds(self.profile.nauseaEpisodes,self)) rpgExpandedReject('nausea-history');
        if (self.endedAt != nil && self.endEvidence != self.boundEndEvidence) rpgExpandedReject('nausea-end-binding');
        rpgInteger(self.startedAt,0,rpgLedger.seconds); return nil;
    }
    activeNow()
    {
        self.validateReceipt();
        return self.endedAt == nil && (self.expiresAt == nil || rpgLedger.seconds < self.expiresAt);
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile))
            rpgExpandedReject('nausea-definition');
        local value = new RpgExpandedResult();
        if (self.startedAt != nil) { self.validateReceipt(); value.status = 'reused'; return value; }
        rpgExpandedValidate(self.profile);
        if (!self.approved || self.causeEvidence == nil || self.causeEvidence == '')
        { value.reason = 'nausea-cause-required'; return value; }
        if (self.profile.dead) { value.reason = 'nausea-patient-dead'; return value; }
        if (self.durationSeconds != nil) rpgInteger(self.durationSeconds,1,2147483647 - rpgLedger.seconds);
        foreach (local prior in self.profile.nauseaEpisodes)
        {
            prior.validateReceipt();
            if (prior.id == self.id) rpgExpandedReject('nausea-duplicate');
        }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.startedAt = rpgLedger.seconds;
        self.expiresAt = self.durationSeconds == nil ? nil : self.startedAt + self.durationSeconds;
        self.boundDefinition = self.definition(); self.profile.nauseaEpisodes = self.profile.nauseaEpisodes + [self];
        value.status = 'resolved'; return value;
    }
    assessEnd()
    {
        self.validateReceipt(); local value = new RpgExpandedResult();
        if (self.endedAt != nil) { value.status = 'reused'; return value; }
        if (self.endEvidence == nil || self.endEvidence == '') { value.reason = 'nausea-end-evidence-required'; return value; }
        value.status = 'ready'; return value;
    }
    end()
    {
        local value = self.assessEnd(); if (value.status != 'ready') return value;
        self.endedAt = rpgLedger.seconds; self.boundEndEvidence = self.endEvidence;
        value.status = 'resolved'; return value;
    }
;
modify RpgExpandedProfile
    nauseaEpisodes = []
    nauseated()
    {
        local active = nil;
        foreach (local episode in self.nauseaEpisodes)
        {
            if (episode == nil || !episode.ofKind(RpgExpandedNausea) || episode.profile != self)
                rpgExpandedReject('nausea-history');
            if (episode.activeNow()) active = true;
        }
        return active;
    }
    healthAttributeModifier(context)
    {
        local value = inherited(context);
        if (self.nauseated() && !holds(['defense','self-control'],context.kind)) value -= 2;
        return value;
    }
    healthDefensePenalty() { return inherited() + (self.nauseated() ? 1 : 0); }
;


/** Preserve the public fear entry point while sharing the physical condition. */
class RpgExpandedFearRetching: RpgExpandedRetching
    recoveryCheckRequired() { return true; }
    contextAccepted() { return self.context != nil && self.context.ofKind(RpgExpandedFearContext); }
;
class RpgExpandedRetchingContext: object
    profile = nil
    approved = nil
    evidence = nil
    assess()
    {
        rpgExpandedValidate(self.profile); local value = new RpgExpandedResult();
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'retching-cause-evidence-required'; return value; }
        value.status = 'ready'; return value;
    }
;

modify RpgExpandedProfile
    nauseaTriggers = []
;
class RpgExpandedNauseaTriggerResult: RpgExpandedResult
    checkRequired = nil
    context = nil
    retching = nil
;

/** B428 event-driven vomiting check. Event identity is supplied by the author. */
class RpgExpandedNauseaTrigger: object
    kindAccepted() { return holds(['meal','odor','fear-failure','stun'],self.kind); }
    eventReason() { return nil; }
    skipWhenHealthy() { return nil; }
    eventId = nil
    profile = nil
    kind = nil
    observedAt = nil
    approved = nil
    evidence = nil
    richMealWithinHour = nil
    episode = nil
    result = nil
    boundDefinition = nil
    definition()
    {
        return [self.eventId,self.profile,self.kind,self.observedAt,self.approved,
            self.evidence,self.richMealWithinHour,self.episode];
    }
    assess()
    {
        if (self.eventId == nil || self.eventId == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)
            || !self.kindAccepted()) rpgExpandedReject('nausea-trigger-definition');
        local value = new RpgExpandedNauseaTriggerResult();
        if (self.result != nil)
        {
            local current = self.definition();
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.boundDefinition[index]) rpgExpandedReject('nausea-trigger-binding');
            if (!holds(self.profile.nauseaTriggers,self)) rpgExpandedReject('nausea-trigger-history');
            if (self.result.retching != nil && self.result.retching.assess().status != 'reused')
                rpgExpandedReject('nausea-trigger-retching-history');
            value.status = 'reused'; value.check = self.result.check; value.retching = self.result.retching;
            value.checkRequired = self.result.checkRequired; return value;
        }
        rpgExpandedValidate(self.profile);
        if (!self.approved || self.evidence == nil || self.evidence == '' || self.observedAt != rpgLedger.seconds)
        { value.reason = 'nausea-trigger-current-event-required'; return value; }
        value.reason = self.eventReason(); if (value.reason != nil) return value;
        foreach (local prior in self.profile.nauseaTriggers)
            if (prior.eventId == self.eventId) rpgExpandedReject('nausea-trigger-duplicate-event');
        if (!self.profile.nauseated())
        {
            if (self.skipWhenHealthy()) value.status = 'ready';
            else value.reason = 'nausea-trigger-condition-required';
            return value;
        }
        value.checkRequired = true;
        if (self.episode == nil || !self.episode.ofKind(RpgExpandedRetching)
            || self.episode.ofKind(RpgExpandedFearRetching) || self.episode.context == nil
            || self.episode.context.profile != self.profile) rpgExpandedReject('nausea-trigger-episode');
        local prepared = self.episode.assess();
        if (prepared.status != 'ready') { value.reason = 'nausea-trigger-retching-unavailable'; return value; }
        value.context = new RpgLiteContext(); value.context.attribute = rpgHT; value.context.kind = 'nausea-trigger';
        value.context.modifier = rpgExpandedNauseaTriggerModifier(self.profile,self.richMealWithinHour);
        local score = rpgLiteScore(self.profile,value.context);
        if (score == nil || score < 3) { value.reason = 'nausea-trigger-score-unavailable'; return value; }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        if (value.checkRequired) value.check = rpgLiteCheck(self.profile,value.context);
        if (value.check != nil && !value.check.achieved)
        {
            if (self.episode.apply().status != 'resolved') rpgExpandedReject('nausea-trigger-retching-changed');
            value.retching = self.episode;
        }
        self.boundDefinition = self.definition(); self.profile.nauseaTriggers = self.profile.nauseaTriggers + [self];
        value.status = 'resolved'; self.result = value; return value;
    }
;


/** Fixed-duration retching must be completed before another action skips its end. */
modify rpgLedger
    validateAdvance(seconds)
    {
        inherited(seconds);
        for (local episode = firstObj(RpgExpandedRetching); episode != nil; episode = nextObj(episode,RpgExpandedRetching))
            if (episode.startedAt != nil && episode.completedAt == nil && !episode.recoveryCheckRequired()
                && !episode.boundProfile.dead)
            {
                episode.assess();
                if (self.seconds + seconds > episode.initialEnd) rpgExpandedReject('retching-fixed-end-boundary');
            }
        return nil;
    }
;


modify RpgExpandedProfile
    nauseaMotionExposures = []
;
/** B428 authored continuing free-fall or motion-sickness situation. */
class RpgExpandedNauseaMotion: object
    id = nil
    profile = nil
    kind = 'motion'
    approved = nil
    evidence = nil
    startedAt = nil
    nextCheckAt = nil
    endedAt = nil
    endEvidence = nil
    boundEndEvidence = nil
    boundDefinition = nil
    hours = []
    definition() { return [self.id,self.profile,self.kind,self.approved,self.evidence]; }
    validateReceipt()
    {
        if (self.startedAt == nil || self.boundDefinition == nil) rpgExpandedReject('nausea-motion-unstarted');
        local current = self.definition();
        for (local index = 1; index <= current.length(); index += 1)
            if (current[index] != self.boundDefinition[index]) rpgExpandedReject('nausea-motion-binding');
        if (!holds(self.profile.nauseaMotionExposures,self)) rpgExpandedReject('nausea-motion-history');
        if (self.endedAt != nil && self.endEvidence != self.boundEndEvidence) rpgExpandedReject('nausea-motion-end-binding');
        return nil;
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)
            || !holds(['motion','free-fall'],self.kind)) rpgExpandedReject('nausea-motion-definition');
        local value = new RpgExpandedResult();
        if (self.startedAt != nil) { self.validateReceipt(); value.status = 'reused'; return value; }
        rpgExpandedValidate(self.profile);
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'nausea-motion-evidence'; return value; }
        if (self.profile.dead) { value.reason = 'nausea-motion-patient-dead'; return value; }
        foreach (local prior in self.profile.nauseaMotionExposures)
        {
            prior.validateReceipt();
            if (prior.id == self.id) rpgExpandedReject('nausea-motion-duplicate');
            if (prior.endedAt == nil) { value.reason = 'nausea-motion-overlap'; return value; }
        }
        rpgInteger(rpgLedger.seconds,0,2147480047); value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.startedAt = rpgLedger.seconds; self.nextCheckAt = self.startedAt + 3600;
        self.boundDefinition = self.definition(); self.profile.nauseaMotionExposures = self.profile.nauseaMotionExposures + [self];
        value.status = 'resolved'; return value;
    }
    end()
    {
        self.validateReceipt(); local value = new RpgExpandedResult();
        if (self.endedAt != nil) { value.status = 'reused'; return value; }
        if (self.endEvidence == nil || self.endEvidence == '') { value.reason = 'nausea-motion-end-evidence'; return value; }
        if (!self.profile.dead && rpgLedger.seconds >= self.nextCheckAt)
        { value.reason = 'nausea-motion-due-hour'; return value; }
        self.endedAt = rpgLedger.seconds; self.boundEndEvidence = self.endEvidence; value.status = 'resolved'; return value;
    }
;
/** Each completed hour uses the shared trigger operation and oral review. */
class RpgExpandedNauseaMotionHour: RpgExpandedNauseaTrigger
    motion = nil
    kind = 'motion-hour'
    kindAccepted() { return self.kind == 'motion-hour'; }
    skipWhenHealthy() { return true; }
    definition() { return inherited() + [self.motion]; }
    eventReason()
    {
        if (self.motion == nil || !self.motion.ofKind(RpgExpandedNauseaMotion)
            || self.motion.profile != self.profile) rpgExpandedReject('nausea-motion-hour-definition');
        self.motion.validateReceipt();
        if (self.motion.endedAt != nil) return 'nausea-motion-ended';
        if (rpgLedger.seconds != self.motion.nextCheckAt) return 'nausea-motion-hour-not-due';
        rpgInteger(rpgLedger.seconds,0,2147480047); return nil;
    }
    apply()
    {
        local value = inherited(); if (value.status != 'resolved') return value;
        self.motion.hours = self.motion.hours + [self]; self.motion.nextCheckAt += 3600; return value;
    }
;
modify rpgLedger
    validateAdvance(seconds)
    {
        inherited(seconds);
        for (local motion = firstObj(RpgExpandedNauseaMotion); motion != nil; motion = nextObj(motion,RpgExpandedNauseaMotion))
            if (motion.startedAt != nil && motion.endedAt == nil && !motion.profile.dead)
            {
                motion.validateReceipt();
                if (self.seconds + seconds > motion.nextCheckAt) rpgExpandedReject('nausea-motion-hour-boundary');
            }
        return nil;
    }
;

class RpgExpandedClottingAssessment: RpgExpandedResult
    internal = nil
    intervalSeconds = nil
    injury = 0
    ordinaryHealingAllowed = nil
    requiresDefinitiveCare = nil
;

/** B138 deterministic assessment only. Care labels are supplied facts, not care execution. */
rpgExpandedAssessImpairedClotting(originalInjury, torsoImpaling, care)
{
    rpgInteger(originalInjury,1,100000);
    if (!holds(['untreated','first-aid','definitive'],care)) rpgExpandedReject('clotting-care-state');
    local value = new RpgExpandedClottingAssessment(); value.internal = torsoImpaling ? true : nil;
    value.requiresDefinitiveCare = value.internal && care != 'definitive';
    value.ordinaryHealingAllowed = care != 'untreated' && !value.internal;
    if (care == 'untreated') { value.intervalSeconds = 60; value.injury = originalInjury; }
    else if (value.requiresDefinitiveCare) { value.intervalSeconds = 86400; value.injury = originalInjury; }
    value.status = 'ready'; return value;
}

modify RpgExpandedProfile
    clottingHistory = []
    clottingProtectedInjury()
    {
        local total = 0;
        foreach (local episode in self.clottingHistory)
        {
            episode.validateReceipt(); local amount = episode.protectedInjury();
            if (amount > self.injury - total) rpgExpandedReject('clotting-protected-injury-history');
            total += amount;
        }
        return total;
    }
    clottingHealingBlocked() { return self.injury > 0 && self.clottingProtectedInjury() >= self.injury; }
    validateHealing(amount)
    {
        inherited(amount);
        if (amount > self.injury - self.clottingProtectedInjury()) rpgExpandedReject('clotting-protected-healing');
        return nil;
    }
    naturalRecoveryNeeded() { return !self.clottingHealingBlocked() && inherited(); }
    naturalRecoveryAmount()
    {
        local amount = inherited(); local available = self.injury - self.clottingProtectedInjury();
        return amount > available ? available : amount;
    }
;

/** B138 one wound's mandatory bleeding; registration is contemporaneous and owned. */
class RpgExpandedClottingEpisode: object
    id = nil
    wound = nil
    torsoImpaling = nil
    approved = nil
    evidence = nil
    startedAt = nil
    originalInjury = nil
    nextLossAt = nil
    care = 'untreated'
    firstAid = nil
    protectedInjury()
    {
        if (self.care != 'untreated') return self.internalLoss;
        local amount = self.originalInjury;
        foreach (local tick in self.ticks) amount += tick.result.injury;
        return amount - self.restoredInternal;
    }
    internalLoss = 0
    ticks = []
    boundDefinition = nil
    definition() { return [self.id,self.wound,self.torsoImpaling,self.approved,self.evidence]; }
    validateReceipt()
    {
        if (self.startedAt == nil || self.boundDefinition == nil) rpgExpandedReject('clotting-unstarted');
        local current = self.definition();
        for (local index = 1; index <= current.length(); index += 1)
            if (current[index] != self.boundDefinition[index]) rpgExpandedReject('clotting-binding');
        if (!holds(self.wound.profile.clottingHistory,self) || self.wound.assess().status != 'reused'
            || self.originalInjury != self.wound.health.injury) rpgExpandedReject('clotting-history');
        return nil;
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.wound == nil || !self.wound.ofKind(RpgExpandedWound)
            || self.wound.health == nil) rpgExpandedReject('clotting-wound-required');
        local value = new RpgExpandedResult();
        if (self.startedAt != nil) { self.validateReceipt(); value.status = 'reused'; return value; }
        self.wound.assess(); local profile = self.wound.profile; rpgExpandedValidate(profile);
        if (profile.level('impaired-clotting') == 0) { value.reason = 'clotting-trait-required'; return value; }
        rpgInteger(profile.ht,1,10);
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'clotting-wound-evidence'; return value; }
        if (profile.dead || self.wound.health.injury <= 0 || self.wound.bandage != nil)
        { value.reason = 'clotting-untreated-wound-required'; return value; }
        if (self.torsoImpaling && self.wound.location != 'torso') rpgExpandedReject('clotting-impalement-location');
        if (self.wound.committedAt != rpgLedger.seconds) { value.reason = 'clotting-late-registration'; return value; }
        if (profile.bleedingEpisode != nil) { value.reason = 'clotting-ordinary-transition-unimplemented'; return value; }
        foreach (local prior in profile.clottingHistory)
            if (prior.id == self.id || prior.wound == self.wound) rpgExpandedReject('clotting-duplicate-wound');
        rpgInteger(rpgLedger.seconds,0,2147483587); value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.startedAt = rpgLedger.seconds; self.originalInjury = self.wound.health.injury;
        self.nextLossAt = self.startedAt + 60; self.boundDefinition = self.definition();
        self.wound.profile.clottingHistory = self.wound.profile.clottingHistory + [self];
        value.status = 'resolved'; return value;
    }
;
class RpgExpandedClottingLossResult: RpgExpandedResult
    wound = nil
    injury = 0
;
class RpgExpandedClottingLoss: object
    id = nil
    episode = nil
    dropDestination = nil
    result = nil
    boundDefinition = nil
    completedAt = nil
    definition() { return [self.id,self.episode,self.dropDestination]; }
    assess()
    {
        if (self.id == nil || self.id == '' || self.episode == nil || !self.episode.ofKind(RpgExpandedClottingEpisode))
            rpgExpandedReject('clotting-loss-definition');
        self.episode.validateReceipt(); local value = new RpgExpandedClottingLossResult();
        if (self.result != nil)
        {
            local current = self.definition();
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.boundDefinition[index]) rpgExpandedReject('clotting-loss-binding');
            if (!holds(self.episode.ticks,self) || self.result.wound.assess().status != 'reused')
                rpgExpandedReject('clotting-loss-history');
            value.status = 'reused'; value.wound = self.result.wound; value.injury = self.result.injury; return value;
        }
        local profile = self.episode.wound.profile;
        if (profile.dead) { value.reason = 'clotting-loss-patient-dead'; return value; }
        local stage = rpgExpandedAssessImpairedClotting(self.episode.originalInjury,self.episode.torsoImpaling,self.episode.care);
        if (stage.intervalSeconds == nil) { value.reason = 'clotting-loss-stopped'; return value; }
        if (rpgLedger.seconds != self.episode.nextLossAt) { value.reason = 'clotting-loss-not-due'; return value; }
        if (profile.level('impaired-clotting') == 0) { value.reason = 'clotting-trait-transition-unimplemented'; return value; }
        if (profile.rules.lastWounds || self.episode.originalInjury * 2 > profile.maxHP)
        { value.reason = 'clotting-loss-injury-policy-unimplemented'; return value; }
        foreach (local prior in self.episode.ticks)
            if (prior.id == self.id || prior.completedAt == rpgLedger.seconds) rpgExpandedReject('clotting-loss-duplicate');
        rpgInteger(rpgLedger.seconds,0,2147483647 - stage.intervalSeconds);
        rpgInteger(self.episode.internalLoss,0,2147483647 - self.episode.originalInjury);
        value.injury = self.episode.originalInjury;
        value.wound = new RpgExpandedWound(); value.wound.profile = profile;
        value.wound.id = 'clotting-' + self.episode.id + '-' + self.id;
        value.wound.amount = value.injury; value.wound.dropDestination = self.dropDestination;
        local prepared = value.wound.assess();
        if (prepared.status != 'ready') { value.reason = prepared.reason; return value; }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        if (value.wound.apply().status != 'resolved') rpgExpandedReject('clotting-loss-wound-changed');
        if (self.episode.torsoImpaling) self.episode.internalLoss += value.injury;
        self.completedAt = rpgLedger.seconds; self.boundDefinition = self.definition();
        self.episode.ticks = self.episode.ticks + [self];
        local stage = rpgExpandedAssessImpairedClotting(self.episode.originalInjury,self.episode.torsoImpaling,self.episode.care);
        self.episode.nextLossAt += stage.intervalSeconds;
        value.status = 'resolved'; self.result = value; return value;
    }
;
modify rpgLedger
    validateAdvance(seconds)
    {
        inherited(seconds);
        for (local episode = firstObj(RpgExpandedClottingEpisode); episode != nil; episode = nextObj(episode,RpgExpandedClottingEpisode))
            if (episode.startedAt != nil && episode.nextLossAt != nil && !episode.wound.profile.dead)
            {
                episode.validateReceipt();
                if (self.seconds + seconds > episode.nextLossAt) rpgExpandedReject('clotting-loss-boundary');
            }
        return nil;
    }
;


/** B138/B424 pressure/bandaging shares the existing one-minute, one-credit operation. */
class RpgExpandedClottingBandage: RpgExpandedBandage
    episode = nil
    boundEpisode = nil
    completedAt = nil
    assess()
    {
        if (self.episode == nil || !self.episode.ofKind(RpgExpandedClottingEpisode)
            || self.wound != self.episode.wound) rpgExpandedReject('clotting-bandage-episode');
        self.episode.validateReceipt();
        if (self.result != nil)
        {
            if (self.episode != self.boundEpisode || self.episode.firstAid != self)
                rpgExpandedReject('clotting-bandage-binding');
            return inherited();
        }
        local value = new RpgExpandedBandageResult(); local patient = self.wound.profile;
        if (self.episode.care != 'untreated' || self.episode.firstAid != nil || self.wound.bandage != nil)
        { value.reason = 'clotting-bandage-already-treated'; return value; }
        if (self.healer == nil || !self.healer.ofKind(RpgLiteProfile)) rpgExpandedReject('clotting-bandage-healer');
        if (patient.dead || patient.mortal || self.healer.dead || self.healer.unconscious || self.healer.stunned)
        { value.reason = 'clotting-bandage-condition'; return value; }
        if (patient.diseaseInjury > 0 || patient.temperatureInjury > 0 || patient.level('unhealing') > 0)
        { value.reason = 'clotting-bandage-injury-combination-unimplemented'; return value; }
        if (self.evidence == nil || self.evidence == '' || self.eligibleInjury != self.episode.originalInjury)
        { value.reason = 'clotting-bandage-evidence'; return value; }
        if (patient.unconscious && patient.fp() > 0 && patient.ht < 3)
        { value.reason = 'bandage-wake-score-unavailable'; return value; }
        local protectedAfter = patient.clottingProtectedInjury() - self.episode.protectedInjury() + self.episode.internalLoss;
        value.healed = rpgExpandedHealingAmount(patient.maxHP,1);
        if (value.healed > self.eligibleInjury) value.healed = self.eligibleInjury;
        if (value.healed > patient.injury - protectedAfter) value.healed = patient.injury - protectedAfter;
        rpgInteger(rpgLedger.seconds,0,2147483647 - 86460);
        rpgLedger.validateAdvance(60);
        value.seconds = 60; value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local definition = [self.episode,self.wound,self.healer,self.evidence,self.eligibleInjury];
        local start = rpgLedger.seconds; rpgSpendTime(value.seconds);
        local current = [self.episode,self.wound,self.healer,self.evidence,self.eligibleInjury];
        for (local index = 1; index <= current.length(); index += 1)
            if (current[index] != definition[index]) rpgExpandedReject('clotting-bandage-interrupted');
        if (rpgLedger.seconds != start + 60 || self.episode.care != 'untreated' || self.wound.bandage != nil
            || self.wound.profile.dead || self.wound.profile.mortal || self.healer.dead
            || self.healer.unconscious || self.healer.stunned) rpgExpandedReject('clotting-bandage-interrupted');
        return self.commitHealing(value);
    }
    commitHealing(value)
    {
        self.boundEpisode = self.episode; self.completedAt = rpgLedger.seconds;
        self.episode.care = 'first-aid'; self.episode.firstAid = self;
        self.episode.nextLossAt = self.episode.torsoImpaling ? rpgLedger.seconds + 86400 : nil;
        return inherited(value);
    }
    applyAfterBleedingCare(care) { rpgExpandedReject('clotting-ordinary-care-incompatible'); }
;

modify RpgExpandedClottingEpisode
    restoredInternal = 0
;
modify RpgExpandedProfile
    clottingRestorations = []
;
class RpgExpandedClottingRestorationResult: RpgExpandedResult
    healed = 0
    stopped = nil
;

/** B138 concrete external supernatural-effect contract. The author supplies the
 * completed effect, its exact protected-HP grant and whether it stops bleeding. */
class RpgExpandedClottingRestoration: object
    eventId = nil
    episode = nil
    restoredHP = 0
    stopsBleeding = nil
    approved = nil
    effectEvidence = nil
    occurredAt = nil
    result = nil
    boundDefinition = nil
    definition() { return [self.eventId,self.episode,self.restoredHP,self.stopsBleeding,self.approved,self.effectEvidence,self.occurredAt]; }
    assess()
    {
        if (self.eventId == nil || self.eventId == '' || self.episode == nil
            || !self.episode.ofKind(RpgExpandedClottingEpisode)) rpgExpandedReject('clotting-restoration-definition');
        self.episode.validateReceipt(); local profile = self.episode.wound.profile;
        local value = new RpgExpandedClottingRestorationResult();
        if (self.result != nil)
        {
            local current = self.definition();
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.boundDefinition[index]) rpgExpandedReject('clotting-restoration-binding');
            if (!holds(profile.clottingRestorations,self)) rpgExpandedReject('clotting-restoration-history');
            value.status = 'reused'; value.healed = self.result.healed; value.stopped = self.result.stopped; return value;
        }
        if (!self.episode.torsoImpaling) { value.reason = 'clotting-restoration-internal-required'; return value; }
        if (profile.dead) { value.reason = 'clotting-restoration-patient-dead'; return value; }
        if (!self.approved || self.effectEvidence == nil || self.effectEvidence == '' || self.occurredAt != rpgLedger.seconds)
        { value.reason = 'clotting-restoration-current-effect-required'; return value; }
        rpgInteger(self.restoredHP,0,self.episode.internalLoss);
        if (self.restoredHP == 0 && !self.stopsBleeding)
        { value.reason = 'clotting-restoration-no-effect'; return value; }
        foreach (local prior in profile.clottingRestorations)
            if (prior.eventId == self.eventId) rpgExpandedReject('clotting-restoration-duplicate-event');
        profile.clottingProtectedInjury();
        rpgInteger(self.episode.restoredInternal,0,2147483647 - self.restoredHP);
        if (self.restoredHP > profile.injury) rpgExpandedReject('clotting-restoration-injury-history');
        /* Existing healing can wake the patient or resolve a mortal condition. */
        if (self.restoredHP > 0 && (profile.unconscious || profile.mortal) && profile.ht < 3)
        { value.reason = 'clotting-restoration-healing-score-unavailable'; return value; }
        value.healed = self.restoredHP; value.stopped = self.stopsBleeding; value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local profile = self.episode.wound.profile;
        self.episode.internalLoss -= self.restoredHP; self.episode.restoredInternal += self.restoredHP;
        if (self.stopsBleeding) { self.episode.care = 'definitive'; self.episode.nextLossAt = nil; }
        local healed = self.restoredHP > 0 ? rpgLiteHeal(profile,self.restoredHP) : 0;
        if (healed != self.restoredHP) rpgExpandedReject('clotting-restoration-healing-changed');
        self.boundDefinition = self.definition(); profile.clottingRestorations = profile.clottingRestorations + [self];
        value.status = 'resolved'; self.result = value; return value;
    }
;

/** Common B223 operation lifecycle. Procedure-specific healing is separate. */
class RpgExpandedSurgicalOperationResult: RpgExpandedResult
    wound = nil
    injury = 0
    succeeded = nil
;
modify RpgExpandedProfile
    surgicalOperations = []
;
class RpgExpandedSurgicalOperation: object
    prepareRoll() { return self.assessment.assess(); }
    infectionReason() { return 'surgical-operation-infection-unimplemented'; }
    id = nil
    patient = nil
    assessment = nil
    durationSeconds = nil
    approved = nil
    procedureEvidence = nil
    dropDestination = nil
    startedAt = nil
    completesAt = nil
    completedAt = nil
    boundDefinition = nil
    result = nil
    definition()
    {
        local c = self.assessment.conditions; local skill = self.assessment.skill;
        return [self.id,self.patient,self.assessment,self.assessment.surgeon,skill,
            skill.attribute,skill.difficulty,skill.techLevel,c,self.durationSeconds,self.approved,
            self.procedureEvidence,self.dropDestination,c.techLevel,c.anesthetic,c.sterile,c.site,
            c.diagnosed,c.fieldExpedient,c.equipmentQualityModifier,c.physiologyModifier,
            c.otherMissingEquipmentModifier,c.earlyAntisepsis];
    }
    validateReceipt()
    {
        if (self.startedAt == nil) return nil;
        local current = self.definition();
        for (local index = 1; index <= current.length(); index += 1)
            if (current[index] != self.boundDefinition[index]) rpgExpandedReject('surgical-operation-binding');
        if (!holds(self.patient.surgicalOperations,self)) rpgExpandedReject('surgical-operation-history');
        return nil;
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.patient == nil || !self.patient.ofKind(RpgExpandedProfile)
            || self.assessment == nil || !self.assessment.ofKind(RpgExpandedSurgicalAssessment))
            rpgExpandedReject('surgical-operation-definition');
        local value = new RpgExpandedSurgicalOperationResult();
        self.validateReceipt();
        if (self.result != nil)
        {
            value.status = 'reused'; value.reason = self.result.reason; value.check = self.result.check;
            value.wound = self.result.wound; value.injury = self.result.injury; value.succeeded = self.result.succeeded;
            return value;
        }
        rpgInteger(self.durationSeconds,1,2147483647);
        if (!self.approved || self.procedureEvidence == nil || self.procedureEvidence == '')
        { value.reason = 'surgical-operation-authored-procedure-required'; return value; }
        if (self.patient.dead) { value.reason = 'surgical-operation-patient-dead'; return value; }
        if (self.patient.level('impaired-clotting') > 0)
        { value.reason = 'surgical-operation-clotting-failure-unimplemented'; return value; }
        if (self.patient.rules == nil || self.patient.rules.bleeding)
        { value.reason = 'surgical-operation-bleeding-classification-unimplemented'; return value; }
        local prepared = self.prepareRoll();
        if (prepared.status != 'ready') { value.reason = prepared.reason; return value; }
        if (prepared.infectionCheckRequired)
        {
            local reason = self.infectionReason();
            if (reason != nil) { value.reason = reason; return value; }
        }
        if (self.startedAt == nil)
        {
            rpgInteger(rpgLedger.seconds,0,2147483647 - self.durationSeconds);
            foreach (local prior in self.patient.surgicalOperations)
                if (prior.id == self.id) rpgExpandedReject('surgical-operation-duplicate');
            for (local prior = firstObj(RpgExpandedSurgicalOperation); prior != nil;
                prior = nextObj(prior,RpgExpandedSurgicalOperation))
                if (prior != self && prior.startedAt != nil && prior.result == nil
                    && (prior.patient == self.patient || prior.assessment.surgeon == self.assessment.surgeon))
                { value.reason = 'surgical-operation-overlap'; return value; }
        }
        /* Every possible general 3d failure is assessed before time or dice.
         * Amputation is a distinct procedure and is not represented here. */
        for (local amount = 3; amount <= 18; amount += 1)
        {
            local wound = self.failureWound(amount); local harm = wound.assess();
            if (harm.status != 'ready') { value.reason = harm.reason; return value; }
        }
        value.seconds = self.durationSeconds; value.status = 'ready'; return value;
    }
    failureWound(amount)
    {
        local wound = new RpgExpandedWound(); wound.id = 'surgery-' + self.id;
        wound.profile = self.patient; wound.amount = amount; wound.dropDestination = self.dropDestination;
        return wound;
    }
    start()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        if (self.startedAt != nil) { value.status = 'reused'; return value; }
        self.startedAt = rpgLedger.seconds; self.completesAt = self.startedAt + self.durationSeconds;
        self.boundDefinition = self.definition(); self.patient.surgicalOperations = self.patient.surgicalOperations + [self];
        value.status = 'resolved'; return value;
    }
    assessCompletion()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        if (self.startedAt == nil) { value.status = 'blocked'; value.reason = 'surgical-operation-not-started'; return value; }
        if (rpgLedger.seconds != self.completesAt)
        { value.status = 'blocked'; value.reason = 'surgical-operation-not-due'; }
        return value;
    }
    complete()
    {
        local value = self.assessCompletion(); if (value.status != 'ready') return value;
        local prepared = self.prepareRoll();
        value.check = rpgLiteCheck(self.assessment.surgeon,prepared.context); value.succeeded = value.check.achieved;
        if (!value.succeeded)
        {
            local amount = rpgRandom.die() + rpgRandom.die() + rpgRandom.die();
            value.wound = self.failureWound(amount); local harm = value.wound.apply();
            if (harm.status != 'resolved') rpgExpandedReject('surgical-operation-failure-changed');
            value.injury = harm.healthLoss;
        }
        self.completedAt = rpgLedger.seconds; value.status = 'resolved'; self.result = value; return value;
    }
    interrupt()
    {
        local value = new RpgExpandedSurgicalOperationResult();
        if (self.startedAt == nil) { value.reason = 'surgical-operation-not-started'; return value; }
        self.validateReceipt();
        if (self.result != nil) return self.assess();
        self.completedAt = rpgLedger.seconds; value.status = 'resolved'; value.reason = 'surgical-operation-interrupted';
        self.result = value; return value;
    }
;
modify rpgLedger
    validateAdvance(seconds)
    {
        inherited(seconds);
        for (local operation = firstObj(RpgExpandedSurgicalOperation); operation != nil;
            operation = nextObj(operation,RpgExpandedSurgicalOperation))
            if (operation.startedAt != nil && operation.result == nil && !operation.patient.dead)
            {
                operation.validateReceipt();
                if (self.seconds + seconds > operation.completesAt) rpgExpandedReject('surgical-operation-boundary');
            }
        return nil;
    }
;

modify RpgExpandedCripplingDuration
    surgicalRecovery = nil
;
modify RpgExpandedSurgicalOperationResult
    recoveryAt = nil
    permanent = nil
;

/** B424: two-hour repair of a lasting crippling injury. Calendar facts refer
 * to completion, not the start of the operation. No month length is invented. */
class RpgExpandedLastingRepair: RpgExpandedSurgicalOperation
    durationSeconds = 7200
    duration = nil
    remainingMonthNumerator = nil
    remainingMonthDenominator = 1
    weekSeconds = nil
    calendarEvidence = nil
    recoversAt = nil
    recoveredAt = nil
    definition()
    {
        return inherited() + [self.duration,self.remainingMonthNumerator,self.remainingMonthDenominator,
            self.weekSeconds,self.calendarEvidence];
    }
    recoverySeconds()
    {
        rpgInteger(self.remainingMonthNumerator,1,6000000);
        rpgInteger(self.remainingMonthDenominator,1,1000000);
        rpgInteger(self.weekSeconds,1,2147483647 / self.remainingMonthNumerator);
        local product = self.remainingMonthNumerator * self.weekSeconds;
        if (product % self.remainingMonthDenominator != 0)
            rpgExpandedReject('lasting-repair-fractional-second-unimplemented');
        return product / self.remainingMonthDenominator;
    }
    assess()
    {
        local value = inherited();
        if (value.status == 'reused')
        {
            value.recoveryAt = self.result.recoveryAt; value.permanent = self.result.permanent; return value;
        }
        if (value.status != 'ready') return value;
        if (self.durationSeconds != 7200 || self.duration == nil
            || !self.duration.ofKind(RpgExpandedCripplingDuration) || self.duration.wound.profile != self.patient)
            rpgExpandedReject('lasting-repair-definition');
        self.duration.assess();
        if (self.duration.result == nil || self.duration.result.duration != 'lasting'
            || self.duration.result.recovered || self.duration.surgicalRecovery != nil)
        { value.status = 'blocked'; value.reason = 'lasting-repair-not-eligible'; return value; }
        if (!self.duration.wound.bodyPart.disabled
            || self.duration.wound.bodyPart.disablingWound != self.duration.wound)
            rpgExpandedReject('lasting-repair-current-wound');
        if (self.calendarEvidence == nil || self.calendarEvidence == '')
        { value.status = 'blocked'; value.reason = 'lasting-repair-calendar-required'; return value; }
        local seconds = self.recoverySeconds();
        local remaining = self.duration.requiredMonths() - self.duration.recoveryMonths.length();
        if (self.remainingMonthNumerator > remaining * self.remainingMonthDenominator
            || self.remainingMonthNumerator <= (remaining - 1) * self.remainingMonthDenominator)
            rpgExpandedReject('lasting-repair-calendar-fraction');
        local completion = self.startedAt == nil ? rpgLedger.seconds + 7200 : self.completesAt;
        rpgInteger(completion,0,2147483647 - seconds);
        return value;
    }
    complete()
    {
        local value = inherited(); if (value.status != 'resolved' || self.completedAt != rpgLedger.seconds) return value;
        if (value.succeeded)
        {
            self.recoversAt = rpgLedger.seconds + self.recoverySeconds();
            self.duration.surgicalRecovery = self; value.recoveryAt = self.recoversAt;
        }
        else if (value.check.critical == 'failure')
        {
            self.duration.result.duration = 'permanent'; self.duration.surgicalRecovery = self;
            value.permanent = true;
        }
        return value;
    }
    assessRecovery()
    {
        local value = new RpgExpandedResult(); self.validateReceipt();
        if (self.result == nil || !self.result.succeeded || self.duration.surgicalRecovery != self)
        { value.reason = 'lasting-repair-not-successful'; return value; }
        if (self.recoveredAt != nil) { value.status = 'reused'; return value; }
        if (self.patient.dead) { value.reason = 'lasting-repair-patient-dead'; return value; }
        if (rpgLedger.seconds != self.recoversAt) { value.reason = 'lasting-repair-recovery-not-due'; return value; }
        if (self.duration.result.duration != 'lasting' || self.duration.result.recovered
            || self.duration.wound.bodyPart.disablingWound != self.duration.wound)
            rpgExpandedReject('lasting-repair-recovery-state');
        value.status = 'ready'; return value;
    }
    recover()
    {
        local value = self.assessRecovery(); if (value.status != 'ready') return value;
        local part = self.duration.wound.bodyPart;
        part.disabled = nil; part.severed = nil; part.disablingWound = nil;
        self.duration.result.recovered = true; self.recoveredAt = rpgLedger.seconds;
        value.status = 'resolved'; return value;
    }
;
modify RpgExpandedRecoveryMonth
    assess()
    {
        local value = inherited();
        if (value.status == 'ready' && self.duration.surgicalRecovery != nil)
        { value.status = 'blocked'; value.reason = 'recovery-month-surgical-schedule'; }
        return value;
    }
;
modify RpgExpandedCripplingCare
    assess()
    {
        local value = inherited();
        if (value.status == 'ready' && self.duration.surgicalRecovery != nil)
        { value.status = 'blocked'; value.reason = 'crippling-care-surgical-schedule'; }
        return value;
    }
;
modify rpgLedger
    validateAdvance(seconds)
    {
        inherited(seconds);
        for (local repair = firstObj(RpgExpandedLastingRepair); repair != nil;
            repair = nextObj(repair,RpgExpandedLastingRepair))
            if (repair.recoversAt != nil && repair.recoveredAt == nil && !repair.patient.dead)
            {
                repair.validateReceipt();
                if (self.seconds + seconds > repair.recoversAt) rpgExpandedReject('lasting-repair-recovery-boundary');
            }
        return nil;
    }
;

/** One observed mortal condition; attempts share this history across surgeons. */
class RpgExpandedMortalCare: object
    id = nil
    patient = nil
    approved = nil
    evidence = nil
    openedAt = nil
    closedAt = nil
    attempts = []
    boundDefinition = nil
    definition() { return [self.id,self.patient,self.approved,self.evidence]; }
    validateReceipt()
    {
        if (self.openedAt == nil) rpgExpandedReject('mortal-care-not-opened');
        local current = self.definition();
        for (local index = 1; index <= current.length(); index += 1)
            if (current[index] != self.boundDefinition[index]) rpgExpandedReject('mortal-care-binding');
        if (!holds(self.patient.mortalCareHistory,self)) rpgExpandedReject('mortal-care-history');
        return nil;
    }
    open()
    {
        local value = new RpgExpandedResult();
        if (self.openedAt != nil) { self.validateReceipt(); value.status = 'reused'; return value; }
        if (self.id == nil || self.id == '' || self.patient == nil || !self.patient.ofKind(RpgExpandedProfile))
            rpgExpandedReject('mortal-care-definition');
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'mortal-care-evidence'; return value; }
        if (!self.patient.mortal || self.patient.dead || self.patient.mortalCare != nil)
        { value.reason = 'mortal-care-condition'; return value; }
        foreach (local prior in self.patient.mortalCareHistory)
            if (prior.id == self.id) rpgExpandedReject('mortal-care-duplicate');
        self.openedAt = rpgLedger.seconds; self.boundDefinition = self.definition();
        self.patient.mortalCareHistory = self.patient.mortalCareHistory + [self]; self.patient.mortalCare = self;
        value.status = 'resolved'; return value;
    }
    close()
    {
        self.validateReceipt(); local value = new RpgExpandedResult();
        if (self.closedAt != nil) { value.status = 'reused'; return value; }
        if (self.patient.mortal && !self.patient.dead) { value.reason = 'mortal-care-still-active'; return value; }
        foreach (local attempt in self.attempts)
            if (attempt.result == nil) { value.reason = 'mortal-care-operation-active'; return value; }
        self.closedAt = rpgLedger.seconds;
        if (self.patient.mortalCare != self) rpgExpandedReject('mortal-care-owner');
        self.patient.mortalCare = nil; value.status = 'resolved'; return value;
    }
    failedAttempts()
    {
        self.validateReceipt(); local count = 0; local seen = [];
        foreach (local attempt in self.attempts)
        {
            if (!attempt.ofKind(RpgExpandedMortalStabilization) || attempt.care != self
                || attempt.patient != self.patient || holds(seen,attempt)) rpgExpandedReject('mortal-care-attempt-history');
            seen = seen + [attempt];
            attempt.validateReceipt();
            if (attempt.result != nil && attempt.result.check != nil && !attempt.result.check.achieved) count += 1;
        }
        return count;
    }
;
modify RpgExpandedProfile
    mortalCare = nil
    mortalCareHistory = []
;
modify RpgExpandedSurgicalOperationResult
    permanentHealthCheck = nil
    healthLost = 0
    complicationReviewRequired = nil
;
class RpgExpandedMortalStabilization: RpgExpandedSurgicalOperation
    durationSeconds = 3600
    care = nil
    definition() { return inherited() + [self.care]; }
    prepareRoll()
    {
        if (self.care == nil || !self.care.ofKind(RpgExpandedMortalCare) || self.care.patient != self.patient)
            rpgExpandedReject('mortal-stabilization-care');
        self.care.validateReceipt();
        local value = inherited(); if (value.status != 'ready') return value;
        local penalty = self.patient.hp() <= -4 * self.patient.maxHP ? -4
            : self.patient.hp() <= -3 * self.patient.maxHP ? -2 : 0;
        penalty -= 2 * self.care.failedAttempts();
        value.modifier += penalty; value.context.modifier += penalty;
        value.score = rpgLiteScore(self.assessment.surgeon,value.context);
        if (value.score == nil || value.score < 3)
        { value.status = 'blocked'; value.reason = 'mortal-stabilization-score-unavailable'; }
        return value;
    }
    assess()
    {
        local value = inherited();
        if (value.status == 'reused')
        {
            value.permanentHealthCheck = self.result.permanentHealthCheck; value.healthLost = self.result.healthLost;
            value.complicationReviewRequired = self.result.complicationReviewRequired; return value;
        }
        if (value.status != 'ready') return value;
        if (self.durationSeconds != 3600) rpgExpandedReject('mortal-stabilization-duration');
        if (!self.patient.mortal || self.patient.mortalCare != self.care || self.care.closedAt != nil)
        { value.status = 'blocked'; value.reason = 'mortal-stabilization-condition'; return value; }
        local context = new RpgLiteContext(); context.attribute = rpgHT; context.kind = 'permanent-health';
        local score = rpgLiteScore(self.patient,context);
        if (score == nil || score < 3)
        { value.status = 'blocked'; value.reason = 'mortal-stabilization-recovery-score'; return value; }
        rpgInteger(self.patient.developmentRevision,0,2147483646);
        return value;
    }
    start()
    {
        local value = inherited();
        if (value.status == 'resolved') self.care.attempts = self.care.attempts + [self];
        return value;
    }
    complete()
    {
        local value = inherited(); if (value.status != 'resolved') return value;
        if (value.succeeded)
        {
            self.patient.mortal = nil;
            local before = self.patient.ht;
            value.permanentHealthCheck = self.patient.afterMortalRecovery('surgery');
            value.healthLost = before - self.patient.ht;
            value.complicationReviewRequired = value.permanentHealthCheck.critical == 'failure';
            self.care.close();
        }
        else if (self.patient.dead) self.care.close();
        return value;
    }
;

class RpgExpandedTraumaAssessment: RpgExpandedResult
    score = nil
    interval = 0
;
class RpgExpandedTraumaCheck: object
    result = nil
    completedAt = nil
;
/** B423 ongoing trauma maintenance; no healing or extra time charge. */
class RpgExpandedTraumaMaintenance: object
    id = nil
    patient = nil
    caregiver = nil
    skill = nil
    lifeSupport = nil
    approved = nil
    equipmentEvidence = nil
    startedAt = nil
    endedAt = nil
    boundDefinition = nil
    checks = []
    definition() { return [self.id,self.patient,self.caregiver,self.skill,self.skill.techLevel,self.lifeSupport,self.approved,self.equipmentEvidence]; }
    validateReceipt()
    {
        if (self.startedAt == nil) return nil;
        local current = self.definition();
        for (local index = 1; index <= current.length(); index += 1)
            if (current[index] != self.boundDefinition[index]) rpgExpandedReject('trauma-maintenance-binding');
        if (!holds(self.patient.traumaHistory,self)) rpgExpandedReject('trauma-maintenance-history');
        return nil;
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.patient == nil || !self.patient.ofKind(RpgExpandedProfile)
            || self.caregiver == nil || !self.caregiver.ofKind(RpgLiteProfile)
            || self.skill == nil || !self.skill.ofKind(RpgLiteSkill) || self.skill.id != 'physician'
            || self.skill.techLevel == nil) rpgExpandedReject('trauma-maintenance-definition');
        self.validateReceipt(); local value = new RpgExpandedTraumaAssessment();
        if (self.endedAt != nil) { value.status = 'reused'; return value; }
        if (self.skill.techLevel < 6) { value.reason = 'trauma-maintenance-technology'; return value; }
        if (!self.approved || self.equipmentEvidence == nil || self.equipmentEvidence == '')
        { value.reason = 'trauma-maintenance-equipment'; return value; }
        if (!self.patient.mortal || self.patient.dead || self.caregiver.dead || self.caregiver.unconscious
            || self.caregiver.mortal || self.caregiver.stunned || self.caregiver.mentalStun)
        { value.reason = 'trauma-maintenance-condition'; return value; }
        if (self.startedAt == nil)
        {
            if (self.patient.traumaMaintenance != nil || self.patient.mortalClock != 0)
            { value.reason = 'trauma-maintenance-transition-boundary'; return value; }
            foreach (local prior in self.patient.traumaHistory)
                if (prior.id == self.id) rpgExpandedReject('trauma-maintenance-duplicate');
        }
        else if (self.patient.traumaMaintenance != self) rpgExpandedReject('trauma-maintenance-owner');
        local patientContext = new RpgLiteContext(); patientContext.attribute = rpgHT; patientContext.kind = 'mortal-wound';
        local physicianContext = new RpgLiteContext(); physicianContext.skill = self.skill; physicianContext.kind = 'trauma-maintenance';
        local health = rpgLiteScore(self.patient,patientContext); local physician = rpgLiteScore(self.caregiver,physicianContext);
        if (health == nil || physician == nil) { value.reason = 'trauma-maintenance-score'; return value; }
        value.score = health > physician ? health : physician;
        if (value.score < 3) { value.reason = 'trauma-maintenance-score'; return value; }
        value.interval = self.lifeSupport ? 86400 : 3600; value.status = 'ready'; return value;
    }
    start()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        if (self.startedAt != nil) { value.status = 'reused'; return value; }
        self.startedAt = rpgLedger.seconds; self.boundDefinition = self.definition();
        self.patient.traumaHistory = self.patient.traumaHistory + [self]; self.patient.traumaMaintenance = self;
        value.status = 'resolved'; return value;
    }
    end()
    {
        self.validateReceipt(); local value = new RpgExpandedResult();
        if (self.startedAt == nil) { value.reason = 'trauma-maintenance-not-started'; return value; }
        if (self.endedAt != nil) { value.status = 'reused'; return value; }
        if (self.patient.mortal && !self.patient.dead && self.patient.mortalClock != 0)
        { value.reason = 'trauma-maintenance-transition-boundary'; return value; }
        if (self.patient.traumaMaintenance != self) rpgExpandedReject('trauma-maintenance-owner');
        self.endedAt = rpgLedger.seconds; self.patient.traumaMaintenance = nil; value.status = 'resolved'; return value;
    }
    survivalCheck()
    {
        local prepared = self.assess(); if (prepared.status != 'ready') rpgExpandedReject(prepared.reason);
        local due = self.startedAt + (self.checks.length() + 1) * prepared.interval;
        if (rpgLedger.seconds - self.patient.mortalClock != due) rpgExpandedReject('trauma-maintenance-clock');
        local receipt = new RpgExpandedTraumaCheck(); receipt.result = rpgCheck(prepared.score,rpgRandom.roll());
        receipt.completedAt = rpgLedger.seconds - self.patient.mortalClock;
        self.checks = self.checks + [receipt];
        self.patient.lastCheck = receipt.result; self.patient.lastCheckDraw = rpgRandom.draws;
        return receipt.result;
    }
;
modify RpgExpandedProfile
    traumaMaintenance = nil
    traumaHistory = []
    mortalSurvivalInterval()
    {
        if (self.traumaMaintenance == nil) return inherited();
        local value = self.traumaMaintenance.assess();
        if (value.status != 'ready') rpgExpandedReject(value.reason);
        return value.interval;
    }
    mortalSurvivalCheck()
    {
        return self.traumaMaintenance == nil ? inherited() : self.traumaMaintenance.survivalCheck();
    }
;
modify rpgLedger
    validateAdvance(seconds)
    {
        inherited(seconds);
        for (local care = firstObj(RpgExpandedTraumaMaintenance); care != nil;
            care = nextObj(care,RpgExpandedTraumaMaintenance))
            if (care.startedAt != nil && care.endedAt == nil && care.patient.mortal && !care.patient.dead)
            {
                local value = care.assess(); if (value.status != 'ready') rpgExpandedReject(value.reason);
            }
        return nil;
    }
;

/* Owned medical clocks advance with the ledger; legacy rest skips this portion
 * while care owns it, preserving one survival clock per patient. */
modify RpgExpandedProfile
    mortalClockOwned() { return self.mortalCare != nil || self.traumaMaintenance != nil; }
;
modify rpgLedger
    afterAdvance(previousSeconds)
    {
        inherited(previousSeconds);
        for (local patient = firstObj(RpgExpandedProfile); patient != nil;
            patient = nextObj(patient,RpgExpandedProfile))
            if (patient.mortalClockOwned()) rpgLiteMortalTime(patient,self.seconds - previousSeconds);
        return nil;
    }
;

/** B423 mortal-survival exception for an already established suspension effect.
 * This receipt does not manufacture its technology, spell, cost or physiology. */
class RpgExpandedMortalSuspension: object
    id = nil
    patient = nil
    kind = nil
    approved = nil
    effectEvidence = nil
    startedAt = nil
    endedAt = nil
    pausedClock = nil
    boundDefinition = nil
    definition() { return [self.id,self.patient,self.kind,self.approved,self.effectEvidence]; }
    validateReceipt()
    {
        if (self.startedAt == nil || !holds(self.patient.mortalSuspensionHistory,self))
            rpgExpandedReject('mortal-suspension-history');
        local current = self.definition();
        for (local index = 1; index <= current.length(); index += 1)
            if (current[index] != self.boundDefinition[index]) rpgExpandedReject('mortal-suspension-binding');
        return nil;
    }
    assess()
    {
        local value = new RpgExpandedResult();
        if (self.id == nil || self.id == '' || self.patient == nil || !self.patient.ofKind(RpgExpandedProfile)
            || !holds(['supernatural','advanced-technology'],self.kind)) rpgExpandedReject('mortal-suspension-definition');
        if (self.startedAt != nil) { self.validateReceipt(); value.status = 'reused'; return value; }
        if (!self.approved || self.effectEvidence == nil || self.effectEvidence == '')
        { value.reason = 'mortal-suspension-effect-required'; return value; }
        if (self.patient.dead || !self.patient.mortal || !self.patient.unconscious)
        { value.reason = 'mortal-suspension-condition'; return value; }
        if (self.patient.mortalCare == nil || self.patient.traumaMaintenance != nil || self.patient.mortalSuspension != nil)
        { value.reason = 'mortal-suspension-care-transition'; return value; }
        foreach (local prior in self.patient.mortalSuspensionHistory)
            if (prior.id == self.id) rpgExpandedReject('mortal-suspension-duplicate');
        foreach (local operation in self.patient.surgicalOperations)
            if (operation.result == nil) { value.reason = 'mortal-suspension-operation-active'; return value; }
        value.status = 'ready'; return value;
    }
    start()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.startedAt = rpgLedger.seconds; self.pausedClock = self.patient.mortalClock;
        self.boundDefinition = self.definition(); self.patient.mortalSuspension = self;
        self.patient.mortalSuspensionHistory = self.patient.mortalSuspensionHistory + [self];
        value.status = 'resolved'; return value;
    }
    end()
    {
        self.validateReceipt(); local value = new RpgExpandedResult();
        if (self.endedAt != nil) { value.status = 'reused'; return value; }
        if (self.patient.mortal && !self.patient.dead && self.patient.mortalCare == nil)
        { value.reason = 'mortal-suspension-resume-care-required'; return value; }
        if (self.patient.mortalSuspension != self || self.patient.mortalClock != self.pausedClock)
            rpgExpandedReject('mortal-suspension-clock');
        self.endedAt = rpgLedger.seconds; self.patient.mortalSuspension = nil;
        value.status = 'resolved'; return value;
    }
;
modify RpgExpandedProfile
    mortalSuspension = nil
    mortalSuspensionHistory = []
    mortalClockOwned() { return self.mortalSuspension != nil || inherited(); }
    mortalSurvivalSuspended()
    {
        if (self.mortalSuspension == nil) return inherited();
        local receipt = self.mortalSuspension; receipt.validateReceipt();
        if (receipt.patient != self || receipt.endedAt != nil || self.mortalClock != receipt.pausedClock
            || !self.unconscious && !self.dead) rpgExpandedReject('mortal-suspension-state');
        return true;
    }
    unconsciousRecoveryOwned() { return self.mortalSuspension != nil || inherited(); }
;
modify RpgExpandedSurgicalOperation
    assess()
    {
        local value = inherited();
        if (value.status == 'ready' && self.patient.mortalSurvivalSuspended())
        { value.status = 'blocked'; value.reason = 'surgical-operation-suspension-active'; }
        return value;
    }
;
modify RpgExpandedTraumaMaintenance
    assess()
    {
        local value = inherited();
        if (value.status == 'ready' && self.patient.mortalSurvivalSuspended())
        { value.status = 'blocked'; value.reason = 'trauma-maintenance-suspension-active'; }
        return value;
    }
;
modify rpgLedger
    validateAdvance(seconds)
    {
        inherited(seconds);
        for (local receipt = firstObj(RpgExpandedMortalSuspension); receipt != nil;
            receipt = nextObj(receipt,RpgExpandedMortalSuspension))
            if (receipt.startedAt != nil && receipt.endedAt == nil) receipt.patient.mortalSurvivalSuspended();
        return nil;
    }
;

/** One B423 recovery consequence, owned by the recovered patient. */
class RpgExpandedMortalRecoveryReceipt: object
    patient = nil
    cause = nil
    completedAt = nil
    healthBefore = 0
    healthAfter = 0
    check = nil
    additionalConsequence = nil
    decisionEvidence = nil
    declineAdditionalConsequence(approved, evidence)
    {
        local value = new RpgExpandedResult();
        if (self.patient == nil || !holds(self.patient.mortalRecoveryHistory,self)
            || self.check == nil) rpgExpandedReject('mortal-recovery-receipt');
        if (self.check.critical != 'failure')
        { value.reason = 'mortal-recovery-no-critical-consequence'; return value; }
        if (self.additionalConsequence != nil)
        {
            if (self.additionalConsequence != 'none' || self.decisionEvidence != evidence || !approved)
                rpgExpandedReject('mortal-recovery-decision-binding');
            value.status = 'reused'; return value;
        }
        if (!approved || evidence == nil || evidence == '')
        { value.reason = 'mortal-recovery-decision-evidence'; return value; }
        self.additionalConsequence = 'none'; self.decisionEvidence = evidence;
        value.status = 'resolved'; return value;
    }
;
modify RpgExpandedProfile
    mortalRecoveryHistory = []
    validateMortalRecovery()
    {
        if (self.ht <= 1) rpgExpandedReject('mortal-recovery-minimum-health-unimplemented');
        rpgInteger(self.developmentRevision,0,2147483646); return nil;
    }
    afterMortalRecovery(cause)
    {
        if (!holds(['healing','survival','surgery'],cause) || self.mortal || self.dead)
            rpgExpandedReject('mortal-recovery-transition');
        self.validateMortalRecovery();
        local receipt = new RpgExpandedMortalRecoveryReceipt(); receipt.patient = self; receipt.cause = cause;
        receipt.completedAt = cause == 'survival' ? rpgLedger.seconds - self.mortalClock : rpgLedger.seconds;
        receipt.healthBefore = self.ht;
        receipt.check = rpgLiteAttributeCheck(self,rpgHT,'permanent-health',0);
        if (!receipt.check.achieved) { self.ht -= 1; self.developmentRevision += 1; }
        receipt.healthAfter = self.ht;
        self.mortalRecoveryHistory = self.mortalRecoveryHistory + [receipt];
        return receipt.check;
    }
;
modify rpgLedger
    validateAdvance(seconds)
    {
        inherited(seconds);
        for (local patient = firstObj(RpgExpandedProfile); patient != nil;
            patient = nextObj(patient,RpgExpandedProfile))
            if (patient.mortalClockOwned() && patient.mortal && !patient.dead && !patient.mortalSurvivalSuspended())
                patient.validateMortalRecovery();
        return nil;
    }
;

/** B162 assessment keeps the open wound separate from lost HP. Dressing and
 * exposure facts must describe the current day and surroundings. */
class RpgExpandedPersistentWoundAssessment: RpgExpandedResult
    targetModifier = 0
    woundingNumerator = 1
    woundingDenominator = 1
    bloodAgentEntry = nil
    infectionModifier = 0
;
rpgExpandedAssessPersistentWound(informedAttacker, woundReached, dressedToday, plagueRidden)
{
    local value = new RpgExpandedPersistentWoundAssessment();
    if (informedAttacker)
    { value.targetModifier = -7; value.woundingNumerator = 3; value.woundingDenominator = 2; }
    value.bloodAgentEntry = woundReached;
    value.infectionModifier = plagueRidden && !dressedToday ? -3 : 0;
    value.status = 'ready'; return value;
}

/** Explicit B423/B162 critical-recovery consequence. It grants no HP loss or
 * spendable points and cannot be applied twice to one recovery receipt. */
class RpgExpandedRecoveryWoundAcquisition: object
    recovery = nil
    trait = nil
    approved = nil
    location = nil
    evidence = nil
    result = nil
    boundDefinition = nil
    definition()
    {
        return [self.recovery,self.trait,self.approved,self.location,self.evidence,
            self.trait.id,self.trait.level,self.trait.points,self.trait.creationCost()];
    }
    assess()
    {
        local value = new RpgExpandedResult();
        if (self.recovery == nil || !self.recovery.ofKind(RpgExpandedMortalRecoveryReceipt)
            || self.recovery.patient == nil || !holds(self.recovery.patient.mortalRecoveryHistory,self.recovery))
            rpgExpandedReject('recovery-wound-receipt');
        local patient = self.recovery.patient;
        if (self.result != nil)
        {
            local current = self.definition();
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.boundDefinition[index]) rpgExpandedReject('recovery-wound-binding');
            if (self.recovery.additionalConsequence != self || !holds(patient.recoveryWoundAcquisitions,self)
                || !holds(patient.traits,self.trait)) rpgExpandedReject('recovery-wound-history');
            value.status = 'reused'; return value;
        }
        if (self.recovery.check.critical != 'failure' || self.recovery.additionalConsequence != nil)
        { value.reason = 'recovery-wound-decision-unavailable'; return value; }
        if (!patient.creationComplete || patient.dead)
        { value.reason = 'recovery-wound-character-state'; return value; }
        if (!self.approved || self.location == nil || self.location == '' || self.evidence == nil || self.evidence == '')
        { value.reason = 'recovery-wound-evidence'; return value; }
        if (self.trait == nil || !self.trait.ofKind(RpgLiteTrait) || self.trait.id != 'persistent-wound'
            || self.trait.level != 1 || self.trait.points != -5 || self.trait.creationCost() != -5
            || !self.trait.active || self.trait.mitigated) rpgExpandedReject('recovery-wound-trait');
        if (patient.trait('persistent-wound') != nil)
        { value.reason = 'recovery-wound-existing-trait'; return value; }
        for (local profile = firstObj(RpgLiteProfile); profile != nil; profile = nextObj(profile,RpgLiteProfile))
            if (holds(profile.traits,self.trait)) rpgExpandedReject('recovery-wound-trait-already-owned');
        rpgInteger(patient.developmentRevision,0,2147483646);
        value.points = -5; value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local patient = self.recovery.patient;
        patient.traits = patient.traits + [self.trait];
        patient.recoveryWoundAcquisitions = patient.recoveryWoundAcquisitions + [self];
        self.recovery.additionalConsequence = self; self.recovery.decisionEvidence = self.evidence;
        self.boundDefinition = self.definition(); patient.developmentRevision += 1;
        value.status = 'resolved'; self.result = value; return value;
    }
;
modify RpgExpandedProfile
    recoveryWoundAcquisitions = []
    postCreationDisadvantageAllowance()
    {
        local value = inherited();
        foreach (local acquisition in self.recoveryWoundAcquisitions)
        {
            if (!acquisition.ofKind(RpgExpandedRecoveryWoundAcquisition) || acquisition.recovery.patient != self
                || acquisition.assess().status != 'reused') rpgExpandedReject('recovery-wound-accounting');
            value += 5;
        }
        return value;
    }
;

class RpgExpandedPersistentDressingResult: RpgExpandedResult
    context = nil
    day = nil
    dressed = nil
;
/** B162 daily dressing; the author supplies time because the source gives no
 * fixed procedure duration. This never grants the ordinary bandaging HP. */
class RpgExpandedPersistentDressing: object
    id = nil
    patient = nil
    healer = nil
    skill = nil
    durationSeconds = nil
    approved = nil
    evidence = nil
    completedAt = nil
    boundDefinition = nil
    result = nil
    definition() { return [self.id,self.patient,self.healer,self.skill,self.skill.techLevel,self.durationSeconds,self.approved,self.evidence]; }
    prepare(day)
    {
        local value = new RpgExpandedPersistentDressingResult(); value.day = day;
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'persistent-dressing-care-required'; return value; }
        if (self.patient.dead || self.patient.level('persistent-wound') == 0
            || self.healer.dead || self.healer.unconscious || self.healer.mortal || self.healer.stunned || self.healer.mentalStun)
        { value.reason = 'persistent-dressing-condition'; return value; }
        foreach (local prior in self.patient.persistentDressings)
        {
            if (prior.id == self.id) rpgExpandedReject('persistent-dressing-duplicate');
            if (prior.result.day == day)
            { value.reason = 'persistent-dressing-repeat-unimplemented'; return value; }
        }
        value.context = new RpgLiteContext(); value.context.skill = self.skill; value.context.kind = 'persistent-dressing';
        local score = rpgLiteScore(self.healer,value.context);
        if (score == nil || score < 3) { value.reason = 'persistent-dressing-score'; return value; }
        value.seconds = self.durationSeconds; value.status = 'ready'; return value;
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.patient == nil || !self.patient.ofKind(RpgExpandedProfile)
            || self.healer == nil || !self.healer.ofKind(RpgLiteProfile) || self.skill == nil
            || !self.skill.ofKind(RpgLiteSkill) || !holds(['first-aid','physician'],self.skill.id)
            || self.skill.techLevel == nil) rpgExpandedReject('persistent-dressing-definition');
        if (self.result != nil)
        {
            local current = self.definition();
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.boundDefinition[index]) rpgExpandedReject('persistent-dressing-binding');
            if (!holds(self.patient.persistentDressings,self)) rpgExpandedReject('persistent-dressing-history');
            local value = new RpgExpandedPersistentDressingResult(); value.status = 'reused';
            value.check = self.result.check; value.day = self.result.day; value.dressed = self.result.dressed; return value;
        }
        rpgInteger(self.durationSeconds,1,86400);
        rpgInteger(rpgLedger.seconds,0,2147483647 - self.durationSeconds);
        local value = self.prepare((rpgLedger.seconds + self.durationSeconds) / 86400);
        if (value.status == 'ready') rpgLedger.validateAdvance(self.durationSeconds);
        return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local definition = self.definition(); local start = rpgLedger.seconds;
        rpgSpendTime(self.durationSeconds);
        local current = self.definition();
        for (local index = 1; index <= current.length(); index += 1)
            if (current[index] != definition[index]) rpgExpandedReject('persistent-dressing-interrupted');
        if (rpgLedger.seconds != start + self.durationSeconds) rpgExpandedReject('persistent-dressing-clock');
        value = self.prepare(rpgLedger.seconds / 86400);
        if (value.status != 'ready') rpgExpandedReject(value.reason);
        value.check = rpgLiteCheck(self.healer,value.context); value.dressed = value.check.achieved;
        self.completedAt = rpgLedger.seconds; self.boundDefinition = self.definition();
        self.patient.persistentDressings = self.patient.persistentDressings + [self];
        value.status = 'resolved'; self.result = value; return value;
    }
;
modify RpgExpandedProfile
    persistentDressings = []
    persistentWoundDressedToday()
    {
        foreach (local care in self.persistentDressings)
        {
            if (care.patient != self || care.assess().status != 'reused') rpgExpandedReject('persistent-dressing-owner');
            if (care.result.day == rpgLedger.seconds / 86400 && care.result.dressed) return true;
        }
        return nil;
    }
    persistentWoundInfectionModifier(plagueRidden)
    {
        return self.level('persistent-wound') > 0 && plagueRidden && !self.persistentWoundDressedToday() ? -3 : 0;
    }
;
