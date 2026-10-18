#include "expanded-sensory-recognition.t"
modify crossPhysician traits = [fineHearingFixture,fineSmellFixture];
memorySignature: object;
memoryAttempt: RpgExpandedSensoryMemoryAttempt id = 'learn-signature' profile = crossPhysician sense = 'hearing'
    signature = memorySignature sourceAvailable = true approved = true evidence = 'The sound remains audible throughout the exposure';
memoryRetry: RpgExpandedSensoryMemoryAttempt id = 'retry-signature' profile = crossPhysician sense = 'hearing'
    signature = memorySignature sourceAvailable = true approved = true evidence = 'The same signature is available again';
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 28100 || code == 28101)
        { memoryAttempt.resolve(); if (code == 28101) throw new RpgError(); return nil; }
        if (code == 28102)
        { event('test.sensory-memory'); eventValue(crossPhysician.sensoryMemoryAttempts.length());
          eventValue(memoryAttempt.result == nil ? nil : memoryAttempt.result.memorized);
          eventValue(memoryAttempt.result == nil ? nil : memoryAttempt.result.retryAt);
          eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil; }
        if (code == 28103)
        { local value = memoryAttempt.assess(); event('test.memory-preview'); eventValue(value.status); eventValue(value.reason); eventValue(value.score); return nil; }
        if (code == 28104) { memoryRetry.resolve(); return nil; }
        if (code == 28105)
        { local value = memoryRetry.assess(); event('test.memory-retry'); eventValue(value.status); eventValue(value.reason); eventValue(value.retryAt); return nil; }
        if (code == 28106) { rpgSpendTime(86399); return nil; }
        if (code == 28107) { rpgSpendTime(1); return nil; }
        if (code == 28108) { memoryAttempt.sourceAvailable = nil; return nil; }
        if (code == 28109) { memoryAttempt.seconds = 59; return nil; }
        if (code == 28110) { memoryAttempt.sense = 'smell'; memoryRetry.sense = 'smell'; return nil; }
        if (code == 28111) { fineHearingFixture.mitigated = true; return nil; }
        if (code == 28112) { memoryAttempt.result.retryAt = 0; memoryAttempt.assess(); return nil; }
        if (code == 28113)
        { event('test.memory-known'); eventValue(crossPhysician.knowsSensorySignature(memoryAttempt.sense,memorySignature)); return nil; }
        return inherited(context);
    }
;
