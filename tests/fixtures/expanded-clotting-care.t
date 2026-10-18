#include "expanded-clotting-loss.t"
clottingCare: RpgExpandedClottingBandage episode = clottingEpisode wound = bleedWound healer = bleedHealer
    eligibleInjury = 2 evidence = 'Pressure and a secure dressing for this wound';
clottingDaily: RpgExpandedClottingLoss id = 'daily-loss' episode = clottingEpisode;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code >= 70 && code <= 72)
        {
            if (code == 71) clottingCare.assess(); else clottingCare.apply();
            if (code == 72) throw new RpgError(); return nil;
        }
        if (code == 73) { rpgSpendTime(86400); return nil; }
        if (code == 74) { clottingDaily.apply(); return nil; }
        if (code == 75)
        {
            event('test.clotting-care'); eventValue(bleedProfile.injury); eventValue(clottingEpisode.care);
            eventValue(clottingEpisode.internalLoss); eventValue(clottingEpisode.nextLossAt);
            eventValue(clottingCare.result == nil ? nil : clottingCare.result.healed);
            eventValue(bleedProfile.clottingProtectedInjury()); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        return inherited(context);
    }
;
