#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-combat.t>
burstRoom: Room 'Range';
modify gameMain initialRoom = burstRoom;
startup() { return vhylStart(); }
act(verb,args)
{
    local draws = rpgRandom.draws; local clock = rpgLedger.seconds;
    if (verb == 2010) { event('test.burst-bonus'); eventValue(rpgExpandedRapidFireBonus(args[1])); }
    else if (verb == 2011)
    {
        local value = rpgExpandedAssessBurst(args[1],args[2],args[3],args[4]);
        event('test.burst-assessment'); eventValue(value.status); eventValue(value.reason);
        eventValue(value.shots); eventValue(value.modifier);
    }
    else if (verb == 2012)
    { event('test.burst-hits'); eventValue(rpgExpandedRapidFireHits(args[1],args[2],args[3])); }
    else if (verb == 2013)
    {
        local value = rpgExpandedRapidFireDodge(args[1],args[2],args[3]);
        event('test.burst-dodge'); eventValue(value.avoided); eventValue(value.remaining);
        eventValue(value.check.achieved ? 1 : 0); eventValue(value.check.critical);
    }
    else return vhylAct(verb,args);
    event('test.burst-purity'); eventValue(rpgRandom.draws - draws); eventValue(rpgLedger.seconds - clock); return nil;
}
