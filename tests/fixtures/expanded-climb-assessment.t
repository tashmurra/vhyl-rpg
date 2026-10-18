#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-exploration.t>
climbRoom: Room 'Cliff base';
modify gameMain initialRoom = climbRoom;
startup() { return vhylStart(); }
act(verb,args)
{
    if (verb == 2292)
    {
        local surfaces = ['ladder-up','ladder-down','tree','mountain','stone-wall','building','rope-up','rope-down','rappel'];
        local value = rpgExpandedAssessClimb(surfaces[args[1]],args[2],args[3],args[4] == 1,args[5]);
        event('test.climb-assessment'); eventValue(value.unit); eventValue(value.rateNumerator);
        eventValue(value.rateDenominator); eventValue(value.seconds); eventValue(value.modifier);
        eventValue(value.checkCount); eventValue(value.fatigueCost); eventValue(value.maneuver);
        eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
    }
    return vhylAct(verb,args);
}
