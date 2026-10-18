/* Include after expanded characters and skills. Source: full-2008, B258-B259.
 * Only character packages are implemented; ancestry cost exceptions are pending. */

/** Shared catalogue rows keep their original three fields. A fourth field is
 * an explicit self-control purchase resolved by the installed trait module. */
rpgExpandedTemplateTrait(row)
{
    if (row.length() == 3) return rpgLiteMakeTrait(row[1],row[2],row[3]);
    if (row.length() == 4) return rpgExpandedTemplateTraits.rated(row[1],row[2],row[3],row[4]);
    rpgExpandedReject('template-trait');
}
modify RpgLiteTrait
    templatePurchaseKind = 'shared-catalogue'
;

/** Character package factory. Every call creates fresh owned training and traits.
 * Skill rows are [definition, points]; trait rows are [Lite ID, level, scope], optionally followed by a supported rating. */
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
    choiceGroups = []
    campaignTL = 3
    techLevel = nil
    pointBudget = 100
    disadvantageLimit = 50
    create(rules)
    {
        if (self.choiceGroups.length() != 0) rpgExpandedReject('template-unresolved-choices');
        local p = new RpgExpandedProfile(); p.rules = rules;
        p.campaignTL = self.campaignTL;
        p.techLevel = self.techLevel == nil ? self.campaignTL : self.techLevel;
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
            p.traits = p.traits + [rpgExpandedTemplateTrait(row)];
        }
        try { rpgLiteValidateTraits(p); }
        catch (RpgLiteCharacterError error) { rpgExpandedReject(error.reason); }
        rpgExpandedValidateCharacter(p); return p;
    }
;

/** Internal temporary requirement for composing purchased skill levels. */
class RpgExpandedTemplateSkillRequirement: object
    skill = nil
    score = 0
;

/** Reconstruct supported purchases rather than sharing intermediate profile state. */
rpgExpandedCopyTemplateTrait(trait)
{
    if (trait == nil || !trait.ofKind(RpgLiteTrait) || trait.labelId == nil)
        rpgExpandedReject('template-trait-copy-definition');
    if (trait.nextCheck != 0) rpgExpandedReject('template-trait-runtime-state');
    local copy = trait.templatePurchaseKind == 'shared-catalogue'
        ? rpgLiteMakeTrait(trait.labelId,trait.level,trait.scope)
        : rpgExpandedTemplateTraits.rated(trait.labelId,trait.level,trait.scope,trait.selfControlNumber());
    if (copy.templatePurchaseKind != trait.templatePurchaseKind || copy.id != trait.id
        || copy.controlled != trait.controlled || copy.creationCost() != trait.creationCost())
        rpgExpandedReject('template-trait-copy-purchase');
    copy.active = trait.active; copy.mitigated = trait.mitigated; copy.skills = trait.skills;
    return copy;
}

/** Explicit choices for one occupational package in a composition. */
class RpgExpandedTemplateSelection: object
    template = nil
    selections = []
    create(rules)
    {
        if (self.template == nil || !self.template.ofKind(RpgExpandedTemplate))
            rpgExpandedReject('template-selection-definition');
        return self.template.createSelected(rules,self.selections);
    }
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
        if (template == nil || !template.ofKind(RpgExpandedTemplate)
            && !template.ofKind(RpgExpandedTemplateSelection)) rpgExpandedReject('template-type');
        local source = template.create(rules);
        local definition = template.ofKind(RpgExpandedTemplateSelection) ? template.template : template;
        result.templateSelections = result.templateSelections + [[definition,source.templateChoices]];
        if (source.contributions.length() != 0 || source.languages.length() != 0
            || source.equipment.length() != 0)
            rpgExpandedReject('template-composition-components');
        if (first)
        { result.campaignTL = source.campaignTL; result.techLevel = source.techLevel; }
        else if (source.campaignTL != result.campaignTL || source.techLevel != result.techLevel)
            rpgExpandedReject('template-technology-conflict');
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
            local purchase = rpgExpandedCopyTemplateTrait(trait);
            local found = nil;
            foreach (local current in result.traits)
                if (current.id == trait.id && current.scope == trait.scope) found = current;
            if (found == nil) result.traits = result.traits + [purchase];
            else
            {
                if (trait.templatePurchaseKind != found.templatePurchaseKind
                    || trait.controlled != found.controlled
                    || trait.controlled && trait.selfControlNumber() != found.selfControlNumber())
                    rpgExpandedReject('template-trait-purchase-conflict');
                if (trait.active != found.active || trait.mitigated != found.mitigated
                    || trait.skills.length() != found.skills.length())
                    rpgExpandedReject('template-trait-state-conflict');
                for (local i = 1; i <= trait.skills.length(); i += 1)
                    if (trait.skills[i] != found.skills[i])
                        rpgExpandedReject('template-trait-state-conflict');
                if (trait.level > found.level) found.level = trait.level;
            }
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

