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

/** Internal temporary requirement for composing purchased skill levels. */
class RpgExpandedTemplateSkillRequirement: object
    skill = nil
    score = 0
;

/** Combine occupational packages, B259. All outputs are freshly constructed;
 * actual secondary scores are maximized before their final costs are derived. */
rpgExpandedCombineTemplates(templates, rules, pointBudget, disadvantageLimit)
{
    if (templates.length() == 0) rpgExpandedReject('empty-template-composition');
    local result = new RpgExpandedProfile(); result.rules = rules;
    result.pointBudget = pointBudget; result.disadvantageLimit = disadvantageLimit;
    local first = true; local hp = 0; local fp = 0; local will = 0; local perception = 0;
    local speed = 0; local move = 0; local requirements = [];
    foreach (local template in templates)
    {
        if (!template.ofKind(RpgExpandedTemplate)) rpgExpandedReject('template-type');
        local source = template.create(rules);
        if (source.contributions.length() != 0 || source.languages.length() != 0
            || source.equipment.length() != 0 || source.techLevel != result.techLevel)
            rpgExpandedReject('template-composition-components');
        foreach (local training in source.skills)
        {
            local skill = training.skill;
            local wildcard = skill.ofKind(RpgExpandedSkill) && skill.wildcard;
            local score = rpgExpandedSkillLevel(source.attributeScore(skill.attribute),
                skill.difficulty, training.points, wildcard);
            if (score == nil) rpgExpandedReject('template-skill');
            local found = nil;
            foreach (local requirement in requirements)
                if (requirement.skill == skill) found = requirement;
            if (found == nil)
            {
                found = new RpgExpandedTemplateSkillRequirement(); found.skill = skill;
                found.score = score; requirements = requirements + [found];
            }
            else if (score > found.score) found.score = score;
        }
        if (first || source.st > result.st) result.st = source.st;
        if (first || source.dx > result.dx) result.dx = source.dx;
        if (first || source.iq > result.iq) result.iq = source.iq;
        if (first || source.ht > result.ht) result.ht = source.ht;
        if (source.maxHP > hp) hp = source.maxHP;
        if (source.maxEnergy > fp) fp = source.maxEnergy;
        if (source.will > will) will = source.will;
        if (source.perception > perception) perception = source.perception;
        if (source.basicSpeedQuarters() > speed) speed = source.basicSpeedQuarters();
        if (source.basicMove() > move) move = source.basicMove();
        foreach (local trait in source.traits)
        {
            local found = nil;
            foreach (local current in result.traits)
                if (current.id == trait.id && current.scope == trait.scope) found = current;
            if (found == nil) result.traits = result.traits + [trait];
            else if (trait.level > found.level) found.level = trait.level;
        }
        first = nil;
    }
    result.hpAdjustment = hp - result.st; result.fpAdjustment = fp - result.ht;
    result.willAdjustment = will - result.iq; result.perceptionAdjustment = perception - result.iq;
    result.speedQuarterAdjustment = speed - result.dx - result.ht;
    result.moveAdjustment = move - speed / 4;
    foreach (local requirement in requirements)
    {
        local skill = requirement.skill;
        local wildcard = skill.ofKind(RpgExpandedSkill) && skill.wildcard;
        local points = rpgExpandedSkillCost(skill.difficulty,
            requirement.score - result.attributeScore(skill.attribute), wildcard);
        local minimum = wildcard ? 3 : 1;
        if (points < minimum) points = minimum;
        local training = new RpgExpandedTraining(); training.skill = skill; training.points = points;
        result.skills = result.skills + [training];
    }
    try { rpgLiteValidateTraits(result); }
    catch (RpgLiteCharacterError error) { rpgExpandedReject(error.reason); }
    rpgExpandedValidateCharacter(result); return result;
}
