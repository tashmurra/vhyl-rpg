#include "expanded-pressure.t"
illness: RpgExpandedDecompressionIllness id = 'unsafe-return' source = pressureExposure
    humanExamples = true unsafeReturn = true approved = true
    evidence = 'Author confirms inadequate decompression after compressed-air exposure';
illnessRecovery: RpgExpandedDecompressionRecovery episode = illness;
illnessSecondRecovery: RpgExpandedDecompressionRecovery episode = illness;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 8600)
        {
            // Large reserves isolate the illness clock from exhaustion in this fixture.
            bleedProfile.fpAdjustment = 100; bleedProfile.hpAdjustment = 20;
            pressureExposure.pressure = 300; pressureExposure.begin(); pressureExposure.end(); return nil;
        }
        if (code == 8601 || code == 8602 || code == 8603)
        {
            local value = code == 8601 ? illness.assess() : illness.apply();
            event('test.decompression-illness-result'); eventValue(value.status); eventValue(value.reason);
            eventValue(value.phase); if (code == 8603) throw new RpgError(); return nil;
        }
        if (code == 8604)
        {
            event('test.decompression-illness'); eventValue(illness.phase); eventValue(illness.recoveries.length());
            eventValue(bleedProfile.fatigue); eventValue(bleedProfile.injury);
            eventValue(bleedProfile.unconscious ? 1 : 0); eventValue(bleedProfile.dead ? 1 : 0);
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 8605)
        {
            if (illness.phase == 'agony')
            {
                for (local minute = 1; minute < 60; minute += 1)
                { rpgSpendTime(60); illness.agony.pay('minute:' + minute); }
                rpgSpendTime(60);
            }
            else rpgSpendTime(3600);
            return nil;
        }
        if (code == 8606 || code == 8607)
        {
            local value = code == 8606 ? illnessRecovery.apply() : illnessSecondRecovery.apply();
            event('test.decompression-recovery'); eventValue(value.status); eventValue(value.reason);
            eventValue(value.phase); eventValue(value.injury); return nil;
        }
        if (code == 8608) { bleedInput.forcedRoll = 11; return nil; }
        if (code == 8609) { bleedInput.forcedRoll = 18; return nil; }
        if (code == 8610)
        {
            event('test.decompression-illness-clock');
            try { rpgSpendTime(3601); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        return inherited(context);
    }
;
