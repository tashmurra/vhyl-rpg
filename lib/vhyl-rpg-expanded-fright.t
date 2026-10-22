/* Fright Checks. Include after the expanded foundation and expanded traits.
 * Source: full-2008, B360-B361 (procedure, modifiers, results); trait effects
 * B127 (Combat Paralysis), B129 (Cowardice), B135 (Fearfulness), B162 (Xenophilia).
 *
 * Dice are drawn in a fixed order: the check, the results roll, then each row's
 * own dice in the order its effects are listed in docs/expanded/fright.md.
 * Effects that need an author decision (which quirk, which phobia, which
 * physical change) are recorded as pending acquisitions, never invented. */

/** Authored facts about one frightening encounter. All fields are optional. */
class RpgFrightSituation: object
    threat = nil
    monster = 0
    count = 1
    body = nil
    mutilation = 1
    dependent = nil
    inCombat = nil
    touched = nil
    viewing = 'present'
    isolated = nil
    dark = nil
    alone = nil
    experienced = nil
    briefing = 0
    physicalDanger = nil
    charging = nil
    swornFoe = nil
    strange = nil
    modifier = 0
;

/** A mental or physical change the author must choose; points are the required total. */
class RpgFrightAcquisition: object
    kind = 'quirk'
    points = -1
    row = nil
;

/** A timed fear condition. Only one is active per character; a new one replaces it. */
class RpgFrightEpisode: object
    kind = 'stun'
    fixed = 0
    interval = 1
    clock = 0
    recovery = 'automatic'
    score = nil
    extendSeconds = 0
    elapsed = 0
    days = 0
    medicalCare = nil
    penaltySeconds = 0
;

/** Receipt for one Fright Check or one applied results row. */
class RpgFrightResult: object
    status = 'blocked'
    reason = nil
    check = nil
    score = nil
    modifier = 0
    tableRoll = nil
    total = nil
    row = nil
    episode = nil
    acquisitions = []
    fatigue = 0
    injury = 0
    panicRoll = nil
;

modify RpgLiteProfile
    frightEpisode = nil
    frightPending = []
    frightExposures = []
    panicked = nil
    retching = nil
    conditionTime(seconds)
    {
        /* A penalty that begins as an episode ends only counts the seconds after it. */
        local lingering = self.lingeringSeconds > 0;
        local left = self.frightEpisode != nil ? rpgFrightAdvance(self, seconds) : seconds;
        if (self.lingeringSeconds > 0)
        {
            self.lingeringSeconds -= lingering ? seconds : left;
            if (self.lingeringSeconds <= 0) { self.lingeringSeconds = 0; self.lingeringPenalty = 0; }
        }
        return nil;
    }
;

/* Holds Lite's fixed-fear timer while an episode owns the character's recovery. */
rpgFrightHold: object seconds = 2000000000;

/** Penalty for a horde: -1 at 5 monsters, -2 at 10, -3 at 20, -4 at 50, -5 at 100+. */
rpgFrightHordePenalty(count)
{
    rpgInteger(count, 1, 1000000);
    return count >= 100 ? -5 : count >= 50 ? -4 : count >= 20 ? -3 : count >= 10 ? -2 : count >= 5 ? -1 : 0;
}

/** Cowardice and Xenophilia scale with self-control: 4, 3, 2 or 1 at 6, 9, 12 or 15. */
rpgFrightControlStep(trait)
{
    local rating = trait.ofKind(RpgExpandedDisadvantage) && trait.selfControlRating != nil
        ? trait.selfControlRating : 12;
    return rating <= 6 ? 4 : rating <= 9 ? 3 : rating <= 12 ? 2 : 1;
}

/** Earlier exposures to the same threat within the last 24 game hours. Pure. */
rpgFrightExposures(profile, threat)
{
    if (threat == nil) return 0;
    local count = 0;
    foreach (local entry in profile.frightExposures)
        if (entry[1] == threat && rpgLedger.seconds - entry[2] < 86400) count += 1;
    return count;
}

/** Situation and conditional trait modifiers. Fearlessness and Combat Reflexes
 * are applied by the shared Lite score for kind 'fright'. Pure. */
