#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-en.t>
#include <vhyl-actions.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded-all.t>
expandedRoom: Room 'Workshop';
expandedRules: RpgExpandedRules;
expandedHero: RpgExpandedProfile actor = player rules = expandedRules
    familiarities = [expandedFamiliarity]
    skills = [expandedInvestment] pointBudget = 1000 developmentOpen = true;
expandedSubject: RpgExpandedSkill id = 'analysis' attribute = rpgIQ difficulty = 3;
expandedInvestment: RpgExpandedTraining skill = expandedSubject points = 1;
expandedStudy: RpgExpandedStudy profile = expandedHero training = expandedInvestment permitted = true;
expandedFamiliarity: RpgExpandedFamiliarity owner = expandedHero skill = expandedSubject
    equipmentType = 'survey-console' available = true;
expandedInput: object code = 0 args = [];
expandedState()
{
    event('test.expanded-state'); eventValue(rpgLedger.seconds);
    eventValue(expandedStudy.credit); eventValue(expandedStudy.awarded);
    eventValue(expandedInvestment.points); eventValue(expandedHero.unspentPoints);
    foreach (local amount in expandedHero.studyUsed) eventValue(amount); eventValue(rpgRandom.draws); return nil;
}
class ExpandedTestAction: Action
    exec(context)
    {
        local code = expandedInput.code; local args = expandedInput.args;
        if (code == 1 || code == 3)
        {
            local value = expandedStudy.advance(args[2]);
            event('test.study'); eventValue(value.status); eventValue(value.reason); eventValue(value.points);
            if (code == 3) throw new RpgError();
        }
        if (code == 2) rpgSpendTime(args[2]);
        if (code == 4) expandedStudy.permitted = nil;
        if (code == 5) expandedStudy.credit = 2879998;
        if (code == 6 || code == 7)
        {
            local value = expandedFamiliarity.advance(args[2]);
            event('test.familiarity'); eventValue(value.status); eventValue(value.reason);
            eventValue(value.seconds);
            if (code == 7) throw new RpgError();
        }
        return nil;
    }
