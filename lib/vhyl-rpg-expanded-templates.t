/* Include after expanded characters and skills. Source: full-2008, B258-B259.
 * Occupational packages and partial ancestry score/trait composition. */

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
        local profile = self.assembleProfile(rules);
        try { rpgLiteValidateTraits(profile); }
        catch (RpgLiteCharacterError error) { rpgExpandedReject(error.reason); }
        rpgExpandedValidateCharacter(profile); return profile;
    }
    /** Internal construction stage; callers must validate the complete character. */
    assembleProfile(rules)
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
        return p;
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
    assembleProfile(rules)
    {
        if (self.template == nil || !self.template.ofKind(RpgExpandedTemplate))
            rpgExpandedReject('template-selection-definition');
        return self.template.assembleSelectedProfile(rules,self.selections);
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
        if (source.ancestryScores != nil || source.contributions.length() != 0 || source.languages.length() != 0
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
        local profile = self.assembleSelectedProfile(rules,selections);
        try { rpgLiteValidateTraits(profile); }
        catch (RpgLiteCharacterError error) { rpgExpandedReject(error.reason); }
        rpgExpandedValidateCharacter(profile); return profile;
    }
    /** Internal selection stage; retains option gates but defers character validation. */
    assembleSelectedProfile(rules, selections)
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
        local profile = resolved.assembleProfile(rules); profile.templateChoices = receipt; return profile;
    }
;

/** Personal changes to an occupational package, full-2008 B258-B259.
 * Creates a fresh character; never edits an existing or finalized profile. */
class RpgExpandedTemplateCustomization: object
    template = nil
    selections = []
    additions = nil
    removeTraits = []
    removeSkills = []
    approved = nil
    evidence = nil
    create(rules)
    {
        local profile = self.assembleProfile(rules);
        rpgExpandedValidateCharacter(profile); return profile;
    }
    /** Internal construction stage used before ancestry is added. */
    assembleProfile(rules)
    {
        if (self.template == nil || !self.template.ofKind(RpgExpandedTemplate)
            || self.additions == nil || !self.additions.ofKind(RpgExpandedTemplateOption))
            rpgExpandedReject('template-customization-definition');
        if (!self.approved || self.evidence == nil || self.evidence == '')
            rpgExpandedReject('template-customization-approval');
        if (!self.additions.eligible) rpgExpandedReject('template-choice-ineligible');
        self.additions.cost();
        local profile = self.template.assembleSelectedProfile(rules,self.selections);
        foreach (local row in self.removeTraits)
        {
            if (row.length() != 2) rpgExpandedReject('template-customization-trait');
            local retained = []; local count = 0;
            foreach (local trait in profile.traits)
            {
                if (trait.id == row[1] && trait.scope == row[2]) count += 1;
                else retained = retained + [trait];
            }
            if (count != 1) rpgExpandedReject('template-customization-trait');
            profile.traits = retained;
        }
        foreach (local skill in self.removeSkills)
        {
            local retained = []; local count = 0;
            foreach (local training in profile.skills)
            {
                if (training.skill == skill) count += 1;
                else retained = retained + [training];
            }
            if (count != 1) rpgExpandedReject('template-customization-skill');
            profile.skills = retained;
        }
        local changes = self.additions.changes();
        profile.st += changes[1]; profile.dx += changes[2];
        profile.iq += changes[3]; profile.ht += changes[4];
        profile.hpAdjustment += changes[5]; profile.fpAdjustment += changes[6];
        profile.willAdjustment += changes[7]; profile.perceptionAdjustment += changes[8];
        profile.speedQuarterAdjustment += changes[9]; profile.moveAdjustment += changes[10];
        local skills = [];
        foreach (local row in self.additions.skillRows)
        {
            if (holds(skills,row[1])) rpgExpandedReject('template-customization-duplicate-skill');
            skills = skills + [row[1]];
            local found = nil;
            foreach (local training in profile.skills) if (training.skill == row[1]) found = training;
            if (found == nil)
            {
                found = new RpgExpandedTraining(); found.skill = row[1]; found.points = 0;
                profile.skills = profile.skills + [found];
            }
            found.points += row[2]; rpgInteger(found.points,1,10000);
        }
        foreach (local row in self.additions.traitRows)
            profile.traits = profile.traits + [rpgExpandedTemplateTrait(row)];
        return profile;
    }
;

