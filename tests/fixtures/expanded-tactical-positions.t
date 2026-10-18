#include <vhyl.h>
#include <vhyl.t>
#include <vhyl-en.t>
#include <vhyl-actions.t>
#include <vhyl-rpg.t>
#include <vhyl-rpg-progression.t>
#include <vhyl-rpg-lite.t>
#include <vhyl-rpg-expanded.t>
#include <vhyl-rpg-expanded-tactical.t>
positionRoom: Room 'Courtyard';
modify gameMain initialRoom = positionRoom;
startup() { rpgRandom.seed(1); return vhylStart(); }
positionRules: RpgExpandedRules;
positionHero: RpgExpandedProfile rules = positionRules;
positionOther: RpgExpandedProfile rules = positionRules;
positionOrigin: RpgExpandedHex;
positionEast: RpgExpandedHex q = 1;
positionWest: RpgExpandedHex q = -1;
positionNorth: RpgExpandedHex r = -1;
positionOutside: RpgExpandedHex q = 2;
positionCell: RpgExpandedHexTerrain coordinate = positionOrigin;
positionEastCell: RpgExpandedHexTerrain coordinate = positionEast;
positionWestCell: RpgExpandedHexTerrain coordinate = positionWest barrier = 'solid';
positionNorthCell: RpgExpandedHexTerrain coordinate = positionNorth barrier = 'partial';
positionMap: RpgExpandedTacticalMap id = 'courtyard'
    cells = [positionCell,positionEastCell,positionWestCell,positionNorthCell];
positionFigure: RpgExpandedTacticalFigure id = 'investigator' profile = positionHero;
positionSecondFigure: RpgExpandedTacticalFigure id = 'witness' profile = positionOther;
positionPlacement: RpgExpandedTacticalPlacement id = 'arrival' map = positionMap figure = positionFigure
    coordinate = positionOrigin facing = 2 approved = true evidence = 'Encounter begins beside the gate';
positionSecond: RpgExpandedTacticalPlacement id = 'witness-arrival' map = positionMap figure = positionSecondFigure
    coordinate = positionEast facing = 5 approved = true evidence = 'Witness is east of the gate';
positionInput: object code = 0;
class PositionTestAction: Action
    exec(context)
    {
        local code = positionInput.code;
        if (code == 3) { positionPlacement.coordinate = positionWest; return nil; }
        if (code == 4) { positionPlacement.coordinate = positionOutside; return nil; }
        if (code == 5) { positionPlacement.coordinate = positionNorth; return nil; }
        if (code == 6) { positionSecond.coordinate = positionOrigin; return nil; }
        if (code == 7) { positionHero.posture = 'lying'; return nil; }
        if (code == 8) { positionHero.posture = 'standing'; return nil; }
        if (code == 9) { positionPlacement.approved = nil; return nil; }
        if (code == 10) { positionMap.cells = positionMap.cells + [positionCell]; return nil; }
        if (code == 11) { positionSecondFigure.profile = positionHero; return nil; }
        if (code == 12) { positionPlacement.coordinate = positionEast; return nil; }
        if (code == 13) { positionFigure.bodyForm = 'horizontal'; return nil; }
        local request = code == 20 || code == 21 ? positionSecond : positionPlacement;
        event('test.tactical-placement');
        try
        {
            local value = code == 1 || code == 21 ? request.assess() : request.apply();
            eventValue(value.status); eventValue(value.reason);
        }
        catch (RpgExpandedError error) { eventValue('error'); eventValue(error.reason); }
        if (code == 2) throw new RpgError(); return nil;
    }
;
positionAction: PositionTestAction;
positionVerb: Verb code = 2278 action = positionAction label = 'position operation';
act(verb,args)
{
    if (verb == 2278) { positionInput.code = args[1]; return vhylAct(verb,args); }
    if (verb == 2279)
    {
        event('test.tactical-position-state');
        eventValue(positionMap.figures.length()); eventValue(positionMap.placements.length());
        eventValue(positionFigure.map == positionMap ? 1 : 0);
        eventValue(positionHero.tacticalFigure == positionFigure ? 1 : 0);
        eventValue(positionFigure.coordinate == nil ? nil : positionFigure.coordinate.q);
        eventValue(positionFigure.coordinate == nil ? nil : positionFigure.coordinate.r);
        eventValue(positionFigure.facing); eventValue(positionHero.posture);
        eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
    }
    if (verb == 2280)
    {
        event('test.tactical-occupancy');
        try
        {
            local value = positionMap.occupancy(positionOrigin);
            eventValue(value.status); eventValue(value.reason); eventValue(value.occupants.length());
        }
        catch (RpgExpandedError error) { eventValue('error'); eventValue(error.reason); }
        return nil;
    }
    return vhylAct(verb,args);
}
