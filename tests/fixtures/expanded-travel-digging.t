#include "expanded-digging-team.t"
digTravelDay: RpgExpandedTravelDay id = 'worker-travels' profile = bleedProfile approved = true evidence = 'Worker uses full daily travel allowance';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 24000) { digTravelDay.reserve(); return nil; }
        if (code == 24001)
        { local value = digTeam.assess(); event('test.travel-dig-team'); eventValue(value.status); eventValue(value.reason); return nil; }
        if (code == 24002)
        { local value = digHour.assess(); event('test.travel-dig-solo'); eventValue(value.status); eventValue(value.reason); return nil; }
        if (code == 24004) { rpgSpendTime(86400); return nil; }
        if (code == 24005)
        { event('test.travel-dig-state'); eventValue(rpgLedger.seconds); eventValue(digSite.hours.length()); eventValue(bleedProfile.fatigue); eventValue(rpgRandom.draws); return nil; }
        return inherited(context);
    }
;
