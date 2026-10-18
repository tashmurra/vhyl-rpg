#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-en.t>
#include <vhyl-actions.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded-character-social.t>
fixtureRoom: Room 'Registry';
fixtureRules: RpgExpandedRules;
fixtureHero: RpgExpandedProfile rules = fixtureRules iq = 12 hpAdjustment = 1 pointBudget = 100
    skills = [fixtureTraining] contributions = [fixtureReputation,fixtureStanding]
    reactionEncounters = [fixtureEncounter] knowledge = fixtureKnowledge money = 10 loyalties = [fixtureLoyalty];
fixtureSkill: RpgExpandedSkill id = 'hard-records' attribute = rpgIQ difficulty = 3;
fixtureTraining: RpgExpandedTraining skill = fixtureSkill points = 4;
fixtureStanding: RpgExpandedStatus id = 'local-status' owner = fixtureHero culture = 'town' level = 1;
fixtureReputation: RpgExpandedReputation id = 'local-reputation' owner = fixtureHero details = 'Reliable records'
    facets = [['recordkeepers',2,'large']] frequency = 'sometimes';
fixtureRecognition: RpgExpandedReputationRecognition reputation = fixtureReputation audience = 'clerk'
    facet = 'recordkeepers' inArea = true identityExposed = true;
fixtureEncounter: RpgExpandedReactionEncounter id = 'clerk-enquiry' subject = fixtureHero audience = 'clerk';
fixtureAttempt: RpgExpandedReactionAttempt encounter = fixtureEncounter approach = 'polite-question';
fixtureKnowledge: RpgExpandedKnowledge owner = fixtureHero;
fixtureProvider: RpgExpandedProfile rules = fixtureRules knowledge = fixtureProviderKnowledge;
fixtureProviderKnowledge: RpgExpandedKnowledge owner = fixtureProvider beliefs = ['first-fact','second-fact'];
fixtureResponse: RpgExpandedInformationReaction band = 2 adverseChoice = 'payment';
fixtureDelivery: RpgExpandedInformationDelivery id = 'paid-answer' provider = fixtureProvider recipient = fixtureHero
    reaction = fixtureResponse requested = ['first-fact','second-fact'] partial = ['first-fact']
    available = true price = 5 paymentApproved = true;
fixtureLoyalty: RpgExpandedLoyalty id = 'service' subject = fixtureHero employer = 'archive' preset = 12;
fixtureLoyaltyCheck: RpgExpandedLoyaltyCheck loyalty = fixtureLoyalty incident = 'trust-record' necessary = true;
fixtureInput: object code = 0;
class CharacterSocialAction: Action
    exec(context)
    {
        local code = fixtureInput.code;
        if (code == 1 || code == 2 || code == 3)
        {
            if (code == 3) fixtureReputation.frequency = 'occasionally';
            fixtureRecognition.resolve(); fixtureAttempt.modifier = rpgExpandedReputationModifier([fixtureRecognition]);
            local value = fixtureAttempt.resolve(); event('test.private-reaction'); eventValue(value.status); eventValue(value.band);
            if (code == 2) throw new RpgError();
        }
        if (code == 4 || code == 5)
        {
            local value = fixtureDelivery.deliver(); event('test.paid-answer'); eventValue(value.status); eventValue(value.money);
            if (code == 5) throw new RpgError();
        }
        if (code == 6 || code == 7)
        {
            fixtureLoyalty.initialize(); local value = fixtureLoyaltyCheck.resolve();
            event('test.private-loyalty'); eventValue(value.status); eventValue(value.loyal ? 1 : 0);
            if (code == 7) throw new RpgError();
        }
        return nil;
    }
