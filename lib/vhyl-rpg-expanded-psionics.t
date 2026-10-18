/* Include after expanded foundation. Source: full-2008, B254-B257. */

/** Authored power membership and pricing policy, independent of ability execution. */
class RpgExpandedPsionicPower: object
    id = nil
    abilityIds = []
    powerModifier = nil
    allowsTalent = true
    talentPoints = 5
    broad = nil
    customTalentPriceApproved = nil
    approved = nil
    evidence = nil
    validate()
    {
        if (self.id == nil || self.id == '' || !self.approved || self.evidence == nil || self.evidence == '')
            rpgExpandedReject('psionic-power-author-facts');
        if (self.powerModifier == nil) rpgExpandedReject('psionic-power-modifier-required');
        rpgInteger(self.powerModifier,-100,1000);
        if (self.abilityIds.length() == 0) rpgExpandedReject('psionic-power-membership-required');
        local seen = [];
        foreach (local abilityId in self.abilityIds)
        {
            if (abilityId == nil || abilityId == '' || holds(seen,abilityId)) rpgExpandedReject('psionic-power-membership');
            seen = seen + [abilityId];
        }
        if (self.allowsTalent)
        {
            rpgInteger(self.talentPoints,1,1000);
            if ((self.broad || self.talentPoints != 5) && !self.customTalentPriceApproved)
                rpgExpandedReject('psionic-talent-price-permission');
        }
        else if (self.talentPoints != 0) rpgExpandedReject('psionic-unused-talent-price');
        return true;
    }
;

/** Owned latent or active power talent, priced through the existing trait ledger. */
class RpgExpandedPsionicTalent: RpgLiteTrait
    power = nil
    aboveFourApproved = nil
    approved = nil
    evidence = nil
    validateTalent()
    {
        if (self.id == nil || self.id == '' || self.power == nil || !self.power.ofKind(RpgExpandedPsionicPower))
            rpgExpandedReject('psionic-talent-definition');
        self.power.validate();
        if (!self.power.allowsTalent) rpgExpandedReject('psionic-power-has-no-talent');
        rpgInteger(self.level,1,100);
        if (!self.approved || self.evidence == nil || self.evidence == '') rpgExpandedReject('psionic-talent-author-facts');
        if (self.level > 4 && !self.aboveFourApproved) rpgExpandedReject('psionic-talent-level-permission');
        return true;
    }
    creationCost() { self.validateTalent(); return self.level * self.power.talentPoints; }
;

/** Talent affects only the associated use roll, not effect magnitude or possession. */
rpgExpandedPsionicTalentBonus(profile, power)
{
    if (profile == nil || !profile.ofKind(RpgExpandedProfile) || power == nil || !power.ofKind(RpgExpandedPsionicPower))
        rpgExpandedReject('psionic-talent-query');
    power.validate(); local talent = nil;
    foreach (local trait in profile.traits)
        if (trait.ofKind(RpgExpandedPsionicTalent))
        {
            trait.validateTalent();
            if (trait.power.id == power.id)
            {
                if (trait.power != power) rpgExpandedReject('psionic-conflicting-power');
                if (talent != nil) rpgExpandedReject('psionic-duplicate-talent');
                talent = trait;
            }
        }
    return talent != nil && talent.active ? talent.level : 0;
}

/** Pure latent first-ability eligibility; this neither buys nor executes the ability. */
rpgExpandedPsionicLatentEligibility(profile, power, abilityId)
{
    local bonus = rpgExpandedPsionicTalentBonus(profile,power);
    local value = new RpgExpandedResult();
    if (!holds(power.abilityIds,abilityId)) { value.reason = 'psionic-ability-outside-power'; return value; }
    /* Inactive talent is still owned potential; temporary suppression does not erase it. */
    local owned = nil;
    foreach (local trait in profile.traits)
        if (trait.ofKind(RpgExpandedPsionicTalent) && trait.power == power) owned = true;
    if (!owned) { value.reason = 'psionic-latent-talent-required'; return value; }
    value.status = 'ready'; return value;
}

