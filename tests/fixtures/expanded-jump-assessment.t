#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-exploration.t>
jumpRoom: Room 'Jump practice';
modify gameMain initialRoom = jumpRoom;
startup() { return vhylStart(); }
act(verb,args)
{
    if (verb == 2292)
    {
        local value = rpgExpandedAssessJump(args[1],args[2],args[3] < 0 ? nil : args[3],args[4] == 1,args[5]);
        event('test.jump-assessment'); eventValue(value.status); eventValue(value.reason); eventValue(value.basis);
        eventValue(value.highInchTenths); eventValue(value.broadInchTenths);
        eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    return rpgDispatchAction(verb,args);
}
