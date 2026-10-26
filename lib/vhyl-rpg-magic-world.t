/* Persistent world adapters and independently removable effects. */

/** A typed, authored property; providers select its ID, never an object property. */
class RpgMagicProperty: object
    id = nil
    kind = 'ordinary'
    value = 0
    minimum = -1000000
    maximum = 1000000
    points = 0
    mental = nil
    permanent = nil
    operations = []
;

/** Target owned by one world. Entity/profile references are never exported to a model. */
class RpgMagicSubject: object
    id = nil
    world = nil
    entity = nil
    profile = nil
    magic = nil
    kind = 'matter'
    location = nil
    weight = 100
    materials = 1
    energyKind = 'light'
    energy = 0
    speed = 0
    exists = true
    visible = true
    sensed = true
    hidden = nil
    stable = true
    alive = nil
    sapient = nil
    conscious = true
    aware = true
    willing = nil
    properties = []
    observations = []
    wounds = []
    sleepRevision = 0
    mentalLocks = []
    controller = nil
    spiritHealth = 0
    projected = nil
    trapped = nil
    magicalHealing = nil
    injuryCause = 'ordinary'
    injuryBlock = nil
    revision = 0
    mass() { return self.weight + rpgMagicOverlayValue(self,'mass'); }
    property(id)
    { foreach (local p in self.properties) if (p.id == id) return p; return nil; }
    value(id)
    {
        local p = self.property(id); if (p == nil) rpgExpandedReject('magic-property');
        return p.value + rpgMagicOverlayValue(self, id);
    }
    facts()
    { return [self.id,self.revision,self.kind,self.exists,self.location == nil ? nil : self.location.id,
        self.weight,self.materials,self.energyKind,self.energy,self.visible,self.sensed,
        self.hidden,self.stable,self.alive,self.sapient,self.conscious,self.aware,self.willing,self.sleepRevision]; }
    slept() { self.sleepRevision += 1; self.mentalLocks = []; return nil; }
;

/** Authored place and boundary, independent of its optional adventure Room. */
class RpgMagicPlace: object
    id = nil
    room = nil
    barrier = 14
    ratings = []
    mode = 'ordinary'
    smallRoom = true
    safe = true
    familiarity = 'visible'
    sourceRating = 0
    source = nil
    accepted = []
    rejected = []
    revision = 0
    rating(domain)
    { foreach (local p in self.ratings) if (p[1] == domain) return p[2]; return 0; }
;

/** Removable layer. Strongest magnitude of each sign wins; ties keep oldest ID. */
class RpgMagicOngoing: object
    id = 0
    world = nil
    caster = nil
    target = nil
    key = nil
    amount = 0
    expires = -1
    active = true
    attention = nil
    anchored = nil
    trigger = nil
    triggered = nil
    effect = nil
    intent = nil
    result = nil
    reversible = nil
    unstable = nil
    leakageClock = 0
    previousController = nil
;

/** World-time clock and journalled scheduler. Call advance once per real elapsed interval. */
class RpgMagicWorld: object
    seconds = 0
    turn = 0
    serial = 0
    subjects = []
    places = []
    effects = []
    advances = []
    states = []
    topology = []
    advance(id, seconds)
    {
        rpgInteger(seconds, 0, 1000000000 - self.seconds);
        if (id == nil) rpgExpandedReject('magic-clock-id');
        foreach (local a in self.advances)
            if (a[1] == id) { if (a[2] != seconds) rpgExpandedReject('magic-clock-conflict'); return nil; }
        self.advances = self.advances + [[id,seconds]];
        local end = self.seconds + seconds;
        /* Process deadlines in chronological order, including simultaneous stable IDs. */
        while (true)
        {
            local next = end; local found = nil;
            foreach (local e in self.effects)
                if (e.active && e.expires >= self.seconds && e.expires <= next
                    && !(e.subjective && rpgMagicOverlayValue(e.target,'suspend') > 0))
                { next = e.expires; found = true; }
            local elapsed = next - self.seconds;
            foreach (local target in self.subjects)
                if (target.projected != nil && target.projected.active)
                { target.projectionRecovery += elapsed;
                  local healed = target.projectionRecovery / 3600; target.projectionRecovery %= 3600;
                  target.spiritHealth += healed;
                  local cap = target.profile.attributeScore(rpgWill); if (target.spiritHealth > cap) target.spiritHealth = cap; }
            foreach (local timer in self.effects)
                if (timer.active && timer.subjective && timer.expires >= 0 && rpgMagicOverlayValue(timer.target,'suspend') > 0)
                    timer.expires += elapsed;
            foreach (local s in self.states) rpgMagicRecoveryTime(s, elapsed);
            foreach (local e in self.effects)
                if (e.active && e.unstable && elapsed > 0)
                {
                    e.leakageClock += elapsed;
                    local injury = e.leakageClock / 86400; e.leakageClock %= 86400;
                    if (injury > 0) rpgMagicWound(e.target, injury, 'unstable', e);
                }
            self.seconds = next;
            foreach (local e in self.effects)
                if (e.active && e.expires == next)
                {
                    if (e.trigger != nil && !e.triggered)
                    { e.triggered = true; e.trigger.fire(e); }
                    rpgMagicEndEffect(e);
                }
            if (!found || self.seconds == end) break;
        }
        self.turn += seconds; return nil;
    }
    subject(id)
    { foreach (local s in self.subjects) if (s.id == id) return s; return nil; }
    place(id)
    { foreach (local p in self.places) if (p.id == id) return p; return nil; }
