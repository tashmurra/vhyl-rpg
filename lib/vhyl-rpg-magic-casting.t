/* Preview is pure. All commits must run inside a vhyl gameplay transaction. */

rpgMagicValidateIntent(intent)
{
    if (intent == nil || !intent.ofKind(RpgMagicIntent) || intent.state == nil
        || intent.scene == nil || intent.opportunity == nil) throw new RpgError();
    local s = intent.state; local o = intent.opportunity;
    rpgExpandedValidate(s.owner);
    if (!holds(s.owner.contributions, s) || !holds(s.opportunities, o)
        || o.owner != s || o.goal == nil || o.goal.owner != s) rpgExpandedReject('magic-ownership');
    local ids = []; local slots = [];
    foreach (local slot in s.opportunities)
    {
        if (slot.owner != s || slot.id == nil || holds(ids, slot.id)) rpgExpandedReject('magic-opportunity');
        ids = ids + [slot.id];
        foreach (local prior in slots)
            if (prior.goal == slot.goal && prior.ordinal == slot.ordinal)
                rpgExpandedReject('magic-duplicate-opportunity');
        slots = slots + [slot]; rpgInteger(slot.ordinal, 1, 3);
    }
    rpgInteger(intent.reserveSpend, 0, 20); rpgInteger(intent.familiarity, 0, 2);
    rpgInteger(intent.scene.localModifier, -1, 1);
    rpgInteger(intent.scene.coincidences, 0, 1000000);
    rpgInteger(o.goal.attempts, 0, 3);
    return nil;
}

rpgMagicContext(intent, skill)
{
    local c = new RpgContext(); c.profile = intent.state.owner;
    c.actor = c.profile.actor; c.approach = intent; c.skill = skill;
    return c;
}

/** Pure assessment. Unknown/new effects require adjudication; illegal effects
 * are blocked. Neither path asks a provider, rolls, charges or completes a goal. */
