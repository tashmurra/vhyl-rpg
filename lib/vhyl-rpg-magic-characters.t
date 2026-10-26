/* Include after expanded characters and skills. */

/** Immutable domain definition; its training is an ordinary paid IQ/VH skill. */
class RpgMagicDomain: RpgExpandedSkill
    attribute = rpgIQ
    difficulty = 3
    defaultPenalty = nil
    id = nil
;
rpgMagicSpace: RpgMagicDomain id = 'space';
rpgMagicChance: RpgMagicDomain id = 'chance-decay';
rpgMagicEnergy: RpgMagicDomain id = 'energy';
rpgMagicLife: RpgMagicDomain id = 'life';
rpgMagicMatter: RpgMagicDomain id = 'matter';
rpgMagicMind: RpgMagicDomain id = 'mind';
rpgMagicPower: RpgMagicDomain id = 'power';
rpgMagicSpirits: RpgMagicDomain id = 'spirits';
rpgMagicTime: RpgMagicDomain id = 'time';

/** Owned domain knowledge, independent of skill investment on the profile. */
class RpgMagicKnowledge: object
    owner = nil
    domain = nil
    rank = 0
    exempt = nil
    access = 5
    restorationPaid = 0
;

/** Owned known formula; improvements do not grant domain permission. */
class RpgMagicFormula: object
    owner = nil
    effect = nil
    improvement = 0
;

/** Optional owned personal tool. available is an authored inventory predicate.
 * Destruction/loss gates domain access separately through knowledge.access. */
class RpgMagicTool: object
    owner = nil
    domain = nil
    bound = nil
    designated = nil
    available(intent) { return nil; }
;

/** Owned character state and rank-cost contribution. Skill points are already
 * counted by the profile, so this contribution never counts them a second time. */
class RpgMagicState: RpgExpandedContribution
    mastery = 1
    channel = 0
    requiresPractice = true
    knowledge = []
    formulas = []
    opportunities = []
    tool = nil
    reserve = 0
    strain = 0
    lasting = 0
    revision = 0
    lastTurn = -1
    concentration = 0
    pendingBacklash = nil
    totalStrain() { return self.strain + self.lasting; }
    amounts(profile)
    {
        local result = [rpgMagicMasteryCost(self.mastery), self.channel * 15];
        foreach (local k in self.knowledge)
            result = result + [rpgMagicRankCost(k.rank, self.requiresPractice), k.restorationPaid];
        foreach (local f in self.formulas) result = result + [rpgMagicFormulaCost(f.improvement)];
        return result;
    }
    validate(profile)
    {
        rpgInteger(self.mastery, 1, 10); rpgInteger(self.channel, 0, 20);
        rpgInteger(self.reserve, 0, 20); rpgInteger(self.strain, 0, 1000000);
        rpgInteger(self.provisional,0,1000000); rpgInteger(self.lasting, 0, 1000000); rpgInteger(self.concentration, 0, 1000);
        if (self.reserve > rpgMagicCapacity(self)) rpgExpandedReject('magic-capacity');
        local ids = []; local exemptions = 0;
        foreach (local k in self.knowledge)
        {
            if (!k.ofKind(RpgMagicKnowledge) || k.owner != self
                || k.domain == nil || !k.domain.ofKind(RpgMagicDomain)
                || dataType(k.domain.id) != TypeSString || k.domain.id == ''
                || holds(ids, k.domain.id)) rpgExpandedReject('magic-domain-ownership');
            ids = ids + [k.domain.id]; rpgInteger(k.rank, 0, 5); rpgInteger(k.access, 0, 5);
            rpgInteger(k.restorationPaid, 0, 1000000);
            if (k.rank > self.mastery) rpgExpandedReject('magic-rank-mastery');
            if (k.exempt) exemptions += 1;
            if (k.domain.attribute != rpgIQ || k.domain.difficulty != 3
                || k.domain.defaultPenalty != nil || k.domain.defaults.length() != 0
                || k.domain.wildcard) rpgExpandedReject('magic-domain-skill');
        }
        if (exemptions > self.mastery - 1 && self.requiresPractice)
            rpgExpandedReject('magic-exemptions');
        local effects = [];
        foreach (local f in self.formulas)
        {
            if (!f.ofKind(RpgMagicFormula) || f.owner != self || f.effect == nil
                || holds(effects, f.effect)) rpgExpandedReject('magic-formula-ownership');
            effects = effects + [f.effect]; rpgInteger(f.improvement, 0, 3);
        }
        if (self.tool != nil && (self.tool.owner != self || self.tool.domain == nil))
            rpgExpandedReject('magic-tool-ownership');
        return nil;
    }
;

/** Corrected total mastery price, not the cost of each individual level. */
rpgMagicMasteryCost(level)
{
    rpgInteger(level, 1, 10);
    return [15,30,45,65,85,110,135,165,200,250][level];
}