/** Zero-cost ancestry prohibitions, full-2008 B261 and B452. */
class RpgExpandedTabooTraits: RpgExpandedContribution
    traitIds = []
    skills = []
    attributeRanges = []
    approved = nil
    evidence = nil
    validateDefinition(profile)
    {
        if (self.owner != profile || self.id == nil || !self.approved
            || self.evidence == nil || self.evidence == '') rpgExpandedReject('taboo-definition');
        local ids = [];
        foreach (local id in self.traitIds)
        {
            if (id == nil || id == '' || holds(ids,id)) rpgExpandedReject('taboo-definition');
            ids = ids + [id];
        }
        local seen = [];
        foreach (local skill in self.skills)
        {
            if (skill == nil || !skill.ofKind(RpgSkill) || holds(seen,skill)) rpgExpandedReject('taboo-definition');
            seen = seen + [skill];
        }
        foreach (local row in self.attributeRanges)
        {
            if (row.length() != 3 || !holds([rpgST,rpgDX,rpgIQ,rpgHT,rpgWill,rpgPerception],row[1]))
                rpgExpandedReject('taboo-definition');
            rpgInteger(row[2],1,1000); rpgInteger(row[3],row[2],1000);
        }
        return nil;
    }
    attributeReason(attribute,score)
    {
        foreach (local row in self.attributeRanges)
            if (row[1] == attribute && score >= row[2] && score <= row[3]) return 'taboo-attribute';
        return nil;
    }
    validate(profile)
    {
        self.validateDefinition(profile);
        foreach (local trait in profile.traits)
            if (holds(self.traitIds,trait.id)) rpgExpandedReject('taboo-trait');
        foreach (local training in profile.skills)
            if (training.points > 0 && holds(self.skills,training.skill)) rpgExpandedReject('taboo-skill');
        foreach (local attribute in [rpgST,rpgDX,rpgIQ,rpgHT,rpgWill,rpgPerception])
        {
            local reason = self.attributeReason(attribute,profile.attributeScore(attribute));
            if (reason != nil) rpgExpandedReject(reason);
        }
        return nil;
    }
    amounts(profile) { self.validate(profile); return []; }
;
modify RpgExpandedProfile
    socialSkillLearningReason(skill)
    {
        local reason = inherited(skill); if (reason != nil) return reason;
        foreach (local contribution in self.contributions)
            if (contribution.ofKind(RpgExpandedTabooTraits))
            {
                contribution.validateDefinition(self);
                if (holds(contribution.skills,skill)) return 'taboo-skill';
            }
        return nil;
    }
    developmentOfferReason(offer)
    {
        local reason = inherited(offer); if (reason != nil) return reason;
        foreach (local contribution in self.contributions)
            if (contribution.ofKind(RpgExpandedTabooTraits))
            {
                contribution.validateDefinition(self);
                if (offer.kind == 'trait' && offer.trait != nil && holds(contribution.traitIds,offer.trait.id))
                    return 'taboo-trait';
                if (offer.kind == 'attribute')
                {
                    reason = contribution.attributeReason(offer.attribute,offer.target);
                    if (reason != nil) return reason;
                    if (offer.attribute == rpgIQ)
                    {
                        local delta = offer.target - self.iq;
                        reason = contribution.attributeReason(rpgWill,self.will + delta);
                        if (reason == nil) reason = contribution.attributeReason(rpgPerception,self.perception + delta);
                        if (reason != nil) return reason;
                    }
                }
            }
        return nil;
    }
;


/** Ancestry score modifiers only; traits and skills require their own origin rules. */
class RpgExpandedAncestryScoreTemplate: RpgExpandedTemplateOption
    supportsTraits = nil
    supportsSkills = nil
    tabooTraitIds = []
    tabooSkills = []
    tabooAttributeRanges = []
    cosmeticFeatures = []
    skillBonusRows = []
    nonhuman = nil
    approved = nil
    evidence = nil
    validate()
    {
        if (self.id == nil || self.id == '' || !self.approved || self.evidence == nil || self.evidence == ''
            || !self.eligible || !self.supportsSkills && self.skillRows.length() != 0 || !self.supportsTraits && self.traitRows.length() != 0)
            rpgExpandedReject('ancestry-score-definition');
        foreach (local feature in self.cosmeticFeatures)
            if (feature == nil || feature == '') rpgExpandedReject('ancestry-feature-definition');
        self.changes(); return nil;
    }
;

/** Supported mandatory trait purchases plus ancestry score modifiers. */
class RpgExpandedAncestryTemplate: RpgExpandedAncestryScoreTemplate
    supportsTraits = true
    supportsSkills = true
;

