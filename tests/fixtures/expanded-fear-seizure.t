#include "expanded-fear-acute.t"
fearFit: RpgExpandedFearSeizure id = 'apparition-fit' context = acuteScene approved = true
    evidence = 'The recorded fear-table outcome is thirty-one' dropDestination = bleedRoom;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 10900) { bleedInput.forcedRoll = 10; return nil; }
        if (code == 10901)
        {
            local value = fearFit.assess(); event('test.fear-fit-preview'); eventValue(value.status);
            eventValue(value.reason); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 10902 || code == 10903)
        {
            local value = fearFit.apply(); event('test.fear-fit'); eventValue(value.status);
            eventValue(value.healthBefore); eventValue(value.healthAfter); eventValue(value.healthLost ? 1 : 0);
            if (code == 10903) throw new RpgError(); return nil;
        }
        if (code == 10904)
        {
            event('test.fear-fit-state'); eventValue(bleedProfile.injury); eventValue(bleedProfile.fatigue);
            eventValue(bleedProfile.ht); eventValue(bleedProfile.developmentRevision); eventValue(bleedProfile.seizureHistory.length());
            eventValue(bleedProfile.seizing() ? 1 : 0); eventValue(bleedProfile.posture); eventValue(rpgLedger.seconds);
            eventValue(rpgRandom.draws); return nil;
        }
        if (code == 10905) { bleedInput.forcedRoll = 11; return nil; }
        if (code == 10906) { bleedInput.forcedRoll = 18; return nil; }
        if (code == 10907) { rpgSpendTime(60); return nil; }
        if (code == 10908) { fearFit.result.seizure.finish(); return nil; }
        if (code == 10909) { bleedProfile.equipment = [acuteHeld]; fearFit.dropDestination = nil; return nil; }
        return inherited(context);
    }
;