/** A concrete selectable component bundle; rows follow the template factory. */
class RpgExpandedTemplateOption: object
    id = nil
    eligible = true
    skillRows = []
    traitRows = []
    stChange = 0
    dxChange = 0
    iqChange = 0
    htChange = 0
    hpChange = 0
    fpChange = 0
    willChange = 0
    perceptionChange = 0
    speedQuarterChange = 0
    moveChange = 0
    changes()
    {
        local values = [self.stChange,self.dxChange,self.iqChange,self.htChange,
            self.hpChange,self.fpChange,self.willChange,self.perceptionChange,
            self.speedQuarterChange,self.moveChange];
        foreach (local value in values) rpgInteger(value, -1000, 1000);
        return values;
    }
    cost()
    {
        local total = 0; local values = self.changes();
        local prices = [10,20,20,10,2,3,5,5,5,5];
        for (local index = 1; index <= 10; index += 1) total += values[index] * prices[index];
        foreach (local row in self.skillRows)
        {
            if (row.length() != 2 || row[1] == nil || !row[1].ofKind(RpgSkill))
                rpgExpandedReject('template-skill');
            rpgInteger(row[2], 1, 10000); total += row[2];
        }
        foreach (local row in self.traitRows)
        {
            total += rpgExpandedTemplateTrait(row).creationCost();
        }
        rpgInteger(total, -1000000, 1000000); return total;
    }
;

/** Count and signed point bounds for one authored choice group. */
class RpgExpandedTemplateChoice: object
    id = nil
    options = []
    minimumChoices = 1
    maximumChoices = 1
    minimumPoints = nil
    maximumPoints = nil
;

modify RpgExpandedProfile
    templateChoices = []
    templateSelections = []
;

modify RpgExpandedTemplate
    /** selections: one [group ID, [option IDs]] row for every group. */
    createSelected(rules, selections)
    {
        if (selections.length() != self.choiceGroups.length())
            rpgExpandedReject('template-choice-groups');
        local selectedGroups = [];
        foreach (local row in selections)
        {
            if (row.length() != 2 || holds(selectedGroups,row[1]))
                rpgExpandedReject('template-choice-groups');
            selectedGroups = selectedGroups + [row[1]];
        }
        local skillRows = self.skillRows; local traitRows = self.traitRows;
        local ids = []; local receipt = []; local changes = [0,0,0,0,0,0,0,0,0,0];
        foreach (local group in self.choiceGroups)
        {
            if (!group.ofKind(RpgExpandedTemplateChoice) || group.id == nil || holds(ids,group.id))
                rpgExpandedReject('template-choice-definition');
            ids = ids + [group.id];
            rpgInteger(group.minimumChoices, 0, 1000);
            rpgInteger(group.maximumChoices, group.minimumChoices, 1000);
            if (group.minimumPoints != nil) rpgInteger(group.minimumPoints, -1000000, 1000000);
            if (group.maximumPoints != nil) rpgInteger(group.maximumPoints, -1000000, 1000000);
            if (group.minimumPoints != nil && group.maximumPoints != nil
                && group.minimumPoints > group.maximumPoints)
                rpgExpandedReject('template-choice-definition');
            local chosen = nil;
            foreach (local row in selections) if (row[1] == group.id) chosen = row[2];
            if (chosen == nil) rpgExpandedReject('template-choice-groups');
            if (chosen.length() < group.minimumChoices || chosen.length() > group.maximumChoices)
                rpgExpandedReject('template-choice-count');
            local optionIds = [];
            foreach (local option in group.options)
            {
                if (!option.ofKind(RpgExpandedTemplateOption) || option.id == nil || holds(optionIds,option.id))
                    rpgExpandedReject('template-choice-definition');
                optionIds = optionIds + [option.id]; option.cost();
            }
            local used = []; local total = 0;
            foreach (local id in chosen)
            {
                if (holds(used,id) || !holds(optionIds,id)) rpgExpandedReject('template-choice-option');
                used = used + [id];
                foreach (local option in group.options)
                    if (option.id == id)
                    {
                        if (!option.eligible) rpgExpandedReject('template-choice-ineligible');
                        total += option.cost(); skillRows = skillRows + option.skillRows;
                        traitRows = traitRows + option.traitRows;
                        local values = option.changes(); local combined = [];
                        for (local index = 1; index <= 10; index += 1)
                            combined = combined + [changes[index] + values[index]];
                        changes = combined;
                        receipt = receipt + [[group.id,option.id]];
                    }
            }
            if (group.minimumPoints != nil && total < group.minimumPoints
                || group.maximumPoints != nil && total > group.maximumPoints)
                rpgExpandedReject('template-choice-points');
        }
        local resolved = new RpgExpandedTemplate();
        resolved.st = self.st + changes[1]; resolved.dx = self.dx + changes[2];
        resolved.iq = self.iq + changes[3]; resolved.ht = self.ht + changes[4];
        resolved.hpAdjustment = self.hpAdjustment + changes[5];
        resolved.fpAdjustment = self.fpAdjustment + changes[6];
        resolved.willAdjustment = self.willAdjustment + changes[7];
        resolved.perceptionAdjustment = self.perceptionAdjustment + changes[8];
        resolved.speedQuarterAdjustment = self.speedQuarterAdjustment + changes[9];
        resolved.moveAdjustment = self.moveAdjustment + changes[10];
        resolved.campaignTL = self.campaignTL; resolved.techLevel = self.techLevel;
        resolved.pointBudget = self.pointBudget; resolved.disadvantageLimit = self.disadvantageLimit;
        resolved.skillRows = skillRows; resolved.traitRows = traitRows;
        local profile = resolved.create(rules); profile.templateChoices = receipt; return profile;
    }
;
