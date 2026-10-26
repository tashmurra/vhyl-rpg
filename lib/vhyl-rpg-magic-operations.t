/* Typed operations. The host may construct proposals from provider data, but
 * requirements, units, defenses and handlers are derived here. */
class RpgMagicOperation: RpgMagicEffect
    operation = nil
    target = nil
    destination = nil
    propertyId = nil
    amount = 1
    yards = 0
    selection = 'touch'
    kind = 'cr'
    permanentAllowed = nil
    attention = nil
    specialMass = nil
    implemented = true
    lifecycleImplemented = true
    prepared = nil
    preparedFacts = []
    declaredWeight = 0
    domain = nil
    rank = 1
    observations = []
    criticalMinimum = 0
    changesMass = nil
    changesMomentum = nil
    massChange = 0
    momentumChange = 0
    requiredMargin(check) { return check.critical == 'success' ? self.criticalMinimum : self.minimumMargin; }
    facts(intent)
    {
        local facts = [self.operation,self.amount,self.propertyId,self.duration,self.yards,
            self.selection,self.kind,self.massChange,self.momentumChange,self.content,self.categories,self.target.facts(),self.target.observations];
        if (self.propertyId != nil && self.target.property(self.propertyId) != nil)
        { local p = self.target.property(self.propertyId);
            facts = facts + [[p.id,p.value,p.minimum,p.maximum,p.points,p.kind,p.mental,p.permanent]]; }
        if (self.destination != nil) facts = facts + [[self.destination.id,self.destination.revision,
            self.destination.barrier,self.destination.mode,self.destination.safe,self.destination.familiarity]];
        return facts;
    }
    declaration()
    {
        local p = self.propertyId == nil ? nil : self.target.property(self.propertyId);
        return [self.operation,self.target,self.destination,self.propertyId,self.amount,self.duration,
            self.yards,self.selection,self.kind,self.permanentAllowed,self.attention,self.specialMass,
            self.changesMass,self.changesMomentum,self.massChange,self.momentumChange,self.requirements,
            self.minimumMargin,self.criticalMinimum,self.fuel,self.fixedModifier,self.target.kind,
            self.target.alive,self.target.materials,self.target.novel,self.content,self.categories,
            p == nil ? nil : [p.points,p.mental,p.permanent,p.kind,p.operations]];
    }
    available(intent)
    {
        if (self.prepared && !rpgGmSame(self.preparedFacts,self.declaration())) return 'magic-reprepare-declaration';
        if (self.target != nil && self.target.mass() > self.declaredWeight) return 'magic-target-scope';
        if (!self.prepared || self.target == nil || self.target.world != intent.state.world)
            return 'magic-operation-world';
        if (self.target.world.subject(self.target.id) != self.target) return 'magic-target-registration';
        if (self.destination != nil && self.target.entity != nil && self.destination.room == nil) return 'magic-destination-room';
        if (self.destination != nil && self.target.world.place(self.destination.id) != self.destination)
            return 'magic-destination-registration';
        if (self.target.mass() + self.massChange < 0) return 'magic-negative-mass';
        if (self.operation == 'create' ? self.target.exists : !self.target.exists) return 'magic-target-existence';
        if (self.operation == 'create' && self.target.sapient) return 'magic-creation-mind';
        if (self.operation == 'create' && (!self.target.stable || !self.target.creationTemplate)) return 'magic-creation-template';
        if (self.operation == 'redirect' && self.target.energy <= 0) return 'magic-existing-energy';
        if (holds(['probe','possess'],self.operation) && holds(self.target.mentalLocks,self.operation))
            return 'magic-sleep-required';
        if (self.operation == 'enhance-mind' && self.target != intent.state.subject) return 'magic-self-only';
        if (self.operation == 'time-sense' && !intent.state.timekeeping) return 'magic-timekeeping-training';
        if (holds(['accelerate','suspend'],self.operation) && (self.target.location == nil || !self.target.location.smallRoom))
            return 'magic-time-area';
        if (self.operation == 'chance' && !self.target.randomEvent) return 'magic-random-event';
        if (self.operation == 'cross' && self.target != intent.state.subject) return 'magic-self-only';
        if (self.duration == -1 && !self.permanentAllowed) return 'magic-permanence';
        if (self.target.location != nil && self.target.location.mode == 'limited')
            foreach (local pair in self.requirements)
                if (pair[2] > self.target.location.rating(pair[1])) return 'magic-world-rating';
        if (holds(['relocate','cross','outer-cross','passage','overlap','region'],self.operation) && self.destination == nil)
            return 'magic-destination';
        if (holds(['reshape','transmute','extraordinary'],self.operation) && self.target.alive) return 'magic-matter-target';
        if (holds(['heal','reshape-life','transform-life'],self.operation) && !self.target.alive) return 'magic-life-target';
        if (self.domain == rpgMagicMind && !self.target.sapient) return 'magic-mind-target';
        if (holds(['injure','disturb'],self.operation) && self.target.profile == nil) return 'magic-health-profile';
        if (holds(['transfer'],self.operation) && self.target.magic == nil) return 'magic-reserve-target';
        if (self.operation == 'receive' && self.target.supply != nil && holds(self.target.supply.attempts,intent.state)) return 'magic-source-attempt';
        if (self.operation == 'receive' && (self.target.supply == nil || !self.target.supply.channelled)) return 'magic-channelled-supply';
        if (self.operation == 'relieve' && (self.amount < 0 || self.amount > intent.state.strain || self.amount + intent.reserveSpend > intent.state.reserve)) return 'magic-strain-removal';
        if (holds(['forward','generate'],self.operation) && self.amount < 1) return 'magic-positive-amount';
        if (self.operation == 'contact' && (self.target.relationship == nil || !self.target.relationship.identified
            || !self.target.visible || self.minimumMargin < self.target.relationship.contactMargin())) return 'magic-spirit-relationship';
        if (self.operation == 'enhance-mind' && self.duration == -1
            && (self.target.property(self.propertyId) == nil || !self.target.property(self.propertyId).permanent
                || self.target.property(self.propertyId).points <= 0 || intent.state.owner.unspentPoints < self.target.property(self.propertyId).points))
            return 'magic-permanent-benefit-purchase';
        if (self.propertyId != nil)
        {
            local p = self.target.property(self.propertyId);
            if (p != nil && p.operations.length() > 0 && !holds(p.operations,self.operation)) return 'magic-property-operation';
            if (p == nil || p.value + self.amount < p.minimum || p.value + self.amount > p.maximum)
                return 'magic-property-bounds';
            if (holds(['st','dx','iq','ht','will','perception'],p.id))
            { if (self.target.profile == nil) return 'magic-attribute-target';
              local attribute = p.id == 'st' ? rpgST : p.id == 'dx' ? rpgDX : p.id == 'iq' ? rpgIQ : p.id == 'ht' ? rpgHT : p.id == 'will' ? rpgWill : rpgPerception;
              local value = self.target.profile.attributeScore(attribute) + self.amount;
              if (value < 1 || value > 100) return 'magic-attribute-bounds'; }
            if (self.operation == 'enhance-mind' && (!p.mental || holds(['will','empathy','psychic'],p.id)))
                return 'magic-mental-benefit';
        }
        if (self.operation == 'heal')
        {
            if (self.target.profile == nil) return 'magic-health-profile';
            local severe = 0;
            foreach (local w in self.target.wounds) if (!w.treated && w.cause == 'severe') severe += w.remaining;
            if (severe > 0 && intent.state.reserve < self.fuel + intent.reserveSpend + (severe + 2) / 3)
                return 'magic-healing-reserve';
        }
        return nil;
    }
    afterRoll(intent,result)
    {
        if (self.operation == 'receive' && self.target.supply != nil)
            self.target.supply.attempts = self.target.supply.attempts + [intent.state];
        if (self.operation == 'probe' || self.operation == 'possess' && !result.check.rollSucceeded)
            self.target.mentalLocks = self.target.mentalLocks + [self.operation];
        if (self.operation == 'cross' && result.check.critical == 'failure') self.target.trapped = self.destination;
        return nil;
    }
    defend(intent,result)
    {
        local t = self.target;

        local d = nil;
        if (self.delivery == 'direct')
            d = rpgMagicResistContributions(t,result,self.possession);
        else if (self.delivery == 'indirect' && t.physicalDefense != nil)
        { d = new RpgMagicDefense(); d.target = t; d.resisted = t.physicalDefense.resolve(t); }
        if (d != nil)
        {
            result.defenses = result.defenses + [d];
            if (d.resisted) { result.delivered = nil; result.outcome = 'resisted';
                if (self.operation == 'possess') t.mentalLocks = t.mentalLocks + [self.operation]; }
        }
        if (result.delivered && self.operation == 'cross')
        {
            local barrier = rpgMagicBarrier(t); local opposing = rpgCheck(barrier,rpgRandom.roll());
            if (opposing.rollSucceeded && opposing.margin >= result.scope)
            { result.delivered = nil; result.outcome = 'barrier'; }
        }
    }
    apply(intent,result) { return rpgMagicApplyOperation(self,intent,result); }
