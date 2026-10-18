#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-exploration.t>
catchRoom: Room 'Practice field';
modify gameMain initialRoom = catchRoom;
startup() { return vhylStart(); }
act(verb,args)
{
    if (verb == 2292)
    {
        local value = rpgExpandedResolveCatch(args[1],args[2] == 1,args[3],args[4],args[5] == 1,args[6]);
        event('test.catch-assessment'); eventValue(value.status); eventValue(value.reason);
        eventValue(value.score); eventValue(value.throwBonus); eventValue(value.waitPenalty);
        eventValue(value.countsAsParry ? 1 : 0); eventValue(value.caught ? 1 : 0);
        eventValue(value.check == nil ? nil : value.check.critical);
        eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    return vhylAct(verb,args);
}