/** B47 and B257: the ordinary danger-warning trait with its -10% source modifier. */
class RpgExpandedPsionicDangerSense: RpgLiteTrait
    id = 'psionic-danger-warning'
    power = nil
    approved = nil
    evidence = nil
    validateAbility()
    {
        if (self.power == nil || !self.power.ofKind(RpgExpandedPsionicPower)) rpgExpandedReject('psionic-danger-power');
        self.power.validate();
        if (self.power.powerModifier != -10 || !holds(self.power.abilityIds,'danger-sense'))
            rpgExpandedReject('psionic-danger-power-definition');
        if (self.level != 1 || !self.approved || self.evidence == nil || self.evidence == '')
            rpgExpandedReject('psionic-danger-author-facts');
        return true;
    }
    creationCost() { self.validateAbility(); return 14; }
;

modify RpgExpandedProfile
    psionicDangerWarnings = []
;

class RpgExpandedDangerWarningResult: RpgExpandedResult
    warning = nil
;

/** One secret check for an authored hazard situation; only warning text is public. */
class RpgExpandedDangerWarning: object
    id = nil
    profile = nil
    ability = nil
    hazardPresent = nil
    approved = nil
    interferenceKnown = nil
    suppressed = nil
    warningText = nil
    detailText = nil
    evidence = nil
    result = nil
    secretCheck = nil
    staticContacts = []
    snapshot = nil
    definition()
    {
        local value = [self.id,self.profile,self.ability,self.ability.power,self.warningText,self.detailText,self.evidence];
        foreach (local contact in self.staticContacts)
        {
            if (contact == nil || !contact.ofKind(RpgExpandedPsionicStaticContact)) rpgExpandedReject('psionic-danger-static-contact');
            value = value + [contact,contact.owner,contact.field,contact.source,contact.target,contact.targetCarrier,
                contact.sourceDistance,contact.targetDistance,contact.indirectPhysical,contact.counterpower,contact.evidence];
        }
        return value;
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)
            || self.ability == nil || !self.ability.ofKind(RpgExpandedPsionicDangerSense))
            rpgExpandedReject('psionic-danger-request');
        local value = new RpgExpandedDangerWarningResult();
        if (self.result != nil)
        {
            local current = self.definition();
            if (self.snapshot == nil || self.snapshot.length() != current.length()) rpgExpandedReject('psionic-danger-binding');
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.snapshot[index]) rpgExpandedReject('psionic-danger-binding');
            if (!holds(self.profile.psionicDangerWarnings,self)) rpgExpandedReject('psionic-danger-history');
            value.status = 'reused'; value.warning = self.result.warning; return value;
        }
        self.ability.validateAbility();
        if (!holds(self.profile.traits,self.ability) || !self.ability.active)
        { value.reason = 'psionic-danger-ability-required'; return value; }
        foreach (local trait in self.profile.traits)
            if (trait.ofKind(RpgExpandedPsionicDangerSense) && trait != self.ability)
            { value.reason = 'psionic-danger-duplicate-ability'; return value; }
        if (self.profile.level('precognition') > 0 || self.profile.level('danger-sense') > 0)
        { value.reason = 'psionic-danger-duplicate-ability'; return value; }
        if (!self.approved || !self.hazardPresent || !self.interferenceKnown || self.evidence == nil || self.evidence == ''
            || self.warningText == nil || self.warningText == '' || self.detailText == nil || self.detailText == '')
        { value.reason = 'psionic-danger-situation-required'; return value; }
        if (self.suppressed) { value.reason = 'psionic-power-suppressed'; return value; }
        foreach (local contact in self.staticContacts)
        {
            if (contact == nil || !contact.ofKind(RpgExpandedPsionicStaticContact)
                || contact.source != self.profile || contact.target != self.profile
                || contact.targetCarrier != nil || contact.indirectPhysical || contact.counterpower)
                rpgExpandedReject('psionic-danger-static-contact');
            local staticResult = contact.assess();
            if (staticResult.status != 'ready') { value.reason = staticResult.reason; return value; }
            if (staticResult.suppressed) { value.reason = 'psionic-power-suppressed'; return value; }
        }
        if (self.profile.dead || self.profile.unconscious)
        { value.reason = 'psionic-danger-observer-unavailable'; return value; }
        foreach (local prior in self.profile.psionicDangerWarnings)
            if (prior.id == self.id) { value.reason = 'psionic-danger-situation-used'; return value; }
        local score = self.profile.attributeScore(rpgPerception) + rpgExpandedPsionicTalentBonus(self.profile,self.ability.power);
        if (score < 3) { value.reason = 'psionic-danger-score-unavailable'; return value; }
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        local score = self.profile.attributeScore(rpgPerception) + rpgExpandedPsionicTalentBonus(self.profile,self.ability.power);
        self.secretCheck = rpgCheck(score,rpgRandom.roll());
        if (self.secretCheck.achieved)
            value.warning = self.secretCheck.roll <= 4 ? self.detailText : self.warningText;
        self.snapshot = self.definition(); self.profile.psionicDangerWarnings = self.profile.psionicDangerWarnings + [self];
        value.status = 'resolved'; self.result = value; return value;
    }
