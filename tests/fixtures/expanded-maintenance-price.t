#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-traits.t>
maintenanceRoom: Room 'Service Desk';
modify gameMain initialRoom = maintenanceRoom;
startup() { return vhylStart(); }
act(verb,args)
{
    if (verb == 2070)
    {
        local draws = rpgRandom.draws; local clock = rpgLedger.seconds;
        event('test.maintenance-price'); eventValue(rpgExpandedMaintenanceBase(args[1]));
        eventValue(rpgExpandedMaintenanceCost(args[1],args[2]));
        event('test.maintenance-purity'); eventValue(rpgRandom.draws-draws); eventValue(rpgLedger.seconds-clock); return nil;
    }
    return rpgDispatchAction(verb,args);
}
