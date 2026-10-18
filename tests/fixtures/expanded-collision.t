#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-skills.t>
#include <vhyl-rpg-expanded-health.t>
#include <vhyl-rpg-expanded-hazards.t>
collisionRoom: Room 'Landing';
modify gameMain initialRoom = collisionRoom;
startup() { return vhylStart(); }
act(verb,args)
{
    if (verb == 2293)
    {
        local value = rpgExpandedAssessFallProtection(args[1],args[2],args[3] == 1 ? 'armor' : 'innate');
        event('test.fall-protection'); eventValue(value.penetratingDamage);
        eventValue(value.bluntInjury); eventValue(value.stoppedDamage);
        eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
    }
    if (verb == 2292)
    {
        local value = rpgExpandedAssessCollision(args[1],args[2],args[3] == 1);
        event('test.collision'); eventValue(value.capacity); eventValue(value.velocity);
        eventValue(value.damageDice); eventValue(value.damageAdds); eventValue(value.damageType);
        eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
    }
    return vhylAct(verb,args);
}