;

/** B81 very-common mental resistance; no power discount applies. */
class RpgExpandedPsionicResistance: RpgLiteTrait
    id = 'psionic-resistance'
    degree = 3
    approved = nil
    evidence = nil
    validateResistance()
    {
        if (!self.active) rpgExpandedReject('psionic-resistance-always-on');
        if (!holds([3,8,'immune'],self.degree) || self.level != 1)
            rpgExpandedReject('psionic-resistance-degree');
        if (!self.approved || self.evidence == nil || self.evidence == '')
            rpgExpandedReject('psionic-resistance-author-facts');
        return true;
    }
    creationCost()
    {
        self.validateResistance();
        return self.degree == 'immune' ? 30 : self.degree == 8 ? 15 : 10;
    }
;

class RpgExpandedPsionicResistanceResult: RpgExpandedResult
    applicable = nil
    immune = nil
;

/** Does not create resistance against an effect that offers no resistance roll. */
rpgExpandedAssessPsionicResistance(profile, resistanceAllowed, attribute)
{
    if (profile == nil || !profile.ofKind(RpgExpandedProfile)) rpgExpandedReject('psionic-resistance-profile');
    local value = new RpgExpandedPsionicResistanceResult(); local resistance = nil;
    foreach (local trait in profile.traits)
        if (trait.ofKind(RpgExpandedPsionicResistance))
        {
            trait.validateResistance();
            if (resistance != nil) rpgExpandedReject('psionic-duplicate-resistance');
            resistance = trait;
        }
    if (!resistanceAllowed) { value.status = 'ready'; return value; }
    if (!holds([rpgIQ,rpgWill],attribute))
    { value.reason = 'psionic-resistance-attribute-unavailable'; return value; }
    value.applicable = true;
    if (resistance != nil && resistance.active)
    {
        value.immune = resistance.degree == 'immune';
        value.modifier = value.immune ? 0 : resistance.degree;
    }
    value.status = 'ready'; return value;
}

/** Use only for the resistance roll of an authored, resistible mental-power effect. */
class RpgExpandedPsionicResistanceContext: RpgLiteContext
    resistanceAllowed = nil
    kind = 'psionic-resistance'
    skillUseModifier(profile)
    {
        local value = rpgExpandedAssessPsionicResistance(profile,self.resistanceAllowed,self.controllingAttribute());
        if (value.status != 'ready' || !value.applicable || value.immune) return nil;
        local ordinary = inherited(profile); return ordinary == nil ? nil : ordinary + value.modifier;
    }
    unavailableReason(profile)
    {
        local value = rpgExpandedAssessPsionicResistance(profile,self.resistanceAllowed,self.controllingAttribute());
        if (value.status != 'ready') return value.reason;
        if (!value.applicable) return 'psionic-no-resistance-roll';
        if (value.immune) return 'psionic-resistance-immune';
        return inherited(profile);
    }
;

/** B78 absolute static, optionally switchable or extended to an area. */
class RpgExpandedPsionicStatic: RpgLiteTrait
    id = 'psionic-static'
    areaLevels = 0
    switchable = nil
    approved = nil
    evidence = nil
    validateStatic()
    {
        rpgInteger(self.areaLevels,0,20);
        if (self.level != 1 || !self.approved || self.evidence == nil || self.evidence == '')
            rpgExpandedReject('psionic-static-author-facts');
        if (!self.active && !self.switchable) rpgExpandedReject('psionic-static-not-switchable');
        return true;
    }
    radius()
    {
        self.validateStatic(); if (self.areaLevels == 0) return 0;
        local yards = 1;
        for (local index = 1; index < self.areaLevels; index += 1) yards *= 2;
        return yards;
    }
    creationCost() { self.validateStatic(); return 30 + 15 * self.areaLevels + (self.switchable ? 30 : 0); }
