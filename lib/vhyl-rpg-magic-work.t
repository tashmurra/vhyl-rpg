/* Ordinary work and extended rituals have explicit lifecycle state. */
class RpgMagicWork: object
    intent = nil
    assessment = nil
    packet = nil
    elapsed = 0
    required = 0
    ended = nil
    result = nil
;
class RpgMagicRitual: RpgMagicWork
    category = 'brief'
    interval = 300
    rolls = 0
    limit = 0
    progress = 0
    failures = 0
    provisional = 0
    endurance = 0
    enduranceChecks = 0
    pauses = 0
    pausedAt = nil
    setup = true
    otherActive = nil
    groupMode = nil
    criticalSuccess = nil
    leadDelivery = true
    facts = []
    contributions = []
;
modify RpgMagicIntent
    continuation = nil
    fixedRuling = nil
    ritualPenalty = 0
    skipPreparation = nil
;

/** Begin work without rolling or debiting reserve. Pending ruling is not enough. */
rpgBeginMagicWork(intent)
{
    local assessment = rpgAssessMagic(intent);
    if (assessment.status != 'ready') return assessment;
    if (intent.state.work != nil || intent.state.ritual != nil) rpgExpandedReject('magic-work-active');
    local work = new RpgMagicWork(); work.intent = intent; work.assessment = assessment;
    work.packet = assessment.ruling; work.required = assessment.seconds;
    intent.state.work = work; return work;
}

/** Elapsed activity is paid even if later interrupted. Reserve is paid at roll time. */
rpgAdvanceMagicWork(work,seconds)
{
    if (work.ended) return work.result;
    rpgInteger(seconds,0,work.required - work.elapsed);
    work.elapsed += seconds; rpgSpendTime(seconds);
    if (work.elapsed < work.required) return nil;
    /* Live facts and resource availability are revalidated at completion. */
    work.intent.state.work = nil;
    work.intent.prepaidSeconds = work.required;
    work.result = rpgCastMagic(work.intent); work.intent.prepaidSeconds = 0;
    work.ended = true; return work.result;
}
modify RpgMagicIntent
    prepaidSeconds = 0
;

/** Start one whole ritual in the ordinary bounded retry sequence. */
rpgBeginMagicRitual(intent,category)
{
    local r = rpgAssessMagic(intent); if (r.status != 'ready') return r;
    local s = intent.state;
    if (rpgMagicAttention(s) > 1) { r.status = 'blocked'; r.reason = 'magic-ritual-concentration'; return r; }
    if (s.work != nil || s.ritual != nil || !holds(['brief','ceremony','major'],category))
        rpgExpandedReject('magic-ritual-start');
    local ritual = new RpgMagicRitual(); ritual.intent = intent; ritual.assessment = r;
    ritual.category = category; ritual.interval = category == 'brief' ? 300 : category == 'ceremony' ? 3600 : 18000;
    ritual.otherActive = rpgMagicAttention(s) == 1;
    ritual.limit = 3 + s.mastery; ritual.packet = r.ruling; ritual.facts = rpgMagicWorkFacts(intent,r.effect);
    s.ritual = ritual; intent.opportunity.goal.attempts += 1;
    intent.continuation = ritual; intent.fixedRuling = r.ruling; return ritual;
}

/** End ritual exactly once; clear only its surviving provisional strain. */
rpgEndMagicRitual(ritual,success,critical)
{
    if (ritual.ended) return ritual.result;
    local intent = ritual.intent; local s = intent.state; local g = intent.opportunity.goal;
    ritual.ended = true; s.ritual = nil;
    s.provisional -= ritual.provisional;
    if (!success) s.strain += ritual.provisional;
    ritual.provisional = 0; s.revision += 1;
    intent.continuation = nil; intent.fixedRuling = nil; intent.ritualPenalty = 0; intent.skipPreparation = nil;
    local r = ritual.result;
    if (r == nil) { r = new RpgMagicResult(); r.effect = ritual.assessment.effect; r.outcome = 'interrupted'; r.status = 'resolved'; }
    if (!ritual.groupMode)
    { local rolls = [];
      foreach (local contribution in ritual.contributions)
      { local copy = new RpgMagicResult(); copy.score = contribution.score; copy.check = rpgCheck(copy.score,contribution.check.roll); rolls = rolls + [copy]; }
      r.resistanceRolls = rolls; }
    r.seconds = ritual.elapsed; r.delivered = success;
    if (!success && !critical) r.outcome = 'unfinished';
    if (r.check != nil && ritual.leadDelivery) r.effect.afterRoll(intent,r);
    if (critical) { g.ended = true; r.outcome = 'failure'; }
    if (success && ritual.leadDelivery)
    {
        r.scope = ritual.progress;
        r.check = rpgCheck(r.score,r.check.roll); r.check.rollSucceeded = true;
        if (ritual.criticalSuccess) r.check.critical = 'success';
        r.check.margin = ritual.progress;
        r.scope = rpgMagicCounterScope(intent,r);
        r.outcome = r.scope >= r.effect.requiredMargin(r.check) ? 'full' : r.effect.partialMargin != nil && r.scope >= r.effect.partialMargin ? 'partial' : 'insufficient';
        r.delivered = r.outcome != 'insufficient';
        if (r.delivered) r.effect.defend(intent,r);
        if (r.delivered) { if (r.ruling[2][2] == 'subtle' && intent.conspicuous) intent.scene.coincidences += 1;
            r.effect.apply(intent,r); if (r.outcome == 'full') g.completed = true; }
    }
    if (success && !ritual.leadDelivery) { r.scope = ritual.progress; r.outcome = ritual.progress >= r.effect.minimumMargin ? 'full' : 'partial'; if (r.outcome == 'full') g.completed = true; }
    intent.opportunity.receiptRevision = g.revision; intent.opportunity.receipt = r.pack();
    if (!ritual.groupMode) rpgMagicNotifyAttempt(intent,r);
    ritual.result = r; return r;
}

