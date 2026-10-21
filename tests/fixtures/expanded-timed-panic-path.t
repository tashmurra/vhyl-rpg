#include "expanded-path-move.t"
timedPathContext: RpgExpandedFearContext profile = positionHero approved = true evidence = 'An alarming manifestation';
timedPathEpisode: RpgExpandedFearPanic id = 'timed-path-panic' context = timedPathContext approved = true
    evidence = 'Recorded row twenty-one' behaviorKind = 'agitated-motion' behavior = 'Run aimlessly through the courtyard';
timedPathActivity: RpgExpandedTimedPanicPath id = 'first-panic-move' episode = timedPathEpisode
    move = pathOperation maneuver = timedPathManeuver approved = true evidence = 'Two clear hexes of aimless movement';
timedPathGate: RpgExpandedTimedPanicPathGate id = 'timed-path-health' profile = positionHero
    timedPanicActivity = timedPathActivity evidence = 'One physical Move turn during timed panic';
timedPathManeuver: RpgExpandedTimedPanicPathManeuver operation = pathOperation healthGate = timedPathGate
    timedPanicActivity = timedPathActivity;
modify rpgRandom die() { self.draws += 1; return 1; };
modify PositionTestAction
    exec(context)
    {
        local code = positionInput.code;
        if (code == 800)
        { positionPlacement.apply(); pathBattle.order = [pathFighter,pathOtherFighter]; pathBattle.active = true;
          timedPathEpisode.apply(); return nil; }
        if (code == 801 || code == 802 || code == 803)
        {
            local value = code == 801 ? timedPathActivity.assess() : timedPathActivity.apply();
            event('test.timed-panic-path-result'); eventValue(value.status); eventValue(value.reason);
            if (code == 803) throw new RpgError(); return nil;
        }
        if (code == 804)
        {
            event('test.timed-panic-path'); eventValue(positionFigure.coordinate.q); eventValue(positionFigure.coordinate.r);
            eventValue(positionHero.pathMoves.length()); eventValue(timedPathEpisode.activities.length());
            eventValue(positionHero.effortHistory.length()); eventValue(pathBattle.index);
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 805) { pathBattle.step(pathFighter,timedPathManeuver); return nil; }
        if (code == 806) { pathBattle.order = [pathFighter]; return nil; }
        if (code == 807) { timedPathGate.apply(); return nil; }
        if (code == 808) { rpgSpendTime(60); return nil; }
        if (code == 809) { timedPathActivity.evidence = nil; return nil; }
        return inherited(context);
    }
;