;
fixtureAction: CharacterSocialAction;
fixtureVerb: Verb code = 1400 action = fixtureAction label = 'character-social-fixture';
modify gameMain initialRoom = fixtureRoom;
startup() { rpgRandom.seed(1); return vhylStart(); }
turn(tokens) { return vhylTurn(tokens); }
act(verb,args)
{
    if (verb == 1400) { fixtureInput.code = args[1]; return vhylAct(verb,args); }
    if (verb == 1450)
    {
        event('test.character-social-state'); eventValue(fixtureReputation.recognitions.length());
        eventValue(fixtureEncounter.history.length()); eventValue(fixtureHero.money); eventValue(fixtureProvider.money);
        eventValue(fixtureKnowledge.received.length()); eventValue(fixtureLoyalty.incidents.length());
        eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    if (verb == 1451)
    {
        local value = fixtureAttempt.assess(); event('test.private-preview'); eventValue(value.status);
        eventValue(value.band); eventValue(value.total); eventValue(value.check); return nil;
    }
    if (verb == 1452)
    {
        rpgExpandedValidateCharacter(fixtureHero); event('test.character-cost');
        eventValue(rpgExpandedCharacterCost(fixtureHero,nil)); eventValue(fixtureHero.will);
        eventValue(fixtureHero.skillScore(fixtureSkill)); return nil;
    }
    if (verb == 1453)
    {
        event('test.skill-table'); eventValue(rpgExpandedSkillLevel(12,args[1],args[2],args[3] == 1)); return nil;
    }
    if (verb == 1454)
    {
        local p = new RpgExpandedProfile(); p.rules = fixtureRules; p.iq = 12;
        local a = new RpgExpandedSkill(); a.id = 'a'; a.attribute = rpgIQ; a.difficulty = 0;
        local b = new RpgExpandedSkill(); b.id = 'b'; b.attribute = rpgIQ; b.defaults = [[a,-2]];
        local c = new RpgExpandedSkill(); c.id = 'c'; c.attribute = rpgIQ; c.defaults = [[b,-2]];
        local t = new RpgExpandedTraining(); t.skill = a; t.points = 4; p.skills = [t];
        event('test.skill-defaults'); eventValue(p.skillScore(a)); eventValue(p.skillScore(b)); eventValue(p.skillScore(c));
        local technique = new RpgExpandedTechnique(); technique.id = 'technique'; technique.owner = p;
        technique.skill = a; technique.penalty = -2; technique.points = 1; p.contributions = [technique];
        eventValue(technique.score()); return nil;
    }
    if (verb == 1455)
    {
        local p = new RpgExpandedProfile(); p.rules = fixtureRules;
        if (args[1] == 1) p.hpAdjustment = 4;
        if (args[1] == 2)
        {
            local language = new RpgLiteLanguage(); language.id = 'native'; language.native = true;
            p.languages = [language,language];
        }
        if (args[1] == 3)
        {
            local language = new RpgLiteLanguage(); language.id = 'native'; language.native = true; language.spoken = 2;
            p.languages = [language];
        }
        if (args[1] == 4) p.traits = [rpgLiteMakeTrait('luck',1,nil),rpgLiteMakeTrait('unluckiness',1,nil)];
        if (args[1] == 5) { p.iq = 12; p.pointBudget = 10; }
        event('test.invalid-character');
        try { rpgExpandedValidateCharacter(p); eventValue('unexpected-success'); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        return nil;
    }
    if (verb == 1456)
    {
        local template = new RpgExpandedTemplate(); template.skillRows = [[fixtureSkill,4]];
        local a = template.create(fixtureRules); local b = template.create(fixtureRules);
        a.skills[1].points = 8; event('test.template-ownership');
        eventValue(a.skills[1].points); eventValue(b.skills[1].points);
        eventValue(a.skills[1] != b.skills[1] ? 1 : 0); return nil;
    }
    if (verb == 1457)
    {
        local skill = args[1] == 1 ? new RpgSkill() : args[1] == 2 ? new RpgLiteSkill() : new RpgExpandedSkill();
        skill.difficulty = args[1] == 4 ? 4 : 3;
        if (args[1] == 5) skill.attribute = nil;
        if (args[1] == 6) skill.defaultPenalty = 1;
        event('test.skill-definition');
        try { rpgExpandedValidateSkill(skill); eventValue('accepted'); }
        catch (RpgError error) { eventValue('rejected'); }
        return nil;
    }
    if (verb == 1458)
    {
        local rules = new RpgExpandedRules(); rules.wildcardSkills = args[1] != 1;
        local p = new RpgExpandedProfile(); p.rules = rules;
        local skill = new RpgExpandedSkill(); skill.id = 'wildcard-fixture';
        skill.wildcard = true; skill.difficulty = args[1] == 2 ? 2 : 3;
        if (args[1] == 3) skill.defaultPenalty = -6;
        if (args[1] == 4) skill.defaults = [[fixtureSkill,-2]];
        local training = new RpgExpandedTraining(); training.skill = skill; training.points = 3;
        p.skills = [training]; event('test.wildcard-creation');
        try
        {
            rpgExpandedValidateCharacter(p); eventValue('accepted');
            eventValue(rpgExpandedCharacterCost(p,nil)); eventValue(p.skillScore(skill));
        }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        return nil;
    }
    if (verb == 1118)
    {
        local p = new RpgExpandedProfile(); p.rules = new RpgExpandedRules(); p.dx = 12;
        local basic = new RpgExpandedSkill(); basic.attribute = rpgDX;
        basic.difficulty = 1; basic.defaultPenalty = 0;
        local advanced = new RpgExpandedSkill();
        local req = new RpgExpandedPrerequisite(); req.skill = basic; req.minimum = 12;
        advanced.prerequisite = req;
        local training = new RpgExpandedTraining(); training.skill = basic; training.points = 0;
        p.skills = [training];
        event('test.learning-requirements'); eventValue(p.skillLearningReason(advanced));
        training.points = 1; eventValue(p.skillLearningReason(advanced));
        training.points = 4; eventValue(p.skillLearningReason(advanced));
        local traitReq = new RpgExpandedPrerequisite(); traitReq.kind = 'trait';
        traitReq.traitId = 'learning-gift'; traitReq.traitLevel = 2;
        local group = new RpgExpandedPrerequisite(); group.kind = 'all';
        group.children = [req,traitReq]; advanced.prerequisite = group;
        eventValue(p.skillLearningReason(advanced));
        group.kind = 'any'; eventValue(p.skillLearningReason(advanced));
        training.points = 0;
        local gift = new RpgLiteTrait(); gift.id = 'learning-gift'; gift.level = 2;
        gift.active = nil; p.traits = [gift]; eventValue(p.skillLearningReason(advanced));
        group.children = [req,group];
        try { p.skillLearningReason(advanced); eventValue('unexpected-success'); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        return nil;
    }
    if (verb == 1134)
    {
        local rules = new RpgExpandedRules();
        local skill = new RpgExpandedSkill(); skill.difficulty = 1;
        local a = new RpgExpandedTemplate(); a.st = 12; a.ht = 12; a.hpAdjustment = 2;
        a.pointBudget = 1000; a.skillRows = [[skill,16]]; a.traitRows = [['status',2,nil]];
        local b = new RpgExpandedTemplate(); b.dx = 12; b.iq = 12; b.perceptionAdjustment = 1;
        b.pointBudget = 1000; b.skillRows = [[skill,1]]; b.traitRows = [['status',1,nil]];
        local p = rpgExpandedCombineTemplates(args[1] == 1 ? [a,b] : [b,a],rules,1000,50);
        event('test.template-composition'); eventValue(p.st); eventValue(p.dx); eventValue(p.iq);
        eventValue(p.ht); eventValue(p.maxHP); eventValue(p.perception);
        eventValue(p.basicSpeedQuarters()); eventValue(p.basicMove());
        eventValue(p.skills[1].points); eventValue(p.traits[1].level);
        eventValue(rpgExpandedCharacterCost(p,nil));
        p.skills[1].points = 100; p.traits[1].level = 3;
        local fresh = rpgExpandedCombineTemplates([a,b],rules,1000,50);
        eventValue(fresh.skills[1].points); eventValue(fresh.traits[1].level);
        return nil;
    }
    if (verb == 1135)
    {
        local rules = new RpgExpandedRules();
        local a = new RpgExpandedTemplate(); a.traitRows = [['status',2,nil]];
        local b = new RpgExpandedTemplate(); b.traitRows = [['low-status',2,nil]];
        event('test.template-conflicts');
        try { rpgExpandedCombineTemplates([a,b],rules,1000,50); eventValue('unexpected-success'); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        try { rpgExpandedCombineTemplates([],rules,1000,50); eventValue('unexpected-success'); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        a.st = 8; a.traitRows = []; b.st = 9; b.traitRows = [];
        local p = rpgExpandedCombineTemplates([a,b],rules,1000,50); eventValue(p.st);
        return nil;
    }
    if (verb == 1136)
    {
        local rules = new RpgExpandedRules();
        local skill = new RpgExpandedSkill(); skill.techLevel = 8;
        local a = new RpgExpandedTemplate(); a.campaignTL = 8; a.skillRows = [[skill,1]];
        local p = a.create(rules);
        event('test.template-technology'); eventValue(p.campaignTL); eventValue(p.techLevel);
        eventValue(rpgExpandedCharacterCost(p,nil));
        a.campaignTL = 6; a.techLevel = 8; p = a.create(rules);
        eventValue(rpgExpandedCharacterCost(p,nil));
        local b = new RpgExpandedTemplate(); b.campaignTL = 6; b.techLevel = 8;
        p = rpgExpandedCombineTemplates([a,b],rules,100,50);
        eventValue(p.techLevel); eventValue(rpgExpandedCharacterCost(p,nil));
        b.techLevel = nil;
        try { rpgExpandedCombineTemplates([a,b],rules,100,50); eventValue('unexpected-success'); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        a.techLevel = nil;
        try { a.create(rules); eventValue('unexpected-success'); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        return nil;
    }
    if (verb == 1137)
    {
        local rules = new RpgExpandedRules(); local skill = new RpgExpandedSkill();
        local a = new RpgExpandedTemplateOption(); a.id = 'training'; a.skillRows = [[skill,4]];
        local b = new RpgExpandedTemplateOption(); b.id = 'position'; b.traitRows = [['status',1,nil]];
        local group = new RpgExpandedTemplateChoice(); group.id = 'focus'; group.options = [a,b];
        group.minimumPoints = 4; group.maximumPoints = 4;
        local template = new RpgExpandedTemplate(); template.choiceGroups = [group];
        event('test.template-choice');
        local p = template.createSelected(rules,[['focus',['training']]]);
        eventValue(rpgExpandedCharacterCost(p,nil)); eventValue(p.skills[1].points);
        eventValue(p.templateChoices[1][1]); eventValue(p.templateChoices[1][2]);
        p.skills[1].points = 20;
        p = template.createSelected(rules,[['focus',['training']]]); eventValue(p.skills[1].points);
        try { template.create(rules); eventValue('unexpected-success'); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        try { template.createSelected(rules,[]); eventValue('unexpected-success'); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        try { template.createSelected(rules,[['focus',['position']]]); eventValue('unexpected-success'); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        group.maximumChoices = 2;
        try { template.createSelected(rules,[['focus',['training','training']]]); eventValue('unexpected-success'); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        a.eligible = nil;
        try { template.createSelected(rules,[['focus',['training']]]); eventValue('unexpected-success'); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        return nil;
    }
    if (verb == 1138)
    {
        local rules = new RpgExpandedRules();
        local option = new RpgExpandedTemplateOption(); option.id = 'limitation';
        option.traitRows = [['low-status',1,nil]];
        local group = new RpgExpandedTemplateChoice(); group.id = 'background'; group.options = [option];
        group.minimumPoints = -5; group.maximumPoints = -5;
        local template = new RpgExpandedTemplate(); template.choiceGroups = [group];
        event('test.template-choice-conflicts');
        local p = template.createSelected(rules,[['background',['limitation']]]);
        eventValue(rpgExpandedCharacterCost(p,nil)); eventValue(p.traits.length());
        template.traitRows = [['status',1,nil]];
        try { template.createSelected(rules,[['background',['limitation']]]); eventValue('unexpected-success'); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        template.traitRows = [];
        try { template.createSelected(rules,[['background',[]]]); eventValue('unexpected-success'); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        try { template.createSelected(rules,[['unknown',['limitation']]]); eventValue('unexpected-success'); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        return nil;
    }
    if (verb == 1139)
    {
        local rules = new RpgExpandedRules();
        local a = new RpgExpandedTemplateOption(); a.id = 'physical';
        a.stChange = 1; a.hpChange = 1; a.speedQuarterChange = 1;
        local b = new RpgExpandedTemplateOption(); b.id = 'focused';
        b.iqChange = -1; b.willChange = 1; b.perceptionChange = 1;
        local group = new RpgExpandedTemplateChoice(); group.id = 'scores'; group.options = [a,b];
        group.minimumChoices = 2; group.maximumChoices = 2; group.minimumPoints = 7; group.maximumPoints = 7;
        local template = new RpgExpandedTemplate(); template.choiceGroups = [group];
        event('test.template-score-options'); eventValue(a.cost()); eventValue(b.cost());
        local p = template.createSelected(rules,[['scores',['physical','focused']]]);
        eventValue(p.st); eventValue(p.maxHP); eventValue(p.iq); eventValue(p.will);
        eventValue(p.perception); eventValue(p.basicSpeedQuarters());
        eventValue(rpgExpandedCharacterCost(p,nil)); eventValue(template.st); eventValue(template.iq);
        group.minimumChoices = 1; group.maximumChoices = 1;
        group.minimumPoints = nil; group.maximumPoints = nil; a.hpChange = 5;
        try { template.createSelected(rules,[['scores',['physical']]]); eventValue('unexpected-success'); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        return nil;
    }
    return vhylAct(verb,args);
}