rpgFrightModifier(profile, situation)
{
    local s = situation;
    rpgInteger(s.monster, -10, 0); rpgInteger(s.briefing, 0, 3); rpgInteger(s.mutilation, 1, 3);
    rpgInteger(s.modifier, -100, 100);
    local amount = s.modifier + s.monster + rpgFrightHordePenalty(s.count);
    if (s.body == 'prepared') amount += 6;
    else if (s.body == 'peaceful') amount += 2;
    else if (s.body == 'mutilated') amount -= s.mutilation;
    else if (s.body != nil && s.body != 'violent') rpgExpandedReject('fright-body');
    if (s.dependent)
    {
        if (s.body == nil) rpgExpandedReject('fright-dependent-without-body');
        amount -= 6;
    }
    if (s.inCombat) amount += 5;
    if (s.touched) amount -= 1;
    if (s.viewing == 'distant') amount += 1;
    else if (s.viewing == 'remote') amount += 3;
    else if (s.viewing != 'present') rpgExpandedReject('fright-viewing');
    if (s.isolated) amount -= 1;
    if (s.dark) amount -= 1;
    if (s.alone) amount -= 2;
    if (s.experienced) amount += 1;
    amount += s.briefing + rpgFrightExposures(profile, s.threat);
    amount -= profile.level('fearfulness') + 2 * profile.level('combat-paralysis');
    if (s.physicalDanger && profile.level('cowardice') > 0)
        amount -= rpgFrightControlStep(profile.trait('cowardice'));
    if (s.charging && profile.level('daredevil') > 0) amount += 1;
    if (s.swornFoe && profile.level('higher-purpose') > 0) amount += 1;
    if (s.strange && profile.level('xenophilia') > 0)
        amount += rpgFrightControlStep(profile.trait('xenophilia'));
    return amount;
}

/** Modified Will before the Rule of 14. Pure. */
rpgFrightModifiedWill(profile, situation)
{
    local context = new RpgLiteContext(); context.attribute = rpgWill; context.kind = 'fright';
    context.modifier = rpgFrightModifier(profile, situation);
    return rpgLiteScore(profile, context);
}

/** Fright Check target: modified Will, reduced to 13 (the Rule of 14). Pure. */
rpgFrightScore(profile, situation)
{
    local score = rpgFrightModifiedWill(profile, situation);
    return score > 13 ? 13 : score;
}

/** Roll 3d against a score. Below 3 the roll still sets a margin; 3 or 4 always succeeds. */
rpgFrightRoll(profile, score)
{
    local roll = rpgRandom.roll();
    local result;
    if (score >= 3) result = rpgCheck(score, roll);
    else
    {
        result = new RpgResult(); result.status = 'resolved'; result.score = score;
        result.roll = roll; result.margin = score - roll; result.achieved = roll <= 4;
        result.critical = roll <= 4 ? 'success' : roll == 18 || roll == 17 || roll - score >= 10 ? 'failure' : nil;
        result.outcome = result.achieved ? 'success' : 'setback';
    }
    profile.lastCheck = result; profile.lastCheckDraw = rpgRandom.draws;
    return result;
}

/** Whether a fear condition currently prevents purposeful action. */
rpgFrightIncapacitated(profile)
{
    return profile.frightEpisode != nil;
}

/** Make a Fright Check and apply any failure. Call from Action.exec. */
rpgFrightCheck(profile, situation)
{
    rpgExpandedValidate(profile);
    local result = new RpgFrightResult();
    if (profile.dead || profile.unconscious) { result.reason = 'incapacitated'; return result; }
    if (profile.level('unfazeable') > 0) { result.status = 'exempt'; return result; }
    local modified = rpgFrightModifiedWill(profile, situation);
    result.modifier = rpgFrightModifier(profile, situation);
    result.score = modified > 13 ? 13 : modified;
    if (situation.threat != nil)
    {
        local kept = [];
        foreach (local entry in profile.frightExposures)
            if (rpgLedger.seconds - entry[2] < 86400) kept = kept + [entry];
        profile.frightExposures = kept + [[situation.threat, rpgLedger.seconds]];
    }
    result.check = rpgFrightRoll(profile, result.score);
    if (result.check.achieved) { result.status = 'resisted'; return result; }
    result.tableRoll = rpgRandom.roll();
    rpgFrightApplyRow(profile, result, result.tableRoll - result.check.margin, modified);
    return result;
}

