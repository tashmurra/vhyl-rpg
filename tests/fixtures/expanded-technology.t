#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-technology.t>
technologyRoom: Room 'Workshop';
modify gameMain initialRoom = technologyRoom;
startup() { return vhylStart(); }
act(verb,args)
{
    if (verb == 2050)
    {
        local draws = rpgRandom.draws; local clock = rpgLedger.seconds;
        local value = rpgExpandedBrokenWeapon(args[1],args[2],args[3] != 0,args[4],args[5] == 0 ? nil : args[5],args[6]);
        event('test.broken-weapon'); eventValue(value.status); eventValue(value.reason); eventValue(value.usable ? 1 : 0);
        eventValue(value.retainOriginal ? 1 : 0); eventValue(value.cuttingDamageModifier);
        eventValue(value.thrustBase); eventValue(value.thrustDamageType); eventValue(value.reach); eventValue(value.pieces.length());
        foreach (local piece in value.pieces)
        {
            event(piece.placement == 'held' ? 'test.broken-held' : 'test.broken-ground'); eventValue(piece.form); eventValue(piece.placement); eventValue(piece.attackModifier);
            eventValue(piece.reach); eventValue(piece.damageBase); eventValue(piece.damageAdds); eventValue(piece.damageType);
        }
        event('test.broken-purity'); eventValue(rpgRandom.draws-draws); eventValue(rpgLedger.seconds-clock); return nil;
    }
    return vhylAct(verb,args);
}
