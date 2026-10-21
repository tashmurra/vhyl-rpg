#include "expanded-danger-warning.t"
chemicalContextFixture: RpgExpandedChemicalContext ordinarySenseAvailable = true stimulusAvailable = true approved = true
    evidence = 'A scent is present in the air within reach of the observer';
chemicalObservationFixture: RpgExpandedChemicalObservation id = 'notice-scent' profile = crossPhysician context = chemicalContextFixture
    target = healthRoom occurrence = terrainOccurrence;
chemicalAcuteFixture: RpgLiteTrait id = 'acute-taste-smell' points = 2 level = 2;
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 27900 || code == 27901)
        { chemicalObservationFixture.resolve(); if (code == 27901) throw new RpgError(); return nil; }
        if (code == 27902)
        { event('test.chemical-state'); eventValue(crossPhysician.chemicalObservations.length());
          eventValue(chemicalObservationFixture.result == nil ? nil : chemicalObservationFixture.result.noticed);
          eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil; }
        if (code == 27903)
        { event('test.chemical-score'); eventValue(rpgLiteScore(crossPhysician,chemicalContextFixture)); return nil; }
        if (code == 27904) { chemicalContextFixture.sense = 'taste'; return nil; }
        if (code == 27905) { chemicalContextFixture.intensityModifier = 3; chemicalContextFixture.disguiseModifier = -2; return nil; }
        if (code == 27906) { crossPhysician.traits = crossPhysician.traits + [chemicalAcuteFixture]; return nil; }
        if (code == 27907) { chemicalContextFixture.ordinarySenseAvailable = nil; return nil; }
        if (code == 27908) { chemicalContextFixture.stimulusAvailable = nil; return nil; }
        if (code == 27909) { comprehensionFixture.observation = chemicalObservationFixture; return nil; }
        if (code == 27910) { ordinaryWarningFixture.failedAttempt = chemicalObservationFixture; return nil; }
        if (code == 27911) { chemicalObservationFixture.result.noticed = nil; chemicalObservationFixture.assess(); return nil; }
        return inherited(context);
    }
;
