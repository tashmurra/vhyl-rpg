/* Quantities retain their own exact-success rules. Host units: yards, pounds,
 * Fahrenheit differences, HP; hundredths of a pound for mass. */

/** Explicit bounded arithmetic, never silent saturation of declared scope. */
rpgMagicPowerOf(base, exponent)
{
    rpgInteger(exponent, 0, 30); local n = 1;
    for (local i = 0; i < exponent; i++)
    { if (n > 1000000000 / base) rpgExpandedReject('magic-scale-overflow'); n *= base; }
    return n;
}

/** Duration ceiling in seconds; -1 denotes an eligible permanent effect. */
rpgMagicDuration(margin, critical)
{
    rpgInteger(margin, 0, 1000000);
    return critical || margin >= 8 ? -1 : margin >= 6 ? 604800
        : margin >= 4 ? 86400 : margin >= 2 ? 1800 : 30;
}

/** Minimum duration margin. Permanence is still operation-specific permission. */
rpgMagicDurationMargin(seconds)
{
    if (seconds == -1) return 8;
    rpgInteger(seconds, 0, 604800);
    return seconds <= 30 ? 0 : seconds <= 1800 ? 2 : seconds <= 86400 ? 4 : 6;
}

/** Mass ceiling in hundredths of pounds. Explicit zero rows take precedence. */
rpgMagicMass(margin, created, special)
{
    rpgInteger(margin, 0, 7);
    if (special)
    {
        if (margin < 2) return 0;
        return [200,1000,2000,10000][margin > 5 ? 4 : margin - 1];
    }
    return rpgMagicPowerOf(10, margin) * (created ? 10 : 100);
}

/** Smallest audited mass row that covers the entire target. */
rpgMagicMassMargin(weight, created, special)
{
    rpgInteger(weight, 0, 1000000000);
    for (local n = 0; n <= 7; n++)
        if (rpgMagicMass(n, created, special) >= weight) return n;
    rpgExpandedReject('magic-mass-unsupported'); return 0;
}

/** General selection: touch, nearby, vicinity, selected vicinity/one seen, sensed. */
rpgMagicReachMargin(selection, yards, visible, sensed)
{
    rpgInteger(yards, 0, 1000000);
    if (selection == 'touch' && yards == 0) return 0;
    if (selection == 'one' && yards <= 2 && sensed) return 2;
    if (selection == 'vicinity' && yards <= 15 && visible) return 3;
    if (selection == 'selected' && yards <= 15 && visible || selection == 'one' && visible) return 4;
    if (selection == 'sensed' && sensed) return 5;
    rpgExpandedReject('magic-reach-unsupported'); return 0;
}

/** Space reach is independent of area; familiarity is a validated authored fact. */
rpgMagicSpaceMargin(familiarity)
{
    if (familiarity == 'visible') return 0;
    if (familiarity == 'very-familiar') return 2;
    if (familiarity == 'familiar') return 3;
    if (familiarity == 'described') return 4;
    if (familiarity == 'world') return 5;
    rpgExpandedReject('magic-destination-unknown'); return 0;
}

/** Damage dice before damage-type adjustments; never grants an operation. */
rpgMagicDamageDice(domain, rank, margin, lifeDirect)
{
    rpgInteger(rank, 1, 5); rpgInteger(margin, 0, 1000);
    local n = margin < 1 ? 1 : margin;
    if (lifeDirect) return n;
    local table = domain == rpgMagicChance ? [0,0,0,4,5]
        : domain == rpgMagicEnergy ? [0,1,2,3,4]
        : domain == rpgMagicLife ? [0,3,3,3,3] : [0,0,1,2,3];
    return n * table[rank];
}

/** Bounded damage evaluation; the specific direct-life effect is 1d-2/success. */
rpgMagicRollDamage(dice, kind, lifeDirect)
{
    rpgInteger(dice, 0, 5000); local total = 0;
    for (local i = 0; i < dice; i++) total += rpgRandom.die();
    total -= dice * (lifeDirect ? 2 : kind == 'cr' ? 0 : 1);
    return total < 0 ? 0 : total;
}

/** Trait cost uses host prices. Negative traits do not award advancement points. */
rpgMagicTraitMargin(points)
{ rpgInteger(points, -10000, 10000); return ((points < 0 ? -points : points) + 9) / 10; }

/** Boundary sight differs from the opposed crossing procedure. */
rpgMagicSightMargin(barrier)
{ rpgInteger(barrier, 0, 18); return barrier <= 7 ? 0 : (barrier - 3) / 2; }

/** Temperature difference in Fahrenheit; zero margin is the explicit five-degree row. */
rpgMagicTemperature(margin)
{ rpgInteger(margin,0,27); return 5 * rpgMagicPowerOf(2,margin); }