;

class RpgExpandedPsionicStaticResult: RpgExpandedResult
    suppressed = nil
;

/** Authored spatial/contact facts for one absolute static field and one effect. */
class RpgExpandedPsionicStaticContact: object
    owner = nil
    field = nil
    source = nil
    target = nil
    targetCarrier = nil
    sourceDistance = nil
    targetDistance = nil
    indirectPhysical = nil
    counterpower = nil
    approved = nil
    evidence = nil
    assess()
    {
        if (self.owner == nil || !self.owner.ofKind(RpgExpandedProfile) || self.field == nil
            || !self.field.ofKind(RpgExpandedPsionicStatic) || !holds(self.owner.traits,self.field)
            || self.source == nil || !self.source.ofKind(RpgExpandedProfile) || self.target == nil)
            rpgExpandedReject('psionic-static-contact-definition');
        self.field.validateStatic(); local value = new RpgExpandedPsionicStaticResult();
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'psionic-static-contact-facts'; return value; }
        if (self.targetCarrier != nil && (!self.targetCarrier.ofKind(RpgExpandedProfile)
            || !holds(self.targetCarrier.equipment,self.target))) rpgExpandedReject('psionic-static-carried-target');
        if (!self.field.active && self.owner.unconscious)
        { value.reason = 'psionic-static-unconscious-reset-required'; return value; }
        if (!self.field.active || self.indirectPhysical || self.counterpower)
        { value.status = 'ready'; return value; }
        if (self.target == self.owner || self.targetCarrier == self.owner)
        { value.suppressed = true; value.status = 'ready'; return value; }
        local radius = self.field.radius();
        if (radius > 0)
        {
            if (self.sourceDistance == nil || self.targetDistance == nil)
            { value.reason = 'psionic-static-distances-required'; return value; }
            rpgInteger(self.sourceDistance,0,100000000); rpgInteger(self.targetDistance,0,100000000);
            if (self.source == self.owner && self.sourceDistance != 0) rpgExpandedReject('psionic-static-source-distance');
            value.suppressed = self.sourceDistance <= radius || self.targetDistance <= radius;
        }
        value.status = 'ready'; return value;
    }
;

/** B34/B78: switch a purchased switchable field as one shared Ready maneuver. */
class RpgExpandedStaticReadyManeuver: RpgLiteManeuver
    kind = 'ready'
    field = nil
    enable = true
    healthAdapter = nil
    healthAvailable(fighter)
    {
        if (self.healthAdapter == self) rpgExpandedReject('static-ready-health-cycle');
        if (self.healthAdapter != nil)
        {
            if (!self.healthAdapter.ofKind(RpgLiteManeuver) || !self.healthAdapter.expandedHealthPermission
                || self.healthAdapter.kind != 'ready') rpgExpandedReject('static-ready-health-adapter');
            return self.healthAdapter.healthAvailable(fighter);
        }
        if (fighter.profile.fp() <= 0 || fighter.profile.hp() <= 0) return 'static-ready-health-adapter-required';
        return nil;
    }
    canAct(fighter)
    {
        if (self.healthAdapter != nil) return self.healthAdapter.canAct(fighter);
        return inherited(fighter);
    }
    available(fighter) { return self.readyAvailable(fighter); }
    readyAvailable(fighter)
    {
        if (self.kind != 'ready' || self.option != nil) return 'static-ready-maneuver';
        if (self.field == nil || !self.field.ofKind(RpgExpandedPsionicStatic)
            || !holds(fighter.profile.traits,self.field)) return 'static-ready-owned-field-required';
        self.field.validateStatic();
        if (!self.field.switchable) return 'psionic-static-not-switchable';
        if (self.field.active == self.enable) return 'static-already-selected';
        return nil;
    }
    performReady(fighter)
    {
        local reason = self.readyAvailable(fighter); if (reason != nil) rpgExpandedReject(reason);
        self.field.active = self.enable; return nil;
    }
;

