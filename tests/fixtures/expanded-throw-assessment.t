#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-exploration.t>
throwRoom: Room 'Practice field';
modify gameMain initialRoom = throwRoom;
startup() { return vhylStart(); }
act(verb,args)
{
    if (verb == 2292)
    {
        event('test.throw-distance-factor'); eventValue(rpgExpandedThrowDistanceFactor(args[1],args[2]));
        eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    if (verb == 2293)
    {
        local skill = rpgExpandedAssessThrowSkill(['unskilled','throwing','throwing-art'][args[4]],args[5],args[6] == 1,args[7] == 1);
        local value = rpgExpandedAssessThrow(args[1],args[2],args[3],skill);
        event('test.throw-assessment'); eventValue(value.status); eventValue(value.reason);
        eventValue(value.handsRequired); eventValue(value.distanceHundredths);
        eventValue(value.damageDice); eventValue(value.damageAdds); eventValue(value.specificTargetModifier);
        eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
    }
    return rpgDispatchAction(verb,args);
}
