#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-en.t>
#include <vhyl-actions.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-exploration.t>
diggingRoom: Room 'Excavation';
modify gameMain initialRoom = diggingRoom;
startup() { return vhylStart(); }
act(verb,args)
{
    if (verb == 2290)
    {
        local stages = ['loose','ordinary','ordinary-pick','hard-pick','hard-shovel','hard-solo','rock-pick','rock-shovel'];
        local materials = ['metal','wood','improvised'];
        local rate = rpgExpandedDiggingRate(args[1],stages[args[2]],materials[args[3]],args[4],args[5]);
        local duration = rpgExpandedDiggingDuration(rate,args[6],args[7]);
        event('test.digging'); eventValue(rate.rateNumerator); eventValue(rate.rateDenominator);
        eventValue(rate.fatiguePerHour); eventValue(rate.workKind);
        eventValue(duration.durationNumerator); eventValue(duration.durationDenominator);
        eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    if (verb == 2291)
    { event('test.digging-volume'); eventValue(rpgExpandedDiggingVolume(args[1],args[2],args[3])); return nil; }
    return vhylAct(verb,args);
}
