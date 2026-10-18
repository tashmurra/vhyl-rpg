#include "expanded-persistent-dressing.t"
poisonDefinition: RpgLiteHazard kind = 'poison' delay = 60 cycles = 1 dice = 1 adds = 0 resistanceModifier = -2;
poisonDelivery: RpgExpandedPoisonEntry patient = bleedProfile route = 'blood' persistentWoundReached = true
    approved = true evidence = 'The fictional agent actually reached the persistent opening';
poisonExposure: RpgExpandedPoisonExposure id = 'fictional-agent' profile = bleedProfile hazard = poisonDefinition entry = poisonDelivery
    approved = true effectEvidence = 'Original fictional single-cycle agent: one die of toxic injury after one minute, resisted at HT-2';
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 260) { poisonExposure.start(); return nil; }
        if (code == 261) { poisonExposure.assessResolution(); return nil; }
        if (code == 262 || code == 263)
        { poisonExposure.resolve(); if (code == 263) throw new RpgError(); return nil; }
        if (code == 264)
        {
            event('test.poison-exposure'); eventValue(poisonExposure.startedAt); eventValue(poisonExposure.dueAt);
            eventValue(poisonExposure.completedAt); eventValue(bleedProfile.poisonExposures.length());
            eventValue(bleedProfile.injury); eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 265) { bleedInput.forcedRoll = 17; surgicalOperationInput.fixedDie = 4; return nil; }
        if (code == 266) { bleedInput.forcedRoll = 8; return nil; }
        if (code == 267) { poisonExposure.sizeModifier = -1; return nil; }
        if (code == 268) { rpgSpendTime(30); return nil; }
        if (code == 269) { poisonDefinition.cycles = 2; return nil; }
        if (code == 270) { poisonDefinition.resistible = nil; surgicalOperationInput.fixedDie = 4; return nil; }
        if (code == 271) { poisonDefinition.delay = 1; poisonExposure.sizeModifier = -1; return nil; }
        return inherited(context);
    }
;
