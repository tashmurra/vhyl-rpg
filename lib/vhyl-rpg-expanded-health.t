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
    assessPartInjury(count)
    {
        return rpgExpandedAssessCrippling(self.profile.maxHP,self.amount,
            holds(['arm','leg'],self.bodyPart.kind) ? 'limb' : 'extremity',count,self.severing);
    }
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
            value.crippling = self.assessPartInjury(count);
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
        if (value.crippling != nil && value.crippling.crippled)
        {
            if (holds(['leg','foot'],self.bodyPart.kind))
            { self.profile.posture = 'lying'; self.profile.onKnockdown(); }
            self.profile.onBodySupportLost(self.bodyPart);
        }
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
        if (!holds(['arm','hand','leg','foot'],self.kind)) rpgExpandedReject('body-part-kind-unavailable');
        if (self.severed && !self.disabled) rpgExpandedReject('body-part-severed-state');
        if (self.disablingWound != nil && (!self.disablingWound.ofKind(RpgExpandedWound)
            || self.disablingWound.profile != self.profile || self.disablingWound.boundBodyPart != self
            || !holds(self.profile.expandedWounds,self.disablingWound)))
            rpgExpandedReject('body-part-wound-history');
        if (holds(['arm','leg'],self.kind) && self.parent != nil) rpgExpandedReject('body-part-parent');
        if (holds(['hand','foot'],self.kind) && (self.parent == nil || !self.parent.ofKind(RpgExpandedBodyPart)
            || self.parent.kind != (self.kind == 'hand' ? 'arm' : 'leg') || self.parent.profile != self.profile
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
            if (holds(['hand','foot'],part.kind))
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
            if (!holds(['arm','hand'],part.kind)) rpgExpandedReject('equipment-lower-support-unavailable');
            seen = seen + [part];
        }
        return nil;
    }
    attackUsableBy(profile)
    {
        self.validateBodySupports(profile);
        if (!inherited(profile)) return nil;
        if (self.bodySupports.length() == 0 && profile.ofKind(RpgExpandedProfile)
            && profile.supportReserved(nil)) return nil;
        if (profile.ofKind(RpgExpandedProfile) && profile.bodyParts.length() > 0
            && holds(['punch','brass-knuckles'],self.id) && self.bodySupports.length() == 0)
            rpgExpandedReject('unarmed-hand-support-required');
        foreach (local part in self.bodySupports)
        {
            if (!part.functional() || profile.supportReserved(part)) return nil;
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
        if (self.bodySupports.length() == 0)
            return profile.ofKind(RpgExpandedProfile) && profile.supportReserved(nil) ? 0 : inherited(profile,requested);
        local arms = [];
        foreach (local part in self.bodySupports)
            if (part.functional() && !profile.supportReserved(part))
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
        if (self.bodySupports.length() == 0 && profile.ofKind(RpgExpandedProfile)
            && profile.supportReserved(nil)) return nil;
        foreach (local part in self.bodySupports)
        {
            if (part.kind != 'arm') rpgExpandedReject('shield-arm-support-required');
            if (!part.functional() || profile.supportReserved(part)) return nil;
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
        if (holds(['leg','foot'],part.kind)) return nil;
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
        if (self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)) return inherited();
        if (self.profile.bodyParts.length() == 0)
            return self.profile.supportReserved(nil) ? 0 : inherited();
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
            if (part.kind == 'arm' && part.functional() && !holds(occupied,part)
                && !self.profile.supportReserved(part)) count += 1;
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
    physiology = 'authored'
    speciesModifier = 0
    subjectSpecies = nil
    physiologyCheck = nil
    boundPhysiology = nil
    physiologyDefinition() { return [self.physiology,self.speciesModifier,self.subjectSpecies,self.physiologyCheck]; }
    assessPhysiology()
    {
        local value = new RpgExpandedResult();
        if (self.physiology == 'authored' && self.physiologyCheck == nil && self.speciesModifier == 0)
        { value.status = 'ready'; return value; }
        if (!holds(['same','similar','different','alien','machine'],self.physiology)) rpgExpandedReject('physician-physiology-category');
        if (self.physiology == 'machine') { value.reason = 'physician-physiology-machine-inapplicable'; return value; }
        rpgInteger(self.speciesModifier,-100,0);
        if (self.physiology == 'same' && self.speciesModifier != 0
            || self.physiology == 'similar' && !holds([-2,-3,-4],self.speciesModifier)
            || self.physiology == 'different' && self.speciesModifier != -5
            || self.physiology == 'alien' && self.speciesModifier > -6) rpgExpandedReject('physician-physiology-modifier');
        value.modifier = self.speciesModifier;
        if (self.physiologyCheck != nil)
        {
            local check = self.physiologyCheck;
            if (!check.ofKind(RpgExpandedPhysiologyReceipt) || check.operation != self || check.profile != self.practice.physician
                || check.subject != self.patient || self.subjectSpecies == nil || check.species != self.subjectSpecies)
                rpgExpandedReject('physician-physiology-check-binding');
            if (check.result == nil) { value.reason = 'physician-physiology-check-unresolved'; return value; }
            check.validateReceipt(); if (check.result.check.achieved) value.modifier = 0;
        }
        value.status = 'ready'; return value;
    }
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
            local facts = self.physiologyDefinition();
            for (local i = 1; i <= facts.length(); i += 1)
                if (facts[i] != self.boundPhysiology[i]) rpgExpandedReject('physician-physiology-binding');
            if (self.physiologyCheck != nil) self.physiologyCheck.validateReceipt();
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
        local physiology = self.assessPhysiology();
        if (physiology.status != 'ready') { value.reason = physiology.reason; return value; }
        value.context = new RpgLiteContext(); value.context.skill = self.practice.skill;
        value.context.kind = 'physician-care'; value.context.modifier = self.modifier + physiology.modifier;
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
        self.boundPhysiology = self.physiologyDefinition();
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
        if (patient.dead || patient.mortal || self.healer.voluntaryMovementUnavailable() || self.healer.dead || self.healer.unconscious || self.healer.stunned)
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
    equipmentAssessment = nil
    boundEquipment = nil
    boundEquipmentDefinition = nil
    modifier = 0
    physiology = 'authored'
    speciesModifier = 0
    subjectSpecies = nil
    physiologyCheck = nil
    boundPhysiology = nil
    physiologyDefinition() { return [self.physiology,self.speciesModifier,self.subjectSpecies,self.physiologyCheck]; }
    assessPhysiology()
    {
        local value = new RpgExpandedResult();
        if (self.physiology == 'authored' && self.physiologyCheck == nil && self.speciesModifier == 0)
        { value.status = 'ready'; return value; }
        if (!holds(['same','similar','different','alien','machine'],self.physiology)) rpgExpandedReject('first-aid-physiology-category');
        if (self.physiology == 'machine') { value.reason = 'first-aid-physiology-machine-inapplicable'; return value; }
        rpgInteger(self.speciesModifier,-100,0);
        if (self.physiology == 'same' && self.speciesModifier != 0
            || self.physiology == 'similar' && !holds([-2,-3,-4],self.speciesModifier)
            || self.physiology == 'different' && self.speciesModifier != -5
            || self.physiology == 'alien' && self.speciesModifier > -6) rpgExpandedReject('first-aid-physiology-modifier');
        value.modifier = self.speciesModifier;
        if (self.physiologyCheck != nil)
        {
            local check = self.physiologyCheck;
            if (!check.ofKind(RpgExpandedPhysiologyReceipt) || check.operation != self || check.profile != self.healer
                || check.subject != self.bandage.wound.profile || self.subjectSpecies == nil || check.species != self.subjectSpecies)
                rpgExpandedReject('first-aid-physiology-check-binding');
            if (check.result == nil) { value.reason = 'first-aid-physiology-check-unresolved'; return value; }
            check.validateReceipt(); if (check.result.check.achieved) value.modifier = 0;
        }
        value.status = 'ready'; return value;
    }
    unusualProblem = nil
    problemEvidence = nil
    diagnosis = nil
    diagnosisCaseId = nil
    diagnosisConsultation = nil
    boundDiagnosis = nil
    diagnosisDefinition() { return [self.unusualProblem,self.problemEvidence,self.diagnosis,self.diagnosisCaseId,self.diagnosisConsultation]; }
    diagnosisAssessment()
    {
        local value = new RpgExpandedResult();
        if (self.unusualProblem && (self.problemEvidence == nil || self.problemEvidence == ''))
        { value.reason = 'first-aid-problem-evidence'; return value; }
        if (self.diagnosis == nil)
        {
            if (self.diagnosisConsultation != nil) rpgExpandedReject('first-aid-diagnosis-consultation-binding');
            if (self.unusualProblem) { value.reason = 'first-aid-diagnosis-required'; return value; }
            value.status = 'ready'; return value;
        }
        if (!self.diagnosis.ofKind(RpgExpandedDiagnosis) || self.diagnosis.patient != self.bandage.wound.profile
            || self.diagnosisCaseId == nil || self.diagnosis.caseId != self.diagnosisCaseId)
            rpgExpandedReject('first-aid-diagnosis-case-binding');
        if (self.diagnosisConsultation != nil)
        {
            local consultation = self.diagnosisConsultation;
            if (!consultation.ofKind(RpgExpandedDiagnosticConsultation) || consultation.diagnosis != self.diagnosis
                || consultation.recipient != self.healer) rpgExpandedReject('first-aid-diagnosis-consultation-binding');
            if (consultation.completedAt == nil) { value.reason = 'first-aid-diagnosis-consultation-required'; return value; }
            consultation.validateReceipt();
        }
        else if (self.diagnosis.examiner != self.healer)
        { value.reason = 'first-aid-diagnosis-consultation-required'; return value; }
        if (self.diagnosis.result == nil) { value.reason = 'first-aid-diagnosis-unresolved'; return value; }
        self.diagnosis.validateReceipt();
        value.modifier = self.diagnosis.result.finding != nil && self.diagnosis.result.findingKind == 'diagnosis' ? 1 : 0;
        if (self.unusualProblem && value.modifier == 0)
        { value.reason = 'first-aid-diagnosis-incomplete'; return value; }
        value.status = 'ready'; return value;
    }
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
            if (self.equipmentAssessment != self.boundEquipment) rpgExpandedReject('first-aid-equipment-binding');
            if (self.equipmentAssessment != nil)
            {
                local equipmentFacts = rpgExpandedFirstAidEquipment.definition(self.equipmentAssessment);
                for (local i = 1; i <= equipmentFacts.length(); i += 1)
                    if (equipmentFacts[i] != self.boundEquipmentDefinition[i]) rpgExpandedReject('first-aid-equipment-binding');
            }
            local facts = self.physiologyDefinition();
            for (local i = 1; i <= facts.length(); i += 1)
                if (facts[i] != self.boundPhysiology[i]) rpgExpandedReject('first-aid-physiology-binding');
            if (self.physiologyCheck != nil) self.physiologyCheck.validateReceipt();
            local diagnosisFacts = self.diagnosisDefinition();
            for (local i = 1; i <= diagnosisFacts.length(); i += 1)
                if (diagnosisFacts[i] != self.boundDiagnosis[i]) rpgExpandedReject('first-aid-diagnosis-binding');
            local diagnosis = self.diagnosisAssessment();
            if (diagnosis.status != 'ready') rpgExpandedReject(diagnosis.reason);
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
        if (patient.dead || patient.mortal || self.healer.voluntaryMovementUnavailable() || self.healer.dead || self.healer.unconscious || self.healer.stunned)
        { value.reason = 'first-aid-condition'; return value; }
        if (patient.diseaseInjury > 0 || patient.temperatureInjury > 0 || patient.level('unhealing') > 0)
        { value.reason = 'first-aid-injury-eligibility-unavailable'; return value; }
        if (!self.comfortable || self.careEvidence == nil || self.careEvidence == '')
        { value.reason = 'first-aid-care-evidence'; return value; }
        if (patient.injury <= 0)
        { value.reason = 'first-aid-no-injury'; return value; }
        rpgInteger(self.modifier,-100,100);
        local diagnosis = self.diagnosisAssessment();
        if (diagnosis.status != 'ready') { value.reason = diagnosis.reason; return value; }
        local physiology = self.assessPhysiology();
        if (physiology.status != 'ready') { value.reason = physiology.reason; return value; }
        value.seconds = rpgExpandedFirstAidTable(self.skill.techLevel).tableSeconds;
        local equipment = 0;
        if (self.equipmentAssessment != nil)
        {
            local tools = rpgExpandedFirstAidEquipment.assess(self.equipmentAssessment,self.healer,self.skill);
            if (tools.status != 'ready') { value.reason = tools.reason; return value; }
            equipment = tools.modifier; value.context = self.skill.firstAidContext(tools.equipmentTL);
            local unavailable = value.context.taskUnavailableReason(self.healer);
            if (unavailable != nil) { value.reason = unavailable; return value; }
        }
        else { value.context = new RpgLiteContext(); value.context.skill = self.skill; }
        value.context.kind = 'first-aid'; value.context.modifier = self.modifier + physiology.modifier + equipment;
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
        self.boundEquipment = self.equipmentAssessment;
        if (self.equipmentAssessment != nil) self.boundEquipmentDefinition = rpgExpandedFirstAidEquipment.definition(self.equipmentAssessment);
        self.boundDiagnosis = self.diagnosisDefinition();
        self.boundPhysiology = self.physiologyDefinition();
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
    assess() { return self.assessForPhysiology(nil); }
    assessForPhysiology(physiologyOverride) { return self.assessForClinicalContext(physiologyOverride,nil); }
    assessForClinicalContext(physiologyOverride,diagnosisState)
    {
        if (self.surgeon == nil || !self.surgeon.ofKind(RpgLiteProfile)
            || self.skill == nil || !self.skill.ofKind(RpgLiteSkill)
            || self.skill.id != 'surgery' || self.skill.attribute != rpgIQ
            || self.skill.difficulty != 3 || self.skill.techLevel == nil
            || self.conditions == nil || !self.conditions.ofKind(RpgExpandedSurgeryContext))
            rpgExpandedReject('surgical-assessment-definition');
        local value = new RpgExpandedSurgeryAssessment();
        if (self.surgeon.voluntaryMovementUnavailable() || self.surgeon.dead || self.surgeon.unconscious || self.surgeon.stunned
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
        if (diagnosisState != nil) rpgInteger(diagnosisState,0,1);
        prepared.diagnosed = diagnosisState == nil ? self.conditions.diagnosed : diagnosisState == 1;
        prepared.physicianTrained = physician;
        prepared.fieldExpedient = self.conditions.fieldExpedient;
        prepared.equipmentQualityModifier = self.conditions.equipmentQualityModifier;
        prepared.physiologyModifier = physiologyOverride == nil ? self.conditions.physiologyModifier : physiologyOverride;
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
        if (self.healer.voluntaryMovementUnavailable() || self.healer.dead || self.healer.unconscious || self.healer.stunned || self.healer.mentalStun
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
    mentalAbility = nil
    requiresSpeech = nil
    requiresMovement = nil
    boundMentalAbility = nil
    boundRequiresSpeech = nil
    boundRequiresMovement = nil
    purpose = 'action'
    evidence = nil
    result = nil
    completedAt = nil
    boundId = nil
    boundProfile = nil
    boundPurpose = nil
    boundEvidence = nil
    healthPermissionReason()
    { return self.profile.healthEffortReason(self.purpose,self.mentalAbility,self.requiresSpeech,self.requiresMovement); }
    assess()
    {
        local value = new RpgExpandedEffortResult();
        if (self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)) rpgExpandedReject('effort-profile');
        if (self.result != nil)
        {
            if (self.id != self.boundId || self.profile != self.boundProfile || self.purpose != self.boundPurpose
                || self.evidence != self.boundEvidence || self.mentalAbility != self.boundMentalAbility
                || self.requiresSpeech != self.boundRequiresSpeech || self.requiresMovement != self.boundRequiresMovement
                || !holds(self.profile.effortHistory,self)) rpgExpandedReject('effort-binding');
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
        local healthReason = self.healthPermissionReason();
        if (healthReason != nil) { value.reason = healthReason; return value; }
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
        self.boundMentalAbility = self.mentalAbility; self.boundRequiresSpeech = self.requiresSpeech; self.boundRequiresMovement = self.requiresMovement;
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
        local ownedPenalty = self.profile.physicalDangerFearPenalty();
        local cowardPenalty = self.cowardicePenalty;
        if (ownedPenalty != nil)
        {
            local required = self.physicalRisk ? ownedPenalty : 0;
            if (cowardPenalty != 0 && cowardPenalty != required)
                rpgExpandedReject('fear-cowardice-purchased-rating');
            cowardPenalty = required;
        }
        else
        {
            local coward = self.profile.level('cowardice') > 0 && self.physicalRisk;
            if (coward != (cowardPenalty > 0)) rpgExpandedReject('fear-cowardice-classification');
        }
        local interested = self.profile.level('xenophilia') > 0 && self.monsters;
        if (interested != (self.xenophiliaBonus > 0)) rpgExpandedReject('fear-xenophilia-classification');
        if (self.touching && (self.remote || self.distance != 0)) rpgExpandedReject('fear-contact-distance');
        local modifier = self.profile.level('fearlessness') - self.profile.level('fearfulness');
        if (self.profile.level('combat-reflexes') > 0) modifier += 2;
        if (self.profile.level('combat-paralysis') > 0) modifier -= 2;
        modifier -= cowardPenalty; modifier += self.xenophiliaBonus;
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
        local assessment = self.context.consequenceAssessment();
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
    recoveryDecision = nil
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
            if (self.result.check != nil && self.result.check.ofKind(RpgExpandedAuthoredRecoveryResult))
            {
                if (self.recoveryDecision != self.result.check.decision) rpgExpandedReject('fear-recovery-ruling-changed');
                self.result.check.validate(self);
            }
            else if (self.recoveryDecision != nil) rpgExpandedReject('fear-recovery-ruling-added');
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
        value.reason = rpgExpandedFearRecoveryReason(self,score); if (value.reason != nil) return value;
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
        value.check = rpgExpandedFearRecoveryRoll(self,profile.attributeScore(rpgWill) + self.episode.recoveryModifier);
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
    healthManeuverReasonFor(kind,request)
    {
        if (self.retchingEpisode != nil && kind == 'concentrate') return 'retching-concentration-failure';
        return inherited(kind,request);
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
        local scene = self.context.consequenceAssessment();
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
    recoveryDecision = nil
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
            if (self.result.check != nil && self.result.check.ofKind(RpgExpandedAuthoredRecoveryResult))
            {
                if (self.recoveryDecision != self.result.check.decision) rpgExpandedReject('fear-recovery-ruling-changed');
                self.result.check.validate(self);
            }
            else if (self.recoveryDecision != nil) rpgExpandedReject('fear-recovery-ruling-added');
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
            value.reason = rpgExpandedFearRecoveryReason(self,score); if (value.reason != nil) return value;
        }
        else if (self.recoveryDecision != nil) { value.reason = 'fear-recovery-ruling-inapplicable'; return value; }
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
        value.check = self.episode.recoveryCheckRequired() ? rpgExpandedFearRecoveryRoll(self,rpgLiteScore(profile,value.context)) : nil;
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
    maximumAmount() { return 6; }
    fatigueCause() { return 'fear'; }
    history() { return self.profile.fearFatigueLosses; }
    remember() { self.profile.fearFatigueLosses = self.profile.fearFatigueLosses + [self]; }
    woundId(index)
    {
        local suffixes = ['one','two','three','four','five','six'];
        return 'fear-fatigue-' + self.id + '-' + suffixes[index];
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile))
            rpgExpandedReject('fear-fatigue-definition');
        rpgInteger(self.amount,1,self.maximumAmount()); local value = new RpgExpandedFearFatigueResult();
        if (self.result != nil)
        {
            if (self.id != self.boundId || self.profile != self.boundProfile || self.amount != self.boundAmount
                || self.dropDestination != self.boundDropDestination || !holds(self.history(),self))
                rpgExpandedReject('fear-fatigue-binding');
            value.status = 'reused'; return value;
        }
        rpgExpandedValidate(self.profile);
        if (self.profile.dead) { value.reason = 'fear-fatigue-dead'; return value; }
        rpgInteger(self.profile.maxEnergy,1,1000); rpgInteger(self.profile.fatigue,0,2 * self.profile.maxEnergy);
        foreach (local prior in self.history())
            if (prior.id == self.id) rpgExpandedReject('fear-fatigue-duplicate');
        local positive = self.profile.fp() > 0 ? self.profile.fp() : 0;
        local injury = self.amount > positive ? self.amount - positive : 0;
        for (local index = 1; index <= injury; index += 1)
        {
            local wound = new RpgExpandedWound(); wound.profile = self.profile; wound.amount = 1;
            wound.id = self.woundId(index); wound.dropDestination = self.dropDestination;
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
            value.fatigueAdded += rpgLiteFatigueIncrement(self.profile,self.fatigueCause());
            if (self.profile.fp() <= -self.profile.maxEnergy)
            {
                if (!self.profile.unconscious) self.profile.becomeUnconscious();
                self.profile.fatigueCollapse = true;
            }
        }
        self.boundId = self.id; self.boundProfile = self.profile; self.boundAmount = self.amount;
        self.boundDropDestination = self.dropDestination;
        self.remember();
        value.status = 'resolved'; self.result = value; return value;
    }
;

modify RpgExpandedProfile
    fearFatigueLosses = []
;

modify RpgExpandedProfile
    fearFaint = nil
    fearFaints = []
    unconsciousRecoveryApartFrom(owner) { return self.fearFaint != nil && self.fearFaint != owner || inherited(owner); }
;

class RpgExpandedFearFaintResult: RpgExpandedResult
    dropPlan = nil
    wound = nil
    fatigueLoss = nil
;

/** B361 rows 17-20: owned fainting, injury and fatigue. Row 20 requires an authored recovery policy. */
class RpgExpandedFearFaint: object
    id = nil
    context = nil
    approved = nil
    evidence = nil
    dropDestination = nil
    tableTotal = 17
    recoveryPolicy = nil
    onset = nil
    startedAt = nil
    nextCheckAt = nil
    completedAt = nil
    boundDefinition = nil
    recoveries = []
    definition() { return [self.id,self.context,self.context.profile,self.evidence,self.dropDestination,self.tableTotal,self.recoveryPolicy,self.approved]; }
    assess()
    {
        if (self.id == nil || self.id == '' || self.context == nil || !self.context.ofKind(RpgExpandedFearContext))
            rpgExpandedReject('fear-faint-definition');
        rpgInteger(self.tableTotal,17,20);
        if (self.tableTotal == 20 && !holds(['automatic','health-minute'],self.recoveryPolicy)
            || self.tableTotal != 20 && self.recoveryPolicy != nil) rpgExpandedReject('fear-faint-recovery-policy');
        local value = new RpgExpandedFearFaintResult();
        if (self.startedAt != nil)
        {
            local current = self.definition();
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.boundDefinition[index]) rpgExpandedReject('fear-faint-binding');
            if (!holds(self.context.profile.fearFaints,self)) rpgExpandedReject('fear-faint-history');
            value.status = 'reused'; return value;
        }
        local scene = self.context.consequenceAssessment();
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
        if (self.tableTotal == 18 || self.tableTotal == 19)
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
        if (self.tableTotal == 20)
        {
            value.fatigueLoss = new RpgExpandedFearFatigueLoss(); value.fatigueLoss.id = 'faint-' + self.id;
            value.fatigueLoss.profile = profile; value.fatigueLoss.amount = 6; value.fatigueLoss.dropDestination = self.dropDestination;
            local fatigue = value.fatigueLoss.assess();
            if (fatigue.status != 'ready') { value.reason = fatigue.reason; return value; }
        }
        rpgInteger(rpgLedger.seconds,0,2147483647 - (self.tableTotal == 20 ? 1440 : self.tableTotal == 19 ? 720 : 360));
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local minutes = rpgRandom.die(); if (self.tableTotal >= 19) minutes += rpgRandom.die();
        if (self.tableTotal == 20) { minutes += rpgRandom.die(); minutes += rpgRandom.die(); }
        if (value.fatigueLoss != nil)
        {
            value.fatigueLoss.amount = rpgRandom.die();
        }
        self.nextCheckAt = rpgLedger.seconds + 60 * minutes; self.startedAt = rpgLedger.seconds;
        self.boundDefinition = self.definition(); local profile = self.context.profile;
        if (value.dropPlan != nil) value.dropPlan.commit();
        if (value.fatigueLoss != nil && value.fatigueLoss.apply().status != 'resolved') rpgExpandedReject('fear-faint-fatigue-changed');
        profile.fearFaint = self; profile.fearFaints = profile.fearFaints + [self];
        profile.posture = 'lying'; if (!profile.dead) profile.becomeUnconscious();
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
    recoveryDecision = nil
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
            if (self.result.check != nil && self.result.check.ofKind(RpgExpandedAuthoredRecoveryResult))
            {
                if (self.recoveryDecision != self.result.check.decision) rpgExpandedReject('fear-recovery-ruling-changed');
                self.result.check.validate(self);
            }
            else if (self.recoveryDecision != nil) rpgExpandedReject('fear-recovery-ruling-added');
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
        if (self.episode.recoveryPolicy != 'automatic')
        { value.reason = rpgExpandedFearRecoveryReason(self,score); if (value.reason != nil) return value; }
        else if (self.recoveryDecision != nil) rpgExpandedReject('fear-recovery-ruling-inapplicable');
        rpgInteger(rpgLedger.seconds,0,2147483587);
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local profile = self.episode.context.profile;
        local context = new RpgLiteContext(); context.attribute = rpgHT; context.kind = 'fear-faint-recovery';
        if (self.episode.recoveryPolicy != 'automatic') value.check = rpgExpandedFearRecoveryCheck(self,profile,context);
        if (self.episode.recoveryPolicy == 'automatic' || value.check.achieved)
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
    boundTimeline = nil
    timeline()
    {
        return [self.startedAt,self.nextCheckAt,self.stoppedAt,self.clearMinutes,self.minutes.length()] + self.minutes;
    }
    validateTimeline()
    {
        local facts = self.timeline();
        if (self.boundTimeline == nil || facts.length() != self.boundTimeline.length()) rpgExpandedReject('bleeding-episode-timeline');
        for (local index = 1; index <= facts.length(); index += 1)
            if (facts[index] != self.boundTimeline[index]) rpgExpandedReject('bleeding-episode-timeline');
        local profile = self.classification.wound.profile;
        if ((self.stoppedAt == nil && !profile.dead && profile.bleedingEpisode != self)
            || (self.stoppedAt != nil && profile.bleedingEpisode == self)) rpgExpandedReject('bleeding-episode-owner');
        foreach (local minute in self.minutes)
            if (minute == nil || !minute.ofKind(RpgExpandedBleedingMinute) || minute.episode != self
                || minute.assess().status != 'reused') rpgExpandedReject('bleeding-minute-history');
        return nil;
    }
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
            self.validateTimeline();
            local current = self.definition();
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.boundDefinition[index]) rpgExpandedReject('bleeding-episode-binding');
            if (!holds(profile.bleedingHistory,self)) rpgExpandedReject('bleeding-episode-history');
            value.status = 'reused'; return value;
        }
        if (self.startedAt != nil || self.nextCheckAt != nil || self.stoppedAt != nil || self.clearMinutes != 0
            || self.minutes.length() != 0 || self.boundTimeline != nil || self.boundDefinition != nil)
            rpgExpandedReject('bleeding-episode-uncommitted');
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
        self.boundTimeline = self.timeline();
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
            if (episode.result != nil || episode.boundTimeline != nil)
            {
                episode.assess();
                if (episode.stoppedAt == nil && !episode.classification.wound.profile.dead
                    && self.seconds + seconds > episode.nextCheckAt) rpgExpandedReject('bleeding-minute-boundary');
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
    boundOutcome = nil
    outcomeDefinition()
    {
        return [self.resolvedAt,self.result,self.result.status,self.result.injury,self.result.clearMinutes,
            self.result.stopped,self.result.wound,self.result.check,self.result.check.score,self.result.check.roll,
            self.result.check.margin,self.result.check.achieved,self.result.check.critical];
    }
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
            local outcome = self.outcomeDefinition();
            if (self.boundOutcome == nil || outcome.length() != self.boundOutcome.length()) rpgExpandedReject('bleeding-minute-outcome');
            for (local index = 1; index <= outcome.length(); index += 1)
                if (outcome[index] != self.boundOutcome[index]) rpgExpandedReject('bleeding-minute-outcome');
            if (!holds(self.episode.minutes,self)) rpgExpandedReject('bleeding-minute-history');
            value.status = 'reused'; return value;
        }
        if (self.resolvedAt != nil || self.boundDefinition != nil || self.boundOutcome != nil) rpgExpandedReject('bleeding-minute-uncommitted');
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
        value.status = 'resolved'; self.result = value; self.boundOutcome = self.outcomeDefinition();
        self.episode.boundTimeline = self.episode.timeline(); return value;
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
    boundStart = nil
    boundOutcome = nil
    outcomeDefinition()
    {
        local facts = [self.completedAt,self.result,self.result.status,self.result.reason,
            self.result.stopped,self.result.healed,self.result.check];
        if (self.result.check != nil)
            facts = facts + [self.result.check.score,self.result.check.roll,self.result.check.margin,
                self.result.check.achieved,self.result.check.critical];
        return facts;
    }
    validateReceipt()
    {
        if (self.boundStart == nil || self.startedAt != self.boundStart || self.completesAt != self.boundStart + 60
            || self.startedAt > rpgLedger.seconds) rpgExpandedReject('bleeding-aid-timeline');
        if (self.result == nil)
        {
            if (self.completedAt != nil || self.boundOutcome != nil) rpgExpandedReject('bleeding-aid-uncommitted-outcome');
            return nil;
        }
        if (self.completedAt == nil || self.completedAt < self.startedAt || self.completedAt > rpgLedger.seconds)
            rpgExpandedReject('bleeding-aid-timeline');
        local facts = self.outcomeDefinition();
        if (self.boundOutcome == nil || facts.length() != self.boundOutcome.length()) rpgExpandedReject('bleeding-aid-outcome');
        for (local index = 1; index <= facts.length(); index += 1)
            if (facts[index] != self.boundOutcome[index]) rpgExpandedReject('bleeding-aid-outcome');
        return nil;
    }
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
            self.validateReceipt();
            local current = self.definition();
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.boundDefinition[index]) rpgExpandedReject('bleeding-aid-binding');
            if (!holds(self.episode.aidAttempts,self)) rpgExpandedReject('bleeding-aid-history');
            if (self.result != nil) { value.status = 'reused'; return value; }
        }
        if (self.startedAt == nil && (self.boundStart != nil || self.completesAt != nil || self.completedAt != nil
            || self.boundOutcome != nil || self.boundDefinition != nil || self.result != nil))
            rpgExpandedReject('bleeding-aid-uncommitted-state');
        if (self.episode.result == nil) { value.reason = 'bleeding-episode-not-started'; return value; }
        self.episode.assess();
        local patient = self.episode.classification.wound.profile;
        if (self.episode.stoppedAt != nil || patient.dead || patient.bleedingEpisode != self.episode)
        { value.reason = 'bleeding-episode-inactive'; return value; }
        if (self.healer.voluntaryMovementUnavailable() || self.healer.dead || self.healer.unconscious || self.healer.mortal
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
        self.startedAt = rpgLedger.seconds; self.boundStart = self.startedAt; self.completesAt = self.startedAt + 60;
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
        self.completedAt = rpgLedger.seconds; self.result = value; self.boundOutcome = self.outcomeDefinition(); return value;
    }
    complete()
    {
        local value = self.assessCompletion(); if (value.status != 'ready') return value;
        value.check = rpgLiteCheck(self.healer,value.context); value.stopped = value.check.achieved;
        if (value.stopped)
        {
            self.episode.stoppedAt = rpgLedger.seconds;
            self.episode.classification.wound.profile.bleedingEpisode = nil;
            self.episode.boundTimeline = self.episode.timeline();
        }
        self.completedAt = rpgLedger.seconds; value.status = 'resolved'; self.result = value;
        self.boundOutcome = self.outcomeDefinition();
        if (value.stopped && self.bandage != nil)
        {
            local credit = self.bandage.applyAfterBleedingCare(self);
            if (credit.status != 'resolved') rpgExpandedReject('bleeding-aid-bandage-changed');
            value.healed = credit.healed;
        }
        self.boundOutcome = self.outcomeDefinition();
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
    consequenceAssessment() { return self.assess(); }
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
        if (patient.dead || patient.mortal || self.healer.voluntaryMovementUnavailable() || self.healer.dead || self.healer.unconscious || self.healer.stunned)
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
            || self.healer.voluntaryMovementUnavailable() || self.healer.unconscious || self.healer.stunned) rpgExpandedReject('clotting-bandage-interrupted');
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
    physiology = 'authored'
    subjectSpecies = nil
    physiologyCheck = nil
    diagnosis = nil
    diagnosisCaseId = nil
    diagnosisConsultation = nil
    diagnosisAssessment()
    {
        local value = new RpgExpandedResult();
        if (self.diagnosis == nil)
        {
            if (self.diagnosisConsultation != nil) rpgExpandedReject('surgical-diagnosis-consultation-binding');
            value.status = 'ready'; return value;
        }
        if (!self.diagnosis.ofKind(RpgExpandedDiagnosis) || self.diagnosis.patient != self.patient
            || self.diagnosisCaseId == nil || self.diagnosis.caseId != self.diagnosisCaseId)
            rpgExpandedReject('surgical-diagnosis-case-binding');
        if (self.diagnosisConsultation != nil)
        {
            local consultation = self.diagnosisConsultation;
            if (!consultation.ofKind(RpgExpandedDiagnosticConsultation) || consultation.diagnosis != self.diagnosis
                || consultation.recipient != self.assessment.surgeon) rpgExpandedReject('surgical-diagnosis-consultation-binding');
            if (consultation.completedAt == nil) { value.reason = 'surgical-diagnosis-consultation-required'; return value; }
            consultation.validateReceipt();
        }
        else if (self.diagnosis.examiner != self.assessment.surgeon)
        { value.reason = 'surgical-diagnosis-consultation-required'; return value; }
        if (self.diagnosis.result == nil) { value.reason = 'surgical-diagnosis-unresolved'; return value; }
        self.diagnosis.validateReceipt();
        value.modifier = self.diagnosis.result.finding != nil && self.diagnosis.result.findingKind == 'diagnosis' ? 1 : 0;
        value.status = 'ready'; return value;
    }
    prepareRoll()
    {
        local value = new RpgExpandedSurgeryAssessment();
        local diagnosis = self.diagnosisAssessment();
        if (diagnosis.status != 'ready') { value.reason = diagnosis.reason; return value; }
        local diagnosisState = self.diagnosis == nil ? nil : diagnosis.modifier;
        if (self.physiology == 'authored' && self.physiologyCheck == nil)
            return self.assessment.assessForClinicalContext(nil,diagnosisState);
        if (!holds(['same','similar','different','alien','machine'],self.physiology))
            rpgExpandedReject('surgical-physiology-category');
        if (self.physiology == 'machine') { value.reason = 'surgical-physiology-machine-inapplicable'; return value; }
        local modifier = self.assessment.conditions.physiologyModifier;
        if (self.physiology == 'same' && modifier != 0 || self.physiology == 'similar' && !holds([-2,-3,-4],modifier)
            || self.physiology == 'different' && modifier != -5 || self.physiology == 'alien' && modifier > -6)
            rpgExpandedReject('surgical-physiology-modifier');
        if (self.physiologyCheck != nil)
        {
            local check = self.physiologyCheck;
            if (!check.ofKind(RpgExpandedPhysiologyReceipt) || check.operation != self || check.profile != self.assessment.surgeon
                || check.subject != self.patient || self.subjectSpecies == nil || check.species != self.subjectSpecies)
                rpgExpandedReject('surgical-physiology-check-binding');
            if (check.result == nil) { value.reason = 'surgical-physiology-check-unresolved'; return value; }
            check.validateReceipt(); if (check.result.check.achieved) modifier = 0;
        }
        return self.assessment.assessForClinicalContext(modifier,diagnosisState);
    }
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
            c.otherMissingEquipmentModifier,c.earlyAntisepsis,self.physiology,self.subjectSpecies,self.physiologyCheck,self.diagnosis,self.diagnosisCaseId,self.diagnosisConsultation];
    }
    validateReceipt()
    {
        if (self.startedAt == nil) return nil;
        local current = self.definition();
        for (local index = 1; index <= current.length(); index += 1)
            if (current[index] != self.boundDefinition[index]) rpgExpandedReject('surgical-operation-binding');
        if (!holds(self.patient.surgicalOperations,self)) rpgExpandedReject('surgical-operation-history');
        if (self.diagnosis != nil) self.diagnosis.validateReceipt();
        if (self.diagnosisConsultation != nil) self.diagnosisConsultation.validateReceipt();
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
        if (!self.patient.mortal || self.patient.dead || self.caregiver.voluntaryMovementUnavailable() || self.caregiver.dead || self.caregiver.unconscious
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
    unconsciousRecoveryApartFrom(owner) { return self.mortalSuspension != nil && self.mortalSuspension != owner || inherited(owner); }
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
            || self.healer.voluntaryMovementUnavailable() || self.healer.dead || self.healer.unconscious || self.healer.mortal || self.healer.stunned || self.healer.mentalStun)
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


modify RpgLiteContext
    /* B421: authors mark custom defensive reactions exempt from temporary
     * attribute penalties. Ordinary defenses have their own recognized kind. */
    defensiveReaction = nil
;

/** B428 coughing/sneezing, with an authored finite duration from its cause. */
class RpgExpandedCoughing: object
    id = nil
    profile = nil
    durationSeconds = nil
    approved = nil
    evidence = nil
    startedAt = nil
    expiresAt = nil
    boundDefinition = nil
    result = nil
    history() { return self.profile.coughingHistory; }
    remember() { self.profile.coughingHistory = self.profile.coughingHistory + [self]; }
    receiptKind() { return 'coughing'; }
    definition() { return [self.id,self.profile,self.durationSeconds,self.approved,self.evidence]; }
    validateReceipt()
    {
        if (self.result == nil || self.startedAt == nil || self.expiresAt != self.startedAt + self.durationSeconds
            || !holds(self.history(),self)) rpgExpandedReject(self.receiptKind() + '-history');
        local current = self.definition();
        for (local index = 1; index <= current.length(); index += 1)
            if (current[index] != self.boundDefinition[index]) rpgExpandedReject(self.receiptKind() + '-binding');
        return nil;
    }
    active()
    { self.validateReceipt(); return !self.profile.dead && rpgLedger.seconds >= self.startedAt && rpgLedger.seconds < self.expiresAt; }
    overlaps(prior) { return prior.active(); }
    assess()
    {
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile))
            rpgExpandedReject(self.receiptKind() + '-definition');
        local value = new RpgExpandedResult();
        if (self.result != nil) { self.validateReceipt(); value.status = 'reused'; return value; }
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = self.receiptKind() + '-cause-required'; return value; }
        if (self.profile.dead) { value.reason = self.receiptKind() + '-patient-dead'; return value; }
        rpgInteger(self.durationSeconds,1,2147483647);
        rpgInteger(rpgLedger.seconds,0,2147483647 - self.durationSeconds);
        foreach (local prior in self.history())
        {
            prior.validateReceipt();
            if (prior.id == self.id) rpgExpandedReject(self.receiptKind() + '-duplicate');
            if (self.overlaps(prior)) { value.reason = self.receiptKind() + '-overlap-unimplemented'; return value; }
        }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.startedAt = rpgLedger.seconds; self.expiresAt = self.startedAt + self.durationSeconds;
        self.boundDefinition = self.definition(); self.remember();
        value.status = 'resolved'; self.result = value; return value;
    }
;
modify RpgExpandedProfile
    coughingHistory = []
    coughing()
    {
        local active = nil;
        foreach (local episode in self.coughingHistory) if (episode.active()) active = true;
        return active;
    }
    healthCheckReason(context)
    {
        if (self.coughing() && context.skill != nil && context.skill.id == 'stealth') return 'coughing-no-stealth';
        return inherited(context);
    }
    healthAttributeModifier(context)
    {
        local value = inherited(context);
        if (!self.coughing() || context.defensiveReaction || holds(['defense','resistance','fright','fear'],context.kind)) return value;
        local attribute = context.controllingAttribute();
        if (attribute == rpgDX) value -= 3;
        else if (holds([rpgIQ,rpgPerception,rpgWill],attribute)) value -= 1;
        return value;
    }
;


/** B124 sudden loss of sight. Finite duration is supplied by its resolved cause. */
class RpgExpandedTemporaryBlindness: RpgExpandedCoughing
    history() { return self.profile.temporaryBlindnessHistory; }
    remember() { self.profile.temporaryBlindnessHistory = self.profile.temporaryBlindnessHistory + [self]; }
    receiptKind() { return 'temporary-blindness'; }
;
modify RpgLiteContext
    /* An author declares tasks that require actual vision, not merely perception. */
    requiresVision = nil
;
modify RpgExpandedProfile
    temporaryBlindnessHistory = []
    temporarilyBlind()
    {
        local active = nil;
        foreach (local episode in self.temporaryBlindnessHistory) if (episode.active()) active = true;
        return active;
    }
    healthCheckReason(context)
    {
        if (self.temporarilyBlind() && (context.kind == 'vision' || context.requiresVision)) return 'temporary-blindness-no-vision';
        return inherited(context);
    }
    validateCombatVision()
    {
        inherited();
        if (self.temporarilyBlind()) rpgExpandedReject('temporary-blindness-combat-adapter-required');
        return nil;
    }
;


/** B429 conscious paralysis. Balance is an explicit physical fact at onset. */
class RpgExpandedParalysis: RpgExpandedCoughing
    positionAssessed = nil
    balanced = nil
    history() { return self.profile.paralysisHistory; }
    remember() { self.profile.paralysisHistory = self.profile.paralysisHistory + [self]; }
    receiptKind() { return 'paralysis'; }
    definition() { return inherited() + [self.positionAssessed,self.balanced]; }
    assess()
    {
        local value = inherited();
        if (value.status == 'ready' && !self.positionAssessed)
        { value.status = 'blocked'; value.reason = 'paralysis-position-required'; }
        return value;
    }
    apply()
    {
        local value = inherited();
        if (value.status == 'resolved' && !self.balanced) self.profile.posture = 'lying';
        return value;
    }
;
modify RpgLiteContext
    mentalAbility = nil
    requiresSpeech = nil
    requiresMovement = nil
;
modify RpgExpandedProfile
    paralysisHistory = []
    paralyzed()
    {
        local active = nil;
        foreach (local episode in self.paralysisHistory) if (episode.active()) active = true;
        return active;
    }
    voluntaryMovementUnavailable() { return self.paralyzed() || inherited(); }
    healthEffortReasonFor(purpose, mentalAbility, speech, movement,authorization)
    {
        if (self.paralyzed() && !holds(['rest','do-nothing'],purpose)
            && (purpose == 'talk' || !mentalAbility || speech || movement)) return 'paralysis-action-unavailable';
        return inherited(purpose,mentalAbility,speech,movement,authorization);
    }
    healthCheckReason(context)
    {
        if (self.paralyzed())
        {
            if (context.requiresSpeech || context.requiresMovement) return 'paralysis-physical-check';
            if (!context.mentalAbility && !context.defensiveReaction
                && (context.kind == 'attack' || holds([rpgDX,rpgST],context.controllingAttribute())))
                return 'paralysis-voluntary-check';
        }
        return inherited(context);
    }
    healthManeuverReasonFor(kind,request)
    {
        if (self.paralyzed() && kind != 'nothing') return 'paralysis-do-nothing-required';
        return inherited(kind,request);
    }
    healthBlocksDefense() { return self.paralyzed() || inherited(); }
    healthDefensePenalty()
    {
        local value = inherited(); return self.paralyzed() && value < 4 ? 4 : value;
    }
;

/** B429 seizure. The resolved cause supplies duration; the end owns its FP roll. */
class RpgExpandedSeizure: RpgExpandedCoughing
    dropDestination = nil
    completedAt = nil
    recovery = nil
    history() { return self.profile.seizureHistory; }
    remember() { self.profile.seizureHistory = self.profile.seizureHistory + [self]; }
    receiptKind() { return 'seizure'; }
    definition() { return inherited() + [self.dropDestination]; }
    validateReceipt()
    {
        inherited();
        if (self.completedAt != nil && (self.completedAt != self.expiresAt || self.recovery == nil
            || self.recovery.id != self.id || self.recovery.profile != self.profile
            || self.recovery.dropDestination != self.dropDestination || self.recovery.assess().status != 'reused'))
            rpgExpandedReject('seizure-recovery-binding');
        return nil;
    }
    active()
    { self.validateReceipt(); return !self.profile.dead && self.completedAt == nil; }
    apply()
    {
        local value = inherited();
        if (value.status == 'resolved' && self.profile.posture == 'standing') self.profile.posture = 'lying';
        return value;
    }
    assessEnd()
    {
        self.validateReceipt(); local value = new RpgExpandedResult();
        if (self.completedAt != nil) { value.status = 'reused'; return value; }
        if (self.profile.dead) { value.reason = 'seizure-patient-dead'; return value; }
        if (rpgLedger.seconds != self.expiresAt) { value.reason = 'seizure-end-time'; return value; }
        local loss = new RpgExpandedSeizureFatigueLoss(); loss.id = self.id; loss.profile = self.profile;
        loss.amount = 6; loss.dropDestination = self.dropDestination;
        return loss.assess();
    }
    finish()
    {
        local value = self.assessEnd(); if (value.status != 'ready') return value;
        local loss = new RpgExpandedSeizureFatigueLoss(); loss.id = self.id; loss.profile = self.profile;
        loss.dropDestination = self.dropDestination; loss.amount = rpgRandom.die();
        value = loss.apply(); if (value.status != 'resolved') rpgExpandedReject('seizure-end-changed');
        self.recovery = loss; self.completedAt = rpgLedger.seconds; return value;
    }
;
class RpgExpandedSeizureFatigueLoss: RpgExpandedFearFatigueLoss
    fatigueCause() { return 'seizure'; }
    history() { return self.profile.seizureFatigueLosses; }
    remember() { self.profile.seizureFatigueLosses = self.profile.seizureFatigueLosses + [self]; }
    woundId(index)
    {
        local suffixes = ['one','two','three','four','five','six'];
        return 'seizure-fatigue-' + self.id + '-' + suffixes[index];
    }
;
modify RpgExpandedProfile
    seizureHistory = []
    seizureFatigueLosses = []
    seizing()
    {
        local active = nil;
        foreach (local episode in self.seizureHistory) if (episode.active()) active = true;
        return active;
    }
    voluntaryMovementUnavailable() { return self.seizing() || inherited(); }
    healthEffortReasonFor(purpose,mentalAbility,speech,movement,authorization)
    {
        if (self.seizing() && !holds(['rest','do-nothing'],purpose)) return 'seizure-action-unavailable';
        return inherited(purpose,mentalAbility,speech,movement,authorization);
    }
    healthCheckReason(context)
    {
        if (self.seizing() && context.kind != 'pain-cry' && (context.mentalAbility || context.requiresSpeech || context.requiresMovement
            || context.requiresConcentration || holds(['attack','concentrate','talk'],context.kind)
            || context.skill != nil || holds([rpgDX,rpgST,rpgIQ,rpgPerception,rpgWill],context.controllingAttribute())))
            return 'seizure-check-unavailable';
        return inherited(context);
    }
    healthManeuverReasonFor(kind,request)
    {
        if (self.seizing() && kind != 'nothing') return 'seizure-do-nothing-required';
        return inherited(kind,request);
    }
    healthBlocksDefense() { return self.seizing() || inherited(); }
;
modify rpgLedger
    validateAdvance(seconds)
    {
        inherited(seconds);
        for (local episode = firstObj(RpgExpandedSeizure); episode != nil; episode = nextObj(episode,RpgExpandedSeizure))
            if (episode.result != nil && episode.active() && self.seconds + seconds > episode.expiresAt)
                rpgExpandedReject('seizure-end-boundary');
        return nil;
    }
;

/** B428 agony: each begun minute owns a fatigue payment, including onset. */
class RpgExpandedAgony: RpgExpandedCoughing
    dropDestination = nil
    payments = []
    nextPaymentAt = nil
    history() { return self.profile.agonyHistory; }
    remember() { self.profile.agonyHistory = self.profile.agonyHistory + [self]; }
    receiptKind() { return 'agony'; }
    requiresPayments() { return true; }
    onsetLowPain = nil
    onsetHighPain = nil
    validateReceipt()
    {
        inherited(); local count = self.payments.length();
        if (self.requiresPayments() && rpgLedger.seconds < self.expiresAt && (self.profile.level('low-pain-threshold') != self.onsetLowPain
            || self.profile.level('high-pain-threshold') != self.onsetHighPain)) rpgExpandedReject('agony-pain-threshold-changed');
        if (count == 0 || count > (self.durationSeconds - 1) / 60 + 1) rpgExpandedReject('agony-payment-history');
        local expected = count == (self.durationSeconds - 1) / 60 + 1 ? self.expiresAt : self.startedAt + count * 60;
        if (self.nextPaymentAt != expected) rpgExpandedReject('agony-payment-boundary');
        foreach (local loss in self.payments)
            if (loss.profile != self.profile || loss.dropDestination != self.dropDestination || loss.assess().status != 'reused')
                rpgExpandedReject('agony-payment-binding');
        return nil;
    }
    definition()
    { return inherited() + [self.dropDestination]; }
    payment(id)
    {
        local loss = new RpgExpandedAgonyFatigueLoss(); loss.id = self.id + '-' + id;
        loss.profile = self.profile; loss.amount = self.profile.level('low-pain-threshold') > 0 ? 2 : 1;
        loss.dropDestination = self.dropDestination; return loss;
    }
    assess()
    {
        local value = inherited(); if (value.status != 'ready') return value;
        if (self.profile.level('low-pain-threshold') > 0 && self.profile.level('high-pain-threshold') > 0)
        { value.status = 'blocked'; value.reason = 'pain-threshold-conflict'; return value; }
        return self.payment('onset').assess();
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local loss = self.payment('onset'); value = loss.apply();
        if (value.status != 'resolved') rpgExpandedReject('agony-onset-changed');
        self.startedAt = rpgLedger.seconds; self.expiresAt = self.startedAt + self.durationSeconds;
        self.nextPaymentAt = self.durationSeconds > 60 ? self.startedAt + 60 : self.expiresAt;
        self.onsetLowPain = self.profile.level('low-pain-threshold'); self.onsetHighPain = self.profile.level('high-pain-threshold');
        self.payments = [loss]; self.boundDefinition = self.definition(); self.remember(); self.result = value;
        if (holds(['standing','sitting'],self.profile.posture)) self.profile.posture = 'lying';
        return value;
    }
    assessPayment(id)
    {
        self.validateReceipt();
        if (id == nil || id == '') rpgExpandedReject('agony-payment-id');
        local value = new RpgExpandedResult();
        foreach (local prior in self.payments)
            if (prior.id == self.id + '-' + id) return prior.assess();
        if (self.profile.dead || !self.requiresPayments() || rpgLedger.seconds >= self.expiresAt)
        { value.reason = 'agony-payment-inactive'; return value; }
        if (rpgLedger.seconds != self.nextPaymentAt)
        { value.reason = 'agony-payment-time'; return value; }
        return self.payment(id).assess();
    }
    pay(id)
    {
        local value = self.assessPayment(id); if (value.status != 'ready') return value;
        local loss = self.payment(id); value = loss.apply();
        if (value.status != 'resolved') rpgExpandedReject('agony-payment-changed');
        self.payments = self.payments + [loss];
        self.nextPaymentAt = self.expiresAt - self.nextPaymentAt > 60 ? self.nextPaymentAt + 60 : self.expiresAt;
        return value;
    }
    recurrenceBonus(skillId, credible, evidence)
    {
        self.validateReceipt();
        if (rpgLedger.seconds < self.expiresAt || !credible) return 0;
        if (!holds(['interrogation','intimidation'],skillId)) return 0;
        if (evidence == nil || evidence == '') rpgExpandedReject('agony-recurrence-evidence');
        return self.profile.level('low-pain-threshold') > 0 ? 6 : 3;
    }
;
class RpgExpandedAgonyFatigueLoss: RpgExpandedFearFatigueLoss
    fatigueCause() { return 'agony'; }
    history() { return self.profile.agonyFatigueLosses; }
    remember() { self.profile.agonyFatigueLosses = self.profile.agonyFatigueLosses + [self]; }
    woundId(index)
    {
        local suffixes = ['one','two']; return 'agony-fatigue-' + self.id + '-' + suffixes[index];
    }
    maximumAmount() { return 2; }
;
modify RpgExpandedProfile
    agonyHistory = []
    agonyFatigueLosses = []
    agonized()
    {
        local active = nil;
        foreach (local episode in self.agonyHistory) if (episode.active()) active = true;
        return active;
    }
    agonyIncapacitated() { return self.agonized() && self.level('high-pain-threshold') == 0; }
    voluntaryMovementUnavailable() { return self.agonyIncapacitated() || inherited(); }
    healthEffortReasonFor(purpose,mentalAbility,speech,movement,authorization)
    {
        if (self.agonyIncapacitated() && !holds(['rest','do-nothing'],purpose)) return 'agony-action-unavailable';
        return inherited(purpose,mentalAbility,speech,movement,authorization);
    }
    healthCheckReason(context)
    {
        if (self.agonyIncapacitated() && !context.defensiveReaction && !holds(['defense','pain-cry'],context.kind)
            && (context.skill != nil || context.mentalAbility || context.requiresMovement || context.requiresSpeech
                || holds([rpgST,rpgDX,rpgIQ,rpgPerception,rpgWill],context.controllingAttribute())))
            return 'agony-check-unavailable';
        return inherited(context);
    }
    healthAttributeModifier(context)
    {
        local value = inherited(context);
        if (self.agonized() && self.level('high-pain-threshold') > 0 && !context.defensiveReaction
            && !holds(['defense','resistance','fright','fear'],context.kind)
            && holds([rpgDX,rpgIQ,rpgPerception,rpgWill],context.controllingAttribute())) value -= 3;
        return value;
    }
    healthManeuverReasonFor(kind,request)
    {
        if (self.agonyIncapacitated() && kind != 'nothing') return 'agony-do-nothing-required';
        return inherited(kind,request);
    }
    healthDefensePenalty()
    { local value = inherited(); return self.agonyIncapacitated() && value < 4 ? 4 : value; }
;
modify rpgLedger
    validateAdvance(seconds)
    {
        inherited(seconds);
        for (local episode = firstObj(RpgExpandedAgony); episode != nil; episode = nextObj(episode,RpgExpandedAgony))
            if (episode.result != nil && !episode.profile.dead)
            {
                episode.validateReceipt();
                if (episode.requiresPayments() && episode.nextPaymentAt < episode.expiresAt && self.seconds + seconds > episode.nextPaymentAt)
                    rpgExpandedReject('agony-minute-boundary');
            }
        return nil;
    }
;

/** B428 recurrence threat, as a pure contribution to the shared skill score. */
class RpgExpandedAgonyThreatContext: RpgLiteContext
    episode = nil
    target = nil
    credible = nil
    threatEvidence = nil
    assessThreat(actor)
    {
        local value = new RpgExpandedResult();
        if (self.episode == nil || !self.episode.ofKind(RpgExpandedAgony)
            || self.target != self.episode.profile || actor == nil || actor == self.target)
        { value.reason = 'agony-threat-participants'; return value; }
        if (self.skill == nil || !holds(['interrogation','intimidation'],self.skill.id))
        { value.reason = 'agony-threat-skill'; return value; }
        if (self.credible && (self.threatEvidence == nil || self.threatEvidence == ''))
        { value.reason = 'agony-threat-evidence'; return value; }
        value.modifier = self.episode.recurrenceBonus(self.skill.id,self.credible,self.threatEvidence);
        value.status = 'ready'; return value;
    }
    skillUseModifier(profile)
    {
        local base = inherited(profile); if (base == nil) return nil;
        local value = self.assessThreat(profile); return value.status == 'ready' ? base + value.modifier : nil;
    }
    unavailableReason(profile)
    {
        local value = self.assessThreat(profile);
        return value.status == 'ready' ? inherited(profile) : value.reason;
    }
    validateInfluenceTarget(target)
    {
        inherited(target);
        if (target != self.target) rpgExpandedReject('agony-threat-influence-target');
        return nil;
    }
;

/** B428 irritating pain, distinct from incapacitating agony and injury shock. */
class RpgExpandedPain: RpgExpandedCoughing
    severity = 'moderate'
    history() { return self.profile.painHistory; }
    remember() { self.profile.painHistory = self.profile.painHistory + [self]; }
    receiptKind() { return 'pain'; }
    definition() { return inherited() + [self.severity]; }
    penalty()
    {
        if (!holds(['moderate','severe','terrible'],self.severity)) rpgExpandedReject('pain-severity');
        local low = self.profile.level('low-pain-threshold') > 0;
        local high = self.profile.level('high-pain-threshold') > 0;
        if (low && high) rpgExpandedReject('pain-threshold-conflict');
        local amount = self.severity == 'moderate' ? 2 : self.severity == 'severe' ? 4 : 6;
        return -(low ? amount * 2 : high ? amount / 2 : amount);
    }
    assess()
    {
        local value = inherited(); if (value.status == 'ready') self.penalty(); return value;
    }
;
modify RpgExpandedProfile
    painHistory = []
    painPenalty()
    {
        local value = 0;
        foreach (local episode in self.painHistory) if (episode.active()) value += episode.penalty();
        return value;
    }
    healthAttributeModifier(context)
    {
        local value = inherited(context);
        if (context.defensiveReaction || holds(['defense','resistance','fright','fear'],context.kind)) return value;
        if (context.skill != nil || context.kind == 'self-control'
            || holds([rpgDX,rpgIQ,rpgPerception,rpgWill],context.controllingAttribute())) value += self.painPenalty();
        return value;
    }
    healthSelfControlModifier(trait) { return inherited(trait) + self.painPenalty(); }
;

modify RpgExpandedProfile
    liftingHandsReason(hands,required)
    {
        if (self.bodyParts.length() == 0) return inherited(hands,required);
        self.validateBodyParts();
        if (hands.length() != required) return 'lifting-hand-bindings';
        local seen = [];
        foreach (local hand in hands)
        {
            if (hand == nil || !holds(self.bodyParts,hand) || hand.kind != 'hand'
                || holds(seen,hand)) return 'lifting-hand-bindings';
            if (!hand.functional()) return 'lifting-hand-disabled';
            seen = seen + [hand];
            foreach (local item in self.equipment)
                if (item.usableBy(self) && (item.ready || item.worn))
                    foreach (local support in item.bodySupports)
                        if (support == hand || support == hand.parent) return 'lifting-hand-occupied';
        }
        return nil;
    }
;

modify RpgExpandedCripplingAssessment
    additionalLimbRollRequired = nil
    allLimbsCrippled = nil
;
/** B431 exception: fall injury to limbs/extremities is never capped at crippling.
 * The extra die applies to a crippled limb; it does not add another wound. */
rpgExpandedAssessFallCrippling(capacity,injury,kind,count,limbRoll)
{
    if (!holds(['limb','extremity'],kind)) rpgExpandedReject('fall-crippling-kind');
    local value = rpgExpandedAssessCrippling(capacity,injury,kind,count,nil);
    value.healthLoss = injury;
    value.additionalLimbRollRequired = kind == 'limb' && value.crippled;
    if (limbRoll != nil)
    {
        rpgInteger(limbRoll,1,6);
        if (!value.additionalLimbRollRequired) rpgExpandedReject('fall-limb-roll-inapplicable');
        value.allLimbsCrippled = limbRoll >= 5;
    }
    return value;
}

/** Owned fall hand wound: retain full health loss and existing disability/drop hooks. */
class RpgExpandedFallExtremityWound: RpgExpandedWound
    assessPartInjury(count)
    {
        if (!holds(['hand','foot'],self.bodyPart.kind) || self.severing) rpgExpandedReject('fall-extremity-unavailable');
        return rpgExpandedAssessFallCrippling(self.profile.maxHP,self.amount,'extremity',count,nil);
    }
;

/** Secondary disability from one fall, with zero additional HP injury. */
class RpgExpandedFallSecondaryWound: RpgExpandedWound
    primary = nil
    boundPrimary = nil
    assess()
    {
        if (self.health != nil && (self.primary != self.boundPrimary
            || !holds(self.primary.additionalWounds,self))) rpgExpandedReject('fall-secondary-binding');
        return inherited();
    }
    assessPartInjury(count)
    {
        if (self.primary == nil || !self.primary.ofKind(RpgExpandedFallLimbWound)
            || self.primary.profile != self.profile || self.bodyPart.kind != self.primary.bodyPart.kind
            || self.primary.bodyPart == self.bodyPart || self.amount != 0 || self.severing)
            rpgExpandedReject('fall-secondary-definition');
        local value = rpgExpandedAssessCrippling(self.profile.maxHP,0,'limb',count,nil);
        value.crippled = true; value.healthLoss = 0; return value;
    }
    apply()
    {
        if (self.primary == nil || self.primary.health == nil || self.primary.additionalRoll < 5
            || !holds(self.primary.additionalWounds,self)) rpgExpandedReject('fall-secondary-unresolved');
        local value = inherited();
        if (value.status == 'resolved') self.boundPrimary = self.primary;
        return value;
    }
;
/** B431: uncapped arm injury plus the owned extra-limb die and disability receipts. */
class RpgExpandedFallLimbWound: RpgExpandedWound
    additionalRoll = nil
    additionalWounds = []
    assessPartInjury(count)
    {
        if (!holds(['arm','leg'],self.bodyPart.kind) || self.severing) rpgExpandedReject('fall-limb-unavailable');
        return rpgExpandedAssessFallCrippling(self.profile.maxHP,self.amount,'limb',count,nil);
    }
    secondary(part)
    {
        local wound = new RpgExpandedFallSecondaryWound(); wound.primary = self;
        wound.id = self.id + '-fall-' + part.id; wound.profile = self.profile;
        wound.bodyPart = part; wound.location = part.kind; wound.dropDestination = self.dropDestination;
        return wound;
    }
    assess()
    {
        local value = inherited();
        if (value.status != 'ready' || value.crippling == nil || !value.crippling.crippled) return value;
        foreach (local part in self.profile.bodyParts)
            if (part.kind == self.bodyPart.kind && part != self.bodyPart && part.functional())
            {
                local prepared = self.secondary(part).assess();
                if (prepared.status != 'ready') { value.status = 'blocked'; value.reason = prepared.reason; return value; }
            }
        return value;
    }
    apply()
    {
        local prepared = self.assess(); if (prepared.status != 'ready') return prepared;
        local value = inherited();
        if (value.status != 'resolved') return value;
        if (self.cripplingAssessment != nil && self.cripplingAssessment.crippled)
        {
            self.additionalRoll = rpgRandom.die();
            if (self.additionalRoll >= 5)
                foreach (local part in self.profile.bodyParts)
                    if (part.kind == self.bodyPart.kind && part != self.bodyPart && part.functional())
                    {
                        local wound = self.secondary(part);
                        self.additionalWounds = self.additionalWounds + [wound];
                        if (wound.apply().status != 'resolved') rpgExpandedReject('fall-secondary-interrupted');
                    }
        }
        return value;
    }
;

class RpgExpandedLowerLimbAssessment: RpgExpandedResult
    fallsDown = true
    legSkillPenalty = 0
    moveLimit = 0
    supportRequired = true
    supportOptions = []
    unaidedCombatPostures = []
    bracedCombatPossible = nil
;
/** B421/B141: one injured lower limb on a biped, before an authored aid assessment.
 * This does not change purchased movement or character points. */
rpgExpandedAssessLowerLimb(kind,basicSpeedHundredths)
{
    if (!holds(['foot','leg'],kind)) rpgExpandedReject('lower-limb-kind');
    rpgInteger(basicSpeedHundredths,0,100000);
    local value = new RpgExpandedLowerLimbAssessment();
    value.legSkillPenalty = kind == 'foot' ? -3 : -6;
    value.moveLimit = kind == 'foot' ? basicSpeedHundredths / 200 : 2;
    value.supportOptions = kind == 'foot' ? ['crutch','lean'] : ['crutch','peg'];
    value.unaidedCombatPostures = kind == 'foot' ? ['lying','sitting','kneeling'] : ['lying','sitting'];
    value.bracedCombatPossible = kind == 'foot';
    value.status = 'ready'; return value;
}


modify RpgExpandedProfile
    lowerLimbImpaired()
    {
        foreach (local part in self.bodyParts)
            if (holds(['leg','foot'],part.kind) && !part.functional()) return true;
        return nil;
    }
    postureChangeReason(posture)
    {
        if (!self.lowerLimbImpaired()) return inherited(posture);
        if (posture == 'standing' && self.mobilitySupport != nil && self.mobilitySupport.assess().status == 'ready')
            return inherited(posture);
        if (holds(['standing','crouching','crawling'],posture)) return 'lower-limb-support-required';
        if (posture == 'kneeling')
            foreach (local part in self.bodyParts)
                if (part.kind == 'leg' && !part.functional()) return 'lower-limb-posture-unavailable';
        return inherited(posture);
    }
    move()
    {
        if (!self.dead && !self.unconscious && self.lowerLimbImpaired()
            && (self.mobilitySupport == nil || self.mobilitySupport.assess().status != 'ready'))
            rpgExpandedReject('lower-limb-movement-adapter-required');
        return inherited();
    }
;

modify RpgLiteSkill
    usesLegs = nil
;
modify RpgExpandedProfile
    legUsePenalty()
    {
        local legs = 0; local impairedLeg = nil; local impairedFoot = nil;
        foreach (local part in self.bodyParts)
        {
            if (part.kind == 'leg')
            { legs += 1; if (!part.functional()) impairedLeg = true; }
            if (part.kind == 'foot' && !part.functional()) impairedFoot = true;
        }
        if (!impairedLeg && !impairedFoot) return inherited();
        if (legs != 2) rpgExpandedReject('lower-limb-anatomy-adapter-required');
        return impairedLeg ? -6 : -3;
    }
;
modify RpgLiteContext
    limbUseModifier(profile)
    {
        if (!holds(['auto','required','none'],self.legUse)) rpgExpandedReject('leg-use-context');
        local applies = self.legUse == 'required' || self.legUse == 'auto'
            && self.skill != nil && self.skill.ofKind(RpgLiteSkill) && self.skill.usesLegs;
        return inherited(profile) + (applies ? profile.legUsePenalty() : 0);
    }
;

modify RpgExpandedProfile
    mobilitySupport = nil
    groundMoveBase()
    {
        local base = inherited();
        if (!self.lowerLimbImpaired()) return base;
        if (self.mobilitySupport == nil || self.mobilitySupport.assess().status != 'ready')
            rpgExpandedReject('lower-limb-movement-adapter-required');
        local limit = self.mobilitySupport.moveLimit();
        return base < limit ? base : limit;
    }
;
/** B141 fitted peg, one impaired leg on a biped. Fitting/terrain are author facts. */
class RpgExpandedPegSupport: object
    lossEvents = []
    settledLossCount = 0
    pendingLoss() { return self.lossEvents.length() > self.settledLossCount; }
    noteLoss(cause)
    {
        if (self.profile == nil || self.profile.mobilitySupport != self) return nil;
        for (local index = self.settledLossCount + 1; index <= self.lossEvents.length(); index += 1)
            if (self.lossEvents[index][1] == cause) return nil;
        self.lossEvents = self.lossEvents + [[cause,rpgLedger.seconds]]; return nil;
    }
    moveLimit() { return 2; }
    profile = nil
    leg = nil
    item = nil
    fitted = nil
    terrainSuitable = nil
    approved = nil
    evidence = nil
    boundDefinition = nil
    definition() { return [self.profile,self.leg,self.item,self.fitted,self.approved,self.evidence]; }
    assess()
    {
        if (self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)
            || self.leg == nil || !self.leg.ofKind(RpgExpandedBodyPart) || self.leg.kind != 'leg'
            || self.leg.profile != self.profile || self.item == nil || !self.item.ofKind(RpgLiteItem))
            rpgExpandedReject('peg-support-definition');
        if (self.boundDefinition != nil)
        {
            local current = self.definition();
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.boundDefinition[index]) rpgExpandedReject('peg-support-binding');
        }
        local value = new RpgExpandedResult();
        if (self.pendingLoss()) { value.reason = 'mobility-support-unsettled'; return value; }
        if (!self.approved || !self.fitted || self.evidence == nil || self.evidence == '' || !self.terrainSuitable)
        { value.reason = 'peg-support-author-facts'; return value; }
        self.profile.validateBodyParts();
        local legs = 0; local impaired = 0;
        foreach (local part in self.profile.bodyParts)
        {
            if (part.kind == 'leg') { legs += 1; if (!part.functional()) impaired += 1; }
            if (part.kind == 'foot' && part.parent != self.leg && !part.functional())
            { value.reason = 'peg-support-other-foot'; return value; }
        }
        if (legs != 2 || impaired != 1 || self.leg.functional())
        { value.reason = 'peg-support-anatomy'; return value; }
        if (!holds(self.profile.equipment,self.item) || !self.item.worn || !self.item.usableBy(self.profile))
        { value.reason = 'peg-support-item-unavailable'; return value; }
        value.status = 'ready'; return value;
    }
    activate()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        if (self.profile.mobilitySupport != nil && self.profile.mobilitySupport != self)
            rpgExpandedReject('peg-support-already-active');
        value.status = self.profile.mobilitySupport == self ? 'reused' : 'resolved';
        self.boundDefinition = self.definition(); self.profile.mobilitySupport = self; return value;
    }
    deactivate()
    {
        if (self.pendingLoss()) rpgExpandedReject('mobility-support-settlement-required');
        if (self.profile != nil && self.profile.mobilitySupport == self && self.profile.lowerLimbImpaired()
            && holds(['standing','crouching'],self.profile.posture)) rpgExpandedReject('mobility-support-settlement-required');
        if (self.profile != nil && self.profile.mobilitySupport == self) self.profile.mobilitySupport = nil;
        return nil;
    }
;

/** Already fitted/readied crutch arrangement; authored hands define its support. */
class RpgExpandedCrutchSupport: RpgExpandedPegSupport
    part = nil
    hands = []
    definition()
    { return [self.profile,self.part,self.item,self.fitted,self.approved,self.evidence,self.hands.length()] + self.hands; }
    moveLimit() { return self.part.kind == 'foot' ? self.profile.basicSpeedQuarters() / 8 : 2; }
    assess()
    {
        if (self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)
            || self.part == nil || !self.part.ofKind(RpgExpandedBodyPart) || self.part.profile != self.profile
            || !holds(['leg','foot'],self.part.kind) || self.item == nil || !self.item.ofKind(RpgLiteItem))
            rpgExpandedReject('crutch-support-definition');
        if (self.boundDefinition != nil)
        {
            local current = self.definition();
            if (current.length() != self.boundDefinition.length()) rpgExpandedReject('crutch-support-binding');
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.boundDefinition[index]) rpgExpandedReject('crutch-support-binding');
        }
        local value = new RpgExpandedResult();
        if (self.pendingLoss()) { value.reason = 'mobility-support-unsettled'; return value; }
        if (!self.approved || !self.fitted || !self.terrainSuitable || self.evidence == nil || self.evidence == '')
        { value.reason = 'crutch-support-author-facts'; return value; }
        self.profile.validateBodyParts();
        local legs = 0; local badLegs = 0;
        foreach (local candidate in self.profile.bodyParts)
        {
            if (candidate.kind == 'leg') { legs += 1; if (!candidate.functional()) badLegs += 1; }
            if (candidate.kind == 'foot' && candidate != self.part && candidate.parent != self.part && !candidate.functional())
            { value.reason = 'crutch-support-other-foot'; return value; }
        }
        if (legs != 2 || self.part.functional() || badLegs != (self.part.kind == 'leg' ? 1 : 0))
        { value.reason = 'crutch-support-anatomy'; return value; }
        if (!holds(self.profile.equipment,self.item) || !self.item.ready || self.item.worn || !self.item.usableBy(self.profile))
        { value.reason = 'crutch-support-item-unavailable'; return value; }
        rpgInteger(self.hands.length(),1,2);
        if (self.item.bodySupports.length() != self.hands.length()) rpgExpandedReject('crutch-support-grips');
        local seen = [];
        foreach (local hand in self.hands)
        {
            if (hand == nil || !hand.ofKind(RpgExpandedBodyPart) || hand.profile != self.profile
                || hand.kind != 'hand' || holds(seen,hand) || !holds(self.item.bodySupports,hand))
                rpgExpandedReject('crutch-support-hand');
            seen = seen + [hand];
            if (!hand.functional()) { value.reason = 'crutch-support-hand-disabled'; return value; }
            if (self.profile.mobilitySupport != self && self.profile.supportReserved(hand))
            { value.reason = 'crutch-support-hand-reserved'; return value; }
            foreach (local gear in self.profile.equipment)
                if (gear != self.item && gear.ready && !gear.worn && gear.usableBy(self.profile))
                {
                    if (gear.bodySupports.length() == 0) { value.reason = 'crutch-support-hand-unmapped'; return value; }
                    foreach (local support in gear.bodySupports)
                        if (support == hand || support == hand.parent)
                        { value.reason = 'crutch-support-hand-occupied'; return value; }
                }
        }
        value.status = 'ready'; return value;
    }
;
modify RpgExpandedProfile
    supportReserved(part)
    {
        if (self.mobilitySupport != nil && self.mobilitySupport.ofKind(RpgExpandedCrutchSupport))
            foreach (local hand in self.mobilitySupport.hands)
                if (part == nil || part == hand || part == hand.parent || part.parent == hand.parent) return true;
        return inherited(part);
    }
;

modify RpgExpandedProfile
    mobilitySettlements = []
;
/** Authored physical settlement of unavailable or deliberately withdrawn support. */
class RpgExpandedMobilitySettlement: object
    support = nil
    cause = 'unavailable'
    evidence = nil
    impactResolved = nil
    impactEvidence = nil
    completedAt = nil
    boundDefinition = nil
    definition() { return [self.support,self.cause,self.evidence,self.impactResolved,self.impactEvidence]; }
    assess()
    {
        if (self.support == nil || !self.support.ofKind(RpgExpandedPegSupport)
            || self.support.profile == nil) rpgExpandedReject('mobility-settlement-definition');
        local value = new RpgExpandedResult();
        if (self.completedAt != nil)
        {
            local current = self.definition();
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.boundDefinition[index]) rpgExpandedReject('mobility-settlement-binding');
            if (!holds(self.support.profile.mobilitySettlements,self)) rpgExpandedReject('mobility-settlement-history');
            value.status = 'reused'; return value;
        }
        if (self.support.profile.mobilitySupport != self.support)
        { value.reason = 'mobility-settlement-inactive'; return value; }
        if (!holds(['unavailable','withdrawn'],self.cause)) rpgExpandedReject('mobility-settlement-cause');
        if (self.evidence == nil || self.evidence == '' || !self.impactResolved
            || self.impactEvidence == nil || self.impactEvidence == '')
        { value.reason = 'mobility-settlement-impact-unresolved'; return value; }
        if (self.cause == 'unavailable' && self.support.assess().status == 'ready')
        { value.reason = 'mobility-settlement-still-supported'; return value; }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local profile = self.support.profile;
        self.boundDefinition = self.definition(); self.completedAt = rpgLedger.seconds;
        self.support.settledLossCount = self.support.lossEvents.length();
        profile.mobilitySupport = nil; profile.posture = 'lying';
        profile.mobilitySettlements = profile.mobilitySettlements + [self];
        profile.onKnockdown(); value.status = 'resolved'; return value;
    }
;
modify rpgLedger
    validateAdvance(seconds)
    {
        inherited(seconds);
        if (seconds > 0)
            for (local profile = firstObj(RpgExpandedProfile); profile != nil; profile = nextObj(profile,RpgExpandedProfile))
                if (profile.mobilitySupport != nil && (profile.mobilitySupport.pendingLoss()
                    || profile.lowerLimbImpaired() && holds(['standing','crouching'],profile.posture)
                        && profile.mobilitySupport.assess().status != 'ready'))
                    rpgExpandedReject('mobility-support-settlement-required');
        return nil;
    }
;


modify RpgExpandedProfile
    onEquipmentUnavailable(item, cause)
    {
        inherited(item,cause);
        if (self.mobilitySupport != nil && self.mobilitySupport.item == item)
            self.mobilitySupport.noteLoss(cause);
        return nil;
    }
    onEquipmentDropped(item)
    {
        inherited(item);
        if (self.mobilitySupport != nil && self.mobilitySupport.item == item)
            self.mobilitySupport.noteLoss('aid-dropped');
        return nil;
    }
    onBodySupportLost(part)
    {
        inherited(part);
        if (self.mobilitySupport != nil && self.mobilitySupport.ofKind(RpgExpandedCrutchSupport))
            foreach (local hand in self.mobilitySupport.hands)
                if (part == hand || part == hand.parent) self.mobilitySupport.noteLoss('support-hand-disabled');
        return nil;
    }
;

/** B426 hourly marching fatigue, including the hot-weather clothing exception.
 * The caller establishes weather and effective cooling as world facts. */
rpgExpandedMarchFatigueCost(encumbrance, hot, heavyClothing, cooling)
{
    rpgInteger(encumbrance,0,4);
    return 1 + encumbrance + (hot && !cooling ? (heavyClothing ? 2 : 1) : 0);
}
class RpgExpandedMarchFatigueLoss: RpgExpandedFearFatigueLoss
    maximumAmount() { return 7; }
    fatigueCause() { return 'exertion'; }
    history() { return self.profile.marchFatigueLosses; }
    remember() { self.profile.marchFatigueLosses = self.profile.marchFatigueLosses + [self]; }
    woundId(index)
    {
        return 'march-fatigue-' + self.id + '-' + ['one','two','three','four','five','six','seven'][index];
    }
;
class RpgExpandedMarchHourResult: RpgExpandedResult
    fatigueCost = 0
    fatigueLoss = nil
;
modify RpgExpandedProfile
    marchHours = []
    marchFatigueLosses = []
;
/** One completed marching hour or the B426 assumed hour at a combat interruption.
 * Time belongs to the journey. Reuse the same interval object for both pathways;
 * an already charged interval cannot acquire a second cost under another ID. */
class RpgExpandedMarchHourCost: object
    id = nil
    profile = nil
    interval = nil
    basis = 'completed-hour'
    hot = nil
    heavyClothing = nil
    cooling = nil
    approved = nil
    evidence = nil
    dropDestination = nil
    result = nil
    boundDefinition = nil
    definition()
    { return [self.id,self.profile,self.interval,self.basis,self.hot,self.heavyClothing,self.cooling,
        self.approved,self.evidence,self.dropDestination]; }
    assess()
    {
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)
            || self.interval == nil || dataType(self.interval) != TypeObject)
            rpgExpandedReject('march-hour-definition');
        local value = new RpgExpandedMarchHourResult();
        if (self.result != nil)
        {
            local current = self.definition();
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.boundDefinition[index]) rpgExpandedReject('march-hour-binding');
            if (!holds(self.profile.marchHours,self) || self.result.fatigueLoss.assess().status != 'reused')
                rpgExpandedReject('march-hour-history');
            value.status = 'reused'; return value;
        }
        if (!holds(['completed-hour','combat-assumed-hour'],self.basis)) rpgExpandedReject('march-hour-basis');
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'march-hour-author-facts'; return value; }
        foreach (local prior in self.profile.marchHours)
            if (prior.id == self.id || prior.interval == self.interval) rpgExpandedReject('march-hour-already-charged');
        value.fatigueCost = rpgExpandedMarchFatigueCost(self.profile.encumbrance(),self.hot,self.heavyClothing,self.cooling);
        local loss = new RpgExpandedMarchFatigueLoss(); loss.id = self.id; loss.profile = self.profile;
        loss.amount = value.fatigueCost; loss.dropDestination = self.dropDestination;
        local prepared = loss.assess();
        if (prepared.status != 'ready') { value.reason = prepared.reason; return value; }
        value.fatigueLoss = loss; value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status == 'reused') return self.result;
        if (value.status != 'ready') return value;
        if (value.fatigueLoss.apply().status != 'resolved') rpgExpandedReject('march-hour-fatigue-changed');
        self.boundDefinition = self.definition(); self.result = value;
        self.profile.marchHours = self.profile.marchHours + [self];
        value.status = 'resolved'; return value;
    }
;

class RpgExpandedMarchExecutionResult: RpgExpandedResult
    gate = nil
    cost = nil
    allowed = nil
;
modify RpgExpandedProfile
    marchExecutions = []
;
/** A continuous, fixed-condition marching hour. No distance is inferred from
 * hourly time: B351 daily mileage includes preparation and rest. */
class RpgExpandedMarchHour: RpgExpandedMarchHourCost
    startedAt = nil
    completedAt = nil
    assess()
    {
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)
            || self.interval == nil || dataType(self.interval) != TypeObject || self.basis != 'completed-hour')
            rpgExpandedReject('march-execution-definition');
        local value = new RpgExpandedMarchExecutionResult();
        if (self.result != nil)
        {
            local current = self.definition();
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.boundDefinition[index]) rpgExpandedReject('march-execution-binding');
            if (!holds(self.profile.marchExecutions,self) || self.result.gate.assess().status != 'reused'
                || self.completedAt != self.startedAt + self.result.seconds)
                rpgExpandedReject('march-execution-history');
            if (self.result.allowed && self.result.cost.assess().status != 'reused')
                rpgExpandedReject('march-execution-cost-history');
            value.status = 'reused'; return value;
        }
        value.reason = self.profile.travelScheduleReason(rpgLedger.seconds,3600);
        if (value.reason != nil) return value;
        foreach (local prior in self.profile.marchExecutions)
            if (prior.id == self.id || prior.interval == self.interval) rpgExpandedReject('march-execution-duplicate');
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'march-hour-author-facts'; return value; }
        if (self.profile.hp() <= 0)
        { value.reason = 'march-continuous-consciousness-required'; return value; }
        if (self.profile.move() <= 0) { value.reason = 'march-movement-unavailable'; return value; }
        local cost = new RpgExpandedMarchHourCost(); cost.id = self.id; cost.profile = self.profile;
        cost.interval = self.interval; cost.hot = self.hot; cost.heavyClothing = self.heavyClothing; cost.cooling = self.cooling;
        cost.approved = self.approved; cost.evidence = self.evidence; cost.dropDestination = self.dropDestination;
        local prepared = cost.assess();
        if (prepared.status != 'ready') { value.reason = prepared.reason; return value; }
        local gate = new RpgExpandedActionGate(); gate.id = 'march-' + self.id; gate.profile = self.profile;
        gate.requiresMovement = true; gate.evidence = self.evidence;
        local permission = gate.assess();
        if (permission.status != 'ready') { value.reason = permission.reason; return value; }
        rpgInteger(rpgLedger.seconds,0,2147480047); rpgLedger.validateAdvance(3600);
        value.gate = gate; value.cost = cost; value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status == 'reused') return self.result;
        if (value.status != 'ready') return value;
        local definition = self.definition(); local start = rpgLedger.seconds;
        local permission = value.gate.apply();
        if (permission.status != 'resolved') rpgExpandedReject('march-permission-changed');
        value.allowed = permission.allowed; value.reason = permission.reason;
        if (value.allowed)
        {
            local before = value.cost.assess(); local movement = self.profile.move();
            local hp = self.profile.hp(); local fp = self.profile.fp();
            if (before.status != 'ready') rpgExpandedReject('march-cost-changed');
            self.profile.restClock = 0; rpgSpendTime(3600);
            local current = self.definition();
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != definition[index]) rpgExpandedReject('march-hour-interrupted');
            local after = value.cost.assess();
            if (rpgLedger.seconds != start + 3600 || after.status != 'ready' || before.fatigueCost != after.fatigueCost
                || self.profile.move() != movement || self.profile.hp() != hp || self.profile.fp() != fp
                || self.profile.hp() <= 0 || self.profile.unconscious
                || self.profile.dead || self.profile.stunned || self.profile.mentalStun
                || self.profile.healthEffortReason('action',nil,nil,true) != nil)
                rpgExpandedReject('march-hour-conditions-changed');
            if (value.cost.apply().status != 'resolved') rpgExpandedReject('march-hour-cost-unresolved');
            value.seconds = 3600;
        }
        self.startedAt = start; self.completedAt = rpgLedger.seconds; self.boundDefinition = definition;
        self.result = value; self.profile.marchExecutions = self.profile.marchExecutions + [self];
        value.status = 'resolved'; return value;
    }
;

/** A throwing grip must name actual usable hands. The thrown item itself is
 * exempt from the occupied-hand check; other ready gear and reservations are not. */
modify RpgLiteItem
    throwingHandsReason(profile, required)
    {
        self.validateBodySupports(profile);
        if (self.bodySupports.length() < required || self.bodySupports.length() > 2)
            return 'throwing-hand-bindings';
        foreach (local hand in self.bodySupports)
        {
            if (hand.kind != 'hand') return 'throwing-hand-bindings';
            if (!hand.functional()) return 'throwing-hand-disabled';
            if (profile.supportReserved(hand)) return 'throwing-hand-reserved';
            foreach (local other in profile.equipment)
                if (other != self && other.usableBy(profile) && (other.ready || other.worn))
                {
                    other.validateBodySupports(profile);
                    if (other.ready && !other.worn && other.bodySupports.length() == 0)
                        return 'throwing-other-grip-unmapped';
                    foreach (local support in other.bodySupports)
                        if (support == hand || support == hand.parent) return 'throwing-hand-occupied';
                }
        }
        return nil;
    }
;

modify RpgExpandedProfile
    prepareThrowGate(id,evidence)
    {
        local gate = new RpgExpandedActionGate(); gate.id = 'throw-' + id; gate.profile = self;
        gate.requiresMovement = true; gate.evidence = evidence; return gate;
    }
;

class RpgExpandedThrownProtection: RpgExpandedResult
    penetratingDamage = 0
    bluntInjury = 0
    healthLoss = 0
;
/** B379 ordinary torso protection: one outer non-flexible layer followed by
 * flexible DR. This does not approximate other layer orderings or anatomy. */
rpgExpandedAssessThrownProtection(damage, damageType, outerDR, flexibleDR)
{
    rpgInteger(damage,0,100000); rpgInteger(outerDR,0,100000); rpgInteger(flexibleDR,0,100000);
    if (!holds(['cr','cut','pi','imp'],damageType)) rpgExpandedReject('thrown-protection-damage-type');
    local value = new RpgExpandedThrownProtection();
    local remaining = damage > outerDR ? damage - outerDR : 0;
    value.penetratingDamage = remaining > flexibleDR ? remaining - flexibleDR : 0;
    if (value.penetratingDamage == 0 && flexibleDR > 0)
        value.bluntInjury = remaining / (damageType == 'cr' ? 5 : 10);
    local multiplier = damageType == 'cut' ? 3 : damageType == 'imp' ? 4 : 2;
    value.healthLoss = value.penetratingDamage * multiplier / 2 + value.bluntInjury;
    value.status = 'ready'; return value;
}
class RpgExpandedThrownInjuryResult: RpgExpandedResult
    protection = nil
    wound = nil
;
modify RpgExpandedProfile
    thrownInjuries = []
;
/** Apply one side of a bound damage receipt to its actual character target.
 * Armour facts must describe the stated layer ordering and ordinary torso. */
class RpgExpandedThrownInjury: object
    id = nil
    receipt = nil
    side = 'target'
    outerDR = 0
    flexibleDR = 0
    location = 'torso'
    approved = nil
    evidence = nil
    dropDestination = nil
    result = nil
    boundDefinition = nil
    definition()
    { return [self.id,self.receipt,self.side,self.outerDR,self.flexibleDR,self.location,self.approved,self.evidence,self.dropDestination]; }
    assess()
    {
        if (self.id == nil || self.id == '' || self.receipt == nil || !self.receipt.ofKind(RpgExpandedThrownDamageReceipt))
            rpgExpandedReject('thrown-injury-definition');
        local value = new RpgExpandedThrownInjuryResult(); local facts = self.receipt.injuryAssessment(self.side);
        if (facts.status != 'ready') { value.reason = facts.reason; return value; }
        if (self.result != nil)
        {
            local current = self.definition();
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.boundDefinition[index]) rpgExpandedReject('thrown-injury-binding');
            if (!holds(facts.profile.thrownInjuries,self) || self.result.wound.assess().status != 'reused')
                rpgExpandedReject('thrown-injury-history');
            value.status = 'reused'; return value;
        }
        foreach (local prior in facts.profile.thrownInjuries)
            if (prior.id == self.id || prior.receipt == self.receipt && prior.side == self.side)
                rpgExpandedReject('thrown-injury-duplicate');
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'thrown-injury-protection-facts'; return value; }
        if (!holds(['torso','arm','hand','leg','foot'],self.location))
        { value.reason = 'thrown-injury-location-adapter-required'; return value; }
        if (self.location != facts.location) rpgExpandedReject('thrown-injury-location-mismatch');
        if (self.location != 'torso')
        {
            value.reason = facts.profile.throwLocationReason(facts.bodyPart,self.location);
            if (value.reason != nil) return value;
        }
        value.protection = rpgExpandedAssessThrownProtection(facts.damage,facts.damageType,self.outerDR,self.flexibleDR);
        if (self.location != 'torso' && facts.damageType == 'imp')
            value.protection.healthLoss = value.protection.penetratingDamage + value.protection.bluntInjury;
        value.wound = new RpgExpandedWound(); value.wound.id = 'thrown-' + self.id + '-' + self.side;
        value.wound.location = self.location; value.wound.bodyPart = facts.bodyPart;
        value.wound.severing = self.location != 'torso' && facts.damageType == 'cut';
        value.wound.profile = facts.profile; value.wound.amount = value.protection.healthLoss;
        value.wound.dropDestination = self.dropDestination;
        local prepared = value.wound.assess();
        if (prepared.status != 'ready') { value.reason = prepared.reason; return value; }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status == 'reused') return self.result;
        if (value.status != 'ready') return value;
        if (value.wound.apply().status != 'resolved') rpgExpandedReject('thrown-injury-wound-changed');
        self.boundDefinition = self.definition(); self.result = value;
        value.wound.profile.thrownInjuries = value.wound.profile.thrownInjuries + [self];
        value.status = 'resolved'; return value;
    }
;

modify RpgExpandedProfile
    throwLocationReason(part,location)
    {
        self.validateBodyParts();
        if (part == nil || !part.ofKind(RpgExpandedBodyPart) || part.profile != self
            || !holds(self.bodyParts,part) || part.kind != location) return 'throw-location-body-part';
        if (!part.functional()) return 'throw-location-disabled-part-adapter-required';
        if (self.level('unliving') > 0) return 'throw-location-living-anatomy-required';
        return nil;
    }
;

modify RpgExpandedProfile
    catchHandReason(hand)
    {
        self.validateBodyParts();
        if (hand == nil || !hand.ofKind(RpgExpandedBodyPart) || hand.profile != self
            || hand.kind != 'hand' || !holds(self.bodyParts,hand)) return 'catch-hand-owner';
        local count = 0; foreach (local part in self.bodyParts) if (part.kind == 'hand') count += 1;
        if (count != 2) return 'catch-hand-count-adapter-required';
        if (!hand.functional()) return 'catch-hand-disabled';
        if (self.supportReserved(hand)) return 'catch-hand-reserved';
        foreach (local item in self.equipment)
            if (item.usableBy(self) && (item.ready || item.worn))
            {
                item.validateBodySupports(self);
                if (item.ready && !item.worn && item.bodySupports.length() == 0) return 'catch-grip-unmapped';
                foreach (local support in item.bodySupports)
                    if (support == hand || support == hand.parent) return 'catch-hand-occupied';
            }
        return nil;
    }
;

/** Physical maneuver adapters cannot borrow a mental-only permission gate. */
class RpgExpandedPhysicalManeuver: RpgExpandedHealthManeuver
    healthAvailable(fighter)
    {
        if (self.healthGate == nil || !self.healthGate.ofKind(RpgExpandedActionGate)
            || !self.healthGate.requiresMovement || self.healthGate.mentalAbility)
            rpgExpandedReject('physical-maneuver-health-gate');
        return inherited(fighter);
    }
;

/** Preparation uses the normal battle scheduler and one fresh health gate per turn. */
class RpgExpandedJumpPrepareManeuver: RpgExpandedPhysicalManeuver
    kind = 'concentrate'
    preparation = nil
    available(fighter)
    {
        if (self.kind != 'concentrate' || self.preparation == nil
            || !self.preparation.ofKind(RpgExpandedJumpPreparationReceipt))
            rpgExpandedReject('jump-prepare-maneuver-definition');
        local reason = inherited(fighter); if (reason != nil) return reason;
        return self.preparation.available(fighter);
    }
    apply(fighter,result)
    {
        inherited(fighter,result);
        self.preparation.record(fighter);
        return nil;
    }
;

class RpgExpandedJumpLaunchManeuver: RpgExpandedPhysicalManeuver
    kind = 'move'
    launch = nil
    preparedLaunch = nil
    available(fighter)
    {
        if (self.kind != 'move' || self.movement != 0 || self.launch == nil
            || !self.launch.ofKind(RpgExpandedJumpLaunchReceipt) || self.launch.fighter != fighter)
            rpgExpandedReject('jump-launch-maneuver-definition');
        local reason = inherited(fighter); if (reason != nil) return reason;
        local value = self.launch.assess();
        if (value.status == 'reused') return 'jump-launch-already-committed';
        return value.status == 'ready' ? nil : value.reason;
    }
    canAct(fighter)
    {
        if (!inherited(fighter)) return nil;
        self.preparedLaunch = self.launch.assess();
        if (self.preparedLaunch.status != 'ready') rpgExpandedReject('jump-launch-after-permission');
        return true;
    }
    apply(fighter,result)
    {
        inherited(fighter,result); self.launch.commit(self.preparedLaunch); return nil;
    }
;

class RpgExpandedPathMoveManeuver: RpgExpandedPhysicalManeuver
    kind = 'move'
    operation = nil
    preparedPath = nil
    available(fighter)
    {
        if (self.kind != 'move' || self.movement != 0 || self.operation == nil
            || !self.operation.ofKind(RpgExpandedPathMoveReceipt) || self.operation.fighter != fighter)
            rpgExpandedReject('path-move-maneuver-definition');
        local reason = inherited(fighter); if (reason != nil) return reason;
        local value = self.operation.assess();
        if (value.status == 'reused') return 'path-move-already-committed';
        return value.status == 'ready' ? nil : value.reason;
    }
    canAct(fighter)
    {
        if (!inherited(fighter)) return nil;
        self.preparedPath = self.operation.assess();
        if (self.preparedPath.status != 'ready') rpgExpandedReject('path-move-after-permission');
        return true;
    }
    apply(fighter,result)
    { inherited(fighter,result); self.operation.commit(self.preparedPath); return nil; }
;

/** Each of the two clamber turns owns a fresh physical health gate. */
class RpgExpandedClamberManeuver: RpgExpandedPathMoveManeuver;

class RpgExpandedForagePoisonAssessment: RpgExpandedResult
    injury = 0
    damageDieRequired = nil
;
/** B427 direct injury, not damage reduced by armor. Supplied dice only. */
rpgExpandedAssessForagePoison(healthScore,healthRoll,injuryDie)
{
    rpgInteger(healthScore,-1000,1000); rpgInteger(healthRoll,3,18);
    local value = new RpgExpandedForagePoisonAssessment();
    if (healthScore < 3) { value.reason = 'forage-poison-health-score'; return value; }
    value.check = rpgCheck(healthScore,healthRoll); value.damageDieRequired = !value.check.achieved;
    if (value.damageDieRequired) { rpgInteger(injuryDie,1,6); value.injury = injuryDie; }
    else value.injury = 1;
    value.status = 'ready'; return value;
}

class RpgExpandedForagePoisoningResult: RpgExpandedResult
    recipients = []
    scores = []
    checks = []
    injuryDice = []
    wounds = []
;
modify RpgExpandedProfile
    foragePoisonings = []
;
/** B427 owned resolution of an authored, already recorded plant-foraging 17/18. */
class RpgExpandedForagePoisoning: object
    id = nil
    occurrence = nil
    forager = nil
    party = []
    foragingCheck = nil
    approved = nil
    ordinarySusceptibility = nil
    evidence = nil
    dropDestination = nil
    result = nil
    boundDefinition = nil
    definition()
    { return [self.id,self.occurrence,self.forager,self.foragingCheck,self.foragingCheck.score,self.foragingCheck.roll,
        self.approved,self.ordinarySusceptibility,self.evidence,self.dropDestination,self.party.length()] + self.party; }
    woundFor(profile,amount)
    {
        local wound = new RpgExpandedWound(); wound.id = 'forage-' + self.id; wound.profile = profile;
        wound.amount = amount; wound.dropDestination = self.dropDestination; return wound;
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.occurrence == nil || dataType(self.occurrence) != TypeObject
            || self.forager == nil || !self.forager.ofKind(RpgExpandedProfile) || self.foragingCheck == nil
            || !self.foragingCheck.ofKind(RpgResult) || self.foragingCheck.status != 'resolved'
            || !holds([17,18],self.foragingCheck.roll)) rpgExpandedReject('forage-poison-definition');
        local value = new RpgExpandedForagePoisoningResult(); local current = self.definition();
        if (self.result != nil)
        {
            if (current.length() != self.boundDefinition.length()) rpgExpandedReject('forage-poison-binding');
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.boundDefinition[index]) rpgExpandedReject('forage-poison-binding');
            foreach (local profile in self.result.recipients)
                if (!holds(profile.foragePoisonings,self)) rpgExpandedReject('forage-poison-history');
            foreach (local wound in self.result.wounds)
                if (wound.assess().status != 'reused') rpgExpandedReject('forage-poison-wound-history');
            value.status = 'reused'; return value;
        }
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'forage-poison-source-facts'; return value; }
        if (!self.ordinarySusceptibility)
        { value.reason = 'forage-poison-susceptibility-adapter-required'; return value; }
        local seen = [];
        foreach (local profile in self.party)
        {
            if (profile == nil || !profile.ofKind(RpgExpandedProfile) || holds(seen,profile))
                rpgExpandedReject('forage-poison-party');
            seen = seen + [profile];
        }
        if (!holds(seen,self.forager)) rpgExpandedReject('forage-poison-forager-missing');
        value.recipients = self.foragingCheck.roll == 17 ? [self.forager] : self.party;
        foreach (local profile in value.recipients)
        {
            foreach (local prior in profile.foragePoisonings)
                if (prior.id == self.id || prior.occurrence == self.occurrence) rpgExpandedReject('forage-poison-duplicate');
            if (profile.dead) { value.reason = 'forage-poison-dead-recipient'; return value; }
            local context = new RpgLiteContext(); context.attribute = rpgHT; context.kind = 'poison';
            local score = rpgLiteScore(profile,context);
            if (score == nil || score < 3) { value.reason = 'forage-poison-health-score'; return value; }
            rpgInteger(score,3,1000); value.scores = value.scores + [score];
            for (local amount = 1; amount <= 6; amount += 1)
            {
                local prepared = self.woundFor(profile,amount).assess();
                if (prepared.status != 'ready') { value.reason = prepared.reason; return value; }
            }
        }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status == 'reused') return self.result;
        if (value.status != 'ready') return value;
        local definition = self.definition();
        for (local index = 1; index <= value.recipients.length(); index += 1)
        {
            local profile = value.recipients[index]; local roll = rpgRandom.roll();
            local check = rpgCheck(value.scores[index],roll);
            local die = check.achieved ? nil : rpgRandom.die();
            local poison = rpgExpandedAssessForagePoison(value.scores[index],roll,die);
            local wound = self.woundFor(profile,poison.injury);
            if (wound.apply().status != 'resolved') rpgExpandedReject('forage-poison-interrupted');
            value.checks = value.checks + [check]; value.injuryDice = value.injuryDice + [die];
            value.wounds = value.wounds + [wound];
            profile.foragePoisonings = profile.foragePoisonings + [self];
        }
        local current = self.definition();
        if (current.length() != definition.length()) rpgExpandedReject('forage-poison-changed');
        for (local index = 1; index <= current.length(); index += 1)
            if (current[index] != definition[index]) rpgExpandedReject('forage-poison-changed');
        self.boundDefinition = definition; self.result = value; value.status = 'resolved'; return value;
    }
;

modify RpgExpandedProfile
    prepareForageGate(id,evidence)
    {
        local gate = new RpgExpandedActionGate(); gate.id = 'forage-' + id; gate.profile = self;
        gate.requiresMovement = true; gate.evidence = evidence; return gate;
    }
;

/** Consume ordinary edible inventory and credit the existing daily needs ledger once. */
class RpgExpandedFoodMeal: RpgExpandedMealCredit
    stock = nil
    boundStock = nil
    validateBinding()
    {
        inherited();
        if (self.stock != self.boundStock) rpgExpandedReject('food-meal-binding');
        return nil;
    }
    assess()
    {
        local value = inherited(); if (value.status != 'ready') return value;
        if (self.stock == nil || !self.stock.ofKind(RpgExpandedFoodStock)) rpgExpandedReject('food-meal-stock');
        self.stock.validateMealStock();
        if (!self.stock.readyToEat || self.stock.preparationEvidence == nil || self.stock.preparationEvidence == '')
        { value.status = 'blocked'; value.reason = 'food-meal-preparation-required'; return value; }
        if (!holds(self.profile.equipment,self.stock) || !self.stock.usableBy(self.profile) || self.stock.quantity < self.meals
            || self.stock.thrownFlight != nil || self.stock.sharedCarry != nil)
        { value.status = 'blocked'; value.reason = 'food-meal-unavailable'; return value; }
        local owners = 0;
        for (local owner = firstObj(RpgLiteProfile); owner != nil; owner = nextObj(owner,RpgLiteProfile))
            foreach (local item in owner.equipment) if (item == self.stock) owners += 1;
        if (owners != 1) rpgExpandedReject('food-meal-ownership');
        return value;
    }
    apply()
    {
        local value = inherited(); if (value.status != 'resolved') return value;
        self.stock.quantity -= self.meals; self.boundStock = self.stock; return value;
    }
;

modify RpgExpandedProfile
    foragingDayConflict(day)
    {
        local reason = inherited(day); if (reason != nil) return reason;
        foreach (local march in self.marchExecutions)
            if (march.result.allowed && march.startedAt / 86400 <= day && (march.completedAt-1) / 86400 >= day)
                return 'foraging-day-travel-started';
        return nil;
    }
;

/** B223 separate 2d-4 direct injury per affected person, never negative healing. */
rpgExpandedSurvivalInjury(first, second)
{
    rpgInteger(first,1,6); rpgInteger(second,1,6);
    local injury = first + second - 4; return injury < 0 ? 0 : injury;
}
class RpgExpandedWildernessDayResult: RpgExpandedResult
    day = nil
    score = nil
    gate = nil
    allowed = nil
    injuryDice = []
    wounds = []
;
modify RpgExpandedProfile
    wildernessDays = []
;
/** One ordinary daily survival roll for a guide and up to ten dependents. */
class RpgExpandedWildernessDay: object
    id = nil
    profile = nil
    skill = nil
    tools = nil
    dependents = []
    compatibleBodies = nil
    approved = nil
    evidence = nil
    dropDestination = nil
    result = nil
    boundDefinition = nil
    recipients() { return [self.profile] + self.dependents; }
    definition()
    { return [self.id,self.profile,self.skill,self.tools,self.compatibleBodies,self.approved,self.evidence,self.dropDestination,
        self.skill.id,self.skill.attribute,self.skill.difficulty,self.skill.defaultPenalty,self.skill.specialty,self.dependents.length()]
        + self.dependents + self.skill.foragingDefinition() + self.tools.definition(); }
    context()
    {
        local context = new RpgLiteContext(); context.skill = self.skill; context.kind = 'survival';
        context.requiresMovement = true; return self.tools.configure(context);
    }
    woundFor(profile, amount)
    {
        local wound = new RpgExpandedWound(); wound.id = 'wilderness-' + self.id; wound.profile = profile;
        wound.amount = amount; wound.dropDestination = self.dropDestination; return wound;
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)
            || self.skill == nil || !self.skill.ofKind(RpgLiteSkill) || self.tools == nil || !self.tools.ofKind(RpgExpandedForageTools))
            rpgExpandedReject('wilderness-day-definition');
        if (self.dependents.length() > 10) rpgExpandedReject('wilderness-dependent-limit');
        local recipients = self.recipients(); local seen = [];
        foreach (local recipient in recipients)
        {
            if (recipient == nil || !recipient.ofKind(RpgExpandedProfile) || holds(seen,recipient))
                rpgExpandedReject('wilderness-recipient');
            seen = seen + [recipient];
        }
        local value = new RpgExpandedWildernessDayResult(); local definition = self.definition();
        if (self.result != nil)
        {
            if (definition.length() != self.boundDefinition.length()) rpgExpandedReject('wilderness-day-binding');
            for (local index = 1; index <= definition.length(); index += 1)
                if (definition[index] != self.boundDefinition[index]) rpgExpandedReject('wilderness-day-binding');
            foreach (local recipient in recipients)
                if (!holds(recipient.wildernessDays,self)) rpgExpandedReject('wilderness-day-history');
            if (self.result.gate.assess().status != 'reused') rpgExpandedReject('wilderness-gate-history');
            foreach (local wound in self.result.wounds)
                if (wound.assess().status != 'reused') rpgExpandedReject('wilderness-wound-history');
            value.status = 'reused'; return value;
        }
        if (!self.approved || !self.compatibleBodies || self.evidence == nil || self.evidence == '')
        { value.reason = 'wilderness-care-facts'; return value; }
        if (self.skill.id != 'survival' || self.skill.attribute != rpgPerception || self.skill.difficulty != 1
            || self.skill.defaultPenalty != -5 || !self.skill.expandedForageDefaultsReady())
            rpgExpandedReject('wilderness-survival-definition');
        local tools = self.tools.assessForProfile(self.profile,self.skill); if (tools.status != 'ready') { value.reason = tools.reason; return value; }
        value.day = rpgLedger.seconds / 86400;
        foreach (local recipient in recipients)
        {
            if (recipient.dead) { value.reason = 'wilderness-recipient-dead'; return value; }
            foreach (local prior in recipient.wildernessDays)
            {
                if (prior.id == self.id) rpgExpandedReject('wilderness-day-duplicate');
                if (prior.result.day == value.day && prior.result.check != nil)
                { value.reason = 'wilderness-day-already-resolved'; return value; }
            }
            for (local amount = 0; amount <= 8; amount += 1)
            {
                local wound = self.woundFor(recipient,amount); local prepared = wound.assess();
                if (prepared.status != 'ready') { value.reason = prepared.reason; return value; }
            }
        }
        value.score = rpgLiteScore(self.profile,self.context());
        if (value.score == nil || value.score < 3) { value.reason = 'wilderness-score-unavailable'; return value; }
        value.gate = new RpgExpandedActionGate(); value.gate.id = 'wilderness-' + self.id;
        value.gate.profile = self.profile; value.gate.requiresMovement = true; value.gate.evidence = self.evidence;
        local permission = value.gate.assess(); if (permission.status != 'ready') { value.reason = permission.reason; return value; }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status == 'reused') return self.result;
        if (value.status != 'ready') return value;
        local definition = self.definition(); local permission = value.gate.apply();
        if (permission.status != 'resolved') rpgExpandedReject('wilderness-permission-changed');
        value.allowed = permission.allowed;
        if (value.allowed)
        {
            if (rpgLedger.seconds / 86400 != value.day || rpgLiteScore(self.profile,self.context()) != value.score)
                rpgExpandedReject('wilderness-context-changed');
            value.check = rpgCheck(value.score,rpgRandom.roll());
            if (!value.check.achieved)
                foreach (local recipient in self.recipients())
                {
                    local first = rpgRandom.die(); local second = rpgRandom.die();
                    local wound = self.woundFor(recipient,rpgExpandedSurvivalInjury(first,second));
                    if (wound.apply().status != 'resolved') rpgExpandedReject('wilderness-injury-changed');
                    value.injuryDice = value.injuryDice + [[first,second]]; value.wounds = value.wounds + [wound];
                }
        }
        local current = self.definition(); if (current.length() != definition.length()) rpgExpandedReject('wilderness-day-changed');
        for (local index = 1; index <= current.length(); index += 1)
            if (current[index] != definition[index]) rpgExpandedReject('wilderness-day-changed');
        foreach (local recipient in self.recipients()) recipient.wildernessDays = recipient.wildernessDays + [self];
        self.boundDefinition = definition; self.result = value; value.status = 'resolved'; return value;
    }
;

modify RpgExpandedProfile
    prepareSocialGate(id, evidence, movement)
    {
        local gate = new RpgExpandedActionGate(); gate.id = 'social-' + id; gate.profile = self;
        gate.evidence = evidence; gate.requiresMovement = movement; return gate;
    }
;

class RpgExpandedRecurrentPainResult: RpgExpandedResult
    occurs = nil
    roll = nil
;
/** B126 one daily appearance check and an authored waking onset. */
class RpgExpandedRecurrentPainDay: object
    id = nil
    profile = nil
    trait = nil
    onsetAt = nil
    duringSleep = nil
    approved = nil
    evidence = nil
    day = nil
    dueAt = nil
    endedAt = nil
    recoveries = []
    boundDefinition = nil
    result = nil
    definition()
    {
        return [self.id,self.profile,self.trait,self.onsetAt,self.duringSleep,self.approved,self.evidence,
            self.trait.severity,self.trait.intervalHours,self.trait.frequency];
    }
    validateReceipt()
    {
        local current = self.definition();
        for (local i = 1; i <= current.length(); i += 1)
            if (current[i] != self.boundDefinition[i]) rpgExpandedReject('recurrent-pain-day-binding');
        if (!holds(self.profile.recurrentPainDays,self)) rpgExpandedReject('recurrent-pain-day-history');
        return nil;
    }
    active()
    {
        if (self.result == nil) return nil;
        self.validateReceipt();
        return self.result.occurs && self.endedAt == nil && rpgLedger.seconds >= self.onsetAt
            && holds(self.profile.traits,self.trait) && self.trait.active && !self.trait.mitigated;
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)
            || self.trait == nil || !self.trait.ofKind(RpgLiteTrait) || !self.trait.recurrentPainDefinition())
            rpgExpandedReject('recurrent-pain-day-definition');
        local value = new RpgExpandedRecurrentPainResult();
        if (self.result != nil) { self.validateReceipt(); value.status = 'reused'; return value; }
        self.trait.creationCost();
        if (!holds(self.profile.traits,self.trait) || !self.trait.active || self.trait.mitigated)
        { value.reason = 'recurrent-pain-trait-unavailable'; return value; }
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'recurrent-pain-onset-required'; return value; }
        local day = rpgLedger.seconds / 86400;
        rpgInteger(self.onsetAt,rpgLedger.seconds,2147483647-self.trait.intervalSeconds());
        if (self.onsetAt / 86400 != day) { value.reason = 'recurrent-pain-onset-day'; return value; }
        foreach (local prior in self.profile.recurrentPainDays)
        {
            prior.validateReceipt();
            if (prior.id == self.id || prior.trait == self.trait && prior.day == day)
                rpgExpandedReject('recurrent-pain-day-duplicate');
            if (prior.trait == self.trait && prior.result.occurs && prior.endedAt == nil)
            { value.reason = 'recurrent-pain-overlapping-day-unresolved'; return value; }
        }
        value.status = 'ready'; return value;
    }
    resolve()
    {
        local value = self.assess(); if (value.status == 'reused') return self.result;
        if (value.status != 'ready') return value;
        self.boundDefinition = self.definition(); self.day = rpgLedger.seconds / 86400;
        value.roll = rpgRandom.roll(); value.occurs = self.trait.appears(value.roll);
        self.dueAt = value.occurs ? self.onsetAt + self.trait.intervalSeconds() : nil;
        self.profile.recurrentPainDays = self.profile.recurrentPainDays + [self];
        value.status = 'resolved'; self.result = value; return value;
    }
;
/** A distinct receipt for each interval; replay never rolls again. */
class RpgExpandedRecurrentPainRecovery: object
    id = nil
    episode = nil
    expectedDue = nil
    result = nil
    boundDefinition = nil
    definition() { return [self.id,self.episode,self.expectedDue]; }
    assess()
    {
        if (self.id == nil || self.id == '' || self.episode == nil || !self.episode.ofKind(RpgExpandedRecurrentPainDay))
            rpgExpandedReject('recurrent-pain-recovery-definition');
        local value = new RpgExpandedResult();
        if (self.result != nil)
        {
            local current = self.definition();
            for (local i = 1; i <= current.length(); i += 1)
                if (current[i] != self.boundDefinition[i]) rpgExpandedReject('recurrent-pain-recovery-binding');
            self.episode.validateReceipt();
            if (!holds(self.episode.recoveries,self)) rpgExpandedReject('recurrent-pain-recovery-history');
            value.status = 'reused'; return value;
        }
        if (self.episode.result == nil || !self.episode.active())
        { value.reason = 'recurrent-pain-not-active'; return value; }
        foreach (local prior in self.episode.recoveries)
            if (prior.id == self.id) rpgExpandedReject('recurrent-pain-recovery-duplicate');
        if (self.expectedDue != self.episode.dueAt || rpgLedger.seconds < self.expectedDue)
        { value.reason = 'recurrent-pain-recovery-not-due'; return value; }
        rpgInteger(rpgLedger.seconds,0,2147483647-self.episode.trait.intervalSeconds());
        local context = new RpgLiteContext(); context.attribute = rpgHT; context.kind = 'recurrent-pain-recovery';
        local score = rpgLiteScore(self.episode.profile,context);
        if (score == nil || score < 3) { value.reason = 'recurrent-pain-recovery-unavailable'; return value; }
        value.modifier = score; value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status == 'reused') return self.result;
        if (value.status != 'ready') return value;
        value.check = rpgCheck(value.modifier,rpgRandom.roll());
        if (value.check.achieved) self.episode.endedAt = rpgLedger.seconds;
        else self.episode.dueAt = rpgLedger.seconds + self.episode.trait.intervalSeconds();
        self.boundDefinition = self.definition(); self.episode.recoveries = self.episode.recoveries + [self];
        value.status = 'resolved'; self.result = value; return value;
    }
;
modify RpgExpandedProfile
    recurrentPainDays = []
    recurrentPainPenalty()
    {
        local amount = 0;
        foreach (local episode in self.recurrentPainDays) if (episode.active() && !episode.duringSleep) amount += episode.trait.awakePenalty();
        return amount;
    }
    healthAttributeModifier(context)
    {
        local amount = inherited(context);
        return amount + (holds([rpgDX,rpgIQ],context.controllingAttribute()) ? self.recurrentPainPenalty() : 0);
    }
    healthSelfControlModifier(trait) { return inherited(trait) + self.recurrentPainPenalty(); }
;

modify RpgExpandedProfile
    validateSleepRecoveryInterval(start,seconds)
    {
        inherited(start,seconds);
        foreach (local episode in self.recurrentPainDays)
        {
            episode.validateReceipt();
            if (episode.result.occurs && episode.duringSleep
                && (episode.endedAt == nil || episode.endedAt > start)
                && holds(self.traits,episode.trait) && episode.trait.active && !episode.trait.mitigated
                && episode.onsetAt < start + seconds)
                rpgExpandedReject('recurrent-pain-sleepless-rest-required');
        }
        return nil;
    }
;
/** B126 sleep interruption uses the existing waking-needs and rest ledgers. */
class RpgExpandedPainSleeplessRest: object
    id = nil
    episode = nil
    needs = nil
    seconds = 0
    food = nil
    water = nil
    healingAllowed = nil
    approved = nil
    evidence = nil
    result = nil
    boundDefinition = nil
    startedAt = nil
    completedAt = nil
    definition()
    {
        return [self.id,self.episode,self.needs,self.seconds,self.food,self.water,self.healingAllowed,self.approved,self.evidence];
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.episode == nil || !self.episode.ofKind(RpgExpandedRecurrentPainDay)
            || self.needs == nil || !self.needs.ofKind(RpgLiteNeeds) || self.needs.profile != self.episode.profile)
            rpgExpandedReject('pain-sleepless-rest-definition');
        local value = new RpgExpandedResult();
        if (self.result != nil)
        {
            local current = self.definition();
            for (local i = 1; i <= current.length(); i += 1)
                if (current[i] != self.boundDefinition[i]) rpgExpandedReject('pain-sleepless-rest-binding');
            if (!holds(self.episode.sleeplessRests,self) || self.completedAt != self.startedAt + self.seconds)
                rpgExpandedReject('pain-sleepless-rest-history');
            value.status = 'reused'; return value;
        }
        rpgInteger(self.seconds,1,86400);
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'pain-sleepless-rest-evidence'; return value; }
        if (!self.episode.active() || !self.episode.duringSleep || self.needs.active)
        { value.reason = 'pain-sleepless-rest-conditions'; return value; }
        if (self.episode.profile.dead || self.episode.profile.unconscious)
        { value.reason = 'pain-sleepless-rest-unavailable'; return value; }
        if (self.seconds > self.episode.dueAt - rpgLedger.seconds)
        { value.reason = 'pain-sleepless-rest-recovery-boundary'; return value; }
        foreach (local prior in self.episode.sleeplessRests)
            if (prior.id == self.id) rpgExpandedReject('pain-sleepless-rest-duplicate');
        self.episode.profile.validateNaturalRecovery(self.seconds,self.food,self.healingAllowed);
        rpgInteger(rpgLedger.seconds,0,2147483647-self.seconds);
        rpgLedger.validateAdvance(self.seconds);
        value.status = 'ready'; value.seconds = self.seconds; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status == 'reused') return self.result;
        if (value.status != 'ready') return value;
        local definition = self.definition(); local start = rpgLedger.seconds;
        local elapsed = self.needs.elapsed; local cycle = self.needs.cycle;
        local due = self.episode.dueAt; local ended = self.episode.endedAt;
        self.needs.advance(self.seconds);
        if (self.episode.profile.unconscious) rpgExpandedReject('pain-sleepless-rest-consciousness-changed');
        local rest = rpgLiteRest(self.episode.profile,self.seconds,self.food,self.water,nil,self.healingAllowed);
        local current = self.definition();
        for (local i = 1; i <= current.length(); i += 1)
            if (current[i] != definition[i]) rpgExpandedReject('pain-sleepless-rest-interrupted');
        if (self.episode.dueAt != due || self.episode.endedAt != ended || !self.episode.active())
            rpgExpandedReject('pain-sleepless-rest-episode-changed');
        if (rest.status != 'resolved' || rpgLedger.seconds != start + self.seconds
            || self.needs.elapsed != (elapsed+self.seconds) % 86400
            || self.needs.cycle != cycle + (elapsed+self.seconds) / 86400)
            rpgExpandedReject('pain-sleepless-rest-double-time');
        self.startedAt = start; self.completedAt = rpgLedger.seconds; self.boundDefinition = definition;
        self.episode.sleeplessRests = self.episode.sleeplessRests + [self];
        value.status = 'resolved'; self.result = value; return value;
    }
;
modify RpgExpandedRecurrentPainDay
    sleeplessRests = []
;

/** B423 explicitly adjudicated lethal attack on a helpless victim. */
class RpgExpandedInstantDeathResult: RpgExpandedResult
    injuryAdded = 0
;
modify RpgExpandedProfile
    instantDeathHistory = []
;
class RpgExpandedInstantDeath: object
    id = nil
    profile = nil
    approved = nil
    evidence = nil
    helpless = nil
    obviouslyLethal = nil
    result = nil
    boundDefinition = nil
    definition() { return [self.id,self.profile,self.approved,self.evidence,self.helpless,self.obviouslyLethal]; }
    validateBinding()
    {
        local current = self.definition();
        for (local i = 1; i <= current.length(); i += 1)
            if (current[i] != self.boundDefinition[i]) rpgExpandedReject('instant-death-binding');
        if (!holds(self.profile.instantDeathHistory,self)) rpgExpandedReject('instant-death-owner');
        return nil;
    }
    assess()
    {
        local value = new RpgExpandedInstantDeathResult();
        if (self.result != nil)
        {
            self.validateBinding(); value.status = 'reused'; value.injuryAdded = self.result.injuryAdded; return value;
        }
        if (self.profile == nil || !self.profile.ofKind(RpgExpandedProfile) || self.id == nil || self.id == '')
            rpgExpandedReject('instant-death-definition');
        rpgExpandedValidate(self.profile);
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'instant-death-approval'; return value; }
        foreach (local prior in self.profile.instantDeathHistory)
            if (prior.id == self.id) rpgExpandedReject('instant-death-duplicate');
        if (self.profile.dead) { value.reason = 'instant-death-already-dead'; return value; }
        if (!self.helpless && !self.profile.unconscious)
        { value.reason = 'instant-death-victim-not-helpless'; return value; }
        if (!self.obviouslyLethal) { value.reason = 'instant-death-lethality'; return value; }
        rpgInteger(self.profile.maxHP,1,1000);
        rpgInteger(self.profile.injury,0,1000000);
        value.injuryAdded = 6 * self.profile.maxHP - self.profile.injury;
        if (value.injuryAdded < 0) value.injuryAdded = 0;
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess();
        if (value.status == 'reused') return self.result;
        if (value.status != 'ready') return value;
        local capacity = self.profile.maxHP;
        local injury = self.profile.injury + value.injuryAdded;
        self.boundDefinition = self.definition();
        self.profile.injury = injury; self.profile.dead = true;
        self.profile.instantDeathHistory = self.profile.instantDeathHistory + [self];
        value.status = 'resolved'; self.result = value;
        self.profile.becomeUnconscious();
        self.validateBinding();
        if (self.profile.maxHP != capacity || self.profile.injury != injury || !self.profile.dead || !self.profile.unconscious)
            rpgExpandedReject('instant-death-state-changed');
        return value;
    }
;


/** B423 optional retention of final injury after death, on the shared ledger. */
modify RpgExpandedRules
    retainPostmortemInjury = nil
;
modify RpgExpandedProfile
    postmortemHistory = []
    postmortemInjury(amount)
    {
        if (self.rules == nil || !self.rules.retainPostmortemInjury) return inherited(amount);
        local receipt = new RpgExpandedPostmortemInjury();
        receipt.id = self.postmortemHistory.length() + 1; receipt.profile = self; receipt.amount = amount;
        receipt.approved = true; receipt.evidence = 'Final injury supplied through the shared wound interface';
        local applied = receipt.apply(); local value = new RpgLiteHealthResult();
        value.status = applied.status; value.injury = applied.injuryAdded; return value;
    }
;
class RpgExpandedPostmortemInjury: object
    id = nil
    profile = nil
    amount = 0
    approved = nil
    evidence = nil
    result = nil
    boundDefinition = nil
    definition() { return [self.id,self.profile,self.amount,self.approved,self.evidence]; }
    assess()
    {
        local value = new RpgExpandedInstantDeathResult();
        if (self.result != nil)
        {
            local current = self.definition();
            for (local i = 1; i <= current.length(); i += 1)
                if (current[i] != self.boundDefinition[i]) rpgExpandedReject('postmortem-binding');
            if (!holds(self.profile.postmortemHistory,self)) rpgExpandedReject('postmortem-owner');
            value.status = 'reused'; value.injuryAdded = self.result.injuryAdded; return value;
        }
        if (self.id == nil || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile))
            rpgExpandedReject('postmortem-definition');
        rpgExpandedValidate(self.profile); rpgInteger(self.amount,1,100000);
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'postmortem-approval'; return value; }
        if (!self.profile.rules.retainPostmortemInjury) { value.reason = 'postmortem-disabled'; return value; }
        if (!self.profile.dead) { value.reason = 'postmortem-living'; return value; }
        foreach (local prior in self.profile.postmortemHistory)
            if (prior.id == self.id) rpgExpandedReject('postmortem-duplicate');
        rpgInteger(self.profile.injury,0,1000000 - self.amount);
        value.injuryAdded = self.amount; value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess();
        if (value.status == 'reused') return self.result;
        if (value.status != 'ready') return value;
        self.boundDefinition = self.definition(); self.profile.injury += self.amount;
        self.profile.postmortemHistory = self.profile.postmortemHistory + [self];
        value.status = 'resolved'; self.result = value; return value;
    }
;

/** B419/B423 body condition is a source-based decision, not an injury multiplier. */
class RpgExpandedBodyResult: RpgExpandedResult
    disposition = nil
;
modify RpgExpandedProfile
    bodyAssessments = []
    bodyIntegrity()
    {
        local current = nil;
        foreach (local receipt in self.bodyAssessments)
        {
            if (!receipt.ofKind(RpgExpandedBodyAssessment) || receipt.profile != self)
                rpgExpandedReject('body-assessment-owner');
            receipt.validateBinding();
            if (receipt.disposition == 'destroyed') return 'destroyed';
            if (receipt.injuryBasis == self.injury && receipt.capacityBasis == self.maxHP)
                current = receipt.disposition;
        }
        if (!self.dead) return 'not-dead';
        if (self.hp() > -10 * self.maxHP) return 'below-threshold';
        return current == nil ? 'unassessed' : current;
    }
;
class RpgExpandedBodyAssessment: object
    id = nil
    profile = nil
    disposition = nil
    approved = nil
    evidence = nil
    result = nil
    injuryBasis = nil
    capacityBasis = nil
    boundDefinition = nil
    definition()
    { return [self.id,self.profile,self.disposition,self.approved,self.evidence,self.injuryBasis,self.capacityBasis]; }
    validateBinding()
    {
        if (self.result == nil || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)
            || !holds(self.profile.bodyAssessments,self)) rpgExpandedReject('body-assessment-owner');
        local current = self.definition();
        for (local i = 1; i <= current.length(); i += 1)
            if (current[i] != self.boundDefinition[i]) rpgExpandedReject('body-assessment-binding');
        return nil;
    }
    assess()
    {
        local value = new RpgExpandedBodyResult();
        if (self.result != nil)
        {
            self.validateBinding(); value.status = 'reused'; value.disposition = self.disposition; return value;
        }
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile))
            rpgExpandedReject('body-assessment-definition');
        rpgExpandedValidate(self.profile); rpgInteger(self.profile.maxHP,1,1000);
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'body-assessment-approval'; return value; }
        if (!holds(['recognizable','destroyed'],self.disposition)) rpgExpandedReject('body-assessment-disposition');
        if (!self.profile.dead) { value.reason = 'body-assessment-not-dead'; return value; }
        if (self.profile.hp() > -10 * self.profile.maxHP) { value.reason = 'body-assessment-threshold'; return value; }
        foreach (local prior in self.profile.bodyAssessments)
            if (prior.id == self.id) rpgExpandedReject('body-assessment-duplicate');
        if (self.profile.bodyIntegrity() != 'unassessed') { value.reason = 'body-state-already-assessed'; return value; }
        value.disposition = self.disposition; value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess();
        if (value.status == 'reused') return self.result;
        if (value.status != 'ready') return value;
        self.injuryBasis = self.profile.injury; self.capacityBasis = self.profile.maxHP;
        self.boundDefinition = self.definition(); self.profile.bodyAssessments = self.profile.bodyAssessments + [self];
        value.status = 'resolved'; self.result = value; return value;
    }
;

/** B421 finite attribute loss from an already-resolved authored cause. */
class RpgExpandedAttributeReduction: RpgExpandedCoughing
    attribute = nil
    penalty = 0
    history() { return self.profile.attributeReductionHistory; }
    remember() { self.profile.attributeReductionHistory = self.profile.attributeReductionHistory + [self]; }
    receiptKind() { return 'attribute-reduction'; }
    definition() { return inherited() + [self.attribute,self.penalty]; }
    assess()
    {
        if (!holds([rpgST,rpgDX,rpgIQ,rpgHT],self.attribute)) rpgExpandedReject('attribute-reduction-attribute-unsupported');
        rpgInteger(self.penalty,1,1000);
        return inherited();
    }
;
modify RpgExpandedProfile
    attributeReductionHistory = []
    healthAttributeModifier(context)
    {
        local value = inherited(context);
        local exempt = context.defensiveReaction || holds(['defense','resistance','fright','fear'],context.kind);
        local attribute = context.controllingAttribute();
        foreach (local episode in self.attributeReductionHistory)
        {
            if (episode.profile != self) rpgExpandedReject('attribute-reduction-owner');
            if (episode.active() && !exempt
                && (attribute == episode.attribute
                    || episode.attribute == rpgIQ && holds([rpgWill,rpgPerception],attribute)))
                value -= episode.penalty;
        }
        return value;
    }
;

modify RpgExpandedProfile
    muscleDamageStrength()
    {
        local strength = inherited();
        foreach (local episode in self.attributeReductionHistory)
        {
            if (episode.profile != self) rpgExpandedReject('attribute-reduction-owner');
            if (episode.active() && episode.attribute == rpgST) strength -= episode.penalty;
        }
        if (strength < 1) rpgExpandedReject('reduced-strength-damage-unavailable');
        return strength;
    }
    validateCombatVision()
    {
        inherited(); self.muscleDamageStrength(); return nil;
    }
;

modify RpgExpandedProfile
    handlingStrength() { return self.muscleDamageStrength(); }
    weaponStrength(weapon)
    {
        /* B270: bows and crossbows use their own rating for range and damage. */
        if (holds(['longbow','short-bow','crossbow'],weapon.id)) return weapon.weaponST;
        return inherited(weapon);
    }
;

modify RpgExpandedProfile
    fearAcuteInjuries = []
;
class RpgExpandedFearAcuteInjuryResult: RpgExpandedResult
    wound = nil
    amount = 0
    dice = []
    dropPlan = nil
;
/** B361 row 32: collapse plus two dice of injury, through the shared ledger. */
class RpgExpandedFearAcuteInjury: object
    id = nil
    context = nil
    approved = nil
    evidence = nil
    dropDestination = nil
    result = nil
    recordedAt = nil
    boundDefinition = nil
    boundWound = nil
    boundDice = nil
    definition() { return [self.id,self.context,self.context.profile,self.approved,self.evidence,self.dropDestination,self.recordedAt]; }
    wound(amount)
    {
        local wound = new RpgExpandedWound(); wound.id = 'fear-acute:' + self.id;
        wound.profile = self.context.profile; wound.amount = amount; wound.dropDestination = self.dropDestination; return wound;
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.context == nil || !self.context.ofKind(RpgExpandedFearContext))
            rpgExpandedReject('fear-acute-definition');
        local value = new RpgExpandedFearAcuteInjuryResult(); local profile = self.context.profile;
        if (self.result != nil)
        {
            if (!holds(profile.fearAcuteInjuries,self)) rpgExpandedReject('fear-acute-history');
            local facts = self.definition();
            for (local index = 1; index <= facts.length(); index += 1)
                if (facts[index] != self.boundDefinition[index]) rpgExpandedReject('fear-acute-binding');
            if (self.result.wound != self.boundWound || self.result.amount != self.boundWound.amount
                || self.result.dice.length() != 2 || self.result.dice[1] != self.boundDice[1]
                || self.result.dice[2] != self.boundDice[2]) rpgExpandedReject('fear-acute-wound-binding');
            self.boundWound.assess(); value.status = 'reused'; value.wound = self.boundWound;
            value.amount = self.boundWound.amount; value.dice = self.result.dice; return value;
        }
        if (self.recordedAt != nil || self.boundDefinition != nil || self.boundWound != nil || self.boundDice != nil) rpgExpandedReject('fear-acute-uncommitted-state');
        local scene = self.context.consequenceAssessment();
        if (scene.status != 'ready') { value.reason = scene.reason; return value; }
        if (scene.immune) { value.reason = 'fear-acute-immune'; return value; }
        if (!self.approved || self.evidence == nil || self.evidence == '') { value.reason = 'fear-acute-evidence'; return value; }
        if (profile.dead || profile.unconscious) { value.reason = 'fear-acute-observer-unavailable'; return value; }
        foreach (local prior in profile.fearAcuteInjuries)
            if (prior.id == self.id) rpgExpandedReject('fear-acute-duplicate');
        value.dropPlan = profile.prepareKnockdownDrop(self.dropDestination);
        if (value.dropPlan != nil && value.dropPlan.status != 'ready') { value.reason = value.dropPlan.reason; return value; }
        for (local amount = 2; amount <= 12; amount += 1)
        {
            local injury = self.wound(amount).assess();
            if (injury.status != 'ready') { value.reason = injury.reason; return value; }
        }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local first = rpgRandom.die(); local second = rpgRandom.die();
        value.dice = [first,second]; value.amount = first + second; value.wound = self.wound(value.amount);
        local injury = value.wound.apply();
        if (injury.status != 'resolved') rpgExpandedReject('fear-acute-injury-changed');
        local profile = self.context.profile;
        if (value.dropPlan != nil && value.wound.droppedEquipment == nil) value.dropPlan.commit();
        profile.posture = 'lying';
        if (!value.wound.health.knockedDown) profile.onKnockdown();
        self.recordedAt = profile.timeElapsed; self.boundDefinition = self.definition(); self.boundWound = value.wound; self.boundDice = [first,second];
        profile.fearAcuteInjuries = profile.fearAcuteInjuries + [self]; value.status = 'resolved'; self.result = value; return value;
    }
;

modify RpgExpandedProfile
    fearPanicEpisodes = []
    fearPanic = nil
;
/** B361 row 21; behavior is an explicit author fact, never an invented route. */
class RpgExpandedFearPanic: object
    id = nil
    context = nil
    approved = nil
    evidence = nil
    behaviorKind = nil
    behavior = nil
    startedAt = nil
    initialMinutes = nil
    nextCheckAt = nil
    completedAt = nil
    boundDefinition = nil
    recoveries = []
    definition()
    {
        return [self.id,self.context,self.context.profile,self.approved,self.evidence,self.behaviorKind,self.behavior,
            self.startedAt,self.initialMinutes];
    }
    validateTimeline()
    {
        local due = self.startedAt + self.initialMinutes * 60; local ended = nil; local ids = [];
        foreach (local recovery in self.recoveries)
        {
            if (recovery == nil || !recovery.ofKind(RpgExpandedFearPanicRecovery) || recovery.episode != self)
                rpgExpandedReject('fear-panic-recovery-owner');
            recovery.validateReceipt();
            if (holds(ids,recovery.id) || ended != nil || recovery.recordedAt != due) rpgExpandedReject('fear-panic-timeline');
            ids = ids + [recovery.id];
            if (recovery.result.check.achieved) ended = due;
            else due += 60;
        }
        if (self.nextCheckAt != due || self.completedAt != ended) rpgExpandedReject('fear-panic-timeline');
        if (ended == nil && self.context.profile.fearPanic != self
            || ended != nil && self.context.profile.fearPanic == self) rpgExpandedReject('fear-panic-owner');
        return nil;
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.context == nil || !self.context.ofKind(RpgExpandedFearContext))
            rpgExpandedReject('fear-panic-definition');
        local value = new RpgExpandedResult(); local profile = self.context.profile;
        if (self.startedAt != nil)
        {
            if (!holds(profile.fearPanicEpisodes,self)) rpgExpandedReject('fear-panic-history');
            local facts = self.definition();
            for (local index = 1; index <= facts.length(); index += 1)
                if (facts[index] != self.boundDefinition[index]) rpgExpandedReject('fear-panic-binding');
            self.validateTimeline();
            if (self.activities.length() != self.activityCount) rpgExpandedReject('fear-panic-activity-count');
            local activityIds = []; local previousEnd = self.startedAt;
            foreach (local activity in self.activities)
            {
                if (activity == nil || !activity.ofKind(RpgExpandedPanicActivityReceipt) || activity.episode != self
                    || holds(activityIds,activity.id)) rpgExpandedReject('fear-panic-activity-owner');
                activity.validateReceipt();
                if (activity.startedAt < previousEnd || activity.completedAt < activity.startedAt
                    || activity.completedAt > rpgLedger.seconds || self.completedAt != nil && activity.completedAt > self.completedAt)
                    rpgExpandedReject('fear-panic-activity-time');
                previousEnd = activity.completedAt; activityIds = activityIds + [activity.id];
            }
            value.status = 'reused'; return value;
        }
        if (self.initialMinutes != nil || self.nextCheckAt != nil || self.completedAt != nil || self.boundDefinition != nil
            || self.recoveries.length() != 0 || self.activities.length() != 0 || self.activityCount != 0)
            rpgExpandedReject('fear-panic-uncommitted-state');
        local scene = self.context.consequenceAssessment();
        if (scene.status != 'ready') { value.reason = scene.reason; return value; }
        if (scene.immune) { value.reason = 'fear-panic-immune'; return value; }
        if (!self.approved || self.evidence == nil || self.evidence == '' || self.behavior == nil || self.behavior == '')
        { value.reason = 'fear-panic-author-facts'; return value; }
        if (!holds(['cry','agitated-motion','other-pointless'],self.behaviorKind)) rpgExpandedReject('fear-panic-behavior-kind');
        if (profile.dead || profile.unconscious || profile.fearPanic != nil)
        { value.reason = 'fear-panic-observer-unavailable'; return value; }
        foreach (local prior in profile.fearPanicEpisodes)
            if (prior.id == self.id) rpgExpandedReject('fear-panic-duplicate');
        rpgInteger(rpgLedger.seconds,0,2147483287);
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.initialMinutes = rpgRandom.die(); self.startedAt = rpgLedger.seconds;
        self.nextCheckAt = self.startedAt + self.initialMinutes * 60; self.boundDefinition = self.definition();
        local profile = self.context.profile; profile.fearPanic = self; profile.fearPanicEpisodes = profile.fearPanicEpisodes + [self];
        value.status = 'resolved'; return value;
    }
;
/** Shared time has reached the boundary; this receipt adds no second time charge. */
class RpgExpandedFearPanicRecovery: object
    recoveryDecision = nil
    id = nil
    episode = nil
    result = nil
    recordedAt = nil
    boundDefinition = nil
    boundCheck = nil
    definition() { return [self.id,self.episode,self.recordedAt]; }
    validateReceipt()
    {
        if (self.result != nil && self.result.check != nil && self.result.check.ofKind(RpgExpandedAuthoredRecoveryResult))
        {
            if (self.recoveryDecision != self.result.check.decision) rpgExpandedReject('fear-recovery-ruling-changed');
            self.result.check.validate(self);
        }
        else if (self.result != nil && self.recoveryDecision != nil) rpgExpandedReject('fear-recovery-ruling-added');
        if (self.result == nil || !holds(self.episode.recoveries,self)) rpgExpandedReject('fear-panic-recovery-history');
        local facts = self.definition();
        for (local index = 1; index <= facts.length(); index += 1)
            if (facts[index] != self.boundDefinition[index]) rpgExpandedReject('fear-panic-recovery-binding');
        local check = self.result.check;
        if (check == nil || check != self.boundCheck[1] || check.score != self.boundCheck[2] || check.roll != self.boundCheck[3]
            || check.achieved != self.boundCheck[4] || check.margin != self.boundCheck[5] || check.critical != self.boundCheck[6])
            rpgExpandedReject('fear-panic-recovery-check-binding');
        if (self.recordedAt > rpgLedger.seconds) rpgExpandedReject('fear-panic-recovery-time');
        return nil;
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.episode == nil || !self.episode.ofKind(RpgExpandedFearPanic))
            rpgExpandedReject('fear-panic-recovery-definition');
        local value = new RpgExpandedResult();
        if (self.result != nil)
        {
            if (self.result.check != nil && self.result.check.ofKind(RpgExpandedAuthoredRecoveryResult))
            {
                if (self.recoveryDecision != self.result.check.decision) rpgExpandedReject('fear-recovery-ruling-changed');
                self.result.check.validate(self);
            }
            else if (self.recoveryDecision != nil) rpgExpandedReject('fear-recovery-ruling-added');
            self.validateReceipt(); self.episode.assess();
            value.status = 'reused'; value.check = self.result.check; return value;
        }
        if (self.recordedAt != nil || self.boundDefinition != nil || self.boundCheck != nil) rpgExpandedReject('fear-panic-recovery-uncommitted-state');
        if (self.episode.startedAt == nil) { value.reason = 'fear-panic-episode-required'; return value; }
        self.episode.assess(); local profile = self.episode.context.profile;
        if (self.episode.completedAt != nil) { value.reason = 'fear-panic-ended'; return value; }
        if (profile.dead) { value.reason = 'fear-panic-recovery-dead'; return value; }
        if (rpgLedger.seconds != self.episode.nextCheckAt) { value.reason = 'fear-panic-recovery-not-due'; return value; }
        foreach (local prior in self.episode.recoveries)
            if (prior.id == self.id) rpgExpandedReject('fear-panic-recovery-duplicate');
        local score = profile.attributeScore(rpgWill);
        value.reason = rpgExpandedFearRecoveryReason(self,score); if (value.reason != nil) return value;
        rpgInteger(rpgLedger.seconds,0,2147483587); value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local profile = self.episode.context.profile;
        value.check = rpgExpandedFearRecoveryRoll(self,profile.attributeScore(rpgWill));
        self.recordedAt = rpgLedger.seconds; self.boundDefinition = self.definition();
        self.boundCheck = [value.check,value.check.score,value.check.roll,value.check.achieved,value.check.margin,value.check.critical];
        self.episode.recoveries = self.episode.recoveries + [self];
        if (value.check.achieved) { self.episode.completedAt = self.recordedAt; profile.fearPanic = nil; }
        else self.episode.nextCheckAt = self.recordedAt + 60;
        value.status = 'resolved'; self.result = value; return value;
    }
;
modify rpgLedger
    validateAdvance(seconds)
    {
        inherited(seconds);
        for (local episode = firstObj(RpgExpandedFearPanic); episode != nil; episode = nextObj(episode,RpgExpandedFearPanic))
            if (episode.startedAt != nil)
            {
                episode.assess();
                if (episode.completedAt == nil && !episode.context.profile.dead
                    && self.seconds + seconds > episode.nextCheckAt) rpgExpandedReject('fear-panic-recovery-boundary');
            }
        return nil;
    }
;

modify RpgExpandedFearPanic
    activities = []
    activityCount = 0
;
modify RpgExpandedProfile
    activeFearPanic()
    {
        local ids = [];
        foreach (local episode in self.fearPanicEpisodes)
        {
            if (episode == nil || !episode.ofKind(RpgExpandedFearPanic) || episode.context.profile != self || holds(ids,episode.id))
                rpgExpandedReject('fear-panic-profile-history');
            episode.assess(); ids = ids + [episode.id];
        }
        if (self.fearPanic == nil) return nil;
        self.fearPanic.assess(); return self.fearPanic.completedAt == nil;
    }
    healthEffortReasonFor(purpose,mentalAbility,speech,movement,authorization)
    {
        local reason = inherited(purpose,mentalAbility,speech,movement,authorization); if (reason != nil) return reason;
        if (self.activeFearPanic() && !holds(['rest','do-nothing'],purpose)
            && !((authorization != nil && authorization.ofKind(RpgExpandedPanicMovementGate)
                && authorization.permits(self,purpose,movement))
                || (authorization != nil && authorization.ofKind(RpgExpandedPanicExpressionGate)
                    && authorization.permits(self,purpose,speech,movement))
                || self.timedPanicAuthorization(authorization))) return 'fear-panic-purposeful-action';
        return nil;
    }
    healthManeuverReasonFor(kind,request)
    {
        local reason = inherited(kind,request); if (reason != nil) return reason;
        return self.activeFearPanic() && kind != 'nothing' && !self.timedPanicAuthorization(request)
            ? 'fear-panic-purposeful-maneuver' : nil;
    }
;
/** Concrete stationary crying interval; author text supplies presentation only. */
class RpgExpandedFearPanicCrying: RpgExpandedPanicActivityReceipt
    id = nil
    episode = nil
    seconds = 1
    healthGate = nil
    result = nil
    startedAt = nil
    completedAt = nil
    boundDefinition = nil
    boundOutcome = nil
    behaviorKind() { return 'cry'; }
    gatePurpose() { return 'do-nothing'; }
    activityReason() { return nil; }
    commitActivity() { return nil; }
    retainFailedGate() { return nil; }
    executing = nil
    definition() { return [self.id,self.episode,self.seconds,self.healthGate,self.startedAt,self.completedAt]; }
    validateReceipt()
    {
        if (self.result == nil || !holds(self.episode.activities,self) || self.boundDefinition == nil)
            rpgExpandedReject('panic-crying-history');
        local facts = self.definition();
        if (facts.length() != self.boundDefinition.length()) rpgExpandedReject('panic-crying-binding');
        for (local index = 1; index <= facts.length(); index += 1)
            if (facts[index] != self.boundDefinition[index]) rpgExpandedReject('panic-crying-binding');
        if (self.boundOutcome == nil || self.result != self.boundOutcome[1] || self.result.status != self.boundOutcome[2]
            || self.result.allowed != self.boundOutcome[3] || self.result.reason != self.boundOutcome[4]
            || self.result.seconds != self.boundOutcome[5]) rpgExpandedReject('panic-activity-outcome-binding');
        if (self.healthGate.assess().status != 'reused') rpgExpandedReject('panic-activity-permission-history');
        return nil;
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.episode == nil || !self.episode.ofKind(RpgExpandedFearPanic))
            rpgExpandedReject('panic-crying-definition');
        local value = new RpgExpandedResult();
        if (self.result != nil)
        {
            self.validateReceipt(); self.episode.assess(); value.status = 'reused'; value.seconds = self.seconds;
            value.allowed = self.result.allowed; value.reason = self.result.reason; return value;
        }
        if (self.startedAt != nil || self.completedAt != nil || self.boundDefinition != nil || self.boundOutcome != nil) rpgExpandedReject('panic-crying-uncommitted-state');
        if (self.episode.startedAt == nil) { value.reason = 'panic-crying-episode-required'; return value; }
        self.episode.assess(); local profile = self.episode.context.profile;
        if (self.episode.completedAt != nil) { value.reason = 'panic-crying-ended'; return value; }
        if (self.episode.behaviorKind != self.behaviorKind()) { value.reason = 'panic-crying-behavior'; return value; }
        if (profile.dead || profile.unconscious || profile.stunned || profile.mentalStun)
        { value.reason = 'panic-crying-incapacitated'; return value; }
        rpgInteger(self.seconds,1,360);
        if (rpgLedger.seconds + self.seconds > self.episode.nextCheckAt)
        { value.reason = 'panic-crying-recovery-boundary'; return value; }
        if (self.healthGate == nil || !self.healthGate.ofKind(RpgExpandedActionGate)
            || self.healthGate.profile != profile || self.healthGate.purpose != self.gatePurpose()) rpgExpandedReject('panic-crying-health-gate');
        if (self.healthGate.result != nil) { value.reason = 'panic-crying-health-gate-used'; return value; }
        foreach (local prior in self.episode.activities)
            if (prior.id == self.id) rpgExpandedReject('panic-crying-duplicate');
        value.reason = self.activityReason(); if (value.reason != nil) return value;
        local gate = self.healthGate.assess();
        if (gate.status != 'ready') { value.reason = gate.reason; return value; }
        rpgLedger.validateAdvance(self.seconds); value.seconds = self.seconds; value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local facts = self.definition(); local start = rpgLedger.seconds;
        rpgSpendTime(self.seconds);
        local current = self.definition();
        for (local index = 1; index <= facts.length(); index += 1)
            if (facts[index] != current[index]) rpgExpandedReject('panic-crying-interrupted');
        self.episode.assess(); local profile = self.episode.context.profile;
        if (rpgLedger.seconds != start + self.seconds || self.episode.completedAt != nil
            || profile.dead || profile.unconscious || profile.stunned || profile.mentalStun)
            rpgExpandedReject('panic-crying-interrupted');
        self.executing = true;
        local gate = self.healthGate.apply();
        self.executing = nil;
        if (gate.status != 'resolved' || !gate.allowed && !self.retainFailedGate()) rpgExpandedReject('panic-crying-health-changed');
        if (gate.allowed)
        {
            if (self.activityReason() != nil) rpgExpandedReject('panic-activity-state-changed');
            self.commitActivity();
        }
        value.allowed = gate.allowed; value.reason = gate.reason;
        self.startedAt = start; self.completedAt = rpgLedger.seconds; self.boundDefinition = self.definition();
        self.episode.activities = self.episode.activities + [self]; self.episode.activityCount += 1;
        value.status = 'resolved'; self.result = value;
        self.boundOutcome = [value,value.status,value.allowed,value.reason,value.seconds]; return value;
    }
;

modify RpgExpandedProfile
    fearSeizureOutcomes = []
;
class RpgExpandedFearSeizureResult: RpgExpandedResult
    seizure = nil
    wound = nil
    healthBefore = nil
    healthAfter = nil
    healthLost = nil
    dropPlan = nil
;
/** B361 row 31 uses the ordinary B429 seizure and its single end-FP payment. */
class RpgExpandedFearSeizure: object
    id = nil
    context = nil
    approved = nil
    evidence = nil
    dropDestination = nil
    result = nil
    recordedAt = nil
    boundDefinition = nil
    boundOutcome = nil
    definition() { return [self.id,self.context,self.context.profile,self.approved,self.evidence,self.dropDestination,self.recordedAt]; }
    seizure(seconds)
    {
        local episode = new RpgExpandedSeizure(); episode.id = 'fear-seizure:' + self.id; episode.profile = self.context.profile;
        episode.durationSeconds = seconds; episode.approved = true; episode.evidence = self.evidence;
        episode.dropDestination = self.dropDestination; return episode;
    }
    wound(amount)
    {
        local wound = new RpgExpandedWound(); wound.id = 'fear-seizure:' + self.id; wound.profile = self.context.profile;
        wound.amount = amount; wound.dropDestination = self.dropDestination; return wound;
    }
    healthContext()
    { local context = new RpgLiteContext(); context.attribute = rpgHT; context.kind = 'fear-seizure-health'; return context; }
    assess()
    {
        if (self.id == nil || self.id == '' || self.context == nil || !self.context.ofKind(RpgExpandedFearContext))
            rpgExpandedReject('fear-seizure-definition');
        local value = new RpgExpandedFearSeizureResult(); local profile = self.context.profile;
        if (self.result != nil)
        {
            if (!holds(profile.fearSeizureOutcomes,self)) rpgExpandedReject('fear-seizure-history');
            local facts = self.definition();
            for (local index = 1; index <= facts.length(); index += 1)
                if (facts[index] != self.boundDefinition[index]) rpgExpandedReject('fear-seizure-binding');
            local saved = self.result;
            if (saved.seizure != self.boundOutcome[1] || saved.wound != self.boundOutcome[2]
                || saved.check != self.boundOutcome[3] || saved.check.roll != self.boundOutcome[4]
                || saved.check.score != self.boundOutcome[5] || saved.check.achieved != self.boundOutcome[6]
                || saved.check.critical != self.boundOutcome[7] || saved.healthBefore != self.boundOutcome[8]
                || saved.healthAfter != self.boundOutcome[9] || saved.healthLost != self.boundOutcome[10])
                rpgExpandedReject('fear-seizure-outcome-binding');
            saved.seizure.validateReceipt(); if (saved.wound != nil) saved.wound.assess();
            value.status = 'reused'; value.seizure = saved.seizure; value.wound = saved.wound; value.check = saved.check;
            value.healthBefore = saved.healthBefore; value.healthAfter = saved.healthAfter; value.healthLost = saved.healthLost; return value;
        }
        if (self.recordedAt != nil || self.boundDefinition != nil || self.boundOutcome != nil) rpgExpandedReject('fear-seizure-uncommitted-state');
        local scene = self.context.consequenceAssessment();
        if (scene.status != 'ready') { value.reason = scene.reason; return value; }
        if (scene.immune) { value.reason = 'fear-seizure-immune'; return value; }
        if (!self.approved || self.evidence == nil || self.evidence == '') { value.reason = 'fear-seizure-evidence'; return value; }
        if (profile.dead || profile.unconscious) { value.reason = 'fear-seizure-observer-unavailable'; return value; }
        if (profile.ht <= 1) { value.reason = 'fear-minimum-health-author-adjudication'; return value; }
        rpgInteger(profile.developmentRevision,0,2147483646);
        foreach (local prior in profile.fearSeizureOutcomes)
            if (prior.id == self.id) rpgExpandedReject('fear-seizure-duplicate');
        local episode = self.seizure(360).assess();
        if (episode.status != 'ready') { value.reason = episode.reason; return value; }
        value.dropPlan = profile.prepareKnockdownDrop(self.dropDestination);
        if (value.dropPlan != nil && value.dropPlan.status != 'ready') { value.reason = value.dropPlan.reason; return value; }
        for (local amount = 1; amount <= 6; amount += 1)
        {
            local injury = self.wound(amount).assess();
            if (injury.status != 'ready') { value.reason = injury.reason; return value; }
        }
        local score = rpgLiteScore(profile,self.healthContext());
        if (score == nil || score < 3) { value.reason = 'fear-seizure-health-author-adjudication'; return value; }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local profile = self.context.profile;
        value.seizure = self.seizure(rpgRandom.die() * 60);
        value.check = rpgLiteCheck(profile,self.healthContext()); value.healthBefore = profile.ht;
        local episode = value.seizure.apply();
        if (episode.status != 'resolved') rpgExpandedReject('fear-seizure-onset-changed');
        if (!value.check.achieved)
        {
            value.wound = self.wound(rpgRandom.die()); local injury = value.wound.apply();
            if (injury.status != 'resolved') rpgExpandedReject('fear-seizure-injury-changed');
        }
        if (value.dropPlan != nil && (value.wound == nil || value.wound.droppedEquipment == nil)) value.dropPlan.commit();
        profile.posture = 'lying';
        if (value.wound == nil || !value.wound.health.knockedDown) profile.onKnockdown();
        value.healthLost = value.check.critical == 'failure';
        if (value.healthLost) { profile.ht -= 1; profile.developmentRevision += 1; }
        value.healthAfter = profile.ht; self.recordedAt = profile.timeElapsed; self.boundDefinition = self.definition();
        self.boundOutcome = [value.seizure,value.wound,value.check,value.check.roll,value.check.score,value.check.achieved,
            value.check.critical,value.healthBefore,value.healthAfter,value.healthLost];
        profile.fearSeizureOutcomes = profile.fearSeizureOutcomes + [self]; value.status = 'resolved'; self.result = value; return value;
    }
;

modify RpgExpandedProfile
    fearComa = nil
    fearComaHistory = []
    unconsciousRecoveryApartFrom(owner) { return self.fearComa != nil && self.fearComa != owner || inherited(owner); }
    healthAttributeModifier(context)
    {
        local amount = inherited(context);
        foreach (local episode in self.fearComaHistory)
        {
            episode.assess();
            if (episode.recoveredAt != nil && rpgLedger.seconds < episode.recoveredAt + 21600
                && self.fearAftermathOverlapPolicy != 'worst') amount -= 2;
        }
        return amount;
    }
;
/** B361 rows 28/29. Higher trait-bearing rows require their own composition. */
class RpgExpandedFearComa: object
    id = nil
    context = nil
    tableTotal = 28
    approved = nil
    evidence = nil
    dropDestination = nil
    startedAt = nil
    nextCheckAt = nil
    recoveredAt = nil
    initialSeconds = nil
    boundDefinition = nil
    recoveries = []
    definition() { return [self.id,self.context,self.context.profile,self.tableTotal,self.approved,self.evidence,
        self.dropDestination,self.startedAt,self.initialSeconds,self.context.profile.fearAftermathOverlapPolicy,self.context.profile.fearAftermathOverlapEvidence]; }
    assess()
    {
        if (self.id == nil || self.id == '' || self.context == nil || !self.context.ofKind(RpgExpandedFearContext))
            rpgExpandedReject('fear-coma-definition');
        local value = new RpgExpandedFearFaintResult(); local profile = self.context.profile;
        if (self.startedAt != nil)
        {
            if (!holds(profile.fearComaHistory,self)) rpgExpandedReject('fear-coma-history');
            local facts = self.definition();
            for (local index = 1; index <= facts.length(); index += 1)
                if (facts[index] != self.boundDefinition[index]) rpgExpandedReject('fear-coma-binding');
            local due = self.startedAt + self.initialSeconds; local ended = nil; local ids = [];
            foreach (local recovery in self.recoveries)
            {
                if (recovery == nil || !recovery.ofKind(RpgExpandedFearComaRecovery) || recovery.episode != self)
                    rpgExpandedReject('fear-coma-recovery-owner');
                recovery.validateReceipt();
                if (ended != nil || recovery.recordedAt != due || holds(ids,recovery.id)) rpgExpandedReject('fear-coma-timeline');
                ids = ids + [recovery.id];
                if (recovery.result.check.achieved) ended = due;
                else due += recovery.delaySeconds;
            }
            if (self.nextCheckAt != due || self.recoveredAt != ended) rpgExpandedReject('fear-coma-timeline');
            if (ended == nil && profile.fearComa != self || ended != nil && profile.fearComa == self) rpgExpandedReject('fear-coma-owner');
            value.status = 'reused'; return value;
        }
        if (!holds([28,29],self.tableTotal)) rpgExpandedReject('fear-coma-row');
        if (self.nextCheckAt != nil || self.recoveredAt != nil || self.initialSeconds != nil || self.boundDefinition != nil
            || self.recoveries.length() != 0) rpgExpandedReject('fear-coma-uncommitted-state');
        if (profile.fearAftermathActive() && !profile.fearAftermathOverlapConfigured())
        { value.reason = 'fear-aftermath-policy-required'; return value; }
        profile.fearAftermathOverlapConfigured();
        local scene = self.context.consequenceAssessment();
        if (scene.status != 'ready') { value.reason = scene.reason; return value; }
        if (scene.immune) { value.reason = 'fear-coma-immune'; return value; }
        if (!self.approved || self.evidence == nil || self.evidence == '') { value.reason = 'fear-coma-evidence'; return value; }
        if (profile.dead || profile.unconscious || profile.mortal || profile.hp() <= 0 || profile.fp() <= 0
            || profile.unconsciousRecoveryOwned() || profile.fearSeconds > 0)
        { value.reason = 'fear-coma-existing-condition'; return value; }
        foreach (local prior in profile.fearComaHistory)
        {
            prior.assess(); if (prior.id == self.id) rpgExpandedReject('fear-coma-duplicate');
            if (prior.recoveredAt == nil) { value.reason = 'fear-coma-active-episode'; return value; }
            if (rpgLedger.seconds < prior.recoveredAt + 21600 && !profile.fearAftermathOverlapConfigured())
            { value.reason = 'fear-aftermath-policy-required'; return value; }
        }
        value.dropPlan = profile.prepareKnockdownDrop(self.dropDestination);
        if (value.dropPlan != nil && value.dropPlan.status != 'ready') { value.reason = value.dropPlan.reason; return value; }
        rpgInteger(rpgLedger.seconds,0,2147462047); value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.initialSeconds = self.tableTotal == 28 ? 1800 : rpgRandom.die() * 3600;
        self.startedAt = rpgLedger.seconds; self.nextCheckAt = self.startedAt + self.initialSeconds;
        self.boundDefinition = self.definition(); local profile = self.context.profile;
        if (value.dropPlan != nil) value.dropPlan.commit();
        profile.fearComa = self; profile.fearComaHistory = profile.fearComaHistory + [self];
        profile.posture = 'lying'; profile.onKnockdown(); profile.becomeUnconscious();
        value.status = 'resolved'; return value;
    }
;
class RpgExpandedFearComaRecovery: object
    recoveryDecision = nil
    id = nil
    episode = nil
    result = nil
    recordedAt = nil
    delaySeconds = nil
    boundDefinition = nil
    boundCheck = nil
    definition() { return [self.id,self.episode,self.recordedAt,self.delaySeconds]; }
    validateReceipt()
    {
        if (self.result != nil && self.result.check != nil && self.result.check.ofKind(RpgExpandedAuthoredRecoveryResult))
        {
            if (self.recoveryDecision != self.result.check.decision) rpgExpandedReject('fear-recovery-ruling-changed');
            self.result.check.validate(self);
        }
        else if (self.result != nil && self.recoveryDecision != nil) rpgExpandedReject('fear-recovery-ruling-added');
        if (self.result == nil || !holds(self.episode.recoveries,self)) rpgExpandedReject('fear-coma-recovery-history');
        local facts = self.definition();
        for (local index = 1; index <= facts.length(); index += 1)
            if (facts[index] != self.boundDefinition[index]) rpgExpandedReject('fear-coma-recovery-binding');
        local check = self.result.check;
        if (check == nil || check != self.boundCheck[1] || check.score != self.boundCheck[2] || check.roll != self.boundCheck[3]
            || check.achieved != self.boundCheck[4] || check.margin != self.boundCheck[5] || check.critical != self.boundCheck[6])
            rpgExpandedReject('fear-coma-recovery-check-binding');
        return nil;
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.episode == nil || !self.episode.ofKind(RpgExpandedFearComa))
            rpgExpandedReject('fear-coma-recovery-definition');
        local value = new RpgExpandedResult();
        if (self.result != nil)
        {
            if (self.result.check != nil && self.result.check.ofKind(RpgExpandedAuthoredRecoveryResult))
            {
                if (self.recoveryDecision != self.result.check.decision) rpgExpandedReject('fear-recovery-ruling-changed');
                self.result.check.validate(self);
            }
            else if (self.recoveryDecision != nil) rpgExpandedReject('fear-recovery-ruling-added');
            self.validateReceipt();
            self.episode.assess(); value.status = 'reused'; value.check = self.result.check; return value;
        }
        if (self.recordedAt != nil || self.delaySeconds != nil || self.boundDefinition != nil || self.boundCheck != nil)
            rpgExpandedReject('fear-coma-recovery-uncommitted-state');
        if (self.episode.startedAt == nil) { value.reason = 'fear-coma-episode-required'; return value; }
        self.episode.assess(); local profile = self.episode.context.profile;
        if (self.episode.recoveredAt != nil) { value.reason = 'fear-coma-ended'; return value; }
        if (profile.dead) { value.reason = 'fear-coma-dead'; return value; }
        if (!profile.unconscious || profile.fearComa != self.episode) rpgExpandedReject('fear-coma-recovery-owner');
        if (rpgLedger.seconds != self.episode.nextCheckAt) { value.reason = 'fear-coma-recovery-not-due'; return value; }
        foreach (local prior in self.episode.recoveries)
            if (prior.id == self.id) rpgExpandedReject('fear-coma-recovery-duplicate');
        local context = new RpgLiteContext(); context.attribute = rpgHT; context.kind = 'fear-coma-recovery';
        local score = rpgLiteScore(profile,context);
        value.reason = rpgExpandedFearRecoveryReason(self,score); if (value.reason != nil) return value;
        rpgInteger(rpgLedger.seconds,0,2147462047); value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local profile = self.episode.context.profile;
        local context = new RpgLiteContext(); context.attribute = rpgHT; context.kind = 'fear-coma-recovery';
        value.check = rpgExpandedFearRecoveryCheck(self,profile,context); self.recordedAt = rpgLedger.seconds;
        self.delaySeconds = value.check.achieved ? 0 : self.episode.tableTotal == 28 ? 1800 : rpgRandom.die() * 3600;
        if (value.check.achieved)
        {
            profile.fearComa = nil; self.episode.recoveredAt = self.recordedAt;
            if (!profile.unconsciousRecoveryApartFrom(self.episode) && !profile.dead && !profile.mortal && profile.hp() > 0 && profile.fp() > 0
                && profile.cardiacArrest == nil && profile.fearSeconds == 0 && !profile.apparentDeath && !profile.needsMedicalHelp)
            { profile.unconscious = nil; profile.unconsciousClock = 0; }
        }
        else self.episode.nextCheckAt = self.recordedAt + self.delaySeconds;
        self.boundCheck = [value.check,value.check.score,value.check.roll,value.check.achieved,value.check.margin,value.check.critical];
        self.boundDefinition = self.definition(); self.episode.recoveries = self.episode.recoveries + [self];
        value.status = 'resolved'; self.result = value; return value;
    }
;
modify rpgLedger
    validateAdvance(seconds)
    {
        inherited(seconds);
        for (local episode = firstObj(RpgExpandedFearComa); episode != nil; episode = nextObj(episode,RpgExpandedFearComa))
            if (episode.startedAt != nil)
            {
                episode.assess();
                if (episode.recoveredAt == nil && !episode.context.profile.dead && self.seconds + seconds > episode.nextCheckAt)
                    rpgExpandedReject('fear-coma-recovery-boundary');
            }
        return nil;
    }
;

modify RpgExpandedProfile
    catatonia = nil
    catatoniaHistory = []
    healthEffortReasonFor(purpose,mentalAbility,speech,movement,authorization)
    {
        if (self.catatonia != nil && !holds(['rest','do-nothing'],purpose)) return 'catatonia-action-unavailable';
        return inherited(purpose,mentalAbility,speech,movement,authorization);
    }
    healthManeuverReasonFor(kind,request)
    { return self.catatonia != nil && kind != 'nothing' ? 'catatonia-do-nothing-required' : inherited(kind,request); }
    healthAttributeModifier(context)
    {
        local amount = inherited(context);
        foreach (local episode in self.catatoniaHistory)
        {
            episode.assess();
            if (episode.recoveredAt != nil && rpgLedger.seconds < episode.recoveredAt + (episode.recoveredAt - episode.startedAt)
                && self.fearAftermathOverlapPolicy != 'worst') amount -= 2;
        }
        return amount;
    }
;
/** B361 row 30: daily care receipts are separate from recovery checks. */
class RpgExpandedCatatonia: object
    id = nil
    context = nil
    approved = nil
    evidence = nil
    careMode = nil
    neglectPolicy = nil
    neglectEvidence = nil
    dropDestination = nil
    startedAt = nil
    nextCheckAt = nil
    initialSeconds = nil
    recoveredAt = nil
    boundDefinition = nil
    days = []
    recoveries = []
    definition() { return [self.id,self.context,self.context.profile,self.approved,self.evidence,self.careMode,self.neglectPolicy,self.neglectEvidence,
        self.dropDestination,self.startedAt,self.initialSeconds,self.context.profile.fearAftermathOverlapPolicy,self.context.profile.fearAftermathOverlapEvidence]; }
    nextDayAt() { return self.startedAt + (self.days.length() + 1) * 86400; }
    assess()
    {
        if (self.id == nil || self.id == '' || self.context == nil || !self.context.ofKind(RpgExpandedFearContext))
            rpgExpandedReject('catatonia-definition');
        local value = new RpgExpandedResult(); local profile = self.context.profile;
        if (self.startedAt != nil)
        {
            if (!holds(profile.catatoniaHistory,self)) rpgExpandedReject('catatonia-history');
            local facts = self.definition();
            for (local index = 1; index <= facts.length(); index += 1)
                if (facts[index] != self.boundDefinition[index]) rpgExpandedReject('catatonia-binding');
            local dayIndex = 0; local dayIds = [];
            foreach (local care in self.days)
            {
                dayIndex += 1;
                if (care == nil || !care.ofKind(RpgExpandedCatatoniaDay) || care.episode != self
                    || holds(dayIds,care.id)) rpgExpandedReject('catatonia-day-owner');
                care.assess(); dayIds = dayIds + [care.id];
                if (care.day != dayIndex || care.recordedAt != self.startedAt + dayIndex * 86400
                    || care.recordedAt > rpgLedger.seconds) rpgExpandedReject('catatonia-day-timeline');
            }
            local due = self.startedAt + self.initialSeconds; local ended = nil; local ids = [];
            foreach (local recovery in self.recoveries)
            {
                if (recovery == nil || !recovery.ofKind(RpgExpandedCatatoniaRecovery) || recovery.episode != self
                    || holds(ids,recovery.id)) rpgExpandedReject('catatonia-recovery-owner');
                recovery.assess(); ids = ids + [recovery.id];
                if (ended != nil || recovery.recordedAt != due || recovery.recordedAt > rpgLedger.seconds)
                    rpgExpandedReject('catatonia-recovery-timeline');
                if (recovery.result.check.achieved) ended = due;
                else due += recovery.delaySeconds;
            }
            if (self.nextCheckAt != due || self.recoveredAt != ended
                || ended != nil && self.days.length() != (ended - self.startedAt) / 86400)
                rpgExpandedReject('catatonia-timeline');
            if (ended == nil && profile.catatonia != self || ended != nil && profile.catatonia == self)
                rpgExpandedReject('catatonia-owner');
            value.status = 'reused'; return value;
        }
        if (self.nextCheckAt != nil || self.initialSeconds != nil || self.recoveredAt != nil || self.boundDefinition != nil
            || self.days.length() != 0 || self.recoveries.length() != 0) rpgExpandedReject('catatonia-uncommitted-state');
        if (profile.fearAftermathActive() && !profile.fearAftermathOverlapConfigured())
        { value.reason = 'fear-aftermath-policy-required'; return value; }
        profile.fearAftermathOverlapConfigured();
        local scene = self.context.consequenceAssessment();
        if (scene.status != 'ready') { value.reason = scene.reason; return value; }
        if (scene.immune) { value.reason = 'catatonia-immune'; return value; }
        if (!self.approved || self.evidence == nil || self.evidence == '') { value.reason = 'catatonia-author-facts'; return value; }
        if (!holds(['continuous','none','daily'],self.careMode)) rpgExpandedReject('catatonia-care-mode');
        if (self.careMode == 'daily')
        {
            if (!holds(['elapsed-days','uncared-days'],self.neglectPolicy) || self.neglectEvidence == nil || self.neglectEvidence == '')
            { value.reason = 'catatonia-neglect-ruling-required'; return value; }
        }
        else if (self.neglectPolicy != nil || self.neglectEvidence != nil) rpgExpandedReject('catatonia-unused-neglect-ruling');
        if (profile.dead || profile.unconscious || profile.catatonia != nil) { value.reason = 'catatonia-existing-condition'; return value; }
        foreach (local prior in profile.catatoniaHistory)
        {
            prior.assess(); if (prior.id == self.id) rpgExpandedReject('catatonia-duplicate');
            if (prior.recoveredAt == nil) { value.reason = 'catatonia-active-episode'; return value; }
            if (rpgLedger.seconds < prior.recoveredAt + (prior.recoveredAt - prior.startedAt) && !profile.fearAftermathOverlapConfigured())
            { value.reason = 'fear-aftermath-policy-required'; return value; }
        }
        rpgInteger(rpgLedger.seconds,0,2146446847); value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.initialSeconds = rpgRandom.die() * 86400; self.startedAt = rpgLedger.seconds;
        self.nextCheckAt = self.startedAt + self.initialSeconds; self.boundDefinition = self.definition();
        local profile = self.context.profile; profile.catatonia = self; profile.catatoniaHistory = profile.catatoniaHistory + [self];
        value.status = 'resolved'; return value;
    }
;
class RpgExpandedCatatoniaDay: object
    id = nil
    episode = nil
    careProvided = nil
    approved = nil
    evidence = nil
    result = nil
    day = nil
    recordedAt = nil
    wound = nil
    boundDefinition = nil
    definition() { return [self.id,self.episode,self.careProvided,self.approved,self.evidence,self.day,self.recordedAt,self.wound]; }
    assess()
    {
        if (self.id == nil || self.id == '' || self.episode == nil || !self.episode.ofKind(RpgExpandedCatatonia))
            rpgExpandedReject('catatonia-day-definition');
        local value = new RpgExpandedResult();
        if (self.result != nil)
        {
            if (!holds(self.episode.days,self)) rpgExpandedReject('catatonia-day-history');
            local facts = self.definition();
            for (local index = 1; index <= facts.length(); index += 1)
                if (facts[index] != self.boundDefinition[index]) rpgExpandedReject('catatonia-day-binding');
            if (self.wound != nil) self.wound.assess(); value.status = 'reused'; return value;
        }
        if (self.day != nil || self.recordedAt != nil || self.wound != nil || self.boundDefinition != nil)
            rpgExpandedReject('catatonia-day-uncommitted-state');
        if (self.episode.startedAt == nil) { value.reason = 'catatonia-episode-required'; return value; }
        self.episode.assess(); local profile = self.episode.context.profile;
        if (profile.dead || self.episode.recoveredAt != nil) { value.reason = 'catatonia-day-ended'; return value; }
        if (rpgLedger.seconds != self.episode.nextDayAt()) { value.reason = 'catatonia-day-not-due'; return value; }
        if (!self.approved || self.evidence == nil || self.evidence == '') { value.reason = 'catatonia-day-care-evidence'; return value; }
        if (self.episode.careMode != 'daily' && (self.episode.careMode == 'continuous') != self.careProvided)
        { value.reason = 'catatonia-care-mode-mismatch'; return value; }
        foreach (local prior in self.episode.days) if (prior.id == self.id) rpgExpandedReject('catatonia-day-duplicate');
        if (!self.careProvided)
        {
            local wound = new RpgExpandedWound(); wound.id = 'catatonia:' + self.id; wound.profile = profile;
            wound.amount = self.episode.nextNeglectInjury(); wound.dropDestination = self.episode.dropDestination;
            local injury = wound.assess(); if (injury.status != 'ready') { value.reason = injury.reason; return value; }
        }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.day = self.episode.days.length() + 1;
        if (!self.careProvided)
        {
            self.wound = new RpgExpandedWound(); self.wound.id = 'catatonia:' + self.id;
            self.wound.profile = self.episode.context.profile; self.wound.amount = self.episode.nextNeglectInjury(); self.wound.dropDestination = self.episode.dropDestination;
            local injury = self.wound.apply(); if (injury.status != 'resolved') rpgExpandedReject('catatonia-day-injury-changed');
        }
        self.recordedAt = rpgLedger.seconds; self.boundDefinition = self.definition();
        self.episode.days = self.episode.days + [self]; value.status = 'resolved'; self.result = value; return value;
    }
;
class RpgExpandedCatatoniaRecovery: object
    recoveryDecision = nil
    id = nil
    episode = nil
    result = nil
    recordedAt = nil
    delaySeconds = nil
    boundDefinition = nil
    boundCheck = nil
    definition() { return [self.id,self.episode,self.recordedAt,self.delaySeconds]; }
    assess()
    {
        if (self.id == nil || self.id == '' || self.episode == nil || !self.episode.ofKind(RpgExpandedCatatonia))
            rpgExpandedReject('catatonia-recovery-definition');
        local value = new RpgExpandedResult();
        if (self.result != nil)
        {
            if (self.result.check != nil && self.result.check.ofKind(RpgExpandedAuthoredRecoveryResult))
            {
                if (self.recoveryDecision != self.result.check.decision) rpgExpandedReject('fear-recovery-ruling-changed');
                self.result.check.validate(self);
            }
            else if (self.recoveryDecision != nil) rpgExpandedReject('fear-recovery-ruling-added');
            if (!holds(self.episode.recoveries,self)) rpgExpandedReject('catatonia-recovery-history');
            local facts = self.definition();
            for (local index = 1; index <= facts.length(); index += 1)
                if (facts[index] != self.boundDefinition[index]) rpgExpandedReject('catatonia-recovery-binding');
            local check = self.result.check;
            if (check == nil || check != self.boundCheck[1] || check.score != self.boundCheck[2] || check.roll != self.boundCheck[3]
                || check.achieved != self.boundCheck[4] || check.critical != self.boundCheck[5])
                rpgExpandedReject('catatonia-recovery-check-binding');
            value.status = 'reused'; value.check = self.result.check; return value;
        }
        if (self.recordedAt != nil || self.delaySeconds != nil || self.boundDefinition != nil || self.boundCheck != nil)
            rpgExpandedReject('catatonia-recovery-uncommitted-state');
        if (self.episode.startedAt == nil) { value.reason = 'catatonia-episode-required'; return value; }
        self.episode.assess(); local profile = self.episode.context.profile;
        if (self.episode.recoveredAt != nil) { value.reason = 'catatonia-ended'; return value; }
        if (profile.dead) { value.reason = 'catatonia-recovery-dead'; return value; }
        if (rpgLedger.seconds != self.episode.nextCheckAt) { value.reason = 'catatonia-recovery-not-due'; return value; }
        if (self.episode.nextDayAt() <= rpgLedger.seconds) { value.reason = 'catatonia-day-required'; return value; }
        foreach (local prior in self.episode.recoveries) if (prior.id == self.id) rpgExpandedReject('catatonia-recovery-duplicate');
        local context = new RpgLiteContext(); context.attribute = rpgHT; context.kind = 'catatonia-recovery';
        local score = rpgLiteScore(profile,context);
        value.reason = rpgExpandedFearRecoveryReason(self,score); if (value.reason != nil) return value;
        rpgInteger(rpgLedger.seconds,0,2146446847);
        if (rpgLedger.seconds - self.episode.startedAt > 2147483647 - rpgLedger.seconds)
        { value.reason = 'catatonia-aftermath-clock'; return value; }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local profile = self.episode.context.profile;
        local context = new RpgLiteContext(); context.attribute = rpgHT; context.kind = 'catatonia-recovery';
        value.check = rpgExpandedFearRecoveryCheck(self,profile,context); self.recordedAt = rpgLedger.seconds;
        self.delaySeconds = value.check.achieved ? 0 : rpgRandom.die() * 86400;
        if (value.check.achieved) { self.episode.recoveredAt = self.recordedAt; profile.catatonia = nil; }
        else self.episode.nextCheckAt = self.recordedAt + self.delaySeconds;
        self.boundCheck = [value.check,value.check.score,value.check.roll,value.check.achieved,value.check.critical];
        self.boundDefinition = self.definition(); self.episode.recoveries = self.episode.recoveries + [self];
        value.status = 'resolved'; self.result = value; return value;
    }
;
modify rpgLedger
    validateAdvance(seconds)
    {
        inherited(seconds);
        for (local episode = firstObj(RpgExpandedCatatonia); episode != nil; episode = nextObj(episode,RpgExpandedCatatonia))
            if (episode.startedAt != nil && episode.recoveredAt == nil && !episode.context.profile.dead)
            {
                episode.assess();
                if (self.seconds + seconds > episode.nextDayAt() || self.seconds + seconds > episode.nextCheckAt)
                    rpgExpandedReject('catatonia-due-boundary');
            }
        return nil;
    }
;


/** B426 injury accompanying fatigue loss during exhausted swimming. */
modify RpgExpandedProfile
    prepareSwimmingWound(id,destination)
    {
        local wound = new RpgExpandedWound(); wound.id = id; wound.profile = self;
        wound.amount = 1; wound.dropDestination = destination; return wound;
    }
;

class RpgExpandedDiagnosisResult: RpgExpandedResult
    context = nil
    score = nil
    finding = nil
    findingKind = nil
;

/** B187 a bounded authored finding; diagnosis never grants treatment or HP. */
class RpgExpandedDiagnosis: object
    id = nil
    caseId = nil
    examiner = nil
    patient = nil
    skill = nil
    obvious = nil
    internalInjury = nil
    rarityModifier = 0
    equipmentModifier = 0
    equipmentAssessment = nil
    physiology = 'same'
    speciesModifier = 0
    subjectSpecies = nil
    physiologyCheck = nil
    finding = nil
    findingKind = 'hint'
    approved = nil
    evidence = nil
    result = nil
    boundDefinition = nil
    boundFinding = nil
    boundFindingKind = nil
    definition()
    {
        local facts = [self.id,self.caseId,self.examiner,self.patient,self.skill,self.obvious,self.internalInjury,
            self.rarityModifier,self.equipmentModifier,self.physiology,self.speciesModifier,self.subjectSpecies,
            self.physiologyCheck,self.finding,self.findingKind,self.approved,self.evidence,self.equipmentAssessment];
        return self.equipmentAssessment == nil ? facts : facts + rpgExpandedDiagnosticEquipment.definition(self.equipmentAssessment);
    }
    validateReceipt()
    {
        if (self.result == nil || self.boundDefinition == nil || !holds(self.examiner.diagnoses,self))
            rpgExpandedReject('diagnosis-history');
        local facts = self.definition();
        for (local i = 1; i <= facts.length(); i += 1)
            if (facts[i] != self.boundDefinition[i]) rpgExpandedReject('diagnosis-binding');
        if (self.result.finding != self.boundFinding || self.result.findingKind != self.boundFindingKind)
            rpgExpandedReject('diagnosis-history');
        return nil;
    }
    assess()
    {
        local value = new RpgExpandedDiagnosisResult();
        if (self.result != nil)
        {
            self.validateReceipt();
            value.status = 'reused'; return value;
        }
        if (self.id == nil || self.id == '' || self.caseId == nil || self.caseId == ''
            || self.examiner == nil || !self.examiner.ofKind(RpgExpandedProfile)
            || self.patient == nil || !self.patient.ofKind(RpgLiteProfile)) rpgExpandedReject('diagnosis-definition');
        if (!self.approved || self.evidence == nil || self.evidence == '' || self.finding == nil || self.finding == '')
        { value.reason = 'diagnosis-authored-finding-required'; return value; }
        if (!holds(['hint','diagnosis'],self.findingKind)) rpgExpandedReject('diagnosis-finding-kind');
        if (self.examiner.dead || self.examiner.unconscious || self.examiner.stunned || self.examiner.mentalStun)
        { value.reason = 'diagnosis-examiner-unavailable'; return value; }
        foreach (local prior in self.examiner.diagnoses)
            if (prior.id == self.id || prior.patient == self.patient && prior.caseId == self.caseId)
                rpgExpandedReject('diagnosis-repeat-case');
        if (!holds(['same','similar','different','alien','machine'],self.physiology)) rpgExpandedReject('diagnosis-physiology');
        if (self.physiology == 'machine') { value.reason = 'diagnosis-machine-inapplicable'; return value; }
        if (self.obvious)
        {
            if (self.equipmentAssessment != nil) rpgExpandedReject('diagnosis-obvious-equipment-inapplicable');
            value.status = 'ready'; return value;
        }
        if (self.skill == nil || !self.skill.ofKind(RpgLiteSkill)) rpgExpandedReject('diagnosis-skill');
        self.skill.validateDiagnosis();
        rpgInteger(self.equipmentModifier,-100,100); rpgInteger(self.rarityModifier,-100,0); rpgInteger(self.speciesModifier,-100,0);
        if (self.rarityModifier != 0 && self.rarityModifier > -5) rpgExpandedReject('diagnosis-rarity');
        if (self.physiology == 'same' && self.speciesModifier != 0
            || self.physiology == 'similar' && !holds([-2,-3,-4],self.speciesModifier)
            || self.physiology == 'different' && self.speciesModifier != -5
            || self.physiology == 'alien' && self.speciesModifier > -6) rpgExpandedReject('diagnosis-species-modifier');
        local species = self.speciesModifier;
        if (self.physiologyCheck != nil)
        {
            local check = self.physiologyCheck;
            if (!check.ofKind(RpgExpandedPhysiologyReceipt) || check.operation != self || check.profile != self.examiner
                || check.subject != self.patient || self.subjectSpecies == nil || check.species != self.subjectSpecies)
                rpgExpandedReject('diagnosis-physiology-check-binding');
            if (check.result == nil) { value.reason = 'diagnosis-physiology-check-unresolved'; return value; }
            check.validateReceipt(); if (check.result.check.achieved) species = 0;
        }
        local equipment = self.equipmentModifier; local equipmentTL = nil;
        if (self.equipmentAssessment != nil)
        {
            if (self.equipmentModifier != 0) rpgExpandedReject('diagnosis-equipment-double-modifier');
            local tools = rpgExpandedDiagnosticEquipment.assess(self.equipmentAssessment,self.examiner,self.skill);
            if (tools.status != 'ready') { value.reason = tools.reason; return value; }
            equipment = tools.modifier; equipmentTL = tools.equipmentTL;
        }
        value.context = self.skill.diagnosisContext(equipmentTL);
        value.context.modifier = equipment + self.rarityModifier + species + (self.internalInjury ? -5 : 0);
        local unavailable = value.context.taskUnavailableReason(self.examiner);
        if (unavailable != nil) { value.reason = unavailable; return value; }
        value.score = rpgLiteScore(self.examiner,value.context);
        if (value.score == nil || value.score < 3) { value.reason = 'diagnosis-score-unavailable'; return value; }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        if (!self.obvious) value.check = rpgLiteCheck(self.examiner,value.context);
        if (self.obvious || value.check.achieved) { value.finding = self.finding; value.findingKind = self.findingKind; }
        self.boundDefinition = self.definition(); self.boundFinding = value.finding; self.boundFindingKind = value.findingKind;
        value.status = 'resolved'; self.result = value; self.examiner.diagnoses = self.examiner.diagnoses + [self]; return value;
    }
;
modify RpgExpandedProfile
    diagnoses = []
;

/** Authored communication contract: a specific diagnostic finding was understood. */
class RpgExpandedDiagnosticConsultation: object
    id = nil
    diagnosis = nil
    recipient = nil
    received = nil
    understood = nil
    evidence = nil
    completedAt = nil
    boundCompletedAt = nil
    boundDefinition = nil
    boundFinding = nil
    boundKind = nil
    definition() { return [self.id,self.diagnosis,self.recipient,self.received,self.understood,self.evidence]; }
    validateReceipt()
    {
        if (self.completedAt == nil || self.completedAt != self.boundCompletedAt || self.completedAt > rpgLedger.seconds
            || !holds(self.recipient.diagnosticConsultations,self)) rpgExpandedReject('diagnostic-consultation-history');
        local facts = self.definition();
        for (local i = 1; i <= facts.length(); i += 1)
            if (facts[i] != self.boundDefinition[i]) rpgExpandedReject('diagnostic-consultation-binding');
        self.diagnosis.validateReceipt();
        if (self.diagnosis.result.finding != self.boundFinding || self.diagnosis.result.findingKind != self.boundKind)
            rpgExpandedReject('diagnostic-consultation-finding-binding');
        return nil;
    }
    assess()
    {
        local value = new RpgExpandedDiagnosisResult();
        if (self.completedAt != nil) { self.validateReceipt(); value.status = 'reused'; return value; }
        if (self.id == nil || self.id == '' || self.diagnosis == nil || !self.diagnosis.ofKind(RpgExpandedDiagnosis)
            || self.recipient == nil || !self.recipient.ofKind(RpgExpandedProfile)) rpgExpandedReject('diagnostic-consultation-definition');
        if (self.diagnosis.result == nil) { value.reason = 'diagnostic-consultation-unresolved'; return value; }
        self.diagnosis.validateReceipt();
        if (!self.received || !self.understood || self.evidence == nil || self.evidence == '')
        { value.reason = 'diagnostic-consultation-communication-required'; return value; }
        if (self.recipient.dead || self.recipient.unconscious)
        { value.reason = 'diagnostic-consultation-recipient-unavailable'; return value; }
        if (self.diagnosis.result.finding == nil) { value.reason = 'diagnostic-consultation-no-finding'; return value; }
        foreach (local prior in self.recipient.diagnosticConsultations)
            if (prior.id == self.id || prior.diagnosis == self.diagnosis) rpgExpandedReject('diagnostic-consultation-duplicate');
        value.status = 'ready'; return value;
    }
    deliver()
    {
        local value = self.assess();
        if (value.status == 'reused') { value.finding = self.boundFinding; value.findingKind = self.boundKind; return value; }
        if (value.status != 'ready') return value;
        self.boundDefinition = self.definition(); self.boundFinding = self.diagnosis.result.finding; self.boundKind = self.diagnosis.result.findingKind;
        self.completedAt = rpgLedger.seconds; self.boundCompletedAt = self.completedAt;
        self.recipient.diagnosticConsultations = self.recipient.diagnosticConsultations + [self];
        value.finding = self.boundFinding; value.findingKind = self.boundKind; value.status = 'resolved'; return value;
    }
;
modify RpgExpandedProfile
    diagnosticConsultations = []
;

/** B426: concurrent marching participants share one elapsed hour. */
class RpgExpandedMarchGroupResult: RpgExpandedResult
    allowed = nil
    members = []
;
class RpgExpandedMarchGroup: object
    id = nil
    hours = []
    result = nil
    startedAt = nil
    completedAt = nil
    boundAllowed = nil
    boundSeconds = nil
    boundDefinition = nil
    definition()
    {
        local facts = [self.id,self.hours.length()];
        foreach (local hour in self.hours) facts = facts + [hour] + hour.definition();
        return facts;
    }
    assess()
    {
        local value = new RpgExpandedMarchGroupResult();
        if (self.id == nil || self.id == '' || self.hours.length() == 0) rpgExpandedReject('march-group-definition');
        local profiles = []; local interval = nil;
        foreach (local hour in self.hours)
        {
            if (hour == nil || !hour.ofKind(RpgExpandedMarchHour) || holds(profiles,hour.profile))
                rpgExpandedReject('march-group-member');
            if (interval != nil && hour.interval != interval) rpgExpandedReject('march-group-interval');
            interval = hour.interval; profiles = profiles + [hour.profile];
        }
        if (self.result != nil)
        {
            if (self.result.members.length() != self.hours.length() || self.result.allowed != self.boundAllowed
                || self.result.seconds != self.boundSeconds || self.completedAt != self.startedAt + self.boundSeconds
                || self.completedAt > rpgLedger.seconds) rpgExpandedReject('march-group-result-binding');
            local facts = self.definition();
            if (self.boundDefinition == nil || facts.length() != self.boundDefinition.length()) rpgExpandedReject('march-group-binding');
            for (local i = 1; i <= facts.length(); i += 1)
                if (facts[i] != self.boundDefinition[i]) rpgExpandedReject('march-group-binding');
            for (local i = 1; i <= self.hours.length(); i += 1)
            {
                local hour = self.hours[i];
                if (!holds(hour.profile.marchGroups,self) || hour.result.allowed != self.boundAllowed
                    || hour.result.seconds != self.boundSeconds || hour.result != self.result.members[i] || hour.assess().status != 'reused'
                    || hour.startedAt != self.startedAt || hour.completedAt != self.completedAt)
                    rpgExpandedReject('march-group-history');
            }
            value.status = 'reused'; return value;
        }
        foreach (local hour in self.hours)
        {
            foreach (local prior in hour.profile.marchGroups)
                if (prior.id == self.id) rpgExpandedReject('march-group-duplicate');
            if (hour.result != nil) rpgExpandedReject('march-group-used-member');
            local prepared = hour.assess();
            if (prepared.status != 'ready') { value.reason = prepared.reason; return value; }
            value.members = value.members + [prepared];
        }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status == 'reused') return self.result;
        if (value.status != 'ready') return value;
        local facts = self.definition(); local start = rpgLedger.seconds; local states = []; value.allowed = true;
        foreach (local prepared in value.members)
        {
            local permission = prepared.gate.apply();
            if (permission.status != 'resolved') rpgExpandedReject('march-group-gate-changed');
            if (!permission.allowed) { value.allowed = nil; value.reason = 'march-group-member-denied'; }
        }
        if (value.allowed)
        {
            for (local i = 1; i <= self.hours.length(); i += 1)
            {
                local profile = self.hours[i].profile; local before = value.members[i].cost.assess();
                if (before.status != 'ready') rpgExpandedReject('march-group-cost-changed');
                states = states + [[profile.move(),profile.hp(),profile.fp(),before.fatigueCost]]; profile.restClock = 0;
            }
            rpgSpendTime(3600);
            local current = self.definition();
            if (current.length() != facts.length()) rpgExpandedReject('march-group-interrupted');
            for (local i = 1; i <= facts.length(); i += 1)
                if (current[i] != facts[i]) rpgExpandedReject('march-group-interrupted');
            for (local i = 1; i <= self.hours.length(); i += 1)
            {
                local profile = self.hours[i].profile; local prepared = value.members[i]; local after = prepared.cost.assess();
                if (rpgLedger.seconds != start + 3600 || after.status != 'ready'
                    || after.fatigueCost != states[i][4] || profile.move() != states[i][1]
                    || profile.hp() != states[i][2] || profile.fp() != states[i][3] || profile.hp() <= 0
                    || profile.dead || profile.unconscious || profile.stunned || profile.mentalStun
                    || profile.healthEffortReason('action',nil,nil,true) != nil)
                    rpgExpandedReject('march-group-conditions-changed');
            }
            foreach (local prepared in value.members)
                if (prepared.cost.apply().status != 'resolved') rpgExpandedReject('march-group-cost-changed');
            value.seconds = 3600;
        }
        local finalFacts = self.definition();
        if (finalFacts.length() != facts.length()) rpgExpandedReject('march-group-interrupted');
        for (local i = 1; i <= facts.length(); i += 1)
            if (finalFacts[i] != facts[i]) rpgExpandedReject('march-group-interrupted');
        for (local i = 1; i <= self.hours.length(); i += 1)
        {
            local hour = self.hours[i]; local prepared = value.members[i];
            prepared.allowed = value.allowed; prepared.reason = value.reason; prepared.seconds = value.seconds; prepared.status = 'resolved';
            hour.startedAt = start; hour.completedAt = rpgLedger.seconds; hour.boundDefinition = hour.definition(); hour.result = prepared;
            hour.profile.marchExecutions = hour.profile.marchExecutions + [hour];
            hour.profile.marchGroups = hour.profile.marchGroups + [self];
        }
        self.boundAllowed = value.allowed; self.boundSeconds = value.seconds;
        self.startedAt = start; self.completedAt = rpgLedger.seconds; self.boundDefinition = facts; self.result = value;
        value.status = 'resolved'; return value;
    }
;

modify RpgExpandedProfile
    marchGroups = []
    validateFeatures()
    {
        inherited(); local ids = [];
        foreach (local group in self.marchGroups)
        {
            if (group == nil || !group.ofKind(RpgExpandedMarchGroup) || holds(ids,group.id)) rpgExpandedReject('march-group-history');
            local member = nil;
            foreach (local hour in group.hours) if (hour.profile == self) member = true;
            if (!member || group.assess().status != 'reused') rpgExpandedReject('march-group-history');
            ids = ids + [group.id];
        }
        return nil;
    }
;

/** Shared command/dialogue route for a participant in an authored marching group. */
class RpgExpandedMarchGroupAction: Action
    group = nil
    perform(actor)
    {
        if (self.group == nil || !self.group.ofKind(RpgExpandedMarchGroup)) rpgExpandedReject('march-group-action-definition');
        local value = new RpgExpandedMarchGroupResult(); local participant = nil;
        if (actor != nil && actor.ofKind(Thing) && actor.rpgProfile != nil)
            foreach (local hour in self.group.hours)
                if (hour != nil && hour.ofKind(RpgExpandedMarchHour) && hour.profile == actor.rpgProfile) participant = true;
        if (!participant) value.reason = 'march-group-action-participant-required';
        else value = self.group.apply();
        event('rpg.expanded.march-group'); eventValue(value.status); eventValue(value.reason); eventValue(value.allowed ? 1 : 0);
        return value;
    }
    exec(context) { return self.perform(context.actor); }
;

/** B426 combat interruption: settle a party's marching costs without advancing time. */
class RpgExpandedMarchInterruption: object
    id = nil
    costs = []
    boundCompletedAt = nil
    completedAt = nil
    boundDefinition = nil
    definition()
    {
        local facts = [self.id,self.costs.length()];
        foreach (local cost in self.costs) facts = facts + [cost] + cost.definition();
        return facts;
    }
    assess()
    {
        local value = new RpgExpandedResult();
        if (self.id == nil || self.id == '' || self.costs.length() == 0) rpgExpandedReject('march-interruption-definition');
        local profiles = []; local interval = nil;
        foreach (local cost in self.costs)
        {
            if (cost == nil || !cost.ofKind(RpgExpandedMarchHourCost) || cost.ofKind(RpgExpandedMarchHour)
                || holds(profiles,cost.profile)) rpgExpandedReject('march-interruption-member');
            if (interval != nil && cost.interval != interval) rpgExpandedReject('march-interruption-interval');
            interval = cost.interval; profiles = profiles + [cost.profile];
            if (cost.result == nil && cost.basis != 'combat-assumed-hour') rpgExpandedReject('march-interruption-basis');
            local ready = cost.assess();
            if (!holds(['ready','reused'],ready.status)) { value.reason = ready.reason; return value; }
        }
        if (self.completedAt != nil)
        {
            local facts = self.definition();
            if (self.completedAt != self.boundCompletedAt || self.completedAt > rpgLedger.seconds || self.boundDefinition == nil || facts.length() != self.boundDefinition.length())
                rpgExpandedReject('march-interruption-binding');
            for (local i = 1; i <= facts.length(); i += 1)
                if (facts[i] != self.boundDefinition[i]) rpgExpandedReject('march-interruption-binding');
            foreach (local cost in self.costs)
                if (!holds(cost.profile.marchInterruptions,self) || cost.result == nil) rpgExpandedReject('march-interruption-history');
            value.status = 'reused'; return value;
        }
        foreach (local cost in self.costs)
            foreach (local prior in cost.profile.marchInterruptions)
                if (prior.id == self.id) rpgExpandedReject('march-interruption-duplicate');
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local facts = self.definition(); local start = rpgLedger.seconds;
        foreach (local cost in self.costs)
            if (cost.result == nil && cost.apply().status != 'resolved') rpgExpandedReject('march-interruption-cost-changed');
        local current = self.definition();
        if (rpgLedger.seconds != start || current.length() != facts.length()) rpgExpandedReject('march-interruption-changed');
        for (local i = 1; i <= facts.length(); i += 1)
            if (current[i] != facts[i]) rpgExpandedReject('march-interruption-changed');
        self.completedAt = start; self.boundCompletedAt = start; self.boundDefinition = facts;
        foreach (local cost in self.costs) cost.profile.marchInterruptions = cost.profile.marchInterruptions + [self];
        value.status = 'resolved'; return value;
    }
;
modify RpgExpandedProfile
    marchInterruptions = []
    validateFeatures()
    {
        inherited(); local ids = [];
        foreach (local interruption in self.marchInterruptions)
        {
            if (interruption == nil || !interruption.ofKind(RpgExpandedMarchInterruption) || holds(ids,interruption.id))
                rpgExpandedReject('march-interruption-history');
            local member = nil;
            foreach (local cost in interruption.costs) if (cost.profile == self) member = true;
            if (!member || interruption.assess().status != 'reused') rpgExpandedReject('march-interruption-history');
            ids = ids + [interruption.id];
        }
        return nil;
    }
;

/** Shared command/dialogue access to one healer-owned bleeding treatment. */
class RpgExpandedBleedingAidAction: Action
    care = nil
    operation = 'preview'
    perform(actor)
    {
        if (self.care == nil || !self.care.ofKind(RpgExpandedBleedingAid)
            || !holds(['preview','start','completion-preview','complete','cancel'],self.operation))
            rpgExpandedReject('bleeding-aid-action-definition');
        local value = new RpgExpandedResult();
        if (actor == nil || !actor.ofKind(Thing) || actor.rpgProfile == nil || actor.rpgProfile != self.care.healer)
            value.reason = 'bleeding-aid-action-healer-required';
        else if (self.operation == 'preview') value = self.care.assess();
        else if (self.operation == 'start') value = self.care.start();
        else if (self.operation == 'completion-preview') value = self.care.assessCompletion();
        else if (self.operation == 'complete') value = self.care.complete();
        else value = self.care.cancel();
        event('rpg.expanded.bleeding-aid'); eventValue(self.operation); eventValue(value.status); eventValue(value.reason);
        return value;
    }
    exec(context) { return self.perform(context.actor); }
;

/** An owned, continuous fixed-condition hour divided into authored travel steps. */
class RpgExpandedMarchProgress: object
    cost = nil
    steps = []
    elapsed = 0
    boundCostDefinition = nil
    boundEncumbrance = nil
    settlingStep = nil
    interruption = nil
    boundInterruption = nil
    settlingInterruption = nil
    validate()
    {
        if (self.cost == nil || !self.cost.ofKind(RpgExpandedMarchHourCost) || self.cost.ofKind(RpgExpandedMarchHour)
            || self.cost.basis != 'completed-hour') rpgExpandedReject('march-progress-cost');
        local total = 0; local ids = []; local previous = nil;
        foreach (local step in self.steps)
        {
            if (step == nil || !step.ofKind(RpgExpandedMarchStep) || step.progress != self || holds(ids,step.id))
                rpgExpandedReject('march-progress-history');
            step.validateReceipt();
            if (previous != nil && step.startedAt != previous) rpgExpandedReject('march-progress-not-continuous');
            previous = step.completedAt; total += step.result.seconds; ids = ids + [step.id];
        }
        if (total != self.elapsed || total > 3600) rpgExpandedReject('march-progress-elapsed');
        if (self.steps.length() != 0)
        {
            if (self.boundEncumbrance != self.steps[1].encumbrance) rpgExpandedReject('march-progress-encumbrance-binding');
            if (!holds(self.cost.profile.marchProgress,self)) rpgExpandedReject('march-progress-owner');
            local facts = self.cost.definition();
            if (self.boundCostDefinition == nil || facts.length() != self.boundCostDefinition.length()) rpgExpandedReject('march-progress-binding');
            for (local i = 1; i <= facts.length(); i += 1)
                if (facts[i] != self.boundCostDefinition[i]) rpgExpandedReject('march-progress-binding');
        }
        if (total == 3600 && (self.cost.result == nil || self.cost.assess().status != 'reused'))
            rpgExpandedReject('march-progress-missing-cost');
        if (self.interruption != self.boundInterruption) rpgExpandedReject('march-progress-interruption-binding');
        if (self.interruption != nil)
        {
            if (total <= 0 || total >= 3600 || self.interruption.progress != self) rpgExpandedReject('march-progress-interruption');
            self.interruption.validateReceipt();
            if (self.cost.assess().status != 'reused') rpgExpandedReject('march-progress-interruption-cost');
        }
        else if (total < 3600 && self.cost.result != nil) rpgExpandedReject('march-progress-premature-cost');
        return nil;
    }
;
class RpgExpandedMarchStepResult: RpgExpandedResult
    gate = nil
    allowed = nil
;
class RpgExpandedMarchStep: RpgExpandedMarchStepReceipt
    id = nil
    progress = nil
    seconds = nil
    result = nil
    startedAt = nil
    completedAt = nil
    encumbrance = nil
    boundDefinition = nil
    boundOutcome = nil
    definition() { return [self.id,self.progress,self.seconds]; }
    outcomeDefinition() { return [self.startedAt,self.completedAt,self.result,self.result.seconds,self.result.allowed,self.result.gate,self.encumbrance]; }
    validateReceipt()
    {
        if (self.result == nil || self.boundDefinition == nil || self.boundOutcome == nil) rpgExpandedReject('march-step-receipt');
        local facts = self.definition(); local outcome = self.outcomeDefinition();
        if (facts.length() != self.boundDefinition.length() || outcome.length() != self.boundOutcome.length()) rpgExpandedReject('march-step-binding');
        for (local i = 1; i <= facts.length(); i += 1)
            if (facts[i] != self.boundDefinition[i]) rpgExpandedReject('march-step-binding');
        for (local i = 1; i <= outcome.length(); i += 1)
            if (outcome[i] != self.boundOutcome[i]) rpgExpandedReject('march-step-outcome');
        if (self.completedAt != self.startedAt+self.result.seconds || self.completedAt > rpgLedger.seconds
            || self.result.gate.assess().status != 'reused') rpgExpandedReject('march-step-history');
        return nil;
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.progress == nil || !self.progress.ofKind(RpgExpandedMarchProgress))
            rpgExpandedReject('march-step-definition');
        rpgInteger(self.seconds,1,3600); self.progress.validate(); local value = new RpgExpandedMarchStepResult();
        if (self.result != nil)
        {
            if (!holds(self.progress.steps,self)) rpgExpandedReject('march-step-owner');
            self.validateReceipt(); value.status = 'reused'; return value;
        }
        if (self.startedAt != nil || self.completedAt != nil || self.boundDefinition != nil || self.boundOutcome != nil)
            rpgExpandedReject('march-step-uncommitted');
        if (self.progress.interruption != nil) { value.reason = 'march-step-interrupted-hour'; return value; }
        if (self.progress.elapsed+self.seconds > 3600) { value.reason = 'march-step-hour-boundary'; return value; }
        foreach (local prior in self.progress.steps)
            if (prior.id == self.id) rpgExpandedReject('march-step-id-used');
        if (self.progress.steps.length() != 0 && self.progress.steps[self.progress.steps.length()].completedAt != rpgLedger.seconds)
        { value.reason = 'march-step-not-continuous'; return value; }
        local cost = self.progress.cost; local profile = cost.profile;
        if (self.progress.steps.length() != 0 && profile.encumbrance() != self.progress.boundEncumbrance)
        { value.reason = 'march-step-encumbrance-changed'; return value; }
        local prepared = cost.assess(); if (prepared.status != 'ready') { value.reason = prepared.reason; return value; }
        foreach (local other in profile.marchProgress)
            if (other != self.progress && (other.cost == cost || other.cost.interval == cost.interval)) rpgExpandedReject('march-progress-duplicate-interval');
        value.reason = profile.travelScheduleReason(rpgLedger.seconds,self.seconds); if (value.reason != nil) return value;
        if (profile.hp() <= 0 || profile.move() <= 0) { value.reason = 'march-step-continuous-movement-required'; return value; }
        value.gate = new RpgExpandedActionGate(); value.gate.id = 'march-step-' + cost.id + '-' + self.id;
        value.gate.profile = profile; value.gate.requiresMovement = true; value.gate.evidence = cost.evidence;
        local permission = value.gate.assess();
        if (permission.status != 'ready') { value.reason = permission.reason; return value; }
        rpgInteger(rpgLedger.seconds,0,2147483647-self.seconds); rpgLedger.validateAdvance(self.seconds);
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status == 'reused') return self.result;
        if (value.status != 'ready') return value;
        local cost = self.progress.cost; local profile = cost.profile; local costFacts = cost.definition(); local facts = self.definition();
        local start = rpgLedger.seconds; local encumbrance = profile.encumbrance(); local before = cost.assess(); local movement = profile.move(); local hp = profile.hp(); local fp = profile.fp();
        local permission = value.gate.apply(); if (permission.status != 'resolved') rpgExpandedReject('march-step-permission-changed');
        value.allowed = permission.allowed; value.reason = permission.reason;
        if (value.allowed)
        {
            profile.restClock = 0; rpgSpendTime(self.seconds); value.seconds = self.seconds;
            local after = cost.assess();
            if (rpgLedger.seconds != start+self.seconds || after.status != 'ready' || after.fatigueCost != before.fatigueCost
                || profile.move() != movement || profile.hp() != hp || profile.fp() != fp || profile.unconscious || profile.dead
                || profile.stunned || profile.mentalStun || profile.healthEffortReason('action',nil,nil,true) != nil)
                rpgExpandedReject('march-step-conditions-changed');
        }
        local current = cost.definition();
        for (local i = 1; i <= current.length(); i += 1)
            if (current[i] != costFacts[i]) rpgExpandedReject('march-step-cost-changed');
        current = self.definition();
        for (local i = 1; i <= current.length(); i += 1)
            if (current[i] != facts[i]) rpgExpandedReject('march-step-changed');
        if (self.progress.elapsed+value.seconds == 3600)
        {
            self.progress.settlingStep = self;
            if (cost.apply().status != 'resolved') rpgExpandedReject('march-step-cost-unresolved');
            self.progress.settlingStep = nil;
        }
        self.encumbrance = encumbrance; self.startedAt = start; self.completedAt = rpgLedger.seconds; self.boundDefinition = facts; value.status = 'resolved'; self.result = value;
        self.boundOutcome = self.outcomeDefinition();
        if (self.progress.steps.length() == 0)
        { self.progress.boundCostDefinition = costFacts; self.progress.boundEncumbrance = encumbrance; profile.marchProgress = profile.marchProgress + [self.progress]; }
        self.progress.elapsed += value.seconds; self.progress.steps = self.progress.steps + [self]; return value;
    }
;
modify RpgExpandedProfile
    marchProgress = []
    validateFeatures()
    {
        inherited(); local intervals = []; local partial = nil;
        foreach (local progress in self.marchProgress)
        {
            if (progress == nil || !progress.ofKind(RpgExpandedMarchProgress) || progress.cost.profile != self
                || holds(intervals,progress.cost.interval)) rpgExpandedReject('march-progress-profile');
            progress.validate();
            if (progress.elapsed > 0 && progress.elapsed < 3600 && progress.interruption == nil)
            {
                if (partial != nil) rpgExpandedReject('march-multiple-partial-hours');
                partial = progress;
            }
            intervals = intervals + [progress.cost.interval];
        }
        return nil;
    }
;

modify RpgExpandedMarchHourCost
    assess()
    {
        if (self.profile != nil && self.profile.ofKind(RpgExpandedProfile))
            foreach (local progress in self.profile.marchProgress)
            {
                if (progress.cost != self && progress.cost.interval == self.interval)
                    rpgExpandedReject('march-hour-owned-by-progress');
                if (self.result == nil && progress.cost != self && progress.elapsed > 0 && progress.elapsed < 3600 && progress.interruption == nil)
                {
                    progress.validate(); local value = new RpgExpandedMarchHourResult();
                    value.reason = 'march-unsettled-partial-hour'; return value;
                }
            }
        return inherited();
    }
    apply()
    {
        if (self.result == nil && self.profile != nil && self.profile.ofKind(RpgExpandedProfile))
            foreach (local progress in self.profile.marchProgress)
                if (progress.cost == self && (progress.settlingInterruption == nil || !progress.settlingInterruption.permitsCost(progress))
                    && (progress.settlingStep == nil
                    || progress.settlingStep.progress != progress || progress.settlingStep.result != nil
                    || progress.elapsed+progress.settlingStep.seconds != 3600))
                    rpgExpandedReject('march-hour-progress-not-complete');
        return inherited();
    }
;

modify RpgExpandedMarchStep
    trackingProfile() { return self.progress == nil || self.progress.cost == nil ? nil : self.progress.cost.profile; }
    trackingDefinition() { return self.definition() + self.progress.cost.definition(); }
;


/** B426 explicit combat assumption for a positive partial marching hour. */
class RpgExpandedPartialMarchInterruption: object
    id = nil
    progress = nil
    combat = nil
    assumeFullHour = nil
    approved = nil
    evidence = nil
    completedAt = nil
    boundDefinition = nil
    boundOutcome = nil
    definition()
    {
        if (self.id == nil || self.id == '' || self.progress == nil || !self.progress.ofKind(RpgExpandedMarchProgress))
            rpgExpandedReject('partial-march-interruption-definition');
        return [self.id,self.progress,self.combat,self.assumeFullHour,self.approved,self.evidence] + self.progress.cost.definition();
    }
    permitsCost(progress)
    { return self.progress == progress && self.completedAt == nil && self.combat && self.assumeFullHour && self.approved
        && self.evidence != nil && self.evidence != '' && progress.elapsed > 0 && progress.elapsed < 3600; }
    validateReceipt()
    {
        local facts = self.definition();
        if (self.completedAt == nil || self.completedAt > rpgLedger.seconds || self.boundDefinition == nil
            || facts.length() != self.boundDefinition.length() || self.boundOutcome == nil
            || self.completedAt != self.boundOutcome[1] || self.progress.cost.result != self.boundOutcome[2]
            || self.progress.interruption != self || !holds(self.progress.cost.profile.partialMarchInterruptions,self))
            rpgExpandedReject('partial-march-interruption-history');
        for (local i = 1; i <= facts.length(); i += 1)
            if (facts[i] != self.boundDefinition[i]) rpgExpandedReject('partial-march-interruption-binding');
        return nil;
    }
    assess()
    {
        self.definition(); self.progress.validate(); local value = new RpgExpandedResult();
        if (self.completedAt != nil) { self.validateReceipt(); value.status = 'reused'; return value; }
        if (self.boundDefinition != nil || self.boundOutcome != nil) rpgExpandedReject('partial-march-interruption-uncommitted');
        if (self.progress.interruption != nil) { value.reason = 'partial-march-already-interrupted'; return value; }
        if (!self.permitsCost(self.progress)) { value.reason = 'partial-march-combat-assumption-required'; return value; }
        if (self.progress.steps[self.progress.steps.length()].completedAt != rpgLedger.seconds)
        { value.reason = 'partial-march-interruption-not-current'; return value; }
        foreach (local prior in self.progress.cost.profile.partialMarchInterruptions)
            if (prior.id == self.id) rpgExpandedReject('partial-march-interruption-id-used');
        local cost = self.progress.cost.assess();
        if (cost.status != 'ready') { value.reason = cost.reason; return value; }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local facts = self.definition(); local start = rpgLedger.seconds;
        self.progress.settlingInterruption = self;
        if (self.progress.cost.apply().status != 'resolved') rpgExpandedReject('partial-march-cost-changed');
        self.progress.settlingInterruption = nil;
        local current = self.definition();
        if (current.length() != facts.length() || rpgLedger.seconds != start) rpgExpandedReject('partial-march-interruption-changed');
        for (local i = 1; i <= facts.length(); i += 1)
            if (current[i] != facts[i]) rpgExpandedReject('partial-march-interruption-changed');
        self.completedAt = start; self.boundDefinition = facts; self.boundOutcome = [start,self.progress.cost.result];
        self.progress.interruption = self; self.progress.boundInterruption = self;
        self.progress.cost.profile.partialMarchInterruptions = self.progress.cost.profile.partialMarchInterruptions + [self];
        value.status = 'resolved'; return value;
    }
;
modify RpgExpandedProfile
    partialMarchInterruptions = []
    validateFeatures()
    {
        inherited(); local ids = [];
        foreach (local interruption in self.partialMarchInterruptions)
        {
            if (interruption == nil || !interruption.ofKind(RpgExpandedPartialMarchInterruption)
                || interruption.progress.cost.profile != self || holds(ids,interruption.id)) rpgExpandedReject('partial-march-interruption-profile');
            interruption.validateReceipt(); ids = ids + [interruption.id];
        }
        return nil;
    }
;

class RpgExpandedMarchStepGroupResult: RpgExpandedMarchStepResult
    members = []
;
/** Concurrent incremental marching advances the shared world clock once. */
class RpgExpandedMarchStepGroup: RpgExpandedMarchStepGroupReceipt
    id = nil
    steps = []
    result = nil
    startedAt = nil
    completedAt = nil
    boundDefinition = nil
    boundOutcome = nil
    definition()
    {
        local facts = [self.id,self.steps.length()];
        foreach (local step in self.steps) facts = facts + [step] + step.trackingDefinition();
        return facts;
    }
    outcomeDefinition()
    { return [self.startedAt,self.completedAt,self.result,self.result.allowed,self.result.seconds] + self.result.members; }
    assess()
    {
        if (self.id == nil || self.id == '' || self.steps.length() == 0) rpgExpandedReject('march-step-group-definition');
        local profiles = []; local duration = nil; local value = new RpgExpandedMarchStepGroupResult();
        foreach (local step in self.steps)
        {
            if (step == nil || !step.ofKind(RpgExpandedMarchStep) || step.progress == nil || step.progress.cost == nil)
                rpgExpandedReject('march-step-group-member');
            local profile = step.trackingProfile();
            if (holds(profiles,profile) || (duration != nil && duration != step.seconds)) rpgExpandedReject('march-step-group-scope');
            profiles = profiles + [profile]; duration = step.seconds;
        }
        local facts = self.definition();
        if (self.result != nil)
        {
            if (self.boundDefinition == nil || facts.length() != self.boundDefinition.length()) rpgExpandedReject('march-step-group-binding');
            for (local i = 1; i <= facts.length(); i += 1)
                if (facts[i] != self.boundDefinition[i]) rpgExpandedReject('march-step-group-binding');
            local outcome = self.outcomeDefinition();
            if (self.boundOutcome == nil || outcome.length() != self.boundOutcome.length()) rpgExpandedReject('march-step-group-outcome');
            for (local i = 1; i <= outcome.length(); i += 1)
                if (outcome[i] != self.boundOutcome[i]) rpgExpandedReject('march-step-group-outcome');
            for (local i = 1; i <= self.steps.length(); i += 1)
                if (!holds(profiles[i].marchStepGroups,self) || self.steps[i].assess().status != 'reused'
                    || self.steps[i].result != self.result.members[i] || self.steps[i].startedAt != self.startedAt
                    || self.steps[i].completedAt != self.completedAt || self.steps[i].result.seconds != self.result.seconds
                    || self.steps[i].result.allowed != self.result.allowed) rpgExpandedReject('march-step-group-history');
            value.status = 'reused'; return value;
        }
        if (self.startedAt != nil || self.completedAt != nil || self.boundDefinition != nil || self.boundOutcome != nil)
            rpgExpandedReject('march-step-group-uncommitted');
        foreach (local profile in profiles)
            foreach (local prior in profile.marchStepGroups)
                if (prior.id == self.id) rpgExpandedReject('march-step-group-id-used');
        foreach (local step in self.steps)
        {
            if (step.result != nil || step.trackingOwner != nil) rpgExpandedReject('march-step-group-used-member');
            local prepared = step.assess();
            if (prepared.status != 'ready') { value.reason = prepared.reason; return value; }
            value.members = value.members + [prepared];
        }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status == 'reused') return self.result;
        if (value.status != 'ready') return value;
        local facts = self.definition(); local start = rpgLedger.seconds; local states = []; value.allowed = true;
        foreach (local prepared in value.members)
        {
            local permission = prepared.gate.apply();
            if (permission.status != 'resolved') rpgExpandedReject('march-step-group-permission-changed');
            if (!permission.allowed) { value.allowed = nil; value.reason = 'march-step-group-member-denied'; }
        }
        foreach (local step in self.steps)
        {
            local profile = step.trackingProfile(); local fatigueCost = 0;
            if (value.allowed)
            {
                local cost = step.progress.cost.assess();
                if (cost.status != 'ready') rpgExpandedReject('march-step-group-cost-changed');
                fatigueCost = cost.fatigueCost;
            }
            states = states + [[profile.move(),profile.hp(),profile.fp(),fatigueCost,profile.encumbrance()]];
        }
        if (value.allowed)
        {
            foreach (local step in self.steps) { local profile = step.trackingProfile(); profile.restClock = 0; }
            value.seconds = self.steps[1].seconds; rpgSpendTime(value.seconds);
            for (local i = 1; i <= self.steps.length(); i += 1)
            {
                local step = self.steps[i]; local profile = step.trackingProfile(); local cost = step.progress.cost.assess();
                if (rpgLedger.seconds != start+value.seconds || cost.status != 'ready' || cost.fatigueCost != states[i][4]
                    || profile.move() != states[i][1] || profile.hp() != states[i][2] || profile.fp() != states[i][3]
                    || profile.unconscious || profile.dead || profile.stunned || profile.mentalStun
                    || profile.healthEffortReason('action',nil,nil,true) != nil) rpgExpandedReject('march-step-group-conditions-changed');
            }
        }
        local current = self.definition();
        if (current.length() != facts.length()) rpgExpandedReject('march-step-group-changed');
        for (local i = 1; i <= facts.length(); i += 1)
            if (current[i] != facts[i]) rpgExpandedReject('march-step-group-changed');
        for (local i = 1; i <= self.steps.length(); i += 1)
        {
            local step = self.steps[i]; local progress = step.progress; local cost = progress.cost; local profile = step.trackingProfile();
            if (progress.elapsed+value.seconds == 3600)
            {
                progress.settlingStep = step;
                if (cost.apply().status != 'resolved') rpgExpandedReject('march-step-group-cost-unresolved');
                progress.settlingStep = nil;
            }
            local member = value.members[i]; member.allowed = value.allowed; member.reason = value.reason;
            member.seconds = value.seconds; member.status = 'resolved'; step.result = member;
            step.encumbrance = states[i][5]; step.startedAt = start; step.completedAt = rpgLedger.seconds;
            step.boundDefinition = step.definition(); step.boundOutcome = step.outcomeDefinition();
            if (progress.steps.length() == 0)
            { progress.boundCostDefinition = cost.definition(); progress.boundEncumbrance = step.encumbrance; profile.marchProgress = profile.marchProgress + [progress]; }
            progress.elapsed += value.seconds; progress.steps = progress.steps + [step]; profile.marchStepGroups = profile.marchStepGroups + [self];
        }
        self.startedAt = start; self.completedAt = rpgLedger.seconds; self.boundDefinition = facts;
        value.status = 'resolved'; self.result = value; self.boundOutcome = self.outcomeDefinition(); return value;
    }
;
modify RpgExpandedProfile
    marchStepGroups = []
    validateFeatures()
    {
        inherited(); local ids = [];
        foreach (local group in self.marchStepGroups)
        {
            if (group == nil || !group.ofKind(RpgExpandedMarchStepGroup) || holds(ids,group.id) || group.assess().status != 'reused')
                rpgExpandedReject('march-step-group-profile');
            local found = nil;
            foreach (local step in group.steps) if (step.trackingProfile() == self) found = true;
            if (!found) rpgExpandedReject('march-step-group-profile'); ids = ids + [group.id];
        }
        return nil;
    }
;

modify RpgExpandedMarchStepGroup
    shadowingProfiles()
    {
        local profiles = [];
        foreach (local step in self.steps) profiles = profiles + [step.trackingProfile()];
        return profiles;
    }
    shadowingFacts() { return self.definition(); }
    shadowingSeconds() { return self.steps.length() == 0 ? 0 : self.steps[1].seconds; }
;

modify RpgExpandedFearContext
    eventFacts()
    {
        return [self.profile,self.approved,self.evidence,self.physicalRisk,self.cowardicePenalty,self.charging,
            self.purposeThreat,self.monsters,self.xenophiliaBonus,self.body,self.mutilationPenalty,self.dependentVictim,
            self.inCombat,self.monsterPenalty,self.hordeBand,self.touching,self.distance,self.remote,self.isolated,
            self.adverseLighting,self.believesAlone,self.priorExperience,self.priorExposures24h,self.briefingBonus];
    }
;
class RpgExpandedFearEventResult: RpgExpandedResult
    stressFollowup = nil
    immune = nil
    score = nil
    tableRoll = nil
    tableTotal = nil
    row = nil
;
/** Authored ruling for a prohibited initial roll (B345), not a derived failure margin. */
class RpgExpandedLowScoreFearDecision: object
    entry = nil
    row = nil
    approved = nil
    evidence = nil
    voiceStress = nil
    facts(owner)
    {
        if (self.entry != owner) rpgExpandedReject('fear-low-score-decision-owner');
        rpgInteger(self.row,4,40);
        if (self.voiceStress != nil && !holds(['check','none'],self.voiceStress))
            rpgExpandedReject('fear-low-score-voice-choice');
        return [self,self.entry,self.row,self.approved,self.evidence,self.voiceStress];
    }
;
/** B360-B361: persist the initial check and selection before authoring a consequence. */
class RpgExpandedFearEvent: object
    id = nil
    occurrence = nil
    context = nil
    result = nil
    recordedAt = nil
    boundDefinition = nil
    boundOutcome = nil
    consequence = nil
    boundConsequence = nil
    lowScoreDecision = nil
    initialAssessment() { return self.context.assess(); }
    eventAssessment()
    {
        local value = self.initialAssessment();
        if (value.score != nil && value.score < 3 && holds(['fear-score-unavailable',
            'phobia-control-unavailable','postbattle-self-control-unavailable'],value.reason))
        {
            if (self.lowScoreDecision == nil || !self.lowScoreDecision.approved
                || self.lowScoreDecision.evidence == nil || self.lowScoreDecision.evidence == '')
            { value.reason = 'fear-low-score-author-decision-required'; return value; }
            value.status = 'ready'; value.reason = nil; return value;
        }
        if (value.status == 'ready' && self.lowScoreDecision != nil)
        { value.status = 'blocked'; value.reason = 'fear-low-score-decision-inapplicable'; }
        return value;
    }
    stressFollowupRequired(check) { return !check.achieved || check.margin == 0; }
    definition()
    {
        if (self.id == nil || self.id == '' || self.occurrence == nil || self.context == nil
            || !self.context.ofKind(RpgExpandedFearContext)) rpgExpandedReject('fear-event-definition');
        local decision = [nil];
        if (self.lowScoreDecision != nil)
        {
            if (!self.lowScoreDecision.ofKind(RpgExpandedLowScoreFearDecision)) rpgExpandedReject('fear-low-score-decision-type');
            decision = self.lowScoreDecision.facts(self);
        }
        return [self.id,self.occurrence,self.context] + self.context.eventFacts() + decision;
    }
    outcomeFacts()
    {
        local v = self.result;
        local facts = [v,v.status,v.reason,v.immune,v.score,v.modifier,v.tableRoll,v.tableTotal,v.row,self.recordedAt,v.check,v.stressFollowup];
        if (v.check != nil) facts = facts + [v.check.score,v.check.roll,v.check.margin,v.check.achieved,v.check.critical];
        return facts;
    }
    assess()
    {
        local facts = self.definition(); local value = new RpgExpandedFearEventResult(); local profile = self.context.profile;
        if (profile == nil || !profile.ofKind(RpgExpandedProfile)) rpgExpandedReject('fear-event-profile');
        if (self.result != nil)
        {
            if (!holds(profile.fearEvents,self) || self.boundDefinition == nil || facts.length() != self.boundDefinition.length())
                rpgExpandedReject('fear-event-history');
            for (local i = 1; i <= facts.length(); i += 1)
                if (facts[i] != self.boundDefinition[i]) rpgExpandedReject('fear-event-binding');
            local outcome = self.outcomeFacts();
            if (self.boundOutcome == nil || outcome.length() != self.boundOutcome.length()) rpgExpandedReject('fear-event-outcome');
            for (local i = 1; i <= outcome.length(); i += 1)
                if (outcome[i] != self.boundOutcome[i]) rpgExpandedReject('fear-event-outcome');
            if (self.consequence != self.boundConsequence || self.recordedAt > rpgLedger.seconds) rpgExpandedReject('fear-event-consequence-binding');
            if (self.result.stressFollowup != nil) profile.validateFearStressFollowup(self,self.result.stressFollowup);
            value.status = 'reused'; return value;
        }
        if (self.recordedAt != nil || self.boundDefinition != nil || self.boundOutcome != nil || self.consequence != nil
            || self.boundConsequence != nil) rpgExpandedReject('fear-event-uncommitted');
        foreach (local prior in profile.fearEvents)
        {
            prior.assess();
            if (prior.id == self.id || prior.occurrence == self.occurrence) rpgExpandedReject('fear-event-duplicate');
            if (prior.result.row != nil && prior.consequence == nil)
            { value.reason = 'fear-event-unresolved-consequence'; return value; }
        }
        if (profile.dead || profile.unconscious) { value.reason = 'fear-event-observer-unavailable'; return value; }
        local prepared = self.eventAssessment();
        if (prepared.status != 'ready') { value.reason = prepared.reason; return value; }
        /* Preflight the specific stress follow-up before consuming the initial roll. */
        if (!prepared.immune)
        {
            value.stressFollowup = profile.newFearStressFollowup(self);
            if (value.stressFollowup != nil && prepared.score < 3)
            {
                if (self.lowScoreDecision.voiceStress == nil)
                { value.reason = 'fear-low-score-voice-decision-required'; return value; }
                if (self.lowScoreDecision.voiceStress == 'none') value.stressFollowup = nil;
            }
            if (value.stressFollowup != nil)
            {
                local stress = value.stressFollowup.assess();
                if (stress.status != 'ready') { value.reason = stress.reason; return value; }
            }
        }
        value.immune = prepared.immune; value.score = prepared.score; value.modifier = prepared.modifier;
        value.status = 'ready'; return value;
    }
    resolve()
    {
        local value = self.assess(); if (value.status == 'reused') return self.result;
        if (value.status != 'ready') return value;
        local facts = self.definition();
        if (!value.immune && value.score < 3)
        {
            value.row = self.lowScoreDecision.row; value.reason = 'author-selected-low-score';
        }
        else if (!value.immune)
        {
            value.check = rpgCheck(value.score,rpgRandom.roll());
            if (!value.check.achieved)
            {
                value.tableRoll = rpgRandom.roll(); value.tableTotal = value.tableRoll-value.check.margin;
                value.row = rpgExpandedFearTable(value.tableTotal).row;
            }
        }
        if (value.stressFollowup != nil)
        {
            if (value.check != nil && self.stressFollowupRequired(value.check)
                || value.check == nil && value.reason == 'author-selected-low-score' && self.lowScoreDecision.voiceStress == 'check')
            {
                local stress = value.stressFollowup.resolve();
                if (stress.status != 'resolved') rpgExpandedReject('fear-event-stress-changed');
            }
            else value.stressFollowup = nil;
        }
        value.status = 'resolved'; self.recordedAt = rpgLedger.seconds; self.result = value;
        self.boundDefinition = facts; self.boundOutcome = self.outcomeFacts();
        self.context.profile.fearEvents = self.context.profile.fearEvents + [self]; return value;
    }
    matchesConsequence(request)
    {
        local row = self.selectedRow();
        if (request.ofKind(RpgExpandedFearTraitConsequence)) return request.fearEventMatches(self);
        if (request.ofKind(RpgExpandedFearStun)) return request.tableTotal == row && (row <= 11 || (row >= 14 && row <= 16));
        if (request.ofKind(RpgExpandedFearRetching)) return row == 12;
        if (request.ofKind(RpgExpandedFearFaint)) return request.tableTotal == row && row >= 17 && row <= 20;
        if (request.ofKind(RpgExpandedFearPanic)) return row == 21;
        if (request.ofKind(RpgExpandedFearComa)) return request.tableTotal == row && (row == 28 || row == 29);
        if (request.ofKind(RpgExpandedCatatonia)) return row == 30;
        if (request.ofKind(RpgExpandedFearSeizure)) return row == 31;
        if (request.ofKind(RpgExpandedFearAcuteInjury)) return row == 32;
        return nil;
    }
    assessConsequence(request)
    {
        local value = new RpgExpandedResult();
        if (self.assess().status != 'reused' || self.result.row == nil)
        { value.reason = 'fear-event-no-consequence'; return value; }
        if (request == nil || !self.matchesConsequence(request))
        { value.reason = 'fear-event-consequence-type-or-row'; return value; }
        if (!request.ofKind(RpgExpandedFearTraitConsequence) && (request.context != self.context || request.id != self.id))
            rpgExpandedReject('fear-event-consequence-owner');
        if (self.consequence != nil)
        {
            if (self.consequence != request) rpgExpandedReject('fear-event-consequence-already-selected');
            if (request.assess().status != 'reused') rpgExpandedReject('fear-event-consequence-history');
            value.status = 'reused'; return value;
        }
        if (self.recordedAt != rpgLedger.seconds) { value.reason = 'fear-event-consequence-delayed'; return value; }
        local prepared = self.eventAssessment();
        if (prepared.status != 'ready' || prepared.immune || prepared.score != self.result.score || prepared.modifier != self.result.modifier)
        { value.reason = 'fear-event-context-changed'; return value; }
        value = request.assess();
        if (value.status == 'reused') rpgExpandedReject('fear-event-used-consequence');
        return value;
    }
    applyConsequence(request)
    {
        local value = self.assessConsequence(request); if (value.status != 'ready') return value;
        value = request.apply(); if (value.status != 'resolved') rpgExpandedReject('fear-event-consequence-changed');
        self.consequence = request; self.boundConsequence = request; return value;
    }
;
modify RpgExpandedProfile
    fearEvents = []
    validateFeatures()
    {
        inherited(); local ids = []; local occurrences = [];
        foreach (local entry in self.fearEvents)
        {
            if (entry == nil || !entry.ofKind(RpgExpandedFearEvent) || entry.context.profile != self
                || holds(ids,entry.id) || holds(occurrences,entry.occurrence) || entry.assess().status != 'reused')
                rpgExpandedReject('fear-event-profile-history');
            ids = ids + [entry.id]; occurrences = occurrences + [entry.occurrence];
        }
        return nil;
    }
;

modify RpgExpandedProfile
    unresolvedFearEvent()
    {
        foreach (local entry in self.fearEvents)
        {
            entry.assess();
            if (entry.result.row != nil && entry.consequence == nil) return entry;
        }
        return nil;
    }
    healthEffortReasonFor(purpose,mentalAbility,speech,movement,authorization)
    {
        if (self.unresolvedFearEvent() != nil) return 'fear-event-unresolved-consequence';
        return inherited(purpose,mentalAbility,speech,movement,authorization);
    }
    healthManeuverReasonFor(kind,request)
    {
        if (self.unresolvedFearEvent() != nil) return 'fear-event-unresolved-consequence';
        return inherited(kind,request);
    }
;
modify rpgLedger
    validateAdvance(seconds)
    {
        inherited(seconds);
        if (seconds > 0)
            for (local entry = firstObj(RpgExpandedFearEvent); entry != nil; entry = nextObj(entry,RpgExpandedFearEvent))
                if (entry.result != nil && entry.result.row != nil && entry.consequence == nil)
                { entry.assess(); rpgExpandedReject('fear-event-unresolved-consequence'); }
        return nil;
    }
;


/** B361 rows 26/38 combine a lasting belief with the specified faint/coma. */
class RpgExpandedFearTraitCompound: RpgExpandedFearTraitConsequence
    id = nil
    context = nil
    tableTotal = 26
    acquisition = nil
    episode = nil
    iqBefore = nil
    iqAfter = nil
    boundIQ = nil
    result = nil
    boundDefinition = nil
    boundResult = nil
    definition()
    {
        if (self.id == nil || self.id == '' || self.context == nil || !self.context.ofKind(RpgExpandedFearContext)
            || !holds([26,27,38,39,40],self.tableTotal) || self.acquisition == nil
            || !self.acquisition.ofKind(RpgExpandedFearTraitConsequence) || self.episode == nil)
            rpgExpandedReject('fear-belief-compound-definition');
        return [self.id,self.context,self.context.profile,self.tableTotal,self.acquisition,self.episode];
    }
    fearEventMatches(entry)
    {
        self.definition();
        return entry.id == self.id && entry.context == self.context && entry.selectedRow() == self.tableTotal;
    }
    assess()
    {
        local facts = self.definition(); local value = new RpgExpandedResult();
        if (!self.acquisition.fearCompoundMatches(self.context.profile,self.id,self.tableTotal))
            rpgExpandedReject('fear-belief-compound-acquisition');
        if ((holds([26,27],self.tableTotal) && (!self.episode.ofKind(RpgExpandedFearFaint) || self.episode.tableTotal != 18))
            || (holds([38,39,40],self.tableTotal) && (!self.episode.ofKind(RpgExpandedFearComa) || self.episode.tableTotal != 29))
            || self.episode.context != self.context || self.episode.id != self.id)
            rpgExpandedReject('fear-belief-compound-episode');
        if (self.result != nil)
        {
            if (self.boundDefinition == nil || !holds(self.context.profile.fearBeliefCompounds,self)
                || self.result != self.boundResult) rpgExpandedReject('fear-belief-compound-history');
            for (local i = 1; i <= facts.length(); i += 1)
                if (facts[i] != self.boundDefinition[i]) rpgExpandedReject('fear-belief-compound-binding');
            if (self.acquisition.assess().status != 'reused' || self.episode.assess().status != 'reused')
                rpgExpandedReject('fear-belief-compound-receipts');
            if (self.boundIQ == nil || self.iqBefore != self.boundIQ[1] || self.iqAfter != self.boundIQ[2])
                rpgExpandedReject('fear-compound-iq-binding');
            value.status = 'reused'; return value;
        }
        if (self.boundDefinition != nil || self.boundResult != nil || self.boundIQ != nil || self.iqBefore != nil || self.iqAfter != nil) rpgExpandedReject('fear-belief-compound-uncommitted');
        foreach (local prior in self.context.profile.fearBeliefCompounds)
            if (prior.id == self.id) rpgExpandedReject('fear-belief-compound-duplicate');
        if (self.tableTotal == 40 && self.context.profile.iq <= 1)
        { value.reason = 'fear-minimum-iq-author-adjudication'; return value; }
        if (self.tableTotal == 40) rpgInteger(self.context.profile.developmentRevision,0,2147483645);
        local trait = self.acquisition.assess();
        if (trait.status == 'reused') rpgExpandedReject('fear-belief-compound-used-acquisition');
        if (trait.status != 'ready') { value.reason = trait.reason; return value; }
        local health = self.episode.assess();
        if (health.status == 'reused') rpgExpandedReject('fear-belief-compound-used-episode');
        if (health.status != 'ready') { value.reason = health.reason; return value; }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local facts = self.definition(); local originalIQ = self.context.profile.iq;
        if (self.acquisition.apply().status != 'resolved') rpgExpandedReject('fear-belief-compound-acquisition-changed');
        if (self.episode.apply().status != 'resolved') rpgExpandedReject('fear-belief-compound-episode-changed');
        if (self.tableTotal == 40)
        {
            if (self.context.profile.iq != originalIQ) rpgExpandedReject('fear-compound-iq-changed');
            self.iqBefore = originalIQ; self.iqAfter = originalIQ-1; self.context.profile.iq = self.iqAfter;
            self.context.profile.developmentRevision += 1;
        }
        self.boundIQ = [self.iqBefore,self.iqAfter];
        value.status = 'resolved'; self.result = value; self.boundResult = value; self.boundDefinition = facts;
        self.context.profile.fearBeliefCompounds = self.context.profile.fearBeliefCompounds + [self]; return value;
    }
;
class RpgExpandedFearBeliefCompound: RpgExpandedFearTraitCompound;
modify RpgExpandedProfile
    fearBeliefCompounds = []
;

/** B93: an authored perceiver of an aura uses the ordinary owned fear flow. */
class RpgExpandedFearAuraContext: RpgExpandedFearContext
    auraOwner = nil
    aura = nil
    perceived = nil
    activated = nil
    contactEstablished = nil
    eventFacts()
    {
        if (self.auraOwner == nil || !self.auraOwner.ofKind(RpgExpandedProfile) || self.aura == nil
            || !self.aura.ofKind(RpgExpandedFearAuraContract)) rpgExpandedReject('fear-aura-context');
        return inherited() + [self.auraOwner,self.aura,self.perceived,self.activated,self.contactEstablished] + self.aura.auraFacts();
    }
    assess()
    {
        self.eventFacts(); local value = new RpgExpandedFearAssessment();
        if (self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)) rpgExpandedReject('fear-aura-victim');
        if (self.priorExposures24h != 0) rpgExpandedReject('fear-aura-owned-history-required');
        if ((self.contactEstablished ? 1 : 0) != (self.touching ? 1 : 0)) rpgExpandedReject('fear-aura-contact-modifier');
        if (!holds(self.auraOwner.traits,self.aura) || !self.aura.active || self.aura.mitigated)
        { value.reason = 'fear-aura-not-active'; return value; }
        if (!self.aura.alwaysOn && (self.auraOwner.dead || self.auraOwner.unconscious))
        { value.reason = 'fear-aura-owner-unavailable'; return value; }
        for (local owner = firstObj(RpgLiteProfile); owner != nil; owner = nextObj(owner,RpgLiteProfile))
            if (owner != self.auraOwner && holds(owner.traits,self.aura)) rpgExpandedReject('fear-aura-shared-purchase');
        if (!self.perceived || (!self.aura.alwaysOn && !self.activated) || (self.aura.touchOnly && !self.contactEstablished))
        { value.reason = 'fear-aura-exposure-required'; return value; }
        value.reason = self.profile.fearAuraPerceptionReason(self.aura); if (value.reason != nil) return value;
        local count = 0; local protected = nil;
        foreach (local entry in self.profile.fearEvents)
            if (entry.context.ofKind(RpgExpandedFearAuraContext)
                && entry.context.auraOwner == self.auraOwner && entry.context.aura == self.aura)
            {
                entry.assess();
                if (entry.result.check != nil && rpgLedger.seconds-entry.recordedAt < 86400) count += 1;
                if (entry.result.check != nil && entry.result.check.achieved && rpgLedger.seconds-entry.recordedAt < 3600) protected = true;
            }
        local scene = inherited();
        if (scene.status != 'ready' && scene.reason != 'fear-score-unavailable') return scene;
        if (scene.immune || protected)
        { scene.immune = true; scene.score = nil; scene.status = 'ready'; scene.reason = nil; return scene; }
        local modifier = scene.modifier-self.aura.penalty+count;
        value = rpgExpandedAssessFear(self.profile.attributeScore(rpgWill),modifier,nil);
        value.modifier = modifier; return value;
    }
;

/** The battle identity is the occurrence; author approval establishes its actual end. */
class RpgExpandedPostbattleFearEvent: RpgExpandedFearEvent
    trait = nil
    battleEnded = nil
    dangerPenalty = 0
    definition()
    {
        rpgInteger(self.dangerPenalty,-100,0);
        return inherited() + [self.trait,self.battleEnded,self.dangerPenalty] + self.context.profile.postbattleFearFacts(self.trait);
    }
    initialAssessment()
    {
        local value = new RpgExpandedFearAssessment();
        if (!self.battleEnded || !self.context.approved || self.context.evidence == nil || self.context.evidence == '')
        { value.reason = 'postbattle-ending-evidence'; return value; }
        if (!self.context.ofKind(RpgExpandedPostbattleFearContext) || self.context.trait != self.trait
            || self.context.dangerPenalty != self.dangerPenalty) rpgExpandedReject('postbattle-recovery-context');
        value.score = self.context.profile.postbattleFearScore(self.trait,self.dangerPenalty);
        if (value.score != nil) value.modifier = value.score-self.trait.selfControlNumber();
        if (value.score == nil || value.score < 3 || value.score > 1000)
        { value.reason = 'postbattle-self-control-unavailable'; return value; }
        value.status = 'ready'; return value;
    }
    stressFollowupRequired(check) { return !check.achieved; }
;

class RpgExpandedPostbattleFearContext: RpgExpandedFearContext
    trait = nil
    dangerPenalty = 0
    eventFacts()
    {
        rpgInteger(self.dangerPenalty,-100,0);
        return inherited() + [self.trait,self.dangerPenalty] + self.profile.postbattleFearFacts(self.trait);
    }
    assess()
    {
        self.eventFacts(); local value = new RpgExpandedFearAssessment();
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'postbattle-context-evidence'; return value; }
        local score = self.profile.postbattleFearScore(self.trait,self.dangerPenalty);
        if (score == nil) { value.reason = 'postbattle-trait-unavailable'; return value; }
        local modifier = score-self.trait.selfControlNumber();
        value = rpgExpandedAssessFear(self.profile.attributeScore(rpgWill),modifier,nil);
        value.modifier = modifier; return value;
    }
;

/** B149/B150 validated stimulus-specific self-control modifiers. */
rpgExpandedPhobiaModifier(kind,condition,crowdCount)
{
    if (kind == 'crowds')
    {
        if (condition != 'ordinary') rpgExpandedReject('phobia-crowd-condition');
        rpgInteger(crowdCount,13,1000000000);
        if (crowdCount <= 25) return 0;
        if (crowdCount < 100) return -1;
        local penalty = -2; local boundary = 1000;
        while (crowdCount >= boundary && boundary <= 1000000000)
        { penalty -= 1; if (boundary == 1000000000) break; boundary *= 10; }
        return penalty;
    }
    if (crowdCount != 0) rpgExpandedReject('phobia-unused-crowd');
    if (condition == 'ordinary') return 0;
    foreach (local row in [['dead','known-body',-4],['dead','animated-or-ghost',-6],['dirt','unfamiliar-food',-5],
        ['heights','fall-risk',-5],['insects','large-or-poisonous',-3],['insects','very-large-or-numerous',-6],
        ['machinery','robot-or-computer',-3],['machinery','hostile-machine',-6],['magic','friendly-target',-3],
        ['magic','hostile-target',-6],['number-thirteen','friday',-5],['reptiles','large-or-poisonous',-2],
        ['reptiles','horde',-4],['sharp','use-or-threat',-2],['weapons','use-or-threat',-2],['unfamiliar','nonhuman-company',-3]])
        if (row[1] == kind && row[2] == condition) return row[3];
    if (kind == 'monsters')
    {
        local labels = ['severity-one','severity-two','severity-three','severity-four'];
        for (local index = 1; index <= 4; index += 1)
            if (labels[index] == condition) return -index;
    }
    rpgExpandedReject('phobia-condition');
}
class RpgExpandedPhobiaExposure: object
    id = nil
    profile = nil
    trait = nil
    cause = nil
    approved = nil
    evidence = nil
    boundStartedAt = nil
    startedAt = nil
    endedAt = nil
    endingEvidence = nil
    boundEnding = nil
    boundDefinition = nil
    checks = []
    definition()
    {
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile) || self.cause == nil)
            rpgExpandedReject('phobia-exposure-definition');
        return [self.id,self.profile,self.trait,self.cause,self.approved,self.evidence,
            self.profile.phobiaOverlapPolicy,self.profile.phobiaOverlapEvidence] + self.profile.phobiaFacts(self.trait);
    }
    nextCheckAt() { return self.checks.length() == 0 ? self.startedAt : self.checks[self.checks.length()].recordedAt+600; }
    assess()
    {
        local facts = self.definition(); local value = new RpgExpandedResult();
        if (self.startedAt != nil)
        {
            if (self.boundDefinition == nil || self.startedAt != self.boundStartedAt || self.startedAt > rpgLedger.seconds
                || !holds(self.profile.phobiaExposures,self)) rpgExpandedReject('phobia-exposure-history');
            for (local i = 1; i <= facts.length(); i += 1)
                if (facts[i] != self.boundDefinition[i]) rpgExpandedReject('phobia-exposure-binding');
            local count = 0;
            foreach (local check in self.checks)
            {
                local due = self.checkDueAfter(count);
                if (due == nil || check.context.exposure != self || check.recordedAt != due || check.assess().status != 'reused')
                    rpgExpandedReject('phobia-check-history');
                count += 1;
            }
            local pauseIds = []; local previousResume = self.startedAt;
            foreach (local pause in self.awarenessPauses)
            {
                pause.validateReceipt();
                if (pause.exposure != self || holds(pauseIds,pause.id) || pause.afterChecks > self.checks.length()
                    || previousResume == nil || pause.startedAt < previousResume
                    || pause.resumedAt != nil && pause.resumedAt < pause.startedAt) rpgExpandedReject('phobia-pause-sequence');
                previousResume = pause.resumedAt; pauseIds = pauseIds + [pause.id];
            }
            if (self.boundEnding == nil && (self.endedAt != nil || self.endingEvidence != nil)) rpgExpandedReject('phobia-ending');
            if (self.boundEnding != nil && (self.endedAt != self.boundEnding[1] || self.endingEvidence != self.boundEnding[2]))
                rpgExpandedReject('phobia-ending');
            value.status = 'reused'; return value;
        }
        if (!self.approved || self.evidence == nil || self.evidence == '') { value.reason = 'phobia-stimulus-evidence'; return value; }
        if (self.awarenessPauses.length() != 0 || self.checks.length() != 0 || self.endedAt != nil || self.boundDefinition != nil || self.boundStartedAt != nil || self.boundEnding != nil || self.endingEvidence != nil)
            rpgExpandedReject('phobia-uncommitted');
        self.profile.phobiaOverlapConfigured();
        if (self.profile.phobiaScore(self.trait,0) == nil) { value.reason = 'phobia-trait-unavailable'; return value; }
        foreach (local prior in self.profile.phobiaExposures)
        {
            prior.assess();
            if (prior.id == self.id || prior.endedAt == nil && prior.cause == self.cause
                && self.profile.phobiaCurrentTrait(prior.trait) == self.profile.phobiaCurrentTrait(self.trait))
                rpgExpandedReject('phobia-duplicate-exposure');
            if (prior.endedAt == nil && !self.profile.phobiaOverlapConfigured())
            { value.reason = 'phobia-overlap-policy-required'; return value; }
        }
        value.status = 'ready'; return value;
    }
    start()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.boundDefinition = self.definition(); self.startedAt = rpgLedger.seconds; self.boundStartedAt = self.startedAt;
        self.profile.phobiaExposures = self.profile.phobiaExposures + [self]; value.status = 'resolved'; return value;
    }
    end(approved,evidence)
    {
        if (self.assess().status != 'reused' || !approved || evidence == nil || evidence == '') rpgExpandedReject('phobia-ending-evidence');
        if (self.endedAt != nil) return nil;
        if (self.checks.length() == 0) rpgExpandedReject('phobia-initial-check-required');
        self.endedAt = rpgLedger.seconds; self.endingEvidence = evidence; self.boundEnding = [self.endedAt,evidence]; return nil;
    }
    penalty()
    {
        self.assess();
        if (self.endedAt != nil || self.awarenessPaused() || self.checks.length() == 0) return 0;
        local check = self.checks[self.checks.length()].result.check;
        if (check == nil || !check.achieved) return 0;
        return -(18-self.profile.phobiaControlNumber(self.trait))/3;
    }
;
class RpgExpandedPhobiaContext: RpgExpandedFearContext
    exposure = nil
    threatOnly = nil
    condition = 'ordinary'
    crowdCount = 0
    eventFacts()
    {
        if (self.exposure == nil || !self.exposure.ofKind(RpgExpandedPhobiaExposure) || self.profile != self.exposure.profile)
            rpgExpandedReject('phobia-context-exposure');
        return inherited() + [self.exposure,self.threatOnly,self.condition,self.crowdCount] + self.exposure.definition();
    }
    stimulusModifier()
    {
        if (self.threatOnly)
        {
            if (self.condition != 'ordinary' || self.crowdCount != 0) rpgExpandedReject('phobia-threat-fields');
            return 4;
        }
        return rpgExpandedPhobiaModifier(self.exposure.trait.scope,self.condition,self.crowdCount);
    }
    controlAssessment()
    {
        self.eventFacts(); local value = new RpgExpandedFearAssessment();
        if (!self.approved || self.evidence == nil || self.evidence == '') { value.reason = 'phobia-context-evidence'; return value; }
        value.score = self.profile.phobiaScore(self.exposure.trait,self.stimulusModifier());
        if (value.score != nil) value.modifier = value.score-self.profile.phobiaControlNumber(self.exposure.trait);
        if (value.score == nil || value.score < 3 || value.score > 1000) { value.reason = 'phobia-control-unavailable'; return value; }
        value.status = 'ready'; return value;
    }
    assess()
    {
        local control = self.controlAssessment(); if (control.status != 'ready') return control;
        local value = rpgExpandedAssessFear(self.profile.attributeScore(rpgWill),control.modifier,nil);
        value.modifier = control.modifier; return value;
    }
;
class RpgExpandedPhobiaCheck: RpgExpandedFearEvent
    initialAssessment()
    {
        if (!self.context.ofKind(RpgExpandedPhobiaContext)) rpgExpandedReject('phobia-check-context');
        return self.context.controlAssessment();
    }
    stressFollowupRequired(check) { return !check.achieved; }
    assess()
    {
        if (self.result == nil)
        {
            if (self.context == nil || !self.context.ofKind(RpgExpandedPhobiaContext)) rpgExpandedReject('phobia-check-context');
            local exposure = self.context.exposure; local value = new RpgExpandedFearEventResult();
            if (exposure == nil || exposure.assess().status != 'reused' || exposure.endedAt != nil)
            { value.reason = 'phobia-active-exposure-required'; return value; }
            if (exposure.nextCheckAt() != rpgLedger.seconds) { value.reason = 'phobia-check-not-due'; return value; }
            rpgInteger(rpgLedger.seconds,0,2147483047);
        }
        else if (self.context == nil || !self.context.ofKind(RpgExpandedPhobiaContext)
            || !holds(self.context.exposure.checks,self)) rpgExpandedReject('phobia-check-exposure-history');
        return inherited();
    }
    resolve()
    {
        local replay = self.result != nil; local value = inherited();
        if (!replay && value.status == 'resolved') self.context.exposure.checks = self.context.exposure.checks + [self];
        return value;
    }
;
modify RpgExpandedProfile
    phobiaExposures = []
    phobiaOverlapPolicy = nil
    phobiaOverlapEvidence = nil
    phobiaOverlapConfigured()
    {
        if (self.phobiaOverlapPolicy == nil && self.phobiaOverlapEvidence == nil) return nil;
        if (!holds(['sum','worst'],self.phobiaOverlapPolicy) || self.phobiaOverlapEvidence == nil || self.phobiaOverlapEvidence == '')
            rpgExpandedReject('phobia-overlap-policy');
        return true;
    }
    healthAttributeModifier(context)
    {
        local value = inherited(context); self.phobiaOverlapConfigured(); local penalty = 0;
        if (context.skill != nil || holds([rpgDX,rpgIQ],context.controllingAttribute()))
            foreach (local exposure in self.phobiaExposures)
            {
                local current = exposure.penalty();
                if (self.phobiaOverlapPolicy == 'worst') { if (current < penalty) penalty = current; }
                else penalty += current;
            }
        return value+penalty;
    }
;
modify rpgLedger
    validateAdvance(seconds)
    {
        inherited(seconds);
        if (seconds > 0)
            for (local exposure = firstObj(RpgExpandedPhobiaExposure); exposure != nil; exposure = nextObj(exposure,RpgExpandedPhobiaExposure))
                if (exposure.startedAt != nil && exposure.endedAt == nil && !exposure.profile.dead)
                {
                    exposure.assess();
                    if (exposure.awarenessPaused())
                    { if (!exposure.profile.unconscious) rpgExpandedReject('phobia-resume-perception-required'); }
                    else if (self.seconds+seconds > exposure.nextCheckAt()) rpgExpandedReject('phobia-repeat-check-due');
                }
        return nil;
    }
;

modify RpgExpandedProfile
    validateFeatures()
    {
        inherited(); local ids = [];
        foreach (local exposure in self.phobiaExposures)
        {
            if (exposure == nil || !exposure.ofKind(RpgExpandedPhobiaExposure) || exposure.profile != self
                || holds(ids,exposure.id) || exposure.assess().status != 'reused') rpgExpandedReject('phobia-profile-history');
            ids = ids + [exposure.id];
        }
        return nil;
    }
;

modify RpgExpandedProfile
    postCreationDisadvantageAllowance()
    {
        local value = inherited(); local belowBaselineLosses = 0;
        foreach (local compound in self.fearBeliefCompounds)
            if (compound.tableTotal == 40)
            {
                compound.assess();
                if (compound.iqAfter < 10) belowBaselineLosses += 1;
            }
        local currentDeficit = self.iq < 10 ? 10-self.iq : 0;
        if (belowBaselineLosses > currentDeficit) belowBaselineLosses = currentDeficit;
        return value + belowBaselineLosses*20;
    }
;

/** B361 row 33: retained severity, authored reaction, then survivor Will. */
class RpgExpandedExtremePanic: RpgExpandedFearTraitConsequence
    id = nil
    context = nil
    approved = nil
    evidence = nil
    initialSeverity = nil
    pendingSeverity = nil
    startedAt = nil
    completedAt = nil
    boundDefinition = nil
    reactions = []
    settlingReaction = nil
    definition()
    {
        if (self.id == nil || self.id == '' || self.context == nil || !self.context.ofKind(RpgExpandedFearContext))
            rpgExpandedReject('extreme-panic-definition');
        return [self.id,self.context,self.context.profile,self.approved,self.evidence,self.initialSeverity,self.startedAt];
    }
    assess()
    {
        local facts = self.definition(); local value = new RpgExpandedResult(); local profile = self.context.profile;
        if (self.startedAt != nil)
        {
            if (!holds(profile.extremePanicHistory,self) || self.boundDefinition == nil
                || facts.length() != self.boundDefinition.length()) rpgExpandedReject('extreme-panic-history');
            for (local i = 1; i <= facts.length(); i += 1)
                if (facts[i] != self.boundDefinition[i]) rpgExpandedReject('extreme-panic-binding');
            local pending = self.initialSeverity; local ended = nil; local ids = [];
            foreach (local reaction in self.reactions)
            {
                reaction.validateReceipt();
                if (reaction.episode != self || reaction.severity != pending || ended != nil || holds(ids,reaction.id))
                    rpgExpandedReject('extreme-panic-reaction-sequence');
                ids = ids + [reaction.id]; pending = reaction.nextSeverity;
                if (pending == nil) ended = reaction.finishedAt;
            }
            if (pending != self.pendingSeverity || ended != self.completedAt
                || ended == nil && profile.extremePanic != self || ended != nil && profile.extremePanic == self)
                rpgExpandedReject('extreme-panic-owner');
            value.status = 'reused'; return value;
        }
        if (self.boundDefinition != nil || self.initialSeverity != nil || self.pendingSeverity != nil
            || self.completedAt != nil || self.reactions.length() != 0 || self.settlingReaction != nil)
            rpgExpandedReject('extreme-panic-uncommitted');
        if (!self.approved || self.evidence == nil || self.evidence == '') { value.reason = 'extreme-panic-evidence'; return value; }
        local scene = self.context.consequenceAssessment();
        if (scene.status != 'ready') { value.reason = scene.reason; return value; }
        if (scene.immune || profile.dead || profile.unconscious || profile.extremePanic != nil || profile.activeFearPanic())
        { value.reason = 'extreme-panic-unavailable'; return value; }
        foreach (local prior in profile.extremePanicHistory)
            if (prior.id == self.id) rpgExpandedReject('extreme-panic-duplicate');
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.initialSeverity = rpgRandom.roll(); self.pendingSeverity = self.initialSeverity;
        self.startedAt = rpgLedger.seconds; self.boundDefinition = self.definition();
        self.context.profile.extremePanicHistory = self.context.profile.extremePanicHistory + [self];
        self.context.profile.extremePanic = self; value.status = 'resolved'; return value;
    }
    fearEventMatches(entry) { return entry.selectedRow() == 33 && entry.id == self.id && entry.context == self.context; }
;
/** Explicit supported reactions, with real shared time/drop/injury effects. No generic completion callback. */
class RpgExpandedExtremePanicReaction: object
    recoveryDecision = nil
    id = nil
    episode = nil
    severity = nil
    kind = nil
    description = nil
    approved = nil
    seconds = 1
    operation = nil
    wound = nil
    actor = nil
    origin = nil
    destination = nil
    distanceYards = 0
    routeEvidence = nil
    dropDestination = nil
    result = nil
    startedAt = nil
    finishedAt = nil
    nextSeverity = nil
    boundDefinition = nil
    boundOutcome = nil
    definition()
    {
        local facts = [self.id,self.episode,self.severity,self.kind,self.description,self.approved,self.seconds,self.wound,self.dropDestination,
            self.actor,self.origin,self.destination,self.distanceYards,self.routeEvidence,self.operation];
        if (self.operation != nil)
        {
            if (!self.operation.ofKind(RpgExpandedPanicOperation)) rpgExpandedReject('panic-operation-type');
            facts = facts + self.operation.facts(self);
        }
        return facts;
    }
    outcomeFacts()
    {
        local check = self.result.check;
        local facts = [self.result,self.result.status,self.startedAt,self.finishedAt,self.nextSeverity,check];
        if (check != nil) facts = facts + [check.score,check.roll,check.margin,check.achieved,check.critical];
        return facts;
    }
    validateReceipt()
    {
        if (self.result == nil || self.boundDefinition == nil || self.boundOutcome == nil) rpgExpandedReject('panic-reaction-receipt');
        local facts = self.definition();
        if (facts.length() != self.boundDefinition.length()) rpgExpandedReject('panic-reaction-binding');
        for (local i = 1; i <= facts.length(); i += 1)
            if (facts[i] != self.boundDefinition[i]) rpgExpandedReject('panic-reaction-binding');
        facts = self.outcomeFacts();
        if (facts.length() != self.boundOutcome.length()) rpgExpandedReject('panic-reaction-outcome');
        for (local i = 1; i <= facts.length(); i += 1)
            if (facts[i] != self.boundOutcome[i]) rpgExpandedReject('panic-reaction-outcome');
        if (self.result.check != nil && self.result.check.ofKind(RpgExpandedAuthoredRecoveryResult))
        {
            if (self.recoveryDecision != self.result.check.decision) rpgExpandedReject('fear-recovery-ruling-changed');
            self.result.check.validate(self);
        }
        else if (self.recoveryDecision != nil) rpgExpandedReject('fear-recovery-ruling-added');
        if (self.operation != nil) self.operation.validateReceipt(self);
        if (self.wound != nil && self.wound.assess().status != 'reused') rpgExpandedReject('panic-reaction-injury-receipt');
        return nil;
    }
    assess()
    {
        local value = new RpgExpandedFearFaintResult();
        if (self.id == nil || self.id == '' || self.episode == nil || !self.episode.ofKind(RpgExpandedExtremePanic))
            rpgExpandedReject('panic-reaction-definition');
        if (self.result != nil)
        {
            if (self.result.check != nil && self.result.check.ofKind(RpgExpandedAuthoredRecoveryResult))
            {
                if (self.recoveryDecision != self.result.check.decision) rpgExpandedReject('fear-recovery-ruling-changed');
                self.result.check.validate(self);
            }
            else if (self.recoveryDecision != nil) rpgExpandedReject('fear-recovery-ruling-added');
            self.validateReceipt();
            if (!holds(self.episode.reactions,self)) rpgExpandedReject('panic-reaction-history');
            value.status = 'reused'; return value;
        }
        if (self.boundDefinition != nil || self.boundOutcome != nil || self.startedAt != nil || self.finishedAt != nil || self.nextSeverity != nil)
            rpgExpandedReject('panic-reaction-uncommitted');
        if (self.episode.assess().status != 'reused' || self.episode.completedAt != nil)
        { value.reason = 'panic-reaction-active-episode'; return value; }
        rpgInteger(self.severity,3,18); rpgInteger(self.seconds,1,86400); rpgInteger(rpgLedger.seconds,0,2147483647-self.seconds);
        if (self.severity != self.episode.pendingSeverity) rpgExpandedReject('panic-reaction-severity');
        if (!self.approved || self.description == nil || self.description == '') { value.reason = 'panic-reaction-author-choice'; return value; }
        if (!holds(['freeze','cry','collapse','flight','world-operation'],self.kind)) rpgExpandedReject('panic-reaction-kind-unsupported');
        local profile = self.episode.context.profile;
        if (profile.dead) { value.reason = 'panic-reaction-dead'; return value; }
        if (self.kind == 'world-operation')
        {
            if (self.operation == nil || !self.operation.ofKind(RpgExpandedPanicOperation) || self.operation.profile != profile)
                rpgExpandedReject('panic-operation-owner');
            local operation = self.operation.assess(self);
            if (operation.status == 'reused') rpgExpandedReject('panic-operation-used');
            if (operation.status != 'ready') return operation;
        }
        else if (self.operation != nil) rpgExpandedReject('panic-operation-unused');
        if (self.kind == 'flight')
        {
            if (self.actor == nil || !self.actor.ofKind(Actor) || self.actor.rpgProfile != profile
                || self.origin == nil || !self.origin.ofKind(Room) || self.destination == nil || !self.destination.ofKind(Room)
                || self.origin == self.destination) rpgExpandedReject('panic-flight-world-facts');
            rpgInteger(self.distanceYards,1,1000000);
            if (self.routeEvidence == nil || self.routeEvidence == '') { value.reason = 'panic-flight-route-evidence'; return value; }
            if (location.get(self.actor) != self.origin) { value.reason = 'panic-flight-origin-changed'; return value; }
            if (profile.unconscious || !holds(['standing','crouching'],profile.posture) || profile.fatigue >= profile.maxEnergy)
            { value.reason = 'panic-flight-mobility-unavailable'; return value; }
            value.reason = profile.panicRelocationReason(); if (value.reason != nil) return value;
            for (local battle = firstObj(RpgLiteBattle); battle != nil; battle = nextObj(battle,RpgLiteBattle))
                if (battle.active)
                    foreach (local fighter in battle.fighters)
                        if (fighter.profile == profile) { value.reason = 'panic-flight-combat-route-required'; return value; }
            if (self.distanceYards > profile.move()*self.seconds) { value.reason = 'panic-flight-distance'; return value; }
        }
        else if (self.actor != nil || self.origin != nil || self.destination != nil || self.distanceYards != 0 || self.routeEvidence != nil)
            rpgExpandedReject('panic-reaction-unused-route');
        foreach (local prior in self.episode.reactions)
            if (prior.id == self.id) rpgExpandedReject('panic-reaction-duplicate');
        value.reason = rpgExpandedFearRecoveryReason(self,profile.attributeScore(rpgWill)); if (value.reason != nil) return value;
        if (self.wound != nil)
        {
            if (self.kind != 'collapse' || !self.wound.ofKind(RpgExpandedWound) || self.wound.profile != profile
                || self.wound.dropDestination != self.dropDestination) rpgExpandedReject('panic-reaction-wound-owner');
            local injury = self.wound.assess();
            if (injury.status == 'reused') rpgExpandedReject('panic-reaction-used-injury');
            if (injury.status != 'ready') { value.reason = injury.reason; return value; }
        }
        if (self.kind == 'collapse')
        {
            value.dropPlan = profile.prepareKnockdownDrop(self.dropDestination);
            if (value.dropPlan != nil && value.dropPlan.status != 'ready') { value.reason = value.dropPlan.reason; return value; }
        }
        else if (self.dropDestination != nil) rpgExpandedReject('panic-reaction-unexpected-drop');
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local profile = self.episode.context.profile; local facts = self.definition(); local start = rpgLedger.seconds;
        local clockSeconds = self.operation == nil ? self.seconds : self.operation.clockSeconds(self);
        self.episode.settlingReaction = self;
        if (self.operation == nil || !self.operation.ownsTime) rpgSpendTime(self.seconds);
        if (profile.dead) rpgExpandedReject('panic-reaction-time-changed');
        if (self.operation != nil && self.operation.apply(self).status != 'resolved') rpgExpandedReject('panic-operation-changed');
        self.episode.settlingReaction = nil;
        if (rpgLedger.seconds != start+clockSeconds) rpgExpandedReject('panic-operation-time');
        if (self.kind == 'flight')
        {
            if (location.get(self.actor) != self.origin || profile.unconscious || profile.fatigue >= profile.maxEnergy
                || !holds(['standing','crouching'],profile.posture) || self.distanceYards > profile.move()*self.seconds
                || profile.panicRelocationReason() != nil) rpgExpandedReject('panic-flight-state-changed');
            relocateActor(self.actor,self.destination);
        }
        if (value.dropPlan != nil) value.dropPlan.commit();
        if (self.wound != nil && self.wound.apply().status != 'resolved') rpgExpandedReject('panic-reaction-injury-changed');
        if (self.kind == 'collapse') profile.posture = 'lying';
        if (!profile.dead)
        {
            value.check = rpgExpandedFearRecoveryRoll(self,profile.attributeScore(rpgWill));
            if (!value.check.achieved) self.nextSeverity = rpgRandom.roll();
        }
        self.startedAt = start; self.finishedAt = rpgLedger.seconds; self.boundDefinition = facts;
        value.status = 'resolved'; self.result = value; self.boundOutcome = self.outcomeFacts();
        self.episode.pendingSeverity = self.nextSeverity; self.episode.reactions = self.episode.reactions + [self];
        if (self.nextSeverity == nil) { self.episode.completedAt = self.finishedAt; profile.extremePanic = nil; }
        return value;
    }
;
modify RpgExpandedProfile
    extremePanic = nil
    extremePanicHistory = []
    healthEffortReasonFor(purpose,mentalAbility,speech,movement,authorization)
    {
        if (self.extremePanic != nil && !self.panicAuthorization(authorization))
        { self.extremePanic.assess(); return 'extreme-panic-reaction-required'; }
        return inherited(purpose,mentalAbility,speech,movement,authorization);
    }
    healthManeuverReasonFor(kind,request)
    {
        if (self.extremePanic != nil && !self.panicAuthorization(request))
        { self.extremePanic.assess(); return 'extreme-panic-reaction-required'; }
        return inherited(kind,request);
    }
;
modify rpgLedger
    validateAdvance(seconds)
    {
        inherited(seconds);
        if (seconds > 0)
            for (local episode = firstObj(RpgExpandedExtremePanic); episode != nil; episode = nextObj(episode,RpgExpandedExtremePanic))
                if (episode.startedAt != nil && episode.completedAt == nil && !episode.context.profile.dead && episode.settlingReaction == nil && !episode.permitsBattleClock(self.panicBattleAdvance))
                    rpgExpandedReject('extreme-panic-reaction-required');
        return nil;
    }
;
modify RpgExpandedProfile
    validateFeatures()
    {
        inherited(); local ids = [];
        foreach (local episode in self.extremePanicHistory)
        {
            if (episode == nil || !episode.ofKind(RpgExpandedExtremePanic) || episode.context.profile != self
                || holds(ids,episode.id) || episode.assess().status != 'reused') rpgExpandedReject('extreme-panic-profile-history');
            ids = ids + [episode.id];
        }
        return nil;
    }
;

/** Author-confirmed interruption of perception during actual unconsciousness. */
class RpgExpandedPhobiaAwarenessPause: object
    id = nil
    exposure = nil
    approved = nil
    evidence = nil
    startedAt = nil
    resumedAt = nil
    resumeEvidence = nil
    afterChecks = nil
    boundDefinition = nil
    boundResume = nil
    definition() { return [self.id,self.exposure,self.approved,self.evidence,self.startedAt,self.afterChecks]; }
    validateReceipt()
    {
        if (self.boundDefinition == nil || !holds(self.exposure.awarenessPauses,self)) rpgExpandedReject('phobia-pause-history');
        local facts = self.definition();
        for (local i = 1; i <= facts.length(); i += 1)
            if (facts[i] != self.boundDefinition[i]) rpgExpandedReject('phobia-pause-binding');
        if (self.boundResume == nil && (self.resumedAt != nil || self.resumeEvidence != nil)
            || self.boundResume != nil && (self.resumedAt != self.boundResume[1] || self.resumeEvidence != self.boundResume[2]))
            rpgExpandedReject('phobia-pause-resume-binding');
        return nil;
    }
    begin()
    {
        local value = new RpgExpandedResult();
        if (self.id == nil || self.id == '' || self.exposure == nil || !self.exposure.ofKind(RpgExpandedPhobiaExposure))
            rpgExpandedReject('phobia-pause-definition');
        if (self.startedAt != nil) { self.validateReceipt(); value.status = 'reused'; return value; }
        if (self.resumedAt != nil || self.resumeEvidence != nil || self.afterChecks != nil || self.boundDefinition != nil || self.boundResume != nil)
            rpgExpandedReject('phobia-pause-uncommitted');
        if (self.exposure.assess().status != 'reused' || self.exposure.endedAt != nil || self.exposure.awarenessPaused()
            || !self.exposure.profile.unconscious || self.exposure.profile.dead || !self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'phobia-pause-unconscious-perception-evidence'; return value; }
        foreach (local prior in self.exposure.awarenessPauses)
            if (prior.id == self.id) rpgExpandedReject('phobia-pause-duplicate');
        if (rpgLedger.seconds > self.exposure.nextCheckAt()) rpgExpandedReject('phobia-pause-overdue');
        self.startedAt = rpgLedger.seconds; self.afterChecks = self.exposure.checks.length(); self.boundDefinition = self.definition();
        self.exposure.awarenessPauses = self.exposure.awarenessPauses + [self]; value.status = 'resolved'; return value;
    }
    resume(approved,evidence)
    {
        self.validateReceipt(); local value = new RpgExpandedResult();
        if (self.resumedAt != nil) { value.status = 'reused'; return value; }
        if (!approved || evidence == nil || evidence == '' || self.exposure.profile.dead || self.exposure.profile.unconscious || self.exposure.endedAt != nil)
        { value.reason = 'phobia-pause-resume-perception-evidence'; return value; }
        rpgInteger(rpgLedger.seconds,0,2147483047);
        self.resumedAt = rpgLedger.seconds; self.resumeEvidence = evidence; self.boundResume = [self.resumedAt,evidence];
        value.status = 'resolved'; return value;
    }
;
modify RpgExpandedPhobiaExposure
    awarenessPauses = []
    awarenessPaused()
    {
        foreach (local pause in self.awarenessPauses)
        { pause.validateReceipt(); if (pause.resumedAt == nil) return true; }
        return nil;
    }
    checkDueAfter(count)
    {
        local due = count == 0 ? self.startedAt : self.checks[count].recordedAt+600;
        foreach (local pause in self.awarenessPauses)
            if (pause.afterChecks == count)
            {
                pause.validateReceipt();
                if (pause.resumedAt == nil) return nil;
                due = pause.resumedAt;
            }
        return due;
    }
    nextCheckAt() { return self.checkDueAfter(self.checks.length()); }
;

/** B360: explicit author replacement/reroll of an inappropriate retained result. */
class RpgExpandedFearAdjudication: object
    id = nil
    entry = nil
    mode = 'replace'
    row = nil
    reason = 'inappropriate'
    approved = nil
    evidence = nil
    result = nil
    selected = nil
    tableRoll = nil
    recordedAt = nil
    boundDefinition = nil
    boundOutcome = nil
    definition() { return [self.id,self.entry,self.mode,self.row,self.reason,self.approved,self.evidence]; }
    validateReceipt()
    {
        if (self.result == nil || self.boundDefinition == nil || self.boundOutcome == nil) rpgExpandedReject('fear-adjudication-receipt');
        local facts = self.definition();
        for (local i = 1; i <= facts.length(); i += 1)
            if (facts[i] != self.boundDefinition[i]) rpgExpandedReject('fear-adjudication-binding');
        if (self.selected != self.boundOutcome[1] || self.tableRoll != self.boundOutcome[2]
            || self.recordedAt != self.boundOutcome[3] || self.result != self.boundOutcome[4]) rpgExpandedReject('fear-adjudication-outcome');
        return nil;
    }
    assess()
    {
        local value = new RpgExpandedResult();
        if (self.id == nil || self.id == '' || self.entry == nil || !self.entry.ofKind(RpgExpandedFearEvent))
            rpgExpandedReject('fear-adjudication-definition');
        if (self.result != nil)
        {
            self.validateReceipt();
            if (!holds(self.entry.adjudications,self)) rpgExpandedReject('fear-adjudication-history');
            value.status = 'reused'; return value;
        }
        if (self.selected != nil || self.tableRoll != nil || self.recordedAt != nil || self.boundDefinition != nil || self.boundOutcome != nil)
            rpgExpandedReject('fear-adjudication-uncommitted');
        if (!holds(['replace','reroll'],self.mode) || !holds(['inappropriate','awe','confusion'],self.reason))
            rpgExpandedReject('fear-adjudication-choice');
        if (self.mode == 'replace') rpgInteger(self.row,4,40);
        else if (self.row != nil) rpgExpandedReject('fear-adjudication-reroll-row');
        if (!self.approved || self.evidence == nil || self.evidence == '') { value.reason = 'fear-adjudication-author-reason'; return value; }
        if (self.entry.assess().status != 'reused' || self.entry.result.row == nil || self.entry.consequence != nil
            || self.entry.recordedAt != rpgLedger.seconds) { value.reason = 'fear-adjudication-pending-event'; return value; }
        if (self.mode == 'reroll' && self.entry.result.check == nil)
        { value.reason = 'fear-adjudication-no-rolled-margin'; return value; }
        foreach (local prior in self.entry.adjudications)
            if (prior.id == self.id) rpgExpandedReject('fear-adjudication-duplicate');
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.boundDefinition = self.definition();
        if (self.mode == 'replace') self.selected = self.row;
        else
        {
            self.tableRoll = rpgRandom.roll();
            self.selected = rpgExpandedFearTable(self.tableRoll-self.entry.result.check.margin).row;
        }
        self.recordedAt = rpgLedger.seconds; value.status = 'resolved'; self.result = value;
        self.boundOutcome = [self.selected,self.tableRoll,self.recordedAt,self.result];
        self.entry.adjudications = self.entry.adjudications + [self]; self.entry.adjudicationCount += 1; return value;
    }
;
modify RpgExpandedFearEvent
    adjudications = []
    adjudicationCount = 0
    selectedRow()
    {
        if (self.result == nil) return nil;
        local row = self.result.row; local ids = [];
        if (self.adjudicationCount != self.adjudications.length()) rpgExpandedReject('fear-adjudication-count');
        foreach (local decision in self.adjudications)
        {
            decision.validateReceipt();
            if (decision.entry != self || decision.recordedAt != self.recordedAt || holds(ids,decision.id))
                rpgExpandedReject('fear-adjudication-event-history');
            ids = ids + [decision.id]; row = decision.selected;
        }
        return row;
    }
    assess()
    {
        if (self.result == nil && (self.adjudications.length() != 0 || self.adjudicationCount != 0)) rpgExpandedReject('fear-adjudication-without-event');
        local value = inherited(); if (self.result != nil) self.selectedRow(); return value;
    }
;

/** One owner-authorized operation shared by parser, structured and dialogue routes. */
class RpgExpandedFearAction: Action
    entry = nil
    consequence = nil
    operation = 'resolve'
    perform(actor)
    {
        if (self.entry == nil || !self.entry.ofKind(RpgExpandedFearEvent) || self.entry.context == nil
            || !holds(['preview','resolve','preview-consequence','consequence'],self.operation))
            rpgExpandedReject('fear-action-definition');
        local value = new RpgExpandedResult();
        if (actor == nil || !actor.ofKind(Thing) || actor.rpgProfile == nil || actor.rpgProfile != self.entry.context.profile)
            value.reason = 'fear-action-owner-required';
        else if (self.operation == 'preview') value = self.entry.assess();
        else if (self.operation == 'resolve') value = self.entry.resolve();
        else if (self.operation == 'preview-consequence') value = self.entry.assessConsequence(self.consequence);
        else value = self.entry.applyConsequence(self.consequence);
        event('rpg.expanded.fear'); eventValue(self.operation); eventValue(value.status); eventValue(value.reason);
        return value;
    }
    exec(context) { return self.perform(context.actor); }
;

/** The action retains the world facts used by its voluntary phobia permission. */
modify RpgExpandedEffort
    phobiaActivity = nil
    boundPhobiaActivityFacts = nil
    phobiaActivityFacts()
    {
        if (self.phobiaActivity == nil) return [nil];
        if (!self.phobiaActivity.ofKind(RpgExpandedPhobiaActivityContract) || self.phobiaActivity.profile != self.profile
            || !holds(['action','talk'],self.purpose)) rpgExpandedReject('effort-phobia-activity-owner');
        return [self.phobiaActivity] + self.phobiaActivity.activityFacts();
    }
    assess()
    {
        local facts = self.phobiaActivityFacts();
        if (self.result != nil)
        {
            if (self.boundPhobiaActivityFacts == nil || facts.length() != self.boundPhobiaActivityFacts.length())
                rpgExpandedReject('effort-phobia-activity-binding');
            for (local i = 1; i <= facts.length(); i += 1)
                if (facts[i] != self.boundPhobiaActivityFacts[i]) rpgExpandedReject('effort-phobia-activity-binding');
        }
        else
        {
            if (self.boundPhobiaActivityFacts != nil) rpgExpandedReject('effort-phobia-activity-uncommitted');
            if (self.phobiaActivity != nil)
            {
                local permission = self.phobiaActivity.assess();
                if (permission.status != 'ready') { local value = new RpgExpandedEffortResult(); value.reason = permission.reason; return value; }
            }
        }
        return inherited();
    }
    apply()
    {
        local replay = self.result != nil; local facts = self.phobiaActivityFacts(); local value = inherited();
        if (!replay && value.status == 'resolved') self.boundPhobiaActivityFacts = facts;
        return value;
    }
;

/** B148: an explicitly frightening cue from an owned disturbing-voice episode. */
class RpgExpandedVoiceFearContext: RpgExpandedFearContext
    voiceOccurrence = nil
    cue = nil
    eventFacts()
    {
        if (self.cue == nil) rpgExpandedReject('voice-fear-cue');
        return inherited() + [self.cue] + self.profile.voiceFearFacts(self.voiceOccurrence);
    }
    assess()
    {
        self.eventFacts(); local reason = self.profile.voiceFearReason(self.voiceOccurrence);
        if (reason != nil) { local value = new RpgExpandedFearAssessment(); value.reason = reason; return value; }
        return inherited();
    }
;

/** A retained low-score decision authorizes its consequence, never an initial roll. */
modify RpgExpandedFearContext
    consequenceAssessment()
    {
        local value = self.assess();
        if (value.status == 'ready') return value;
        if (value.score == nil || value.score >= 3 || !holds(['fear-score-unavailable',
            'phobia-control-unavailable','postbattle-self-control-unavailable'],value.reason)) return value;
        foreach (local entry in self.profile.fearEvents)
        {
            if (entry.context == self && entry.result != nil && entry.result.reason == 'author-selected-low-score'
                && entry.consequence == nil && entry.recordedAt == rpgLedger.seconds)
            {
                entry.assess(); local initial = entry.eventAssessment();
                if (initial.status == 'ready' && initial.score == entry.result.score && initial.modifier == entry.result.modifier)
                { value.status = 'ready'; value.reason = nil; return value; }
            }
        }
        return value;
    }
;


/** Same-effect overlap is an explicit campaign ruling, retained with each episode. */
modify RpgExpandedProfile
    fearAftermathOverlapPolicy = nil
    fearAftermathOverlapEvidence = nil
    fearAftermathOverlapConfigured()
    {
        if (self.fearAftermathOverlapPolicy == nil && self.fearAftermathOverlapEvidence == nil) return nil;
        if (!holds(['sum','worst'],self.fearAftermathOverlapPolicy) || self.fearAftermathOverlapEvidence == nil
            || self.fearAftermathOverlapEvidence == '') rpgExpandedReject('fear-aftermath-policy');
        return true;
    }
    healthAttributeModifier(context)
    {
        local value = inherited(context); self.fearAftermathOverlapConfigured();
        if (self.fearAftermathOverlapPolicy == 'worst')
        {
            local active = nil;
            foreach (local episode in self.fearComaHistory)
                if (episode.recoveredAt != nil && rpgLedger.seconds < episode.recoveredAt + 21600) active = true;
            foreach (local episode in self.catatoniaHistory)
                if (episode.recoveredAt != nil && rpgLedger.seconds < episode.recoveredAt + episode.recoveredAt-episode.startedAt) active = true;
            if (active) value -= 2;
        }
        return value;
    }
;
modify RpgExpandedFearEvent
    consequenceBoundaryReason()
    {
        local row = self.selectedRow(); local profile = self.context.profile;
        if (row == 31)
        {
            if (profile.ht <= 1) return 'fear-minimum-health-author-adjudication';
            local context = new RpgLiteContext(); context.attribute = rpgHT; context.kind = 'fear-seizure-health';
            local score = rpgLiteScore(profile,context);
            if (score == nil || score < 3) return 'fear-seizure-health-author-adjudication';
        }
        if (row == 40 && profile.iq <= 1) return 'fear-minimum-iq-author-adjudication';
        return nil;
    }
    assessConsequence(request)
    {
        if (self.result != nil && self.consequence == nil)
        {
            self.assess(); local reason = self.consequenceBoundaryReason();
            if (reason != nil) { local value = new RpgExpandedResult(); value.reason = reason; return value; }
        }
        return inherited(request);
    }
;

modify RpgExpandedProfile
    fearAftermathActive()
    {
        foreach (local episode in self.fearComaHistory)
            if (episode.recoveredAt != nil && rpgLedger.seconds < episode.recoveredAt + 21600) return true;
        foreach (local episode in self.catatoniaHistory)
            if (episode.recoveredAt != nil && rpgLedger.seconds < episode.recoveredAt + episode.recoveredAt-episode.startedAt) return true;
        return nil;
    }
;
modify RpgExpandedCatatonia
    nextNeglectInjury()
    {
        if (self.neglectPolicy != 'uncared-days') return self.days.length()+1;
        local count = 1;
        foreach (local day in self.days) if (!day.careProvided) count += 1;
        return count;
    }
;


/** B345 recovery boundary: author ruling when the required roll cannot be attempted. */
class RpgExpandedFearRecoveryDecision: object
    owner = nil
    recover = nil
    approved = nil
    evidence = nil
    facts() { return [self,self.owner,self.recover,self.approved,self.evidence]; }
;
class RpgExpandedAuthoredRecoveryResult: RpgResult
    decision = nil
    boundFacts = nil
    validate(owner)
    {
        if (self.decision == nil || self.decision.owner != owner || self.boundFacts == nil) rpgExpandedReject('fear-recovery-ruling-owner');
        local facts = self.decision.facts() + [self.score,self.achieved,self.roll,self.margin,self.critical,self.reason];
        if (facts.length() != self.boundFacts.length()) rpgExpandedReject('fear-recovery-ruling-binding');
        for (local i = 1; i <= facts.length(); i += 1)
            if (facts[i] != self.boundFacts[i]) rpgExpandedReject('fear-recovery-ruling-binding');
        return nil;
    }
;
rpgExpandedFearRecoveryReason(owner,score)
{
    local decision = owner.recoveryDecision;
    if (score == nil || score > 1000) return 'fear-recovery-score-unavailable';
    if (score >= 3) return decision == nil ? nil : 'fear-recovery-ruling-inapplicable';
    if (decision == nil) return 'fear-recovery-author-decision-required';
    if (!decision.ofKind(RpgExpandedFearRecoveryDecision) || decision.owner != owner) rpgExpandedReject('fear-recovery-ruling-owner');
    if (!decision.approved || decision.evidence == nil || decision.evidence == '') return 'fear-recovery-author-evidence';
    return nil;
}
rpgExpandedFearRecoveryRoll(owner,score)
{
    local reason = rpgExpandedFearRecoveryReason(owner,score); if (reason != nil) rpgExpandedReject(reason);
    if (score >= 3) return rpgCheck(score,rpgRandom.roll());
    local value = new RpgExpandedAuthoredRecoveryResult(); value.decision = owner.recoveryDecision;
    value.score = score; value.achieved = value.decision.recover; value.rollSucceeded = nil;
    value.status = 'resolved'; value.reason = 'author-selected-recovery'; value.outcome = value.achieved ? 'success' : 'setback';
    value.boundFacts = value.decision.facts() + [value.score,value.achieved,value.roll,value.margin,value.critical,value.reason];
    return value;
}
rpgExpandedFearRecoveryCheck(owner,profile,context)
{
    local score = rpgLiteScore(profile,context);
    if (score != nil && score >= 3 && owner.recoveryDecision == nil) return rpgLiteCheck(profile,context);
    return rpgExpandedFearRecoveryRoll(owner,score);
}

/** Explicit panic authorization travels with the request; preview never changes profile state. */
class RpgExpandedPanicActionGate: RpgExpandedActionGate
    panicReaction = nil
    healthPermissionReason()
    {
        if (!self.profile.panicAuthorization(self)) return 'panic-permission-owner';
        return self.profile.healthEffortReasonFor(self.purpose,self.mentalAbility,self.requiresSpeech,self.requiresMovement,self);
    }
;
class RpgExpandedPanicPathManeuver: RpgExpandedPathMoveManeuver
    panicReaction = nil
;
modify RpgExpandedProfile
    panicAuthorization(request)
    {
        if (request == nil || self.extremePanic == nil) return nil;
        local reaction = request.panicReaction;
        if (reaction == nil || !reaction.ofKind(RpgExpandedExtremePanicReaction)
            || reaction.episode != self.extremePanic || reaction.result != nil
            || reaction.episode.completedAt != nil || reaction.severity != reaction.episode.pendingSeverity
            || !reaction.approved || reaction.operation == nil) return nil;
        return reaction.operation.permitsAuthorization(request);
    }
    healthManeuverRequestReason(request)
    {
        if (self.panicAuthorization(request)) return self.healthManeuverReasonFor(request.kind,request);
        return inherited(request);
    }
;
modify RpgExpandedExtremePanic
    permitsBattleClock(battle)
    {
        if (battle == nil || self.reactions.length() == 0) return nil;
        self.assess(); local reaction = self.reactions[self.reactions.length()];
        return reaction.operation != nil && reaction.operation.permitsBattleClock(battle);
    }
;
modify rpgLedger panicBattleAdvance = nil;
modify RpgLiteBattle
    advanceClock()
    {
        local prior = rpgLedger.panicBattleAdvance; rpgLedger.panicBattleAdvance = self;
        try { inherited(); }
        catch (RpgError error) { rpgLedger.panicBattleAdvance = prior; throw error; }
        rpgLedger.panicBattleAdvance = prior; return nil;
    }
;

/** Recorded ordinary attack adjudication. Scores/dice and final injury are supplied
 * by the author; permission, equipment, injury and the battle clock are committed here.
 * This is not the automatic expanded attack resolver. */
class RpgExpandedAdjudicatedStrike: object
    id = nil
    attacker = nil
    defender = nil
    weapon = nil
    mode = nil
    attackScore = nil
    attackRoll = nil
    basicDamage = 0
    defenseKind = nil
    defenseScore = nil
    defenseRoll = nil
    criticalConsequence = nil
    defenseConsequence = nil
    committingDefense = nil
    defenseWaivedEvidence = nil
    wound = nil
    unready = nil
    approved = nil
    legalityEvidence = nil
    resolutionEvidence = nil
    result = nil
    boundFacts = nil
    boundOutcome = nil
    ammunitionBefore = nil
    facts()
    {
        if (self.id == nil || self.id == '' || self.attacker == nil || !self.attacker.ofKind(RpgLiteFighter)
            || self.defender == nil || !self.defender.ofKind(RpgLiteFighter) || self.attacker == self.defender
            || !self.attacker.profile.ofKind(RpgExpandedProfile) || !self.defender.profile.ofKind(RpgExpandedProfile)
            || self.weapon == nil || !self.weapon.ofKind(RpgLiteWeapon) || self.mode == nil || !self.mode.ofKind(RpgLiteAttackMode))
            rpgExpandedReject('adjudicated-strike-definition');
        local facts = [self,self.id,self.attacker,self.defender,self.attacker.profile,self.defender.profile,
            self.weapon,self.mode,self.mode.ranged,self.mode.thrown,self.attackScore,self.attackRoll,self.basicDamage,
            self.defenseKind,self.defenseScore,self.defenseRoll,self.defenseWaivedEvidence,self.wound,
            self.unready,self.approved,self.legalityEvidence,self.resolutionEvidence];
        if (self.wound != nil)
        {
            if (!self.wound.ofKind(RpgExpandedWound) || self.wound.profile != self.defender.profile)
                rpgExpandedReject('adjudicated-strike-wound-owner');
            facts = facts + [self.wound.id,self.wound.amount,self.wound.location,self.wound.bodyPart,
                self.wound.severing,self.wound.maleGroin,self.wound.dropDestination,self.wound.anatomy,
                self.wound.criticalHit,self.wound.forceMajorWound];
        }
        if (self.criticalConsequence != nil)
        {
            if (!self.criticalConsequence.ofKind(RpgExpandedStrikeCriticalHit)) rpgExpandedReject('adjudicated-strike-critical-consequence');
            facts = facts + self.criticalConsequence.facts(self);
        }
        else facts = facts + [nil];
        if (self.defenseConsequence != nil)
        {
            if (!self.defenseConsequence.ofKind(RpgExpandedStrikeDefenseConsequence)) rpgExpandedReject('adjudicated-strike-defense-consequence');
            facts = facts + self.defenseConsequence.facts(self);
        }
        else facts = facts + [nil];
        return facts;
    }
    classified()
    {
        rpgInteger(self.attackScore,3,1000); rpgInteger(self.attackRoll,3,18);
        rpgInteger(self.basicDamage,0,1000000);
        local value = new RpgLiteCombatResult(); value.attackMode = self.mode; value.damage = self.basicDamage;
        value.attack = rpgExpandedCombatCheck(self.mode.ranged ? 'ranged' : 'melee',self.attackScore,self.attackRoll);
        if (value.attack.critical == 'failure' || value.attack.critical == 'success' && self.criticalConsequence == nil)
        { value.reason = 'adjudicated-strike-critical-adapter-required'; return value; }
        if (value.attack.critical == 'success')
        {
            if (self.defenseKind != nil || self.defenseScore != nil || self.defenseRoll != nil
                || self.defenseWaivedEvidence != nil || self.defenseConsequence != nil)
                rpgExpandedReject('adjudicated-strike-critical-no-defense');
            local critical = self.criticalConsequence.assess(self);
            if (critical.status != 'ready') { value.reason = critical.reason; return value; }
        }
        else if (self.criticalConsequence != nil) rpgExpandedReject('adjudicated-strike-unused-critical-consequence');
        value.outcome = value.attack.achieved ? 'hit' : 'miss';
        if (self.defenseKind != nil)
        {
            if (!value.attack.achieved || !holds(['dodge','parry','block'],self.defenseKind)
                || self.defenseWaivedEvidence != nil) rpgExpandedReject('adjudicated-strike-defense-definition');
            local check = rpgExpandedCombatCheck('defense',self.defenseScore,self.defenseRoll);
            if (check.critical == 'success' && (!self.mode.ranged || self.mode.thrown))
            { value.reason = 'adjudicated-strike-critical-defense-required'; return value; }
            if (check.critical == 'failure')
            {
                if (self.defenseConsequence == nil) { value.reason = 'adjudicated-strike-critical-defense-required'; return value; }
                local consequence = self.defenseConsequence.assess(self);
                if (consequence.status != 'ready')
                { value.reason = consequence.status == 'reused' ? 'adjudicated-strike-defense-consequence-used' : consequence.reason; return value; }
            }
            else if (self.defenseConsequence != nil) rpgExpandedReject('adjudicated-strike-unused-defense-consequence');
            value.defenses = [check];
            if (check.achieved) { value.outcome = 'defended'; value.successfulDefense = self.defenseKind; }
        }
        else
        {
            if (self.defenseConsequence != nil) rpgExpandedReject('adjudicated-strike-unused-defense-consequence');
            if (self.defenseScore != nil || self.defenseRoll != nil) rpgExpandedReject('adjudicated-strike-unused-defense');
            if (value.attack.achieved && value.attack.critical != 'success' && (self.defenseWaivedEvidence == nil || self.defenseWaivedEvidence == ''))
            { value.reason = 'adjudicated-strike-defense-disposition'; return value; }
        }
        if (value.outcome != 'hit' && self.basicDamage != 0) rpgExpandedReject('adjudicated-strike-unused-damage');
        if ((value.outcome == 'hit') != (self.wound != nil)) rpgExpandedReject('adjudicated-strike-injury-disposition');
        if (self.wound != nil && value.attack.critical != 'success' && (self.wound.criticalHit || self.wound.forceMajorWound))
            rpgExpandedReject('adjudicated-strike-unused-critical');
        value.status = 'ready'; return value;
    }
    outcomeFacts()
    {
        local value = self.result; local check = value.attack;
        local facts = [value,value.status,value.outcome,value.injury,value.damage,value.attackMode,value.successfulDefense,
            check,check.score,check.roll,check.margin,check.achieved,check.critical,self.ammunitionBefore];
        foreach (local defense in value.defenses)
            facts = facts + [defense,defense.score,defense.roll,defense.margin,defense.achieved,defense.critical];
        return facts;
    }
    validateReceipt()
    {
        local facts = self.facts();
        if (self.result == nil || self.boundFacts == nil || self.boundOutcome == nil
            || !holds(self.attacker.profile.adjudicatedStrikes,self) || facts.length() != self.boundFacts.length())
            rpgExpandedReject('adjudicated-strike-receipt');
        for (local i = 1; i <= facts.length(); i += 1)
            if (facts[i] != self.boundFacts[i]) rpgExpandedReject('adjudicated-strike-binding');
        facts = self.outcomeFacts();
        if (facts.length() != self.boundOutcome.length()) rpgExpandedReject('adjudicated-strike-outcome');
        for (local i = 1; i <= facts.length(); i += 1)
            if (facts[i] != self.boundOutcome[i]) rpgExpandedReject('adjudicated-strike-outcome');
        if (self.defenseConsequence != nil) self.defenseConsequence.validate(self);
        if (self.wound != nil && self.wound.assess().status != 'reused') rpgExpandedReject('adjudicated-strike-injury-history');
        return nil;
    }
    assess()
    {
        self.facts();
        if (self.result != nil) { self.validateReceipt(); local prior = new RpgLiteCombatResult(); prior.status = 'reused'; return prior; }
        if (self.boundFacts != nil || self.boundOutcome != nil || self.ammunitionBefore != nil)
            rpgExpandedReject('adjudicated-strike-uncommitted');
        local value = self.classified(); if (value.status != 'ready') return value;
        value.status = 'blocked';
        if (!self.approved || self.legalityEvidence == nil || self.legalityEvidence == ''
            || self.resolutionEvidence == nil || self.resolutionEvidence == '')
        { value.reason = 'adjudicated-strike-evidence'; return value; }
        self.weapon.validateStrike(self.attacker,self.mode);
        if (self.mode.thrown) { value.reason = 'adjudicated-strike-thrown-adapter-required'; return value; }
        if (self.attacker.weapon != self.weapon || self.attacker.mode() != self.mode
            || !holds(self.attacker.profile.equipment,self.weapon) || !self.weapon.ready
            || !self.weapon.attackUsableBy(self.attacker.profile))
        { value.reason = 'adjudicated-strike-weapon-unavailable'; return value; }
        if (self.attacker.profile.dead || self.defender.profile.dead)
        { value.reason = 'adjudicated-strike-dead'; return value; }
        if (self.mode.ranged && self.weapon.ammunition < 1)
        { value.reason = 'adjudicated-strike-empty'; return value; }
        foreach (local prior in self.attacker.profile.adjudicatedStrikes)
            if (prior.id == self.id) rpgExpandedReject('adjudicated-strike-duplicate');
        if (self.wound != nil)
        {
            local injury = self.wound.assess();
            if (injury.status == 'reused') rpgExpandedReject('adjudicated-strike-used-wound');
            if (injury.status != 'ready') { value.reason = injury.reason; return value; }
        }
        value.status = 'ready'; return value;
    }
    apply(request)
    {
        local permitted = nil;
        if (request != nil && request.ofKind(RpgExpandedPanicAttackManeuver))
            permitted = request.strike == self && request.panicReaction != nil
                && request.panicReaction.episode.settlingReaction == request.panicReaction
                && request.panicReaction.operation.maneuver == request
                && self.attacker.profile.panicAuthorization(request) && request.healthGate.result != nil
                && request.healthGate.result.allowed;
        else if (request != nil && (request.ofKind(RpgExpandedPathWaitInterruption)
            || request.ofKind(RpgExpandedOverstimulationCounterManeuver)))
            permitted = request.permitsStrike(self);
        if (!permitted) rpgExpandedReject('adjudicated-strike-execution-owner');
        local value = self.assess(); if (value.status != 'ready') return value;
        self.boundFacts = self.facts(); self.ammunitionBefore = self.weapon.ammunition;
        if (self.mode.ranged) self.weapon.ammunition -= 1;
        if (self.unready) self.weapon.ready = nil;
        self.attacker.attacked = true; self.attacker.participated = true; self.attacker.aimSeconds = 0;
        if (self.defenseKind == 'parry') self.defender.parries += 1;
        if (self.defenseKind == 'block') self.defender.blocks += 1;
        if (self.defenseKind != nil) { self.defender.participated = true; rpgLiteDistract(self.defender); }
        if (self.defenseConsequence != nil)
        {
            self.committingDefense = true;
            local consequence = nil;
            try { consequence = self.defenseConsequence.apply(self); }
            catch (RpgError error) { self.committingDefense = nil; throw error; }
            self.committingDefense = nil;
            if (consequence.status != 'resolved') rpgExpandedReject('adjudicated-strike-defense-consequence-changed');
        }
        if (self.wound != nil)
        {
            local injury = self.wound.apply();
            if (injury.status != 'resolved') rpgExpandedReject('adjudicated-strike-injury-changed');
            value.injury = injury.healthLoss;
            if (value.injury > 0) rpgLiteDistract(self.defender);
        }
        value.status = 'resolved'; self.weapon.afterStrike(self.attacker,self.mode,value); self.result = value;
        self.attacker.profile.adjudicatedStrikes = self.attacker.profile.adjudicatedStrikes + [self];
        self.boundOutcome = self.outcomeFacts();
        self.defender.profile.recordDirectPhysicalAttack(self.attacker,self.defender,value); return value;
    }
;
modify RpgExpandedProfile
    adjudicatedStrikes = []
    validateFeatures()
    { inherited(); foreach (local strike in self.adjudicatedStrikes) strike.validateReceipt(); return nil; }
;
class RpgExpandedPanicAttackManeuver: RpgExpandedPhysicalManeuver
    kind = 'attack'
    panicReaction = nil
    strike = nil
    resolveStrike(attacker,defender)
    {
        if (self.strike == nil || !self.strike.ofKind(RpgExpandedAdjudicatedStrike)
            || self.strike.attacker != attacker || self.strike.defender != defender)
            rpgExpandedReject('panic-attack-strike-owner');
        return self.preflight ? self.strike.assess() : self.strike.apply(self);
    }
;
class RpgExpandedPanicAttackOperation: RpgExpandedPanicOperation
    ownsTime = true
    reaction = nil
    battle = nil
    maneuver = nil
    result = nil
    boundFacts = nil
    boundOutcome = nil
    battleSecond = nil
    ledgerSecond = nil
    facts(owner)
    {
        if (self.reaction != owner || self.battle == nil || !self.battle.ofKind(RpgLiteBattle)
            || self.maneuver == nil || !self.maneuver.ofKind(RpgExpandedPanicAttackManeuver)
            || self.maneuver.panicReaction != owner || self.maneuver.kind != 'attack'
            || self.maneuver.movement != 0 || self.maneuver.strike == nil
            || self.maneuver.strike.attacker.profile != self.profile
            || self.maneuver.target != self.maneuver.strike.defender
            || self.maneuver.healthGate == nil || !self.maneuver.healthGate.ofKind(RpgExpandedPanicActionGate)
            || self.maneuver.healthGate.panicReaction != owner)
            rpgExpandedReject('panic-attack-definition');
        return [self,self.profile,owner,self.battle,self.maneuver,self.maneuver.healthGate,self.ownsTime]
            + self.maneuver.strike.facts();
    }
    permitsAuthorization(request)
    { return self.result == nil && (request == self.maneuver || request == self.maneuver.healthGate); }
    clockSeconds(owner) { self.facts(owner); return self.battle.index == self.battle.order.length() ? 1 : 0; }
    permitsBattleClock(battle)
    { return self.result != nil && battle == self.battle && battle.active
        && battle.seconds == self.battleSecond+1 && rpgLedger.seconds == self.ledgerSecond; }
    outcomeFacts() { return [self.result,self.result.status,self.result.outcome,self.battleSecond,self.ledgerSecond]; }
    validateReceipt(owner)
    {
        local facts = self.facts(owner);
        if (self.result == nil || self.boundFacts == nil || self.boundOutcome == nil
            || facts.length() != self.boundFacts.length()) rpgExpandedReject('panic-attack-receipt');
        for (local i = 1; i <= facts.length(); i += 1)
            if (facts[i] != self.boundFacts[i]) rpgExpandedReject('panic-attack-binding');
        facts = self.outcomeFacts();
        for (local i = 1; i <= facts.length(); i += 1)
            if (facts[i] != self.boundOutcome[i]) rpgExpandedReject('panic-attack-outcome');
        if (self.maneuver.healthGate.assess().status != 'reused') rpgExpandedReject('panic-attack-permission-receipt');
        if (self.result.outcome == 'incapacitated')
        {
            if (self.maneuver.strike.result != nil || self.maneuver.healthGate.result.allowed)
                rpgExpandedReject('panic-attack-incapacity-receipt');
        }
        else if (self.maneuver.strike.result != self.result || self.maneuver.strike.assess().status != 'reused')
            rpgExpandedReject('panic-attack-strike-receipt');
        return nil;
    }
    assess(owner)
    {
        self.facts(owner); local value = new RpgExpandedResult();
        if (self.result != nil) { self.validateReceipt(owner); value.status = 'reused'; return value; }
        if (self.boundFacts != nil || self.boundOutcome != nil || self.battleSecond != nil || self.ledgerSecond != nil)
            rpgExpandedReject('panic-attack-uncommitted');
        if (!self.ownsTime || owner.operation != self) rpgExpandedReject('panic-attack-time-owner');
        if (owner.seconds != 1) { value.reason = 'panic-attack-one-turn'; return value; }
        if (self.battle.current() != self.maneuver.strike.attacker || !holds(self.battle.fighters,self.maneuver.target))
        { value.reason = 'panic-attack-battle-turn'; return value; }
        value.reason = self.maneuver.healthAvailable(self.maneuver.strike.attacker); if (value.reason != nil) return value;
        value = self.maneuver.strike.assess();
        if (value.status == 'reused') rpgExpandedReject('panic-attack-used-strike');
        return value;
    }
    apply(owner)
    {
        local value = self.assess(owner); if (value.status != 'ready') return value;
        self.boundFacts = self.facts(owner); self.battleSecond = self.battle.seconds; self.ledgerSecond = rpgLedger.seconds;
        value = self.battle.step(self.maneuver.strike.attacker,self.maneuver);
        if (value.status != 'resolved') rpgExpandedReject('panic-attack-turn-changed');
        self.result = value; self.boundOutcome = self.outcomeFacts(); return value;
    }
;

/** B366: a declared stationary ordinary Attack response, valid until the next turn. */
class RpgExpandedWaitDeclaration: object
    id = nil
    fighter = nil
    battle = nil
    weapon = nil
    mode = nil
    targetProfile = nil
    triggerHex = nil
    approved = nil
    evidence = nil
    declaredAt = nil
    declaredTurnSerial = nil
    boundReceipt = nil
    boundTrigger = nil
    boundFacts = nil
    maneuver = nil
    triggeredBy = nil
    facts()
    {
        if (self.id == nil || self.id == '' || self.fighter == nil || !self.fighter.ofKind(RpgLiteFighter)
            || !self.fighter.profile.ofKind(RpgExpandedProfile) || self.battle == nil || !self.battle.ofKind(RpgLiteBattle)
            || self.weapon == nil || !self.weapon.ofKind(RpgLiteWeapon) || self.mode == nil
            || !self.mode.ofKind(RpgLiteAttackMode) || self.targetProfile == nil
            || !self.targetProfile.ofKind(RpgExpandedProfile) || self.targetProfile == self.fighter.profile || self.triggerHex == nil
            || !self.triggerHex.ofKind(RpgExpandedHex)) rpgExpandedReject('wait-declaration-definition');
        self.triggerHex.validate();
        return [self,self.id,self.fighter,self.fighter.profile,self.battle,self.weapon,self.mode,self.mode.ranged,
            self.mode.thrown,self.targetProfile,self.triggerHex.q,self.triggerHex.r,self.approved,self.evidence];
    }
    validateReceipt()
    {
        local facts = self.facts();
        if (self.declaredAt == nil || self.declaredTurnSerial == nil || self.boundFacts == nil
            || self.maneuver == nil || self.maneuver.declaration != self
            || !holds(self.fighter.profile.waitDeclarations,self) || facts.length() != self.boundFacts.length())
            rpgExpandedReject('wait-declaration-receipt');
        for (local i = 1; i <= facts.length(); i += 1)
            if (facts[i] != self.boundFacts[i]) rpgExpandedReject('wait-declaration-binding');
        local receipt = [self.declaredAt,self.declaredTurnSerial,self.maneuver,self.maneuver.healthGate,self.maneuver.kind,self.maneuver.movement];
        if (self.boundReceipt == nil || self.triggeredBy != self.boundTrigger) rpgExpandedReject('wait-declaration-history');
        for (local i = 1; i <= receipt.length(); i += 1)
            if (receipt[i] != self.boundReceipt[i]) rpgExpandedReject('wait-declaration-history');
        if (self.maneuver.healthGate.assess().status != 'reused' || !self.maneuver.healthGate.result.allowed)
            rpgExpandedReject('wait-declaration-permission');
        return nil;
    }
    assess()
    {
        self.facts(); local value = new RpgExpandedResult();
        if (self.declaredAt != nil) { self.validateReceipt(); value.status = 'reused'; return value; }
        if (self.boundFacts != nil || self.maneuver != nil || self.declaredTurnSerial != nil || self.triggeredBy != nil || self.boundTrigger != nil || self.boundReceipt != nil)
            rpgExpandedReject('wait-declaration-uncommitted');
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'wait-declaration-author-facts'; return value; }
        if (!self.battle.active || self.battle.current() != self.fighter)
        { value.reason = 'wait-declaration-turn'; return value; }
        local targetPresent = nil;
        foreach (local other in self.battle.fighters)
            if (other.profile == self.targetProfile) targetPresent = true;
        if (!targetPresent) { value.reason = 'wait-declaration-target'; return value; }
        if (self.mode.thrown) { value.reason = 'wait-declaration-thrown-adapter-required'; return value; }
        if (self.weapon != self.fighter.weapon || self.mode != self.fighter.mode() || !self.weapon.ready
            || !self.weapon.attackUsableBy(self.fighter.profile) || !holds(self.fighter.profile.equipment,self.weapon))
        { value.reason = 'wait-declaration-weapon'; return value; }
        foreach (local prior in self.fighter.profile.waitDeclarations)
            if (prior.id == self.id) rpgExpandedReject('wait-declaration-duplicate');
        value.status = 'ready'; return value;
    }
    record(request)
    {
        if (request == nil || !request.ofKind(RpgExpandedWaitManeuver) || request.declaration != self
            || self.fighter.maneuver != 'wait' || request.healthGate.result == nil || !request.healthGate.result.allowed)
            rpgExpandedReject('wait-declaration-execution-owner');
        local value = self.assess(); if (value.status != 'ready') rpgExpandedReject('wait-declaration-changed');
        self.maneuver = request; self.boundFacts = self.facts(); self.declaredAt = rpgLedger.seconds;
        self.declaredTurnSerial = self.fighter.turnSerial;
        self.boundReceipt = [self.declaredAt,self.declaredTurnSerial,self.maneuver,self.maneuver.healthGate,self.maneuver.kind,self.maneuver.movement];
        self.fighter.profile.waitDeclarations = self.fighter.profile.waitDeclarations + [self]; return nil;
    }
    responseReason()
    {
        self.validateReceipt();
        if (!self.battle.active || self.fighter.turnSerial != self.declaredTurnSerial || self.fighter.maneuver != 'wait')
            return 'wait-response-expired';
        if (self.triggeredBy != nil) return 'wait-response-used';
        local profile = self.fighter.profile;
        if (profile.dead || profile.unconscious || profile.mortal || profile.stunned || profile.mentalStun)
            return 'wait-response-incapacitated';
        return profile.healthEffortReason('action',nil,nil,true);
    }
;
class RpgExpandedWaitManeuver: RpgExpandedHealthManeuver
    kind = 'wait'
    declaration = nil
    available(fighter)
    {
        if (self.kind != 'wait' || self.movement != 0 || self.declaration == nil
            || !self.declaration.ofKind(RpgExpandedWaitDeclaration) || self.declaration.fighter != fighter)
            rpgExpandedReject('wait-maneuver-definition');
        local value = self.declaration.assess();
        return value.status == 'ready' ? nil : value.status == 'reused' ? 'wait-declaration-used' : value.reason;
    }
    apply(fighter,result) { inherited(fighter,result); self.declaration.record(self); return nil; }
;
modify RpgExpandedProfile
    waitDeclarations = []
    validateFeatures()
    { inherited(); foreach (local declaration in self.waitDeclarations) declaration.validateReceipt(); return nil; }
;

/** No free attack: this permission applies only to the actor's ordinary Attack turn. */
class RpgExpandedOverstimulationCounterManeuver: RpgExpandedPhysicalManeuver
    kind = 'attack'
    notice = nil
    resolution = nil
    strike = nil
    executingStrike = nil
    permittedTurn = nil
    battle = nil
    available(fighter)
    {
        if (self.kind != 'attack' || self.movement != 0) rpgExpandedReject('overstimulation-counter-maneuver');
        if (!holds(['abridged','recorded'],self.resolution)) return 'overstimulation-counter-resolution-required';
        if (self.resolution == 'recorded')
        {
            if (self.strike == nil || !self.strike.ofKind(RpgExpandedAdjudicatedStrike)
                || self.strike.attacker != fighter || self.strike.defender != self.target
                || self.battle == nil || !self.battle.ofKind(RpgLiteBattle) || self.battle.current() != fighter)
                return 'overstimulation-counter-strike-owner';
            local value = self.strike.assess();
            if (value.status != 'ready') return value.status == 'reused' ? 'overstimulation-counter-strike-used' : value.reason;
        }
        else if (self.strike != nil) rpgExpandedReject('overstimulation-counter-unused-strike');
        local reason = fighter.profile.overstimulationNoticeReason(self.notice,self.target);
        if (reason != nil) return reason;
        if (self.notice.defender != fighter) return 'overstimulation-counterattack-owner';
        return inherited(fighter);
    }
    healthAvailable(fighter)
    {
        if (self.healthGate == nil || !self.healthGate.ofKind(RpgExpandedOverstimulationCounterGate)
            || self.healthGate.maneuver != self) rpgExpandedReject('overstimulation-counter-gate');
        return inherited(fighter);
    }
    canAct(fighter)
    {
        local allowed = inherited(fighter);
        if (allowed) self.permittedTurn = fighter.turnSerial;
        return allowed;
    }
    permitsStrike(strike)
    {
        return self.executingStrike && self.resolution == 'recorded' && self.strike == strike
            && self.battle != nil && self.battle.current() == strike.attacker
            && strike.attacker.turnSerial == self.permittedTurn
            && self.healthGate != nil && self.healthGate.result != nil && self.healthGate.result.allowed
            && self.healthGate.completedAt == rpgLedger.seconds
            && strike.attacker.profile.overstimulationCounterAllowed(self);
    }
    resolveStrike(attacker,defender)
    {
        if (self.resolution == 'abridged') return inherited(attacker,defender);
        if (self.resolution != 'recorded' || self.strike == nil || self.strike.attacker != attacker
            || self.strike.defender != defender) rpgExpandedReject('overstimulation-counter-strike-owner');
        if (self.preflight) return self.strike.assess();
        if (self.executingStrike) rpgExpandedReject('overstimulation-counter-reentrant');
        self.executingStrike = true;
        local value = nil;
        try { value = self.strike.apply(self); }
        catch (RpgError error) { self.executingStrike = nil; throw error; }
        self.executingStrike = nil; return value;
    }
;
class RpgExpandedOverstimulationCounterGate: RpgExpandedActionGate
    maneuver = nil
    healthPermissionReason()
    {
        if (!self.profile.overstimulationCounterAllowed(self)) return 'overstimulation-counter-permission';
        return self.profile.healthEffortReasonFor(self.purpose,self.mentalAbility,self.requiresSpeech,self.requiresMovement,self);
    }
;
modify RpgExpandedProfile
    overstimulationCounterAllowed(request)
    {
        local maneuver = request;
        if (request != nil && request.ofKind(RpgExpandedOverstimulationCounterGate)) maneuver = request.maneuver;
        if (maneuver == nil || !maneuver.ofKind(RpgExpandedOverstimulationCounterManeuver)
            || maneuver.kind != 'attack' || maneuver.movement != 0 || maneuver.healthGate == nil
            || maneuver.healthGate.profile != self) return nil;
        return self.overstimulationNoticeReason(maneuver.notice,maneuver.target) == nil;
    }
    healthManeuverRequestReason(request)
    {
        if (self.activeOverstimulation() != nil) return self.healthManeuverReasonFor(request.kind,request);
        return inherited(request);
    }
;

/** Row 21 world movement. The author specifies an unobstructed, non-tactical leg. */
class RpgExpandedFearPanicMovement: RpgExpandedFearPanicCrying
    actor = nil
    origin = nil
    destination = nil
    distanceYards = 1
    approved = nil
    routeEvidence = nil
    behaviorKind() { return 'agitated-motion'; }
    gatePurpose() { return 'action'; }
    retainFailedGate() { return true; }
    definition()
    { return inherited() + [self.actor,self.origin,self.destination,self.distanceYards,self.approved,self.routeEvidence,
        self.healthGate == nil ? nil : self.healthGate.activity]; }
    activityReason()
    {
        local profile = self.episode.context.profile;
        if (self.actor == nil || !self.actor.ofKind(Actor) || self.actor.rpgProfile != profile
            || self.origin == nil || !self.origin.ofKind(Room) || self.destination == nil || !self.destination.ofKind(Room)
            || self.healthGate == nil || !self.healthGate.ofKind(RpgExpandedPanicMovementGate)
            || self.healthGate.activity != self || !self.healthGate.requiresMovement || self.healthGate.mentalAbility)
            rpgExpandedReject('panic-movement-definition');
        rpgInteger(self.distanceYards,1,1000000);
        if (!self.approved || self.routeEvidence == nil || self.routeEvidence == '') return 'panic-movement-route-evidence';
        if (location.get(self.actor) != self.origin) return 'panic-movement-origin-changed';
        if (!holds(['standing','crouching'],profile.posture) || profile.voluntaryMovementUnavailable())
            return 'panic-movement-mobility';
        local reason = profile.panicRelocationReason(); if (reason != nil) return reason;
        for (local battle = firstObj(RpgLiteBattle); battle != nil; battle = nextObj(battle,RpgLiteBattle))
            if (battle.active)
                foreach (local fighter in battle.fighters)
                    if (fighter.profile == profile) return 'panic-movement-combat-route-required';
        if (self.distanceYards > profile.move()*self.seconds) return 'panic-movement-distance';
        return nil;
    }
    commitActivity() { relocateActor(self.actor,self.destination); return nil; }
;
/** Narrow panic permission; all other effort and consciousness checks still apply. */
class RpgExpandedPanicMovementGate: RpgExpandedActionGate
    activity = nil
    purpose = 'action'
    requiresMovement = true
    permits(profile,purpose,movement)
    {
        return self.activity != nil && self.activity.ofKind(RpgExpandedFearPanicMovement)
            && self.activity.healthGate == self && self.profile == profile && purpose == 'action' && movement
            && self.activity.episode != nil && self.activity.episode.context.profile == profile
            && profile.fearPanic == self.activity.episode && self.activity.episode.completedAt == nil;
    }
    healthPermissionReason()
    { return self.profile.healthEffortReasonFor(self.purpose,self.mentalAbility,self.requiresSpeech,self.requiresMovement,self); }
    apply()
    {
        if (self.result == nil && (self.activity == nil || !self.activity.executing))
            rpgExpandedReject('panic-movement-gate-owner');
        return inherited();
    }
;

/** Tactical module supplies the concrete timed-panic path authorization. */
modify RpgExpandedProfile
    healthManeuverRequestReason(request)
    {
        if (self.timedPanicAuthorization(request))
        {
            if (!request.timedPanicActivity.executing) return 'timed-panic-path-owner';
            return self.healthManeuverReasonFor(request.kind,request);
        }
        return inherited(request);
    }
;

/** Row-21 stationary expression: authored portrayal, no task or social benefit. */
class RpgExpandedFearPanicExpression: RpgExpandedFearPanicCrying
    mode = nil
    portrayal = nil
    approved = nil
    evidence = nil
    behaviorKind() { return 'other-pointless'; }
    gatePurpose() { return self.mode == 'still' ? 'do-nothing' : 'action'; }
    needsVocalization() { return holds(['vocalization','gesture-and-vocalization'],self.mode); }
    needsMovement() { return holds(['gesture','gesture-and-vocalization'],self.mode); }
    retainFailedGate() { return true; }
    definition()
    { return inherited() + [self.mode,self.portrayal,self.approved,self.evidence,
        self.healthGate == nil ? nil : self.healthGate.activity]; }
    activityReason()
    {
        if (!holds(['still','gesture','vocalization','gesture-and-vocalization'],self.mode)
            || self.healthGate == nil || !self.healthGate.ofKind(RpgExpandedPanicExpressionGate)
            || self.healthGate.activity != self || self.healthGate.mentalAbility
            || self.healthGate.requiresSpeech
            || self.healthGate.requiresMovement != self.needsMovement())
            rpgExpandedReject('panic-expression-definition');
        if (!self.approved || self.evidence == nil || self.evidence == '' || self.portrayal == nil || self.portrayal == '')
            return 'panic-expression-author-facts';
        local profile = self.episode.context.profile;
        if (self.needsMovement() && profile.voluntaryMovementUnavailable()) return 'panic-expression-movement-unavailable';
        if (self.needsVocalization()) return profile.panicVocalizationReason();
        return nil;
    }
    commitActivity()
    {
        event('rpg.expanded.panic-expression'); eventValue(self.id); eventValue(self.mode); eventValue(self.portrayal);
        return nil;
    }
;
class RpgExpandedPanicExpressionGate: RpgExpandedActionGate
    activity = nil
    permits(profile,purpose,speech,movement)
    {
        return self.activity != nil && self.activity.ofKind(RpgExpandedFearPanicExpression)
            && self.activity.healthGate == self && self.profile == profile
            && purpose == self.activity.gatePurpose() && !speech
            && movement == self.activity.needsMovement() && self.activity.episode != nil
            && self.activity.episode.context.profile == profile && profile.fearPanic == self.activity.episode
            && self.activity.episode.completedAt == nil;
    }
    healthPermissionReason()
    { return self.profile.healthEffortReasonFor(self.purpose,self.mentalAbility,self.requiresSpeech,self.requiresMovement,self); }
    apply()
    {
        if (self.result == nil && (self.activity == nil || !self.activity.executing)) rpgExpandedReject('panic-expression-gate-owner');
        return inherited();
    }
;
