#include "expanded-jump-launch.t"
#include <vhyl-rpg-expanded-tactical.t>
jumpOrigin: RpgExpandedHex q = 0 r = 0;
jumpEnd: RpgExpandedHex q = 3 r = 0;
jumpFailure: RpgExpandedHex q = 1 r = 0;
jumpFailureUpper: RpgExpandedHex q = 2 r = 0;
jumpCell0: RpgExpandedHexTerrain coordinate = jumpOrigin;
jumpCell1: RpgExpandedHexTerrain coordinate = jumpFailure;
jumpCell2: RpgExpandedHexTerrain coordinate = jumpFailureUpper;
jumpCell3: RpgExpandedHexTerrain coordinate = jumpEnd;
jumpMap: RpgExpandedTacticalMap id = 'jump-map' cells = [jumpCell0,jumpCell1,jumpCell2,jumpCell3];
jumpFigure: RpgExpandedTacticalFigure id = 'jumper' profile = bleedProfile;
jumpSetup: RpgExpandedTacticalPlacement id = 'jumper-start' figure = jumpFigure map = jumpMap
    coordinate = jumpOrigin approved = true evidence = 'Initial position on the west platform';
jumpPosition: RpgExpandedJumpPlacement figure = jumpFigure origin = jumpOrigin destination = jumpEnd
    failure = jumpFailure failureUpper = jumpFailureUpper clearanceApproved = true
    evidence = 'Clear three-yard horizontal arc; failed jumps land prone on the two middle cells';
modify jumpLaunch direction = 'horizontal' requiredInchTenths = 1080 difficult = true positionPlan = jumpPosition;
modify prepDistance runYards = 1;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 1370) { jumpSetup.apply(); return nil; }
        if (code == 1371)
        {
            event('test.jump-position'); eventValue(jumpFigure.coordinate.q); eventValue(jumpFigure.coordinate.r);
            eventValue(jumpFigure.upperCoordinate == nil ? nil : jumpFigure.upperCoordinate.q);
            eventValue(jumpFigure.jumpPlacements.length()); eventValue(rpgRandom.draws);
            eventValue(rpgLedger.seconds); return nil;
        }
        if (code == 1372) { jumpCell2.barrier = 'solid'; return nil; }
        if (code == 1373) { jumpLaunch.positionPlan = nil; return nil; }
        return inherited(context);
    }
;

blockJumpProfile: RpgExpandedProfile rules = bleedRules;
blockJumpFigure: RpgExpandedTacticalFigure id = 'blocker' profile = blockJumpProfile;
blockJumpPlacement: RpgExpandedTacticalPlacement id = 'blocker-start' map = jumpMap figure = blockJumpFigure
    coordinate = jumpFailureUpper approved = true evidence = 'An occupied possible failure landing cell';
modify BleedTestAction
    exec(context)
    {
        if (bleedInput.code == 1374) { blockJumpPlacement.apply(); return nil; }
        return inherited(context);
    }
;
