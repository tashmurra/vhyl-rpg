#include "expanded-fear-panic.t"
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 10800) { panicEpisode.nextCheckAt += 60; return nil; }
        if (code == 10801) { panicEpisode.completedAt = rpgLedger.seconds; bleedProfile.fearPanic = nil; return nil; }
        if (code == 10802) { panicRecovery.result.check.achieved = true; return nil; }
        if (code == 10803) { panicEpisode.recoveries = []; return nil; }
        if (code == 10804) { panicRecovery.recordedAt -= 1; return nil; }
        if (code == 10805) { bleedProfile.fearPanicEpisodes = []; return nil; }
        if (code == 10809) { bleedProfile.fearPanic = nil; return nil; }
        if (code == 10806 || code == 10807 || code == 10808 || code == 10810)
        {
            event('test.panic-history');
            try
            {
                if (code == 10806) panicEpisode.assess();
                else if (code == 10807) rpgSpendTime(1);
                else if (code == 10808) panicRecovery.assess();
                else bleedProfile.healthEffortReason('action',nil,nil,true);
                eventValue('accepted');
            }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        return inherited(context);
    }
;
