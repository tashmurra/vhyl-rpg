#include "expanded-fear-event.t"
boundaryDecision: RpgExpandedLowScoreFearDecision entry = ownedFearEvent row = 31 approved = true
    evidence = 'The author selects a consequence at the unrollable initial fear boundary';
fearDecision: RpgExpandedFearAdjudication id = 'replacement' entry = ownedFearEvent mode = 'replace' row = 10
    approved = true evidence = 'The author selects a suitable brief stunned reaction for this scene';
fearReroll: RpgExpandedFearAdjudication id = 'reroll' entry = ownedFearEvent mode = 'reroll'
    approved = true reason = 'confusion' evidence = 'The first reaction does not fit this confusing stimulus';
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 998) { fearDecision.row = 4; fearDecision.apply(); return nil; }
        if (code == 999 || code == 1000)
        { fearEpisode.tableTotal = 4; ownedFearEvent.applyConsequence(fearEpisode);
          if (code == 1000) throw new RpgError(); return nil; }
        if (code == 1001)
        {
            event('test.boundary-lifecycle'); eventValue(ownedFearEvent.selectedRow());
            eventValue(ownedFearEvent.consequence == nil ? 0 : 1);
            eventValue(fearProfile.mentalStun ? 1 : 0); eventValue(fearEpisode.completed ? 1 : 0);
            eventValue(fearProfile.fearStunEpisodes.length()); eventValue(rpgRandom.draws);
            eventValue(rpgLedger.seconds); eventValue(fearProfile.ht); eventValue(fearProfile.iq); return nil;
        }
        if (code == 480 || code == 481) { fearDecision.apply(); if (code == 481) throw new RpgError(); return nil; }
        if (code == 482) { fearReroll.apply(); return nil; }
        if (code == 483)
        {
            event('test.fear-adjudication'); eventValue(ownedFearEvent.result == nil ? nil : ownedFearEvent.result.row);
            eventValue(ownedFearEvent.selectedRow()); eventValue(ownedFearEvent.adjudications.length()); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 486 || code == 487 || code == 488)
        {
            fearProfile.willAdjustment = -8; fearProfile.ht = code == 486 ? 1 : 2;
            if (code == 488) { fearProfile.iq = 1; fearProfile.willAdjustment = 1; boundaryDecision.row = 40; }
            ownedFearEvent.lowScoreDecision = boundaryDecision; ownedFearEvent.resolve(); return nil;
        }
        if (code == 489)
        { event('test.fear-boundary'); eventValue(ownedFearEvent.consequenceBoundaryReason()); eventValue(rpgRandom.draws); return nil; }
        if (code == 484) { fearDecision.approved = nil; fearDecision.apply(); return nil; }
        if (code == 485) { fearEpisode.tableTotal = 10; ownedFearEvent.applyConsequence(fearEpisode); return nil; }
        return inherited(context);
    }
;
