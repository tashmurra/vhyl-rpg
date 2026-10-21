#include "expanded-hearing-observation.t"
comprehensionContextFixture: RpgExpandedComprehensionContext evidence = 'The listener can interpret the ordinary signal';
comprehensionFixture: RpgExpandedSenseComprehension id = 'interpret-call' profile = crossPhysician observation = hearingObservationFixture
    context = comprehensionContextFixture meaning = 'The call warns of a blocked crossing' seconds = 2 applicable = true
    evidence = 'The noticed call provides sufficient evidence for this interpretation';
comprehensionLanguage: RpgLiteLanguage id = 'river-speech' spoken = 1 written = 0;
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 27600 || code == 27601)
        { comprehensionFixture.resolve(); if (code == 27601) throw new RpgError(); return nil; }
        if (code == 27602)
        { local value = comprehensionFixture.assess(); event('test.comprehension-preview'); eventValue(value.status); eventValue(value.reason); eventValue(value.score); return nil; }
        if (code == 27603)
        { event('test.comprehension-state'); eventValue(crossPhysician.senseComprehensions.length());
          eventValue(comprehensionFixture.result == nil ? nil : comprehensionFixture.result.meaning);
          eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil; }
        if (code == 27604) { comprehensionContextFixture.purpose = 'speech'; comprehensionContextFixture.language = 'river-speech'; return nil; }
        if (code == 27605) { crossPhysician.languages = [comprehensionLanguage]; return nil; }
        if (code == 27606)
        { comprehensionContextFixture.purpose = 'expert'; comprehensionContextFixture.skill = geologyCatalogue;
          comprehensionContextFixture.expertiseApproved = true; return nil; }
        if (code == 27607) { comprehensionFixture.profile = beggingObserver; return nil; }
        if (code == 27608)
        { comprehensionFixture.result.meaning = 'A rewritten interpretation'; comprehensionFixture.assess(); return nil; }
        if (code == 27609) { comprehensionFixture.observation = visionObservationFixture; return nil; }
        return inherited(context);
    }
;
