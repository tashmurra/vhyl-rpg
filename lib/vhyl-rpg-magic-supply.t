/* Explicit supply transactions. Every operation has a game-owned identity. */
class RpgMagicSupply: object
    id = nil
    quantity = 0
    consumed = nil
    channelled = nil
    receipts = []
    attempts = []
;
class RpgMagicSource: RpgMagicSupply
    output = 1
    owners = []
    periods = []
    rating() { return self.output <= 5 ? 1 : self.output <= 10 ? 2 : self.output <= 20 ? 3 : self.output <= 40 ? 4 : 5; }
    barrier() { return 9 - self.rating(); }
;

/** Reserve storage ceiling, including innate capacity without power training. */
rpgMagicStorage(state)
{
    local cap = rpgMagicCapacity(state);
    local k = rpgMagicKnowledgeFor(state,rpgMagicPower);
    if ((k == nil || k.rank < 1 || !k.exempt && k.access < 1) && cap > state.channel) cap = state.channel;
    return cap;
}

/** One indivisible portable portion. Allocate before rolling; leftovers are lost. */
rpgAbsorbMagicSupply(portion, allocations)
{
    local r = new RpgExpandedResult();
    if (portion.consumed) { r.status = 'reused'; return r; }
    local total = 0; local seen = [];
    foreach (local a in allocations)
    {
        if (a.length() != 2 || holds(seen,a[1])) rpgExpandedReject('magic-supply-allocation');
        rpgInteger(a[2],0,portion.quantity); total += a[2]; seen = seen + [a[1]];
        if (rpgMagicSkill(a[1],rpgMagicPower,3) == nil) { r.reason = 'magic-permission'; return r; }
    }
    if (total > portion.quantity) { r.reason = 'magic-supply-quantity'; return r; }
    portion.consumed = true;
    foreach (local a in allocations) rpgMagicReceive(a[1],a[2]);
    portion.quantity = 0; rpgSpendTime(1); r.status = 'resolved'; return r;
}

/** Atomic transfer after the successful operation's delivery and resistance.
 * A receipt belongs to the source; the same ID cannot transfer twice. */
rpgMoveMagicReserve(actor, donor, recipient, id, requested, margin, remote)
{
    rpgInteger(requested,0,20); rpgInteger(margin,0,1000);
    foreach (local receipt in donor.transfers)
        if (receipt[1] == id)
        { if (receipt[2] != recipient || receipt[3] != requested || receipt[4] != remote)
            rpgExpandedReject('magic-transfer-conflict'); return receipt[5]; }
    if (id == nil || donor == recipient || rpgMagicSkill(actor,rpgMagicPower,3) == nil
        || remote && rpgMagicSkill(actor,rpgMagicSpace,4) == nil)
        rpgExpandedReject('magic-transfer-permission');
    local n = (margin < 1 ? 1 : margin) * (remote ? 1 : 5);
    if (n > requested) n = requested;
    if (n > rpgMagicTransferable(donor)) n = rpgMagicTransferable(donor);
    if (n > rpgMagicStorage(recipient) - recipient.reserve) n = rpgMagicStorage(recipient) - recipient.reserve;
    if (n < 0) n = 0;
    donor.reserve -= n; recipient.reserve += n; donor.revision += 1; recipient.revision += 1;
    donor.transfers = donor.transfers + [[id,recipient,requested,remote,n]]; return n;
}

/** Source output uses explicit period IDs, independent of meditation. */
rpgCollectMagicSource(source, period)
{
    if (period == nil) rpgExpandedReject('magic-period');
    if (holds(source.periods,period)) return 0;
    rpgInteger(source.output,1,1000000);
    source.periods = source.periods + [period]; source.quantity += source.output; return source.output;
}

/** An hour of trained meditation replenishes innate reserve without consuming output. */
rpgMeditateMagic(state, source, skill)
{
    local r = new RpgExpandedResult();
    local score = rpgExpandedPaidSkill(state.owner,skill,[]);
    if (score == nil || score < 3 || skill.ofKind(RpgMagicDomain))
    { r.reason = 'magic-meditation-training'; return r; }
    if (state.reserve >= state.channel) { r.reason = 'magic-innate-full'; return r; }
    rpgSpendTime(3600); r.check = rpgCheck(score,rpgRandom.roll()); r.points = 0;
    if (r.check.rollSucceeded)
    {
        local n = r.check.margin / 2; if (n < 1) n = 1;
        if (n > source.rating()) n = source.rating();
        if (n > state.channel - state.reserve) n = state.channel - state.reserve;
        r.points = rpgMagicReceive(state,n);
    }
    r.seconds = 3600; r.status = 'resolved'; return r;
}

