/* Include after expanded foundation. Source: full-2008, B419.
 * This incremental module does not yet supply detailed injury or medical care. */

modify RpgExpandedRules
    scaledInjuryShock = nil
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
    bodyPart = nil
    severing = nil
    boundBodyPart = nil
    boundSevering = nil
    cripplingAssessment = nil
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
                || self.dropDestination != self.boundDropDestination
                || self.anatomy != 'standard-humanoid') rpgExpandedReject('expanded-wound-retargeted');
            value.status = 'reused'; value.health = self.health; value.assessment = self.knockdownAssessment;
            value.crippling = self.cripplingAssessment; value.healthLoss = self.health.injury; return value;
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
        if (self.profile.ht < 3 && self.profile.hp() - value.healthLoss <= -self.profile.maxHP)
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
                /* Knockdown may already have dropped some of the same held items. */
                local remaining = [];
                foreach (local item in value.limbDrop.items)
                    if (self.droppedEquipment == nil || !holds(self.droppedEquipment.items,item))
                        remaining = remaining + [item];
                value.limbDrop.items = remaining;
                value.limbDrop.commit(); self.droppedLimbEquipment = value.limbDrop;
            }
        }
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
        local items = [];
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
                        else retained = true;
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
                            { local blocked = new RpgExpandedResult(); blocked.reason = 'limb-drop-multiple-grip-unavailable'; return blocked; }
                            items = items + [item];
                        }
                    }
                }
            }
        }
        return self.prepareForcedDrop(items,destination);
    }
;