/** Apply one results row directly, e.g. for an author-chosen substitute result. */
rpgFrightApply(profile, total, modifiedWill)
{
    rpgExpandedValidate(profile);
    rpgInteger(total, 4, 1000); rpgInteger(modifiedWill, -1000, 1000);
    local result = new RpgFrightResult();
    rpgFrightApplyRow(profile, result, total, modifiedWill);
    return result;
}

/* Begin an episode, replacing any current one. */
rpgFrightBegin(profile, result, kind, fixed, recovery, interval, score)
{
    rpgFrightEnd(profile);
    local episode = new RpgFrightEpisode();
    episode.kind = kind; episode.fixed = fixed; episode.recovery = recovery;
    episode.interval = interval; episode.score = score;
    profile.frightEpisode = episode; profile.fearSeconds = rpgFrightHold.seconds;
    if (kind == 'stun') profile.stunned = true;
    else if (kind == 'seizure') { profile.stunned = true; profile.posture = 'lying'; }
    else if (kind == 'panic' || kind == 'total-panic') profile.panicked = true;
    else if (kind == 'retch') profile.retching = true;
    else { profile.unconscious = true; profile.posture = 'lying'; }
    result.episode = episode;
    return episode;
}

/* Clear the flags an episode set and start any lingering penalty. */
rpgFrightEnd(profile)
{
    local episode = profile.frightEpisode;
    if (episode == nil) return nil;
    profile.frightEpisode = nil; profile.fearSeconds = 0;
    if (episode.kind == 'stun' || episode.kind == 'seizure') profile.stunned = nil;
    else if (episode.kind == 'panic' || episode.kind == 'total-panic') profile.panicked = nil;
    else if (episode.kind == 'retch') profile.retching = nil;
    else if (profile.hp() > 0 && profile.fp() > 0) profile.unconscious = nil;
    if (episode.penaltySeconds > 0)
    {
        profile.lingeringPenalty = 2;
        if (episode.penaltySeconds > profile.lingeringSeconds) profile.lingeringSeconds = episode.penaltySeconds;
    }
    return nil;
}

/* Recovery roll at the end of a fixed period or interval. */
rpgFrightRecovers(profile, episode)
{
    if (episode.recovery == 'automatic') return true;
    if (episode.recovery == 'will') return rpgFrightRoll(profile, profile.will).achieved;
    if (episode.recovery == 'modified-will') return rpgFrightRoll(profile, episode.score).achieved;
    return rpgFrightRoll(profile, profile.ht).achieved;
}

/** Advance the active episode by game seconds; called from rpgLiteHealthTime.
 * Returns the seconds left over after the episode ended (0 while it continues). */
rpgFrightAdvance(profile, seconds)
{
    rpgInteger(seconds, 0, 86400);
    while (seconds > 0 && profile.frightEpisode != nil && !profile.dead)
    {
        local episode = profile.frightEpisode;
        if (episode.kind == 'total-panic') { seconds = 0; break; }
        local step = episode.fixed > 0 ? episode.fixed : episode.interval - episode.clock;
        if (step > seconds) step = seconds;
        if (episode.kind == 'catatonia')
        {
            local toDay = 86400 - episode.elapsed % 86400;
            if (step > toDay) step = toDay;
        }
        seconds -= step; episode.elapsed += step;
        if (episode.kind == 'catatonia' && episode.elapsed % 86400 == 0)
        {
            episode.days += 1;
            if (!episode.medicalCare) rpgLiteWound(profile, episode.days);
            if (profile.dead) return 0;
        }
        if (episode.fixed > 0)
        {
            episode.fixed -= step;
            if (episode.fixed > 0) continue;
            if (episode.extendSeconds > 0)
            {
                if (rpgFrightRoll(profile, profile.ht).achieved) { rpgFrightFinish(profile, episode); continue; }
                episode.fixed = rpgRandom.die() * episode.extendSeconds; continue;
            }
            if (episode.recovery == 'automatic') { rpgFrightFinish(profile, episode); continue; }
            episode.clock = 0; continue;
        }
        episode.clock += step;
        if (episode.clock < episode.interval) continue;
        episode.clock = 0;
        if (rpgFrightRecovers(profile, episode)) rpgFrightFinish(profile, episode);
    }
    if (profile.frightEpisode != nil) { profile.fearSeconds = rpgFrightHold.seconds; return 0; }
    return seconds;
}

