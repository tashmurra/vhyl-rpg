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
    skills = [expandedInvestment] pointBudget = 1000 developmentOpen = true;
expandedSubject: RpgExpandedSkill id = 'analysis' attribute = rpgIQ difficulty = 3;
expandedInvestment: RpgExpandedTraining skill = expandedSubject points = 1;
expandedStudy: RpgExpandedStudy profile = expandedHero training = expandedInvestment permitted = true;
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
        a.wildcard = nil; local b = new RpgExpandedSkill();
        local bt = new RpgExpandedTraining(); bt.skill = b; bt.points = 1;
        a.defaults = [[b,-2]]; b.defaults = [[a,-2]];
        at.defaultFrom = b; bt.defaultFrom = a; p.skills = [at,bt];
        try { p.skillScore(a); eventValue('unexpected-success'); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        try { rpgExpandedDamageDice(41,nil); eventValue('unexpected-success'); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        return nil;
    }
    return vhylAct(verb,args);
}
modify gameMain initialRoom = expandedRoom;
