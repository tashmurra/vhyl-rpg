/* Include after the expanded foundation. Source: full-2008, B16 and B550. */

/** Extended whole-yard speed/range lookup, rounding up to the next row.
 * Numeric support is bounded to 100 million yards to prevent integer overflow. */
rpgExpandedRangeModifier(yards)
{
    rpgInteger(yards, 0, 100000000);
    if (yards <= 2) return 0;
    local row = 0; local factor = 1;
    while (factor <= 100000000)
    {
        foreach (local limit in [3, 5, 7, 10, 15, 20])
        {
            row += 1;
            if (yards <= limit * factor) return -row;
        }
        factor *= 10;
    }
    throw new RpgError();
}

/** Full-reference damage rows at ST 1-40 and every five thereafter through 100.
 * Intermediate scores above 40 are rejected, pending an explicit verified policy. */
rpgExpandedDamageDice(strength, swing)
{
    rpgInteger(strength, 1, 100);
    if (strength <= 20) return rpgLiteDamageDice(strength, swing);
    local rows = [
        [21,2,0,4,-1],[22,2,0,4,0],[23,2,1,4,1],[24,2,1,4,2],
        [25,2,2,5,-1],[26,2,2,5,0],[27,3,-1,5,1],[28,3,-1,5,1],
        [29,3,0,5,2],[30,3,0,5,2],[31,3,1,6,-1],[32,3,1,6,-1],
        [33,3,2,6,0],[34,3,2,6,0],[35,4,-1,6,1],[36,4,-1,6,1],
        [37,4,0,6,2],[38,4,0,6,2],[39,4,1,7,-1],[40,4,1,7,-1],
        [45,5,0,7,1],[50,5,2,8,-1],[55,6,0,8,1],[60,7,-1,9,0],
        [65,7,1,9,2],[70,8,0,10,0],[75,8,2,10,2],[80,9,0,11,0],
        [85,9,2,11,2],[90,10,0,12,0],[95,10,2,12,2],[100,11,0,13,0]];
    foreach (local row in rows)
        if (row[1] == strength) return swing ? [row[4],row[5]] : [row[2],row[3]];
    rpgExpandedReject('unsupported-strength-row'); return nil;
}
