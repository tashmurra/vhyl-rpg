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
    snapshot = nil
    definition()
    { return [self.id,self.profile,self.ability,self.ability.power,self.warningText,self.detailText,self.evidence]; }
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