/** B34 defaults persist after waking; switching off again requires another Ready. */
modify RpgExpandedProfile
    restoreDefaultStatic()
    {
        foreach (local trait in self.traits)
            if (trait.ofKind(RpgExpandedPsionicStatic)) trait.validateStatic();
        foreach (local trait in self.traits)
            if (trait.ofKind(RpgExpandedPsionicStatic)) trait.active = true;
        return nil;
    }
    onUnconscious() { inherited(); self.restoreDefaultStatic(); return nil; }
    onSleep() { inherited(); self.restoreDefaultStatic(); return nil; }
;

modify RpgExpandedProfile
    psionicTalentAdvancements = []
;

/** Owned earned-point purchase; creation accounting continues to use the same trait. */
class RpgExpandedPsionicTalentAdvancement: object
    id = nil
    profile = nil
    talent = nil
    targetLevel = 1
    permitted = nil
    newPowerApproved = nil
    aboveFourApproved = nil
    requiresDowntime = true
    evidence = nil
    result = nil
    snapshot = nil
    definition()
    { return [self.id,self.profile,self.talent,self.talent.power,self.targetLevel,self.evidence]; }
    assess()
    {
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile)
            || self.talent == nil || !self.talent.ofKind(RpgExpandedPsionicTalent))
            rpgExpandedReject('psionic-talent-advancement-definition');
        local value = new RpgExpandedResult();
        if (self.result != nil)
        {
            local current = self.definition();
            if (self.snapshot == nil || self.snapshot.length() != current.length()) rpgExpandedReject('psionic-talent-advancement-binding');
            for (local index = 1; index <= current.length(); index += 1)
                if (current[index] != self.snapshot[index]) rpgExpandedReject('psionic-talent-advancement-binding');
            if (!holds(self.profile.psionicTalentAdvancements,self)) rpgExpandedReject('psionic-talent-advancement-history');
            value.status = 'reused'; return value;
        }
        rpgExpandedValidate(self.profile); self.talent.validateTalent();
        rpgInteger(self.targetLevel,1,100);
        rpgInteger(self.profile.unspentPoints,0,1000000);
        rpgInteger(self.profile.developmentRevision,0,2147483646);
        if (!self.profile.creationComplete) { value.reason = 'psionic-advancement-after-creation'; return value; }
        if (!self.permitted || self.evidence == nil || self.evidence == '')
        { value.reason = 'psionic-advancement-permission'; return value; }
        if (self.requiresDowntime && !self.profile.developmentOpen)
        { value.reason = 'rpg.downtime-required'; return value; }
        if (self.targetLevel > 4 && !self.aboveFourApproved)
        { value.reason = 'psionic-talent-level-permission'; return value; }
        local owned = holds(self.profile.traits,self.talent); local member = owned;
        foreach (local trait in self.profile.traits)
        {
            if (trait != self.talent && trait.id == self.talent.id) rpgExpandedReject('psionic-talent-id-conflict');
            if (trait.ofKind(RpgExpandedPsionicTalent) && trait != self.talent && trait.power.id == self.talent.power.id)
                rpgExpandedReject('psionic-duplicate-talent');
            if (trait.ofKind(RpgExpandedPsionicDangerSense) && trait.power == self.talent.power)
            { trait.validateAbility(); member = true; }
        }
        if (!member && !self.newPowerApproved) { value.reason = 'psionic-new-power-permission'; return value; }
        foreach (local prior in self.profile.psionicTalentAdvancements)
            if (prior.id == self.id) rpgExpandedReject('psionic-talent-advancement-duplicate');
        local priorLevel = owned ? self.talent.level : 0;
        if (self.targetLevel <= priorLevel) { value.reason = 'psionic-talent-not-increase'; return value; }
        value.points = (self.targetLevel-priorLevel) * self.talent.power.talentPoints;
        if (value.points > self.profile.unspentPoints) { value.reason = 'rpg.insufficient-points'; return value; }
        value.reason = self.profile.developmentSpendingReason(); if (value.reason != nil) return value;
        value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status != 'ready') return value;
        self.snapshot = self.definition();
        self.profile.unspentPoints -= value.points; self.profile.developmentRevision += 1;
        self.talent.level = self.targetLevel;
        if (self.targetLevel > 4) self.talent.aboveFourApproved = true;
        if (!holds(self.profile.traits,self.talent)) self.profile.traits = self.profile.traits + [self.talent];
        self.profile.psionicTalentAdvancements = self.profile.psionicTalentAdvancements + [self];
        value.status = 'resolved'; self.result = value; return value;
    }
;
