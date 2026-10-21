#include "expanded-panic-path.t"
modify positionRules scaledInjuryShock = true;
interruptedMove: RpgExpandedInterruptedPathMove id = 'interrupted-flight' fighter = pathFighter battle = pathBattle path = pathRequest
    reducedMovePolicy = 'stop' interruptions = [routeFirst,routeSecond]
    evidence = 'The route crosses two predeclared injury triggers; stop if injury reduces the allowance';
routeWound: RpgExpandedWound id = 'first-route-injury' profile = positionHero amount = 1;
routeSecondWound: RpgExpandedWound id = 'second-route-injury' profile = positionHero amount = 1;
routeFirst: RpgExpandedPathInjuryInterruption move = interruptedMove afterLeg = 1 wound = routeWound fallUpper = positionOrigin
    approved = true triggerEvidence = 'A fixed trap triggers on entry to the first hex'
    injuryEvidence = 'The authored trap has already resolved damage, protection and final torso injury';
routeSecond: RpgExpandedPathInjuryInterruption move = interruptedMove afterLeg = 2 wound = routeSecondWound fallUpper = positionEast
    approved = true triggerEvidence = 'A second fixed trap triggers only on entry to the second hex'
    injuryEvidence = 'The second trap causes the separately recorded final torso injury';
modify pathPanicOperation move = interruptedMove;
modify panicPathManeuver operation = interruptedMove;
modify PositionTestAction
    exec(context)
    {
        local code = positionInput.code;
        if (code == 220)
        {
            local value = interruptedMove.result;
            event('test.interrupted-path'); eventValue(positionFigure.coordinate.q); eventValue(positionFigure.coordinate.r);
            eventValue(positionFigure.upperCoordinate == nil ? nil : positionFigure.upperCoordinate.q);
            eventValue(positionHero.injury); eventValue(positionHero.expandedWounds.length());
            eventValue(value == nil ? 0 : value.completedLegs); eventValue(value == nil ? nil : value.stoppedReason);
            eventValue(value == nil ? 0 : value.spentHalfPoints); eventValue(positionHero.pathMoves.length());
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 221) { routeWound.amount = 6; return nil; }
        if (code == 222) { routeWound.amount = 2; interruptedMove.assess(); return nil; }
        if (code == 223) { routeFirst.fallUpper = positionWest; return nil; }
        if (code == 224) { interruptedMove.reducedMovePolicy = nil; return nil; }
        if (code == 225) { routeSecond.afterLeg = 1; return nil; }
        if (code == 226) { routeSecondWound.apply(); return nil; }
        if (code == 227) { positionHero.injury = 6; return nil; }
        if (code == 228) { routeFirst.triggerEvidence = nil; return nil; }
        if (code == 229) { routeFirst.apply([1,0,0,2]); return nil; }
        return inherited(context);
    }
;
