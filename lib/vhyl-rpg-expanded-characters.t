/* Include after the expanded foundation. Source: full-2008, B14-B17. */

modify RpgExpandedProfile
    creationScoreAmounts()
    {
        return [(self.st - 10) * 10, (self.dx - 10) * 20,
            (self.iq - 10) * 20, (self.ht - 10) * 10,
            (self.techLevel - self.campaignTL) * 5,
            self.hpAdjustment * 2, self.fpAdjustment * 3,
            self.willAdjustment * 5, self.perceptionAdjustment * 5,
            self.speedQuarterAdjustment * 5, self.moveAdjustment * 5];
    }
    creationDisadvantageExemption() { return 0; }
;

/** Individual point components; negative entries count separately toward limits. */
rpgExpandedCharacterAmounts(profile)
{
    rpgExpandedValidate(profile);
    local amounts = profile.creationScoreAmounts();
    foreach (local trait in profile.traits) amounts = amounts + [trait.creationCost()];
    foreach (local language in profile.languages) amounts = amounts + [language.cost()];
    foreach (local training in profile.skills) amounts = amounts + [training.points];
    foreach (local contribution in profile.contributions)
        amounts = amounts + contribution.amounts(profile);
    return amounts;
}

/** Total creation cost or the sum of negative components, without changing state. */
rpgExpandedCharacterCost(profile, negativeOnly)
{
    local total = 0;
    foreach (local amount in rpgExpandedCharacterAmounts(profile))
    {
        rpgInteger(amount, -1000000, 1000000);
        if (!negativeOnly || amount < 0) total += amount;
    }
    return total;
}

/** Validate purchased secondary characteristics and budgets.
 * Exceptional limits are explicit. Catalogue-specific compatibility is separate. */
rpgExpandedValidateCharacter(profile)
{
    rpgExpandedValidate(profile);
    foreach (local score in [profile.st, profile.dx, profile.iq, profile.ht,
        profile.maxHP, profile.maxEnergy, profile.will, profile.perception])
        rpgInteger(score, 1, 1000);
    foreach (local offset in [profile.hpAdjustment, profile.fpAdjustment,
        profile.willAdjustment, profile.perceptionAdjustment,
        profile.speedQuarterAdjustment, profile.moveAdjustment])
        rpgInteger(offset, -1000, 1000);
    rpgInteger(profile.basicSpeedQuarters(), 0, 4000);
    rpgInteger(profile.basicMove(), 0, 1000);
    rpgInteger(profile.techLevel, 0, 12); rpgInteger(profile.campaignTL, 0, 12);
    rpgInteger(profile.pointBudget, 0, 1000000);
    rpgInteger(profile.disadvantageLimit, 0, 1000000);
    if (!profile.rules.exceptionalCharacteristics)
    {
        if (profile.hpAdjustment * 10 > profile.st * 3
            || profile.hpAdjustment * 10 < -profile.st * 3
            || profile.fpAdjustment * 10 > profile.ht * 3
            || profile.fpAdjustment * 10 < -profile.ht * 3
            || profile.will > 20 || profile.willAdjustment < -4
            || profile.perception > 20 || profile.perceptionAdjustment < -4
            || profile.speedQuarterAdjustment < -8 || profile.speedQuarterAdjustment > 8
            || profile.moveAdjustment < -3 || profile.moveAdjustment > 3)
            rpgExpandedReject('secondary-limit');
    }
    try { rpgLiteValidateTraits(profile); rpgLiteValidateLanguages(profile); }
    catch (RpgLiteCharacterError error) { rpgExpandedReject(error.reason); }
    local skills = [];
    foreach (local training in profile.skills)
    {
        if (training == nil || !training.ofKind(RpgTraining) || training.skill == nil
            || !training.skill.ofKind(RpgSkill) || holds(skills, training.skill)) rpgExpandedReject('duplicate-training');
        skills = skills + [training.skill]; rpgInteger(training.points, 0, 1000000);
        local ownershipReason = profile.trainingPurchaseReason(training.skill,training);
        if (ownershipReason != nil) rpgExpandedReject(ownershipReason);
        if (training.points > 0)
        {
            local reason = profile.skillLearningReason(training.skill);
            if (reason != nil) rpgExpandedReject(reason);
        }
    }
    if (rpgExpandedCharacterCost(profile, nil) > profile.pointBudget
        || -rpgExpandedCharacterCost(profile, true) - profile.postCreationDisadvantageAllowance() - profile.creationDisadvantageExemption() > profile.disadvantageLimit)
        rpgExpandedReject('point-budget');
    return true;
}