/** B452 single-skill bonuses; ancestry groups and penalties are separate rules. */
class RpgExpandedAncestrySkillBonuses: RpgExpandedContribution
    id = 'ancestry-skill-bonuses'
    receipt = nil
    rows = []
    validate(profile)
    {
        if (self.owner != profile || self.receipt == nil || profile.ancestryScores != self.receipt
            || self.receipt.skillBonuses != self) rpgExpandedReject('ancestry-skill-bonus-ownership');
        self.receipt.validate(profile); return nil;
    }
    amounts(profile)
    {
        self.validate(profile); local result = [];
        foreach (local row in self.rows) result = result + [row[2] * 2];
        return result;
    }
;

/** Author-approved complete omission; partial or modified replacements are separate. */
class RpgExpandedAncestryOmission: object
    id = nil
    traitId = nil
    scope = nil
    approved = nil
    evidence = nil
;
class RpgExpandedAncestryOmissionAccounting: RpgExpandedContribution
    id = 'ancestry-omissions'
    receipt = nil
    validate(profile)
    {
        if (self.owner != profile || self.receipt == nil || self.receipt != profile.ancestryScores
            || self.receipt.omissionAccounting != self) rpgExpandedReject('ancestry-omission-accounting');
        self.receipt.validate(profile); return nil;
    }
    amounts(profile)
    {
        self.validate(profile); local amounts = [];
        foreach (local omission in self.receipt.omissions) amounts = amounts + [omission[4],-omission[4]];
        return amounts;
    }
;