;

/** Strongest positive and strongest negative equivalent layers combine. */
rpgMagicOverlayValue(subject, key)
{
    if (subject == nil || subject.world == nil) return 0;
    local positive = 0; local negative = 0;
    foreach (local e in subject.world.effects)
        if (e.active && e.target == subject && e.key == key)
        { if (e.amount > positive) positive = e.amount; if (e.amount < negative) negative = e.amount; }
    return positive + negative;
}

/** Add an owned effect without mutating the target's base value. */
rpgMagicLayer(state, target, key, amount, seconds, attention)
{
    local w = target.world; if (w == nil) rpgExpandedReject('magic-world');
    rpgInteger(seconds, -1, 1000000000 - w.seconds);
    local e = new RpgMagicOngoing(); w.serial += 1; e.id = w.serial;
    e.world = w; e.caster = state; e.target = target; e.key = key; e.amount = amount;
    e.expires = seconds == -1 ? -1 : w.seconds + seconds; e.attention = attention;
    w.effects = w.effects + [e]; target.revision += 1; return e;
}

/** Remove this effect only. A later independent controller is not overwritten. */
rpgMagicEndEffect(effect)
{
    if (!effect.active) return nil;
    effect.active = nil;
    if (effect.key == 'controller' && effect.target.controller == effect.caster)
        effect.target.controller = effect.previousController;
    if (effect.key == 'created') rpgMagicSetExistence(effect.target,nil);
    if (effect.key == 'projection') effect.target.projected = nil;
    effect.target.revision += 1; return nil;
}

/** Only expressly reversible effects can be canceled by their owner. */
rpgCancelMagicEffect(state, effect)
{
    local r = new RpgExpandedResult();
    if (!effect.active) { r.status = 'reused'; return r; }
    if (effect.caster != state || !effect.reversible) { r.reason = 'magic-cancel-permission'; return r; }
    rpgMagicEndEffect(effect); r.status = 'resolved'; return r;
}

/** Actual concentration load, excluding passive duration, anchors and waiting triggers. */
rpgMagicAttention(state)
{
    local n = state.concentration;
    if (state.world != nil) foreach (local e in state.world.effects)
        if (e.active && e.caster == state && e.attention && !e.anchored && e.trigger == nil
            && !(e.effect != nil && e.effect.personalPerception)) n += 1;
    return n;
}

modify RpgMagicState
    world = nil
    subject = nil
    provisional = 0
    recoveryClock = 0
    ritual = nil
    work = nil
    totalStrain() { return self.strain + self.lasting + self.provisional; }
;

modify RpgMagicScene
    world = nil
    place = nil
    worldTurn() { return self.world == nil ? inherited() : self.world.turn; }
;

/** Subjective activity changes do not change the world's casting clock. */
rpgMagicActionRate(subject)
{
    local rate = rpgMagicOverlayValue(subject,'accelerate'); return rate > 1 ? rate : 1;
}
rpgMagicSubjectCanAct(subject)
{ return subject.exists && subject.conscious && rpgMagicOverlayValue(subject,'suspend') == 0; }

