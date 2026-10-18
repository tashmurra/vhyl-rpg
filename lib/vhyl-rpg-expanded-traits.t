/* Include after the expanded foundation. Source: full-2008, B101; B110; B121. */

/** Pure signed percentage pricing, rounded toward positive infinity.
 * This validates arithmetic bounds, not modifier eligibility or effects. */
rpgExpandedSignedModifiedCost(base, percentages)
{
    rpgInteger(base, -1000000, 1000000);
    local percent = 100;
    foreach (local value in percentages) { rpgInteger(value, -1000, 1000); percent += value; }
    if (percent < 20) percent = 20;
    rpgInteger(percent, 20, 2000);
    if (base < 0) return -((-base * percent) / 100);
    return (base * percent + 99) / 100;
}

/** Pure percentage pricing for a positive-cost trait; ceiling, with an 80% floor.
 * Applicability and each modifier's actual effect require a separate definition. */
rpgExpandedModifiedCost(base, percentages)
{
    rpgInteger(base, 1, 1000000);
    return rpgExpandedSignedModifiedCost(base, percentages);
}

/** Pure self-control pricing for a negative base value; discard fractional magnitude.
 * The rating is independent of Will. This does not roll or resolve a trigger. */
rpgExpandedSelfControlCost(base, rating)
{
    rpgInteger(base, -1000000, -1);
    if (!holds([6, 9, 12, 15], rating)) rpgExpandedReject('self-control-rating');
    if (rating == 6) return base * 2;
    if (rating == 9) return -((-base * 3) / 2);
    if (rating == 15) return -((-base) / 2);
    return base;
}

/** An explicitly approved positive trait price specification.
 * This prices the trait; it does not implement modifier effects. */
class RpgExpandedTrait: RpgLiteTrait
    percentages = []
    approved = nil
    creationCost()
    {
        if (!self.approved) rpgExpandedReject('unapproved-trait');
        rpgInteger(self.points, 1, 10000); rpgInteger(self.level, 1, 100);
        return rpgExpandedModifiedCost(self.points * self.level, self.percentages);
    }
;

/** Approved negative price specification, using the shared character cost ledger.
 * Approval covers the authored price only, not completion of catalogue effects. */
class RpgExpandedDisadvantage: RpgLiteTrait
    percentages = []
    approved = nil
    selfControlRating = nil
    creationCost()
    {
        if (!self.approved) rpgExpandedReject('unapproved-trait');
        rpgInteger(self.points, -10000, -1); rpgInteger(self.level, 1, 100);
        local base = self.points * self.level;
        if (self.selfControlRating != nil)
        {
            /* Resolve composition/rounding from source before supporting both. */
            if (self.percentages.length() != 0)
                rpgExpandedReject('self-control-modifier-combination');
            return rpgExpandedSelfControlCost(base, self.selfControlRating);
        }
        return rpgExpandedSignedModifiedCost(base, self.percentages);
    }
;