/** Owned immutable ancestry score origins; later personal advancement changes totals. */
class RpgExpandedAncestryScores: object
    owner = nil
    nonhuman = nil
    boundNonhuman = nil
    origins = []
    changes = []
    boundOrigins = []
    boundChanges = []
    traits = []
    traitOrigins = []
    boundTraits = []
    decisions = []
    boundDecisions = []
    constraints = []
    boundConstraints = []
    features = []
    boundFeatures = []
    omissions = []
    boundOmissions = []
    omissionAccounting = nil
    trainings = []
    boundTrainings = []
    skillBonuses = nil
    boundSkillBonusRows = []
    omit(profile, requests)
    {
        local ids = [];
        foreach (local request in requests)
        {
            if (request == nil || !request.ofKind(RpgExpandedAncestryOmission) || request.id == nil || request.id == ''
                || !request.approved || request.evidence == nil || request.evidence == '')
                rpgExpandedReject('ancestry-omission-definition');
            if (holds(ids,request.id)) rpgExpandedReject('ancestry-omission-duplicate');
            ids = ids + [request.id]; local found = 0;
            for (local i = 1; i <= self.traits.length(); i += 1)
                if (self.traits[i].id == request.traitId && self.traits[i].scope == request.scope)
                {
                    if (found != 0) rpgExpandedReject('ancestry-omission-ambiguous');
                    found = i;
                }
            if (found == 0) rpgExpandedReject('ancestry-omission-missing');
            local trait = self.traits[found]; local cost = trait.creationCost();
            if (cost == 0) rpgExpandedReject('ancestry-omission-zero-cost');
            self.omissions = self.omissions + [[request.id,trait,self.traitOrigins[found],cost,
                self.traitDefinition(trait,self.traitOrigins[found]),request.evidence]];
            local keptTraits = []; local keptOrigins = []; local keptProfile = [];
            for (local i = 1; i <= self.traits.length(); i += 1)
                if (i != found) { keptTraits = keptTraits + [self.traits[i]]; keptOrigins = keptOrigins + [self.traitOrigins[i]]; }
            foreach (local current in profile.traits) if (current != trait) keptProfile = keptProfile + [current];
            self.traits = keptTraits; self.traitOrigins = keptOrigins; profile.traits = keptProfile;
        }
        self.boundOmissions = self.omissions;
        if (self.omissions.length() != 0)
        {
            local accounting = new RpgExpandedAncestryOmissionAccounting(); accounting.owner = profile; accounting.receipt = self;
            self.omissionAccounting = accounting; profile.contributions = profile.contributions + [accounting];
        }
        return nil;
    }
    constraintDefinition(constraint)
    {
        return [constraint,constraint.id,constraint.owner,constraint.traitIds,constraint.skills,
            constraint.attributeRanges,constraint.approved,constraint.evidence];
    }
    traitDefinition(trait,origin)
    {
        return [trait,origin,trait.id,trait.level,trait.scope,trait.points,trait.templatePurchaseKind,
            trait.controlled,trait.selfControlNumber(),trait.creationCost(),trait.skills];
    }
    validate(profile)
    {
        if (self.owner != profile || profile.ancestryScores != self || self.changes.length() != 10
            || self.boundChanges.length() != 10 || self.origins.length() != self.boundOrigins.length())
            rpgExpandedReject('ancestry-score-ownership');
        if (self.nonhuman != self.boundNonhuman) rpgExpandedReject('ancestry-score-binding');
        if (self.boundSkillBonusRows.length() != 0)
        {
            local count = 0;
            foreach (local contribution in profile.contributions) if (contribution == self.skillBonuses) count += 1;
            if (count != 1 || self.skillBonuses.owner != profile || self.skillBonuses.receipt != self)
                rpgExpandedReject('ancestry-skill-bonus-ownership');
            if (self.skillBonuses.rows.length() != self.boundSkillBonusRows.length()) rpgExpandedReject('ancestry-skill-bonus-binding');
            for (local i = 1; i <= self.boundSkillBonusRows.length(); i += 1)
                if (self.skillBonuses.rows[i] != self.boundSkillBonusRows[i]) rpgExpandedReject('ancestry-skill-bonus-binding');
        }
        else if (self.skillBonuses != nil) rpgExpandedReject('ancestry-skill-bonus-binding');
        if (self.trainings.length() != self.boundTrainings.length()) rpgExpandedReject('ancestry-training-binding');
        for (local i = 1; i <= self.trainings.length(); i += 1)
        {
            local entry = self.trainings[i]; local training = entry[1]; local count = 0;
            if (entry != self.boundTrainings[i] || training.skill != entry[2] || training.points < entry[3])
                rpgExpandedReject('ancestry-training-binding');
            foreach (local slot in profile.skills) if (slot == training) count += 1;
            if (count != 1) rpgExpandedReject('ancestry-training-mandatory');
            if (training.ofKind(RpgExpandedTraining) && training.defaultFrom != nil)
                rpgExpandedReject('ancestry-training-default-unresolved');
            local reason = profile.trainingPurchaseReason(training.skill,training);
            if (reason != nil) rpgExpandedReject(reason);
        }
        if (self.omissions.length() != self.boundOmissions.length()) rpgExpandedReject('ancestry-omission-binding');
        for (local i = 1; i <= self.omissions.length(); i += 1)
        {
            local omission = self.omissions[i];
            if (omission != self.boundOmissions[i]) rpgExpandedReject('ancestry-omission-binding');
            local definition = self.traitDefinition(omission[2],omission[3]);
            for (local j = 1; j <= definition.length(); j += 1)
                if (definition[j] != omission[5][j]) rpgExpandedReject('ancestry-omission-binding');
            foreach (local trait in profile.traits)
                if (trait.id == omission[2].id && (trait.id != 'quirk' || trait.scope == omission[2].scope))
                    rpgExpandedReject('ancestry-omission-restoration-required');
        }
        if (self.omissions.length() != 0)
        {
            local count = 0;
            foreach (local contribution in profile.contributions) if (contribution == self.omissionAccounting) count += 1;
            if (count != 1 || self.omissionAccounting.owner != profile || self.omissionAccounting.receipt != self)
                rpgExpandedReject('ancestry-omission-accounting');
        }
        if (self.constraints.length() != self.boundConstraints.length()) rpgExpandedReject('ancestry-taboo-binding');
        for (local i = 1; i <= self.constraints.length(); i += 1)
        {
            local constraint = self.constraints[i]; local count = 0;
            foreach (local contribution in profile.contributions) if (contribution == constraint) count += 1;
            if (count != 1) rpgExpandedReject('ancestry-taboo-mandatory');
            local definition = self.constraintDefinition(constraint);
            if (definition.length() != self.boundConstraints[i].length()) rpgExpandedReject('ancestry-taboo-binding');
            for (local j = 1; j <= definition.length(); j += 1)
                if (definition[j] != self.boundConstraints[i][j]) rpgExpandedReject('ancestry-taboo-binding');
        }
        if (self.features.length() != self.boundFeatures.length()) rpgExpandedReject('ancestry-feature-binding');
        for (local i = 1; i <= self.features.length(); i += 1)
            if (self.features[i] != self.boundFeatures[i]) rpgExpandedReject('ancestry-feature-binding');
        if (self.decisions.length() != self.boundDecisions.length()) rpgExpandedReject('ancestry-resolution-binding');
        for (local i = 1; i <= self.decisions.length(); i += 1)
            if (self.decisions[i] != self.boundDecisions[i]) rpgExpandedReject('ancestry-resolution-binding');
        if (self.traits.length() != self.boundTraits.length() || self.traitOrigins.length() != self.traits.length())
            rpgExpandedReject('ancestry-trait-binding');
        for (local i = 1; i <= self.traits.length(); i += 1)
        {
            local trait = self.traits[i]; local count = 0;
            foreach (local current in profile.traits) if (current == trait) count += 1;
            if (count != 1) rpgExpandedReject('ancestry-trait-mandatory');
            local definition = self.traitDefinition(trait,self.traitOrigins[i]);
            if (definition.length() != self.boundTraits[i].length()) rpgExpandedReject('ancestry-trait-binding');
            for (local j = 1; j <= definition.length(); j += 1)
                if (definition[j] != self.boundTraits[i][j]) rpgExpandedReject('ancestry-trait-binding');
        }
        for (local i = 1; i <= 10; i += 1)
            if (self.changes[i] != self.boundChanges[i]) rpgExpandedReject('ancestry-score-binding');
        for (local i = 1; i <= self.origins.length(); i += 1)
            if (self.origins[i] != self.boundOrigins[i]) rpgExpandedReject('ancestry-score-binding');
        return nil;
    }
    amounts(profile)
    {
        self.validate(profile); local result = []; local prices = [10,20,20,10,2,3,5,5,5,5];
        for (local i = 1; i <= 10; i += 1) result = result + [self.changes[i] * prices[i]];
        return result;
    }