/* Finish an episode; catatonia's lingering penalty lasts as many days as it did. */
rpgFrightFinish(profile, episode)
{
    if (episode.kind == 'catatonia') episode.penaltySeconds = (episode.elapsed + 86399) / 86400 * 86400;
    rpgFrightEnd(profile);
    return nil;
}

/** After an author resolves a total-panic reaction, roll Will to come out of it.
 * Returns the next 3d reaction roll, or nil when the panic ends. */
rpgFrightPanicReaction(profile)
{
    local episode = profile.frightEpisode;
    if (episode == nil || episode.kind != 'total-panic') rpgExpandedReject('fright-no-total-panic');
    if (rpgFrightRoll(profile, profile.will).achieved) { rpgFrightEnd(profile); return nil; }
    return rpgRandom.roll();
}

/* Record a pending author choice. */
rpgFrightPending(profile, result, kind, points, row)
{
    local item = new RpgFrightAcquisition(); item.kind = kind; item.points = points; item.row = row;
    profile.frightPending = profile.frightPending + [item];
    result.acquisitions = result.acquisitions + [item];
    return item;
}

/* Faint for 1d minutes, then HT each minute; an immediate HT roll risks 1 HP (row 18). */
rpgFrightFaint(profile, result, row)
{
    local minutes = rpgRandom.die();
    rpgFrightBegin(profile, result, 'faint', minutes * 60, 'ht', 60, nil);
    if (!rpgFrightRoll(profile, profile.ht).achieved) result.injury += rpgLiteWound(profile, 1).injury;
    return nil;
}

/* Coma: 1d hours, then HT; each failure adds 1d hours. Waking leaves -2 for 6 hours. */
rpgFrightComa(profile, result)
{
    local episode = rpgFrightBegin(profile, result, 'coma', rpgRandom.die() * 3600, 'ht', 1, nil);
    episode.extendSeconds = 3600; episode.penaltySeconds = 21600;
    return episode;
}

/* Lose 1d FP. */
rpgFrightFatigue(profile, result)
{
    local damage = rpgLiteFatigue(profile, rpgRandom.die(), 'fright');
    result.fatigue += damage.fatigue; result.injury += damage.injury;
    return nil;
}

