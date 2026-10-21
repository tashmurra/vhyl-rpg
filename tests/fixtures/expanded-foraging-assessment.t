#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-exploration.t>
#include <vhyl-rpg-expanded-health.t>
forageRoom: Room 'Forage clearing';
modify gameMain initialRoom = forageRoom;
startup() { return vhylStart(); }
act(verb,args)
{
    if (verb == 2292)
    {
        local site = new RpgExpandedForageSite(); site.id = 'clearing'; site.evidence = 'Authored local resources and scarcity';
        site.plantsAvailable = args[4] == 1; site.gameAvailable = args[4] == 1; site.waterAvailable = args[4] == 1;
        site.scarcityPenalty = args[5]; site.repeatedUsePenalty = args[6];
        local value = site.assess(['plants','hunting','fishing'][args[1]],args[2],args[3]);
        event('test.forage'); eventValue(value.status); eventValue(value.reason); eventValue(value.meals);
        eventValue(value.poisonScope); eventValue(value.score); eventValue(value.group);
        eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    if (verb == 2293)
    {
        local value = rpgExpandedAssessForagePoison(args[1],args[2],args[3]);
        event('test.forage-poison'); eventValue(value.status); eventValue(value.reason); eventValue(value.injury);
        eventValue(value.damageDieRequired ? 1 : 0); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    return rpgDispatchAction(verb,args);
}
