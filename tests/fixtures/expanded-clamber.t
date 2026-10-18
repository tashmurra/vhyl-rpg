#include "expanded-path-move.t"
clamberOperation: RpgExpandedClamber id = 'platform-clamber' fighter = pathFighter battle = pathBattle
    figure = positionFigure origin = positionOrigin destination = positionEast reachable = true stableSurface = true
    evidence = 'Adjacent upper platform with reachable handholds and stable support, requiring no separate hazard check';
modify PositionTestAction
    exec(context)
    {
        local code = positionInput.code;
        if (code == 140 || code == 141)
        {
            local gate = new RpgExpandedActionGate(); gate.profile = positionHero; gate.requiresMovement = true;
            gate.id = ['clamber-one','clamber-two','clamber-three','clamber-four'][pathBattle.seconds + 1];
            gate.evidence = 'Move turn to clamber onto the platform';
            local request = new RpgExpandedClamberManeuver(); request.operation = clamberOperation; request.healthGate = gate;
            pathBattle.step(pathFighter,request); if (code == 141) throw new RpgError(); return nil;
        }
        if (code == 142)
        {
            event('test.clamber'); eventValue(clamberOperation.turns); eventValue(positionFigure.coordinate.q);
            eventValue(clamberOperation.result != nil ? 1 : 0); eventValue(positionHero.clambers.length());
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 143) { pathBattle.step(pathFighter,new RpgLiteManeuver()); return nil; }
        if (code == 144) { clamberOperation.reachable = nil; return nil; }
        return inherited(context);
    }
;