;
modify RpgExpandedProfile
    ancestryScores = nil
    ancestrySkillModifier(skill)
    {
        local amount = inherited(skill);
        if (self.ancestryScores == nil) return amount;
        self.ancestryScores.validate(self);
        if (self.ancestryScores.skillBonuses == nil || skill == nil || !skill.ofKind(RpgLiteSkill)) return amount;
        local identity = skill;
        if (skill.ofKind(RpgExpandedSkill) && skill.optionalParent != nil) identity = skill.optionalParent;
        foreach (local row in self.ancestryScores.skillBonuses.rows)
            if (row[1] == identity.id)
            {
                if (skill.ofKind(RpgExpandedSkill) && skill.wildcard) rpgExpandedReject('ancestry-skill-bonus-wildcard-unresolved');
                amount += row[2];
            }
        return amount;
    }
    socialSkillLearningReason(skill)
    {
        if (self.ancestryScores != nil) self.ancestryScores.validate(self);
        return inherited(skill);
    }
    quirkCountsTowardCreationLimit(trait)
    {
        if (self.ancestryScores != nil)
        {
            self.ancestryScores.validate(self);
            if (holds(self.ancestryScores.traits,trait)) return nil;
        }
        return inherited(trait);
    }
    disadvantageBuyoffCost(trait)
    {
        if (self.ancestryScores != nil)
        {
            self.ancestryScores.validate(self);
            if (holds(self.ancestryScores.traits,trait)) return nil;
        }
        return inherited(trait);
    }
    developmentOfferReason(offer)
    {
        if (self.ancestryScores != nil)
        {
            self.ancestryScores.validate(self);
            if (offer.kind == 'remove-trait' && holds(self.ancestryScores.traits,offer.trait))
                return 'ancestry-trait-mandatory';
            if (offer.kind == 'trait' && offer.trait != nil)
                foreach (local omission in self.ancestryScores.omissions)
                    if (offer.trait.id == omission[2].id && (offer.trait.id != 'quirk' || offer.trait.scope == omission[2].scope))
                        return 'ancestry-omission-restoration-required';
        }
        return inherited(offer);
    }
    physicalCharacteristicLimitsExempt()
    {
        if (self.ancestryScores == nil) return inherited();
        self.ancestryScores.validate(self);
        return self.ancestryScores.nonhuman || inherited();
    }
    validateFeatures()
    {
        inherited(); if (self.ancestryScores != nil) self.ancestryScores.validate(self); return nil;
    }
    creationScoreAmounts()
    {
        local ordinary = inherited(); if (self.ancestryScores == nil) return ordinary;
        local ancestry = self.ancestryScores.amounts(self); local result = [];
        local index = 1;
        for (local i = 1; i <= ordinary.length(); i += 1)
        {
            if (i == 5) result = result + [ordinary[i]];
            else { result = result + [ordinary[i] - ancestry[index]]; index += 1; }
        }
        return result + ancestry;
    }
    creationDisadvantageExemption()
    {
        local amount = inherited(); if (self.ancestryScores == nil) return amount;
        foreach (local cost in self.ancestryScores.amounts(self)) if (cost < 0) amount -= cost;
        foreach (local trait in self.ancestryScores.traits)
            if (trait.creationCost() < 0) amount -= trait.creationCost();
        foreach (local omission in self.ancestryScores.omissions) if (omission[4] < 0) amount -= omission[4];
        return amount;
    }
