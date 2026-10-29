/* Include after the Lite umbrella, expanded foundation and expanded skills.
 * Source: full-2008, B218, B354, B426-B427. Ordinary ground running only.
 * Exhaustion and recovery retain the host's Lite health approximations. */

/** Shared immutable Running definition. Training belongs to each profile. */
rpgExpandedRunningSkill: RpgExpandedSkill
    id = 'running'
    attribute = rpgHT
    difficulty = 1
    defaultPenalty = -5
;

/** Receipt for one advance: completed time, actual resource losses, and ordered
 * effort, consciousness, running and overflow-injury checks. Passive condition
 * hooks retain their own receipts. A stop reason can accompany completed time. */
class RpgExpandedRunningResult: RpgLiteHealthResult
    reason = nil
;

/** One persistent running activity per character. Use setPace for pace changes
 * and interrupt when stopping or changing direction, including before resting.
 * Partial fatigue intervals survive both operations. Include alone opts in no one. */
class RpgExpandedRunning: object
    profile = nil
    skill = rpgExpandedRunningSkill
    pace = 'sprint'
    sprintEligible = true
    sprintClock = 0
    pacedClock = 0
    /* Saturates at one: whether a full eligible sprint second preceded this one. */
    sprintSeconds = 0
    elapsed = 0

    /* Observational hook, called separately for HT (nil) and Running. */
    fatigueContext(which)
    {
        local context = new RpgLiteContext();
        context.attribute = rpgHT; context.skill = which; context.kind = 'running-fatigue';
        return context;
    }
    /* Validate and evaluate both candidates without drawing dice. HT wins ties. */
    fatigueContextForCheck()
    {
        local health = self.fatigueContext(nil); local running = self.fatigueContext(self.skill);
        local healthScore = rpgLiteScore(self.profile, health);
        local runningScore = rpgLiteScore(self.profile, running);
        if (healthScore == nil) rpgExpandedReject('running-ht-unavailable');
        rpgInteger(healthScore, -1000, 1000);
        if (runningScore != nil) rpgInteger(runningScore, -1000, 1000);
        return runningScore != nil && runningScore > healthScore ? running : health;
    }
    validate()
    {
        rpgExpandedValidate(self.profile);
        rpgExpandedValidateSkill(self.skill);
        if (!self.skill.ofKind(RpgExpandedSkill) || self.skill.id != 'running'
            || self.skill.attribute != rpgHT || self.skill.difficulty != 1 || self.skill.wildcard)
            rpgExpandedReject('running-skill');
        if (self.pace != 'sprint' && self.pace != 'paced') rpgExpandedReject('running-pace');
        if (self.sprintEligible != true && self.sprintEligible != nil) rpgExpandedReject('running-eligibility');
        rpgInteger(self.sprintClock, 0, 14); rpgInteger(self.pacedClock, 0, 59);
        rpgInteger(self.sprintSeconds, 0, 1); rpgInteger(self.elapsed, 0, 2147483647);
        rpgInteger(self.profile.maxEnergy, 1, 1000);
        self.fatigueContextForCheck();
        return nil;
    }
    /** Change pace without erasing fatigue progress; a same-pace call is a no-op. */
    setPace(pace)
    {
        self.validate();
        if (pace != 'sprint' && pace != 'paced') rpgExpandedReject('running-pace');
        if (pace != self.pace) { self.pace = pace; self.sprintSeconds = 0; }
        return nil;
    }
    /** Stop or turn without spending time or resetting fatigue intervals. */
    interrupt()
    {
        self.validate(); self.sprintSeconds = 0; return nil;
    }
    /* Good ground and straight, standing movement permit the sprint bonus. */
    eligible() { return self.sprintEligible && self.profile.posture == 'standing'; }
    /** Speed for the next second, in hundredths of a yard/second. Pure preview. */
    speedHundredths()
    {
        self.validate();
        if (self.profile.dead || self.profile.unconscious || self.profile.mortal) return 0;
        local base = self.profile.move() * 100;
        if (base == 0) return 0;
        local sprint = base * 120 / 100;
        if (sprint < base + 100) sprint = base + 100;
        if (self.pace == 'paced') return sprint / 2;
        return self.eligible() && self.sprintSeconds > 0 ? sprint : base;
    }
    /* An incapacitated or immobile character cannot start another running second. */
    stopReason()
    {
        if (self.profile.dead || self.profile.unconscious || self.profile.mortal) return 'incapacitated';
        if (self.profile.move() <= 0) return 'cannot-move';
        return nil;
    }
    /** Advance one-second activity steps, then charge their total exactly once.
     * Stops before the next second when effort fails; zero seconds changes nothing. */
    advance(seconds)
    {
        rpgInteger(seconds, 0, 86400); self.validate();
        rpgInteger(self.elapsed, 0, 2147483647 - seconds);
        rpgInteger(rpgLedger.seconds, 0, 2147483647 - seconds);
        local result = new RpgExpandedRunningResult();
        if (seconds == 0) return result;
        for (local i = 0; i < seconds; i += 1)
        {
            result.reason = self.stopReason();
            if (result.reason != nil) break;
            if (!rpgLiteCanActRecorded(self.profile, nil, result))
            { result.reason = 'cannot-act'; break; }
            self.profile.restClock = 0;
            self.elapsed += 1; result.seconds += 1;
            self.sprintSeconds = self.pace == 'sprint' && self.eligible() ? 1 : 0;
            local due = nil;
            if (self.pace == 'sprint')
            {
                self.sprintClock += 1;
                if (self.sprintClock == 15) { self.sprintClock = 0; due = true; }
            }
            else
            {
                self.pacedClock += 1;
                if (self.pacedClock == 60) { self.pacedClock = 0; due = true; }
            }
            if (due)
            {
                result.check = rpgLiteCheck(self.profile, self.fatigueContextForCheck());
                result.checks = result.checks + [result.check];
                if (!result.check.achieved)
                {
                    local damage = rpgLiteFatigue(self.profile, 1, 'exertion');
                    result.fatigue += damage.fatigue; result.injury += damage.injury;
                    result.checks = result.checks + damage.checks;
                }
            }
            rpgLiteHealthTime(self.profile, 1);
            result.reason = self.stopReason();
            if (result.reason != nil) break;
        }
        if (result.reason != nil)
        {
            self.sprintSeconds = 0;
            result.status = result.seconds == 0 ? 'blocked' : 'stopped';
        }
        rpgSpendTime(result.seconds);
        return result;
    }
;
