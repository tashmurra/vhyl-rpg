/* Fully qualified cooperation. The host fixes participant order before rolling. */
class RpgMagicGroup: object
    intents = []
    communicating = true
    mutualSight = true
    result = nil
    rolls = []
;

/** Validate every participant before any time, reserve, strain or RNG mutation. */
rpgCastMagicGroup(group)
{
    if (group.result != nil) return rpgMagicRecall(group.result);
    local out = new RpgMagicResult(); local assessments = []; local states = []; local effect = nil;
    if (group.intents.length() < 2 || !group.communicating || !group.mutualSight)
    { out.reason = 'magic-group-communication'; return out; }
    local seconds = 0; local appearance = nil;
    foreach (local intent in group.intents)
    {
        if (holds(states,intent.state) || intent.continuation != nil) rpgExpandedReject('magic-group-participant');
        states = states + [intent.state]; local r = rpgAssessMagic(intent);
        if (r.status != 'ready') return r;
        if (effect == nil) { effect = r.effect; appearance = r.ruling[2][2]; }
        if (r.effect != effect || r.ruling[2][2] != appearance
            || intent.scene != group.intents[1].scene) { out.reason = 'magic-group-effect'; return out; }
        if (r.seconds > seconds) seconds = r.seconds;
        assessments = assessments + [r];
    }
    local rank = 0; foreach (local p in effect.requirements) if (p[2] > rank) rank = p[2];
    local margin = 0; local successes = 0; local criticalFailure = nil; local criticalSuccess = nil; local strain = 0;
    for (local i = 1; i <= group.intents.length(); i++)
    {
        local intent = group.intents[i]; local s = intent.state; local r = assessments[i];
        s.reserve -= r.spent; s.lastTurn = intent.scene.worldTurn(); s.revision += 1;
        if (!effect.personalPerception) s.recoveryClock = 0;
        intent.opportunity.goal.attempts += 1;
        r.dice = rpgRandom.dice(); r.check = rpgCheck(r.score,rpgDiceTotal(r.dice));
        if (r.check.rollSucceeded) { margin += r.check.margin; successes += 1; }
        if (r.check.critical == 'failure') criticalFailure = true;
        if (r.check.critical == 'success') criticalSuccess = true;
        strain += rpgMagicStrainGain(r.check,rank,appearance,intent.scene.witnessed());
    }
    rpgSpendTime(seconds); group.rolls = assessments;
    local lead = group.intents[1]; out = assessments[1]; out.seconds = seconds;
    /* Aggregate check is separate, preserving all individual check objects. */
    out = new RpgMagicResult(); out.effect = effect; out.score = assessments[1].score;
    out.dice = assessments[1].dice; out.ruling = assessments[1].ruling;
    out.check = rpgCheck(out.score,assessments[1].check.roll);
    out.check.margin = margin; out.check.rollSucceeded = successes > 0 && !criticalFailure;
    out.check.critical = criticalFailure ? 'failure' : criticalSuccess ? 'success' : nil;
    out.resistanceRolls = assessments; out.strainGained = strain; out.seconds = seconds; out.status = 'resolved';
    for (local i = 1; i <= group.intents.length(); i++)
    {
        local intent = group.intents[i]; local s = intent.state;
        rpgMagicAddStrain(s,strain);
        if (criticalFailure)
        { intent.opportunity.goal.ended = true;
          if (appearance == 'overt') assessments[i].backlashStrength = rpgMagicDischarge(s).strength; }
    }
    effect.afterRoll(lead,out); rpgMagicFinishScope(lead,out);
    /* Install guards for all entry points before delivery. */
    foreach (local intent in group.intents)
    { intent.opportunity.receiptRevision = intent.opportunity.goal.revision; intent.opportunity.receipt = out.pack(); }
    group.result = out.pack();
    for (local i = 1; i <= group.intents.length(); i++)
    { assessments[i].outcome = out.outcome; assessments[i].seconds = seconds; rpgMagicNotifyAttempt(group.intents[i],assessments[i]); }
    if (out.delivered)
    {
        effect.apply(lead,out);
        if (appearance == 'subtle' && lead.conspicuous) lead.scene.coincidences += 1;
        foreach (local intent in group.intents) if (out.outcome == 'full') intent.opportunity.goal.completed = true;
    }
    foreach (local intent in group.intents) intent.opportunity.receipt = out.pack();
    group.result = out.pack();
    return out;
}

class RpgMagicGroupRitual: object
    group = nil
    members = []
    rolls = 0
    limit = 0
    progress = 0
    failures = 0
    ended = nil
    result = nil
;