;

/** Merge compatible ancestry purchases; tiered choices are not additive levels. */
rpgExpandedMergeAncestryTrait(existing, incoming)
{
    if (existing.id != incoming.id || existing.scope != incoming.scope
        || existing.templatePurchaseKind != incoming.templatePurchaseKind
        || existing.points != incoming.points || existing.controlled != incoming.controlled
        || existing.selfControlNumber() != incoming.selfControlNumber()
        || existing.active != incoming.active || existing.mitigated != incoming.mitigated
        || existing.skills.length() != incoming.skills.length())
        rpgExpandedReject('ancestry-trait-conflict');
    for (local i = 1; i <= existing.skills.length(); i += 1)
        if (existing.skills[i] != incoming.skills[i]) rpgExpandedReject('ancestry-trait-conflict');
    if (existing.templatePurchaseKind == 'shared-catalogue'
        && holds(['acute-hearing','acute-vision','acute-touch','acute-taste-smell',
            'charisma','fearlessness','hard-to-kill','night-vision'],existing.id))
    {
        local level = existing.level + incoming.level;
        if (existing.id == 'night-vision' && level > 9) rpgExpandedReject('ancestry-trait-level-limit');
        if (level > 100) rpgExpandedReject('ancestry-trait-level-limit');
        existing.level = level;
    }
    else if (existing.level != incoming.level || existing.creationCost() != incoming.creationCost())
        rpgExpandedReject('ancestry-trait-conflict');
    return existing;
}

/** An explicit B261 decision between purchases in two different ancestries. */
class RpgExpandedAncestryConflict: object
    id = nil
    retainedAncestry = nil
    retainedTrait = nil
    retainedScope = nil
    discardedAncestry = nil
    discardedTrait = nil
    discardedScope = nil
    approved = nil
    evidence = nil
    definition()
    {
        return [self.id,self.retainedAncestry,self.retainedTrait,self.retainedScope,
            self.discardedAncestry,self.discardedTrait,self.discardedScope,self.approved,self.evidence];
    }
    purchase(ancestries,ancestryId,traitId,scope)
    {
        local found = nil;
        foreach (local ancestry in ancestries)
            if (ancestry.id == ancestryId)
                foreach (local row in ancestry.traitRows)
                {
                    local trait = rpgExpandedTemplateTrait(row);
                    if (trait.id == traitId && trait.scope == scope)
                    {
                        if (found != nil) rpgExpandedReject('ancestry-resolution-ambiguous');
                        found = trait;
                    }
                }
        if (found == nil) rpgExpandedReject('ancestry-resolution-missing');
        return found;
    }
    validate(ancestries)
    {
        if (self.id == nil || self.id == '' || !self.approved || self.evidence == nil || self.evidence == ''
            || self.retainedAncestry == self.discardedAncestry)
            rpgExpandedReject('ancestry-resolution-definition');
        local retained = self.purchase(ancestries,self.retainedAncestry,self.retainedTrait,self.retainedScope);
        local discarded = self.purchase(ancestries,self.discardedAncestry,self.discardedTrait,self.discardedScope);
        local conflict = nil;
        if (retained.id == discarded.id && retained.scope == discarded.scope)
        {
            try { rpgExpandedMergeAncestryTrait(retained,discarded); }
            catch (RpgExpandedError error)
            {
                if (error.reason == 'ancestry-trait-conflict') conflict = true;
                else throw error;
            }
        }
        else
            foreach (local group in [['luck','extraordinary-luck','ridiculous-luck','unluckiness'],
                ['hideous','ugly','unattractive','attractive','handsome','very-handsome'],
                ['dead-broke','poor','struggling','comfortable','wealthy','very-wealthy','filthy-rich'],
                ['flexibility','double-jointed'],['bad-sight','bad-sight-correctable'],
                ['status','low-status'],['resistant-disease-3','resistant-disease-8'],
                ['acute-hearing','hard-of-hearing']])
                if (retained.id != discarded.id && holds(group,retained.id) && holds(group,discarded.id)) conflict = true;
        if (!conflict) rpgExpandedReject('ancestry-resolution-not-conflicting');
        return nil;
    }
;

