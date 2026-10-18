#include "expanded-decompression-illness.t"
modify BleedTestAction
    exec(context)
    {
        local code = bleedInput.code;
        if (code == 8700)
        { illness.failureMode = 'paralysis'; illness.positionAssessed = true; illness.balanced = nil; return nil; }
        if (code == 8701) { illness.positionAssessed = nil; return nil; }
        if (code == 8702)
        {
            event('test.decompression-paralysis'); eventValue(bleedProfile.paralyzed() ? 1 : 0);
            eventValue(bleedProfile.voluntaryMovementUnavailable() ? 1 : 0);
            eventValue(bleedProfile.healthBlocksDefense() ? 1 : 0);
            eventValue(bleedProfile.posture); eventValue(bleedProfile.unconscious ? 1 : 0);
            eventValue(bleedProfile.paralysisHistory.length()); eventValue(rpgRandom.draws); return nil;
        }
        return inherited(context);
    }
;
