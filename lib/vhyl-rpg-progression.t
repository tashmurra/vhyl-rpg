/* Optional milestone awards and constrained development opportunities.
 * Include after vhyl-rpg.t. Copyright (c) 2026 John Cunningham. MIT License. */

modify RpgProfile
    earnedPoints = 0
    unspentPoints = 0
    developmentOpen = nil
    developmentRevision = 0
    /* Optional mandatory advancement can reserve discretionary point spending. */
    developmentSpendingReason() { return nil; }
    /* Optional profile rules may reject learning before any resources are spent. */
    skillLearningReason(skill) { return nil; }
    skillLearningWithTeacherReason(skill, teacher) { return self.skillLearningReason(skill); }
;

/** Authored objective award. Eligibility is observational; apply can unlock
 * opportunities after the receipt has been claimed. Never award for retries. */
class RpgMilestone: object
    id = nil
    points = 1
    available(profile) { return nil; }
    apply(profile) { return nil; }
;

/** Predeclared receipt per allowed profile/milestone pair; saved and undoable. */
class RpgAward: object
    profile = nil
    milestone = nil
    claimed = nil
;

/** An owned, authored purchase. kind is skill, attribute, trait or remove-trait.
 * Skill/attribute costs are differences; trait costs are explicit positive
 * prices. Unlocks and downtime are separate gates. Reopened goals are explicit. */
class RpgDevelopment: object
    id = nil
    profile = nil
    kind = 'skill'
    training = nil
    teacher = nil
    attribute = nil
    trait = nil
    target = 1
    cost = 1
    unlocked = nil
    requiresDowntime = true
    purchased = nil
    reopens = []
    available(profile) { return nil; }
    apply(profile) { return nil; }
;

/** Temporary award or purchase assessment/result. No output is implicit. */
class RpgProgressResult: object
    profile = nil
    id = nil
    kind = nil
    status = 'blocked'
    reason = nil
    points = 0
;

rpgAwardSlot(profile, milestone)
{
    local found = nil;
    for (local receipt = firstObj(RpgAward); receipt != nil; receipt = nextObj(receipt, RpgAward))
        if (receipt.profile == profile && receipt.milestone == milestone)
        {
            if (found != nil) throw new RpgError();
            found = receipt;
        }
    if (found == nil) throw new RpgError();
    return found;
}

/** Commit an eligible milestone exactly once per profile. Receipt, bank and
 * unlock consequences are in the same gameplay transaction. */
rpgAwardMilestone(profile, milestone)
{
    if (profile == nil || !profile.ofKind(RpgProfile)
        || milestone == nil || !milestone.ofKind(RpgMilestone)) throw new RpgError();
    local receipt = rpgAwardSlot(profile, milestone);
    local value = new RpgProgressResult(); value.profile = profile;
    value.id = milestone.id; value.kind = 'award';
    if (receipt.claimed) { value.status = 'reused'; return value; }
    value.reason = milestone.available(profile);
    if (value.reason != nil) return value;
    rpgInteger(profile.earnedPoints, 0, 1000000 - milestone.points);
    receipt.claimed = true; profile.earnedPoints += milestone.points;
    profile.unspentPoints += milestone.points;
    value.status = 'resolved'; value.points = milestone.points;
    milestone.apply(profile); return value;
}

rpgDevelopmentCost(offer)
{
    local p = offer.profile;
    if (offer.kind == 'skill') return offer.target - offer.training.points;
    if (offer.kind == 'attribute')
    {
        local price = offer.attribute == rpgDX || offer.attribute == rpgIQ ? 20
            : offer.attribute == rpgST || offer.attribute == rpgHT ? 10 : 5;
        return (offer.target - p.attributeScore(offer.attribute)) * price;
    }
    return offer.cost;
}

/** Observational purchase query. It consumes no points, randomness or history. */
rpgAssessDevelopment(offer)
{
    if (offer == nil || !offer.ofKind(RpgDevelopment)) throw new RpgError();
    local p = offer.profile;
    local value = new RpgProgressResult(); value.profile = p;
    value.id = offer.id; value.kind = 'purchase';
    value.points = rpgDevelopmentCost(offer);
    if (offer.purchased || value.points <= 0
        || offer.kind == 'trait' && holds(p.traits, offer.trait)
        || offer.kind == 'remove-trait' && !holds(p.traits, offer.trait))
    { value.status = 'reused'; value.points = 0; return value; }
    if (!offer.unlocked) { value.reason = 'rpg.development-locked'; return value; }
    if (offer.requiresDowntime && !p.developmentOpen)
    { value.reason = 'rpg.downtime-required'; return value; }
    if (offer.kind == 'attribute' && offer.attribute == rpgIQ)
    {
        local delta = offer.target - p.iq;
        if (p.will + delta > 100 || p.perception + delta > 100)
        { value.reason = 'rpg.attribute-limit'; return value; }
    }
    if (offer.kind == 'skill')
    {
        value.reason = p.skillLearningWithTeacherReason(offer.training.skill, offer.teacher);
        if (value.reason != nil) return value;
    }
    value.reason = offer.available(p);
    if (value.reason != nil) return value;
    if (value.points > p.unspentPoints) { value.reason = 'rpg.insufficient-points'; return value; }
    value.reason = p.developmentSpendingReason();
    if (value.reason != nil) return value;
    value.status = 'ready'; return value;
}