/** B261, B451-B452: add ancestry deltas after resolving personal purchases. */
rpgExpandedCreateAncestryCharacter(personal, ancestries, rules)
{
    return rpgExpandedCreateResolvedAncestryCharacter(personal,ancestries,[],rules);
}

/** Resolve identified ancestry conflicts before assembling the combined character. */
rpgExpandedCreateResolvedAncestryCharacter(personal, ancestries, resolutions, rules)
{
    return rpgExpandedCreateCustomizedAncestryCharacter(personal,ancestries,resolutions,[],rules);
}

/** B262: preserve ancestry cost and add an opposite personal omission adjustment. */
rpgExpandedCreateCustomizedAncestryCharacter(personal, ancestries, resolutions, omissions, rules)
{
    if (personal == nil || !personal.ofKind(RpgExpandedTemplate)
        && !personal.ofKind(RpgExpandedTemplateSelection) && !personal.ofKind(RpgExpandedTemplateCustomization))
        rpgExpandedReject('ancestry-personal-template');
    if (rules == nil || !rules.ofKind(RpgExpandedRules)) rpgExpandedReject('profile-or-rules');
    local changes = [0,0,0,0,0,0,0,0,0,0]; local origins = []; local nonhuman = nil;
    foreach (local ancestry in ancestries)
    {
        if (ancestry == nil || !ancestry.ofKind(RpgExpandedAncestryScoreTemplate))
            rpgExpandedReject('ancestry-score-definition');
        ancestry.validate(); if (ancestry.nonhuman) nonhuman = true;
        if (holds(origins,ancestry.id)) rpgExpandedReject('duplicate-ancestry-score');
        origins = origins + [ancestry.id]; local values = ancestry.changes(); local combined = [];
        for (local i = 1; i <= 10; i += 1)
        {
            local value = changes[i] + values[i]; rpgInteger(value,-1000,1000); combined = combined + [value];
        }
        changes = combined;
    }
    local resolutionIds = []; local decisions = [];
    foreach (local item in resolutions)
        if (item == nil || !item.ofKind(RpgExpandedAncestryConflict)) rpgExpandedReject('ancestry-resolution-definition');
    foreach (local resolution in resolutions)
    {
        if (resolution == nil || !resolution.ofKind(RpgExpandedAncestryConflict))
            rpgExpandedReject('ancestry-resolution-definition');
        resolution.validate(ancestries);
        if (holds(resolutionIds,resolution.id)) rpgExpandedReject('ancestry-resolution-duplicate');
        resolutionIds = resolutionIds + [resolution.id];
        foreach (local other in resolutions)
            if (other != resolution)
            {
                if (other.discardedAncestry == resolution.discardedAncestry
                    && other.discardedTrait == resolution.discardedTrait && other.discardedScope == resolution.discardedScope)
                    rpgExpandedReject('ancestry-resolution-duplicate');
                if (other.discardedAncestry == resolution.retainedAncestry
                    && other.discardedTrait == resolution.retainedTrait && other.discardedScope == resolution.retainedScope)
                    rpgExpandedReject('ancestry-resolution-retained-discarded');
            }
        decisions = decisions + [resolution.definition()];
    }
    local p = personal.assembleProfile(rules);
    if (p.ancestryScores != nil || p.creationComplete) rpgExpandedReject('ancestry-existing-character');
    local receipt = new RpgExpandedAncestryScores(); receipt.owner = p;
    receipt.decisions = decisions; receipt.boundDecisions = decisions;
    receipt.nonhuman = nonhuman; receipt.boundNonhuman = nonhuman;
    receipt.origins = origins; receipt.boundOrigins = origins;
    receipt.changes = changes; receipt.boundChanges = changes; p.ancestryScores = receipt;
    foreach (local ancestry in ancestries)
    {
        foreach (local feature in ancestry.cosmeticFeatures) receipt.features = receipt.features + [[ancestry.id,feature]];
        if (ancestry.tabooTraitIds.length() != 0 || ancestry.tabooSkills.length() != 0
            || ancestry.tabooAttributeRanges.length() != 0)
        {
            local constraint = new RpgExpandedTabooTraits(); constraint.id = 'ancestry-taboo:' + ancestry.id;
            constraint.owner = p; constraint.traitIds = ancestry.tabooTraitIds; constraint.skills = ancestry.tabooSkills;
            constraint.attributeRanges = ancestry.tabooAttributeRanges; constraint.approved = ancestry.approved;
            constraint.evidence = ancestry.evidence; constraint.validateDefinition(p);
            p.contributions = p.contributions + [constraint]; receipt.constraints = receipt.constraints + [constraint];
            receipt.boundConstraints = receipt.boundConstraints + [receipt.constraintDefinition(constraint)];
        }
    }
    receipt.boundFeatures = receipt.features;
    foreach (local ancestry in ancestries)
        foreach (local row in ancestry.traitRows)
        {
            local trait = rpgExpandedTemplateTrait(row); local found = 0; local discarded = nil;
            foreach (local resolution in resolutions)
                if (resolution.discardedAncestry == ancestry.id && resolution.discardedTrait == trait.id
                    && resolution.discardedScope == trait.scope) discarded = true;
            if (discarded) continue;
            for (local i = 1; i <= receipt.traits.length(); i += 1)
                if (receipt.traits[i].id == trait.id && receipt.traits[i].scope == trait.scope) found = i;
            if (found == 0)
            {
                receipt.traits = receipt.traits + [trait]; receipt.traitOrigins = receipt.traitOrigins + [[ancestry.id]];
                p.traits = p.traits + [trait];
            }
            else
            {
                if (holds(receipt.traitOrigins[found],ancestry.id)) rpgExpandedReject('duplicate-ancestry-trait-row');
                rpgExpandedMergeAncestryTrait(receipt.traits[found],trait);
                local updated = [];
                for (local i = 1; i <= receipt.traitOrigins.length(); i += 1)
                    updated = updated + [i == found ? receipt.traitOrigins[i] + [ancestry.id] : receipt.traitOrigins[i]];
                receipt.traitOrigins = updated;
            }
        }
    foreach (local ancestry in ancestries)
        foreach (local row in ancestry.skillRows)
        {
            if (row.length() != 2 || row[1] == nil || !row[1].ofKind(RpgSkill))
                rpgExpandedReject('ancestry-training-definition');
            rpgInteger(row[2],1,10000);
            foreach (local entry in receipt.trainings)
                if (entry[2] == row[1]) rpgExpandedReject('ancestry-training-overlap-unresolved');
            local training = rpgExpandedTrainingFor(p,row[1]);
            if (training == nil)
            {
                training = new RpgExpandedTraining(); training.skill = row[1]; training.points = 0;
                p.skills = p.skills + [training];
            }
            if (training.ofKind(RpgExpandedTraining) && training.defaultFrom != nil)
                rpgExpandedReject('ancestry-training-default-unresolved');
            rpgInteger(training.points,0,10000 - row[2]); training.points += row[2];
            receipt.trainings = receipt.trainings + [[training,row[1],row[2],ancestry.id]];
        }
    receipt.boundTrainings = receipt.trainings;
    local bonusRows = [];
    foreach (local ancestry in ancestries)
    {
        local seen = [];
        foreach (local row in ancestry.skillBonusRows)
        {
            if (row.length() != 2 || row[1] == nil || row[1] == '' || holds(seen,row[1]))
                rpgExpandedReject('ancestry-skill-bonus-definition');
            seen = seen + [row[1]]; rpgInteger(row[2],1,3);
            local found = nil; local updated = [];
            foreach (local prior in bonusRows)
            {
                if (prior[1] == row[1])
                {
                    local bonus = prior[2] + row[2];
                    if (bonus > 3) rpgExpandedReject('ancestry-skill-bonus-limit');
                    updated = updated + [[row[1],bonus,prior[3] + [ancestry.id]]]; found = true;
                }
                else updated = updated + [prior];
            }
            if (!found) updated = updated + [[row[1],row[2],[ancestry.id]]];
            bonusRows = updated;
        }
    }
    if (bonusRows.length() != 0)
    {
        local bonuses = new RpgExpandedAncestrySkillBonuses(); bonuses.owner = p; bonuses.receipt = receipt; bonuses.rows = bonusRows;
        receipt.skillBonuses = bonuses; receipt.boundSkillBonusRows = bonusRows; p.contributions = p.contributions + [bonuses];
    }
    receipt.omit(p,omissions);
    for (local i = 1; i <= receipt.traits.length(); i += 1)
        receipt.boundTraits = receipt.boundTraits + [receipt.traitDefinition(receipt.traits[i],receipt.traitOrigins[i])];
    p.st += changes[1]; p.dx += changes[2]; p.iq += changes[3]; p.ht += changes[4];
    p.hpAdjustment += changes[5]; p.fpAdjustment += changes[6];
    p.willAdjustment += changes[7]; p.perceptionAdjustment += changes[8];
    p.speedQuarterAdjustment += changes[9]; p.moveAdjustment += changes[10];
    rpgExpandedValidateCharacter(p); return p;
}
