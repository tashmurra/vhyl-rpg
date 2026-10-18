/* Include after expanded characters and skills. Source: full-2008, B258-B259.
 * Only character packages are implemented; ancestry cost exceptions are pending. */

/** Character package factory. Every call creates fresh owned training and traits.
 * Skill rows are [definition, points]; trait rows are [Lite ID, level, scope]. */
class RpgExpandedTemplate: object
    st = 10
    dx = 10
    iq = 10
    ht = 10
    hpAdjustment = 0
    fpAdjustment = 0
    willAdjustment = 0
    perceptionAdjustment = 0
    speedQuarterAdjustment = 0
    moveAdjustment = 0
    skillRows = []
    traitRows = []
    pointBudget = 100
    disadvantageLimit = 50
    create(rules)
    {
        local p = new RpgExpandedProfile(); p.rules = rules;
        p.st = self.st; p.dx = self.dx; p.iq = self.iq; p.ht = self.ht;
        p.hpAdjustment = self.hpAdjustment; p.fpAdjustment = self.fpAdjustment;
        p.willAdjustment = self.willAdjustment; p.perceptionAdjustment = self.perceptionAdjustment;
        p.speedQuarterAdjustment = self.speedQuarterAdjustment; p.moveAdjustment = self.moveAdjustment;
        p.pointBudget = self.pointBudget; p.disadvantageLimit = self.disadvantageLimit;
        foreach (local row in self.skillRows)
        {
            if (row.length() != 2 || row[1] == nil || !row[1].ofKind(RpgSkill))
                rpgExpandedReject('template-skill');
            rpgInteger(row[2], 1, 10000);
            local training = new RpgExpandedTraining(); training.skill = row[1]; training.points = row[2];
            p.skills = p.skills + [training];
        }
        foreach (local row in self.traitRows)
        {
            if (row.length() != 3) rpgExpandedReject('template-trait');
            p.traits = p.traits + [rpgLiteMakeTrait(row[1],row[2],row[3])];
        }
        rpgExpandedValidateCharacter(p); return p;
    }
;