;

/** Merge conjunctions by maximum required rank, never by adding skill bonuses. */
rpgMagicMergeRequirements(left,right)
{
    local merged = left;
    foreach (local p in right)
    {
        local next = []; local found = nil;
        foreach (local q in merged)
        { if (q[1] == p[1]) { next = next + [[p[1],p[2] > q[2] ? p[2] : q[2]]]; found = true; }
          else next = next + [q]; }
        if (!found) next = next + [p]; merged = next;
    }
    return merged;
}

/** Derive permission and scope from a bounded typed declaration. Call after
 * populating fields, before registering the effect with an intent. */
rpgPrepareMagicOperation(e, caster)
{
    local t = e.target; if (t == nil || t.world == nil || e.id == nil) rpgExpandedReject('magic-operation-target');
    if (e.content.length() > 16 || e.categories.length() > 16) rpgExpandedReject('magic-content-limit');
    foreach (local category in e.categories) if (dataType(category) != TypeSString) rpgExpandedReject('magic-link-category');
    if (e.operation == 'memory')
        foreach (local entry in e.content)
        {
            if (dataType(entry) != TypeList || entry.length() < 2 || !holds(['suppress','add'],entry[1])
                || dataType(entry[2]) != TypeSString || entry[1] == 'suppress' && entry.length() != 2
                || entry[1] == 'add' && (entry.length() != 3 || dataType(entry[3]) != TypeSString))
                rpgExpandedReject('magic-memory-content');
        }
    if (!holds(['cr','cut','imp','burn','pi-','pi','pi+','tox','fat'],e.kind)) rpgExpandedReject('magic-damage-kind');
    rpgInteger(e.massChange,-1000000,1000000); rpgInteger(e.momentumChange,-1000000,1000000);
    rpgInteger(e.amount,-1000000,1000000); rpgInteger(e.duration,-1,604800);
    local op = e.operation; local d = nil; local rank = 1; local extra = [];
    local lifeRank = t.kind == 'simple-life' ? 2 : t == caster.subject ? 3 : 4;
    e.delivery = 'noncombat'; e.possession = nil;
    if (op == 'observe')
    { d = e.domain; if (!holds([rpgMagicSpace,rpgMagicChance,rpgMagicEnergy,rpgMagicLife,rpgMagicMatter,rpgMagicPower,rpgMagicSpirits],d)) rpgExpandedReject('magic-observation-domain'); }
    else if (op == 'remote-sense' || op == 'search' || op == 'relocate' || op == 'passage' || op == 'dimensions' || op == 'overlap' || op == 'distribute')
    { d = rpgMagicSpace; rank = op == 'remote-sense' ? 2 : op == 'search' ? 3 : op == 'relocate' ? (t == caster.subject ? 3 : 4) : op == 'passage' || op == 'distribute' ? 4 : 5; }
    else if (op == 'chance' || op == 'decay' || op == 'erode-belief')
    { d = rpgMagicChance; rank = op == 'chance' ? 2 : op == 'erode-belief' ? 5 : t.alive ? 4 : 3;
      if (op == 'decay' && t.alive && e.propertyId != nil) extra = [[rpgMagicLife,lifeRank]]; }
    else if (op == 'redirect' || op == 'generate')
    { d = rpgMagicEnergy; rank = holds(['light','electricity','magnetism'],t.energyKind) ? 2 : 4;
      if (op == 'generate') { rank += 1; extra = [[rpgMagicPower,2]]; } }
    else if (op == 'heal' || op == 'reshape-life' || op == 'transform-life')
    { d = rpgMagicLife; rank = op == 'transform-life' ? 5 : lifeRank; }
    else if (op == 'create')
    {
        d = t.alive ? rpgMagicLife : rpgMagicMatter;
        rank = t.alive ? (t.kind == 'simple-life' && !t.novel ? 3 : 5)
            : t.novel ? 5 : t.materials > 1 ? 4 : 2;
        extra = [[rpgMagicPower,2]];
    }
    else if (op == 'reshape' || op == 'transmute' || op == 'extraordinary')
    { d = rpgMagicMatter; rank = op == 'reshape' ? 3 : op == 'transmute' ? 4 : 5;
      if (op == 'reshape' && t.materials > 1) rank = 4; }
    else if (op == 'enhance-mind' || op == 'suggest' || op == 'link' || op == 'probe' || op == 'illusion' || op == 'memory' || op == 'possess' || op == 'project')
    { d = rpgMagicMind; rank = op == 'enhance-mind' ? 1 : op == 'suggest' ? 2
        : holds(['link','probe','illusion'],op) ? 3 : op == 'project' ? 5 : 4; e.possession = op == 'possess'; }
    else if (op == 'receive' || op == 'disturb' || op == 'transfer' || op == 'unmake' || op == 'replenish' || op == 'relieve')
    { d = rpgMagicPower; rank = op == 'receive' ? 1 : op == 'disturb' ? 2 : op == 'transfer' ? 3 : op == 'unmake' && !t.alive ? 4 : 5;
      if (op == 'transfer' && e.destination != nil) extra = [[rpgMagicSpace,4]]; }
    else if (op == 'contact' || op == 'cross' || op == 'boundary' || op == 'region' || op == 'outer-cross' || op == 'mark' || op == 'spirit-protection')
    { d = rpgMagicSpirits; rank = op == 'contact' ? 2 : op == 'cross' ? 3 : op == 'boundary' || op == 'region' ? 4 : 5;
      if (op == 'region') { extra = [[rpgMagicMatter,4],[rpgMagicPower,3]]; e.fuel = 10; } }
    else if (op == 'time-sense' || op == 'past' || op == 'future' || op == 'accelerate' || op == 'suspend' || op == 'forward' || op == 'outside-time')
    { d = rpgMagicTime; rank = op == 'time-sense' ? 1 : op == 'past' || op == 'future' ? 2 : op == 'accelerate' ? 3 : op == 'suspend' ? 4 : 5;
      if (op == 'past' && e.destination != nil) extra = [[rpgMagicSpace,3]]; }
    else if (op == 'injure')
    { d = e.domain; rank = d == rpgMagicLife ? lifeRank : d == rpgMagicMind ? 3 : d == rpgMagicPower ? 2 : d == rpgMagicEnergy ? (holds(['light','electricity','magnetism'],t.energyKind) ? 3 : 5) : 0;
      if (rank == 0) rpgExpandedReject('magic-damage-domain'); if (d == rpgMagicEnergy) extra = [[rpgMagicPower,2]]; }
    else rpgExpandedReject('unsupported-effect');
    if (d == nil) rpgExpandedReject('magic-domain');
    if (d == rpgMagicSpace && (e.changesMass || e.massChange != 0)) extra = rpgMagicMergeRequirements(extra,[[t.alive ? rpgMagicLife : rpgMagicMatter,t.alive ? lifeRank : 3]]);
    if (d == rpgMagicSpace && (e.changesMomentum || e.momentumChange != 0))
    { extra = rpgMagicMergeRequirements(extra,[[rpgMagicEnergy,e.momentumChange > 0 ? 5 : 4]]);
      if (e.momentumChange > 0) extra = rpgMagicMergeRequirements(extra,[[rpgMagicPower,2]]); }
    if (op == 'unmake' && e.propertyId != nil)
    { local property = t.property(e.propertyId); if (property == nil) rpgExpandedReject('magic-property');
      extra = rpgMagicMergeRequirements(extra,[[t.kind == 'energy' ? rpgMagicEnergy : rpgMagicMatter,
          t.kind == 'energy' ? (holds(['light','electricity','magnetism'],t.energyKind) ? 2 : 4) : property.kind == 'extraordinary' ? 5 : 3]]); }
    if (e.propertyId != nil)
    {
        local property = t.property(e.propertyId);
        if (property != nil && d == rpgMagicMatter && property.kind == 'extraordinary') rank = 5;
        if (property != nil && d == rpgMagicLife && property.mental)
            extra = rpgMagicMergeRequirements(extra,[[rpgMagicMind,t == caster.subject ? 1 : 4]]);
    }
    e.personalPerception = rank == 1 && t == caster.subject && holds(['observe','time-sense'],op);
    e.domain = d; e.rank = rank; e.requirements = rpgMagicMergeRequirements([[d,rank]],extra);
    if (holds(['relocate','reshape-life','transform-life','decay','erode-belief','suggest','link','probe','illusion','memory','possess','disturb','transfer','unmake','injure'],op))
        e.delivery = op == 'injure' && d == rpgMagicEnergy ? 'indirect' : 'direct';
    local physical = 0;
    local need = rpgMagicReachMargin(e.selection,e.yards,t.visible,t.sensed);
    if (e.duration != 0)
    { local n = rpgMagicDurationMargin(e.duration); if (n > need) need = n; }
    if (holds(['create','reshape','transmute','extraordinary','unmake','disturb','relocate','reshape-life','transform-life'],op))
    { local n = rpgMagicMassMargin(t.mass(),op == 'create',e.specialMass); if (n > need) need = n; physical = n; }
    if (e.destination != nil && d == rpgMagicSpace)
    { local n = rpgMagicSpaceMargin(e.destination.familiarity); if (n > need) need = n; }
    if (op == 'enhance-mind')
    { local p = t.property(e.propertyId); if (p == nil) rpgExpandedReject('magic-property');
      physical = rpgMagicTraitMargin(p.points) + 1;
      need = rpgMagicTraitMargin(p.points) + (e.duration == 0 ? 1 : rpgMagicDurationMargin(e.duration) + 1); }
    if (op == 'contact' && t.relationship != nil)
    { local n = t.relationship.contactMargin(); if (n > need) need = n; if (n > physical) physical = n; }
    if (op == 'heal' || op == 'injure') { local n = e.amount; if (n < 1) rpgExpandedReject('magic-positive-amount'); if (n == 1) n = 0; if (n > need) need = n; if (n > physical) physical = n; }
    if (op == 'observe' && d == rpgMagicSpirits)
    { if (t.location == nil) rpgExpandedReject('magic-location'); local n = rpgMagicSightMargin(t.location.barrier); if (n > need) need = n; if (n > physical) physical = n; }
    if (op == 'accelerate') { local n = (e.amount - 1) * 2; if (n > need) need = n; e.fixedModifier = -2; if (n > physical) physical = n; }
    if (op == 'outer-cross') e.fixedModifier = -5;
    if (holds(['reshape-life','transform-life'],op) && e.propertyId != nil)
    { local n = (e.amount < 0 ? -e.amount : e.amount) * (t == caster.subject ? 1 : 2);
      if (e.propertyId == 'armor') { n = ((e.amount < 0 ? -e.amount : e.amount) + 4) / 5; if (n == 1) n = 0; }
      else if (t == caster.subject && n == 1) n = 0;
      if (n > need) need = n; if (n > physical) physical = n; }
    if (op == 'boundary') { local n = e.amount < 0 ? -e.amount : e.amount; if (n == 1) n = 0; if (n > need) need = n; if (n > physical) physical = n; }
    if (holds(['receive','replenish','transfer'],op))
    { if (e.amount < 1) rpgExpandedReject('magic-positive-amount');
      local n = op == 'transfer' && e.destination == nil ? (e.amount + 4) / 5 : e.amount;
      if (n == 1) n = 0; if (n > need) need = n; if (n > physical) physical = n; }
    e.minimumMargin = need; e.criticalMinimum = physical; e.declaredWeight = t.mass(); e.prepared = true; e.preparedFacts = e.declaration(); return e;
}

