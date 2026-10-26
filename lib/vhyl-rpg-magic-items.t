/* Item construction is a paid workflow; failed checks never create flawed items. */
class RpgMagicItemAbility: object
    effect = nil
    rating = 0
    command = nil
    gesture = nil
    appearance = 'overt'
;
class RpgMagicItem: object
    id = nil
    abilities = []
    charge = 0
    capacity = 0
    sealed = nil
    destroyed = nil
    activated = nil
    receipts = []
    currencyFactor = 1
    eligible(state) { return state != nil; }
;
class RpgMagicCraft: object
    item = nil
    lead = nil
    contributors = []
    skill = nil
    tier = 0
    active = nil
    elapsed = 0
    required = 0
    planned = nil
    effectScore = 0
    powerScore = 0
    craftScore = 0
    finalizing = nil
    delivered = 0
    available() { return nil; }
;

/** First rating point costs 30 minutes; later tiers grow by an hour. */
rpgMagicCraftSeconds(rating,tier)
{
    rpgInteger(rating,1,100); rpgInteger(tier,0,100);
    local seconds = 0;
    for (local i = 0; i < rating; i++)
    { local n = tier + i; seconds += n == 0 ? 1800 : n * 3600; }
    return seconds;
}

/** Freeze proposed ability and fully qualified participants before work begins. */
rpgBeginMagicCraft(craft,ability)
{
    local r = new RpgExpandedResult();
    if (craft.item == nil || craft.item.destroyed || craft.item.sealed || craft.active != nil || craft.finalizing)
    { r.reason = 'magic-craft-state'; return r; }
    r.reason = craft.available(); if (r.reason != nil) return r;
    local people = [craft.lead] + craft.contributors; local seen = [];
    local effectScore = 1000; local powerScore = 1000;
    foreach (local s in people)
    {
        if (s == nil || holds(seen,s)) rpgExpandedReject('magic-craft-contributor'); seen = seen + [s];
        local power = rpgMagicSkill(s,rpgMagicPower,3);
        if (power == nil) { r.reason = 'magic-craft-permission'; return r; }
        if (power < powerScore) powerScore = power;
        foreach (local p in ability.effect.requirements)
        { local score = rpgMagicSkill(s,p[1],p[2]); if (score == nil) { r.reason = 'magic-craft-permission'; return r; }
          if (score < effectScore) effectScore = score; }
    }
    local paidPower = rpgExpandedPaidSkill(craft.lead.owner,rpgMagicPower,[]);
    local craftScore = craft.skill == nil ? paidPower - 3 : rpgExpandedPaidSkill(craft.lead.owner,craft.skill,[]);
    if (craftScore == nil || craftScore < 3 || !ability.effect.implemented)
    { r.reason = 'magic-craft-training'; return r; }
    local rating = effectScore < powerScore ? effectScore : powerScore;
    ability.rating = rating; craft.effectScore = effectScore; craft.powerScore = powerScore; craft.craftScore = craftScore;
    craft.active = ability; craft.elapsed = 0;
    craft.required = rpgMagicCraftSeconds(rating,craft.tier) + (ability.command || ability.gesture ? 3600 : 0);
    r.status = 'ready'; r.seconds = craft.required; return r;
}

/** Resolve checks in stable craft/effect/power order. Any failed check destroys it. */
rpgAdvanceMagicCraft(craft,seconds)
{
    local r = new RpgExpandedResult();
    if (craft.active == nil) { r.reason = 'magic-craft-inactive'; return r; }
    r.reason = craft.available(); if (r.reason != nil) { rpgInterruptMagicCraft(craft); return r; }
    rpgInteger(seconds,0,craft.required - craft.elapsed); craft.elapsed += seconds; rpgMagicSpendTime(seconds);
    if (craft.elapsed < craft.required) { r.status = 'working'; return r; }
    local success = true;
    foreach (local score in [craft.craftScore,craft.effectScore,craft.powerScore])
        if (!rpgCheck(score,rpgRandom.roll()).rollSucceeded) success = nil;
    craft.tier += craft.active.rating;
    if (success) craft.item.abilities = craft.item.abilities + [craft.active];
    else craft.item.destroyed = true;
    craft.active = nil; r.status = success ? 'resolved' : 'failed'; return r;
}

/** Interruption abandons only the current ability but advances its construction tier. */
rpgInterruptMagicCraft(craft)
{
    if (craft.active != nil) { craft.tier += craft.active.rating; craft.active = nil; }
    if (craft.finalizing) { craft.item.capacity = craft.delivered; craft.item.sealed = true; craft.item.activated = true; craft.finalizing = nil; }
    return nil;
}

/** Final activation is retryable on a failed power check. */
rpgBeginMagicItemCharge(craft)
{
    local r = new RpgExpandedResult(); local item = craft.item;
    if (item.destroyed || item.sealed || craft.active != nil || craft.finalizing || item.abilities.length() == 0)
    { r.reason = 'magic-item-state'; return r; }
    local score = rpgMagicSkill(craft.lead,rpgMagicPower,3);
    if (score == nil) { r.reason = 'magic-permission'; return r; }
    r.check = rpgCheck(score,rpgRandom.roll());
    if (!r.check.rollSucceeded) { r.status = 'failed'; return r; }
    local lowest = 1000; foreach (local a in item.abilities) if (a.rating < lowest) lowest = a.rating;
    item.capacity = lowest * 2; craft.finalizing = true; craft.delivered = 0;
    r.status = 'ready'; return r;
}