modify RpgExpandedProfile
    /** Creation exchanges burn unused budget; they do not add trait value. */
    creationMoneyReason(points)
    {
        rpgExpandedValidateCharacter(self);
        return points > self.pointBudget || self.pointBudget - rpgExpandedCharacterCost(self,nil) < points
            ? 'money-exchange-points' : nil;
    }
;

modify RpgExpandedProfile
    creationReceipt = nil
;
/** Finalize validated starting purchases and preserve their original negative costs. */
class RpgExpandedCharacterFinalization: object
    id = nil
    profile = nil
    approved = nil
    evidence = nil
    result = nil
    boundDefinition = nil
    bases = []
    originalTraits = []
    originalBonuses = []
    definition() { return [self.id,self.profile,self.approved,self.evidence]; }
    validateOriginalBasis(basis)
    {
        if (self.result == nil || self.profile.creationReceipt != self || !self.profile.creationComplete)
            rpgExpandedReject('creation-receipt-history');
        local current = self.definition();
        for (local i = 1; i <= current.length(); i += 1)
            if (current[i] != self.boundDefinition[i]) rpgExpandedReject('creation-receipt-binding');
        for (local i = 1; i <= self.bases.length(); i += 1)
            if (self.bases[i] == basis)
            {
                if (basis.owner != self.profile || basis.trait != self.originalTraits[i]
                    || basis.originalBonus != self.originalBonuses[i] || basis.creationReceipt != self
                    || !holds(self.profile.buyoffBases,basis)) rpgExpandedReject('creation-original-cost-changed');
                return nil;
            }
        rpgExpandedReject('creation-original-cost-missing');
    }
    assess()
    {
        if (self.id == nil || self.id == '' || self.profile == nil || !self.profile.ofKind(RpgExpandedProfile))
            rpgExpandedReject('creation-finalization-definition');
        local value = new RpgExpandedResult();
        if (self.result != nil)
        {
            if (self.profile.creationReceipt != self || !self.profile.creationComplete)
                rpgExpandedReject('creation-receipt-history');
            local current = self.definition();
            for (local i = 1; i <= current.length(); i += 1)
                if (current[i] != self.boundDefinition[i]) rpgExpandedReject('creation-receipt-binding');
            foreach (local basis in self.bases) self.validateOriginalBasis(basis);
            value.status = 'reused'; return value;
        }
        if (self.profile.creationComplete || self.profile.creationReceipt != nil || self.profile.buyoffBases.length() != 0)
        { value.reason = 'creation-finalization-existing-history'; return value; }
        if (!self.approved || self.evidence == nil || self.evidence == '')
        { value.reason = 'creation-finalization-approval'; return value; }
        rpgExpandedValidateCharacter(self.profile);
        value.points = rpgExpandedCharacterCost(self.profile,nil); value.status = 'ready'; return value;
    }
    apply()
    {
        local value = self.assess(); if (value.status == 'reused') return self.result;
        if (value.status != 'ready') return value;
        foreach (local trait in self.profile.traits)
        {
            local cost = trait.creationCost();
            if (cost < 0)
            {
                local basis = new RpgExpandedBuyoffBasis(); basis.owner = self.profile; basis.trait = trait;
                basis.originalBonus = -cost; basis.creationReceipt = self;
                self.bases = self.bases + [basis]; self.originalTraits = self.originalTraits + [trait];
                self.originalBonuses = self.originalBonuses + [-cost];
            }
        }
        self.profile.buyoffBases = self.bases; self.profile.creationComplete = true; self.profile.creationReceipt = self;
        self.boundDefinition = self.definition(); value.status = 'resolved'; self.result = value; return value;
    }
;
