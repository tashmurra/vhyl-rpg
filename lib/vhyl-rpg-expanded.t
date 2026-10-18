/* Include after core, progression and the Lite umbrella. */

/** Expanded configuration error with a stable, author-readable reason. */
class RpgExpandedError: RpgError
    reason = 'invalid-expanded-configuration'
;

/** Raise an expanded configuration error before committing an operation. */
rpgExpandedReject(reason)
{
    local error = new RpgExpandedError(); error.reason = reason; throw error;
}

/** Per-campaign options. Merely including a module never enables these options. */
class RpgExpandedRules: object
    exceptionalCharacteristics = nil
    wildcardSkills = nil
    cinematicInstantTasks = nil
;

/** Expanded profile; keeps the inherited injury, fatigue, inventory and point ledgers.
 * Profiles may share immutable campaign rules; contribution instances are owned. */
class RpgExpandedProfile: RpgLiteProfile
    rules = nil
    contributions = []
    /* Character module supplies creation-budget assessment for cash exchanges. */
    creationMoneyReason(points) { return 'creation-money-accounting-unavailable'; }
    validateFeatures() { return nil; }
    hpAdjustment = 0
    fpAdjustment = 0
    willAdjustment = 0
    perceptionAdjustment = 0
    speedQuarterAdjustment = 0
    moveAdjustment = 0
    maxHP = (st + hpAdjustment)
    maxEnergy = (ht + fpAdjustment)
    will = (iq + willAdjustment)
    perception = (iq + perceptionAdjustment)
    basicSpeedQuarters() { return self.dx + self.ht + self.speedQuarterAdjustment; }
    basicMove() { return self.basicSpeedQuarters() / 4 + self.moveAdjustment; }
;

/** Owned point contribution from an optional subsystem; cost queries are pure. */
class RpgExpandedContribution: object
    id = nil
    owner = nil
    amounts(profile) { return []; }
    wealthStatusBonus() { return 0; }
    validate(profile) { return nil; }
;

/** Operation receipt. Blocked operations have a reason and spend nothing. */
class RpgExpandedResult: object
    status = 'blocked'
    reason = nil
    points = 0
    seconds = 0
    check = nil
    modifier = 0
;

/** Validate the foundation contract without requiring any optional module. */
rpgExpandedValidate(profile)
{
    if (profile == nil || !profile.ofKind(RpgExpandedProfile)
        || profile.rules == nil || !profile.rules.ofKind(RpgExpandedRules))
        rpgExpandedReject('profile-or-rules');
    profile.validateFeatures();
    local ids = [];
    foreach (local contribution in profile.contributions)
    {
        if (!contribution.ofKind(RpgExpandedContribution) || contribution.owner != profile
            || contribution.id == nil || holds(ids, contribution.id))
            rpgExpandedReject('contribution-ownership');
        ids = ids + [contribution.id]; contribution.validate(profile);
    }
    return true;
}