rpgAssessMagic(intent)
{
    rpgMagicValidateIntent(intent);
    local s = intent.state; local o = intent.opportunity; local g = o.goal;
    if (o.receipt != nil && o.receiptRevision == g.revision) return rpgMagicRecall(o.receipt);
    local r = new RpgMagicResult();
    if (g.completed) { r.status = 'complete'; return r; }
    if (g.ended || intent.continuation == nil && (g.attempts >= 3 || o.ordinal != g.attempts + 1)
        || intent.continuation != nil && (s.ritual != intent.continuation || o.ordinal != g.attempts))
    { r.reason = 'magic-retry-limit'; return r; }
    if (s.work != nil || s.ritual != nil && intent.continuation != s.ritual)
    { r.reason = 'magic-work-active'; return r; }
    if (s.pendingBacklash != nil) { r.reason = 'magic-consequence-pending'; return r; }
    if (s.lastTurn == intent.scene.worldTurn()) { r.reason = 'magic-world-turn'; return r; }
    local ruling = rpgGmRead(intent);
    if (intent.continuation != nil && intent.fixedRuling != nil)
    { ruling.status = 'ruled'; ruling.packet = intent.fixedRuling[1]; ruling.data = intent.fixedRuling[2]; }
    if (ruling.status != 'ruled') { r.status = ruling.status; r.reason = ruling.reason; return r; }
    r.ruling = [ruling.packet, ruling.data];
    local e = rpgMagicEffectFor(intent, ruling.data[1]); r.effect = e;
    if (e.requirements.length() == 0) rpgExpandedReject('magic-empty-permission');
    rpgInteger(e.minimumMargin, 0, 1000); rpgInteger(e.seconds, 1, 86400);
    rpgInteger(e.fuel, 0, 20); rpgInteger(e.minimumModifier, -100, 0);
    rpgInteger(e.maximumModifier, 0, 100);
    if (e.partialMargin != nil) rpgInteger(e.partialMargin, 0, e.minimumMargin - 1);
    local score = nil; local domains = []; local needPractice = nil; local primary = nil;
    foreach (local pair in e.requirements)
    {
        if (pair.length() != 2 || holds(domains, pair[1])) rpgExpandedReject('magic-requirement');
        rpgInteger(pair[2], 1, 5); domains = domains + [pair[1]];
        local k = rpgMagicKnowledgeFor(s, pair[1]);
        if (s.tool != nil && s.tool.bound && s.tool.designated && s.tool.domain == pair[1]
            && k != nil && !k.exempt && !s.tool.available(intent))
        { r.reason = 'magic-bound-tool'; return r; }
        local level = rpgMagicSkill(s, pair[1], pair[2]);
        if (level == nil) { r.reason = 'magic-permission'; return r; }
        if (score == nil || level < score) { score = level; primary = pair[1]; }
        if (s.requiresPractice && !rpgMagicKnowledgeFor(s, pair[1]).exempt) needPractice = true;
    }
    if (needPractice && intent.practice == nil) { r.reason = 'magic-practice'; return r; }
    rpgInteger(intent.haste,0,100);
    if (intent.instantaneous && intent.haste < 3 || intent.haste > 0 && !intent.instantaneous && intent.haste < 1)
    { r.reason = 'magic-haste-policy'; return r; }
    r.seconds = e.seconds;
    if (intent.practice != nil)
    {
        local p = intent.practice; r.reason = p.available(intent);
        if (r.reason != nil) return r;
        if (p.skill != nil)
        {
            local paid = rpgExpandedPaidSkill(s.owner, p.skill, []);
            if (paid == nil || p.minimum != nil && paid < p.minimum)
            { r.reason = 'magic-practice-training'; return r; }
        }
        rpgInteger(p.seconds, 1, 86400);
        if (p.seconds > r.seconds) r.seconds = p.seconds;
    }
    r.reason = e.available(intent); if (r.reason != nil) return r;
    local c = rpgMagicContext(intent, primary);
    r.reason = s.owner.blockedReason(c); if (r.reason != nil) return r;
    score -= domains.length() - 1;
    if (intent.formula != nil)
    {
        local f = intent.formula;
        if (f.owner != s || !holds(s.formulas, f) || f.effect != e)
        { r.reason = 'magic-formula'; return r; }
        if (intent.extraTime) { r.reason = 'magic-fixed-time'; return r; }
        score += f.improvement;
    }
    else if (intent.extraTime) { r.seconds *= 2; score += 1; }
    if (intent.haste > 0) r.seconds = 1;
    score -= intent.haste;
    if (o.distractionRevision == g.revision) score += o.distractionModifier;
    if (r.seconds > 86400) { r.reason = 'magic-time-limit'; return r; }
    if (intent.reserveSpend > s.channel) { r.reason = 'magic-channel'; return r; }
    r.spent = intent.reserveSpend + e.fuel;
    if (r.spent > s.reserve) { r.reason = 'magic-reserve'; return r; }
    local appearance = ruling.data[2];
    score += intent.reserveSpend * 2 + (appearance == 'subtle' ? s.mastery / 2 : 0);
    score += ruling.data[3] + e.fixedModifier + intent.scene.sourceBonus() + intent.scene.modifierFor(intent) - intent.familiarity;
    score -= g.attempts - (intent.continuation == nil ? 0 : 1) + rpgMagicAttention(s) / 2 + intent.ritualPenalty;
    if (appearance == 'subtle' && intent.conspicuous)
    {
        local penalty = intent.scene.coincidences <= 2 ? 0 : (intent.scene.coincidences - 1) / 2;
        score -= penalty > 3 ? 3 : penalty;
    }
    if (!intent.skipPreparation && o.preparationRevision == g.revision) score += o.preparationModifier;
    if (s.tool != nil && s.tool.designated && holds(domains, s.tool.domain) && s.tool.available(intent))
        score += s.tool.bound ? 2 : 1;
    foreach (local trait in s.owner.traits) score += trait.modifierFor(c);
    local extras = s.owner.modifiersFor(c);
    if (extras.length() % 3 != 0) throw new RpgError();
    for (local i = 3; i <= extras.length(); i += 3) score += extras[i];
    rpgInteger(score, -1000, 1000); r.score = score;
    if (score < 3) { r.reason = 'too-difficult'; return r; }
    r.status = 'ready'; return r;
}

/** Commit the validated single-caster noncombat procedure once. Record a guard
 * before authored callbacks so recursive or duplicate delivery cannot recast. */