/** Commit a current affordable offer, with no refunds or automatic rerolls.
 * Attribute purchases preserve Will/Perception offsets and energy deficits. */
rpgDevelop(offer)
{
    local value = rpgAssessDevelopment(offer);
    if (value.status != 'ready') return value;
    local p = offer.profile;
    rpgInteger(p.developmentRevision, 0, 2147483646);
    offer.purchased = true; p.unspentPoints -= value.points;
    if (offer.kind == 'skill') offer.training.points = offer.target;
    else if (offer.kind == 'attribute')
    {
        local energy = p.energy; local capacity = p.maxEnergy;
        local delta = offer.target - p.attributeScore(offer.attribute);
        if (offer.attribute == rpgST) p.st = offer.target;
        else if (offer.attribute == rpgDX) p.dx = offer.target;
        else if (offer.attribute == rpgHT) p.ht = offer.target;
        else if (offer.attribute == rpgWill) p.will = offer.target;
        else if (offer.attribute == rpgPerception) p.perception = offer.target;
        else
        {
            local will = p.will; local perception = p.perception;
            p.iq = offer.target; p.will = will + delta; p.perception = perception + delta;
        }
        p.energy = energy + p.maxEnergy - capacity;
    }
    else if (offer.kind == 'trait') p.traits = p.traits + [offer.trait];
    else
    {
        local kept = [];
        foreach (local trait in p.traits) if (trait != offer.trait) kept = kept + [trait];
        p.traits = kept;
    }
    p.developmentRevision += 1;
    foreach (local goal in offer.reopens) goal.advance();
    value.status = 'resolved'; offer.apply(p); return value;
}

/** Explicit publication of an award or purchase result. Call only for a
 * player-visible character; the library never reveals NPC development itself. */
rpgPublishProgress(value)
{
    event('rpg.progress'); eventValue(1); eventValue(value.profile.actor);
    eventValue(value.kind); eventValue(value.id); eventValue(value.status);
    eventValue(value.reason); eventValue(value.points);
    eventValue(value.profile.unspentPoints); eventValue(value.profile.earnedPoints);
    eventValue(value.profile.developmentRevision); return nil;
}

rpgProgressionValidation: InitObject
    execute()
    {
        for (local p = firstObj(RpgProfile); p != nil; p = nextObj(p, RpgProfile))
        {
            rpgInteger(p.earnedPoints, 0, 1000000); rpgInteger(p.unspentPoints, 0, p.earnedPoints);
            rpgInteger(p.developmentRevision, 0, 2147483646);
        }
        local ids = [];
        for (local m = firstObj(RpgMilestone); m != nil; m = nextObj(m, RpgMilestone))
        {
            if (dataType(m.id) != TypeSString || m.id == '' || holds(ids, m.id)) throw new RpgError();
            ids = ids + [m.id]; rpgInteger(m.points, 1, 10000);
        }
        for (local a = firstObj(RpgAward); a != nil; a = nextObj(a, RpgAward))
        {
            if (a.profile == nil || !a.profile.ofKind(RpgProfile)
                || a.milestone == nil || !a.milestone.ofKind(RpgMilestone)
                || rpgAwardSlot(a.profile, a.milestone) != a) throw new RpgError();
        }
        ids = [];
        for (local o = firstObj(RpgDevelopment); o != nil; o = nextObj(o, RpgDevelopment))
        {
            if (dataType(o.id) != TypeSString || o.id == '' || holds(ids, o.id)
                || o.profile == nil || !o.profile.ofKind(RpgProfile)) throw new RpgError();
            ids = ids + [o.id];
            if (o.kind == 'skill')
            {
                if (o.training == nil || !o.training.ofKind(RpgTraining)
                    || !holds(o.profile.skills, o.training)) throw new RpgError();
                local owners = 0;
                for (local p = firstObj(RpgProfile); p != nil; p = nextObj(p, RpgProfile))
                    if (holds(p.skills, o.training)) owners += 1;
                if (owners != 1) throw new RpgError();
                rpgInteger(o.target, 1, 10000);
            }
            else if (o.kind == 'attribute')
            { rpgValidateAttribute(o.attribute); rpgInteger(o.target, 1, 100); }
            else if (o.kind == 'trait' || o.kind == 'remove-trait')
            {
                if (o.trait == nil || !o.trait.ofKind(RpgTrait)) throw new RpgError();
                rpgInteger(o.cost, 1, 10000);
            }
            else throw new RpgError();
            local goals = [];
            foreach (local goal in o.reopens)
            {
                if (!goal.ofKind(RpgChallenge) || holds(goals, goal)) throw new RpgError();
                goals = goals + [goal];
            }
        }
        return nil;
    }
;
