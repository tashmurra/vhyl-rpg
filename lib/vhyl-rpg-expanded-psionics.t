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