/** One bounded ritual interval; endurance failures are not casting failures. */
rpgRollMagicRitual(ritual)
{
    if (ritual.ended) return ritual.result;
    if (ritual.pausedAt != nil || !ritual.setup) rpgExpandedReject('magic-ritual-paused');
    local intent = ritual.intent; local s = intent.state;
    if (!rpgGmSame(ritual.facts,rpgMagicWorkFacts(intent,ritual.assessment.effect))) return rpgEndMagicRitual(ritual,nil,nil);
    if (ritual.rolls >= ritual.limit) return rpgEndMagicRitual(ritual,nil,nil);
    if (rpgMagicAttention(s) > 1) return rpgEndMagicRitual(ritual,nil,nil);
    ritual.otherActive = rpgMagicAttention(s) == 1;
    intent.ritualPenalty = ritual.failures + (ritual.otherActive ? 1 : 0);
    intent.skipPreparation = ritual.rolls > 0;
    local r = rpgAssessMagic(intent); if (r.status != 'ready') return r;
    local capacity = rpgMagicCapacity(s) - (ritual.rolls > 0 ? 1 : 0);
    if (r.spent > capacity) { r.status = 'blocked'; r.reason = 'magic-reserve'; return r; }
    local allowance = s.owner.attributeScore(rpgHT) / 3; if (allowance < 1) allowance = 1;
    local remainingTime = ritual.interval;
    while (remainingTime > 0)
    {
        if (ritual.endurance % 3600 == 0 && ritual.endurance / 3600 >= allowance)
        {
            local check = rpgCheck(s.owner.attributeScore(rpgHT) - ritual.enduranceChecks,rpgRandom.roll());
            ritual.enduranceChecks += 1;
            if (!check.rollSucceeded) return rpgEndMagicRitual(ritual,nil,nil);
        }
        local chunk = 3600 - ritual.endurance % 3600;
        if (chunk > remainingTime) chunk = remainingTime;
        rpgSpendTime(chunk); ritual.endurance += chunk; ritual.elapsed += chunk; remainingTime -= chunk;
    }
    if (ritual.rolls > 0)
    { ritual.provisional += 1; s.provisional += 1; rpgMagicAddStrain(s,0); }
    if (s.reserve < r.spent) { r.reason = 'magic-reserve'; r.status = 'blocked'; return r; }
    s.reserve -= r.spent; s.revision += 1; s.lastTurn = intent.scene.worldTurn(); s.recoveryClock = 0;
    ritual.rolls += 1;
    r.dice = rpgRandom.dice(); r.check = rpgCheck(r.score,rpgDiceTotal(r.dice));
    local rank = 0; foreach (local p in r.effect.requirements) if (p[2] > rank) rank = p[2];
    r.strainGained = rpgMagicStrainGain(r.check,rank,r.ruling[2][2],intent.scene.witnessed());
    if (!ritual.groupMode) rpgMagicAddStrain(s,r.strainGained); r.status = 'resolved'; r.seconds = ritual.interval;
    if (r.check.critical == 'success') ritual.criticalSuccess = true;
    ritual.result = r; ritual.contributions = ritual.contributions + [r];
    if (ritual.groupMode) return r;
    if (r.check.critical == 'failure')
    { if (r.ruling[2][2] == 'overt') r.backlashStrength = rpgMagicDischarge(s).strength;
      return rpgEndMagicRitual(ritual,nil,true); }
    if (r.check.rollSucceeded)
    { local progress = r.check.margin < 1 ? 1 : r.check.margin; ritual.progress += progress; }
    else ritual.failures += 1;
    if (ritual.progress >= rpgMagicRitualRequired(ritual)) return rpgEndMagicRitual(ritual,true,nil);
    if (ritual.rolls == ritual.limit)
        return rpgEndMagicRitual(ritual,r.effect.partialMargin != nil && ritual.progress >= r.effect.partialMargin,nil);
    rpgMagicNotifyAttempt(intent,r); return r;
}

