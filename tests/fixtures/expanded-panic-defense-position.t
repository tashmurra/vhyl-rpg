#include "expanded-panic-defense.t"
#include <vhyl-rpg-expanded-tactical.t>
defenseOrigin: RpgExpandedHex q = 0 r = 0;
defenseUpper: RpgExpandedHex q = 1 r = 0;
defenseCell: RpgExpandedHexTerrain coordinate = defenseOrigin;
defenseUpperCell: RpgExpandedHexTerrain coordinate = defenseUpper;
defenseMap: RpgExpandedTacticalMap id = 'defense-court' cells = [defenseCell,defenseUpperCell];
defenseFigure: RpgExpandedTacticalFigure id = 'defender' profile = attackTarget;
defensePlacement: RpgExpandedTacticalPlacement id = 'defender-entry' map = defenseMap figure = defenseFigure
    coordinate = defenseOrigin approved = true evidence = 'The defender is standing in this hex';
defenseFootprint: RpgExpandedFootprintChange id = 'defense-fall' figure = defenseFigure selected = defenseUpper
    approved = true evidence = 'The adjacent clear hex receives the upper body';
defensePosition: RpgExpandedDefenseFallPosition owner = panicDefenseConsequence figure = defenseFigure
    footprint = defenseFootprint approved = true evidence = 'The grounded defender falls into the authored clear footprint';
defenseBlockerProfile: RpgExpandedProfile rules = fearRules;
defenseBlocker: RpgExpandedTacticalFigure id = 'blocker' profile = defenseBlockerProfile;
defenseBlockerPlacement: RpgExpandedTacticalPlacement id = 'blocker-entry' map = defenseMap figure = defenseBlocker
    coordinate = defenseUpper approved = true evidence = 'Another figure occupies the proposed upper-body hex';
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 770)
        { defensePlacement.apply(); attackTarget.requiresTacticalFall = true; panicDefenseConsequence.position = defensePosition; return nil; }
        if (code == 771)
        {
            event('test.defense-position'); eventValue(attackTarget.posture);
            eventValue(defenseFigure.upperCoordinate == nil ? nil : defenseFigure.upperCoordinate.q);
            eventValue(defenseFigure.footprintChanges.length()); eventValue(attackTarget.injury);
            eventValue(attackTarget.criticalDefenseFailures.length()); eventValue(attackWeapon.ammunition);
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 772) { defensePosition.apply(panicDefenseConsequence); return nil; }
        if (code == 773) { defensePosition.approved = nil; return nil; }
        if (code == 774) { defensePosition.footprint = nil; return nil; }
        if (code == 775) { defenseUpper.q = 2; return nil; }
        if (code == 776) { defenseBlockerPlacement.apply(); return nil; }
        if (code == 777)
        { attackTarget.posture = 'lying'; defenseFootprint.apply(); defensePosition.footprint = nil; return nil; }
        if (code == 778) { defensePosition.evidence = 'changed'; attackDecision.validateReceipt(); return nil; }
        if (code == 779) { defenseMap.occupancy(defenseUpper); attackDecision.validateReceipt(); return nil; }
        return inherited(context);
    }
;
