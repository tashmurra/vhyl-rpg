/* Data definitions and the adjudication adapter. */

/** Authored witness eligibility, independent of friendship or named groups. */
class RpgMagicWitness: object
    id = nil
    present = nil
    perceives = nil
    accommodates = nil
;

/** Game-owned scene facts. advanceScene requires a material change. */
class RpgMagicScene: object
    id = nil
    revision = 0
    coincidences = 0
    localModifier = 0
    witnesses = []
    worldTurn() { return turnCount.value; }
    advanceScene() { self.revision += 1; self.coincidences = 0; return nil; }
    facts()
    {
        local facts = [self.id, self.revision, self.coincidences, self.localModifier];
        foreach (local w in self.witnesses)
            facts = facts + [[w.id, w.present, w.perceives, w.accommodates]];
        return facts;
    }
    witnessed()
    {
        foreach (local w in self.witnesses)
            if (w.present && w.perceives && !w.accommodates) return true;
        return nil;
    }
;

/** Optional ordinary-skill practice; available checks actual tools/activity. */
class RpgMagicPractice: object
    id = nil
    skill = nil
    minimum = nil
    seconds = 1
    available(intent) { return nil; }
;

/** Registered effect implementation. Providers cannot lower these requirements.
 * Delivery, lifecycle and permission handlers are library-owned or authored.
 * Handlers must expose relevant facts and implement actual eligibility/application. */
class RpgMagicEffect: object
    id = nil
    requirements = []
    minimumMargin = 0
    partialMargin = nil
    seconds = 1
    fuel = 0
    delivery = 'noncombat'
    duration = 0
    implemented = nil
    lifecycleImplemented = nil
    defensive = nil
    fixedModifier = 0
    requiredMargin(check) { return self.minimumMargin; }
    afterRoll(intent,result) { return nil; }
    appearances = ['subtle', 'overt']
    minimumModifier = 0
    maximumModifier = 0
    facts(intent) { return []; }
    available(intent) { return 'unsupported-effect'; }
    apply(intent, result) { throw new RpgError(); }
;

/** Goal retry sequence, reopened only by an authored material change. */
class RpgMagicGoal: object
    id = nil
    owner = nil
    revision = 0
    attempts = 0
    ended = nil
    completed = nil
    reopen()
    {
        self.revision += 1; self.attempts = 0; self.ended = nil; self.completed = nil;
        return nil;
    }
;

/** Owned opportunity shared by all input paths; rewording grants no new slot. */
class RpgMagicOpportunity: object
    id = nil
    owner = nil
    goal = nil
    ordinal = 1
    receipt = nil
    receiptRevision = -1
;

/** GM ruling data: [effect ID, appearance, modifier, rationale]. Mechanical
 * parameters and targets remain authoritative game data, not provider claims. */
