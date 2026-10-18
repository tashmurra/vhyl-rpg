#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-exploration.t>
loadRoom: Room 'Loading yard';
modify gameMain initialRoom = loadRoom;
startup() { return vhylStart(); }
act(verb,args)
{
    if (verb == 2292)
    {
        local value = rpgExpandedAssessLift(args[1],args[2],['one-hand','two-hands','shove','back','shift'][args[3]],
            args[4] == 1,args[5] == 1,args[6] == 1);
        event('test.lift'); eventValue(value.status); eventValue(value.reason);
        eventValue(value.capacityHundredths); eventValue(value.seconds); eventValue(value.maneuver);
        eventValue(value.fatiguePerSecond); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
    }
    if (verb == 2293)
    {
        local value = rpgExpandedAssessDragging(args[1],args[2],args[3],['none','snow-sledge','cart','wagon'][args[4]],args[5] == 1);
        event('test.drag'); eventValue(value.status); eventValue(value.reason);
        eventValue(value.effectiveNumerator); eventValue(value.effectiveDenominator);
        eventValue(value.encumbranceLevel); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
    }
    if (verb == 2297)
    {
        local profile = new RpgExpandedProfile(); profile.st = args[1];
        local value = rpgExpandedAssessLift(profile.basicLiftHundredths(),args[2],'one-hand',nil,nil,nil);
        event('test.load-strength'); eventValue(profile.basicLiftHundredths());
        eventValue(value.seconds); eventValue(value.status); return nil;
    }
    return vhylAct(verb,args);
}
