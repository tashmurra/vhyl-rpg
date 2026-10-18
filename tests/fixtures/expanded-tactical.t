#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-tactical.t>
tacticalRoom: Room 'Courtyard';
modify gameMain initialRoom = tacticalRoom;
startup() { rpgRandom.seed(1); return vhylStart(); }
act(verb,args)
{
    if (verb == 2270)
    {
        local request = new RpgExpandedFacingAssessment();
        request.origin = rpgExpandedHex(0,0);
        request.target = rpgExpandedHex(args[2],args[3]);
        request.facing = args[1]; request.handedness = args[4] == 0 ? 'right' : 'left';
        local value = request.assess();
        event('test.tactical-facing'); eventValue(value.status); eventValue(value.reason);
        eventValue(value.heading); eventValue(value.side); eventValue(value.weaponSide); eventValue(value.shieldSide);
        return nil;
    }
    if (verb == 2271)
    {
        event('test.tactical-distance');
        eventValue(rpgExpandedHexDistance(rpgExpandedHex(args[1],args[2]),rpgExpandedHex(args[3],args[4])));
        eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
    }
    if (verb == 2272)
    {
        local terrain = new RpgExpandedHexTerrain(); terrain.coordinate = rpgExpandedHex(0,0);
        terrain.barrier = args[1] == 0 ? 'none' : args[1] == 1 ? 'partial' : 'solid';
        terrain.partialAllowed = args[2] == 0;
        if (args[3] != 0) terrain.rulingEvidence = 'A narrow ledge cannot support this figure';
        event('test.tactical-terrain');
        try { local value = terrain.assess(); eventValue(value.status); eventValue(value.reason); }
        catch (RpgExpandedError error) { eventValue('error'); eventValue(error.reason); }
        eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
    }
    return vhylAct(verb,args);
}