/** Typed delivery. No provider-supplied property access or callbacks. */
rpgMagicApplyOperation(e,intent,result)
{
    local t = e.target; local s = intent.state; local w = t.world; local op = e.operation;
    local seconds = e.duration == 0 ? 30 : e.duration; local layer = nil;
    if (holds(['observe','remote-sense','search','past','future','time-sense','probe'],op))
    {
        /* Only explicitly authored observations are disclosed. Future never reads RNG. */
        foreach (local observation in t.observations)
            if (observation[1] == op || op == 'observe' && observation[1] == e.domain.id)
                e.observations = e.observations + [observation];
        if (op == 'remote-sense') rpgMagicLayer(s,t,'spatial-disturbance',1,seconds,nil);
    }
    else if (op == 'enhance-mind' && e.duration == -1) layer = rpgMagicPurchaseBenefit(s,t.property(e.propertyId),e.amount);
    else if (op == 'heal') rpgHealMagic(t,e.amount,result.ruling[2][2] == 'overt',s);
    else if (op == 'injure' || op == 'disturb')
    {
        local dice = rpgMagicDamageDice(e.domain,e.rank,e.amount,e.domain == rpgMagicLife);
        local injury = rpgMagicRollDamage(dice,e.kind,e.domain == rpgMagicLife);
        local armor = 0;
        if (e.delivery == 'indirect')
        { armor = rpgLiteArmor(t.profile); if (t.physicalDefense != nil) armor += t.physicalDefense.cover; }
        injury = rpgLitePenetration(injury,armor,1,e.kind,nil);
        if (e.kind == 'fat') rpgLiteFatigue(t.profile,injury,'exertion');
        else rpgMagicWound(t,injury,'ordinary',nil);
    }
    else if (op == 'relocate' || op == 'cross' || op == 'outer-cross')
    { if (e.destination == nil) rpgExpandedReject('magic-destination'); rpgRelocateMagicSubject(t,e.destination); t.trapped = nil; }
    else if (op == 'create')
    { rpgMagicSetExistence(t,true); t.controller = nil; layer = rpgMagicLayer(s,t,'created',1,seconds,nil); }
    else if (op == 'unmake')
    { if (e.propertyId == nil) rpgMagicSetExistence(t,nil); else layer = rpgMagicLayer(s,t,e.propertyId,-t.value(e.propertyId),seconds,nil); }
    else if (op == 'dimensions')
    { layer = rpgMagicLayer(s,t,'dimensions',e.amount,seconds,nil);
      if (e.massChange != 0) rpgMagicLayer(s,t,'mass',e.massChange,seconds,nil);
      if (e.momentumChange != 0) rpgMagicLayer(s,t,'momentum',e.momentumChange,seconds,nil); }
    else if (op == 'redirect') { t.energyDestination = e.destination; }
    else if (op == 'generate') { t.energy += e.amount; }
    else if (op == 'transfer')
    { if (t.magic == nil) rpgExpandedReject('magic-reserve-target'); rpgTransferMagicReserve(t.magic,s,intent.opportunity.id,e.amount,result.scope,e.destination != nil); }
    else if (op == 'receive')
    {
        if (t.supply == nil) rpgExpandedReject('magic-supply');
        if (!holds(t.supply.receipts,s))
        { local n = result.scope < 1 ? 1 : result.scope; if (n > e.amount) n = e.amount; if (n > t.supply.quantity) n = t.supply.quantity;
          t.supply.quantity -= rpgMagicReceive(s,n); t.supply.receipts = t.supply.receipts + [s]; }
    }
    else if (op == 'relieve') rpgRemoveMagicStrain(s,e.amount);
    else if (op == 'replenish')
    { local n = s.channel - s.reserve; if (n > e.amount) n = e.amount; if (n > 0) rpgMagicReceive(s,n); }
    else if (op == 'forward') w.advance(intent.opportunity.id,e.amount);
    else if (op == 'possess')
    { layer = rpgMagicLayer(s,t,'controller',1,seconds,true); layer.previousController = t.controller; t.controller = s; }
    else if (op == 'project')
    { layer = rpgMagicLayer(s,t,'projection',1,seconds,true); t.projected = layer; t.spiritHealth = s.owner.attributeScore(rpgWill); }
    else if (op == 'link')
    { layer = rpgMagicLayer(s,t,'link',1,seconds,e.attention);
      local link = new RpgMagicLink(); link.owner = s; link.members = [s.subject,t]; link.categories = e.categories; link.layer = layer;
      t.links = t.links + [link]; s.subject.links = s.subject.links + [link]; }
    else if (op == 'contact') t.contacted = true;
    else if (op == 'boundary')
    { layer = rpgMagicLayer(s,t,'boundary',e.amount * 2,seconds,nil); layer.reversible = true; }
    else if (holds(['passage','overlap','region','distribute'],op))
    { layer = rpgMagicLayer(s,t,op,e.amount,seconds,nil); layer.destination = e.destination; layer.reversible = true; w.topology = w.topology + [layer]; }
    else
    {
        local key = e.propertyId == nil ? op : e.propertyId;
        layer = rpgMagicLayer(s,t,key,e.amount,seconds,e.attention);
        if (holds(['reshape-life','transform-life'],op)) layer.unstable = true;
        if (op == 'memory') layer.reversible = true;
    }
    if (layer != nil) { layer.effect = e; layer.intent = intent; layer.result = result; layer.content = e.content; }
    t.revision += 1; return nil;
}

