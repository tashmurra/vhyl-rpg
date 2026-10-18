#include "expanded-tactical-positions.t"
modify positionPlacement facing = 0;
pathFar: RpgExpandedHex q = 2;
pathDiagonal: RpgExpandedHex q = 1 r = 1;
pathFarCell: RpgExpandedHexTerrain coordinate = pathFar;
pathDiagonalCell: RpgExpandedHexTerrain coordinate = pathDiagonal;
modify positionMap cells = [positionCell,positionEastCell,positionWestCell,positionNorthCell,pathFarCell,pathDiagonalCell];
pathFirst: RpgExpandedPathLeg destination = positionEast;
pathSecond: RpgExpandedPathLeg destination = pathFar;
pathTurn: RpgExpandedPathLeg kind = 'turn' heading = 1;
pathRequest: RpgExpandedMovementPath figure = positionFigure move = 5 legs = [pathFirst,pathSecond];
modify PositionTestAction
    exec(context)
    {
        local code = positionInput.code;
        if (code < 70) return inherited(context);
        if (code == 70) { positionPlacement.apply(); return nil; }
        if (code == 71) pathRequest.move = 1;
        if (code == 72) { pathRequest.legs = [pathFirst]; positionHero.posture = 'kneeling'; }
        if (code == 73) { positionSecond.apply(); pathRequest.allies = [positionSecondFigure]; }
        if (code == 74) pathRequest.legs = [pathFirst];
        if (code == 75) pathRequest.allies = [];
        if (code == 76) positionEastCell.water = 'deep';
        if (code == 77) pathSecond.destination = pathDiagonal;
        if (code == 78) pathRequest.legs = [pathTurn,pathFirst];
        if (code == 79) pathRequest.finalFacing = 3;
        if (code == 80) { positionHero.posture = 'crouching'; pathRequest.move = 3; }
        if (code == 81) pathRequest.finalFacing = 1;
        if (code == 82) pathRequest.maneuver = 'committed-attack';
        local value = pathRequest.assess();
        event('test.tactical-path'); eventValue(value.status); eventValue(value.reason);
        eventValue(value.destination == nil ? nil : value.destination.q);
        eventValue(value.destination == nil ? nil : value.destination.r);
        eventValue(value.heading); eventValue(value.halfPoints); eventValue(value.allowanceHalfPoints);
        eventValue(value.enteredHexes); eventValue(value.minimumProgress); eventValue(value.wholeAllowance);
        eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
    }
;