/** Ten minutes per initial point; insufficient supply seals at the amount delivered. */
rpgChargeMagicItem(craft,points)
{
    local r = new RpgExpandedResult();
    if (!craft.finalizing) { r.reason = 'magic-item-not-charging'; return r; }
    rpgInteger(points,0,craft.item.capacity - craft.delivered);
    local available = 0; local people = [craft.lead] + craft.contributors;
    foreach (local s in people) available += s.reserve;
    if (points > available) points = available;
    local left = points;
    foreach (local s in people) { local n = s.reserve < left ? s.reserve : left; s.reserve -= n; s.revision += 1; left -= n; }
    craft.delivered += points; craft.item.charge += points; rpgMagicSpendTime(points * 600);
    if (craft.delivered == craft.item.capacity || points == 0 || available == points)
    { craft.item.capacity = craft.delivered; craft.item.sealed = true; craft.item.activated = true; craft.finalizing = nil; }
    r.points = points; r.status = 'resolved'; return r;
}

/** Later recharge uses ordinary transfer throughput, not construction time. */
rpgRechargeMagicItem(item,state,id,requested,margin)
{
    if (!item.sealed || item.destroyed || rpgMagicSkill(state,rpgMagicPower,3) == nil) rpgExpandedReject('magic-item-recharge');
    if (holds(item.receipts,id)) return 0;
    rpgInteger(requested,0,1000); rpgInteger(margin,0,1000);
    local n = (margin < 1 ? 1 : margin) * 5;
    if (n > requested) n = requested;
    if (n > item.capacity - item.charge) n = item.capacity - item.charge;
    if (n > rpgMagicTransferable(state)) n = rpgMagicTransferable(state);
    state.reserve -= n; state.revision += 1; item.charge += n;
    item.receipts = item.receipts + [id]; return n;
}

/** Activation has a fixed effect and item skill, while strain belongs to its user. */
rpgActivateMagicItem(item,ability,intent,contact,command,gesture,payFromUser)
{
    rpgMagicValidateIntent(intent);
    local r = new RpgMagicResult(); local s = intent.state; local g = intent.opportunity.goal;
    if (intent.opportunity.receipt != nil && intent.opportunity.receiptRevision == intent.opportunity.goal.revision)
        return rpgMagicRecall(intent.opportunity.receipt);
    if (g.completed || g.ended || g.attempts >= 3 || intent.opportunity.ordinal != g.attempts + 1)
    { r.reason = 'magic-retry-limit'; return r; }
    if (!item.activated || item.destroyed || !holds(item.abilities,ability) || !contact || !item.eligible(s)
        || ability.command && !command || ability.gesture && !gesture)
    { r.reason = 'magic-item-activation'; return r; }
    if (s.lastTurn == intent.scene.worldTurn() || s.pendingBacklash != nil || s.work != nil || s.ritual != nil)
    { r.reason = 'magic-world-turn'; return r; }
    if (payFromUser ? s.reserve < 1 : item.charge < 1) { r.reason = 'magic-item-charge'; return r; }
    r.reason = ability.effect.available(intent); if (r.reason != nil) return r;
    local ruling = rpgGmRead(intent);
    if (ruling.status != 'ruled' || ruling.data[1] != ability.effect.id || ruling.data[2] != ability.appearance)
    { r.status = 'needs-ruling'; return r; }
    if (payFromUser) s.reserve -= 1; else item.charge -= 1;
    g.attempts += 1;
    r.spent = 1; r.seconds = 1; rpgSpendTime(1); s.lastTurn = intent.scene.worldTurn(); s.recoveryClock = 0;
    r.effect = ability.effect; r.score = ability.rating; r.ruling = [ruling.packet,ruling.data];
    r.dice = rpgRandom.dice(); r.check = rpgCheck(r.score,rpgDiceTotal(r.dice));
    local rank = 0; foreach (local p in r.effect.requirements) if (p[2] > rank) rank = p[2];
    r.strainGained = rpgMagicStrainGain(r.check,rank,ability.appearance,intent.scene.witnessed());
    rpgMagicAddStrain(s,r.strainGained);
    if (r.check.critical == 'failure' && ability.appearance == 'overt') r.backlashStrength = rpgMagicDischarge(s).strength;
    if (r.check.critical == 'failure') g.ended = true;
    r.effect.afterRoll(intent,r); rpgMagicFinishScope(intent,r); r.status = 'resolved';
    intent.opportunity.receiptRevision = intent.opportunity.goal.revision; intent.opportunity.receipt = r.pack();
    rpgMagicNotifyAttempt(intent,r);
    if (r.delivered) { if (ability.appearance == 'subtle' && intent.conspicuous) intent.scene.coincidences += 1;
        r.effect.apply(intent,r); if (r.outcome == 'full') g.completed = true; }
    intent.opportunity.receipt = r.pack();
    return r;
}

/** Authored currency conversion, not a guaranteed resale value. */
rpgMagicItemPrice(item)
{
    local price = 0;
    foreach (local a in item.abilities)
    { price += a.rating * 1000; foreach (local p in a.effect.requirements) price += [2000,4000,8000,16000,32000][p[2]]; }
    return price * item.currencyFactor;
}

/** Depletion is not disenchantment. Requires a successful power-four delivery. */
rpgDisenchantMagicItem(item,state)
{
    if (rpgMagicSkill(state,rpgMagicPower,4) == nil) rpgExpandedReject('magic-permission');
    item.activated = nil; item.charge = 0; return nil;
}
