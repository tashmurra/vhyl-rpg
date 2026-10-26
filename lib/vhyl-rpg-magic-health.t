/* Host injury integration with provenance and shared treatment opportunities. */

/** One injury batch; healing restrictions remain attached to the injury. */
class RpgMagicWound: object
    remaining = 0
    cause = 'ordinary'
    blocker = nil
    treated = nil
;

/** Reconcile pre-existing injury when a profile first enters the magic adapter. */
rpgMagicSyncWounds(subject)
{
    local total = 0; foreach (local w in subject.wounds) total += w.remaining;
    if (subject.profile.injury > total)
    { local w = new RpgMagicWound(); w.remaining = subject.profile.injury - total;
        subject.wounds = subject.wounds + [w]; }
    return nil;
}

/** Route damage through the existing major-wound/death pipeline. */
rpgMagicWound(subject, injury, cause, blocker)
{
    if (subject.profile == nil) rpgExpandedReject('magic-health-profile');
    if (subject.profile.magicSubject == nil) subject.profile.magicSubject = subject;
    if (subject.profile.magicSubject != subject) rpgExpandedReject('magic-health-owner');
    rpgMagicSyncWounds(subject); subject.injuryCause = cause; subject.injuryBlock = blocker;
    local r = rpgLiteWound(subject.profile, injury);
    subject.injuryCause = 'ordinary'; subject.injuryBlock = nil; subject.revision += 1;
    return r;
}

/** Natural healing cannot repair an actively leaking transformation. */
rpgMagicHealingLimit(subject, requested)
{
    rpgMagicSyncWounds(subject); local available = 0;
    foreach (local w in subject.wounds)
        if (!(w.blocker != nil && w.blocker.active)
            && (!subject.magicalHealing || !w.treated && !holds(['backlash','unstable'],w.cause)))
            available += w.remaining;
    return requested < available ? requested : available;
}

/** Shared opportunity: changing caster never reopens a treated injury batch. */
rpgHealMagic(subject, margin, overt, payer)
{
    local r = new RpgExpandedResult(); rpgMagicSyncWounds(subject);
    local severe = 0;
    foreach (local w in subject.wounds) if (!w.treated && w.cause == 'severe') severe += w.remaining;
    local wanted = (margin < 1 ? 1 : margin) * 2;
    if (severe > 0 && !overt) { r.reason = 'magic-healing-overt'; return r; }
    subject.magicalHealing = true;
    local amount = rpgMagicHealingLimit(subject, wanted);
    local remaining = amount; local costly = 0;
    foreach (local w in subject.wounds)
        if (remaining > 0 && !w.treated && !holds(['backlash','unstable'],w.cause) && !(w.blocker != nil && w.blocker.active))
        { local n = w.remaining < remaining ? w.remaining : remaining;
          if (w.cause == 'severe') costly += n; remaining -= n; }
    local cost = (costly + 2) / 3;
    if (payer.reserve < cost) { subject.magicalHealing = nil; r.reason = 'magic-reserve'; return r; }
    payer.reserve -= cost; payer.revision += 1;
    r.points = rpgLiteHeal(subject.profile, amount);
    foreach (local w in subject.wounds)
        if (!holds(['backlash','unstable'],w.cause)) w.treated = true;
    subject.magicalHealing = nil; subject.revision += 1; r.status = 'resolved'; return r;
}

modify RpgExpandedProfile
    magicSubject = nil
    maxHP = (st + hpAdjustment + rpgMagicOverlayValue(magicSubject,'st'))
    maxEnergy = (ht + fpAdjustment + rpgMagicOverlayValue(magicSubject,'ht'))
    basicSpeedQuarters() { return self.attributeScore(rpgDX) + self.attributeScore(rpgHT) + self.speedQuarterAdjustment; }
    basicLiftHundredths()
    { local strength = self.attributeScore(rpgST); local amount = strength * strength * 20;
      return amount >= 1000 ? (amount + 50) / 100 * 100 : amount; }
    attributeScore(attribute)
    {
        local base = inherited(attribute);
        local key = attribute == rpgST ? 'st' : attribute == rpgDX ? 'dx'
            : attribute == rpgIQ ? 'iq' : attribute == rpgHT ? 'ht'
            : attribute == rpgWill ? 'will' : 'perception';
        return base + rpgMagicOverlayValue(self.magicSubject, key);
    }
    magicArmorBonus() { return rpgMagicOverlayValue(self.magicSubject, 'armor'); }
    healingLimit(amount)
    { return self.magicSubject == nil ? inherited(amount) : rpgMagicHealingLimit(self.magicSubject, amount); }
    injuryApplied(amount)
    {
        if (self.magicSubject == nil || amount == 0) return nil;
        local s = self.magicSubject; local w = new RpgMagicWound();
        w.remaining = amount; w.cause = s.injuryCause; w.blocker = s.injuryBlock;
        s.wounds = s.wounds + [w]; return nil;
    }
    healingApplied(amount)
    {
        if (self.magicSubject == nil) return nil;
        local s = self.magicSubject;
        foreach (local w in s.wounds)
            if (amount > 0 && !(w.blocker != nil && w.blocker.active)
                && (!s.magicalHealing || !w.treated && !holds(['backlash','unstable'], w.cause)))
            { local n = w.remaining < amount ? w.remaining : amount; w.remaining -= n; amount -= n; }
        return nil;
    }
;
