#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-exploration.t>
hikeRoom: Room 'Trailhead';
modify gameMain initialRoom = hikeRoom;
startup() { return vhylStart(); }
act(verb,args)
{
    if (verb == 2292)
    {
        local conditions = new RpgExpandedHikingConditions();
        conditions.terrain = ['very-bad','bad','average','good'][args[1]];
        conditions.weather = ['dry','rain','shallow-snow','deep-snow','ice-coating','solid-ice'][args[2]];
        conditions.road = ['none','poor','ordinary','best'][args[3]];
        conditions.roadCleared = args[4] == 1;
        conditions.equipment = ['none','skis','skates'][args[5]];
        conditions.deepSnowDivisor = args[6];
        if (args[7] == 1) conditions.deepSnowEvidence = 'Authored unusually restrictive snow';
        local value = rpgExpandedAssessHiking(args[8],args[9],args[10] == 1,conditions);
        event('test.hiking-assessment'); eventValue(value.status); eventValue(value.reason);
        eventValue(value.effectiveTerrain); eventValue(value.weatherDivisor); eventValue(value.travelSkill);
        eventValue(value.milesHundredths); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
    }
    return rpgDispatchAction(verb,args);
}
