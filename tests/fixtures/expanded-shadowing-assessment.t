#include "expanded-stealth-context.t"
shadowAssessmentInput: object aware = nil target = beggingObserver context = visionContextFixture;
shadowTargetContext: RpgExpandedShadowingContext skill = shadowingCatalogue crowdAvailable = true approved = true
    evidence = 'The aware target is evading through the same crowd';
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 29400)
        {
            local value = rpgExpandedPrepareShadowing(crossPhysician,shadowingContextFixture,shadowAssessmentInput.target,
                shadowAssessmentInput.context,shadowAssessmentInput.aware);
            event('test.shadowing-assessment'); eventValue(value.status); eventValue(value.reason); eventValue(value.interval);
            eventValue(value.targetRole); eventValue(value.followerScore); eventValue(value.targetScore);
            eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil;
        }
        if (code == 29401) { shadowAssessmentInput.aware = true; shadowAssessmentInput.context = shadowTargetContext; return nil; }
        if (code == 29402) { shadowAssessmentInput.aware = true; shadowAssessmentInput.context = stealthContextFixture; return nil; }
        if (code == 29403) { shadowAssessmentInput.aware = true; return nil; }
        if (code == 29404) { shadowAssessmentInput.context = stealthContextFixture; return nil; }
        if (code == 29405) { visionContextFixture.ordinarySightAvailable = nil; return nil; }
        if (code == 29406) { beggingObserver.unconscious = true; return nil; }
        if (code == 29407) { stealthContextFixture.scentObserver = crossPhysician; crossPhysician.traits = [fineSmellFixture]; return nil; }
        if (code == 29408) { beggingObserver.dx = 15; return nil; }
        return inherited(context);
    }
;