/** Query actual topology. Ordinary passages do not transport their surroundings. */
rpgMagicDestinations(subject)
{
    local destinations = [subject.location];
    foreach (local e in subject.world.topology)
        if (e.active && e.target == subject && e.destination != nil) destinations = destinations + [e.destination];
    return destinations;
}
rpgTraverseMagicPassage(subject,passage,willing,carried)
{
    if (!passage.active || !holds(['passage','overlap','region'],passage.key)
        || passage.destination == nil || !willing && !carried) return nil;
    rpgRelocateMagicSubject(subject,passage.destination); return true;
}

/** Boundary rescue requires the rescuer to reach the prison or an open breach. */
rpgRescueMagicTraveler(rescuer,subject)
{
    if (subject.trapped == nil || rescuer.location != subject.trapped && rpgMagicBarrier(subject) > 0) return nil;
    subject.trapped = nil; subject.revision += 1; return true;
}

/** Triggers are registered game objects, never provider executable text. */
class RpgMagicTrigger: object
    id = nil
    fired = nil
    fire(effect) { self.fired = true; return nil; }
;
modify RpgMagicOngoing
    subjective = nil
;

/** Long downtime is charged in legal host ledger chunks, with overflow preflight. */
rpgMagicSpendTime(seconds)
{
    rpgInteger(seconds,0,1000000000); rpgInteger(rpgLedger.seconds,0,2147483647 - seconds);
    while (seconds > 0) { local n = seconds > 86400 ? 86400 : seconds; rpgSpendTime(n); seconds -= n; }
    return nil;
}

/** Suggested local boundary defaults; authors may override individual locations. */
rpgMagicDefaultBarrier(kind,sourceStrength)
{
    if (sourceStrength > 0) { rpgInteger(sourceStrength,1,5); return 9 - sourceStrength; }
    if (kind == 'laboratory') return 18;
    if (kind == 'inner-city') return 16;
    if (kind == 'ordinary' || kind == 'city') return 14;
    if (kind == 'rural') return 12;
    if (kind == 'wilderness') return 10;
    rpgExpandedReject('magic-boundary-profile'); return 0;
}

/** One accepted/neutral/rejected modifier, never stacked by overlapping profiles. */
rpgMagicLocalModifier(place,practice)
{
    if (place == nil || practice == nil) return 0;
    local yes = holds(place.accepted,practice.id); local no = holds(place.rejected,practice.id);
    if (yes && no) rpgExpandedReject('magic-local-conflict');
    return yes ? 1 : no ? -1 : 0;
}
modify RpgMagicScene
    modifierFor(intent)
    { return self.place == nil ? self.localModifier : rpgMagicLocalModifier(self.place,intent.practice); }
;

/** Relocate the optional adventure entity as well as its typed world adapter. */
rpgRelocateMagicSubject(subject,destination)
{
    if (destination == nil) rpgExpandedReject('magic-destination');
    if (subject.entity != nil)
    {
        if (destination.room == nil) rpgExpandedReject('magic-destination-room');
        if (subject.entity.ofKind(Actor)) relocateActor(subject.entity,destination.room);
        else contains.set(destination.room,subject.entity);
    }
    subject.location = destination; subject.revision += 1; return nil;
}

/** Reflect created/unmade adapter existence in ordinary containment. */
rpgMagicSetExistence(subject,exists)
{
    if (subject.entity != nil)
    {
        if (exists)
        { if (subject.location == nil || subject.location.room == nil) rpgExpandedReject('magic-creation-location');
          contains.set(subject.location.room,subject.entity); }
        else if (location.get(subject.entity) != nil) contains.unset(location.get(subject.entity),subject.entity);
    }
    subject.exists = exists; subject.revision += 1; return nil;
}

modify RpgMagicScene
    sourceBonus()
    {
        if (self.place == nil) return 0;
        local rating = self.place.source == nil ? self.place.sourceRating : self.place.source.rating();
        rpgInteger(rating,0,5); return rating;
    }
    facts()
    {
        local data = inherited(); if (self.place == nil) return data;
        local ratings = []; foreach (local pair in self.place.ratings) ratings = ratings + [[pair[1].id,pair[2]]];
        return data + [[self.place.id,self.place.revision,self.place.mode,self.place.barrier,
            self.sourceBonus(),ratings,self.place.accepted,self.place.rejected]];
    }
;
