/* Include after the expanded foundation. Source: full-2008, B15-B16 and B550. */

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

/** Full-reference damage rows, with B15's full-ten-point progression above 100.
 * Missing intermediate rows between 40 and 100 remain explicitly unsupported. */
rpgExpandedDamageDice(strength, swing)
{
    rpgInteger(strength, 1, 1000);
    if (strength > 100) return [(swing ? 13 : 11) + (strength - 100) / 10, 0];
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

/** B550 size modifier. Measure the relevant dimension in thirtieths of an inch
 * to preserve every printed fractional-inch boundary without floating point.
 * shape is 0 for ordinary, 1 elongated box, or 2 box/sphere/blob. */
rpgExpandedSizeModifier(dimensionTicks, shape)
{
    rpgInteger(dimensionTicks, 6, 1000000000); rpgInteger(shape, 0, 2);
    local thresholds = [6,10,15,20,30,45,60,90,150,240,360,540,720,1080,1620,2160];
    for (local index = 1; index <= thresholds.length(); index += 1)
        if (dimensionTicks <= thresholds[index]) return index - 16 + shape;
    /* All larger printed thresholds are whole yards. Round up before lookup. */
    return -rpgExpandedRangeModifier((dimensionTicks + 1079) / 1080) + shape;
}

/** B550 speed/range combination, with explicit author selection of speed use. */
rpgExpandedSpeedRangeModifier(yards, yardsPerSecond, includeSpeed)
{
    rpgInteger(yards, 0, 100000000); rpgInteger(yardsPerSecond, 0, 100000000);
    if (!includeSpeed) return rpgExpandedRangeModifier(yards);
    if (yardsPerSecond > 100000000 - yards) rpgExpandedReject('speed-range-limit');
    return rpgExpandedRangeModifier(yards + yardsPerSecond);
}

/** Authored task-specific equipment adequacy, B345. It describes the tools
 * actually available for this operation, not a permanent skill or item bonus. */
class RpgExpandedEquipmentAssessment: object
    quality = 'basic'
    allowWithoutEquipment = nil
    techLevel = nil
    missingItems = 0
    damagePenalty = 0
    assess(skill)
    {
        if (skill == nil || !skill.ofKind(RpgSkill)) rpgExpandedReject('equipment-skill-required');
        if (!holds(['none','improvised','basic','good','fine','best'], self.quality))
            rpgExpandedReject('equipment-quality');
        rpgInteger(self.missingItems, 0, 1000); rpgInteger(self.damagePenalty, 0, 3);
        if (self.techLevel != nil) rpgInteger(self.techLevel, 0, 12);
        local value = new RpgExpandedResult();
        local technological = skill.ofKind(RpgLiteSkill) && skill.techLevel != nil;
        if (self.quality == 'none' || self.quality == 'improvised')
        {
            if (self.missingItems != 0 || self.damagePenalty != 0)
                rpgExpandedReject('equipment-condition-inapplicable');
            if (self.quality == 'none' && !self.allowWithoutEquipment)
            { value.reason = 'equipment-required'; return value; }
            value.modifier = self.quality == 'none' ? (technological ? -10 : -5)
                : (technological ? -5 : -2);
        }
        else
        {
            local bonus = self.quality == 'good' ? 1 : self.quality == 'fine' ? 2 : 0;
            if (self.quality == 'best')
            {
                if (self.techLevel == nil) rpgExpandedReject('equipment-technology-required');
                bonus = self.techLevel / 2; if (bonus < 2) bonus = 2;
            }
            value.modifier = bonus - self.missingItems - self.damagePenalty;
        }
        value.status = 'ready'; return value;
    }
;

modify RpgLiteContext
    equipmentAssessment = nil
    equipmentUseModifier(profile)
    {
        if (self.equipmentAssessment == nil) return 0;
        if (!self.equipmentAssessment.ofKind(RpgExpandedEquipmentAssessment))
            rpgExpandedReject('equipment-assessment');
        local value = self.equipmentAssessment.assess(self.skill);
        return value.status == 'ready' ? value.modifier : nil;
    }
    unavailableReason(profile)
    {
        if (self.equipmentAssessment != nil)
        {
            if (!self.equipmentAssessment.ofKind(RpgExpandedEquipmentAssessment))
                rpgExpandedReject('equipment-assessment');
            local value = self.equipmentAssessment.assess(self.skill);
            if (value.status != 'ready') return value.reason;
        }
        return inherited(profile);
    }
;
