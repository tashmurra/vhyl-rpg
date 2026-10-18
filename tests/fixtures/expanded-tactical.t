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
    if (verb == 2274)
    {
        local modes = ['move','move-attack','committed-attack','increased-dodge'];
        local value = rpgExpandedMovementAllowance(args[1],modes[args[2]]);
        event('test.tactical-allowance'); eventValue(value.halfPoints); eventValue(value.alternativeHexes); return nil;
    }
    if (verb == 2275)
    {
        local request = new RpgExpandedHexEntry(); request.origin = rpgExpandedHex(0,0);
        request.target = rpgExpandedHexNeighbor(request.origin,args[1]);
        request.travel = args[2] == 0 ? 'forward' : 'sidestep';
        request.maneuver = args[3] == 0 ? 'move' : 'committed-attack';
        local postures = ['standing','crouching','kneeling','crawling','lying','sitting'];
        request.posture = postures[args[4]];
        request.terrain = new RpgExpandedHexTerrain(); request.terrain.coordinate = request.target;
        if (args[5] == 1) request.minorObstructions = 2;
        if (args[5] == 2) request.severeObstruction = true;
        if (args[5] == 3) request.enemyPresent = true;
        if (args[5] == 4) { request.treacherous = true; request.stairs = true; request.water = 'shallow'; }
        if (args[5] == 5) request.water = 'deep';
        if (args[5] == 6) request.terrain.barrier = 'solid';
        local value = request.assess(); event('test.tactical-entry');
        eventValue(value.status); eventValue(value.reason); eventValue(value.halfPoints);
        eventValue(value.heading); eventValue(value.wholeAllowance);
        eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
    }
    if (verb == 2276)
    {
        local modes = ['move','move-attack','committed-attack','increased-dodge'];
        local value = rpgExpandedFinalFacing(args[1],args[2],modes[args[3]],args[4],args[5]);
        event('test.tactical-final'); eventValue(value.status); eventValue(value.reason);
        eventValue(value.heading); eventValue(value.halfPoints); return nil;
    }
    if (verb == 2277)
    {
        local modes = ['move','move-attack','committed-attack','increased-dodge'];
        local value = rpgExpandedMovementTurn(args[1],args[2],modes[args[3]]);
        event('test.tactical-turn'); eventValue(value.status); eventValue(value.reason);
        eventValue(value.heading); eventValue(value.halfPoints); return nil;
    }
    return vhylAct(verb,args);
}
