#include "expanded-hearing.t"
hearingObservationFixture: RpgExpandedHearingObservation id = 'distant-call' profile = crossPhysician context = hearingContextFixture
    target = healthRoom occurrence = terrainOccurrence;
modify PhysicianFixtureAction
    exec(context)
    {
        local code = healthInput.code;
        if (code == 27400 || code == 27401)
        { hearingObservationFixture.resolve(); if (code == 27401) throw new RpgError(); return nil; }
        if (code == 27402)
        { local value = hearingObservationFixture.assess(); event('test.hearing-preview'); eventValue(value.status); eventValue(value.reason); return nil; }
        if (code == 27403)
        { event('test.hearing-state'); eventValue(crossPhysician.hearingObservations.length());
          eventValue(hearingObservationFixture.result == nil ? nil : hearingObservationFixture.result.noticed);
          eventValue(rpgRandom.draws); eventValue(rpgLedger.seconds); return nil; }
        if (code == 27404)
        { hearingObservationFixture.result.noticed = nil; hearingObservationFixture.assess(); return nil; }
        return inherited(context);
    }
;
