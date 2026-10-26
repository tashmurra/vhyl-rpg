/* Deterministic resource accounting; authored consequences remain explicit. */

/** Shared reserve capacity; strain is never capped at twenty. */
rpgMagicCapacity(state)
{
    local result = 20 - state.totalStrain(); return result < 0 ? 0 : result;
}

/** Add earned strain, then displace reserve with no later refund. */
rpgMagicAddStrain(state, amount)
{
    rpgInteger(amount, 0, 1000000 - state.strain); state.strain += amount;
    if (state.reserve > rpgMagicCapacity(state)) state.reserve = rpgMagicCapacity(state);
    if (state.totalStrain() >= 5) state.recoveryClock = 0;
    state.revision += 1; return nil;
}

/** Storage primitive, not permission to create supply. A receiving operation
 * must establish actual source quantity, permissions and throughput first. */
rpgMagicReceive(state, amount)
{
    rpgInteger(amount, 0, 1000000);
    local cap = rpgMagicCapacity(state); local power = rpgMagicKnowledgeFor(state, rpgMagicPower);
    if ((power == nil || power.rank < 1 || !power.exempt && power.access < 1) && cap > state.channel)
        cap = state.channel;
    local accepted = cap - state.reserve;
    if (accepted < 0) accepted = 0;
    if (accepted > amount) accepted = amount;
    state.reserve += accepted; state.revision += 1; return accepted;
}

/** Protected reserve is a numerical floor, not a provenance ledger. */
rpgMagicTransferable(state)
{ return state.reserve > state.channel ? state.reserve - state.channel : 0; }

/** Gain from the actual roll, before delivery. Natural failures at high skill
 * use minimum failure margin one; this is an explicit host conversion. */
rpgMagicStrainGain(check, rank, appearance, witnessed)
{
    if (appearance == 'subtle') return check.critical == 'failure' ? rank : 0;
    if (check.rollSucceeded) return witnessed ? rank : 1;
    local failure = check.margin < 0 ? -check.margin : 1;
    return failure * (witnessed ? 2 : 1);
}

/** Pending authored consequence after discharge, persistent and undoable. */
class RpgMagicBacklash: object
    strength = 0
    released = 0
    roll = 0
    resolved = nil
    choice = nil
;

/** Complete authored consequence for one band. apply must handle the selected
 * branch, including injury provenance, protection, blast and required content.
 * No default silently discards a required consequence. */
class RpgMagicConsequence: object
    id = nil
    band = 1
    branch = 'physical'
    available(state, backlash) { return 'unsupported-consequence'; }
    apply(state, backlash, injury, lasting) { throw new RpgError(); }
;

/** Three-die discharge. Lasting strain affects strength but cannot be released.
 * Natural 17/18 fail; critical flags add no release multiplier. */
rpgMagicDischarge(state)
{
    if (state.pendingBacklash != nil) throw new RpgError();
    local b = new RpgMagicBacklash(); b.roll = rpgRandom.roll();
    local total = state.totalStrain();
    if (b.roll < 17 && total > b.roll) b.strength = total - b.roll;
    b.released = b.strength > state.strain ? state.strain : b.strength;
    state.strain -= b.released;
    local remaining = b.strength - b.released;
    if (remaining > 0 && state.ritual != nil)
    { local n = remaining > state.ritual.provisional ? state.ritual.provisional : remaining;
      state.ritual.provisional -= n; state.provisional -= n; b.released += n; }
    state.revision += 1;
    if (b.strength > 0) state.pendingBacklash = b;
    return b;
}

/** Apply an authored consequence once inside a gameplay transaction. Band 1
 * physical includes a trivial complication; band 5 includes a further choice. */
rpgResolveMagicBacklash(state, choice)
{
    local r = new RpgExpandedResult(); local b = state.pendingBacklash;
    if (b == nil) { r.status = 'reused'; return r; }
    local d = b.strength;
    local band = d <= 5 ? 1 : d <= 10 ? 2 : d <= 15 ? 3 : d <= 20 ? 4 : 5;
    if (choice.band != band || choice.id == nil
        || !(choice.branch == 'physical'
            || band == 2 && choice.branch == 'complication'
            || band == 3 && holds(['complication','encounter','perception'], choice.branch)
            || band == 4 && choice.branch == 'paired'))
    { r.reason = 'invalid-consequence'; return r; }
    r.reason = choice.available(state, b); if (r.reason != nil) return r;
    local injury = choice.branch != 'physical' ? 0 : band <= 2 ? (d + 1) / 2 : band == 5 ? d * 2 : d;
    local lasting = choice.branch == 'physical' && band == 4 ? 1 : 0;
    b.resolved = true; b.choice = choice.id; state.pendingBacklash = nil;
    state.lasting += lasting; rpgMagicAddStrain(state, 0);
    choice.apply(state, b, injury, lasting);
    r.status = 'resolved'; return r;
}

/** Collateral injury before protection; no internal-explosion multiplier. */
rpgMagicBlastInjury(injury, yards, cover, armor)
{
    rpgInteger(injury, 0, 2000000); rpgInteger(yards, 0, 1000000);
    rpgInteger(cover, 0, 1000000); rpgInteger(armor, 0, 1000000);
    local damage = injury / (3 * (yards < 1 ? 1 : yards)) - cover - armor;
    return damage < 0 ? 0 : damage;
}