/** Ritual cooperation has one progress pool and one lead-based roll allowance. */
rpgBeginMagicGroupRitual(group,category)
{
    if (group.intents.length() < 2 || !group.communicating || !group.mutualSight) rpgExpandedReject('magic-group-communication');
    local effect = nil; local seen = [];
    foreach (local intent in group.intents)
    { local r = rpgAssessMagic(intent); if (r.status != 'ready') return r;
      if (holds(seen,intent.state)) rpgExpandedReject('magic-group-participant'); seen = seen + [intent.state];
      if (effect != nil && effect != r.effect) rpgExpandedReject('magic-group-effect'); effect = r.effect; }
    local ritual = new RpgMagicGroupRitual(); ritual.group = group; ritual.limit = 3 + group.intents[1].state.mastery;
    foreach (local intent in group.intents)
    { local member = rpgBeginMagicRitual(intent,category); member.groupMode = true; member.limit = ritual.limit;
      member.leadDelivery = ritual.members.length() == 0; ritual.members = ritual.members + [member]; }
    return ritual;
}

rpgEndMagicGroupRitual(ritual,success,critical)
{
    if (ritual.ended) return ritual.result;
    ritual.ended = true;
    local all = [];
    foreach (local member in ritual.members) foreach (local contribution in member.contributions)
    { local copy = new RpgMagicResult(); copy.score = contribution.score; copy.check = rpgCheck(copy.score,contribution.check.roll); all = all + [copy]; }
    foreach (local member in ritual.members)
    { if (member.result != nil) member.result.resistanceRolls = all; member.progress = ritual.progress; local r = rpgEndMagicRitual(member,success,critical);
      if (member.leadDelivery) ritual.result = r; }
    foreach (local member in ritual.members)
    {
        member.result.outcome = ritual.result.outcome; member.result.delivered = ritual.result.delivered;
        member.intent.opportunity.goal.completed = ritual.result.delivered && ritual.result.outcome == 'full';
        rpgMagicNotifyAttempt(member.intent,member.result);
        member.intent.opportunity.receipt = member.result.pack();
    }
    return ritual.result;
}

/** Sum raw successful margins, then apply exact-success minimum once. */
rpgRollMagicGroupRitual(ritual)
{
    if (ritual.ended) return ritual.result;
    if (!ritual.group.communicating || !ritual.group.mutualSight) return rpgEndMagicGroupRitual(ritual,nil,nil);
    foreach (local member in ritual.members)
    { member.failures = ritual.failures;
      if (member.ended) return rpgEndMagicGroupRitual(ritual,nil,nil);
      local preview = rpgAssessMagic(member.intent); if (preview.status != 'ready') return preview; }
    local strain = 0; local margin = 0; local success = nil; local critical = nil; local seconds = 0;
    foreach (local member in ritual.members)
    {
        local before = rpgLedger.seconds; local r = rpgRollMagicRitual(member);
        local spent = rpgLedger.seconds - before; if (spent > seconds) seconds = spent;
        /* Participants work concurrently; ledger time is settled once below. */
        rpgLedger.seconds = before;
        if (member.ended || r.check == nil) { rpgSpendTime(seconds); return rpgEndMagicGroupRitual(ritual,nil,nil); }
        strain += r.strainGained;
        if (r.check.rollSucceeded) { success = true; margin += r.check.margin; }
        if (r.check.critical == 'failure') critical = true;
    }
    rpgSpendTime(seconds); ritual.rolls += 1;
    foreach (local member in ritual.members)
    { rpgMagicAddStrain(member.intent.state,strain);
      if (critical && member.result.ruling[2][2] == 'overt')
          member.result.backlashStrength = rpgMagicDischarge(member.intent.state).strength; }
    if (critical) return rpgEndMagicGroupRitual(ritual,nil,true);
    if (success) ritual.progress += margin < 1 ? 1 : margin; else ritual.failures += 1;
    local effect = ritual.members[1].assessment.effect;
    local criticalSuccess = nil; foreach (local member in ritual.members) if (member.criticalSuccess) criticalSuccess = true;
    foreach (local member in ritual.members) member.criticalSuccess = criticalSuccess;
    if (ritual.progress >= rpgMagicRitualRequired(ritual.members[1])) return rpgEndMagicGroupRitual(ritual,true,nil);
    if (ritual.rolls >= ritual.limit)
        return rpgEndMagicGroupRitual(ritual,effect.partialMargin != nil && ritual.progress >= effect.partialMargin,nil);
    foreach (local member in ritual.members) rpgMagicNotifyAttempt(member.intent,member.result);
    return ritual.members[1].result;
}
