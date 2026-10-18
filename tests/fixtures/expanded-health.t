#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-health.t>
healthRoom: Room 'Recovery';
modify gameMain initialRoom = healthRoom;
startup() { return vhylStart(); }
act(verb,args)
{
    if (verb == 1600)
    {
        event('test.scaled-shock'); eventValue(rpgExpandedInjuryShock(args[1],args[2])); return nil;
    }
    if (verb == 1601)
    {
        local rules = new RpgExpandedRules(); rules.scaledInjuryShock = args[1] == 1;
        local p = new RpgExpandedProfile(); p.rules = rules; p.st = 30;
        if (args[2] == 1) p.traits = [rpgLiteMakeTrait('high-pain-threshold',1,nil)];
        local before = rpgRandom.draws; rpgLiteWound(p,8); event('test.shock-integration');
        eventValue(p.injury); eventValue(p.shock); rpgLiteWound(p,8);
        eventValue(p.injury); eventValue(p.shock); eventValue(rpgRandom.draws - before); return nil;
    }
    if (verb == 1602)
    {
        local rules = new RpgExpandedRules(); rules.scaledInjuryShock = true;
        local p = new RpgExpandedProfile(); p.rules = rules; p.st = 30;
        local trait = new RpgLiteTrait(); trait.id = 'low-pain-threshold'; p.traits = [trait];
        local before = rpgRandom.draws; event('test.shock-rejection');
        try { rpgLiteWound(p,8); eventValue('unexpected-success'); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        eventValue(p.injury); eventValue(p.shock); eventValue(p.woundSerial);
        eventValue(rpgRandom.draws - before); return nil;
    }
    if (verb == 1603)
    {
        local rules = new RpgExpandedRules(); rules.scaledInjuryShock = args[1] == 1;
        local p = new RpgExpandedProfile(); p.rules = rules; p.st = 30;
        if (args[2] == 1) p.traits = [rpgLiteMakeTrait('high-pain-threshold',1,nil)];
        local before = rpgRandom.draws; event('test.shock-turn');
        eventValue(p.shockAfterTurn(8)); rpgLiteWound(p,8);
        local fighter = new RpgLiteFighter(); fighter.profile = p;
        local other = new RpgLiteFighter(); other.profile = new RpgLiteProfile();
        local battle = new RpgLiteBattle(); battle.fighters = [fighter,other];
        battle.order = [fighter,other]; battle.active = true;
        local value = battle.step(fighter,new RpgLiteManeuver()); eventValue(value.status);
        eventValue(p.shock); eventValue(p.injury); eventValue(rpgRandom.draws - before); return nil;
    }
    if (verb == 1604)
    {
        local value = rpgExpandedAssessKnockdown(args[1],args[2],args[3],args[4] == 1);
        event('test.knockdown-assessment'); eventValue(value.major ? 1 : 0);
        eventValue(value.required ? 1 : 0); eventValue(value.modifier); eventValue(value.shock); return nil;
    }
    if (verb == 1605)
    {
        event('test.knockdown-rejection');
        try { rpgExpandedAssessKnockdown(10,3,'eye',nil); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        try { rpgExpandedAssessKnockdown(10,3,'torso',true); }
        catch (RpgExpandedError error) { eventValue(error.reason); }
        return nil;
    }
    if (verb == 1606)
    {
        local rules = new RpgExpandedRules(); rules.scaledInjuryShock = true;
        local p = new RpgExpandedProfile(); p.rules = rules; p.ht = args[3];
        local wound = new RpgExpandedWound(); wound.id = 'impact'; wound.profile = p;
        wound.amount = args[1]; wound.location = args[2];
        rpgRandom.seed(1); event('test.wound-commit'); local preview = wound.assess();
        eventValue(preview.status); eventValue(preview.reason); eventValue(p.injury); eventValue(rpgRandom.draws);
        local result = wound.apply(); eventValue(result.status); eventValue(p.injury); eventValue(p.shock);
        eventValue(p.stunned ? 1 : 0); eventValue(p.unconscious ? 1 : 0);
        eventValue(result.health == nil ? 0 : result.health.checks.length()); eventValue(rpgRandom.draws);
        eventValue(wound.apply().status); eventValue(p.expandedWounds.length()); return nil;
    }
    if (verb == 1607)
    {
        local rules = new RpgExpandedRules(); rules.scaledInjuryShock = true;
        local p = new RpgExpandedProfile(); p.rules = rules;
        local wound = new RpgExpandedWound(); wound.id = 'impact'; wound.profile = p; wound.amount = 6;
        local item = new RpgLiteItem(); item.ready = true; p.equipment = [item];
        local before = rpgRandom.draws; event('test.wound-gates'); eventValue(wound.apply().reason);
        item.ready = nil; wound.anatomy = 'other'; eventValue(wound.apply().reason);
        wound.anatomy = 'standard-humanoid'; rules.scaledInjuryShock = nil; eventValue(wound.apply().reason);
        eventValue(p.injury); eventValue(p.expandedWounds.length()); eventValue(rpgRandom.draws - before); return nil;
    }
    if (verb == 1608)
    {
        local rules = new RpgExpandedRules(); rules.scaledInjuryShock = true;
        local p = new RpgExpandedProfile(); p.rules = rules;
        local trait = new RpgLiteTrait(); trait.id = args[3]; p.traits = [trait];
        local wound = new RpgExpandedWound(); wound.id = 'anatomy-impact'; wound.profile = p;
        wound.amount = args[1]; wound.location = args[2]; wound.maleGroin = args[4] == 1;
        rpgRandom.seed(1); local value = wound.apply(); event('test.anatomy-wound');
        eventValue(value.status); eventValue(p.injury); eventValue(value.assessment.required ? 1 : 0);
        eventValue(value.assessment.modifier); eventValue(p.stunned ? 1 : 0);
        eventValue(rpgRandom.draws); eventValue(wound.knockdownAssessment.brainException ? 1 : 0);
        eventValue(wound.knockdownAssessment.vitalsException ? 1 : 0); return nil;
    }
    return vhylAct(verb,args);
}
