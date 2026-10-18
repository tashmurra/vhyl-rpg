#include "expanded-decompression-paralysis.t"
recompressionPressure: RpgExpandedPressureExposure id = 'treatment-pressure' profile = bleedProfile pressure = 300
    approved = true evidence = 'Maintained chamber pressure equal to the highest exposure';
recompression: RpgExpandedRecompression id = 'chamber-care' episode = illness exposure = recompressionPressure
    highestConfirmed = true approved = true evidence = 'Author confirms this exposure was the highest pressure experienced';
recompressionFirst: RpgExpandedRecompressionCheck treatment = recompression;
recompressionSecond: RpgExpandedRecompressionCheck treatment = recompression;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 8800) { recompressionPressure.begin(); recompression.begin(); return nil; }
        if (code == 8801 || code == 8802 || code == 8803)
        {
            local value = code == 8802 ? recompressionSecond.apply() : recompressionFirst.apply();
            event('test.recompression-result'); eventValue(value.status); eventValue(value.reason); eventValue(value.phase);
            if (code == 8803) throw new RpgError(); return nil;
        }
        if (code == 8804)
        {
            event('test.recompression'); eventValue(illness.phase); eventValue(recompression.checks.length());
            eventValue(bleedProfile.agonized() ? 1 : 0); eventValue(bleedProfile.paralyzed() ? 1 : 0);
            eventValue(bleedProfile.unconscious ? 1 : 0); eventValue(bleedProfile.fatigue);
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 8805)
        {
            if (illness.phase == 'agony')
            {
                for (local minute = 1; minute <= 5; minute += 1)
                {
                    // At a check boundary, attempt treatment before paying the next begun minute.
                    if (rpgLedger.seconds == illness.agony.nextPaymentAt)
                        illness.agony.pay('minute:' + rpgLedger.seconds);
                    rpgSpendTime(60);
                }
            }
            else rpgSpendTime(300);
            return nil;
        }
        if (code == 8809)
        {
            event('test.recompression-boundary');
            try { rpgSpendTime(301); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 8810) { recompressionPressure.pressure = 200; return nil; }
        if (code == 8811)
        {
            local value = recompression.assess(); event('test.recompression-preview');
            eventValue(value.status); eventValue(value.reason); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 8806) { rpgSpendTime(600); return nil; }
        if (code == 8807) { bleedInput.forcedRoll = 15; return nil; }
        if (code == 8808) { recompression.cancel(); recompressionPressure.end(); return nil; }
        return inherited(context);
    }
;
