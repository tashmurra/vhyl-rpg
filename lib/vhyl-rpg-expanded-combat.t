/* Include after expanded foundation. Sources: full-2008, B373-B375.
 * Partial rapid-fire assessments; no automatic attack or injury dispatch. */

/** Ordinary one-target burst assessment and supplied-roll Dodge result. */
class RpgExpandedRapidFireResult: RpgExpandedResult
    shots = 0
    hits = 0
    avoided = 0
    remaining = 0
;

/** Attack bonus from actual shots fired, including the printed doubling extension. */
rpgExpandedRapidFireBonus(shots)
{
    rpgInteger(shots,1,1000000);
    if (shots <= 4) return 0;
    if (shots <= 8) return 1;
    if (shots <= 12) return 2;
    if (shots <= 16) return 3;
    if (shots <= 24) return 4;
    if (shots <= 49) return 5;
    local boundary = 100; local bonus = 6;
    while (shots >= boundary) { bonus += 1; boundary *= 2; }
    return bonus;
}

/** Declare one ordinary burst before an attack roll; this never spends ammunition. */
rpgExpandedAssessBurst(shots, rate, loaded, recoil)
{
    rpgInteger(shots,1,1000000); rpgInteger(rate,1,1000000);
    rpgInteger(loaded,0,1000000); rpgInteger(recoil,1,1000);
    local value = new RpgExpandedRapidFireResult();
    if (shots > rate) { value.reason = 'burst-rate-exceeded'; return value; }
    if (shots > loaded) { value.reason = 'burst-ammunition-insufficient'; return value; }
    value.shots = shots; value.modifier = rpgExpandedRapidFireBonus(shots);
    value.status = 'ready'; return value;
}

/** Potential hits after a successful attack, before defense; not for failed attacks. */
rpgExpandedRapidFireHits(shots, recoil, successMargin)
{
    rpgInteger(shots,1,1000000); rpgInteger(recoil,1,1000);
    rpgInteger(successMargin,-1,1000000);
    /* Automatic success at score three on a four still supplies the first hit. */
    local margin = successMargin < 0 ? 0 : successMargin;
    local hits = 1 + margin / recoil;
    return hits > shots ? shots : hits;
}

/** Assess one already-eligible Dodge using supplied dice, without drawing randomness. */
rpgExpandedRapidFireDodge(hits, score, roll)
{
    rpgInteger(hits,1,1000000); rpgInteger(score,-1000,1000); rpgInteger(roll,3,18);
    local value = new RpgExpandedRapidFireResult(); value.hits = hits;
    value.check = rpgCheck(score < 3 ? 3 : score,roll);
    value.check.score = score; value.check.margin = score - roll;
    value.check.achieved = roll <= 4 || roll < 17 && roll <= score;
    value.check.outcome = value.check.achieved ? 'success' : 'setback';
    if (value.check.achieved)
    {
        value.avoided = value.check.critical == 'success' ? hits : 1 + value.check.margin;
        if (value.avoided > hits) value.avoided = hits;
    }
    value.remaining = hits - value.avoided; value.status = 'ready'; return value;
}