rpgCastMagic(intent)
{
    local r = rpgAssessMagic(intent); if (r.status != 'ready') return r;
    if (intent.continuation != nil) { r.status = 'blocked'; r.reason = 'magic-use-ritual'; return r; }
    rpgCheckMagicDistractions(intent); r = rpgAssessMagic(intent); if (r.status != 'ready') return r;
    local s = intent.state; local o = intent.opportunity; local g = o.goal; local e = r.effect;
    local c = rpgMagicContext(intent, e.requirements[1][1]);
    s.lastTurn = intent.scene.worldTurn(); s.reserve -= r.spent; s.revision += 1;
    rpgSpendTime(r.seconds - intent.prepaidSeconds); g.attempts += 1;
    r.dice = rpgRandom.dice(); r.check = rpgCheck(r.score, rpgDiceTotal(r.dice));
    local rank = 0;
    foreach (local pair in e.requirements) if (pair[2] > rank) rank = pair[2];
    local mode = r.ruling[2][2];
    r.strainGained = rpgMagicStrainGain(r.check, rank, mode, intent.scene.witnessed());
    rpgMagicAddStrain(s, r.strainGained);
    if (r.check.critical == 'failure') g.ended = true;
    if (r.check.critical == 'failure' && mode == 'overt')
        r.backlashStrength = rpgMagicDischarge(s).strength;
    e.afterRoll(intent,r); rpgMagicFinishScope(intent,r); r.status = 'resolved';
    if (!e.personalPerception) s.recoveryClock = 0;
    r.check.profile = s.owner; r.check.approach = intent; r.check.kind = 'magic';
    r.check.status = 'resolved';
    r.check.outcome = r.outcome == 'full' ? 'success'
        : r.check.critical == 'failure' ? 'complication' : 'setback';
    r.check.achieved = r.outcome == 'full'; r.check.timeSpent = r.seconds;
    r.check.recordedTimeSpent = r.seconds; r.check.dice = r.dice;
    o.receiptRevision = g.revision; o.receipt = r.pack();
    s.owner.afterAttempt(c, r.check);
    if (r.delivered)
    {
        if (mode == 'subtle' && intent.conspicuous) intent.scene.coincidences += 1;
        e.apply(intent, r);
        if (r.outcome == 'full') g.completed = true;
    }
    o.receipt = r.pack();
    return r;
}

modify RpgMagicOpportunity
    preparationRevision = -1
    preparationModifier = 0
    preparationRoll = nil
;

/** Authored ordinary preparation. No magical or complementary modifiers are
 * applied; available must exclude an already magically enhanced base skill. */
class RpgMagicPreparation: object
    intent = nil
    skill = nil
    seconds = 1
    available() { return 'unsupported-preparation'; }
;

/** One preparation check per opportunity, using actual paid mundane training. */
rpgPrepareMagic(preparation)
{
    local intent = preparation.intent; rpgMagicValidateIntent(intent);
    local o = intent.opportunity; local g = o.goal; local r = new RpgExpandedResult();
    if (!intent.skipPreparation && o.preparationRevision == g.revision) { r.status = 'reused'; return r; }
    if (g.ended || g.completed || g.attempts + 1 != o.ordinal
        || o.receiptRevision == g.revision) { r.reason = 'magic-retry-limit'; return r; }
    r.reason = preparation.available(); if (r.reason != nil) return r;
    if (preparation.skill == nil || preparation.skill.ofKind(RpgMagicDomain))
        rpgExpandedReject('magic-preparation-skill');
    local score = rpgExpandedPaidSkill(intent.state.owner, preparation.skill, []);
    if (score == nil || score < 3) { r.reason = 'magic-practice-training'; return r; }
    rpgInteger(preparation.seconds, 1, 86400);
    r.check = rpgCheck(score, rpgRandom.roll());
    r.modifier = r.check.critical == 'success' ? 2 : r.check.critical == 'failure' ? -1
        : r.check.rollSucceeded ? 1 : 0;
    o.preparationRevision = g.revision; o.preparationModifier = r.modifier;
    o.preparationRoll = r.check.roll; rpgSpendTime(preparation.seconds);
    r.seconds = preparation.seconds; r.status = 'resolved'; return r;
}

/** Player-safe envelope; diagnostic reasons, facts, scores and rationale stay
 * private. An author may explicitly disclose more through a separate reporter. */
rpgPublishMagic(intent, result)
{
    event('rpg.magic.result'); eventValue(1); eventValue(intent.opportunity.id);
    eventValue(result.status); eventValue(result.delivered);
    eventValue(result.status == 'resolved' ? result.seconds : 0);
    return nil;
}

/** Shared core-shaped notification for group, ritual and item attempts. */
rpgMagicNotifyAttempt(intent,result)
{
    if (result.check == nil || result.notified) return nil;
    result.notified = true;
    local check = result.check; local c = rpgMagicContext(intent,result.effect.requirements[1][1]);
    check.profile = intent.state.owner; check.approach = intent; check.kind = 'magic'; check.status = 'resolved';
    check.outcome = result.outcome == 'full' ? 'success' : check.critical == 'failure' ? 'complication' : 'setback';
    check.achieved = result.outcome == 'full'; check.timeSpent = result.seconds;
    check.recordedTimeSpent = result.seconds; check.dice = result.dice;
    intent.state.owner.afterAttempt(c,check); return nil;
}
