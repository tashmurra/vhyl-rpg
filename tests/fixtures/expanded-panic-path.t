#include "expanded-path-move.t"
pathPanicContext: RpgExpandedFearContext profile = positionHero approved = true evidence = 'A terrifying manifestation blocks the rear exit';
pathPanicEpisode: RpgExpandedExtremePanic id = 'path-panic' context = pathPanicContext approved = true
    evidence = 'The owned extreme reaction is fleeing along the open courtyard';
pathPanicReaction: RpgExpandedExtremePanicReaction id = 'escape-turn' episode = pathPanicEpisode severity = 18
    kind = 'world-operation' operation = pathPanicOperation seconds = 1 approved = true description = 'Flee two hexes toward the open gate';
pathPanicOperation: RpgExpandedPanicPathOperation profile = positionHero reaction = pathPanicReaction
    move = pathOperation maneuver = panicPathManeuver;
panicPathGate: RpgExpandedPanicActionGate id = 'panic-path-permission' profile = positionHero requiresMovement = true
    panicReaction = pathPanicReaction evidence = 'Actual flight still requires physical ability';
panicPathManeuver: RpgExpandedPanicPathManeuver operation = pathOperation healthGate = panicPathGate panicReaction = pathPanicReaction;
pathPanicDice: object index = 0 rolls = [18,18,7];
modify rpgRandom
    roll() { self.draws += 3; pathPanicDice.index += 1; return pathPanicDice.rolls[pathPanicDice.index]; }
;
modify PositionTestAction
    exec(context)
    {
        local code = positionInput.code;
        if (code == 200) { positionPlacement.apply(); pathBattle.order = [pathFighter,pathOtherFighter]; pathBattle.active = true; pathPanicEpisode.apply(); return nil; }
        if (code == 201)
        { local value = pathPanicReaction.assess(); event('test.panic-path-preview'); eventValue(value.status); eventValue(value.reason); return nil; }
        if (code == 202 || code == 203)
        { pathPanicReaction.apply(); if (code == 203) throw new RpgError(); return nil; }
        if (code == 204)
        {
            event('test.panic-path'); eventValue(positionFigure.coordinate.q); eventValue(positionFigure.coordinate.r);
            eventValue(positionHero.pathMoves.length()); eventValue(pathPanicEpisode.reactions.length());
            eventValue(pathBattle.index); eventValue(pathBattle.seconds); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws);
            eventValue(pathPanicEpisode.pendingSeverity); return nil;
        }
        if (code == 205) { pathBattle.step(pathOtherFighter,new RpgLiteManeuver()); return nil; }
        if (code == 206) { pathBattle.step(pathFighter,pathManeuver); return nil; }
        if (code == 207) { rpgSpendTime(1); return nil; }
        if (code == 208) { pathOperation.uninterrupted = nil; return nil; }
        if (code == 210) { pathBattle.order = [pathFighter]; return nil; }
        if (code == 211) { positionHero.stunned = true; return nil; }
        if (code == 209) { pathPanicOperation.battleSecond = 9; pathPanicReaction.assess(); return nil; }
        return inherited(context);
    }
;
