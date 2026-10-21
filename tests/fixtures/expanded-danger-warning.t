#include "expanded-sense-comprehension.t"
ordinaryWarningTrait: RpgLiteTrait id = 'danger-sense' points = 15;
modify crossPhysician traits = [ordinaryWarningTrait];
ordinaryWarningFixture: RpgExpandedOrdinaryDangerWarning id = 'unstable-crossing' profile = crossPhysician situation = terrainOccurrence
    hazardPresent = true approved = true evidence = 'The nearby crossing is about to collapse'
    warningText = 'Something is wrong nearby' detailText = 'The crossing is about to collapse';
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 27700 || code == 27701)
        { ordinaryWarningFixture.resolve(); if (code == 27701) throw new RpgError(); return nil; }
        if (code == 27702)
        { event('test.ordinary-warning'); eventValue(crossPhysician.ordinaryDangerWarnings.length());
          eventValue(ordinaryWarningFixture.result == nil ? nil : ordinaryWarningFixture.result.warning);
          eventValue(ordinaryWarningFixture.result == nil || ordinaryWarningFixture.result.check == nil ? 1 : 0);
          eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil; }
        if (code == 27703)
        { local value = ordinaryWarningFixture.assess(); event('test.warning-preview'); eventValue(value.status); eventValue(value.reason); return nil; }
        if (code == 27704) { rpgRandom.medicalRoll = 4; return nil; }
        if (code == 27705) { rpgRandom.medicalRoll = 5; return nil; }
        if (code == 27706) { rpgRandom.medicalRoll = 3; return nil; }
        if (code == 27707) { ordinaryWarningTrait.mitigated = true; return nil; }
        if (code == 27708) { ordinaryWarningFixture.hazardPresent = nil; return nil; }
        if (code == 27709)
        { ordinaryWarningFixture.secretCheck.roll += 1; ordinaryWarningFixture.assess(); return nil; }
        if (code == 27710) { ordinaryWarningFixture.failedAttempt = hearingObservationFixture; return nil; }
        if (code == 27711) { ordinaryWarningFixture.failedAttempt = comprehensionFixture; return nil; }
        return inherited(context);
    }
;
