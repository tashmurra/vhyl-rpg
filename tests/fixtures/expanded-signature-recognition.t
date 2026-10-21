#include "expanded-sensory-memory.t"
recognizedSubject: object;
recognitionFixture: RpgExpandedSignatureRecognition id = 'recognize-signature' profile = crossPhysician observation = hearingObservationFixture
    signature = memorySignature subject = recognizedSubject approved = true identityUncontested = true evidence = 'The observed signature belongs to this subject';
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 28300 || code == 28301)
        { recognitionFixture.resolve(); if (code == 28301) throw new RpgError(); return nil; }
        if (code == 28302)
        { event('test.signature-recognition'); eventValue(crossPhysician.signatureRecognitions.length());
          eventValue(recognitionFixture.result == nil ? nil : recognitionFixture.result.recognized);
          eventValue(recognitionFixture.result != nil && recognitionFixture.result.subject == recognizedSubject ? 1 : 0);
          eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil; }
        if (code == 28303)
        { local value = recognitionFixture.assess(); event('test.recognition-preview'); eventValue(value.status); eventValue(value.reason); return nil; }
        if (code == 28304)
        { recognitionFixture.familiarBeforehand = true; recognitionFixture.familiarityEvidence = 'A long-known companion voice'; return nil; }
        if (code == 28305) { recognitionFixture.familiarBeforehand = true; return nil; }
        if (code == 28306) { recognitionFixture.profile = beggingObserver; return nil; }
        if (code == 28307) { recognitionFixture.result.subject = healthRoom; recognitionFixture.assess(); return nil; }
        if (code == 28308) { recognitionFixture.observation = chemicalObservationFixture; memoryAttempt.sense = 'smell'; return nil; }
        if (code == 28309) { recognitionFixture.identityUncontested = nil; return nil; }
        return inherited(context);
    }
;