modify RpgMagicSubject
    creationTemplate = nil
    novel = nil
    randomEvent = nil
    energyDestination = nil
    supply = nil
    contacted = nil
    relationship = nil
;
modify RpgMagicState
    timekeeping = nil
;
modify RpgMagicOngoing
    destination = nil
;

/** Compound declarations retain each operation's checks and target defenses. */
class RpgMagicComposition: RpgMagicEffect
    steps = []
    declarations = []
    implemented = true
    lifecycleImplemented = true
    facts(intent)
    { local f = []; foreach (local e in self.steps) f = f + [[e.id,e.facts(intent)]]; return f; }
    available(intent)
    { local declarations = []; foreach (local e in self.steps)
      { local reason = e.available(intent); if (reason != nil) return reason; declarations = declarations + [e.preparedFacts]; }
      return rpgGmSame(declarations,self.declarations) ? nil : 'magic-recompose-declaration'; }
    afterRoll(intent,result) { foreach (local e in self.steps) e.afterRoll(intent,result); return nil; }
    apply(intent,result)
    {
        foreach (local e in self.steps)
        {
            local child = new RpgMagicResult(); child.effect = e; child.score = result.score;
            child.check = result.check; child.scope = result.scope; child.ruling = result.ruling; child.resistanceRolls = result.resistanceRolls; child.delivered = true;
            e.defend(intent,child); if (child.delivered) e.apply(intent,child);
            result.defenses = result.defenses + child.defenses;
        }
    }
;

/** Build a conjunction from already validated typed operations, never raw code. */
rpgComposeMagic(id,steps)
{
    if (id == nil || steps.length() < 1 || steps.length() > 8) rpgExpandedReject('magic-composition');
    local e = new RpgMagicComposition(); e.id = id; e.steps = steps;
    foreach (local step in steps)
    {
        if (!step.ofKind(RpgMagicOperation) || !step.prepared) rpgExpandedReject('magic-operation');
        e.declarations = e.declarations + [step.preparedFacts];
        e.requirements = rpgMagicMergeRequirements(e.requirements,step.requirements);
        if (step.minimumMargin > e.minimumMargin) e.minimumMargin = step.minimumMargin;
        if (step.seconds > e.seconds) e.seconds = step.seconds;
        e.fuel += step.fuel;
    }
    local views = 0; foreach (local step in steps) if (step.operation == 'remote-sense') views += 1;
    if (views > 1) e.requirements = rpgMagicMergeRequirements(e.requirements,[[rpgMagicSpace,3]]);
    return e;
}
