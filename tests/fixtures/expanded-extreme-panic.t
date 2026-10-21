#include "expanded-fear-event.t"
extremeEpisode: RpgExpandedExtremePanic id = 'apparition' context = fearContext approved = true evidence = 'Retained extreme panic outcome';
extremeFirst: RpgExpandedExtremePanicReaction id = 'first' episode = extremeEpisode severity = 18
    kind = 'collapse' approved = true description = 'Falls to the chamber floor, losing the next second' seconds = 1;
extremeSecond: RpgExpandedExtremePanicReaction id = 'second' episode = extremeEpisode severity = 7
    kind = 'cry' approved = true description = 'Spends another second crying instead of acting' seconds = 1;
panicDice: object rolls = [18,18,7,3] index = 0;
modify rpgRandom
    roll() { self.draws += 3; panicDice.index += 1; return panicDice.rolls[panicDice.index]; }
;
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 440 || code == 441)
        { extremeEpisode.apply(); if (code == 441) throw new RpgError(); return nil; }
        if (code == 442 || code == 443)
        { extremeFirst.apply(); if (code == 443) throw new RpgError(); return nil; }
        if (code == 444) { extremeSecond.apply(); return nil; }
        if (code == 445)
        {
            event('test.extreme-panic'); eventValue(extremeEpisode.pendingSeverity); eventValue(extremeEpisode.reactions.length());
            eventValue(extremeEpisode.completedAt); eventValue(fearProfile.extremePanic == nil ? 0 : 1);
            eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
        }
        if (code == 446) { extremeFirst.severity = 17; extremeFirst.apply(); return nil; }
        if (code == 447) { extremeFirst.kind = 'flight'; extremeFirst.apply(); return nil; }
        if (code == 448) { fearProfile.validateFeatures(); return nil; }
        return inherited(context);
    }
;
