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
    return vhylAct(verb,args);
}
