/* Include after the expanded foundation. Source: full-2008, B14-B17. */

/** Individual point components; negative entries count separately toward limits. */
rpgExpandedCharacterAmounts(profile)
{
    rpgExpandedValidate(profile);
    local amounts = [(profile.st - 10) * 10, (profile.dx - 10) * 20,
        (profile.iq - 10) * 20, (profile.ht - 10) * 10,
        (profile.techLevel - profile.campaignTL) * 5,
        profile.hpAdjustment * 2, profile.fpAdjustment * 3,
        profile.willAdjustment * 5, profile.perceptionAdjustment * 5,
        profile.speedQuarterAdjustment * 5, profile.moveAdjustment * 5];
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
    local skills = [];
    foreach (local training in profile.skills)
    {
        if (training.skill == nil || holds(skills, training.skill)) rpgExpandedReject('duplicate-training');
        skills = skills + [training.skill]; rpgInteger(training.points, 0, 1000000);
        if (training.points > 0)
        {
            local reason = profile.skillLearningReason(training.skill);
            if (reason != nil) rpgExpandedReject(reason);
        }
    }
    if (rpgExpandedCharacterCost(profile, nil) > profile.pointBudget
        || -rpgExpandedCharacterCost(profile, true) > profile.disadvantageLimit)
        rpgExpandedReject('point-budget');
    return true;
}
