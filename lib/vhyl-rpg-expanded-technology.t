/* Include after the expanded foundation. Source: full-2008, B483-B485. */

/** A surviving weapon form; replacement statistics come from that form's catalogue. */
class RpgExpandedBrokenPiece: object
    form = nil
    placement = 'held'
    attackModifier = 0
    reach = nil
    damageBase = nil
    damageAdds = nil
    damageType = nil
;

class RpgExpandedBrokenWeaponResult: RpgExpandedResult
    usable = nil
    pieces = []
    retainOriginal = nil
    cuttingDamageModifier = 0
    thrustBase = nil
    thrustDamageType = nil
    reach = nil
;

/** Pure disabled/destroyed weapon assessment. No item, damage, die or clock mutation. */
rpgExpandedBrokenWeapon(state, weightHundredths, missile, family, die, reach)
{
    if (!holds(['disabled','destroyed'],state)) rpgExpandedReject('broken-weapon-state');
    rpgInteger(weightHundredths,0,100000000); rpgInteger(reach,0,1000);
    local value = new RpgExpandedBrokenWeaponResult();
    if (state == 'destroyed' || weightHundredths <= 100 || missile)
    {
        if (die != nil) rpgExpandedReject('broken-weapon-unused-die');
        value.status = 'ready'; return value;
    }
    if (!holds(['axe-mace','polearm','rapier','smallsword','spear','sword','saber','two-handed-axe-mace'],family))
    { value.reason = 'broken-weapon-analogy-required'; return value; }
    if (die == nil) { value.status = 'needs-roll'; value.reason = 'broken-weapon-die-required'; return value; }
    rpgInteger(die,1,6);
    local held = new RpgExpandedBrokenPiece(); local ground = nil;
    if (family == 'axe-mace') { if (die <= 3) held.form = 'light-club'; }
    else if (family == 'polearm')
    {
        if (die <= 2)
        { held.form = 'long-spear'; held.damageBase = 'thrust'; held.damageAdds = 2; held.damageType = 'cr'; }
        else
        {
            ground = new RpgExpandedBrokenPiece(); ground.placement = 'ground';
            held.form = die <= 4 ? 'quarterstaff' : 'light-club';
            ground.form = die <= 4 ? 'axe' : 'great-axe';
            ground.attackModifier = die <= 4 ? -4 : -2; ground.reach = die <= 4 ? 1 : 2;
        }
    }
    else if (family == 'rapier' || family == 'smallsword')
    {
        if (die <= 3) { held.form = family == 'rapier' ? 'smallsword' : 'dagger'; held.damageType = 'imp'; }
    }
    else if (family == 'spear')
    {
        held.form = die <= 3 ? 'quarterstaff' : 'baton';
        if (die >= 4)
        { ground = new RpgExpandedBrokenPiece(); ground.placement = 'ground'; ground.form = 'spear'; ground.reach = 1; }
    }
    else if (family == 'sword' || family == 'saber')
    {
        if (die <= 3)
        {
            held.form = 'original'; value.retainOriginal = true; value.cuttingDamageModifier = -2;
            value.thrustBase = 'thrust'; value.thrustDamageType = 'cr'; value.reach = reach == 2 ? 1 : reach;
        }
    }
    else
    {
        held.form = die <= 3 ? 'quarterstaff' : 'light-club';
        if (die >= 4)
        {
            ground = new RpgExpandedBrokenPiece(); ground.placement = 'ground';
            ground.form = 'axe'; ground.attackModifier = -4; ground.reach = 1;
        }
    }
    if (held.form != nil) { value.usable = true; value.pieces = [held]; }
    if (ground != nil) value.pieces = value.pieces + [ground];
    value.status = 'ready'; return value;
}

/** B483 detailed capacity calculation, rounded up using exact integer arithmetic.
 * Weight is in hundredths of a pound; the bound keeps cubic products in range. */
rpgExpandedObjectCapacity(weightHundredths, construction)
{
    rpgInteger(weightHundredths,1,1000000);
    if (!holds(['unliving','homogenous'],construction)) rpgExpandedReject('object-capacity-construction');
    local factor = construction == 'unliving' ? 4 : 8;
    local target = weightHundredths * factor * factor * factor;
    local low = 1; local high = 173;
    while (low < high)
    {
        local middle = (low + high) / 2;
        if (middle * middle * middle * 100 >= target) high = middle;
        else low = middle + 1;
    }
    return low;
}

class RpgExpandedObjectInjuryResult: RpgExpandedResult
    remaining = 0
    destructionThresholds = []
    automaticDestruction = nil
    stressChecksRequired = nil
    reducedEffectivenessEligible = nil
    majorDamage = nil
;

/** Assess final object injury, after material/type effects, without choosing subsystem failures. */
rpgExpandedObjectInjury(capacity, priorInjury, injury)
{
    rpgInteger(capacity,1,1000000); rpgInteger(priorInjury,0,100000000); rpgInteger(injury,0,100000000);
    local value = new RpgExpandedObjectInjuryResult();
    local before = capacity - priorInjury; value.remaining = before - injury;
    for (local multiple = 1; multiple <= 4; multiple += 1)
        if (before > -multiple * capacity && value.remaining <= -multiple * capacity)
            value.destructionThresholds = value.destructionThresholds + [multiple];
    value.automaticDestruction = value.remaining <= -5 * capacity;
    value.stressChecksRequired = value.remaining <= 0;
    value.reducedEffectivenessEligible = value.remaining * 3 < capacity;
    value.majorDamage = injury * 2 > capacity;
    value.status = 'ready'; return value;
}
