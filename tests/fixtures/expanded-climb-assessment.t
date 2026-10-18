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
    if (verb == 2295)
    {
        local value = rpgExpandedAssessLanding(args[1],args[2] == 1 ? 'acrobatics' : 'dive',args[3] == 1,args[4] == 1,args[5],args[6]);
        event('test.landing'); eventValue(value.status); eventValue(value.reason);
        eventValue(value.effectiveDistance); eventValue(value.velocity); eventValue(value.modifier);
        eventValue(value.negatesDamage ? 1 : 0); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
    }
    if (verb == 2293)
    {
        local value = rpgExpandedAssessClimbFall(args[1],args[2],args[3],args[4] == 1,args[4] == 1 ? args[5] : nil);
        event('test.climb-fall'); eventValue(value.check.achieved ? 1 : 0); eventValue(value.check.critical);
        eventValue(value.falls ? 1 : 0); eventValue(value.ropeLimited ? 1 : 0);
        eventValue(value.distanceFeet); eventValue(value.impactRequired ? 1 : 0);
        eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
    }
    if (verb == 2294)
    {
        event('test.fall-velocity'); eventValue(rpgExpandedFallVelocity(args[1]));
        eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
    }
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
