#include "expanded-cultures.t"
gestureAttemptFixture: RpgExpandedGestureAttempt id = 'doorway-signal' profile = crossPhysician counterpart = beggingObserver
    context = gestureTask seconds = 2 approved = true evidence = 'An observed brief hand signal at the doorway';
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 26500 || code == 26501)
        { gestureAttemptFixture.resolve(); if (code == 26501) throw new RpgError(); return nil; }
        if (code == 26502)
        { local value = gestureAttemptFixture.assess(); event('test.gesture-preview'); eventValue(value.status); eventValue(value.reason); return nil; }
        if (code == 26503)
        { event('test.gesture-attempt'); eventValue(crossPhysician.gestureAttempts.length()); eventValue(beggingObserver.gestureAttempts.length());
          eventValue(gestureAttemptFixture.result == nil ? nil : gestureAttemptFixture.result.meaning);
          eventValue(rpgLedger.seconds); eventValue(rpgRandom.draws); return nil; }
        if (code == 26504) { rpgRandom.medicalRoll = 18; return nil; }
        if (code == 26505) { crossPhysician.fatigue = crossPhysician.maxEnergy; rpgRandom.medicalRoll = 13; return nil; }
        if (code == 26506) { beggingObserver.unconscious = true; return nil; }
        if (code == 26507)
        { gestureAttemptFixture.result.meaning = 'A rewritten instruction'; gestureAttemptFixture.assess(); return nil; }
        return inherited(context);
    }
;
