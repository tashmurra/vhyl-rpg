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
    postCreationDisadvantageAllowance() { return 0; }
    /* Equipment module supplies concrete forced-drop handling when installed. */
    prepareKnockdownDrop(destination)
    {
        foreach (local item in self.equipment)
            if (item.ready && !item.worn)
            {
                local value = new RpgExpandedResult(); value.reason = 'expanded-wound-drop-unavailable';
                return value;
            }
        return nil;
    }
    /* Optional equipment supplies committed storage for anatomy-forced drops. */
    prepareForcedDrop(items, destination)
    {
        if (items.length() == 0) return nil;
        local value = new RpgExpandedResult(); value.reason = 'expanded-wound-drop-unavailable';
        return value;
    }
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

modify RpgExpandedProfile
    prepareTechnologyWound(id, amount, destination) { return nil; }
;

modify RpgExpandedProfile
    inventionCapabilityTier() { return nil; }
;

/** Full-reference damage rows, with B15's full-ten-point progression above 100.
 * Missing intermediate rows between 40 and 100 remain explicitly unsupported. */
rpgExpandedDamageDice(strength, swing)
{
    rpgInteger(strength, 1, 1000);
    if (strength > 100) return [(swing ? 13 : 11) + (strength - 100) / 10, 0];
    if (strength <= 20) return rpgLiteDamageDice(strength, swing);
    local rows = [
        [21,2,0,4,-1],[22,2,0,4,0],[23,2,1,4,1],[24,2,1,4,2],
        [25,2,2,5,-1],[26,2,2,5,0],[27,3,-1,5,1],[28,3,-1,5,1],
        [29,3,0,5,2],[30,3,0,5,2],[31,3,1,6,-1],[32,3,1,6,-1],
        [33,3,2,6,0],[34,3,2,6,0],[35,4,-1,6,1],[36,4,-1,6,1],
        [37,4,0,6,2],[38,4,0,6,2],[39,4,1,7,-1],[40,4,1,7,-1],
        [45,5,0,7,1],[50,5,2,8,-1],[55,6,0,8,1],[60,7,-1,9,0],
        [65,7,1,9,2],[70,8,0,10,0],[75,8,2,10,2],[80,9,0,11,0],
        [85,9,2,11,2],[90,10,0,12,0],[95,10,2,12,2],[100,11,0,13,0]];
    foreach (local row in rows)
        if (row[1] == strength) return swing ? [row[4],row[5]] : [row[2],row[3]];
    rpgExpandedReject('unsupported-strength-row'); return nil;
}


modify RpgExpandedProfile
    prepareSwarmWound(id, amount, destination) { return nil; }
;

/** Optional trait-module contract; the foundation alone cannot award a quirk. */
class RpgExpandedFearQuirkContract: object
    profile = nil
    eventId = nil
    assess()
    {
        local value = new RpgExpandedResult(); value.reason = 'fear-quirk-module-required'; return value;
    }
    apply() { return self.assess(); }
;

modify RpgExpandedProfile
    radiationDivisor() { return 1; }
;
