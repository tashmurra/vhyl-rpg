/* Optional authored injuries. Include after Lite. No hit locations are selected. */

/** Persistent loss of function, independent of the HP deficit. One record per event. */
class RpgInjury: object
    owner = nil
    part = nil
    side = nil
    severity = 'temporary'
    active = true
    amount = 0
    remainingSeconds = 0
    physician = nil
    surgery = nil
    assessed = nil
    lifeTreated = nil
;

/** Treatment receipt; blocked attempts spend no time and draw no randomness. */
class RpgInjuryResult: RpgLiteHealthResult
    reason = nil
    record = nil
;

/** Apply authored HP injury once and attach an explicitly classified consequence.
 * Severity is temporary, lasting, permanent, or mortal (internal only).
 * Lasting duration is authored in months; one month is explicitly 30 days. */
rpgInflictInjury(profile, part, side, amount, severity, months)
{
    rpgInteger(amount, 1, 100000); rpgInteger(months, 0, 6);
    if (!holds(['arm','hand','leg','foot','internal'], part)
        || (part == 'internal' ? side != nil : !holds(['left','right'], side))
        || !holds(['temporary','lasting','permanent','mortal'], severity)
        || severity == 'mortal' && part != 'internal'
        || (severity == 'lasting' ? months < 1 : months != 0)) throw new RpgError();
    local r = new RpgInjuryResult();
    if (profile.dead) { r.status = 'blocked'; r.reason = 'dead'; return r; }
    local w = rpgLiteWound(profile, amount);
    local i = new RpgInjury(); i.owner = profile; i.part = part; i.side = side;
    i.amount = amount; i.severity = severity; i.remainingSeconds = months * 2592000;
    profile.injuries = profile.injuries + [i];
    if (part == 'leg' || part == 'foot') profile.posture = 'lying';
    if (severity == 'mortal' && !profile.dead)
    { if (!profile.mortal) profile.mortalClock = 0;
      profile.mortal = true; profile.unconscious = true; }
    r.record = i; r.injury = w.injury; r.checks = w.checks; return r;
}

/** Assess an authored crippling injury once, normally at combat end.
 * This does not apply HP loss again or affect explicitly classified injuries. */
rpgAssessInjury(record)
{
    local r = new RpgInjuryResult(); r.record = record;
    if (!record.active || record.severity != 'temporary' || record.assessed)
    { r.status = 'blocked'; r.reason = 'injury-assessed'; return r; }
    r.check = rpgLiteAttributeCheck(record.owner, rpgHT, 'injury-duration', 0);
    record.assessed = true;
    if (r.check.critical == 'failure') record.severity = 'permanent';
    else if (!r.check.achieved)
    { record.severity = 'lasting'; record.remainingSeconds = rpgRandom.die() * 2592000; }
    return r;
}

/** One physician intervention or surgical attempt per record.
 * Surgery requires a capable conscious healer and supplied skill score/modifier;
 * equipment, access, supplies and medical TL eligibility are host obligations. */
rpgTreatInjury(record, healer, skill, modifier, techLevel, surgical)
{
    rpgInteger(techLevel, 0, 12); rpgInteger(skill, 1, 100); rpgInteger(modifier, -100, 100);
    local r = new RpgInjuryResult(); r.record = record;
    local stabilizing = record.severity == 'mortal' && record.owner.mortal && surgical;
    if (!record.active || record.severity != 'lasting' && !stabilizing || record.owner.dead
        || !surgical && skill < 12
        || healer.dead || healer.unconscious || healer.stunned || healer.mortal
        || (surgical ? record.surgery : record.physician || record.surgery))
    { r.status = 'blocked'; r.reason = 'injury-treatment-unavailable'; return r; }
    if (!surgical)
    {
        record.physician = true;
        local reduction = techLevel >= 7 ? 3 : techLevel == 6 ? 2 : techLevel == 5 ? 1 : 0;
        local old = record.remainingSeconds;
        record.remainingSeconds -= reduction * 2592000;
        local floor = old < 2592000 ? old : 2592000;
        if (record.remainingSeconds < floor) record.remainingSeconds = floor;
        return r;
    }
    record.surgery = true; r.seconds = stabilizing ? 3600 : 7200; rpgSpendTime(r.seconds);
    rpgLiteHealthTime(record.owner,r.seconds);
    if (healer != record.owner) rpgLiteHealthTime(healer,r.seconds);
    if (record.owner.dead || healer.dead || healer.unconscious || healer.stunned || healer.mortal)
    { r.reason = 'injury-treatment-interrupted'; return r; }
    if (!record.active) { r.reason = 'injury-recovered'; return r; }
    r.check = rpgCheck(skill + modifier, rpgRandom.roll());
    if (stabilizing)
    {
        if (r.check.achieved)
        { record.owner.mortal = nil; record.severity = 'lasting'; record.remainingSeconds = 2592000; }
        return r;
    }
    if (r.check.critical == 'failure') { record.severity = 'permanent'; record.remainingSeconds = 0; }
    else if (r.check.achieved) record.remainingSeconds = (record.remainingSeconds + 29) / 30 * 7;
    return r;
}

modify RpgLiteProfile
    injuries = []
    injuryHandUsable(side)
    {
        foreach (local i in self.injuries)
            if (i.active && i.side == side && holds(['arm','hand'], i.part)) return nil;
        return inherited(side);
    }
    injuryHands() { return (self.injuryHandUsable('left') ? 1 : 0) + (self.injuryHandUsable('right') ? 1 : 0); }
    injuryLegsUsable()
    {
        foreach (local i in self.injuries) if (i.active && holds(['leg','foot'], i.part)) return nil;
        return inherited();
    }
    injuryExertionAllowed()
    {
        foreach (local i in self.injuries) if (i.active && i.part == 'internal') return nil;
        return inherited();
    }
    injuryPostureAllowed(posture)
    { return self.injuryLegsUsable() || holds(['lying','sitting','crawling'], posture); }
    injuryMove(amount)
    { return !self.injuryLegsUsable() ? (self.posture == 'crawling' || self.posture == 'lying' ? (amount > 0 ? 1 : 0) : 0) : inherited(amount); }
    injuryTime(seconds)
    {
        rpgInteger(seconds, 0, 2147483647);
        inherited(seconds);
        foreach (local i in self.injuries)
            if (i.active)
            {
                if (i.severity == 'lasting')
                { i.remainingSeconds -= seconds;
                  if (i.remainingSeconds <= 0) { i.remainingSeconds = 0; i.active = nil; } }
                else if (i.severity == 'temporary' && self.injury == 0
                    || i.severity == 'mortal' && !self.mortal) i.active = nil;
            }
    }
;