/** Only temporary strain can be removed through a successful power-five working. */
rpgRemoveMagicStrain(state, amount)
{
    rpgInteger(amount,0,20);
    if (rpgMagicSkill(state,rpgMagicPower,5) == nil || amount > state.reserve || amount > state.strain)
        rpgExpandedReject('magic-strain-removal');
    state.reserve -= amount; state.strain -= amount; state.revision += 1; return amount;
}

/** Advance abstinence recovery; reaching five or disallowed casting resets it. */
rpgMagicRecoveryTime(state, seconds)
{
    if (state.totalStrain() >= 5) { state.recoveryClock = 0; return nil; }
    state.recoveryClock += seconds;
    while (state.recoveryClock >= 604800)
    { state.recoveryClock -= 604800; if (state.strain > 0) { state.strain -= 1; state.revision += 1; } }
    return nil;
}
modify RpgMagicState
    transfers = []
;

/** Pull transfer convenience: recipient is the casting actor. Giving uses the explicit actor API. */
rpgTransferMagicReserve(donor,recipient,id,requested,margin,remote)
{ return rpgMoveMagicReserve(recipient,donor,recipient,id,requested,margin,remote); }

/** Authored access to starting portable supply or a share of an existing source. */
class RpgMagicSupplyPurchase: object
    id = nil
    state = nil
    source = nil
    portion = nil
    units = 1
    unlocked = nil
    creation = nil
;
modify RpgMagicState
    sourceShares = []
    portableInvestment = 0
    supplyPurchases = []
    validate(profile)
    {
        inherited(profile); rpgInteger(self.portableInvestment,0,1000000);
        local units = 0;
        foreach (local contribution in profile.contributions)
            if (contribution.ofKind(RpgMagicState))
                foreach (local share in contribution.sourceShares)
                { if (share.length() != 2 || !share[1].ofKind(RpgMagicSource)) rpgExpandedReject('magic-source-share');
                  rpgInteger(share[2],1,5); units += share[2]; }
        if (units > 5) rpgExpandedReject('magic-source-share-limit');
        return nil;
    }
    amounts(profile)
    {
        local prices = inherited(profile); prices = prices + [self.portableInvestment];
        foreach (local share in self.sourceShares) prices = prices + [share[2] * 10];
        return prices;
    }
;

/** Purchase ownership, not unlimited extraction. Source output is not increased. */
rpgBuyMagicSupply(offer)
{
    local r = new RpgExpandedResult(); local s = offer.state;
    if (s == nil || offer.id == nil) rpgExpandedReject('magic-supply-offer');
    rpgExpandedValidate(s.owner);
    if (!holds(s.owner.contributions,s)) rpgExpandedReject('magic-supply-owner');
    foreach (local receipt in s.supplyPurchases)
        if (receipt[1] == offer.id)
        { if (receipt[2] != offer.source || receipt[3] != offer.portion || receipt[4] != offer.units)
              rpgExpandedReject('magic-supply-offer-conflict'); r.status = 'reused'; return r; }
    rpgInteger(offer.units,1,1000);
    if (!offer.unlocked || !s.owner.developmentOpen) { r.reason = 'magic-supply-milestone'; return r; }
    local cost = 0;
    if (offer.source != nil && offer.portion == nil)
    {
        local owned = 0; foreach (local contribution in s.owner.contributions)
            if (contribution.ofKind(RpgMagicState)) foreach (local share in contribution.sourceShares) owned += share[2];
        if (owned + offer.units > 5) { r.reason = 'magic-source-share-limit'; return r; }
        local allocated = 0; foreach (local owner in offer.source.owners) allocated += owner[2];
        if (allocated + offer.units > offer.source.output) { r.reason = 'magic-source-unavailable'; return r; }
        cost = offer.units * 10;
    }
    else if (offer.portion != nil && offer.source == nil)
    {
        if (!offer.creation || rpgMagicSkill(s,rpgMagicPower,1) == nil || offer.portion.consumed)
        { r.reason = 'magic-starting-supply'; return r; }
        cost = offer.units * 2;
    }
    else { r.reason = 'magic-supply-offer'; return r; }
    if (s.owner.unspentPoints < cost) { r.reason = 'insufficient-points'; return r; }
    s.owner.unspentPoints -= cost;
    if (offer.source != nil)
    { s.sourceShares = s.sourceShares + [[offer.source,offer.units]];
      offer.source.owners = offer.source.owners + [[s,offer.units]]; }
    else { offer.portion.quantity += offer.units; s.portableInvestment += cost; }
    s.supplyPurchases = s.supplyPurchases + [[offer.id,offer.source,offer.portion,offer.units]];
    s.revision += 1; r.points = cost; r.status = 'resolved'; return r;
}
