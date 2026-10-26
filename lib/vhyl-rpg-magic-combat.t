/* Optional bridges to the host's ordinary attack/defense and skill procedures. */

/** An augmentation validates the injury declaration but delivers it through the
 * later mundane attack, combining damage before armor rather than striking twice. */
class RpgMagicAugmentation: RpgMagicOperation
    defend(intent,result) { return nil; }
    apply(intent,result) { return nil; }
    available(intent)
    { if (self.operation != 'injure') return 'magic-augmentation-operation'; return inherited(intent); }
;

/** Use with RpgLiteBattle.step so its apply hook consumes assistance on misses too. */
class RpgMagicManeuver: RpgLiteManeuver
    magicResult = nil
    magicRole = 'damage'
    magicSign = 1
    magicConsumed = nil
    requiresMagic = nil
    magicalDamage = nil
    pendingInjuries = []
    available(fighter)
    {
        if (self.magicConsumed || self.requiresMagic && (self.magicResult == nil || !self.magicResult.delivered))
            return 'magic-attack-unavailable';
        if (!holds([-1,1],self.magicSign)) return 'magic-assistance-sign';
        if (self.magicRole == 'augment' && self.magicResult != nil && fighter.weapon != nil
            && self.magicResult.effect.kind != fighter.mode().damageType) return 'magic-augmentation-damage-type';
        return inherited(fighter);
    }
    damageModifier(attacker,defender,result)
    {
        if (self.magicResult == nil || !self.magicResult.delivered || self.magicConsumed) return inherited(attacker,defender,result);
        if (self.magicRole == 'damage') return self.magicResult.scope * self.magicSign;
        if (self.magicRole == 'augment')
        {
            if (self.magicalDamage == nil)
            {
                local e = self.magicResult.effect;
                self.magicalDamage = rpgMagicRollDamage(rpgMagicDamageDice(e.domain,e.rank,e.amount,e.domain == rpgMagicLife),e.kind,e.domain == rpgMagicLife);
            }
            return self.magicalDamage;
        }
        return 0;
    }
    applyInjury(defender,amount)
    { self.pendingInjuries = self.pendingInjuries + [[defender,amount]]; return nil; }
    apply(fighter,result)
    {
        local critical = nil;
        if (result != nil)
        {
            if (result.attack != nil && result.attack.critical == 'failure') critical = true;
            foreach (local strike in result.strikes)
                if (strike.attack != nil && strike.attack.critical == 'failure') critical = true;
        }
        if (!critical)
            foreach (local injury in self.pendingInjuries)
            { rpgLiteWound(injury[1].profile,injury[2]); if (injury[2] > 0) rpgLiteDistract(injury[1]); }
        else
        {
            result.outcome = 'miss'; result.damage = 0; result.injury = 0;
            foreach (local strike in result.strikes) { strike.outcome = 'miss'; strike.damage = 0; strike.injury = 0; }
        }
        self.pendingInjuries = []; self.magicConsumed = true; return inherited(fighter,result);
    }
;

/** Arm only the already-declared maneuver; a miss still spends the magic. */
rpgArmMagicManeuver(maneuver,intent,role)
{
    if (maneuver.magicResult != nil || !holds(['damage','augment'],role)) rpgExpandedReject('magic-attack-declaration');
    local r = rpgAssessMagic(intent);
    if (r.status != 'ready') return r;
    if (!r.effect.ofKind(RpgMagicAugmentation)) rpgExpandedReject('magic-augmentation-handler');
    maneuver.magicResult = rpgCastMagic(intent); maneuver.magicRole = role; return maneuver.magicResult;
}

/** A subtle assistance result is bound to one authored task identifier. */
class RpgMagicAssistance: object
    task = nil
    result = nil
    consumed = nil
;
/** Consume assistance only for its declared next task, returning the bounded bonus. */
rpgUseMagicAssistance(assistance,task)
{
    if (assistance.consumed || assistance.task != task || assistance.result == nil) return 0;
    assistance.consumed = true; local r = assistance.result;
    if (!r.delivered || r.ruling[2][2] != 'subtle') return 0;
    return r.scope / 2 < 1 ? 1 : r.scope / 2;
}

/** Immediate defense uses unmodified suitable domain skill and recorded subtle
 * adjudication, without charging reserve or taking an ordinary casting action. */
rpgImmediateMagicDefense(intent)
{
    local r = new RpgMagicResult(); rpgMagicValidateIntent(intent);
    local o = intent.opportunity;
    if (o.receipt != nil && o.receiptRevision == o.goal.revision) return rpgMagicRecall(o.receipt);
    local ruling = rpgGmRead(intent);
    if (ruling.status != 'ruled' || ruling.data[2] != 'subtle') { r.status = 'needs-ruling'; return r; }
    local e = rpgMagicEffectFor(intent,ruling.data[1]); local score = 1000;
    if (intent.purpose != 'defense' || !e.defensive || e.requirements.length() == 0)
    { r.reason = 'magic-defense-declaration'; return r; }
    r.reason = e.available(intent); if (r.reason != nil) return r;
    foreach (local p in e.requirements)
    { local value = rpgMagicSkill(intent.state,p[1],p[2]); if (value == nil) { r.reason = 'magic-permission'; return r; } if (value < score) score = value; }
    if (intent.conspicuous)
    { local n = intent.scene.coincidences <= 2 ? 0 : (intent.scene.coincidences - 1) / 2; score -= n > 3 ? 3 : n; }
    if (score < 3) { r.reason = 'too-difficult'; return r; }
    r.score = score; r.effect = e; r.ruling = [ruling.packet,ruling.data];
    r.dice = rpgRandom.dice(); r.check = rpgCheck(score,rpgDiceTotal(r.dice));
    r.delivered = r.check.rollSucceeded; r.scope = r.check.margin; r.outcome = r.delivered ? 'full' : 'failure'; r.status = 'resolved';
    if (r.delivered && intent.conspicuous) intent.scene.coincidences += 1;
    local rank = 0; foreach (local p in e.requirements) if (p[2] > rank) rank = p[2];
    r.strainGained = rpgMagicStrainGain(r.check,rank,'subtle',nil); rpgMagicAddStrain(intent.state,r.strainGained);
    if (!e.personalPerception) intent.state.recoveryClock = 0;
    o.receiptRevision = o.goal.revision; o.receipt = r.pack(); return r;
}