/** Total domain rank price under the creation-time practice policy. */
rpgMagicRankCost(rank, practice)
{
    rpgInteger(rank, 0, 5);
    if (rank == 0) return 0;
    return [5,25,45,65,90][rank] + (practice ? 0 : 5);
}

/** Formula improvement totals; the zero-point default remains available. */
rpgMagicFormulaCost(improvement)
{
    rpgInteger(improvement, 0, 3); return [0,1,2,4][improvement + 1];
}

/** Cumulative restoration cost, rounded once so purchase paths cost the same. */
rpgMagicRestorationCost(rank, practice)
{ return (rpgMagicRankCost(rank, practice) + 1) / 2; }

/** Lookup without creating state or supplying a default rank. */
rpgMagicKnowledgeFor(state, domain)
{
    foreach (local k in state.knowledge) if (k.domain == domain) return k;
    return nil;
}

/** Capped paid skill; nil means absent training or currently inaccessible rank. */
rpgMagicSkill(state, domain, rank)
{
    local k = rpgMagicKnowledgeFor(state, domain);
    if (k == nil || k.rank < rank || (!k.exempt && k.access < rank)) return nil;
    local score = rpgExpandedPaidSkill(state.owner, domain, []);
    if (score == nil) return nil;
    if (state.mastery < 10 && score > 10 + state.mastery) score = 10 + state.mastery;
    return score;
}

/** A magic-owned purchase offer. unlocked represents an authored breakthrough,
 * learning or rebinding milestone; it never awards that milestone itself. */
class RpgMagicPurchase: object
    id = nil
    state = nil
    kind = 'rank'
    knowledge = nil
    formula = nil
    target = 1
    unlocked = nil
    purchased = nil
;

/** Pure development assessment using the existing profile point bank. */
rpgAssessMagicPurchase(offer)
{
    local r = new RpgExpandedResult(); local s = offer.state;
    rpgExpandedValidate(s.owner);
    if (!holds(s.owner.contributions, s)) rpgExpandedReject('magic-state-ownership');
    if (offer.purchased) { r.status = 'reused'; return r; }
    local old = 0;
    if (offer.kind == 'mastery')
    { old = s.mastery; r.points = rpgMagicMasteryCost(offer.target) - rpgMagicMasteryCost(old); }
    else if (offer.kind == 'channel')
    { rpgInteger(offer.target, 0, 20); old = s.channel; r.points = (offer.target - old) * 15; }
    else if (offer.kind == 'rank' || offer.kind == 'restore')
    {
        local k = offer.knowledge;
        if (k == nil || k.owner != s || !holds(s.knowledge, k)) rpgExpandedReject('magic-knowledge');
        rpgInteger(offer.target, 0, 5);
        if (offer.target > s.mastery || offer.kind == 'restore' && offer.target > k.rank)
        { r.reason = 'magic-rank-limit'; return r; }
        old = offer.kind == 'rank' ? k.rank : k.access;
        r.points = offer.kind == 'rank'
            ? rpgMagicRankCost(offer.target, s.requiresPractice) - rpgMagicRankCost(old, s.requiresPractice)
            : rpgMagicRestorationCost(offer.target, s.requiresPractice)
                - rpgMagicRestorationCost(old, s.requiresPractice);
    }
    else if (offer.kind == 'formula')
    {
        if (offer.formula == nil || !holds(s.formulas, offer.formula)) rpgExpandedReject('magic-formula');
        old = offer.formula.improvement;
        r.points = rpgMagicFormulaCost(offer.target) - rpgMagicFormulaCost(old);
    }
    else rpgExpandedReject('magic-purchase-kind');
    if (offer.target <= old) { r.status = 'reused'; r.points = 0; return r; }
    if (!offer.unlocked) { r.reason = 'magic-development-locked'; return r; }
    if (!s.owner.developmentOpen) { r.reason = 'rpg.downtime-required'; return r; }
    if (r.points > s.owner.unspentPoints) { r.reason = 'rpg.insufficient-points'; return r; }
    r.status = 'ready'; return r;
}

/** Commit once inside a gameplay transaction; existing trained skill is retained. */
rpgBuyMagic(offer)
{
    local r = rpgAssessMagicPurchase(offer);
    if (r.status != 'ready') return r;
    local s = offer.state; offer.purchased = true; s.owner.unspentPoints -= r.points;
    if (offer.kind == 'mastery') s.mastery = offer.target;
    else if (offer.kind == 'channel') s.channel = offer.target;
    else if (offer.kind == 'rank') offer.knowledge.rank = offer.target;
    else if (offer.kind == 'formula') offer.formula.improvement = offer.target;
    else { offer.knowledge.access = offer.target; offer.knowledge.restorationPaid += r.points; }
    s.revision += 1; s.owner.developmentRevision += 1; r.status = 'resolved'; return r;
}
