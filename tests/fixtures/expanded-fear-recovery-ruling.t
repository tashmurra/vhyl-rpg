#include "expanded-fear.t"
recoveryRuling: RpgExpandedFearRecoveryDecision owner = fearRecovery recover = true approved = true
    evidence = 'Author resolves an unavailable recovery roll without inventing a margin';
modify FearTestAction
    exec(context)
    {
        local code = fearInput.code;
        if (code == 610) { fearEpisode.tableTotal = 6; fearEpisode.apply(); fearProfile.willAdjustment = -8; rpgSpendTime(1); return nil; }
        if (code == 611) { fearRecovery.recoveryDecision = recoveryRuling; return nil; }
        if (code == 612)
        { local v = fearRecovery.assess(); event('test.recovery-ruling-preview'); eventValue(v.status); eventValue(v.reason); return nil; }
        if (code == 613 || code == 614)
        { fearRecovery.apply(); if (code == 614) throw new RpgError(); return nil; }
        if (code == 615)
        {
            event('test.recovery-ruling'); eventValue(fearEpisode.completed ? 1 : 0); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds);
            local check = fearRecovery.result == nil ? nil : fearRecovery.result.check;
            eventValue(check == nil ? nil : check.roll); eventValue(check == nil ? nil : check.margin);
            eventValue(check == nil ? nil : check.reason); return nil;
        }
        if (code == 616) { recoveryRuling.evidence = 'Changed'; fearRecovery.assess(); return nil; }
        return inherited(context);
    }
;