;
expandedTestAction: ExpandedTestAction;
expandedTestVerb: Verb code = 1100 action = expandedTestAction label = 'test-expanded';
startup() { return vhylStart(); }
turn(tokens) { return vhylTurn(tokens); }
act(verb, args)
{
    if (verb == 1100) { expandedInput.code = args[1]; expandedInput.args = args; return vhylAct(verb,[]); }
    if (verb == 1101) return expandedState();
    if (verb == 1102)
    {
        event('test.level'); eventValue(rpgExpandedSkillLevel(12,args[1],args[2],args[3] == 1)); return nil;
    }
    if (verb == 1103)
    {
        event('test.price'); eventValue(rpgExpandedModifiedCost(args[1],[args[2],args[3]])); return nil;
    }
    if (verb == 1104)
    {
        event('test.range'); eventValue(rpgExpandedRangeModifier(args[1])); return nil;
    }
    if (verb == 1105)
    {
        event('test.damage'); foreach (local amount in rpgExpandedDamageDice(args[1],nil)) eventValue(amount); foreach (local amount in rpgExpandedDamageDice(args[1],true)) eventValue(amount); return nil;
    }
    if (verb == 1106)
    {
        local p = new RpgExpandedProfile(); p.rules = new RpgExpandedRules(); p.pointBudget = 1000;
        p.hpAdjustment = args[1]; p.fpAdjustment = -1; p.willAdjustment = 1;
        p.perceptionAdjustment = -1; p.speedQuarterAdjustment = 1; p.moveAdjustment = 2;
        event('test.character');
        try { rpgExpandedValidateCharacter(p); eventValue('valid'); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        eventValue(rpgExpandedCharacterCost(p,nil)); eventValue(rpgExpandedCharacterCost(p,true));
        eventValue(p.maxHP); eventValue(p.maxEnergy); eventValue(p.basicSpeedQuarters()); eventValue(p.basicMove());
        return nil;
    }
    if (verb == 1107)
    {
        local p = new RpgExpandedProfile(); p.rules = new RpgExpandedRules(); p.dx = 12;
        local a = new RpgExpandedSkill(); a.id = 'a'; a.attribute = rpgDX; a.difficulty = 1; a.defaultPenalty = -5;
        local b = new RpgExpandedSkill(); b.id = 'b'; b.attribute = rpgDX; b.difficulty = 1;
        b.defaults = [[a,-2]];
        local c = new RpgExpandedSkill(); c.id = 'c'; c.attribute = rpgDX; c.defaults = [[b,-2]];
        local at = new RpgExpandedTraining(); at.skill = a; at.points = args[1];
        local bt = new RpgExpandedTraining(); bt.skill = b; bt.points = args[2]; bt.defaultFrom = a;
        p.skills = [at,bt];
        event('test.defaults'); eventValue(p.skillScore(a)); eventValue(p.skillScore(b)); eventValue(p.skillScore(c));
        local technique = new RpgExpandedTechnique(); technique.owner = p; technique.skill = a;
        technique.penalty = -4; technique.hard = true; technique.points = 3;
        eventValue(technique.score()); return nil;
    }
    if (verb == 1108)
    {
        local task = new RpgExpandedTaskTime(); task.baseSeconds = 101;
        task.steps = args[1]; task.applicable = args[2] == 1;
        local result = task.assess(expandedRules);
        event('test.time'); eventValue(result.status); eventValue(result.reason);
        eventValue(result.modifier); eventValue(result.seconds); return nil;
    }
    if (verb == 1109)
    {
        local result = expandedStudy.assess(args[1]);
        event('test.study'); eventValue(result.status); eventValue(result.reason); eventValue(result.points); return nil;
    }
    if (verb == 1110)
    {
        local package = new RpgExpandedTemplate(); package.iq = 11;
        package.skillRows = [[expandedSubject,4]];
        package.traitRows = [['acute-vision',2,nil]];
        local a = package.create(new RpgExpandedRules());
        local b = package.create(new RpgExpandedRules());
        a.skills[1].points = 8; a.traits[1].level = 3;
        event('test.template'); eventValue(b.skills[1].points); eventValue(b.traits[1].level);
        eventValue(rpgExpandedCharacterCost(b,nil)); return nil;
    }
    if (verb == 1111)
    {
        local p = new RpgExpandedProfile(); p.rules = new RpgExpandedRules();
        local a = new RpgExpandedSkill(); a.difficulty = 3; a.wildcard = true;
        local at = new RpgExpandedTraining(); at.skill = a; at.points = 3; p.skills = [at];
        event('test.invalid');
        try { p.skillScore(a); eventValue('unexpected-success'); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        p.rules.wildcardSkills = true; a.defaultPenalty = -6;
        try { p.skillScore(a); eventValue('unexpected-success'); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        a.defaultPenalty = nil; a.wildcard = nil; local b = new RpgExpandedSkill();
        local bt = new RpgExpandedTraining(); bt.skill = b; bt.points = 1;
        a.defaults = [[b,-2]]; b.defaults = [[a,-2]];
        at.defaultFrom = b; bt.defaultFrom = a; p.skills = [at,bt];
        try { p.skillScore(a); eventValue('unexpected-success'); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        try { rpgExpandedDamageDice(41,nil); eventValue('unexpected-success'); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        return nil;
    }
    if (verb == 1112)
    {
        event('test.signed-price');
        eventValue(rpgExpandedSignedModifiedCost(args[1],[args[2],args[3]])); return nil;
    }
    if (verb == 1113)
    {
        event('test.control-price');
        eventValue(rpgExpandedSelfControlCost(args[1],args[2])); return nil;
    }
    if (verb == 1114)
    {
        local trait = new RpgExpandedDisadvantage(); trait.approved = true;
        trait.points = -15; trait.selfControlRating = 9;
        local p = new RpgExpandedProfile(); p.rules = new RpgExpandedRules();
        p.traits = [trait]; p.pointBudget = 1000; p.disadvantageLimit = 20;
        event('test.negative-accounting'); eventValue(trait.creationCost());
        eventValue(rpgExpandedCharacterCost(p,nil)); eventValue(rpgExpandedCharacterCost(p,true));
        try { rpgExpandedValidateCharacter(p); eventValue('unexpected-success'); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        p.disadvantageLimit = 22; eventValue(rpgExpandedValidateCharacter(p));
        eventValue(p.unspentPoints); return nil;
    }
    if (verb == 1115)
    {
        event('test.negative-invalid');
        try { rpgExpandedSelfControlCost(-10,7); eventValue('unexpected-success'); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        local trait = new RpgExpandedDisadvantage(); trait.points = -10;
        try { trait.creationCost(); eventValue('unexpected-success'); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        trait.approved = true; trait.selfControlRating = 12; trait.percentages = [-10];
        try { trait.creationCost(); eventValue('unexpected-success'); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        return nil;
    }
    if (verb == 1116)
    {
        local p = new RpgExpandedProfile(); p.rules = new RpgExpandedRules(); p.dx = 12;
        local a = new RpgExpandedSkill(); a.attribute = rpgDX; a.difficulty = 1;
        local training = new RpgExpandedTraining(); training.skill = a; training.points = 4;
        p.skills = [training];
        local parent = new RpgExpandedTechnique(); parent.owner = p; parent.id = 'parent';
        parent.skill = a; parent.maximumAboveSkill = 4;
        local child = new RpgExpandedTechnique(); child.owner = p; child.id = 'child';
        child.parentTechnique = parent; child.penalty = -3; child.hard = true;
        child.points = args[1]; p.contributions = [parent,child];
        event('test.technique-chain'); eventValue(child.score());
        parent.points = 2; eventValue(child.score());
        training.points = 8; eventValue(child.score());
        eventValue(rpgExpandedCharacterCost(p,nil));
        return nil;
    }
    if (verb == 1117)
    {
        local p = new RpgExpandedProfile(); p.rules = new RpgExpandedRules(); p.st = 12;
        local t = new RpgExpandedTechnique(); t.owner = p; t.attribute = rpgST;
        t.hard = true; t.penalty = -4; t.maximumAboveSkill = 3; t.points = 8;
        event('test.technique-bases'); eventValue(t.score());
        t.points = 9;
        try { t.score(); eventValue('unexpected-success'); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        t.maximumAboveSkill = nil; t.points = 20; eventValue(t.score());
        t.parentTechnique = t;
        try { t.score(); eventValue('unexpected-success'); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        t.attribute = nil;
        try { t.score(); eventValue('unexpected-success'); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        local other = new RpgExpandedTechnique(); other.owner = new RpgExpandedProfile();
        t.parentTechnique = other;
        try { t.score(); eventValue('unexpected-success'); }
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
    if (verb == 1119)
    {
        local p = new RpgExpandedProfile(); p.rules = new RpgExpandedRules();
        p.developmentOpen = true; p.unspentPoints = 10;
        local basic = new RpgExpandedSkill(); local advanced = new RpgExpandedSkill();
        local req = new RpgExpandedPrerequisite(); req.skill = basic;
        advanced.prerequisite = req;
        local training = new RpgExpandedTraining(); training.skill = advanced; training.points = 0;
        p.skills = [training];
        local offer = new RpgDevelopment(); offer.profile = p; offer.training = training;
        offer.unlocked = true;
        local study = new RpgExpandedStudy(); study.profile = p; study.training = training;
        study.permitted = true;
        event('test.learning-gates'); eventValue(rpgDevelop(offer).reason);
        eventValue(study.advance(3600).reason); eventValue(p.unspentPoints);
        eventValue(training.points); eventValue(study.credit); eventValue(p.developmentRevision);
        training.points = 1;
        try { rpgExpandedValidateCharacter(p); eventValue('unexpected-success'); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        return nil;
    }
    if (verb == 1120)
    {
        event('test.familiarity-state'); eventValue(expandedFamiliarity.practicedSeconds);
        eventValue(expandedFamiliarity.modifier()); eventValue(rpgLedger.seconds);
        eventValue(expandedInvestment.points); eventValue(rpgRandom.draws);
        local context = new RpgExpandedSkillContext(); context.skill = expandedSubject;
        context.familiarity = expandedFamiliarity; context.modifier = 1;
        eventValue(rpgLiteScore(expandedHero,context)); return nil;
    }
    if (verb == 1121)
    {
        local value = expandedFamiliarity.assess(args[1]);
        event('test.familiarity'); eventValue(value.status); eventValue(value.reason);
        eventValue(value.seconds); return nil;
    }
    if (verb == 1122)
    {
        local p = new RpgExpandedProfile(); p.rules = new RpgExpandedRules();
        local skill = new RpgExpandedSkill();
        local training = new RpgExpandedTraining(); training.skill = skill; p.skills = [training];
        local a = new RpgExpandedFamiliarity(); a.owner = p; a.skill = skill;
        a.equipmentType = 'a'; a.initial = true;
        local b = new RpgExpandedFamiliarity(); b.owner = p; b.skill = skill;
        b.equipmentType = 'b'; b.initial = true;
        local c = new RpgExpandedFamiliarity(); c.owner = p; c.skill = skill;
        c.equipmentType = 'c'; c.initial = true;
        p.familiarities = [a,b]; event('test.familiarity-invalid'); eventValue(a.modifier());
        p.familiarities = [a,b,c];
        try { a.modifier(); eventValue('unexpected-success'); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        c.initial = nil; c.equipmentType = 'a';
        try { a.modifier(); eventValue('unexpected-success'); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        p.familiarities = [a,b];
        local context = new RpgExpandedSkillContext(); context.skill = skill; context.familiarity = a;
        try { context.skillUseModifier(expandedHero); eventValue('unexpected-success'); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        return nil;
    }
    if (verb == 1123)
    {
        event('test.technology-modifier');
        eventValue(rpgExpandedTechnologyModifier(args[1],args[2],args[3] == 1)); return nil;
    }
    if (verb == 1124)
    {
        local p = new RpgExpandedProfile(); p.rules = new RpgExpandedRules(); p.iq = 12; p.dx = 12;
        local skill = new RpgExpandedSkill(); skill.attribute = rpgDX;
        skill.techLevel = 5; skill.difficulty = 1;
        local training = new RpgExpandedTraining(); training.skill = skill; training.points = 4;
        p.skills = [training];
        local familiar = new RpgExpandedFamiliarity(); familiar.owner = p; familiar.skill = skill;
        familiar.equipmentType = 'test-device'; p.familiarities = [familiar];
        local context = new RpgExpandedSkillContext(); context.skill = skill;
        context.familiarity = familiar; context.equipmentTL = 7;
        event('test.technology-context'); eventValue(rpgLiteScore(p,context));
        familiar.initial = true; eventValue(rpgLiteScore(p,context));
        skill.attribute = rpgIQ; eventValue(rpgLiteScore(p,context));
        familiar.initial = nil; eventValue(rpgLiteScore(p,context));
        context.equipmentTL = 9; eventValue(rpgLiteScore(p,context));
        eventValue(rpgLiteCheck(p,context).reason);
        skill.techLevel = nil;
        try { context.skillUseModifier(p); eventValue('unexpected-success'); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        return nil;
    }
    if (verb == 1125)
    {
        local p = new RpgExpandedProfile(); p.rules = new RpgExpandedRules(); p.iq = 12;
        local general = new RpgExpandedSkill(); general.difficulty = 2;
        local narrow = rpgExpandedOptionalSpecialty(general,'analysis-narrow','quantitative',true);
        local related = new RpgExpandedSkill(); related.difficulty = 2; related.defaults = [[general,-5]];
        local distant = new RpgExpandedSkill(); distant.defaults = [[related,-2]];
        local nt = new RpgExpandedTraining(); nt.skill = narrow; nt.points = args[1];
        local gt = new RpgExpandedTraining(); gt.skill = general; gt.points = args[2]; gt.defaultFrom = narrow;
        p.skills = [nt,gt];
        event('test.optional-specialty'); eventValue(p.skillScore(narrow));
        eventValue(p.skillScore(general)); eventValue(p.skillScore(related));
        eventValue(p.skillScore(distant)); eventValue(narrow.difficulty);
        return nil;
    }
    if (verb == 1126)
    {
        local general = new RpgExpandedSkill(); general.difficulty = 2;
        event('test.optional-invalid');
        try { rpgExpandedOptionalSpecialty(general,'narrow','field',nil); eventValue('unexpected-success'); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        general.attribute = rpgDX;
        try { rpgExpandedOptionalSpecialty(general,'narrow','field',true); eventValue('unexpected-success'); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        general.attribute = rpgIQ; general.difficulty = 0;
        try { rpgExpandedOptionalSpecialty(general,'narrow','field',true); eventValue('unexpected-success'); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        general.difficulty = 2;
        local req = new RpgExpandedPrerequisite(); req.skill = new RpgExpandedSkill();
        general.prerequisite = req;
        local narrow = rpgExpandedOptionalSpecialty(general,'narrow','field',true);
        local p = new RpgExpandedProfile(); p.rules = new RpgExpandedRules();
        eventValue(p.skillLearningReason(narrow));
        local other = rpgExpandedOptionalSpecialty(general,'other','field',true);
        local first = new RpgExpandedTraining(); first.skill = narrow;
        local second = new RpgExpandedTraining(); second.skill = other;
        p.skills = [first,second];
        try { rpgExpandedValidate(p); eventValue('unexpected-success'); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        return nil;
    }
    return vhylAct(verb,args);
}
modify gameMain initialRoom = expandedRoom;
