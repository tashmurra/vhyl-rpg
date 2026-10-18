#include "expanded-march-fatigue.t"
marchExecution: RpgExpandedMarchHour id = 'walking-hour' profile = bleedProfile interval = marchInterval
    approved = true evidence = 'One continuous road-travel hour under unchanged conditions' dropDestination = bleedRoom;
modify rpgLedger
    afterAdvance(previous)
    {
        inherited(previous);
        if (bleedInput.code == 1147) bleedProfile.fatigue += 1;
        return nil;
    }
;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 1140)
        {
            local value = marchExecution.assess(); event('test.march-hour-preview');
            eventValue(value.status); eventValue(value.reason); eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
        }
        if (code == 1141 || code == 1142 || code == 1147)
        { marchExecution.apply(); if (code == 1142) throw new RpgError(); return nil; }
        if (code == 1143)
        {
            event('test.march-hour-owned'); eventValue(rpgLedger.seconds); eventValue(bleedProfile.fatigue);
            eventValue(bleedProfile.injury); eventValue(bleedProfile.marchExecutions.length());
            eventValue(bleedProfile.marchHours.length()); eventValue(rpgRandom.draws);
            eventValue(marchExecution.result != nil && marchExecution.result.allowed ? 1 : 0); return nil;
        }
        if (code == 1144) { bleedProfile.fatigue = 10; return nil; }
        if (code == 1145) { bleedInput.forcedRoll = 11; return nil; }
        if (code == 1146) { bleedProfile.injury = 10; return nil; }
        return inherited(context);
    }
;
