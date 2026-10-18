#include "expanded-pressure.t"
decompressionPlan: RpgExpandedDecompressionPlan id = 'authored-ascent' source = pressureExposure
    stages = [[200,60],[100,60]] approved = true
    evidence = 'Campaign author approves these exact stages for this exposure; this is not an inferred schedule';
decompressionFirst: RpgExpandedDecompressionProgress plan = decompressionPlan stage = 1 seconds = 60;
decompressionSecond: RpgExpandedDecompressionProgress plan = decompressionPlan stage = 2 seconds = 60;
decompressionStageEntry: RpgExpandedPressureCheck;
decompressionStageMinute: RpgExpandedPressureCheck;
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 8500)
        {
            pressureExposure.pressure = 250; pressureExposure.begin(); pressureExposure.end();
            decompressionPlan.begin(); return nil;
        }
        if (code == 8501) { decompressionFirst.apply(); return nil; }
        if (code == 8502) { decompressionPlan.finishStage(); return nil; }
        if (code == 8503) { decompressionSecond.apply(); return nil; }
        if (code == 8504)
        {
            event('test.decompression-plan'); eventValue(decompressionPlan.stageIndex); eventValue(decompressionPlan.stageSeconds);
            eventValue(decompressionPlan.completedAt); eventValue(decompressionPlan.progress.length());
            eventValue(decompressionPlan.exposures.length()); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 8505) { decompressionFirst.apply(); throw new RpgError(); }
        if (code == 8510)
        {
            pressureExposure.begin(); pressureEntry.apply(); pressureExposure.end();
            decompressionPlan.stages = [[2000,60],[100,60]]; decompressionPlan.begin();
            decompressionStageEntry.exposure = decompressionPlan.exposures[1];
            decompressionStageMinute.exposure = decompressionPlan.exposures[1]; return nil;
        }
        if (code == 8512) { decompressionStageEntry.apply(); return nil; }
        if (code == 8513)
        {
            local value = decompressionPlan.finishStage(); event('test.decompression-stage-end');
            eventValue(value.status); eventValue(value.reason); return nil;
        }
        if (code == 8514) { decompressionStageMinute.apply(); return nil; }
        if (code == 8515)
        {
            pressureExposure.pressure = 250; pressureExposure.begin(); pressureExposure.end();
            decompressionPlan.stages = [[200,30],[200,30],[100,60]];
            event('test.decompression-stage-error');
            try { decompressionPlan.begin(); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil;
        }
        if (code == 8506)
        {
            event('test.decompression-clock');
            try { rpgSpendTime(1); eventValue('accepted'); }
            catch (RpgExpandedError error) { eventValue(error.reason); }
            eventValue(rpgLedger.seconds); return nil;
        }
        return inherited(context);
    }
;