class RpgMagicIntent: RpgGmQuestion
    policy = 'magic-1'
    purpose = 'casting'
    state = nil
    scene = nil
    opportunity = nil
    effects = []
    practice = nil
    formula = nil
    reserveSpend = 0
    extraTime = nil
    familiarity = 0
    conspicuous = nil
    targetIds = []
    method = ''
    contextData()
    {
        local s = self.state;
        local facts = [self.purpose,self.method, self.targetIds, self.scene.facts(), self.scene.modifierFor(self), s.revision,
            s.mastery, s.channel, s.reserve, s.strain, s.lasting,
            self.opportunity.id, self.opportunity.goal.revision,
            self.opportunity.ordinal, self.reserveSpend, self.extraTime,
            self.familiarity, self.conspicuous, s.concentration, self.distractions, self.multitasking, self.haste, self.instantaneous,
            self.practice == nil ? nil : [self.practice.id, self.practice.seconds,
                self.practice.available(self)],
            self.formula == nil ? nil : [self.formula.effect.id, self.formula.improvement],
            s.tool == nil ? nil : [s.tool.domain.id, s.tool.bound, s.tool.designated,
                s.tool.available(self)],
            self.opportunity.preparationRevision, self.opportunity.preparationModifier];
        foreach (local k in s.knowledge)
            facts = facts + [[k.domain.id, k.rank, k.access, k.exempt,
                rpgMagicSkill(s, k.domain, k.rank)]];
        foreach (local e in self.effects) facts = facts + [[e.id, e.facts(self)]];
        foreach (local c in self.counters)
        { local participants = c.participants.length() == 0 ? [c.state] : c.participants;
          foreach (local participant in participants) facts = facts + [[participant.revision,participant.mastery,c.ready]]; }
        return facts;
    }
    choicesData()
    {
        local data = [];
        foreach (local e in self.effects)
        {
            local required = [];
            foreach (local pair in e.requirements) required = required + [[pair[1].id, pair[2]]];
            data = data + [[e.id, required, e.minimumMargin, e.partialMargin, e.seconds,
                e.fuel, e.delivery, e.duration, e.implemented, e.appearances,
                e.minimumModifier, e.maximumModifier, e.defensive]];
        }
        return data;
    }
    rulingReason(data)
    {
        if (dataType(data) != TypeList || data.length() != 4
            || dataType(data[1]) != TypeSString || dataType(data[2]) != TypeSString
            || dataType(data[3]) != TypeInt || dataType(data[4]) != TypeSString
            || data[4].length() > 1024) return 'invalid-ruling';
        local effect = rpgMagicEffectFor(self, data[1]);
        if (effect == nil || !effect.implemented || effect.duration != 0 && !effect.lifecycleImplemented || !holds(['noncombat','direct','indirect'],effect.delivery)) return 'unsupported-effect';
        if (!holds(effect.appearances, data[2]) || !holds(['subtle','overt'], data[2])
            || data[3] < effect.minimumModifier || data[3] > effect.maximumModifier)
            return 'ruling-outside-bounds';
        return nil;
    }
;

/* Provider strings select registered IDs, never properties or executable code. */
rpgMagicEffectFor(intent, id)
{
    local found = nil;
    foreach (local e in intent.effects)
    {
        if (e == nil || !e.ofKind(RpgMagicEffect)) throw new RpgError();
        if (e.id == id)
        {
            if (found != nil) throw new RpgError();
            found = e;
        }
    }
    return found;
}

/** Private result. Roll success and delivered scope are distinct. */
class RpgMagicResult: object
    status = 'blocked'
    notified = nil
    reason = nil
    effect = nil
    score = nil
    check = nil
    outcome = nil
    delivered = nil
    spent = 0
    seconds = 0
    strainGained = 0
    backlashStrength = 0
    ruling = nil
    dice = []
    pack()
    {
        return [self.effect, self.score, self.check == nil ? nil : self.check.roll,
            self.outcome, self.delivered, self.spent, self.seconds, self.strainGained,
            self.backlashStrength, self.ruling, self.dice, self.scope, self.defenses,
            self.check == nil ? nil : self.check.margin, self.check == nil ? nil : self.check.critical,
            self.check == nil ? nil : self.check.rollSucceeded, self.resistanceRolls];
    }
;

rpgMagicRecall(data)
{
    local r = new RpgMagicResult(); r.status = 'reused';
    r.effect = data[1]; r.score = data[2];
    if (data[3] != nil) r.check = rpgCheck(r.score, data[3]);
    r.outcome = data[4]; r.delivered = data[5]; r.strainGained = data[8];
    r.backlashStrength = data[9]; r.ruling = data[10]; r.dice = data[11];
    if (data.length() >= 13) { r.scope = data[12]; r.defenses = data[13]; }
    if (data.length() >= 17 && r.check != nil)
    { r.check.margin = data[14]; r.check.critical = data[15]; r.check.rollSucceeded = data[16]; r.resistanceRolls = data[17]; }
    return r;
}
