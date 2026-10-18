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
recognitionHero: RpgExpandedProfile rules = expandedRules iq = 12 techLevel = 5
    skills = [recognitionTraining]
    familiarities = [recognitionOne,recognitionTwo,recognitionThree,recognitionFour,recognitionFive,recognitionSix,recognitionTarget];
recognitionSkill: RpgExpandedSkill id = 'console-operation' techLevel = 5 difficulty = 1;
recognitionTraining: RpgExpandedTraining skill = recognitionSkill points = 4;
recognitionOne: RpgExpandedFamiliarity owner = recognitionHero skill = recognitionSkill equipmentType = 'one' initial = true;
recognitionTwo: RpgExpandedFamiliarity owner = recognitionHero skill = recognitionSkill equipmentType = 'two' initial = true;
recognitionThree: RpgExpandedFamiliarity owner = recognitionHero skill = recognitionSkill equipmentType = 'three' initial = true;
recognitionFour: RpgExpandedFamiliarity owner = recognitionHero skill = recognitionSkill equipmentType = 'four' initial = true;
recognitionFive: RpgExpandedFamiliarity owner = recognitionHero skill = recognitionSkill equipmentType = 'five' initial = true;
recognitionSix: RpgExpandedFamiliarity owner = recognitionHero skill = recognitionSkill equipmentType = 'six' initial = true;
recognitionTarget: RpgExpandedFamiliarity owner = recognitionHero skill = recognitionSkill equipmentType = 'new' available = true;
recognitionDecision: RpgExpandedFamiliarityRecognition familiarity = recognitionTarget approved = true;
purchaseHero: RpgExpandedProfile rules = expandedRules money = 100;
purchaseItem: RpgLiteItem id = 'field-tools' cost = 40 weight = 200 dr = 3;
purchaseOffer: RpgExpandedAcquisition profile = purchaseHero item = purchaseItem available = true permitted = true;
purchaseStorage: RpgExpandedEquipmentStorage profile = purchaseHero item = purchaseItem destination = 'workshop' accessible = true;
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
        if (code == 8 || code == 9 || code == 10)
        {
            if (code == 10)
            { recognitionDecision.mode = 'improved'; recognitionDecision.similarTo = recognitionOne; }
            else recognitionHero.iq = args[2];
            local value = recognitionDecision.resolve();
            event('test.recognition'); eventValue(value.status); eventValue(value.reason);
            if (code == 9) throw new RpgError();
        }
        if (code == 11 || code == 12)
        {
            local value = purchaseOffer.acquire(); event('test.acquisition');
            eventValue(value.status); eventValue(value.reason); eventValue(value.money);
            if (code == 12) throw new RpgError();
        }
        if (code == 13 || code == 14)
        {
            purchaseStorage.destination = code == 13 ? 'workshop' : nil;
            local value = purchaseStorage.move(); event('test.storage');
            eventValue(value.status); eventValue(value.reason);
        }
        if (code == 15) { purchaseItem.ready = true; purchaseItem.worn = true; }
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
    if (verb == 1127)
    {
        local p = new RpgExpandedProfile(); p.rules = new RpgExpandedRules(); p.dx = 10; p.iq = 14;
        local skill = new RpgExpandedSkill(); skill.attribute = rpgDX; skill.difficulty = 1;
        local training = new RpgExpandedTraining(); training.skill = skill; training.points = 28;
        p.skills = [training];
        local context = new RpgExpandedSkillContext(); context.skill = skill; context.rollAttribute = rpgIQ;
        event('test.relative-skill'); eventValue(rpgExpandedRelativeSkill(p,skill));
        eventValue(rpgLiteScore(p,context));
        context.rollAttribute = nil; context.fixedBase = 10; eventValue(rpgLiteScore(p,context));
        context.fixedBase = nil; context.rollAttribute = rpgIQ; context.modifier = -2;
        eventValue(rpgLiteScore(p,context));
        context.fixedBase = 10;
        try { rpgLiteScore(p,context); eventValue('unexpected-success'); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        p.shock = 2; context.fixedBase = nil; eventValue(rpgLiteScore(p,context));
        context.rollAttribute = rpgHT; eventValue(rpgLiteScore(p,context));
        context.rollAttribute = nil; context.fixedBase = 10; eventValue(rpgLiteScore(p,context));
        return nil;
    }
    if (verb == 1128)
    {
        local p = new RpgExpandedProfile(); p.rules = new RpgExpandedRules(); p.iq = args[1]; p.st = 12;
        local skill = new RpgExpandedSkill(); skill.difficulty = 2;
        local training = new RpgExpandedTraining(); training.skill = skill; training.points = args[2];
        p.skills = [training];
        local context = new RpgExpandedSkillContext(); context.skill = skill; context.fixedBase = 10;
        event('test.fixed-skill'); eventValue(rpgLiteScore(p,context));
        eventValue(rpgExpandedSkillStrength(p,skill)); return nil;
    }
    if (verb == 1129)
    {
        local p = new RpgExpandedProfile(); p.rules = new RpgExpandedRules(); p.techLevel = 3;
        local skill = new RpgExpandedSkill(); skill.techLevel = 5; skill.attribute = rpgDX;
        local teacher = new RpgExpandedProfile(); teacher.rules = p.rules; teacher.techLevel = 5;
        local tt = new RpgExpandedTraining(); tt.skill = skill; teacher.skills = [tt];
        event('test.technology-learning'); eventValue(p.skillLearningWithTeacherReason(skill,teacher));
        p.creationComplete = true; eventValue(p.skillLearningWithTeacherReason(skill,nil));
        eventValue(p.skillLearningWithTeacherReason(skill,p));
        eventValue(p.skillLearningWithTeacherReason(skill,teacher));
        tt.points = 0; eventValue(p.skillLearningWithTeacherReason(skill,teacher));
        tt.points = 1; skill.attribute = rpgIQ; eventValue(p.skillLearningWithTeacherReason(skill,teacher));
        p.techLevel = 5; eventValue(p.skillLearningWithTeacherReason(skill,nil));
        p.iq = 5; eventValue(p.skillLearningWithTeacherReason(skill,teacher));
        skill.techLevel = nil; eventValue(p.skillLearningWithTeacherReason(skill,nil));
        return nil;
    }
    if (verb == 1130)
    {
        local p = new RpgExpandedProfile(); p.rules = new RpgExpandedRules();
        p.techLevel = 3; p.creationComplete = true; p.developmentOpen = true; p.unspentPoints = 5;
        local skill = new RpgExpandedSkill(); skill.techLevel = 5; skill.attribute = rpgDX;
        local training = new RpgExpandedTraining(); training.skill = skill; training.points = 0;
        p.skills = [training];
        local offer = new RpgDevelopment(); offer.profile = p; offer.training = training; offer.unlocked = true;
        local teacher = new RpgExpandedProfile(); teacher.rules = p.rules; teacher.techLevel = 5;
        local tt = new RpgExpandedTraining(); tt.skill = skill; teacher.skills = [tt];
        local study = new RpgExpandedStudy(); study.profile = p; study.training = training;
        study.permitted = true; study.teacher = teacher; study.teachingScore = 12;
        event('test.technology-learning-gates'); eventValue(rpgDevelop(offer).reason);
        eventValue(study.advance(100).reason); eventValue(p.unspentPoints); eventValue(training.points);
        offer.teacher = teacher; eventValue(rpgAssessDevelopment(offer).status);
        study.mode = 'education'; eventValue(study.assess(100).status);
        p.iq = 5; eventValue(study.advance(100).reason); eventValue(study.credit);
        return nil;
    }
    if (verb == 1131)
    {
        event('test.recognition-state'); eventValue(recognitionTarget.recognitionAttempted);
        eventValue(recognitionTarget.recognized ? 1 : 0); eventValue(rpgRandom.draws);
        eventValue(rpgLedger.seconds); eventValue(recognitionTarget.modifier());
        eventValue(recognitionTarget.recognitionCheck == nil ? nil : recognitionTarget.recognitionCheck.roll);
        local context = new RpgExpandedSkillContext(); context.skill = recognitionSkill;
        context.familiarity = recognitionTarget; context.equipmentTL = 7;
        eventValue(rpgLiteScore(recognitionHero,context)); return nil;
    }
    if (verb == 1132)
    {
        local value = recognitionDecision.assess();
        event('test.recognition'); eventValue(value.status); eventValue(value.reason); return nil;
    }
    if (verb == 1133)
    {
        local p = new RpgExpandedProfile(); p.rules = new RpgExpandedRules();
        local skill = new RpgExpandedSkill();
        local training = new RpgExpandedTraining(); training.skill = skill; training.points = 4;
        p.skills = [training];
        local source = new RpgExpandedFamiliarity(); source.owner = p; source.skill = skill;
        source.equipmentType = 'known'; source.initial = true;
        local target = new RpgExpandedFamiliarity(); target.owner = p; target.skill = skill;
        target.equipmentType = 'new'; target.available = true; p.familiarities = [source,target];
        local decision = new RpgExpandedFamiliarityRecognition(); decision.familiarity = target;
        event('test.recognition-gates'); eventValue(decision.assess().reason);
        decision.approved = true; eventValue(decision.assess().reason);
        decision.mode = 'similar'; decision.similarTo = source; eventValue(decision.assess().status);
        source.initial = nil; eventValue(decision.assess().reason);
        decision.similarTo = recognitionOne;
        try { decision.assess(); eventValue('unexpected-success'); }
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
    if (verb == 1140)
    {
        event('test.size-modifier'); eventValue(rpgExpandedSizeModifier(args[1],args[2])); return nil;
    }
    if (verb == 1141)
    {
        event('test.speed-range');
        eventValue(rpgExpandedSpeedRangeModifier(args[1],args[2],args[3] == 1)); return nil;
    }
    if (verb == 1142)
    {
        local skill = new RpgExpandedSkill(); if (args[2] == 1) skill.techLevel = 8;
        local equipment = new RpgExpandedEquipmentAssessment(); equipment.quality = args[1];
        equipment.missingItems = args[3]; equipment.damagePenalty = args[4]; equipment.techLevel = args[5];
        equipment.allowWithoutEquipment = args[6] == 1;
        local value = equipment.assess(skill); event('test.equipment-quality');
        eventValue(value.status); eventValue(value.reason); eventValue(value.modifier); return nil;
    }
    if (verb == 1143)
    {
        local p = new RpgExpandedProfile(); p.rules = new RpgExpandedRules(); p.iq = 12; p.techLevel = 8;
        local skill = new RpgExpandedSkill(); skill.techLevel = 8;
        local training = new RpgExpandedTraining(); training.skill = skill; training.points = 4;
        p.skills = [training];
        local familiar = new RpgExpandedFamiliarity(); familiar.owner = p; familiar.skill = skill;
        familiar.equipmentType = 'tools'; p.familiarities = [familiar];
        local equipment = new RpgExpandedEquipmentAssessment(); equipment.quality = 'good'; equipment.damagePenalty = 1;
        local context = new RpgExpandedSkillContext(); context.skill = skill;
        context.familiarity = familiar; context.equipmentTL = 9; context.modifier = -1;
        context.equipmentAssessment = equipment;
        event('test.equipment-context'); eventValue(rpgLiteScore(p,context));
        equipment.quality = 'none'; equipment.damagePenalty = 0;
        eventValue(rpgLiteCheck(p,context).reason);
        equipment.quality = 'improvised'; equipment.damagePenalty = 1;
        try { rpgLiteScore(p,context); eventValue('unexpected-success'); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        return nil;
    }
    if (verb == 1144)
    {
        event('test.acquisition-state'); eventValue(purchaseHero.money);
        eventValue(purchaseHero.equipment.length()); eventValue(purchaseOffer.claimed);
        eventValue(purchaseHero.loadHundredths()); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws);
        return nil;
    }
    if (verb == 1145)
    {
        local value = purchaseOffer.assess(); event('test.acquisition');
        eventValue(value.status); eventValue(value.reason); eventValue(value.money); return nil;
    }
    if (verb == 1146)
    {
        local p = new RpgExpandedProfile(); p.rules = new RpgExpandedRules(); p.money = 10;
        local item = new RpgLiteItem(); item.cost = 20;
        local offer = new RpgExpandedAcquisition(); offer.profile = p; offer.item = item;
        event('test.acquisition-gates'); eventValue(offer.assess().reason);
        offer.available = true; eventValue(offer.assess().reason);
        offer.permitted = true; eventValue(offer.assess().reason);
        offer.mode = 'issue'; eventValue(offer.assess().status); eventValue(offer.assess().money);
        offer.quote = 5;
        try { offer.assess(); eventValue('unexpected-success'); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        offer.quote = nil; offer.item = purchaseItem; eventValue(offer.assess().reason);
        return nil;
    }
    if (verb == 1147)
    {
        event('test.storage-state'); eventValue(purchaseItem.storageLocation);
        eventValue(purchaseItem.worn); eventValue(purchaseItem.ready);
        eventValue(purchaseHero.loadHundredths()); eventValue(rpgLiteArmor(purchaseHero));
        eventValue(purchaseHero.equipment.length()); eventValue(purchaseHero.money); return nil;
    }
    if (verb == 1148)
    {
        local p = new RpgExpandedProfile(); p.rules = new RpgExpandedRules();
        local weapon = new RpgLiteWeapon(); weapon.ready = true; weapon.storageLocation = 'store';
        weapon.reserves = 10;
        local mode = new RpgLiteAttackMode(); mode.ranged = true; mode.base = 'fixed';
        weapon.modes = [mode]; p.equipment = [weapon];
        local fighter = new RpgLiteFighter(); fighter.profile = p; fighter.weapon = weapon;
        local request = new RpgLiteManeuver();
        event('test.stored-use'); eventValue(rpgLiteStrike(fighter,fighter,request).reason);
        eventValue(rpgLiteReloadSeconds(p,weapon,mode));
        local storage = new RpgExpandedEquipmentStorage(); storage.profile = p; storage.item = weapon;
        eventValue(storage.assess().reason);
        weapon.db = 2; fighter.shield = weapon; mode.ranged = nil;
        local shieldSkill = new RpgExpandedSkill(); shieldSkill.defaultPenalty = 0;
        fighter.shieldSkill = shieldSkill;
        eventValue(rpgLiteDefenseScore(fighter,fighter,request,'block'));
        eventValue(rpgLiteDefenseScore(fighter,fighter,request,'dodge'));
        weapon.storageLocation = nil;
        eventValue(rpgLiteDefenseScore(fighter,fighter,request,'block'));
        eventValue(rpgLiteDefenseScore(fighter,fighter,request,'dodge'));
        return nil;
    }
    if (verb == 1149)
    {
        local policy = new RpgExpandedLegalAccess(); policy.controlRating = args[1];
        policy.legality = args[2]; policy.role = args[3]; policy.licensed = args[4] == 1;
        local value = policy.assess(); event('test.legal-table'); eventValue(value.status);
        eventValue(value.reason); eventValue(value.requirement); return nil;
    }
    if (verb == 1150)
    {
        local policy = new RpgExpandedLegalAccess(); policy.controlRating = 3; policy.legality = 3;
        policy.registrationRequired = true;
        event('test.legal-access'); eventValue(policy.assess().reason);
        policy.registered = true; eventValue(policy.assess().status);
        policy.excluded = true; eventValue(policy.assess().reason);
        policy.legality = 4; policy.citizen = nil; eventValue(policy.assess().reason);
        policy.exception = 'allow'; eventValue(policy.assess().status);
        policy.exception = 'deny'; eventValue(policy.assess().reason);
        policy.exception = 'table'; policy.legality = 2; policy.legitimateNeed = true;
        eventValue(policy.assess().licenseEligible); eventValue(policy.assess().reason);
        local p = new RpgExpandedProfile(); p.rules = new RpgExpandedRules(); p.money = 100;
        local item = new RpgLiteItem(); item.cost = 20;
        local offer = new RpgExpandedAcquisition(); offer.profile = p; offer.item = item;
        offer.available = true; offer.permitted = true; offer.legalAccess = policy; policy.subject = p; policy.equipment = item;
        eventValue(offer.acquire().reason); eventValue(p.money); eventValue(p.equipment.length());
        policy.licensed = true; eventValue(offer.assess().status); return nil;
    }
    return vhylAct(verb,args);
}
modify gameMain initialRoom = expandedRoom;