/* Apply the results row for a total of 3d plus the failure margin. */
rpgFrightApplyRow(profile, result, total, modifiedWill)
{
    result.status = 'failed'; result.total = total;
    local row = total > 40 ? 40 : total; result.row = row;
    if (row <= 5) rpgFrightBegin(profile, result, 'stun', 1, 'automatic', 1, nil);
    else if (row <= 7) rpgFrightBegin(profile, result, 'stun', 1, 'will', 1, nil);
    else if (row <= 9) rpgFrightBegin(profile, result, 'stun', 1, 'modified-will', 1, modifiedWill);
    else if (row == 10) rpgFrightBegin(profile, result, 'stun', rpgRandom.die(), 'modified-will', 1, modifiedWill);
    else if (row == 11)
        rpgFrightBegin(profile, result, 'stun', rpgRandom.die() + rpgRandom.die(), 'modified-will', 1, modifiedWill);
    else if (row == 12)
    {
        local fixed = 25 - profile.ht;
        rpgFrightBegin(profile, result, 'retch', fixed > 0 ? fixed : 0, 'ht', 1, nil);
    }
    else if (row == 13) rpgFrightPending(profile, result, 'quirk', -1, row);
    else if (row <= 15)
    {
        rpgFrightFatigue(profile, result);
        rpgFrightBegin(profile, result, 'stun', rpgRandom.die(), 'modified-will', 1, modifiedWill);
    }
    else if (row == 16)
    {
        rpgFrightBegin(profile, result, 'stun', rpgRandom.die(), 'modified-will', 1, modifiedWill);
        rpgFrightPending(profile, result, 'quirk', -1, row);
    }
    else if (row == 17) rpgFrightBegin(profile, result, 'faint', rpgRandom.die() * 60, 'ht', 60, nil);
    else if (row == 18) rpgFrightFaint(profile, result, row);
    else if (row == 19)
    {
        rpgFrightBegin(profile, result, 'faint', (rpgRandom.die() + rpgRandom.die()) * 60, 'ht', 60, nil);
        result.injury += rpgLiteWound(profile, 1).injury;
    }
    else if (row == 20)
    {
        local dice = rpgRandom.die() + rpgRandom.die() + rpgRandom.die() + rpgRandom.die();
        rpgFrightBegin(profile, result, 'faint', dice * 60, 'automatic', 1, nil);
        rpgFrightFatigue(profile, result);
    }
    else if (row == 21) rpgFrightBegin(profile, result, 'panic', rpgRandom.die() * 60, 'will', 60, nil);
    else if (row == 22) rpgFrightPending(profile, result, 'delusion', -10, row);
    else if (row == 23) rpgFrightPending(profile, result, 'mental', -10, row);
    else if (row == 24) rpgFrightPending(profile, result, 'physical', -15, row);
    else if (row == 25) rpgFrightPending(profile, result, 'worsen-or-mental', -10, row);
    else if (row == 26) { rpgFrightFaint(profile, result, row); rpgFrightPending(profile, result, 'delusion', -10, row); }
    else if (row == 27) { rpgFrightFaint(profile, result, row); rpgFrightPending(profile, result, 'mental', -10, row); }
    else if (row == 28)
    {
        local episode = rpgFrightBegin(profile, result, 'light-coma', 0, 'ht', 1800, nil);
        episode.penaltySeconds = 21600;
    }
    else if (row == 29) rpgFrightComa(profile, result);
    else if (row == 30)
    {
        local episode = rpgFrightBegin(profile, result, 'catatonia', rpgRandom.die() * 86400, 'ht', 1, nil);
        episode.extendSeconds = 86400;
    }
    else if (row == 31)
    {
        rpgFrightBegin(profile, result, 'seizure', rpgRandom.die() * 60, 'automatic', 1, nil);
        rpgFrightFatigue(profile, result);
        local check = rpgFrightRoll(profile, profile.ht);
        if (!check.achieved) result.injury += rpgLiteWound(profile, rpgRandom.die()).injury;
        if (check.critical == 'failure' && profile.ht > 1) profile.ht -= 1;
    }
    else if (row == 32)
    {
        profile.posture = 'lying';
        result.injury += rpgLiteWound(profile, rpgRandom.die() + rpgRandom.die()).injury;
    }
    else if (row == 33)
    {
        rpgFrightBegin(profile, result, 'total-panic', 0, 'will', 1, nil);
        result.panicRoll = rpgRandom.roll();
    }
    else if (row == 34) rpgFrightPending(profile, result, 'delusion', -15, row);
    else if (row == 35) rpgFrightPending(profile, result, 'mental', -15, row);
    else if (row == 36) rpgFrightPending(profile, result, 'physical', -20, row);
    else if (row == 37) rpgFrightPending(profile, result, 'physical', -30, row);
    else if (row == 38) { rpgFrightComa(profile, result); rpgFrightPending(profile, result, 'delusion', -15, row); }
    else
    {
        rpgFrightComa(profile, result); rpgFrightPending(profile, result, 'mental', -15, row);
        if (row == 40 && profile.iq > 1) profile.iq -= 1;
    }
    return result;
}

/** Resolve a pending acquisition with new traits whose costs total its points.
 * For 'worsen-or-mental', pass one owned disadvantage with self-control 9-15 to
 * worsen it one step instead. Traits gained this way may exceed the quirk limit. */
rpgFrightAcquire(profile, acquisition, traits)
{
    if (!holds(profile.frightPending, acquisition)) rpgExpandedReject('fright-acquisition-not-pending');
    if (acquisition.kind == 'worsen-or-mental' && traits.length() == 1 && holds(profile.traits, traits[1]))
    {
        local trait = traits[1];
        if (!trait.ofKind(RpgExpandedDisadvantage) || !holds([9, 12, 15], trait.selfControlRating))
            rpgExpandedReject('fright-cannot-worsen');
        trait.selfControlRating = trait.selfControlRating == 15 ? 12 : trait.selfControlRating == 12 ? 9 : 6;
    }
    else
    {
        local total = 0;
        foreach (local trait in traits)
        {
            if (!trait.ofKind(RpgLiteTrait) || holds(profile.traits, trait)) rpgExpandedReject('fright-acquisition-trait');
            total += trait.creationCost();
        }
        if (total != acquisition.points) rpgExpandedReject('fright-acquisition-points');
        foreach (local trait in traits) trait.acquiredInPlay = true;
        profile.traits = profile.traits + traits;
    }
    local remaining = [];
    foreach (local item in profile.frightPending) if (item != acquisition) remaining = remaining + [item];
    profile.frightPending = remaining;
    return true;
}
