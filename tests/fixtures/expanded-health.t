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
    return vhylAct(verb,args);
}