/** Major workings alone permit controlled pauses between completed rolls. */
rpgPauseMagicRitual(ritual)
{
    if (ritual.ended || ritual.category != 'major' || ritual.rolls == 0 || ritual.pausedAt != nil
        || ritual.intent.state.world == nil) rpgExpandedReject('magic-ritual-pause');
    ritual.pausedAt = ritual.intent.state.world.seconds; return nil;
}

/** Resume uses paid capped domain skill, no casting bonuses. */
rpgResumeMagicRitual(ritual,slept)
{
    if (ritual.ended) return ritual.result;
    if (ritual.pausedAt == nil) rpgExpandedReject('magic-ritual-not-paused');
    local s = ritual.intent.state;
    if (!ritual.setup || s.world.seconds - ritual.pausedAt > 172800) return rpgEndMagicRitual(ritual,nil,nil);
    local score = 1000;
    foreach (local p in ritual.assessment.effect.requirements)
    { local n = rpgMagicSkill(s,p[1],p[2]); if (n == nil) return rpgEndMagicRitual(ritual,nil,nil); if (n < score) score = n; }
    local check = rpgCheck(score - ritual.pauses,rpgRandom.roll()); ritual.pauses += 1;
    if (!check.rollSucceeded) return rpgEndMagicRitual(ritual,nil,nil);
    ritual.pausedAt = nil;
    if (slept) { ritual.endurance = 0; ritual.enduranceChecks = 0; }
    return nil;
}

/** One interruption check, distinct from ordinary distractions. */
rpgInterruptMagic(state,cause)
{
    local work = state.ritual == nil ? state.work : state.ritual;
    if (work == nil || work.ended) return nil;
    local automatic = holds(['stun','unconscious','setup-destroyed'],cause);
    if (!automatic && rpgCheck(state.owner.attributeScore(rpgWill) - 3,rpgRandom.roll()).rollSucceeded) return nil;
    if (state.ritual != nil) return rpgEndMagicRitual(work,nil,nil);
    work.ended = true; state.work = nil; local r = new RpgMagicResult(); r.status = 'resolved'; r.outcome = 'interrupted'; work.result = r;
    return r;
}

/** Freeze world facts, leaving the ritual's own resource changes out of its ruling. */
rpgMagicWorkFacts(intent,effect)
{
    return [effect.facts(intent),intent.method,intent.targetIds,intent.scene.revision,
        intent.scene.modifierFor(intent),intent.scene.sourceBonus(),intent.scene.witnessed(),intent.practice == nil ? nil : intent.practice.available(intent)];
}

modify RpgMagicIntent
    distractions = 0
    multitasking = nil
    haste = 0
    instantaneous = nil
;
modify RpgMagicOpportunity
    distractionRevision = -1
    distractionModifier = 0
;

/** Commit an ordinary distraction assessment once per attempt. Forced physical
 * interruptions use their own Will-3 check instead. */
rpgCheckMagicDistractions(intent)
{
    local o = intent.opportunity;
    if (o.distractionRevision == o.goal.revision) return o.distractionModifier;
    rpgInteger(intent.distractions,0,100);
    o.distractionRevision = o.goal.revision;
    if (!intent.multitasking && intent.distractions > 0)
    {
        local check = rpgCheck(intent.state.owner.attributeScore(rpgWill) - intent.distractions,rpgRandom.roll());
        if (!check.rollSucceeded) o.distractionModifier = -(intent.distractions > 5 ? 5 : intent.distractions);
    }
    return o.distractionModifier;
}

/** Additional casting requires authored feasibility and preserves the ritual's
 * one-extra-active-effect limit. Host world turns and normal costs still apply. */
rpgCastDuringMagicRitual(ritual,intent,feasible)
{
    local r = new RpgMagicResult(); local s = intent.state;
    if (ritual.ended || ritual.pausedAt != nil || s.ritual != ritual || intent == ritual.intent || !feasible)
    { r.reason = 'magic-ritual-other-activity'; return r; }
    s.ritual = nil; r = rpgCastMagic(intent); s.ritual = ritual;
    if (rpgMagicAttention(s) > 1) rpgExpandedReject('magic-ritual-concentration');
    ritual.otherActive = rpgMagicAttention(s) == 1; return r;
}

/** Only range/duration critical eligibility changes the ritual's completion threshold. */
rpgMagicRitualRequired(ritual)
{
    local check = new RpgResult(); check.critical = ritual.criticalSuccess ? 'success' : nil;
    return ritual.assessment.effect.requiredMargin(check);
}
