/* Optional bridge. Include after injuries and the magic umbrella. */

/** A normal delivered Life heal that additionally repairs one authored injury.
 * Use rpgPrepareMagicOperation and the ordinary casting pipeline. Restoration
 * of missing/permanently disabled parts needs a separately authored effect. */
class RpgInjuryLifeEffect: RpgMagicOperation
    operation = 'heal'
    injuryRecord = nil
    declaration() { return inherited() + [self.injuryRecord]; }
    facts(intent)
    {
        local i = self.injuryRecord;
        return inherited(intent) + [i == nil ? nil : [i.owner == self.target.profile,i.amount,i.active,i.severity,i.lifeTreated,i.remainingSeconds]];
    }
    available(intent)
    {
        local reason = inherited(intent); if (reason != nil) return reason;
        local i = self.injuryRecord;
        if (self.operation != 'heal' || i == nil || i.owner != self.target.profile
            || i.owner.dead || !holds(i.owner.injuries,i) || !i.active || i.lifeTreated
            || i.severity == 'permanent') return 'injury-life-unavailable';
        if (self.partialMargin != nil || self.amount * 2 < i.amount) return 'injury-life-scope';
        return nil;
    }
    apply(intent,result)
    {
        local r = rpgHealMagic(self.target,self.amount,result.ruling[2][2] == 'overt',intent.state);
        if (r.status == 'resolved' && (self.injuryRecord.severity != 'mortal' || !self.target.profile.mortal))
        { self.injuryRecord.active = nil; self.injuryRecord.lifeTreated = true;
          self.injuryRecord.remainingSeconds = 0; }
        return r;
    }
;
