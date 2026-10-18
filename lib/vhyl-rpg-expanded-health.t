/* Include after expanded foundation. Source: full-2008, B419.
 * This incremental module does not yet supply detailed injury or medical care. */

modify RpgExpandedRules
    scaledInjuryShock = nil
    lastWounds = nil
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
